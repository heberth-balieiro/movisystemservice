unit uEleicaoAPIClient;

interface

uses
  uEleicaoAPIConfig;

type
  TEleicaoAPIClient = class
  private
    class function NormalizarRecurso(const ARecurso: string): string; static;
    class function ExtrairMensagem(const AConteudo: string): string; static;

    class function ExecutarPost(
      const AConfig: TEleicaoAPIConfig;
      const ARecurso, AJson: string;
      const AHeader1, AValor1, AHeader2, AValor2: string;
      out AResposta, AErro: string
    ): Boolean; static;
    class function ExecutarGet(const AConfig: TEleicaoAPIConfig; const ARecurso,
      AJson, AHeader1, AValor1, AHeader2, AValor2: string; out AResposta,
      AErro: string): Boolean; static;

  public
    class function PostBootstrap(
      const AConfig: TEleicaoAPIConfig;
      const ARecurso, AJson: string;
      out AResposta, AErro: string
    ): Boolean; static;

    class function PostEmpresa(
      const AConfig: TEleicaoAPIConfig;
      const AUUID, AAPIKey: string;
      const ARecurso, AJson: string;
      out AResposta, AErro: string
    ): Boolean; static;


    //Get
    class function GetEmpresa(
      const AConfig: TEleicaoAPIConfig;
      const AUUID, AAPIKey: string;
      const ARecurso, AJson: string;
      out AResposta, AErro: string
    ): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  RESTRequest4D,
  REST.Types;

{ TEleicaoAPIClient }

{$REGION 'Method Post'}

class function TEleicaoAPIClient.NormalizarRecurso(const ARecurso: string): string;
begin
  Result := Trim(ARecurso);

  while Result.StartsWith('/') do
    Delete(Result,1,1);
end;

class function TEleicaoAPIClient.ExtrairMensagem(const AConteudo: string): string;
var
  JSON : TJSONValue;
  Valor: TJSONValue;
begin
  Result := '';

  if Trim(AConteudo).IsEmpty then
    Exit;

  JSON := TJSONObject.ParseJSONValue(AConteudo);
  try
    if not Assigned(JSON) then
      Exit(Trim(AConteudo));

    Valor := JSON.FindValue('mensagem');

    if Assigned(Valor) and not (Valor is TJSONNull) then
      Result := Valor.Value;

    if Result.IsEmpty then
    begin
      Valor := JSON.FindValue('message');

      if Assigned(Valor) and not (Valor is TJSONNull) then
        Result := Valor.Value;
    end;

    if Result.IsEmpty then
      Result := Trim(AConteudo);

  finally
    JSON.Free;
  end;
end;

class function TEleicaoAPIClient.ExecutarPost(
  const AConfig: TEleicaoAPIConfig;
  const ARecurso, AJson: string;
  const AHeader1, AValor1, AHeader2, AValor2: string;
  out AResposta, AErro: string): Boolean;
var
  Resposta: IResponse;
begin
  Result := False;
  AResposta := '';
  AErro := '';

  try
    Resposta := TRequest.New
      .BaseURL(AConfig.URL)
      .Resource(NormalizarRecurso(ARecurso))
      .Accept('application/json')
      .ContentType('application/json')
      .AddHeader(AHeader1,AValor1)
      .AddHeader(AHeader2,AValor2)
      .AddBody(AJson,TRESTContentType.ctAPPLICATION_JSON)
      .Timeout(AConfig.Timeout)
      .POST;

    if not Assigned(Resposta) then
    begin
      AErro := 'A API de eleição não retornou uma resposta.';
      Exit;
    end;

    AResposta := Resposta.Content;

    Result := (Resposta.StatusCode >= 200) and
              (Resposta.StatusCode <= 299);

    if not Result then
    begin
      AErro := ExtrairMensagem(Resposta.Content);

      if AErro.IsEmpty then
        AErro := Format('Erro HTTP %d ao acessar a API de eleição.',[Resposta.StatusCode]);

      Exit;
    end;

  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

class function TEleicaoAPIClient.PostBootstrap(
  const AConfig: TEleicaoAPIConfig;
  const ARecurso, AJson: string;
  out AResposta, AErro: string): Boolean;
begin
  Result := ExecutarPost(
    AConfig,
    ARecurso,
    AJson,
    'X-EasyOne-Usuario',
    AConfig.Usuario,
    'X-EasyOne-Senha',
    AConfig.Senha,
    AResposta,
    AErro
  );
end;

class function TEleicaoAPIClient.PostEmpresa(const AConfig: TEleicaoAPIConfig;
  const AUUID, AAPIKey: string;
  const ARecurso, AJson: string;
  out AResposta, AErro: string): Boolean;
begin
  if Trim(AUUID).IsEmpty then
  begin
    AResposta := '';
    AErro := 'UUID da empresa não informado.';
    Exit(False);
  end;

  if Trim(AAPIKey).IsEmpty then
  begin
    AResposta := '';
    AErro := 'Chave de integração da empresa não informada.';
    Exit(False);
  end;

  Result := ExecutarPost(AConfig,ARecurso, AJson, 'X-EasyOne-Empresa', AUUID, 'X-EasyOne-Key', AAPIKey, AResposta, AErro);
end;


class function TEleicaoAPIClient.GetEmpresa(const AConfig: TEleicaoAPIConfig;
  const AUUID, AAPIKey, ARecurso, AJson: string; out AResposta,
  AErro: string): Boolean;
begin
  if Trim(AUUID).IsEmpty then
  begin
    AResposta := '';
    AErro := 'UUID da empresa não informado.';
    Exit(False);
  end;

  if Trim(AAPIKey).IsEmpty then
  begin
    AResposta := '';
    AErro := 'Chave de integração da empresa não informada.';
    Exit(False);
  end;

  Result := ExecutarGet(AConfig,ARecurso, AJson, 'X-EasyOne-Empresa', AUUID, 'X-EasyOne-Key', AAPIKey, AResposta, AErro);
end;

{$ENDREGION}

{$REGION 'Method Get'}

class function TEleicaoAPIClient.ExecutarGet(
  const AConfig: TEleicaoAPIConfig;
  const ARecurso, AJson: string;
  const AHeader1, AValor1, AHeader2, AValor2: string;
  out AResposta, AErro: string): Boolean;
var
  Resposta: IResponse;
begin
  Result := False;
  AResposta := '';
  AErro := '';

  try
    Resposta := TRequest.New
      .BaseURL(AConfig.URL)
      .Resource(NormalizarRecurso(ARecurso))
      .Accept('application/json')
      .ContentType('application/json')
      .AddHeader(AHeader1,AValor1)
      .AddHeader(AHeader2,AValor2)
      .AddBody(AJson,TRESTContentType.ctAPPLICATION_JSON)
      .Timeout(AConfig.Timeout)
      .GET;

    if not Assigned(Resposta) then
    begin
      AErro := 'A API de eleição não retornou uma resposta.';
      Exit;
    end;

    AResposta := Resposta.Content;

    Result := (Resposta.StatusCode >= 200) and
              (Resposta.StatusCode <= 299);

    if not Result then
    begin
      AErro := ExtrairMensagem(Resposta.Content);

      if AErro.IsEmpty then
        AErro := Format('Erro HTTP %d ao acessar a API de eleição.',[Resposta.StatusCode]);

      Exit;
    end;

  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;


{$ENDREGION}




end.
