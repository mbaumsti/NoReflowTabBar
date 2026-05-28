Unit NoReflowTabBarDemoMain;

{
  NoReflowTabBarDemoMain.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Public demonstration form for the NoReflowTabBar VCL component.

  Repository:
  https://github.com/mbaumsti/NoReflowTabBar

  License:
  Mozilla Public License 2.0.
  See LICENSE file.

  ------------------------------------------------------------------------------

  Main demo form dedicated to the NoReflowTabBar component.

  This unit provides:
  - TFrmOngletBtn, the main demonstration form;
  - a page-based demo UI driven by a main NoReflowTabBar navigation bar;
  - examples for layout, zones, signals, events, button modes, drag and drop,
  persistence and inline caption editing.

  Role of this unit:
  - keep the demo visual structure in the DFM;
  - apply runtime options selected by the user;
  - route the main navigation bar to the corresponding demo pages;
  - log component events in a readable grid;
  - save and restore local in-memory snapshots for Reset actions;
  - demonstrate public component behaviour without rebuilding item collections
  in code.

  Notes:
  - the DFM is the initial source of truth for the demo state;
  - Reset buttons restore memory snapshots captured after form creation;
  - no INI file or external persistence layer is used by this demo;
  - this form is intentionally a demo application layer and must not contain
  core component logic.
}

Interface

Uses
    Winapi.Windows,
    System.SysUtils,
    System.Classes,
    System.Types,
    System.Generics.Collections,
    Vcl.Graphics,
    Vcl.Controls,
    Vcl.Forms,
    Vcl.StdCtrls,
    Vcl.ExtCtrls,
    Vcl.ComCtrls,
    Vcl.ImgList,
    Vcl.Grids,
    Vcl.WinXPanels,
    System.ImageList,
    NoReflowTabBar,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_Items,
    Vcl.NumberBox,
    NoReflowTabBar_Core,
    NoReflowTabBar_LayoutSupport,
    NoReflowTabBar_RenderSupport,
    NoReflowTabBar_HintSupport,
    NoReflowTabBar_EditSupport,
    NoReflowTabBar_DragSupport,
    NoReflowTabBar_StorageSupport;

Type
    {
      Main demonstration form for NoReflowTabBar.

      The demo intentionally relies on DFM-defined bars and items. Runtime code
      only changes options, records event activity, and restores snapshots so
      the form remains useful as a design-time configuration example.
    }
    TFrmOngletBtn = Class(TForm)
        FStatusBar: TStatusBar;
        CardPanel1: TCardPanel;
        CardOverview: TCard;
        CardLayoutAndZone: TCard;
        CardSignals: TCard;
        CardEvents: TCard;
        CardButtonsModes: TCard;
        CardDragAndDrop: TCard;
        CardPersistence: TCard;
        CardInlineEdition: TCard;
        MainBar: TNoReflowTabBar;
        FImages: TImageList;

        LabelTopOverview: TLabel;
        TopPanelOverview: TPanel;
        BtnResetOverview: TButton;
        BtnSelectPrevious: TButton;
        BtnSelectNext: TButton;
        OverviewBar: TNoReflowTabBar;

        LabelTopLayout: TLabel;
        TopPanelLayout: TPanel;
        RgBarPosition: TRadioGroup;
        RgLayoutMode: TRadioGroup;
        RgFlowOrder: TRadioGroup;
        RgFlowAlignment: TRadioGroup;
        RgTextOrientation: TRadioGroup;
        RgRenderMode: TRadioGroup;
        RgPaletteMode: TRadioGroup;
        RgShapeFirstSlant: TRadioGroup;
        RgShapeFirstRadius: TRadioGroup;
        ChkShowHeaders: TCheckBox;
        LayoutBar: TNoReflowTabBar;

        LabelTopSignals: TLabel;
        TopPanelSignals: TPanel;
        BtnResetSignals: TButton;
        SignalsBar: TNoReflowTabBar;

        LabelTopEvents: TLabel;
        TopPanelEvents: TPanel;
        BtnClearEvents: TButton;
        EventsBar: TNoReflowTabBar;
        EventsGrid: TStringGrid;

        LabelTopButtons: TLabel;
        TopPanelButtons: TPanel;
        RgButtonMode: TRadioGroup;
        RgForcedButtonSize: TRadioGroup;
        BtnResetButtonModes: TButton;
        ButtonModeBar: TNoReflowTabBar;

        LabelTopDrag: TLabel;
        TopPanelDrag: TPanel;
        BtnResetDrag: TButton;
        DragBar1: TNoReflowTabBar;
        MenuFocusBar: TNoReflowTabBar;
        BarDragSelf: TNoReflowTabBar;
        MenuFocusPages: TPageControl;
        TabCustomerButtons: TTabSheet;
        TabProductionButtons: TTabSheet;
        TabDocumentButtons: TTabSheet;
        MenuCustomerBar: TNoReflowTabBar;
        MenuProductionBar: TNoReflowTabBar;
        MenuDocumentsBar: TNoReflowTabBar;

        LabelTopPersistence: TLabel;
        TopPanelPersistence: TPanel;
        BtnSaveLocalState: TButton;
        BtnLoadLocalState: TButton;
        BtnResetPersistence: TButton;
        PersistenceBar: TNoReflowTabBar;

        LabelTopEditing: TLabel;
        TopPanelEditing: TPanel;
        ChkAllowEdit: TCheckBox;
        BtnResetEditing: TButton;
        EditingBar: TNoReflowTabBar;
        RgOverlap: TRadioGroup;
        ChkSameThickness: TCheckBox;
        ChkSameLength: TCheckBox;
        Panel1: TPanel;
        Label1: TLabel;
        RgDragZones: TRadioGroup;
        Panel2: TPanel;
        Label2: TLabel;
        Panel3: TPanel;
        Label3: TLabel;
        DragBar2: TNoReflowTabBar;
        GroupBox1: TGroupBox;
        ChkDragStart: TCheckBox;
        ChkDragCenter: TCheckBox;
        ChkDragEnd: TCheckBox;
        Label4: TLabel;
        RgButtonsPosition: TRadioGroup;
        RgButtonsTextDirection: TRadioGroup;
        RgButtonsSignalPosition: TRadioGroup;
        RgShapeSecondSlant: TRadioGroup;
        RgShapeSecondRadius: TRadioGroup;
        RgSignalsPosition: TRadioGroup;
        GroupBox2: TGroupBox;
        Label5: TLabel;
        NbRed: TNumberBox;
        Label6: TLabel;
        NbGreen: TNumberBox;
        Label7: TLabel;
        NbBlue: TNumberBox;
        BtnAddUserColor: TButton;
    RGSignalFilling: TRadioGroup;
        UpSignalRed: TUpDown;
        UpSignalOrange: TUpDown;
        UpSignalGreen: TUpDown;
        UpSignalGray: TUpDown;
    Label8: TLabel;

        {
          Adds a custom user signal colour to the Signals page.
        }
        Procedure BtnAddUserColorClick(Sender: TObject);

        {
          Initialises the demo, applies initial UI options and captures reset
          snapshots.
        }
        Procedure FormCreate(Sender: TObject);

        {
          Releases in-memory snapshots owned by the demo.
        }
        Procedure FormDestroy(Sender: TObject);

        {
          Routes the main navigation bar selection to the corresponding card.
        }
        Procedure MainBarChange(
            Sender: TObject;
            OldItem: TNoReflowTabBarItem;
            NewItem: TNoReflowTabBarItem);

        {
          Restores the Overview sample bar from its initial snapshot.
        }
        Procedure BtnResetOverviewClick(Sender: TObject);

        {
          Restores the Signals sample bar from its initial snapshot.
        }
        Procedure BtnResetSignalsClick(Sender: TObject);

        {
          Clears the event grid.
        }
        Procedure BtnClearEventsClick(Sender: TObject);

        {
          Restores the Button Modes sample bar from its initial snapshot.
        }
        Procedure BtnResetButtonModesClick(Sender: TObject);

        {
          Restores the Drag and Drop demo state.
        }
        Procedure BtnResetDragClick(Sender: TObject);

        {
          Saves the current persistence sample state into an in-memory snapshot.
        }
        Procedure BtnSaveLocalStateClick(Sender: TObject);

        {
          Loads the persistence sample state from the in-memory snapshot.
        }
        Procedure BtnLoadLocalStateClick(Sender: TObject);

        {
          Restores the Persistence sample bar from its initial snapshot.
        }
        Procedure BtnResetPersistenceClick(Sender: TObject);

        {
          Restores the Inline Editing sample bar from its initial snapshot.
        }
        Procedure BtnResetEditingClick(Sender: TObject);

        {
          Selects the next item on the Overview sample bar.
        }
        Procedure BtnSelectNextClick(Sender: TObject);

        {
          Selects the previous item on the Overview sample bar.
        }
        Procedure BtnSelectPreviousClick(Sender: TObject);

        {
          Applies the layout-related options selected in the UI.
        }
        Procedure LayoutOptionClick(Sender: TObject);

        {
          Applies the selected button mode to the Button Modes sample bar.
        }
        Procedure ButtonModeClick(Sender: TObject);

        {
          Shows or hides zone headers according to the UI option.
        }
        Procedure HeaderVisibilityClick(Sender: TObject);

        {
          Applies inline editing options selected in the UI.
        }
        Procedure EditingOptionClick(Sender: TObject);

        {
          Demo handler for OnChange.
        }
        Procedure DemoBarChange(
            Sender: TObject;
            OldItem: TNoReflowTabBarItem;
            NewItem: TNoReflowTabBarItem);

        {
          Demo handler for OnItemClick.
        }
        Procedure DemoBarItemClick(
            Sender: TObject;
            AItemIndex: Integer;
            AItem: TNoReflowTabBarItem;
            Button: TMouseButton;
            Shift: TShiftState;
            X, Y: Integer);

        {
          Demo handler for OnItemDblClick.
        }
        Procedure DemoBarItemDblClick(
            Sender: TObject;
            AItemIndex: Integer;
            AItem: TNoReflowTabBarItem;
            Shift: TShiftState;
            X, Y: Integer);

        {
          Demo handler for OnBeginItemDrag.
        }
        Procedure DemoBeginItemDrag(
            Sender: TObject;
            AItem: TNoReflowTabBarItem;
            ASourceIndex: Integer;
            ASourceZone: TNoReflowTabBarPinZone);

        {
          Demo handler for OnEndItemDrag.
        }
        Procedure DemoEndItemDrag(
            Sender: TObject;
            AItem: TNoReflowTabBarItem;
            ASourceIndex: Integer;
            ASourceZone: TNoReflowTabBarPinZone;
            ATargetZone: TNoReflowTabBarPinZone;
            ATargetZoneIndex: Integer;
            ADropped: Boolean);

        {
          Demo handler for OnCanReorderItem.
        }
        Procedure DemoCanReorderItem(
            Sender: TObject;
            AItem: TNoReflowTabBarItem;
            ASourceZone: TNoReflowTabBarPinZone;
            ASourceZoneIndex: Integer;
            ATargetZone: TNoReflowTabBarPinZone;
            ATargetZoneIndex: Integer;
            Var Allow: Boolean);

        {
          Demo handler for OnCanDropItem.
        }
        Procedure DemoCanDropItem(
            Sender: TObject;
            ASourceBar: TObject;
            ASourceItem: TNoReflowTabBarItem;
            ATargetZone: TNoReflowTabBarPinZone;
            ATargetZoneIndex: Integer;
            Var Allow: Boolean);

        {
          Demo handler for OnItemDropped.
        }
        Procedure DemoItemDropped(
            Sender: TObject;
            ASourceBar: TObject;
            ASourceItem: TNoReflowTabBarItem;
            ATargetItem: TNoReflowTabBarItem;
            ATargetZone: TNoReflowTabBarPinZone;
            ATargetZoneIndex: Integer);

        {
          Demo handler for OnItemDragOver.
        }
        Procedure DemoItemDragOver(
            Sender: TObject;
            ASourceBar: TObject;
            ASourceItem: TNoReflowTabBarItem;
            AItemIndex: Integer;
            AItem: TNoReflowTabBarItem;
            Var Accept: Boolean);

        {
          Demo handler for OnItemDragLeave.
        }
        Procedure DemoItemDragLeave(
            Sender: TObject;
            ASourceBar: TObject;
            ASourceItem: TNoReflowTabBarItem;
            AItemIndex: Integer;
            AItem: TNoReflowTabBarItem);

        {
          Demo handler for OnCanEditItemCaption.
        }
        Procedure DemoCanEditItemCaption(
            Sender: TObject;
            AItemIndex: Integer;
            AItem: TNoReflowTabBarItem;
            Var Allow: Boolean);

        {
          Demo handler for OnValidateItemCaption.
        }
        Procedure DemoValidateItemCaption(
            Sender: TObject;
            AItemIndex: Integer;
            AItem: TNoReflowTabBarItem;
            Const AOldCaption: String;
            Var ANewCaption: String;
            Var Accept: Boolean);

        {
          Demo handler for OnItemCaptionEdited.
        }
        Procedure DemoItemCaptionEdited(
            Sender: TObject;
            AItemIndex: Integer;
            AItem: TNoReflowTabBarItem;
            Const AOldCaption: String;
            Const ANewCaption: String);

        {
          Demo handler for OnItemMouseEnter.
        }
        Procedure DemoItemMouseEnter(
            Sender: TObject;
            AItemIndex: Integer;
            AItem: TNoReflowTabBarItem;
            Shift: TShiftState;
            X, Y: Integer);

        {
          Demo handler for OnItemMouseLeave.
        }
        Procedure DemoItemMouseLeave(
            Sender: TObject;
            AItemIndex: Integer;
            AItem: TNoReflowTabBarItem;
            Shift: TShiftState;
            X, Y: Integer);

        {
          Demo handler for OnZoneMouseEnter.
        }
        Procedure DemoZoneMouseEnter(
            Sender: TObject;
            APinZone: TNoReflowTabBarPinZone;
            Shift: TShiftState;
            X, Y: Integer);

        {
          Demo handler for OnZoneMouseLeave.
        }
        Procedure DemoZoneMouseLeave(
            Sender: TObject;
            APinZone: TNoReflowTabBarPinZone;
            Shift: TShiftState;
            X, Y: Integer);

        {
          Demo handler for OnGetItemHint.
        }
        Procedure DemoGetItemHint(
            Sender: TObject;
            AItemIndex: Integer;
            AItem: TNoReflowTabBarItem;
            Var AHint: String;
            Var AShowHint: Boolean);

        {
          Applies the selected drag zone options to the drag sample.
        }
        Procedure DragZonesOptionsClick(Sender: TObject);
        procedure UpSignalGrayClick(
            Sender: TObject;
            Button: TUDBtnType);
        procedure UpSignalGreenClick(
            Sender: TObject;
            Button: TUDBtnType);
        procedure UpSignalOrangeClick(
            Sender: TObject;
            Button: TUDBtnType);
        procedure UpSignalRedClick(
            Sender: TObject;
            Button: TUDBtnType);
    private
        {
          Initial per-bar snapshots used by Reset buttons.
        }
        FBarSnapshots: TObjectDictionary<TNoReflowTabBar, TMemoryStream>;

        {
          User snapshot used by the Persistence page.
        }
        FPersistenceSnapshot: TMemoryStream;

        {
          Current event log row count.
        }
        FEventsRow: Integer;

        {
          Next custom signal code used by the Signals page.
        }
        FSignalCode: Integer;

        {
          Captures the initial state of all demo bars that support Reset.
        }
        Procedure SaveInitialBarStates;

        {
          Saves one bar into the specified snapshot dictionary.
        }
        Procedure SaveBarSnapshot(
            ABar: TNoReflowTabBar;
            ASnapshots: TObjectDictionary<TNoReflowTabBar, TMemoryStream>);

        {
          Restores one bar from the specified snapshot dictionary.
        }
        Procedure RestoreBarSnapshot(
            ABar: TNoReflowTabBar;
            ASnapshots: TObjectDictionary<TNoReflowTabBar, TMemoryStream>);

        {
          Serialises a bar to an in-memory component stream.
        }
        Procedure SaveBarToStream(
            ABar: TNoReflowTabBar;
            AStream: TMemoryStream);

        {
          Restores a bar from an in-memory component stream.
        }
        Procedure RestoreBarFromStream(
            ABar: TNoReflowTabBar;
            AStream: TMemoryStream);

        {
          Restores a demo bar from its initial snapshot.
        }
        Procedure ResetBar(ABar: TNoReflowTabBar);

        {
          Restores the full drag sample setup.
        }
        Procedure ResetDragSample;

        {
          Initialises the event log grid.
        }
        Procedure InitEventsGrid;

        {
          Adds one event message to the event log grid.
        }
        Procedure AddEventLog(Const AText: String);

        {
          Displays a message in the demo status bar.
        }
        Procedure ShowStatus(Const AText: String);

        {
          Applies all layout options currently selected in the UI.
        }
        Procedure ApplyLayoutOptions;

        {
          Applies all button mode options currently selected in the UI.
        }
        Procedure ApplyButtonModeOptions;

        {
          Applies the selected tab slant and radius options.
        }
        Procedure ApplyShapeSlantOptions;

        {
          Selects the menu focus page associated with a tab item.
        }
        Procedure SelectMenuFocusPage(AItem: TNoReflowTabBarItem);

        {
          Returns an item caption or '<nil>' for readable event logging.
        }
        Function ItemCaptionOrNil(AItem: TNoReflowTabBarItem): String;

        {
          Converts a pin zone value to readable text for the demo log.
        }
        Function PinZoneToText(APinZone: TNoReflowTabBarPinZone): String;
    public
    End;

Var
    FrmOngletBtn: TFrmOngletBtn;

Implementation

{$R *.dfm}

Procedure TFrmOngletBtn.FormCreate(Sender: TObject);
Begin
    FSignalCode := 100;

    FBarSnapshots := TObjectDictionary<TNoReflowTabBar, TMemoryStream>.Create([doOwnsValues]);
    FPersistenceSnapshot := TMemoryStream.Create;
    FEventsRow := 1;

    InitEventsGrid;
    ApplyLayoutOptions;
    ApplyButtonModeOptions;
    DragZonesOptionsClick(Nil);
    EditingOptionClick(Nil);

    SaveInitialBarStates;

    If MainBar.BarItems.Count > 0 Then
        MainBar.SetBarItemChecked(
            0,
            True);

    CardPanel1.ActiveCard := CardOverview;
    ShowStatus('Ready');

End;

Procedure TFrmOngletBtn.FormDestroy(Sender: TObject);
Begin
    FPersistenceSnapshot.Free;
    FBarSnapshots.Free;
End;

Procedure TFrmOngletBtn.BtnAddUserColorClick(Sender: TObject);
Var
    LSignal: TNoReflowTabBarSignalDef;
    Name:    String;
    Item :TNoReflowTabBarItem;
Begin

    Name := Format('RGB(%d,%d,%d)', [NbRed.ValueInt, NbGreen.ValueInt, NbBlue.ValueInt]);

    If SignalsBar.BarSignals.FindByName(Name) = Nil Then Begin
        LSignal := SignalsBar.BarSignals.Add;
        LSignal.Code := FSignalCode;
        LSignal.Name := Name;
        LSignal.FillColor := RGB(
            NbRed.ValueInt,
            NbGreen.ValueInt,
            NbBlue.ValueInt);
        LSignal.BorderColor := RGB(
            0,
            0,
            0);

        Item:=SignalsBar.AddCenterItem(
            Name,
            FSignalCode);
        Item.SignalMax:=4;
        Item.SignalValue:=RGSignalFilling.ItemIndex;

        inc(FSignalCode);

    End;

End;

Procedure TFrmOngletBtn.SaveInitialBarStates;
Begin
    //---------------------------------------------------------------------
    //Replacement for the former PopulateProductionItems reset logic:
    //the initial state read from the DFM is kept in local memory streams.
    //This keeps the DFM as the single source of the initial demo state and
    //prevents the item lists from being duplicated in code.
    //---------------------------------------------------------------------

    SaveBarSnapshot(
        OverviewBar,
        FBarSnapshots);
    SaveBarSnapshot(
        LayoutBar,
        FBarSnapshots);
    SaveBarSnapshot(
        SignalsBar,
        FBarSnapshots);
    SaveBarSnapshot(
        EventsBar,
        FBarSnapshots);
    SaveBarSnapshot(
        ButtonModeBar,
        FBarSnapshots);
    SaveBarSnapshot(
        DragBar1,
        FBarSnapshots);
    SaveBarSnapshot(
        DragBar2,
        FBarSnapshots);
    SaveBarSnapshot(
        BarDragSelf,
        FBarSnapshots);
    SaveBarSnapshot(
        MenuFocusBar,
        FBarSnapshots);
    SaveBarSnapshot(
        MenuCustomerBar,
        FBarSnapshots);
    SaveBarSnapshot(
        MenuProductionBar,
        FBarSnapshots);
    SaveBarSnapshot(
        MenuDocumentsBar,
        FBarSnapshots);
    SaveBarSnapshot(
        PersistenceBar,
        FBarSnapshots);
    SaveBarSnapshot(
        EditingBar,
        FBarSnapshots);
End;

Procedure TFrmOngletBtn.SaveBarSnapshot(
    ABar: TNoReflowTabBar;
    ASnapshots: TObjectDictionary<TNoReflowTabBar, TMemoryStream>);
Var
    LStream: TMemoryStream;
Begin
    If ABar = Nil Then
        Exit;

    If Not ASnapshots.TryGetValue(ABar, LStream) Then Begin
        LStream := TMemoryStream.Create;
        ASnapshots.Add(
            ABar,
            LStream);
    End;

    SaveBarToStream(
        ABar,
        LStream);
End;

Procedure TFrmOngletBtn.RestoreBarSnapshot(
    ABar: TNoReflowTabBar;
    ASnapshots: TObjectDictionary<TNoReflowTabBar, TMemoryStream>);
Var
    LStream: TMemoryStream;
Begin
    If ABar = Nil Then
        Exit;

    If ASnapshots.TryGetValue(ABar, LStream) Then
        RestoreBarFromStream(
            ABar,
            LStream);
End;

Procedure TFrmOngletBtn.SaveBarToStream(
    ABar: TNoReflowTabBar;
    AStream: TMemoryStream);
Begin
    If (ABar = Nil) Or (AStream = Nil) Then
        Exit;

    AStream.Size := 0;
    AStream.Position := 0;
    AStream.WriteComponent(ABar);
    AStream.Position := 0;
End;

Procedure TFrmOngletBtn.RestoreBarFromStream(
    ABar: TNoReflowTabBar;
    AStream: TMemoryStream);
Begin
    If (ABar = Nil) Or (AStream = Nil) Or (AStream.Size = 0) Then
        Exit;

    AStream.Position := 0;
    AStream.ReadComponent(ABar);
    AStream.Position := 0;
End;

Procedure TFrmOngletBtn.ResetBar(ABar: TNoReflowTabBar);
Begin
    RestoreBarSnapshot(
        ABar,
        FBarSnapshots);
End;

Procedure TFrmOngletBtn.InitEventsGrid;
Begin
    If EventsGrid = Nil Then
        Exit;

    EventsGrid.Cells[0, 0] := 'Time';
    EventsGrid.Cells[1, 0] := 'Event';
    EventsGrid.ColWidths[0] := 110;
    EventsGrid.ColWidths[1] := 1000;
    EventsGrid.RowCount := 2;
    EventsGrid.Cells[0, 1] := '';
    EventsGrid.Cells[1, 1] := '';
    FEventsRow := 1;
End;

Procedure TFrmOngletBtn.AddEventLog(Const AText: String);
Var
    InsertRow: Integer;
    RowIndex:  Integer;
Begin
    If EventsGrid = Nil Then
        Exit;

    //----------------------------------------------------------------------
    //New events are inserted at the top of the grid.
    //
    //If the grid has a fixed header row, insertion starts just below it.
    //Otherwise, insertion starts at row 0.
    //----------------------------------------------------------------------
    InsertRow := EventsGrid.FixedRows;

    If InsertRow < 0 Then
        InsertRow := 0;

    //----------------------------------------------------------------------
    //If the first available row already contains an event, add one row at
    //the bottom so the existing rows can be shifted down safely.
    //----------------------------------------------------------------------
    If EventsGrid.Cells[0, InsertRow] <> '' Then
        EventsGrid.RowCount := EventsGrid.RowCount + 1;

    //----------------------------------------------------------------------
    //Shift existing rows down.
    //
    //The copy starts from the bottom to avoid overwriting values that still
    //need to be copied.
    //----------------------------------------------------------------------
    For RowIndex := EventsGrid.RowCount - 1 Downto InsertRow + 1 Do Begin
        EventsGrid.Cells[0, RowIndex] := EventsGrid.Cells[0, RowIndex - 1];
        EventsGrid.Cells[1, RowIndex] := EventsGrid.Cells[1, RowIndex - 1];
    End;

    //----------------------------------------------------------------------
    //Write the new event at the top of the list.
    //----------------------------------------------------------------------
    EventsGrid.Cells[0, InsertRow] := FormatDateTime(
        'hh:nn:ss',
        Now);
    EventsGrid.Cells[1, InsertRow] := AText;

    If EventsGrid.RowCount > 200 Then
        EventsGrid.RowCount := 200;

    //----------------------------------------------------------------------
    //Visually select the row that has just been inserted, which is the first
    //data row.
    //----------------------------------------------------------------------
    EventsGrid.Row := InsertRow;

    //----------------------------------------------------------------------
    //Keep FEventsRow coherent with the previous append-based model, even
    //though the grid is now displayed in reverse chronological order.
    //----------------------------------------------------------------------
    FEventsRow := EventsGrid.RowCount - 1;
End;

Procedure TFrmOngletBtn.ShowStatus(Const AText: String);
Begin
    If FStatusBar <> Nil Then
        FStatusBar.SimpleText := AText;
End;

Function TFrmOngletBtn.ItemCaptionOrNil(AItem: TNoReflowTabBarItem): String;
Begin
    If AItem = Nil Then
        Result := '<nil>'
    Else
        Result := AItem.Caption;
End;

Function TFrmOngletBtn.PinZoneToText(APinZone: TNoReflowTabBarPinZone): String;
Begin
    Case APinZone Of
        nrtpzStart:
            Result := 'Start';
        nrtpzCenter:
            Result := 'Center';
        nrtpzEnd:
            Result := 'End';
    Else
        Result := 'Unknown';
    End;
End;

Procedure TFrmOngletBtn.MainBarChange(
    Sender: TObject;
    OldItem: TNoReflowTabBarItem;
    NewItem: TNoReflowTabBarItem);
Begin
    If NewItem = Nil Then
        Exit;

    Case NewItem.ItemIndex Of
        0:
            CardPanel1.ActiveCard := CardOverview;
        1:
            CardPanel1.ActiveCard := CardLayoutAndZone;
        2:
            CardPanel1.ActiveCard := CardSignals;
        3:
            CardPanel1.ActiveCard := CardEvents;
        4:
            CardPanel1.ActiveCard := CardButtonsModes;
        5:
            CardPanel1.ActiveCard := CardDragAndDrop;
        6:
            CardPanel1.ActiveCard := CardPersistence;
        7:
            CardPanel1.ActiveCard := CardInlineEdition;
    Else
        Exit;
    End;

    ShowStatus('Page: ' + NewItem.Caption);
End;

Procedure TFrmOngletBtn.ApplyLayoutOptions;
Begin
    If LayoutBar = Nil Then
        Exit;

    LayoutBar.Align := alNone;

    Case RgBarPosition.ItemIndex Of
        0: Begin
                LayoutBar.Align := alTop;
                LayoutBar.Height := 150;
                LayoutBar.BarPosition := nrtbpTop;
            End;
        1: Begin
                LayoutBar.Align := alBottom;
                LayoutBar.Height := 150;
                LayoutBar.BarPosition := nrtbpBottom;
            End;
        2: Begin
                LayoutBar.Align := alLeft;
                LayoutBar.Width := 290;
                LayoutBar.BarPosition := nrtbpLeft;
            End;
        3: Begin
                LayoutBar.Align := alRight;
                LayoutBar.Width := 290;
                LayoutBar.BarPosition := nrtbpRight;
            End;
    End;

    If RgLayoutMode.ItemIndex = 0 Then
        LayoutBar.BarLayoutMode := nrblmSequential
    Else
        LayoutBar.BarLayoutMode := nrblmByZones;

    Case RgFlowOrder.ItemIndex Of
        0:
            LayoutBar.BarFlowOrder := nrtfoNormal;
        1:
            LayoutBar.BarFlowOrder := nrtfoReverseZones;
        2:
            LayoutBar.BarFlowOrder := nrtfoReverseZonesAndItems;
    End;

    Case RgFlowAlignment.ItemIndex Of
        0:
            LayoutBar.BarLayout.FlowAlignment := nrtfaStart;
        1:
            LayoutBar.BarLayout.FlowAlignment := nrtfaCenter;
        2:
            LayoutBar.BarLayout.FlowAlignment := nrtfaEnd;
    End;

    Case RgSignalsPosition.ItemIndex Of
        0:
            LayoutBar.BarSignalPosition := nrtspBefore;
        1:
            LayoutBar.BarSignalPosition := nrtspAfter;
        2:
            LayoutBar.BarSignalPosition := nrtspItemEnd;

    End;

    If ChkSameThickness.Checked Then
        LayoutBar.BarLayout.SameThickness := True
    Else
        LayoutBar.BarLayout.SameThickness := false;

    If ChkSameLength.Checked Then
        LayoutBar.BarLayout.SameLength := True
    Else
        LayoutBar.BarLayout.SameLength := false;

    Case RgTextOrientation.ItemIndex Of
        0:
            LayoutBar.BarTextOrientation := nrttoAuto;
        1:
            LayoutBar.BarTextOrientation := nrttoHorizontal;
        2:
            LayoutBar.BarTextOrientation := nrttoVerticalUp;
        3:
            LayoutBar.BarTextOrientation := nrttoVerticalDown;
    End;

    Case RgRenderMode.ItemIndex Of
        0:
            LayoutBar.BarRenderMode := nrrmAuto;
        1:
            LayoutBar.BarRenderMode := nrrmFlat;
        2:
            LayoutBar.BarRenderMode := nrrmGradient;
    End;

    If RgPaletteMode.ItemIndex = 0 Then
        LayoutBar.BarPaletteMode := nrtcmStyle
    Else
        LayoutBar.BarPaletteMode := nrtcmCustom;

    LayoutBar.BarZoneHeader.Visible := ChkShowHeaders.Checked;
    ApplyShapeSlantOptions;
End;

Procedure TFrmOngletBtn.ApplyShapeSlantOptions;
Begin
    If LayoutBar = Nil Then
        Exit;

    Case RgOverlap.ItemIndex Of
        0:
            LayoutBar.BarLayoutTabs.TabOverlap := 0;
        1:
            LayoutBar.BarLayoutTabs.TabOverlap := 16;
        2:
            LayoutBar.BarLayoutTabs.TabOverlap := -6;
    End;

    Case RgShapeFirstSlant.ItemIndex Of
        0: Begin
                LayoutBar.BarLayoutTabs.ShapeSlantFirst := 0;
            End;
        1: Begin
                LayoutBar.BarLayoutTabs.ShapeSlantFirst := 18;
            End;
        2: Begin
                LayoutBar.BarLayoutTabs.ShapeSlantFirst := 32;
            End;
    End;

    Case RgShapeSecondSlant.ItemIndex Of
        0: Begin
                LayoutBar.BarLayoutTabs.ShapeSlantSecond := 0;
            End;
        1: Begin
                LayoutBar.BarLayoutTabs.ShapeSlantSecond := 18;
            End;
        2: Begin
                LayoutBar.BarLayoutTabs.ShapeSlantSecond := 32;
            End;
    End;

    Case RgShapeFirstRadius.ItemIndex Of
        0: Begin
                LayoutBar.BarLayoutTabs.ShapeRadiusFirst := 0;
            End;
        1: Begin
                LayoutBar.BarLayoutTabs.ShapeRadiusFirst := 6;
            End;
        2: Begin
                LayoutBar.BarLayoutTabs.ShapeRadiusFirst := 12;
            End;
        3: Begin
                LayoutBar.BarLayoutTabs.ShapeRadiusFirst := 18;
            End;
    End;

    Case RgShapeSecondRadius.ItemIndex Of
        0: Begin
                LayoutBar.BarLayoutTabs.ShapeRadiusSecond := 0;
            End;
        1: Begin
                LayoutBar.BarLayoutTabs.ShapeRadiusSecond := 6;
            End;
        2: Begin
                LayoutBar.BarLayoutTabs.ShapeRadiusSecond := 12;
            End;
        3: Begin
                LayoutBar.BarLayoutTabs.ShapeRadiusSecond := 18;
            End;
    End;
End;

Procedure TFrmOngletBtn.ApplyButtonModeOptions;
Begin
    If ButtonModeBar = Nil Then
        Exit;

    Case RgButtonMode.ItemIndex Of
        0:
            ButtonModeBar.BarMode := nrbmPushButtons;
        1:
            ButtonModeBar.BarMode := nrbmSelectButtons;
        2:
            ButtonModeBar.BarMode := nrbmCheckButtons;
    End;

    Case RgButtonsPosition.ItemIndex Of
        0: begin
                ButtonModeBar.Align := alTop;
                ButtonModeBar.BarPosition := nrtbpTop;
                ButtonModeBar.BarFlowOrder := nrtfoNormal;
                ButtonModeBar.BarLayout.FlowAlignment := nrtfaStart;
            end;
        1: begin
                ButtonModeBar.Align := alBottom;
                ButtonModeBar.BarPosition := nrtbpBottom;
                ButtonModeBar.BarFlowOrder := nrtfoNormal;
                ButtonModeBar.BarLayout.FlowAlignment := nrtfaStart;
            end;
        2: begin
                ButtonModeBar.Align := alLeft;
                ButtonModeBar.BarPosition := nrtbpLeft;
                ButtonModeBar.BarFlowOrder := nrtfoReverseZonesAndItems;
                ButtonModeBar.BarLayout.FlowAlignment := nrtfaEnd;
            end;
        3: begin
                ButtonModeBar.Align := alRight;
                ButtonModeBar.BarPosition := nrtbpRight;
                ButtonModeBar.BarFlowOrder := nrtfoNormal;
                ButtonModeBar.BarLayout.FlowAlignment := nrtfaStart;
            end;
    End;

    Case RgButtonsTextDirection.ItemIndex Of
        0:
            ButtonModeBar.BarTextOrientation := nrttoHorizontal;
        1:
            ButtonModeBar.BarTextOrientation := nrttoVerticalUp;
        2:
            ButtonModeBar.BarTextOrientation := nrttoVerticalDown;

    End;

    Case RgButtonsSignalPosition.ItemIndex Of
        0:
            ButtonModeBar.BarSignalPosition := nrtspBefore;
        1:
            ButtonModeBar.BarSignalPosition := nrtspAfter;

    End;

    //---------------------------------------------------------------------
    //Forced and minimum button logical dimensions are deliberately exposed in the demo.
    //
    //They are especially useful to verify the overflow behaviour of button
    //content:
    //- long captions should be shortened with ellipsis;
    //- glyphs and signals should not be drawn outside the item bounds;
    //- small forced sizes should degrade gracefully instead of producing
    //overlapping content.
    //
    //The properties are harmless in tab mode because they are consumed by the
    //button geometry only. Keeping the option visible while switching modes also
    //makes it easier to compare tab and button rendering.
    //---------------------------------------------------------------------
    ButtonModeBar.BarLayoutButtons.ForcedLength := 0;
    ButtonModeBar.BarLayoutButtons.MinimumLength := 0;
    ButtonModeBar.BarLayoutButtons.ForcedThickness := 0;

    If RgForcedButtonSize <> Nil Then Begin
        Case RgForcedButtonSize.ItemIndex Of
            1: Begin
                    ButtonModeBar.BarLayoutButtons.ForcedLength := 120;
                    ButtonModeBar.BarLayoutButtons.ForcedThickness := 0;
                End;
            2: Begin
                    ButtonModeBar.BarLayoutButtons.ForcedLength := 0;
                    ButtonModeBar.BarLayoutButtons.ForcedThickness := 36;
                End;
            3: Begin
                    ButtonModeBar.BarLayoutButtons.ForcedLength := 120;
                    ButtonModeBar.BarLayoutButtons.ForcedThickness := 36;
                End;
            4: Begin
                    ButtonModeBar.BarLayoutButtons.ForcedLength := 78;
                    ButtonModeBar.BarLayoutButtons.ForcedThickness := 36;
                End;
            5: Begin
                    ButtonModeBar.BarLayoutButtons.MinimumLength := 200;
                    ButtonModeBar.BarLayoutButtons.ForcedThickness := 0;
                End;
        End;
    End;

    If ButtonModeBar.BarMode = nrbmCheckButtons Then Begin
        If ButtonModeBar.BarItems.Count > 0 Then
            ButtonModeBar.BarItems[0].Checked := True;
        If ButtonModeBar.BarItems.Count > 2 Then
            ButtonModeBar.BarItems[2].Checked := True;
    End;
End;

Procedure TFrmOngletBtn.SelectMenuFocusPage(AItem: TNoReflowTabBarItem);
Begin
    If (AItem = Nil) Or (MenuFocusPages = Nil) Then
        Exit;

    If SameText(AItem.Caption, 'Customers') Then
        MenuFocusPages.ActivePage := TabCustomerButtons
    Else If SameText(AItem.Caption, 'Production') Then
        MenuFocusPages.ActivePage := TabProductionButtons
    Else If SameText(AItem.Caption, 'Documents') Then
        MenuFocusPages.ActivePage := TabDocumentButtons;
End;

Procedure TFrmOngletBtn.ResetDragSample;
Begin
    ResetBar(DragBar1);
    ResetBar(DragBar2);
    ResetBar(BarDragSelf);
    ResetBar(MenuFocusBar);
    ResetBar(MenuCustomerBar);
    ResetBar(MenuProductionBar);
    ResetBar(MenuDocumentsBar);

End;

Procedure TFrmOngletBtn.BtnResetOverviewClick(Sender: TObject);
Begin
    ResetBar(OverviewBar);
    ShowStatus('Overview restored from initial DFM state.');
End;

Procedure TFrmOngletBtn.BtnResetSignalsClick(Sender: TObject);
Begin
    ResetBar(SignalsBar);
    ShowStatus('Signals restored from initial DFM state.');
End;

Procedure TFrmOngletBtn.BtnClearEventsClick(Sender: TObject);
Begin
    InitEventsGrid;
    AddEventLog('Event grid cleared.');
End;

Procedure TFrmOngletBtn.BtnResetButtonModesClick(Sender: TObject);
Begin
    ResetBar(ButtonModeBar);
    ApplyButtonModeOptions;
    ShowStatus('Button mode page restored from initial DFM state.');
End;

Procedure TFrmOngletBtn.BtnResetDragClick(Sender: TObject);
Begin
    ResetDragSample;
    ShowStatus('Drag sample restored from initial DFM state.');
End;

Procedure TFrmOngletBtn.BtnSaveLocalStateClick(Sender: TObject);
Begin
    SaveBarToStream(
        PersistenceBar,
        FPersistenceSnapshot);
    ShowStatus('Persistence page state saved in local memory.');
End;

Procedure TFrmOngletBtn.BtnLoadLocalStateClick(Sender: TObject);
Begin
    RestoreBarFromStream(
        PersistenceBar,
        FPersistenceSnapshot);
    ShowStatus('Persistence page state restored from local memory.');
End;

Procedure TFrmOngletBtn.BtnResetPersistenceClick(Sender: TObject);
Begin
    ResetBar(PersistenceBar);
    ShowStatus('Persistence page restored from initial DFM state.');
End;

Procedure TFrmOngletBtn.BtnResetEditingClick(Sender: TObject);
Begin
    ResetBar(EditingBar);
    EditingBar.BarEditEnabled := ChkAllowEdit.Checked;
    ShowStatus('Inline editing page restored from initial DFM state.');
End;

Procedure TFrmOngletBtn.BtnSelectNextClick(Sender: TObject);
Begin
    OverviewBar.SelectNext;
End;

Procedure TFrmOngletBtn.BtnSelectPreviousClick(Sender: TObject);
Begin
    OverviewBar.SelectPrevious;
End;

Procedure TFrmOngletBtn.LayoutOptionClick(Sender: TObject);
Begin
    ApplyLayoutOptions;
    ShowStatus('Layout options applied.');
End;

Procedure TFrmOngletBtn.ButtonModeClick(Sender: TObject);
Begin
    ApplyButtonModeOptions;
    ShowStatus('Button mode changed.');
End;

Procedure TFrmOngletBtn.HeaderVisibilityClick(Sender: TObject);
Begin
    If LayoutBar <> Nil Then
        LayoutBar.BarZoneHeader.Visible := ChkShowHeaders.Checked;
    ShowStatus('Zone header visibility changed.');
End;

Procedure TFrmOngletBtn.EditingOptionClick(Sender: TObject);
Begin
    If EditingBar <> Nil Then
        EditingBar.BarEditEnabled := ChkAllowEdit.Checked;
    ShowStatus('Inline editing option changed.');
End;

Procedure TFrmOngletBtn.DemoBarChange(
    Sender: TObject;
    OldItem: TNoReflowTabBarItem;
    NewItem: TNoReflowTabBarItem);
Begin

    If Sender = MenuFocusBar Then
        SelectMenuFocusPage(NewItem);

    If Sender = EventsBar Then
        AddEventLog('OnChange: ' + ItemCaptionOrNil(OldItem) + ' -> ' + ItemCaptionOrNil(NewItem));

    If NewItem <> Nil Then
        ShowStatus('Selected: ' + NewItem.Caption);
End;

Procedure TFrmOngletBtn.DemoBarItemClick(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    Button: TMouseButton;
    Shift: TShiftState;
    X, Y: Integer);
Begin
    If Sender = EventsBar Then
        AddEventLog('OnItemClick: ' + ItemCaptionOrNil(AItem));

    If AItem <> Nil Then
        ShowStatus('Clicked: ' + AItem.Caption);
End;

Procedure TFrmOngletBtn.DemoBarItemDblClick(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    Shift: TShiftState;
    X, Y: Integer);
Begin

    If Sender = EventsBar Then
        AddEventLog('OnItemDblClick: ' + ItemCaptionOrNil(AItem));
End;

Procedure TFrmOngletBtn.DemoBeginItemDrag(
    Sender: TObject;
    AItem: TNoReflowTabBarItem;
    ASourceIndex: Integer;
    ASourceZone: TNoReflowTabBarPinZone);
Begin
    If Sender = EventsBar Then
        AddEventLog('OnBeginItemDrag: ' + ItemCaptionOrNil(AItem) + ' from ' + PinZoneToText(ASourceZone));
End;

Procedure TFrmOngletBtn.DemoEndItemDrag(
    Sender: TObject;
    AItem: TNoReflowTabBarItem;
    ASourceIndex: Integer;
    ASourceZone: TNoReflowTabBarPinZone;
    ATargetZone: TNoReflowTabBarPinZone;
    ATargetZoneIndex: Integer;
    ADropped: Boolean);
Begin
    If Sender = EventsBar Then
        AddEventLog('OnEndItemDrag: ' + ItemCaptionOrNil(AItem) + ' dropped=' + BoolToStr(ADropped, True));
End;

Procedure TFrmOngletBtn.DemoCanReorderItem(
    Sender: TObject;
    AItem: TNoReflowTabBarItem;
    ASourceZone: TNoReflowTabBarPinZone;
    ASourceZoneIndex: Integer;
    ATargetZone: TNoReflowTabBarPinZone;
    ATargetZoneIndex: Integer;
    Var Allow: Boolean);
Begin

    Allow := True;

    If Sender = EventsBar Then
        AddEventLog('OnCanReorderItem: ' + ItemCaptionOrNil(AItem));
End;

Procedure TFrmOngletBtn.DemoCanDropItem(
    Sender: TObject;
    ASourceBar: TObject;
    ASourceItem: TNoReflowTabBarItem;
    ATargetZone: TNoReflowTabBarPinZone;
    ATargetZoneIndex: Integer;
    Var Allow: Boolean);
Begin
    Allow := True;
    If Sender = EventsBar Then
        AddEventLog('OnCanDropItem: ' + ItemCaptionOrNil(ASourceItem) + ' allow=' + BoolToStr(Allow, True));
End;

Procedure TFrmOngletBtn.DemoItemDropped(
    Sender: TObject;
    ASourceBar: TObject;
    ASourceItem: TNoReflowTabBarItem;
    ATargetItem: TNoReflowTabBarItem;
    ATargetZone: TNoReflowTabBarPinZone;
    ATargetZoneIndex: Integer);
Begin
    If Sender = EventsBar Then
        AddEventLog('OnItemDropped: ' + ItemCaptionOrNil(ATargetItem) + ' in ' + PinZoneToText(ATargetZone));

    ShowStatus('Item dropped.');
End;

Procedure TFrmOngletBtn.DemoItemDragOver(
    Sender: TObject;
    ASourceBar: TObject;
    ASourceItem: TNoReflowTabBarItem;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    Var Accept: Boolean);
Begin
    Accept := True;

    If Sender = MenuFocusBar Then
        MenuFocusBar.SelectItem(AItem);
    //SelectMenuFocusPage(AItem);

    If Sender = EventsBar Then
        AddEventLog('OnItemDragOver: ' + ItemCaptionOrNil(AItem));
End;

Procedure TFrmOngletBtn.DemoItemDragLeave(
    Sender: TObject;
    ASourceBar: TObject;
    ASourceItem: TNoReflowTabBarItem;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem);
Begin
    If Sender = EventsBar Then
        AddEventLog('OnItemDragLeave: ' + ItemCaptionOrNil(AItem));
End;

Procedure TFrmOngletBtn.DemoCanEditItemCaption(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    Var Allow: Boolean);
Begin
    Allow := (AItem = Nil) Or Not SameText(AItem.Caption, 'Locked');

    If Sender = EventsBar Then
        AddEventLog('OnCanEditItemCaption: ' + ItemCaptionOrNil(AItem) + ' allow=' + BoolToStr(Allow, True));
End;

Procedure TFrmOngletBtn.DemoValidateItemCaption(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    Const AOldCaption: String;
    Var ANewCaption: String;
    Var Accept: Boolean);
Begin

    ANewCaption := Trim(ANewCaption);
    Accept := ANewCaption <> '';

    If Sender = EventsBar Then
        AddEventLog('OnValidateItemCaption: ' + AOldCaption + ' -> ' + ANewCaption);
End;

Procedure TFrmOngletBtn.DemoItemCaptionEdited(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    Const AOldCaption: String;
    Const ANewCaption: String);
Begin
    If Sender = EventsBar Then
        AddEventLog('OnItemCaptionEdited: ' + AOldCaption + ' -> ' + ANewCaption);

    ShowStatus('Caption changed.');
End;

Procedure TFrmOngletBtn.DemoItemMouseEnter(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    Shift: TShiftState;
    X, Y: Integer);
Begin
    If Sender = EventsBar Then
        AddEventLog('OnItemMouseEnter: ' + ItemCaptionOrNil(AItem));
End;

Procedure TFrmOngletBtn.DemoItemMouseLeave(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    Shift: TShiftState;
    X, Y: Integer);
Begin
    If Sender = EventsBar Then
        AddEventLog('OnItemMouseLeave: ' + ItemCaptionOrNil(AItem));
End;

Procedure TFrmOngletBtn.DemoZoneMouseEnter(
    Sender: TObject;
    APinZone: TNoReflowTabBarPinZone;
    Shift: TShiftState;
    X, Y: Integer);
Begin
    If Sender = EventsBar Then
        AddEventLog('OnZoneMouseEnter: ' + PinZoneToText(APinZone));
End;

Procedure TFrmOngletBtn.DemoZoneMouseLeave(
    Sender: TObject;
    APinZone: TNoReflowTabBarPinZone;
    Shift: TShiftState;
    X, Y: Integer);
Begin
    If Sender = EventsBar Then
        AddEventLog('OnZoneMouseLeave: ' + PinZoneToText(APinZone));
End;

Procedure TFrmOngletBtn.DemoGetItemHint(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    Var AHint: String;
    Var AShowHint: Boolean);
Begin
    AShowHint := AItem <> Nil;

    If AItem <> Nil Then
        AHint := 'Item: ' + AItem.Caption + ' / Signal=' + IntToStr(AItem.SignalCode);
End;

Procedure TFrmOngletBtn.DragZonesOptionsClick(Sender: TObject);
Var
    zones: TNoReflowTabBarZones;
Begin
    Case RgDragZones.ItemIndex Of
        0:
            BarDragSelf.BarDragReorderMode := nrbrmNone;
        1:
            BarDragSelf.BarDragReorderMode := nrbrmSameZoneOnly;
        2:
            BarDragSelf.BarDragReorderMode := nrbrmAllZones;
    End;

    zones := [];

    If ChkDragStart.Checked Then
        zones := zones + [nrtzStart];
    If ChkDragCenter.Checked Then
        zones := zones + [nrtzCenter];
    If ChkDragEnd.Checked Then
        zones := zones + [nrtzEnd];

    BarDragSelf.BarDragReorderZones := zones;
End;

procedure TFrmOngletBtn.UpSignalGrayClick(
    Sender: TObject;
    Button: TUDBtnType);
begin
    SignalsBar.BarItems[1].signalMAx := 4;
    SignalsBar.BarItems[1].SignalValue := UpSignalGray.Position;
end;

procedure TFrmOngletBtn.UpSignalGreenClick(
    Sender: TObject;
    Button: TUDBtnType);
begin
    SignalsBar.BarItems[2].signalMAx := 4;
    SignalsBar.BarItems[2].SignalValue := UpSignalGreen.Position;

end;

procedure TFrmOngletBtn.UpSignalOrangeClick(
    Sender: TObject;
    Button: TUDBtnType);
begin
    SignalsBar.BarItems[3].signalMAx := 4;
    SignalsBar.BarItems[3].SignalValue := UpSignalOrange.Position;

end;

procedure TFrmOngletBtn.UpSignalRedClick(
    Sender: TObject;
    Button: TUDBtnType);
begin
    SignalsBar.BarItems[4].signalMAx := 4;
    SignalsBar.BarItems[4].SignalValue := UpSignalRed.Position;

end;

End.
