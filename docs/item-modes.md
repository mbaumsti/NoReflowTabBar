# Item modes

`BarMode` defines how items behave when the user clicks them.

The same visual component can be used as a tab bar, a push-button bar, a selectable button bar or a check-button bar.

## `nrbmTabs`

Classic tab-like behaviour.

Characteristics:

- one active item;
- `BarCurrentItemIndex` represents the selected item;
- the selected item is visually active;
- useful for switching pages or views.

Use this mode when the bar represents mutually exclusive content pages.

## `nrbmPushButtons`

Button-like behaviour without persistent selection.

Characteristics:

- clicking an item triggers an action;
- no persistent selected item is required;
- `OnItemClick` is usually the main event;
- useful for command bars or action launchers.

Use this mode when items are commands rather than stateful choices.

## `nrbmSelectButtons`

Button rendering with single-selection behaviour.

Characteristics:

- one item is selected;
- the visual style is button-oriented;
- useful for module selection or navigation menus.

Use this mode when the UI should look like buttons but behave like a single-choice navigation bar.

## `nrbmCheckButtons`

Independent checked states.

Characteristics:

- several items can be checked at the same time;
- `Checked` is the main item state;
- `BarCheckedItems` and `BarCheckedCount` are useful helpers;
- useful for filters, toggles and display options.

Use this mode when items represent independent on/off options.

## `OnChange` versus `OnItemClick`

`OnChange` is a state event. It means the active item changed.

`OnItemClick` is an interaction event. It means the user clicked an item.

This distinction matters:

- in tab mode, both may be relevant;
- in push-button mode, `OnItemClick` is usually more relevant;
- in check-button mode, use checked-state helpers when the final state matters;
- in selectable-button mode, `OnChange` is usually the navigation event.

## Double-click behaviour

If `OnItemDblClick` is assigned, the component may delay the simple click notification so that a real double-click does not also emit a normal item click.

The item activation itself should remain immediate. Only the application-level click notification needs to be delayed.

## Checked state helpers

Useful methods and properties include:

- `IsBarItemChecked`
- `SetBarItemChecked`
- `ToggleBarItemChecked`
- `ClearBarCheckedItems`
- `BarCheckedItems`
- `BarCheckedCount`

Use them instead of directly manipulating `Checked` when application code needs to express intent clearly.
