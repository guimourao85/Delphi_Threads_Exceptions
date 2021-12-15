unit ClasseExcessoes;

interface

uses
  SysUtils, Forms, System.Classes;

type
  TClasseExcecoes = class
  public
    class procedure TratarExcecao(E: Exception; Value: String);
  end;

implementation

uses
  Vcl.Dialogs;

class procedure TClasseExcecoes.TratarExcecao(E: Exception; Value: String);
var
  txtLog : TextFile;
  FLogFile : String;
begin
  FLogFile := ChangeFileExt(ParamStr(0), '.log');
  AssignFile(txtLog, FLogFile);
  if FileExists(FLogFile) then
    Append(txtLog)
  else
    Rewrite(txtLog);
  Writeln(txtLog, '=======================================================');
  Writeln(txtLog, FormatDateTime('dd/mm/YY hh:nn:ss - ', Now) + 'Chamada: ' +  Value);
  Writeln(txtLog, 'Classe Erro: ' + E.ClassName);
  Writeln(txtLog, 'Erro: ' + E.Message);
  CloseFile(txtLog);
  ShowMessage(E.Message);
end;


end.

