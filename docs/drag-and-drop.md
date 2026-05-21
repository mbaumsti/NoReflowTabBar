# Drag and drop

NoReflowTabBar supports item reordering inside one bar and item moves between compatible bars.

Drag and drop is optional and controlled by published properties and events.

## Internal reordering

`BarDragReorderMode` controls whether items can be reordered by mouse drag.

Available modes:

- `nrbrmNone`: drag reorder is disabled.
- `nrbrmSameZoneOnly`: items can be reordered only inside their original zone.
- `nrbrmAllZones`: items can be moved between enabled zones.

## Enabled drag zones

`BarDragReorderZones` controls which zones participate in drag reordering.

For example, a bar can allow drag only in `Center` while keeping `Start` and `End` fixed.

This is useful when some items are application-defined and others are user-customisable.

## Inter-bar drag and drop

`BarDragInterBarMode` controls drag and drop between bars. `BarDragInterBarGroup` defines which bars are compatible.

A common design is:

- one bar acts as a navigation or drop target;
- another bar acts as a source of commands;
- both bars share the same inter-bar group.

Only compatible bars should accept each other's items.

## Authorisation events

Use events to accept or reject a drag/drop operation.

Important events:

- `OnCanReorderItem`: called before an internal reorder is accepted.
- `OnCanDropItem`: called before a drop is accepted, including inter-bar drops.
- `OnItemDropped`: called after a drop has been accepted and applied.
- `OnBeginItemDrag`: called when drag starts.
- `OnEndItemDrag`: called when drag ends.
- `OnItemDragOver`: called when a dragged item is over an item.
- `OnItemDragLeave`: called when a dragged item leaves the previously hovered item.

## Page activation while dragging

`OnItemDragOver` is useful for menu-like interfaces.

For example, when dragging a command button over a navigation item, the application can select that navigation item and display the corresponding page, allowing the user to drop the command into a bar inside that page.

## Empty zones

A bar may contain no item in one of its zones. Empty zones still need meaningful drop candidates.

The drag engine should treat an empty zone as one possible candidate among the other candidates. It should not let an empty-zone fallback hide all insertion positions in populated zones.

This is especially important for inter-bar drag and drop, where the source item may come from `Center` while the target bar currently has only `Start` or `End` items.

## Practical recommendations

Enable drag only where it is meaningful. A demo can wire many drag events to show the event model, but production code should usually enable drag only on customisable bars.

Use `OnCanDropItem` for business rules. Examples:

- reject items from another functional group;
- prevent dropping into a locked zone;
- forbid user-defined items before system items;
- restrict drag between bars to compatible contexts.

Use `OnItemDropped` to persist the new layout if the application stores user customisation.
