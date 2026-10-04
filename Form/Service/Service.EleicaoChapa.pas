unit Service.EleicaoChapa;

interface

uses
  Uni;

type
  TEleicaoChapaService = class
  private
    class function CriarJSON(const ADTO: TObject): string; static;
  public
    class function Sincronizar(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Model.EleicaoChapa,
  Dao.EleicaoChapa,
  Dao.Config,
  uEleicaoAPIConfig,
  uEleicaoAPIClient;

class function TEleicaoChapaService.CriarJSON(const ADTO: TObject): string;
var
  D: TEleicaoChapaEnvioDTO;
  J: TJSONObject;
begin
  D := TEleicaoChapaEnvioDTO(ADTO);

  J := TJSONObject.Create;
  try
    J.AddPair('eleicao_id',TJSONNumber.Create(D.IdEleicao));
    J.AddPair('id_chapa_int',TJSONNumber.Create(D.IdChapa));
    J.AddPair('codigo',TJSONNumber.Create(D.Codigo));
    J.AddPair('situacao',D.Situacao);
    J.AddPair('num_chapa',TJSONNumber.Create(D.NumChapa));
    J.AddPair('nome_chapa',D.NomeChapa);
    J.AddPair('slogan',D.Slogan);
    J.AddPair('obs',D.Obs);
    J.AddPair('ativo',D.Ativo);

    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

class function TEleicaoChapaService.Sincronizar(AConn: TUniConnection;
  const AIDRegistro: Integer; out AErro: string): Boolean;
var
  DTO: TEleicaoChapaEnvioDTO;
  URL, Usuario, Senha, JSON, Resposta: string;
  Config: TEleicaoAPIConfig;
begin
  Result := False;
  AErro := '';

  try
    DTO := TDaoEleicaoChapa.BuscarParaSincronizacao(AConn,AIDRegistro);
    if not Assigned(DTO) then Exit(True);

    try
      DTO.Situacao := UpperCase(Trim(DTO.Situacao));

      { INSCRITA ainda não participa da eleição }
      if DTO.Situacao = 'INSCRITA' then
      begin
        TDaoEleicaoChapa.AtualizarSincronizacao(AConn,AIDRegistro);
        Exit(True);
      end;

      if (DTO.Situacao <> 'HOMOLOGADA') and (DTO.Situacao <> 'INDEFERIDA') then
      begin
        AErro := 'Situação da chapa inválida: ' + DTO.Situacao;
        Exit;
      end;

      if DTO.IdEleicao <= 0 then begin AErro := 'Eleição não informada.'; Exit; end;
      if Trim(DTO.NomeChapa).IsEmpty then begin AErro := 'Nome da chapa não informado.'; Exit; end;

      { INDEFERIDA deve ficar indisponível para votação }
      if DTO.Situacao = 'INDEFERIDA' then DTO.Ativo := 'N';

      if Trim(DTO.Ativo).IsEmpty then DTO.Ativo := 'S';

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
        '/v1/integracao/eleicao/chapa',
        JSON,
        Resposta,
        AErro
      ) then Exit;

      TDaoEleicaoChapa.AtualizarSincronizacao(AConn,AIDRegistro);
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
