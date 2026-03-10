object FormDXComplyBuildConfirmationDialog: TFormDXComplyBuildConfirmationDialog
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'DX.Comply CRA Compliance Generation'
  ClientHeight = 316
  ClientWidth = 640
  Color = clBtnFace
  Constraints.MinHeight = 316
  Constraints.MinWidth = 640
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  Scaled = True
  PixelsPerInch = 96
  TextHeight = 15
  object TitleLabel: TLabel
    Left = 20
    Top = 20
    Width = 376
    Height = 25
    Caption = 'Generate CRA compliance documentation with DX.Comply'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object DescriptionLabel: TLabel
    Left = 20
    Top = 58
    Width = 600
    Height = 40
    AutoSize = False
    Caption =
      'DX.Comply will run a dedicated Deep-Evidence build with detailed MAP generation before creating the SBOM and the companion compliance report.'
    WordWrap = True
  end
  object ProjectCaptionLabel: TLabel
    Left = 20
    Top = 122
    Width = 41
    Height = 15
    Caption = 'Project:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object ProjectValueLabel: TLabel
    Left = 140
    Top = 122
    Width = 480
    Height = 15
    AutoSize = False
    Caption = 'ProjectValueLabel'
  end
  object ConfigurationCaptionLabel: TLabel
    Left = 20
    Top = 150
    Width = 78
    Height = 15
    Caption = 'Configuration:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object ConfigurationValueLabel: TLabel
    Left = 140
    Top = 150
    Width = 480
    Height = 15
    AutoSize = False
    Caption = 'ConfigurationValueLabel'
  end
  object PlatformCaptionLabel: TLabel
    Left = 20
    Top = 178
    Width = 47
    Height = 15
    Caption = 'Platform:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object PlatformValueLabel: TLabel
    Left = 140
    Top = 178
    Width = 480
    Height = 15
    AutoSize = False
    Caption = 'PlatformValueLabel'
  end
  object MapCaptionLabel: TLabel
    Left = 20
    Top = 206
    Width = 92
    Height = 15
    Caption = 'Expected MAP file:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object MapValueLabel: TLabel
    Left = 140
    Top = 206
    Width = 480
    Height = 36
    AutoSize = False
    Caption = 'MapValueLabel'
    WordWrap = True
  end
  object DisablePromptCheckBox: TCheckBox
    Left = 20
    Top = 258
    Width = 280
    Height = 21
    Caption = 'Do not show this confirmation again'
    TabOrder = 0
  end
  object OkButton: TButton
    Left = 444
    Top = 270
    Width = 88
    Height = 30
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object CancelButton: TButton
    Left = 544
    Top = 270
    Width = 88
    Height = 30
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end