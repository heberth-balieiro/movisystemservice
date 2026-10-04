unit Controllers.ElaicaoComissao;

interface

uses
  Uni;

type
  TControllersEleicaoComissao = class
  public
    class function Sincronizar(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
    class function SincronizarAptos(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;


implementation

end.
