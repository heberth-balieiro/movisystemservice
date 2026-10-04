unit Dao.EleicaoChapa;

interface

uses
  Uni,
  Model.EleicaoChapa;

type
  TDaoEleicaoChapa = class
  public
    class function BuscarParaSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer): TEleicaoChapaEnvioDTO; static;
    class procedure AtualizarSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer); static;
  end;

implementation

uses
  System.SysUtils;

class function TDaoEleicaoChapa.BuscarParaSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer): TEleicaoChapaEnvioDTO;
const
  SQL =
    'SELECT c.id,c.codigo,c.id_eleicao,c.situacao,c.num_chapa,c.nome_chapa,'+
    ' c.slogan,c.obs,c.ativo,e.guid,e.token_api '+
    ' FROM eleicao_chapa c '+
    ' INNER JOIN empresa e ON e.id_empresa=c.id_empresa '+
    ' WHERE c.id= :id AND c.sinc_app=''S'' LIMIT 1';
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

    Result := TEleicaoChapaEnvioDTO.Create;
    try
      Result.IdChapa     := Qry.FieldByName('id').AsInteger;
      Result.Codigo      := Qry.FieldByName('codigo').AsInteger;
      Result.IdEleicao   := Qry.FieldByName('id_eleicao').AsInteger;
      Result.Situacao    := UpperCase(Trim(Qry.FieldByName('situacao').AsString));
      Result.NumChapa    := Qry.FieldByName('num_chapa').AsInteger;
      Result.NomeChapa   := Trim(Qry.FieldByName('nome_chapa').AsString);
      Result.Slogan      := Trim(Qry.FieldByName('slogan').AsString);
      Result.Obs         := Trim(Qry.FieldByName('obs').AsString);
      Result.Ativo       := Trim(Qry.FieldByName('ativo').AsString);
      Result.GuidEmpresa := Trim(Qry.FieldByName('guid').AsString);
      Result.APIKey      := Trim(Qry.FieldByName('token_api').AsString);
    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TDaoEleicaoChapa.AtualizarSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE eleicao_chapa SET sinc_app=''N'' WHERE id=:id';
    Qry.ParamByName('id').AsInteger := AIDRegistro;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
