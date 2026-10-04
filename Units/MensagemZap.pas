unit MensagemZap;

interface

Uses
 ACBRUTIL, RESTRequest4D,DataSet.Serialize.Adapter.RESTRequest4D,System.JSON, UConeSul, uni;

 Function EnviarMSG(out msg:string;telefone, mensagem:string; token:string;Connection: TUniConnection):boolean;
 Function EnviarMSGArquivoIMG(out msg:string;telefone, mensagem, anexo:string; token:string;Connection: TUniConnection):boolean;
 Function EnviarMSGArquivo(out msg:string;telefone, mensagem, anexo:string; token:string;Connection: TUniConnection):boolean;
 Function EnviarMSGArquivoVideo(out msg:string;telefone, mensagem, anexo:string; token:string;Connection: TUniConnection):boolean;
 Function EnviarMSGLink(out msg:string;telefone, URLAPP:string; token:string;Connection: TUniConnection):boolean;

 Function InitInstance(Token: String;Connection: TUniConnection):Boolean;
 Function InstanciaInfo(Token: String;Connection: TUniConnection):Boolean;

 Function UrlWhatsApp(out URL:String; Connection: TUniConnection):Boolean;
 procedure Log(const Msg: string);

implementation

uses UnitEasyBot,SysUtils;

Function InstanciaInfo(Token: String;Connection: TUniConnection):Boolean;
var
  LResponse : IResponse;
  JsonResp: TJSONObject;
  url       : string;
  ErrorMsg, Msg: string;
begin
  //Funcao para verificar se a instancia está on se não subir.
  Result  := false;

  if UrlWhatsApp(url, Connection) then
  begin
    LResponse := TRequest.New.BaseURL(url)
                .Resource('instance/info?')
                .AddParam('key',token)
                .Get;

    try
      JsonResp := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
    except
      JsonResp := nil;
    end;

    if Assigned(JsonResp) then
    begin
      if LResponse.StatusCode = 200 then
      begin
        Msg := JsonResp.GetValue<string>('message');
        log(Format('Instância conectada com sucesso: %d - %s', [LResponse.StatusCode, Msg]));
        Result := True;
      end
      else
      begin
        ErrorMsg := JsonResp.GetValue<string>('message');
        log(Format('Erro na instância: %d - %s', [LResponse.StatusCode, ErrorMsg]));

        if InitInstance(token,Connection) then
        begin
          Result  := True;
        end;

      end;

      JsonResp.Free;
    end
    else
    begin
      log(Format('Erro ao processar resposta da instância: %d - %s', [LResponse.StatusCode, LResponse.Content]));
    end;
  end;

end;

Function InitInstance(Token: String;Connection: TUniConnection):Boolean;
var
  LResponse : IResponse;
  JsonResp: TJSONObject;
  url       : string;
  ErrorMsg, Msg: string;
begin
  //Funcao para verificar se a instancia está on se não subir.
  Result  := false;

  if UrlWhatsApp(url, Connection) then
  begin
    LResponse := TRequest.New.BaseURL(url)
                .Resource('instance/init?')
                .AddParam('key',token)
                .AddParam('token','RANDOM_STRING_HERE')
                .Get;

    try
      JsonResp := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
    except
      JsonResp := nil;
    end;

    if Assigned(JsonResp) then
    begin
      if LResponse.StatusCode = 200 then
      begin
        Msg := JsonResp.GetValue<string>('message');
        log(Format('Instância inicializada com sucesso: %d - %s', [LResponse.StatusCode, Msg]));
        Result := True;
      end
      else
      begin
        ErrorMsg := JsonResp.GetValue<string>('message');
        log(Format('Erro na instância: %d - %s', [LResponse.StatusCode, ErrorMsg]));
      end;

      JsonResp.Free;
    end
    else
    begin
      log(Format('Erro ao processar resposta da instância: %d - %s', [LResponse.StatusCode, LResponse.Content]));
    end;
  end;
end;

Function EnviarMSG(out msg:string;telefone, mensagem:string; token:string;Connection: TUniConnection):boolean;
var
  LResponse : IResponse;
  JsonBody  : TJsonObject;
  url       : string;
begin
  //Chamada de envio de mensagem
  Result  := false;

  if UrlWhatsApp(url, Connection) then
  begin
    LResponse := TRequest.New.BaseURL(url)
                .Resource('/message/text?')
                .AddParam('key',token)
                .AddField('id',telefone)
                .AddField('message',Mensagem)
                .Post;

    if LResponse.StatusCode = 201 then
    begin
      log(Format('Mensagem postada -> %d - [%s]',[LResponse.StatusCode,LResponse.StatusText]));
      Result  := True;
    end
    else
    begin
      log(Format('Erro statusCode -> %d - [%s]',[LResponse.StatusCode,LResponse.StatusText]));
      result  := False;
    end;

  end;

end;

Function UrlWhatsApp(out URL:String; Connection: TUniConnection):Boolean;
var
  Qry       :TUniquery;
  sqlQuery  :string;
begin
  Result      := False;
  sqlQuery    := 'Select urlapiwhatsapp as url from configuracao_nf limit 1';
  Qry         := TUniQuery.Create(nil);

  try
    try
      Qry.Connection    := Connection;
      Qry.SQL.Text      := SqlQuery;
      Qry.Open;

      if not Qry.IsEmpty then
      begin
        if qry.FieldByName('url').AsString <> '' then
        begin
          url     := qry.FieldByName('url').AsString;
          Result  := True;
        end
        else
        begin
          url     := '';
          Result  := False;
        end;
      end;

      Qry.Close;
    except
      on E: Exception do
      begin
        log(Format('Erro ao localizar a URL WhatsApp. SQL: %s - Erro: %s', [sqlQuery, e.message]));
        raise;
      end;
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure Log(const Msg: string);
var
  LogFile: TextFile;
  FileName: string;
begin
  FileName := ExtractFilePath(ParamStr(0)) +'\LogMensagenszap.txt'; // Adjust path as needed
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

Function EnviarMSGArquivoIMG(out msg:string;telefone, mensagem, anexo:string; token:string;Connection: TUniConnection):boolean;
var
  LResponse : IResponse;
  url       : string;
begin
  //Chamada de envio de enviar PDF
  Result  := False;

  if UrlWhatsApp(url, Connection) then
  begin
    LResponse := TRequest.New.BaseURL(url)
                  .Resource('/message/image?')
                  .AddParam('key',token)
                  .AddFile('file',anexo)
                  .AddField('id',telefone)
                  .AddField('caption','')
                  .Post;

    if LResponse.StatusCode = 201 then
    begin
      log(Format('Mensagem postada -> %d - [%s]',[LResponse.StatusCode,LResponse.StatusText]));
      Result  := True
    end
    else
    begin
      log(Format('Mensagem postada -> %d - [%s]',[LResponse.StatusCode,LResponse.StatusText]));
      result  := False;
    end;
  end;

end;

Function EnviarMSGArquivo(out msg:string;telefone, mensagem, anexo:string; token:string;Connection: TUniConnection):boolean;
var
  LResponse : IResponse;
  url       : string;
begin
  //Chamada de envio de enviar PDF
  Result  := False;

  if UrlWhatsApp(url, Connection) then
  begin


        LResponse := TRequest.New.BaseURL(url)
                .Resource('/message/doc?')
                .AddParam('key',token)
                .AddFile('file',anexo)
                .AddField('id',telefone)
                .AddField('filename','')
                .Post;

        if LResponse.StatusCode = 201 then
        begin
          log(Format('Mensagem postada -> %d - [%s]',[LResponse.StatusCode,LResponse.StatusText]));
          Result  := True
        end
        else
        begin
          log(Format('Mensagem postada -> %d - [%s]',[LResponse.StatusCode,LResponse.StatusText]));
          result  := False;
        end;


  end;

end;

Function EnviarMSGArquivoVideo(out msg:string;telefone, mensagem, anexo:string; token:string;Connection: TUniConnection):boolean;
var
  LResponse : IResponse;
  url       : string;

begin
  //Chamada de envio de enviar PDF
  Result  := False;

  if UrlWhatsApp(url, Connection) then
  begin
   
        LResponse := TRequest.New.BaseURL(url)
                .Resource('/message/video?')
                .AddParam('key',token)
                .AddFile('file',anexo)
                .AddField('id',telefone)
                .AddField('caption','')
                .Post;

        if LResponse.StatusCode = 201 then
        begin
          log(Format('Mensagem postada -> %d - [%s]',[LResponse.StatusCode,LResponse.StatusText]));
          Result  := True
        end
        else
        begin
          log(Format('Mensagem postada -> %d - [%s]',[LResponse.StatusCode,LResponse.StatusText]));
          result  := False;
        end;


  end;

end;

Function EnviarMSGLink(out msg:string;telefone, URLAPP:string; token:string;Connection: TUniConnection):boolean;
var
  LResponse : IResponse;
  url       : string;

begin
  //Chamada de envio de mensagem
  Result  := False;

  if UrlWhatsApp(url, Connection) then
  begin


        LResponse := TRequest.New.BaseURL(url)
                .Resource('/message/mediaurl?')
                .AddParam('key',token)
                .AddField('id',telefone)
                .AddField('message',URLAPP)
                .Post;

        if LResponse.StatusCode = 201 then
        begin
          log(Format('Mensagem postada -> %d - [%s]',[LResponse.StatusCode,LResponse.StatusText]));
          Result  := True
        end
        else
        begin
          log(Format('Mensagem postada -> %d - [%s]',[LResponse.StatusCode,LResponse.StatusText]));
          result  := False;
        end;

  end;

end;

end.
