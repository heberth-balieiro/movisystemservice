unit Service.Associado;

interface

uses
  Uni;

type
  TAssociadoService = class
  private
    class function CriarJSON(const ADTO: TObject): string; static;
    class function SincronizarAssociadoInterno(AConn: TUniConnection; const AIDRegistro: Integer; const AForcar: Boolean; out AErro: string): Boolean; static;
  public
    class function SincronizarAssociado(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
    class function SincronizarAssociadoForcado(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  System.DateUtils,
  Model.Associado,
  Dao.Associado,
  Dao.Config,
  uEleicaoAPIConfig,
  uEleicaoAPIClient;

class function TAssociadoService.CriarJSON(const ADTO: TObject): string;
var
  D: TAssociadoEnvioDTO;
  J: TJSONObject;
begin
  D := TAssociadoEnvioDTO(ADTO);
  J := TJSONObject.Create;
  try
    J.AddPair('id_socio',TJSONNumber.Create(D.IdSocio));
    J.AddPair('codigo',TJSONNumber.Create(D.Codigo));
    J.AddPair('matricula',TJSONNumber.Create(D.Matricula));
    J.AddPair('ativo',D.Ativo);
    J.AddPair('nome',D.Nome);
    J.AddPair('apelido',D.Apelido);
    J.AddPair('telefone',D.Telefone);
    J.AddPair('celular',D.Celular);
    J.AddPair('whatsapp',D.WhatsApp);
    J.AddPair('cpf',D.CPF);

    if D.Nascimento > 0 then J.AddPair('nascimento',FormatDateTime('yyyy-mm-dd',D.Nascimento)) else J.AddPair('nascimento',TJSONNull.Create);

    J.AddPair('email',D.Email);
    J.AddPair('cidade',D.Cidade);
    J.AddPair('secretaria',D.Secretaria);
    J.AddPair('profissao',D.Profissao);
    J.AddPair('lotacao',D.Lotacao);
    J.AddPair('localtrabalho',D.LocalTrabalho);
    J.AddPair('funcao',D.Funcao);
    J.AddPair('naturalde',D.NaturalDe);
    J.AddPair('rg',D.RG);

    if D.DataFiliacao > 0 then J.AddPair('data_filiacao',FormatDateTime('yyyy-mm-dd',D.DataFiliacao)) else J.AddPair('data_filiacao',TJSONNull.Create);

    J.AddPair('pai',D.Pai);
    J.AddPair('mae',D.Mae);
    J.AddPair('foto',D.Foto);
    J.AddPair('bloqueado',D.Bloqueado);
    J.AddPair('excluido',TJSONNumber.Create(D.Excluido));

    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

class function TAssociadoService.SincronizarAssociadoInterno(AConn: TUniConnection;
  const AIDRegistro: Integer; const AForcar: Boolean; out AErro: string): Boolean;
var
  DTO: TAssociadoEnvioDTO;
  URL, Usuario, Senha, JSON, Resposta: string;
  Config: TEleicaoAPIConfig;
begin
  Result := False;
  AErro := '';

  try
    DTO := TDaoAssociado.BuscarParaSincronizacao(AConn,AIDRegistro,AForcar);
    if not Assigned(DTO) then
    begin
      if AForcar then
      begin
        AErro := 'Associado não encontrado para sincronização. ID: ' + AIDRegistro.ToString;
        Exit;
      end;

      Exit(True);
    end;

    try
      if not TDaoConfig.BuscarURLAppEleicao(AConn,URL,Usuario,Senha) then
      begin
        AErro := 'Configuração da API de eleição não encontrada.';
        Exit;
      end;

      Config := TEleicaoAPIConfig.Criar(URL,Usuario,Senha);

      if Trim(DTO.GuidEmpresa).IsEmpty then
      begin
        AErro := 'UUID da empresa não informado.';
        Exit;
      end;

      if Trim(DTO.APIKey).IsEmpty then
      begin
        AErro := 'API Key da empresa não informada.';
        Exit;
      end;

      JSON := CriarJSON(DTO);

      if not TEleicaoAPIClient.PostEmpresa(Config,DTO.GuidEmpresa,DTO.APIKey,'/v1/integracao/associado',JSON,Resposta,AErro) then Exit;

      TDaoAssociado.AtualizarSincronizacao(AConn,AIDRegistro);
      Result := True;
    finally
      DTO.Free;
    end;
  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

class function TAssociadoService.SincronizarAssociado(AConn: TUniConnection;
  const AIDRegistro: Integer; out AErro: string): Boolean;
begin
  Result := SincronizarAssociadoInterno(AConn,AIDRegistro,False,AErro);
end;

class function TAssociadoService.SincronizarAssociadoForcado(AConn: TUniConnection;
  const AIDRegistro: Integer; out AErro: string): Boolean;
begin
  Result := SincronizarAssociadoInterno(AConn,AIDRegistro,True,AErro);
end;

end.
