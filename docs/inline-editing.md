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

For horizontal text, the editor is positioned from the computed text rectangle returned by the layout engine. This keeps editing aligned with the visible caption even when the caption is ellipsized or when the item uses forced length or forced thickness.

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
