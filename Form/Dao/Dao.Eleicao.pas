unit Dao.Eleicao;

interface

uses
  Uni,
  Model.Eleicao;

type
  TDaoEleicao = class
  public
    class function BuscarParaSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer): TEleicaoEnvioDTO; static;
    class procedure AtualizarSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer); static;
  end;

implementation

uses
  System.SysUtils;

class function TDaoEleicao.BuscarParaSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer): TEleicaoEnvioDTO;
const
  SQL =
    'SELECT el.id_eleicao, el.codigo, el.nome, el.descricao, el.ano, el.ano_fim, '+
    ' el.ativo, el.tipo, el.situacao, el.operacao, emp.guid, emp.token_api '+
    'FROM eleicao el '+
    ' INNER JOIN empresa emp '+
    ' ON emp.id_empresa=el.id_empresa '+
    ' WHERE el.id_eleicao= :id_eleicao and el.sinc_app=''S'' and el.situacao=''AGENDADA'' '+
    ' LIMIT 1';
var
  Qry: TUniQuery;
begin
  Result := nil;

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := SQL;
    Qry.ParamByName('id_eleicao').AsInteger := AIDRegistro;
    Qry.Open;

    if Qry.IsEmpty then Exit;

    Result := TEleicaoEnvioDTO.Create;
    try
      Result.IdEleicao   := Qry.FieldByName('id_eleicao').AsInteger;
      Result.Codigo      := Qry.FieldByName('codigo').AsInteger;
      Result.Nome        := Trim(Qry.FieldByName('nome').AsString);
      Result.Descricao   := Trim(Qry.FieldByName('descricao').AsString);
      Result.Ano         := Qry.FieldByName('ano').AsInteger;
      Result.AnoFim      := Qry.FieldByName('ano_fim').AsInteger;
      Result.Ativo       := Trim(Qry.FieldByName('ativo').AsString);
      Result.Tipo        := Trim(Qry.FieldByName('tipo').AsString);
      Result.Situacao    := Trim(Qry.FieldByName('situacao').AsString);
      Result.GuidEmpresa := Trim(Qry.FieldByName('guid').AsString);
      Result.APIKey      := Trim(Qry.FieldByName('token_api').AsString);
      Result.operacao    := Trim(Qry.FieldByName('operacao').AsString);
    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TDaoEleicao.AtualizarSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE eleicao SET sinc_app=''N'' WHERE id_eleicao=:id_eleicao';
    Qry.ParamByName('id_eleicao').AsInteger := AIDRegistro;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
