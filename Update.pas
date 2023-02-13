unit Update;

interface
procedure DownloadFile(ASourceUrl: string);
procedure ReplaceFile;
function getNewExeFileName: string;
function getCurrentExeName: string;

const
  CRLF = #13#10;
  C_BAT_FILE_NAME = 'Updater.bat';
  C_BAT_FILE = '@echo off' + CRLF +
               'if not exist "%s" goto finish' + CRLF + CRLF +
               ':again' + CRLF +
               'del "%s"' + CRLF +
               'if exist "%s" goto again' + CRLF + CRLF +
               'rename "%s" %s' + CRLF + CRLF +
               'start %s' + CRLF + CRLF +
               ':finish' + CRLF +
               'del ' + C_BAT_FILE_NAME + CRLF + CRLF +
               'exit';


implementation

uses IdHTTP, System.Classes, System.SysUtils, System.IOUtils, Winapi.Windows;

function BuildBatFileContent: string;
var
  lOldName, lNewName: string;
begin
  lOldName := getCurrentExeName;
  lNewName := getNewExeFileName;
  Result := Format(C_BAT_FILE, [lNewName, lOldName, lOldName, lNewName, TPath.GetFileName(lOldName), TPath.GetFileName(lOldName)]);
end;

function getNewExeFileName: string;
begin
  Result := ParamStr(0) + '_new';
end;

function getCurrentExeName: string;
begin
  Result := ParamStr(0);
end;

procedure DownloadFile(ASourceUrl: string);
var
  lIdHTTP: TIdHTTP;
  lStream: TMemoryStream;
  FileName: String;
begin
  Filename := getNewExeFileName;

  lIdHTTP := TIdHTTP.Create;
  lStream := TMemoryStream.Create;
  try
    try
      lIdHTTP.Get(ASourceUrl, lStream);
      lStream.SaveToFile(FileName);
    except
       // do nothing, just hide exception
    end;
  finally
    FreeAndNil(lStream);
    FreeAndNil(lIdHTTP);
  end;
end;

procedure RunBatFile;
begin
  if FileExists(C_BAT_FILE_NAME) and FileExists(getNewExeFileName) then
    WinExec(C_BAT_FILE_NAME, SW_MINIMIZE);
end;

procedure ReplaceFile;
var
  lStr: TStringList;
begin
  lStr := TStringList.Create;
  try
    lStr.Text := BuildBatFileContent;
    lStr.SaveToFile(C_BAT_FILE_NAME);
  finally
    FreeAndNil(lStr);
  end;
  RunBatFile;
  Halt(0);
end;

end.
