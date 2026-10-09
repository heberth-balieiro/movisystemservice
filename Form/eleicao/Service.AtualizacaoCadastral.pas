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
    class procedure ProcessarEmpresa(AConn: TUniConnection;
      const AIDEmpresa: Integer; const AUUID, AAPIKey: string); static;
    class procedure ProcessarResposta(AConn: TUniConnection;
      const AIDEmpresa: Integer; const AResposta: string); static;
    class procedure GravarSolicitacao(AConn: TUniConnection;
      const AIDEmpresa: Integer; AItem: TJSONObject); static;
    class procedure EnviarRetornos(AConn: TUniConnection;
      const AIDEmpresa: Integer; const AUUID, AAPIKey: string;
      const AConfig: TEleicaoAPIConfig); static;
  public
    class function Sincronizar(AConn: TUniConnection; out AErro: string): Boolean; static;
  end;

implementation

class function TAtualizacaoCadastralIntegracaoService.Sincronizar(
  AConn: TUniConnection; out AErro: string): Boolean;
var
  Qry: TUniQuery;
begin
  Result := False;
  AErro := '';

  try
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
  ErroConsulta, ErroRetorno: string;
begin
  if not TDaoConfig.BuscarURLAppEleicao(AConn, URL, Usuario, Senha) then
    raise Exception.Create('Configuração da API da eleição não encontrada.');

  Config := TEleicaoAPIConfig.Criar(URL, Usuario, Senha);
  ErroConsulta := '';
  ErroRetorno := '';

  Resposta := '';
  Erro := '';
  try
    if TEleicaoAPIClient.GetEmpresa(
      Config,
      AUUID,
      AAPIKey,
      '/v1/integracao/easyone/atualizacoes-cadastrais/pendentes',
      '',
      Resposta,
      Erro
    ) then
      ProcessarResposta(AConn, AIDEmpresa, Resposta)
    else
      ErroConsulta := Erro;
  except
    on E: Exception do
      ErroConsulta := E.Message;
  end;

  try
    EnviarRetornos(AConn, AIDEmpresa, AUUID, AAPIKey, Config);
  except
    on E: Exception do
      ErroRetorno := E.Message;
  end;

  if (Trim(ErroConsulta) <> '') and (Trim(ErroRetorno) <> '') then
    raise Exception.Create(
      'Consulta de pendencias: ' + ErroConsulta +
      ' | Retorno de status: ' + ErroRetorno
    );

  if Trim(ErroConsulta) <> '' then
    raise Exception.Create('Consulta de pendencias: ' + ErroConsulta);

  if Trim(ErroRetorno) <> '' then
    raise Exception.Create('Retorno de status: ' + ErroRetorno);
end;

class procedure TAtualizacaoCadastralIntegracaoService.EnviarRetornos(
  AConn: TUniConnection; const AIDEmpresa: Integer;
  const AUUID, AAPIKey: string; const AConfig: TEleicaoAPIConfig);
var
  Qry, QryAtualiza: TUniQuery;
  Json: TJSONObject;
  IdSolicitacao: Int64;
  Situacao, Observacao, Resposta, Erro, PrimeiroErro: string;
begin
  PrimeiroErro := '';

  Qry := TUniQuery.Create(nil);
  QryAtualiza := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    QryAtualiza.Connection := AConn;

    Qry.SQL.Text :=
      'SELECT id_solicitacao_api, situacao, erro ' +
      'FROM integracao_atualizacao_cadastral ' +
      'WHERE id_empresa = :id_empresa ' +
      '  AND situacao IN (''PROCESSADO'', ''REJEITADO'', ''ERRO'') ' +
      '  AND retornado_api_em IS NULL ' +
      'ORDER BY id_solicitacao_api';
    Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
    Qry.Open;

    while not Qry.Eof do
    begin
      IdSolicitacao := Qry.FieldByName('id_solicitacao_api').AsLargeInt;
      Situacao := UpperCase(Trim(Qry.FieldByName('situacao').AsString));
      Observacao := Trim(Qry.FieldByName('erro').AsString);
      Resposta := '';
      Erro := '';

      Json := TJSONObject.Create;
      try
        Json.AddPair('id_solicitacao', TJSONNumber.Create(IdSolicitacao));
        Json.AddPair('situacao', Situacao);
        Json.AddPair('observacao', Observacao);

        if TEleicaoAPIClient.PostEmpresa(
          AConfig,
          AUUID,
          AAPIKey,
          '/v1/integracao/easyone/atualizacoes-cadastrais/status',
          Json.ToJSON,
          Resposta,
          Erro
        ) then
        begin
          QryAtualiza.Close;
          QryAtualiza.SQL.Text :=
            'UPDATE integracao_atualizacao_cadastral ' +
            'SET retornado_api_em = NOW(), retorno_api_erro = NULL ' +
            'WHERE id_solicitacao_api = :id_solicitacao_api ' +
            '  AND id_empresa = :id_empresa ' +
            '  AND retornado_api_em IS NULL';
          QryAtualiza.ParamByName('id_solicitacao_api').AsLargeInt := IdSolicitacao;
          QryAtualiza.ParamByName('id_empresa').AsInteger := AIDEmpresa;
          QryAtualiza.ExecSQL;
        end
        else
        begin
          if Trim(Erro) = '' then
            Erro := 'Falha ao retornar situação da atualização cadastral para a API.';

          QryAtualiza.Close;
          QryAtualiza.SQL.Text :=
            'UPDATE integracao_atualizacao_cadastral ' +
            'SET retorno_api_erro = :erro ' +
            'WHERE id_solicitacao_api = :id_solicitacao_api ' +
            '  AND id_empresa = :id_empresa ' +
            '  AND retornado_api_em IS NULL';
          QryAtualiza.ParamByName('erro').AsString := Copy(Erro, 1, 500);
          QryAtualiza.ParamByName('id_solicitacao_api').AsLargeInt := IdSolicitacao;
          QryAtualiza.ParamByName('id_empresa').AsInteger := AIDEmpresa;
          QryAtualiza.ExecSQL;

          if PrimeiroErro = '' then
            PrimeiroErro := Format(
              'Solicitação %d: %s',
              [IdSolicitacao, Erro]
            );
        end;
      finally
        Json.Free;
      end;

      Qry.Next;
    end;
  finally
    QryAtualiza.Free;
    Qry.Free;
  end;

  if PrimeiroErro <> '' then
    raise Exception.Create(PrimeiroErro);
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
  Nome, CPF, Matricula, EmailNovo, TelefoneNovo, WhatsappNovo: string;
  CepNovo, EnderecoNovo, NumeroNovo, BairroNovo, ComplementoNovo, CidadeNova: string;
  CriadoEm: string;
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
  CepNovo := '';
  EnderecoNovo := '';
  NumeroNovo := '';
  BairroNovo := '';
  ComplementoNovo := '';
  CidadeNova := '';
  CriadoEm := '';

  if Assigned(AItem.GetValue('nome')) then Nome := AItem.GetValue<string>('nome');
  if Assigned(AItem.GetValue('cpf')) then CPF := AItem.GetValue<string>('cpf');
  if Assigned(AItem.GetValue('matricula')) then Matricula := AItem.GetValue<string>('matricula');
  if Assigned(AItem.GetValue('email_novo')) then EmailNovo := AItem.GetValue<string>('email_novo');
  if Assigned(AItem.GetValue('telefone_novo')) then TelefoneNovo := AItem.GetValue<string>('telefone_novo');
  if Assigned(AItem.GetValue('whatsapp_novo')) then WhatsappNovo := AItem.GetValue<string>('whatsapp_novo');
  if Assigned(AItem.GetValue('cep_novo')) then CepNovo := AItem.GetValue<string>('cep_novo');
  if Assigned(AItem.GetValue('endereco_novo')) then EnderecoNovo := AItem.GetValue<string>('endereco_novo');
  if Assigned(AItem.GetValue('numero_novo')) then NumeroNovo := AItem.GetValue<string>('numero_novo');
  if Assigned(AItem.GetValue('bairro_novo')) then BairroNovo := AItem.GetValue<string>('bairro_novo');
  if Assigned(AItem.GetValue('complemento_novo')) then ComplementoNovo := AItem.GetValue<string>('complemento_novo');
  if Assigned(AItem.GetValue('cidade_nova')) then CidadeNova := AItem.GetValue<string>('cidade_nova');
  if Assigned(AItem.GetValue('criado_em')) then CriadoEm := AItem.GetValue<string>('criado_em');

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO integracao_atualizacao_cadastral (' +
      ' id_solicitacao_api, id_empresa, pessoa_id_api, nome, cpf, matricula, ' +
      ' email_novo, telefone_novo, whatsapp_novo, cep_novo, endereco_novo, numero_novo, ' +
      ' bairro_novo, complemento_novo, cidade_nova, situacao, criado_em_api, recebido_em) ' +
      'VALUES (:id, :empresa, :pessoa, :nome, :cpf, :matricula, :email, :telefone, :whatsapp, ' +
      ' :cep, :endereco, :numero, :bairro, :complemento, :cidade, ' +
      ' ''PENDENTE'', STR_TO_DATE(:criado_em, ''%Y-%m-%d %H:%i:%s''), NOW()) ' +
      'ON DUPLICATE KEY UPDATE ' +
      ' pessoa_id_api=VALUES(pessoa_id_api), nome=VALUES(nome), cpf=VALUES(cpf), ' +
      ' matricula=VALUES(matricula), email_novo=VALUES(email_novo), ' +
      ' telefone_novo=VALUES(telefone_novo), whatsapp_novo=VALUES(whatsapp_novo), ' +
      ' cep_novo=VALUES(cep_novo), endereco_novo=VALUES(endereco_novo), ' +
      ' numero_novo=VALUES(numero_novo), bairro_novo=VALUES(bairro_novo), ' +
      ' complemento_novo=VALUES(complemento_novo), cidade_nova=VALUES(cidade_nova), ' +
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
    Qry.ParamByName('cep').AsString := CepNovo;
    Qry.ParamByName('endereco').AsString := EnderecoNovo;
    Qry.ParamByName('numero').AsString := NumeroNovo;
    Qry.ParamByName('bairro').AsString := BairroNovo;
    Qry.ParamByName('complemento').AsString := ComplementoNovo;
    Qry.ParamByName('cidade').AsString := CidadeNova;
    Qry.ParamByName('criado_em').AsString := CriadoEm;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
