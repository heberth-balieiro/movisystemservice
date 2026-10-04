unit Model.Garagem;

interface

Uses
  Uni,
  System.JSON,
  ACBRUTIL,
  System.SysUtils;

Type
  TModelGaragem = Class
    Private
      FTransacao : TUniTransaction;
      Function DataParaJSON(Data: TDateTime): string;
    Public
      Conexao : TUniconnection;

      Constructor Create(conn :Tuniconnection); // Construtor
      Destructor Destroy;override; // Destruidor

      Function CriarJsonArrayEmpresa(ALimite, idempresa:integer):String;
      Function CriarJsonArrayVeiculo(ALimite:integer; guid:string):String;


    end;

implementation

{ TModelGaragem }

constructor TModelGaragem.Create(conn: Tuniconnection);
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

destructor TModelGaragem.Destroy;
begin
  FTransacao.Free;
  inherited;
end;

function TModelGaragem.DataParaJSON(Data: TDateTime): string;
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


function TModelGaragem.CriarJsonArrayEmpresa(ALimite, idempresa: integer): String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'Select                                    '+
              ' e.id_empresa,'+
              ' e.razao,                                '+
              ' e.fantasia,                             '+
              ' e.cep,                                  '+
              ' e.endereco,                             '+
              ' e.numero,                               '+
              ' e.bairro,                               '+
              ' e.cnpj,                                 '+
              ' e.celular,                              '+
              ' e.whatsapp,                             '+
              ' e.email1,                               '+
              ' e.logo,                                 '+
              ' e.guid,                                 '+
              ' c.cidade,                               '+
              ' c.uf                                    '+
              ' From Empresa e                          '+
              ' Inner Join Cidade c                     '+
              ' On e.id_cidade = c.id_cidade            '+
              ' where id_empresa= :id                   '+
                  ' LIMIT :limit';
begin
  Result      := '';

  Qry         := TUniquery.Create(nil);
  JsonArray   := TJsonArray.Create;

  Try
      Qry.Connection                              := Conexao;
      Qry.SQL.Text                                := QryStr;
      qry.Params.ParamByName('limit').AsInteger   := ALimite;
      Qry.Params.ParamByName('id').AsInteger      := idempresa;
    Try
      Qry.Open;

      if qry.IsEmpty then
      begin
        FreeAndNil(qry);
        FreeAndNil(JsonArray);
        Exit('');
      end;

      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;
          json.AddPair('idempresa',TJSONNumber.Create(qry.FieldByName('id_empresa').AsInteger));
          json.AddPair('guid',    qry.FieldByName('guid').AsString);
          json.AddPair('cnpj',    qry.FieldByName('cnpj').AsString);
          json.AddPair('razao',   qry.FieldByName('razao').AsString);
          json.AddPair('fantasia',qry.FieldByName('fantasia').AsString);
          json.AddPair('cep',     qry.FieldByName('cep').AsString);
          json.AddPair('endereco',qry.FieldByName('endereco').AsString);
          json.AddPair('bairro',  qry.FieldByName('bairro').AsString);
          json.AddPair('numero',  qry.FieldByName('numero').AsString);
          json.AddPair('cidade',  qry.FieldByName('cidade').AsString);
          json.AddPair('uf',      qry.FieldByName('uf').AsString);
          json.AddPair('email',   qry.FieldByName('email1').AsString);
          json.AddPair('logo',    qry.FieldByName('logo').AsString);
          json.AddPair('telefone',qry.FieldByName('celular').AsString);
          json.AddPair('whatsapp',qry.FieldByName('whatsapp').AsString);

        JsonArray.Add(json);

        Qry.Next;
      end;
      if JsonArray.Count > 0 then
        Result := JsonArray.ToJSON
       else
       Result := '';

      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;

function TModelGaragem.CriarJsonArrayVeiculo(ALimite: integer; guid:string): String;
var
qry         : TUniquery;
json        : TJsonObject;
JsonArray   : TJsonArray;

Const
QryStr      = 'Select                                                                    '+
              ' p.id_produto as idveiculo,                                               '+
              ' p.codigo,                                                                '+
              ' p.tipo_produto as tipoveiculo,                                           '+
              ' p.descricao as ndescveiculo,                                             '+
              ' p.descricao_fiscal as ndescfiscal,                                       '+
              ' concat(p.veiculo_ano,'' / '',p.veiculo_ano_modelo) as anomodelo,         '+
              ' p.veiculo_cor as cor,                                                    '+
              ' coalesce(p.prc_venda,0) as vlrvenda,                                     '+
              ' coalesce(p.veiculo_valorpraticado,0) as vlrpraticado,                    '+
              ' case when p.estoque_atual =1 then ''SIM'' else ''NÃO'' end as estoque,   '+
              ' p.foto1 as imagemprincipal,                                              '+
              ' p.veiculo_combustivel as ncombustivel,                                   '+
              ' p.veiculo_cambio as ncambio,                                             '+
              ' p.veiculo_porta as nportas,                                              '+
              ' p.veiculo_km as nkm,                                                     '+
              ' l.localizacao as nlocal,                                                 '+
              ' m.marca as nmarca,                                                       '+
              ' v.descricao as nmodelo,                                                  '+
              ' ve.descricao as nespecie,                                                '+
              ' g.grupo as ntipoveiculo,                                                 '+
              ' p.ativo as nativo,                                                       '+
              ' p.mostrar_app as exibirapp                                               '+
              ' from produto p                                                           '+
              ' Inner Join localizacao l                                                 '+
              ' On p.id_localizacao = l.id_localizacao                                   '+
              ' Inner Join marca m                                                       '+
              ' On p.id_marca = m.id_marca                                               '+
              ' Inner Join veiculo_modelo v                                              '+
              ' On p.id_veiculo_modelo = v.id_veiculo_modelo                             '+
              ' Inner Join veiculo_especie ve                                            '+
              ' On p.id_veiculo_especie = ve.id_veiculo_especie                          '+
              ' Inner join grupo g                                                       '+
              ' On p.id_grupo = g.id_grupo                                               '+
              ' where p.sinc_app=''S'' order by p.id_produto                             '+
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

      if qry.IsEmpty then
      begin
        FreeAndNil(qry);
        FreeAndNil(JsonArray);
        Exit('');
      end;


      while not Qry.Eof do
      begin
        json  := TJsonObject.Create;

          json.AddPair('guidempresa',      Trim(guid));
          json.AddPair('codigo',           TJSONNumber.Create(qry.FieldByName('codigo').AsInteger));
          json.AddPair('tipo',             TiraAcentos(Trim(qry.FieldByName('tipoveiculo').AsString)));
          json.AddPair('descricaomodelo',  qry.FieldByName('ndescveiculo').AsString);
          json.AddPair('descricaoveiculo', qry.FieldByName('ndescfiscal').AsString);
          json.AddPair('anomodelo',        qry.FieldByName('anomodelo').AsString);
          json.AddPair('cor',              qry.FieldByName('cor').AsString);
          json.AddPair('vlrvenda',         qry.FieldByName('vlrvenda').Asfloat);
          json.AddPair('estoque',          qry.FieldByName('estoque').AsString);
          json.AddPair('fotoprincipal',    qry.FieldByName('imagemprincipal').AsString);
          json.AddPair('combustivel',      qry.FieldByName('ncombustivel').AsString);
          json.AddPair('cambio',           qry.FieldByName('ncambio').AsString);
          json.AddPair('portas',           qry.FieldByName('nportas').AsString);
          json.AddPair('km',               qry.FieldByName('nkm').AsString);
          json.AddPair('localestoque',     qry.FieldByName('nlocal').AsString);
          json.AddPair('marca',            qry.FieldByName('nmarca').AsString);
          json.AddPair('modelo',           qry.FieldByName('nmodelo').AsString);
          json.AddPair('vlrpraticado',     qry.FieldByName('vlrpraticado').Asfloat);
          json.AddPair('nespecie',         qry.FieldByName('nespecie').AsString);
          json.AddPair('ntipoveiculo',     qry.FieldByName('ntipoveiculo').AsString);
          json.AddPair('nativo',           qry.FieldByName('nativo').AsString);
          json.AddPair('exibirapp',        qry.FieldByName('exibirapp').AsString);
          json.AddPair('idveiculo',        TJSONNumber.Create(qry.FieldByName('idveiculo').AsInteger));

        JsonArray.Add(json);

        Qry.Next;
      end;
       if JsonArray.Count > 0 then
        Result := JsonArray.ToJSON
       else
       Result := '';

      qry.Close;

    except on e:exception do
      raise Exception.Create(e.Message);
    end;

  Finally
    FreeAndNil(Qry);
    freeAndNIl(JsonArray);
  End;
end;



end.
