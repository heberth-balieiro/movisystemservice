unit Controllers.EleicaoQuestao;

interface

uses
  Uni;

type
  TControllersEleicaoQuestao = class
  public
    class function SincronizarEleicaoQuestao(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
    class function SincronizarEleicaoQuestaoOpcao(AConn: TUniConnection; const AIDRegistro: Integer; out AErro: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  Service.EleicaoQuestao;

{ TControllersEleicaoQuestao }

class function TControllersEleicaoQuestao.SincronizarEleicaoQuestao(
  AConn: TUniConnection; const AIDRegistro: Integer;out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    Result := TEleicaoQuestaoService.SincronizarEleicaoQuestao(AConn,AIDRegistro,AErro);
  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

class function TControllersEleicaoQuestao.SincronizarEleicaoQuestaoOpcao(
  AConn: TUniConnection; const AIDRegistro: Integer;
  out AErro: string): Boolean;
begin
  Result := False;
  AErro := '';

  try
    Result := TEleicaoQuestaoService.SincronizarEleicaoQuestaoOpcao(AConn,AIDRegistro,AErro);
  except
    on E: Exception do
    begin
      Result := False;
      AErro := E.ClassName + ': ' + E.Message;
    end;
  end;
end;

end.
