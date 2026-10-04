unit Controllers.Garagem;

interface

Uses
  Uni,
  Model.Gerais,
  Model.Garagem,
  APP.Asmuv,
  Constantes,
  System.JSON,
  SysUtils;

Type
  TControllersGaragem = Class
    Private

    Public
      Conexao   : TUniconnection;
      nTotalregistro:Integer;
      TemMais   :Boolean;
      JsonAtual : string;
      JsonArray : TJSONArray;
      JsonObj   : TJSONObject;

      Constructor Create(conn :Tuniconnection); // Construtor
      Destructor Destroy;override; // Destruidor

      Function SincronizarEmpresa(idempresa:integer):Boolean;
      Function SincronizarVeiculo():Boolean;
      

  End;

implementation

{ TControllersGaragem }

constructor TControllersGaragem.Create(conn: Tuniconnection);
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
  Conexao     := Conn;
end;

destructor TControllersGaragem.Destroy;
begin

  inherited;
end;

function TControllersGaragem.SincronizarEmpresa(idempresa:integer): Boolean;
var
ModelGerais  : TModelGerais;
ModelGaragem : TModelGaragem;
ModelAPP     : TSincronizador;
begin
  Result            := false;
  JsonAtual         := '';

  ModelGerais       := TModelGerais.Create(Conexao);
  Try
    ModelGaragem    := TModelGaragem.Create(Conexao);
    Try
        JsonAtual   := ModelGaragem.CriarJsonArrayEmpresa(1,idempresa);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogEmpresa,LogMsg9);
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvioGaragem(JsonAtual, LogEmpresa, RotaEmpresa) then
            begin
              Result    := True;
            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

    Finally
      FreeAndNil(ModelGaragem);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

function TControllersGaragem.SincronizarVeiculo: Boolean;
var
ModelGerais  : TModelGerais;
ModelGaragem: TModelGaragem;
ModelAPP     : TSincronizador;
url, usuario, senha,token:string;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('produto','sinc_app',' order by id_produto');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogVeiculo,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogVeiculo,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    if not ModelGerais.BuscarURLAppVeiculo(url, usuario, senha,token) then
    begin
      Result  := false;
      exit;
    end;

    ModelGaragem   := TModelGaragem.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelGaragem.CriarJsonArrayVeiculo(Limit,token);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogVeiculo,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogVeiculo, RotaVeiculo) then
            begin
              Result    := True;
              JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
              Try
                if assigned(JsonArray) then
                begin
                  var I   :integer;
                  var id  :integer;

                  for I := 0 to JsonArray.Count -1 do
                  begin
                    JsonObj := JsonArray.Items[i] as TJSONObject;
                    id      := JsonObj.GetValue<Integer>('idveiculo');

                    ModelGerais.AtualizarRegistroSincronizado('produto','sinc_app','id_produto',id);

                  end;
                  ModelGerais.GravarLogBanco(LogVeiculo,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('produto','sinc_app',' order by id_produto');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogVeiculo,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogVeiculo,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelGaragem);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

end.
