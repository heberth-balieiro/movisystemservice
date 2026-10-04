unit uCarteiraSincronizacaoService;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.IOUtils,
  Data.DB, DBAccess, Uni,
  Controllers.Carteira, Controllers.Garagem, Controllers.Empresa,
  Controllers.Associado;

type
  TCarteiraSincronizacaoConfig = record
    ProviderName: string;
    Server: string;
    Port: Integer;
    Database: string;
    UserName: string;
    Password: string;
    IntervaloMs: Cardinal;
    TamanhoLote: Integer;
    CaminhoLog: string;
    class function Criar(const AConn: TUniConnection;
      const AIntervaloMs: Cardinal): TCarteiraSincronizacaoConfig; static;
  end;

  TCarteiraSincronizacaoService = class
  private
    FConfig: TCarteiraSincronizacaoConfig;
    FThread: TThread;
    FStopEvent: TEvent;
    FLogLock: TCriticalSection;
    function CriarConexao: TUniConnection;
    function Parando: Boolean;
    function Aguardar(const AMilisegundos: Cardinal): Boolean;
    procedure Executar;
    procedure ProcessarLote;
    procedure ProcessarRegistro(AConn: TUniConnection; AQry: TUniQuery);
    procedure MarcarConcluido(AConn: TUniConnection; const AIDSincronizar: Int64);
    function ExecutarController(AConn: TUniConnection; const ACodigoTabela,
      AIDRegistro: Integer): Boolean;
    function ConcluirQuandoRetornarFalse(const ACodigoTabela: Integer): Boolean;
    function NomeProcesso(const ACodigoTabela: Integer): string;
    procedure LogArquivo(const AMensagem: string);
  public
    constructor Create(const AConfig: TCarteiraSincronizacaoConfig);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Executando: Boolean;
  end;

implementation

const
  // Códigos usados pela carteira em produção. Eleição: 8, 9, 10, 11, 12 e 22.
  C_CODIGOS_CARTEIRA = '1,2,3,4,5,6,7,14,15,16,17,19,20';

type
  TCarteiraWorkerThread = class(TThread)
  private
    FOwner: TCarteiraSincronizacaoService;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TCarteiraSincronizacaoService);
  end;

{ TCarteiraSincronizacaoConfig }

class function TCarteiraSincronizacaoConfig.Criar(const AConn: TUniConnection;
  const AIntervaloMs: Cardinal): TCarteiraSincronizacaoConfig;
begin
  Result.ProviderName := AConn.ProviderName;
  Result.Server       := AConn.Server;
  Result.Port         := AConn.Port;
  Result.Database     := AConn.Database;
  Result.UserName     := AConn.UserName;
  Result.Password     := AConn.Password;
  Result.IntervaloMs  := AIntervaloMs;
  Result.TamanhoLote  := 5;
  Result.CaminhoLog   := TPath.Combine(ExtractFilePath(ParamStr(0)),'LogSincronizarAPI.txt');
end;

{ TCarteiraWorkerThread }

constructor TCarteiraWorkerThread.Create(AOwner: TCarteiraSincronizacaoService);
begin
  inherited Create(True);
  FOwner := AOwner;
  FreeOnTerminate := False;
end;

procedure TCarteiraWorkerThread.Execute;
begin
  FOwner.Executar;
end;

{ TCarteiraSincronizacaoService }

constructor TCarteiraSincronizacaoService.Create(const AConfig: TCarteiraSincronizacaoConfig);
begin
  inherited Create;
  FConfig := AConfig;
  if FConfig.IntervaloMs < 1000 then FConfig.IntervaloMs := 10000;
  if FConfig.TamanhoLote <= 0 then FConfig.TamanhoLote := 5;
  if Trim(FConfig.CaminhoLog) = '' then
    FConfig.CaminhoLog := TPath.Combine(ExtractFilePath(ParamStr(0)),'LogSincronizarAPI.txt');

  FStopEvent := TEvent.Create(nil, True, False, '');
  FLogLock   := TCriticalSection.Create;
end;

destructor TCarteiraSincronizacaoService.Destroy;
begin
  Stop;
  FreeAndNil(FLogLock);
  FreeAndNil(FStopEvent);
  inherited;
end;

procedure TCarteiraSincronizacaoService.Start;
begin
  if Assigned(FThread) then Exit;
  FStopEvent.ResetEvent;
  FThread := TCarteiraWorkerThread.Create(Self);
  FThread.Start;
  LogArquivo('Serviço de sincronização da carteira iniciado.');
end;

procedure TCarteiraSincronizacaoService.Stop;
begin
  if not Assigned(FThread) then Exit;
  FStopEvent.SetEvent;
  FThread.Terminate;
  FThread.WaitFor;
  FreeAndNil(FThread);
  LogArquivo('Serviço de sincronização da carteira finalizado.');
end;

function TCarteiraSincronizacaoService.Executando: Boolean;
begin
  Result := Assigned(FThread) and not Parando;
end;

function TCarteiraSincronizacaoService.Parando: Boolean;
begin
  Result := Assigned(FStopEvent) and (FStopEvent.WaitFor(0) = wrSignaled);
end;

function TCarteiraSincronizacaoService.Aguardar(const AMilisegundos: Cardinal): Boolean;
begin
  Result := not Parando and (FStopEvent.WaitFor(AMilisegundos) <> wrSignaled);
end;

procedure TCarteiraSincronizacaoService.Executar;
begin
  while not Parando do
  begin
    try
      ProcessarLote;
    except
      on E: Exception do
        LogArquivo('Erro no processamento da carteira: ' + E.Message);
    end;

    if not Aguardar(FConfig.IntervaloMs) then Break;
  end;
end;

function TCarteiraSincronizacaoService.CriarConexao: TUniConnection;
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
    Result.AutoCommit   := True;
    Result.SpecificOptions.Values['charset'] := 'utf8mb4';
    Result.SpecificOptions.Values['Connectiontimeout'] := '30';
    Result.SpecificOptions.Values['UseUnicode'] := 'True';
    Result.Pooling := True;
    Result.PoolingOptions.MaxPoolSize         := 50;
    Result.PoolingOptions.MinPoolSize         := 2;
    Result.PoolingOptions.ConnectionLifetime  := 30;
    Result.Open;
  except
    Result.Free;
    raise;
  end;
end;

procedure TCarteiraSincronizacaoService.ProcessarLote;
var
  Conn: TUniConnection;
  Qry: TUniQuery;
begin
  Conn := nil;
  Qry  := nil;
  try
    Conn := CriarConexao;
    Qry  := TUniQuery.Create(nil);
    Qry.Connection := Conn;
    Qry.SQL.Text :=
      'SELECT id_sincronizar, cod_tabela, status, id_registro ' +
      'FROM sincronizar WHERE status = ''S'' ' +
      'AND cod_tabela IN (' + C_CODIGOS_CARTEIRA + ') ' +
      'ORDER BY id_sincronizar LIMIT ' + IntToStr(FConfig.TamanhoLote);
    Qry.Open;

    while not Qry.Eof do
    begin
      if Parando then Break;
      ProcessarRegistro(Conn, Qry);
      Qry.Next;
    end;
  finally
    Qry.Free;
    Conn.Free;
  end;
end;

procedure TCarteiraSincronizacaoService.ProcessarRegistro(AConn: TUniConnection;
  AQry: TUniQuery);
var
  IDSincronizar: Int64;
  CodigoTabela, IDRegistro: Integer;
  Sucesso: Boolean;
  Processo: string;
begin
  IDSincronizar := AQry.FieldByName('id_sincronizar').AsLargeInt;
  CodigoTabela  := AQry.FieldByName('cod_tabela').AsInteger;
  IDRegistro    := 0;
  if not AQry.FieldByName('id_registro').IsNull then
    IDRegistro  := AQry.FieldByName('id_registro').AsInteger;
  Processo      := NomeProcesso(CodigoTabela);

  try
    LogArquivo(Format('Sincronização %d iniciada. Código: %d - %s. Registro: %d.',
      [IDSincronizar, CodigoTabela, Processo, IDRegistro]));

    Sucesso := ExecutarController(AConn, CodigoTabela, IDRegistro);

    if Sucesso then
    begin
      MarcarConcluido(AConn, IDSincronizar);
      LogArquivo(Format('Sincronização %d concluída: %s.',
        [IDSincronizar, Processo]));
    end
    else if ConcluirQuandoRetornarFalse(CodigoTabela) then
    begin
      // Preserva a regra antiga: alguns controllers retornam False quando não há itens.
      MarcarConcluido(AConn, IDSincronizar);
      LogArquivo(Format('Sincronização %d finalizada sem registros: %s.',
        [IDSincronizar, Processo]));
    end
    else
      LogArquivo(Format('Sincronização %d não concluída e continuará com status S: %s.',
        [IDSincronizar, Processo]));
  except
    on E: Exception do
      LogArquivo(Format('Sincronização %d com erro em %s: %s',
        [IDSincronizar, Processo, E.Message]));
  end;
end;

function TCarteiraSincronizacaoService.ExecutarController(AConn: TUniConnection;
  const ACodigoTabela, AIDRegistro: Integer): Boolean;
var
  Carteira: TControllersCarteira;
  Garagem : TControllersGaragem;
  AErro   : String;
begin
  Result   := False;
  Carteira := nil;
  Garagem  := nil;

  case ACodigoTabela of
    1..3, 5..7, 14..17:
      begin
        Carteira := TControllersCarteira.Create(AConn);
        try
          case ACodigoTabela of
            1:  Result := Carteira.SincronizarSecretaria;
            2:  Result := Carteira.SincronizarLotacao;
            3:  Result := Carteira.SincronizarProfissao;
            5:  Result := Carteira.SincronizarDependentes;
            6:  Result := Carteira.SincronizarCarteira;
            7:  Result := Carteira.SincronizarConvenio;
            14: Result := Carteira.SincronizarNotificacao;
            15: Result := Carteira.SincronizarUsuario;
            16: Result := Carteira.SincronizarAutorizacao(AIDRegistro);
            17: Result := Carteira.SincronizarRegEntrada;
          end;
        finally
          Carteira.Free;
        end;
      end;

    4: Result   := TControllersAssociado.SincronizarAssociado(AConn, AIDRegistro, AErro); //carteira
//    19: Result  := TControllersEmpresa.SincronizarEmpresa(AConn, AIDRegistro);
//
//    20:
//      begin
//        Garagem := TControllersGaragem.Create(AConn);
//        try
//          Result := Garagem.SincronizarVeiculo;
//        finally
//          Garagem.Free;
//        end;
//      end;
  end;
end;

function TCarteiraSincronizacaoService.ConcluirQuandoRetornarFalse(const ACodigoTabela: Integer): Boolean;
begin
  // Na implementação anterior apenas Profissão, Associado e Empresa voltavam para S.
  Result := not (ACodigoTabela in [3, 4]);
end;

function TCarteiraSincronizacaoService.NomeProcesso(const ACodigoTabela: Integer): string;
begin
  case ACodigoTabela of
    1:  Result := 'Secretaria';
    2:  Result := 'Lotação';
    3:  Result := 'Profissão';
    4:  Result := 'Associado';
    5:  Result := 'Dependentes';
    6:  Result := 'Carteira';
    7:  Result := 'Convênio';
    14: Result := 'Notificação';
    15: Result := 'Usuário';
    16: Result := 'Autorização';
    17: Result := 'Registro de entrada';
    19: Result := 'Empresa';
    //20: Result := 'Veículo';
  else
    Result := 'Código não reconhecido';
  end;
end;

procedure TCarteiraSincronizacaoService.MarcarConcluido(AConn: TUniConnection; const AIDSincronizar: Int64);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'UPDATE sincronizar SET status = ''C'' ' +
      'WHERE id_sincronizar = :id AND status = ''S''';
    Qry.ParamByName('id').AsLargeInt := AIDSincronizar;
    Qry.ExecSQL;
    if Qry.RowsAffected <> 1 then
      raise Exception.CreateFmt('Não foi possível concluir a sincronização %d.',
        [AIDSincronizar]);
  finally
    Qry.Free;
  end;
end;

procedure TCarteiraSincronizacaoService.LogArquivo(const AMensagem: string);
var
  Arquivo: TextFile;
begin
  FLogLock.Acquire;
  try
    try
      if ExtractFilePath(FConfig.CaminhoLog) <> '' then
        ForceDirectories(ExtractFilePath(FConfig.CaminhoLog));
      AssignFile(Arquivo, FConfig.CaminhoLog);
      if FileExists(FConfig.CaminhoLog) then Append(Arquivo) else Rewrite(Arquivo);
      try
        Writeln(Arquivo, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + AMensagem);
      finally
        CloseFile(Arquivo);
      end;
    except
      { Falha no arquivo de log não pode derrubar o worker. }
    end;
  finally
    FLogLock.Release;
  end;
end;

end.
