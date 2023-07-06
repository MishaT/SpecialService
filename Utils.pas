unit Utils;

interface
uses Classes;

function GetVersionInt: Integer;
function GetVersionAsString: string;
procedure SendCloseKey;
procedure Play5minSound;
procedure KillTaskByTitle(FileCaption: string);
function KillTask(ExeFileName: string): Integer;
procedure KillTasks(AExeFileNames: TStrings);
procedure KillTasksByTitle(AFileCaptions: TStrings);
procedure MinimizeAppByTitle(AFileTitleName: string);
//procedure StopOneService(AServiceName: string);
procedure StopServices(AServiceNames: TStrings);


implementation

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, MMSystem, Constants, Tlhelp32, ShellApi;


procedure GetVersionInfo(var V1, V2, V3, V4: word);
var
  VerInfoSize, VerValueSize, Dummy: DWORD;
  VerInfo: Pointer;
  VerValue: PVSFixedFileInfo;
begin
  VerInfoSize := GetFileVersionInfoSize(PChar(ParamStr(0)), Dummy);
  if VerInfoSize > 0 then
  begin
      GetMem(VerInfo, VerInfoSize);
      try
        if GetFileVersionInfo(PChar(ParamStr(0)), 0, VerInfoSize, VerInfo) then
        begin
          VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
          with VerValue^ do
          begin
            V1 := dwFileVersionMS shr 16;
            V2 := dwFileVersionMS and $FFFF;
            V3 := dwFileVersionLS shr 16;
            V4 := dwFileVersionLS and $FFFF;
          end;
        end;
      finally
        FreeMem(VerInfo, VerInfoSize);
      end;
  end;
end;

function GetVersionInt: Integer;
var
  V1, V2, V3, V4: word;
begin
  GetVersionInfo(V1, V2, V3, V4);
  Result :=  V1*10000000 + V2*100000 + V3*1000 + V4;
end;

function GetVersionAsString: string;
var
  V1, V2, V3, V4: word;
begin
  GetVersionInfo(V1, V2, V3, V4);
  Result := IntToStr(V1) + '.' + IntToStr(V2) + '.' + IntToStr(V3) + '.' + IntToStr(V4);
end;

procedure SendCloseKey;
var
  Inputs: array [0..3] of TInput;
begin
  // press
  Inputs[0].Itype := INPUT_KEYBOARD;
  Inputs[0].ki.wVk := VK_CONTROL;
  Inputs[0].ki.dwFlags := 0;

  Inputs[1].Itype := INPUT_KEYBOARD;
  Inputs[1].ki.wVk := Ord('W');
  Inputs[1].ki.dwFlags := 0;

  // release
  Inputs[2].Itype := INPUT_KEYBOARD;
  Inputs[2].ki.wVk := Ord('W');
  Inputs[2].ki.dwFlags := KEYEVENTF_KEYUP;

  Inputs[3].Itype := INPUT_KEYBOARD;
  Inputs[3].ki.wVk := VK_CONTROL;
  Inputs[3].ki.dwFlags := KEYEVENTF_KEYUP;

  SendInput(Length(Inputs), Inputs[0], SizeOf(TInput));
end;

procedure Play5minSound;
begin
  if FileExists(C_5minSound_FileName) then
    PlaySound(pchar(C_5minSound_FileName), 0, SND_ASYNC or SND_FILENAME);
end;

procedure KillTaskByTitle(FileCaption: string);
var
  H: HWND;
begin //ExeFileName = caption or cmd path
  H := FindWindow(nil, LPCWSTR(FileCaption));
  if H <> 0 then
    PostMessage(H, WM_CLOSE, 0, 0);
end;

function KillTask(ExeFileName: string): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(
                        OpenProcess(PROCESS_TERMINATE,
                                    BOOL(0),
                                    FProcessEntry32.th32ProcessID),
                                    0));
     ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

procedure KillTasks(AExeFileNames: TStrings);
var
  i: Integer;
begin
  for i := 0 to AExeFileNames.Count - 1 do
  begin
    KillTask(AExeFileNames[i]);
  end;
end;

procedure KillTasksByTitle(AFileCaptions: TStrings);
var
  i: Integer;
begin
  for i := 0 to AFileCaptions.Count - 1 do
  begin
    KillTaskByTitle(AFileCaptions[i]);
  end;
end;

procedure MinimizeAppByTitle(AFileTitleName: string);
var
  H: HWND;
begin //ExeFileName = caption or cmd path
  H := FindWindow(nil, LPCWSTR(AFileTitleName));
  if H <> 0 then
    ShowWindow(H, SW_MINIMIZE);
end;

procedure StopOneService(AServiceName: string);
var
  cmd: String;
begin
  cmd := '/c sc stop "' + AServiceName + '"';
  ShellExecute(0, 'open', PChar('cmd.exe'), PChar(cmd), nil, SW_HIDE);
end;

procedure StopServices(AServiceNames: TStrings);
var
  i: Integer;
begin
  for i := 0 to AServiceNames.Count - 1 do
  begin
    StopOneService(AServiceNames[i]);
  end;

end;

end.
