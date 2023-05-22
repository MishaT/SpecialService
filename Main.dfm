object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  ClientHeight = 160
  ClientWidth = 383
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object btnReload: TButton
    Left = 72
    Top = 32
    Width = 241
    Height = 49
    Caption = 'Reload'
    TabOrder = 0
    OnClick = btnReloadClick
  end
  object tmrKill: TTimer
    Interval = 20000
    OnTimer = tmrKillTimer
    Left = 32
    Top = 8
  end
  object tmrLoadParams: TTimer
    Interval = 60000
    OnTimer = tmrLoadParamsTimer
    Left = 32
    Top = 56
  end
end
