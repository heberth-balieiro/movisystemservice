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

    class procedure AtualizarSituacao(AConn: TUniConnection;const AIDEmpresa, AIDEleicao: Integer;
      const ASituacao: string); static;

    class function SituacaoValida(const ASituacao: string): Boolean; static;

  public
    class function Sincronizar(AConn: TUniConnection; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.IOUtils;

{ TEleicaoRetornoService }

class function TEleicaoRetornoService.Sincronizar(AConn: TUniConnection; out AErro: string): Boolean;
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
        ProcessarEmpresa(AConn,
          Qry.FieldByName('id_empresa').AsInteger,
          Trim(Qry.FieldByName('guid').AsString),
          Trim(Qry.FieldByName('token_api').AsString));

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

class procedure TEleicaoRetornoService.ProcessarEmpresa(AConn: TUniConnection;const AIDEmpresa: Integer;
  const AUUID, AAPIKey: string
);
var
  URL, Usuario, Senha: string;
  Config: TEleicaoAPIConfig;
  Resposta, Erro: string;
begin
  if not TDaoConfig.BuscarURLAppEleicao(AConn,URL,Usuario,Senha) then
    raise Exception.Create('Configuração da API da eleição não encontrada.');

  Config    := TEleicaoAPIConfig.Criar(URL,Usuario,Senha);
  Resposta  := '';
  Erro      := '';

  if not TEleicaoAPIClient.GetEmpresa(Config,AUUID,AAPIKey,'/v1/integracao/easyone/eleicoes/status','', Resposta,Erro) then
    raise Exception.Create(Erro);

  ProcessarRetorno(AConn,AIDEmpresa,Resposta);
end;

class procedure TEleicaoRetornoService.ProcessarRetorno(AConn: TUniConnection;const AIDEmpresa: Integer; const AResposta: string);
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

      AtualizarSituacao(AConn, AIDEmpresa, IDEleicao, Situacao);
    end;

  finally
    Json.Free;
  end;
end;

class function TEleicaoRetornoService.SituacaoValida(const ASituacao: string): Boolean;
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

class procedure TEleicaoRetornoService.AtualizarSituacao(AConn: TUniConnection; const AIDEmpresa, AIDEleicao: Integer;
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

end.
