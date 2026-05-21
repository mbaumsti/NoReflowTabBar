Unit NoReflowTabBar_RenderTypes;

{
  NoReflowTabBar_RenderTypes.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Intermediate render structures for the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Intermediate render structures used by the NoReflowTabBar component.

  This unit provides:
  - TNoReflowTabBarRenderItem, the computed representation of one logical item
    during layout, painting and hit testing.

  Role of this unit:
  - separate calculated render data from persistent item data;
  - provide stable structures shared by layout, painting and hit testing;
  - prevent the rendering pipeline from repeatedly querying the persistent item
    collection during every calculation step.

  Typical information stored in these structures includes:
  - computed item dimensions;
  - resolved item state;
  - final item bounds;
  - computed text, glyph and signal metrics;
  - the actual polygonal outline used for painting and hit testing.

  Architecture:
  - persistent item data is defined in NoReflowTabBar_Items;
  - common item metrics are defined in NoReflowTabBar_CommonTypes;
  - render items are produced by the Core, LayoutSupport and RenderSupport
    layers;
  - the final NoReflowTabBar control uses them when painting and hit testing.

  Notes:
  - these structures describe calculated, non-persistent state;
  - they are not the main public business API for items;
  - they act as the intermediate representation between the item model and the
    visual rendering pipeline.
}

Interface

Uses
    System.Types,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_Items;

Type
    {
      Intermediate representation of an item prepared for rendering.

      A render item connects the persistent item model represented by
      TNoReflowTabBarItem to the actual screen representation used by the
      component.

      It stores the resolved state, final bounds, computed content metrics and
      polygonal region of one item for the current layout pass.

      The component uses this structure for:
      - painting;
      - hit testing;
      - custom item painting callbacks;
      - drag marker and insertion target calculations;
      - layout diagnostics and internal render decisions.

      This record is recalculated by the component and must not be considered
      persistent application data.
    }
    TNoReflowTabBarRenderItem = Record
        {
          Source logical item represented by this render item.
        }
        Item: TNoReflowTabBarItem;

        {
          Current absolute index of the source item in the item collection.
        }
        ItemIndex: Integer;

        {
          Resolved visibility state at calculation time.
        }
        Visible: Boolean;

        {
          Resolved enabled state at calculation time.
        }
        Enabled: Boolean;

        {
          True when the item is currently selected or otherwise considered the
          active item according to the current bar mode.
        }
        Selected: Boolean;

        {
          True when the item is currently under the mouse pointer.
        }
        Hot: Boolean;

        {
          Final item bounds in control client coordinates.
        }
        Bounds: TRect;

        {
          Computed content metrics used by the layout and rendering pipeline.
        }
        Metrics: TNoReflowTabBarItemMetrics;

        {
          Exact polygonal outline used for painting and hit testing.

          This allows the component to respect slanted shapes, overlaps and
          non-rectangular tab geometry instead of relying only on Bounds.
        }
        RegionPoints: TArray<TPoint>;
    End;

Implementation

End.

