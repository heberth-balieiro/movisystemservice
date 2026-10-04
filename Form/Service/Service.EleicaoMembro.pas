unit Service.EleicaoMembro;

interface

uses
  Uni, Service.Util;

type
  TEleicaoMembroService = class
  private
    class function CriarJSON(const ADTO: TObject): string; static;
  public
    class function Sincronizar(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Model.EleicaoMembro,
  Dao.EleicaoMembro,
  Dao.Config,
  uEleicaoAPIConfig,
  uEleicaoAPIClient;

class function TEleicaoMembroService.CriarJSON(const ADTO: TObject): string;
var
  D: TEleicaoMembroEnvioDTO;
  J: TJSONObject;
begin
  D := TEleicaoMembroEnvioDTO(ADTO);

  J := TJSONObject.Create;
  try
    J.AddPair('eleicao_id',       TJSONNumber.Create(D.IdEleicao));
    J.AddPair('eleicao_chapa_id', TJSONNumber.Create(D.IdChapa));
    J.AddPair('id_membro_int',    TJSONNumber.Create(D.IdMembro));
    J.AddPair('codigo',           TJSONNumber.Create(D.Codigo));
    J.AddPair('nome',             D.Nome);
    J.AddPair('cpf',              D.CPF);
    J.AddPair('telefone',         D.Telefone);
    J.AddPair('email',            D.Email);
    J.AddPair('ativo',            D.Ativo);
    J.AddPair('cargo',            D.Cargo);
    J.AddPair('tipo',             D.Tipo);
    J.AddPair('observacao',       D.Observacao);
    J.AddPair('arquivo_foto',     D.ArquivoFoto);
    J.AddPair('extensao_foto',    D.ExtensaoFoto);

    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

class function TEleicaoMembroService.Sincronizar(AConn: TUniConnection;
  const AIDRegistro: Integer; out AErro: string): Boolean;
var
  DTO: TEleicaoMembroEnvioDTO;
  URL, Usuario, Senha, JSON, Resposta: string;
  Config: TEleicaoAPIConfig;
begin
  Result := False;
  AErro := '';

  try
    DTO := TDaoEleicaoMembro.BuscarParaSincronizacao(AConn,AIDRegistro);
    if not Assigned(DTO) then Exit(True);

    try
      if DTO.IdEleicao <= 0 then
      begin
        AErro := 'Eleição não informada.';
        Exit;
      end;

      if DTO.IdChapa <= 0 then
      begin
        AErro := 'Chapa não informada.';
        Exit;
      end;

      if DTO.IdMembro <= 0 then
      begin
        AErro := 'Membro não informado.';
        Exit;
      end;

      if Trim(DTO.Nome).IsEmpty then begin AErro := 'Nome do membro não informado.'; Exit; end;
      if Trim(DTO.CPF).IsEmpty then begin AErro := 'CPF do membro não informado.'; Exit; end;

      if Trim(DTO.Ativo).IsEmpty then DTO.Ativo := 'S';
      if Trim(DTO.ExtensaoFoto).IsEmpty then DTO.ExtensaoFoto := 'PNG';

      if not TDaoConfig.BuscarURLAppEleicao(AConn,URL,Usuario,Senha) then
      begin
        AErro := 'Configuração da API de eleição não encontrada.';
        Exit;
      end;

      Config := TEleicaoAPIConfig.Criar(URL,Usuario,Senha);

      if Trim(DTO.GuidEmpresa).IsEmpty then begin AErro := 'UUID da empresa não informado.'; Exit; end;
      if Trim(DTO.APIKey).IsEmpty then begin AErro := 'API Key da empresa não informada.'; Exit; end;

      JSON := CriarJSON(DTO);

      if not TEleicaoAPIClient.PostEmpresa(
        Config,
        DTO.GuidEmpresa,
        DTO.APIKey,
        '/v1/integracao/eleicao/chapa/membros',
        JSON,
        Resposta,
        AErro
      ) then Exit;

      TDaoEleicaoMembro.AtualizarSincronizacao(AConn,AIDRegistro);

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

end.
