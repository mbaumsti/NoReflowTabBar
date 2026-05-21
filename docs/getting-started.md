# Getting started

This guide shows the shortest path to using `TNoReflowTabBar` in a Delphi VCL application.

## Add the component to a form

Install the runtime and design-time packages, then place a `TNoReflowTabBar` on a VCL form.

The component is designed to be useful at design time: items, zones, signals, layout options and rendering options can be configured in the Object Inspector.

For a first test, set these properties:

```text
BarMode       = nrbmTabs
BarLayoutMode = nrblmByZones
BarPosition   = nrtbpTop
```

Then add several items to `BarItems`.

## Add items at design time

Open the `BarItems` collection editor and create items.

Useful item properties are:

- `Caption`: text displayed by the item.
- `Zone`: logical zone displayed in the Object Inspector.
- `ZoneIndex`: position inside its zone.
- `Checked`: checked or selected state, depending on the bar mode.
- `SignalCode` or `SignalName`: optional signal indicator.
- `GlyphIndex`: image index used with `BarImages`.
- `Visible`: whether the item participates in layout and rendering.
- `Enabled`: whether the item can be selected or clicked.

## Add items at runtime

Use the zone-specific helper methods when possible. They express the intended placement more clearly than manipulating the collection directly.

```pascal
procedure TForm1.FormCreate(Sender: TObject);
begin
    NoReflowTabBar1.BarMode := nrbmTabs;
    NoReflowTabBar1.BarLayoutMode := nrblmByZones;

    NoReflowTabBar1.AddStartItem('Home');
    NoReflowTabBar1.AddCenterItem('Production');
    NoReflowTabBar1.AddCenterItem('Planning');
    NoReflowTabBar1.AddEndItem('Settings');
end;
```

## Select an item

For tab and selectable-button modes, use `BarCurrentItemIndex` or the selection helper methods.

```pascal
NoReflowTabBar1.BarCurrentItemIndex := 0;
```

To move selection through the bar:

```pascal
NoReflowTabBar1.SelectNext;
NoReflowTabBar1.SelectPrevious;
```

## React to selection changes

Use `OnChange` when the application must react to the active item changing.

```pascal
procedure TForm1.NoReflowTabBar1Change(
    Sender: TObject;
    OldItem: TNoReflowTabBarItem;
    NewItem: TNoReflowTabBarItem);
begin
    if NewItem = nil then
        Exit;

    StatusBar1.SimpleText := 'Selected: ' + NewItem.Caption;
end;
```

Use `OnChanging` if the application must be able to reject a selection change.

## React to clicks

Use `OnItemClick` for command-like behaviour.

```pascal
procedure TForm1.NoReflowTabBar1ItemClick(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    Button: TMouseButton;
    Shift: TShiftState;
    X, Y: Integer);
begin
    if AItem = nil then
        Exit;

    ShowMessage('Clicked: ' + AItem.Caption);
end;
```

`OnChange` and `OnItemClick` do not have the same role:

- `OnChange` means the active item changed.
- `OnItemClick` means the user clicked an item.

In `nrbmPushButtons`, a click does not create a persistent selection, so `OnItemClick` is usually more important than `OnChange`.

## Use the demo as a reference

The demo application is the best starting point for visual configuration. It shows:

- grouped zones;
- all bar modes;
- layout and rendering options;
- signals;
- drag and drop;
- inline editing;
- local state snapshots and reset actions.

The demo intentionally keeps most visual setup in the DFM, which makes it useful as a design-time configuration reference.
