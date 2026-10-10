unit Service.UsuarioSistema;

interface

uses
  Uni,
  uEleicaoSenha,
  UConeSul;

type
  TUsuarioSistemaService = class
  private
    class function CriarJSON(const ADTO: TObject): string; static;
    class function CriarJSONAPTOS(const ADTO: TObject): string; static;
    class function CriarJSONComissao(const ADTO: TObject): string; static;
  public
    class function Sincronizar(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
    class function SincronizarAptos(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
    class function SincronizarComissao(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  System.JSON,
  Model.UsuarioSistema,
  Dao.UsuarioSistema,
  Dao.Config,
  uEleicaoAPIConfig,
  uEleicaoAPIClient,
  Service.Associado;

class function TUsuarioSistemaService.CriarJSON(const ADTO: TObject): string;
var
  D: TUsuarioSistemaEnvioDTO;
  J: TJSONObject;
  ASenha, ASenhaNova:String;
begin
  D := TUsuarioSistemaEnvioDTO(ADTO);
  J := TJSONObject.Create;
  try

    ASenha    := TConeSul.Crypt('D',D.Senha);
    ASenhaNova:= GerarSenhaAPI(ASenha);

    J.AddPair('id_usuario',     TJSONNumber.Create(D.IdUsuario));
    J.AddPair('nome',               D.Nome);
    J.AddPair('login',              D.Login);
    J.AddPair('senha_hash',         ASenhaNova);
    J.AddPair('ativo',              D.Ativo);
    J.AddPair('email',              D.Email);
    //J.AddPair('sistema',            D.Sistema);
    //J.AddPair('excluido',TJSONNumber.Create(D.Excluido));
    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

class function TUsuarioSistemaService.CriarJSONAPTOS(const ADTO: TObject): string;
var
  D: TUsuarioAPTOSEnvioDTO;
  J: TJSONObject;
  ASenha, ASenhaNova:String;
begin
  D := TUsuarioAPTOSEnvioDTO(ADTO);
  J := TJSONObject.Create;

  try
    ASenha    := D.Senha;//TConeSul.Crypt('D',D.Senha);
    ASenhaNova:= GerarSenhaAPI(ASenha);

    J.AddPair('id_eleitor',         TJSONNumber.Create(D.ideleitor));
    J.AddPair('id_socio',           TJSONNumber.Create(D.idassociado));
    J.AddPair('nome',               D.Nome);
    J.AddPair('login',              D.Login);
    J.AddPair('senha_hash',         ASenhaNova);
    J.AddPair('ativo',              D.Ativo);
    J.AddPair('email',              D.Email);
    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;


class function TUsuarioSistemaService.CriarJSONComissao(const ADTO: TObject): string;
var
  D: TComissaoEleitoralEnvioDTO;
  J: TJSONObject;
  ASenha, ASenhaNova: string;
begin
  D := TComissaoEleitoralEnvioDTO(ADTO);
  J := TJSONObject.Create;
  try
    ASenha := TConeSul.Crypt('D',D.Senha);
    ASenhaNova := GerarSenhaAPI(ASenha);

    J.AddPair('id_comissao_int', TJSONNumber.Create(D.IdComissao));
    J.AddPair('id_eleicao_int', TJSONNumber.Create(D.IdEleicao));
    J.AddPair('nome', D.Nome);
    J.AddPair('cpf', D.CPF);
    J.AddPair('telefone', D.Telefone);
    J.AddPair('email', D.Email);
    J.AddPair('cargo', D.Cargo);
    J.AddPair('ativo', D.Ativo);
    J.AddPair('senha_hash', ASenhaNova);

    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

class function TUsuarioSistemaService.Sincronizar(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean;
var
  DTO: TUsuarioSistemaEnvioDTO;
  URL, UsuarioAPI, SenhaAPI, JSON, Resposta: string;
  Config: TEleicaoAPIConfig;
begin
  Result := False;
  AErro := '';

  try
    DTO := TDaoUsuarioSistema.BuscarParaSincronizacao(AConn,AIDRegistro);
    if not Assigned(DTO) then Exit(True);

    try
      if Trim(DTO.Nome).IsEmpty then begin AErro := 'Nome do usuário não informado.'; Exit; end;
      if Trim(DTO.Login).IsEmpty then begin AErro := 'Login do usuário não informado.'; Exit; end;
      if Trim(DTO.Senha).IsEmpty then begin AErro := 'Senha do usuário não informada.'; Exit; end;

      //if DTO.Excluido <> 0 then DTO.Ativo := 'N';

      if not TDaoConfig.BuscarURLAppEleicao(AConn,URL,UsuarioAPI,SenhaAPI) then
      begin
        AErro := 'Configuração da API de eleição não encontrada.';
        Exit;
      end;

      Config := TEleicaoAPIConfig.Criar(URL,UsuarioAPI,SenhaAPI);

      if Trim(DTO.GuidEmpresa).IsEmpty then begin AErro := 'UUID da empresa não informado.'; Exit; end;
      if Trim(DTO.APIKey).IsEmpty then begin AErro := 'API Key da empresa não informada.'; Exit; end;

      JSON := CriarJSON(DTO);

      if not TEleicaoAPIClient.PostEmpresa(
        Config,
        DTO.GuidEmpresa,
        DTO.APIKey,
        '/v1/integracao/usuario/sistema',
        JSON,
        Resposta,
        AErro
      ) then Exit;

      TDaoUsuarioSistema.AtualizarSincronizacao(AConn,AIDRegistro);
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

class function TUsuarioSistemaService.SincronizarAptos(AConn: TUniConnection; const AIDRegistro: Integer;
  out AErro: string): Boolean;
var
  DTO: TUsuarioAPTOSEnvioDTO;
  URL, UsuarioAPI, SenhaAPI, JSON, Resposta: string;
  ErroAssociado: string;
  Config: TEleicaoAPIConfig;
  JSONResp, Dados:TJSONObject;
  JSONValue:TJSONValue;
  IDUsuarioAPI:Integer;
begin
  Result  := False;
  AErro   := '';

  try
    DTO   := TDaoUsuarioSistema.BuscarParaSincronizacaoAPTOS(AConn,AIDRegistro);
    if not Assigned(DTO) then
    Exit(True);

    try
      if Trim(DTO.Nome).IsEmpty then
      begin
        AErro := 'Nome do associado não informado.';
        Exit;
      end;

      if Trim(DTO.Login).IsEmpty then
      begin
        AErro := 'CPF do associado não informado.';
        Exit;
      end;

      if Trim(DTO.Senha).IsEmpty then
      begin
        AErro := 'Matricula do associado não informada.';
        Exit;
      end;

      if DTO.idassociado <= 0 then
      begin
        AErro := 'ID do associado não informado.';
        Exit;
      end;

      if not TDaoConfig.BuscarURLAppEleicao(AConn,URL,UsuarioAPI,SenhaAPI) then
      begin
        AErro := 'Configuração da API de eleição não encontrada.';
        Exit;
      end;

      Config    := TEleicaoAPIConfig.Criar(URL,UsuarioAPI,SenhaAPI);

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

      // Garante que a pessoa/associado exista na API antes de criar o usuário APTO.
      // O envio é forçado e não depende do flag socio.sinc_app.
      if not TAssociadoService.SincronizarAssociadoForcado(AConn,DTO.idassociado,ErroAssociado) then
      begin
        AErro := 'Falha ao sincronizar associado antes do usuário APTO: ' + ErroAssociado;
        Exit;
      end;

      JSON  := CriarJSONAPTOS(DTO);

      if not TEleicaoAPIClient.PostEmpresa(Config, DTO.GuidEmpresa, DTO.APIKey,
        '/v1/integracao/usuario/associado', JSON, Resposta, AErro) then
        Exit;

      //capturar resposta da API
      JSONValue:=TJSONObject.ParseJSONValue(Resposta);
      try
        if not Assigned(JSONValue) then
          raise Exception.Create('Resposta inválida da API.');
        JSONResp:=JSONValue as TJSONObject;
        Dados:=JSONResp.GetValue<TJSONObject>('dados');
        if not Assigned(Dados) then
          raise Exception.Create('Objeto dados não retornado pela API.');
        IDUsuarioAPI    :=Dados.GetValue<Integer>('id');
        // aqui você grava o retorno
        TDaoUsuarioSistema.AtualizarSincronizacaoAPTOS(AConn, AIDRegistro, IDUsuarioAPI);
        //TDaoEleicaoEleitor.AtualizarIDUsuarioAPI(AConn,DTO.IdEleitor,IDUsuarioAPI);
        Result:=True;
      finally
        JSONValue.Free;
      end;

      //TDaoUsuarioSistema.AtualizarSincronizacaoAPTOS(AConn, AIDRegistro);
      //Result := True;
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





class function TUsuarioSistemaService.SincronizarComissao(AConn: TUniConnection;
                          const AIDRegistro: Integer; out AErro: string): Boolean;
var
  DTO: TComissaoEleitoralEnvioDTO;
  URL, UsuarioAPI, SenhaAPI, JSON, Resposta: string;
  Config: TEleicaoAPIConfig;
begin
  //Funcao para criar os usuarios das comissao eleitorais
  Result := False;
  AErro := '';

  try
    DTO := TDaoUsuarioSistema.BuscarParaSincronizacaoComissao(AConn,AIDRegistro);
    if not Assigned(DTO) then Exit(True);

    try
      if DTO.IdEleicao <= 0 then
      begin
        AErro := 'Eleição da comissão não informada.';
        Exit;
      end;

      if Trim(DTO.Nome).IsEmpty then
      begin
        AErro := 'Nome do usuário/comissão não informado.';
        Exit;
      end;

      if Trim(DTO.CPF).IsEmpty then
      begin
        AErro := 'CPF do usuário/comissão não informado.';
        Exit;
      end;

      if Trim(DTO.Email).IsEmpty then
      begin
        AErro := 'E-mail do usuário/comissão não informado.';
        Exit;
      end;

      if Trim(DTO.Senha).IsEmpty then
      begin
        AErro := 'Senha do usuário/comissão não informada.';
        Exit;
      end;

      if not TDaoConfig.BuscarURLAppEleicao(AConn,URL,UsuarioAPI,SenhaAPI) then
      begin
        AErro := 'Configuração da API de eleição não encontrada.';
        Exit;
      end;

      Config := TEleicaoAPIConfig.Criar(URL,UsuarioAPI,SenhaAPI);

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

      JSON  := CriarJSONComissao(DTO);

      if not TEleicaoAPIClient.PostEmpresa(
        Config,
        DTO.GuidEmpresa,
        DTO.APIKey,
        '/v1/integracao/eleicao/comissao',
        JSON,
        Resposta,
        AErro
      ) then Exit;

      TDaoUsuarioSistema.AtualizarSincronizacaoComissao(AConn,AIDRegistro);
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
