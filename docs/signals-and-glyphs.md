# Signals and glyphs

NoReflowTabBar items can display both glyphs and signal indicators.

These two concepts are independent.

When item size is constrained, the layout engine treats them differently. Glyphs are useful visual identity markers, but signals represent state. For this reason, when everything cannot fit, the engine may remove the glyph before removing the signal.

## Glyphs

A glyph is the main visual image associated with an item.

The usual setup is:

1. assign an image list to `BarImages`;
2. set `GlyphIndex` on the item;
3. optionally configure glyph visibility and glyph placement.

Glyphs are useful for:

- compact navigation;
- command bars;
- recognisable workflow steps;
- menu-like interfaces.

## Signals

A signal is a small status indicator associated with an item.

Signals are defined in the bar-level `BarSignals` collection. An item references a signal with `SignalCode` or `SignalName`.

The value `SignalCode = 0` means no signal.

Signals are useful for:

- warning or error state;
- completed / pending state;
- document availability;
- production status;
- application-specific flags.

## Custom signal colours

Applications can add custom signals at runtime:

```pascal
var
    Signal: TNoReflowTabBarSignalDef;
begin
    Signal := NoReflowTabBar1.BarSignals.Add;
    Signal.Code := 100;
    Signal.Name := 'RGB(255,128,0)';
    Signal.FillColor := RGB(255, 128, 0);
    Signal.BorderColor := clBlack;
end;
```

Then assign it to an item:

```pascal
NoReflowTabBar1.BarItems[0].SignalCode := 100;
```

## Partial signal fill

Items expose `SignalValue` and `SignalMax`. These values can be used by the renderer to display a partially filled signal.

Examples:

```text
SignalValue = 3,  SignalMax = 4
SignalValue = 75, SignalMax = 100
```

If `SignalMax <= 0`, the signal should be considered full.

## Fallback priority when space is limited

Signals are considered important status indicators. When the item is too small to display text, signal and glyph together, the content layout engine tries to preserve the signal before preserving the glyph.

The fallback order is:

1. full text + signal + glyph;
2. full text + signal;
3. shortened text + signal;
4. full text only;
5. shortened text only.

This means a signal can remain visible even when the caption is ellipsized. The complete caption can still be exposed through the item hint.

## Practical recommendations

Use glyphs for identity and signals for state. This distinction also matches the layout fallback rules: identity glyphs may be hidden in very compact items, while state signals are kept as long as possible.

Avoid replacing short captions with too many visual indicators. A bar remains easier to understand when each visual element has a stable meaning.
