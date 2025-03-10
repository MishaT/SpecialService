unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  Vcl.ExtCtrls;

type
  TMainForm = class(TForm)
    btnReload: TButton;
    tmrKill: TTimer;
    tmrLoadParams: TTimer;
    procedure btnReloadClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tmrKillTimer(Sender: TObject);
    procedure tmrLoadParamsTimer(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    AllowedTime: TDateTime;
    ExeNames: TStrings;
    ExeTitles: TStrings;
    TabsToClose: TStringList;
    AppsToMinimize: TStringList;
    ServicesToStop: TStringList;
    BrowserClassNames: TStringList;
    FAppVersion: string;
    FNewVersion: string;
    function GetSettingsFromUrl: string;
    procedure LoadParams(ASilent: Boolean = True);
    procedure ShowCaption;
    procedure DrawMessage(AText1, AText2: string);
    procedure CloseChromeTab;
    procedure MinimizeApps;
  public
    LocalHeader: string;
    LocalClassName: string;
    property AppVersion: string read FAppVersion;
  end;

var
  MainForm: TMainForm;

implementation

uses
  Tlhelp32, System.StrUtils, System.DateUtils, MMSystem, Update, Utils, Constants;

{$R *.dfm}

function EnumWindowsProc(wHandle: HWND; lb: TStringList): BOOL; stdcall;
var
  Title, ClassName: array[0..255] of char;
  position: Integer;
begin
  GetWindowText(wHandle, Title, 255);
  GetClassName(wHandle, ClassName, 255);
  if IsWindowVisible(wHandle) then
  begin
    if (Pos(MainForm.LocalClassName, string(ClassName)) > 0) then
    begin
      position := Pos(MainForm.LocalHeader, string(Title)); //need this variable to avoid optimization
      if (position > 0) then
      begin
        SetForegroundWindow(wHandle);
        SendCloseKey;
      end;
    end;
  end;
  Result := True;
end;

procedure TMainForm.btnReloadClick(Sender: TObject);
begin
  LoadParams(False);
end;

procedure TMainForm.CloseChromeTab;
var
  Urls: TStringList;
  LBrowserName, LTabName: string;
begin
  for LBrowserName in BrowserClassNames do
  begin
    LocalClassName := LBrowserName;
    for LTabName in TabsToClose do
    begin
      LocalHeader := LTabName;
      Urls := TStringList.Create;
      try
        EnumWindows(@EnumWindowsProc, LParam(Urls));
      finally
        FreeAndNil(Urls);
      end;
    end;
  end;
end;

procedure TMainForm.DrawMessage(AText1, AText2: string);
  procedure LPopulateCanvas(var ACanvas: TCanvas);
  var
    h: HWND;
  begin
    h := GetWindowDC(0);
    ACanvas.Handle      := h;
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Name   := 'Courier New';
    ACanvas.Font.Style  := [fsBold];
    ACanvas.Font.Size   := 60;
    ACanvas.Font.Color  := clRed;
  end;
var
  lCanvas: TCanvas;
  lWindowState: TWindowState;
  lFormVisible: Boolean;
begin
  lCanvas := TCanvas.Create;
  try
    LPopulateCanvas(lCanvas);
    lCanvas.TextOut(50, 50, AText1);
    lCanvas.TextOut(50, 150, AText2);
    Application.ProcessMessages;
    Sleep(10000);
  finally
    FreeAndNil(lCanvas);
  end;

  lWindowState := Self.WindowState;
  lFormVisible := Self.Visible;
  Self.Show;
  Self.BringToFront;
  Self.WindowState := wsMaximized;
  Self.WindowState := wsNormal;
  Self.WindowState := lWindowState;
  Self.Visible     := lFormVisible;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := false;
  Self.WindowState := wsMinimized;
  Self.Hide;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FAppVersion       := GetVersionAsString;
  TabsToClose       := TStringList.Create;
  ExeNames          := TStringList.Create;
  ExeTitles         := TStringList.Create;
  AppsToMinimize    := TStringList.Create;
  ServicesToStop    := TStringList.Create;
  BrowserClassNames := TStringList.Create;
  LoadParams;
end;

function TMainForm.GetSettingsFromUrl: string;
var
  lIdHTTP: TIdHTTP;
begin
  try
    lIdHTTP := TIdHTTP.Create;
    try
      Result := lIdHTTP.Get(C_SOURCE_URL);
    except
    end;
    if Result = '' then
    try
      Result := lIdHTTP.Get(C_SOURCE_URL2);
    except
    end;
  finally
    FreeAndNil(lIdHTTP);
  end;
end;

procedure TMainForm.LoadParams(ASilent: Boolean = True);
  function LGetFormatSettings: TFormatSettings;
  begin
    Result := TFormatSettings.Create;
    Result.ShortDateFormat := 'yyyy-MM-dd';
    Result.DateSeparator   := '-';
    Result.TimeSeparator   := ':';
  end;
  procedure LGetNewVersionInfo(AStrings: TStringList);
  var
    i: Integer;
    lStr: string;
    lPosition: Integer;
  begin
    FNewVersion := '';
    for i := 0 to AStrings.Count - 1 do
    begin
      if (Pos(C_VERSION_MARKER, AStrings[i]) = 1) then
      begin
        lStr := AStrings[i];
        lPosition := Pos(C_VERSION_MARKER, lStr);
        FNewVersion := Copy(lStr, Length(C_VERSION_MARKER) + 1, Length(lStr) - lPosition);
      end;
    end;
  end;

  procedure LFillAppsList(AStrings: TStrings; AMarker: String; AListToPopulate: TStrings; ASuffix: string = '');
  var
    i: Integer;
    lTabsStarted: Boolean;
  begin
    AListToPopulate.Clear;
    lTabsStarted := False;
    for i := 0 to AStrings.Count - 1 do
    begin
      if AStrings[i] = '' then
        Continue;
      if (lTabsStarted and (Pos('-- ', AStrings[i]) = 1)) then
        Exit;   //populate finished, new section started
      if (AStrings[i] = AMarker) then
      begin
        lTabsStarted := True;
        Continue; // skip this line
      end;
      if lTabsStarted then
      begin
        if (ASuffix <> '') or (RightStr(AStrings[i], Length(ASuffix)) = ASuffix) then
          AListToPopulate.Add(AStrings[i]);
      end;
    end;
  end;
var
  lReply: String;
  lStrings: TStringList;
  lText1, lText2: string;
begin
  lReply := GetSettingsFromUrl;
  if (lReply = '') then
    Exit;

  lStrings := TStringList.Create;
  try
    lStrings.Text := lReply;

//    LFillTabsAndExeToClose(lStrings);
    LFillAppsList(lStrings, C_CLOSE_APP_MARKER, ExeNames, '.exe');
    LFillAppsList(lStrings, C_CLOSE_APP_MARKER, ExeTitles);
    LFillAppsList(lStrings, C_CHROME_TABS_MARKER, TabsToClose);
    LFillAppsList(lStrings, C_MINIMIZE_APP_MARKER, AppsToMinimize);
    LFillAppsList(lStrings, C_SERVICES_LIST_MARKER, ServicesToStop);
    LFillAppsList(lStrings, C_BROWSER_CLASSES_MARKER, BrowserClassNames);

    LGetNewVersionInfo(lStrings);
  finally
    FreeAndNil(lStrings);
  end;

  if (StrToDateTime(lReply, LGetFormatSettings) <> AllowedTime) then
  begin
    AllowedTime := StrToDateTime(lReply, LGetFormatSettings);

    if Now > AllowedTime then
    begin
      lText1 := 'New Time : ' + FormatDateTime('hh:mm', AllowedTime);
      lText2 := 'Time is UP ';
    end
    else begin
      lText1 := 'New Time : ' + FormatDateTime('hh:mm', AllowedTime);
      lText2 := 'Remains : ' + IntToStr(MinutesBetween(Now, AllowedTime)) + ' min';
    end;

    if not ASilent then
      DrawMessage(lText1, lText2);
  end;

  ShowCaption;
end;

procedure TMainForm.MinimizeApps;
var
  i: Integer;
  lAppTitle: string;
begin
  for i := 0 to AppsToMinimize.Count - 1 do
  begin
    lAppTitle := AppsToMinimize[i];
    MinimizeAppByTitle(lAppTitle);
  end;
end;

procedure TMainForm.ShowCaption;
begin
  if Now > AllowedTime then
    Caption := FormatDateTime('hh:mm', AllowedTime) + ' Time is UP'
  else
    Caption := FormatDateTime('hh:mm', AllowedTime) +
      ' Remains : ' + IntToStr(MinutesBetween(Now, AllowedTime)) + ' min.';
end;

procedure TMainForm.tmrKillTimer(Sender: TObject);
var
  lRemainMinutes: Integer;
begin
  ShowCaption;
  lRemainMinutes := MinutesBetween(Now, AllowedTime);
  if (AllowedTime > Now) and (lRemainMinutes < 9) and (lRemainMinutes > 7) then
       Play5minSound;

  if Now > AllowedTime then
  begin
    KillTasks(ExeNames);
    KillTasksByTitle(ExeTitles);
    CloseChromeTab;
    MinimizeApps;
    StopServices(ServicesToStop);
  end;
end;

procedure TMainForm.tmrLoadParamsTimer(Sender: TObject);
begin
  LoadParams(False);
  if FNewVersion > AppVersion then
  begin
    DownloadFile(C_UPDATE_SOURCE);
    ReplaceFile;
  end;
end;

end.
