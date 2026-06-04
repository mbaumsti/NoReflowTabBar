# Layout and zones

NoReflowTabBar is built around a stable layout engine. Its main purpose is to keep items predictable when the available space changes or when the user selects an item.

## Layout ownership

The layout/support layer owns item positioning. It computes bounds, text rectangles, glyph rectangles, signal rectangles, outline polygons and zone-header primitives before rendering starts. GDI and Direct2D backends must consume these values and draw them; they must not correct positions locally.

The global layout is computed in a canonical horizontal Top coordinate system, then transformed to the requested bar position. This keeps Top, Bottom, Left and Right positions consistent and avoids maintaining separate layout algorithms for each orientation.

## Stable multi-row layout

Classic multi-row tab controls may move rows when a tab is selected. NoReflowTabBar avoids that kind of disruptive reflow.

The layout engine distributes items across several rows or columns while preserving a stable logical order. The user should not lose the visual position of an item simply because it has been clicked.

## Layout modes

`BarLayoutMode` controls the layout strategy.

### `nrblmSequential`

Sequential layout places items in a simple logical sequence. It is useful when the bar is mostly a classic tab or button list.

### `nrblmByZones`

Zone-aware layout treats the `Start`, `Center` and `End` zones as separate logical groups. This mode is recommended for grouped navigation, application menus and command surfaces.

## Bar position

`BarPosition` controls how the bar is visually interpreted:

- `nrtbpTop`
- `nrtbpBottom`
- `nrtbpLeft`
- `nrtbpRight`

This property is independent from the VCL `Align` property. `Align` controls where the control is placed in its parent. `BarPosition` controls the visual orientation of items, text and layout calculations.

## Zones

Items can be placed in one of three zones:

- `Start`
- `Center`
- `End`

The zones allow one bar to contain several logical groups without needing several controls.

Typical examples:

- `Start`: main modules or primary commands.
- `Center`: current workflow or document entries.
- `End`: settings, tools or auxiliary commands.

## Zone headers

`BarZoneHeader` controls optional visual headers for zones.

Zone headers are decorative labels rendered by the bar. They are not separate VCL controls. They can be used to make grouped bars easier to understand.

A zone header is useful when:

- several logical groups share one bar;
- the bar is used as a compact menu;
- a vertical bar needs clearer sections;
- items have short captions and need contextual grouping.

When zone headers are too long for the available space, they are treated as decorative text and truncated rather than forcing the layout to expand. Header captions are bounded by the computed zone width and ellipsized when needed.

## Flow order

`BarFlowOrder` controls the logical order in which zones and items are presented to the zone layout engine.

Available values are:

- `nrtfoNormal`: `Start`, then `Center`, then `End`, with items in their natural order.
- `nrtfoReverseZones`: `End`, then `Center`, then `Start`, with items in their natural order.
- `nrtfoReverseZonesAndItems`: `End`, then `Center`, then `Start`, with items reversed inside each zone.

This does not rewrite the item collection. It affects how the layout is computed.

## Flow alignment

`BarLayout.FlowAlignment` controls how a line or column is aligned when there is remaining space:

- start alignment;
- centered alignment;
- end alignment.

This is especially visible when the bar has fewer items than the available space or when a line is not full.

## Same length and same thickness

`BarLayoutTabs.SameLength` and `BarLayoutTabs.SameThickness` can be used to make tab-like items more regular.

These options are mostly visual. They help create a more consistent tab strip when item captions have very different lengths.

## Forced length and forced thickness

Button layout can also use forced logical dimensions.

`ForcedLength` constrains the item size along the text flow axis. `ForcedThickness` constrains the item size along the cross axis.

`MinimumLength` is specific to button modes and is used only when `ForcedLength` is 0. In that case, the natural logical button length is computed from the content as usual, then enlarged to `MinimumLength` only when the computed length is smaller.

When `MinimumLength` adds extra logical length and the glyph is placed above or below the caption, the stacked glyph/caption block is centered on the logical flow axis in the useful area that remains after reserving any status signal. With horizontal text this means horizontal centering; with vertical text this means vertical centering. This keeps menu-like buttons visually balanced without moving the signal. Glyph-left and glyph-right layouts intentionally keep the historical aligned behavior.

For horizontal text, length usually corresponds to width and thickness to height. For vertical text, the meaning is intentionally logical rather than physical: length follows the text direction and thickness follows the perpendicular direction.

When the available size is too small for every visual element, the content layout engine composes several candidates from scratch and keeps the first one that fits. The current fallback priority is:

1. full text + signal + glyph;
2. full text + signal;
3. shortened text + signal;
4. full text only;
5. shortened text only.

This avoids overlapping text, glyphs and signals. A visible status signal is preferred over a complete caption because the full text can usually still be available through the item hint.

## Text orientation

`BarTextOrientation` controls item text orientation:

- `nrttoAuto`
- `nrttoHorizontal`
- `nrttoVerticalUp`
- `nrttoVerticalDown`

Automatic orientation follows the bar position. Explicit orientation can be useful for special side navigation designs.


## Style-aware design-time rendering

When `BarPaletteMode` is configured to use VCL styles, NoReflowTabBar also resolves style colors at design time. In design mode, the component gives priority to the parent style context before falling back to the control style and then to the active global style. This makes the Object Inspector/design surface preview closer to the final styled runtime appearance.

## Shape options

Tab-like rendering can use additional shape options:

- overlap between tabs;
- slanted edges;
- rounded corners.

These options are part of `BarLayoutTabs`, because they describe tab-specific geometry. Button-specific geometry belongs to `BarLayoutButtons`.

## Practical recommendations

Use `nrblmByZones` for most modern grouped scenarios.

Use zone headers when the bar contains groups that would otherwise be ambiguous.

Avoid using one bar for too many unrelated behaviours at the same time. A bar can be powerful, but a clear UI still benefits from a clear role: navigation, workflow, command group or editable menu.
