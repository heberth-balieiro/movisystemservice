unit Dao.Associado;

interface

uses
  Uni,
  Model.Associado;

type
  TDaoAssociado = class
  public
    class function BuscarParaSincronizacao(AConn: TUniConnection; const ARegistro: Integer; const AForcar: Boolean = False): TAssociadoEnvioDTO; static;
    class procedure AtualizarSincronizacao(AConn: TUniConnection; const ARegistro: Integer); static;
  end;

implementation

uses
  System.SysUtils;

class function TDaoAssociado.BuscarParaSincronizacao(AConn: TUniConnection; const ARegistro: Integer; const AForcar: Boolean): TAssociadoEnvioDTO;
var
  Qry: TUniQuery;
  SQL: string;
begin
  Result := nil;

  SQL :=
    'SELECT s.id_socio,s.codigo,COALESCE(s.matricula,0) matricula,s.socio_deste,s.situacao,s.nome,s.apelido,'+
    's.telefone,s.celular,s.whatsapp,s.cpf,s.nascimento,s.email,s.foto,s.bloqueado,s.excluido,s.rg,s.pai,s.mae,'+
    'c.cidade,ss.razao secretaria,sp.descricao profissao,sl.descricao lotacao,st.descricao localtrabalho,'+
    's.profissao funcao,cc.cidade naturalde,e.guid,e.token_api '+
    'FROM socio s '+
    'INNER JOIN empresa e ON e.id_empresa=s.id_empresa '+
    'LEFT JOIN cidade c ON c.id_cidade=s.id_cidade '+
    'LEFT JOIN secretaria ss ON ss.id_secretaria=s.escritorio '+
    'LEFT JOIN sindicato_profissao sp ON sp.id_profissao=s.id_profissao '+
    'LEFT JOIN sindicato_lotacao sl ON sl.id_lotacao=s.id_lotacao '+
    'LEFT JOIN sindicato_local_trabalho st ON st.id_local=s.id_localtrabalho '+
    'LEFT JOIN cidade cc ON cc.id_cidade=s.natural_cidade '+
    'WHERE s.id_socio= :id_socio ';

  if not AForcar then
    SQL := SQL + 'AND s.sinc_app=''S'' ';

  SQL := SQL + 'LIMIT 1';

  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := SQL;
    Qry.ParamByName('id_socio').AsInteger := ARegistro;
    Qry.Open;

    if Qry.IsEmpty then Exit;

    Result              := TAssociadoEnvioDTO.Create;
    Result.IdSocio      := Qry.FieldByName('id_socio').AsInteger;
    Result.Codigo       := Qry.FieldByName('codigo').AsInteger;
    Result.Matricula    := Qry.FieldByName('matricula').AsInteger;
    Result.Ativo        := 'S';//Trim(Qry.FieldByName('situacao').AsString);
    Result.Nome         := Trim(Qry.FieldByName('nome').AsString);
    Result.Apelido      := Trim(Qry.FieldByName('apelido').AsString);
    Result.Telefone     := Trim(Qry.FieldByName('telefone').AsString);
    Result.Celular      := Trim(Qry.FieldByName('celular').AsString);
    Result.WhatsApp     := Trim(Qry.FieldByName('whatsapp').AsString);
    Result.CPF          := Trim(Qry.FieldByName('cpf').AsString);
    Result.Nascimento   := Qry.FieldByName('nascimento').AsDateTime;
    Result.Email        := Trim(Qry.FieldByName('email').AsString);
    Result.Cidade       := Trim(Qry.FieldByName('cidade').AsString);
    Result.Secretaria   := Trim(Qry.FieldByName('secretaria').AsString);
    Result.Profissao    := Trim(Qry.FieldByName('profissao').AsString);
    Result.Lotacao      := Trim(Qry.FieldByName('lotacao').AsString);
    Result.LocalTrabalho:= Trim(Qry.FieldByName('localtrabalho').AsString);
    Result.Funcao       := Trim(Qry.FieldByName('funcao').AsString);
    Result.NaturalDe    := Trim(Qry.FieldByName('naturalde').AsString);
    Result.RG           := Trim(Qry.FieldByName('rg').AsString);
    Result.DataFiliacao := Qry.FieldByName('socio_deste').AsDateTime;
    Result.Pai          := Trim(Qry.FieldByName('pai').AsString);
    Result.Mae          := Trim(Qry.FieldByName('mae').AsString);
    Result.Foto         := Qry.FieldByName('foto').AsString;
    Result.Bloqueado    := Trim(Qry.FieldByName('bloqueado').AsString);
    Result.Excluido     := Qry.FieldByName('excluido').AsInteger;
    Result.GuidEmpresa  := Trim(Qry.FieldByName('guid').AsString);
    Result.APIKey       := Trim(Qry.FieldByName('token_api').AsString);
  finally
    Qry.Free;
  end;
end;

class procedure TDaoAssociado.AtualizarSincronizacao(AConn: TUniConnection; const ARegistro: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE socio SET sinc_app=''N'' WHERE id_socio=:id_socio';
    Qry.ParamByName('id_socio').AsInteger := ARegistro;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

end.
