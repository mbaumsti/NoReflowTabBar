Unit NoReflowTabBar_EditSupport;

{
  NoReflowTabBar_EditSupport.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Direct inline item caption editing layer of the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Inline caption editing layer of the NoReflowTabBar component.

  This unit provides:
  - TNoReflowTabBarEditSupport, the specialised layer responsible for direct
    editing of item captions.

  Role of this unit:
  - isolate all inline caption editing logic;
  - keep NoReflowTabBar.pas focused on the final facade and VCL messages;
  - preserve a clean published API in the final component;
  - use an abstract inline caption editor contract;
  - keep the default implementation based on the standard VCL TEdit.

  Behaviour:
  - editing can be started by double-click or F2;
  - editing is accepted with Enter or focus loss;
  - editing is cancelled with Escape;
  - editing can be enabled globally and restricted by zone;
  - application code can approve editing before it starts;
  - application code can validate or adjust the new caption before it is applied;
  - a notification is fired after an effective caption change.

  Important note:
  - a standard VCL TEdit cannot display truly vertical text;
  - for vertical items, the editor remains horizontal but is positioned as close
    as possible to the target item, using parent coordinates when appropriate
    to provide enough editing width;
  - for horizontal items, the editor is anchored to the TextRect returned by the
    content layout engine, not to a reconstructed legacy text position.
}

Interface

Uses
    Winapi.Windows,
    System.Types,
    System.Classes,
    System.SysUtils,
    System.Math,
    Vcl.Controls,
    Vcl.Graphics,
    Vcl.Forms,
    Vcl.Themes,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_Items,
    NoReflowTabBar_EventsTypes,
    NoReflowTabBar_CaptionEditor,
    NoReflowTabBar_HintSupport;

Type
    {
      Inline caption editing support layer.

      This class owns the lazily created caption editor used for item caption
      editing and implements the full edit lifecycle: authorisation, editor placement,
      validation, cancellation, application of the new caption and final
      notification.

      Applications normally control this layer through the published properties
      and events exposed by TNoReflowTabBar:
      - BarEditEnabled;
      - BarEditZones;
      - OnCanEditItemCaption;
      - OnValidateItemCaption;
      - OnItemCaptionEdited.
    }
    TNoReflowTabBarEditSupport = Class(TNoReflowTabBarHintSupport)
    protected
        //-----------------------------------------------------------------
        // Internal inline editing state
        //-----------------------------------------------------------------

        {
          Lazily created editor used to edit the current item caption.

          The editor is held through INoReflowTabBarCaptionEditor so this layer
          does not depend on the concrete TEdit implementation anymore. The
          default implementation is still TNoReflowTabBarStandardCaptionEdit.
        }
        FItemEdit: INoReflowTabBarCaptionEditor;

        {
          Absolute index of the item currently being edited.
        }
        FItemEditIndex: Integer;

        {
          Original caption stored when editing starts.
        }
        FItemEditOriginalCaption: String;

        {
          Reentrancy guard used while ending an edit operation.
        }
        FItemEditEnding: Boolean;

        {
          Global switch enabling or disabling inline editing.
        }
        FItemsEditEnabled: Boolean;

        {
          Zones in which inline editing is allowed.
        }
        FItemEditZones: TNoReflowTabBarEditZones;

        {
          Event fired before editing starts.
        }
        FOnCanEditItemCaption: TNoReflowTabBarCanEditItemCaptionEvent;

        {
          Event fired before accepting a new caption.
        }
        FOnValidateItemCaption: TNoReflowTabBarValidateItemCaptionEvent;

        {
          Event fired after a caption has effectively changed.
        }
        FOnItemCaptionEdited: TNoReflowTabBarItemCaptionEditedEvent;

        Constructor Create(AOwner: TComponent); override;
        Destructor Destroy; override;

        {
          Creates the concrete inline editor.

          The actual creation is delegated to NoReflowTabBar_CaptionEditor so
          that optional packages may register another editor factory later.
          Without such a package, the default implementation still returns the
          historical TEdit-based editor.
        }
        Function CreateItemCaptionEditor: INoReflowTabBarCaptionEditor; virtual;

        {
          Creates the inline editor when needed.

          Important:
          - the editor is not created at design time;
          - it is created lazily on first use;
          - it is owned by the TabBar and therefore destroyed by
            TComponent.Destroy.
        }
        Function EnsureItemCaptionEditor: Boolean;

        //-----------------------------------------------------------------
        // Configuration
        //-----------------------------------------------------------------

        {
          Enables or disables inline caption editing globally.
        }
        Procedure SetItemsEditEnabled(Const Value: Boolean);

        {
          Changes the zones in which inline caption editing is allowed.
        }
        Procedure SetItemEditZones(Const Value: TNoReflowTabBarEditZones);

        {
          Converts an internal pin zone to the corresponding edit permission
          zone.
        }
        Function PinZoneToEditZone(APinZone: TNoReflowTabBarPinZone): TNoReflowTabBarEditZone;

        {
          Returns True when inline editing is allowed in the specified pin zone.
        }
        Function IsItemEditZoneAllowed(APinZone: TNoReflowTabBarPinZone): Boolean;

        //-----------------------------------------------------------------
        // Editing lifecycle
        //-----------------------------------------------------------------

        {
          Returns True when an item caption is currently being edited.
        }
        Function IsEditingItemCaption: Boolean;

        {
          Returns True when the specified item can start inline caption editing.

          This method checks the global edit switch, zone permissions, item
          validity and the OnCanEditItemCaption event.
        }
        Function CanEditItemCaption(
            AIndex: Integer;
            AItem: TNoReflowTabBarItem): Boolean;

        {
          Starts inline editing for the item at the specified absolute index.

          Returns True when the editor is successfully shown.
        }
        Function BeginEditItemCaption(AIndex: Integer): Boolean;

        {
          Ends the current inline edit operation.

          When AAccept is True, the edited text is validated and applied when
          accepted. When AAccept is False, the original caption is preserved.
        }
        Procedure EndEditItemCaption(AAccept: Boolean);

        {
          Cancels the current inline edit operation.
        }
        Procedure CancelEditItemCaption;

        {
          Hides the inline editor without applying a new caption.
        }
        Procedure HideItemCaptionEditor;

        //-----------------------------------------------------------------
        // TEdit placement and appearance
        //-----------------------------------------------------------------

        {
          Returns the windowed control used as parent for the inline editor.
        }
        Function GetItemEditHost: TWinControl;

        {
          Computes the explicit text geometry for the specified item and host
          control.

          The returned record is not a final editor rectangle. It contains the
          neutral information needed by concrete editors: center point, logical
          length, logical thickness and effective text orientation.
        }
        Function GetItemEditTextGeometry(
            AIndex: Integer;
            AHost: TWinControl): TNoReflowTabBarCaptionEditorGeometry;

        {
          Updates the visual appearance of the inline editor for the edited item.
        }
        Procedure UpdateItemEditAppearance(
            AEdit: INoReflowTabBarCaptionEditor;
            AIndex: Integer;
            AItem: TNoReflowTabBarItem);

        //-----------------------------------------------------------------
        // TEdit handlers
        //-----------------------------------------------------------------

        {
          Handles editor keyboard shortcuts such as Enter and Escape.
        }
        Procedure ItemEditKeyDown(
            Sender: TObject;
            Var Key: Word;
            Shift: TShiftState);

        {
          Handles editor key press filtering.
        }
        Procedure ItemEditKeyPress(
            Sender: TObject;
            Var Key: Char);

        {
          Handles editor focus loss.
        }
        Procedure ItemEditExit(Sender: TObject);

        //-----------------------------------------------------------------
        // Reactions to external changes
        //-----------------------------------------------------------------

        {
          Hides the editor when the bar position changes, then lets inherited
          logic apply the new position.
        }
        Procedure ApplyBarPosition; override;

        {
          Hides custom hints while inline editing is active.
        }
        Procedure HideCustomHint; override;
    End;

Implementation


//===============================================================================================================================
//TNoReflowTabBarEditSupport
//===============================================================================================================================

Constructor TNoReflowTabBarEditSupport.Create(AOwner: TComponent);
Begin
    Inherited Create(AOwner);

    //-------------------------------------------------------------------------
    //L'éditeur inline n'est PAS créé ici.
    //
    //Raison :
    //si on crée un TEdit enfant dès le constructeur, il apparaît dans le
    //designer Delphi, ce qui est gênant pour un contrôle interne purement
    //technique.
    //
    //Il sera créé paresseusement à l'exécution par EnsureItemCaptionEditor.
    //-------------------------------------------------------------------------

    FItemEdit := Nil;

    FItemEditIndex := -1;
    FItemEditOriginalCaption := '';
    FItemEditEnding := False;

    //-------------------------------------------------------------------------
    //Doit rester cohérent avec la propriété publiée :
    //
    //Property BarEditEnabled: Boolean ... default False;
    //
    //Delphi ne streame pas les propriétés dont la valeur est égale au default.
    //Si le constructeur initialise True alors que le default publié est False,
    //une fiche dont BarEditEnabled vaut False dans l'inspecteur peut être
    //rechargée avec l'édition active.
    //-------------------------------------------------------------------------

    FItemsEditEnabled := False;

    FItemEditZones := [
        nrtezStart,
        nrtezCenter,
        nrtezEnd];
End;

Destructor TNoReflowTabBarEditSupport.Destroy;
Var
    EditorControl: TWinControl;
Begin
    //-------------------------------------------------------------------------
    //The concrete editor control belongs to Self when it has been created.
    //
    //It is therefore not freed manually here. The VCL component ownership chain
    //will destroy it. We only detach events and parentage to prevent reentrancy
    //while the component is being destroyed.
    //-------------------------------------------------------------------------

    FItemEditEnding := True;
    Try
        If FItemEdit <> Nil Then Begin
            FItemEdit.ClearEditorEvents;

            EditorControl := FItemEdit.GetEditorControl;

            If EditorControl <> Nil Then Begin
                EditorControl.Visible := False;
                EditorControl.Parent := Nil;
            End;
        End;

        FItemEditIndex := -1;
        FItemEditOriginalCaption := '';

        FItemEdit := Nil;
    Finally
        FItemEditEnding := False;
    End;

    Inherited Destroy;
End;

Function TNoReflowTabBarEditSupport.CreateItemCaptionEditor: INoReflowTabBarCaptionEditor;
Begin
    //-------------------------------------------------------------------------
    //Delegates editor creation to the shared factory layer.
    //
    //Without an optional package, this still creates the standard TEdit-based
    //editor. Once the future VclRotatedEdit optional package is installed, the
    //same call will be able to return the registered rotated editor adapter.
    //-------------------------------------------------------------------------

    Result := CreateNoReflowTabBarCaptionEditor(Self);
End;

Function TNoReflowTabBarEditSupport.EnsureItemCaptionEditor: Boolean;
Var
    EditorControl: TWinControl;
Begin
    //-------------------------------------------------------------------------
    //Crée l'éditeur inline uniquement quand il devient nécessaire.
    //
    //Point important :
    //en design-time, on ne crée rien. Cela évite qu'un TEdit technique
    //apparaisse sur la surface de conception ou dans la hiérarchie visuelle.
    //-------------------------------------------------------------------------

    Result := False;

    If FItemEdit <> Nil Then Begin
        Result := True;
        Exit;
    End;

    If csDesigning In ComponentState Then
        Exit;

    FItemEdit := CreateItemCaptionEditor;

    If FItemEdit = Nil Then
        Exit;

    EditorControl := FItemEdit.GetEditorControl;

    If EditorControl = Nil Then Begin
        FItemEdit := Nil;
        Exit;
    End;

    EditorControl.Parent := Self;
    EditorControl.Visible := False;

    FItemEdit.ApplyEditorBaseSettings(
        True,
        True,
        StyleElements,
        False);

    FItemEdit.AssignEditorEvents(
        ItemEditExit,
        ItemEditKeyDown,
        ItemEditKeyPress);

    Result := True;
End;

Procedure TNoReflowTabBarEditSupport.SetItemsEditEnabled(Const Value: Boolean);
Begin
    If FItemsEditEnabled = Value Then
        Exit;

    FItemsEditEnabled := Value;

    If Not FItemsEditEnabled Then
        CancelEditItemCaption;
End;

Procedure TNoReflowTabBarEditSupport.SetItemEditZones(Const Value: TNoReflowTabBarEditZones);
Begin
    If FItemEditZones = Value Then
        Exit;

    FItemEditZones := Value;

    If IsEditingItemCaption Then Begin
        If (FItemEditIndex >= 0) And (FItemEditIndex < FItems.Count) Then Begin
            If Not IsItemEditZoneAllowed(FItems[FItemEditIndex].PinZone) Then
                CancelEditItemCaption;
        End
        Else
            CancelEditItemCaption;
    End;
End;

Function TNoReflowTabBarEditSupport.PinZoneToEditZone(APinZone: TNoReflowTabBarPinZone): TNoReflowTabBarEditZone;
Begin
    Case APinZone Of
        nrtpzStart:
            Result := nrtezStart;

        nrtpzEnd:
            Result := nrtezEnd;
    Else
        Result := nrtezCenter;
    End;
End;

Function TNoReflowTabBarEditSupport.IsItemEditZoneAllowed(APinZone: TNoReflowTabBarPinZone): Boolean;
Begin
    Result := PinZoneToEditZone(APinZone) In FItemEditZones;
End;

Function TNoReflowTabBarEditSupport.IsEditingItemCaption: Boolean;
Var
    EditorControl: TWinControl;
Begin
    Result := False;

    If FItemEdit = Nil Then
        Exit;

    EditorControl := FItemEdit.GetEditorControl;

    If EditorControl = Nil Then
        Exit;

    Result := EditorControl.Visible And (FItemEditIndex >= 0);
End;

Function TNoReflowTabBarEditSupport.CanEditItemCaption(
    AIndex: Integer;
    AItem: TNoReflowTabBarItem): Boolean;
Var
    Allow: Boolean;
Begin
    Result := False;

    If Not FItemsEditEnabled Then
        Exit;

    If AItem = Nil Then
        Exit;

    If (AIndex < 0) Or (AIndex >= FItems.Count) Then
        Exit;

    If Not AItem.Visible Then
        Exit;

    If Not AItem.Enabled Then
        Exit;

    If Not IsItemEditZoneAllowed(AItem.PinZone) Then
        Exit;

    Allow := True;

    If Assigned(FOnCanEditItemCaption) Then
        FOnCanEditItemCaption(
            Self,
            AIndex,
            AItem,
            Allow);

    Result := Allow;
End;

Function TNoReflowTabBarEditSupport.GetItemEditHost: TWinControl;
Begin
    //-------------------------------------------------------------------------
    //On préfère placer le TEdit dans le parent du contrôle.
    //
    //Avantage :
    //- pour les barres verticales, la TabBar est souvent étroite ;
    //- un TEdit enfant de la TabBar serait alors sévèrement rogné ;
    //- en le plaçant dans le parent, l'éditeur peut dépasser légèrement
    //la barre et rester réellement utilisable.
    //
    //Si aucun parent n'est disponible, on retombe sur Self.
    //-------------------------------------------------------------------------

    If Parent <> Nil Then
        Result := Parent
    Else
        Result := Self;
End;

Function TNoReflowTabBarEditSupport.GetItemEditTextGeometry(
    AIndex: Integer;
    AHost: TWinControl): TNoReflowTabBarCaptionEditorGeometry;
Var
    R:             TRect;
    M:             TNoReflowTabBarItemMetrics;
    AnchorClient:  TPoint;
    AnchorScreen:  TPoint;
    AnchorHost:    TPoint;
    TextLength:    Integer;
    TextThickness: Integer;
Begin
    //-------------------------------------------------------------------------
    //Builds the neutral text geometry used by the inline caption editor.
    //
    //Important:
    //the TabBar does not compute the final editor control bounds here. It only
    //provides explicit text information:
    //- the center of the rendered text reference in host coordinates;
    //- the logical text length;
    //- the logical text thickness;
    //- the effective text orientation.
    //
    //This method deliberately uses the same text anchor convention as the
    //renderer. The renderer does not draw vertical text from the top-left corner
    //of a final physical rectangle; it uses TextOut with orientation-specific
    //alignment. Therefore the editor geometry must be derived from TextX/TextY,
    //not from the naive center of TextRect.
    //-------------------------------------------------------------------------

    Result.TextCenter := Point(0, 0);
    Result.TextLength := 0;
    Result.TextThickness := 0;
    Result.TextOrientation := nrttoHorizontal;

    If AHost = Nil Then
        Exit;

    EnsureRenderInfo;

    If (AIndex < 0) Or (AIndex >= Length(FRenderItems)) Then
        Exit;

    If Not FRenderItems[AIndex].Visible Then
        Exit;

    R := FRenderItems[AIndex].Bounds;
    M := FRenderItems[AIndex].Metrics;

    Result.TextOrientation := M.TextOrientation;

    TextLength := M.TextWidth;
    TextThickness := M.TextHeight;

    If TextLength < 1 Then
        TextLength := 1;

    If TextThickness < 1 Then
        TextThickness := 1;

    //-------------------------------------------------------------------------
    //TextX/TextY are renderer anchors, not a generic top-left text rectangle.
    //They are the coordinates passed to TextOut after the item bounds are
    //applied. We convert that anchor into the editor host coordinate system.
    //-------------------------------------------------------------------------
    AnchorClient := Point(
        R.Left + M.TextX,
        R.Top + M.TextY);

    AnchorScreen := ClientToScreen(AnchorClient);
    AnchorHost := AHost.ScreenToClient(AnchorScreen);

    Result.TextLength := TextLength;
    Result.TextThickness := TextThickness;

    Case M.TextOrientation Of
        nrttoVerticalUp: Begin
            //-----------------------------------------------------------------
            //VerticalUp is rendered with a 90 degree font orientation and a
            //left / bottom text anchor. The editor center is therefore half a
            //logical thickness to the left of the anchor and half a logical
            //length above the anchor.
            //-----------------------------------------------------------------
            Result.TextCenter := Point(
                AnchorHost.X - (TextThickness Div 2),
                AnchorHost.Y - (TextLength Div 2));
        End;

        nrttoVerticalDown: Begin
            //-----------------------------------------------------------------
            //VerticalDown is rendered with a 270 degree font orientation. In
            //the current layout convention, the same Y correction as
            //VerticalUp is required. Using +TextLength/2 places both the
            //standard TEdit and TRotatedEdit too low by exactly one text
            //length.
            //-----------------------------------------------------------------
            Result.TextCenter := Point(
                AnchorHost.X - (TextThickness Div 2),
                AnchorHost.Y - (TextLength Div 2));
        End;
    Else
        Result.TextCenter := Point(
            AnchorHost.X + (TextLength Div 2),
            AnchorHost.Y + (TextThickness Div 2));
    End;
End;
Procedure TNoReflowTabBarEditSupport.UpdateItemEditAppearance(
    AEdit: INoReflowTabBarCaptionEditor;
    AIndex: Integer;
    AItem: TNoReflowTabBarItem);
Var
    Palette:          TNoReflowTabBarPalette;
    VisualState:      TNoReflowTabBarItemVisualState;
    TopColor:         TColor;
    BottomColor:      TColor;
    TextColor:        TColor;
    BorderColor:      TColor;
    SignalBrushColor: TColor;
    SignalPenColor:   TColor;
Begin
    If AEdit = Nil Then
        Exit;

    AEdit.ApplyEditorBaseSettings(
        False,
        True,
        StyleElements,
        False);

    AEdit.AssignEditorFont(Font);

    //Si l'item édité est sélectionné, on applique le même enrichissement
    //typographique que le rendu standard.
    If (AIndex >= 0) And (AIndex = FItemIndex) Then
        AEdit.AddEditorFontStyle(FSelectedFontStyle);

    //-------------------------------------------------------------------------
    //Mode style :
    //on laisse le TEdit suivre le style VCL autant que possible.
    //
    //Mode custom :
    //on force les couleurs de texte/fond pour rester cohérent avec l'item.
    //-------------------------------------------------------------------------

    If FPaletteMode = nrtcmStyle Then Begin
        AEdit.SetEditorStyleElements([seFont, seClient, seBorder]);
        Exit;
    End;

    Palette := GetActivePalette;
    VisualState := GetItemVisualState(AIndex);

    ResolveTabRenderColors(
        Palette,
        VisualState,
        AItem.SignalCode,
        TopColor,
        BottomColor,
        TextColor,
        BorderColor,
        SignalBrushColor,
        SignalPenColor);

    AEdit.SetEditorStyleElements([]);
    AEdit.SetEditorColors(
        BottomColor,
        TextColor);
End;

Function TNoReflowTabBarEditSupport.BeginEditItemCaption(AIndex: Integer): Boolean;
Var
    Item:          TNoReflowTabBarItem;
    Host:          TWinControl;
    TextGeometry:  TNoReflowTabBarCaptionEditorGeometry;
    EditorControl: TWinControl;
Begin
    Result := False;

    If IsEditingItemCaption Then
        EndEditItemCaption(True);

    If (AIndex < 0) Or (AIndex >= FItems.Count) Then
        Exit;

    Item := FItems[AIndex];

    If Not CanEditItemCaption(AIndex, Item) Then
        Exit;

    HideCustomHint;

    Host := GetItemEditHost;
    If Host = Nil Then
        Exit;

    TextGeometry := GetItemEditTextGeometry(
        AIndex,
        Host);

    If (TextGeometry.TextLength <= 0) Or (TextGeometry.TextThickness <= 0) Then
        Exit;

    If Not EnsureItemCaptionEditor Then
        Exit;

    EditorControl := FItemEdit.GetEditorControl;

    If EditorControl = Nil Then
        Exit;

    EditorControl.Parent := Host;
    FItemEditIndex := AIndex;
    FItemEditOriginalCaption := Item.Caption;

    //-------------------------------------------------------------------------
    //Transmit the effective text orientation of the rendered item to the
    //caption editor. The standard TEdit implementation ignores it; optional
    //editors such as TRotatedEdit can translate it to their own Angle or
    //Orientation model.
    //-------------------------------------------------------------------------
    FItemEdit.ApplyEditorTextOrientation(TextGeometry.TextOrientation);

    UpdateItemEditAppearance(
        FItemEdit,
        AIndex,
        Item);

    FItemEdit.SetEditorText(Item.Caption);

    FItemEdit.ApplyEditorTextGeometry(TextGeometry);

    EditorControl.Visible := True;
    EditorControl.BringToFront;
    EditorControl.SetFocus;

    FItemEdit.SelectAllEditorText;

    Result := True;
End;

Procedure TNoReflowTabBarEditSupport.HideItemCaptionEditor;
Var
    EditorControl: TWinControl;
Begin
    //-------------------------------------------------------------------------
    //Masque l'éditeur inline sans le détruire.
    //
    //L'éditeur est permanent et appartient à la TabBar.
    //Cette méthode ne fait donc qu'annuler l'édition visuelle courante.
    //-------------------------------------------------------------------------

    If FItemEdit <> Nil Then Begin
        EditorControl := FItemEdit.GetEditorControl;

        If EditorControl <> Nil Then
            EditorControl.Visible := False;
    End;

    FItemEditIndex := -1;
    FItemEditOriginalCaption := '';
End;

Procedure TNoReflowTabBarEditSupport.EndEditItemCaption(AAccept: Boolean);
Var
    Item:        TNoReflowTabBarItem;
    OldCaption: String;
    NewCaption: String;
    Accept:     Boolean;
    EditIndex:  Integer;
Begin
    If FItemEditEnding Then
        Exit;

    If Not IsEditingItemCaption Then
        Exit;

    FItemEditEnding := True;
    Try
        EditIndex := FItemEditIndex;

        If (EditIndex < 0) Or (EditIndex >= FItems.Count) Then Begin
            HideItemCaptionEditor;
            Exit;
        End;

        Item := FItems[EditIndex];
        If Item = Nil Then Begin
            HideItemCaptionEditor;
            Exit;
        End;

        OldCaption := FItemEditOriginalCaption;
        NewCaption := FItemEdit.GetEditorText;

        HideItemCaptionEditor;

        If Not AAccept Then
            Exit;

        Accept := True;

        If Assigned(FOnValidateItemCaption) Then
            FOnValidateItemCaption(
                Self,
                EditIndex,
                Item,
                OldCaption,
                NewCaption,
                Accept);

        If Not Accept Then
            Exit;

        If NewCaption = OldCaption Then
            Exit;

        Item.Caption := NewCaption;

        If Assigned(FOnItemCaptionEdited) Then
            FOnItemCaptionEdited(
                Self,
                EditIndex,
                Item,
                OldCaption,
                NewCaption);
    Finally FItemEditEnding := False;
    End;
End;

Procedure TNoReflowTabBarEditSupport.CancelEditItemCaption;
Begin
    EndEditItemCaption(False);
End;

Procedure TNoReflowTabBarEditSupport.ItemEditKeyDown(
    Sender: TObject;
    Var Key: Word;
    Shift: TShiftState);
Begin
    If Shift <> [] Then
        Exit;

    Case Key Of
        VK_RETURN: Begin
                Key := 0;
                EndEditItemCaption(True);
            End;

        VK_ESCAPE: Begin
                Key := 0;
                EndEditItemCaption(False);
            End;
    End;
End;

Procedure TNoReflowTabBarEditSupport.ItemEditKeyPress(
    Sender: TObject;
    Var Key: Char);
Begin
    //-------------------------------------------------------------------------
    //Un TEdit standard émet un bip Windows si Entrée ou Échap arrive jusqu'au
    //traitement caractère, car ce ne sont pas des caractères éditables.
    //
    //Même si OnKeyDown remet déjà Key à 0, certaines versions / configurations
    //laissent encore passer WM_CHAR. On neutralise donc aussi ici.
    //-------------------------------------------------------------------------
    Case Key Of
        #13,
        #27:
            Key := #0;
    End;
End;

Procedure TNoReflowTabBarEditSupport.ItemEditExit(Sender: TObject);
Begin
    If FItemEditEnding Then
        Exit;

    If IsEditingItemCaption Then
        EndEditItemCaption(True);
End;

Procedure TNoReflowTabBarEditSupport.ApplyBarPosition;
Begin
    CancelEditItemCaption;
    Inherited ApplyBarPosition;
End;

Procedure TNoReflowTabBarEditSupport.HideCustomHint;
Begin
    Inherited HideCustomHint;
End;

End.

