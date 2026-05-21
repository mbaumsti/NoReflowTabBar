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
  - use a standard VCL TEdit to remain as consistent as possible with the active
    VCL style.

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
    Vcl.StdCtrls,
    Vcl.Graphics,
    Vcl.Forms,
    Vcl.Themes,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_Items,
    NoReflowTabBar_EventsTypes,
    NoReflowTabBar_HintSupport;

Type
    {
      Inline caption editing support layer.

      This class owns the lazily created TEdit used for item caption editing and
      implements the full edit lifecycle: authorisation, editor placement,
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
        }
        FItemEdit: TEdit;

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
          Computes the editor bounds for the specified item and host control.
        }
        Function GetItemEditBounds(
            AIndex: Integer;
            AHost: TWinControl): TRect;

        {
          Updates the visual appearance of the inline editor for the edited item.
        }
        Procedure UpdateItemEditAppearance(
            AEdit: TEdit;
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
Begin
    //-------------------------------------------------------------------------
    //FItemEdit appartient à Self s'il a été créé.
    //
    //On ne le libère donc pas manuellement. On neutralise seulement les
    //événements pour éviter toute réentrée pendant la destruction VCL.
    //-------------------------------------------------------------------------

    FItemEditEnding := True;
    Try
        If FItemEdit <> Nil Then Begin
            FItemEdit.OnExit := Nil;
            FItemEdit.OnKeyDown := Nil;
            FItemEdit.Visible := False;
            FItemEdit.Parent := Nil;
        End;

        FItemEditIndex := -1;
        FItemEditOriginalCaption := '';

        FItemEdit := Nil;
    Finally
        FItemEditEnding := False;
    End;

    Inherited Destroy;
End;

Function TNoReflowTabBarEditSupport.EnsureItemCaptionEditor: Boolean;
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

    FItemEdit := TEdit.Create(Self);
    FItemEdit.Parent := Self;
    FItemEdit.Visible := False;
    FItemEdit.BorderStyle := bsSingle;
    FItemEdit.TabStop := False;

    FItemEdit.ParentFont := True;
    FItemEdit.ParentColor := True;
    FItemEdit.StyleElements := StyleElements;

    FItemEdit.OnExit := ItemEditExit;
    FItemEdit.OnKeyDown := ItemEditKeyDown;
    FItemEdit.OnKeyPress := ItemEditKeyPress;

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
Begin
    Result := (FItemEdit <> Nil) And FItemEdit.Visible And (FItemEditIndex >= 0);
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

Function TNoReflowTabBarEditSupport.GetItemEditBounds(
    AIndex: Integer;
    AHost: TWinControl): TRect;
Var
    R:                 TRect;
    M:                 TNoReflowTabBarItemMetrics;
    TextRect:          TRect;
    ScreenTopLeft:     TPoint;
    ScreenBottomRight: TPoint;
    HostTopLeft:       TPoint;
    HostBottomRight:   TPoint;
    EditHeight:        Integer;
    EditWidth:         Integer;
    CenterX:           Integer;
    CenterY:           Integer;
    HostClientRect:    TRect;
Begin
    SetRectEmpty(Result);

    If AHost = Nil Then
        Exit;

    EnsureRenderInfo;

    If (AIndex < 0) Or (AIndex >= Length(FRenderItems)) Then
        Exit;

    If Not FRenderItems[AIndex].Visible Then
        Exit;

    R := FRenderItems[AIndex].Bounds;
    M := FRenderItems[AIndex].Metrics;

    //-------------------------------------------------------------------------
    //Cas naturel : texte horizontal.
    //
    //Depuis le nouveau moteur de layout de contenu, TextRect est la source de
    //vérité pour la zone texte réellement affichée :
    //- il inclut les marges intérieures décidées par ZoneLayout ;
    //- il tient compte des fallbacks du moteur de composition ;
    //- il peut être plus court que le texte complet en cas de ForcedLength.
    //
    //L'éditeur doit donc s'ancrer sur ce rectangle plutôt que reconstruire une
    //ancienne emprise à partir de TextX / TextY / TextWidth / TextHeight.
    //
    //On garde une petite respiration autour du rectangle, mais on ne cherche
    //pas à recalculer la largeur du texte complet : l'éditeur est placé sur la
    //zone visible. Les contraintes minimales plus bas garantissent malgré tout
    //une surface éditable.
    //-------------------------------------------------------------------------

    If M.TextOrientation = nrttoHorizontal Then Begin
        If Not IsRectEmpty(M.TextRect) Then Begin
            TextRect := M.TextRect;

            OffsetRect(
                TextRect,
                R.Left,
                R.Top);

            InflateRect(
                TextRect,
                4,
                3);
        End Else Begin
            //-----------------------------------------------------------------
            //Fallback défensif.
            //
            //Ce cas ne devrait normalement plus arriver, mais il évite de rendre
            //l'édition impossible si une ancienne métrique ou un handler externe
            //fournit encore un rectangle texte vide.
            //-----------------------------------------------------------------
            TextRect := Rect(
                R.Left + M.TextX - 4,
                R.Top + M.TextY - 3,
                R.Left + M.TextX + Max(M.TextWidth + 12, 48),
                R.Top + M.TextY + M.TextHeight + 6);
        End;
    End Else Begin
        //-------------------------------------------------------------------------
        //Cas vertical.
        //
        //Un TEdit standard ne peut pas tourner son texte.
        //On crée donc un éditeur horizontal centré sur l'item, avec une largeur
        //suffisante pour une saisie confortable.
        //-------------------------------------------------------------------------

        EditHeight := Max(
            M.TextHeight + 8,
            22);

        EditWidth := Max(
            M.TextWidth + 24,
            90);

        CenterX := (R.Left + R.Right) Div 2;
        CenterY := (R.Top + R.Bottom) Div 2;

        TextRect := Rect(
            CenterX - (EditWidth Div 2),
            CenterY - (EditHeight Div 2),
            CenterX + ((EditWidth + 1) Div 2),
            CenterY + ((EditHeight + 1) Div 2));
    End;

    //Conversion du rectangle client de la TabBar vers le repère client du host.
    ScreenTopLeft := ClientToScreen(TextRect.TopLeft);
    ScreenBottomRight := ClientToScreen(TextRect.BottomRight);

    HostTopLeft := AHost.ScreenToClient(ScreenTopLeft);
    HostBottomRight := AHost.ScreenToClient(ScreenBottomRight);

    Result := Rect(
        HostTopLeft.X,
        HostTopLeft.Y,
        HostBottomRight.X,
        HostBottomRight.Y);

    //-------------------------------------------------------------------------
    //Sécurisation minimale :
    //- conserver une taille éditable ;
    //- éviter de sortir complètement du parent.
    //-------------------------------------------------------------------------

    If Result.Right - Result.Left < 48 Then
        Result.Right := Result.Left + 48;

    If Result.Bottom - Result.Top < 22 Then
        Result.Bottom := Result.Top + 22;

    HostClientRect := AHost.ClientRect;

    If Result.Right > HostClientRect.Right Then
        OffsetRect(
            Result,
            HostClientRect.Right - Result.Right,
            0);

    If Result.Left < HostClientRect.Left Then
        OffsetRect(
            Result,
            HostClientRect.Left - Result.Left,
            0);

    If Result.Bottom > HostClientRect.Bottom Then
        OffsetRect(
            Result,
            0,
            HostClientRect.Bottom - Result.Bottom);

    If Result.Top < HostClientRect.Top Then
        OffsetRect(
            Result,
            0,
            HostClientRect.Top - Result.Top);
End;

Procedure TNoReflowTabBarEditSupport.UpdateItemEditAppearance(
    AEdit: TEdit;
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

    AEdit.ParentFont := False;
    AEdit.Font.Assign(Font);

    //Si l'item édité est sélectionné, on applique le même enrichissement
    //typographique que le rendu standard.
    If (AIndex >= 0) And (AIndex = FItemIndex) Then
        AEdit.Font.Style := AEdit.Font.Style + FSelectedFontStyle;

    //-------------------------------------------------------------------------
    //Mode style :
    //on laisse le TEdit suivre le style VCL autant que possible.
    //
    //Mode custom :
    //on force les couleurs de texte/fond pour rester cohérent avec l'item.
    //-------------------------------------------------------------------------

    If FPaletteMode = nrtcmStyle Then Begin
        AEdit.StyleElements := [seFont, seClient, seBorder];
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

    AEdit.StyleElements := [];
    AEdit.Color := BottomColor;
    AEdit.Font.Color := TextColor;
End;

Function TNoReflowTabBarEditSupport.BeginEditItemCaption(AIndex: Integer): Boolean;
Var
    Item:        TNoReflowTabBarItem;
    Host:       TWinControl;
    EditBounds: TRect;
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

    EditBounds := GetItemEditBounds(
        AIndex,
        Host);

    If IsRectEmpty(EditBounds) Then
        Exit;

    If Not EnsureItemCaptionEditor Then
        Exit;

    FItemEdit.Parent := Host;
    FItemEditIndex := AIndex;
    FItemEditOriginalCaption := Item.Caption;

    UpdateItemEditAppearance(
        FItemEdit,
        AIndex,
        Item);

    FItemEdit.Text := Item.Caption;
    FItemEdit.SetBounds(
        EditBounds.Left,
        EditBounds.Top,
        EditBounds.Right - EditBounds.Left,
        EditBounds.Bottom - EditBounds.Top);

    FItemEdit.Visible := True;
    FItemEdit.BringToFront;
    FItemEdit.SetFocus;
    FItemEdit.SelectAll;

    Result := True;
End;

Procedure TNoReflowTabBarEditSupport.HideItemCaptionEditor;
Begin
    //-------------------------------------------------------------------------
    //Masque l'éditeur inline sans le détruire.
    //
    //L'éditeur est permanent et appartient à la TabBar.
    //Cette méthode ne fait donc qu'annuler l'édition visuelle courante.
    //-------------------------------------------------------------------------
    If FItemEdit <> Nil Then
        FItemEdit.Visible := False;

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
        NewCaption := FItemEdit.Text;

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

