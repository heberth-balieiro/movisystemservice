unit Controllers.Eleicao;

interface

uses
  Uni;

type
  TControllersEleicao = class
  public
    class function SincronizarEleicao(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Service.Eleicao;

class function TControllersEleicao.SincronizarEleicao(AConn: TUniConnection;
  const AIDRegistro: Integer; out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    Result := TEleicaoService.SincronizarEleicao(AConn,AIDRegistro,AErro);
  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
