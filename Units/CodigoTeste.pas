unit CodigoTeste;

interface

implementation

end.
var APagina       := 1;
          var JsonAtual     := '';
          var nUrl, nUsuario, nSenha, nToken:string;
          var nTotalRegistro := 0;
          var TemMais       : Boolean;

          Log('['+LogEasyBot+'] '+LogMsg3+'','LogSincronizarAPI');

//Sincronizar secretaria
          {$REGION 'Secretaria - 1'}

          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 1 then
          begin
            Var Limit         := 5;

            //Buscar dados de autorizacao
            if not modelapp.BuscarURLAppCarteira(nUrl, nUsuario, nSenha, nToken) then
            begin
              Log('['+LogSecretaria+'] '+LogMsg6+'','LogSincronizarAPI');
              Exit;
            end;

            Log('['+LogSecretaria+'] '+LogMsg5+'', 'LogSincronizarAPI');


            nTotalregistro    := ModelApp.ContaRegistrosPendentes('secretaria','sinc_app',' order by id_secretaria');
            Log('['+LogSecretaria+'] '+LogMsg7+' ' + nTotalregistro.ToString + ' '+LogMsg8+'', 'LogSincronizarAPI');
            if nTotalregistro > 0 then
            TemMais     := True
            else
            Temmais     := False;

            while TemMais do
            begin
              JsonAtual := modelapp.JsonSecretaria(APagina,Limit);

              if Jsonatual = '' then
              begin
                Log('['+LogSecretaria+'] '+LogMsg9+'','LogSincronizarAPI');
                TemMais := False;
              end
              else
              begin
                if modelapp.SincronizarSecretaria(JsonAtual,nUrl, nUsuario, nSenha,nToken) then
                begin
                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                    Try
                      if assigned(JsonArray) then
                      begin
                        for I := 0 to JsonArray.Count -1 do
                        begin
                          JsonObj := JsonArray.Items[i] as TJSONObject;

                          idGeral := JsonObj.GetValue<Integer>('idveiculo');

                          // Aqui você atualiza no banco seu registro como sincronizado
                          QryAuxiliar.Close;
                          QryAuxiliar.SQL.Text := 'UPDATE secretaria SET sinc_app = ''N'' WHERE id_secretaria = :id';
                          QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                          QryAuxiliar.ExecSQL;

                        end;
                        Log('['+LogSecretaria+'] '+LogMsg10+'', 'LogSincronizarAPI');

                      end;
                    Finally
                      JsonArray.Free;
                    End;
                    Inc(APagina);

                    nTotalregistro    := ModelApp.ContaRegistrosPendentes('secretaria','sinc_app',' order by id_secretaria');

                    if nTotalregistro > 0 then
                    begin
                      Log('['+LogSecretaria+'] '+LogMsg11+' ' + nTotalregistro.ToString + ' '+LogMsg12+'', 'LogSincronizarAPI');
                      TemMais     := True
                    end
                    else
                    begin
                      Log('['+LogSecretaria+'] '+LogMsg2+'', 'LogSincronizarAPI');
                      TemMais     := False;
                    end;
                end;
              end;

            end;

            // Atualizar o status para "enviado"
            if nTotalregistro = 0 then
            begin
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Secretaria] '+LogMsg13+'', 'LogSincronizarAPI');
            end;

            //Fim do codigo
          end;
          {$ENDREGION}

          //Sincronizar Lotação
          {$REGION 'Lotação -2'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 2 then
          begin
            Var TagLog        := 'Lotação';
            Var Limit         := 5;

            //Buscar dados de autorizacao
            if not modelapp.BuscarURLAppCarteira(nUrl, nUsuario, nSenha, nToken) then
            begin
              Log('['+TagLog+'] Empresa sem configuração de sincronização!','LogSincronizarAPI');
              Exit;
            end;

            Log('['+TagLog+'] Iniciando sincronização de veículos com a API...', 'LogSincronizarAPI');

















            repeat
              JsonAtual := modelapp.JsonLotacao(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                Log('[Lotação] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');
                if modelapp.SincronizarLotacao(msg, JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('id');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE sindicato_lotacao SET sinc_app = ''N'' WHERE id_lotacao = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Lotação] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Lotação] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;









          end;
          {$ENDREGION}

          //Sincronizar Profissao
          {$REGION 'Profissao - 3'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 3 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonProfissao(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                Log('[Profissao] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');
                if modelapp.SincronizarProfissao(msg, JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('idprofissao');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE sindicato_profissao SET sinc_app = ''N'' WHERE id_profissao = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Profissao] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Profissao] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar Pessoas socio
          {$REGION 'Pessoas -4'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 4 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonPessoa(msg,TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                Log('[Associado] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');
                if modelapp.SincronizarPessoa(msg, JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('idsocio');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE socio SET sinc_app = ''N'' WHERE id_socio = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Associado] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Associado] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar Dependentes
          {$REGION 'Dependentes - 5'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 5 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonDependente(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                Log('[Dependente] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');
                if modelapp.SincronizarDependente(msg, JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('id');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE sindicato_dependente SET sinc_app = ''N'' WHERE id_dependente = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Dependente] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Dependente] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar Carteira
          {$REGION 'Carteira - 6'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 6 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonCarteira(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin

                Log('[Carteira] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');

                if modelapp.SincronizarCarteira(msg, JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('idcarteira');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE carteira SET sinc_app = ''N'' WHERE id_carteira = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Carteira] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Carteira] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar convenio
          {$REGION 'Convenio - 7'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 7 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual         := modelapp.JsonConvenio(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                Log('[Convenio] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');

                if modelapp.SincronizarConvenio(msg, JsonAtual) then
                begin
                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('idconvenio');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE convenio SET sinc_app = ''N'' WHERE id_convenio = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Convenio] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Convenio] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar Candidato
          {$REGION 'Candidato - 8'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 8 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonCandidato(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin

                Log('[Candidato] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');

                if modelapp.SincronizarCandidato(JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('idcandidato');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE candidato SET sinc_app = ''N'' WHERE id_candidato = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Candidato] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Candidato] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar eleicao
          {$REGION 'Eleicao - 9'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 9 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonEleicao(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                Log('[Eleição] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');

                if modelapp.SincronizarEleicao(JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('ideleicao');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE eleicao SET sinc_app = ''N'' WHERE id_eleicao = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Eleição] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Eleição] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar Membro
          {$REGION 'Membro 10'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 10 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonMembro(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                Log('[Membro] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');

                if modelapp.SincronizarMembro(JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('idmembro');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE membro SET sinc_app = ''N'' WHERE id_membro = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Membro] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Membro] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar Chapa
          {$REGION 'Chapa - 11'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 11 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonChapa(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                Log('[Chapa] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');

                if modelapp.SincronizarChapa(JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('idchapa');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE chapa SET sinc_app = ''N'' WHERE id_chapa = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Chapa] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Chapa] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar Campanha
          {$REGION 'Campanha - 12'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 12 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonCampanha(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                Log('[Campanha] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');

                if modelapp.SincronizarCampanha(JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('idcampanha');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE campanha SET sinc_app = ''N'' WHERE id_campanha = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Campanha] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Campanha] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar individual
          {$REGION 'Pessoa individual 13'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 13 then
          begin
            if modelapp.SincronizarPessoa(msg,modelapp.JsonPessoaIndividual(msg,QrySincronizar.FieldByName('id_registro').AsInteger)) then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
            end;
          end;
          {$ENDREGION}

          //sincronizar notificacao
          {$REGION 'Notificação - 14'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 14 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonNotificacao(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                Log('[Notificação] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');

                if modelapp.SincronizarNotificacao(msg, JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('idnotificacao');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE notificacao SET sinc_app = ''N'' WHERE id_notificacao = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Lotação] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Notificação] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar Usuario
          {$REGION 'Usuario - 15'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 15 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonUsuario(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                Log('[Usuário] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');

                if modelapp.SincronizarUsuario(JsonAtual) then
                begin
                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('idusuario');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE usuario SET sinc_app = ''N'' WHERE id_usuario = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Usuário] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Usuário] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //sincronizar autorizacao
          {$REGION 'Autorizacao - 16'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 16 then
          begin
            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonAutorizacao(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
               Log('[Autorização] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');

                if modelapp.SincronizarAutorizacao(JsonAtual) then
                begin

                  //Alterar os registro que foram sincronizado com sucesso.

                  JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                  Try
                    if assigned(JsonArray) then
                    begin
                      for I := 0 to JsonArray.Count -1 do
                      begin
                        JsonObj := JsonArray.Items[i] as TJSONObject;

                        idGeral := JsonObj.GetValue<Integer>('idautorizacao');

                        // Aqui você atualiza no banco seu registro como sincronizado
                        QryAuxiliar.Close;
                        QryAuxiliar.SQL.Text := 'UPDATE autorizacao SET sinc_app = ''N'' WHERE id_autorizacao = :id';
                        QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                        QryAuxiliar.ExecSQL;

                      end;
                      Log('[Autorização] Registro atualizado em tabela','LogSincronizarAPI');
                    end;
                  Finally
                    JsonArray.Free;
                  End;

                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Autorização] Sincronização finalizada total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
            end;
          end;
          {$ENDREGION}

          //Sincronizar registro de enrada
          {$REGION 'Registro entrada - 17'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 17 then
          begin

            if modelapp.SincronizarRecRegistroEntrada(msg) then
            begin
              Log('Recebendo dados registro API: '+msg,'LogSincronizarAPI');
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
            end;
          end;
          {$ENDREGION}

          //Sincronizar pessoa excluida
          {$REGION 'Pessoa Excluida - 18'}
          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 18 then
          begin
            //enviar associado excluido
            Log('Preparando envio [associado excluido].','LogSincronizarAPI');

            var APagina       := 1;
            var TotalPaginas  := 0;
            var JsonAtual     := '';

            repeat
              JsonAtual := modelapp.JsonPessoaExcluida(TotalPaginas, APagina);
              if JsonAtual <> '' then
              begin
                if modelapp.SincronizarPessoaExcluida(JsonAtual) then
                begin
                  Inc(APagina);
                end
                else
                begin
                  Break; // se deu erro no envio, para
                end;
              end;

            until APagina > TotalPaginas ;

             // se enviou todas as páginas com sucesso
            if APagina > TotalPaginas then
            begin
              // Atualizar o status para "enviado"
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
            end;
          end;
          {$ENDREGION}

          {$REGION 'Funções Veiculo'}

            {$REGION 'Sinc Empresa - 19'}

              if QrySincronizar.FieldByName('cod_tabela').AsInteger = 19 then
              begin
                var APagina       := 1;
                var TotalPaginas  := 0;
                var JsonAtual     := '';

                repeat
                  JsonAtual       := modelapp.JsonEmpresa(TotalPaginas, APagina, QrySincronizar.FieldByName('id_registro').AsInteger);
                  if JsonAtual <> '' then
                  begin
                    Log('[Empresa] Pagina Total: '+inttostr(TotalPaginas)+' - Pagina: '+inttostr(APagina),'LogSincronizarAPI');

                    if modelapp.SincronizarEmpresa(JsonAtual) then
                    begin

                      Inc(APagina);
                    end
                    else
                    begin
                      Break; // se deu erro no envio, para
                    end;
                  end;

                until APagina > TotalPaginas ;

                 // se enviou todas as páginas com sucesso
                if APagina > TotalPaginas then
                begin
                  // Atualizar o status para "enviado"
                  QrySincronizar.Edit;
                  QrySincronizar.FieldByName('status').AsString := 'C';
                  QrySincronizar.Post;
                  Log('[Empresa] Sincronização finalizada, total enviado: '+ inttostr(TotalPaginas),'LogSincronizarAPI');
                end;
              end;


            {$ENDREGION}

          {$ENDREGION}


          {$REGION 'Veiculo - 20'}

          if QrySincronizar.FieldByName('cod_tabela').AsInteger = 20 then
          begin
            var APagina       := 1;
            var JsonAtual     := '';
            var nUrl, nUsuario, nSenha, nToken:string;
            var nTotalRegistro := 0;
            Var Limit         := 5;
            var TemMais       : Boolean;

            //Buscar dados de autorizacao
            if not modelapp.BuscarURLAppVeiculo(nUrl, nUsuario, nSenha, nToken) then
            begin
              Log('[Veículo] Empresa sem configuração de autorização!','LogSincronizarAPI');
              Exit;
            end;

            Log('[Veículo] Iniciando sincronização de veículos com a API...', 'LogSincronizarAPI');


            nTotalregistro    := ModelApp.ContaRegistrosPendentes('produto','sinc_app',' order by id_produto');
            Log('[Veículo] Encontrados ' + nTotalregistro.ToString + ' registros pendentes para sincronizar.', 'LogSincronizarAPI');
            if nTotalregistro > 0 then
            TemMais     := True
            else
            Temmais     := False;

            while TemMais do
            begin
              //Montar o Json com os dados
              JsonAtual       := modelapp.JsonVeiculo(APagina, nToken, limit);

              if Jsonatual = '' then
              begin
                Log('[Veículo] Json sem dados para enviar!','LogSincronizarAPI');
                TemMais := False;
              end
              else
              begin

                if modelapp.SincronizarVeiculo(JsonAtual) then
                begin
                  //Atualizar registro ja enviado
                    JsonArray := TJSONObject.ParseJSONValue(JsonAtual) as TJSONArray;
                    Try
                      if assigned(JsonArray) then
                      begin
                        for I := 0 to JsonArray.Count -1 do
                        begin
                          JsonObj := JsonArray.Items[i] as TJSONObject;

                          idGeral := JsonObj.GetValue<Integer>('idveiculo');

                          // Aqui você atualiza no banco seu registro como sincronizado
                          QryAuxiliar.Close;
                          QryAuxiliar.SQL.Text := 'UPDATE produto SET sinc_app = ''N'' WHERE id_produto = :id';
                          QryAuxiliar.ParamByName('id').AsInteger := idGeral;
                          QryAuxiliar.ExecSQL;

                        end;
                        Log('[Veículo] Atualizando status dos registros sincronizados...', 'LogSincronizarAPI');

                      end;
                    Finally
                      JsonArray.Free;
                    End;
                    Inc(APagina);

                    nTotalregistro    := ModelApp.ContaRegistrosPendentes('produto','sinc_app',' order by id_produto');

                    if nTotalregistro > 0 then
                    begin
                      Log('[Veículo] Ainda restam ' + nTotalregistro.ToString + ' registros para sincronizar.', 'LogSincronizarAPI');
                      TemMais     := True
                    end
                    else
                    begin
                      Log('[Veículo] Sem registros para sincronizar.', 'LogSincronizarAPI');
                      TemMais     := False;
                    end;
                end;
              end;
            end;

            //finalizar o processo
            // Atualizar o status para "enviado"
            if nTotalregistro = 0 then
            begin
              QrySincronizar.Edit;
              QrySincronizar.FieldByName('status').AsString := 'C';
              QrySincronizar.Post;
              Log('[Veículo] Sincronização concluída! Nenhum registro pendente.', 'LogSincronizarAPI');
            end;
          end;

          {$ENDREGION}
