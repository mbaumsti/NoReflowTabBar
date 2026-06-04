# Rendering and styles

NoReflowTabBar separates layout from rendering.

The layout/support layer computes the final primitives used by every backend:

- item bounds;
- text rectangles and text anchors;
- glyph rectangles;
- signal rectangles;
- item outline polygons;
- zone-header segments and text rectangles;
- trimming permissions.

The render backends consume those primitives. They must not recompute positions locally to compensate for a visual issue. If an item, header, glyph, signal or caption is misplaced, the correction belongs in the layout/support layer.

## Rendering backend selection

The low-level backend is selected with `BarRenderBackendKind`:

- `ntrbkGDI` uses the historical GDI/GDI+ renderer.
- `ntrbkDirect2D` uses the Direct2D renderer introduced and stabilized in version 1.3.

`BarRenderMode` is independent from the backend. It controls the visual strategy used by the component, such as automatic, flat or gradient rendering.

`BarPaletteMode` controls where the colors come from:

- `nrtcmCustom` uses the colors stored in `BarAppearance`.
- `nrtcmStyle` derives colors from the active VCL style.

## GDI backend

The GDI/GDI+ backend is the historical renderer. It remains available for compatibility and for applications that use `OnGDIPaintItem`.

`OnGDIPaintItem` is intentionally tied to `TCanvas`; it is therefore called by the GDI backend only. The Direct2D backend does not call this event. A future Direct2D-specific custom drawing event would need a dedicated Direct2D-aware contract.

## Direct2D backend

The Direct2D backend draws the standard component content natively:

- bar content over an already prepared background;
- item surfaces and borders;
- zone headers;
- text;
- glyphs;
- status signals;
- focus and drag indicators when applicable.

The backend uses the same layout primitives as GDI. This is important because the component must behave the same way in Top, Bottom, Left and Right positions.

## Styled and textured backgrounds

A VCL style background may be a texture, not just a color. A plain Direct2D `FillRectangle` cannot reproduce such a background faithfully.

For this reason, when `BarPaletteMode = nrtcmStyle` and the active VCL style requires a styled background, NoReflowTabBar may ask the VCL/GDI style pipeline to paint only the general bar background first. Direct2D then draws the component content on top.

This is a limited hybrid path. It is not a full GDI fallback: the Direct2D backend remains responsible for the standard item, header, text, glyph and signal rendering.

## Text ellipsis and trimming

Text trimming is controlled by the layout/support layer. Renderers must not decide independently that a caption should be shortened.

This rule is especially important for Direct2D, because DirectWrite text metrics can differ slightly from the GDI metrics used during layout. In natural tab mode, captions should not be trimmed just because the Direct2D backend sees a slightly different measured width.

When trimming is allowed by the layout, the renderer may draw the ellipsis. When trimming is not allowed, the renderer must draw within the prepared text area without adding a local trimming decision.

## Maintainer rule

When fixing a visual issue, first identify whether it is a layout problem or a drawing problem.

- Wrong bounds, shifted text, misplaced glyphs, wrong signal placement, wrong header endpoint: fix the layout/support layer.
- Wrong brush, wrong antialiasing, wrong pixel coverage, wrong Direct2D/GDI primitive choice: fix the backend.

Do not add corrective offsets in a renderer to hide a layout problem.
