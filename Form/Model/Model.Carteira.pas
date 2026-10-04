unit Model.Carteira;

interface

Uses
  Uni,
  System.JSON,
  ACBRUTIL,
  System.SysUtils;

Type
  TModelCarteira = Class
    Private
      FTransacao : TUniTransaction;
      Function DataParaJSON(Data: TDateTime): string;
    Public
      Conexao : TUniconnection;

      Constructor Create(conn :Tuniconnection); // Construtor
      Destructor Destroy;override; // Destruidor

      Function CriarJsonArraySecretaria(ALimite:integer):String;
      Function CriarJsonArrayLotacao(ALimite:integer):String;
      Function CriarJsonArrayProfissao(ALimite:integer):String;
      Function CriarJsonArrayPessoa(ALimite:integer):String;
      Function CriarJsonArrayDependentes(ALimite:integer):String;
      Function CriarJsonArrayCarteira(ALimite:integer):String;
      Function CriarJsonArrayConvenio(ALimite:integer):String;

      Function CriarJsonArrayCandidato(ALimite:integer):String;
      Function CriarJsonArrayEleicao(ALimite:integer):String;
      Function CriarJsonArrayMembro(ALimite:integer):String;
      Function CriarJsonArrayChapa(ALimite:integer):String;
      Function CriarJsonArrayCampanha(ALimite:integer):String;

      Function CriarJsonArrayUsuario(ALimite:integer):String;
      Function CriarJsonArrayAutorizacao(ALimite,AID:integer):String;
      Function CriarJsonArrayNotificacao(ALimite:integer):String;

  End;

implementation

{ TModelCarteira }

constructor TModelCarteira.Create(conn: Tuniconnection);
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

destructor TModelCarteira.Destroy;
begin
  FTransacao.Free;
  inherited;
end;


function TModelCarteira.CriarJsonArraySecretaria(ALimite: integer): String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'SELECT id_secretaria as id, codigo as codigo, razao as nome, '+
                  'ativo as ativo FROM secretaria where sinc_app=''S'' order by id_secretaria'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

        json.AddPair('id',        TJSONNumber.Create(qry.FieldByName('id').AsInteger));
        json.AddPair('codigo',    TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
        json.AddPair('descricao', TiraAcentos(Trim(qry.FieldByName('nome').AsString)));
        json.AddPair('ativo',     qry.FieldByName('ativo').AsString);

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayLotacao(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;
Const
QryStr      = 'SELECT id_lotacao as id, codigo as codigo, descricao as descricao, '+
                'ativo as ativo FROM sindicato_lotacao where sinc_app=''S'' order by id_lotacao'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json                      := TJsonObject.Create;

        json.AddPair('id',        TJSONNumber.Create(qry.FieldByName('id').AsInteger));
        json.AddPair('codigo',    TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
        json.AddPair('descricao', TiraAcentos(Trim(qry.FieldByName('descricao').AsString)));
        json.AddPair('ativo',     qry.FieldByName('ativo').AsString);

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayProfissao(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;
Const
QryStr      = 'Select id_profissao as id, codigo as codigo, descricao as descricao,'+
              ' ativo as ativo from sindicato_profissao where sinc_app=''S'' order by id_profissao'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json                      := TJsonObject.Create;

        json.AddPair('idprofissao',   TJSONNumber.Create(qry.FieldByName('id').AsInteger));
        json.AddPair('codigo',        TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
        json.AddPair('descricao',     TiraAcentos(Trim(qry.FieldByName('descricao').AsString)));
        json.AddPair('ativo',         qry.FieldByName('ativo').AsString);

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayPessoa(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;
Const
QryStr      = 'Select id_socio as idsocio,    '+
                    'id_empresa as idempresa,'+
                    'id_sede as idsede,'+
                    'codigo as codigo,'+
                    'matricula as matricula,'+
                    'socio_deste as sociodeste,'+
                    'situacao as situacao,'+
                    'nome as nome,'+
                    'apelido as apelido,'+
                    'cep as cep,'+
                    'endereco as endereco,'+
                    'numero as numero,'+
                    'bairro as bairro,'+
                    'complemento as complemento,'+
                    'id_cidade as idcidade,' +
                    'telefone as telefone,'+
                    'celular as celular,'+
                    'whatsapp as whatsapp,'+
                    'cpf as cpf,'+
                    'rg as rg,'+
                    'orgao as orgao,'+
                    'ctps as ctps,'+
                    'serie as serie,'+
                    'pis as pis,'+
                    'sexo as sexo,'+
                    'estado_civil as estadocivil,'+
                    'nascimento as nascimento,'+
                    'natural_cidade as naturalcidade,'+
                    'email as email,'+
                    'pai as pai,'+
                    'mae as mae,'+
                    'profissao as profissao,'+
                    'admissao as admissao,'+
                    'data_desativacao as datadesativacao,'+
                    'obs as obs,'+
                    'cli_tipo as clitipo,'+
                    'cli_responsavel as cliresponsavel,'+
                    'cliente as cliente,'+
                    'fornecedor as fornecedor,'+
                    'envemail as envemail,'+
                    'envwhats as envwhats,'+
                    'codfornecedor as codfornecedor,'+
                    'telefone2 as telefone2,'+
                    'celular2 as celular2,'+
                    'aviso as aviso,'+
                    'foto as foto,'+
                    'escritorio as escritorio,'+
                    'mostrarapp as mostrarapp,'+
                    'sindicato_perc_desconto as desconto,'+
                    'sindicato_salario as salario,'+
                    'tipo_mensalidade as tipomensalidade,'+
                    'bloqueado as bloqueado,'+
                    'sind_id_empresa as sindidempresa,'+
                    'id_profissao as idprofissao,'+
                    'id_lotacao as idlotacao from socio where id_socio > 0 and sinc_app=''S'' order by id_socio'+
                    ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json                      := TJsonObject.Create;

          json.AddPair('idsocio',     TJSONNumber.Create(qry.FieldByName('idsocio').AsInteger));
          json.AddPair('idempresa',   TJSONNumber.Create(qry.FieldByName('idempresa').AsInteger));
          json.AddPair('idsede',      TJSONNumber.Create(qry.FieldByName('idsede').AsInteger));
          json.AddPair('codigo',      TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
          json.AddPair('matricula',   TJSONNumber.Create(qry.FieldByName('matricula').AsInteger));
          if not qry.FieldByName('sociodeste').IsNull then
          json.AddPair('sociodeste',  DataParaJSON(qry.FieldByName('sociodeste').AsDateTime))
          else
          json.AddPair('sociodeste',  TJSONNull.Create);
          json.AddPair('situacao',    TiraAcentos(Trim(qry.FieldByName('situacao').AsString)));
          json.AddPair('nome',        TiraAcentos(Trim(qry.FieldByName('nome').AsString)));
          if Trim(qry.FieldByName('apelido').AsString).IsEmpty then
          json.AddPair('apelido',     TJSONNull.Create)
          else
          json.AddPair('apelido',     TiraAcentos(Trim(qry.FieldByName('apelido').AsString)));
          if Trim(qry.FieldByName('cep').AsString).IsEmpty then
          json.AddPair('cep',         TJSONNull.Create)
          else
          json.AddPair('cep',         Trim(qry.FieldByName('cep').AsString));
          if Trim(qry.FieldByName('endereco').AsString).IsEmpty then
          json.AddPair('endereco',         TJSONNull.Create)
          else
          json.AddPair('endereco',    TiraAcentos(Trim(qry.FieldByName('endereco').AsString)));
          if Trim(qry.FieldByName('numero').AsString).IsEmpty then
          json.AddPair('numero',         TJSONNull.Create)
          else
          json.AddPair('numero',      TiraAcentos(Trim(qry.FieldByName('numero').AsString)));
          if Trim(qry.FieldByName('bairro').AsString).IsEmpty then
          json.AddPair('bairro',         TJSONNull.Create)
          else
          json.AddPair('bairro',      TiraAcentos(Trim(qry.FieldByName('bairro').AsString)));
          if Trim(qry.FieldByName('complemento').AsString).IsEmpty then
          json.AddPair('complemento',         TJSONNull.Create)
          else
          json.AddPair('complemento', TiraAcentos(Trim(qry.FieldByName('complemento').AsString)));
          json.AddPair('idcidade',    TJSONNumber.Create(qry.FieldByName('idcidade').AsInteger));
          if Trim(qry.FieldByName('telefone').AsString).IsEmpty then
          json.AddPair('telefone',         TJSONNull.Create)
          else
          json.AddPair('telefone',    Trim(qry.FieldByName('telefone').AsString));
          if Trim(qry.FieldByName('celular').AsString).IsEmpty then
          json.AddPair('celular',         TJSONNull.Create)
          else
          json.AddPair('celular',     Trim(qry.FieldByName('celular').AsString));
          if Trim(qry.FieldByName('whatsapp').AsString).IsEmpty then
          json.AddPair('whatsapp',         TJSONNull.Create)
          else
          json.AddPair('whatsapp',    Trim(qry.FieldByName('whatsapp').AsString));
          if Trim(qry.FieldByName('cpf').AsString).IsEmpty then
          json.AddPair('cpf',         '00000000000')
          else
          json.AddPair('cpf',         Trim(qry.FieldByName('cpf').AsString));
          if Trim(qry.FieldByName('rg').AsString).IsEmpty then
          json.AddPair('rg',         TJSONNull.Create)
          else
          json.AddPair('rg',          Trim(qry.FieldByName('rg').AsString));
          if Trim(qry.FieldByName('orgao').AsString).IsEmpty then
          json.AddPair('orgao',         TJSONNull.Create)
          else
          json.AddPair('orgao',       TiraAcentos(Trim(qry.FieldByName('orgao').AsString)));
          if Trim(qry.FieldByName('ctps').AsString).IsEmpty then
          json.AddPair('ctps',         TJSONNull.Create)
          else
          json.AddPair('ctps',        Trim(qry.FieldByName('ctps').AsString));
          if Trim(qry.FieldByName('serie').AsString).IsEmpty then
          json.AddPair('serie',         TJSONNull.Create)
          else
          json.AddPair('serie',       Trim(qry.FieldByName('serie').AsString));
          if Trim(qry.FieldByName('pis').AsString).IsEmpty then
          json.AddPair('pis',         TJSONNull.Create)
          else
          json.AddPair('pis',         Trim(qry.FieldByName('pis').AsString));
          if Trim(qry.FieldByName('sexo').AsString).IsEmpty then
          json.AddPair('sexo',         TJSONNull.Create)
          else
          json.AddPair('sexo',        Trim(qry.FieldByName('sexo').AsString));
          if Trim(qry.FieldByName('estadocivil').AsString).IsEmpty then
          json.AddPair('estadocivil',         TJSONNull.Create)
          else
          json.AddPair('estadocivil', TiraAcentos(Trim(qry.FieldByName('estadocivil').AsString)));
          if not qry.FieldByName('nascimento').IsNull  then
          json.AddPair('nascimento',  DataParaJSON(qry.FieldByName('nascimento').AsDateTime))
          else
          json.AddPair('nascimento',  TJSONNull.Create);
          json.AddPair('naturalcidade',TJSONNumber.Create(qry.FieldByName('naturalcidade').AsInteger));
          if Trim(qry.FieldByName('email').AsString).IsEmpty then
          json.AddPair('email',         TJSONNull.Create)
          else
          json.AddPair('email',       Trim(qry.FieldByName('email').AsString));
          if Trim(qry.FieldByName('pai').AsString).IsEmpty then
          json.AddPair('pai',         TJSONNull.Create)
          else
          json.AddPair('pai',         TiraAcentos(Trim(qry.FieldByName('pai').AsString)));
          if Trim(qry.FieldByName('mae').AsString).IsEmpty then
          json.AddPair('mae',         TJSONNull.Create)
          else
          json.AddPair('mae',         TiraAcentos(Trim(qry.FieldByName('mae').AsString)));
          if Trim(qry.FieldByName('profissao').AsString).IsEmpty then
          json.AddPair('profissao',         TJSONNull.Create)
          else
          json.AddPair('profissao',   TiraAcentos(Trim(qry.FieldByName('profissao').AsString)));
          if not qry.FieldByName('admissao').IsNull then
          json.AddPair('admissao',    DataParaJSON(qry.FieldByName('admissao').AsDateTime))
          else
          json.AddPair('admissao',  TJSONNull.Create);
          if not qry.FieldByName('datadesativacao').IsNull then
          json.AddPair('datadesativacao',DataParaJSON(qry.FieldByName('datadesativacao').AsDateTime))
          else
          json.AddPair('datadesativacao', TJSONNull.Create);
          if Trim(qry.FieldByName('obs').AsString).IsEmpty then
          json.AddPair('obs',         TJSONNull.Create)
          else
          json.AddPair('obs',         TiraAcentos(Trim(qry.FieldByName('obs').AsString)));

          if Trim(qry.FieldByName('clitipo').AsString).IsEmpty then
          json.AddPair('clitipo',         TJSONNull.Create)
          else
          json.AddPair('clitipo',     TiraAcentos(Trim(qry.FieldByName('clitipo').AsString)));
          if Trim(qry.FieldByName('cliresponsavel').AsString).IsEmpty then
          json.AddPair('cliresponsavel',         TJSONNull.Create)
          else
          json.AddPair('cliresponsavel', TiraAcentos(Trim(qry.FieldByName('cliresponsavel').AsString)));
          if Trim(qry.FieldByName('cliente').AsString).IsEmpty then
          json.AddPair('cliente','S')
          else
          json.AddPair('cliente',     Trim(qry.FieldByName('cliente').AsString));
          if Trim(qry.FieldByName('fornecedor').AsString).IsEmpty then
          json.AddPair('fornecedor','N')
          else
          json.AddPair('fornecedor',  Trim(qry.FieldByName('fornecedor').AsString));
          if Trim(qry.FieldByName('envemail').AsString).IsEmpty then
          json.AddPair('envemail','N')
          else
          json.AddPair('envemail',    Trim(qry.FieldByName('envemail').AsString));
          if Trim(qry.FieldByName('envwhats').AsString).IsEmpty then
          json.AddPair('envwhats','N')
          else
          json.AddPair('envwhats',    Trim(qry.FieldByName('envwhats').AsString));

          json.AddPair('codfornecedor',TJSONNumber.Create(0));
          if Trim(qry.FieldByName('telefone2').AsString).IsEmpty then
          json.AddPair('telefone2',   TJSONNull.Create)
          else
          json.AddPair('telefone2',   Trim(qry.FieldByName('telefone2').AsString));
          if Trim(qry.FieldByName('celular2').AsString).IsEmpty then
          json.AddPair('celular2',    TJSONNull.Create)
          else
          json.AddPair('celular2',    Trim(qry.FieldByName('celular2').AsString));
          if Trim(qry.FieldByName('aviso').AsString).IsEmpty then
          json.AddPair('aviso',       TJSONNull.Create)
          else
          json.AddPair('aviso',       TiraAcentos(Trim(qry.FieldByName('aviso').AsString)));

          if qry.FieldByName('foto').AsString.IsEmpty then
          json.AddPair('foto',       TJSONNull.Create)
          else
          json.AddPair('foto',       TJSONString.Create(qry.FieldByName('foto').AsString));

          if Trim(qry.FieldByName('escritorio').AsString).IsEmpty then
          json.AddPair('escritorio',  TJSONNull.Create)
          else
          json.AddPair('escritorio',  TiraAcentos(Trim(qry.FieldByName('escritorio').AsString)));
          if Trim(qry.FieldByName('mostrarapp').AsString).IsEmpty then
          json.AddPair('mostrarapp','N')
          else
          json.AddPair('mostrarapp',  Trim(qry.FieldByName('mostrarapp').AsString));

          json.AddPair('desconto',    qry.FieldByName('desconto').AsFloat);
          json.AddPair('salario',     qry.FieldByName('salario').AsFloat);
          if Trim(qry.FieldByName('tipomensalidade').AsString).IsEmpty then
          json.AddPair('tipomensalidade',TJSONNull.Create)
          else
          json.AddPair('tipomensalidade', TiraAcentos(Trim(qry.FieldByName('tipomensalidade').AsString)));
          json.AddPair('sindidempresa', TJSONNumber.Create(qry.FieldByName('sindidempresa').AsInteger));
          if Trim(qry.FieldByName('bloqueado').AsString).IsEmpty then
          json.AddPair('bloqueado', TJSONNull.Create)
          else
          json.AddPair('bloqueado',     Trim(qry.FieldByName('bloqueado').AsString));
          json.AddPair('idprofissao',   TJSONNumber.Create(qry.FieldByName('idprofissao').AsInteger));
          json.AddPair('idlotacao',     TJSONNumber.Create(qry.FieldByName('idlotacao').AsInteger));

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayDependentes(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;
Const
QryStr      = 'SELECT id_dependente as id, codigo as codigo, id_socio as idsocio,'+
                ' nome as nome, nascimento as nascimento, parentesco as parentesco, '+
                ' cpf as cpf, rg as rg, sexo as sexo, foto as foto, ativo as ativo '+
                ' FROM sindicato_dependente where sinc_app=''S'' order by id_dependente'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json                      := TJsonObject.Create;

          json.AddPair('id',        TJSONNumber.Create(qry.FieldByName('id').AsInteger));
          json.AddPair('codigo',    TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
          json.AddPair('idsocio',   TJSONNumber.Create(qry.FieldByName('idsocio').AsInteger));
          json.AddPair('descricao', TiraAcentos(Trim(qry.FieldByName('nome').AsString)));
          json.AddPair('nascimento',DataParaJSON(qry.FieldByName('nascimento').AsDateTime));
          json.AddPair('parentesco',TiraAcentos(Trim(qry.FieldByName('parentesco').AsString)));
          json.AddPair('cpf',       Trim(qry.FieldByName('cpf').AsString));
          json.AddPair('rg',        Trim(qry.FieldByName('rg').AsString));
          json.AddPair('sexo',      Trim(qry.FieldByName('sexo').AsString));
          json.AddPair('foto',      Trim(qry.FieldByName('foto').AsString));
          json.AddPair('ativo',     qry.FieldByName('ativo').AsString);

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayCarteira(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'SELECT id_carteira as id,                      '+
                        ' id_socio as idsocio,               '+
                        ' validade as validade,              '+
                        ' ativo as ativo,                    '+
                        ' impresso_dependente as impresso,   '+
                        ' digital as digital,                '+
                        ' senha as senha,                    '+
                        ' id_usuario as idusuario,           '+
                        ' id_empresa as idempresa,           '+
                        ' dataemissao as dataemissao,        '+
                        ' token as token,                    '+
                        ' token_device as device,             '+
                        ' qrcde,                               '+
                        ' id_dependente,                      '+
                        ' api,                                '+
                        ' login,                              '+
                        ' nomeuser                            '+
                        ' FROM carteira where sinc_app=''S'' order by id_carteira'+
                        ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

          json.AddPair('idcarteira',        TJSONNumber.Create(qry.FieldByName('id').AsInteger));
          json.AddPair('idsocio',           TJSONNumber.Create(qry.FieldByName('idsocio').AsInteger));
          json.AddPair('validade',          DataParaJSON(qry.FieldByName('validade').AsDateTime));
          json.AddPair('ativo',             qry.FieldByName('ativo').AsString);
          json.AddPair('impressodependente',Trim(qry.FieldByName('impresso').AsString));
          json.AddPair('digital',           TiraAcentos(Trim(qry.FieldByName('digital').AsString)));
          json.AddPair('senha',             TiraAcentos(Trim(qry.FieldByName('senha').AsString)));
          json.AddPair('idusuario',         TJSONNumber.Create(qry.FieldByName('idusuario').AsInteger));
          json.AddPair('idempresa',         TJSONNumber.Create(qry.FieldByName('idempresa').AsInteger));
          json.AddPair('dataemissao',       DataParaJSON(qry.FieldByName('dataemissao').AsDateTime));
          json.AddPair('token',             Trim(qry.FieldByName('token').AsString));
          json.AddPair('tokendevice',       Trim(qry.FieldByName('device').AsString));
          json.AddPair('qrcode',            Trim(qry.FieldByName('qrcde').AsString));
          json.AddPair('iddependente',      TJSONNumber.Create(qry.FieldByName('id_dependente').AsInteger));
          json.AddPair('api',               'S');
          json.AddPair('login',             Trim(qry.FieldByName('login').AsString));
          json.AddPair('nomeuser',          Trim(qry.FieldByName('nomeuser').AsString));

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayConvenio(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'Select id_convenio, codigo, nome, tipo, termos,  '+
              'informacao_contrato, Coalesce(valores,0) as valores, telefone, ativo, '+
              'id_empresa, datacriacao from convenio where sinc_app=''S'' order by id_convenio'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

          json.AddPair('idconvenio',   TJSONNumber.Create(qry.FieldByName('id_convenio').AsInteger));
          json.AddPair('codigo',       TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
          json.AddPair('nome',         TiraAcentos(Trim(qry.FieldByName('nome').AsString)));
          json.AddPair('tipo',         qry.FieldByName('tipo').AsString);
          json.AddPair('termos',       qry.FieldByName('termos').AsString);
          json.AddPair('informacao',   qry.FieldByName('informacao_contrato').AsString);
          json.AddPair('valores',      qry.FieldByName('valores').AsFloat);
          json.AddPair('telefone',     qry.FieldByName('telefone').AsString);
          json.AddPair('ativo',        qry.FieldByName('ativo').AsString);
          json.AddPair('idempresa',    TJSONNumber.Create(qry.FieldByName('id_empresa').AsInteger));
          json.AddPair('datacriacao',  DataParaJSON(qry.FieldByName('datacriacao').AsDateTime));

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;


Function TModelCarteira.CriarJsonArrayCandidato(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'Select id_candidato, codigo, nome, cargo, cpf, descricao, id_empresa,'+
            ' foto, inativo from candidato where id_candidato>0 and sinc_app=''S'' order by id_candidato'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

          json.AddPair('idcandidato',     TJSONNumber.Create(qry.FieldByName('id_candidato').AsInteger));
          json.AddPair('codigo',          TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
          json.AddPair('idempresa',       TJSONNumber.Create(qry.FieldByName('id_empresa').AsInteger));
          json.AddPair('nome',            TiraAcentos(Trim(qry.FieldByName('nome').AsString)));
          json.AddPair('cargo',           TiraAcentos(Trim(qry.FieldByName('cargo').AsString)));
          json.AddPair('cpf',             TiraAcentos(Trim(qry.FieldByName('cpf').AsString)));
          json.AddPair('descricao',       TiraAcentos(Trim(qry.FieldByName('descricao').AsString)));
          json.AddPair('foto',            qry.FieldByName('foto').AsString);
          json.AddPair('ativo',           Trim(qry.FieldByName('inativo').AsString));

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayEleicao(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'Select id_eleicao, codigo, nome, descricao, id_empresa, ano, inativo,'+
                    ' tipo from eleicao where id_eleicao>0 and sinc_app=''S'' order by id_eleicao'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

        json.AddPair('ideleicao',     TJSONNumber.Create(qry.FieldByName('id_eleicao').AsInteger));
          json.AddPair('codigo',        TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
          json.AddPair('idempresa',     TJSONNumber.Create(qry.FieldByName('id_empresa').AsInteger));
          json.AddPair('nome',          TiraAcentos(Trim(qry.FieldByName('nome').AsString)));
          json.AddPair('descricao',     TiraAcentos(Trim(qry.FieldByName('descricao').AsString)));
          json.AddPair('ano',           TJSONNumber.Create(qry.FieldByName('ano').AsInteger));
          json.AddPair('inativo',       TiraAcentos(Trim(qry.FieldByName('inativo').AsString)));
          json.AddPair('tipo',          TiraAcentos(Trim(qry.FieldByName('tipo').AsString)));

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayMembro(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'select id_membro, codigo, nome, presidente, cpf, id_empresa, foto,'+
          ' inativo, id_eleicao, whatsapp, email, chave_key, secretaria, mesario '+
           ' from membro where id_membro>0 and sinc_app=''S'' order by id_membro'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

        json.AddPair('idmembro',        TJSONNumber.Create(qry.FieldByName('id_membro').AsInteger));
          json.AddPair('codigo',          TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
          json.AddPair('idempresa',       TJSONNumber.Create(qry.FieldByName('id_empresa').AsInteger));
          json.AddPair('ideleicao',       TJSONNumber.Create(qry.FieldByName('id_eleicao').AsInteger));
          json.AddPair('nome',            TiraAcentos(Trim(qry.FieldByName('nome').AsString)));
          json.AddPair('presidente',      TiraAcentos(Trim(qry.FieldByName('presidente').AsString)));
          json.AddPair('cpf',             TiraAcentos(Trim(qry.FieldByName('cpf').AsString)));
          json.AddPair('foto',            qry.FieldByName('foto').AsString);
          json.AddPair('inativo',         Trim(qry.FieldByName('inativo').AsString));
          json.AddPair('whatsapp',        Trim(qry.FieldByName('whatsapp').AsString));
          json.AddPair('email',           Trim(qry.FieldByName('email').AsString));
          json.AddPair('key',             Trim(qry.FieldByName('chave_key').AsString));
          json.AddPair('secretaria',      Trim(qry.FieldByName('secretaria').AsString));
          json.AddPair('mesario',         Trim(qry.FieldByName('mesario').AsString));

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayChapa(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'Select id_chapa, codigo, nome, descricao, inativo, id_empresa, '+
                'id_eleicao, id_candidato, exibir from chapa where id_chapa>0 and sinc_app=''S'' order by id_chapa'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

        json.AddPair('idchapa',       TJSONNumber.Create(qry.FieldByName('id_chapa').AsInteger));
          json.AddPair('codigo',        TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
          json.AddPair('idempresa',     TJSONNumber.Create(qry.FieldByName('id_empresa').AsInteger));
          json.AddPair('ideleicao',     TJSONNumber.Create(qry.FieldByName('id_eleicao').AsInteger));
          json.AddPair('idcandidato',   TJSONNumber.Create(qry.FieldByName('id_candidato').AsInteger));
          json.AddPair('nome',          TiraAcentos(Trim(qry.FieldByName('nome').AsString)));
          json.AddPair('descricao',     TiraAcentos(Trim(qry.FieldByName('descricao').AsString)));
          json.AddPair('inativo',       TiraAcentos(Trim(qry.FieldByName('inativo').AsString)));
          json.AddPair('exibir',        TiraAcentos(Trim(qry.FieldByName('exibir').AsString)));

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayCampanha(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'Select id_campanha, codigo, id_empresa, id_usuario, data_ini, hora_ini,'+
            ' data_final, hora_final, auditoria, id_eleicao, detalhes, publicada, '+
            'token, dthr_publicacao, dthr_fechamento, dthr_despublicacao, concluida,'+
            ' anexo, anexo_formato, chave_key, chave_key_alt, chave_key_publicar,'+
            ' chave_key_despublicar, fechamento_automatico, chave_key_encerramento from campanha where id_campanha >0 and sinc_app=''S'' order by id_campanha'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

          json.AddPair('idcampanha',          TJSONNumber.Create(qry.FieldByName('id_campanha').AsInteger));
          json.AddPair('codigo',              TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
          json.AddPair('idempresa',           TJSONNumber.Create(qry.FieldByName('id_empresa').AsInteger));
          json.AddPair('ideleicao',           TJSONNumber.Create(qry.FieldByName('id_eleicao').AsString));
          json.AddPair('dataini',             DataParaJSON(qry.FieldByName('data_ini').AsDateTime));
          json.AddPair('datafinal',           DataParaJSON(qry.FieldByName('data_final').AsDateTime));
          json.AddPair('dthrpublicacao',      DataParaJSON(qry.FieldByName('dthr_publicacao').AsDateTime));
          json.AddPair('dthrfechamento',      DataParaJSON(qry.FieldByName('dthr_fechamento').AsDateTime));
          json.AddPair('dthrdespublicacao',   DataParaJSON(qry.FieldByName('dthr_despublicacao').AsDateTime));

          {json.AddPair('dthrpublicacao',      FormatDatetime('dd/mm/yyyy hh:mm',qry.FieldByName('dthr_publicacao').AsDateTime));
          json.AddPair('dthrfechamento',      FormatDatetime('dd/mm/yyyy hh:mm',qry.FieldByName('dthr_fechamento').AsDateTime));
          json.AddPair('dthrdespublicacao',   FormatDatetime('dd/mm/yyyy hh:mm',qry.FieldByName('dthr_despublicacao').AsDateTime));
          }json.AddPair('horaini',            FormatDatetime('hh:mm',qry.FieldByName('hora_ini').AsDateTime));
          json.AddPair('horafinal',           FormatDatetime('hh:mm',qry.FieldByName('hora_final').AsDateTime));
          json.AddPair('auditoria',           Trim(qry.FieldByName('auditoria').AsString));
          json.AddPair('detalhes',            Trim(qry.FieldByName('detalhes').AsString));
          json.AddPair('publicada',           Trim(qry.FieldByName('publicada').AsString));
          json.AddPair('token',               Trim(qry.FieldByName('token').AsString));
          json.AddPair('concluida',           Trim(qry.FieldByName('concluida').AsString));
          json.AddPair('anexo',               Trim(qry.FieldByName('anexo').AsString));
          json.AddPair('anexoformato',        Trim(qry.FieldByName('anexo_formato').AsString));
          json.AddPair('chavekey',            Trim(qry.FieldByName('chave_key').AsString));
          json.AddPair('chavekeyalt',         Trim(qry.FieldByName('chave_key_alt').AsString));
          json.AddPair('chavekeypublicar',    Trim(qry.FieldByName('chave_key_publicar').AsString));
          json.AddPair('chavekeydespublicar', Trim(qry.FieldByName('chave_key_despublicar').AsString));
          json.AddPair('fechamentoautomatico',Trim(qry.FieldByName('fechamento_automatico').AsString));
          json.AddPair('chavekeyencerramento',Trim(qry.FieldByName('chave_key_encerramento').AsString));

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;


Function TModelCarteira.CriarJsonArrayUsuario(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'SELECT id_usuario, nome, login, senha, ativo FROM usuario where sinc_app=''S'' order by id_usuario'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

          json.AddPair('idusuario',   TJSONNumber.Create(qry.FieldByName('id_usuario').AsInteger));
          json.AddPair('nome',        TiraAcentos(Trim(qry.FieldByName('nome').AsString)));
          json.AddPair('login',       TiraAcentos(Trim(qry.FieldByName('login').AsString)));
          json.AddPair('senha',       qry.FieldByName('senha').AsString);
          json.AddPair('ativo',       qry.FieldByName('ativo').AsString);

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayAutorizacao(ALimite, AID:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'SELECT id_autorizacao, data, nome, qtde_pessoa, obs, pessoa_autorizou,'+
            ' status FROM autorizacao where sinc_app=''S'' order by id_autorizacao'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;

    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

        json.AddPair('idautorizacao',      TJSONNumber.Create(qry.FieldByName('id_autorizacao').AsInteger));
          json.AddPair('data',               DataParaJSON(qry.FieldByName('data').AsDateTime));
          json.AddPair('nome',               TiraAcentos(Trim(qry.FieldByName('nome').AsString)));
          json.AddPair('qtdepessoa',         TJSONNumber.Create(qry.FieldByName('qtde_pessoa').AsInteger));
          Json.AddPair('obs',                Trim(qry.FieldByName('obs').AsString));
          Json.AddPair('autorizou',          Trim(qry.FieldByName('pessoa_autorizou').AsString));
          Json.AddPair('status',             Trim(qry.FieldByName('status').AsString));

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

Function TModelCarteira.CriarJsonArrayNotificacao(ALimite:integer):String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'Select id_notificacao, tipo, titulo, mensagem, publico, foto from notificacao where tipo=0 and sinc_app=''S'' order by id_notificacao'+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
    Try
      Qry.Open;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

          json.AddPair('idnotificacao',   TJSONNumber.Create(qry.FieldByName('id_notificacao').AsInteger));
          json.AddPair('idsocio',         TJSONNumber.Create(0));
          json.AddPair('tipo',            TJSONNumber.Create(0));
          json.AddPair('titulo',          trim(qry.FieldByName('titulo').asstring));
          json.AddPair('mensagem',        Trim(qry.FieldByName('mensagem').AsString));
          Json.AddPair('publico',         qry.FieldByName('publico').AsString);
          Json.AddPair('foto',            qry.FieldByName('foto').AsString);

        JsonArray.Add(json);

        Qry.Next;
      end;
      Result  := JsonArray.ToJSON;
      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

function TModelCarteira.DataParaJSON(Data: TDateTime): string;
var
  FormatSettings: TFormatSettings;
begin
  // Configura os formatos de data e hora
  FormatSettings := TFormatSettings.Create;
  FormatSettings.ShortDateFormat := 'yyyy-mm-dd'; // Formato ISO 8601  'yyyy-mm-dd';
  FormatSettings.DateSeparator := '-';
  // Converte a data para string no formato desejado
  Result := DateToStr(Data, FormatSettings);
end;

end.
