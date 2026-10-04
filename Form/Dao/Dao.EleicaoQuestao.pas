unit Dao.EleicaoQuestao;

interface

uses
  Uni,
  Model.EleicaoQuestao;

type
  TDaoEleicaoQuestao = class
  public
    class function BuscarParaSincronizacaoQuestao(AConn: TUniConnection; const AIDRegistro: Integer): TEleicaoQuestaoEnvioDTO; static;
    class procedure AtualizarSincronizacaoQuestao(AConn: TUniConnection; const AIDRegistro: Integer); static;

    //Opcao
    class function BuscarParaSincronizacaoQuestaoOpcao(AConn: TUniConnection; const AIDRegistro: Integer): TEleicaoQuestaoOpcaoEnvioDTO; static;
    class procedure AtualizarSincronizacaoQuestaoOpcao(AConn: TUniConnection; const AIDRegistro: Integer); static;

  end;

implementation

uses
  System.SysUtils;

{ TDaoEleicaoQuestao }

{$REGION 'Questao'}

class procedure TDaoEleicaoQuestao.AtualizarSincronizacaoQuestao(
  AConn: TUniConnection; const AIDRegistro: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE eleicao_questao SET sinc_app=''N'' WHERE id_questao= :id';
    Qry.ParamByName('id').AsInteger := AIDRegistro;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class function TDaoEleicaoQuestao.BuscarParaSincronizacaoQuestao(AConn: TUniConnection;
  const AIDRegistro: Integer): TEleicaoQuestaoEnvioDTO;
const
  SQL =
    'SELECT e.id_questao, e.id_eleicao, e.titulo, e.descricao, e.ordem, e.tipo_resposta, e.obrigatoria,'+
    ' e.ativo, ee.guid,ee.token_api FROM eleicao_questao e   '+
    ' INNER JOIN empresa ee ON ee.id_empresa=e.id_empresa '+
    ' WHERE e.id_questao= :id AND e.sinc_app=''S'' LIMIT 1';
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := SQL;
    Qry.ParamByName('id').AsInteger := AIDRegistro;
    Qry.Open;

    if Qry.IsEmpty then Exit;

    Result := TEleicaoQuestaoEnvioDTO.Create;
    try
      Result.id_questao     :=Qry.FieldByName('id_questao').AsInteger;
      Result.id_eleicao     :=Qry.FieldByName('id_eleicao').AsInteger;

      Result.titulo         :=Trim(Qry.FieldByName('titulo').AsString);
      Result.descricao      :=Trim(Qry.FieldByName('descricao').AsString);
      Result.ordem          :=Qry.FieldByName('ordem').AsInteger;
      Result.tipo_resposta  :=Trim(Qry.FieldByName('tipo_resposta').AsString);
      Result.obrigatoria    :=Trim(Qry.FieldByName('obrigatoria').AsString);
      Result.ativo          :=Trim(Qry.FieldByName('ativo').AsString);
      Result.GuidEmpresa    :=Trim(Qry.FieldByName('guid').AsString);
      Result.APIKey         :=Trim(Qry.FieldByName('token_api').AsString);

    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

{$ENDREGION}

{$REGION 'Opcao'}

class procedure TDaoEleicaoQuestao.AtualizarSincronizacaoQuestaoOpcao(
  AConn: TUniConnection; const AIDRegistro: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE eleicao_questao_opcao SET sinc_app=''N'' WHERE id_opcao= :id';
    Qry.ParamByName('id').AsInteger := AIDRegistro;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class function TDaoEleicaoQuestao.BuscarParaSincronizacaoQuestaoOpcao(
  AConn: TUniConnection;
  const AIDRegistro: Integer): TEleicaoQuestaoOpcaoEnvioDTO;
const
  SQL =
    'SELECT SELECT q.id_opcao, q.id_questao, q.id_eleicao, q.ordem, q.descricao, q.ativo,'+
    ' ee.guid,ee.token_api FROM eleicao_questao_opcao q '+
    ' INNER JOIN empresa ee ON ee.id_empresa=q.id_empresa '+
    ' WHERE q.id_opcao= :id AND q.sinc_app=''S'' LIMIT 1';
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := SQL;
    Qry.ParamByName('id').AsInteger := AIDRegistro;
    Qry.Open;

    if Qry.IsEmpty then Exit;

    Result := TEleicaoQuestaoOpcaoEnvioDTO.Create;
    try
      Result.id_opcao       :=Qry.FieldByName('id_opcao').AsInteger;
      Result.id_questao     :=Qry.FieldByName('id_questao').AsInteger;
      Result.id_eleicao     :=Qry.FieldByName('id_eleicao').AsInteger;
      Result.ordem          :=Qry.FieldByName('ordem').AsInteger;
      Result.descricao      :=Trim(Qry.FieldByName('descricao').AsString);
      Result.ativo          :=Trim(Qry.FieldByName('ativo').AsString);
      Result.GuidEmpresa    :=Trim(Qry.FieldByName('guid').AsString);
      Result.APIKey         :=Trim(Qry.FieldByName('token_api').AsString);

    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

{$ENDREGION}


end.
