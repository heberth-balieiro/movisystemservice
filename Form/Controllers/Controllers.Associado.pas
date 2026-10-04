unit Controllers.Associado;

interface

uses
  Uni;

type
  TControllersAssociado = class
  public
    class function SincronizarAssociado(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Service.Associado;

class function TControllersAssociado.SincronizarAssociado(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    Result := TAssociadoService.SincronizarAssociado(AConn,AIDRegistro,AErro);
  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
