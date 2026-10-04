unit Service.EleicaoQuestao;

interface

uses
  Uni;

type
  TEleicaoQuestaoService = class
  private
    class function CriarJSONQuestao(const ADTO: TObject): string; static;
    class function CriarJSONQuestaoOpcao(const ADTO: TObject): string; static;
  public
    class function SincronizarEleicaoQuestao(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
    class function SincronizarEleicaoQuestaoOpcao(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Model.EleicaoQuestao,
  Dao.EleicaoQuestao,
  Dao.Config,
  uEleicaoAPIConfig,
  uEleicaoAPIClient;

{ TEleicaoQuestaoService }

{$REGION 'Questao'}

class function TEleicaoQuestaoService.CriarJSONQuestao(const ADTO: TObject): string;
var
  D: TEleicaoQuestaoEnvioDTO;
  J: TJSONObject;
begin
  D := TEleicaoQuestaoEnvioDTO(ADTO);

  J := TJSONObject.Create;
  try
    J.AddPair('id_questao_int',   TJSONNumber.Create(D.id_questao));
    J.AddPair('id_eleicao_int',   TJSONNumber.Create(D.id_eleicao));
    J.AddPair('titulo',           D.titulo);
    J.AddPair('descricao',        D.descricao);
    J.AddPair('ordem',            TJSONNumber.Create(D.ordem));
    J.AddPair('tipo_resposta',    D.tipo_resposta);
    J.AddPair('obrigatoria',      D.obrigatoria);
    J.AddPair('ativo',            D.Ativo);

    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

class function TEleicaoQuestaoService.SincronizarEleicaoQuestao(
  AConn: TUniConnection; const AIDRegistro: Integer;out AErro: string): Boolean;
var
  DTO: TEleicaoQuestaoEnvioDTO;
  URL, Usuario, Senha, JSON, Resposta: string;
  Config: TEleicaoAPIConfig;
begin
  Result := False;
  AErro := '';

  try
    DTO := TDaoEleicaoQuestao.BuscarParaSincronizacaoQuestao(AConn,AIDRegistro);
    if not Assigned(DTO) then Exit(True);

    try
      if DTO.id_eleicao <= 0 then
      begin
        AErro := 'Eleição não informada.';
        Exit;
      end;

      if Trim(DTO.titulo).IsEmpty then
      begin
        AErro := 'Título da questão não informado.';
        Exit;
      end;

      if Trim(DTO.Ativo).IsEmpty then
      DTO.Ativo := 'S';

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

      JSON := CriarJSONQuestao(DTO);

      if not TEleicaoAPIClient.PostEmpresa(
        Config,
        DTO.GuidEmpresa,
        DTO.APIKey,
        '/v1/integracao/eleicao/questao',
        JSON,
        Resposta,
        AErro
      ) then Exit;

      TDaoEleicaoQuestao.AtualizarSincronizacaoQuestao(AConn,AIDRegistro);
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

{$ENDREGION}

{$REGION 'Opcao'}

 class function TEleicaoQuestaoService.CriarJSONQuestaoOpcao(
  const ADTO: TObject): string;
var
  D: TEleicaoQuestaoOpcaoEnvioDTO;
  J: TJSONObject;
begin
  D := TEleicaoQuestaoOpcaoEnvioDTO(ADTO);

  J := TJSONObject.Create;
  try
    J.AddPair('id_opcao_int',     TJSONNumber.Create(D.id_opcao));
    J.AddPair('id_questao_int',   TJSONNumber.Create(D.id_questao));
    J.AddPair('id_eleicao_int',   TJSONNumber.Create(D.id_eleicao));
    J.AddPair('ordem',            TJSONNumber.Create(D.ordem));
    J.AddPair('descricao',        D.descricao);
    J.AddPair('ativo',            D.Ativo);
    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

class function TEleicaoQuestaoService.SincronizarEleicaoQuestaoOpcao(
  AConn: TUniConnection; const AIDRegistro: Integer;
  out AErro: string): Boolean;
var
  DTO: TEleicaoQuestaoOpcaoEnvioDTO;
  URL, Usuario, Senha, JSON, Resposta: string;
  Config: TEleicaoAPIConfig;
begin
  Result := False;
  AErro := '';

  try
    DTO := TDaoEleicaoQuestao.BuscarParaSincronizacaoQuestaoOpcao(AConn,AIDRegistro);
    if not Assigned(DTO) then Exit(True);

    try
      if DTO.id_eleicao <= 0 then
      begin
        AErro := 'Eleição não informada.';
        Exit;
      end;

      if Trim(DTO.descricao).IsEmpty then
      begin
        AErro := 'Descrição da questão não informado.';
        Exit;
      end;

      if Trim(DTO.Ativo).IsEmpty then
      DTO.Ativo := 'S';

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

      JSON := CriarJSONQuestaoOpcao(DTO);

      if not TEleicaoAPIClient.PostEmpresa(
        Config,
        DTO.GuidEmpresa,
        DTO.APIKey,
        '/v1/integracao/eleicao/questao/opcao',
        JSON,
        Resposta,
        AErro
      ) then Exit;

      TDaoEleicaoQuestao.AtualizarSincronizacaoQuestaoOpcao(AConn,AIDRegistro);
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


{$ENDREGION}


end.
