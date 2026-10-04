unit Service.EleicaoConfig;

interface

uses
  Uni;

type
  TEleicaoConfigService = class
  private
    class function CriarJSON(const ADTO: TObject): string; static;
  public
    class function Sincronizar(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Model.EleicaoConfig,
  Dao.EleicaoConfig,
  Dao.Config,
  uEleicaoAPIConfig,
  uEleicaoAPIClient;

class function TEleicaoConfigService.CriarJSON(const ADTO: TObject): string;
var
  D: TEleicaoConfigEnvioDTO;
  J: TJSONObject;
begin
  D := TEleicaoConfigEnvioDTO(ADTO);
  J := TJSONObject.Create;
  try
    J.AddPair('eleicao_id',         TJSONNumber.Create(D.IdEleicao));
    J.AddPair('id_config',          TJSONNumber.Create(D.IdConfig));
    J.AddPair('slug',               D.Slug);
    J.AddPair('nome_exibicao',      D.NomeExibicao);
    J.AddPair('mensagem_boas_vindas',D.MensagemBoasVindas);
    J.AddPair('url_publica',        D.UrlPublica);
    J.AddPair('email',              D.Email);
    J.AddPair('telefone',           D.Telefone);
    J.AddPair('cor_primaria',       D.CorPrimaria);
    J.AddPair('cor_secundaria',     D.CorSecundaria);
    J.AddPair('url_instagram',      D.UrlInstagram);
    J.AddPair('url_facebook',       D.UrlFacebook);
    J.AddPair('url_youtube',        D.UrlYoutube);
    J.AddPair('pagina_publicar',    D.PaginaPublicar);
    J.AddPair('data_hora_inicio',   FormatDateTime('yyyy-mm-dd"T"hh:nn:ss',D.DataHoraInicio));
    J.AddPair('data_hora_fim',      FormatDateTime('yyyy-mm-dd"T"hh:nn:ss',D.DataHoraFim));
    J.AddPair('logo',               d.logo);
    J.AddPair('banner',             d.banner);

    J.AddPair('abertura_automatica',       d.abertura_automatica);
    J.AddPair('encerramento_automatico',   d.encerramento_automatico);
    J.AddPair('votacao_secreta',           d.votacao_secreta);
    J.AddPair('exibir_resultado_parcial',  d.exibir_resultado_parcial);
    J.AddPair('publicacao_resultado',      d.publicacao_resultado);
    J.AddPair('controlar_quorum',          d.controlar_quorum);
    J.AddPair('tipo_quorum',               d.tipo_quorum);
    J.AddPair('quorum_minimo',             TJSONNumber.Create(d.quorum_minimo));
    J.AddPair('quorum_percentual',         d.quorum_percentual);
    J.AddPair('quorum_base',               d.quorum_base);
    J.AddPair('controlar_presenca',        d.controlar_presenca);
    J.AddPair('exigir_presenca_votacao',   d.exigir_presenca_votacao);

    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

class function TEleicaoConfigService.Sincronizar(AConn: TUniConnection;
  const AIDRegistro: Integer; out AErro: string): Boolean;
var
  DTO: TEleicaoConfigEnvioDTO;
  URL, Usuario, Senha, JSON, Resposta: string;
  Config: TEleicaoAPIConfig;
begin
  Result := False;
  AErro := '';

  try
    DTO := TDaoEleicaoConfig.BuscarParaSincronizacao(AConn,AIDRegistro);
    if not Assigned(DTO) then Exit(True);

    try
      if DTO.IdEleicao <= 0 then begin AErro := 'Eleição não informada.'; Exit; end;
      if Trim(DTO.Slug).IsEmpty then begin AErro := 'Slug não informado.'; Exit; end;
      if DTO.DataHoraInicio <= 0 then begin AErro := 'Data/hora inicial não informada.'; Exit; end;
      if DTO.DataHoraFim <= 0 then begin AErro := 'Data/hora final não informada.'; Exit; end;
      if DTO.DataHoraFim <= DTO.DataHoraInicio then begin AErro := 'Data/hora final deve ser maior que a inicial.'; Exit; end;

      if not TDaoConfig.BuscarURLAppEleicao(AConn,URL,Usuario,Senha) then begin AErro := 'Configuração da API de eleição não encontrada.'; Exit; end;

      Config := TEleicaoAPIConfig.Criar(URL,Usuario,Senha);

      if Trim(DTO.GuidEmpresa).IsEmpty then begin AErro := 'UUID da empresa não informado.'; Exit; end;
      if Trim(DTO.APIKey).IsEmpty then begin AErro := 'API Key da empresa não informada.'; Exit; end;

      JSON := CriarJSON(DTO);

      if not TEleicaoAPIClient.PostEmpresa(Config,DTO.GuidEmpresa,DTO.APIKey,'/v1/integracao/eleicaoconfig',JSON,Resposta,AErro) then Exit;

      TDaoEleicaoConfig.AtualizarSincronizacao(AConn,AIDRegistro);
      Result := True;
    finally
      DTO.Free;
    end;
  except
    on E: Exception do begin Result := False; AErro := E.ClassName + ': ' + E.Message; end;
  end;
end;

end.
