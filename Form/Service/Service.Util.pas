unit Service.Util;

interface

uses
  System.JSON;

type
  TUtilService = class
  private
  public
    class procedure SalvarJsonDebug(const AJson: TJSONObject; const ANomeArquivo: string); static;
  end;

implementation

uses
  System.Classes, System.SysUtils;

{ TUtilService }

class procedure TUtilService.SalvarJsonDebug(const AJson: TJSONObject;const ANomeArquivo: string);
var
  Lista: TStringList;
  Pasta: string;
begin
  Pasta := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'Debug\Json\';

  ForceDirectories(Pasta);

  Lista := TStringList.Create;
  try
    Lista.Text := AJson.Format(2);
    Lista.SaveToFile(Pasta + ANomeArquivo, TEncoding.UTF8);
  finally
    Lista.Free;
  end;
end;

{

Exemplo de uso

SalvarJsonDebug(Json, Format('Empresa_%d.json',[DTO.IdEmpresaSistema]));
    Result := True;
    Exit;

}


end.
