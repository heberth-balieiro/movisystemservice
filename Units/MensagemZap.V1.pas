unit MensagemZap.V1;

interface

Uses
 ACBRUTIL, RESTRequest4D,DataSet.Serialize.Adapter.RESTRequest4D,System.JSON, UConeSul, uni,
 REST.Types;

 {$REGION 'Instancia'}
  // 1 - Criar a Instancia Primeiro
  Function InstanceCreate(Out Token, msg: String; URL, APIKEY, NomeInstancia, Descricao:string):Boolean;
  Function InstanceDelete(Out msg: String; Token, URL, NomeInstancia:string):Boolean;
  Function InstanceConnect(Out msg, Base64:String; URL, NomeInstancia, Token :String):Boolean;
  Function InstanceLogout(Out msg: String; Token, URL, NomeInstancia:string):Boolean;
  //Function InstanceFetch(Out msg: String; Key, URL, NomeInstancia:string):Boolean;
  Function InstanceConnectionStatus(Out msg, state: String; Token, URL, NomeInstancia:string):Boolean;


 {$ENDREGION}

 {$REGION 'Mensagem'}
  // função para envio
  Function MessageText(Out msg:string; URL, NomeInstancia, Token, Numero, MensagemFormatada:String):Boolean;
  Function MessageMedia(Out msg:string; URL, NomeInstancia, Token, Numero, media, filename, caption, mediatype:String):Boolean;
  Function MessageMediaFile(Out msg:string; URL, NomeInstancia, Token, Numero, caption, mediatype, attachment, quotedid :String):Boolean;

 {$ENDREGION}

 {$REGION 'Logs'}
  procedure Log(const Msg: string);
 {$ENDREGION}

 //zYzP7ocstxh3Sscefew4FZTCu4ehnM8v4hu

implementation

uses
  System.SysUtils;

{$REGION 'Instancia'}

Function InstanceCreate(Out Token, msg: String; URL, APIKEY, NomeInstancia, Descricao:string):Boolean;
var
  LResponse : IResponse;
  JsonBody  : TJsonObject;
  StatusCode: Integer;
begin
  Result    := False;
  JsonBody  := TJSONObject.Create;
  Try
    JSonBody.AddPair('instanceName',Trim(NomeInstancia));
    JSonBody.AddPair('qrcode', true);
    JSonBody.AddPair('integration', 'WHATSAPP-BAILEYS');
    //JSonBody.AddPair('description',Trim(Descricao));

    Try
      LResponse := TRequest.New.BaseURL(url.TrimRight(['/']))
                .Resource('instance/create')
                .AddHeader('Content-Type', 'application/json')
                .AddHeader('apikey', APIKEY)
                .AddBody(JsonBody.ToJSON,TRESTContentType.ctAPPLICATION_JSON)  //TRESTContentType.ctAPPLICATION_JSON
                .Post;

      StatusCode := LResponse.StatusCode;
      log('Instância criada: Código:'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content);

      if StatusCode in [200, 201] then
      begin
        Result  := True;
        var
        LJson := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
        //Token   :=LJson.GetValue<string>('Auth.token');
        Token   := LJson.GetValue<string>('instanceId');
      end
      else
      if StatusCode = 403 then
      begin
        // Nome já está em uso
        msg := TJSONObject.ParseJSONValue(LResponse.Content)
                    .GetValue<TJSONArray>('message')
                    .Items[0].Value;
      end
      else
      begin
        // Outro erro
        msg := LResponse.Content;
      end;
    Except on e:exception do
      begin
        msg := 'Erro ao criar instância: ' + E.Message;
        Result := False;
      end;
    End;

  Finally
    FreeAndNil(JSonBody);
  End;

end;

Function InstanceDelete(Out msg: String; Token, URL, NomeInstancia:string):Boolean;
var
  LResponse : IResponse;
  StatusCode: Integer;
begin
  Result    := False;

  Try
    LResponse := TRequest.New.BaseURL(url)
                  .Resource('/instance/delete/' + Trim(NomeInstancia))
                  .AddParam('Authorization', 'Bearer ' + Token, pkHTTPHEADER, [poDoNotEncode])
                  .Delete;

    StatusCode := LResponse.StatusCode;
    log('Instance/delete: Código:'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content);

    if StatusCode = 200 then
    begin
      Result  := True;
      msg     := 'Instância excluída com sucesso.';
    end
    else
    if StatusCode = 400 then
    begin
      msg     := 'Nenhuma instância encontrada para excluir.';
    end
    else
    if StatusCode = 401 then
    begin
      msg     := 'Nenhum token encontrado ou sem autorização.';
    end
    else
    begin
      // Outro erro
      msg := LResponse.Content;
    end;
  Except on e:exception do
    begin
      msg := 'Erro ao detelar instância: ' + E.Message;
      Result := False;
    end;
  End;
end;

Function InstanceConnect(Out msg, Base64:String; URL, NomeInstancia, Token :String):Boolean;
var
  LResponse     : IResponse;
  StatusCode    : Integer;
  LJsonResponse : TJSONObject;
begin
  Result        := False;
  Base64        := '';

  Try
    LResponse := TRequest.New.BaseURL(url)
                  .Resource('/instance/connect/' + Trim(NomeInstancia))
                  .AddParam('Authorization', 'Bearer ' + Token, pkHTTPHEADER, [poDoNotEncode])
                  .Get;

    StatusCode := LResponse.StatusCode;
    log('InstanceConnect:Código:'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content);

    if StatusCode = 200 then
    begin
      {
       "state": "refused",
       "statusReason": 428
      }

      {
      "count": 1,
      "base64":"aqui minnha base 64",
      "code":""
      }
      LJsonResponse := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;

      Try
        if LJsonResponse.GetValue('state') <> nil then
        begin
          // É a estrutura de erro
          Msg := 'Estado: ' + LJsonResponse.GetValue<string>('state') +
                 ', Motivo: ' + LJsonResponse.GetValue<string>('statusReason');
        end
        else
        if LJsonResponse.GetValue('base64') <> nil then
        begin
          // É a estrutura de sucesso
          Base64 := LJsonResponse.GetValue<string>('base64');
          Msg := 'Base64 recebido com sucesso.';
          Result := True;
        end
        else
        begin
          Msg := 'Resposta inesperada: ' + LResponse.Content;
        end;
      Finally
        FreeAndNIl(LJsonResponse);
      end;

    end
    else
    if StatusCode = 401 then
    begin
      LJsonResponse := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
      Try
        msg := 'Status: ' + LJsonResponse.GetValue<string>('status') +
               ', Error: ' + LJsonResponse.GetValue<string>('error');
      Finally
        FreeAndNil(LJsonResponse);
      End;
    end
    else
    begin
      // Outro erro
      msg := LResponse.Content;
    end;
  Except on e:exception do
    begin
      msg := 'Erro ao conectar a uma instância: ' + E.Message;
      Result := False;
    end;
  End;
end;

Function InstanceLogout(Out msg: String; Token, URL, NomeInstancia:string):Boolean;
var
  LResponse : IResponse;
  StatusCode: Integer;
begin
  Result    := False;

  Try
    LResponse := TRequest.New.BaseURL(url)
                  .Resource('/instance/logout/' + Trim(NomeInstancia))
                  .AddParam('Authorization', 'Bearer ' + Token, pkHTTPHEADER, [poDoNotEncode])
                  .Delete;

    StatusCode := LResponse.StatusCode;
    log('Instance/logout: Código:'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content);

    if StatusCode = 200 then
    begin
      Result  := True;
      msg     := 'Logout realizado com sucesso.';
    end
    else
    if StatusCode = 400 then
    begin
      msg     := 'Nenhuma instância encontrada para realizar o logout.';
    end
    else
    if StatusCode = 401 then
    begin
      msg     := 'Nenhum token encontrado ou sem autorização.';
    end
    else
    begin
      // Outro erro
      msg := LResponse.Content;
    end;
  Except on e:exception do
    begin
      msg := 'Erro ao fazer o logout da instância: ' + E.Message;
      Result := False;
    end;
  End;
end;

Function InstanceConnectionStatus(Out msg, state: String; Token, URL, NomeInstancia:string):Boolean;
var
  LResponse     : IResponse;
  StatusCode    : Integer;
  LJsonResponse : TJSONObject;
begin
  Result        := False;

  Try
    LResponse := TRequest.New.BaseURL(url)
                  .Resource('/instance/connectionState/' + Trim(NomeInstancia))
                  .AddParam('Authorization', 'Bearer ' + Token, pkHTTPHEADER, [poDoNotEncode])
                  .Get;

    StatusCode := LResponse.StatusCode;
    log('ConnectionState:Código:'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content);

    if StatusCode = 200 then
    begin
      Result    := True;
      {
      "state": "open",
      "statusReason": 200
      }
      LJsonResponse := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;

      Try
        if LJsonResponse.GetValue('state') <> nil then
        begin
          // É a estrutura de erro
          Msg   := 'Estado: ' + LJsonResponse.GetValue<string>('state') +
                 ', Motivo: ' + LJsonResponse.GetValue<string>('statusReason');
          state := LJsonResponse.GetValue<string>('state');
        end
        else
        begin
          Msg := 'Resposta inesperada: ' + LResponse.Content;
        end;
      Finally
        FreeAndNIl(LJsonResponse);
      end;

    end
    else
    if StatusCode = 401 then
    begin
      LJsonResponse := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
      Try
        msg := 'Status: ' + LJsonResponse.GetValue<string>('status') +
               ', Error: ' + LJsonResponse.GetValue<string>('error');
        state := LJsonResponse.GetValue<string>('state');
      Finally
        FreeAndNil(LJsonResponse);
      End;
    end
    else
    begin
      // Outro erro
      msg := LResponse.Content;
    end;
  Except on e:exception do
    begin
      msg := 'Erro ao verificar a instância: ' + E.Message;
      Result := False;
    end;
  End;
end;


 {$ENDREGION}

{$REGION 'Mensagem'}

Function MessageText(Out msg:string; URL, NomeInstancia, Token, Numero, MensagemFormatada:String):Boolean;
var
  LResponse : IResponse;
  JsonBody, JsonOptions, JsonText : TJSONObject;
  StatusCode: Integer;
begin
  Result    := False;
  JsonBody    := TJSONObject.Create;
  JsonOptions := TJSONObject.Create;
  JsonText    := TJSONObject.Create;

  Try
    JsonOptions.AddPair('delay', TJSONNumber.Create(1200));
    JsonOptions.AddPair('presence', 'composing');

    JsonText.AddPair('text', Trim(MensagemFormatada));

    JsonBody.AddPair('number', Trim(Numero));
    JsonBody.AddPair('options', JsonOptions);
    JsonBody.AddPair('textMessage', JsonText);

    Try
      LResponse := TRequest.New.BaseURL(url)
                .Resource('/message/sendText/' +Trim(NomeInstancia))
                .AddParam('Authorization', 'Bearer ' + Token, pkHTTPHEADER, [poDoNotEncode])
                .AddBody(JsonBody.ToJSON, TRESTContentType.ctAPPLICATION_JSON)
                .Post;

      StatusCode := LResponse.StatusCode;
      log('sendText: Código:'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content);

      if StatusCode = 201 then
      begin
        Result  := True;
        msg     := 'Mensagem enviada: ' + LResponse.Content;
      end
      else
      if StatusCode = 401 then
      begin
        msg     := 'Não autorizado:' +LResponse.Content;
      end
      else
      if StatusCode = 400 then
      begin
        msg     := 'Verifique o número digitado: '+LResponse.Content;
      end
      else
      begin
        msg := LResponse.Content;
      end;
    except on e:exception do
      begin
        msg := 'Erro ao enviar mensagem: ' + E.Message;
        Result := False;
      end;
    End;

  Finally
    JsonBody.Free;
  End;

end;

Function MessageMedia(Out msg:string; URL, NomeInstancia, Token, Numero, media, filename, caption, mediatype:String):Boolean;
var
  LResponse : IResponse;
  JsonBody, JsonOptions, JsonTextMedia : TJSONObject;
  StatusCode: Integer;
begin
  //somante quando estiver hospedado em outro servidor.
  Result    := False;
  JsonBody    := TJSONObject.Create;
  JsonOptions := TJSONObject.Create;
  JsonTextMedia    := TJSONObject.Create;

  Try
    JsonOptions.AddPair('delay', TJSONNumber.Create(1200));
    JsonOptions.AddPair('presence', 'composing');
    //JsonOptions.AddPair('quotedMessageId', '1');


    JsonTextMedia.AddPair('mediatype', mediatype);
    JsonTextMedia.AddPair('fileName', filename);
    JsonTextMedia.AddPair('caption', caption);
    JsonTextMedia.AddPair('media', media);

    JsonBody.AddPair('number', Trim(Numero));
    JsonBody.AddPair('options', JsonOptions);
    JsonBody.AddPair('mediaMessage', JsonTextMedia);

    Try
      LResponse := TRequest.New.BaseURL(url)
                .Resource('/message/sendMedia/' +Trim(NomeInstancia))
                .AddParam('Authorization', 'Bearer ' + Token, pkHTTPHEADER, [poDoNotEncode])
                .AddBody(JsonBody.ToJSON, TRESTContentType.ctAPPLICATION_JSON)
                .Post;

      StatusCode := LResponse.StatusCode;
      log('sendMedia: Código:'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content);

      if StatusCode = 201 then
      begin
        Result  := True;
        msg     := 'Media enviada.'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content;
      end
      else
      if StatusCode = 401 then
      begin
        msg     := 'Não autorizado.'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content;
      end
      else
      if StatusCode = 400 then
      begin
        msg     := 'Verifique o número digitado.'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content;
      end
      else
      begin
        msg := LResponse.Content;
      end;

    except on e:exception do
      begin
        msg := 'Erro ao enviar mensagem: ' + E.Message;
        Result := False;
      end;
    End;

  Finally
    JsonBody.Free;
  End;

end;

Function MessageMediaFile(Out msg:string; URL, NomeInstancia, Token, Numero, caption, mediatype, attachment, quotedid :String):Boolean;
var
  LResponse : IResponse;
  StatusCode: Integer;
begin
  Result    := False;

  Try
    LResponse := TRequest.New.BaseURL(url)
                .Resource('/message/sendMediaFile/' +Trim(NomeInstancia))
                .AddParam('Authorization', 'Bearer ' + Token, pkHTTPHEADER, [poDoNotEncode])
                .AddField('number', Trim(Numero))
                .AddField('caption',Trim(caption))
                .AddField('mediatype',mediatype)//tipo de arquivo
                .AddField('presence','composing')
                .AddField('delay','1200')
                //.AddField('quotedMessageId',quotedid)
                .AddFile('attachment',attachment)
                .Post;

    StatusCode := LResponse.StatusCode;
    log('sendMediaFile: Código:'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content);

    if StatusCode = 201 then
    begin
      Result  := True;
      msg     := 'Media enviada.'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content;
    end
    else
    if StatusCode = 401 then
    begin
      msg     := 'Não autorizado.'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content;
    end
    else
    if StatusCode = 400 then
    begin
      msg     := 'Verifique o número digitado.'+ inttoStr(LResponse.StatusCode)+' Messagem:'+LResponse.Content;
    end
    else
    begin
      msg := LResponse.Content;
    end;
  except on e:exception do
    begin
      msg := 'Erro ao enviar mensagem: ' + E.Message;
      Result := False;
    end;
  End;
end;

{$ENDREGION}

{$REGION 'Logs'}
procedure Log(const Msg: string);
var
  LogFile: TextFile;
  FileName: string;
begin
  FileName := ExtractFilePath(ParamStr(0)) +'\LogMensagenszap.txt';
  AssignFile(LogFile, FileName);
  if FileExists(FileName) then
    Append(LogFile)
  else
    Rewrite(LogFile);
  try
    Writeln(LogFile, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + Msg);
  finally
    CloseFile(LogFile);
  end;
end;

 {$ENDREGION}


 end.
