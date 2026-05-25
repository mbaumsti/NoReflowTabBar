# Inline editing

NoReflowTabBar can optionally let the user edit item captions directly inside the bar.

## Enable editing

Use `BarEditEnabled` to enable or disable inline editing globally.

```pascal
NoReflowTabBar1.BarEditEnabled := True;
```

When enabled, editing can usually be started by:

- double-clicking an editable item;
- pressing `F2` on the current item.

The editor receives an explicit text geometry from the layout engine: text center, logical text length, logical text thickness and rendered text orientation. The active editor is then responsible for converting that geometry into its own position and dimensions. This keeps the bar independent from the concrete editor implementation.


## Inline editor architecture

The built-in editor is a standard VCL `TEdit`. NoReflowTabBar therefore works out of the box without any additional dependency.

The editing layer is extensible through `NoReflowTabBar_CaptionEditor.pas`. This unit defines the editor interface, the geometry record passed by the bar and the factory registration helpers used by optional editor adapters.

The geometry passed to an editor is intentionally explicit rather than a raw final `TRect`:

- `TextCenter`: center of the text reference area in the editor host coordinates;
- `TextLength`: useful logical text length;
- `TextThickness`: useful logical text thickness;
- `TextOrientation`: effective rendered text orientation.

A standard `TEdit` converts this geometry into a horizontal edit control. An orientation-aware editor can instead use the same geometry to align itself with horizontal or vertical captions.

## Optional VclRotatedEdit adapter

The repository includes an optional adapter for [`VclRotatedEdit`](https://github.com/mbaumsti/VclRotatedEdit). It allows NoReflowTabBar to use `TRotatedEdit` as its inline caption editor, which is especially useful when item captions are rendered vertically.

The adapter is located under:

```text
Optional_Packages/VclRotatedEdit/
```

It is not required by the main component. Install it only if `VclRotatedEdit` is also installed and you want rotated inline caption editing.

For applications compiled without runtime packages, add the adapter unit explicitly so its initialization section is linked and executed:

```pascal
uses
    NoReflowTabBar_VclRotatedEditAdapter;
```

## Editable zones

`BarEditZones` controls which zones allow editing.

This is independent from drag zones. A zone can be editable but not draggable, or draggable but not editable.

Example:

```pascal
NoReflowTabBar1.BarEditZones := [nrtezCenter];
```

## Authorise editing

Use `OnCanEditItemCaption` to reject editing for specific items.

```pascal
procedure TForm1.NoReflowTabBar1CanEditItemCaption(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    var Allow: Boolean);
begin
    Allow := (AItem <> nil) and not SameText(AItem.Caption, 'Locked');
end;
```

## Validate the new caption

Use `OnValidateItemCaption` to normalise or reject the edited text.

```pascal
procedure TForm1.NoReflowTabBar1ValidateItemCaption(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    const AOldCaption: string;
    var ANewCaption: string;
    var Accept: Boolean);
begin
    ANewCaption := Trim(ANewCaption);
    Accept := ANewCaption <> '';
end;
```

## React after editing

Use `OnItemCaptionEdited` to persist the change in application storage.

```pascal
procedure TForm1.NoReflowTabBar1ItemCaptionEdited(
    Sender: TObject;
    AItemIndex: Integer;
    AItem: TNoReflowTabBarItem;
    const AOldCaption: string;
    const ANewCaption: string);
begin
    SaveUserCaption(AItem.UserId, ANewCaption);
end;
```

## Practical recommendations

Keep system-defined items locked when their caption has a fixed business meaning.

Use editing mainly for user-defined navigation entries, custom menu labels, workflow labels or configurable command bars.

Do not assume that the editor width always equals the full caption width. In compact layouts, the visible caption may be ellipsized, and the editor is anchored on the visible text area while still keeping a practical minimum editing size.
