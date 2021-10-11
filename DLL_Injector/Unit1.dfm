object Form1: TForm1
  Left = 265
  Top = 133
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'DLL Injector'
  ClientHeight = 105
  ClientWidth = 362
  Color = clBtnFace
  Font.Charset = RUSSIAN_CHARSET
  Font.Color = clBlack
  Font.Height = -13
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 120
  TextHeight = 16
  object SpeedButton1: TSpeedButton
    Left = 328
    Top = 40
    Width = 25
    Height = 25
    Caption = '...'
    OnClick = SpeedButton1Click
  end
  object Label1: TLabel
    Left = 8
    Top = 48
    Width = 54
    Height = 16
    Caption = 'DLL Path'
  end
  object Label2: TLabel
    Left = 8
    Top = 16
    Width = 69
    Height = 16
    Caption = 'Process ID:'
  end
  object Button1: TButton
    Left = 7
    Top = 72
    Width = 170
    Height = 25
    Caption = 'Inject DLL'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 184
    Top = 72
    Width = 169
    Height = 25
    Caption = 'UnInject DLL'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Edit1: TEdit
    Left = 88
    Top = 40
    Width = 233
    Height = 25
    TabOrder = 2
  end
  object Edit2: TEdit
    Left = 88
    Top = 8
    Width = 81
    Height = 25
    TabOrder = 3
  end
  object OpenDialog1: TOpenDialog
    Filter = 'dll, exe|*.dll;*.exe'
    Left = 183
    Top = 7
  end
end
