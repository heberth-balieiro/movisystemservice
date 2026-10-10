unit Service.EleicaoRetorno;

interface

uses
  System.SysUtils,
  System.JSON,
  System.StrUtils,
  Uni,
  Dao.Config,
  uEleicaoAPIConfig,
  uEleicaoAPIClient;

type
  TEleicaoRetornoService = class
  private
    class procedure ProcessarEmpresa(
      AConn: TUniConnection;
      const AIDEmpresa: Integer;
      const AUUID, AAPIKey: string); static;

    class procedure ProcessarRetorno(
      AConn: TUniConnection;
      const AIDEmpresa: Integer;
      const AResposta: string); static;

    class procedure AtualizarSituacao(
      AConn: TUniConnection;
      const AIDEmpresa, AIDEleicao: Integer;
      const ASituacao: string); static;

    class function SituacaoValida(const ASituacao: string): Boolean; static;

    class procedure SincronizarResultados(
      AConn: TUniConnection;
      const AIDEmpresa: Integer;
      const AUUID, AAPIKey: string;
      const AConfig: TEleicaoAPIConfig); static;

    class procedure ProcessarResultado(
      AConn: TUniConnection;
      const AIDEmpresa, AIDEleicao: Integer;
      const AResposta: string); static;

    class procedure GravarResumoResultado(
      AConn: TUniConnection;
      const AIDEmpresa, AIDEleicao: Integer;
      ADados: TJSONObject); static;

    class procedure GravarChapasResultado(
      AConn: TUniConnection;
      const AIDEmpresa, AIDEleicao: Integer;
      AChapas: TJSONArray); static;

    class procedure GravarQuestoesResultado(
      AConn: TUniConnection;
      const AIDEmpresa, AIDEleicao: Integer;
      AQuestoes: TJSONArray); static;

  public
    class function Sincronizar(
      AConn: TUniConnection;
      out AErro: string
    ): Boolean; static;
  end;

implementation

uses
  System.IOUtils;

{ TEleicaoRetornoService }

class function TEleicaoRetornoService.Sincronizar(
  AConn: TUniConnection;
  out AErro: string
): Boolean;
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
        'SELECT id_empresa,guid,token_api '+
        'FROM empresa '+
        'WHERE COALESCE(guid,'''')<>'''' '+
        'AND COALESCE(token_api,'''')<>'''' '+
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

class procedure TEleicaoRetornoService.ProcessarEmpresa(
  AConn: TUniConnection;
  const AIDEmpresa: Integer;
  const AUUID, AAPIKey: string
);
var
  URL, Usuario, Senha: string;
  Config: TEleicaoAPIConfig;
  Resposta, Erro: string;
begin
  if not TDaoConfig.BuscarURLAppEleicao(AConn,URL,Usuario,Senha) then
    raise Exception.Create('Configuração da API da eleição não encontrada.');

  Config   := TEleicaoAPIConfig.Criar(URL,Usuario,Senha);
  Resposta := '';
  Erro     := '';

  if not TEleicaoAPIClient.GetEmpresa(
    Config,
    AUUID,
    AAPIKey,
    '/v1/integracao/easyone/eleicoes/status',
    '',
    Resposta,
    Erro
  ) then
    raise Exception.Create(Erro);

  ProcessarRetorno(AConn,AIDEmpresa,Resposta);

  SincronizarResultados(
    AConn,
    AIDEmpresa,
    AUUID,
    AAPIKey,
    Config
  );
end;

class procedure TEleicaoRetornoService.ProcessarRetorno(
  AConn: TUniConnection;
  const AIDEmpresa: Integer;
  const AResposta: string
);
var
  Json: TJSONObject;
  Dados: TJSONArray;
  Item: TJSONObject;
  I, IDEleicao: Integer;
  Situacao: string;
begin
  Json := TJSONObject.ParseJSONValue(AResposta) as TJSONObject;

  try
    if not Assigned(Json) then
      raise Exception.Create('Retorno inválido da API.');

    Dados := Json.GetValue<TJSONArray>('dados');

    if not Assigned(Dados) then
      Exit;

    for I := 0 to Dados.Count - 1 do
    begin
      if not (Dados.Items[I] is TJSONObject) then
        Continue;

      Item := Dados.Items[I] as TJSONObject;

      IDEleicao := 0;
      Situacao := '';

      if Assigned(Item.GetValue('id_eleicao_int')) then
        IDEleicao := Item.GetValue<Integer>('id_eleicao_int');

      if Assigned(Item.GetValue('situacao')) then
        Situacao := UpperCase(Trim(Item.GetValue<string>('situacao')));

      if IDEleicao <= 0 then
        Continue;

      if not SituacaoValida(Situacao) then
        Continue;

      AtualizarSituacao(AConn,AIDEmpresa,IDEleicao,Situacao);
    end;

  finally
    Json.Free;
  end;
end;

class function TEleicaoRetornoService.SituacaoValida(
  const ASituacao: string
): Boolean;
begin
  Result :=
    MatchText(
      UpperCase(Trim(ASituacao)),
      [
        'AGENDADA',
        'ABERTA',
        'ENCERRADA',
        'EM_APURACAO',
        'APURADA',
        'PUBLICADA'
      ]
    );
end;

class procedure TEleicaoRetornoService.AtualizarSituacao(
  AConn: TUniConnection;
  const AIDEmpresa, AIDEleicao: Integer;
  const ASituacao: string
);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'UPDATE eleicao '+
      'SET situacao=:situacao '+
      'WHERE id_eleicao=:id_eleicao '+
      'AND id_empresa=:id_empresa '+
      'AND COALESCE(situacao,'''')<>:situacao_atual';

    Qry.ParamByName('situacao').AsString := ASituacao;
    Qry.ParamByName('situacao_atual').AsString := ASituacao;
    Qry.ParamByName('id_eleicao').AsInteger := AIDEleicao;
    Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;

    Qry.ExecSQL;

  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoRetornoService.SincronizarResultados(
  AConn: TUniConnection;
  const AIDEmpresa: Integer;
  const AUUID, AAPIKey: string;
  const AConfig: TEleicaoAPIConfig
);
var
  Qry: TUniQuery;
  IDEleicao: Integer;
  Recurso, Resposta, Erro, PrimeiroErro: string;
begin
  PrimeiroErro := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'SELECT e.id_eleicao, UPPER(TRIM(COALESCE(e.situacao,''''))) AS situacao ' +
      'FROM eleicao e ' +
      'LEFT JOIN eleicao_resultado r ON r.id_empresa=e.id_empresa ' +
      '  AND r.id_eleicao=e.id_eleicao ' +
      'WHERE e.id_empresa=:id_empresa ' +
      '  AND UPPER(TRIM(COALESCE(e.situacao,''''))) IN (''APURADA'',''PUBLICADA'') ' +
      '  AND (r.id_resultado IS NULL OR UPPER(TRIM(COALESCE(r.situacao,'''')))<>UPPER(TRIM(COALESCE(e.situacao,'''')))) ' +
      'ORDER BY e.id_eleicao';

    Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
    Qry.Open;

    while not Qry.Eof do
    begin
      IDEleicao := Qry.FieldByName('id_eleicao').AsInteger;
      Recurso := Format(
        '/v1/integracao/easyone/eleicoes/%d/resultado',
        [IDEleicao]
      );

      Resposta := '';
      Erro := '';

      try
        if TEleicaoAPIClient.GetEmpresa(
          AConfig,
          AUUID,
          AAPIKey,
          Recurso,
          '',
          Resposta,
          Erro
        ) then
          ProcessarResultado(AConn,AIDEmpresa,IDEleicao,Resposta)
        else if PrimeiroErro = '' then
          PrimeiroErro := Format('Eleicao %d: %s',[IDEleicao,Erro]);
      except
        on E: Exception do
          if PrimeiroErro = '' then
            PrimeiroErro := Format('Eleicao %d: %s',[IDEleicao,E.Message]);
      end;

      Qry.Next;
    end;
  finally
    Qry.Free;
  end;

  if PrimeiroErro <> '' then
    raise Exception.Create(PrimeiroErro);
end;

class procedure TEleicaoRetornoService.ProcessarResultado(
  AConn: TUniConnection;
  const AIDEmpresa, AIDEleicao: Integer;
  const AResposta: string
);
var
  Json: TJSONObject;
  Dados: TJSONObject;
  Chapas, Questoes: TJSONArray;
  IDEleicaoRetorno: Integer;
begin
  Json := TJSONObject.ParseJSONValue(AResposta) as TJSONObject;
  try
    if not Assigned(Json) then
      raise Exception.Create('Retorno de resultado invalido da API.');

    Dados := Json.GetValue<TJSONObject>('dados');
    if not Assigned(Dados) then
      raise Exception.Create('Dados do resultado nao informados pela API.');

    IDEleicaoRetorno := 0;
    if Assigned(Dados.GetValue('id_eleicao_int')) then
      IDEleicaoRetorno := Dados.GetValue<Integer>('id_eleicao_int');

    if IDEleicaoRetorno <> AIDEleicao then
      raise Exception.Create('ID da eleicao retornado pela API e diferente do solicitado.');

    Chapas := Dados.GetValue<TJSONArray>('chapas');
    Questoes := Dados.GetValue<TJSONArray>('questoes');

    AConn.StartTransaction;
    try
      GravarResumoResultado(AConn,AIDEmpresa,AIDEleicao,Dados);
      GravarChapasResultado(AConn,AIDEmpresa,AIDEleicao,Chapas);
      GravarQuestoesResultado(AConn,AIDEmpresa,AIDEleicao,Questoes);
      AConn.Commit;
    except
      if AConn.InTransaction then
        AConn.Rollback;
      raise;
    end;
  finally
    Json.Free;
  end;
end;

class procedure TEleicaoRetornoService.GravarResumoResultado(
  AConn: TUniConnection;
  const AIDEmpresa, AIDEleicao: Integer;
  ADados: TJSONObject
);
var
  Qry: TUniQuery;
  Resumo: TJSONObject;
  Operacao, Situacao: string;
  TotalEleitores, TotalVotantes, TotalNaoVotantes: Integer;
  TotalVotos, VotosValidos, VotosBrancos, VotosNulos: Integer;
begin
  if not Assigned(ADados) then
    raise Exception.Create('Resultado da eleicao nao informado.');

  Resumo := ADados.GetValue<TJSONObject>('resumo');
  if not Assigned(Resumo) then
    raise Exception.Create('Resumo do resultado nao informado pela API.');

  Operacao := '';
  Situacao := '';
  TotalEleitores := 0;
  TotalVotantes := 0;
  TotalNaoVotantes := 0;
  TotalVotos := 0;
  VotosValidos := 0;
  VotosBrancos := 0;
  VotosNulos := 0;

  if Assigned(ADados.GetValue('operacao')) then
    Operacao := ADados.GetValue<string>('operacao');

  if Assigned(ADados.GetValue('situacao')) then
    Situacao := UpperCase(Trim(ADados.GetValue<string>('situacao')));

  if Assigned(Resumo.GetValue('total_eleitores')) then
    TotalEleitores := Resumo.GetValue<Integer>('total_eleitores');

  if Assigned(Resumo.GetValue('total_votantes')) then
    TotalVotantes := Resumo.GetValue<Integer>('total_votantes');

  if Assigned(Resumo.GetValue('total_nao_votantes')) then
    TotalNaoVotantes := Resumo.GetValue<Integer>('total_nao_votantes');

  if Assigned(Resumo.GetValue('total_votos')) then
    TotalVotos := Resumo.GetValue<Integer>('total_votos');

  if Assigned(Resumo.GetValue('votos_validos')) then
    VotosValidos := Resumo.GetValue<Integer>('votos_validos');

  if Assigned(Resumo.GetValue('votos_brancos')) then
    VotosBrancos := Resumo.GetValue<Integer>('votos_brancos');

  if Assigned(Resumo.GetValue('votos_nulos')) then
    VotosNulos := Resumo.GetValue<Integer>('votos_nulos');

  if not MatchText(Situacao,['APURADA','PUBLICADA']) then
    raise Exception.Create('Situacao do resultado retornado pela API e invalida.');

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      'INSERT INTO eleicao_resultado (' +
      ' id_empresa,id_eleicao,operacao,situacao,total_eleitores,total_votantes, ' +
      ' total_nao_votantes,total_votos,votos_validos,votos_brancos,votos_nulos,recebido_em) ' +
      'VALUES (' +
      ' :id_empresa,:id_eleicao,:operacao,:situacao,:total_eleitores,:total_votantes, ' +
      ' :total_nao_votantes,:total_votos,:votos_validos,:votos_brancos,:votos_nulos,NOW()) ' +
      'ON DUPLICATE KEY UPDATE ' +
      ' operacao=VALUES(operacao),situacao=VALUES(situacao), ' +
      ' total_eleitores=VALUES(total_eleitores),total_votantes=VALUES(total_votantes), ' +
      ' total_nao_votantes=VALUES(total_nao_votantes),total_votos=VALUES(total_votos), ' +
      ' votos_validos=VALUES(votos_validos),votos_brancos=VALUES(votos_brancos), ' +
      ' votos_nulos=VALUES(votos_nulos),recebido_em=NOW()';

    Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
    Qry.ParamByName('id_eleicao').AsInteger := AIDEleicao;
    Qry.ParamByName('operacao').AsString := Operacao;
    Qry.ParamByName('situacao').AsString := Situacao;
    Qry.ParamByName('total_eleitores').AsInteger := TotalEleitores;
    Qry.ParamByName('total_votantes').AsInteger := TotalVotantes;
    Qry.ParamByName('total_nao_votantes').AsInteger := TotalNaoVotantes;
    Qry.ParamByName('total_votos').AsInteger := TotalVotos;
    Qry.ParamByName('votos_validos').AsInteger := VotosValidos;
    Qry.ParamByName('votos_brancos').AsInteger := VotosBrancos;
    Qry.ParamByName('votos_nulos').AsInteger := VotosNulos;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoRetornoService.GravarChapasResultado(
  AConn: TUniConnection;
  const AIDEmpresa, AIDEleicao: Integer;
  AChapas: TJSONArray
);
var
  Qry: TUniQuery;
  Item: TJSONObject;
  I, IDChapa, Numero, QuantidadeVotos: Integer;
  Nome: string;
  Percentual: Double;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'DELETE FROM eleicao_resultado_chapa ' +
      'WHERE id_empresa=:id_empresa AND id_eleicao=:id_eleicao';
    Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
    Qry.ParamByName('id_eleicao').AsInteger := AIDEleicao;
    Qry.ExecSQL;

    if not Assigned(AChapas) then
      Exit;

    for I := 0 to AChapas.Count - 1 do
    begin
      if not (AChapas.Items[I] is TJSONObject) then
        Continue;

      Item := AChapas.Items[I] as TJSONObject;
      IDChapa := 0;
      Numero := 0;
      Nome := '';
      QuantidadeVotos := 0;
      Percentual := 0;

      if Assigned(Item.GetValue('id_chapa_int')) then
        IDChapa := Item.GetValue<Integer>('id_chapa_int');

      if IDChapa <= 0 then
        raise Exception.Create('ID da chapa retornado pela API e invalido.');

      if Assigned(Item.GetValue('numero')) then
        Numero := Item.GetValue<Integer>('numero');

      if Assigned(Item.GetValue('nome')) then
        Nome := Item.GetValue<string>('nome');

      if Assigned(Item.GetValue('quantidade_votos')) then
        QuantidadeVotos := Item.GetValue<Integer>('quantidade_votos');

      if Assigned(Item.GetValue('percentual')) then
        Percentual := Item.GetValue<Double>('percentual');

      Qry.Close;
      Qry.SQL.Text :=
        'INSERT INTO eleicao_resultado_chapa (' +
        ' id_empresa,id_eleicao,id_chapa,numero,nome,quantidade_votos,percentual,recebido_em) ' +
        'VALUES (' +
        ' :id_empresa,:id_eleicao,:id_chapa,:numero,:nome,:quantidade_votos,:percentual,NOW())';

      Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
      Qry.ParamByName('id_eleicao').AsInteger := AIDEleicao;
      Qry.ParamByName('id_chapa').AsInteger := IDChapa;
      Qry.ParamByName('numero').AsInteger := Numero;
      Qry.ParamByName('nome').AsString := Nome;
      Qry.ParamByName('quantidade_votos').AsInteger := QuantidadeVotos;
      Qry.ParamByName('percentual').AsFloat := Percentual;
      Qry.ExecSQL;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TEleicaoRetornoService.GravarQuestoesResultado(
  AConn: TUniConnection;
  const AIDEmpresa, AIDEleicao: Integer;
  AQuestoes: TJSONArray
);
var
  Qry: TUniQuery;
  Questao, Opcao: TJSONObject;
  Opcoes: TJSONArray;
  I, J: Integer;
  IDQuestao, OrdemQuestao, TotalVotos: Integer;
  IDOpcao, OrdemOpcao, QuantidadeVotos: Integer;
  Titulo, Descricao: string;
  Percentual: Double;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;

    Qry.SQL.Text :=
      'DELETE FROM eleicao_resultado_questao_opcao ' +
      'WHERE id_empresa=:id_empresa AND id_eleicao=:id_eleicao';
    Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
    Qry.ParamByName('id_eleicao').AsInteger := AIDEleicao;
    Qry.ExecSQL;

    Qry.Close;
    Qry.SQL.Text :=
      'DELETE FROM eleicao_resultado_questao ' +
      'WHERE id_empresa=:id_empresa AND id_eleicao=:id_eleicao';
    Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
    Qry.ParamByName('id_eleicao').AsInteger := AIDEleicao;
    Qry.ExecSQL;

    if not Assigned(AQuestoes) then
      Exit;

    for I := 0 to AQuestoes.Count - 1 do
    begin
      if not (AQuestoes.Items[I] is TJSONObject) then
        Continue;

      Questao := AQuestoes.Items[I] as TJSONObject;
      IDQuestao := Questao.GetValue<Integer>('id_questao_int',0);
      OrdemQuestao := Questao.GetValue<Integer>('ordem',0);
      Titulo := Questao.GetValue<string>('titulo','');
      TotalVotos := Questao.GetValue<Integer>('total_votos',0);

      if IDQuestao <= 0 then
        raise Exception.Create('ID da questao retornado pela API e invalido.');

      Qry.Close;
      Qry.SQL.Text :=
        'INSERT INTO eleicao_resultado_questao (' +
        ' id_empresa,id_eleicao,id_questao,ordem,titulo,total_votos,recebido_em) ' +
        'VALUES (' +
        ' :id_empresa,:id_eleicao,:id_questao,:ordem,:titulo,:total_votos,NOW())';
      Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
      Qry.ParamByName('id_eleicao').AsInteger := AIDEleicao;
      Qry.ParamByName('id_questao').AsInteger := IDQuestao;
      Qry.ParamByName('ordem').AsInteger := OrdemQuestao;
      Qry.ParamByName('titulo').AsString := Titulo;
      Qry.ParamByName('total_votos').AsInteger := TotalVotos;
      Qry.ExecSQL;

      Opcoes := Questao.GetValue<TJSONArray>('opcoes');
      if not Assigned(Opcoes) then
        Continue;

      for J := 0 to Opcoes.Count - 1 do
      begin
        if not (Opcoes.Items[J] is TJSONObject) then
          Continue;

        Opcao := Opcoes.Items[J] as TJSONObject;
        IDOpcao := Opcao.GetValue<Integer>('id_opcao_int',0);
        OrdemOpcao := Opcao.GetValue<Integer>('ordem',0);
        Descricao := Opcao.GetValue<string>('descricao','');
        QuantidadeVotos := Opcao.GetValue<Integer>('quantidade_votos',0);
        Percentual := Opcao.GetValue<Double>('percentual',0);

        if IDOpcao <= 0 then
          raise Exception.Create('ID da opcao retornado pela API e invalido.');

        Qry.Close;
        Qry.SQL.Text :=
          'INSERT INTO eleicao_resultado_questao_opcao (' +
          ' id_empresa,id_eleicao,id_questao,id_opcao,ordem,descricao,quantidade_votos,percentual,recebido_em) ' +
          'VALUES (' +
          ' :id_empresa,:id_eleicao,:id_questao,:id_opcao,:ordem,:descricao,:quantidade_votos,:percentual,NOW())';
        Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
        Qry.ParamByName('id_eleicao').AsInteger := AIDEleicao;
        Qry.ParamByName('id_questao').AsInteger := IDQuestao;
        Qry.ParamByName('id_opcao').AsInteger := IDOpcao;
        Qry.ParamByName('ordem').AsInteger := OrdemOpcao;
        Qry.ParamByName('descricao').AsString := Descricao;
        Qry.ParamByName('quantidade_votos').AsInteger := QuantidadeVotos;
        Qry.ParamByName('percentual').AsFloat := Percentual;
        Qry.ExecSQL;
      end;
    end;
  finally
    Qry.Free;
  end;
end;

end.
