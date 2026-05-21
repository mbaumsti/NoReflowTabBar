unit NoReflowTabBar_DragSupport;

{
  NoReflowTabBar_DragSupport.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Drag and drop support layer of the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Specialised drag and drop layer of the NoReflowTabBar component.

  This unit provides:
  - TNoReflowTabBarDragContext, a normalised context used by drop target
    resolution;
  - TNoReflowTabBarDragSupport, the internal, inter-zone and inter-bar drag and
    drop support layer.

  Role of this unit:
  - activate item dragging after the mouse movement threshold is reached;
  - compute insertion targets;
  - manage drag insertion markers;
  - allow or reject moves according to zones, modes and events;
  - support item exchange between compatible bars.

  Notes:
  - this unit does not change the standard item rendering pipeline;
  - it consumes already computed layout and render item information;
  - successful drop operations leave the item collection normalised by zone.
}

interface

uses
    winapi.Messages,
    System.Types,
    System.Classes,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_EventsTypes,
    NoReflowTabBar_Items,
    NoReflowTabBar_ZoneLayout,
    NoReflowTabBar_Library,
    NoReflowTabBar_EditSupport;

type

    {
      Normalised context passed to the common drag target resolution engine.

      The purpose of this record is to avoid making target calculation depend
      implicitly on FDragSourceIndex. That index is reliable only for an
      internal drag inside the same bar. It does not exist in the target bar
      during inter-bar drag and drop.
    }
    TNoReflowTabBarDragContext = record
        {
          Source item being dragged.
        }
        SourceItem: TNoReflowTabBarItem;

        {
          Logical source zone carried by the dragged item.
        }
        SourceZone: TNoReflowTabBarPinZone;
    end;

    {
      Drag and drop support class.

      This intermediate class contains the complete drag and drop behaviour:
      - internal reorder;
      - inter-zone moves;
      - inter-bar preview and drop;
      - insertion target calculation;
      - functional hover notifications.

      The final component inherits this layer through the support class chain.
      Most methods are protected because applications normally use the published
      properties and events exposed by TNoReflowTabBar.
    }
    TNoReflowTabBarDragSupport = class(TNoReflowTabBarEditSupport)
    protected
        //-----------------------------------------------------------------
        // Internal item drag and drop state
        //-----------------------------------------------------------------

        {
          True after MouseDown on an item while the drag threshold has not yet
          been reached.
        }
        FDragTracking: Boolean;

        {
          True when item drag is active and an insertion marker can be shown.
        }
        FDragActive: Boolean;

        {
          Absolute index of the item currently dragged for an internal drag.
        }
        FDragSourceIndex: Integer;

        {
          Initial mouse position used to apply the drag threshold.
        }
        FDragStartPos: TPoint;

        FItemDragHotIndex:      Integer;
        FItemDragHotSourceBar:  TObject;
        FItemDragHotSourceItem: TNoReflowTabBarItem;

        {
          Best current target computed during drag.
        }
        FDragTarget: TNoReflowTabBarDragTarget;

        FOnBeginItemDrag:   TNoReflowTabBarBeginDragItemEvent;
        FOnEndItemDrag:     TNoReflowTabBarEndDragItemEvent;
        FOnCanReorderItems: TNoReflowTabBarCanReorderItemEvent;
        FOnCanDropItem:     TNoReflowTabBarCanDropItemEvent;
        FOnItemDropped:     TNoReflowTabBarItemDroppedEvent;
        FOnItemDragOver:    TNoReflowTabBarItemDragOverEvent;
        FOnItemDragLeave:   TNoReflowTabBarItemDragLeaveEvent;

        {
          External target bar currently hovered during an item drag.

          This remains nil for historical internal drag operations.
        }
        FDragExternalTargetBar: TNoReflowTabBarDragSupport;

        Constructor Create(AOwner: TComponent); override;

        {
          Cancels any active drag before reapplying the bar position.

          This avoids keeping an insertion marker or target computed in the
          previous coordinate system.
        }
        Procedure ApplyBarPosition; override;

        {
          Changes the list of zones accepting item drag and reorder.
        }
        Procedure SetItemsReorderZones(Const Value: TNoReflowTabBarZones);

        {
          Returns True when a logical zone accepts item drag and reorder.
        }
        Function IsTabReorderZoneAllowed(APinZone: TNoReflowTabBarPinZone): Boolean;

        {
          Changes the item reorder mode.
        }
        Procedure SetItemsReorderMode(Const Value: TNoReflowTabBarDragReorderMode);

        {
          Completely resets internal drag state.

          Call this whenever the geometry context becomes invalid, for example
          after a bar position change, reorder mode cancellation or drag end.
        }
        Procedure ResetTabDragState;

        {
          Checks whether the source drag index still points to an existing,
          visible item consistent with the current render items.
        }
        Function IsTabDragSourceIndexValid: Boolean;

        {
          Returns the insertion marker reference point for an item in actual
          control coordinates.

          The point is later converted to canonical coordinates so distances can
          be compared independently from Top / Bottom / Left / Right bar
          position.
        }
        Function GetTabDragMarkerPoint(AIndex: Integer): TPoint;

        {
          Returns the absolute index of the last visible item belonging to a
          zone, according to its real visual position in the layout.

          In multi-line layouts this index is not necessarily the last physical
          item in FRenderItems. It is used to create the "insert at end of zone"
          candidate.
        }
        Function GetZoneLastVisibleItemIndex(APinZone: TNoReflowTabBarPinZone): Integer;

        {
          Clamps an insertion index inside a zone.

          Several drag paths manipulate ZoneInsertIndex: internal moves,
          inter-bar drops and user validation. Centralising the clamp avoids
          small differences between internal and external paths.
        }
        Function ClampZoneInsertIndex(
            APinZone: TNoReflowTabBarPinZone;
            AZoneInsertIndex: Integer): Integer;

        {
          Applies the actual item move after mouse release.

          The target can represent a move inside the same zone or a change of
          zone. The method converts ZoneInsertIndex to an effective move in the
          BarItems collection.
        }
        Function ApplyDraggedTabToTarget(
            ASourceIndex: Integer;
            Const ATarget: TNoReflowTabBarDragTarget): Boolean;

        {
          Returns the actual rectangle used to draw the drag insertion marker.

          For inter-zone targets the rectangle is usually already provided by
          the target. For same-zone insertions it is reconstructed around the
          marker point and the relevant item.
        }
        Function GetDragInsertMarkerRect(Const ATarget: TNoReflowTabBarDragTarget): TRect;

        {
          Returns the item index currently hovered by an item drag.

          This method uses the real bar hit-test through ItemAtPos, so it
          respects slanted shapes, overlaps, rounded corners and multi-line
          layouts.
        }
        Function GetItemDragHotIndex(
            ASourceBar: TObject;
            ASourceItem: TNoReflowTabBarItem;
            Const AClientPos: TPoint): Integer;

        {
          Fires the leave event for the currently drag-hovered item, then resets
          the hover state.
        }
        Procedure ClearItemDragHotItem;

        {
          Updates the item hovered during an item drag.

          This method does not replace insertion logic. It only adds functional
          notification when a drag passes over an existing item.
        }
        Function UpdateItemDragHotItem(
            ASourceBar: TObject;
            ASourceItem: TNoReflowTabBarItem;
            Const AClientPos: TPoint): Boolean;

        {
          Builds the normalised context for an internal drag.

          This is intentionally the only place where the drag engine reads
          FDragSourceIndex to start local target calculation.
        }
        Function BuildLocalDragContext(Out AContext: TNoReflowTabBarDragContext): Boolean;

        {
          Builds the normalised context for a drag coming from another bar.

          The target bar has no local source index. It receives only the
          business item and the source bar.
        }
        Function BuildItemDragContext(
            ASourceItem: TNoReflowTabBarItem;
            Out AContext: TNoReflowTabBarDragContext): Boolean;

        {
          Builds the best drag target for a normalised context.

          This is the common engine used by internal drag and inter-bar drag.
          Target resolution follows the same sequence:
          1) convert the mouse position to canonical coordinates;
          2) generate candidates in the logical source zone;
          3) optionally generate inter-zone candidates;
          4) select the best candidate;
          5) project it to TNoReflowTabBarDragTarget.
        }
        Function ResolveBestDragTarget(
            Const AContext: TNoReflowTabBarDragContext;
            Const P: TPoint;
            Out ATarget: TNoReflowTabBarDragTarget): Boolean;

        {
          Builds the best internal drag target for a mouse position.

          This remains the historical entry point for local drag, but now
          delegates to the common target resolution engine.
        }
        Function TryBuildTabDragTarget(
            Const P: TPoint;
            Out ATarget: TNoReflowTabBarDragTarget): Boolean;

        {
          Adds insertion candidates for empty zones.

          An empty zone must not short-circuit the whole drag resolution. It is
          only one additional candidate comparable to candidates built before
          existing items.

          This is especially important for inter-bar drag when the source item
          comes from Center, the target bar has no Center item, but it has Start
          and/or End items. The empty Center candidate must not hide all other
          possible insertion positions.
        }
        Procedure AddEmptyZoneDragCandidates(
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            Const ACanonicalMousePoint: TPoint;
            Var ABest: TNoReflowTabBarDragBestCandidate);

        {
          Adds same-zone insertion candidates.

          These candidates cover insertion before each visible item in the zone
          and insertion at the end of the zone.
        }
        procedure AddSameZoneDragCandidates(
            ASourceZone: TNoReflowTabBarPinZone;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            const ACanonicalMousePoint: TPoint;
            var ABest: TNoReflowTabBarDragBestCandidate);

        {
          Adds candidates allowing a zone change.

          Calculation is done in canonical Top coordinates:
          - beginning of line means a switch toward the previous zone;
          - end of line means a switch toward the next zone.
        }
        procedure AddInterZoneDragCandidates(
            ASourceZone: TNoReflowTabBarPinZone;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            const ACanonicalMousePoint: TPoint;
            const ACanonicalBarRect: TRect;
            const ACanonicalZoneRect: TRect;
            ACanonicalLastLineHeight: Integer;
            var ABest: TNoReflowTabBarDragBestCandidate);

        {
          Builds the canonical rectangles needed by inter-zone drag.

          The method computes the useful bar bounds, the source zone bounds and
          the height of the last visible line.
        }
        function BuildCanonicalDragContext(
            ASourceZone: TNoReflowTabBarPinZone;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            out ACanonicalBarRect: TRect;
            out ACanonicalZoneRect: TRect;
            out ACanonicalLastLineHeight: Integer): Boolean;

        {
          Converts the best internal candidate to a drag target usable by the
          bar and by marker rendering.
        }
        procedure FillDragTargetFromBestCandidate(
            const ABest: TNoReflowTabBarDragBestCandidate;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            var ATarget: TNoReflowTabBarDragTarget);

        {
          Fires OnBeginItemDrag when assigned.
        }
        Procedure DoBeginTabDrag;

        {
          Fires OnEndItemDrag when assigned.
        }
        Procedure DoEndTabDrag(
            ATab: TNoReflowTabBarItem;
            ASourceIndex: Integer;
            ASourceZone: TNoReflowTabBarPinZone;
            ATargetZone: TNoReflowTabBarPinZone;
            ATargetZoneIndex: Integer;
            ADropped: Boolean);

        {
          Asks user code whether reordering to the specified target is allowed.
        }
        Function CanReorderTabToTarget(
            ASourceTab: TNoReflowTabBarItem;
            Const ATarget: TNoReflowTabBarDragTarget): Boolean;

        {
          Returns True when this bar can initiate inter-bar item dragging.
        }
        Function CanActAsInterBarDragSource: Boolean;

        {
          Returns True when this bar can receive item drops from another bar.
        }
        Function CanActAsInterBarDragTarget: Boolean;

        {
          Checks whether two bars belong to the same inter-bar drag group.
        }
        Function IsInterBarDragGroupCompatible(ASourceBar: TNoReflowTabBarDragSupport): Boolean;

        {
          Returns True when this bar can receive an item from ASourceBar.
        }
        Function CanAcceptItemDropFrom(ASourceBar: TNoReflowTabBarDragSupport): Boolean;

        {
          Returns True when this bar wants OnItemDragOver / OnItemDragLeave
          functional notifications during inter-bar drag, even if it does not
          accept an actual drop.

          This is intentionally distinct from CanAcceptItemDropFrom:
          - CanAcceptItemDropFrom allows a real drop with an insertion marker;
          - CanReceiveItemDragOverFrom allows only item hover reactions.

          This allows, for example, a tab bar to remain in nrtbimNone while still
          activating a page when the user drags a button over a tab.
        }
        Function CanReceiveItemDragOverFrom(ASourceBar: TNoReflowTabBarDragSupport): Boolean;

        {
          Finds another compatible TNoReflowTabBarDragSupport under the mouse.
        }
        Function FindCompatibleDropBarAtScreenPos(Const AScreenPos: TPoint): TNoReflowTabBarDragSupport;

        {
          Updates preview state on an external target bar.
        }
        Function UpdateExternalDraggedBarItemPreview(Const AScreenPos: TPoint): Boolean;

        {
          Applies a drop on an external target bar when a target is active.
        }
        Function DropExternalDraggedBarItem(
            Const AScreenPos: TPoint;
            Var ATargetItem: TNoReflowTabBarItem): Boolean;

        {
          Cancels the preview displayed by the external target bar.
        }
        Procedure ClearExternalDraggedBarItemPreview;

        {
          Builds a drag target for an explicit source item.

          Unlike TryBuildTabDragTarget, this method does not require
          FDragSourceIndex. It is used by the inter-bar protocol: the target bar
          receives a source item and computes where it would accept it.
        }
        Function TryBuildTabDragTargetForItem(
            ASourceBar: TObject;
            ASourceItem: TNoReflowTabBarItem;
            Const P: TPoint;
            Out ATarget: TNoReflowTabBarDragTarget): Boolean;

        {
          Builds a special insertion target for an empty zone.

          This case is not limited to inter-bar drag. The common engine can face
          a target zone without visible items, where no FRenderItems entry can be
          used to compute proximity-based insertion.
        }
        Function TryBuildEmptyZoneDragTarget(
            ASourceZone: TNoReflowTabBarPinZone;
            Const P: TPoint;
            Out ATarget: TNoReflowTabBarDragTarget): Boolean;

        {
          Asks user code whether an explicit source item can be dropped on the
          computed target.
        }
        Function CanDropTabToTarget(
            ASourceBar: TObject;
            ASourceItem: TNoReflowTabBarItem;
            Const ATarget: TNoReflowTabBarDragTarget): Boolean;

        {
          Applies the drop of an explicit source item.

          For internal drag, the source item is moved directly. For inter-bar
          drag, the target bar creates a new item by controlled copy. The caller
          remains responsible for removing the source item when the business move
          is confirmed.
        }
        Function ApplyDroppedTabFromBar(
            ASourceBar: TObject;
            ASourceItem: TNoReflowTabBarItem;
            Const ATarget: TNoReflowTabBarDragTarget;
            Var ATargetItem: TNoReflowTabBarItem): Boolean;

    public
        {
          Returns the drag target currently computed for this bar.

          This avoids external bars having to access the internal FDragTarget
          field directly, especially during inter-bar drag.
        }
        Function GetCurrentDragTarget(Var ATarget: TNoReflowTabBarDragTarget): Boolean;

        {
          Previews the drop of an item coming from a source bar.

          The target bar computes its own target, applies its acceptance rules
          and displays its insertion marker when the drop is possible.
        }
        Function PreviewDraggedBarItem(
            ASourceBar: TObject;
            ASourceItem: TNoReflowTabBarItem;
            Const AClientPos: TPoint): Boolean;

        {
          Cancels the current external drop preview.
        }
        Procedure CancelDraggedBarItemPreview;

        {
          Drops an item coming from a source bar.

          The method returns the item effectively present in the target bar:
          - the same object for an internal drag;
          - a newly copied object for an inter-bar drag.
        }
        Function DropDraggedBarItem(
            ASourceBar: TObject;
            ASourceItem: TNoReflowTabBarItem;
            Const AClientPos: TPoint;
            Var ATargetItem: TNoReflowTabBarItem): Boolean;
    end;

Const
    {
      Canonical offset used when switching between zones during drag.
    }
    CDragInterZoneSwitchOffset = 8;

    {
      Minimum width of an inter-zone insertion marker.
    }
    CDragInterZoneMarkerMinWidth = 16;

    {
      Thickness of the drag insertion marker.
    }
    CDragMarkerThickness = 3;

    {
      Padding around the drag insertion marker.
    }
    CDragMarkerPad = 2;

implementation


uses
    System.Math,
    System.SysUtils,
    Vcl.Controls;

Constructor TNoReflowTabBarDragSupport.Create(AOwner: TComponent);
Begin
    Inherited Create(AOwner);

    ClearExternalDraggedBarItemPreview;

    FDragTracking := False;
    FDragActive := False;
    FDragSourceIndex := -1;
    FDragStartPos := Point(
        -1,
        -1);
    FItemDragHotIndex := -1;
    FItemDragHotSourceBar := Nil;
    FItemDragHotSourceItem := Nil;
    FDragTarget.Init;
    FDragExternalTargetBar := Nil;

End;

Procedure TNoReflowTabBarDragSupport.SetItemsReorderZones(Const Value: TNoReflowTabBarZones);
Begin
    If FItemsReorderZones = Value Then
        Exit;

    FItemsReorderZones := Value;

    //Si la configuration change pendant un drag, la cible courante n'est plus fiable.
    ResetTabDragState;
    Invalidate;
End;

Function TNoReflowTabBarDragSupport.IsTabReorderZoneAllowed(APinZone: TNoReflowTabBarPinZone): Boolean;
Begin
    Result := PinZoneToReorderZone(APinZone) In FItemsReorderZones;
End;

Procedure TNoReflowTabBarDragSupport.ApplyBarPosition;
Begin
    ResetTabDragState;
    Inherited ApplyBarPosition;
End;

Procedure TNoReflowTabBarDragSupport.SetItemsReorderMode(Const Value: TNoReflowTabBarDragReorderMode);
Begin
    If FItemsReorderMode = Value Then
        Exit;

    FItemsReorderMode := Value;

    //Si le mode est désactivé pendant un drag en cours, on annule
    //immédiatement l'état de drag pour éviter un marqueur fantôme.
    If FItemsReorderMode = nrbrmNone Then Begin
        ResetTabDragState;
        Invalidate;
    End;
End;

Procedure TNoReflowTabBarDragSupport.ResetTabDragState;
Begin
    //-------------------------------------------------------------------------
    //Réinitialise tous les états temporaires liés au drag.
    //
    //On annule aussi FPressedItemIndex, car dès qu'un drag commence ou qu'un
    //tracking souris est réinitialisé, l'état "bouton pressé" ne doit plus
    //rester affiché.
    //-------------------------------------------------------------------------

    ClearItemDragHotItem;

    FDragTracking := False;
    FDragActive := False;
    FDragSourceIndex := -1;
    FPressedItemIndex := -1;
    FItemDragHotIndex := -1;
    FItemDragHotSourceBar := Nil;
    FItemDragHotSourceItem := Nil;
    FDragStartPos := Point(
        -1,
        -1);

    FDragTarget.Init;
End;

Function TNoReflowTabBarDragSupport.IsTabDragSourceIndexValid: Boolean;
Begin
    Result := (FDragSourceIndex >= 0) And (FDragSourceIndex < FItems.Count) And (FDragSourceIndex < Length(FRenderItems)) And (FItems[FDragSourceIndex] <> Nil) And
        FRenderItems[FDragSourceIndex].Visible;
End;

Function TNoReflowTabBarDragSupport.GetTabDragMarkerPoint(AIndex: Integer): TPoint;
Var
    R:               TRect;
    CanonicalR:      TRect;
    MarkerPt:        TPoint;
    FlowOrientation: TNoReflowTabBarZoneFlowOrientation;
Begin
    Result := Point(
        0,
        0);

    If (AIndex < 0) Or (AIndex >= Length(FRenderItems)) Then
        Exit;

    FlowOrientation := GetZoneFlowOrientation;

    R := FRenderItems[AIndex].Bounds;

    //-------------------------------------------------------------------------
    //Le point d'insertion est calculé dans le repère canonique du layout.
    //
    //On conserve uniquement ici la détermination du type de repère
    //horizontal / vertical. Le détail Top / Bottom / Left / Right est ensuite
    //pris en charge par les transformations du moteur de layout.
    //-------------------------------------------------------------------------

    CanonicalR := TNoReflowTabBarZoneLayoutEngine.TransformActualRectToCanonical(
        R,
        FlowOrientation,
        FBarPosition,
        ClientWidth,
        ClientHeight);

    MarkerPt := Point(
        CanonicalR.Left,
        (CanonicalR.Top + CanonicalR.Bottom) Div 2);

    Result := TNoReflowTabBarZoneLayoutEngine.TransformCanonicalPointToActual(
        MarkerPt,
        FlowOrientation,
        FBarPosition,
        ClientWidth,
        ClientHeight);
End;

Function TNoReflowTabBarDragSupport.GetZoneLastVisibleItemIndex(APinZone: TNoReflowTabBarPinZone): Integer;
Var
    I:                 Integer;
    FlowOrientation:   TNoReflowTabBarZoneFlowOrientation;
    CanonicalRect:     TRect;
    BestCanonicalRect: TRect;
    BestIndex:         Integer;
    HasBest:           Boolean;
    SameLineAsBest:    Boolean;
Begin
    //-------------------------------------------------------------------------
    //Retourne le dernier item visible d'une zone selon le layout visuel réel.
    //
    //Important :
    //il ne faut pas se baser sur l'ordre physique de FRenderItems.
    //En multi-ligne, le dernier item de la collection peut parfaitement se
    //trouver sur une ligne supérieure, selon les contraintes de layout.
    //
    //La logique correcte est donc :
    //1) travailler en repère canonique TOP
    //2) trouver la ligne visuellement la plus basse de la zone
    //3) dans cette ligne, prendre l'item le plus à droite
    //
    //Ce résultat sert notamment à construire le candidat "insertion en fin
    //de zone", qui doit toujours apparaître après le dernier item visuel.
    //-------------------------------------------------------------------------

    Result := -1;

    FlowOrientation := GetZoneFlowOrientation;

    BestIndex := -1;
    HasBest := False;
    BestCanonicalRect := Rect(
        0,
        0,
        0,
        0);

    For I := 0 To High(FRenderItems) Do Begin
        If Not FRenderItems[I].Visible Then
            Continue;

        If FRenderItems[I].Item = Nil Then
            Continue;

        If FRenderItems[I].Item.PinZone <> APinZone Then
            Continue;

        CanonicalRect := TNoReflowTabBarZoneLayoutEngine.TransformActualRectToCanonical(
            FRenderItems[I].Bounds,
            FlowOrientation,
            FBarPosition,
            ClientWidth,
            ClientHeight);

        If Not HasBest Then Begin
            BestIndex := I;
            BestCanonicalRect := CanonicalRect;
            HasBest := True;
            Continue;
        End;

        SameLineAsBest := SameCanonicalLine(
            CanonicalRect,
            BestCanonicalRect);

        //Nouvelle ligne plus basse : elle devient prioritaire.
        If CanonicalRect.Top > BestCanonicalRect.Top Then Begin
            BestIndex := I;
            BestCanonicalRect := CanonicalRect;
            Continue;
        End;

        //Même ligne canonique : on prend l'item le plus à droite.
        If SameLineAsBest And (CanonicalRect.Right > BestCanonicalRect.Right) Then Begin
            BestIndex := I;
            BestCanonicalRect := CanonicalRect;
            Continue;
        End;
    End;

    Result := BestIndex;
End;

Function TNoReflowTabBarDragSupport.ClampZoneInsertIndex(
    APinZone: TNoReflowTabBarPinZone;
    AZoneInsertIndex: Integer): Integer;
Var
    ItemCount: Integer;
Begin
    Result := AZoneInsertIndex;

    If Result < 0 Then
        Result := 0;

    ItemCount := GetItemsCountInZone(APinZone);

    If Result > ItemCount Then
        Result := ItemCount;
End;

Function TNoReflowTabBarDragSupport.ApplyDraggedTabToTarget(
    ASourceIndex: Integer;
    Const ATarget: TNoReflowTabBarDragTarget): Boolean;
Var
    SourceTab:       TNoReflowTabBarItem;
    TargetTab:       TNoReflowTabBarItem;
    TargetZoneIndex: Integer;
Begin
    Result := False;

    If Not ATarget.Valid Then
        Exit;

    If (ASourceIndex < 0) Or (ASourceIndex >= FItems.Count) Then
        Exit;

    SourceTab := FItems[ASourceIndex];
    If SourceTab = Nil Then
        Exit;

    If Not CanReorderTabToTarget(SourceTab, ATarget) Then
        Exit;

    TargetZoneIndex := ClampZoneInsertIndex(
        ATarget.PinZone,
        ATarget.ZoneInsertIndex);

    If (ATarget.TargetItemIndex >= 0) And (ATarget.TargetItemIndex < FItems.Count) Then Begin
        TargetTab := FItems[ATarget.TargetItemIndex];
        If TargetTab <> Nil Then
            TargetZoneIndex := TargetTab.ZoneIndex;

        If ATarget.InsertKind = nrtdikAfterTab Then
            Inc(TargetZoneIndex);
    End;

    If SourceTab.PinZone = ATarget.PinZone Then Begin
        If TargetZoneIndex > SourceTab.ZoneIndex Then
            Dec(TargetZoneIndex);

        MoveItemInZone(
            SourceTab,
            TargetZoneIndex);
    End
    Else
        MoveItemToZone(
            SourceTab,
            ATarget.PinZone,
            TargetZoneIndex);

    Result := True;
End;

Function TNoReflowTabBarDragSupport.GetDragInsertMarkerRect(Const ATarget: TNoReflowTabBarDragTarget): TRect;
Var
    R:               TRect;
    CanonicalR:      TRect;
    CanonicalPoint:  TPoint;
    CanonicalRect:   TRect;
    FlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    MarkerHeight:    Integer;
    MarkerTop:       Integer;
    MarkerBottom:    Integer;
    ReferenceIndex:  Integer;
Begin
    If Not IsRectEmpty(ATarget.MarkerRect) Then Begin
        Result := ATarget.MarkerRect;
        Exit;
    End;

    Result := Rect(
        0,
        0,
        0,
        0);

    If Not ATarget.Valid Then
        Exit;

    FlowOrientation := GetZoneFlowOrientation;

    If (ATarget.TargetItemIndex >= 0) And (ATarget.TargetItemIndex < Length(FRenderItems)) Then
        R := FRenderItems[ATarget.TargetItemIndex].Bounds
    Else Begin
        //---------------------------------------------------------------------
        //Insertion en fin de zone : TargetItemIndex = -1.
        //
        //Le rectangle de référence ne doit pas venir de FDragSourceIndex.
        //Cet index n'existe que dans la barre source pendant un drag interne.
        //Lors d'un drag inter-barres, la barre cible doit construire son
        //marqueur uniquement à partir de sa propre géométrie.
        //
        //On prend donc le dernier item visible de la zone cible. Ce rectangle
        //sert seulement à fournir une hauteur cohérente au marqueur ; la
        //position réelle reste portée par ATarget.MarkerPoint.
        //---------------------------------------------------------------------
        ReferenceIndex := GetZoneLastVisibleItemIndex(ATarget.PinZone);

        If (ReferenceIndex >= 0) And (ReferenceIndex < Length(FRenderItems)) Then
            R := FRenderItems[ReferenceIndex].Bounds
        Else If IsTabDragSourceIndexValid Then
            R := FRenderItems[FDragSourceIndex].Bounds
        Else
            Exit;
    End;

    CanonicalR := TNoReflowTabBarZoneLayoutEngine.TransformActualRectToCanonical(
        R,
        FlowOrientation,
        FBarPosition,
        ClientWidth,
        ClientHeight);

    CanonicalPoint := TNoReflowTabBarZoneLayoutEngine.TransformActualPointToCanonical(
        ATarget.MarkerPoint,
        FlowOrientation,
        FBarPosition,
        ClientWidth,
        ClientHeight);

    //-------------------------------------------------------------------------
    //Cas normal : insertion avant un item existant.
    //
    //Le marqueur reprend alors naturellement la hauteur canonique de l'item
    //cible, donc sa ligne visuelle.
    //
    //Cas particulier : insertion en fin de zone.
    //
    //Dans ce cas TargetItemIndex = -1. Il ne faut surtout pas reprendre
    //CanonicalR.Top / Bottom de l'item source, car cela ramène le marqueur
    //sur la ligne de l'item déplacé.
    //
    //On garde seulement la hauteur de référence, mais on centre cette hauteur
    //sur ATarget.MarkerPoint, qui lui porte la bonne ligne canonique.
    //-------------------------------------------------------------------------
    If ATarget.TargetItemIndex >= 0 Then Begin
        MarkerTop := CanonicalR.Top - CDragMarkerPad;
        MarkerBottom := CanonicalR.Bottom + CDragMarkerPad;
    End Else Begin
        MarkerHeight := CanonicalR.Height;

        If MarkerHeight < 1 Then
            MarkerHeight := 1;

        MarkerTop := CanonicalPoint.Y - (MarkerHeight Div 2) - CDragMarkerPad;
        MarkerBottom := CanonicalPoint.Y + ((MarkerHeight + 1) Div 2) + CDragMarkerPad;
    End;

    CanonicalRect := Rect(
        CanonicalPoint.X - (CDragMarkerThickness Div 2),
        MarkerTop,
        CanonicalPoint.X - (CDragMarkerThickness Div 2) + CDragMarkerThickness,
        MarkerBottom);

    Result := TNoReflowTabBarZoneLayoutEngine.TransformCanonicalRectToActual(
        CanonicalRect,
        FlowOrientation,
        FBarPosition,
        ClientWidth,
        ClientHeight);
End;

Function TNoReflowTabBarDragSupport.GetItemDragHotIndex(
    ASourceBar: TObject;
    ASourceItem: TNoReflowTabBarItem;
    Const AClientPos: TPoint): Integer;
Var
    ItemIndex: Integer;
    Item:      TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Recherche l'item réellement survolé pendant un drag.
    //
    //Important :
    //on ne déduit pas cet item depuis FDragTarget.TargetItemIndex.
    //La cible d'insertion représente l'endroit où l'item serait inséré,
    //alors que le besoin métier ici est différent : savoir quel onglet est
    //effectivement sous la souris.
    //
    //Exemple :
    //- le marqueur peut être "avant l'item B" ;
    //- mais l'application veut savoir que l'item B est survolé pour activer
    //sa page.
    //-------------------------------------------------------------------------
    Result := -1;

    EnsureRenderInfo;

    ItemIndex := ItemAtPos(AClientPos);
    If ItemIndex < 0 Then
        Exit;

    If ItemIndex >= FItems.Count Then
        Exit;

    Item := FItems[ItemIndex];
    If Item = Nil Then
        Exit;

    //Pendant un drag interne, on évite de signaler l'item source comme cible
    //fonctionnelle de son propre drag. Cela évite les réactions parasites
    //lorsque la souris est encore sur l'onglet en cours de déplacement.
    If (ASourceBar = Self) And (Item = ASourceItem) Then
        Exit;

    Result := ItemIndex;
End;

Procedure TNoReflowTabBarDragSupport.ClearItemDragHotItem;
Var
    OldIndex: Integer;
    OldItem:  TNoReflowTabBarItem;
Begin
    OldIndex := FItemDragHotIndex;

    If OldIndex < 0 Then Begin
        FItemDragHotSourceBar := Nil;
        FItemDragHotSourceItem := Nil;
        Exit;
    End;

    If (OldIndex >= 0) And (OldIndex < FItems.Count) Then Begin
        OldItem := FItems[OldIndex];

        If Assigned(FOnItemDragLeave) Then
            FOnItemDragLeave(
                Self,
                FItemDragHotSourceBar,
                FItemDragHotSourceItem,
                OldIndex,
                OldItem);
    End;

    FItemDragHotIndex := -1;
    FItemDragHotSourceBar := Nil;
    FItemDragHotSourceItem := Nil;
End;

Function TNoReflowTabBarDragSupport.UpdateItemDragHotItem(
    ASourceBar: TObject;
    ASourceItem: TNoReflowTabBarItem;
    Const AClientPos: TPoint): Boolean;
Var
    NewIndex: Integer;
    NewItem:  TNoReflowTabBarItem;
    Accept:   Boolean;
Begin
    //-------------------------------------------------------------------------
    //Met à jour l'item survolé pendant un drag.
    //
    //Cette logique est volontairement indépendante de la cible d'insertion :
    //- le marqueur d'insertion continue d'être calculé par ResolveBestDragTarget ;
    //- l'événement OnItemDragOver sert uniquement aux réactions fonctionnelles
    //de l'application, par exemple activer une page de menu.
    //-------------------------------------------------------------------------
    Result := False;

    If ASourceItem = Nil Then Begin
        ClearItemDragHotItem;
        Exit;
    End;

    NewIndex := GetItemDragHotIndex(
        ASourceBar,
        ASourceItem,
        AClientPos);

    If NewIndex < 0 Then Begin
        ClearItemDragHotItem;
        Exit;
    End;

    If NewIndex >= FItems.Count Then Begin
        ClearItemDragHotItem;
        Exit;
    End;

    NewItem := FItems[NewIndex];
    If NewItem = Nil Then Begin
        ClearItemDragHotItem;
        Exit;
    End;

    //Si l'item change, on notifie d'abord la sortie de l'ancien item.
    If NewIndex <> FItemDragHotIndex Then
        ClearItemDragHotItem;

    Accept := True;

    If Assigned(FOnItemDragOver) Then
        FOnItemDragOver(
            Self,
            ASourceBar,
            ASourceItem,
            NewIndex,
            NewItem,
            Accept);

    If Not Accept Then Begin
        //Si l'application refuse le survol fonctionnel, on ne conserve pas
        //cet item comme item chaud. Le marqueur d'insertion, lui, reste libre
        //de continuer à fonctionner.
        If NewIndex = FItemDragHotIndex Then
            ClearItemDragHotItem;

        Exit;
    End;

    FItemDragHotIndex := NewIndex;
    FItemDragHotSourceBar := ASourceBar;
    FItemDragHotSourceItem := ASourceItem;

    Result := True;
End;

Procedure TNoReflowTabBarDragSupport.AddEmptyZoneDragCandidates(
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    Const ACanonicalMousePoint: TPoint;
    Var ABest: TNoReflowTabBarDragBestCandidate);
Var
    Zones:                 Array[0..2] Of TNoReflowTabBarPinZone;
    ZoneIndex:             Integer;
    CandidateZone:         TNoReflowTabBarPinZone;
    CanonicalBarRect:      TRect;
    CanonicalStartRect:    TRect;
    CanonicalCenterRect:   TRect;
    CanonicalEndRect:      TRect;
    HasBarRect:            Boolean;
    HasStartRect:          Boolean;
    HasCenterRect:         Boolean;
    HasEndRect:            Boolean;
    CandidatePoint:        TPoint;
    MarkerCanonicalRect:   TRect;
    MarkerActualRect:      TRect;
    MarkerWidth:           Integer;
    DX:                    Integer;
    DY:                    Integer;
    Dist2:                 Int64;

    Function BuildCanonicalRectForZone(
        APinZone: TNoReflowTabBarPinZone;
        Out ARect: TRect): Boolean;
    Var
        I:        Integer;
        TestRect: TRect;
    Begin
        //---------------------------------------------------------------------
        //Construit l'emprise canonique des items visibles d'une zone.
        //
        //Cette méthode ne dépend pas de l'ordre physique de FItems. Elle s'appuie
        //sur FRenderItems, donc sur la géométrie réellement affichée.
        //---------------------------------------------------------------------

        Result := False;

        ARect := Rect(
            0,
            0,
            0,
            0);

        For I := 0 To High(FRenderItems) Do Begin
            If Not FRenderItems[I].Visible Then
                Continue;

            If FRenderItems[I].Item = Nil Then
                Continue;

            If FRenderItems[I].Item.PinZone <> APinZone Then
                Continue;

            TestRect := TNoReflowTabBarZoneLayoutEngine.TransformActualRectToCanonical(
                FRenderItems[I].Bounds,
                AFlowOrientation,
                FBarPosition,
                ClientWidth,
                ClientHeight);

            If Not Result Then Begin
                ARect := TestRect;
                Result := True;
            End Else Begin
                If TestRect.Left < ARect.Left Then
                    ARect.Left := TestRect.Left;

                If TestRect.Right > ARect.Right Then
                    ARect.Right := TestRect.Right;

                If TestRect.Top < ARect.Top Then
                    ARect.Top := TestRect.Top;

                If TestRect.Bottom > ARect.Bottom Then
                    ARect.Bottom := TestRect.Bottom;
            End;
        End;
    End;

    Procedure ExtendCanonicalBarRect(Const ARect: TRect);
    Begin
        //---------------------------------------------------------------------
        //Étend l'emprise globale utilisée pour placer les marqueurs de zones
        //vides. On garde une emprise basée sur les items réels, afin de ne pas
        //dessiner un marqueur démesuré dans toute la hauteur du composant.
        //---------------------------------------------------------------------

        If Not HasBarRect Then Begin
            CanonicalBarRect := ARect;
            HasBarRect := True;
        End Else Begin
            If ARect.Left < CanonicalBarRect.Left Then
                CanonicalBarRect.Left := ARect.Left;

            If ARect.Right > CanonicalBarRect.Right Then
                CanonicalBarRect.Right := ARect.Right;

            If ARect.Top < CanonicalBarRect.Top Then
                CanonicalBarRect.Top := ARect.Top;

            If ARect.Bottom > CanonicalBarRect.Bottom Then
                CanonicalBarRect.Bottom := ARect.Bottom;
        End;
    End;

    Function ResolveEmptyZoneCandidatePoint(
        APinZone: TNoReflowTabBarPinZone;
        Out APoint: TPoint): Boolean;
    Begin
        //---------------------------------------------------------------------
        //Calcule un point canonique représentatif d'une zone vide.
        //
        //Le but n'est pas de modifier le layout : on fabrique simplement un
        //point de comparaison stable pour que la zone vide puisse participer au
        //choix du meilleur candidat.
        //
        //Ordre logique :
        //Start -> Center -> End
        //---------------------------------------------------------------------

        Result := False;

        If Not HasBarRect Then Begin
            APoint := Point(
                ClientWidth Div 2,
                ClientHeight Div 2);
            Result := True;
            Exit;
        End;

        Case APinZone Of
            nrtpzStart:
                Begin
                    If HasCenterRect Then
                        APoint.X := CanonicalCenterRect.Left - FLayout.ZoneSpacing
                    Else If HasEndRect Then
                        APoint.X := CanonicalEndRect.Left - FLayout.ZoneSpacing
                    Else
                        APoint.X := CanonicalBarRect.Left - FLayout.ZoneSpacing;

                    APoint.Y := (CanonicalBarRect.Top + CanonicalBarRect.Bottom) Div 2;
                    Result := True;
                End;

            nrtpzCenter:
                Begin
                    If HasStartRect And HasEndRect Then
                        APoint.X := (CanonicalStartRect.Right + CanonicalEndRect.Left) Div 2
                    Else If HasStartRect Then
                        APoint.X := CanonicalStartRect.Right + FLayout.ZoneSpacing
                    Else If HasEndRect Then
                        APoint.X := CanonicalEndRect.Left - FLayout.ZoneSpacing
                    Else
                        APoint.X := (CanonicalBarRect.Left + CanonicalBarRect.Right) Div 2;

                    APoint.Y := (CanonicalBarRect.Top + CanonicalBarRect.Bottom) Div 2;
                    Result := True;
                End;

            nrtpzEnd:
                Begin
                    If HasCenterRect Then
                        APoint.X := CanonicalCenterRect.Right + FLayout.ZoneSpacing
                    Else If HasStartRect Then
                        APoint.X := CanonicalStartRect.Right + FLayout.ZoneSpacing
                    Else
                        APoint.X := CanonicalBarRect.Right + FLayout.ZoneSpacing;

                    APoint.Y := (CanonicalBarRect.Top + CanonicalBarRect.Bottom) Div 2;
                    Result := True;
                End;
        End;
    End;

    Procedure AcceptEmptyZoneCandidate(
        APinZone: TNoReflowTabBarPinZone;
        Const APoint: TPoint);
    Begin
        DX := ACanonicalMousePoint.X - APoint.X;
        DY := ACanonicalMousePoint.Y - APoint.Y;
        Dist2 := Int64(DX) * DX + Int64(DY) * DY;

        If Dist2 >= ABest.Dist2 Then
            Exit;

        MarkerCanonicalRect := Rect(
            APoint.X - (MarkerWidth Div 2),
            CanonicalBarRect.Top,
            APoint.X + (MarkerWidth Div 2),
            CanonicalBarRect.Bottom);

        MarkerActualRect := TNoReflowTabBarZoneLayoutEngine.TransformCanonicalRectToActual(
            MarkerCanonicalRect,
            AFlowOrientation,
            FBarPosition,
            ClientWidth,
            ClientHeight);

        ABest.Valid := True;
        ABest.Dist2 := Dist2;
        ABest.TargetKind := nrtdtkSameZone;
        ABest.TargetItemIndex := -1;
        ABest.PinZone := APinZone;
        ABest.ZoneInsertIndex := 0;
        ABest.CanonicalPoint := APoint;
        ABest.MarkerRect := MarkerActualRect;
        ABest.MarkerCanonicalRect := MarkerCanonicalRect;
        ABest.MarkerCanonicalDirection := Point(
            0,
            0);
        ABest.InterZoneDirection := 0;
    End;

Begin
    //---------------------------------------------------------------------
    //Une zone vide doit être traitée comme un candidat, pas comme un fallback
    //prioritaire.
    //
    //Cela permet de comparer correctement :
    //- insertion devant un item Start existant ;
    //- insertion dans Center vide ;
    //- insertion devant / après des items End existants ;
    //- insertion dans une autre zone vide autorisée.
    //---------------------------------------------------------------------

    MarkerWidth := Max(
        FLayout.ZoneSpacing,
        CDragInterZoneMarkerMinWidth);

    If MarkerWidth < CDragMarkerThickness Then
        MarkerWidth := CDragMarkerThickness;

    Zones[0] := nrtpzStart;
    Zones[1] := nrtpzCenter;
    Zones[2] := nrtpzEnd;

    HasBarRect := False;

    HasStartRect := BuildCanonicalRectForZone(
        nrtpzStart,
        CanonicalStartRect);

    If HasStartRect Then
        ExtendCanonicalBarRect(CanonicalStartRect);

    HasCenterRect := BuildCanonicalRectForZone(
        nrtpzCenter,
        CanonicalCenterRect);

    If HasCenterRect Then
        ExtendCanonicalBarRect(CanonicalCenterRect);

    HasEndRect := BuildCanonicalRectForZone(
        nrtpzEnd,
        CanonicalEndRect);

    If HasEndRect Then
        ExtendCanonicalBarRect(CanonicalEndRect);

    If Not HasBarRect Then Begin
        CanonicalBarRect := Rect(
            2,
            2,
            ClientWidth - 2,
            ClientHeight - 2);

        HasBarRect := True;
    End;

    If CanonicalBarRect.Bottom <= CanonicalBarRect.Top Then
        CanonicalBarRect.Bottom := CanonicalBarRect.Top + CDragMarkerThickness;

    For ZoneIndex := Low(Zones) To High(Zones) Do Begin
        CandidateZone := Zones[ZoneIndex];

        If Not IsTabReorderZoneAllowed(CandidateZone) Then
            Continue;

        If GetItemsCountInZone(CandidateZone) <> 0 Then
            Continue;

        If Not ResolveEmptyZoneCandidatePoint(
            CandidateZone,
            CandidatePoint) Then
            Continue;

        AcceptEmptyZoneCandidate(
            CandidateZone,
            CandidatePoint);
    End;
End;

Procedure TNoReflowTabBarDragSupport.AddSameZoneDragCandidates(
    ASourceZone: TNoReflowTabBarPinZone;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    Const ACanonicalMousePoint: TPoint;
    Var ABest: TNoReflowTabBarDragBestCandidate);
Var
    I:               Integer;
    LastIndexInZone: Integer;
    CandidatePoint:  TPoint;
    LastRect:        TRect;
    DX:              Integer;
    DY:              Integer;
    Dist2:           Int64;

    Procedure AcceptCandidate(
        ADist2: Int64;
        ATargetItemIndex: Integer;
        AZoneInsertIndex: Integer;
        Const ACanonicalPoint: TPoint);
    Begin
        If ADist2 >= ABest.Dist2 Then
            Exit;

        ABest.Valid := True;
        ABest.Dist2 := ADist2;
        ABest.TargetKind := nrtdtkSameZone;
        ABest.TargetItemIndex := ATargetItemIndex;
        ABest.PinZone := ASourceZone;
        ABest.ZoneInsertIndex := AZoneInsertIndex;
        ABest.CanonicalPoint := ACanonicalPoint;
        ABest.MarkerRect := Rect(
            0,
            0,
            0,
            0);
        ABest.MarkerCanonicalRect := Rect(
            0,
            0,
            0,
            0);
        ABest.MarkerCanonicalDirection := Point(
            0,
            0);
        ABest.InterZoneDirection := 0;
    End;

Begin
    //----------------------------------------------------------------------
    //Candidats same-zone : insertion avant chaque item visible de la zone.
    //
    //Chaque point candidat est converti en repère canonique pour que le
    //calcul de distance reste identique en Top / Bottom / Left / Right.
    //----------------------------------------------------------------------

    If Not IsTabReorderZoneAllowed(ASourceZone) Then
        Exit;

    For I := 0 To High(FRenderItems) Do Begin
        If Not FRenderItems[I].Visible Then
            Continue;

        If (FRenderItems[I].Item = Nil) Or (FRenderItems[I].Item.PinZone <> ASourceZone) Then
            Continue;

        CandidatePoint := TNoReflowTabBarZoneLayoutEngine.TransformActualPointToCanonical(
            GetTabDragMarkerPoint(I),
            AFlowOrientation,
            FBarPosition,
            ClientWidth,
            ClientHeight);

        DX := ACanonicalMousePoint.X - CandidatePoint.X;
        DY := ACanonicalMousePoint.Y - CandidatePoint.Y;
        Dist2 := Int64(DX) * DX + Int64(DY) * DY;

        AcceptCandidate(
            Dist2,
            I,
            FRenderItems[I].Item.ZoneIndex,
            CandidatePoint);
    End;

    //----------------------------------------------------------------------
    //Candidat same-zone : insertion après le dernier item de la zone.
    //
    //Ce candidat permet de déplacer un item en dernière position de sa
    //zone actuelle, sans déclencher un changement de zone.
    //----------------------------------------------------------------------

    LastIndexInZone := GetZoneLastVisibleItemIndex(ASourceZone);
    If LastIndexInZone < 0 Then
        Exit;

    LastRect := TNoReflowTabBarZoneLayoutEngine.TransformActualRectToCanonical(
        FRenderItems[LastIndexInZone].Bounds,
        AFlowOrientation,
        FBarPosition,
        ClientWidth,
        ClientHeight);

    CandidatePoint := Point(
        LastRect.Right,
        (LastRect.Top + LastRect.Bottom) Div 2);

    DX := ACanonicalMousePoint.X - CandidatePoint.X;
    DY := ACanonicalMousePoint.Y - CandidatePoint.Y;
    Dist2 := Int64(DX) * DX + Int64(DY) * DY;

    AcceptCandidate(
        Dist2,
        -1,
        GetItemsCountInZone(ASourceZone),
        CandidatePoint);
End;

Function TNoReflowTabBarDragSupport.BuildLocalDragContext(Out AContext: TNoReflowTabBarDragContext): Boolean;
Var
    SourceTab: TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Construit le contexte d'un drag local.
    //
    //FDragSourceIndex reste une donnée d'état de la barre source. Le moteur
    //commun ne doit pas aller le relire ensuite : il reçoit ici une copie
    //normalisée de l'information utile.
    //-------------------------------------------------------------------------
    Result := False;

    AContext.SourceItem := Nil;
    AContext.SourceZone := nrtpzNone;

    If Not IsTabDragSourceIndexValid Then
        Exit;

    SourceTab := FItems[FDragSourceIndex];
    If SourceTab = Nil Then
        Exit;

    AContext.SourceItem := SourceTab;
    AContext.SourceZone := SourceTab.PinZone;

    Result := True;
End;

Function TNoReflowTabBarDragSupport.BuildItemDragContext(
    ASourceItem: TNoReflowTabBarItem;
    Out AContext: TNoReflowTabBarDragContext): Boolean;
Begin
    //-------------------------------------------------------------------------
    //Construit le contexte d'un drag portant sur un item explicite.
    //
    //La barre cible ne doit pas dépendre d'un index source local. Toute la
    //géométrie de cible est reconstruite depuis les items visibles de cette
    //barre, à partir de la zone logique portée par l'item source.
    //-------------------------------------------------------------------------
    Result := False;

    AContext.SourceItem := ASourceItem;
    AContext.SourceZone := nrtpzNone;

    If ASourceItem = Nil Then
        Exit;

    AContext.SourceZone := ASourceItem.PinZone;

    Result := True;
End;

Function TNoReflowTabBarDragSupport.ResolveBestDragTarget(
    Const AContext: TNoReflowTabBarDragContext;
    Const P: TPoint;
    Out ATarget: TNoReflowTabBarDragTarget): Boolean;
Var
    Best:                    TNoReflowTabBarDragBestCandidate;
    FlowOrientation:         TNoReflowTabBarZoneFlowOrientation;
    CanonicalMousePoint:     TPoint;
    CanonicalZoneRect:       TRect;
    CanonicalBarRect:        TRect;
    CanonicalLastLineHeight: Integer;
Begin
    //-------------------------------------------------------------------------
    //Moteur unique de résolution de cible.
    //
    //Le même pipeline est utilisé pour le drag interne et pour le drag externe.
    //La différence entre les deux cas est contenue dans AContext, pas dans deux
    //branches de calcul séparées. Cela évite les divergences de maintenance,
    //comme le cas où la fin de zone fonctionnait en interne mais pas en
    //inter-barres faute de FDragSourceIndex local.
    //-------------------------------------------------------------------------
    ATarget.Init;
    Result := False;

    If AContext.SourceItem = Nil Then
        Exit;

    If FItemsReorderMode = nrbrmNone Then
        Exit;

    EnsureRenderInfo;

    If Not IsTabReorderZoneAllowed(AContext.SourceZone) Then
        Exit;

    If (FItemsReorderMode <> nrbrmSameZoneOnly) And (FItemsReorderMode <> nrbrmAllZones) Then
        Exit;

    FlowOrientation := GetZoneFlowOrientation;

//    //-------------------------------------------------------------------------
//    //Zone vide : aucun FRenderItems ne peut fournir de point de comparaison.
//    //
//    //Ce cas est surtout utile en drag inter-barres, mais il est volontairement
//    //placé dans le moteur commun : si un autre scénario aboutit à une zone
//    //cible vide, le comportement restera identique.
//    //-------------------------------------------------------------------------
//    If TryBuildEmptyZoneDragTarget(AContext.SourceZone, P, ATarget) Then Begin
//        Result := True;
//        Exit;
//    End;

    CanonicalMousePoint := TNoReflowTabBarZoneLayoutEngine.TransformActualPointToCanonical(
        P,
        FlowOrientation,
        FBarPosition,
        ClientWidth,
        ClientHeight);

//    Best.Init;
//
//    //-------------------------------------------------------------------------
//    //Candidats dans la zone logique de départ.
//    //
//    //Pour un drag interne, cette zone est celle de l'item déplacé dans la même
//    //barre. Pour un drag inter-barres, c'est la zone logique de l'item source,
//    //rejouée dans la barre cible.
//    //-------------------------------------------------------------------------
//    AddSameZoneDragCandidates(
//        AContext.SourceZone,
//        FlowOrientation,
//        CanonicalMousePoint,
//        Best);

    Best.Init;

    //-------------------------------------------------------------------------
    //Candidats dans les zones contenant déjà des items.
    //
    //En mode SameZoneOnly, on conserve le comportement strict : seule la zone
    //logique d'origine participe à la résolution.
    //
    //En mode AllZones, toutes les zones autorisées doivent produire des
    //candidats. C'est indispensable en drag inter-barres : la zone portée par
    //l'item source peut être vide dans la barre cible, alors que Start ou End
    //contiennent déjà des emplacements valides.
    //-------------------------------------------------------------------------

    If FItemsReorderMode = nrbrmSameZoneOnly Then Begin
        AddSameZoneDragCandidates(
            AContext.SourceZone,
            FlowOrientation,
            CanonicalMousePoint,
            Best);
    End Else Begin
        AddSameZoneDragCandidates(
            nrtpzStart,
            FlowOrientation,
            CanonicalMousePoint,
            Best);

        AddSameZoneDragCandidates(
            nrtpzCenter,
            FlowOrientation,
            CanonicalMousePoint,
            Best);

        AddSameZoneDragCandidates(
            nrtpzEnd,
            FlowOrientation,
            CanonicalMousePoint,
            Best);
    End;

    //-------------------------------------------------------------------------
    //Candidats des zones vides.
    //
    //Ils sont ajoutés après les candidats sur items existants, mais restent
    //comparés par distance comme les autres. Ils ne bloquent donc plus les
    //insertions possibles dans les zones déjà peuplées.
    //-------------------------------------------------------------------------

    AddEmptyZoneDragCandidates(
        FlowOrientation,
        CanonicalMousePoint,
        Best);

    //-------------------------------------------------------------------------
    //Candidats interzones.
    //
    //Ils restent optionnels et dépendants du mode de réordonnancement. La
    //construction du contexte canonique peut échouer si la zone de départ ne
    //possède aucun item visible ; ce cas à normalement déjà été traité par la
    //branche zone vide ci-dessus.
    //-------------------------------------------------------------------------
    If BuildCanonicalDragContext(AContext.SourceZone, FlowOrientation, CanonicalBarRect, CanonicalZoneRect, CanonicalLastLineHeight) Then Begin
        If FItemsReorderMode = nrbrmAllZones Then
            AddInterZoneDragCandidates(
                AContext.SourceZone,
                FlowOrientation,
                CanonicalMousePoint,
                CanonicalBarRect,
                CanonicalZoneRect,
                CanonicalLastLineHeight,
                Best);
    End;

    If Not Best.Valid Then
        Exit;

    FillDragTargetFromBestCandidate(
        Best,
        FlowOrientation,
        ATarget);

    Result := True;
End;

Function TNoReflowTabBarDragSupport.TryBuildTabDragTarget(
    Const P: TPoint;
    Out ATarget: TNoReflowTabBarDragTarget): Boolean;
Var
    Context: TNoReflowTabBarDragContext;
Begin
    ATarget.Init;
    Result := False;

    If Not BuildLocalDragContext(Context) Then
        Exit;

    Result := ResolveBestDragTarget(
        Context,
        P,
        ATarget);

    If Result Then
        UpdateItemDragHotItem(
            Self,
            Context.SourceItem,
            P)
    Else
        ClearItemDragHotItem;
End;

Procedure TNoReflowTabBarDragSupport.AddInterZoneDragCandidates(
    ASourceZone: TNoReflowTabBarPinZone;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    Const ACanonicalMousePoint: TPoint;
    Const ACanonicalBarRect: TRect;
    Const ACanonicalZoneRect: TRect;
    ACanonicalLastLineHeight: Integer;
    Var ABest: TNoReflowTabBarDragBestCandidate);

Var
    I:                     Integer;
    J:                     Integer;
    CanonicalRect:         TRect;
    TestRect:              TRect;
    LineRect:              TRect;
    IsFirstInLine:         Boolean;
    IsLastInLine:          Boolean;
    TargetZone:            TNoReflowTabBarPinZone;
    TargetInsertIndex:     Integer;
    BoundaryPoint:         TPoint;
    ShiftedCandidatePoint: TPoint;
    EdgeMarkerRect:        TRect;
    MarkerWidth:           Integer;
    EmptyTargetZone:       Boolean;
    InterZoneGap:          Integer;
    DX:                    Integer;
    DY:                    Integer;
    Dist2:                 Int64;

    Function GetPreviousZone(
        APinZone: TNoReflowTabBarPinZone;
        Out APreviousZone: TNoReflowTabBarPinZone): Boolean;
    Begin
        //------------------------------------------------------------------
        //Retourne la zone logique précédente.
        //
        //Ordre canonique des zones :
        //Start -> Center(None) -> End
        //------------------------------------------------------------------
        Result := True;

        Case APinZone Of
            nrtpzCenter:
                APreviousZone := nrtpzStart;

            nrtpzEnd:
                APreviousZone := nrtpzCenter;
        Else
            Result := False;
            APreviousZone := nrtpzCenter;
        End;
    End;

    Function GetNextZone(
        APinZone: TNoReflowTabBarPinZone;
        Out ANextZone: TNoReflowTabBarPinZone): Boolean;
    Begin
        //------------------------------------------------------------------
        //Retourne la zone logique suivante.
        //
        //Ordre canonique des zones :
        //Start -> Center(None) -> End
        //------------------------------------------------------------------
        Result := True;

        Case APinZone Of
            nrtpzStart:
                ANextZone := nrtpzCenter;

            nrtpzCenter:
                ANextZone := nrtpzEnd;
        Else
            Result := False;
            ANextZone := nrtpzCenter;
        End;
    End;

    Procedure AcceptInterZoneCandidate(
        ADist2: Int64;
        ATargetZone: TNoReflowTabBarPinZone;
        ATargetInsertIndex: Integer;
        ADirection: Integer;
        Const ACanonicalPoint: TPoint;
        Const AMarkerCanonicalRect: TRect);
    Begin
        If ADist2 >= ABest.Dist2 Then
            Exit;

        ABest.Valid := True;
        ABest.Dist2 := ADist2;
        ABest.TargetKind := nrtdtkInterZone;
        ABest.TargetItemIndex := -1;
        ABest.PinZone := ATargetZone;
        ABest.ZoneInsertIndex := ATargetInsertIndex;
        ABest.CanonicalPoint := ACanonicalPoint;

        ABest.MarkerRect := TNoReflowTabBarZoneLayoutEngine.TransformCanonicalRectToActual(
            AMarkerCanonicalRect,
            AFlowOrientation,
            FBarPosition,
            ClientWidth,
            ClientHeight);

        ABest.MarkerCanonicalRect := AMarkerCanonicalRect;
        ABest.MarkerCanonicalDirection := Point(
            ADirection,
            0);

        ABest.InterZoneDirection := ADirection;
    End;

    Procedure AddInterZoneEdgeCandidate(
        Const ALineRect: TRect;
        ATargetZone: TNoReflowTabBarPinZone;
        ATargetInsertIndex: Integer;
        ADirection: Integer);
    Var
        UseInsidePreviousEmptyZoneCandidate: Boolean;
    Begin
        //------------------------------------------------------------------
        //Ajoute un candidat interzone placé sur une extrémité de ligne.
        //
        //La détection reste liée à la ligne survolée, mais le marqueur
        //visuel est placé sur la frontière complète de la zone source :
        //- ADirection = +1 : sortie vers la zone suivante
        //- ADirection = -1 : retour vers la zone précédente
        //
        //Cas important :
        //lorsque la zone précédente est vide, il n'existe aucun espace réel
        //à gauche de la zone courante pour que la souris puisse "attraper"
        //la cible de changement de zone.
        //
        //Exemple :
        //- zone Start vide ;
        //- items visibles uniquement en zone Center ;
        //- on veut déplacer un item Center vers Start.
        //
        //Dans ce cas, placer le candidat à gauche de ACanonicalZoneRect.Left
        //revient souvent à le placer hors de la zone réellement accessible.
        //On ramène donc le candidat sur le bord gauche de la ligne source,
        //avec un point de comparaison légèrement à l'intérieur de la ligne.
        //------------------------------------------------------------------

        EmptyTargetZone := GetItemsCountInZone(ATargetZone) = 0;
        InterZoneGap := 0;

        UseInsidePreviousEmptyZoneCandidate :=
            EmptyTargetZone And
            (ADirection < 0);

        If EmptyTargetZone And Not UseInsidePreviousEmptyZoneCandidate Then
            InterZoneGap := FLayout.ZoneSpacing;

        If ADirection < 0 Then Begin
            If UseInsidePreviousEmptyZoneCandidate Then
                BoundaryPoint := Point(
                    ALineRect.Left,
                    (ALineRect.Top + ALineRect.Bottom) Div 2)
            Else
                BoundaryPoint := Point(
                    ACanonicalZoneRect.Left - InterZoneGap,
                    (ALineRect.Top + ALineRect.Bottom) Div 2);
        End Else Begin
            BoundaryPoint := Point(
                ACanonicalZoneRect.Right + InterZoneGap,
                (ALineRect.Top + ALineRect.Bottom) Div 2);
        End;

        //------------------------------------------------------------------
        //Le point de comparaison est légèrement décalé vers la zone cible.
        //
        //Cas standard :
        //- on décale vers l'extérieur de la zone source pour distinguer une
        //  insertion same-zone en extrémité d'un vrai changement de zone.
        //
        //Cas zone précédente vide :
        //- on décale au contraire vers l'intérieur de la ligne source, afin
        //  que le candidat soit réellement atteignable par la souris.
        //------------------------------------------------------------------

        If UseInsidePreviousEmptyZoneCandidate Then
            ShiftedCandidatePoint := Point(
                BoundaryPoint.X + CDragInterZoneSwitchOffset,
                BoundaryPoint.Y)
        Else
            ShiftedCandidatePoint := Point(
                BoundaryPoint.X + (ADirection * CDragInterZoneSwitchOffset),
                BoundaryPoint.Y);

        DX := ACanonicalMousePoint.X - ShiftedCandidatePoint.X;
        DY := ACanonicalMousePoint.Y - ShiftedCandidatePoint.Y;
        Dist2 := Int64(DX) * DX + Int64(DY) * DY;

        //------------------------------------------------------------------
        //Le rectangle canonique du marqueur représente l'espace interzone.
        //
        //Si la zone précédente est vide, le marqueur est dessiné au bord
        //gauche de la ligne source, donc dans une zone visible et atteignable.
        //------------------------------------------------------------------

        MarkerWidth := Max(
            FLayout.ZoneSpacing,
            CDragInterZoneMarkerMinWidth);

        If ADirection > 0 Then
            EdgeMarkerRect := Rect(
                BoundaryPoint.X,
                ACanonicalBarRect.Top,
                BoundaryPoint.X + MarkerWidth,
                ACanonicalBarRect.Bottom - (ACanonicalLastLineHeight Div 2))
        Else Begin
            If UseInsidePreviousEmptyZoneCandidate Then
                EdgeMarkerRect := Rect(
                    BoundaryPoint.X,
                    ACanonicalBarRect.Top,
                    BoundaryPoint.X + MarkerWidth,
                    ACanonicalBarRect.Bottom - (ACanonicalLastLineHeight Div 2))
            Else
                EdgeMarkerRect := Rect(
                    BoundaryPoint.X - MarkerWidth,
                    ACanonicalBarRect.Top,
                    BoundaryPoint.X,
                    ACanonicalBarRect.Bottom - (ACanonicalLastLineHeight Div 2));
        End;

        AcceptInterZoneCandidate(
            Dist2,
            ATargetZone,
            ATargetInsertIndex,
            ADirection,
            BoundaryPoint,
            EdgeMarkerRect);
    End;

Begin
    //----------------------------------------------------------------------
    //Candidats interzones.
    //
    //On ne crée pas un unique point global entre deux zones. Chaque ligne
    //visible de la zone source fournit deux extrémités potentielles :
    //- début de ligne : passage vers la zone précédente
    //- fin de ligne   : passage vers la zone suivante
    //----------------------------------------------------------------------

    For I := 0 To High(FRenderItems) Do Begin
        If Not FRenderItems[I].Visible Then
            Continue;

        If (FRenderItems[I].Item = Nil) Or (FRenderItems[I].Item.PinZone <> ASourceZone) Then
            Continue;

        CanonicalRect := TNoReflowTabBarZoneLayoutEngine.TransformActualRectToCanonical(
            FRenderItems[I].Bounds,
            AFlowOrientation,
            FBarPosition,
            ClientWidth,
            ClientHeight);

        //------------------------------------------------------------------
        //Recherche de l'emprise complète de la ligne contenant l'item I.
        //------------------------------------------------------------------
        LineRect := CanonicalRect;
        IsFirstInLine := True;
        IsLastInLine := True;

        For J := 0 To High(FRenderItems) Do Begin
            If I = J Then
                Continue;

            If Not FRenderItems[J].Visible Then
                Continue;

            If (FRenderItems[J].Item = Nil) Or (FRenderItems[J].Item.PinZone <> ASourceZone) Then
                Continue;

            TestRect := TNoReflowTabBarZoneLayoutEngine.TransformActualRectToCanonical(
                FRenderItems[J].Bounds,
                AFlowOrientation,
                FBarPosition,
                ClientWidth,
                ClientHeight);

            If Not SameCanonicalLine(CanonicalRect, TestRect) Then
                Continue;

            If TestRect.Left < LineRect.Left Then
                LineRect.Left := TestRect.Left;

            If TestRect.Right > LineRect.Right Then
                LineRect.Right := TestRect.Right;

            If TestRect.Top < LineRect.Top Then
                LineRect.Top := TestRect.Top;

            If TestRect.Bottom > LineRect.Bottom Then
                LineRect.Bottom := TestRect.Bottom;

            If TestRect.Left < CanonicalRect.Left Then
                IsFirstInLine := False;

            If TestRect.Right > CanonicalRect.Right Then
                IsLastInLine := False;
        End;

        //------------------------------------------------------------------
        //Début de ligne : candidat de changement vers la zone précédente.
        //------------------------------------------------------------------
        If IsFirstInLine And GetPreviousZone(ASourceZone, TargetZone) Then Begin
            If IsTabReorderZoneAllowed(TargetZone) Then Begin
                TargetInsertIndex := GetItemsCountInZone(TargetZone);

                AddInterZoneEdgeCandidate(
                    LineRect,
                    TargetZone,
                    TargetInsertIndex,
                    -1);
            End;
        End;

        //------------------------------------------------------------------
        //Fin de ligne : candidat de changement vers la zone suivante.
        //------------------------------------------------------------------
        If IsLastInLine And GetNextZone(ASourceZone, TargetZone) Then Begin
            If IsTabReorderZoneAllowed(TargetZone) Then Begin
                TargetInsertIndex := 0;

                AddInterZoneEdgeCandidate(
                    LineRect,
                    TargetZone,
                    TargetInsertIndex,
                    +1);
            End;
        End;

    End;
End;

Function TNoReflowTabBarDragSupport.BuildCanonicalDragContext(
    ASourceZone: TNoReflowTabBarPinZone;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    Out ACanonicalBarRect: TRect;
    Out ACanonicalZoneRect: TRect;
    Out ACanonicalLastLineHeight: Integer): Boolean;
Var
    I:        Integer;
    TestRect: TRect;
Begin
    //----------------------------------------------------------------------
    //Construit les rectangles canoniques utiles au drag interzone.
    //
    //ACanonicalBarRect :
    //- hauteur utile de la barre, basée uniquement sur les items visibles
    //
    //ACanonicalZoneRect :
    //- emprise complète de la zone source dans le repère canonique
    //
    //ACanonicalLastLineHeight :
    //- hauteur de la ligne la plus basse, utilisée pour éviter que la flèche
    //interzone soit collée au bord bas en position Top.
    //----------------------------------------------------------------------

    Result := False;

    ACanonicalBarRect := Rect(
        0,
        0,
        0,
        0);

    ACanonicalZoneRect := Rect(
        0,
        0,
        0,
        0);

    ACanonicalLastLineHeight := 0;

    For I := 0 To High(FRenderItems) Do Begin
        If Not FRenderItems[I].Visible Then
            Continue;

        If FRenderItems[I].Item = Nil Then
            Continue;

        TestRect := TNoReflowTabBarZoneLayoutEngine.TransformActualRectToCanonical(
            FRenderItems[I].Bounds,
            AFlowOrientation,
            FBarPosition,
            ClientWidth,
            ClientHeight);

        //------------------------------------------------------------------
        //Hauteur globale de la barre.
        //
        //Important :
        //on détecte la ligne la plus basse avant de modifier Bottom afin de
        //conserver la hauteur de cette dernière ligne.
        //------------------------------------------------------------------
        If IsRectEmpty(ACanonicalBarRect) Then Begin
            ACanonicalBarRect := TestRect;
            ACanonicalLastLineHeight := TestRect.Height;
        End Else Begin
            If TestRect.Bottom > ACanonicalBarRect.Bottom Then
                ACanonicalLastLineHeight := TestRect.Height;

            If TestRect.Top < ACanonicalBarRect.Top Then
                ACanonicalBarRect.Top := TestRect.Top;

            If TestRect.Bottom > ACanonicalBarRect.Bottom Then
                ACanonicalBarRect.Bottom := TestRect.Bottom;
        End;

        //------------------------------------------------------------------
        //Emprise complète de la zone source.
        //------------------------------------------------------------------
        If FRenderItems[I].Item.PinZone <> ASourceZone Then
            Continue;

        If IsRectEmpty(ACanonicalZoneRect) Then
            ACanonicalZoneRect := TestRect
        Else Begin
            If TestRect.Left < ACanonicalZoneRect.Left Then
                ACanonicalZoneRect.Left := TestRect.Left;

            If TestRect.Right > ACanonicalZoneRect.Right Then
                ACanonicalZoneRect.Right := TestRect.Right;

            If TestRect.Top < ACanonicalZoneRect.Top Then
                ACanonicalZoneRect.Top := TestRect.Top;

            If TestRect.Bottom > ACanonicalZoneRect.Bottom Then
                ACanonicalZoneRect.Bottom := TestRect.Bottom;
        End;
    End;

    Result := Not IsRectEmpty(ACanonicalZoneRect);
End;

Procedure TNoReflowTabBarDragSupport.FillDragTargetFromBestCandidate(
    Const ABest: TNoReflowTabBarDragBestCandidate;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    Var ATarget: TNoReflowTabBarDragTarget);
Var
    CanonicalDirection: TPoint;
Begin
    //----------------------------------------------------------------------
    //Transfère le meilleur candidat calculé vers la cible de drag finale.
    //
    //Le meilleur candidat est conservé en grande partie en repère canonique.
    //Cette méthode se charge donc de reprojeter les points nécessaires vers
    //le repère réel de la barre.
    //----------------------------------------------------------------------

    ATarget.Valid := True;
    ATarget.TargetKind := ABest.TargetKind;
    ATarget.PinZone := ABest.PinZone;

    //----------------------------------------------------------------------
    //Point principal du marqueur.
    //
    //Utilisé surtout par le marqueur same-zone et par les anciens helpers de
    //calcul de rectangle.
    //----------------------------------------------------------------------
    ATarget.MarkerPoint := TNoReflowTabBarZoneLayoutEngine.TransformCanonicalPointToActual(
        ABest.CanonicalPoint,
        AFlowOrientation,
        FBarPosition,
        ClientWidth,
        ClientHeight);

    //----------------------------------------------------------------------
    //Rectangles de marqueur.
    //
    //MarkerRect est déjà projeté en coordonnées réelles.
    //MarkerCanonicalRect reste disponible pour le dessin interzone, qui est
    //dessiné en canonique puis reprojeté point par point.
    //----------------------------------------------------------------------
    ATarget.MarkerRect := ABest.MarkerRect;
    ATarget.MarkerCanonicalRect := ABest.MarkerCanonicalRect;
    ATarget.MarkerCanonicalDirection := ABest.MarkerCanonicalDirection;

    //----------------------------------------------------------------------
    //Direction réelle du marqueur.
    //
    //Same-zone :
    //- direction canonique vers le bas, comme pour une barre Top.
    //
    //Interzone :
    //- direction canonique horizontale selon la zone cible.
    //----------------------------------------------------------------------
    If ABest.TargetKind = nrtdtkInterZone Then
        CanonicalDirection := Point(
            ABest.InterZoneDirection,
            0)
    Else
        CanonicalDirection := Point(
            0,
            1);

    ATarget.MarkerDirection := TNoReflowTabBarZoneLayoutEngine.TransformCanonicalDirectionToActual(
        CanonicalDirection,
        AFlowOrientation,
        FBarPosition);

    //----------------------------------------------------------------------
    //Informations logiques d'insertion.
    //----------------------------------------------------------------------
    ATarget.TargetItemIndex := ABest.TargetItemIndex;
    ATarget.ZoneInsertIndex := ABest.ZoneInsertIndex;

    //----------------------------------------------------------------------
    //Type logique d'insertion.
    //
    //Important :
    //TargetItemIndex = -1 ne signifie pas forcément "zone vide".
    //Cela peut aussi représenter une insertion en fin de zone, après le
    //dernier item visible.
    //
    //La vraie position d'insertion reste portée par ZoneInsertIndex.
    //InsertKind sert surtout à qualifier sémantiquement la cible.
    //----------------------------------------------------------------------
    If ABest.TargetItemIndex >= 0 Then
        ATarget.InsertKind := nrtdikBeforeTab
    Else Begin
        //------------------------------------------------------------------
        //TargetItemIndex = -1 couvre deux familles de cibles :
        //- zone vide ;
        //- fin de zone après le dernier item visible.
        //
        //Cette qualification ne doit pas dépendre du type de candidat. Une
        //fin de zone same-zone doit recevoir nrtdikAtZoneEnd exactement comme
        //une fin de zone atteinte depuis un candidat interzone.
        //------------------------------------------------------------------
        If GetItemsCountInZone(ABest.PinZone) = 0 Then
            ATarget.InsertKind := nrtdikIntoEmptyZone
        Else If ABest.ZoneInsertIndex >= GetItemsCountInZone(ABest.PinZone) Then
            ATarget.InsertKind := nrtdikAtZoneEnd
        Else
            ATarget.InsertKind := nrtdikBeforeTab;
    End;
End;

Procedure TNoReflowTabBarDragSupport.DoBeginTabDrag;
Var
    LTab: TNoReflowTabBarItem;
Begin
    If Not Assigned(FOnBeginItemDrag) Then
        Exit;

    If Not IsTabDragSourceIndexValid Then
        Exit;

    LTab := FItems[FDragSourceIndex];
    If LTab = Nil Then
        Exit;

    FOnBeginItemDrag(
        Self,
        LTab,
        FDragSourceIndex,
        LTab.PinZone);
End;

Procedure TNoReflowTabBarDragSupport.DoEndTabDrag(
    ATab: TNoReflowTabBarItem;
    ASourceIndex: Integer;
    ASourceZone: TNoReflowTabBarPinZone;
    ATargetZone: TNoReflowTabBarPinZone;
    ATargetZoneIndex: Integer;
    ADropped: Boolean);
Begin
    If Not Assigned(FOnEndItemDrag) Then
        Exit;

    FOnEndItemDrag(
        Self,
        ATab,
        ASourceIndex,
        ASourceZone,
        ATargetZone,
        ATargetZoneIndex,
        ADropped);
End;

Function TNoReflowTabBarDragSupport.CanReorderTabToTarget(
    ASourceTab: TNoReflowTabBarItem;
    Const ATarget: TNoReflowTabBarDragTarget): Boolean;
Var
    Allow:           Boolean;
    TargetZoneIndex: Integer;
    TargetTab:       TNoReflowTabBarItem;
Begin
    Result := False;

    If ASourceTab = Nil Then
        Exit;

    If Not ATarget.Valid Then
        Exit;

    If Not IsTabReorderZoneAllowed(ASourceTab.PinZone) Then
        Exit;

    If Not IsTabReorderZoneAllowed(ATarget.PinZone) Then
        Exit;

    TargetZoneIndex := ClampZoneInsertIndex(
        ATarget.PinZone,
        ATarget.ZoneInsertIndex);

    If (ATarget.TargetItemIndex >= 0) And (ATarget.TargetItemIndex < FItems.Count) Then Begin
        TargetTab := FItems[ATarget.TargetItemIndex];
        If TargetTab <> Nil Then
            TargetZoneIndex := TargetTab.ZoneIndex;

        If ATarget.InsertKind = nrtdikAfterTab Then
            Inc(TargetZoneIndex);
    End;

    If ASourceTab.PinZone = ATarget.PinZone Then
        If TargetZoneIndex > ASourceTab.ZoneIndex Then
            Dec(TargetZoneIndex);

    Allow := True;

    If Assigned(FOnCanReorderItems) Then
        FOnCanReorderItems(
            Self,
            ASourceTab,
            ASourceTab.PinZone,
            ASourceTab.ZoneIndex,
            ATarget.PinZone,
            TargetZoneIndex,
            Allow);

    Result := Allow;
End;

Function TNoReflowTabBarDragSupport.CanActAsInterBarDragSource: Boolean;
Begin
    Result := FItemsInterBarMode In [nrtbimSourceOnly, nrtbimSourceAndTarget];
End;

Function TNoReflowTabBarDragSupport.CanActAsInterBarDragTarget: Boolean;
Begin
    Result := FItemsInterBarMode In [nrtbimTargetOnly, nrtbimSourceAndTarget];
End;

Function TNoReflowTabBarDragSupport.IsInterBarDragGroupCompatible(ASourceBar: TNoReflowTabBarDragSupport): Boolean;
Begin
    Result := False;

    If ASourceBar = Nil Then
        Exit;

    //Le groupe est volontairement compare tel quel, sans notion de hierarchie.
    //La chaine vide est simplement le groupe par défaut : deux barres laissees
    //avec la valeur vide dialoguent donc entre elles si leurs roles le permettent.
    Result := SameText(
        ASourceBar.FItemsInterBarGroup,
        FItemsInterBarGroup);
End;

Function TNoReflowTabBarDragSupport.CanAcceptItemDropFrom(ASourceBar: TNoReflowTabBarDragSupport): Boolean;
Begin
    Result := False;

    If ASourceBar = Nil Then
        Exit;

    //-------------------------------------------------------------------------
    //Cas interne : la barre se reçoit elle-m�me.
    //
    //Le mode inter-barres ne doit surtout pas intervenir ici. Le drag interne
    //reste uniquement régi par le mode de réordonnancement et les zones
    //autorisées de cette barre.
    //-------------------------------------------------------------------------
    If ASourceBar = Self Then Begin
        Result := FItemsReorderMode <> nrbrmNone;
        Exit;
    End;

    //-------------------------------------------------------------------------
    //Cas inter-barres : une barre source et une barre cible différentes
    //dialoguent seulement si les deux rôles l'autorisent et si le groupe est
    //identique. La cible utilise ensuite sa propre logique de réordonnancement
    //pour calculer la position d'insertion.
    //-------------------------------------------------------------------------
    If Not ASourceBar.CanActAsInterBarDragSource Then
        Exit;

    If Not CanActAsInterBarDragTarget Then
        Exit;

    If FItemsReorderMode = nrbrmNone Then
        Exit;

    If Not IsInterBarDragGroupCompatible(ASourceBar) Then
        Exit;

    Result := True;
End;

Function TNoReflowTabBarDragSupport.CanReceiveItemDragOverFrom(ASourceBar: TNoReflowTabBarDragSupport): Boolean;
Begin
    Result := False;

    If ASourceBar = Nil Then
        Exit;

    If ASourceBar = Self Then
        Exit;

    //La barre source doit quand même être une vraie source de drag inter-barres.
    //Sinon n'importe quel drag interne local pourrait déclencher des survols
    //fonctionnels sur des barres voisines.
    If Not ASourceBar.CanActAsInterBarDragSource Then
        Exit;

    //On conserve la notion de groupe pour éviter que des barres sans rapport
    //réagissent entre elles.
    If Not IsInterBarDragGroupCompatible(ASourceBar) Then
        Exit;

    //S'il n'y à aucun gestionnaire de survol, cette barre n'a aucune raison
    //de participer au protocole hover-only.
    If Not Assigned(FOnItemDragOver) Then
        Exit;

    Result := True;
End;

Function TNoReflowTabBarDragSupport.FindCompatibleDropBarAtScreenPos(
    Const AScreenPos: TPoint): TNoReflowTabBarDragSupport;
Var
    WinControl: TWinControl;
Begin
    Result := Nil;

    If Not CanActAsInterBarDragSource Then
        Exit;

    WinControl := FindVCLWindow(AScreenPos);

    While WinControl <> Nil Do Begin
        If WinControl Is TNoReflowTabBarDragSupport Then Begin
            Result := TNoReflowTabBarDragSupport(WinControl);

            //La barre source garde son chemin historique pour le drag interne.
            //Cette recherche ne sert qu'au dialogue avec une autre barre.
            If Result = Self Then Begin
                Result := Nil;
                Exit;
            End;

            //Deux cas compatibles :
            //
            //1) vraie cible de drop :
            //   la barre accepte un dépôt et pourra afficher un marqueur.
            //
            //2) cible de survol fonctionnel seulement :
            //   la barre refuse le dépôt, mais veut recevoir OnItemDragOver.
            //
            //Cela permet à une barre d'onglets de rester en nrtbimNone tout en
            //réagissant au passage d'un bouton déplacé au-dessus d'un onglet.
            If Result.CanAcceptItemDropFrom(Self) Or
                Result.CanReceiveItemDragOverFrom(Self) Then
                Exit;

            Result := Nil;
            Exit;
        End;

        WinControl := WinControl.Parent;
    End;
End;

Procedure TNoReflowTabBarDragSupport.ClearExternalDraggedBarItemPreview;
Begin
    If FDragExternalTargetBar <> Nil Then Begin
        FDragExternalTargetBar.CancelDraggedBarItemPreview;
        FDragExternalTargetBar := Nil;
    End;
End;

Function TNoReflowTabBarDragSupport.UpdateExternalDraggedBarItemPreview(Const AScreenPos: TPoint): Boolean;
Var
    TargetBar:  TNoReflowTabBarDragSupport;
    ClientPos:  TPoint;
    SourceItem: TNoReflowTabBarItem;
Begin
    Result := False;

    If Not IsTabDragSourceIndexValid Then Begin
        ClearExternalDraggedBarItemPreview;
        Exit;
    End;

    SourceItem := FItems[FDragSourceIndex];
    TargetBar := FindCompatibleDropBarAtScreenPos(AScreenPos);

    If TargetBar <> FDragExternalTargetBar Then Begin
        ClearExternalDraggedBarItemPreview;
        FDragExternalTargetBar := TargetBar;
    End;

    If TargetBar = Nil Then
        Exit;

    ClientPos := TargetBar.ScreenToClient(AScreenPos);

    Result := TargetBar.PreviewDraggedBarItem(
        Self,
        SourceItem,
        ClientPos);

    If Not Result Then
        ClearExternalDraggedBarItemPreview;
End;

Function TNoReflowTabBarDragSupport.DropExternalDraggedBarItem(
    Const AScreenPos: TPoint;
    Var ATargetItem: TNoReflowTabBarItem): Boolean;
Var
    ClientPos:  TPoint;
    SourceItem: TNoReflowTabBarItem;
Begin
    Result := False;
    ATargetItem := Nil;

    If FDragExternalTargetBar = Nil Then
        Exit;

    If Not IsTabDragSourceIndexValid Then
        Exit;

    SourceItem := FItems[FDragSourceIndex];
    ClientPos := FDragExternalTargetBar.ScreenToClient(AScreenPos);

    Result := FDragExternalTargetBar.DropDraggedBarItem(
        Self,
        SourceItem,
        ClientPos,
        ATargetItem);

    //La suppression de l'item source est volontairement laissee au
    //gestionnaire du drag source. Cela lui permet encore de déclencher
    //OnEndItemDrag avec un pointeur source valide, puis seulement ensuite
    //de retirer l'item de sa propre collection.
    FDragExternalTargetBar := Nil;
End;

Function TNoReflowTabBarDragSupport.GetCurrentDragTarget(Var ATarget: TNoReflowTabBarDragTarget): Boolean;
Begin
    ATarget := FDragTarget;
    Result := ATarget.Valid;
End;

Function TNoReflowTabBarDragSupport.TryBuildEmptyZoneDragTarget(
    ASourceZone: TNoReflowTabBarPinZone;
    Const P: TPoint;
    Out ATarget: TNoReflowTabBarDragTarget): Boolean;
Var
    MarkerThickness: Integer;
    MarkerLeft:      Integer;
    MarkerTop:       Integer;
    MarkerBottom:    Integer;
Begin
    ATarget.Init;
    Result := False;

    //On refuse les points vraiment hors de la barre.
    //Cela évite qu'une barre vide devienne une cible fantôme dès qu'elle est
    //compatible au niveau groupe/rôle.
    If Not PtInRect(ClientRect, P) Then
        Exit;

    If Not IsTabReorderZoneAllowed(ASourceZone) Then
        Exit;

    If GetItemsCountInZone(ASourceZone) <> 0 Then
        Exit;

    MarkerThickness := CDragMarkerThickness;
    If MarkerThickness < 1 Then
        MarkerThickness := 1;

    MarkerLeft := 2;
    MarkerTop := 2;
    MarkerBottom := ClientHeight - 2;

    If MarkerBottom <= MarkerTop Then
        MarkerBottom := MarkerTop + MarkerThickness;

    ATarget.Valid := True;
    ATarget.TargetKind := nrtdtkSameZone;
    ATarget.PinZone := ASourceZone;
    ATarget.InsertKind := nrtdikIntoEmptyZone;
    ATarget.TargetItemIndex := -1;
    ATarget.ZoneInsertIndex := 0;

    //On fournit directement un rectangle de marqueur.
    //GetDragInsertMarkerRect ne peut pas reconstruire ce rectangle dans une
    //barre vide, puisqu'il n'y à ni item cible ni item source local.
    ATarget.MarkerRect := Rect(
        MarkerLeft,
        MarkerTop,
        MarkerLeft + MarkerThickness,
        MarkerBottom);

    ATarget.MarkerPoint := Point(
        MarkerLeft,
        (MarkerTop + MarkerBottom) Div 2);

    ATarget.MarkerDirection := Point(
        0,
        1);

    Result := True;
End;

Function TNoReflowTabBarDragSupport.TryBuildTabDragTargetForItem(
    ASourceBar: TObject;
    ASourceItem: TNoReflowTabBarItem;
    Const P: TPoint;
    Out ATarget: TNoReflowTabBarDragTarget): Boolean;
Var
    Context: TNoReflowTabBarDragContext;
Begin
    //-------------------------------------------------------------------------
    //Point d'entrée historique du drag inter-barres.
    //
    //La méthode ne contient plus de moteur spécifique. Elle construit un
    //contexte externe puis délègue au même ResolveBestDragTarget que le drag
    //interne.
    //-------------------------------------------------------------------------
    ATarget.Init;
    Result := False;

    If Not BuildItemDragContext(ASourceItem, Context) Then
        Exit;

    Result := ResolveBestDragTarget(
        Context,
        P,
        ATarget);
End;

Function TNoReflowTabBarDragSupport.CanDropTabToTarget(
    ASourceBar: TObject;
    ASourceItem: TNoReflowTabBarItem;
    Const ATarget: TNoReflowTabBarDragTarget): Boolean;
Var
    SourceDragBar: TNoReflowTabBarDragSupport;
Begin
    Result := False;

    If ASourceItem = Nil Then
        Exit;

    If Not ATarget.Valid Then
        Exit;

    If Not(ASourceBar Is TNoReflowTabBarDragSupport) Then
        Exit;

    SourceDragBar := TNoReflowTabBarDragSupport(ASourceBar);

    If Not CanAcceptItemDropFrom(SourceDragBar) Then
        Exit;

    If Not IsTabReorderZoneAllowed(ATarget.PinZone) Then
        Exit;

    Result := True;

    If Assigned(FOnCanDropItem) Then
        FOnCanDropItem(
            Self,
            ASourceBar,
            ASourceItem,
            ATarget.PinZone,
            ATarget.ZoneInsertIndex,
            Result);
End;

Function TNoReflowTabBarDragSupport.ApplyDroppedTabFromBar(
    ASourceBar: TObject;
    ASourceItem: TNoReflowTabBarItem;
    Const ATarget: TNoReflowTabBarDragTarget;
    Var ATargetItem: TNoReflowTabBarItem): Boolean;
Var
    SourceIndex:     Integer;
    TargetZoneIndex: Integer;
Begin
    Result := False;
    ATargetItem := Nil;

    If Not CanDropTabToTarget(ASourceBar, ASourceItem, ATarget) Then
        Exit;

    TargetZoneIndex := ClampZoneInsertIndex(
        ATarget.PinZone,
        ATarget.ZoneInsertIndex);

    If ASourceBar = Self Then Begin
        SourceIndex := IndexOfItem(ASourceItem);

        If SourceIndex < 0 Then
            Exit;

        If Not ApplyDraggedTabToTarget(SourceIndex, ATarget) Then
            Exit;

        ATargetItem := ASourceItem;
    End Else Begin

        ATargetItem := InsertItemInZone(
            ATarget.PinZone,
            TargetZoneIndex,
            ASourceItem.Caption,
            ASourceItem.SignalCode,
            ASourceItem.UserId,
            ASourceItem.Enabled);

        If ATargetItem = Nil Then
            Exit;

        ATargetItem.Assign(ASourceItem);
        ATargetItem.Data := ASourceItem.Data;
        MoveItemToZone(
            ATargetItem,
            ATarget.PinZone,
            TargetZoneIndex);
    End;

    If Assigned(FOnItemDropped) Then
        FOnItemDropped(
            Self,
            ASourceBar,
            ASourceItem,
            ATargetItem,
            ATarget.PinZone,
            TargetZoneIndex);

    Result := True;
End;

Function TNoReflowTabBarDragSupport.PreviewDraggedBarItem(
    ASourceBar: TObject;
    ASourceItem: TNoReflowTabBarItem;
    Const AClientPos: TPoint): Boolean;
Var
    NewTarget:    TNoReflowTabBarDragTarget;
    SourceDragBar: TNoReflowTabBarDragSupport;
    CanDropHere:  Boolean;
    CanHoverHere: Boolean;
Begin
    Result := False;

    NewTarget.Init;
    CanDropHere := False;
    CanHoverHere := False;

    If ASourceItem = Nil Then Begin
        CancelDraggedBarItemPreview;
        Exit;
    End;

    If Not(ASourceBar Is TNoReflowTabBarDragSupport) Then Begin
        CancelDraggedBarItemPreview;
        Exit;
    End;

    SourceDragBar := TNoReflowTabBarDragSupport(ASourceBar);

    //-------------------------------------------------------------------------
    //Deux niveaux de compatibilité sont volontairement séparés.
    //
    //1) Compatibilité drop :
    //   la barre accepte réellement l'item et peut afficher un marqueur
    //   d'insertion.
    //
    //2) Compatibilité hover-only :
    //   la barre refuse le dépôt mais accepte de notifier OnItemDragOver /
    //   OnItemDragLeave lorsqu'un item est survolé.
    //
    //Ce second cas sert typiquement à une barre d'onglets :
    //elle ne doit jamais recevoir le bouton déplacé, mais elle doit pouvoir
    //activer l'onglet survolé pendant le drag.
    //-------------------------------------------------------------------------

    CanHoverHere := CanReceiveItemDragOverFrom(SourceDragBar);

    If TryBuildTabDragTargetForItem(
        ASourceBar,
        ASourceItem,
        AClientPos,
        NewTarget) Then
        CanDropHere := CanDropTabToTarget(
            ASourceBar,
            ASourceItem,
            NewTarget);

    If CanDropHere Then Begin
        //Cas normal : vraie cible de drop.
        FDragActive := True;
        FDragTarget := NewTarget;

        UpdateItemDragHotItem(
            ASourceBar,
            ASourceItem,
            AClientPos);

        Invalidate;

        Result := True;
        Exit;
    End;

    If CanHoverHere Then Begin
        //Cas hover-only : pas de dépôt, pas de marqueur d'insertion.
        //
        //On garde uniquement la notification fonctionnelle de survol.
        //FDragActive reste à False pour éviter que la barre dessine un marqueur
        //ou soit considérée comme une cible de drop valide.
        FDragActive := False;
        FDragTarget.Init;

        Result := UpdateItemDragHotItem(
            ASourceBar,
            ASourceItem,
            AClientPos);

        If Result Then
            Invalidate
        Else
            CancelDraggedBarItemPreview;

        Exit;
    End;

    CancelDraggedBarItemPreview;
End;

Procedure TNoReflowTabBarDragSupport.CancelDraggedBarItemPreview;
Begin
    If (Not FDragActive) And (Not FDragTarget.Valid) And (FItemDragHotIndex < 0) Then
        Exit;

    FDragActive := False;
    FDragTarget.Init;

    ClearItemDragHotItem;

    Invalidate;
End;

Function TNoReflowTabBarDragSupport.DropDraggedBarItem(
    ASourceBar: TObject;
    ASourceItem: TNoReflowTabBarItem;
    Const AClientPos: TPoint;
    Var ATargetItem: TNoReflowTabBarItem): Boolean;
Var
    Target: TNoReflowTabBarDragTarget;
Begin
    ATargetItem := Nil;
    Target.Init;

    //En mode hover-only, la barre peut avoir reçu OnItemDragOver sans jamais
    //avoir construit de cible de dépôt. Dans ce cas, le drop doit être refusé
    //explicitement.
    If FDragTarget.Valid Then
        Target := FDragTarget
    Else If Not TryBuildTabDragTargetForItem(
        ASourceBar,
        ASourceItem,
        AClientPos,
        Target) Then Begin
        Result := False;
        CancelDraggedBarItemPreview;
        Exit;
    End;

    If Not CanDropTabToTarget(
        ASourceBar,
        ASourceItem,
        Target) Then Begin
        Result := False;
        CancelDraggedBarItemPreview;
        Exit;
    End;

    Result := ApplyDroppedTabFromBar(
        ASourceBar,
        ASourceItem,
        Target,
        ATargetItem);

    CancelDraggedBarItemPreview;
End;


end.

