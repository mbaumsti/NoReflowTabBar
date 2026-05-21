# Core concepts

This document explains the main concepts used by `TNoReflowTabBar`.

## Bar

The bar is the `TNoReflowTabBar` control itself. It owns the item collection, layout settings, rendering settings, signal definitions and interaction options.

A bar can behave as:

- a tab bar;
- a push-button bar;
- a selectable navigation bar;
- a check-button bar.

The behaviour is controlled by `BarMode`.

## Item

An item is an entry inside `BarItems`. It is represented by `TNoReflowTabBarItem`.

An item can have:

- a caption;
- a logical zone;
- a zone index;
- a user identifier;
- a checked state;
- an enabled / visible state;
- a glyph;
- a signal indicator;
- a hint;
- optional user data.

Although the component name contains `TabBar`, an item is not necessarily a tab. Depending on `BarMode`, the same item can behave as a tab, a push button, a selectable button or a check button.

## Zones

The component uses three logical zones:

- `Start`
- `Center`
- `End`

Internally these correspond to `nrtpzStart`, `nrtpzCenter` and `nrtpzEnd`.

Zones are used to group unrelated items in the same visual bar. Typical examples are:

- navigation entries on the left and configuration entries on the right;
- workflow steps in the center and utility buttons at the end;
- document categories separated from application commands.

## Zone index

`ZoneIndex` is the position of an item inside its own zone.

The physical collection order is normalised by zone, but application code should usually reason in terms of zone and zone index rather than raw collection order.

## Current item

`BarCurrentItemIndex` is the main current item index. Its meaning depends on `BarMode`:

- in `nrbmTabs`, it is the selected tab;
- in `nrbmSelectButtons`, it is the selected button;
- in `nrbmCheckButtons`, it is the last current or activated item;
- in `nrbmPushButtons`, it can represent the last activated item without creating a persistent selection.

Use `BarCurrentItem` to access the current item object directly.

## Selected items

The component exposes selection-oriented helpers:

- `BarSelectedItems`
- `BarSelectedCount`
- `HasBarSelectedItems`

Their meaning depends on the current mode. In check-button mode, selected items are the checked items. In push-button mode, there is normally no persistent selected item.

## Checked items

Checked state is carried by each item. It can be queried independently from the current bar mode:

- `BarCheckedItems`
- `BarCheckedCount`
- `IsBarItemChecked`
- `SetBarItemChecked`
- `ToggleBarItemChecked`
- `ClearBarCheckedItems`

In `nrbmCheckButtons`, `Checked` is the main state. In tab and selectable-button modes, the checked state is normally synchronised with the active item.

## Signals

Signals are small status indicators associated with items. They are defined in `BarSignals` and referenced by each item through `SignalCode` or `SignalName`.

Signals can be used for status, warnings, progress, workflow state or application-specific flags.

## Glyphs

Items can display images. The usual source is the bar image list through `BarImages` and an item `GlyphIndex`.

Glyphs and signals are independent: an item can have one, both or neither.

## Rendering mode

`BarRenderMode` controls the rendering strategy:

- `nrrmAuto`
- `nrrmFlat`
- `nrrmGradient`

`BarPaletteMode` controls whether colours are based on custom appearance settings or on the current VCL style.

## Layout mode

`BarLayoutMode` selects the layout engine:

- `nrblmSequential`: sequential layout.
- `nrblmByZones`: zone-aware layout.

The zone-aware layout is the main layout mode for grouped and stable multi-row bars.

## Design-time and runtime use

The component is intended to work well at design time. Most important properties are published and can be configured in the Object Inspector.

Runtime code should focus on behaviour: reacting to events, changing selection, changing enabled states, saving or restoring layout, and adding application-specific items when necessary.
