unit Service.Eleicao;

interface

uses
  Uni;

type
  TEleicaoService = class
  private
    class function CriarJSON(const ADTO: TObject): string; static;
  public
    class function SincronizarEleicao(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Model.Eleicao,
  Dao.Eleicao,
  Dao.Config,
  uEleicaoAPIConfig,
  uEleicaoAPIClient;

class function TEleicaoService.CriarJSON(const ADTO: TObject): string;
var
  D: TEleicaoEnvioDTO;
  J: TJSONObject;
begin
  D := TEleicaoEnvioDTO(ADTO);
  J := TJSONObject.Create;
  try
    J.AddPair('id_eleicao_int',TJSONNumber.Create(D.IdEleicao));
    J.AddPair('codigo',TJSONNumber.Create(D.Codigo));
    J.AddPair('nome',D.Nome);
    J.AddPair('descricao',D.Descricao);
    J.AddPair('ano',TJSONNumber.Create(D.Ano));
    J.AddPair('ativo',D.Ativo);
    J.AddPair('ano_fim',TJSONNumber.Create(D.AnoFim));
    J.AddPair('tipo',D.Tipo);
    J.AddPair('situacao',D.Situacao);
    J.AddPair('operacao',D.operacao);

    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

class function TEleicaoService.SincronizarEleicao(AConn: TUniConnection;
  const AIDRegistro: Integer; out AErro: string): Boolean;
var
  DTO: TEleicaoEnvioDTO;
  URL, Usuario, Senha, JSON, Resposta: string;
  Config: TEleicaoAPIConfig;
begin
  Result := False;
  AErro := '';

  try
    DTO := TDaoEleicao.BuscarParaSincronizacao(AConn,AIDRegistro);

    if not Assigned(DTO) then Exit(True);

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

      if Trim(DTO.Nome).IsEmpty then
      begin
        AErro := 'Nome da eleição não informado.';
        Exit;
      end;

      JSON := CriarJSON(DTO);

      if not TEleicaoAPIClient.PostEmpresa(
        Config,
        DTO.GuidEmpresa,
        DTO.APIKey,
        '/v1/integracao/eleicao',
        JSON,
        Resposta,
        AErro
      ) then Exit;

      TDaoEleicao.AtualizarSincronizacao(AConn,AIDRegistro);

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
