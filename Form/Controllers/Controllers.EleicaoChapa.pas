unit Controllers.EleicaoChapa;

interface

uses
  Uni;

type
  TControllersEleicaoChapa = class
  public
    class function Sincronizar(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Service.EleicaoChapa;

class function TControllersEleicaoChapa.Sincronizar(AConn: TUniConnection;
  const AIDRegistro: Integer; out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    Result := TEleicaoChapaService.Sincronizar(AConn,AIDRegistro,AErro);
  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
