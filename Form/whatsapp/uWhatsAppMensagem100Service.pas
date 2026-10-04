unit uWhatsAppMensagem100Service;
interface
uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections,
  System.StrUtils, System.DateUtils, System.Math, System.IOUtils, Data.DB, DBAccess, Uni,
  UConesul, uEvolutionAPI;
type
  TWhatsAppMensagemConfig100 = record
    ProviderName: string;
    Server: string;
    Port: Integer;
    Database: string;
    UserName: string;
    Password: string;
    IntervaloMs: Cardinal;
    TamanhoLote: Integer;
    MaxTentativas: Integer;
    MinDelayMs: Integer;
    MaxDelayMs: Integer;
    LimitePorJanela: Integer;
    JanelaMs: Integer;
    CooldownNumeroMs: Integer;
    GravarLogBanco: Boolean;
    CaminhoLog: string;
    class function Criar(const AConn: TUniConnection; const AIntervaloMs: Cardinal;
                  const AGravarLogBanco: Boolean): TWhatsAppMensagemConfig100; static;
  end;
  TWhatsAppMensagemService100 = class
  private
    FConfig: TWhatsAppMensagemConfig100;
    FThread: TThread;
    FStopEvent: TEvent;
    FLogLock: TCriticalSection;
    FEvolution: TEvolutionAPI;
    FCooldowns: TDictionary<string, TDateTime>;
    FInicioJanela: TDateTime;
    FEnviosNaJanela: Integer;
    FEstruturaVerificada: Boolean;
    FRecuperacaoExecutada: Boolean;
    FTemTentativas: Boolean;
    FTemProximoEnvio: Boolean;
    FTemProcessandoEm: Boolean;
    FTemUltimoErro: Boolean;
    FTemMessageID: Boolean;
    function CriarConexao: TUniConnection;
    function InicializarEvolution(AConn: TUniConnection): Boolean;
    function Parando: Boolean;
    function Aguardar(const AMilisegundos: Cardinal): Boolean;
    function AguardarLimites(const ANumero: string): Boolean;
    procedure RegistrarTentativaEnvio(const ANumero: string);
    procedure LimparCooldownsExpirados;
    procedure Executar;
    procedure ProcessarLote;
    procedure ProcessarMensagem(AConn: TUniConnection; AQry: TUniQuery);
    procedure VerificarEstrutura(AConn: TUniConnection);
    procedure RecuperarMensagensInterrompidas(AConn: TUniConnection);
    function TentarMarcarProcessando(AConn: TUniConnection; const AID: Int64): Boolean;
    procedure MarcarEnviada(AConn: TUniConnection; const AID: Int64; const AMessageID: string);
    procedure MarcarRetry(AConn: TUniConnection; const AID: Int64; const ATentativa: Integer;
      const AErro: string);
    procedure MarcarFalha(AConn: TUniConnection; const AID: Int64; const AErro: string);
    procedure MarcarSemInstancia(AConn: TUniConnection; const AID: Int64; const AErro: string);
    procedure LiberarParaFila(AConn: TUniConnection; const AID: Int64);
    procedure LogArquivo(const AMensagem: string);
    procedure LogBanco(AConn: TUniConnection; const AMensagem, APara,
      AFone: string; const AIDUsuario: Integer = 0);
    function CalcularProximoEnvio(const ATentativa: Integer): TDateTime;
    function NormalizarNumeroBR(const AValor: string; out ANumero, AErro: string): Boolean;
    function InferirMediaType(const AExtensao: string): string;
    function CampoTexto(AQry: TDataSet; const ACampo: string): string;
    function CampoInteiro(AQry: TDataSet; const ACampo: string; const ADefault: Integer = 0): Integer;
    function ObterInstanciaUsuario(out AInstancia: String; AIDnumero: string;
      AConn: TUniConnection): boolean;
  public
    constructor Create(const AConfig: TWhatsAppMensagemConfig100);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Executando: Boolean;
  end;
implementation
type
  TWhatsAppWorkerThread = class(TThread)
  private
    FOwner: TWhatsAppMensagemService100;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TWhatsAppMensagemService100);
  end;
{ TWhatsAppMensagemConfig100 }
class function TWhatsAppMensagemConfig100.Criar(const AConn: TUniConnection;
  const AIntervaloMs: Cardinal; const AGravarLogBanco: Boolean): TWhatsAppMensagemConfig100;
begin
  Result.ProviderName      := AConn.ProviderName;
  Result.Server            := AConn.Server;
  Result.Port              := AConn.Port;
  Result.Database          := AConn.Database;
  Result.UserName          := AConn.UserName;
  Result.Password          := AConn.Password;
  Result.IntervaloMs       := AIntervaloMs;
  Result.TamanhoLote       := 10;
  Result.MaxTentativas     := 5;
  Result.MinDelayMs        := 2000;
  Result.MaxDelayMs        := 6000;
  Result.LimitePorJanela   := 15;
  Result.JanelaMs          := 60000;
  Result.CooldownNumeroMs  := 30000;
  Result.GravarLogBanco    := AGravarLogBanco;
  Result.CaminhoLog        := TPath.Combine(ExtractFilePath(ParamStr(0)), 'LogMensagenszap.txt');
end;
{ TWhatsAppWorkerThread }
constructor TWhatsAppWorkerThread.Create(AOwner: TWhatsAppMensagemService100);
begin
  inherited Create(True);
  FOwner := AOwner;
  FreeOnTerminate := False;
end;
procedure TWhatsAppWorkerThread.Execute;
begin
  FOwner.Executar;
end;
{ TWhatsAppMensagemConfig100 }
constructor TWhatsAppMensagemService100.Create(const AConfig: TWhatsAppMensagemConfig100);
begin
  inherited Create;
  FConfig := AConfig;
  if FConfig.IntervaloMs < 1000 then FConfig.IntervaloMs := 3000;
  if FConfig.TamanhoLote <= 0 then FConfig.TamanhoLote := 10;
  if FConfig.MaxTentativas <= 0 then FConfig.MaxTentativas := 5;
  if FConfig.MinDelayMs < 0 then FConfig.MinDelayMs := 0;
  if FConfig.MaxDelayMs < FConfig.MinDelayMs then FConfig.MaxDelayMs := FConfig.MinDelayMs;
  if FConfig.LimitePorJanela <= 0 then FConfig.LimitePorJanela := 15;
  if FConfig.JanelaMs <= 0 then FConfig.JanelaMs := 60000;
  if FConfig.CooldownNumeroMs < 0 then FConfig.CooldownNumeroMs := 0;
  if Trim(FConfig.CaminhoLog) = '' then
    FConfig.CaminhoLog := TPath.Combine(ExtractFilePath(ParamStr(0)), 'LogMensagenszap.txt');
  FStopEvent := TEvent.Create(nil, True, False, '');
  FLogLock   := TCriticalSection.Create;
  FCooldowns := TDictionary<string, TDateTime>.Create;
  FInicioJanela := Now;
end;
destructor TWhatsAppMensagemService100.Destroy;
begin
  Stop;
  FreeAndNil(FEvolution);
  FreeAndNil(FCooldowns);
  FreeAndNil(FLogLock);
  FreeAndNil(FStopEvent);
  inherited;
end;
procedure TWhatsAppMensagemService100.Start;
begin
  if Assigned(FThread) then Exit;
  FStopEvent.ResetEvent;
  FThread := TWhatsAppWorkerThread.Create(Self);
  FThread.Start;
  LogArquivo('Serviço de mensagens WhatsApp iniciado.');
end;
procedure TWhatsAppMensagemService100.Stop;
begin
  if not Assigned(FThread) then Exit;
  FStopEvent.SetEvent;
  FThread.Terminate;
  FThread.WaitFor;
  FreeAndNil(FThread);
  LogArquivo('Serviço de mensagens WhatsApp finalizado.');
end;
function TWhatsAppMensagemService100.Executando: Boolean;
begin
  Result := Assigned(FThread) and not Parando;
end;
function TWhatsAppMensagemService100.Parando: Boolean;
begin
  Result := Assigned(FStopEvent) and (FStopEvent.WaitFor(0) = wrSignaled);
end;
function TWhatsAppMensagemService100.Aguardar(const AMilisegundos: Cardinal): Boolean;
begin
  Result := not Parando and (FStopEvent.WaitFor(AMilisegundos) <> wrSignaled);
end;
procedure TWhatsAppMensagemService100.Executar;
begin
  Randomize;
  while not Parando do
  begin
    try
      ProcessarLote;
    except
      on E: Exception do
      begin
        FRecuperacaoExecutada := False;
        LogArquivo('Erro no processamento da fila: ' + E.Message);
      end;
    end;
    if not Aguardar(FConfig.IntervaloMs) then Break;
  end;
end;
function TWhatsAppMensagemService100.CriarConexao: TUniConnection;
begin
  Result := TUniConnection.Create(nil);
  try
    Result.ProviderName := FConfig.ProviderName;
    Result.Server       := FConfig.Server;
    Result.Port         := FConfig.Port;
    Result.Database     := FConfig.Database;
    Result.UserName     := FConfig.UserName;
    Result.Password     := FConfig.Password;
    Result.LoginPrompt  := False;
    Result.SpecificOptions.Values['charset'] := 'utf8mb4';
    Result.SpecificOptions.Values['Connectiontimeout'] := '30';
    Result.SpecificOptions.Values['UseUnicode'] := 'True';
    Result.Pooling := True;
    Result.PoolingOptions.MaxPoolSize := 50;
    Result.PoolingOptions.MinPoolSize := 2;
    Result.PoolingOptions.ConnectionLifetime := 30;
    Result.Open;
  except
    Result.Free;
    raise;
  end;
end;
function TWhatsAppMensagemService100.InicializarEvolution(AConn: TUniConnection): Boolean;
var
  Qry: TUniQuery;
  URL, APIKey: string;
begin
  //pegar a url e api ley do zap
  Result := Assigned(FEvolution);
  if Result then Exit;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := 'SELECT what_url as url, what_token FROM temp LIMIT 1';
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      URL    := Trim(Qry.FieldByName('url').AsString);
      APIKey := Trim(Qry.FieldByName('what_token').AsString);
    end;
  finally
    Qry.Free;
  end;
  if (URL = '') or (APIKey = '') then
  begin
    LogArquivo('Sistema sem URL ou API Key da Evolution configurada.');
    Exit(False);
  end;
  try
    FEvolution := TEvolutionAPI.Create(URL, APIKey);
    Result := True;
  except
    on E: Exception do
    begin
      Result := False;
      LogArquivo('Erro ao inicializar Evolution: ' + E.Message);
    end;
  end;
end;
procedure TWhatsAppMensagemService100.VerificarEstrutura(AConn: TUniConnection);
var
  Qry: TUniQuery;
  Coluna: string;
begin
  if FEstruturaVerificada then Exit;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT LOWER(column_name) AS column_name FROM information_schema.columns ' +
      'WHERE table_schema = DATABASE() AND table_name = ''mensagem_zap'' ' +
      'AND LOWER(column_name) IN (''tentativas'', ''proximo_envio'', ''processando_em'', ' +
      '''ultimo_erro'', ''message_id'')';
    Qry.Open;
    while not Qry.Eof do
    begin
      Coluna := LowerCase(Qry.FieldByName('column_name').AsString);
      if Coluna = 'tentativas' then FTemTentativas := True
      else if Coluna = 'proximo_envio' then FTemProximoEnvio := True
      else if Coluna = 'processando_em' then FTemProcessandoEm := True
      else if Coluna = 'ultimo_erro' then FTemUltimoErro := True
      else if Coluna = 'message_id' then FTemMessageID := True;
      Qry.Next;
    end;
    FEstruturaVerificada := True;
  finally
    Qry.Free;
  end;
end;
procedure TWhatsAppMensagemService100.RecuperarMensagensInterrompidas(AConn: TUniConnection);
var
  Qry: TUniQuery;
begin
  if FRecuperacaoExecutada and not FTemProcessandoEm then Exit;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    if FTemProcessandoEm then
      Qry.SQL.Text := 'UPDATE mensagem_zap SET status = ''PENDENTES'', processando_em = NULL ' +
        'WHERE status = ''REPROCESSAR'' AND (processando_em IS NULL OR processando_em < DATE_SUB(NOW(), INTERVAL 10 MINUTE))'
    else
      Qry.SQL.Text := 'UPDATE mensagem_zap SET status = ''PENDENTES'' WHERE status = ''P''';
    Qry.ExecSQL;
    if Qry.RowsAffected > 0 then
      LogArquivo(Format('%d mensagem(ns) interrompida(s) retornaram para a fila.', [Qry.RowsAffected]));
    FRecuperacaoExecutada := True;
  finally
    Qry.Free;
  end;
end;

procedure TWhatsAppMensagemService100.ProcessarLote;
var
  Conn: TUniConnection;
  Qry: TUniQuery;
  SQL: string;
begin
  Conn := nil;
  Qry  := nil;
  try
    Conn := CriarConexao;
    VerificarEstrutura(Conn);
    RecuperarMensagensInterrompidas(Conn);

    if not InicializarEvolution(Conn) then Exit;
    SQL := 'SELECT * FROM mensagem_zap WHERE status = ''PENDENTES''';
    //if FTemProximoEnvio then
    //SQL := SQL + ' AND (proximo_envio IS NULL OR proximo_envio <= NOW())';
    SQL := SQL + ' ORDER BY codigo LIMIT ' + IntToStr(FConfig.TamanhoLote);
    Qry             := TUniQuery.Create(nil);
    Qry.Connection  := Conn;
    Qry.SQL.Text    := SQL;
    Qry.Open;

    while not Qry.Eof do
    begin
      if Parando then Break;
//      if TentarMarcarProcessando(Conn, Qry.FieldByName('codigo').AsLargeInt) then
//      begin
//        try
//          ProcessarMensagem(Conn, Qry);
//        except
//          on E: Exception do
//          begin
//            LogArquivo(Format('Mensagem %d: erro não tratado: %s',
//              [Qry.FieldByName('codigo').AsLargeInt, E.Message]));
//            MarcarRetry(Conn, Qry.FieldByName('codigo').AsLargeInt,
//              CampoInteiro(Qry, 'tentativas') + 1, E.Message);
//          end;
//        end;
//      end;
        try
          ProcessarMensagem(Conn, Qry);
        except
          on E: Exception do
          begin
            LogArquivo(Format('Mensagem %d: erro não tratado: %s',
              [Qry.FieldByName('codigo').AsLargeInt, E.Message]));
            //MarcarRetry(Conn, Qry.FieldByName('codigo').AsLargeInt,
            //  CampoInteiro(Qry, 'tentativas') + 1, E.Message);
          end;
        end;
        Qry.Next;
    end;
  finally
    Qry.Free;
    Conn.Free;
  end;
end;

Function TWhatsAppMensagemService100.ObterInstanciaUsuario(out AInstancia :String; AIDnumero:string; AConn: TUniConnection):boolean;
var
  Qry       :TUniquery;
  sqlQuery  :string;
begin
  Result      := False;
  sqlQuery    := 'Select token from config_zap where fone= :fone';
  Qry         := TUniQuery.Create(nil);

  try
    try
      Qry.Connection    := AConn;
      Qry.Params.Clear;
      Qry.SQL.Text      := SqlQuery;
      Qry.Params.ParamByName('fone').AsString   := trim(AIDnumero);
      Qry.Open;

      if not Qry.IsEmpty then
      begin
        if qry.FieldByName('token').AsString <> '' then
        begin
          AInstancia  := qry.FieldByName('token').AsString;
          Result      := True;
        end
        else
        begin
          AInstancia  := '';
          Result      := False;
        end;
      end;

      Qry.Close;
    except
      on E: Exception do
      begin
        LogArquivo(Format('Erro buscar instancia - número informado: %s', [AIDnumero]));
        raise;
      end;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TWhatsAppMensagemService100.ProcessarMensagem(AConn: TUniConnection; AQry: TUniQuery);
var
  ID: Int64;
  Telefone, Numero, ErroNumero, NomePessoa, NomeInstancia, TipoMensagem: string;
  Conteudo, MessageID, Msg, Estado, Extensao, MediaType, CaminhoMidia, Base64Midia: string;
  Tentativa: Integer;
  Enviado: Boolean;
begin
  ID           := AQry.FieldByName('codigo').AsLargeInt;
  Telefone     := CampoTexto(AQry, 'fone');
  NomePessoa   := CampoTexto(AQry, 'nome');
  ObterInstanciaUsuario(NomeInstancia,AQry.FieldByName('idnumero').AsString, AConn);        //Trim(CampoTexto(AQry, 'nomeinstancia'));
  TipoMensagem := UpperCase(Trim(CampoTexto(AQry, 'ESTENSAO')));
  Tentativa    := CampoInteiro(AQry, 'tentativas') + 1;

  if Parando then
  begin
    LiberarParaFila(AConn, ID);
    Exit;
  end;

  if not NormalizarNumeroBR(Telefone, Numero, ErroNumero) then
  begin
    LogArquivo(Format('Mensagem %d: %s - número informado: %s', [ID, ErroNumero, Telefone]));
    LogBanco(AConn, ErroNumero, NomePessoa, Telefone);
    MarcarFalha(AConn, ID, ErroNumero);
    Exit;
  end;

  if NomeInstancia = '' then
  begin
    Msg := 'Mensagem sem instância de envio.';
    LogArquivo(Format('Mensagem %d: %s', [ID, Msg]));
    LogBanco(AConn, Msg, NomePessoa, Numero);
    MarcarSemInstancia(AConn, ID, Msg);
    Exit;
  end;

  if not FEvolution.InstanceConnectionState(NomeInstancia, Estado, Msg) then
  begin
    if Trim(Msg) = '' then Msg := 'Falha ao consultar o estado da instância.';
    LogArquivo(Format('Mensagem %d: %s', [ID, Msg]));
    MarcarRetry(AConn, ID, Tentativa, Msg);
    Exit;
  end;

  if not SameText(Estado, 'open') then
  begin
    Msg := 'Instância não conectada. Estado: ' + Estado;
    LogArquivo(Format('Mensagem %d: %s', [ID, Msg]));
    MarcarRetry(AConn, ID, Tentativa, Msg);
    Exit;
  end;
  if not AguardarLimites(Numero) then
  begin
    LiberarParaFila(AConn, ID);
    Exit;
  end;

  Enviado  := False;
  MessageID:= '';
  Msg      := '';
 

  if (AQry.FieldByName('estensao').AsString = 'pdf') or (AQry.FieldByName('estensao').AsString = '.pdf') or (AQry.FieldByName('estensao').AsString = '.PDF') then
  begin
    //Primeiro a mensagem
    Conteudo  :=
                          '📌 *Pedido/Orçamento*'                       +sLineBreak+
                          '📅 *Data/Hora:* '+FormatDateTime('dd/mm/yyyy', AQry.FieldByName('data').AsDateTime)+
                          ' - '+FormatDateTime('hh:mm', AQry.FieldByName('hora').AsDateTime)  +sLineBreak+
                          '🏢 *Empresa:* '+ AQry.FieldByName('empresa').AsString  +sLineBreak+

                          '👤 *Cliente:* '+AQry.FieldByName('nome').AsString           +sLineBreak+sLineBreak+sLineBreak+

                          AQry.FieldByName('mensagem_padrao').AsString              +sLineBreak+
                          AQry.FieldByName('nome').AsString                        +sLineBreak+sLineBreak+

                          '📌 Detalhes do pedido:'  +sLineBreak+
                          AQry.FieldByName('mensagem').AsString                   +sLineBreak+sLineBreak+
                          '🛒 *Vendedor:* '+AQry.FieldByName('vendedor').AsString;
    if Trim(Conteudo) = '' then
    begin
      //MarcarFalha(AConn, ID, 'Mensagem de texto vazia.');
      Exit;
    end;
    Enviado := FEvolution.SendText(NomeInstancia, Numero, Conteudo, MessageID, Msg, 1000, True);

    Extensao    := CampoTexto(AQry, 'ESTENSAO');
    Base64Midia := CampoTexto(AQry, 'ANEXO64');

    if Trim(Base64Midia) = '' then
    begin
      MarcarFalha(AConn, ID, 'Mídia sem conteúdo Base64.');
      Exit;
    end;
    MediaType         := InferirMediaType(Extensao);
    CaminhoMidia      := '';
    try
      CaminhoMidia    := TConeSul.SalvarBase64Temporario(Base64Midia, Extensao);
      if (CaminhoMidia = '') or not FileExists(CaminhoMidia) then
        raise Exception.Create('Não foi possível criar o arquivo temporário da mídia.');
      Enviado := FEvolution.SendMedia(NomeInstancia, Numero, CaminhoMidia, '', MessageID, Msg, MediaType);
    finally
      if (CaminhoMidia <> '') and FileExists(CaminhoMidia) then
      DeleteFile(CaminhoMidia);
    end;
  end
  else
  begin
    //MarcarFalha(AConn, ID, 'Tipo de mensagem desconhecido: ' + TipoMensagem);
    Exit;
  end;

  //RegistrarTentativaEnvio(Numero);

  if Enviado then
  begin
    MarcarEnviada(AConn, ID, MessageID);
    LogArquivo(Format('Mensagem %d enviada. MessageID: %s', [ID, MessageID]));
    LogBanco(AConn, 'Mensagem enviada - ' + MessageID, NomePessoa, Numero);
  end
  else
  begin
    if Trim(Msg) = '' then Msg := 'A Evolution não confirmou o envio.';
    LogArquivo(Format('Mensagem %d: falha no envio: %s', [ID, Msg]));
    LogBanco(AConn, 'Falha no envio: ' + Msg, NomePessoa, Numero);
    MarcarRetry(AConn, ID, Tentativa, Msg);
  end;

end;

function TWhatsAppMensagemService100.TentarMarcarProcessando(AConn: TUniConnection;
  const AID: Int64): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE mensagem_zap SET status = ''REPROCESSADA''';
    if FTemProcessandoEm then Qry.SQL.Add(', processando_em = NOW()');
    if FTemUltimoErro then Qry.SQL.Add(', ultimo_erro = NULL');
    Qry.SQL.Add('WHERE codigo = :id AND status = ''PENDENTES''');
    Qry.ParamByName('id').AsLargeInt := AID;
    Qry.ExecSQL;
    Result := Qry.RowsAffected = 1;
  finally
    Qry.Free;
  end;
end;

procedure TWhatsAppMensagemService100.MarcarEnviada(AConn: TUniConnection;
  const AID: Int64; const AMessageID: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE mensagem_zap SET status = ''ENVIADA''';
    //if FTemTentativas then Qry.SQL.Add(', tentativas = 0');
    //if FTemProximoEnvio then Qry.SQL.Add(', proximo_envio = NULL');
    //if FTemProcessandoEm then Qry.SQL.Add(', processando_em = NULL');
    //if FTemUltimoErro then Qry.SQL.Add(', ultimo_erro = NULL');
    //if FTemMessageID then Qry.SQL.Add(', message_id = :message_id');
    Qry.SQL.Add('WHERE codigo = :id');
    //if FTemMessageID then Qry.ParamByName('message_id').AsString := Copy(AMessageID, 1, 200);
    Qry.ParamByName('id').AsLargeInt := AID;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

procedure TWhatsAppMensagemService100.MarcarRetry(AConn: TUniConnection; const AID: Int64;
  const ATentativa: Integer; const AErro: string);
var
  Qry: TUniQuery;
  FalhaDefinitiva: Boolean;
begin
  FalhaDefinitiva := ATentativa >= FConfig.MaxTentativas;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE mensagem_zap SET status = :status';
    if FTemTentativas then Qry.SQL.Add(', tentativas = :tentativas');
    if FTemProximoEnvio then
    begin
      if FalhaDefinitiva then Qry.SQL.Add(', proximo_envio = NULL')
      else Qry.SQL.Add(', proximo_envio = :proximo_envio');
    end;
    if FTemProcessandoEm then Qry.SQL.Add(', processando_em = NULL');
    if FTemUltimoErro then Qry.SQL.Add(', ultimo_erro = :ultimo_erro');
    Qry.SQL.Add('WHERE codigo = :id');
    if FalhaDefinitiva then Qry.ParamByName('status').AsString := 'FALHA'
    else Qry.ParamByName('status').AsString := 'PENDENTES';
    if FTemTentativas then Qry.ParamByName('tentativas').AsInteger := ATentativa;
    if FTemProximoEnvio and not FalhaDefinitiva then
      Qry.ParamByName('proximo_envio').AsDateTime := CalcularProximoEnvio(ATentativa);
    if FTemUltimoErro then Qry.ParamByName('ultimo_erro').AsString := Copy(AErro, 1, 1000);
    Qry.ParamByName('id').AsLargeInt := AID;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;
procedure TWhatsAppMensagemService100.MarcarFalha(AConn: TUniConnection; const AID: Int64;
  const AErro: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE mensagem_zap SET status = ''FALHA''';
    if FTemTentativas then Qry.SQL.Add(', tentativas = :tentativas');
    if FTemProximoEnvio then Qry.SQL.Add(', proximo_envio = NULL');
    if FTemProcessandoEm then Qry.SQL.Add(', processando_em = NULL');
    if FTemUltimoErro then Qry.SQL.Add(', ultimo_erro = :ultimo_erro');
    Qry.SQL.Add('WHERE codigo = :id');
    if FTemTentativas then Qry.ParamByName('tentativas').AsInteger := FConfig.MaxTentativas;
    if FTemUltimoErro then Qry.ParamByName('ultimo_erro').AsString := Copy(AErro, 1, 1000);
    Qry.ParamByName('id').AsLargeInt := AID;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;
procedure TWhatsAppMensagemService100.MarcarSemInstancia(AConn: TUniConnection;
  const AID: Int64; const AErro: string);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE mensagem_zap SET status = ''TENTATIVA''';
    if FTemProcessandoEm then Qry.SQL.Add(', processando_em = NULL');
    if FTemUltimoErro then Qry.SQL.Add(', ultimo_erro = :ultimo_erro');
    Qry.SQL.Add('WHERE codigo = :id');
    if FTemUltimoErro then Qry.ParamByName('ultimo_erro').AsString := Copy(AErro, 1, 1000);
    Qry.ParamByName('id').AsLargeInt := AID;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

procedure TWhatsAppMensagemService100.LiberarParaFila(AConn: TUniConnection; const AID: Int64);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE mensagem_zap SET status = ''PENDENTES''';
    if FTemProcessandoEm then Qry.SQL.Add(', processando_em = NULL');
    Qry.SQL.Add('WHERE codigo = :id AND status = ''TENTATIVA''');
    Qry.ParamByName('id').AsLargeInt := AID;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

function TWhatsAppMensagemService100.CalcularProximoEnvio(const ATentativa: Integer): TDateTime;
var
  Expoente, BaseMs: Integer;
begin
  Expoente := Max(0, Min(ATentativa - 1, 4));
  BaseMs := 5000 * (1 shl Expoente);
  Result := IncMilliSecond(Now, BaseMs + Random(2000));
end;
function TWhatsAppMensagemService100.AguardarLimites(const ANumero: string): Boolean;
var
  UltimoEnvio: TDateTime;
  Restante: Integer;
begin
  Result := False;
  LimparCooldownsExpirados;
  if MilliSecondsBetween(Now, FInicioJanela) >= FConfig.JanelaMs then
  begin
    FInicioJanela := Now;
    FEnviosNaJanela := 0;
  end;
  if FEnviosNaJanela >= FConfig.LimitePorJanela then
  begin
    Restante := Max(0, FConfig.JanelaMs - MilliSecondsBetween(Now, FInicioJanela));
    if (Restante > 0) and not Aguardar(Restante) then Exit;
    FInicioJanela := Now;
    FEnviosNaJanela := 0;
  end;
  if FCooldowns.TryGetValue(ANumero, UltimoEnvio) then
  begin
    Restante := FConfig.CooldownNumeroMs - MilliSecondsBetween(Now, UltimoEnvio);
    if (Restante > 0) and not Aguardar(Restante) then Exit;
  end;
  if (FEnviosNaJanela > 0) and (FConfig.MaxDelayMs > 0) then
  begin
    Restante := FConfig.MinDelayMs + Random(FConfig.MaxDelayMs - FConfig.MinDelayMs + 1);
    if (Restante > 0) and not Aguardar(Restante) then Exit;
  end;
  Result := not Parando;
end;
procedure TWhatsAppMensagemService100.RegistrarTentativaEnvio(const ANumero: string);
begin
  Inc(FEnviosNaJanela);
  FCooldowns.AddOrSetValue(ANumero, Now);
end;
procedure TWhatsAppMensagemService100.LimparCooldownsExpirados;
var
  Remover: TList<string>;
  Item: TPair<string, TDateTime>;
  Numero: string;
begin
  if FCooldowns.Count = 0 then Exit;
  Remover := TList<string>.Create;
  try
    for Item in FCooldowns do
      if MilliSecondsBetween(Now, Item.Value) > FConfig.CooldownNumeroMs then Remover.Add(Item.Key);
    for Numero in Remover do FCooldowns.Remove(Numero);
  finally
    Remover.Free;
  end;
end;
function TWhatsAppMensagemService100.NormalizarNumeroBR(const AValor: string; out ANumero, AErro: string): Boolean;
var
  C: Char;
  Digitos, Valor: string;
begin
  Valor := StringReplace(Trim(AValor), '@c.us', '', [rfReplaceAll, rfIgnoreCase]);

  Digitos := '';
  for C in Valor do
    if CharInSet(C, ['0'..'9']) then Digitos := Digitos + C;

  if (Length(Digitos) in [12, 13]) and (Copy(Digitos, 1, 2) = '55') then
    ANumero := Digitos
  else if Length(Digitos) in [10, 11] then
    ANumero := '55' + Digitos
  else
  begin
    ANumero := '';
    AErro := 'Número do WhatsApp inválido. Informe DDD e telefone.';
    Exit(False);
  end;

  AErro := '';
  Result := True;
end;
function TWhatsAppMensagemService100.InferirMediaType(const AExtensao: string): string;
var
  Ext: string;
begin
  Ext := LowerCase(Trim(AExtensao));
  if (Ext <> '') and (Ext[1] <> '.') then Ext := '.' + Ext;
  if MatchText(Ext, ['.png', '.jpg', '.jpeg', '.jfif', '.gif', '.webp']) then Exit('image');
  if MatchText(Ext, ['.mp4', '.webm', '.mov']) then Exit('video');
  if MatchText(Ext, ['.mp3', '.ogg', '.wav', '.m4a', '.aac', '.opus']) then Exit('audio');
  Result := 'document';
end;
function TWhatsAppMensagemService100.CampoTexto(AQry: TDataSet; const ACampo: string): string;
var
  Campo: TField;
begin
  Campo := AQry.FindField(ACampo);
  if Assigned(Campo) and not Campo.IsNull then Result := Campo.AsString else Result := '';
end;
function TWhatsAppMensagemService100.CampoInteiro(AQry: TDataSet; const ACampo: string;
  const ADefault: Integer): Integer;
var
  Campo: TField;
begin
  Campo := AQry.FindField(ACampo);
  if Assigned(Campo) and not Campo.IsNull then Result := Campo.AsInteger else Result := ADefault;
end;
procedure TWhatsAppMensagemService100.LogArquivo(const AMensagem: string);
var
  Arquivo: TextFile;
begin
  FLogLock.Acquire;
  try
    try
      if ExtractFilePath(FConfig.CaminhoLog) <> '' then ForceDirectories(ExtractFilePath(FConfig.CaminhoLog));
      AssignFile(Arquivo, FConfig.CaminhoLog);
      if FileExists(FConfig.CaminhoLog) then Append(Arquivo) else Rewrite(Arquivo);
      try
        Writeln(Arquivo, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + AMensagem);
      finally
        CloseFile(Arquivo);
      end;
    except
      { O serviço não deve parar se o arquivo de log estiver indisponível. }
    end;
  finally
    FLogLock.Release;
  end;
end;
procedure TWhatsAppMensagemService100.LogBanco(AConn: TUniConnection; const AMensagem,
  APara, AFone: string; const AIDUsuario: Integer);
var
  Qry: TUniQuery;
begin
  if not FConfig.GravarLogBanco then Exit;
  Qry := TUniQuery.Create(nil);
  try
    try
      Qry.Connection := AConn;
      Qry.SQL.Text := 'INSERT INTO log_mensagem(data, hora, id_usuario, descricao, para, fone) ' +
        'VALUES (:data, :hora, :id_usuario, :descricao, :para, :fone)';
      Qry.ParamByName('data').AsDate := Date;
      Qry.ParamByName('hora').AsTime := Time;
      Qry.ParamByName('id_usuario').AsInteger := AIDUsuario;
      Qry.ParamByName('descricao').AsString := AMensagem;
      Qry.ParamByName('para').AsString := APara;
      Qry.ParamByName('fone').AsString := AFone;
      Qry.ExecSQL;
    except
      on E: Exception do LogArquivo('Erro ao gravar log no banco: ' + E.Message);
    end;
  finally
    Qry.Free;
  end;
end;
end.
