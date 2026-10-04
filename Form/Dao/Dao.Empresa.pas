unit Dao.Empresa;

interface

uses
  System.SysUtils,
  Data.DB,
  Uni,
  Model.Empresa;

type
  TDaoEmpresa = class
  public
    class function BuscarParaSincronizacao(AConn: TUniConnection; const AIDEmpresa: Integer): TEmpresaModel; static;
    class procedure AtualizarSincronizacao(AConn: TUniConnection; const AIDEmpresa: Integer); static;
    class procedure AtualizarAPIKey(AConn: TUniConnection; const AIDEmpresa: Integer; const AAPIKey: string); static;
  end;

implementation

{ TDaoEmpresa }

class function TDaoEmpresa.BuscarParaSincronizacao(AConn: TUniConnection; const AIDEmpresa: Integer): TEmpresaModel;
const
  SQL_EMPRESA =
    'Select e.id_empresa, e.guid, e.razao, e.fantasia, e.telefone, e.cnpj,    '+
	  ' nf.urlapiwhatsapp, nf.whatsapp_apikey, e.token_api '+
	  ' from empresa e                        '+
    ' Inner Join configuracao_nf nf         '+
    ' on e.id_empresa = nf.id_empresa       ' +
    ' WHERE e.id_empresa= :id_empresa ' +
    ' AND e.sinc_app=''S'' ' +
    ' LIMIT 1';
var
  Qry: TUniQuery;
begin
  Result := nil;

  if not Assigned(AConn) then
    raise Exception.Create('Conexão não informada.');

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection  := AConn;
    Qry.SQL.Text    := SQL_EMPRESA;
    Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
    Qry.Open;

    if Qry.IsEmpty then
      Exit;

    Result := TEmpresaModel.Create;
    try
      Result.IdEmpresa      := Qry.FieldByName('id_empresa').AsInteger;
      Result.UUID           := Trim(Qry.FieldByName('guid').AsString);
      Result.Razao          := Trim(Qry.FieldByName('razao').AsString);
      Result.Fantasia       := Trim(Qry.FieldByName('fantasia').AsString);
      Result.Telefone       := Trim(Qry.FieldByName('telefone').AsString);
      Result.CPFCNPJ        := Trim(Qry.FieldByName('cnpj').AsString);
      Result.Ativo          := 'S';
      Result.WhatsAppURL    := Trim(Qry.FieldByName('urlapiwhatsapp').AsString);
      Result.WhatsAppToken  := Trim(Qry.FieldByName('whatsapp_apikey').AsString);
      Result.EasyOneAPIKey  := Trim(Qry.FieldByName('token_api').AsString);

      Result.EasyOneIntegracaoAtivo := 'S';
    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

class procedure TDaoEmpresa.AtualizarAPIKey(AConn: TUniConnection; const AIDEmpresa: Integer; const AAPIKey: string);
var
  Qry: TUniQuery;
begin
  if not Assigned(AConn) then
    raise Exception.Create('Conexão não informada.');

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE empresa SET token_api= :api_key WHERE id_empresa=:id_empresa';
    Qry.ParamByName('api_key').AsString     := Trim(AAPIKey);
    Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TDaoEmpresa.AtualizarSincronizacao(AConn: TUniConnection; const AIDEmpresa: Integer);
var
  Qry: TUniQuery;
begin
  if not Assigned(AConn) then
    raise Exception.Create('Conexão não informada.');

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE empresa SET sinc_app=''N'' WHERE id_empresa=:id_empresa';
    Qry.ParamByName('id_empresa').AsInteger := AIDEmpresa;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
