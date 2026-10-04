{

Sincronizar aplicação carteira digital
Sincronizar aplicação eleição digital
Sincronizar aplicação envio de mensagem

//Teste
    //TUtilService.SalvarJsonDebug(JsonLote, Format('Associado_%d.json',[1]));
    //Result := True;
    //Exit;

}

unit UnitEasyBot;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs,
  Vcl.ExtCtrls, UniProvider, MySQLUniProvider, DBAccess, Uni, Data.DB, MemDS,
  System.IniFiles, ACBRUTIL, Uconesul,
  System.Math,System.DateUtils,System.Generics.Collections,System.IOUtils,

  uCarteiraSincronizacaoService,
  uWhatsAppMensagemService,
  uWhatsAppMensagem100Service,
  uEleicaoSincronizacaoService,
  uEleicaoRetornoService;

type
  TEasybotservice = class(TService)
    Conn: TUniConnection;
    QryMsG: TUniQuery;
    UniTransaction: TUniTransaction;
    Provider: TMySQLUniProvider;
    TimerEnvio: TTimer;
    TimerSincronizarAPI: TTimer;
    QrySincronizar: TUniQuery;
    QryAuxiliar: TUniQuery;
    QryLog: TUniQuery;
    TimerEleicao: TTimer;
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  private
    FGravarBanco      : String;
    FEnvioMensagem    : String;
    FEnvioCarteira    : String;
    FEnvioEleicao     : String;
    FEnvioMensagem100 : String;

    FWhatsAppService  : TWhatsAppMensagemService;
    FCarteiraService  : TCarteiraSincronizacaoService;
    FEleicaoService   : TEleicaoSincronizacaoService;
    FWhatsAppService100  : TWhatsAppMensagemService100;
    FEleicaoRetornoService  : TEleicaoRetornoService;

    Procedure ConfBancoDados(AConn: TUniConnection);
    procedure Log(const Msg, Arquivo: string);
    procedure LogBanco(const msg, descricao, para, fone: string;const id: integer);
    procedure LimparLogsAntigos;
    procedure ExcluirLogsAoIniciar;
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  Easybotservice: TEasybotservice;

implementation

{$R *.dfm}

uses APP.Asmuv, Constantes;

{$REGION 'Controle de Logs'}

procedure TEasybotservice.Log(const Msg,Arquivo: string);
var
  LogFile: TextFile;
  FileName: string;
begin
  FileName := ExtractFilePath(ParamStr(0)) +'\'+Arquivo+'.txt';
  AssignFile(LogFile, FileName);
  if FileExists(FileName) then
    Append(LogFile)
  else
    Rewrite(LogFile);
  try
    Writeln(LogFile, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + Msg);
  finally
    CloseFile(LogFile);
  end;

end;

Procedure TEasybotservice.LogBanco(Const msg, descricao, para, fone: string; const id: integer);
Const
  QryStr = 'Insert into log_mensagem(data, hora, id_usuario, descricao, para, fone) ' +
           'Values (:data, :hora, :id_usuario, :descricao, :para, :fone)';
begin
  try
    QryLog.SQL.Text   := QryStr;
    QryLog.ParamByName('data').AsDate           := Date;   // só data
    QryLog.ParamByName('hora').AsTime           := Time;   // só hora
    QryLog.ParamByName('id_usuario').AsInteger  := id;
    QryLog.ParamByName('descricao').AsString    := msg;
    QryLog.ParamByName('para').AsString         := para;
    QryLog.ParamByName('fone').AsString         := fone;

    try
      QryLog.ExecSQL;
    except
      on E: Exception do
        Log('Erro ao gravar log: ' + E.Message, 'LogMensagenszap');
    end;

  finally
    QryLog.Close;
  end;
end;

procedure TEasybotservice.LimparLogsAntigos;
const
  QryStr = 'DELETE FROM log_mensagem WHERE data < :DataLimite';
begin
  try
    QryLog.SQL.Text := QryStr;
    QryLog.ParamByName('DataLimite').AsDate := Date - 2; // mantém só os últimos 2 dias
    QryLog.ExecSQL;
  except
    on E: Exception do
      Log('Erro ao limpar logs: ' + E.Message, 'LogMensagenszap');
  end;
end;

procedure TEasybotservice.ExcluirLogsAoIniciar;
const
  ArquivosLog: array[0..2] of string = (
    'LogMensagenszap.txt',
    'LogSincronizarAPI.txt',
    'LogSincronizarAPIEleicao.txt'
  );
var
  DiretorioExe: string;
  NomeLog: string;
  CaminhoLog: string;
begin
  DiretorioExe := ExtractFilePath(ParamStr(0));
  for NomeLog in ArquivosLog do
  begin
    CaminhoLog := TPath.Combine(DiretorioExe, NomeLog);
    if TFile.Exists(CaminhoLog) then
      TFile.Delete(CaminhoLog);
  end;
end;

{$ENDREGION}

{$REGION 'Serviço'}

procedure TEasybotservice.ConfBancoDados(AConn: TUniConnection);
var
  arq_ini : string;
  ini : TIniFile;
  pass: string;
begin
  ini := nil;
  Try
    try
      arq_ini := ExtractFilePath(ParamStr(0)) + '\Config.ini';

      if not FileExists(arq_ini) then
      begin
        Log('Erro ao localizar caminho do arquivo de configuração do banco de dados.', 'LogBanco');
        Exit;
      end;

      ini := TIniFile.Create(arq_ini);

      with AConn do
      begin
        ProviderName      := ini.ReadString('DADOS', 'DriverID', '');
        Server            := ini.ReadString('DADOS', 'Server', '');
        Port              := ini.ReadInteger('DADOS', 'Port', 3306);
        Database          := ini.ReadString('DADOS', 'Database', '');
        UserName          := ini.ReadString('DADOS', 'User_Name', '');
        pass              := ini.ReadString('DADOS', 'Password', '');
        Password          := TConeSul.Crypt('D', pass);
        LoginPrompt       := False;
        SpecificOptions.Values['charset'] := 'utf8mb4';
        SpecificOptions.Values['Connectiontimeout'] := '30';
        SpecificOptions.Values['UseUnicode'] := 'True';

        Pooling                                 := True;
        PoolingOptions.MaxPoolSize              := 50;
        PoolingOptions.MinPoolSize              := 2;
        PoolingOptions.ConnectionLifetime       := 30;
      end;

      TimerEnvio.Interval           := ini.ReadInteger('SERVICE', 'Intervalo', 3000);
      TimerSincronizarAPI.Interval  := ini.ReadInteger('SERVICE', 'IntervaloAPI', 10000);
      TimerEleicao.Interval         := ini.ReadInteger('SERVICE', 'IntervaloAPI', 10000);

      FGravarBanco                  := ini.ReadString('SERVICE','GravaDB','false');
      FEnvioMensagem                := ini.ReadString('SERVICE','EnvioMensagem','false');
      FEnvioCarteira                := ini.ReadString('SERVICE','EnvioCarteira','false');
      FEnvioEleicao                 := ini.ReadString('SERVICE','EnvioEleicao','false');

      //100 alumio
      FEnvioMensagem100             := ini.ReadString('SERVICE','EnvioMensagem100','false');

    except
      on Ex: Exception do
      begin
        Log('Erro ao configurar o banco de dados: ' + Ex.Message, 'LogBanco');
        raise;
      end;
    end;
  finally
    ini.Free;
  end;
end;

procedure TEasybotservice.ServiceStart(Sender: TService; var Started: Boolean);
var
  WhatsAppConfig        : TWhatsAppMensagemConfig;
  CarteiraConfig        : TCarteiraSincronizacaoConfig;
  EleicaoConfig         : TEleicaoSincronizacaoConfig;
  WhatsAppConfig100     : TWhatsAppMensagemConfig100;
  EleicaoRetornoConfig  : TEleicaoRetornoConfig;
begin
  Started := False;

  try
    {$REGION 'Banco'}

    LogMessage('EasyBot: entrando no ServiceStart.', EVENTLOG_INFORMATION_TYPE);
    //Limpar Logs
    ExcluirLogsAoIniciar;
    //carregar Configuracao
    ConfBancoDados(Conn);
    Log('02 - Configurações carregadas.', 'LogBanco');

    if not Conn.Connected then
      Conn.Open;
    Log('03 - Banco conectado.', 'LogBanco');

    {$ENDREGION}

    //Codigo ativado pra enviar mensagem
    {$REGION 'WhatsApp'}

    if SameText(Trim(FEnvioMensagem), 'true') then
    begin
      Log('04 - Criando configuração do WhatsApp.', 'LogMensagenszap');

      WhatsAppConfig := TWhatsAppMensagemConfig.Criar(
        Conn,
        TimerEnvio.Interval,
        SameText(Trim(FGravarBanco), 'true')
      );

      Log('05 - Criando serviço do WhatsApp.', 'LogMensagenszap');

      FWhatsAppService := TWhatsAppMensagemService.Create(WhatsAppConfig);

      Log('06 - Iniciando worker do WhatsApp.', 'LogMensagenszap');

      FWhatsAppService.Start;

      Log('07 - Worker do WhatsApp iniciado.', 'LogMensagenszap');
    end
    else
      Log('EnvioMensagem está desativado no Config.ini: ' +
        FEnvioMensagem, 'LogMensagenszap');

    {$ENDREGION}

    //Codigo ativado para sincronizar dados carteira
    {$REGION 'Carteira'}

    if SameText(Trim(FEnvioCarteira), 'true') then
    begin
      Log('Criando configuração da carteira.', 'LogSincronizarAPI');
      CarteiraConfig    := TCarteiraSincronizacaoConfig.Criar(Conn, TimerSincronizarAPI.Interval);
      Log('Criando serviço da Carteira.', 'LogSincronizarAPI');
      FCarteiraService  := TCarteiraSincronizacaoService.Create(CarteiraConfig);
      Log('Iniciando worker do carteira.', 'LogSincronizarAPI');
      FCarteiraService.Start;

      LogMessage('Worker de sincronização da carteira iniciado.',EVENTLOG_INFORMATION_TYPE);
    end;

    {$ENDREGION}

    //Codigo ativado para sincronizar dados da eleicao para api
    {$REGION 'Eleicao'}

    if SameText(Trim(FEnvioEleicao), 'true') then
    begin
      //Envio
      {$REGION 'Envio'}
        Log('Criando configuração da eleição.', 'LogSincronizarAPIEleicao');
        EleicaoConfig     := TEleicaoSincronizacaoConfig.Criar(Conn,TimerEleicao.Interval);
        Log('Criando serviço da Eleição.', 'LogSincronizarAPIEleicao');
        FEleicaoService   := TEleicaoSincronizacaoService.Create(EleicaoConfig);
        Log('Iniciando worker do eleição.', 'LogSincronizarAPIEleicao');
        FEleicaoService.Start;
        Log('Worker da eleição iniciado.', 'LogSincronizarAPIEleicao');
      {$ENDREGION}

      //Retorno da API
      {$REGION 'Retorno'}
        Log('Criando configuração do retorno da eleição.','LogSincronizarAPIEleicao');
        EleicaoRetornoConfig :=TEleicaoRetornoConfig.Criar(Conn,TimerEleicao.Interval);
        Log('Criando serviço de retorno da eleição.','LogSincronizarAPIEleicao');
        FEleicaoRetornoService  := TEleicaoRetornoService.Create(EleicaoRetornoConfig);
        Log('Iniciando worker de retorno da eleição.', 'LogSincronizarAPIEleicao');
        FEleicaoRetornoService.Start;
        Log('Worker de retorno da eleição iniciado.','LogSincronizarAPIEleicao');
      {$ENDREGION}

    end;

    {$ENDREGION}

    //codigo ativado para 100 aluminio FEnvioMensagem100
    {$REGION 'Zap 100%'}

    if SameText(Trim(FEnvioMensagem100), 'true') then
    begin
      Log('Criando configuração do WhatsApp.', 'LogMensagenszap');

      WhatsAppConfig100  := TWhatsAppMensagemConfig100.Criar(Conn,TimerEnvio.Interval,
                              SameText(Trim(FGravarBanco), 'true'));

      Log('Criando serviço do WhatsApp.', 'LogMensagenszap');
      FWhatsAppService100    := TWhatsAppMensagemService100.Create(WhatsAppConfig100);
      Log('Iniciando worker do WhatsApp.', 'LogMensagenszap');
      FWhatsAppService100.Start;
      Log('Worker do WhatsApp iniciado.', 'LogMensagenszap');
    end
    else
      Log('EnvioMensagem está desativado no Config.ini: ' +
        FEnvioMensagem, 'LogMensagenszap');

    {$ENDREGION}

    Started := True;
    LogMessage('EasyBot iniciado com sucesso.', EVENTLOG_INFORMATION_TYPE);

  except
    on E: Exception do
    begin
      Started := False;

      LogMessage(
        'EasyBot: erro no ServiceStart: ' +
        E.ClassName + ' - ' + E.Message,
        EVENTLOG_ERROR_TYPE
      );

      try
        Log(
          'ERRO ServiceStart: ' + E.ClassName + ' - ' + E.Message,
          'LogBanco'
        );
      except
        // Impede que uma falha no arquivo de log esconda o erro original.
      end;
    end;
  end;
end;

procedure TEasybotservice.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  try
    if Assigned(FEleicaoService) then
    begin
      FEleicaoService.Stop;
      FreeAndNil(FEleicaoService);
    end;

    if Assigned(FCarteiraService) then
    begin
      FCarteiraService.Stop;
      FreeAndNil(FCarteiraService);
    end;

    if Assigned(FWhatsAppService) then
    begin
      FWhatsAppService.Stop;
      FreeAndNil(FWhatsAppService);
    end;

    if Assigned(FEleicaoRetornoService) then
    begin
      FEleicaoRetornoService.Stop;
      FreeAndNil(FEleicaoRetornoService);
    end;

    Stopped := True;
  except
    on E: Exception do
    begin
      Log('Erro ao finalizar WhatsApp: ' + E.Message, 'LogMensagenszap');
      Stopped := False;
    end;
  end;
end;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  Easybotservice.Controller(CtrlCode);
end;

function TEasybotservice.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

{$ENDREGION}

end.


