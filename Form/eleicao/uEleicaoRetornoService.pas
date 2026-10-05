unit uEleicaoRetornoService;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.IOUtils,
  DBAccess, Uni,
  Controllers.EleicaoRetorno;

type
  TEleicaoRetornoConfig = record
    ProviderName: string;
    Server: string;
    Port: Integer;
    Database: string;
    UserName: string;
    Password: string;
    IntervaloMs: Cardinal;
    CaminhoLog: string;
    class function Criar(const AConn: TUniConnection;
      const AIntervaloMs: Cardinal): TEleicaoRetornoConfig; static;
  end;

  TEleicaoRetornoService = class
  private
    FConfig: TEleicaoRetornoConfig;
    FThread: TThread;
    FStopEvent: TEvent;
    FLogLock: TCriticalSection;

    function CriarConexao: TUniConnection;
    function Parando: Boolean;
    function Aguardar(const AMilisegundos: Cardinal): Boolean;

    procedure Executar;
    procedure ProcessarRetorno;
    procedure LogArquivo(const AMensagem: string);

  public
    constructor Create(const AConfig: TEleicaoRetornoConfig);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;
    function Executando: Boolean;
  end;

implementation

uses
  Service.AtualizacaoCadastral;

type
  TEleicaoRetornoWorkerThread = class(TThread)
  private
    FOwner: TEleicaoRetornoService;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TEleicaoRetornoService);
  end;

{ TEleicaoRetornoConfig }

class function TEleicaoRetornoConfig.Criar(
  const AConn: TUniConnection;
  const AIntervaloMs: Cardinal): TEleicaoRetornoConfig;
begin
  Result.ProviderName := AConn.ProviderName;
  Result.Server       := AConn.Server;
  Result.Port         := AConn.Port;
  Result.Database     := AConn.Database;
  Result.UserName     := AConn.UserName;
  Result.Password     := AConn.Password;
  Result.IntervaloMs  := AIntervaloMs;

  Result.CaminhoLog :=
    TPath.Combine(
      ExtractFilePath(ParamStr(0)),
      'LogRetornoAPIEleicao.txt'
    );
end;

{ TEleicaoRetornoWorkerThread }

constructor TEleicaoRetornoWorkerThread.Create(
  AOwner: TEleicaoRetornoService);
begin
  inherited Create(True);
  FOwner := AOwner;
  FreeOnTerminate := False;
end;

procedure TEleicaoRetornoWorkerThread.Execute;
begin
  FOwner.Executar;
end;

{ TEleicaoRetornoService }

constructor TEleicaoRetornoService.Create(const AConfig: TEleicaoRetornoConfig);
begin
  inherited Create;

  FConfig := AConfig;

  if FConfig.IntervaloMs < 1000 then
    FConfig.IntervaloMs := 10000;

  if Trim(FConfig.CaminhoLog) = '' then
    FConfig.CaminhoLog :=
      TPath.Combine(
        ExtractFilePath(ParamStr(0)),
        'LogRetornoAPIEleicao.txt'
      );

  FStopEvent := TEvent.Create(nil,True,False,'');
  FLogLock   := TCriticalSection.Create;
end;

destructor TEleicaoRetornoService.Destroy;
begin
  Stop;

  FreeAndNil(FLogLock);
  FreeAndNil(FStopEvent);

  inherited;
end;

procedure TEleicaoRetornoService.Start;
begin
  if Assigned(FThread) then
    Exit;

  FStopEvent.ResetEvent;

  FThread := TEleicaoRetornoWorkerThread.Create(Self);
  FThread.Start;

  LogArquivo('Serviço de retorno da eleição iniciado.');
end;

procedure TEleicaoRetornoService.Stop;
begin
  if not Assigned(FThread) then
    Exit;

  FStopEvent.SetEvent;
  FThread.Terminate;
  FThread.WaitFor;

  FreeAndNil(FThread);

  LogArquivo('Serviço de retorno da eleição finalizado.');
end;

function TEleicaoRetornoService.Executando: Boolean;
begin
  Result := Assigned(FThread) and not Parando;
end;

function TEleicaoRetornoService.Parando: Boolean;
begin
  Result :=
    Assigned(FStopEvent) and
    (FStopEvent.WaitFor(0) = wrSignaled);
end;

function TEleicaoRetornoService.Aguardar(const AMilisegundos: Cardinal): Boolean;
begin
  Result :=
    not Parando and
    (FStopEvent.WaitFor(AMilisegundos) <> wrSignaled);
end;

function TEleicaoRetornoService.CriarConexao: TUniConnection;
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

    Result.AutoCommit := True;

    Result.SpecificOptions.Values['charset'] := 'utf8mb4';
    Result.SpecificOptions.Values['Connectiontimeout'] := '30';
    Result.SpecificOptions.Values['UseUnicode'] := 'True';

    Result.Pooling := True;
    Result.PoolingOptions.MaxPoolSize        := 50;
    Result.PoolingOptions.MinPoolSize        := 2;
    Result.PoolingOptions.ConnectionLifetime := 30;

    Result.Open;

  except
    Result.Free;
    raise;
  end;
end;

procedure TEleicaoRetornoService.Executar;
begin
  while not Parando do
  begin
    try
      ProcessarRetorno;
    except
      on E: Exception do
        LogArquivo('Erro no retorno da eleição: ' + E.Message);
    end;

    if not Aguardar(FConfig.IntervaloMs) then
      Break;
  end;
end;

procedure TEleicaoRetornoService.ProcessarRetorno;
var
  Conn: TUniConnection;
  Erro: string;
begin
  Conn := nil;

  try
    Conn := CriarConexao;

    Erro := '';

    LogArquivo('Consultando alterações da eleição na API.');

    if not TControllersEleicaoRetorno.Sincronizar(Conn, Erro ) then
    begin
      if Trim(Erro) <> '' then
        LogArquivo('Retorno da eleição não concluído: ' + Erro);

      Exit;
    end;

    LogArquivo('Retorno da eleição concluído.');

    // Aproveita o mesmo worker de retorno para buscar solicitações públicas
    // de atualização cadastral. Nesta fase o EasyBot apenas grava uma cópia
    // local PENDENTE; nenhum cadastro de associado é alterado aqui.
    Erro := '';
    if not TAtualizacaoCadastralIntegracaoService.Sincronizar(Conn, Erro) then
    begin
      if Trim(Erro) <> '' then
        LogArquivo('Atualização cadastral não concluída: ' + Erro);
      Exit;
    end;

    LogArquivo('Pendências de atualização cadastral sincronizadas.');

  finally
    Conn.Free;
  end;
end;

procedure TEleicaoRetornoService.LogArquivo(const AMensagem: string);
var
  Arquivo: TextFile;
begin
  FLogLock.Acquire;

  try
    try

      if ExtractFilePath(FConfig.CaminhoLog) <> '' then
        ForceDirectories(
          ExtractFilePath(FConfig.CaminhoLog)
        );

      AssignFile(
        Arquivo,
        FConfig.CaminhoLog
      );

      if FileExists(FConfig.CaminhoLog) then
        Append(Arquivo)
      else
        Rewrite(Arquivo);

      try

        Writeln(
          Arquivo,
          FormatDateTime(
            'yyyy-mm-dd hh:nn:ss',
            Now
          ) +
          ' - ' +
          AMensagem
        );

      finally
        CloseFile(Arquivo);
      end;

    except
      // não deixa erro de log derrubar o worker
    end;

  finally
    FLogLock.Release;
  end;
end;

end.
