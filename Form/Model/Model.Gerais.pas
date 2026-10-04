unit Model.Gerais;

interface

Uses
  Uni;

Type
  TModelGerais = Class
    Private
      FTransacao  : TUniTransaction;

    Public
      Conexao : TUniconnection;
      Constructor Create(conn :Tuniconnection);
      Destructor Destroy;override;

      Function BuscarURLAppCarteira(out url, usuario, senha, token: string): boolean;
      Function BuscarURLAppVeiculo(out url,usuario, senha, token: string): boolean;
      function BuscarURLAppEleicao(out url, usuario, senha, token: string): boolean;

      Function ContaRegistrosPendentes(const tabela, campo,ordem: string): Integer;
      Function GravarLogBanco(Tabela,Msg:string):Boolean;
      function AtualizarRegistroSincronizado(tabela, campo, params: String;id: integer): Boolean;
  End;

implementation

uses
  System.SysUtils;

{ TModelGerais }

function TModelGerais.BuscarURLAppCarteira(out url, usuario, senha, token: string): boolean;
const
  SqlQuery = 'SELECT carteira_api, carteira_usuario, carteira_senha, carteira_token FROM configuracao_nf LIMIT 1';
var
  Qry: TUniQuery;
begin
  // Valor padrão em caso de erro ou sem registro
  Result  := False;
  url     := '';
  usuario := '';
  senha   := '';
  token   := '';

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := conexao;
    Qry.SQL.Text   := SqlQuery;

    try
      Qry.Open;

      if not Qry.IsEmpty then
      begin
        // Só retorna True se o campo "url" vier preenchido
        url       := Trim(Qry.FieldByName('carteira_api').AsString);
        if url <> '' then
        begin
          usuario := Trim(Qry.FieldByName('carteira_usuario').AsString);
          senha   := Trim(Qry.FieldByName('carteira_senha').AsString);
          token   := Trim(Qry.FieldByName('carteira_token').AsString);
          Result  := True;
        end;
      end;

    except
      on E: Exception do
      begin
        // Em caso de erro, mantém Result=False e limpa os outs
        url     := '';
        usuario := '';
        senha   := '';
        token   := '';
      end;
    end;

  finally
    Qry.Free;
  end;
end;

function TModelGerais.BuscarURLAppVeiculo(out url, usuario, senha, token: string): boolean;
const
  SqlQuery = 'Select veiculo_api, veiculo_usuario, veiculo_senha, veiculo_token from configuracao_nf limit 1';
var
  Qry: TUniQuery;
begin
  // Valor padrão em caso de erro ou sem registro
  Result  := False;
  url     := '';
  usuario := '';
  senha   := '';
  token   := '';

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := conexao;
    Qry.SQL.Text   := SqlQuery;

    try
      Qry.Open;

      if not Qry.IsEmpty then
      begin
        // Só retorna True se o campo "url" vier preenchido
        url       := Trim(Qry.FieldByName('veiculo_api').AsString);
        if url <> '' then
        begin
          usuario := Trim(Qry.FieldByName('veiculo_usuario').AsString);
          senha   := Trim(Qry.FieldByName('veiculo_senha').AsString);
          token   := Trim(Qry.FieldByName('veiculo_token').AsString);
          Result  := True;
        end;
      end;

    except
      on E: Exception do
      begin
        // Em caso de erro, mantém Result=False e limpa os outs
        url     := '';
        usuario := '';
        senha   := '';
        token   := '';
      end;
    end;

  finally
    Qry.Free;
  end;
end;

function TModelGerais.BuscarURLAppEleicao(out url, usuario, senha, token: string): boolean;
const
  SqlQuery = 'Select eleicao_api, eleicao_usuario, eleicao_senha, eleicao_token from configuracao_nf limit 1';
var
  Qry: TUniQuery;
begin
  // Valor padrão em caso de erro ou sem registro
  Result  := False;
  url     := '';
  usuario := '';
  senha   := '';
  token   := '';

  Qry := TUniQuery.Create(nil);

  try
    Qry.Connection := conexao;
    Qry.SQL.Text   := SqlQuery;

    try
      Qry.Open;

      if not Qry.IsEmpty then
      begin
        // Só retorna True se o campo "url" vier preenchido
        url       := Trim(Qry.FieldByName('eleicao_api').AsString);
        if url <> '' then
        begin
          usuario := Trim(Qry.FieldByName('eleicao_usuario').AsString);
          senha   := Trim(Qry.FieldByName('eleicao_senha').AsString);
          token   := Trim(Qry.FieldByName('eleicao_token').AsString);
          Result  := True;
        end;
      end;

    except
      on E: Exception do
      begin
        // Em caso de erro, mantém Result=False e limpa os outs
        url     := '';
        usuario := '';
        senha   := '';
        token   := '';
      end;
    end;

  finally
    Qry.Free;
  end;
end;

Function TModelGerais.ContaRegistrosPendentes(const tabela, campo, ordem:string): Integer;
var
  Qry: TUniQuery;
begin
  Result := 0;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := Conexao;
    Qry.SQL.Text := 'Select Count(*) as total from '+tabela+' where '+campo+'=''S'' '+ordem+'';
    Qry.Open;
    if not Qry.IsEmpty then
      Result := Qry.FieldByName('total').AsInteger;
  finally
    FreeAndNil(Qry);
  end;
end;

constructor TModelGerais.Create(conn: Tuniconnection);
procedure LogErro(const Mensagem: String);
  var
    LogFile: TextFile;
    LogPath: String;
  begin
    LogPath := ExtractFilePath(ParamStr(0)) + 'Log_banco'+FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)+'.txt';
    AssignFile(LogFile, LogPath);
    try
      Rewrite(LogFile);
      Writeln(LogFile, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + Mensagem);
    finally
      CloseFile(LogFile);
    end;
  end;
begin
  Conexao := conn;
  FTransacao := TUniTransaction.Create(nil);
  FTransacao.DefaultConnection := Conexao;
end;

destructor TModelGerais.Destroy;
begin
   FTransacao.Free;
  inherited;
end;

function TModelGerais.GravarLogBanco(Tabela, Msg: string): Boolean;
var
  Qry : TUniquery;
Const
  Qrystr  = 'Insert into log_banco(id, data, hora, tabela, descricao)Values(:0,:1,:2,:3,:4)';
begin
  Result  := False;

  Qry   := TUniquery.Create(nil);

  try
    qry.Connection                              := Conexao;
    FTransacao.StartTransaction;
    Qry.SQL.Text                                := QryStr;
    Qry.Params.ParamByName('0').AsInteger       := 0;
    Qry.Params.ParamByName('1').AsDateTime      := Now;
    Qry.Params.ParamByName('2').AsDateTime      := now;
    Qry.Params.ParamByName('3').AsString        := Trim(tabela);
    Qry.Params.ParamByName('4').AsString        := Trim(Msg);

    Try
      Qry.ExecSQL;
      FTransacao.Commit;
      Result  := True;

    except on e:exception do
      begin
        FTransacao.Rollback;
        raise;
      end;
    End;

  finally
    Qry.Free;
  end;

end;

Function TModelGerais.AtualizarRegistroSincronizado(tabela, campo, params:String;id:integer):Boolean;
var
  Qry : TUniquery;
  QryStr  :String;
begin
  Result  := False;
  Qrystr  := 'Update '+Tabela+' set '+campo+' =''N'' Where '+params+'= :id';
  Qry   := TUniquery.Create(nil);

  try
    qry.Connection                              := Conexao;
    FTransacao.StartTransaction;
    Qry.SQL.Text                                := QryStr;
    Qry.Params.ParamByName('id').AsInteger      := id;

    Try
      Qry.ExecSQL;
      FTransacao.Commit;
      Result  := True;
    Except on e:exception do
      begin
        FTransacao.Rollback;
        raise;
      end;
    End;

  finally
    Qry.Free;
  end;
end;

end.
