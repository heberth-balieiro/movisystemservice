unit uEleicaoAPIConfig;

interface

type
  TEleicaoAPIConfig = record
    URL    : string;
    Usuario: string;
    Senha  : string;
    Timeout: Integer;

    class function Criar(const AURL, AUsuario, ASenha: string; const ATimeout: Integer = 60000): TEleicaoAPIConfig; static;
    procedure Validar;
  end;

implementation

uses
  System.SysUtils;

{ TEleicaoAPIConfig }

class function TEleicaoAPIConfig.Criar(const AURL, AUsuario, ASenha: string; const ATimeout: Integer): TEleicaoAPIConfig;
begin
  Result := Default(TEleicaoAPIConfig);
  Result.URL := Trim(AURL);
  Result.Usuario := Trim(AUsuario);
  Result.Senha := Trim(ASenha);
  Result.Timeout := ATimeout;

  if Result.Timeout <= 0 then
    Result.Timeout := 60000;

  while Result.URL.EndsWith('/') do
    Delete(Result.URL,Length(Result.URL),1);

  Result.Validar;
end;

procedure TEleicaoAPIConfig.Validar;
begin
  if Trim(URL).IsEmpty then raise Exception.Create('URL da API de eleição não configurada.');
  if Trim(Usuario).IsEmpty then raise Exception.Create('Usuário da API de eleição não configurado.');
  if Trim(Senha).IsEmpty then raise Exception.Create('Senha da API de eleição não configurada.');
end;

end.
