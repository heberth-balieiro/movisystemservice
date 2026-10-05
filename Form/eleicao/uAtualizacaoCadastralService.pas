unit uAtualizacaoCadastralService;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.IOUtils,
  DBAccess,
  Uni;

type
  TAtualizacaoCadastralConfig = record
    ProviderName: string;
    Server: string;
    Port: Integer;
    Database: string;
    UserName: string;
    Password: string;
    IntervaloMs: Cardinal;
    CaminhoLog: string;
    class function Criar(const AConn: TUniConnection;
      const AIntervaloMs: Cardinal): TAtualizacaoCadastralConfig; static;
  end;

  TAtualizacaoCadastralService = class
  private
    FConfig: TAtualizacaoCadastralConfig;
    FThread: TThread;
    FStopEvent: TEvent;
    FLogLock: TCriticalSection;

    function CriarConexao: TUniConnection;
    function Parando: Boolean;
    function Aguardar(const AMilisegundos: Cardinal): Boolean;
    procedure Executar;
    procedure Processar;
    procedure LogArquivo(const AMensagem: string);
  public
    constructor Create(const AConfig: TAtualizacaoCadastralConfig);
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    function Executando: Boolean;
  end;

implementation

uses
  Service.AtualizacaoCadastral;

type
  TAtualizacaoCadastralWorkerThread = class(TThread)
  private
    FOwner: TAtualizacaoCadastralService;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TAtualizacaoCadastralService);
  end;

class function TAtualizacaoCadastralConfig.Criar(const AConn: TUniConnection;
  const AIntervaloMs: Cardinal): TAtualizacaoCadastralConfig;
begin
  Result.ProviderName := AConn.ProviderName;
  Result.Server := AConn.Server;
  Result.Port := AConn.Port;
  Result.Database := AConn.Database;
  Result.UserName := AConn.UserName;
  Result.Password := AConn.Password;
  Result.IntervaloMs := AIntervaloMs;
  Result.CaminhoLog := TPath.Combine(
    ExtractFilePath(ParamStr(0)),
    'LogAtualizacaoCadastral.txt'
  );
end;

constructor TAtualizacaoCadastralWorkerThread.Create(
  AOwner: TAtualizacaoCadastralService);
begin
  inherited Create(True);
  FOwner := AOwner;
  FreeOnTerminate := False;
end;

procedure TAtualizacaoCadastralWorkerThread.Execute;
begin
  FOwner.Executar;
end;

constructor TAtualizacaoCadastralService.Create(
  const AConfig: TAtualizacaoCadastralConfig);
begin
  inherited Create;
  FConfig := AConfig;
  if FConfig.IntervaloMs < 1000 then
    FConfig.IntervaloMs := 10000;
  FStopEvent := TEvent.Create(nil, True, False, '');
  FLogLock := TCriticalSection.Create;
end;

destructor TAtualizacaoCadastralService.Destroy;
begin
  Stop;
  FreeAndNil(FLogLock);
  FreeAndNil(FStopEvent);
  inherited;
end;

procedure TAtualizacaoCadastralService.Start;
begin
  if Assigned(FThread) then
    Exit;

  FStopEvent.ResetEvent;
  FThread := TAtualizacaoCadastralWorkerThread.Create(Self);
  FThread.Start;
  LogArquivo('Worker de atualização cadastral iniciado.');
end;

procedure TAtualizacaoCadastralService.Stop;
begin
  if not Assigned(FThread) then
    Exit;

  FStopEvent.SetEvent;
  FThread.Terminate;
  FThread.WaitFor;
  FreeAndNil(FThread);
  LogArquivo('Worker de atualização cadastral finalizado.');
end;

function TAtualizacaoCadastralService.Executando: Boolean;
begin
  Result := Assigned(FThread) and not Parando;
end;

function TAtualizacaoCadastralService.Parando: Boolean;
begin
  Result := Assigned(FStopEvent) and (FStopEvent.WaitFor(0) = wrSignaled);
end;

function TAtualizacaoCadastralService.Aguardar(
  const AMilisegundos: Cardinal): Boolean;
begin
  Result := not Parando and
    (FStopEvent.WaitFor(AMilisegundos) <> wrSignaled);
end;

function TAtualizacaoCadastralService.CriarConexao: TUniConnection;
begin
  Result := TUniConnection.Create(nil);
  try
    Result.ProviderName := FConfig.ProviderName;
    Result.Server := FConfig.Server;
    Result.Port := FConfig.Port;
    Result.Database := FConfig.Database;
    Result.UserName := FConfig.UserName;
    Result.Password := FConfig.Password;
    Result.LoginPrompt := False;
    Result.AutoCommit := True;
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

procedure TAtualizacaoCadastralService.Executar;
begin
  while not Parando do
  begin
    try
      Processar;
    except
      on E: Exception do
        LogArquivo('Erro na atualização cadastral: ' + E.Message);
    end;

    if not Aguardar(FConfig.IntervaloMs) then
      Break;
  end;
end;

procedure TAtualizacaoCadastralService.Processar;
var
  Conn: TUniConnection;
  Erro: string;
begin
  Conn := nil;
  try
    Conn := CriarConexao;
    Erro := '';

    if not TAtualizacaoCadastralIntegracaoService.Sincronizar(Conn, Erro) then
    begin
      if Trim(Erro) <> '' then
        LogArquivo('Consulta de atualização cadastral não concluída: ' + Erro);
      Exit;
    end;
  finally
    Conn.Free;
  end;
end;

procedure TAtualizacaoCadastralService.LogArquivo(const AMensagem: string);
var
  Arquivo: TextFile;
begin
  FLogLock.Acquire;
  try
    try
      if ExtractFilePath(FConfig.CaminhoLog) <> '' then
        ForceDirectories(ExtractFilePath(FConfig.CaminhoLog));

      AssignFile(Arquivo, FConfig.CaminhoLog);
      if FileExists(FConfig.CaminhoLog) then
        Append(Arquivo)
      else
        Rewrite(Arquivo);
      try
        Writeln(
          Arquivo,
          FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + AMensagem
        );
      finally
        CloseFile(Arquivo);
      end;
    except
      // Falha de log não deve derrubar o worker.
    end;
  finally
    FLogLock.Release;
  end;
end;

end.
