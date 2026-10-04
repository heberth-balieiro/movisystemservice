unit Controllers.UsuarioSistema;

interface

uses
  Uni;

type
  TControllersUsuarioSistema = class
  public
    class function Sincronizar(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
    class function SincronizarAptos(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
    class function SincronizarComissao(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Service.UsuarioSistema;

class function TControllersUsuarioSistema.Sincronizar(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    Result := TUsuarioSistemaService.Sincronizar(AConn,AIDRegistro,AErro);
  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

class function TControllersUsuarioSistema.SincronizarAptos(AConn: TUniConnection; const AIDRegistro: Integer;
  out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    Result := TUsuarioSistemaService.SincronizarAptos(AConn,AIDRegistro,AErro);
  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

class function TControllersUsuarioSistema.SincronizarComissao(AConn: TUniConnection;
      const AIDRegistro: Integer; out AErro: string): Boolean;
begin
   Result := False;
  AErro := '';

  try
    Result := TUsuarioSistemaService.SincronizarComissao(AConn,AIDRegistro,AErro);
  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
