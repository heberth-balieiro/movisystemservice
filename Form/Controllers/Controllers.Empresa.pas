unit Controllers.Empresa;

interface

uses
  Uni;

type
  TControllersEmpresa = class
  public
    class function SincronizarEmpresa(AConn: TUniConnection; const AIDEmpresa: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Service.Empresa;

{ TControllersEmpresa }

class function TControllersEmpresa.SincronizarEmpresa(AConn: TUniConnection;
  const AIDEmpresa: Integer; out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    Result := TEmpresaService.SincronizarEmpresa(AConn,AIDEmpresa,AErro);
  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
