unit Service.AtualizacaoCadastral;

interface

uses
  System.SysUtils,
  System.JSON,
  Uni,
  Dao.Config,
  uEleicaoAPIConfig,
  uEleicaoAPIClient;

type
  TAtualizacaoCadastralIntegracaoService = class
  private
    class procedure GarantirTabela(AConn: TUniConnection); static;
    class procedure ProcessarEmpresa(AConn: TUniConnection;
      const AIDEmpresa: Integer; const AUUID, AAPIKey: string); static;
    class procedure ProcessarResposta(AConn: TUniConnection;
      const AIDEmpresa: Integer; const AResposta: string); static;
    class procedure GravarSolicitacao(AConn: TUniConnection;
      const AIDEmpresa: Integer; AItem: TJSONObject); static;
  public
    class function Sincronizar(AConn: TUniConnection; out AErro: string): Boolean; static;
  end;

implementation

class procedure TAtualizacaoCadastralIntegracaoService.GarantirTabela(AConn: TUniConnection);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS integracao_atualizacao_cadastral (' +
      ' id_solicitacao_api BIGINT NOT NULL,' +
      ' id_empresa INT NOT NULL,' +
      ' pessoa_id_api BIGINT NULL,' +
      ' nome VARCHAR(180) NULL,' +
      ' cpf VARCHAR(20) NULL,' +
      ' matricula VARCHAR(30) NULL,' +
      ' email_novo VARCHAR(180) NULL,' +
      ' telefone_novo VARCHAR(20) NULL,' +
      ' whatsapp_novo VARCHAR(20) NULL,' +
      ' situacao VARCHAR(20) NOT NULL DEFAULT ''PENDENTE'',' +
      ' criado_em_api DATETIME NULL,' +
      ' recebido_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
      ' processado_em DATETIME NULL,' +
      ' erro VARCHAR(500) NULL,' +
      ' PRIMARY KEY (id_solicitacao_api, id_empresa),' +
      ' KEY idx_integracao_atualizacao_situacao (id_empresa, situacao)' +
      ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4';
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class function TAtualizacaoCadastralIntegracaoService.Sincronizar(
  AConn: TUniConnection; out AErro: string): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AErro := '';

  try
    GarantirTabela(AConn);

    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        'SELECT id_empresa, guid, token_api ' +
        'FROM empresa ' +
        'WHERE COALESCE(guid,'''')<>'''' ' +
        'AND COALESCE(token_api,'''')<>'''' ' +
        'ORDER BY id_empresa';
      Qry.Open;

      while not Qry.Eof do
      begin
        ProcessarEmpresa(
          AConn,
          Qry.FieldByName('id_empresa').AsInteger,
          Trim(Qry.FieldByName('guid').AsString),
          Trim(Qry.FieldByName('token_api').AsString)
        );
        Qry.Next;
      end;
    finally
      Qry.Free;
    end;

    Result := True;
  except
    on E: Exception do
    begin
      AErro := E.Message;
      Result := False;
    end;
  end;
end;

class procedure TAtualizacaoCadastralIntegracaoService.ProcessarEmpresa(
  AConn: TUniConnection; const AIDEmpresa: Integer;
  const AUUID, AAPIKey: string);
var
  URL, Usuario, Senha: string;
  Config: TEleicaoAPIConfig;
  Resposta, Erro: string;
begin
  if not TDaoConfig.BuscarURLAppEleicao(AConn, URL, Usuario, Senha) then
    raise Exception.Create('Configuração da API da eleição não encontrada.');

  Config := TEleicaoAPIConfig.Criar(URL, Usuario, Senha);
  Resposta := '';
  Erro := '';

  if not TEleicaoAPIClient.GetEmpresa(
    Config,
    AUUID,
    AAPIKey,
    '/v1/integracao/easyone/atualizacoes-cadastrais/pendentes',
    '',
    Resposta,
    Erro
  ) then
    raise Exception.Create(Erro);

  ProcessarResposta(AConn, AIDEmpresa, Resposta);
end;

class procedure TAtualizacaoCadastralIntegracaoService.ProcessarResposta(
  AConn: TUniConnection; const AIDEmpresa: Integer; const AResposta: string);
var
  Json: TJSONObject;
  Dados: TJSONArray;
  I: Integer;
begin
  Json := TJSONObject.ParseJSONValue(AResposta) as TJSONObject;
  try
    if not Assigned(Json) then
      raise Exception.Create('Retorno inválido da API para atualização cadastral.');

    Dados := Json.GetValue<TJSONArray>('dados');
    if not Assigned(Dados) then
      Exit;

    for I := 0 to Dados.Count - 1 do
      if Dados.Items[I] is TJSONObject then
        GravarSolicitacao(AConn, AIDEmpresa, Dados.Items[I] as TJSONObject);
  finally
    Json.Free;
  end;
end;

class procedure TAtualizacaoCadastralIntegracaoService.GravarSolicitacao(
  AConn: TUniConnection; const AIDEmpresa: Integer; AItem: TJSONObject);
var
  Qry: TUniQuery;
  IdSolicitacao, PessoaIdAPI: Int64;
  Nome, CPF, Matricula, EmailNovo, TelefoneNovo, WhatsappNovo, CriadoEm: string;
begin
  IdSolicitacao := 0;
  PessoaIdAPI := 0;

  if Assigned(AItem.GetValue('id_solicitacao')) then
    IdSolicitacao := AItem.GetValue<Int64>('id_solicitacao');

  if IdSolicitacao <= 0 then
    Exit;

  if Assigned(AItem.GetValue('pessoa_id_api')) then
    PessoaIdAPI := AItem.GetValue<Int64>('pessoa_id_api');

  Nome := '';
  CPF := '';
  Matricula := '';
  EmailNovo := '';
  TelefoneNovo := '';
  WhatsappNovo := '';
  CriadoEm := '';

  if Assigned(AItem.GetValue('nome')) then Nome := AItem.GetValue<string>('nome');
  if Assigned(AItem.GetValue('cpf')) then CPF := AItem.GetValue<string>('cpf');
  if Assigned(AItem.GetValue('matricula')) then Matricula := AItem.GetValue<string>('matricula');
  if Assigned(AItem.GetValue('email_novo')) then EmailNovo := AItem.GetValue<string>('email_novo');
  if Assigned(AItem.GetValue('telefone_novo')) then TelefoneNovo := AItem.GetValue<string>('telefone_novo');
  if Assigned(AItem.GetValue('whatsapp_novo')) then WhatsappNovo := AItem.GetValue<string>('whatsapp_novo');
  if Assigned(AItem.GetValue('criado_em')) then CriadoEm := AItem.GetValue<string>('criado_em');

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO integracao_atualizacao_cadastral (' +
      ' id_solicitacao_api, id_empresa, pessoa_id_api, nome, cpf, matricula, ' +
      ' email_novo, telefone_novo, whatsapp_novo, situacao, criado_em_api, recebido_em) ' +
      'VALUES (:id, :empresa, :pessoa, :nome, :cpf, :matricula, :email, :telefone, :whatsapp, ' +
      ' ''PENDENTE'', STR_TO_DATE(:criado_em, ''%Y-%m-%d %H:%i:%s''), NOW()) ' +
      'ON DUPLICATE KEY UPDATE ' +
      ' pessoa_id_api=VALUES(pessoa_id_api), nome=VALUES(nome), cpf=VALUES(cpf), ' +
      ' matricula=VALUES(matricula), email_novo=VALUES(email_novo), ' +
      ' telefone_novo=VALUES(telefone_novo), whatsapp_novo=VALUES(whatsapp_novo), ' +
      ' criado_em_api=VALUES(criado_em_api), recebido_em=NOW()';

    Qry.ParamByName('id').AsLargeInt := IdSolicitacao;
    Qry.ParamByName('empresa').AsInteger := AIDEmpresa;
    Qry.ParamByName('pessoa').AsLargeInt := PessoaIdAPI;
    Qry.ParamByName('nome').AsString := Nome;
    Qry.ParamByName('cpf').AsString := CPF;
    Qry.ParamByName('matricula').AsString := Matricula;
    Qry.ParamByName('email').AsString := EmailNovo;
    Qry.ParamByName('telefone').AsString := TelefoneNovo;
    Qry.ParamByName('whatsapp').AsString := WhatsappNovo;
    Qry.ParamByName('criado_em').AsString := CriadoEm;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
