program SpecialService;

{$SetPEFlags 1}    //remove relocation table, it's not need for exe files
{$Z2}              // an enumerantion type is stored as unsigned word (max 65535 elements in enum)

uses
  Vcl.Forms,
  System.SyncObjs,
  Winapi.Windows,
  Main in 'Main.pas' {MainForm},
  Update in 'Update.pas',
  Utils in 'Utils.pas',
  Constants in 'Constants.pas';

{$R *.res}

var
  AppMutex: TMutex = nil;

function isSecondInstance: Boolean;
const
  UNIQUE_MUTEX_NAME = '{D8835707-4409-44C5-8E6F-2B5EE83C633D}';
var
  lMutexErr: Integer;
begin
  Result    := False;
  AppMutex  := TMutex.Create(nil, True, UNIQUE_MUTEX_NAME);
  lMutexErr := GetLastError;
  if lMutexErr <> ERROR_SUCCESS then
    Result := True;
end;

begin
  Application.Initialize;
  try
    if isSecondInstance then
      Exit;
    Application.MainFormOnTaskbar := False;
    Application.ShowMainForm      := False;
    Application.Title             := 'Very special service';
    Application.CreateForm(TMainForm, MainForm);
    Application.Run;
  finally
    if Assigned(AppMutex) then
      AppMutex.Free;
  end;
end.
