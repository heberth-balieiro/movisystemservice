program Easybot;

uses
  Vcl.SvcMgr,
  UnitEasyBot in 'Form\UnitEasyBot.pas' {Easybotservice: TService},
  MensagemZap in 'Units\MensagemZap.pas',
  UConeSul in '..\Aplicacao\Utils\UConeSul.pas',
  APP.Asmuv in '..\Aplicacao\AppVendas\APP.Asmuv.pas',
  Constantes in 'Units\Constantes.pas',
  Controllers.Carteira in 'Form\Controllers\Controllers.Carteira.pas',
  Controllers.Garagem in 'Form\Controllers\Controllers.Garagem.pas',
  Controllers.Gerais in 'Form\Controllers\Controllers.Gerais.pas',
  CodigoTeste in 'Units\CodigoTeste.pas',
  Model.Carteira in 'Form\Model\Model.Carteira.pas',
  Model.Gerais in 'Form\Model\Model.Gerais.pas',
  Model.Garagem in 'Form\Model\Model.Garagem.pas',
  MensagemZap.V1 in 'Units\MensagemZap.V1.pas',
  Dao.Empresa in 'Form\Dao\Dao.Empresa.pas',
  Controllers.Empresa in 'Form\Controllers\Controllers.Empresa.pas',
  Model.Empresa in 'Form\Model\Model.Empresa.pas',
  Service.Empresa in 'Form\Service\Service.Empresa.pas',
  Service.Util in 'Form\Service\Service.Util.pas',
  Dao.Associado in 'Form\Dao\Dao.Associado.pas',
  Service.Associado in 'Form\Service\Service.Associado.pas',
  Controllers.Associado in 'Form\Controllers\Controllers.Associado.pas',
  Model.Associado in 'Form\Model\Model.Associado.pas',
  uEvolutionAPI in 'Units\uEvolutionAPI.pas',
  uWhatsAppMensagem100Service in 'Form\whatsapp\uWhatsAppMensagem100Service.pas',
  uCarteiraSincronizacaoService in 'Form\carteira\uCarteiraSincronizacaoService.pas',
  uEleicaoSincronizacaoService in 'Form\eleicao\uEleicaoSincronizacaoService.pas',
  uWhatsAppMensagemService in 'Form\whatsapp\uWhatsAppMensagemService.pas',
  uEleicaoAPIConfig in 'Form\eleicao\uEleicaoAPIConfig.pas',
  Dao.Config in 'Form\eleicao\Dao.Config.pas',
  uEleicaoAPIClient in 'Form\eleicao\uEleicaoAPIClient.pas',
  Model.Eleicao in 'Form\Model\Model.Eleicao.pas',
  Dao.Eleicao in 'Form\Dao\Dao.Eleicao.pas',
  Service.Eleicao in 'Form\Service\Service.Eleicao.pas',
  Controllers.Eleicao in 'Form\Controllers\Controllers.Eleicao.pas',
  Model.EleicaoConfig in 'Form\Model\Model.EleicaoConfig.pas',
  Dao.EleicaoConfig in 'Form\Dao\Dao.EleicaoConfig.pas',
  Service.EleicaoConfig in 'Form\Service\Service.EleicaoConfig.pas',
  Controllers.EleicaoConfig in 'Form\Controllers\Controllers.EleicaoConfig.pas',
  Model.EleicaoChapa in 'Form\Model\Model.EleicaoChapa.pas',
  Dao.EleicaoChapa in 'Form\Dao\Dao.EleicaoChapa.pas',
  Service.EleicaoChapa in 'Form\Service\Service.EleicaoChapa.pas',
  Controllers.EleicaoChapa in 'Form\Controllers\Controllers.EleicaoChapa.pas',
  Model.EleicaoMembro in 'Form\Model\Model.EleicaoMembro.pas',
  Dao.EleicaoMembro in 'Form\Dao\Dao.EleicaoMembro.pas',
  Service.EleicaoMembro in 'Form\Service\Service.EleicaoMembro.pas',
  Controllers.EleicaoMembro in 'Form\Controllers\Controllers.EleicaoMembro.pas',
  Model.UsuarioSistema in 'Form\Model\Model.UsuarioSistema.pas',
  Dao.UsuarioSistema in 'Form\Dao\Dao.UsuarioSistema.pas',
  Service.UsuarioSistema in 'Form\Service\Service.UsuarioSistema.pas',
  Controllers.UsuarioSistema in 'Form\Controllers\Controllers.UsuarioSistema.pas',
  uEleicaoSenha in 'Form\eleicao\uEleicaoSenha.pas',
  uEleicaoRetornoService in 'Form\eleicao\uEleicaoRetornoService.pas',
  Controllers.EleicaoRetorno in 'Form\eleicao\Controllers.EleicaoRetorno.pas',
  Service.EleicaoRetorno in 'Form\eleicao\Service.EleicaoRetorno.pas',
  Service.AtualizacaoCadastral in 'Form\eleicao\Service.AtualizacaoCadastral.pas',
  Controllers.EleicaoQuestao in 'Form\Controllers\Controllers.EleicaoQuestao.pas',
  Service.EleicaoQuestao in 'Form\Service\Service.EleicaoQuestao.pas',
  Model.EleicaoQuestao in 'Form\Model\Model.EleicaoQuestao.pas',
  Dao.EleicaoQuestao in 'Form\Dao\Dao.EleicaoQuestao.pas';

{$R *.RES}

begin
  //Serviço sincronizar Carteira
  //serviço sincronizar Eleição
  //Serviço sincronizar Mensagem

  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  //Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TEasybotservice, Easybotservice);
  Application.Run;
end.
