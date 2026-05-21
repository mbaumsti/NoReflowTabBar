# Persistence

NoReflowTabBar includes a storage layer for saving and restoring layout-related item state.

The storage layer is intentionally independent from a specific backend. Applications can store the generated data in a file, INI file, registry, database, memory stream or any other storage system.

## What can be persisted

The storage options can include different parts of the item state, such as:

- placement;
- zone and zone index;
- selection;
- checked state;
- visibility;
- caption;
- glyph-related values.

The exact stored parts are controlled by `TNoReflowTabBarStorageOptions`.

## Storage options

The component provides predefined option sets such as:

- placement only;
- full storage;
- user layout storage;
- placement without selection;
- placement and captions;
- center placement only.

Use custom options when the application needs precise control.

## Save to strings

```pascal
var
    Lines: TStringList;
begin
    Lines := TStringList.Create;
    try
        NoReflowTabBar1.SaveStorageToStrings(
            Lines,
            TNoReflowTabBarStorageOptions.UserLayoutStorage);

        Lines.SaveToFile('bar-layout.txt', TEncoding.UTF8);
    finally
        Lines.Free;
    end;
end;
```

## Load from strings

```pascal
var
    Lines: TStringList;
begin
    Lines := TStringList.Create;
    try
        Lines.LoadFromFile('bar-layout.txt', TEncoding.UTF8);

        NoReflowTabBar1.LoadStorageFromStrings(
            Lines,
            TNoReflowTabBarStorageOptions.UserLayoutStorage);
    finally
        Lines.Free;
    end;
end;
```

## Save to stream or file

The storage support also provides stream and file wrappers:

```pascal
NoReflowTabBar1.SaveStorageToFile(
    'bar-layout.txt',
    TNoReflowTabBarStorageOptions.UserLayoutStorage);
```

```pascal
NoReflowTabBar1.LoadStorageFromFile(
    'bar-layout.txt',
    TNoReflowTabBarStorageOptions.UserLayoutStorage);
```

## DFM-state snapshots

The demo application also shows another useful pattern: saving a component snapshot to a memory stream with `WriteComponent`, then restoring it with `ReadComponent`.

That approach is useful for Reset buttons inside a demo because it restores the initial DFM state without duplicating item creation logic in code.

For application user settings, prefer the component storage API because it is more explicit and does not require serialising the whole component.

## Practical recommendations

Use stable item keys or user identifiers when restoring user customisation.

Avoid persisting purely visual demo state unless the application genuinely needs it.

Store only the parts the user is expected to customise. For example, a production application may persist item order and visibility, but keep captions defined by the application.
