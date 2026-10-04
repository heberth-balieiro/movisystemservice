unit Dao.UsuarioSistema;

interface

uses
  Uni,
  Model.UsuarioSistema, UConeSul;

type
  TDaoUsuarioSistema = class
  private

  public
    class function BuscarParaSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer): TUsuarioSistemaEnvioDTO; static;
    class function BuscarParaSincronizacaoAPTOS(AConn: TUniConnection; const AIDRegistro: Integer): TUsuarioAPTOSEnvioDTO; static;
    class function BuscarParaSincronizacaoComissao(AConn: TUniConnection; const AIDRegistro: Integer):TComissaoEleitoralEnvioDTO; static;

    class procedure AtualizarSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer); static;
    class procedure AtualizarSincronizacaoAPTOS(AConn: TUniConnection; const AIDRegistro,AIDAPI: Integer); static;
    class procedure AtualizarSincronizacaoComissao(AConn: TUniConnection;
      const AIDRegistro: Integer); static;
  end;

implementation

uses
  System.SysUtils;

class function TDaoUsuarioSistema.BuscarParaSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer): TUsuarioSistemaEnvioDTO;
const
  SQL =
    'SELECT u.id_usuario,u.nome,u.login,u.senha,u.ativo,u.email,u.sistema,u.excluido,e.guid,e.token_api '+
    'FROM usuario u '+
    'INNER JOIN empresa e ON e.id_empresa=u.id_empresa '+
    'WHERE u.id_usuario=:id_usuario AND u.sinc_app=''S'' LIMIT 1';
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := SQL;
    Qry.ParamByName('id_usuario').AsInteger := AIDRegistro;
    Qry.Open;

    if Qry.IsEmpty then Exit;

    Result             := TUsuarioSistemaEnvioDTO.Create;
    Result.IdUsuario   := Qry.FieldByName('id_usuario').AsInteger;
    Result.Nome        := Trim(Qry.FieldByName('nome').AsString);
    Result.Login       := Trim(Qry.FieldByName('login').AsString);
    Result.Senha       := Trim(Qry.FieldByName('senha').AsString);
    Result.Ativo       := Trim(Qry.FieldByName('ativo').AsString);
    Result.Email       := Trim(Qry.FieldByName('email').AsString);
    //Result.Sistema     := Trim(Qry.FieldByName('sistema').AsString);
    Result.Excluido    := Qry.FieldByName('excluido').AsInteger;
    Result.GuidEmpresa := Trim(Qry.FieldByName('guid').AsString);
    Result.APIKey      := Trim(Qry.FieldByName('token_api').AsString);
  finally
    Qry.Free;
  end;
end;

class function TDaoUsuarioSistema.BuscarParaSincronizacaoAPTOS(AConn: TUniConnection;
                                const AIDRegistro: Integer): TUsuarioAPTOSEnvioDTO;
const
  SQL =
    'SELECT                    '+
    ' s.nome,       '+
    ' s.cpf,        '+
    ' s.matricula,  '+
    ' s.email,      '+
    ' ee.id_eleitor,'+
    ' ee.id_associado,'+
    ' ep.guid,      '+
    ' ep.token_api  '+

    ' FROM eleicao_eleitor ee '+
    ' INNER JOIN empresa ep '+
    ' ON ep.id_empresa = ee.id_empresa '+
    ' INNER JOIN socio s '+
    ' ON ee.id_associado = s.id_socio  '+
    ' WHERE ee.id_eleitor = :id_eleitor AND ee.sinc_app=''S'' LIMIT 1';
var
  Qry: TUniQuery;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := SQL;
    Qry.ParamByName('id_eleitor').AsInteger := AIDRegistro;
    Qry.Open;

    if Qry.IsEmpty then
    Exit;

    Result             := TUsuarioAPTOSEnvioDTO.Create;
    Result.ideleitor   := Qry.FieldByName('id_eleitor').AsInteger;
    Result.idassociado := Qry.FieldByName('id_associado').AsInteger;
    Result.Nome        := Trim(Qry.FieldByName('nome').AsString);
    Result.Login       := Trim(Qry.FieldByName('cpf').AsString);
    Result.Senha       := Qry.FieldByName('matricula').ToString;
    Result.Ativo       := 'S';
    Result.Email       := Trim(Qry.FieldByName('email').AsString);
    Result.GuidEmpresa := Trim(Qry.FieldByName('guid').AsString);
    Result.APIKey      := Trim(Qry.FieldByName('token_api').AsString);
  finally
    Qry.Free;
  end;
end;

class procedure TDaoUsuarioSistema.AtualizarSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE usuario SET sinc_app=''N'' WHERE id_usuario=:id_usuario';
    Qry.ParamByName('id_usuario').AsInteger := AIDRegistro;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class procedure TDaoUsuarioSistema.AtualizarSincronizacaoAPTOS(AConn: TUniConnection; const AIDRegistro,AIDAPI: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE eleicao_eleitor SET sinc_app=''N'', id_usuario_api= :id WHERE id_eleitor=:id_eleitor';
    Qry.ParamByName('id_eleitor').AsInteger := AIDRegistro;
    Qry.ParamByName('id').AsInteger         := AIDAPI;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;



//comisaso
class function TDaoUsuarioSistema.BuscarParaSincronizacaoComissao(
  AConn: TUniConnection; const AIDRegistro: Integer): TComissaoEleitoralEnvioDTO;
const
  SQL =
    'SELECT ec.id_comissao, ec.id_eleicao, ec.nome, ec.cpf, ec.telefone, '+
    ' ec.email, ec.cargo, ec.ativo, e.guid, e.token_api '+
    ' from eleicao_comissao ec '+
    ' INNER JOIN empresa e '+
    ' ON e.id_empresa = ec.id_empresa '+
    ' WHERE ec.id_comissao= :idcomissao and ec.sinc_app=''S'' LIMIT 1';
var
  Qry: TUniQuery;
  Asenha  :String;
begin
  Result := nil;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := SQL;
    Qry.ParamByName('idcomissao').AsInteger := AIDRegistro;
    Qry.Open;

    if Qry.IsEmpty then Exit;

    ASenha             := Copy(Qry.FieldByName('cpf').AsString,1,5);
    ASenha             := TConeSul.Crypt('C',ASenha);

    Result             := TComissaoEleitoralEnvioDTO.Create;
    Result.IdComissao  := Qry.FieldByName('id_comissao').AsInteger;
    Result.IdEleicao   := Qry.FieldByName('id_eleicao').AsInteger;
    Result.Nome        := Trim(Qry.FieldByName('nome').AsString);
    Result.CPF         := Trim(Qry.FieldByName('cpf').AsString);
    Result.Telefone    := Trim(Qry.FieldByName('telefone').AsString);
    Result.Email       := Trim(Qry.FieldByName('email').AsString);
    Result.Cargo       := Trim(Qry.FieldByName('cargo').AsString);
    Result.Ativo       := Trim(Qry.FieldByName('ativo').AsString);
    Result.Senha       := ASenha;
    Result.GuidEmpresa := Trim(Qry.FieldByName('guid').AsString);
    Result.APIKey      := Trim(Qry.FieldByName('token_api').AsString);
  finally
    Qry.Free;
  end;
end;


class procedure TDaoUsuarioSistema.AtualizarSincronizacaoComissao(AConn: TUniConnection; const AIDRegistro: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE eleicao_comissao SET sinc_app=''N'' WHERE id_comissao= :id_comissao';
    Qry.ParamByName('id_comissao').AsInteger := AIDRegistro;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;
end.
