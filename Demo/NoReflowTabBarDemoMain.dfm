object FrmOngletBtn: TFrmOngletBtn
  Left = 0
  Top = 0
  Caption = 'NoReflowTabBar Demo'
  ClientHeight = 820
  ClientWidth = 1240
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  ShowHint = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 20
  object FStatusBar: TStatusBar
    Left = 0
    Top = 801
    Width = 1240
    Height = 19
    Panels = <>
    SimplePanel = True
    SimpleText = 'Ready'
  end
  object CardPanel1: TCardPanel
    Left = 0
    Top = 45
    Width = 1240
    Height = 756
    Align = alClient
    ActiveCard = CardButtonsModes
    Caption = 'CardPanel1'
    TabOrder = 1
    object CardOverview: TCard
      Left = 1
      Top = 1
      Width = 1238
      Height = 754
      Caption = 'Overview'
      CardIndex = 0
      TabOrder = 0
      object LabelTopOverview: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 3
        Width = 1214
        Height = 52
        Margins.Left = 12
        Margins.Right = 12
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 
          'Overview of the component: multi-row tabs, logical zones, zone h' +
          'eaders, glyphs, status indicators and drag support.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        WordWrap = True
        StyleElements = [seClient, seBorder]
      end
      object TopPanelOverview: TPanel
        Left = 0
        Top = 58
        Width = 1238
        Height = 50
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object BtnResetOverview: TButton
          Left = 12
          Top = 18
          Width = 140
          Height = 30
          Caption = 'Reset demo items'
          TabOrder = 1
          OnClick = BtnResetOverviewClick
        end
        object BtnSelectPrevious: TButton
          Left = 153
          Top = 18
          Width = 140
          Height = 30
          Caption = 'Select previous'
          TabOrder = 2
          OnClick = BtnSelectPreviousClick
        end
        object BtnSelectNext: TButton
          Left = 295
          Top = 18
          Width = 140
          Height = 30
          Caption = 'Select next'
          TabOrder = 0
          OnClick = BtnSelectNextClick
        end
      end
      object OverviewBar: TNoReflowTabBar
        Left = 0
        Top = 108
        Width = 1238
        Height = 143
        Hint = ' '
        BarAppearance.TabNormalTop = 13224393
        BarAppearance.TabNormalBottom = 10263708
        BarAppearance.TabNormalText = clBlack
        BarAppearance.TabNormalBorder = 13224393
        BarAppearance.TabHotTop = 9270622
        BarAppearance.TabHotBottom = 7692622
        BarAppearance.TabHotText = clWhite
        BarAppearance.TabHotBorder = 13224393
        BarAppearance.TabSelectedTop = 15461355
        BarAppearance.TabSelectedBottom = 15461355
        BarAppearance.TabSelectedText = 13395456
        BarAppearance.TabSelectedBorder = 13224393
        BarAppearance.TabDisabledTop = 15461355
        BarAppearance.TabDisabledBottom = 15461355
        BarAppearance.TabDisabledText = 9868950
        BarAppearance.TabDisabledBorder = 13224393
        BarAppearance.ButtonNormalTop = clWhitesmoke
        BarAppearance.ButtonNormalBottom = clGainsboro
        BarAppearance.ButtonNormalText = clBlack
        BarAppearance.ButtonNormalBorder = 10526880
        BarAppearance.ButtonHotTop = 16446187
        BarAppearance.ButtonHotBottom = 15785677
        BarAppearance.ButtonHotText = clBlack
        BarAppearance.ButtonHotBorder = 13395456
        BarAppearance.ButtonPressedTop = 14469300
        BarAppearance.ButtonPressedBottom = 16115415
        BarAppearance.ButtonPressedText = clBlack
        BarAppearance.ButtonPressedBorder = 11031552
        BarAppearance.ButtonSelectedTop = 13400576
        BarAppearance.ButtonSelectedBottom = 12084736
        BarAppearance.ButtonSelectedText = clWhite
        BarAppearance.ButtonSelectedBorder = 11031552
        BarAppearance.ButtonDisabledTop = 15461355
        BarAppearance.ButtonDisabledBottom = 14803425
        BarAppearance.ButtonDisabledText = 9868950
        BarAppearance.ButtonDisabledBorder = 12500670
        BarAppearance.ButtonLightEdge = clWhite
        BarAppearance.ButtonShadowEdge = clGray
        BarAppearance.FocusColor = 13395456
        BarPaletteMode = nrtcmStyle
        BarDragReorderMode = nrbrmAllZones
        BarEditEnabled = True
        BarSignals = <
          item
            Code = 1
            Name = 'Gray'
            FillColor = 11513775
            BorderColor = 8026746
          end
          item
            Code = 2
            Name = 'Green'
            FillColor = 3451449
            BorderColor = 3963199
          end
          item
            Code = 3
            Name = 'Orange'
            FillColor = 2535420
            BorderColor = 3897499
          end
          item
            Code = 4
            Name = 'Red'
            FillColor = 2700006
            BorderColor = 4869522
          end>
        BarLayout.ZoneSpacing = 18
        BarLayout.MarginStart = 12
        BarLayout.MarginEnd = 12
        BarLayoutTabs.ShapeSlantSecond = 32
        BarLayoutButtons.CornerRadius = 4
        BarImages = FImages
        BarZoneHeader.Visible = True
        BarZoneHeader.CaptionStart = 'Technical Data'
        BarZoneHeader.CaptionCenter = 'Manufacturing Stations'
        BarZoneHeader.CaptionEnd = 'Files'
        BarZoneHeader.Font.Charset = DEFAULT_CHARSET
        BarZoneHeader.Font.Color = clWindowText
        BarZoneHeader.Font.Height = -11
        BarZoneHeader.Font.Name = 'Segoe UI'
        BarZoneHeader.Font.Style = [fsItalic]
        BarItems = <
          item
            Caption = 'Property'
            SignalCode = 2
            UserId = 1001
            Checked = True
            Zone = nrtzStart
            ZoneIndex = 0
            GlyphIndex = 0
            ItemKey = 1
          end
          item
            Caption = 'Formulas'
            SignalCode = 1
            UserId = 1002
            Zone = nrtzStart
            ZoneIndex = 1
            GlyphIndex = 1
            ItemKey = 2
          end
          item
            Caption = 'Material Preparation'
            SignalCode = 1
            UserId = 2001
            ZoneIndex = 0
            GlyphIndex = 2
            ItemKey = 3
          end
          item
            Caption = 'Cutting'
            SignalCode = 3
            UserId = 2002
            ZoneIndex = 1
            GlyphIndex = 3
            ItemKey = 4
          end
          item
            Caption = 'Assembly Preparation'
            SignalCode = 2
            UserId = 2003
            ZoneIndex = 2
            GlyphIndex = 4
            ItemKey = 5
          end
          item
            Caption = 'Assembly'
            SignalCode = 1
            UserId = 2004
            ZoneIndex = 3
            GlyphIndex = 4
            ItemKey = 6
          end
          item
            Caption = 'Fittings Preparation'
            SignalCode = 3
            UserId = 2005
            ZoneIndex = 4
            GlyphIndex = 5
            ItemKey = 7
          end
          item
            Caption = 'Fittings'
            SignalCode = 2
            UserId = 2006
            ZoneIndex = 5
            GlyphIndex = 5
            ItemKey = 8
          end
          item
            Caption = 'Subcontracting Drawings'
            SignalCode = 3
            UserId = 3001
            Zone = nrtzEnd
            ZoneIndex = 0
            GlyphIndex = 6
            ItemKey = 9
          end
          item
            Caption = 'CAD Files'
            SignalCode = 2
            UserId = 3002
            Zone = nrtzEnd
            ZoneIndex = 1
            GlyphIndex = 7
            ItemKey = 10
          end>
        BarCurrentItemIndex = 0
        Align = alTop
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnChange = DemoBarChange
        OnItemClick = DemoBarItemClick
        OnItemDblClick = DemoBarItemDblClick
        OnGetItemHint = DemoGetItemHint
      end
    end
    object CardLayoutAndZone: TCard
      Left = 1
      Top = 1
      Width = 1238
      Height = 754
      Caption = 'LayoutAndZone'
      CardIndex = 1
      TabOrder = 1
      object LabelTopLayout: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 3
        Width = 1214
        Height = 52
        Margins.Left = 12
        Margins.Right = 12
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 
          'Layout and zones: change orientation, flow order, alignment, hea' +
          'ders, tab overlap, slants and radius.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        WordWrap = True
        StyleElements = [seClient, seBorder]
      end
      object TopPanelLayout: TPanel
        Left = 0
        Top = 201
        Width = 1238
        Height = 553
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
        object RgBarPosition: TRadioGroup
          Left = 12
          Top = 8
          Width = 150
          Height = 96
          Caption = 'Position'
          ItemIndex = 0
          Items.Strings = (
            'Top'
            'Bottom'
            'Left'
            'Right')
          TabOrder = 0
          OnClick = LayoutOptionClick
        end
        object RgLayoutMode: TRadioGroup
          Left = 170
          Top = 8
          Width = 128
          Height = 72
          Caption = 'Layout mode'
          ItemIndex = 1
          Items.Strings = (
            'Sequential'
            'By zones')
          TabOrder = 1
          OnClick = LayoutOptionClick
        end
        object RgFlowOrder: TRadioGroup
          Left = 305
          Top = 8
          Width = 210
          Height = 96
          Caption = 'Flow order'
          ItemIndex = 0
          Items.Strings = (
            'Normal'
            'Reverse zones'
            'Reverse zones and items')
          TabOrder = 2
          OnClick = LayoutOptionClick
        end
        object RgFlowAlignment: TRadioGroup
          Left = 523
          Top = 8
          Width = 133
          Height = 96
          Caption = 'Flow alignment'
          ItemIndex = 0
          Items.Strings = (
            'Start'
            'Center'
            'End')
          TabOrder = 3
          OnClick = LayoutOptionClick
        end
        object RgTextOrientation: TRadioGroup
          Left = 186
          Top = 111
          Width = 131
          Height = 96
          Caption = 'Text'
          ItemIndex = 0
          Items.Strings = (
            'Auto'
            'Horizontal'
            'Vertical up'
            'Vertical down')
          TabOrder = 4
          OnClick = LayoutOptionClick
        end
        object RgRenderMode: TRadioGroup
          Left = 461
          Top = 111
          Width = 99
          Height = 96
          Caption = 'Render'
          ItemIndex = 0
          Items.Strings = (
            'Auto'
            'Flat'
            'Gradient')
          TabOrder = 5
          OnClick = LayoutOptionClick
        end
        object RgPaletteMode: TRadioGroup
          Left = 565
          Top = 111
          Width = 89
          Height = 96
          Caption = 'Palette'
          ItemIndex = 0
          Items.Strings = (
            'Style'
            'Custom')
          TabOrder = 6
          OnClick = LayoutOptionClick
        end
        object RgShapeFirstSlant: TRadioGroup
          Left = 15
          Top = 219
          Width = 115
          Height = 96
          Caption = 'First Slant'
          ItemIndex = 0
          Items.Strings = (
            'None'
            'Slim'
            'Large')
          TabOrder = 7
          OnClick = LayoutOptionClick
        end
        object RgShapeFirstRadius: TRadioGroup
          Left = 263
          Top = 220
          Width = 140
          Height = 96
          Caption = 'First Radius'
          ItemIndex = 1
          Items.Strings = (
            'None'
            'Small'
            'Medium'
            'Large')
          TabOrder = 8
          OnClick = LayoutOptionClick
        end
        object ChkShowHeaders: TCheckBox
          Left = 20
          Top = 120
          Width = 157
          Height = 24
          Caption = 'Show zone headers'
          Checked = True
          State = cbChecked
          TabOrder = 9
          OnClick = HeaderVisibilityClick
        end
        object RgOverlap: TRadioGroup
          Left = 560
          Top = 220
          Width = 91
          Height = 96
          Caption = 'Overlap'
          ItemIndex = 1
          Items.Strings = (
            'None'
            'Negative'
            'Positive')
          TabOrder = 10
          OnClick = LayoutOptionClick
        end
        object ChkSameThickness: TCheckBox
          Left = 20
          Top = 146
          Width = 136
          Height = 24
          Caption = 'Same Thickness'
          TabOrder = 11
          OnClick = LayoutOptionClick
        end
        object ChkSameLength: TCheckBox
          Left = 20
          Top = 174
          Width = 141
          Height = 24
          Caption = 'Same Length'
          TabOrder = 12
          OnClick = LayoutOptionClick
        end
        object RgShapeSecondSlant: TRadioGroup
          Left = 139
          Top = 219
          Width = 115
          Height = 96
          Caption = 'Second Slant'
          ItemIndex = 2
          Items.Strings = (
            'None'
            'Slim'
            'Large')
          TabOrder = 13
          OnClick = LayoutOptionClick
        end
        object RgShapeSecondRadius: TRadioGroup
          Left = 410
          Top = 220
          Width = 140
          Height = 96
          Caption = 'Second Radius'
          ItemIndex = 2
          Items.Strings = (
            'None'
            'Small'
            'Medium'
            'Large')
          TabOrder = 14
          OnClick = LayoutOptionClick
        end
        object RgSignalsPosition: TRadioGroup
          Left = 329
          Top = 111
          Width = 99
          Height = 96
          Caption = 'Signals'
          ItemIndex = 0
          Items.Strings = (
            'Before'
            'After'
            'ItemEnd')
          TabOrder = 15
          OnClick = LayoutOptionClick
        end
      end
      object LayoutBar: TNoReflowTabBar
        Left = 0
        Top = 58
        Width = 1238
        Height = 143
        Hint = ' '
        BarAppearance.TabNormalTop = 13224393
        BarAppearance.TabNormalBottom = 10263708
        BarAppearance.TabNormalText = clBlack
        BarAppearance.TabNormalBorder = 13224393
        BarAppearance.TabHotTop = 9270622
        BarAppearance.TabHotBottom = 7692622
        BarAppearance.TabHotText = clWhite
        BarAppearance.TabHotBorder = 13224393
        BarAppearance.TabSelectedTop = 15461355
        BarAppearance.TabSelectedBottom = 15461355
        BarAppearance.TabSelectedText = 13395456
        BarAppearance.TabSelectedBorder = 13224393
        BarAppearance.TabDisabledTop = 15461355
        BarAppearance.TabDisabledBottom = 15461355
        BarAppearance.TabDisabledText = 9868950
        BarAppearance.TabDisabledBorder = 13224393
        BarAppearance.ButtonNormalTop = clWhitesmoke
        BarAppearance.ButtonNormalBottom = clGainsboro
        BarAppearance.ButtonNormalText = clBlack
        BarAppearance.ButtonNormalBorder = 10526880
        BarAppearance.ButtonHotTop = 16446187
        BarAppearance.ButtonHotBottom = 15785677
        BarAppearance.ButtonHotText = clBlack
        BarAppearance.ButtonHotBorder = 13395456
        BarAppearance.ButtonPressedTop = 14469300
        BarAppearance.ButtonPressedBottom = 16115415
        BarAppearance.ButtonPressedText = clBlack
        BarAppearance.ButtonPressedBorder = 11031552
        BarAppearance.ButtonSelectedTop = 13400576
        BarAppearance.ButtonSelectedBottom = 12084736
        BarAppearance.ButtonSelectedText = clWhite
        BarAppearance.ButtonSelectedBorder = 11031552
        BarAppearance.ButtonDisabledTop = 15461355
        BarAppearance.ButtonDisabledBottom = 14803425
        BarAppearance.ButtonDisabledText = 9868950
        BarAppearance.ButtonDisabledBorder = 12500670
        BarAppearance.ButtonLightEdge = clWhite
        BarAppearance.ButtonShadowEdge = clGray
        BarAppearance.FocusColor = 13395456
        BarPaletteMode = nrtcmStyle
        BarEditEnabled = True
        BarSignals = <
          item
            Code = 1
            Name = 'Gray'
            FillColor = 11513775
            BorderColor = 8026746
          end
          item
            Code = 2
            Name = 'Green'
            FillColor = 3451449
            BorderColor = 3963199
          end
          item
            Code = 3
            Name = 'Orange'
            FillColor = 2535420
            BorderColor = 3897499
          end
          item
            Code = 4
            Name = 'Red'
            FillColor = 2700006
            BorderColor = 4869522
          end>
        BarLayout.ZoneSpacing = 18
        BarLayout.MarginStart = 12
        BarLayout.MarginEnd = 12
        BarLayoutTabs.ShapeSlantSecond = 32
        BarLayoutTabs.ShapeRadiusFirst = 6
        BarLayoutTabs.ShapeRadiusSecond = 12
        BarLayoutButtons.CornerRadius = 4
        BarImages = FImages
        BarZoneHeader.Visible = True
        BarZoneHeader.CaptionStart = 'Technical Data'
        BarZoneHeader.CaptionCenter = 'Manufacturing Stations'
        BarZoneHeader.CaptionEnd = 'Files'
        BarZoneHeader.Font.Charset = DEFAULT_CHARSET
        BarZoneHeader.Font.Color = clWindowText
        BarZoneHeader.Font.Height = -11
        BarZoneHeader.Font.Name = 'Segoe UI'
        BarZoneHeader.Font.Style = [fsItalic]
        BarItems = <
          item
            Caption = 'Property'
            SignalCode = 2
            UserId = 1001
            Checked = True
            Zone = nrtzStart
            ZoneIndex = 0
            GlyphIndex = 0
            ItemKey = 1
          end
          item
            Caption = 'Formulas'
            SignalCode = 1
            UserId = 1002
            Zone = nrtzStart
            ZoneIndex = 1
            GlyphIndex = 1
            ItemKey = 2
          end
          item
            Caption = 'Material Preparation'
            SignalCode = 1
            UserId = 2001
            ZoneIndex = 0
            GlyphIndex = 2
            ItemKey = 3
          end
          item
            Caption = 'Cutting'
            SignalCode = 3
            UserId = 2002
            ZoneIndex = 1
            GlyphIndex = 3
            ItemKey = 4
          end
          item
            Caption = 'Assembly Preparation'
            SignalCode = 2
            UserId = 2003
            ZoneIndex = 2
            GlyphIndex = 4
            ItemKey = 5
          end
          item
            Caption = 'Assembly'
            SignalCode = 1
            UserId = 2004
            ZoneIndex = 3
            GlyphIndex = 4
            ItemKey = 6
          end
          item
            Caption = 'Fittings Preparation'
            SignalCode = 3
            UserId = 2005
            ZoneIndex = 4
            GlyphIndex = 5
            ItemKey = 7
          end
          item
            Caption = 'Fittings'
            SignalCode = 2
            UserId = 2006
            ZoneIndex = 5
            GlyphIndex = 5
            ItemKey = 8
          end
          item
            Caption = 'Subcontracting Drawings'
            SignalCode = 3
            UserId = 3001
            Zone = nrtzEnd
            ZoneIndex = 0
            GlyphIndex = 6
            GlyphPosition = nrigpTop
            ItemKey = 9
          end
          item
            Caption = 'CAD Files'
            SignalCode = 2
            UserId = 3002
            Zone = nrtzEnd
            ZoneIndex = 1
            GlyphIndex = 7
            GlyphPosition = nrigpTop
            ItemKey = 10
          end>
        BarCurrentItemIndex = 0
        Align = alTop
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnChange = DemoBarChange
        OnItemClick = DemoBarItemClick
        OnItemDblClick = DemoBarItemDblClick
      end
    end
    object CardSignals: TCard
      Left = 1
      Top = 1
      Width = 1238
      Height = 754
      Caption = 'Signals'
      CardIndex = 2
      TabOrder = 2
      object LabelTopSignals: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 3
        Width = 1214
        Height = 52
        Margins.Left = 12
        Margins.Right = 12
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 
          'Signals: standard indicators, partial indicators and custom appl' +
          'ication-defined signal colors.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        WordWrap = True
        StyleElements = [seClient, seBorder]
        ExplicitLeft = 14
      end
      object Label8: TLabel
        Left = 102
        Top = 379
        Width = 89
        Height = 20
        Caption = 'Signals filling'
      end
      object TopPanelSignals: TPanel
        Left = 0
        Top = 58
        Width = 1238
        Height = 50
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object BtnResetSignals: TButton
          Left = 12
          Top = 12
          Width = 140
          Height = 30
          Caption = 'Reset signals'
          TabOrder = 0
          OnClick = BtnResetSignalsClick
        end
      end
      object SignalsBar: TNoReflowTabBar
        Left = 0
        Top = 108
        Width = 1238
        Height = 211
        Hint = ' '
        BarAppearance.TabNormalTop = 13224393
        BarAppearance.TabNormalBottom = 10263708
        BarAppearance.TabNormalText = clBlack
        BarAppearance.TabNormalBorder = 13224393
        BarAppearance.TabHotTop = 9270622
        BarAppearance.TabHotBottom = 7692622
        BarAppearance.TabHotText = clWhite
        BarAppearance.TabHotBorder = 13224393
        BarAppearance.TabSelectedTop = 15461355
        BarAppearance.TabSelectedBottom = 15461355
        BarAppearance.TabSelectedText = 13395456
        BarAppearance.TabSelectedBorder = 13224393
        BarAppearance.TabDisabledTop = 15461355
        BarAppearance.TabDisabledBottom = 15461355
        BarAppearance.TabDisabledText = 9868950
        BarAppearance.TabDisabledBorder = 13224393
        BarAppearance.ButtonNormalTop = clWhitesmoke
        BarAppearance.ButtonNormalBottom = clGainsboro
        BarAppearance.ButtonNormalText = clBlack
        BarAppearance.ButtonNormalBorder = 10526880
        BarAppearance.ButtonHotTop = 16446187
        BarAppearance.ButtonHotBottom = 15785677
        BarAppearance.ButtonHotText = clBlack
        BarAppearance.ButtonHotBorder = 13395456
        BarAppearance.ButtonPressedTop = 14469300
        BarAppearance.ButtonPressedBottom = 16115415
        BarAppearance.ButtonPressedText = clBlack
        BarAppearance.ButtonPressedBorder = 11031552
        BarAppearance.ButtonSelectedTop = 13400576
        BarAppearance.ButtonSelectedBottom = 12084736
        BarAppearance.ButtonSelectedText = clWhite
        BarAppearance.ButtonSelectedBorder = 11031552
        BarAppearance.ButtonDisabledTop = 15461355
        BarAppearance.ButtonDisabledBottom = 14803425
        BarAppearance.ButtonDisabledText = 9868950
        BarAppearance.ButtonDisabledBorder = 12500670
        BarAppearance.ButtonLightEdge = clWhite
        BarAppearance.ButtonShadowEdge = clGray
        BarAppearance.FocusColor = 13395456
        BarPaletteMode = nrtcmStyle
        BarSignals = <
          item
            Code = 1
            Name = 'Gray'
            FillColor = 11513775
            BorderColor = 8026746
          end
          item
            Code = 2
            Name = 'Green'
            FillColor = 3451449
            BorderColor = 3963199
          end
          item
            Code = 3
            Name = 'Orange'
            FillColor = 2535420
            BorderColor = 3897499
          end
          item
            Code = 4
            Name = 'Red'
            FillColor = 2700006
            BorderColor = 4869522
          end>
        BarLayout.SameLength = True
        BarLayout.ZoneSpacing = 18
        BarLayout.MarginStart = 12
        BarLayout.MarginEnd = 12
        BarLayout.SignalSize = 30
        BarLayoutTabs.TabOverlap = -4
        BarLayoutTabs.ShapeSlantSecond = 0
        BarLayoutTabs.ShapeRadiusSecond = 3
        BarLayoutButtons.CornerRadius = 4
        BarImages = FImages
        BarZoneHeader.Visible = True
        BarZoneHeader.CaptionStart = 'Standards colors'
        BarZoneHeader.CaptionCenter = 'Users colors'
        BarZoneHeader.Font.Charset = DEFAULT_CHARSET
        BarZoneHeader.Font.Color = clWindowText
        BarZoneHeader.Font.Height = -11
        BarZoneHeader.Font.Name = 'Segoe UI'
        BarZoneHeader.Font.Style = [fsItalic]
        BarSignalPosition = nrtspItemEnd
        BarItems = <
          item
            Caption = 'No signal'
            UserId = 3100
            Checked = True
            Zone = nrtzStart
            ZoneIndex = 0
            GlyphIndex = 0
            ShowGlyph = False
            ItemKey = 1
          end
          item
            Caption = 'Gray standard'
            SignalCode = 1
            SignalValue = 4.000000000000000000
            SignalMax = 4.000000000000000000
            UserId = 3101
            Zone = nrtzStart
            ZoneIndex = 1
            GlyphIndex = 1
            ShowGlyph = False
            ItemKey = 2
          end
          item
            Caption = 'Green standard'
            SignalCode = 2
            SignalValue = 4.000000000000000000
            SignalMax = 4.000000000000000000
            UserId = 3102
            Zone = nrtzStart
            ZoneIndex = 2
            GlyphIndex = 2
            ShowGlyph = False
            ItemKey = 3
          end
          item
            Caption = 'Orange standard'
            SignalCode = 3
            SignalValue = 4.000000000000000000
            SignalMax = 4.000000000000000000
            UserId = 3103
            Zone = nrtzStart
            ZoneIndex = 3
            GlyphIndex = 3
            ShowGlyph = False
            ItemKey = 4
          end
          item
            Caption = 'Red standard'
            SignalCode = 4
            SignalValue = 4.000000000000000000
            SignalMax = 4.000000000000000000
            UserId = 3104
            Zone = nrtzStart
            ZoneIndex = 4
            GlyphIndex = 4
            ShowGlyph = False
            ItemKey = 5
          end>
        BarCurrentItemIndex = 0
        BarTextOrientation = nrttoVerticalUp
        Align = alTop
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnChange = DemoBarChange
      end
      object GroupBox2: TGroupBox
        Left = 466
        Top = 379
        Width = 411
        Height = 206
        Caption = 'User Color'
        TabOrder = 2
        object Label5: TLabel
          Left = 34
          Top = 40
          Width = 26
          Height = 20
          Caption = 'Red'
        end
        object Label6: TLabel
          Left = 154
          Top = 40
          Width = 39
          Height = 20
          Caption = 'Green'
        end
        object Label7: TLabel
          Left = 283
          Top = 40
          Width = 29
          Height = 20
          Caption = 'Blue'
        end
        object NbRed: TNumberBox
          Left = 68
          Top = 36
          Width = 64
          Height = 28
          MaxValue = 255.000000000000000000
          TabOrder = 0
        end
        object NbGreen: TNumberBox
          Left = 203
          Top = 36
          Width = 64
          Height = 28
          MaxValue = 255.000000000000000000
          TabOrder = 1
        end
        object NbBlue: TNumberBox
          Left = 321
          Top = 36
          Width = 64
          Height = 28
          MaxValue = 255.000000000000000000
          TabOrder = 2
        end
        object BtnAddUserColor: TButton
          Left = 32
          Top = 152
          Width = 358
          Height = 35
          Caption = 'Add User Color And create example item'
          TabOrder = 3
          OnClick = BtnAddUserColorClick
        end
        object RGSignalFilling: TRadioGroup
          Left = 34
          Top = 78
          Width = 353
          Height = 61
          Caption = 'Filling'
          Columns = 5
          ItemIndex = 4
          Items.Strings = (
            '0'
            '1/4'
            '2/4'
            '3/4'
            '4/4')
          TabOrder = 4
        end
      end
      object UpSignalRed: TUpDown
        Left = 201
        Top = 325
        Width = 40
        Height = 49
        Max = 4
        Position = 4
        TabOrder = 3
        OnClick = UpSignalRedClick
      end
      object UpSignalOrange: TUpDown
        Left = 155
        Top = 325
        Width = 40
        Height = 49
        Max = 4
        Position = 4
        TabOrder = 4
        OnClick = UpSignalOrangeClick
      end
      object UpSignalGreen: TUpDown
        Left = 107
        Top = 325
        Width = 40
        Height = 49
        Max = 4
        Position = 4
        TabOrder = 5
        OnClick = UpSignalGreenClick
      end
      object UpSignalGray: TUpDown
        Left = 60
        Top = 325
        Width = 40
        Height = 49
        Max = 4
        Position = 4
        TabOrder = 6
        OnClick = UpSignalGrayClick
      end
    end
    object CardEvents: TCard
      Left = 1
      Top = 1
      Width = 1238
      Height = 754
      Caption = 'Events'
      CardIndex = 3
      TabOrder = 3
      object LabelTopEvents: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 3
        Width = 1214
        Height = 52
        Margins.Left = 12
        Margins.Right = 12
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 
          'Events: click, selection, drag, edit and hover callbacks are log' +
          'ged in the grid below.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        WordWrap = True
        StyleElements = [seClient, seBorder]
      end
      object TopPanelEvents: TPanel
        Left = 0
        Top = 58
        Width = 1238
        Height = 50
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object BtnClearEvents: TButton
          Left = 12
          Top = 12
          Width = 140
          Height = 30
          Caption = 'Clear events'
          TabOrder = 0
          OnClick = BtnClearEventsClick
        end
      end
      object EventsBar: TNoReflowTabBar
        Left = 0
        Top = 108
        Width = 1238
        Height = 65
        Hint = ' '
        BarAppearance.TabNormalTop = 13224393
        BarAppearance.TabNormalBottom = 10263708
        BarAppearance.TabNormalText = clBlack
        BarAppearance.TabNormalBorder = 13224393
        BarAppearance.TabHotTop = 9270622
        BarAppearance.TabHotBottom = 7692622
        BarAppearance.TabHotText = clWhite
        BarAppearance.TabHotBorder = 13224393
        BarAppearance.TabSelectedTop = 15461355
        BarAppearance.TabSelectedBottom = 15461355
        BarAppearance.TabSelectedText = 13395456
        BarAppearance.TabSelectedBorder = 13224393
        BarAppearance.TabDisabledTop = 15461355
        BarAppearance.TabDisabledBottom = 15461355
        BarAppearance.TabDisabledText = 9868950
        BarAppearance.TabDisabledBorder = 13224393
        BarAppearance.ButtonNormalTop = clWhitesmoke
        BarAppearance.ButtonNormalBottom = clGainsboro
        BarAppearance.ButtonNormalText = clBlack
        BarAppearance.ButtonNormalBorder = 10526880
        BarAppearance.ButtonHotTop = 16446187
        BarAppearance.ButtonHotBottom = 15785677
        BarAppearance.ButtonHotText = clBlack
        BarAppearance.ButtonHotBorder = 13395456
        BarAppearance.ButtonPressedTop = 14469300
        BarAppearance.ButtonPressedBottom = 16115415
        BarAppearance.ButtonPressedText = clBlack
        BarAppearance.ButtonPressedBorder = 11031552
        BarAppearance.ButtonSelectedTop = 13400576
        BarAppearance.ButtonSelectedBottom = 12084736
        BarAppearance.ButtonSelectedText = clWhite
        BarAppearance.ButtonSelectedBorder = 11031552
        BarAppearance.ButtonDisabledTop = 15461355
        BarAppearance.ButtonDisabledBottom = 14803425
        BarAppearance.ButtonDisabledText = 9868950
        BarAppearance.ButtonDisabledBorder = 12500670
        BarAppearance.ButtonLightEdge = clWhite
        BarAppearance.ButtonShadowEdge = clGray
        BarAppearance.FocusColor = 13395456
        BarPaletteMode = nrtcmStyle
        BarDragReorderMode = nrbrmAllZones
        BarSignals = <
          item
            Code = 1
            Name = 'Gray'
            FillColor = 11513775
            BorderColor = 8026746
          end
          item
            Code = 2
            Name = 'Green'
            FillColor = 3451449
            BorderColor = 3963199
          end
          item
            Code = 3
            Name = 'Orange'
            FillColor = 2535420
            BorderColor = 3897499
          end
          item
            Code = 4
            Name = 'Red'
            FillColor = 2700006
            BorderColor = 4869522
          end>
        BarLayout.ZoneSpacing = 18
        BarLayout.MarginStart = 12
        BarLayout.MarginEnd = 12
        BarLayoutTabs.ShapeSlantSecond = 32
        BarLayoutButtons.CornerRadius = 4
        BarImages = FImages
        BarZoneHeader.Visible = True
        BarZoneHeader.CaptionStart = 'Start'
        BarZoneHeader.CaptionCenter = 'Center'
        BarZoneHeader.CaptionEnd = 'End'
        BarZoneHeader.Font.Charset = DEFAULT_CHARSET
        BarZoneHeader.Font.Color = clWindowText
        BarZoneHeader.Font.Height = -11
        BarZoneHeader.Font.Name = 'Segoe UI'
        BarZoneHeader.Font.Style = [fsItalic]
        BarItems = <
          item
            Caption = 'Item 1 '
            UserId = 3100
            Checked = True
            Zone = nrtzStart
            ZoneIndex = 0
            GlyphIndex = 0
            ShowGlyph = False
            ItemKey = 1
          end
          item
            Caption = 'Item 2'
            UserId = 3101
            Zone = nrtzStart
            ZoneIndex = 1
            GlyphIndex = 1
            ShowGlyph = False
            ItemKey = 2
          end
          item
            Caption = 'Item 3'
            UserId = 3102
            ZoneIndex = 0
            GlyphIndex = 2
            ShowGlyph = False
            ItemKey = 3
          end
          item
            Caption = 'Item 4'
            UserId = 3103
            ZoneIndex = 1
            GlyphIndex = 3
            ShowGlyph = False
            ItemKey = 4
          end
          item
            Caption = 'Item 5'
            UserId = 3104
            ZoneIndex = 2
            GlyphIndex = 4
            ShowGlyph = False
            ItemKey = 5
          end
          item
            Caption = 'Item 6'
            UserId = 3105
            Zone = nrtzEnd
            ZoneIndex = 0
            GlyphIndex = 5
            ShowGlyph = False
            ItemKey = 6
          end
          item
            Caption = 'Item 7'
            UserId = 3106
            Zone = nrtzEnd
            ZoneIndex = 1
            GlyphIndex = 6
            ShowGlyph = False
            ItemKey = 7
          end>
        BarCurrentItemIndex = 0
        Align = alTop
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnChange = DemoBarChange
        OnItemClick = DemoBarItemClick
        OnItemDblClick = DemoBarItemDblClick
        OnBeginItemDrag = DemoBeginItemDrag
        OnEndItemDrag = DemoEndItemDrag
        OnCanReorderItem = DemoCanReorderItem
        OnCanDropItem = DemoCanDropItem
        OnItemDropped = DemoItemDropped
        OnItemDragOver = DemoItemDragOver
        OnItemDragLeave = DemoItemDragLeave
        OnCanEditItemCaption = DemoCanEditItemCaption
        OnValidateItemCaption = DemoValidateItemCaption
        OnItemCaptionEdited = DemoItemCaptionEdited
        OnGetItemHint = DemoGetItemHint
        OnItemMouseEnter = DemoItemMouseEnter
        OnItemMouseLeave = DemoItemMouseLeave
        OnZoneMouseEnter = DemoZoneMouseEnter
        OnZoneMouseLeave = DemoZoneMouseLeave
      end
      object EventsGrid: TStringGrid
        AlignWithMargins = True
        Left = 12
        Top = 183
        Width = 1214
        Height = 559
        Margins.Left = 12
        Margins.Top = 10
        Margins.Right = 12
        Margins.Bottom = 12
        Align = alClient
        ColCount = 2
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
        TabOrder = 2
      end
    end
    object CardButtonsModes: TCard
      Left = 1
      Top = 1
      Width = 1238
      Height = 754
      Caption = 'ButtonsModes'
      CardIndex = 4
      TabOrder = 4
      object LabelTopButtons: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 3
        Width = 1214
        Height = 52
        Margins.Left = 12
        Margins.Right = 12
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 
          'Button modes: same item model rendered as tabs, push buttons, se' +
          'lect buttons or check buttons.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        WordWrap = True
        StyleElements = [seClient, seBorder]
      end
      object TopPanelButtons: TPanel
        Left = 0
        Top = 58
        Width = 1238
        Height = 149
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object RgButtonMode: TRadioGroup
          Left = 12
          Top = 2
          Width = 151
          Height = 105
          Caption = 'Mode'
          ItemIndex = 0
          Items.Strings = (
            'Push buttons'
            'Select buttons'
            'Check buttons')
          TabOrder = 1
          OnClick = ButtonModeClick
        end
        object RgForcedButtonSize: TRadioGroup
          Left = 574
          Top = 2
          Width = 218
          Height = 140
          Caption = 'Button length/thickness'
          ItemIndex = 0
          Items.Strings = (
            'Natural'
            'Forced length'
            'Forced thickness'
            'Forced length + thickness'
            'Very small'
            'Minimum length')
          TabOrder = 0
          OnClick = ButtonModeClick
        end
        object BtnResetButtonModes: TButton
          Left = 924
          Top = 43
          Width = 140
          Height = 30
          Caption = 'Reset items'
          TabOrder = 2
          OnClick = BtnResetButtonModesClick
        end
        object RgButtonsPosition: TRadioGroup
          Left = 175
          Top = 2
          Width = 103
          Height = 128
          Caption = 'Position'
          ItemIndex = 0
          Items.Strings = (
            'Top '
            'Bottom'
            'Left '
            'Right')
          TabOrder = 3
          OnClick = ButtonModeClick
        end
        object RgButtonsTextDirection: TRadioGroup
          Left = 287
          Top = 2
          Width = 134
          Height = 102
          Caption = 'Text direction'
          ItemIndex = 0
          Items.Strings = (
            'Horizontal'
            'Vertical Up'
            'Vertical down')
          TabOrder = 4
          OnClick = ButtonModeClick
        end
        object RgButtonsSignalPosition: TRadioGroup
          Left = 431
          Top = 2
          Width = 134
          Height = 80
          Caption = 'Signal position'
          ItemIndex = 0
          Items.Strings = (
            'Before'
            'After')
          TabOrder = 5
          OnClick = ButtonModeClick
        end
      end
      object ButtonModeBar: TNoReflowTabBar
        Left = 0
        Top = 207
        Width = 1238
        Height = 171
        Hint = ' '
        BarAppearance.TabNormalTop = 13224393
        BarAppearance.TabNormalBottom = 10263708
        BarAppearance.TabNormalText = clBlack
        BarAppearance.TabNormalBorder = 13224393
        BarAppearance.TabHotTop = 9270622
        BarAppearance.TabHotBottom = 7692622
        BarAppearance.TabHotText = clWhite
        BarAppearance.TabHotBorder = 13224393
        BarAppearance.TabSelectedTop = 15461355
        BarAppearance.TabSelectedBottom = 15461355
        BarAppearance.TabSelectedText = 13395456
        BarAppearance.TabSelectedBorder = 13224393
        BarAppearance.TabDisabledTop = 15461355
        BarAppearance.TabDisabledBottom = 15461355
        BarAppearance.TabDisabledText = 9868950
        BarAppearance.TabDisabledBorder = 13224393
        BarAppearance.ButtonNormalTop = clWhitesmoke
        BarAppearance.ButtonNormalBottom = clGainsboro
        BarAppearance.ButtonNormalText = clBlack
        BarAppearance.ButtonNormalBorder = 10526880
        BarAppearance.ButtonHotTop = 16446187
        BarAppearance.ButtonHotBottom = 15785677
        BarAppearance.ButtonHotText = clBlack
        BarAppearance.ButtonHotBorder = 13395456
        BarAppearance.ButtonPressedTop = 14469300
        BarAppearance.ButtonPressedBottom = 16115415
        BarAppearance.ButtonPressedText = clBlack
        BarAppearance.ButtonPressedBorder = 11031552
        BarAppearance.ButtonSelectedTop = 13400576
        BarAppearance.ButtonSelectedBottom = 12084736
        BarAppearance.ButtonSelectedText = clWhite
        BarAppearance.ButtonSelectedBorder = 11031552
        BarAppearance.ButtonDisabledTop = 15461355
        BarAppearance.ButtonDisabledBottom = 14803425
        BarAppearance.ButtonDisabledText = 9868950
        BarAppearance.ButtonDisabledBorder = 12500670
        BarAppearance.ButtonLightEdge = clWhite
        BarAppearance.ButtonShadowEdge = clGray
        BarAppearance.FocusColor = 13395456
        BarPaletteMode = nrtcmStyle
        BarRenderMode = nrrmGradient
        BarMode = nrbmPushButtons
        BarEditEnabled = True
        BarSignals = <
          item
            Code = 1
            Name = 'Gray'
            FillColor = 11513775
            BorderColor = 8026746
          end
          item
            Code = 2
            Name = 'Green'
            FillColor = 3451449
            BorderColor = 3963199
          end
          item
            Code = 3
            Name = 'Orange'
            FillColor = 2535420
            BorderColor = 3897499
          end
          item
            Code = 4
            Name = 'Red'
            FillColor = 2700006
            BorderColor = 4869522
          end>
        BarLayout.ZoneSpacing = 18
        BarLayout.MarginStart = 12
        BarLayout.MarginEnd = 12
        BarLayoutTabs.ShapeSlantSecond = 32
        BarLayoutButtons.CornerRadius = 4
        BarImages = FImages
        BarZoneHeader.Visible = True
        BarZoneHeader.CaptionStart = 'Technical Data'
        BarZoneHeader.CaptionCenter = 'Manufacturing Stations'
        BarZoneHeader.CaptionEnd = 'Files'
        BarZoneHeader.Font.Charset = DEFAULT_CHARSET
        BarZoneHeader.Font.Color = clWindowText
        BarZoneHeader.Font.Height = -11
        BarZoneHeader.Font.Name = 'Segoe UI'
        BarZoneHeader.Font.Style = [fsItalic]
        BarSignalPosition = nrtspItemEnd
        BarItems = <
          item
            Caption = 'Property'
            SignalCode = 2
            UserId = 1001
            Checked = True
            Zone = nrtzStart
            ZoneIndex = 0
            GlyphIndex = 0
            GlyphPosition = nrigpRight
            ItemKey = 1
          end
          item
            Caption = 'Formulas'
            SignalCode = 1
            UserId = 1002
            Zone = nrtzStart
            ZoneIndex = 1
            GlyphIndex = 1
            GlyphPosition = nrigpRight
            ItemKey = 2
          end
          item
            Caption = 'Material Preparation'
            SignalCode = 1
            UserId = 2001
            ZoneIndex = 0
            GlyphIndex = 2
            ItemKey = 3
          end
          item
            Caption = 'Cutting'
            SignalCode = 3
            UserId = 2002
            ZoneIndex = 1
            GlyphIndex = 3
            ItemKey = 4
          end
          item
            Caption = 'Assembly Preparation'
            SignalCode = 2
            UserId = 2003
            ZoneIndex = 2
            GlyphIndex = 4
            ItemKey = 5
          end
          item
            Caption = 'Assembly'
            UserId = 2004
            ZoneIndex = 3
            GlyphIndex = 4
            ItemKey = 6
          end
          item
            Caption = 'Fittings Preparation'
            SignalCode = 3
            UserId = 2005
            ZoneIndex = 4
            GlyphIndex = 5
            ItemKey = 7
          end
          item
            Caption = 'Fittings'
            SignalCode = 2
            UserId = 2006
            ZoneIndex = 5
            GlyphIndex = 5
            ItemKey = 8
          end
          item
            Caption = 'Program files'
            ZoneIndex = 6
            GlyphIndex = 0
            GlyphPosition = nrigpBottom
            ItemKey = 11
          end
          item
            Caption = 'Subcontracting Drawings'
            SignalCode = 3
            UserId = 3001
            Zone = nrtzEnd
            ZoneIndex = 0
            GlyphIndex = 6
            GlyphPosition = nrigpTop
            ItemKey = 9
          end
          item
            Caption = 'CAD Files'
            SignalCode = 2
            UserId = 3002
            Zone = nrtzEnd
            ZoneIndex = 1
            GlyphIndex = 7
            GlyphPosition = nrigpTop
            ItemKey = 10
          end>
        Align = alTop
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnChange = DemoBarChange
        OnItemClick = DemoBarItemClick
        OnItemDblClick = DemoBarItemDblClick
      end
    end
    object CardDragAndDrop: TCard
      Left = 1
      Top = 1
      Width = 1238
      Height = 754
      Caption = 'DragAndDrop'
      CardIndex = 5
      TabOrder = 5
      object LabelTopDrag: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 3
        Width = 1214
        Height = 52
        Margins.Left = 12
        Margins.Right = 12
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 
          'Drag and drop: move items inside a bar, between bars, or hover a' +
          ' menu tab to activate a target button bar.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        WordWrap = True
        StyleElements = [seClient, seBorder]
      end
      object TopPanelDrag: TPanel
        Left = 0
        Top = 58
        Width = 1238
        Height = 42
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object BtnResetDrag: TButton
          Left = 17
          Top = 2
          Width = 150
          Height = 30
          Caption = 'Reset drag sample'
          TabOrder = 0
          OnClick = BtnResetDragClick
        end
      end
      object DragBar1: TNoReflowTabBar
        Left = 0
        Top = 413
        Width = 1238
        Height = 65
        Hint = ' '
        BarAppearance.TabNormalTop = 13224393
        BarAppearance.TabNormalBottom = 10263708
        BarAppearance.TabNormalText = clBlack
        BarAppearance.TabNormalBorder = 13224393
        BarAppearance.TabHotTop = 9270622
        BarAppearance.TabHotBottom = 7692622
        BarAppearance.TabHotText = clWhite
        BarAppearance.TabHotBorder = 13224393
        BarAppearance.TabSelectedTop = 15461355
        BarAppearance.TabSelectedBottom = 15461355
        BarAppearance.TabSelectedText = 13395456
        BarAppearance.TabSelectedBorder = 13224393
        BarAppearance.TabDisabledTop = 15461355
        BarAppearance.TabDisabledBottom = 15461355
        BarAppearance.TabDisabledText = 9868950
        BarAppearance.TabDisabledBorder = 13224393
        BarAppearance.ButtonNormalTop = clWhitesmoke
        BarAppearance.ButtonNormalBottom = clGainsboro
        BarAppearance.ButtonNormalText = clBlack
        BarAppearance.ButtonNormalBorder = 10526880
        BarAppearance.ButtonHotTop = 16446187
        BarAppearance.ButtonHotBottom = 15785677
        BarAppearance.ButtonHotText = clBlack
        BarAppearance.ButtonHotBorder = 13395456
        BarAppearance.ButtonPressedTop = 14469300
        BarAppearance.ButtonPressedBottom = 16115415
        BarAppearance.ButtonPressedText = clBlack
        BarAppearance.ButtonPressedBorder = 11031552
        BarAppearance.ButtonSelectedTop = 13400576
        BarAppearance.ButtonSelectedBottom = 12084736
        BarAppearance.ButtonSelectedText = clWhite
        BarAppearance.ButtonSelectedBorder = 11031552
        BarAppearance.ButtonDisabledTop = 15461355
        BarAppearance.ButtonDisabledBottom = 14803425
        BarAppearance.ButtonDisabledText = 9868950
        BarAppearance.ButtonDisabledBorder = 12500670
        BarAppearance.ButtonLightEdge = clWhite
        BarAppearance.ButtonShadowEdge = clGray
        BarAppearance.FocusColor = 13395456
        BarPaletteMode = nrtcmStyle
        BarDragReorderMode = nrbrmAllZones
        BarDragInterBarMode = nrtbimSourceAndTarget
        BarDragInterBarGroup = 'DragMultiBar'
        BarSignals = <
          item
            Code = 1
            Name = 'Gray'
            FillColor = 11513775
            BorderColor = 8026746
          end
          item
            Code = 2
            Name = 'Green'
            FillColor = 3451449
            BorderColor = 3963199
          end
          item
            Code = 3
            Name = 'Orange'
            FillColor = 2535420
            BorderColor = 3897499
          end
          item
            Code = 4
            Name = 'Red'
            FillColor = 2700006
            BorderColor = 4869522
          end>
        BarLayout.ZoneSpacing = 18
        BarLayout.MarginStart = 12
        BarLayout.MarginEnd = 12
        BarLayoutTabs.ShapeSlantSecond = 32
        BarLayoutTabs.ShapeRadiusFirst = 6
        BarLayoutTabs.ShapeRadiusSecond = 12
        BarLayoutButtons.CornerRadius = 4
        BarImages = FImages
        BarZoneHeader.Visible = True
        BarZoneHeader.CaptionStart = 'Start'
        BarZoneHeader.CaptionCenter = 'Center'
        BarZoneHeader.CaptionEnd = 'End'
        BarZoneHeader.Font.Charset = DEFAULT_CHARSET
        BarZoneHeader.Font.Color = clWindowText
        BarZoneHeader.Font.Height = -11
        BarZoneHeader.Font.Name = 'Segoe UI'
        BarZoneHeader.Font.Style = [fsItalic]
        BarItems = <
          item
            Caption = 'Bar 1 - Item 1'
            UserId = 4001
            Checked = True
            Zone = nrtzStart
            ZoneIndex = 0
            GlyphIndex = 0
            ShowGlyph = False
            ItemKey = 1
          end
          item
            Caption = 'Bar 1 - Item 2'
            UserId = 4002
            ZoneIndex = 0
            GlyphIndex = 1
            ShowGlyph = False
            ItemKey = 2
          end
          item
            Caption = 'Bar 1 - Item 3'
            UserId = 4003
            ZoneIndex = 1
            GlyphIndex = 2
            ShowGlyph = False
            ItemKey = 3
          end
          item
            Caption = 'Bar 1 - Item 4'
            UserId = 4004
            Zone = nrtzEnd
            ZoneIndex = 0
            GlyphIndex = 3
            ShowGlyph = False
            ItemKey = 4
          end>
        BarCurrentItemIndex = 0
        Align = alTop
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnItemDropped = DemoItemDropped
      end
      object MenuFocusBar: TNoReflowTabBar
        Left = 0
        Top = 612
        Width = 1238
        Height = 39
        Hint = ' '
        BarAppearance.TabNormalTop = 13224393
        BarAppearance.TabNormalBottom = 10263708
        BarAppearance.TabNormalText = clBlack
        BarAppearance.TabNormalBorder = 13224393
        BarAppearance.TabHotTop = 9270622
        BarAppearance.TabHotBottom = 7692622
        BarAppearance.TabHotText = clWhite
        BarAppearance.TabHotBorder = 13224393
        BarAppearance.TabSelectedTop = 15461355
        BarAppearance.TabSelectedBottom = 15461355
        BarAppearance.TabSelectedText = 13395456
        BarAppearance.TabSelectedBorder = 13224393
        BarAppearance.TabDisabledTop = 15461355
        BarAppearance.TabDisabledBottom = 15461355
        BarAppearance.TabDisabledText = 9868950
        BarAppearance.TabDisabledBorder = 13224393
        BarAppearance.ButtonNormalTop = clWhitesmoke
        BarAppearance.ButtonNormalBottom = clGainsboro
        BarAppearance.ButtonNormalText = clBlack
        BarAppearance.ButtonNormalBorder = 10526880
        BarAppearance.ButtonHotTop = 16446187
        BarAppearance.ButtonHotBottom = 15785677
        BarAppearance.ButtonHotText = clBlack
        BarAppearance.ButtonHotBorder = 13395456
        BarAppearance.ButtonPressedTop = 14469300
        BarAppearance.ButtonPressedBottom = 16115415
        BarAppearance.ButtonPressedText = clBlack
        BarAppearance.ButtonPressedBorder = 11031552
        BarAppearance.ButtonSelectedTop = 13400576
        BarAppearance.ButtonSelectedBottom = 12084736
        BarAppearance.ButtonSelectedText = clWhite
        BarAppearance.ButtonSelectedBorder = 11031552
        BarAppearance.ButtonDisabledTop = 15461355
        BarAppearance.ButtonDisabledBottom = 14803425
        BarAppearance.ButtonDisabledText = 9868950
        BarAppearance.ButtonDisabledBorder = 12500670
        BarAppearance.ButtonLightEdge = clWhite
        BarAppearance.ButtonShadowEdge = clGray
        BarAppearance.FocusColor = 13395456
        BarPaletteMode = nrtcmStyle
        BarDragInterBarGroup = 'DragInterBar'
        BarSignals = <
          item
            Code = 1
            Name = 'Gray'
            FillColor = 11513775
            BorderColor = 8026746
          end
          item
            Code = 2
            Name = 'Green'
            FillColor = 3451449
            BorderColor = 3963199
          end
          item
            Code = 3
            Name = 'Orange'
            FillColor = 2535420
            BorderColor = 3897499
          end
          item
            Code = 4
            Name = 'Red'
            FillColor = 2700006
            BorderColor = 4869522
          end>
        BarLayout.ZoneSpacing = 18
        BarLayout.MarginStart = 12
        BarLayout.MarginEnd = 12
        BarLayoutTabs.TabOverlap = 0
        BarLayoutTabs.ShapeSlantFirst = 10
        BarLayoutTabs.ShapeSlantSecond = 10
        BarLayoutTabs.ShapeRadiusFirst = 12
        BarLayoutTabs.ShapeRadiusSecond = 12
        BarLayoutButtons.CornerRadius = 4
        BarImages = FImages
        BarZoneHeader.CaptionStart = 'Start'
        BarZoneHeader.CaptionCenter = 'Center'
        BarZoneHeader.CaptionEnd = 'End'
        BarZoneHeader.Font.Charset = DEFAULT_CHARSET
        BarZoneHeader.Font.Color = clWindowText
        BarZoneHeader.Font.Height = -11
        BarZoneHeader.Font.Name = 'Segoe UI'
        BarZoneHeader.Font.Style = [fsItalic]
        BarItems = <
          item
            Caption = 'Customers'
            UserId = 5001
            Checked = True
            ZoneIndex = 0
            GlyphIndex = 4
            ShowGlyph = False
            ItemKey = 1
          end
          item
            Caption = 'Production'
            UserId = 5002
            ZoneIndex = 1
            GlyphIndex = 5
            ShowGlyph = False
            ItemKey = 2
          end
          item
            Caption = 'Documents'
            UserId = 5003
            ZoneIndex = 2
            GlyphIndex = 6
            ShowGlyph = False
            ItemKey = 3
          end>
        BarCurrentItemIndex = 0
        Align = alTop
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        OnChange = DemoBarChange
        OnItemDragOver = DemoItemDragOver
      end
      object BarDragSelf: TNoReflowTabBar
        Left = 0
        Top = 214
        Width = 1238
        Height = 65
        Hint = ' '
        BarAppearance.TabNormalTop = 13224393
        BarAppearance.TabNormalBottom = 10263708
        BarAppearance.TabNormalText = clBlack
        BarAppearance.TabNormalBorder = 13224393
        BarAppearance.TabHotTop = 9270622
        BarAppearance.TabHotBottom = 7692622
        BarAppearance.TabHotText = clWhite
        BarAppearance.TabHotBorder = 13224393
        BarAppearance.TabSelectedTop = 15461355
        BarAppearance.TabSelectedBottom = 15461355
        BarAppearance.TabSelectedText = 13395456
        BarAppearance.TabSelectedBorder = 13224393
        BarAppearance.TabDisabledTop = 15461355
        BarAppearance.TabDisabledBottom = 15461355
        BarAppearance.TabDisabledText = 9868950
        BarAppearance.TabDisabledBorder = 13224393
        BarAppearance.ButtonNormalTop = clWhitesmoke
        BarAppearance.ButtonNormalBottom = clGainsboro
        BarAppearance.ButtonNormalText = clBlack
        BarAppearance.ButtonNormalBorder = 10526880
        BarAppearance.ButtonHotTop = 16446187
        BarAppearance.ButtonHotBottom = 15785677
        BarAppearance.ButtonHotText = clBlack
        BarAppearance.ButtonHotBorder = 13395456
        BarAppearance.ButtonPressedTop = 14469300
        BarAppearance.ButtonPressedBottom = 16115415
        BarAppearance.ButtonPressedText = clBlack
        BarAppearance.ButtonPressedBorder = 11031552
        BarAppearance.ButtonSelectedTop = 13400576
        BarAppearance.ButtonSelectedBottom = 12084736
        BarAppearance.ButtonSelectedText = clWhite
        BarAppearance.ButtonSelectedBorder = 11031552
        BarAppearance.ButtonDisabledTop = 15461355
        BarAppearance.ButtonDisabledBottom = 14803425
        BarAppearance.ButtonDisabledText = 9868950
        BarAppearance.ButtonDisabledBorder = 12500670
        BarAppearance.ButtonLightEdge = clWhite
        BarAppearance.ButtonShadowEdge = clGray
        BarAppearance.FocusColor = 13395456
        BarPaletteMode = nrtcmStyle
        BarDragReorderMode = nrbrmAllZones
        BarDragInterBarGroup = 'MenuFocusBar'
        BarSignals = <
          item
            Code = 1
            Name = 'Gray'
            FillColor = 11513775
            BorderColor = 8026746
          end
          item
            Code = 2
            Name = 'Green'
            FillColor = 3451449
            BorderColor = 3963199
          end
          item
            Code = 3
            Name = 'Orange'
            FillColor = 2535420
            BorderColor = 3897499
          end
          item
            Code = 4
            Name = 'Red'
            FillColor = 2700006
            BorderColor = 4869522
          end>
        BarLayout.ZoneSpacing = 18
        BarLayout.MarginStart = 12
        BarLayout.MarginEnd = 12
        BarLayoutTabs.ShapeSlantSecond = 32
        BarLayoutTabs.ShapeRadiusFirst = 6
        BarLayoutTabs.ShapeRadiusSecond = 12
        BarLayoutButtons.CornerRadius = 4
        BarImages = FImages
        BarZoneHeader.Visible = True
        BarZoneHeader.CaptionStart = 'Start'
        BarZoneHeader.CaptionCenter = 'Center'
        BarZoneHeader.CaptionEnd = 'End'
        BarZoneHeader.Font.Charset = DEFAULT_CHARSET
        BarZoneHeader.Font.Color = clWindowText
        BarZoneHeader.Font.Height = -11
        BarZoneHeader.Font.Name = 'Segoe UI'
        BarZoneHeader.Font.Style = [fsItalic]
        BarItems = <
          item
            Caption = 'Item 1'
            UserId = 6001
            Checked = True
            Zone = nrtzStart
            ZoneIndex = 0
            GlyphIndex = 0
            ShowGlyph = False
            ItemKey = 1
          end
          item
            Caption = 'Item 2'
            Zone = nrtzStart
            ZoneIndex = 1
            ItemKey = 4
          end
          item
            Caption = 'Item 3'
            ZoneIndex = 0
            ItemKey = 5
          end
          item
            Caption = 'Item 4'
            ZoneIndex = 1
            ItemKey = 6
          end
          item
            Caption = 'Item 5'
            Zone = nrtzEnd
            ZoneIndex = 0
            ItemKey = 7
          end
          item
            Caption = 'Item 6'
            Zone = nrtzEnd
            ZoneIndex = 1
            ItemKey = 8
          end>
        BarCurrentItemIndex = 0
        Align = alTop
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 3
        OnItemDropped = DemoItemDropped
      end
      object MenuFocusPages: TPageControl
        AlignWithMargins = True
        Left = 12
        Top = 651
        Width = 1214
        Height = 91
        Margins.Left = 12
        Margins.Top = 0
        Margins.Right = 12
        Margins.Bottom = 12
        ActivePage = TabCustomerButtons
        Align = alClient
        TabOrder = 4
        object TabCustomerButtons: TTabSheet
          Caption = 'Customers'
          TabVisible = False
          object MenuCustomerBar: TNoReflowTabBar
            Left = 0
            Top = 0
            Width = 1206
            Height = 45
            Hint = ' '
            BarAppearance.TabNormalTop = 13224393
            BarAppearance.TabNormalBottom = 10263708
            BarAppearance.TabNormalText = clBlack
            BarAppearance.TabNormalBorder = 13224393
            BarAppearance.TabHotTop = 9270622
            BarAppearance.TabHotBottom = 7692622
            BarAppearance.TabHotText = clWhite
            BarAppearance.TabHotBorder = 13224393
            BarAppearance.TabSelectedTop = 15461355
            BarAppearance.TabSelectedBottom = 15461355
            BarAppearance.TabSelectedText = 13395456
            BarAppearance.TabSelectedBorder = 13224393
            BarAppearance.TabDisabledTop = 15461355
            BarAppearance.TabDisabledBottom = 15461355
            BarAppearance.TabDisabledText = 9868950
            BarAppearance.TabDisabledBorder = 13224393
            BarAppearance.ButtonNormalTop = clWhitesmoke
            BarAppearance.ButtonNormalBottom = clGainsboro
            BarAppearance.ButtonNormalText = clBlack
            BarAppearance.ButtonNormalBorder = 10526880
            BarAppearance.ButtonHotTop = 16446187
            BarAppearance.ButtonHotBottom = 15785677
            BarAppearance.ButtonHotText = clBlack
            BarAppearance.ButtonHotBorder = 13395456
            BarAppearance.ButtonPressedTop = 14469300
            BarAppearance.ButtonPressedBottom = 16115415
            BarAppearance.ButtonPressedText = clBlack
            BarAppearance.ButtonPressedBorder = 11031552
            BarAppearance.ButtonSelectedTop = 13400576
            BarAppearance.ButtonSelectedBottom = 12084736
            BarAppearance.ButtonSelectedText = clWhite
            BarAppearance.ButtonSelectedBorder = 11031552
            BarAppearance.ButtonDisabledTop = 15461355
            BarAppearance.ButtonDisabledBottom = 14803425
            BarAppearance.ButtonDisabledText = 9868950
            BarAppearance.ButtonDisabledBorder = 12500670
            BarAppearance.ButtonLightEdge = clWhite
            BarAppearance.ButtonShadowEdge = clGray
            BarAppearance.FocusColor = 13395456
            BarMode = nrbmPushButtons
            BarDragReorderMode = nrbrmAllZones
            BarDragInterBarMode = nrtbimSourceAndTarget
            BarDragInterBarGroup = 'DragInterBar'
            BarEditEnabled = True
            BarSignals = <
              item
                Code = 1
                Name = 'Gray'
                FillColor = 11513775
                BorderColor = 8026746
              end
              item
                Code = 2
                Name = 'Green'
                FillColor = 3451449
                BorderColor = 3963199
              end
              item
                Code = 3
                Name = 'Orange'
                FillColor = 2535420
                BorderColor = 3897499
              end
              item
                Code = 4
                Name = 'Red'
                FillColor = 2700006
                BorderColor = 4869522
              end>
            BarImages = FImages
            BarZoneHeader.Font.Charset = DEFAULT_CHARSET
            BarZoneHeader.Font.Color = clWindowText
            BarZoneHeader.Font.Height = -11
            BarZoneHeader.Font.Name = 'Segoe UI'
            BarZoneHeader.Font.Style = [fsItalic]
            BarItems = <
              item
                Caption = 'Customer - Action 1'
                SignalCode = 2
                UserId = 8000
                ZoneIndex = 0
                GlyphIndex = 0
                ItemKey = 1
              end
              item
                Caption = 'Customer - Action 2'
                SignalCode = 3
                UserId = 8001
                ZoneIndex = 1
                GlyphIndex = 1
                ItemKey = 2
              end>
            Align = alTop
            DoubleBuffered = True
            ParentDoubleBuffered = False
            ParentShowHint = False
            ShowHint = True
            TabOrder = 0
            OnItemDropped = DemoItemDropped
          end
        end
        object TabProductionButtons: TTabSheet
          Caption = 'Production'
          TabVisible = False
          object MenuProductionBar: TNoReflowTabBar
            Left = 0
            Top = 0
            Width = 1206
            Height = 45
            Hint = ' '
            BarAppearance.TabNormalTop = 13224393
            BarAppearance.TabNormalBottom = 10263708
            BarAppearance.TabNormalText = clBlack
            BarAppearance.TabNormalBorder = 13224393
            BarAppearance.TabHotTop = 9270622
            BarAppearance.TabHotBottom = 7692622
            BarAppearance.TabHotText = clWhite
            BarAppearance.TabHotBorder = 13224393
            BarAppearance.TabSelectedTop = 15461355
            BarAppearance.TabSelectedBottom = 15461355
            BarAppearance.TabSelectedText = 13395456
            BarAppearance.TabSelectedBorder = 13224393
            BarAppearance.TabDisabledTop = 15461355
            BarAppearance.TabDisabledBottom = 15461355
            BarAppearance.TabDisabledText = 9868950
            BarAppearance.TabDisabledBorder = 13224393
            BarAppearance.ButtonNormalTop = clWhitesmoke
            BarAppearance.ButtonNormalBottom = clGainsboro
            BarAppearance.ButtonNormalText = clBlack
            BarAppearance.ButtonNormalBorder = 10526880
            BarAppearance.ButtonHotTop = 16446187
            BarAppearance.ButtonHotBottom = 15785677
            BarAppearance.ButtonHotText = clBlack
            BarAppearance.ButtonHotBorder = 13395456
            BarAppearance.ButtonPressedTop = 14469300
            BarAppearance.ButtonPressedBottom = 16115415
            BarAppearance.ButtonPressedText = clBlack
            BarAppearance.ButtonPressedBorder = 11031552
            BarAppearance.ButtonSelectedTop = 13400576
            BarAppearance.ButtonSelectedBottom = 12084736
            BarAppearance.ButtonSelectedText = clWhite
            BarAppearance.ButtonSelectedBorder = 11031552
            BarAppearance.ButtonDisabledTop = 15461355
            BarAppearance.ButtonDisabledBottom = 14803425
            BarAppearance.ButtonDisabledText = 9868950
            BarAppearance.ButtonDisabledBorder = 12500670
            BarAppearance.ButtonLightEdge = clWhite
            BarAppearance.ButtonShadowEdge = clGray
            BarAppearance.FocusColor = 13395456
            BarMode = nrbmPushButtons
            BarDragReorderMode = nrbrmAllZones
            BarDragInterBarMode = nrtbimSourceAndTarget
            BarDragInterBarGroup = 'DragInterBar'
            BarEditEnabled = True
            BarSignals = <
              item
                Code = 1
                Name = 'Gray'
                FillColor = 11513775
                BorderColor = 8026746
              end
              item
                Code = 2
                Name = 'Green'
                FillColor = 3451449
                BorderColor = 3963199
              end
              item
                Code = 3
                Name = 'Orange'
                FillColor = 2535420
                BorderColor = 3897499
              end
              item
                Code = 4
                Name = 'Red'
                FillColor = 2700006
                BorderColor = 4869522
              end>
            BarImages = FImages
            BarZoneHeader.Font.Charset = DEFAULT_CHARSET
            BarZoneHeader.Font.Color = clWindowText
            BarZoneHeader.Font.Height = -11
            BarZoneHeader.Font.Name = 'Segoe UI'
            BarZoneHeader.Font.Style = [fsItalic]
            BarItems = <
              item
                Caption = 'Production - Action 1'
                SignalCode = 2
                UserId = 8100
                ZoneIndex = 0
                GlyphIndex = 2
                ItemKey = 1
              end
              item
                Caption = 'Production - Action 2'
                UserId = 8101
                ZoneIndex = 1
                GlyphIndex = 3
                ItemKey = 2
              end>
            Align = alTop
            DoubleBuffered = True
            ParentDoubleBuffered = False
            ParentShowHint = False
            ShowHint = True
            TabOrder = 0
            OnItemDropped = DemoItemDropped
          end
        end
        object TabDocumentButtons: TTabSheet
          Caption = 'Documents'
          TabVisible = False
          object MenuDocumentsBar: TNoReflowTabBar
            Left = 0
            Top = 0
            Width = 1206
            Height = 45
            Hint = ' '
            BarAppearance.TabNormalTop = 13224393
            BarAppearance.TabNormalBottom = 10263708
            BarAppearance.TabNormalText = clBlack
            BarAppearance.TabNormalBorder = 13224393
            BarAppearance.TabHotTop = 9270622
            BarAppearance.TabHotBottom = 7692622
            BarAppearance.TabHotText = clWhite
            BarAppearance.TabHotBorder = 13224393
            BarAppearance.TabSelectedTop = 15461355
            BarAppearance.TabSelectedBottom = 15461355
            BarAppearance.TabSelectedText = 13395456
            BarAppearance.TabSelectedBorder = 13224393
            BarAppearance.TabDisabledTop = 15461355
            BarAppearance.TabDisabledBottom = 15461355
            BarAppearance.TabDisabledText = 9868950
            BarAppearance.TabDisabledBorder = 13224393
            BarAppearance.ButtonNormalTop = clWhitesmoke
            BarAppearance.ButtonNormalBottom = clGainsboro
            BarAppearance.ButtonNormalText = clBlack
            BarAppearance.ButtonNormalBorder = 10526880
            BarAppearance.ButtonHotTop = 16446187
            BarAppearance.ButtonHotBottom = 15785677
            BarAppearance.ButtonHotText = clBlack
            BarAppearance.ButtonHotBorder = 13395456
            BarAppearance.ButtonPressedTop = 14469300
            BarAppearance.ButtonPressedBottom = 16115415
            BarAppearance.ButtonPressedText = clBlack
            BarAppearance.ButtonPressedBorder = 11031552
            BarAppearance.ButtonSelectedTop = 13400576
            BarAppearance.ButtonSelectedBottom = 12084736
            BarAppearance.ButtonSelectedText = clWhite
            BarAppearance.ButtonSelectedBorder = 11031552
            BarAppearance.ButtonDisabledTop = 15461355
            BarAppearance.ButtonDisabledBottom = 14803425
            BarAppearance.ButtonDisabledText = 9868950
            BarAppearance.ButtonDisabledBorder = 12500670
            BarAppearance.ButtonLightEdge = clWhite
            BarAppearance.ButtonShadowEdge = clGray
            BarAppearance.FocusColor = 13395456
            BarMode = nrbmPushButtons
            BarDragReorderMode = nrbrmAllZones
            BarDragInterBarMode = nrtbimSourceAndTarget
            BarDragInterBarGroup = 'DragInterBar'
            BarEditEnabled = True
            BarSignals = <
              item
                Code = 1
                Name = 'Gray'
                FillColor = 11513775
                BorderColor = 8026746
              end
              item
                Code = 2
                Name = 'Green'
                FillColor = 3451449
                BorderColor = 3963199
              end
              item
                Code = 3
                Name = 'Orange'
                FillColor = 2535420
                BorderColor = 3897499
              end
              item
                Code = 4
                Name = 'Red'
                FillColor = 2700006
                BorderColor = 4869522
              end>
            BarImages = FImages
            BarZoneHeader.Font.Charset = DEFAULT_CHARSET
            BarZoneHeader.Font.Color = clWindowText
            BarZoneHeader.Font.Height = -11
            BarZoneHeader.Font.Name = 'Segoe UI'
            BarZoneHeader.Font.Style = [fsItalic]
            BarItems = <
              item
                Caption = 'Documents - Action 1'
                SignalCode = 1
                UserId = 8200
                ZoneIndex = 0
                GlyphIndex = 6
                ItemKey = 1
              end
              item
                Caption = 'Documents - Action 2'
                UserId = 8201
                ZoneIndex = 1
                GlyphIndex = 7
                ItemKey = 2
              end>
            Align = alTop
            DoubleBuffered = True
            ParentDoubleBuffered = False
            ParentShowHint = False
            ShowHint = True
            TabOrder = 0
            OnItemDropped = DemoItemDropped
          end
        end
      end
      object Panel1: TPanel
        AlignWithMargins = True
        Left = 0
        Top = 112
        Width = 1238
        Height = 102
        Margins.Left = 0
        Margins.Top = 12
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alTop
        BevelEdges = [beTop]
        BevelKind = bkSoft
        BevelOuter = bvNone
        TabOrder = 5
        object Label1: TLabel
          Left = 15
          Top = 8
          Width = 244
          Height = 20
          Caption = 'Drag and drop within the same bar'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object RgDragZones: TRadioGroup
          Left = 28
          Top = 36
          Width = 306
          Height = 56
          Caption = 'Between Zones'
          Columns = 3
          ItemIndex = 2
          Items.Strings = (
            'None'
            'Same zone'
            'All zones')
          TabOrder = 0
          OnClick = DragZonesOptionsClick
        end
        object GroupBox1: TGroupBox
          Left = 342
          Top = 36
          Width = 263
          Height = 55
          Caption = 'Authorized zones'
          TabOrder = 1
          object ChkDragStart: TCheckBox
            Left = 15
            Top = 28
            Width = 97
            Height = 17
            Caption = 'Start'
            Checked = True
            State = cbChecked
            TabOrder = 0
            OnClick = DragZonesOptionsClick
          end
          object ChkDragCenter: TCheckBox
            Left = 91
            Top = 28
            Width = 97
            Height = 17
            Caption = 'Center'
            Checked = True
            State = cbChecked
            TabOrder = 1
            OnClick = DragZonesOptionsClick
          end
          object ChkDragEnd: TCheckBox
            Left = 185
            Top = 28
            Width = 97
            Height = 17
            Caption = 'End'
            Checked = True
            State = cbChecked
            TabOrder = 2
            OnClick = DragZonesOptionsClick
          end
        end
      end
      object Panel2: TPanel
        AlignWithMargins = True
        Left = 0
        Top = 309
        Width = 1238
        Height = 104
        Margins.Left = 0
        Margins.Top = 30
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alTop
        BevelEdges = [beTop]
        BevelKind = bkSoft
        BevelOuter = bvNone
        TabOrder = 6
        object Label2: TLabel
          Left = 15
          Top = 8
          Width = 265
          Height = 20
          Caption = 'Drag and drop between multiple bars.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object Label4: TLabel
          Left = 34
          Top = 36
          Width = 507
          Height = 60
          Caption = 
            '- All bars must have the BarDragInterBarGroup property with the ' +
            'same value.'#13#10'- Source bars, receiving bars, or both'#13#10'- Zone-base' +
            'd limitation'
        end
      end
      object Panel3: TPanel
        AlignWithMargins = True
        Left = 0
        Top = 573
        Width = 1238
        Height = 39
        Margins.Left = 0
        Margins.Top = 30
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alTop
        BevelEdges = [beTop]
        BevelKind = bkSoft
        BevelOuter = bvNone
        TabOrder = 7
        object Label3: TLabel
          Left = 15
          Top = 8
          Width = 729
          Height = 20
          Caption = 
            'Drag and drop between bars present on different pages, activated' +
            ' by hovering over items in another bar'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -15
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
      end
      object DragBar2: TNoReflowTabBar
        Left = 0
        Top = 478
        Width = 1238
        Height = 65
        Hint = ' '
        BarAppearance.TabNormalTop = 13224393
        BarAppearance.TabNormalBottom = 10263708
        BarAppearance.TabNormalText = clBlack
        BarAppearance.TabNormalBorder = 13224393
        BarAppearance.TabHotTop = 9270622
        BarAppearance.TabHotBottom = 7692622
        BarAppearance.TabHotText = clWhite
        BarAppearance.TabHotBorder = 13224393
        BarAppearance.TabSelectedTop = 15461355
        BarAppearance.TabSelectedBottom = 15461355
        BarAppearance.TabSelectedText = 13395456
        BarAppearance.TabSelectedBorder = 13224393
        BarAppearance.TabDisabledTop = 15461355
        BarAppearance.TabDisabledBottom = 15461355
        BarAppearance.TabDisabledText = 9868950
        BarAppearance.TabDisabledBorder = 13224393
        BarAppearance.ButtonNormalTop = clWhitesmoke
        BarAppearance.ButtonNormalBottom = clGainsboro
        BarAppearance.ButtonNormalText = clBlack
        BarAppearance.ButtonNormalBorder = 10526880
        BarAppearance.ButtonHotTop = 16446187
        BarAppearance.ButtonHotBottom = 15785677
        BarAppearance.ButtonHotText = clBlack
        BarAppearance.ButtonHotBorder = 13395456
        BarAppearance.ButtonPressedTop = 14469300
        BarAppearance.ButtonPressedBottom = 16115415
        BarAppearance.ButtonPressedText = clBlack
        BarAppearance.ButtonPressedBorder = 11031552
        BarAppearance.ButtonSelectedTop = 13400576
        BarAppearance.ButtonSelectedBottom = 12084736
        BarAppearance.ButtonSelectedText = clWhite
        BarAppearance.ButtonSelectedBorder = 11031552
        BarAppearance.ButtonDisabledTop = 15461355
        BarAppearance.ButtonDisabledBottom = 14803425
        BarAppearance.ButtonDisabledText = 9868950
        BarAppearance.ButtonDisabledBorder = 12500670
        BarAppearance.ButtonLightEdge = clWhite
        BarAppearance.ButtonShadowEdge = clGray
        BarAppearance.FocusColor = 13395456
        BarPaletteMode = nrtcmStyle
        BarDragReorderMode = nrbrmAllZones
        BarDragInterBarMode = nrtbimSourceAndTarget
        BarDragInterBarGroup = 'DragMultiBar'
        BarSignals = <
          item
            Code = 1
            Name = 'Gray'
            FillColor = 11513775
            BorderColor = 8026746
          end
          item
            Code = 2
            Name = 'Green'
            FillColor = 3451449
            BorderColor = 3963199
          end
          item
            Code = 3
            Name = 'Orange'
            FillColor = 2535420
            BorderColor = 3897499
          end
          item
            Code = 4
            Name = 'Red'
            FillColor = 2700006
            BorderColor = 4869522
          end>
        BarLayout.ZoneSpacing = 18
        BarLayout.MarginStart = 12
        BarLayout.MarginEnd = 12
        BarLayoutTabs.ShapeSlantSecond = 32
        BarLayoutTabs.ShapeRadiusFirst = 6
        BarLayoutTabs.ShapeRadiusSecond = 12
        BarLayoutButtons.CornerRadius = 4
        BarImages = FImages
        BarZoneHeader.Visible = True
        BarZoneHeader.CaptionStart = 'Start'
        BarZoneHeader.CaptionCenter = 'Center'
        BarZoneHeader.CaptionEnd = 'End'
        BarZoneHeader.Font.Charset = DEFAULT_CHARSET
        BarZoneHeader.Font.Color = clWindowText
        BarZoneHeader.Font.Height = -11
        BarZoneHeader.Font.Name = 'Segoe UI'
        BarZoneHeader.Font.Style = [fsItalic]
        BarItems = <
          item
            Caption = 'Bar 2 - Item 1'
            UserId = 5001
            Checked = True
            Zone = nrtzStart
            ZoneIndex = 0
            GlyphIndex = 4
            ShowGlyph = False
            ItemKey = 1
          end
          item
            Caption = 'Bar 2 - Item 2'
            UserId = 5002
            ZoneIndex = 0
            GlyphIndex = 5
            ShowGlyph = False
            ItemKey = 2
          end
          item
            Caption = 'Bar 2 - Item 3'
            UserId = 5003
            Zone = nrtzEnd
            ZoneIndex = 0
            GlyphIndex = 6
            ShowGlyph = False
            ItemKey = 3
          end>
        BarCurrentItemIndex = 0
        Align = alTop
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 8
        OnItemDropped = DemoItemDropped
      end
    end
    object CardPersistence: TCard
      Left = 1
      Top = 1
      Width = 1238
      Height = 754
      Caption = 'Persistence'
      CardIndex = 6
      TabOrder = 6
      object LabelTopPersistence: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 3
        Width = 1214
        Height = 52
        Margins.Left = 12
        Margins.Right = 12
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 
          'Persistence: save the current bar state in memory, restore it, o' +
          'r reset to the initial DFM state.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        WordWrap = True
        StyleElements = [seClient, seBorder]
      end
      object TopPanelPersistence: TPanel
        Left = 0
        Top = 58
        Width = 1238
        Height = 50
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object BtnSaveLocalState: TButton
          Left = 12
          Top = 12
          Width = 140
          Height = 30
          Caption = 'Save local state'
          TabOrder = 1
          OnClick = BtnSaveLocalStateClick
        end
        object BtnLoadLocalState: TButton
          Left = 160
          Top = 12
          Width = 140
          Height = 30
          Caption = 'Load local state'
          TabOrder = 2
          OnClick = BtnLoadLocalStateClick
        end
        object BtnResetPersistence: TButton
          Left = 308
          Top = 12
          Width = 140
          Height = 30
          Caption = 'Reset items'
          TabOrder = 0
          OnClick = BtnResetPersistenceClick
        end
      end
      object PersistenceBar: TNoReflowTabBar
        Left = 0
        Top = 108
        Width = 1238
        Height = 143
        Hint = ' '
        BarAppearance.TabNormalTop = 13224393
        BarAppearance.TabNormalBottom = 10263708
        BarAppearance.TabNormalText = clBlack
        BarAppearance.TabNormalBorder = 13224393
        BarAppearance.TabHotTop = 9270622
        BarAppearance.TabHotBottom = 7692622
        BarAppearance.TabHotText = clWhite
        BarAppearance.TabHotBorder = 13224393
        BarAppearance.TabSelectedTop = 15461355
        BarAppearance.TabSelectedBottom = 15461355
        BarAppearance.TabSelectedText = 13395456
        BarAppearance.TabSelectedBorder = 13224393
        BarAppearance.TabDisabledTop = 15461355
        BarAppearance.TabDisabledBottom = 15461355
        BarAppearance.TabDisabledText = 9868950
        BarAppearance.TabDisabledBorder = 13224393
        BarAppearance.ButtonNormalTop = clWhitesmoke
        BarAppearance.ButtonNormalBottom = clGainsboro
        BarAppearance.ButtonNormalText = clBlack
        BarAppearance.ButtonNormalBorder = 10526880
        BarAppearance.ButtonHotTop = 16446187
        BarAppearance.ButtonHotBottom = 15785677
        BarAppearance.ButtonHotText = clBlack
        BarAppearance.ButtonHotBorder = 13395456
        BarAppearance.ButtonPressedTop = 14469300
        BarAppearance.ButtonPressedBottom = 16115415
        BarAppearance.ButtonPressedText = clBlack
        BarAppearance.ButtonPressedBorder = 11031552
        BarAppearance.ButtonSelectedTop = 13400576
        BarAppearance.ButtonSelectedBottom = 12084736
        BarAppearance.ButtonSelectedText = clWhite
        BarAppearance.ButtonSelectedBorder = 11031552
        BarAppearance.ButtonDisabledTop = 15461355
        BarAppearance.ButtonDisabledBottom = 14803425
        BarAppearance.ButtonDisabledText = 9868950
        BarAppearance.ButtonDisabledBorder = 12500670
        BarAppearance.ButtonLightEdge = clWhite
        BarAppearance.ButtonShadowEdge = clGray
        BarAppearance.FocusColor = 13395456
        BarPaletteMode = nrtcmStyle
        BarDragReorderMode = nrbrmAllZones
        BarEditEnabled = True
        BarSignals = <
          item
            Code = 1
            Name = 'Gray'
            FillColor = 11513775
            BorderColor = 8026746
          end
          item
            Code = 2
            Name = 'Green'
            FillColor = 3451449
            BorderColor = 3963199
          end
          item
            Code = 3
            Name = 'Orange'
            FillColor = 2535420
            BorderColor = 3897499
          end
          item
            Code = 4
            Name = 'Red'
            FillColor = 2700006
            BorderColor = 4869522
          end>
        BarLayout.ZoneSpacing = 18
        BarLayout.MarginStart = 12
        BarLayout.MarginEnd = 12
        BarLayoutTabs.ShapeSlantSecond = 32
        BarLayoutButtons.CornerRadius = 4
        BarImages = FImages
        BarZoneHeader.Visible = True
        BarZoneHeader.CaptionStart = 'Technical Data'
        BarZoneHeader.CaptionCenter = 'Manufacturing Stations'
        BarZoneHeader.CaptionEnd = 'Files'
        BarZoneHeader.Font.Charset = DEFAULT_CHARSET
        BarZoneHeader.Font.Color = clWindowText
        BarZoneHeader.Font.Height = -11
        BarZoneHeader.Font.Name = 'Segoe UI'
        BarZoneHeader.Font.Style = [fsItalic]
        BarItems = <
          item
            Caption = 'Property'
            SignalCode = 2
            UserId = 1001
            Checked = True
            Zone = nrtzStart
            ZoneIndex = 0
            GlyphIndex = 0
            ItemKey = 1
          end
          item
            Caption = 'Formulas'
            SignalCode = 1
            UserId = 1002
            Zone = nrtzStart
            ZoneIndex = 1
            GlyphIndex = 1
            ItemKey = 2
          end
          item
            Caption = 'Material Preparation'
            SignalCode = 1
            UserId = 2001
            ZoneIndex = 0
            GlyphIndex = 2
            ItemKey = 3
          end
          item
            Caption = 'Cutting'
            SignalCode = 3
            UserId = 2002
            ZoneIndex = 1
            GlyphIndex = 3
            ItemKey = 4
          end
          item
            Caption = 'Assembly Preparation'
            SignalCode = 2
            UserId = 2003
            ZoneIndex = 2
            GlyphIndex = 4
            ItemKey = 5
          end
          item
            Caption = 'Assembly'
            SignalCode = 1
            UserId = 2004
            ZoneIndex = 3
            GlyphIndex = 4
            ItemKey = 6
          end
          item
            Caption = 'Fittings Preparation'
            SignalCode = 3
            UserId = 2005
            ZoneIndex = 4
            GlyphIndex = 5
            ItemKey = 7
          end
          item
            Caption = 'Fittings'
            SignalCode = 2
            UserId = 2006
            ZoneIndex = 5
            GlyphIndex = 5
            ItemKey = 8
          end
          item
            Caption = 'Subcontracting Drawings'
            SignalCode = 3
            UserId = 3001
            Zone = nrtzEnd
            ZoneIndex = 0
            GlyphIndex = 6
            ItemKey = 9
          end
          item
            Caption = 'CAD Files'
            SignalCode = 2
            UserId = 3002
            Zone = nrtzEnd
            ZoneIndex = 1
            GlyphIndex = 7
            ItemKey = 10
          end>
        BarCurrentItemIndex = 0
        Align = alTop
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
      end
    end
    object CardInlineEdition: TCard
      Left = 1
      Top = 1
      Width = 1238
      Height = 754
      Caption = 'InlineEdition'
      CardIndex = 7
      TabOrder = 7
      object LabelTopEditing: TLabel
        AlignWithMargins = True
        Left = 12
        Top = 3
        Width = 1214
        Height = 52
        Margins.Left = 12
        Margins.Right = 12
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 
          'Inline editing: enable editing, then double-click an item captio' +
          'n. The item named Locked is refused by validation.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clHighlight
        Font.Height = -16
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        WordWrap = True
        StyleElements = [seClient, seBorder]
      end
      object TopPanelEditing: TPanel
        Left = 0
        Top = 58
        Width = 1238
        Height = 50
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object ChkAllowEdit: TCheckBox
          Left = 12
          Top = 16
          Width = 260
          Height = 24
          Caption = 'Allow inline caption editing'
          Checked = True
          State = cbChecked
          TabOrder = 1
          OnClick = EditingOptionClick
        end
        object BtnResetEditing: TButton
          Left = 300
          Top = 12
          Width = 140
          Height = 30
          Caption = 'Reset items'
          TabOrder = 0
          OnClick = BtnResetEditingClick
        end
      end
      object EditingBar: TNoReflowTabBar
        Left = 0
        Top = 108
        Width = 1238
        Height = 65
        Hint = ' '
        BarAppearance.TabNormalTop = 13224393
        BarAppearance.TabNormalBottom = 10263708
        BarAppearance.TabNormalText = clBlack
        BarAppearance.TabNormalBorder = 13224393
        BarAppearance.TabHotTop = 9270622
        BarAppearance.TabHotBottom = 7692622
        BarAppearance.TabHotText = clWhite
        BarAppearance.TabHotBorder = 13224393
        BarAppearance.TabSelectedTop = 15461355
        BarAppearance.TabSelectedBottom = 15461355
        BarAppearance.TabSelectedText = 13395456
        BarAppearance.TabSelectedBorder = 13224393
        BarAppearance.TabDisabledTop = 15461355
        BarAppearance.TabDisabledBottom = 15461355
        BarAppearance.TabDisabledText = 9868950
        BarAppearance.TabDisabledBorder = 13224393
        BarAppearance.ButtonNormalTop = clWhitesmoke
        BarAppearance.ButtonNormalBottom = clGainsboro
        BarAppearance.ButtonNormalText = clBlack
        BarAppearance.ButtonNormalBorder = 10526880
        BarAppearance.ButtonHotTop = 16446187
        BarAppearance.ButtonHotBottom = 15785677
        BarAppearance.ButtonHotText = clBlack
        BarAppearance.ButtonHotBorder = 13395456
        BarAppearance.ButtonPressedTop = 14469300
        BarAppearance.ButtonPressedBottom = 16115415
        BarAppearance.ButtonPressedText = clBlack
        BarAppearance.ButtonPressedBorder = 11031552
        BarAppearance.ButtonSelectedTop = 13400576
        BarAppearance.ButtonSelectedBottom = 12084736
        BarAppearance.ButtonSelectedText = clWhite
        BarAppearance.ButtonSelectedBorder = 11031552
        BarAppearance.ButtonDisabledTop = 15461355
        BarAppearance.ButtonDisabledBottom = 14803425
        BarAppearance.ButtonDisabledText = 9868950
        BarAppearance.ButtonDisabledBorder = 12500670
        BarAppearance.ButtonLightEdge = clWhite
        BarAppearance.ButtonShadowEdge = clGray
        BarAppearance.FocusColor = 13395456
        BarPaletteMode = nrtcmStyle
        BarEditEnabled = True
        BarSignals = <
          item
            Code = 1
            Name = 'Gray'
            FillColor = 11513775
            BorderColor = 8026746
          end
          item
            Code = 2
            Name = 'Green'
            FillColor = 3451449
            BorderColor = 3963199
          end
          item
            Code = 3
            Name = 'Orange'
            FillColor = 2535420
            BorderColor = 3897499
          end
          item
            Code = 4
            Name = 'Red'
            FillColor = 2700006
            BorderColor = 4869522
          end>
        BarLayout.ZoneSpacing = 18
        BarLayout.MarginStart = 12
        BarLayout.MarginEnd = 12
        BarLayoutTabs.ShapeSlantSecond = 32
        BarLayoutButtons.CornerRadius = 4
        BarImages = FImages
        BarZoneHeader.Visible = True
        BarZoneHeader.CaptionStart = 'Technical Data'
        BarZoneHeader.CaptionCenter = 'Manufacturing Stations'
        BarZoneHeader.CaptionEnd = 'Files'
        BarZoneHeader.Font.Charset = DEFAULT_CHARSET
        BarZoneHeader.Font.Color = clWindowText
        BarZoneHeader.Font.Height = -11
        BarZoneHeader.Font.Name = 'Segoe UI'
        BarZoneHeader.Font.Style = [fsItalic]
        BarItems = <
          item
            Caption = 'Editable'
            SignalCode = 2
            UserId = 7001
            Checked = True
            Zone = nrtzStart
            ZoneIndex = 0
            GlyphIndex = 0
            ItemKey = 1
          end
          item
            Caption = 'Double click me'
            SignalCode = 3
            UserId = 7002
            ZoneIndex = 0
            GlyphIndex = 1
            ItemKey = 2
          end
          item
            Caption = 'Locked'
            SignalCode = 4
            UserId = 7003
            ZoneIndex = 1
            GlyphIndex = 2
            ItemKey = 3
          end
          item
            Caption = 'Also editable'
            UserId = 7004
            Zone = nrtzEnd
            ZoneIndex = 0
            GlyphIndex = 3
            ItemKey = 4
          end>
        BarCurrentItemIndex = 0
        Align = alTop
        DoubleBuffered = True
        ParentDoubleBuffered = False
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnCanEditItemCaption = DemoCanEditItemCaption
        OnValidateItemCaption = DemoValidateItemCaption
        OnItemCaptionEdited = DemoItemCaptionEdited
      end
    end
  end
  object MainBar: TNoReflowTabBar
    Left = 0
    Top = 0
    Width = 1240
    Height = 45
    Hint = ' '
    BarAppearance.TabNormalTop = 13224393
    BarAppearance.TabNormalBottom = 10263708
    BarAppearance.TabNormalText = clBlack
    BarAppearance.TabNormalBorder = 13224393
    BarAppearance.TabHotTop = 9270622
    BarAppearance.TabHotBottom = 7692622
    BarAppearance.TabHotText = clWhite
    BarAppearance.TabHotBorder = 13224393
    BarAppearance.TabSelectedTop = 15461355
    BarAppearance.TabSelectedBottom = 15461355
    BarAppearance.TabSelectedText = 13395456
    BarAppearance.TabSelectedBorder = 13224393
    BarAppearance.TabDisabledTop = 15461355
    BarAppearance.TabDisabledBottom = 15461355
    BarAppearance.TabDisabledText = 9868950
    BarAppearance.TabDisabledBorder = 13224393
    BarAppearance.ButtonNormalTop = clWhitesmoke
    BarAppearance.ButtonNormalBottom = clGainsboro
    BarAppearance.ButtonNormalText = clBlack
    BarAppearance.ButtonNormalBorder = 10526880
    BarAppearance.ButtonHotTop = 16446187
    BarAppearance.ButtonHotBottom = 15785677
    BarAppearance.ButtonHotText = clBlack
    BarAppearance.ButtonHotBorder = 13395456
    BarAppearance.ButtonPressedTop = 14469300
    BarAppearance.ButtonPressedBottom = 16115415
    BarAppearance.ButtonPressedText = clBlack
    BarAppearance.ButtonPressedBorder = 11031552
    BarAppearance.ButtonSelectedTop = 13400576
    BarAppearance.ButtonSelectedBottom = 12084736
    BarAppearance.ButtonSelectedText = clWhite
    BarAppearance.ButtonSelectedBorder = 11031552
    BarAppearance.ButtonDisabledTop = 15461355
    BarAppearance.ButtonDisabledBottom = 14803425
    BarAppearance.ButtonDisabledText = 9868950
    BarAppearance.ButtonDisabledBorder = 12500670
    BarAppearance.ButtonLightEdge = clWhite
    BarAppearance.ButtonShadowEdge = clGray
    BarAppearance.FocusColor = 13395456
    BarPaletteMode = nrtcmStyle
    BarSignals = <
      item
        Code = 1
        Name = 'Gray'
        FillColor = 11513775
        BorderColor = 8026746
      end
      item
        Code = 2
        Name = 'Green'
        FillColor = 3451449
        BorderColor = 3963199
      end
      item
        Code = 3
        Name = 'Orange'
        FillColor = 2535420
        BorderColor = 3897499
      end
      item
        Code = 4
        Name = 'Red'
        FillColor = 2700006
        BorderColor = 4869522
      end>
    BarLayout.MarginStart = 6
    BarLayout.MarginFirstRow = 12
    BarLayoutTabs.ShapeRadiusSecond = 6
    BarZoneHeader.Font.Charset = DEFAULT_CHARSET
    BarZoneHeader.Font.Color = clWindowText
    BarZoneHeader.Font.Height = -11
    BarZoneHeader.Font.Name = 'Segoe UI'
    BarZoneHeader.Font.Style = [fsItalic]
    BarItems = <
      item
        Caption = 'OverView'
        Checked = True
        ZoneIndex = 0
        ItemKey = 1
      end
      item
        Caption = 'Layout and zones'
        ZoneIndex = 1
        ItemKey = 2
      end
      item
        Caption = 'Signals'
        ZoneIndex = 2
        ItemKey = 3
      end
      item
        Caption = 'Events'
        ZoneIndex = 3
        ItemKey = 4
      end
      item
        Caption = 'Button modes'
        ZoneIndex = 4
        ItemKey = 5
      end
      item
        Caption = 'Drag and drop'
        ZoneIndex = 5
        ItemKey = 6
      end
      item
        Caption = 'Persistence'
        ZoneIndex = 6
        ItemKey = 7
      end
      item
        Caption = 'Inline Editing'
        ZoneIndex = 7
        ItemKey = 8
      end>
    BarCurrentItemIndex = 0
    Align = alTop
    DoubleBuffered = True
    ParentDoubleBuffered = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    OnChange = MainBarChange
  end
  object FImages: TImageList
    Left = 842
    Top = 102
    Bitmap = {
      494C010108001800040010001000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000003000000001002000000000000030
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      800080808000808080000000000000000000000000008080800096963C009696
      3C0096963C0096963C0096963C0096963C0096963C0096963C0096963C009696
      3C0096963C0096963C0080808000000000000000000080808000555596005555
      9600555596005555960055559600555596005555960055559600555596005555
      96005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A005A785A005A785A005A785A005A785A005A785A005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      8200828282008282820082828200828282008282820082828200828282008282
      820082828200828282008080800000000000000000008080800096963C009696
      3C0096963C0096963C0096963C0096963C0096963C0096963C0096963C009696
      3C0096963C0096963C0080808000000000000000000080808000555596005555
      9600555596005555960055559600555596005555960055559600555596005555
      96005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A005A785A005A785A005A785A005A785A005A785A005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      8200828282008282820082828200828282008282820082828200828282008282
      820082828200828282008080800000000000000000008080800096963C009696
      3C00A8963C00FFEEA400BADDFF0096963C00A8963C00FFEEA400CCEEFF009696
      610096963C0096963C0080808000000000000000000080808000555596005555
      960055559600AF749600FFFFEE00FFFFFF00FFFFFF00CAFFFF005555BA005555
      96005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A00E6BE7800FFFFFF00FFFFFF00CBFFFF005A7895005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      820099828200FFEBC300D7FFFF008282AE00AE828200FFFFD700C3EBFF008282
      990082828200828282008080800000000000000000008080800096963C009696
      3C0096963C00EECC6100DDFFFF0096968300BA963C00FFFFC300A8CCE1009696
      3C0096963C0096963C0080808000000000000000000080808000555596005555
      960055559600AF749600E5FFEE005574CC0055559600FFCABA00CAFFFF005555
      BA005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A005A785A005A785A0078785A00FFEAB10078BEE6005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      820082828200AE828200FFFFD70099C3EB00EBC39900EBFFFF008299C3008282
      820082828200828282008080800000000000000000008080800096963C009696
      3C0096963C00CCA83C00FFFFE100FFFFFF00FFFFFF00EEFFFF0096A8A4009696
      3C0096963C0096963C0080808000000000000000000080808000555596005555
      960055559600AF749600E5FFEE005574CC005555960091559600FFFFDD005591
      DD005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A005A785A005A785A00B1905A00FFFFE60078BEE6005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      82008282820082828200EBC39900EBFFFF00FFEBEB0099C3EB00828282008282
      820082828200828282008080800000000000000000008080800096963C009696
      3C0096963C00A8963C00FFEEA400A8CCE100EECC6100CCEEFF00969661009696
      3C0096963C0096963C0080808000000000000000000080808000555596005555
      960055559600AF749600E5FFEE005574CC005555960091559600FFFFDD0074AF
      EE005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A0095785A00FFFFCB00FFFFFF00CBFFFF005A7895005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      8200828282008282820099828200FFEBC300D7FFFF008282AE00828282008282
      820082828200828282008080800000000000000000008080800096963C009696
      3C0096963C0096963C00EECC6100BADDFF00FFDD8300A8CCE10096963C009696
      3C0096963C0096963C0080808000000000000000000080808000555596005555
      960055559600AF749600E5FFEE005574CC005555960091559600FFFFDD005591
      DD005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A00FFD49500E6FFFF005A90B1005A785A005A785A005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      82008282820082828200EBC39900EBFFFF00FFEBEB0099C3EB00828282008282
      820082828200828282008080800000000000000000008080800096963C009696
      3C0096963C0096963C00CCA83C00FFFFE100FFFFFF0096BAC30096963C009696
      3C0096963C0096963C0080808000000000000000000080808000555596005555
      960055559600AF749600E5FFEE005574CC0055559600FFCABA00CAFFFF005555
      BA005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A00FFD49500B1EAFF005A7878005A785A005A785A005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      820082828200AE828200FFFFD700AED7FF00EBC39900D7FFFF008282AE008282
      820082828200828282008080800000000000000000008080800096963C009696
      3C0096963C0096963C00BA963C00FFFFC300DDFFFF009696830096963C009696
      3C0096963C0096963C0080808000000000000000000080808000555596005555
      960055559600AF749600FFFFEE00FFFFFF00FFFFFF00E5FFFF005574CC005555
      96005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A0095785A00FFFFCB00FFFFFF00FFFFFF005AA8CB005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      820082828200FFD7AE00EBFFFF008299C300AE828200FFFFD700AED7FF008282
      820082828200828282008080800000000000000000008080800096963C009696
      3C0096963C0096963C0096963C0096963C0096963C0096963C0096963C009696
      3C0096963C0096963C0080808000000000000000000080808000555596005555
      9600555596005555960055559600555596005555960055559600555596005555
      96005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A005A785A005A785A005A785A005A785A005A785A005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      8200828282008282820082828200828282008282820082828200828282008282
      820082828200828282008080800000000000000000008080800096963C009696
      3C0096963C0096963C0096963C0096963C0096963C0096963C0096963C009696
      3C0096963C0096963C0080808000000000000000000080808000555596005555
      9600555596005555960055559600555596005555960055559600555596005555
      96005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A005A785A005A785A005A785A005A785A005A785A005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      8200828282008282820082828200828282008282820082828200828282008282
      820082828200828282008080800000000000000000008080800096963C009696
      3C0096963C0096963C0096963C0096963C0096963C0096963C0096963C009696
      3C0096963C0096963C0080808000000000000000000080808000555596005555
      9600555596005555960055559600555596005555960055559600555596005555
      96005555960055559600808080000000000000000000808080005A785A005A78
      5A005A785A005A785A005A785A005A785A005A785A005A785A005A785A005A78
      5A005A785A005A785A0080808000000000000000000080808000828282008282
      8200828282008282820082828200828282008282820082828200828282008282
      8200828282008282820080808000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000080808000B4824600B482
      4600B4824600B4824600B4824600B4824600B4824600B4824600B4824600B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A
      4C002A9A4C002A9A4C00808080000000000000000000808080002378C8002378
      C8002378C8002378C8002378C8002378C8002378C8002378C8002378C8002378
      C8002378C8002378C80080808000000000000000000080808000B4824600B482
      4600B4824600B4824600B4824600B4824600B4824600B4824600B4824600B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A
      4C002A9A4C002A9A4C00808080000000000000000000808080002378C8002378
      C8002378C8002378C8002378C8002378C8002378C8002378C8002378C8002378
      C8002378C8002378C80080808000000000000000000080808000B4824600B482
      4600B4824600DB994600FFFFE200B4AEC600B4824600B4824600B4824600B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800D5787800F2FFEA00AA78BE00AA5A7800AA5A7800AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C009DAB4C00DFFFE3002AABAB00BFBD4C00FFFFFF002ABDC8009DAB
      4C00DFFFE3002AABAB00808080000000000000000000808080002378C8002378
      C8002378C8002378C8009B90C800FFFFF600FFFFFF00FFFFFF0076D4FF002378
      C8002378C8002378C80080808000000000000000000080808000B4824600B482
      4600B4824600DB994600FFFFE200B4AEC600B4824600B4824600B4824600B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800D5787800F2FFEA00AA78BE00AA5A7800AA5A7800AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C009DAB4C00DFFFE3002AABAB00DFCE6E00FFFFFF0054CEE3009DAB
      4C00DFFFE3002AABAB00808080000000000000000000808080002378C8002378
      C8002378C8009B90C800FFFFF60050BEF6002378C8002378C8002378C8002378
      C8002378C8002378C80080808000000000000000000080808000B4824600B482
      4600B4824600DB994600FFFFE200B4AEC600B4824600B4824600B4824600B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800D5787800F2FFEA00AA78BE00AA5A7800AA5A7800AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C009DAB4C00DFFFE30054ABAB00FFEFAB00DFEFE3009DEFFF009DAB
      6E00DFFFE3002AABAB00808080000000000000000000808080002378C8002378
      C8002378C800DEBED2009BEAFF002478D2002378C8002378C8002378C8002378
      C8002378C8002378C80080808000000000000000000080808000B4824600B482
      4600B4824600DB994600FFFFE200FFFFFF00FFFFFF00DBEBFF00B4826900B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800D5787800FFFFEA00FFFFFF00FFFFFF00B9B1EA00AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C009DAB4C00DFFFE3009DBDAB00DFFFE30079ABAB00DFFFC8009DBD
      AB00DFFFE3002AABAB00808080000000000000000000808080002378C8002378
      C8002378C800FFD4DB009BEAFF002478D2002378C8002378C8002378C8002378
      C8002378C8002378C80080808000000000000000000080808000B4824600B482
      4600B4824600DB994600FFFFE200B4AEC600C1824600FFEBA800C1C3E200B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800D5787800F2FFEA00AA78BE00AA5A7800AA5A7800AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C009DAB4C00DFFFE300DFDEC8009DEFFF002A9A6E00FFDE8D00BFDE
      E300DFFFE3002AABAB00808080000000000000000000808080002378C8002378
      C8002378C800DEBED2009BEAFF002478D2002378C8002378C8002378C8002378
      C8002378C8002378C80080808000000000000000000080808000B4824600B482
      4600B4824600DB994600FFFFE200B4AEC600C1824600FFEBA800C1C3E200B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800D5787800F2FFEA00AA78BE00AA5A7800AA5A7800AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C009DAB4C00FFFFE300FFFFFF0054CEE3002A9A4C00BFBD4C00FFFF
      FF00DFFFFF002AABAB00808080000000000000000000808080002378C8002378
      C8002378C8007678C800FFFFED0050BEF6002378C8002378C8002378C8002378
      C8002378C8002378C80080808000000000000000000080808000B4824600B482
      4600B4824600DB994600FFFFE200FFFFFF00FFFFFF00E7FFFF00B4828900B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800D5787800FFFFEA00FFFFFF00FFFFFF00C8CBFF00AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C009DAB4C00FFFFE300DFFFFF002AABAB002A9A4C00799A4C00FFFF
      C800DFFFFF002AABAB00808080000000000000000000808080002378C8002378
      C8002378C8002378C8007678C800FFFFED00FFFFFF00FFFFFF0076D4FF002378
      C8002378C8002378C80080808000000000000000000080808000B4824600B482
      4600B4824600B4824600B4824600B4824600B4824600B4824600B4824600B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A
      4C002A9A4C002A9A4C00808080000000000000000000808080002378C8002378
      C8002378C8002378C8002378C8002378C8002378C8002378C8002378C8002378
      C8002378C8002378C80080808000000000000000000080808000B4824600B482
      4600B4824600B4824600B4824600B4824600B4824600B4824600B4824600B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A
      4C002A9A4C002A9A4C00808080000000000000000000808080002378C8002378
      C8002378C8002378C8002378C8002378C8002378C8002378C8002378C8002378
      C8002378C8002378C80080808000000000000000000080808000B4824600B482
      4600B4824600B4824600B4824600B4824600B4824600B4824600B4824600B482
      4600B4824600B482460080808000000000000000000080808000AA5A7800AA5A
      7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A7800AA5A
      7800AA5A7800AA5A7800808080000000000000000000808080002A9A4C002A9A
      4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A4C002A9A
      4C002A9A4C002A9A4C00808080000000000000000000808080002378C8002378
      C8002378C8002378C8002378C8002378C8002378C8002378C8002378C8002378
      C8002378C8002378C80080808000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000808080008080
      8000808080008080800080808000808080008080800080808000808080008080
      8000808080008080800000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000300000000100010000000000800100000000000000000000
      000000000000000000000000FFFFFF0000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000FFFFFFFFFFFFFFFFC003C003C003C003
      8001800180018001800180018001800180018001800180018001800180018001
      8001800180018001800180018001800180018001800180018001800180018001
      8001800180018001800180018001800180018001800180018001800180018001
      C003C003C003C003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC003C003C003C003
      8001800180018001800180018001800180018001800180018001800180018001
      8001800180018001800180018001800180018001800180018001800180018001
      8001800180018001800180018001800180018001800180018001800180018001
      C003C003C003C003FFFFFFFFFFFFFFFF00000000000000000000000000000000
      000000000000}
  end
end
