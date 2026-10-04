unit Controllers.EleicaoRetorno;

interface

uses
  System.SysUtils,
  Uni,
  Service.EleicaoRetorno;

type
  TControllersEleicaoRetorno = class
  public
    class function Sincronizar(
      AConn: TUniConnection;
      out AErro: string
    ): Boolean; static;
  end;

implementation

{ TControllersEleicaoRetorno }

class function TControllersEleicaoRetorno.Sincronizar(AConn: TUniConnection;out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    Result := TEleicaoRetornoService.Sincronizar(AConn,AErro);
  except
    on E: Exception do
    begin
      AErro := E.Message;
      Result := False;
    end;
  end;
end;

end.
