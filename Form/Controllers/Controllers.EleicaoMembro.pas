unit Controllers.EleicaoMembro;

interface

uses
  Uni;

type
  TControllersEleicaoMembro = class
  public
    class function Sincronizar(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Service.EleicaoMembro;

class function TControllersEleicaoMembro.Sincronizar(AConn: TUniConnection;
  const AIDRegistro: Integer; out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    Result := TEleicaoMembroService.Sincronizar(AConn,AIDRegistro,AErro);
  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
