unit NoReflowTabBar_AppearanceAndLayout;

{
  NoReflowTabBar_AppearanceAndLayout.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Appearance and layout sub-objects used by the NoReflowTabBar VCL component.

  Repository:
  https://github.com/mbaumsti/NoReflowTabBar

  License:
  Mozilla Public License 2.0.
  See LICENSE file.

  ------------------------------------------------------------------------------

  Persistent appearance and layout configuration objects for NoReflowTabBar.

  This unit provides:
  - TNoReflowTabBarAppearance, custom colors for tab and button rendering;
  - TNoReflowTabBarLayout, common margins, spacing and content layout options;
  - TNoReflowTabBarLayoutTabs, tab-specific shape and overlap settings;
  - TNoReflowTabBarLayoutButtons, button-specific shape and sizing settings.

  Role of this unit:
  - isolate visual and layout parameters from the main control;
  - expose these parameters cleanly in the Delphi Object Inspector;
  - notify the owning control when a visual or layout property changes;
  - keep appearance, common layout, tab geometry and button geometry separated.

  Architecture notes:
  - this unit does not draw anything by itself;
  - it describes rendering and layout settings consumed by the core and render
  layers;
  - change callbacks keep these persistent sub-objects decoupled from the final
  TNoReflowTabBar facade.
}

interface

Uses
    System.Classes,
    Vcl.Graphics,
    NoReflowTabBar_CommonTypes;

Type
    {
      Notification event used by persistent appearance and layout sub-objects.

      The owner component handles this event to invalidate layout, palette or
      painting state without forcing the sub-object to depend directly on the
      final TNoReflowTabBar class.
    }
    TNoReflowTabBarObjectChangedEvent = Procedure(Sender: TObject) Of Object;

    {
      Persistent color configuration object used by NoReflowTabBar.

      This class stores the custom colors used when BarPaletteMode selects the
      component-defined palette. It contains separate color groups for tab
      rendering and button rendering, plus focus and edge colors used by the
      drawing pipeline.

      Instances are owned by the bar and are exposed through the BarAppearance
      property.
    }
    TNoReflowTabBarAppearance = Class(TPersistent)
    private
        FOwner:     TPersistent;
        FOnChanged: TNoReflowTabBarObjectChangedEvent;

        FTabNormalTop:    TColor;
        FTabNormalBottom: TColor;
        FTabNormalText:   TColor;
        FTabNormalBorder: TColor;

        FTabHotTop:    TColor;
        FTabHotBottom: TColor;
        FTabHotText:   TColor;
        FTabHotBorder: TColor;

        FTabSelectedTop:    TColor;
        FTabSelectedBottom: TColor;
        FTabSelectedText:   TColor;
        FTabSelectedBorder: TColor;

        FTabPressedTop:    TColor;
        FTabPressedBottom: TColor;
        FTabPressedText:   TColor;
        FTabPressedBorder: TColor;

        FTabDisabledTop:    TColor;
        FTabDisabledBottom: TColor;
        FTabDisabledText:   TColor;
        FTabDisabledBorder: TColor;

        FTabLightEdge:  TColor;
        FTabShadowEdge: TColor;

        FButtonNormalTop:    TColor;
        FButtonNormalBottom: TColor;
        FButtonNormalText:   TColor;
        FButtonNormalBorder: TColor;

        FButtonHotTop:    TColor;
        FButtonHotBottom: TColor;
        FButtonHotText:   TColor;
        FButtonHotBorder: TColor;

        FButtonPressedTop:    TColor;
        FButtonPressedBottom: TColor;
        FButtonPressedText:   TColor;
        FButtonPressedBorder: TColor;

        FButtonSelectedTop:    TColor;
        FButtonSelectedBottom: TColor;
        FButtonSelectedText:   TColor;
        FButtonSelectedBorder: TColor;

        FButtonDisabledTop:    TColor;
        FButtonDisabledBottom: TColor;
        FButtonDisabledText:   TColor;
        FButtonDisabledBorder: TColor;

        FButtonLightEdge:  TColor;
        FButtonShadowEdge: TColor;

        FFocusColor: TColor;

        FUpdating: Integer;

        //Notifies the owning component that an appearance property changed.
        Procedure Changed;

        //Tab color setters.
        Procedure SetTabNormalTop(Const Value: TColor);
        Procedure SetTabNormalBottom(Const Value: TColor);
        Procedure SetTabNormalText(Const Value: TColor);
        Procedure SetTabNormalBorder(Const Value: TColor);

        Procedure SetTabHotTop(Const Value: TColor);
        Procedure SetTabHotBottom(Const Value: TColor);
        Procedure SetTabHotText(Const Value: TColor);
        Procedure SetTabHotBorder(Const Value: TColor);

        Procedure SetTabSelectedTop(Const Value: TColor);
        Procedure SetTabSelectedBottom(Const Value: TColor);
        Procedure SetTabSelectedText(Const Value: TColor);
        Procedure SetTabSelectedBorder(Const Value: TColor);

        Procedure SetTabPressedTop(Const Value: TColor);
        Procedure SetTabPressedBottom(Const Value: TColor);
        Procedure SetTabPressedText(Const Value: TColor);
        Procedure SetTabPressedBorder(Const Value: TColor);

        Procedure SetTabDisabledTop(Const Value: TColor);
        Procedure SetTabDisabledBottom(Const Value: TColor);
        Procedure SetTabDisabledText(Const Value: TColor);
        Procedure SetTabDisabledBorder(Const Value: TColor);

        //Button color setters.
        Procedure SetButtonNormalTop(Const Value: TColor);
        Procedure SetButtonNormalBottom(Const Value: TColor);
        Procedure SetButtonNormalText(Const Value: TColor);
        Procedure SetButtonNormalBorder(Const Value: TColor);

        Procedure SetButtonHotTop(Const Value: TColor);
        Procedure SetButtonHotBottom(Const Value: TColor);
        Procedure SetButtonHotText(Const Value: TColor);
        Procedure SetButtonHotBorder(Const Value: TColor);

        Procedure SetButtonPressedTop(Const Value: TColor);
        Procedure SetButtonPressedBottom(Const Value: TColor);
        Procedure SetButtonPressedText(Const Value: TColor);
        Procedure SetButtonPressedBorder(Const Value: TColor);

        Procedure SetButtonSelectedTop(Const Value: TColor);
        Procedure SetButtonSelectedBottom(Const Value: TColor);
        Procedure SetButtonSelectedText(Const Value: TColor);
        Procedure SetButtonSelectedBorder(Const Value: TColor);

        Procedure SetButtonDisabledTop(Const Value: TColor);
        Procedure SetButtonDisabledBottom(Const Value: TColor);
        Procedure SetButtonDisabledText(Const Value: TColor);
        Procedure SetButtonDisabledBorder(Const Value: TColor);

        Procedure SetTabLightEdge(Const Value: TColor);
        Procedure SetTabShadowEdge(Const Value: TColor);

        Procedure SetButtonLightEdge(Const Value: TColor);
        Procedure SetButtonShadowEdge(Const Value: TColor);

        Procedure SetFocusColor(Const Value: TColor);

    public
        {
          Creates the appearance object and stores its owner.

          The owner is used only for persistence ownership and design-time
          integration; visual invalidation is performed through OnChanged.
        }
        Constructor Create(AOwner: TPersistent);

        {
          Copies all appearance properties from another compatible object.
        }
        Procedure Assign(Source: TPersistent); override;

        {
          Starts a grouped update.

          While an update is active, individual property changes do not notify
          the owner immediately.
        }
        Procedure BeginUpdate;

        {
          Ends a grouped update and sends one notification when required.
        }
        Procedure EndUpdate;

        {
          Event fired when an appearance property changes.
        }
        Property OnChanged: TNoReflowTabBarObjectChangedEvent Read FOnChanged Write FOnChanged;

    published
        {
          Top gradient color of a normal tab.
        }
        Property TabNormalTop: TColor Read FTabNormalTop Write SetTabNormalTop default clBtnFace;

        {
          Bottom gradient color of a normal tab.
        }
        Property TabNormalBottom: TColor Read FTabNormalBottom Write SetTabNormalBottom default clBtnFace;

        {
          Text color of a normal tab.
        }
        Property TabNormalText: TColor Read FTabNormalText Write SetTabNormalText default clBtnText;

        {
          Border color of a normal tab.
        }
        Property TabNormalBorder: TColor Read FTabNormalBorder Write SetTabNormalBorder default clBtnShadow;

        {
          Top gradient color of a hot tab.
        }
        Property TabHotTop: TColor Read FTabHotTop Write SetTabHotTop default clHighlight;

        {
          Bottom gradient color of a hot tab.
        }
        Property TabHotBottom: TColor Read FTabHotBottom Write SetTabHotBottom default clHighlight;

        {
          Text color of a hot tab.
        }
        Property TabHotText: TColor Read FTabHotText Write SetTabHotText default clBtnText;

        {
          Border color of a hot tab.
        }
        Property TabHotBorder: TColor Read FTabHotBorder Write SetTabHotBorder default clActiveBorder;

        {
          Top gradient color of a selected tab.
        }
        Property TabSelectedTop: TColor Read FTabSelectedTop Write SetTabSelectedTop default clBtnHighlight;

        {
          Bottom gradient color of a selected tab.
        }
        Property TabSelectedBottom: TColor Read FTabSelectedBottom Write SetTabSelectedBottom default clBtnHighlight;

        {
          Text color of a selected tab.
        }
        Property TabSelectedText: TColor Read FTabSelectedText Write SetTabSelectedText default clHighlightText;

        {
          Border color of a selected tab.
        }
        Property TabSelectedBorder: TColor Read FTabSelectedBorder Write SetTabSelectedBorder default clActiveBorder;

        {
          Top gradient color of a pressed tab.

          By default, the pressed tab state reuses the hot appearance in order
          to preserve the historical rendering unless explicit colors are set.
        }
        Property TabPressedTop: TColor Read FTabPressedTop Write SetTabPressedTop default clHighlight;

        {
          Bottom gradient color of a pressed tab.
        }
        Property TabPressedBottom: TColor Read FTabPressedBottom Write SetTabPressedBottom default clHighlight;

        {
          Text color of a pressed tab.
        }
        Property TabPressedText: TColor Read FTabPressedText Write SetTabPressedText default clBtnText;

        {
          Border color of a pressed tab.
        }
        Property TabPressedBorder: TColor Read FTabPressedBorder Write SetTabPressedBorder default clActiveBorder;

        {
          Top gradient color of a disabled tab.
        }
        Property TabDisabledTop: TColor Read FTabDisabledTop Write SetTabDisabledTop default clBtnFace;

        {
          Bottom gradient color of a disabled tab.
        }
        Property TabDisabledBottom: TColor Read FTabDisabledBottom Write SetTabDisabledBottom default clBtnFace;

        {
          Text color of a disabled tab.
        }
        Property TabDisabledText: TColor Read FTabDisabledText Write SetTabDisabledText default clGrayText;

        {
          Border color of a disabled tab.
        }
        Property TabDisabledBorder: TColor Read FTabDisabledBorder Write SetTabDisabledBorder default clBtnShadow;

        {
          Light edge color optionally used by tab rendering.
        }
        Property TabLightEdge: TColor Read FTabLightEdge Write SetTabLightEdge default clBtnHighlight;

        {
          Shadow edge color optionally used by tab rendering.
        }
        Property TabShadowEdge: TColor Read FTabShadowEdge Write SetTabShadowEdge default clBtnShadow;

        {
          Top gradient color of a normal button.
        }
        Property ButtonNormalTop: TColor Read FButtonNormalTop Write SetButtonNormalTop default clBtnFace;

        {
          Bottom gradient color of a normal button.
        }
        Property ButtonNormalBottom: TColor Read FButtonNormalBottom Write SetButtonNormalBottom default clBtnFace;

        {
          Text color of a normal button.
        }
        Property ButtonNormalText: TColor Read FButtonNormalText Write SetButtonNormalText default clBtnText;

        {
          Border color of a normal button.
        }
        Property ButtonNormalBorder: TColor Read FButtonNormalBorder Write SetButtonNormalBorder default clBtnShadow;

        {
          Top gradient color of a hot button.
        }
        Property ButtonHotTop: TColor Read FButtonHotTop Write SetButtonHotTop default clHighlight;

        {
          Bottom gradient color of a hot button.
        }
        Property ButtonHotBottom: TColor Read FButtonHotBottom Write SetButtonHotBottom default clHighlight;

        {
          Text color of a hot button.
        }
        Property ButtonHotText: TColor Read FButtonHotText Write SetButtonHotText default clHighlightText;

        {
          Border color of a hot button.
        }
        Property ButtonHotBorder: TColor Read FButtonHotBorder Write SetButtonHotBorder default clActiveBorder;

        {
          Top gradient color of a pressed button.
        }
        Property ButtonPressedTop: TColor Read FButtonPressedTop Write SetButtonPressedTop default clBtnShadow;

        {
          Bottom gradient color of a pressed button.
        }
        Property ButtonPressedBottom: TColor Read FButtonPressedBottom Write SetButtonPressedBottom default clBtnShadow;

        {
          Text color of a pressed button.
        }
        Property ButtonPressedText: TColor Read FButtonPressedText Write SetButtonPressedText default clBtnText;

        {
          Border color of a pressed button.
        }
        Property ButtonPressedBorder: TColor Read FButtonPressedBorder Write SetButtonPressedBorder default clBtnShadow;

        {
          Top gradient color of a selected or checked button.
        }
        Property ButtonSelectedTop: TColor Read FButtonSelectedTop Write SetButtonSelectedTop default clBtnHighlight;

        {
          Bottom gradient color of a selected or checked button.
        }
        Property ButtonSelectedBottom: TColor Read FButtonSelectedBottom Write SetButtonSelectedBottom default clBtnHighlight;

        {
          Text color of a selected or checked button.
        }
        Property ButtonSelectedText: TColor Read FButtonSelectedText Write SetButtonSelectedText default clHighlightText;

        {
          Border color of a selected or checked button.
        }
        Property ButtonSelectedBorder: TColor Read FButtonSelectedBorder Write SetButtonSelectedBorder default clActiveBorder;

        {
          Top gradient color of a disabled button.
        }
        Property ButtonDisabledTop: TColor Read FButtonDisabledTop Write SetButtonDisabledTop default clBtnFace;

        {
          Bottom gradient color of a disabled button.
        }
        Property ButtonDisabledBottom: TColor Read FButtonDisabledBottom Write SetButtonDisabledBottom default clBtnFace;

        {
          Text color of a disabled button.
        }
        Property ButtonDisabledText: TColor Read FButtonDisabledText Write SetButtonDisabledText default clGrayText;

        {
          Border color of a disabled button.
        }
        Property ButtonDisabledBorder: TColor Read FButtonDisabledBorder Write SetButtonDisabledBorder default clBtnShadow;

        {
          Light edge color optionally used by button rendering.
        }
        Property ButtonLightEdge: TColor Read FButtonLightEdge Write SetButtonLightEdge default clBtnHighlight;

        {
          Shadow edge color optionally used by button rendering.
        }
        Property ButtonShadowEdge: TColor Read FButtonShadowEdge Write SetButtonShadowEdge default clBtnShadow;

        {
          Keyboard focus outline color.
        }
        Property FocusColor: TColor Read FFocusColor Write SetFocusColor default clHighlight;
    End;

    {
      Common layout settings shared by tabs and buttons.

      This class contains only parameters that make sense for both tab mode and
      button modes:
      - global margins;
      - spacing between logical zones;
      - spacing between rows or columns;
      - content spacing around text, signals and glyphs;
      - signal and glyph layout parameters;
      - optional length and thickness equalisation.

      Tab-specific shape settings are stored in TNoReflowTabBarLayoutTabs.
      Button-specific shape settings are stored in TNoReflowTabBarLayoutButtons.
    }
    TNoReflowTabBarLayout = Class(TPersistent)
    private
        FOwner:     TPersistent;
        FOnChanged: TNoReflowTabBarObjectChangedEvent;

        FSameLength:    Boolean;
        FSameThickness: Boolean;

        FZoneSpacing:    Integer;
        FMarginStart:    Integer;
        FMarginFirstRow: Integer;
        FMarginEnd:      Integer;
        FRowSpacing:     Integer;

        //Alignment of the full item block along the main layout axis.
        FFlowAlignment: TNoReflowTabBarFlowAlignment;

        FSignalSize:    Integer;
        FSignalSpacing: Integer;

        FTextSpaceBefore: Integer;
        FTextSpaceAfter:  Integer;
        FTextSpaceOver:   Integer;
        FTextSpaceUnder:  Integer;

        FGlyphSpacing:  Integer;
        FGlyphPosition: TNoReflowTabBarGlyphPosition;

        FUpdating: Integer;

        Procedure Changed;

        Procedure SetSameLength(Const Value: Boolean);
        Procedure SetSameThickness(Const Value: Boolean);

        Procedure SetZoneSpacing(Const Value: Integer);
        Procedure SetMarginStart(Const Value: Integer);
        Procedure SetMarginFirstRow(Const Value: Integer);
        Procedure SetMarginEnd(Const Value: Integer);
        Procedure SetFlowAlignment(Const Value: TNoReflowTabBarFlowAlignment);

        Procedure SetRowSpacing(Const Value: Integer);

        Procedure SetSignalSize(Const Value: Integer);
        Procedure SetSignalSpacing(Const Value: Integer);

        Procedure SetTextSpaceBefore(Const Value: Integer);
        Procedure SetTextSpaceAfter(Const Value: Integer);
        Procedure SetTextSpaceOver(Const Value: Integer);
        Procedure SetTextSpaceUnder(Const Value: Integer);

        Procedure SetGlyphSpacing(Const Value: Integer);
        Procedure SetGlyphPosition(Const Value: TNoReflowTabBarGlyphPosition);

    public
        {
          Creates the layout object and stores its owner.
        }
        Constructor Create(AOwner: TPersistent);

        {
          Copies all layout properties from another compatible object.
        }
        Procedure Assign(Source: TPersistent); override;

        {
          Starts a grouped update.
        }
        Procedure BeginUpdate;

        {
          Ends a grouped update and sends one notification when required.
        }
        Procedure EndUpdate;

        {
          Event fired when a layout property changes.
        }
        Property OnChanged: TNoReflowTabBarObjectChangedEvent Read FOnChanged Write FOnChanged;

    published
        {
          Forces all visible items to use the same natural content length.

          For a horizontal bar, this affects the natural width. For a vertical
          bar, this affects the natural height.
        }
        Property SameLength: Boolean Read FSameLength Write SetSameLength default False;

        {
          Forces all visible items to use the same natural thickness.

          For a horizontal bar, this affects the natural height. For a vertical
          bar, this affects the natural width.
        }
        Property SameThickness: Boolean Read FSameThickness Write SetSameThickness default False;

        {
          Spacing between the Start, Center and End logical zones.
        }
        Property ZoneSpacing: Integer Read FZoneSpacing Write SetZoneSpacing default 12;

        {
          Leading margin on the main layout axis.
        }
        Property MarginStart: Integer Read FMarginStart Write SetMarginStart default 0;

        {
          Start offset of the first row or column.
        }
        Property MarginFirstRow: Integer Read FMarginFirstRow Write SetMarginFirstRow default 6;

        {
          Trailing margin on the main layout axis.
        }
        Property MarginEnd: Integer Read FMarginEnd Write SetMarginEnd default 0;

        {
          Alignment of the full item block on the main layout axis.

          This property does not change the logical order of zones or items. It
          is applied after layout calculation to position the whole item block in
          the available space between MarginStart and MarginEnd.
        }
        Property FlowAlignment: TNoReflowTabBarFlowAlignment Read FFlowAlignment Write SetFlowAlignment default nrtfaStart;

        {
          Spacing between two rows or two columns.
        }
        Property RowSpacing: Integer Read FRowSpacing Write SetRowSpacing default 6;

        {
          Diameter of the signal drawn in an item.
        }
        Property SignalSize: Integer Read FSignalSize Write SetSignalSize default 16;

        {
          Spacing between the signal and the text.
        }
        Property SignalSpacing: Integer Read FSignalSpacing Write SetSignalSpacing default 8;

        {
          Space before the content on the main content axis.
        }
        Property TextSpaceBefore: Integer Read FTextSpaceBefore Write SetTextSpaceBefore default 12;

        {
          Space after the content on the main content axis.
        }
        Property TextSpaceAfter: Integer Read FTextSpaceAfter Write SetTextSpaceAfter default 12;

        {
          Space above the content.
        }
        Property TextSpaceOver: Integer Read FTextSpaceOver Write SetTextSpaceOver default 6;

        {
          Space below the content.
        }
        Property TextSpaceUnder: Integer Read FTextSpaceUnder Write SetTextSpaceUnder default 6;

        {
          Spacing between the glyph and the text.
        }
        Property GlyphSpacing: Integer Read FGlyphSpacing Write SetGlyphSpacing default 6;

        {
          Global glyph position relative to item text.
        }
        Property GlyphPosition: TNoReflowTabBarGlyphPosition Read FGlyphPosition Write SetGlyphPosition default nrgpLeft;
    End;

    {
      Layout settings specific to tab rendering.

      This class contains only options that describe tab-specific shape and
      behaviour:
      - overlap between consecutive tabs;
      - first and second slants;
      - first and second corner radii;
      - optional closing edge drawing.

      Common text, signal, glyph and margin settings remain in
      TNoReflowTabBarLayout.
    }
    TNoReflowTabBarLayoutTabs = Class(TPersistent)
    private
        FOwner:     TPersistent;
        FOnChanged: TNoReflowTabBarObjectChangedEvent;

        FTabOverlap: Integer;

        FShapeSlantFirst:   Integer;
        FShapeSlantSecond:  Integer;
        FShapeRadiusFirst:  Integer;
        FShapeRadiusSecond: Integer;

        FShowClosingEdge: Boolean;

        FUpdating: Integer;

        Procedure Changed;

        Procedure SetTabOverlap(Const Value: Integer);

        Procedure SetShapeSlantFirst(Const Value: Integer);
        Procedure SetShapeSlantSecond(Const Value: Integer);
        Procedure SetShapeRadiusFirst(Const Value: Integer);
        Procedure SetShapeRadiusSecond(Const Value: Integer);

        Procedure SetShowClosingEdge(Const Value: Boolean);

    public
        {
          Creates the tab-layout object and stores its owner.
        }
        Constructor Create(AOwner: TPersistent);

        {
          Copies tab-layout properties from another compatible object.
        }
        Procedure Assign(Source: TPersistent); override;

        {
          Starts a grouped update.
        }
        Procedure BeginUpdate;

        {
          Ends a grouped update and sends one notification when required.
        }
        Procedure EndUpdate;

        {
          Event fired when a tab-layout property changes.
        }
        Property OnChanged: TNoReflowTabBarObjectChangedEvent Read FOnChanged Write FOnChanged;

    published
        {
          Overlap between two consecutive tabs.

          Positive values make consecutive tabs overlap. Zero disables overlap.
        }
        Property TabOverlap: Integer Read FTabOverlap Write SetTabOverlap default 16;

        {
          Value of the first tab-shape slant.
        }
        Property ShapeSlantFirst: Integer Read FShapeSlantFirst Write SetShapeSlantFirst default 0;

        {
          Value of the second tab-shape slant.
        }
        Property ShapeSlantSecond: Integer Read FShapeSlantSecond Write SetShapeSlantSecond default 37;

        {
          Radius of the first rounded corner.
        }
        Property ShapeRadiusFirst: Integer Read FShapeRadiusFirst Write SetShapeRadiusFirst default 3;

        {
          Radius of the second rounded corner.
        }
        Property ShapeRadiusSecond: Integer Read FShapeRadiusSecond Write SetShapeRadiusSecond default 0;

        {
          Controls whether non-selected tabs draw a closed border on their
          contact edge.
        }
        Property ShowClosingEdge: Boolean Read FShowClosingEdge Write SetShowClosingEdge default False;
    End;

    {
      Layout settings specific to button rendering.

      This class contains only button-specific properties:
      - spacing between independent buttons;
      - optional forced dimensions;
      - optional minimum button length when the length is not forced;
      - corner radius;
      - border drawing;
      - visual pressed-content offset.

      Common text, signal, glyph and margin settings remain in
      TNoReflowTabBarLayout.
    }
    TNoReflowTabBarLayoutButtons = Class(TPersistent)
    private
        FOwner:     TPersistent;
        FOnChanged: TNoReflowTabBarObjectChangedEvent;

        FButtonSpacing:   Integer;
        FForcedLength:    Integer;
        FMinimumLength:   Integer;
        FForcedThickness: Integer;
        FCornerRadius:    Integer;
        FDrawBorder:      Boolean;
        FPressedOffset:   Integer;

        FUpdating: Integer;

        Procedure Changed;

        Procedure SetButtonSpacing(Const Value: Integer);
        Procedure SetForcedLength(Const Value: Integer);
        Procedure SetMinimumLength(Const Value: Integer);
        Procedure SetForcedThickness(Const Value: Integer);
        Procedure SetCornerRadius(Const Value: Integer);
        Procedure SetDrawBorder(Const Value: Boolean);
        Procedure SetPressedOffset(Const Value: Integer);

    public
        {
          Creates the button-layout object and stores its owner.
        }
        Constructor Create(AOwner: TPersistent);

        {
          Copies button-layout properties from another compatible object.
        }
        Procedure Assign(Source: TPersistent); override;

        {
          Starts a grouped update.
        }
        Procedure BeginUpdate;

        {
          Ends a grouped update and sends one notification when required.
        }
        Procedure EndUpdate;

        {
          Event fired when a button-layout property changes.
        }
        Property OnChanged: TNoReflowTabBarObjectChangedEvent Read FOnChanged Write FOnChanged;

    published
        {
          Spacing between two consecutive buttons.

          Unlike TabOverlap, this is a normal positive spacing between
          independent button shapes.
        }
        Property ButtonSpacing: Integer Read FButtonSpacing Write SetButtonSpacing default 6;

        {
          Forced button length in the item flow direction.

          This is a logical dimension, not necessarily the physical screen
          width. A value of 0 means that the natural length is computed from the
          item content.
        }
        Property ForcedLength: Integer Read FForcedLength Write SetForcedLength default 0;

        {
          Minimum logical button length in the item flow direction.

          This property is used only when ForcedLength is 0. The natural logical
          length is still computed from the item content, then raised to this minimum
          when necessary. A value of 0 disables the minimum constraint.

          Important:
          Length is not necessarily a physical X-axis width. For vertical bar
          orientations, the logical length may later be transformed to a physical
          Y-axis span by the canonical layout transformation pipeline.
        }
        Property MinimumLength: Integer Read FMinimumLength Write SetMinimumLength default 0;

        {
          Forced button thickness in the item cross direction.

          This is a logical dimension, not necessarily the physical screen
          height. A value of 0 means that the natural thickness is computed from
          the item content.
        }
        Property ForcedThickness: Integer Read FForcedThickness Write SetForcedThickness default 0;

        {
          Button corner radius.
        }
        Property CornerRadius: Integer Read FCornerRadius Write SetCornerRadius default 3;

        {
          Controls whether a border is drawn around buttons.
        }
        Property DrawBorder: Boolean Read FDrawBorder Write SetDrawBorder default True;

        {
          Visual content offset applied when a button is pressed.

          A value of 0 disables the offset.
        }
        Property PressedOffset: Integer Read FPressedOffset Write SetPressedOffset default 1;
    End;

implementation

//===============================================================================================================================
//TNoReflowTabBarAppearance
//===============================================================================================================================

//Construit l’objet de configuration visuelle.
//
//Cet objet n’est qu’un conteneur de propriétés :
//il stocke les couleurs à utiliser quand la barre fonctionne
//en mode custom (BarPaletteMode = nrtcmCustom).
//
//Le composant propriétaire est conservé dans FOwner afin de pouvoir
//conserver le rattachement logique au composant qui possède ce sous-objet.
//
//La notification réelle des changements ne passe plus directement
//par TNoReflowTabBar mais par le callback OnChanged.
Constructor TNoReflowTabBarAppearance.Create(AOwner: TPersistent);
Begin
    Inherited Create;
    FOwner := AOwner;
    FOnChanged := Nil;
    FUpdating := 0;

    //Valeurs par défaut du style "normal".
    //Cet état correspond à un onglet visible, actif,
    //non survolé et non sélectionné.
    FTabNormalTop := clBtnFace;
    FTabNormalBottom := clBtnFace;
    FTabNormalText := clBtnText;
    FTabNormalBorder := clBtnShadow;

    //Valeurs par défaut du style "hot".
    //Cet état est utilisé quand la souris survole un onglet.
    FTabHotTop := clHighlight;
    FTabHotBottom := clHighlight;
    FTabHotText := clBtnText;
    FTabHotBorder := clActiveBorder;

    //Valeurs par défaut du style "selected".
    //Cet état est utilisé pour l’onglet actuellement sélectionné.
    FTabSelectedTop := clBtnHighlight;
    FTabSelectedBottom := clBtnHighlight;
    FTabSelectedText := clHighlightText;
    FTabSelectedBorder := clActiveBorder;

    //Valeurs par défaut du style "pressed".
    //Par défaut, l’état pressé reprend l’aspect hot pour préserver
    //le comportement visuel antérieur lorsqu’aucune couleur dédiée
    //n’a été configurée dans l’inspecteur d’objets.
    FTabPressedTop := clHighlight;
    FTabPressedBottom := clHighlight;
    FTabPressedText := clBtnText;
    FTabPressedBorder := clActiveBorder;

    //Couleurs utilisées par le relief éventuel des onglets
    //dans les rendus maison.
    FTabLightEdge := clBtnHighlight;
    FTabShadowEdge := clBtnShadow;

    //Valeurs par défaut du style "disabled".
    //Cet état est utilisé pour un onglet visible mais désactivé.
    FTabDisabledTop := clBtnFace;
    FTabDisabledBottom := clBtnFace;
    FTabDisabledText := clGrayText;
    FTabDisabledBorder := clBtnShadow;

    //Valeurs par défaut du style bouton "normal".
    //Ces couleurs sont volontairement proches des boutons VCL standards,
    //afin que le futur mode bouton puisse être activé sans rupture visuelle.
    FButtonNormalTop := clBtnFace;
    FButtonNormalBottom := clBtnFace;
    FButtonNormalText := clBtnText;
    FButtonNormalBorder := clBtnShadow;

    //Valeurs par défaut du style bouton "hot".
    FButtonHotTop := clHighlight;
    FButtonHotBottom := clHighlight;
    FButtonHotText := clHighlightText;
    FButtonHotBorder := clActiveBorder;

    //Valeurs par défaut du style bouton "pressed".
    //L'inversion légère haut/bas sera affinée plus tard dans le rendu,
    //mais la palette expose déjà un état distinct.
    FButtonPressedTop := clBtnShadow;
    FButtonPressedBottom := clBtnShadow;
    FButtonPressedText := clBtnText;
    FButtonPressedBorder := clBtnShadow;

    //Valeurs par défaut du style bouton "selected" ou "checked".
    //Pour la première version, selected et checked utiliseront le même état visuel.
    FButtonSelectedTop := clBtnHighlight;
    FButtonSelectedBottom := clBtnHighlight;
    FButtonSelectedText := clHighlightText;
    FButtonSelectedBorder := clActiveBorder;

    //Valeurs par défaut du style bouton désactivé.
    FButtonDisabledTop := clBtnFace;
    FButtonDisabledBottom := clBtnFace;
    FButtonDisabledText := clGrayText;
    FButtonDisabledBorder := clBtnShadow;

    //Couleurs utilisées uniquement si le rendu bouton active un relief léger.
    FButtonLightEdge := clBtnHighlight;
    FButtonShadowEdge := clBtnShadow;

    //Couleur dédiée du focus clavier.
    FFocusColor := clHighlight;
End;

//Copie l’ensemble des propriétés depuis un autre TNoReflowTabBarAppearance.
//
//Cette méthode est appelée notamment quand on affecte BarAppearance
//depuis un autre composant ou un autre objet.
//
//Important :
//on copie directement les champs internes puis on appelle Changed une fois,
//ce qui évite de déclencher une invalidation pour chaque propriété.
Procedure TNoReflowTabBarAppearance.Assign(Source: TPersistent);
Var
    Src: TNoReflowTabBarAppearance;
Begin
    If Source Is TNoReflowTabBarAppearance Then Begin
        Src := TNoReflowTabBarAppearance(Source);

        //Copie des couleurs de l’état normal.
        FTabNormalTop := Src.TabNormalTop;
        FTabNormalBottom := Src.TabNormalBottom;
        FTabNormalText := Src.TabNormalText;
        FTabNormalBorder := Src.TabNormalBorder;

        //Copie des couleurs de l’état hot.
        FTabHotTop := Src.TabHotTop;
        FTabHotBottom := Src.TabHotBottom;
        FTabHotText := Src.TabHotText;
        FTabHotBorder := Src.TabHotBorder;

        //Copie des couleurs de l’état sélectionné.
        FTabSelectedTop := Src.TabSelectedTop;
        FTabSelectedBottom := Src.TabSelectedBottom;
        FTabSelectedText := Src.TabSelectedText;
        FTabSelectedBorder := Src.TabSelectedBorder;

        //Copie des couleurs de l’état pressé.
        FTabPressedTop := Src.TabPressedTop;
        FTabPressedBottom := Src.TabPressedBottom;
        FTabPressedText := Src.TabPressedText;
        FTabPressedBorder := Src.TabPressedBorder;

        //Copie des couleurs de relief des onglets.
        FTabLightEdge := Src.TabLightEdge;
        FTabShadowEdge := Src.TabShadowEdge;

        //Copie des couleurs de l’état désactivé.
        FTabDisabledTop := Src.TabDisabledTop;
        FTabDisabledBottom := Src.TabDisabledBottom;
        FTabDisabledText := Src.TabDisabledText;
        FTabDisabledBorder := Src.TabDisabledBorder;

        //Copie des couleurs de boutons à l’état normal.
        FButtonNormalTop := Src.ButtonNormalTop;
        FButtonNormalBottom := Src.ButtonNormalBottom;
        FButtonNormalText := Src.ButtonNormalText;
        FButtonNormalBorder := Src.ButtonNormalBorder;

        //Copie des couleurs de boutons à l’état hot.
        FButtonHotTop := Src.ButtonHotTop;
        FButtonHotBottom := Src.ButtonHotBottom;
        FButtonHotText := Src.ButtonHotText;
        FButtonHotBorder := Src.ButtonHotBorder;

        //Copie des couleurs de boutons à l’état pressé.
        FButtonPressedTop := Src.ButtonPressedTop;
        FButtonPressedBottom := Src.ButtonPressedBottom;
        FButtonPressedText := Src.ButtonPressedText;
        FButtonPressedBorder := Src.ButtonPressedBorder;

        //Copie des couleurs de boutons à l’état sélectionné/coché.
        FButtonSelectedTop := Src.ButtonSelectedTop;
        FButtonSelectedBottom := Src.ButtonSelectedBottom;
        FButtonSelectedText := Src.ButtonSelectedText;
        FButtonSelectedBorder := Src.ButtonSelectedBorder;

        //Copie des couleurs de boutons à l’état désactivé.
        FButtonDisabledTop := Src.ButtonDisabledTop;
        FButtonDisabledBottom := Src.ButtonDisabledBottom;
        FButtonDisabledText := Src.ButtonDisabledText;
        FButtonDisabledBorder := Src.ButtonDisabledBorder;

        //Copie des couleurs de relief et de focus.
        FButtonLightEdge := Src.ButtonLightEdge;
        FButtonShadowEdge := Src.ButtonShadowEdge;
        FFocusColor := Src.FocusColor;

        //Une seule notification finale suffit.
        Changed;
    End
    Else
        Inherited Assign(Source);
End;

//Entre en mode mise à jour groupée.
//
//Tant que FUpdating > 0, les changements de propriétés n’entraînent
//pas de notification immédiate vers la barre.
//
//Cela permet par exemple de modifier plusieurs couleurs de suite
//sans recalculer la palette ni redessiner le composant à chaque fois.
Procedure TNoReflowTabBarAppearance.BeginUpdate;
Begin
    Inc(FUpdating);
End;

//Sort du mode mise à jour groupée.
//
//Quand le compteur revient à zéro, on déclenche Changed pour
//propager les modifications accumulées.
Procedure TNoReflowTabBarAppearance.EndUpdate;
Begin
    If FUpdating > 0 Then
        Dec(FUpdating);

    //Quand toutes les mises à jour imbriquées sont terminées,
    //on notifie enfin le propriétaire.
    If FUpdating = 0 Then
        Changed;
End;

//Notifie le composant propriétaire qu’une propriété visuelle a changé.
//
//Cette méthode est le point central de propagation des modifications.
//Elle ne fait rien si :
//- on est au milieu d’un BeginUpdate / EndUpdate,
//- aucun callback de notification n’a été branché.
//
//La décision concrète de ce qu’il faut faire ensuite
//(Invalidate, InvalidateLayout, InvalidatePalette, etc.)
//est désormais laissée au composant principal via OnChanged.
Procedure TNoReflowTabBarAppearance.Changed;
Begin
    //Tant qu’on est en mise à jour groupée,
    //on ne déclenche aucune notification.
    If FUpdating > 0 Then
        Exit;

    If Assigned(FOnChanged) Then
        FOnChanged(Self);
End;

//Définit la couleur haute du dégradé de l’état normal.
//
//Cette couleur correspond à la teinte utilisée en haut
//de l’onglet quand il est dans son état normal.
Procedure TNoReflowTabBarAppearance.SetTabNormalTop(Const Value: TColor);
Begin
    If FTabNormalTop = Value Then
        Exit;

    FTabNormalTop := Value;
    Changed;
End;

//Définit la couleur basse du dégradé de l’état normal.
Procedure TNoReflowTabBarAppearance.SetTabNormalBottom(Const Value: TColor);
Begin
    If FTabNormalBottom = Value Then
        Exit;

    FTabNormalBottom := Value;
    Changed;
End;

//Définit la couleur du texte pour l’état normal.
Procedure TNoReflowTabBarAppearance.SetTabNormalText(Const Value: TColor);
Begin
    If FTabNormalText = Value Then
        Exit;

    FTabNormalText := Value;
    Changed;
End;

//Définit la couleur de bordure pour l’état normal.
Procedure TNoReflowTabBarAppearance.SetTabNormalBorder(Const Value: TColor);
Begin
    If FTabNormalBorder = Value Then
        Exit;

    FTabNormalBorder := Value;
    Changed;
End;

//Définit la couleur haute du dégradé de l’état hot.
Procedure TNoReflowTabBarAppearance.SetTabHotTop(Const Value: TColor);
Begin
    If FTabHotTop = Value Then
        Exit;

    FTabHotTop := Value;
    Changed;
End;

//Définit la couleur basse du dégradé de l’état hot.
Procedure TNoReflowTabBarAppearance.SetTabHotBottom(Const Value: TColor);
Begin
    If FTabHotBottom = Value Then
        Exit;

    FTabHotBottom := Value;
    Changed;
End;

//Définit la couleur du texte pour l’état hot.
Procedure TNoReflowTabBarAppearance.SetTabHotText(Const Value: TColor);
Begin
    If FTabHotText = Value Then
        Exit;

    FTabHotText := Value;
    Changed;
End;

//Définit la couleur de bordure pour l’état hot.
Procedure TNoReflowTabBarAppearance.SetTabHotBorder(Const Value: TColor);
Begin
    If FTabHotBorder = Value Then
        Exit;

    FTabHotBorder := Value;
    Changed;
End;

//Définit la couleur haute du dégradé de l’état sélectionné.
Procedure TNoReflowTabBarAppearance.SetTabSelectedTop(Const Value: TColor);
Begin
    If FTabSelectedTop = Value Then
        Exit;

    FTabSelectedTop := Value;
    Changed;
End;

//Définit la couleur basse du dégradé de l’état sélectionné.
Procedure TNoReflowTabBarAppearance.SetTabSelectedBottom(Const Value: TColor);
Begin
    If FTabSelectedBottom = Value Then
        Exit;

    FTabSelectedBottom := Value;
    Changed;
End;

//Définit la couleur du texte pour l’état sélectionné.
Procedure TNoReflowTabBarAppearance.SetTabSelectedText(Const Value: TColor);
Begin
    If FTabSelectedText = Value Then
        Exit;

    FTabSelectedText := Value;
    Changed;
End;

//Définit la couleur de bordure pour l’état sélectionné.
Procedure TNoReflowTabBarAppearance.SetTabSelectedBorder(Const Value: TColor);
Begin
    If FTabSelectedBorder = Value Then
        Exit;

    FTabSelectedBorder := Value;
    Changed;
End;

//Définit la couleur haute du dégradé de l’état pressé.
Procedure TNoReflowTabBarAppearance.SetTabPressedTop(Const Value: TColor);
Begin
    If FTabPressedTop = Value Then
        Exit;

    FTabPressedTop := Value;
    Changed;
End;

//Définit la couleur basse du dégradé de l’état pressé.
Procedure TNoReflowTabBarAppearance.SetTabPressedBottom(Const Value: TColor);
Begin
    If FTabPressedBottom = Value Then
        Exit;

    FTabPressedBottom := Value;
    Changed;
End;

//Définit la couleur du texte pour l’état pressé.
Procedure TNoReflowTabBarAppearance.SetTabPressedText(Const Value: TColor);
Begin
    If FTabPressedText = Value Then
        Exit;

    FTabPressedText := Value;
    Changed;
End;

//Définit la couleur de bordure pour l’état pressé.
Procedure TNoReflowTabBarAppearance.SetTabPressedBorder(Const Value: TColor);
Begin
    If FTabPressedBorder = Value Then
        Exit;

    FTabPressedBorder := Value;
    Changed;
End;

//Définit la couleur haute du dégradé de l’état désactivé.
Procedure TNoReflowTabBarAppearance.SetTabDisabledTop(Const Value: TColor);
Begin
    If FTabDisabledTop = Value Then
        Exit;

    FTabDisabledTop := Value;
    Changed;
End;

//Définit la couleur basse du dégradé de l’état désactivé.
Procedure TNoReflowTabBarAppearance.SetTabDisabledBottom(Const Value: TColor);
Begin
    If FTabDisabledBottom = Value Then
        Exit;

    FTabDisabledBottom := Value;
    Changed;
End;

//Définit la couleur du texte pour l’état désactivé.
Procedure TNoReflowTabBarAppearance.SetTabDisabledText(Const Value: TColor);
Begin
    If FTabDisabledText = Value Then
        Exit;

    FTabDisabledText := Value;
    Changed;
End;

//Définit la couleur de bordure pour l’état désactivé.
Procedure TNoReflowTabBarAppearance.SetTabDisabledBorder(Const Value: TColor);
Begin
    If FTabDisabledBorder = Value Then
        Exit;

    FTabDisabledBorder := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonNormalTop(Const Value: TColor);
Begin
    If FButtonNormalTop = Value Then
        Exit;

    FButtonNormalTop := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonNormalBottom(Const Value: TColor);
Begin
    If FButtonNormalBottom = Value Then
        Exit;

    FButtonNormalBottom := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonNormalText(Const Value: TColor);
Begin
    If FButtonNormalText = Value Then
        Exit;

    FButtonNormalText := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonNormalBorder(Const Value: TColor);
Begin
    If FButtonNormalBorder = Value Then
        Exit;

    FButtonNormalBorder := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonHotTop(Const Value: TColor);
Begin
    If FButtonHotTop = Value Then
        Exit;

    FButtonHotTop := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonHotBottom(Const Value: TColor);
Begin
    If FButtonHotBottom = Value Then
        Exit;

    FButtonHotBottom := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonHotText(Const Value: TColor);
Begin
    If FButtonHotText = Value Then
        Exit;

    FButtonHotText := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonHotBorder(Const Value: TColor);
Begin
    If FButtonHotBorder = Value Then
        Exit;

    FButtonHotBorder := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonPressedTop(Const Value: TColor);
Begin
    If FButtonPressedTop = Value Then
        Exit;

    FButtonPressedTop := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonPressedBottom(Const Value: TColor);
Begin
    If FButtonPressedBottom = Value Then
        Exit;

    FButtonPressedBottom := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonPressedText(Const Value: TColor);
Begin
    If FButtonPressedText = Value Then
        Exit;

    FButtonPressedText := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonPressedBorder(Const Value: TColor);
Begin
    If FButtonPressedBorder = Value Then
        Exit;

    FButtonPressedBorder := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonSelectedTop(Const Value: TColor);
Begin
    If FButtonSelectedTop = Value Then
        Exit;

    FButtonSelectedTop := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonSelectedBottom(Const Value: TColor);
Begin
    If FButtonSelectedBottom = Value Then
        Exit;

    FButtonSelectedBottom := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonSelectedText(Const Value: TColor);
Begin
    If FButtonSelectedText = Value Then
        Exit;

    FButtonSelectedText := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonSelectedBorder(Const Value: TColor);
Begin
    If FButtonSelectedBorder = Value Then
        Exit;

    FButtonSelectedBorder := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonDisabledTop(Const Value: TColor);
Begin
    If FButtonDisabledTop = Value Then
        Exit;

    FButtonDisabledTop := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonDisabledBottom(Const Value: TColor);
Begin
    If FButtonDisabledBottom = Value Then
        Exit;

    FButtonDisabledBottom := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonDisabledText(Const Value: TColor);
Begin
    If FButtonDisabledText = Value Then
        Exit;

    FButtonDisabledText := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonDisabledBorder(Const Value: TColor);
Begin
    If FButtonDisabledBorder = Value Then
        Exit;

    FButtonDisabledBorder := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetTabLightEdge(Const Value: TColor);
Begin
    If FTabLightEdge = Value Then
        Exit;

    FTabLightEdge := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetTabShadowEdge(Const Value: TColor);
Begin
    If FTabShadowEdge = Value Then
        Exit;

    FTabShadowEdge := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonLightEdge(Const Value: TColor);
Begin
    If FButtonLightEdge = Value Then
        Exit;

    FButtonLightEdge := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetButtonShadowEdge(Const Value: TColor);
Begin
    If FButtonShadowEdge = Value Then
        Exit;

    FButtonShadowEdge := Value;
    Changed;
End;

Procedure TNoReflowTabBarAppearance.SetFocusColor(Const Value: TColor);
Begin
    If FFocusColor = Value Then
        Exit;

    FFocusColor := Value;
    Changed;
End;

//===============================================================================================================================
//TNoReflowTabBarLayout
//===============================================================================================================================

Constructor TNoReflowTabBarLayout.Create(AOwner: TPersistent);
Begin
    Inherited Create;

    FOwner := AOwner;
    FOnChanged := Nil;
    FUpdating := 0;

    FSameLength := False;
    FSameThickness := False;

    FZoneSpacing := 12;
    FMarginStart := 0;
    FMarginFirstRow := 6;
    FMarginEnd := 0;
    FFlowAlignment := nrtfaStart;
    FRowSpacing := 6;

    FSignalSize := 16;
    FSignalSpacing := 8;

    FTextSpaceBefore := 12;
    FTextSpaceAfter := 12;
    FTextSpaceOver := 6;
    FTextSpaceUnder := 6;

    FGlyphSpacing := 6;
    FGlyphPosition := nrgpLeft;
End;

Procedure TNoReflowTabBarLayout.Assign(Source: TPersistent);
Var
    Src: TNoReflowTabBarLayout;
Begin
    If Source Is TNoReflowTabBarLayout Then Begin
        Src := TNoReflowTabBarLayout(Source);

        FSameLength := Src.SameLength;
        FSameThickness := Src.SameThickness;

        FZoneSpacing := Src.ZoneSpacing;
        FMarginStart := Src.MarginStart;
        FMarginFirstRow := Src.MarginFirstRow;
        FMarginEnd := Src.MarginEnd;
        FFlowAlignment := Src.FlowAlignment;
        FRowSpacing := Src.RowSpacing;

        FSignalSize := Src.SignalSize;
        FSignalSpacing := Src.SignalSpacing;

        FTextSpaceBefore := Src.TextSpaceBefore;
        FTextSpaceAfter := Src.TextSpaceAfter;
        FTextSpaceOver := Src.TextSpaceOver;
        FTextSpaceUnder := Src.TextSpaceUnder;

        FGlyphSpacing := Src.GlyphSpacing;
        FGlyphPosition := Src.GlyphPosition;

        Changed;
    End
    Else
        Inherited Assign(Source);
End;

Procedure TNoReflowTabBarLayout.BeginUpdate;
Begin
    Inc(FUpdating);
End;

Procedure TNoReflowTabBarLayout.EndUpdate;
Begin
    If FUpdating > 0 Then
        Dec(FUpdating);

    If FUpdating = 0 Then
        Changed;
End;

Procedure TNoReflowTabBarLayout.Changed;
Begin
    If FUpdating > 0 Then
        Exit;

    If Assigned(FOnChanged) Then
        FOnChanged(Self);
End;

Procedure TNoReflowTabBarLayout.SetSameLength(Const Value: Boolean);
Begin
    If FSameLength = Value Then
        Exit;

    FSameLength := Value;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetSameThickness(Const Value: Boolean);
Begin
    If FSameThickness = Value Then
        Exit;

    FSameThickness := Value;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetZoneSpacing(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FZoneSpacing = NewValue Then
        Exit;

    FZoneSpacing := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetMarginStart(Const Value: Integer);
Begin
    If FMarginStart = Value Then
        Exit;

    FMarginStart := Value;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetMarginFirstRow(Const Value: Integer);
Begin
    If FMarginFirstRow = Value Then
        Exit;

    FMarginFirstRow := Value;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetMarginEnd(Const Value: Integer);
Begin
    If FMarginEnd = Value Then
        Exit;

    FMarginEnd := Value;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetFlowAlignment(Const Value: TNoReflowTabBarFlowAlignment);
Begin
    //-------------------------------------------------------------------------
    //Change l'alignement global du flux dans l'axe principal.
    //
    //Cette propriété ne force aucun recalcul de métriques internes des items :
    //elle modifie seulement la position de départ du bloc complet après calcul
    //de sa largeur logique.
    //
    //On déclenche néanmoins Changed, car le layout final doit être reconstruit.
    //-------------------------------------------------------------------------

    If FFlowAlignment = Value Then
        Exit;

    FFlowAlignment := Value;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetRowSpacing(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FRowSpacing = NewValue Then
        Exit;

    FRowSpacing := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetSignalSize(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FSignalSize = NewValue Then
        Exit;

    FSignalSize := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetSignalSpacing(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FSignalSpacing = NewValue Then
        Exit;

    FSignalSpacing := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetTextSpaceBefore(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FTextSpaceBefore = NewValue Then
        Exit;

    FTextSpaceBefore := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetTextSpaceAfter(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FTextSpaceAfter = NewValue Then
        Exit;

    FTextSpaceAfter := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetTextSpaceOver(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FTextSpaceOver = NewValue Then
        Exit;

    FTextSpaceOver := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetTextSpaceUnder(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FTextSpaceUnder = NewValue Then
        Exit;

    FTextSpaceUnder := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetGlyphSpacing(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FGlyphSpacing = NewValue Then
        Exit;

    FGlyphSpacing := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayout.SetGlyphPosition(Const Value: TNoReflowTabBarGlyphPosition);
Begin
    If FGlyphPosition = Value Then
        Exit;

    FGlyphPosition := Value;
    Changed;
End;

//===============================================================================================================================
//TNoReflowTabBarLayoutTabs
//===============================================================================================================================

Constructor TNoReflowTabBarLayoutTabs.Create(AOwner: TPersistent);
Begin
    Inherited Create;

    FOwner := AOwner;
    FOnChanged := Nil;
    FUpdating := 0;

    FTabOverlap := 16;

    FShapeSlantFirst := 0;
    FShapeSlantSecond := 37;
    FShapeRadiusFirst := 3;
    FShapeRadiusSecond := 0;

    FShowClosingEdge := False;
End;

Procedure TNoReflowTabBarLayoutTabs.Assign(Source: TPersistent);
Var
    Src: TNoReflowTabBarLayoutTabs;
Begin
    If Source Is TNoReflowTabBarLayoutTabs Then Begin
        Src := TNoReflowTabBarLayoutTabs(Source);

        FTabOverlap := Src.TabOverlap;

        FShapeSlantFirst := Src.ShapeSlantFirst;
        FShapeSlantSecond := Src.ShapeSlantSecond;
        FShapeRadiusFirst := Src.ShapeRadiusFirst;
        FShapeRadiusSecond := Src.ShapeRadiusSecond;

        FShowClosingEdge := Src.ShowClosingEdge;

        Changed;
    End
    Else
        Inherited Assign(Source);
End;

Procedure TNoReflowTabBarLayoutTabs.BeginUpdate;
Begin
    Inc(FUpdating);
End;

Procedure TNoReflowTabBarLayoutTabs.EndUpdate;
Begin
    If FUpdating > 0 Then
        Dec(FUpdating);

    If FUpdating = 0 Then
        Changed;
End;

Procedure TNoReflowTabBarLayoutTabs.Changed;
Begin
    If FUpdating > 0 Then
        Exit;

    If Assigned(FOnChanged) Then
        FOnChanged(Self);
End;

Procedure TNoReflowTabBarLayoutTabs.SetTabOverlap(Const Value: Integer);
Begin
    If FTabOverlap = Value Then
        Exit;

    FTabOverlap := Value;
    Changed;
End;

Procedure TNoReflowTabBarLayoutTabs.SetShapeSlantFirst(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FShapeSlantFirst = NewValue Then
        Exit;

    FShapeSlantFirst := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayoutTabs.SetShapeSlantSecond(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FShapeSlantSecond = NewValue Then
        Exit;

    FShapeSlantSecond := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayoutTabs.SetShapeRadiusFirst(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FShapeRadiusFirst = NewValue Then
        Exit;

    FShapeRadiusFirst := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayoutTabs.SetShapeRadiusSecond(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FShapeRadiusSecond = NewValue Then
        Exit;

    FShapeRadiusSecond := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayoutTabs.SetShowClosingEdge(Const Value: Boolean);
Begin
    If FShowClosingEdge = Value Then
        Exit;

    FShowClosingEdge := Value;
    Changed;
End;

//===============================================================================================================================
//TNoReflowTabBarLayoutButtons
//===============================================================================================================================

Constructor TNoReflowTabBarLayoutButtons.Create(AOwner: TPersistent);
Begin
    Inherited Create;

    FOwner := AOwner;
    FOnChanged := Nil;
    FUpdating := 0;

    FButtonSpacing := 6;
    FForcedLength := 0;
    FMinimumLength := 0;
    FForcedThickness := 0;
    FCornerRadius := 3;

    FDrawBorder := True;
    FPressedOffset := 1;
End;

Procedure TNoReflowTabBarLayoutButtons.Assign(Source: TPersistent);
Var
    Src: TNoReflowTabBarLayoutButtons;
Begin
    If Source Is TNoReflowTabBarLayoutButtons Then Begin
        Src := TNoReflowTabBarLayoutButtons(Source);

        FButtonSpacing := Src.ButtonSpacing;
        FForcedLength := Src.ForcedLength;
        FMinimumLength := Src.MinimumLength;
        FForcedThickness := Src.ForcedThickness;
        FCornerRadius := Src.CornerRadius;

        FDrawBorder := Src.DrawBorder;
        FPressedOffset := Src.PressedOffset;

        Changed;
    End
    Else
        Inherited Assign(Source);
End;

Procedure TNoReflowTabBarLayoutButtons.BeginUpdate;
Begin
    Inc(FUpdating);
End;

Procedure TNoReflowTabBarLayoutButtons.EndUpdate;
Begin
    If FUpdating > 0 Then
        Dec(FUpdating);

    If FUpdating = 0 Then
        Changed;
End;

Procedure TNoReflowTabBarLayoutButtons.Changed;
Begin
    If FUpdating > 0 Then
        Exit;

    If Assigned(FOnChanged) Then
        FOnChanged(Self);
End;

Procedure TNoReflowTabBarLayoutButtons.SetButtonSpacing(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FButtonSpacing = NewValue Then
        Exit;

    FButtonSpacing := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayoutButtons.SetForcedLength(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FForcedLength = NewValue Then
        Exit;

    FForcedLength := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayoutButtons.SetMinimumLength(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    //--------------------------------------------------------------------------
    //Normalise la longueur minimale des boutons.
    //
    //La valeur reste indépendante de ForcedLength :
    //- ForcedLength > 0 impose toujours une longueur fixe ;
    //- ForcedLength = 0 conserve la longueur naturelle calculée depuis le
    //contenu, puis applique MinimumLength comme garde-fou inférieur.
    //--------------------------------------------------------------------------

    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FMinimumLength = NewValue Then
        Exit;

    FMinimumLength := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayoutButtons.SetForcedThickness(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FForcedThickness = NewValue Then
        Exit;

    FForcedThickness := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayoutButtons.SetCornerRadius(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FCornerRadius = NewValue Then
        Exit;

    FCornerRadius := NewValue;
    Changed;
End;

Procedure TNoReflowTabBarLayoutButtons.SetDrawBorder(Const Value: Boolean);
Begin
    If FDrawBorder = Value Then
        Exit;

    FDrawBorder := Value;
    Changed;
End;

Procedure TNoReflowTabBarLayoutButtons.SetPressedOffset(Const Value: Integer);
Var
    NewValue: Integer;
Begin
    NewValue := Value;

    If NewValue < 0 Then
        NewValue := 0;

    If FPressedOffset = NewValue Then
        Exit;

    FPressedOffset := NewValue;
    Changed;
End;

end.
