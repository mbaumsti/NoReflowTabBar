# Optional package: VclRotatedEdit adapter

This optional package lets `NoReflowTabBar` use [`TRotatedEdit`](https://github.com/mbaumsti/VclRotatedEdit) as its inline caption editor.

`NoReflowTabBar` itself does **not** require [`VclRotatedEdit`](https://github.com/mbaumsti/VclRotatedEdit). The main packages remain independent:

- `NoReflowTabBarR`
- `NoReflowTabBarDesign`

The adapter package is only for users who have also installed [`VclRotatedEdit`](https://github.com/mbaumsti/VclRotatedEdit):

- `VclRotatedEditR`
- `VclRotatedEditDesign`

## Packages

Runtime adapter:

```text
NoReflowTabBarVclRotatedEditAdapterR.dpk
```

Design-time adapter:

```text
NoReflowTabBarVclRotatedEditAdapterDesign.dpk
```

## Install order

Recommended order:

1. Download or clone [`VclRotatedEdit`](https://github.com/mbaumsti/VclRotatedEdit).
2. Install `VclRotatedEditR`.
3. Install `VclRotatedEditDesign`.
4. Install `NoReflowTabBarR`.
5. Install `NoReflowTabBarDesign`.
6. Build `NoReflowTabBarVclRotatedEditAdapterR`.
7. Install `NoReflowTabBarVclRotatedEditAdapterDesign`.

## Behavior

When this optional adapter package is loaded, it registers a `TRotatedEdit`-backed caption editor factory through `NoReflowTabBar_CaptionEditor`.

If this package is not installed or not loaded, `NoReflowTabBar` continues to use its built-in standard `TEdit` editor.

The adapter receives an explicit `TNoReflowTabBarCaptionEditorGeometry` record from the TabBar editing layer. This record contains:

- `TextCenter`: the center of the text reference area in host coordinates;
- `TextLength`: the useful logical text length;
- `TextThickness`: the useful logical text thickness;
- `TextOrientation`: the effective rendered orientation.

The adapter maps this explicit geometry to `TRotatedEdit`'s logical model: `TextLength` is assigned to `LogicalLength`, `TextThickness` is assigned to `LogicalThickness`, and `TextOrientation` is translated to `Angle`. The projected editor control is then centered on `TextCenter`.

For applications compiled without runtime packages, add the adapter unit explicitly to the project or to one application unit so its initialization section is linked and executed:

```pascal
Uses
    NoReflowTabBar_VclRotatedEditAdapter;
```

## Important rule

Do not add the adapter unit to `NoReflowTabBarR`.

The adapter must remain isolated in this optional package because it depends on both `NoReflowTabBarR` and `VclRotatedEditR`.
