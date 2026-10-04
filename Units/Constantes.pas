unit Constantes;

interface

Const
  //Logs telas
  LogSecretaria = 'Secretaria';
  LogLotacao    = 'Lotação';
  LogProfissao  = 'Profissão';
  LogPessoas    = 'Pessoas';
  LogDependentes= 'Dependentes';
  LogCarteira   = 'Carteira';
  LogConvenio   = 'Convenio';
  LogCandidato  = 'Candidato';
  LogEleicao    = 'Eleição';
  LogMembro     = 'Membro';
  LogChapa      = 'Chapa';
  LogCampanha   = 'Campanha';
  LogNotificacao= 'Notificacao';
  LogUsuario    = 'Usuário';
  LogAutorizacao= 'Autorização';
  LogEntrada    = 'Registro';
  LogEmpresa    = 'Empresa';
  LogVeiculo    = 'Veículo';

  LogEasyBot    = 'EasyBot';

  LogMsg1       = 'Buscando registro para enviar para API...';
  LogMsg2       = 'Nenhum registro para sincronizar.';
  LogMsg3       = 'Analisando registro das tabelas.';
  LogMsg4       = 'Erro ao processar registro:';
  LogMsg5       = 'Iniciando sincronização de registro com a API...';

  LogMsg6       = 'Empresa sem configuração de sincronização!';
  LogMsg7       = 'Encontrados';
  LogMsg8       = 'registros pendentes para sincronizar';
  LogMsg9       = 'Json sem dados para enviar!';
  LogMsg10      = 'Atualizando status dos registros sincronizados...';
  LogMsg11      = 'Ainda restam';
  LogMsg12      = 'registros para sincronizar.';
  LogMsg13      = 'Ciclo de Sincronização concluída! Nenhum registro pendente.';
  LogMsg14      = 'ID da empresa inválido para sincronização.';

  RotaSecretaria  = '/v1/secretaria';
  RotaLotacao     = '/v1/lotacao';
  RotaDependente  = '/v1/dependente';
  RotaUsuario     = '/v1/usuario';
  RotaAutorizacao = '/v1/autorizacao';
  RotaCandidato   = '/v1/candidato';
  RotaMembro      = '/v1/membro';
  RotaChapa       = '/v1/chapa';
  RotaEleicao     = '/v1/eleicao';
  RotaCampanha    = '/v1/campanha';
  RotaPessoa      = '/v1/pessoa';
  RotaCarteira    = '/v1/carteira';
  RotaNotificacao = '/v1/notificacoes';
  RotaConvenio    = '/v1/convenio';
  RotaProfissao   = '/v1/profissao';
  RotaEmpresa     = '/v1/empresa';
  RotaVeiculo     = '/v1/veiculo';
  RotaRegEntrada  = '/v1/registro';
  RotaRetornoreg  = '/v1/registro/retorno';
implementation

end.
