unit Service.Empresa;

interface

uses
  Uni;

type
  TEmpresaService = class
  private
    class function GerarAPIKey: string; static;
    class function GerarHashSHA256(const AValor: string): string; static;
  public
    class function SincronizarEmpresa(AConn: TUniConnection; const AIDEmpresa: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  System.Hash,
  Dao.Config,
  Dao.Empresa,
  Model.Empresa,
  uEleicaoAPIConfig,
  uEleicaoAPIClient;

{ TEmpresaService }

class function TEmpresaService.GerarAPIKey: string;
var
  G1, G2: TGUID;
begin
  CreateGUID(G1);
  CreateGUID(G2);

  Result :=
    StringReplace(
      StringReplace(
        StringReplace(
          StringReplace(GUIDToString(G1) + GUIDToString(G2),'{','',[rfReplaceAll]),
          '}','',[rfReplaceAll]
        ),
        '-','',[rfReplaceAll]
      ),
      ' ','',[rfReplaceAll]
    );

  Result := UpperCase(Result);
end;

class function TEmpresaService.GerarHashSHA256(const AValor: string): string;
begin
  Result := UpperCase(THashSHA2.GetHashString(Trim(AValor)));
end;

class function TEmpresaService.SincronizarEmpresa(
  AConn: TUniConnection;
  const AIDEmpresa: Integer;
  out AErro: string): Boolean;
var
  URL, UsuarioAPI, SenhaAPI: string;
  Config                    : TEleicaoAPIConfig;
  Empresa                   : TEmpresaModel;
  JSON                      : TJSONObject;
  Resposta                  : string;
  APIKeyHash                : string;
begin
  Result := False;
  AErro := '';

  if not Assigned(AConn) then
  begin
    AErro := 'Conexão com banco de dados não informada.';
    Exit;
  end;

  if AIDEmpresa <= 0 then
  begin
    AErro := 'Empresa não informada.';
    Exit;
  end;

  try
    { Configuração da API }
    if not TDaoConfig.BuscarURLAppEleicao(AConn,URL,UsuarioAPI,SenhaAPI) then
    begin
      AErro := 'Configuração da API de eleição não encontrada.';
      Exit;
    end;

    Config := TEleicaoAPIConfig.Criar(URL,UsuarioAPI,SenhaAPI);

    { Empresa }
    Empresa := TDaoEmpresa.BuscarParaSincronizacao(AConn,AIDEmpresa);

    if not Assigned(Empresa) then
    begin
      AErro := 'Empresa não encontrada ou não está pendente de sincronização.';
      Exit;
    end;

    try
      if Trim(Empresa.UUID).IsEmpty then
      begin
        AErro := 'UUID da empresa não informado.';
        Exit;
      end;

      if Empresa.IdEmpresa <= 0 then
      begin
        AErro := 'Código da empresa inválido.';
        Exit;
      end;

      if Trim(Empresa.Razao).IsEmpty then
      begin
        AErro := 'Razão Social da empresa não informada.';
        Exit;
      end;

      if Trim(Empresa.CPFCNPJ).IsEmpty then
      begin
        AErro := 'CPF/CNPJ da empresa não informado.';
        Exit;
      end;

      { Gera uma única vez e mantém a chave original no EasyOne }
      if Trim(Empresa.EasyOneAPIKey).IsEmpty then
      begin
        Empresa.EasyOneAPIKey   := GerarAPIKey;
        TDaoEmpresa.AtualizarAPIKey(AConn, Empresa.IdEmpresa, Empresa.EasyOneAPIKey);
      end;

      APIKeyHash  := GerarHashSHA256(Empresa.EasyOneAPIKey);

      JSON        := TJSONObject.Create;
      try
        JSON.AddPair('id_empresa',      TJSONNumber.Create(Empresa.IdEmpresa));
        JSON.AddPair('uuid',            Empresa.UUID);
        JSON.AddPair('razao',           Empresa.Razao);
        JSON.AddPair('fantasia',        Empresa.Fantasia);
        JSON.AddPair('telefone',        Empresa.Telefone);
        JSON.AddPair('ativo',           Empresa.Ativo);
        JSON.AddPair('cpfcnpj',         Empresa.CPFCNPJ);
        JSON.AddPair('whatsapp_url',    Empresa.WhatsAppURL);
        JSON.AddPair('whatsapp_token',  Empresa.WhatsAppToken);

        JSON.AddPair('easyone_api_key_hash',    APIKeyHash);
        JSON.AddPair('easyone_integracao_ativo',Empresa.EasyOneIntegracaoAtivo);

        if not TEleicaoAPIClient.PostBootstrap(
          Config,
          '/v1/integracao/empresa', JSON.ToJSON, Resposta, AErro) then
          Exit;

        TDaoEmpresa.AtualizarSincronizacao(AConn,Empresa.IdEmpresa);

        Result := True;
      finally
        JSON.Free;
      end;

    finally
      Empresa.Free;
    end;

  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
