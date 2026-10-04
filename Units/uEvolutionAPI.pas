unit uEvolutionAPI;

interface

uses
  System.SysUtils,
  System.JSON,
  REST.Types,
  RESTRequest4D;

type
  TEvolutionAPI = class
  private
    FBaseURL: string;
    FAPIKey: string;
    class function ApenasNumeros(const Valor: string): string; static;
    class function JSONTexto(const Conteudo, Caminho: string): string; static;
    class function RespostaSucesso(const Resposta: IResponse): Boolean; static;
    class function MensagemResposta(const Resposta: IResponse): string; static;
    function RecursoInstancia(const Prefixo, NomeInstancia: string): string;
  public
    constructor Create(const BaseURL, APIKey: string);
    function Ping(out Versao, Msg: string): Boolean;
    function InstanceCreate(const NomeInstancia: string; out Token, QRCodeBase64, Msg: string): Boolean;
    function InstanceConnect(const NomeInstancia: string; out QRCodeBase64, QRCode, PairingCode, Msg: string): Boolean;
    function InstanceConnectionState(const NomeInstancia: string; out Estado, Msg: string): Boolean;
    function InstanceFetchAll(out JSON, Msg: string): Boolean;
    function InstanceRestart(const NomeInstancia: string; out Msg: string): Boolean;
    function InstanceLogout(const NomeInstancia: string; out Msg: string): Boolean;
    function InstanceDelete(const NomeInstancia: string; out Msg: string): Boolean;
    function WhatsAppNumberExists(const NomeInstancia, Numero: string; out Existe: Boolean; out JID, Msg: string): Boolean;
    function SendText(const NomeInstancia, Numero, Texto: string; out MessageID, Msg: string; Delay: Integer = 1000; LinkPreview: Boolean = False): Boolean;
    function SendMedia(const NomeInstancia, Numero, CaminhoArquivo, Legenda: string;
    out MessageID, Msg: string; const MediaType: string; const NomeArquivo: string = ''): Boolean;
    property BaseURL: string read FBaseURL;
  end;

implementation

{ TEvolutionAPI }

constructor TEvolutionAPI.Create(const BaseURL, APIKey: string);
begin
  inherited Create;
  FBaseURL := Trim(BaseURL);
  while (FBaseURL <> '') and (FBaseURL[Length(FBaseURL)] = '/') do Delete(FBaseURL, Length(FBaseURL), 1);
  FAPIKey := Trim(APIKey);
  if FBaseURL = '' then raise EArgumentException.Create('URL da Evolution API não informada.');
  if FAPIKey = '' then raise EArgumentException.Create('Chave da Evolution API não informada.');
end;

class function TEvolutionAPI.ApenasNumeros(const Valor: string): string;
var
  C: Char;
begin
  Result := '';
  for C in Valor do
    if CharInSet(C, ['0'..'9']) then Result := Result + C;
end;

class function TEvolutionAPI.JSONTexto(const Conteudo, Caminho: string): string;
var
  JSON, Valor: TJSONValue;
begin
  Result := '';
  if Trim(Conteudo) = '' then Exit;
  JSON := TJSONObject.ParseJSONValue(Conteudo);
  try
    if not Assigned(JSON) then Exit;
    Valor := JSON.FindValue(Caminho);
    if not Assigned(Valor) or (Valor is TJSONNull) then Exit;
    if Valor is TJSONString then Result := Valor.Value else Result := Valor.ToJSON;
  finally
    JSON.Free;
  end;
end;

class function TEvolutionAPI.RespostaSucesso(const Resposta: IResponse): Boolean;
begin
  Result := Assigned(Resposta) and (Resposta.StatusCode >= 200) and (Resposta.StatusCode < 300);
  if not Result then Exit;
  if SameText(JSONTexto(Resposta.Content, 'error'), 'true') then Exit(False);
  if SameText(JSONTexto(Resposta.Content, 'success'), 'false') then Exit(False);
end;

class function TEvolutionAPI.MensagemResposta(const Resposta: IResponse): string;
begin
  if not Assigned(Resposta) then Exit('A Evolution API não retornou uma resposta.');
  Result := JSONTexto(Resposta.Content, 'response.message');
  if Result = '' then Result := JSONTexto(Resposta.Content, 'error.message');
  if Result = '' then Result := JSONTexto(Resposta.Content, 'message');
  if Result = '' then Result := Trim(Resposta.Content);
  if Result = '' then Result := Format('HTTP %d sem conteúdo de resposta.', [Resposta.StatusCode]);
end;

function TEvolutionAPI.RecursoInstancia(const Prefixo, NomeInstancia: string): string;
begin
  if Trim(NomeInstancia) = '' then raise EArgumentException.Create('Nome da instância não informado.');
  Result := Prefixo + Trim(NomeInstancia);
end;

function TEvolutionAPI.Ping(out Versao, Msg: string): Boolean;
var
  Resposta: IResponse;
begin
  Result := False;
  Versao := '';
  Msg := '';
  try
    Resposta := TRequest.New.BaseURL(FBaseURL)
      .AddHeader('Accept', 'application/json')
      .AddHeader('apikey', FAPIKey)
      .Get;
    Result := RespostaSucesso(Resposta);
    if Result then
    begin
      Versao := JSONTexto(Resposta.Content, 'version');
      Msg := 'Evolution API disponível.';
    end
    else Msg := MensagemResposta(Resposta);
  except
    on E: Exception do Msg := E.Message;
  end;
end;

function TEvolutionAPI.InstanceCreate(const NomeInstancia: string; out Token, QRCodeBase64, Msg: string): Boolean;
var
  Resposta: IResponse;
  Body: TJSONObject;
begin
  Result := False;
  Token := '';
  QRCodeBase64 := '';
  Msg := '';
  if Trim(NomeInstancia) = '' then
  begin
    Msg := 'Nome da instância não informado.';
    Exit;
  end;
  Body := TJSONObject.Create;
  try
    Body.AddPair('instanceName',  Trim(NomeInstancia));
    Body.AddPair('qrcode',        TJSONBool.Create(True));
    Body.AddPair('integration',   'WHATSAPP-BAILEYS');
    try
      Resposta := TRequest.New
        .BaseURL(FBaseURL + '/instance/create')
        .Accept('application/json')
        .ContentType('application/json')
        .AddHeader('apikey', FAPIKey)
        .AddBody(Body.ToJSON)
        .Post;
      Result := RespostaSucesso(Resposta);
      if Result then
      begin
        Token := JSONTexto(Resposta.Content, 'hash');
        QRCodeBase64 := JSONTexto(Resposta.Content, 'qrcode.base64');
        Msg := 'Instância criada com sucesso.';
      end
      else Msg := MensagemResposta(Resposta);
    except
      on E: Exception do Msg := E.Message;
    end;
  finally
    Body.Free;
  end;
end;

function TEvolutionAPI.InstanceConnect(const NomeInstancia: string; out QRCodeBase64, QRCode, PairingCode, Msg: string): Boolean;
var
  Resposta: IResponse;
begin
  Result := False;
  QRCodeBase64 := '';
  QRCode := '';
  PairingCode := '';
  Msg := '';
  try
    Resposta := TRequest.New.BaseURL(FBaseURL)
      .Resource(RecursoInstancia('instance/connect/', NomeInstancia))
      .AddHeader('Accept', 'application/json')
      .AddHeader('apikey', FAPIKey)
      .Get;
    Result := RespostaSucesso(Resposta);
    if Result then
    begin
      QRCodeBase64    := JSONTexto(Resposta.Content, 'base64');
      QRCode          := JSONTexto(Resposta.Content, 'code');
      PairingCode     := JSONTexto(Resposta.Content, 'pairingCode');
      Msg             := 'Dados de conexão obtidos com sucesso.';
    end
    else Msg := MensagemResposta(Resposta);
  except
    on E: Exception do Msg := E.Message;
  end;
end;

function TEvolutionAPI.InstanceConnectionState(const NomeInstancia: string; out Estado, Msg: string): Boolean;
var
  Resposta: IResponse;
begin
  Result := False;
  Estado := '';
  Msg := '';
  try
    Resposta := TRequest.New.BaseURL(FBaseURL)
      .Resource(RecursoInstancia('instance/connectionState/', NomeInstancia))
      .AddHeader('Accept', 'application/json')
      .AddHeader('apikey', FAPIKey)
      .Get;
    Result := RespostaSucesso(Resposta);
    if Result then
    begin
      Estado := JSONTexto(Resposta.Content, 'instance.state');
      Msg := 'Estado da instância consultado com sucesso.';
    end
    else Msg := MensagemResposta(Resposta);
  except
    on E: Exception do Msg := E.Message;
  end;
end;

function TEvolutionAPI.InstanceFetchAll(out JSON, Msg: string): Boolean;
var
  Resposta: IResponse;
begin
  Result := False;
  JSON := '';
  Msg := '';
  try
    Resposta := TRequest.New.BaseURL(FBaseURL)
      .Resource('instance/fetchInstances')
      .AddHeader('Accept', 'application/json')
      .AddHeader('apikey', FAPIKey)
      .Get;
    Result := RespostaSucesso(Resposta);
    if Result then
    begin
      JSON := Resposta.Content;
      Msg := 'Instâncias consultadas com sucesso.';
    end
    else Msg := MensagemResposta(Resposta);
  except
    on E: Exception do Msg := E.Message;
  end;
end;

function TEvolutionAPI.InstanceRestart(const NomeInstancia: string; out Msg: string): Boolean;
var
  Resposta: IResponse;
begin
  Result := False;
  Msg := '';
  try
    Resposta := TRequest.New.BaseURL(FBaseURL)
      .Resource(RecursoInstancia('instance/restart/', NomeInstancia))
      .AddHeader('Accept', 'application/json')
      .AddHeader('apikey', FAPIKey)
      .Post;
    Result := RespostaSucesso(Resposta);
    if Result then Msg := 'Instância reiniciada com sucesso.' else Msg := MensagemResposta(Resposta);
  except
    on E: Exception do Msg := E.Message;
  end;
end;

function TEvolutionAPI.InstanceLogout(const NomeInstancia: string; out Msg: string): Boolean;
var
  Resposta: IResponse;
begin
  Result := False;
  Msg := '';
  try
    Resposta := TRequest.New.BaseURL(FBaseURL)
      .Resource(RecursoInstancia('instance/logout/', NomeInstancia))
      .AddHeader('Accept', 'application/json')
      .AddHeader('apikey', FAPIKey)
      .Delete;
    Result := RespostaSucesso(Resposta);
    if Result then Msg := 'Logout realizado com sucesso.' else Msg := MensagemResposta(Resposta);
  except
    on E: Exception do Msg := E.Message;
  end;
end;

function TEvolutionAPI.InstanceDelete(const NomeInstancia: string; out Msg: string): Boolean;
var
  Resposta: IResponse;
begin
  Result := False;
  Msg := '';
  try
    Resposta := TRequest.New.BaseURL(FBaseURL)
      .Resource(RecursoInstancia('instance/delete/', NomeInstancia))
      .AddHeader('Accept', 'application/json')
      .AddHeader('apikey', FAPIKey)
      .Delete;
    Result := RespostaSucesso(Resposta);
    if Result then Msg := 'Instância excluída com sucesso.' else Msg := MensagemResposta(Resposta);
  except
    on E: Exception do Msg := E.Message;
  end;
end;

function TEvolutionAPI.WhatsAppNumberExists(const NomeInstancia, Numero: string; out Existe: Boolean; out JID, Msg: string): Boolean;
var
  Resposta: IResponse;
  Body: TJSONObject;
  Numeros: TJSONArray;
  JSON, Item, Valor: TJSONValue;
  NumeroLimpo: string;
begin
  Result := False;
  Existe := False;
  JID := '';
  Msg := '';
  NumeroLimpo := ApenasNumeros(Numero);
  if Length(NumeroLimpo) < 10 then
  begin
    Msg := 'Número do WhatsApp inválido. Informe país, DDD e telefone.';
    Exit;
  end;
  Body := TJSONObject.Create;
  try
    Numeros := TJSONArray.Create;
    Numeros.Add(NumeroLimpo);
    Body.AddPair('numbers', Numeros);
    try
      Resposta := TRequest.New.BaseURL(FBaseURL)
        .Resource(RecursoInstancia('chat/whatsappNumbers/', NomeInstancia))
        .AddHeader('Accept', 'application/json')
        .AddHeader('Content-Type', 'application/json')
        .AddHeader('apikey', FAPIKey)
        .AddBody(Body.ToJSON, TRESTContentType.ctAPPLICATION_JSON)
        .Post;
      Result := RespostaSucesso(Resposta);
      if not Result then
      begin
        Msg := MensagemResposta(Resposta);
        Exit;
      end;
      JSON := TJSONObject.ParseJSONValue(Resposta.Content);
      try
        Item := nil;
        if JSON is TJSONArray then
        begin
          if TJSONArray(JSON).Count > 0 then Item := TJSONArray(JSON).Items[0];
        end
        else if Assigned(JSON) then Item := JSON.FindValue('numbers[0]');
        if Assigned(Item) then
        begin
          Valor := Item.FindValue('exists');
          Existe := Assigned(Valor) and SameText(Valor.Value, 'true');
          Valor := Item.FindValue('jid');
          if Assigned(Valor) and not (Valor is TJSONNull) then JID := Valor.Value;
        end;
      finally
        JSON.Free;
      end;
      Msg := 'Número consultado com sucesso.';
    except
      on E: Exception do
      begin
        Result := False;
        Msg := E.Message;
      end;
    end;
  finally
    Body.Free;
  end;
end;

function TEvolutionAPI.SendText(const NomeInstancia, Numero, Texto: string; out MessageID, Msg: string; Delay: Integer; LinkPreview: Boolean): Boolean;
var
  Resposta: IResponse;
  Body: TJSONObject;
  NumeroLimpo: string;
begin
  Result := False;
  MessageID := '';
  Msg := '';
  NumeroLimpo := ApenasNumeros(Numero);

  if Length(NumeroLimpo) < 10 then
  begin
    Msg := 'Número do WhatsApp inválido. Informe país, DDD e telefone.';
    Exit;
  end;

  if Trim(Texto) = '' then
  begin
    Msg := 'Texto da mensagem não informado.';
    Exit;
  end;

  if Delay < 0 then Delay := 0;

  Body := TJSONObject.Create;

  try
    Body.AddPair('number', NumeroLimpo);
    Body.AddPair('text', Texto);
    Body.AddPair('delay', TJSONNumber.Create(Delay));
    Body.AddPair('linkPreview', TJSONBool.Create(LinkPreview));

    try
      Resposta := TRequest.New.BaseURL(FBaseURL)
        .Resource(RecursoInstancia('message/sendText/', NomeInstancia))
        .Accept('application/json')
        .ContentType('application/json')
        .AddHeader('apikey', FAPIKey)
        .AddBody(Body.ToJSON)
        .Post;
      Result := RespostaSucesso(Resposta);
      if Result then
      begin
        MessageID := JSONTexto(Resposta.Content, 'key.id');
        Msg := 'Mensagem enviada com sucesso.';
      end
      else Msg := MensagemResposta(Resposta);
    except
      on E: Exception do Msg := E.Message;
    end;
  finally
    Body.Free;
  end;
end;

function TEvolutionAPI.SendMedia(const NomeInstancia, Numero, CaminhoArquivo,
  Legenda: string; out MessageID, Msg: string; const MediaType,
  NomeArquivo: string): Boolean;
var
  Requisicao: IRequest;
  Resposta: IResponse;
  NumeroLimpo, ArquivoEnvio, NomeArquivoEnvio: string;
  TipoMidia, MimeType, Extensao: string;

  function ObterMimeType(const AArquivo: string): string;
  var
    Ext: string;
  begin
    Ext := LowerCase(ExtractFileExt(AArquivo));

    if (Ext = '.jpg') or (Ext = '.jpeg') or (Ext = '.jfif') then Result := 'image/jpeg'
    else if Ext = '.png'  then Result := 'image/png'
    else if Ext = '.gif'  then Result := 'image/gif'
    else if Ext = '.webp' then Result := 'image/webp'
    else if Ext = '.pdf'  then Result := 'application/pdf'
    else if Ext = '.mp4'  then Result := 'video/mp4'
    else if Ext = '.webm' then Result := 'video/webm'
    else if Ext = '.mp3'  then Result := 'audio/mpeg'
    else if Ext = '.ogg'  then Result := 'audio/ogg'
    else if Ext = '.wav'  then Result := 'audio/wav'
    else if Ext = '.m4a'  then Result := 'audio/mp4'
    else if Ext = '.doc'  then Result := 'application/msword'
    else if Ext = '.docx' then Result := 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    else if Ext = '.xls'  then Result := 'application/vnd.ms-excel'
    else if Ext = '.xlsx' then Result := 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    else Result := 'application/octet-stream';
  end;

begin
  Result := False;
  MessageID := '';
  Msg := '';

  NumeroLimpo := ApenasNumeros(Numero);
  if Length(NumeroLimpo) < 10 then
  begin
    Msg := 'Número do WhatsApp inválido.';
    Exit;
  end;

  ArquivoEnvio := Trim(CaminhoArquivo);
  if (ArquivoEnvio = '') or not FileExists(ArquivoEnvio) then
  begin
    Msg := 'Arquivo não encontrado: ' + ArquivoEnvio;
    Exit;
  end;

  TipoMidia := LowerCase(Trim(MediaType));
  if (TipoMidia <> 'image') and
     (TipoMidia <> 'video') and
     (TipoMidia <> 'audio') and
     (TipoMidia <> 'document') then
  begin
    Msg := 'Tipo de mídia inválido: ' + TipoMidia;
    Exit;
  end;

  NomeArquivoEnvio := ExtractFileName(Trim(NomeArquivo));
  if NomeArquivoEnvio = '' then
    NomeArquivoEnvio := ExtractFileName(ArquivoEnvio);

  Extensao := ExtractFileExt(NomeArquivoEnvio);
  if Extensao = '' then
  begin
    Msg := 'O arquivo precisa possuir extensão.';
    Exit;
  end;

  MimeType := ObterMimeType(NomeArquivoEnvio);

  try
    Requisicao := TRequest.New
      .BaseURL(FBaseURL)
      .Resource(RecursoInstancia('message/sendMedia/', NomeInstancia))
      .Accept('application/json')
      .AddHeader('apikey', FAPIKey)
      .AddParam('number', NumeroLimpo, pkREQUESTBODY)
      .AddParam('mediatype', TipoMidia, pkREQUESTBODY)
      .AddParam('mimetype', MimeType, pkREQUESTBODY)
      .AddParam('fileName', NomeArquivoEnvio, pkREQUESTBODY);
      //.AddParam('delay', '1200', pkREQUESTBODY);

    if Trim(Legenda) <> '' then
      Requisicao.AddParam('caption', Legenda, pkREQUESTBODY);

    { Na Evolution o nome correto do campo é "file" }
    Requisicao.AddFile('file', ArquivoEnvio);

    Resposta := Requisicao.Post;
    Result := RespostaSucesso(Resposta);

    if Result then
    begin
      MessageID := JSONTexto(Resposta.Content, 'key.id');
      Msg := 'Mídia enviada com sucesso.';
    end
    else
      Msg := Format(
        'HTTP %d - %s',
        [Resposta.StatusCode, MensagemResposta(Resposta)]
      );

  except
    on E: Exception do
    begin
      Result := False;
      MessageID := '';
      Msg := E.Message;
    end;
  end;
end;



end.
