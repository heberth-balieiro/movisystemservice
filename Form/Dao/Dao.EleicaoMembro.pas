unit Dao.EleicaoMembro;

interface

uses
  Uni,
  Data.DB,
  Model.EleicaoMembro;

type
  TDaoEleicaoMembro = class
  private
    class function BlobParaBase64(const AField: TField): string; static;
  public
    class function BuscarParaSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer): TEleicaoMembroEnvioDTO; static;
    class procedure AtualizarSincronizacao(AConn: TUniConnection; const AIDRegistro: Integer); static;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.NetEncoding;

class function TDaoEleicaoMembro.BlobParaBase64(const AField: TField): string;
var
  Stream: TMemoryStream;
  Bytes: TBytes;
begin
  Result := '';
  if not Assigned(AField) or AField.IsNull then Exit;

  Stream := TMemoryStream.Create;
  try
    TBlobField(AField).SaveToStream(Stream);
    if Stream.Size <= 0 then Exit;

    SetLength(Bytes,Stream.Size);
    Stream.Position := 0;
    Stream.ReadBuffer(Bytes[0],Length(Bytes));

    Result := TNetEncoding.Base64.EncodeBytesToString(Bytes);
  finally
    Stream.Free;
  end;
end;

class procedure TDaoEleicaoMembro.AtualizarSincronizacao(AConn: TUniConnection;const AIDRegistro: Integer);
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text := 'UPDATE eleicao_chapa_membro SET sinc_app=''N'' WHERE id=:id';
    Qry.ParamByName('id').AsInteger := AIDRegistro;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

class function TDaoEleicaoMembro.BuscarParaSincronizacao(AConn: TUniConnection;
  const AIDRegistro: Integer): TEleicaoMembroEnvioDTO;
const
  SQL =
    'SELECT m.id, m.id_eleicao, m.id_chapa, m.codigo, m.nome, m.cpf, m.telefone, m.email, m.ativo,'+
    ' m.cargo, m.tipo, m.observacao, m.arquivo_foto, m.extensao_foto, e.guid, e.token_api '+
    ' FROM eleicao_chapa_membro m '+
    ' INNER JOIN empresa e ON e.id_empresa=m.id_empresa '+
    ' WHERE m.id=:id and m.sinc_app=''S'' LIMIT 1';
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

    Result := TEleicaoMembroEnvioDTO.Create;
    try
      Result.IdMembro       := Qry.FieldByName('id').AsInteger;
      Result.IdEleicao      := Qry.FieldByName('id_eleicao').AsInteger;
      Result.IdChapa        := Qry.FieldByName('id_chapa').AsInteger;
      Result.Codigo         := Qry.FieldByName('codigo').AsInteger;
      Result.Nome           := Trim(Qry.FieldByName('nome').AsString);
      Result.CPF            := Trim(Qry.FieldByName('cpf').AsString);
      Result.Telefone       := Trim(Qry.FieldByName('telefone').AsString);
      Result.Email          := Trim(Qry.FieldByName('email').AsString);
      Result.Ativo          := Trim(Qry.FieldByName('ativo').AsString);
      Result.Cargo          := Trim(Qry.FieldByName('cargo').AsString);
      Result.Tipo           := Trim(Qry.FieldByName('tipo').AsString);
      Result.Observacao     := Trim(Qry.FieldByName('observacao').AsString);
      Result.ArquivoFoto    := BlobParaBase64(Qry.FieldByName('arquivo_foto'));
      Result.ExtensaoFoto   := Trim(Qry.FieldByName('extensao_foto').AsString);
      Result.GuidEmpresa    := Trim(Qry.FieldByName('guid').AsString);
      Result.APIKey         := Trim(Qry.FieldByName('token_api').AsString);
    except
      Result.Free;
      raise;
    end;
  finally
    Qry.Free;
  end;
end;

end.
