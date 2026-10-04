unit Controllers.EleicaoConfig;

interface

uses
  Uni;

type
  TControllersEleicaoConfig = class
  public
    class function Sincronizar(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Service.EleicaoConfig;

class function TControllersEleicaoConfig.Sincronizar(AConn: TUniConnection;
  const AIDRegistro: Integer; out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    Result := TEleicaoConfigService.Sincronizar(AConn,AIDRegistro,AErro);
  except
    on E: Exception do begin Result := False; AErro := E.ClassName + ': ' + E.Message; end;
  end;
end;

end.
