unit uEleicaoSincronizacaoService;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.IOUtils,
  Data.DB, DBAccess, Uni,
  Controllers.Empresa,
  Controllers.associado,
  Controllers.Eleicao,
  Controllers.EleicaoConfig,
  Controllers.EleicaoChapa,
  Controllers.EleicaoMembro,
  Controllers.UsuarioSistema,
  Controllers.EleicaoQuestao;

type
  TEleicaoSincronizacaoConfig = record
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
      const AIntervaloMs: Cardinal): TEleicaoSincronizacaoConfig; static;
  end;

  TEleicaoSincronizacaoService = class
  private
    FConfig: TEleicaoSincronizacaoConfig;
    FThread: TThread;
    FStopEvent: TEvent;
    FLogLock: TCriticalSection;
    function CriarConexao: TUniConnection;
    function Parando: Boolean;
    function Aguardar(const AMilisegundos: Cardinal): Boolean;
    function ExisteEmpresaPendente(AConn: TUniConnection): Boolean;
    function ProcessarEmpresasPendentes(AConn: TUniConnection): Boolean;
    function ProcessarRegistro(AConn: TUniConnection; AQry: TUniQuery): Boolean;
    function ExecutarController(AConn: TUniConnection; const ACodigoTabela,
      AIDRegistro: Integer): Boolean;
    function NomeProcesso(const ACodigoTabela: Integer): string;
    procedure Executar;
    procedure ProcessarLote;
    procedure ProcessarEleicao(AConn: TUniConnection);
    procedure MarcarConcluido(AConn: TUniConnection; const AIDSincronizar: Int64);
    procedure LogArquivo(const AMensagem: string);
  public
    constructor Create(const AConfig: TEleicaoSincronizacaoConfig);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Executando: Boolean;
  end;

implementation

const
  C_CODIGO_EMPRESA          = 19;
  C_CODIGO_ASSOCIADO        = 4;
  C_CODIGO_USUARIO_SISTEMA  = 15;
  C_CODIGO_ELEICAO          = 100;
  C_CODIGO_ELEICAO_CONFIG   = 101;
  C_CODIGO_ELEICAO_CHAPA    = 102;
  C_CODIGO_ELEICAO_MEMBROS  = 103;
  C_CODIGO_USUARIO_APTO     = 104;
  C_CODIGO_ELEICAO_COMISSAO = 105;
  C_CODIGO_ELEICAO_QUESTAO  = 106;
  C_CODIGO_ELEICAO_QUESTAOOPCAO  = 107;
  C_CODIGOS_ELEICAO         = '4,15,100,101,102,103,104,105,106,107';

type
  TEleicaoWorkerThread = class(TThread)
  private
    FOwner: TEleicaoSincronizacaoService;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TEleicaoSincronizacaoService);
  end;

{ TEleicaoSincronizacaoConfig }

class function TEleicaoSincronizacaoConfig.Criar(const AConn: TUniConnection;
  const AIntervaloMs: Cardinal): TEleicaoSincronizacaoConfig;
begin
  Result.ProviderName := AConn.ProviderName;
  Result.Server       := AConn.Server;
  Result.Port         := AConn.Port;
  Result.Database     := AConn.Database;
  Result.UserName     := AConn.UserName;
  Result.Password     := AConn.Password;
  Result.IntervaloMs  := AIntervaloMs;
  Result.TamanhoLote  := 5;
  Result.CaminhoLog   := TPath.Combine(ExtractFilePath(ParamStr(0)),
    'LogSincronizarAPIEleicao.txt');
end;

{ TEleicaoWorkerThread }

constructor TEleicaoWorkerThread.Create(AOwner: TEleicaoSincronizacaoService);
begin
  inherited Create(True);
  FOwner := AOwner;
  FreeOnTerminate := False;
end;

procedure TEleicaoWorkerThread.Execute;
begin
  FOwner.Executar;
end;

{ TEleicaoSincronizacaoService }

constructor TEleicaoSincronizacaoService.Create(
  const AConfig: TEleicaoSincronizacaoConfig);
begin
  inherited Create;
  FConfig := AConfig;
  if FConfig.IntervaloMs < 1000 then FConfig.IntervaloMs := 10000;
  if FConfig.TamanhoLote <= 0 then FConfig.TamanhoLote := 5;
  if Trim(FConfig.CaminhoLog) = '' then
    FConfig.CaminhoLog := TPath.Combine(ExtractFilePath(ParamStr(0)),
      'LogSincronizarAPIEleicao.txt');

  FStopEvent := TEvent.Create(nil, True, False, '');
  FLogLock   := TCriticalSection.Create;
end;

destructor TEleicaoSincronizacaoService.Destroy;
begin
  Stop;
  FreeAndNil(FLogLock);
  FreeAndNil(FStopEvent);
  inherited;
end;

procedure TEleicaoSincronizacaoService.Start;
begin
  if Assigned(FThread) then Exit;
  FStopEvent.ResetEvent;
  FThread := TEleicaoWorkerThread.Create(Self);
  FThread.Start;
  LogArquivo('Serviço de sincronização da eleição iniciado.');
end;

procedure TEleicaoSincronizacaoService.Stop;
begin
  if not Assigned(FThread) then Exit;
  FStopEvent.SetEvent;
  FThread.Terminate;
  FThread.WaitFor;
  FreeAndNil(FThread);
  LogArquivo('Serviço de sincronização da eleição finalizado.');
end;

function TEleicaoSincronizacaoService.Executando: Boolean;
begin
  Result := Assigned(FThread) and not Parando;
end;

function TEleicaoSincronizacaoService.Parando: Boolean;
begin
  Result := Assigned(FStopEvent) and (FStopEvent.WaitFor(0) = wrSignaled);
end;

function TEleicaoSincronizacaoService.Aguardar(
  const AMilisegundos: Cardinal): Boolean;
begin
  Result := not Parando and (FStopEvent.WaitFor(AMilisegundos) <> wrSignaled);
end;

procedure TEleicaoSincronizacaoService.Executar;
begin
  while not Parando do
  begin
    try
      ProcessarLote;
    except
      on E: Exception do
        LogArquivo('Erro no processamento da eleição: ' + E.Message);
    end;

    if not Aguardar(FConfig.IntervaloMs) then Break;
  end;
end;

function TEleicaoSincronizacaoService.CriarConexao: TUniConnection;
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

procedure TEleicaoSincronizacaoService.ProcessarLote;
var
  Conn: TUniConnection;
begin
  Conn := nil;
  try
    Conn := CriarConexao;

    if not ProcessarEmpresasPendentes(Conn) then
    begin
      LogArquivo('Sincronização eleitoral aguardando o envio da empresa.');
      Exit;
    end;

    if not Parando then ProcessarEleicao(Conn);
  finally
    Conn.Free;
  end;
end;

function TEleicaoSincronizacaoService.ProcessarEmpresasPendentes(
  AConn: TUniConnection): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id_sincronizar, cod_tabela, status, id_registro ' +
      'FROM sincronizar WHERE status = ''S'' AND cod_tabela = ' +
      IntToStr(C_CODIGO_EMPRESA) + ' ORDER BY id_sincronizar LIMIT ' +
      IntToStr(FConfig.TamanhoLote);
    Qry.Open;

    while not Qry.Eof do
    begin
      if Parando then Break;
      ProcessarRegistro(AConn, Qry);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;

  Result := not Parando and not ExisteEmpresaPendente(AConn);
end;

function TEleicaoSincronizacaoService.ExisteEmpresaPendente(
                                                AConn: TUniConnection): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS quantidade FROM sincronizar ' +
      'WHERE status = ''S'' AND cod_tabela = ' + IntToStr(C_CODIGO_EMPRESA);
    Qry.Open;
    Result := Qry.FieldByName('quantidade').AsInteger > 0;
  finally
    Qry.Free;
  end;
end;

procedure TEleicaoSincronizacaoService.ProcessarEleicao(AConn: TUniConnection);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT id_sincronizar, cod_tabela, status, id_registro ' +
      'FROM sincronizar WHERE status = ''S'' AND cod_tabela IN (' +
      C_CODIGOS_ELEICAO + ') ' +
      'ORDER BY FIELD(cod_tabela,4,15,100,101,102,103,104,105,106,107), id_sincronizar LIMIT ' +
      IntToStr(FConfig.TamanhoLote);
    Qry.Open;

    while not Qry.Eof do
    begin
      if Parando then Break;
      ProcessarRegistro(AConn, Qry);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

function TEleicaoSincronizacaoService.ProcessarRegistro(AConn: TUniConnection;
  AQry: TUniQuery): Boolean;
var
  IDSincronizar: Int64;
  CodigoTabela, IDRegistro: Integer;
  Processo: string;
begin
  Result         := False;
  IDSincronizar  := AQry.FieldByName('id_sincronizar').AsLargeInt;
  CodigoTabela   := AQry.FieldByName('cod_tabela').AsInteger;
  IDRegistro     := 0;
  if not AQry.FieldByName('id_registro').IsNull then
    IDRegistro := AQry.FieldByName('id_registro').AsInteger;
  Processo := NomeProcesso(CodigoTabela);

  try
    LogArquivo(Format('Sincronização %d iniciada. código: %d - %s. Registro: %d.',
      [IDSincronizar, CodigoTabela, Processo, IDRegistro]));

    if CodigoTabela = 22 then
    begin
      LogArquivo(Format('Sincronização %d aguardando implementação do controller: %s.',
        [IDSincronizar, Processo]));
      Exit;
    end;

    if not ExecutarController(AConn, CodigoTabela, IDRegistro) then
    begin
      LogArquivo(Format('Sincronização %d não concluida e continuara com status S: %s.',
        [IDSincronizar, Processo]));
      Exit;
    end;

    MarcarConcluido(AConn, IDSincronizar);
    LogArquivo(Format('Sincronização %d concluida: %s.',
      [IDSincronizar, Processo]));
    Result := True;
  except
    on E: Exception do
      LogArquivo(Format('Sincronização %d com erro em %s: %s',
        [IDSincronizar, Processo, E.Message]));
  end;
end;

function TEleicaoSincronizacaoService.ExecutarController(AConn: TUniConnection;
  const ACodigoTabela, AIDRegistro: Integer): Boolean;
var
  AErro   : String;
begin
  Result  := False;
  AErro   := '';

  case ACodigoTabela of
    C_CODIGO_EMPRESA        : Result := TControllersEmpresa.SincronizarEmpresa(AConn,AIDRegistro,AErro);
    C_CODIGO_ASSOCIADO      : Result := TControllersAssociado.SincronizarAssociado(AConn,AIDRegistro,AErro);
    C_CODIGO_ELEICAO        : Result := TControllersEleicao.SincronizarEleicao(AConn,AIDRegistro,AErro);
    C_CODIGO_ELEICAO_CONFIG : Result := TControllersEleicaoConfig.Sincronizar(AConn,AIDRegistro,AErro);
    C_CODIGO_ELEICAO_CHAPA  : Result := TControllersEleicaoChapa.Sincronizar(AConn,AIDRegistro,AErro);
    C_CODIGO_ELEICAO_MEMBROS: Result := TControllersEleicaoMembro.Sincronizar(AConn,AIDRegistro,AErro);
    C_CODIGO_USUARIO_SISTEMA: Result := TControllersUsuarioSistema.Sincronizar(AConn,AIDRegistro,AErro);
    C_CODIGO_USUARIO_APTO   : Result := TControllersUsuarioSistema.SincronizarAptos(AConn,AIDRegistro,AErro);
    C_CODIGO_ELEICAO_COMISSAO: Result := TControllersUsuarioSistema.SincronizarComissao(AConn,AIDRegistro,AErro);
    C_CODIGO_ELEICAO_QUESTAO : Result := TControllersEleicaoQuestao.SincronizarEleicaoQuestao(AConn,AIDRegistro,AErro);
    C_CODIGO_ELEICAO_QUESTAOOPCAO : Result := TControllersEleicaoQuestao.SincronizarEleicaoQuestaoOpcao(AConn,AIDRegistro,AErro);
  else
    Exit(False);
  end;
  if (not Result) and (Trim(AErro) <> '') then
    raise Exception.Create(AErro);

end;

function TEleicaoSincronizacaoService.NomeProcesso(const ACodigoTabela: Integer): string;
begin
  case ACodigoTabela of
    19  : Result  := 'Empresa Sincronizado';
    4   : Result  := 'Associado Sincronizado';
    15  : Result  := 'Úsuário Sistema Sincronizado';
    100 : Result  := 'Eleicao Sincronizado';
    101 : Result  := 'Eleição Configuração Sincronizado';
    102 : Result  := 'Eleicao Chapa Sincronizado';
    103 : Result  := 'Eleição Chapa Membros Sincronizado';
    104 : Result  := 'Eleição Usuário APTO Sincronizado';
    105 : Result  := 'Eleição Comissão Sincronizado';
    106 : Result  := 'Eleição Questão Sincronizado';
    107 : Result  := 'Eleição Questão Opção Sincronizado';
  else
    Result := 'Código não reconhecido';
  end;
end;

procedure TEleicaoSincronizacaoService.MarcarConcluido(AConn: TUniConnection;
  const AIDSincronizar: Int64);
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
      raise Exception.CreateFmt('Não foi possivel concluir a sincronização %d.',
        [AIDSincronizar]);
  finally
    Qry.Free;
  end;
end;

procedure TEleicaoSincronizacaoService.LogArquivo(const AMensagem: string);
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
        Writeln(Arquivo, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) +
          ' - ' + AMensagem);
      finally
        CloseFile(Arquivo);
      end;
    except

    end;
  finally
    FLogLock.Release;
  end;
end;

end.
