unit NoReflowTabBar_EventsTypes;

{
  NoReflowTabBar_EventsTypes.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Public event type declarations used by the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Event signature declarations for the NoReflowTabBar component.

  This unit provides the callback types used by the bar for:
  - selection changes;
  - item click, double-click and mouse tracking;
  - logical zone mouse tracking;
  - dynamic text, hint, measurement and painting customisation;
  - internal, inter-zone and inter-bar drag and drop;
  - inline editing of item captions.

  Role of this unit:
  - isolate public event type declarations;
  - keep the main component units free from long callback declarations;
  - provide a readable event API to the Core, Drag, Render and published facade
    layers.

  Notes:
  - this unit contains no runtime logic;
  - it depends only on common types and the item model;
  - event signatures should remain as stable as possible to preserve
    compatibility with existing applications.
}

interface

uses
    System.Types,
    System.Classes,
    Vcl.Graphics,
    Vcl.Controls,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_Items;

Type
    {
      Event fired just before the selected or current item changes.

      OldItem is the current item before the transition. NewItem is the
      requested item after component-side normalisation. Either value may be
      nil when no item exists before or after the operation.

      Set Allow to False to reject the transition. Typical use cases include
      preventing the user from leaving a page with invalid data, requesting user
      confirmation, or applying application-specific access rules.
    }
    TNoReflowTabBarChangingEvent = Procedure(
        Sender: TObject;
        OldItem: TNoReflowTabBarItem;
        NewItem: TNoReflowTabBarItem;
        Var Allow: Boolean) Of Object;

    {
      Event fired after a new selected or current item has been applied.

      OldItem is the previous item. NewItem is the new item. Either value may be
      nil when the bar changes from or to an empty state.
    }
    TNoReflowTabBarChangeEvent = Procedure(
        Sender: TObject;
        OldItem: TNoReflowTabBarItem;
        NewItem: TNoReflowTabBarItem) Of Object;

    {
      Event fired when an item drag operation becomes active.

      This event is not fired on MouseDown. It is fired only after the mouse
      movement threshold has been exceeded.

      AItem is the dragged item, ASourceIndex is its absolute index when the drag
      started, and ASourceZone is its original logical zone.
    }
    TNoReflowTabBarBeginDragItemEvent = Procedure(
        Sender: TObject;
        AItem: TNoReflowTabBarItem;
        ASourceIndex: Integer;
        ASourceZone: TNoReflowTabBarPinZone) Of Object;

    {
      Event fired when an item drag operation ends.

      ADropped is True only when a move or drop operation has actually been
      applied. ATargetZone and ATargetZoneIndex describe the resolved target.
      When ADropped is False, the target information can usually be ignored.
    }
    TNoReflowTabBarEndDragItemEvent = Procedure(
        Sender: TObject;
        AItem: TNoReflowTabBarItem;
        ASourceIndex: Integer;
        ASourceZone: TNoReflowTabBarPinZone;
        ATargetZone: TNoReflowTabBarPinZone;
        ATargetZoneIndex: Integer;
        ADropped: Boolean) Of Object;

    {
      Event used to validate an item reorder operation before it is applied.

      AItem is the item being moved. ASourceZone and ASourceZoneIndex describe
      its current position. ATargetZone and ATargetZoneIndex describe the
      requested target position.

      Set Allow to False to reject the move.
    }
    TNoReflowTabBarCanReorderItemEvent = Procedure(
        Sender: TObject;
        AItem: TNoReflowTabBarItem;
        ASourceZone: TNoReflowTabBarPinZone;
        ASourceZoneIndex: Integer;
        ATargetZone: TNoReflowTabBarPinZone;
        ATargetZoneIndex: Integer;
        Var Allow: Boolean) Of Object;

    {
      Event used to validate a drop operation before it is applied.

      This event generalises OnCanReorderItem:
      - ASourceBar can be the target bar itself for an internal drag;
      - ASourceBar can be another TNoReflowTabBar for an inter-bar drag.

      The component does not assign application-specific meaning to ASourceBar.
      Applications can use it to identify a page, category, menu, command group
      or any other owner context.

      Set Allow to False to reject the drop.
    }
    TNoReflowTabBarCanDropItemEvent = Procedure(
        Sender: TObject;
        ASourceBar: TObject;
        ASourceItem: TNoReflowTabBarItem;
        ATargetZone: TNoReflowTabBarPinZone;
        ATargetZoneIndex: Integer;
        Var Allow: Boolean) Of Object;

    {
      Event fired after a drop has been accepted and applied by the target bar.

      For an internal drag, ASourceItem and ATargetItem normally refer to the
      same moved object.

      For an inter-bar drag, ATargetItem refers to the item created in the target
      bar from the source item. Removing the original source item, when desired,
      remains the responsibility of the application or calling layer.
    }
    TNoReflowTabBarItemDroppedEvent = Procedure(
        Sender: TObject;
        ASourceBar: TObject;
        ASourceItem: TNoReflowTabBarItem;
        ATargetItem: TNoReflowTabBarItem;
        ATargetZone: TNoReflowTabBarPinZone;
        ATargetZoneIndex: Integer) Of Object;

    {
      Event fired while a dragged item is hovering over a bar item.

      This event does not mean that the dragged item will be inserted into the
      bar. It lets the application react to functional hover states, for example
      by activating a menu page, opening a group, displaying contextual help, or
      deciding whether the hovered item should react to this drag.

      ASourceBar identifies the source bar or owner of the drag. ASourceItem is
      the dragged item. AItemIndex and AItem identify the item currently under
      the drag. Set Accept to False to indicate that this item does not accept
      this kind of hover reaction.
    }
    TNoReflowTabBarItemDragOverEvent = Procedure(
        Sender: TObject;
        ASourceBar: TObject;
        ASourceItem: TNoReflowTabBarItem;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem;
        Var Accept: Boolean) Of Object;

    {
      Event fired when a drag operation leaves the item that was previously
      hovered.

      Applications can use this event to clear visual or functional state that
      was set by OnItemDragOver.
    }
    TNoReflowTabBarItemDragLeaveEvent = Procedure(
        Sender: TObject;
        ASourceBar: TObject;
        ASourceItem: TNoReflowTabBarItem;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem) Of Object;

    {
      Event fired before inline caption editing starts for an item.

      Set Allow to False to prevent editing. This is useful to keep fixed items
      read-only, apply application-specific permissions, or disable editing
      depending on the current context.
    }
    TNoReflowTabBarCanEditItemCaptionEvent = Procedure(
        Sender: TObject;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem;
        Var Allow: Boolean) Of Object;

    {
      Event fired just before a new item caption is accepted.

      ANewCaption is writable. The handler can trim it, normalise casing,
      replace a forbidden value, or reject the change by setting Accept to False.

      When Accept is False, the edit operation is cancelled and the original
      caption is preserved.
    }
    TNoReflowTabBarValidateItemCaptionEvent = Procedure(
        Sender: TObject;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem;
        Const AOldCaption: String;
        Var ANewCaption: String;
        Var Accept: Boolean) Of Object;

    {
      Event fired after an item caption has been effectively changed.

      This is the event an application should handle to persist the new caption
      in a database, configuration file, user profile or other application
      storage.
    }
    TNoReflowTabBarItemCaptionEditedEvent = Procedure(
        Sender: TObject;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem;
        Const AOldCaption: String;
        Const ANewCaption: String) Of Object;

    {
      Event used to customise the GDI/VCL rendering of an item.

      This event is deliberately tied to TCanvas and therefore to the GDI
      backend. It is exposed through TNoReflowTabBar.OnGDIPaintItem. The
      Direct2D backend does not call this event; a future Direct2D-specific
      hook should use a dedicated Direct2D-aware contract instead of mixing
      rendering backends during the same paint pass.

      Unlike a simple rectangle-based paint callback, this event exposes:
      - the active component canvas;
      - the logical item object;
      - the item bounding rectangle;
      - the real polygonal outline used for painting and hit testing;
      - the computed content metrics prepared by the layout;
      - the resolved visual state.

      The handler can either leave ADefaultDraw set to True to keep the standard
      GDI drawing pipeline, or set it to False and perform the full GDI drawing
      itself.

      AText contains the resolved display text for the item, after applying
      OnGetItemText when assigned. The same text is used by the component during
      measurement, provided OnGetItemText remains stable during the layout and
      paint cycle.
    }
    TNoReflowTabBarGDIPaintEvent = Procedure(
        Sender: TObject;
        ACanvas: TCanvas;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem;
        Const AText: String;
        Const ABounds: TRect;
        Const ARegionPoints: TArray<TPoint>;
        Const AMetrics: TNoReflowTabBarItemMetrics;
        AVisualState: TNoReflowTabBarItemVisualState;
        Var ADefaultDraw: Boolean) Of Object;

    {
      Legacy source-level alias kept for code that referenced the old event
      type name directly. The published event property itself has been renamed
      to OnGDIPaintItem to make the backend dependency explicit.
    }
    TNoReflowTabBarPaintEvent = TNoReflowTabBarGDIPaintEvent;


    {
      Event fired when a mouse click activates a valid item.

      Unlike the standard TControl.OnClick event, this event explicitly provides
      the item involved in the click and the relevant mouse information.
    }
    TNoReflowTabBarClickEvent = Procedure(
        Sender: TObject;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem;
        Button: TMouseButton;
        Shift: TShiftState;
        X, Y: Integer) Of Object;

    {
      Event fired when a mouse double-click activates a valid item.

      The standard control double-click event is not published by the component
      in order to avoid ambiguity between the bar itself and its virtual items.
    }
    TNoReflowTabBarDblClickEvent = Procedure(
        Sender: TObject;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem;
        Shift: TShiftState;
        X, Y: Integer) Of Object;

    {
      Event fired when the mouse enters or leaves a virtual item.

      Unlike OnMouseEnter and OnMouseLeave, this event refers to a precise item
      managed by the bar.
    }
    TNoReflowTabBarMouseEvent = Procedure(
        Sender: TObject;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem;
        Shift: TShiftState;
        X, Y: Integer) Of Object;

    {
      Event fired when the mouse enters or leaves a logical zone.

      APinZone is nrtpzStart, nrtpzCenter or nrtpzEnd depending on the zone
      involved in the transition.
    }
    TNoReflowTabBarZoneMouseEvent = Procedure(
        Sender: TObject;
        APinZone: TNoReflowTabBarPinZone;
        Shift: TShiftState;
        X, Y: Integer) Of Object;

    {
      Event used to resolve the text displayed for an item dynamically.

      AText initially contains AItem.Caption. The handler can replace it to
      display calculated text without modifying the TNoReflowTabBarItem object.
    }
    TNoReflowTabBarGetItemTextEvent = Procedure(
        Sender: TObject;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem;
        Var AText: String) Of Object;

    {
      Event used to resolve the hint displayed for an item dynamically.

      AHint initially contains AItem.Hint, or the resolved item text when the
      item hint is empty. Set AShowHint to False to disable the hint for this
      item.
    }
    TNoReflowTabBarGetItemHintEvent = Procedure(
        Sender: TObject;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem;
        Var AHint: String;
        Var AShowHint: Boolean) Of Object;

    {
      Event used to override item text measurement.

      The component first computes the standard measurement. The handler can
      replace it by changing ATextWidth and ATextHeight, then setting AHandled
      to True.
    }
    TNoReflowTabBarMeasureItemEvent = Procedure(
        Sender: TObject;
        ACanvas: TCanvas;
        AItemIndex: Integer;
        AItem: TNoReflowTabBarItem;
        ASelectedFont: Boolean;
        Var ATextWidth: Integer;
        Var ATextHeight: Integer;
        Var AHandled: Boolean) Of Object;

implementation


end.

