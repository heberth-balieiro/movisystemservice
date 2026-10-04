unit Dao.Config;

interface

uses
  Uni;

type
  TDaoConfig = class
  public
    class function BuscarURLAppEleicao(AConn: TUniConnection; out AUrl, AUser, ASenha: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

{ TDaoConfig }

class function TDaoConfig.BuscarURLAppEleicao(AConn: TUniConnection; out AUrl, AUser, ASenha: string): Boolean;
const
  SqlQuery = 'SELECT eleicao_api, eleicao_usuario, eleicao_senha FROM configuracao_nf LIMIT 1';
var
  Qry: TUniQuery;
begin
  Result := False;
  AUrl   := '';
  AUser  := '';
  ASenha := '';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := SqlQuery;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    AUrl   := Trim(Qry.FieldByName('eleicao_api').AsString);
    AUser  := Trim(Qry.FieldByName('eleicao_usuario').AsString);
    ASenha := Trim(Qry.FieldByName('eleicao_senha').AsString);

    Result := not AUrl.IsEmpty;
  finally
    Qry.Free;
  end;
end;

end.
