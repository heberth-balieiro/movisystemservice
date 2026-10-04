unit Controllers.Carteira;

interface

Uses
  Uni,
  Model.Gerais,
  Model.Carteira,
  APP.Asmuv,
  Constantes,
  System.JSON,
  SysUtils;

Type
  TControllersCarteira = Class
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

      Function SincronizarSecretaria():Boolean;
      Function SincronizarLotacao():Boolean;
      Function SincronizarProfissao():Boolean;
      Function SincronizarPessoa():Boolean;
      Function SincronizarDependentes():Boolean;
      Function SincronizarCarteira():Boolean;
      Function SincronizarConvenio():Boolean;

      Function SincronizarCandidato():Boolean;
      Function SincronizarEleicao():Boolean;
      Function SincronizarMembro():Boolean;
      Function SincronizarChapa():Boolean;
      Function SincronizarCampanha():Boolean;

      Function SincronizarUsuario():Boolean;
      Function SincronizarAutorizacao(AID:Integer):Boolean;
      Function SincronizarNotificacao():Boolean;

      Function SincronizarRegEntrada():Boolean;


  End;

implementation

{ TControllersCarteira }

constructor TControllersCarteira.Create(conn: Tuniconnection);
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

destructor TControllersCarteira.Destroy;
begin

  inherited;
end;


function TControllersCarteira.SincronizarSecretaria: Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('secretaria','sinc_app',' order by id_secretaria');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LOGSECRETARIA,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LOGSECRETARIA,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArraySecretaria(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LOGSECRETARIA,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LOGSECRETARIA, RotaSecretaria) then
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
                    id      := JsonObj.GetValue<Integer>('id');

                    ModelGerais.AtualizarRegistroSincronizado('secretaria','sinc_app','id_secretaria',id);

                  end;
                  ModelGerais.GravarLogBanco(LOGSECRETARIA,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('secretaria','sinc_app',' order by id_secretaria');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LOGSECRETARIA,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LOGSECRETARIA,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;

end;

Function TControllersCarteira.SincronizarLotacao():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('sindicato_lotacao','sinc_app',' order by id_lotacao');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(Loglotacao,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(Loglotacao,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayLotacao(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(Loglotacao,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, Loglotacao, RotaLotacao) then
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
                    id      := JsonObj.GetValue<Integer>('id');

                    ModelGerais.AtualizarRegistroSincronizado('sindicato_lotacao','sinc_app','id_lotacao',id);

                  end;
                  ModelGerais.GravarLogBanco(Loglotacao,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('sindicato_lotacao','sinc_app',' order by id_lotacao');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(Loglotacao,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(Loglotacao,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

Function TControllersCarteira.SincronizarProfissao():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('sindicato_profissao','sinc_app',' order by id_profissao');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogProfissao,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogProfissao,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayProfissao(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogProfissao,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogProfissao, RotaProfissao) then
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
                    id      := JsonObj.GetValue<Integer>('idprofissao');

                    ModelGerais.AtualizarRegistroSincronizado('sindicato_profissao','sinc_app','id_profissao',id);

                  end;
                  ModelGerais.GravarLogBanco(LogProfissao,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('sindicato_profissao','sinc_app',' order by id_profissao');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogProfissao,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogProfissao,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

Function TControllersCarteira.SincronizarPessoa():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('socio','sinc_app',' order by id_socio');

    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogPessoas,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogPessoas,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayPessoa(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogPessoas,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogPessoas,RotaPessoa) then
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
                    id      := JsonObj.GetValue<Integer>('idsocio');

                    ModelGerais.AtualizarRegistroSincronizado('socio','sinc_app','id_socio',id);

                  end;
                  ModelGerais.GravarLogBanco(LogPessoas,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('socio','sinc_app',' order by id_socio');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogPessoas,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogPessoas,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

Function TControllersCarteira.SincronizarDependentes():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('sindicato_dependente','sinc_app',' order by id_dependente');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogDependentes,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogDependentes,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayDependentes(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogDependentes,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogDependentes,RotaDependente) then
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
                    id      := JsonObj.GetValue<Integer>('id');

                    ModelGerais.AtualizarRegistroSincronizado('sindicato_dependente','sinc_app','id_dependente',id);

                  end;
                  ModelGerais.GravarLogBanco(LogDependentes,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('sindicato_dependente','sinc_app',' order by id_dependente');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogDependentes,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogDependentes,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

Function TControllersCarteira.SincronizarCarteira():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('carteira','sinc_app',' order by id_carteira');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogCarteira,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogCarteira,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayCarteira(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogCarteira,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogCarteira,RotaCarteira) then
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
                    id      := JsonObj.GetValue<Integer>('idcarteira');

                    ModelGerais.AtualizarRegistroSincronizado('carteira','sinc_app','id_carteira',id);

                  end;
                  ModelGerais.GravarLogBanco(LogCarteira,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('carteira','sinc_app',' order by id_carteira');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogCarteira,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogCarteira,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

Function TControllersCarteira.SincronizarConvenio():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('convenio','sinc_app',' order by id_convenio');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogConvenio,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogConvenio,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayConvenio(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogConvenio,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogConvenio, RotaConvenio) then
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
                    id      := JsonObj.GetValue<Integer>('idconvenio');

                    ModelGerais.AtualizarRegistroSincronizado('convenio','sinc_app','id_convenio',id);

                  end;
                  ModelGerais.GravarLogBanco(LogConvenio,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('convenio','sinc_app',' order by id_convenio');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogConvenio,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogConvenio,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;


Function TControllersCarteira.SincronizarCandidato():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('candidato','sinc_app',' order by id_candidato');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogCandidato,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogCandidato,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayCandidato(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogCandidato,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogCandidato, RotaCandidato) then
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
                    id      := JsonObj.GetValue<Integer>('idcandidato');

                    ModelGerais.AtualizarRegistroSincronizado('candidato','sinc_app','id_candidato',id);

                  end;
                  ModelGerais.GravarLogBanco(LogCandidato,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('candidato','sinc_app',' order by id_candidato');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogCandidato,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogCandidato,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

Function TControllersCarteira.SincronizarEleicao():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('eleicao','sinc_app',' order by id_eleicao');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogEleicao,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogEleicao,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayEleicao(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogEleicao,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogEleicao, RotaEleicao) then
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
                    id      := JsonObj.GetValue<Integer>('ideleicao');

                    ModelGerais.AtualizarRegistroSincronizado('eleicao','sinc_app','id_eleicao',id);

                  end;
                  ModelGerais.GravarLogBanco(LogEleicao,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('eleicao','sinc_app',' order by id_eleicao');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogEleicao,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogEleicao,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

Function TControllersCarteira.SincronizarMembro():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 2;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('membro','sinc_app',' order by id_membro');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogMembro,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogMembro,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayMembro(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogMembro,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogMembro, RotaMembro) then
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
                    id      := JsonObj.GetValue<Integer>('idmembro');

                    ModelGerais.AtualizarRegistroSincronizado('membro','sinc_app','id_membro',id);

                  end;
                  ModelGerais.GravarLogBanco(LogMembro,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('membro','sinc_app',' order by id_membro');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogMembro,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogMembro,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

Function TControllersCarteira.SincronizarChapa():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 2;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('chapa','sinc_app',' order by id_chapa');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogChapa,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogChapa,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayChapa(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogChapa,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogChapa, RotaChapa) then
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
                    id      := JsonObj.GetValue<Integer>('idchapa');

                    ModelGerais.AtualizarRegistroSincronizado('chapa','sinc_app','id_chapa',id);

                  end;
                  ModelGerais.GravarLogBanco(LogChapa,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('chapa','sinc_app',' order by id_chapa');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogChapa,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogChapa,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

Function TControllersCarteira.SincronizarCampanha():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 1;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('campanha','sinc_app',' order by id_campanha');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogCampanha,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogCampanha,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayCampanha(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogCampanha,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogCampanha, RotaCampanha) then
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
                    id      := JsonObj.GetValue<Integer>('idcampanha');

                    ModelGerais.AtualizarRegistroSincronizado('campanha','sinc_app','id_campanha',id);

                  end;
                  ModelGerais.GravarLogBanco(LogCampanha,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('campanha','sinc_app',' order by id_campanha');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogCampanha,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogCampanha,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;


Function TControllersCarteira.SincronizarUsuario():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 2;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('usuario','sinc_app',' order by id_usuario');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogUsuario,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogUsuario,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayUsuario(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogUsuario,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogUsuario, RotaUsuario) then
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
                    id      := JsonObj.GetValue<Integer>('idusuario');

                    ModelGerais.AtualizarRegistroSincronizado('usuario','sinc_app','id_usuario',id);

                  end;
                  ModelGerais.GravarLogBanco(LogUsuario,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('usuario','sinc_app',' order by id_usuario');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogUsuario,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogUsuario,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

Function TControllersCarteira.SincronizarAutorizacao(AID:Integer):Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('autorizacao','sinc_app',' order by id_autorizacao');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogAutorizacao,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogAutorizacao,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayAutorizacao(Limit,0);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogAutorizacao,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogAutorizacao, RotaAutorizacao) then
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
                    id      := JsonObj.GetValue<Integer>('idautorizacao');

                    ModelGerais.AtualizarRegistroSincronizado('autorizacao','sinc_app','id_autorizacao',id);

                  end;
                  ModelGerais.GravarLogBanco(LogAutorizacao,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('autorizacao','sinc_app',' order by id_autorizacao');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogAutorizacao,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogAutorizacao,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;

Function TControllersCarteira.SincronizarNotificacao():Boolean;
var
ModelGerais  : TModelGerais;
Modelcarteira: TModelCarteira;
ModelAPP     : TSincronizador;
begin
  var Limit       := 5;
  Result          := false;
  nTotalregistro  := 0;
  JsonAtual       := '';

  Try
    ModelGerais     := TModelGerais.Create(Conexao);

    nTotalregistro  := ModelGerais.ContaRegistrosPendentes('notificacao','sinc_app',' order by id_notificacao');
    if nTotalregistro > 0 then
    begin
      ModelGerais.GravarLogBanco(LogNotificacao,LogMsg7+' '+ InttoStr(nTotalregistro)+ ' '+LogMsg8);
      TemMais     := True;
    end
    else
    begin
      ModelGerais.GravarLogBanco(LogNotificacao,LogMsg2+' '+LogMsg8);
      TemMais     := False;
      Result      := False;
      Exit;
    end;

    ModelCarteira   := TModelCarteira.Create(Conexao);

    Try
      while TemMais do
      begin
        JsonAtual     := ModelCarteira.CriarJsonArrayNotificacao(Limit);

        if Jsonatual = '' then
        begin
          ModelGerais.GravarLogBanco(LogNotificacao,LogMsg9);
          TemMais := False;
        end
        else
        begin
          ModelAPP    := TSincronizador.create(Conexao);
          Try
            if ModelApp.SincronizarEnvio(JsonAtual, LogNotificacao, RotaNotificacao) then
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
                    id      := JsonObj.GetValue<Integer>('idnotificacao');

                    ModelGerais.AtualizarRegistroSincronizado('notificacao','sinc_app','id_notificacao',id);

                  end;
                  ModelGerais.GravarLogBanco(LogNotificacao,LogMsg10);

                end;
              Finally
                JsonArray.Free;
              End;

              nTotalregistro  := ModelGerais.ContaRegistrosPendentes('notificacao','sinc_app',' order by id_notificacao');

              if nTotalregistro > 0 then
              begin
                ModelGerais.GravarLogBanco(LogNotificacao,LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12);
                TemMais     := True
              end
              else
              begin
                ModelGerais.GravarLogBanco(LogNotificacao,LogMsg2);
                TemMais     := False;
              end;

            end;

          Finally
            FreeAndNil(ModelApp);
          End;

        end;

      end;

    Finally
      FreeAndNil(ModelCarteira);
    End;

  Finally
    FreeAndNil(ModelGerais);
  End;
end;


Function TControllersCarteira.SincronizarRegEntrada():Boolean;
var
ModelGerais  : TModelGerais;
ModelAPP     : TSincronizador;
msg:string;
begin
  Result          := false;

  ModelAPP    := TSincronizador.create(Conexao);
  try
    ModelGerais  := TModelGerais.Create(Conexao);
    Try
      if not ModelApp.SincronizarRecRegistroEntrada(msg) then
      Result  := False
      else
      ModelGerais.GravarLogBanco(LogEntrada,msg +' Sincronizando dados...');
    Finally
      FreeAndNIl(ModelGerais);
    End;

  finally
    FreeAndNil(ModelAPP);
  end;


end;

end.
