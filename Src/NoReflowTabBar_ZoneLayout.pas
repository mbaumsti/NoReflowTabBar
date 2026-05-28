Unit NoReflowTabBar_ZoneLayout;

{
  NoReflowTabBar_ZoneLayout.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Canonical zone layout engine for the NoReflowTabBar VCL component.

  Repository:
  https://github.com/mbaumsti/NoReflowTabBar

  License:
  See LICENSE file.

  ------------------------------------------------------------------------------

  Moteur de layout canonique par zones du composant NoReflowTabBar.

  Cette unité fournit :
  - les structures de layout par zones ;
  - le moteur de construction du layout canonique ;
  - les conversions entre repère canonique et repère réel ;
  - les calculs de taille utilisés par les orientations Top / Bottom /
  Left / Right.

  Rôle de cette unité :
  - isoler la logique de placement des zones Start / Center / End ;
  - conserver un repère canonique unique, indépendant de l'orientation finale ;
  - projeter les positions calculées vers la géométrie réelle du contrôle ;
  - éviter de dupliquer les algorithmes de layout pour chaque orientation.

  Remarques :
  - cette unité ne dessine rien directement ;
  - les transformations géométriques centralisées ici sont utilisées par le
  rendu, le hit-test et le drag & drop ;
  - toute modification de convention canonique doit être considérée avec
  prudence, car elle impacte l'ensemble du pipeline visuel.

  GARDE-FOU MAJEUR : NE PAS RECREER UN LAYOUT VERTICAL SPECIFIQUE

  Le moteur doit rester fonde sur le principe :

  - calcul dans un repere canonique horizontal TOP ;
  - transformation finale vers Top / Bottom / Left / Right.

  Les entrees verticales BuildVerticalZoneLayout et BuildVerticalSequentialLayout
  n'ont pas le droit de placer directement les items en coordonnees finales.
  Elles doivent seulement fournir au moteur canonique des dimensions transposees
  puis laisser TransformAllCanonicalRectsToActual effectuer la projection finale.

  Toute correction introduite directement dans le repere Left / Right risque de
  casser le rendu, le hit-test, les marqueurs de drag et les zones.
}

Interface

Uses
    System.Types,
    System.Classes,
    System.SysUtils,
    System.Math,
    System.Generics.Collections,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_RenderTypes,
    NoReflowTabBar_Items,
    NoReflowTabBar_AppearanceAndLayout;

Type
    //===============================================================================================================================
    //NoReflowTabBar_ZoneLayout
    //
    //Moteur de layout par zones pour TNoReflowTabBar.
    //
    //Réécriture sur repère canonique unique :
    //- tout le calcul interne est fait comme si la barre était HORIZONTALE et en position TOP
    //- les items sont donc toujours posés de gauche à droite
    //- la répartition interne se fait sur des "columns", terme volontairement neutre
    //par rapport à l'orientation finale de la barre
    //- la projection vers Bottom / Left / Right est faite à la toute fin
    //
    //Conséquences :
    //- le moteur métier de compaction des zones ne dépend plus de la géométrie finale
    //- les notions Width / Height, X / Y, Column sont de nouveau lisibles
    //- la complexité orientation / symétrie / rotation est isolée
    //
    //Principe retenu :
    //- on part toujours d'un état zéro : chaque zone sur une seule "column"
    //- la cible est toujours la largeur disponible dans le repère canonique
    //- on compacte d'abord la zone centrale, puis la zone de fin, puis la zone de début
    //- chaque zone est remplie séquentiellement, sans permutation d'items
    //- on impose d'abord une largeur mini esthétique au centre
    //- si cela ne suffit pas, on relâche cette contrainte et on autorise le centre
    //à descendre jusqu'à un item par column
    //===============================================================================================================================

    TNoReflowTabBarZoneColumnAlign = (nrtzcaStart, nrtzcaCenter, nrtzcaEnd);
    TNoReflowTabBarZoneFlowOrientation = (nrtzfoHorizontal, nrtzfoVertical);

    TNoReflowTabBarZoneColumnAssignment = Array Of Integer;

    TNoReflowTabBarZoneState = Record
        ColumnAssignments: TNoReflowTabBarZoneColumnAssignment;
        ColumnCount: Integer;
        UsedWidth: Integer;
        UsedHeight: Integer;
    End;

    TNoReflowTabBarSingleZoneLayoutInfo = Record
        HasZone: Boolean;
        OuterCanonicalRect: TRect;
        FirstRowCanonicalTop: Integer;
        Procedure Init;
    End;

    TNoReflowTabBarZoneLayoutInfo = Record
        StartZone: TNoReflowTabBarSingleZoneLayoutInfo;
        CenterZone: TNoReflowTabBarSingleZoneLayoutInfo;
        EndZone: TNoReflowTabBarSingleZoneLayoutInfo;
        Procedure Init;
    End;

    TNoReflowTabBarZoneLayoutItem = Class
    private
        FRenderIndex: Integer;
        FItem:        TNoReflowTabBarItem;
        FPinZone:     TNoReflowTabBarPinZone;
        FWidth:       Integer;
        FHeight:      Integer;
        FColumnIndex: Integer;
    public
        Constructor Create(
            ARenderIndex: Integer;
            AItem: TNoReflowTabBarItem;
            APinZone: TNoReflowTabBarPinZone;
            AWidth: Integer;
            AHeight: Integer);

        Property RenderIndex: Integer Read FRenderIndex;
        Property Item: TNoReflowTabBarItem Read FItem;
        Property PinZone: TNoReflowTabBarPinZone Read FPinZone;
        Property Width: Integer Read FWidth Write FWidth;
        Property Height: Integer Read FHeight Write FHeight;
        Property ColumnIndex: Integer Read FColumnIndex Write FColumnIndex;
    End;

    TNoReflowTabBarZoneLayoutZone = Class
    private
        FPinZone: TNoReflowTabBarPinZone;

        FItems: TObjectList<TNoReflowTabBarZoneLayoutItem>;

        Function GetCount: Integer;
        Function GetItem(AAbsoluteItemIndex: Integer): TNoReflowTabBarZoneLayoutItem;

        Function GetMaxColumnIndexForState(Const AState: TNoReflowTabBarZoneState): Integer;
        Function GetColumnWidthForState(
            Const AState: TNoReflowTabBarZoneState;
            AColumnIndex: Integer;
            ATabOverlap: Integer): Integer;
        Function GetColumnHeightForState(
            Const AState: TNoReflowTabBarZoneState;
            AColumnIndex: Integer): Integer;

        Function GetMonoColumnWidth(ATabOverlap: Integer): Integer;
        Function GetMaxItemWidth: Integer;

        Procedure CopyState(
            Const ASource: TNoReflowTabBarZoneState;
            Var ADest: TNoReflowTabBarZoneState);
    public
        Constructor Create(APinZone: TNoReflowTabBarPinZone);
        Destructor Destroy; override;

        Procedure Clear;
        Procedure AddItem(AItem: TNoReflowTabBarZoneLayoutItem);

        Function HasVisibleContent: Boolean;
        Function GetDefaultColumnAlign: TNoReflowTabBarZoneColumnAlign;

        Procedure BuildInitialZoneState(
            Out AState: TNoReflowTabBarZoneState;
            ATabOverlap: Integer;
            ARowSpacing: Integer);
        Procedure RecalcZoneStateMetrics(
            Var AState: TNoReflowTabBarZoneState;
            ATabOverlap: Integer;
            ARowSpacing: Integer);

        Function BuildSequentialStateForTargetWidth(
            ATargetWidth: Integer;
            ATabOverlap: Integer;
            ARowSpacing: Integer;
            Out AState: TNoReflowTabBarZoneState): Boolean;

        Function GetAppliedZoneWidth(ATabOverlap: Integer): Integer;
        Function GetAppliedZoneHeight(ARowSpacing: Integer): Integer;
        Function GetAppliedMaxColumnIndex: Integer;

        Procedure ApplyZoneState(Const AState: TNoReflowTabBarZoneState);

        Property PinZone: TNoReflowTabBarPinZone Read FPinZone;

        Property Count: Integer Read GetCount;
        Property Items[AIndex: Integer]: TNoReflowTabBarZoneLayoutItem Read GetItem;
    End;

    TNoReflowTabBarZoneLayoutGrid = Class
    private
        FStartZone:   TNoReflowTabBarZoneLayoutZone;
        FCenterZone:  TNoReflowTabBarZoneLayoutZone;
        FEndZone:     TNoReflowTabBarZoneLayoutZone;
        FZoneSpacing: Integer;

        //Ordre logique utilisé par la grille pour :
        //- déterminer l'ordre visuel des zones ;
        //- déterminer l'ordre de priorité de compactage.
        //
        //Les zones conservent leur identité réelle Start / Center / End.
        //On ne remappe donc jamais une zone vers une autre.
        FFlowOrder: TNoReflowTabBarFlowOrder;

        FStartState:  TNoReflowTabBarZoneState;
        FCenterState: TNoReflowTabBarZoneState;
        FEndState:    TNoReflowTabBarZoneState;

        Function GetVisibleZoneCount: Integer;
        Function GetZoneByPinZone(APinZone: TNoReflowTabBarPinZone): TNoReflowTabBarZoneLayoutZone;

        Function HasStart: Boolean;
        Function HasCenter: Boolean;
        Function HasEnd: Boolean;

        Function GetSpacingCount: Integer;
        Function GetGlobalWidth: Integer;

        Procedure InitZoneStates(
            ATabOverlap: Integer;
            ARowSpacing: Integer);
        Procedure ApplyStatesToZones;

        Function GetLeadingZone: TNoReflowTabBarZoneLayoutZone;
        Function GetTrailingZone: TNoReflowTabBarZoneLayoutZone;
    public
        Constructor Create;
        Destructor Destroy; override;

        Procedure Clear;

        Function WrapToFit(
            AAvailableWidth: Integer;
            AItemOverlap: Integer;
            ARowSpacing: Integer): Boolean;

        Function TotalWidth(ATabOverlap: Integer): Integer;
        Function TotalHeight(ARowSpacing: Integer): Integer;

        Property StartZone: TNoReflowTabBarZoneLayoutZone Read FStartZone;
        Property CenterZone: TNoReflowTabBarZoneLayoutZone Read FCenterZone;
        Property EndZone: TNoReflowTabBarZoneLayoutZone Read FEndZone;

        Property ZoneSpacing: Integer Read FZoneSpacing Write FZoneSpacing;
        Property VisibleZoneCount: Integer Read GetVisibleZoneCount;
        Property ZoneByPinZone[APinZone: TNoReflowTabBarPinZone]: TNoReflowTabBarZoneLayoutZone Read GetZoneByPinZone;

        Property FlowOrder: TNoReflowTabBarFlowOrder Read FFlowOrder Write FFlowOrder;
    End;


    TNoReflowTabBarItemContentElementSet = Set Of (nrtcesText, nrtcesSignal, nrtcesGlyph);

    TNoReflowTabBarItemContentLayoutInput = Record
        //---------------------------------------------------------------------
        //Input contract for the item content layout engine.
        //
        //All values are expressed in the local item coordinate system, before
        //the item itself is positioned in the bar.
        //
        //The engine deliberately receives only resolved values:
        //- final item size;
        //- effective text orientation;
        //- measured text size;
        //- resolved glyph availability and size;
        //- resolved signal availability and size;
        //- margins, spacings, slant pads and shape insets.
        //
        //This keeps the engine independent from TNoReflowTabBarItem,
        //TNoReflowTabBarLayout and rendering details. It can therefore be
        //debugged as a pure geometry service.
        //---------------------------------------------------------------------

        //Final local size of the item that will contain the content.
        ItemWidth: Integer;
        ItemHeight: Integer;

        //Item/bar geometry context used to derive the useful inner rectangle.
        TabPosition: TNoReflowTabBarPosition;
        TextOrientation: TNoReflowTabBarTextOrientation;

        //Measured text size using the font selected by RenderSupport.
        TextWidth: Integer;
        TextHeight: Integer;

        //Resolved signal state. HasSignal=False means that the signal must not
        //participate in any candidate.
        HasSignal: Boolean;
        SignalDiameter: Integer;
        SignalPosition: TNoReflowTabBarSignalPosition;

        //Resolved glyph state. HasGlyph=False means that the glyph must not
        //participate in any candidate.
        HasGlyph: Boolean;
        GlyphWidth: Integer;
        GlyphHeight: Integer;
        GlyphPosition: TNoReflowTabBarGlyphPosition;

        //Content margins and element spacings. These are applied while building
        //the useful inner rectangle and composing candidates.
        TextSpaceBefore: Integer;
        TextSpaceAfter: Integer;
        TextSpaceOver: Integer;
        TextSpaceUnder: Integer;
        SignalSpacing: Integer;
        GlyphSpacing: Integer;

        //Slant pads generated by tab geometry. They are only non-zero for tab
        //shapes, but the content engine does not need to know where they came
        //from.
        SlantPadFirst: Integer;
        SlantPadSecond: Integer;

        //Shape insets generated by the item outline. They are part of the
        //useful inner rectangle and must be applied before composition.
        LeftInset: Integer;
        TopInset: Integer;
        RightInset: Integer;
        BottomInset: Integer;
    End;

    TNoReflowTabBarItemContentLayoutResult = Record
        //---------------------------------------------------------------------
        //Output contract of the content layout engine.
        //
        //All rectangles are local to the item. RenderSupport may translate them
        //by item Bounds.Left / Bounds.Top when drawing, but must not recalculate
        //or reinterpret them.
        //
        //Visibility rule:
        //  Rect(0, 0, 0, 0) = element not visible.
        //
        //This rule is intentionally stronger than auxiliary Boolean flags in
        //TNoReflowTabBarItemMetrics. Those flags must be derived from these
        //rectangles, never the opposite.
        //---------------------------------------------------------------------

        //Final local rectangle used for text drawing and clipping.
        TextRect: TRect;

        //Final local rectangle used for glyph drawing. Empty = no glyph.
        GlyphRect: TRect;

        //Final local rectangle used for signal drawing. Empty = no signal.
        SignalRect: TRect;

        //GDI TextOut anchor. For horizontal text, this is the top-left point of
        //TextRect. For vertical text, this is the orientation-specific anchor
        //computed by the layout engine.
        TextAnchorX: Integer;
        TextAnchorY: Integer;

        {
          Clears all rectangles and anchors.

          Direct assignment to Rect(0,0,0,0) is used instead of helper methods
          such as TRect.Empty / SetRectEmpty to remain compatible with the
          Delphi versions targeted by the component.
        }
        Procedure Init;
    End;

    TNoReflowTabBarItemContentLayoutEngine = Class
    Private
        Class Function ResolvePhysicalGlyphPosition(
            AGlyphPosition: TNoReflowTabBarGlyphPosition;
            ATextOrientation: TNoReflowTabBarTextOrientation): TNoReflowTabBarGlyphPosition; Static;

        Class Function BuildContentContainerRect(
            Const AResult: TNoReflowTabBarItemContentLayoutResult;
            Out AContainerRect: TRect): Boolean; Static;

        Class Function RectFits(
            Const AOuterRect: TRect;
            Const AInnerRect: TRect): Boolean; Static;

        Class Function ComposeFlowCandidate(
            Const AInput: TNoReflowTabBarItemContentLayoutInput;
            AElements: TNoReflowTabBarItemContentElementSet;
            ATextFlow: Integer;
            Out AResult: TNoReflowTabBarItemContentLayoutResult;
            Out AContainerRect: TRect): Boolean; Static;

        Class Procedure OffsetFlowCandidate(
            Var AResult: TNoReflowTabBarItemContentLayoutResult;
            ADeltaFlow: Integer;
            ADeltaCross: Integer); Static;

        Class Function BuildPhysicalCandidate(
            Const AInput: TNoReflowTabBarItemContentLayoutInput;
            AElements: TNoReflowTabBarItemContentElementSet;
            ATextFlow: Integer;
            Out AResult: TNoReflowTabBarItemContentLayoutResult): Boolean; Static;

        Class Function TryCandidateWithShortText(
            Const AInput: TNoReflowTabBarItemContentLayoutInput;
            AElements: TNoReflowTabBarItemContentElementSet;
            Out AResult: TNoReflowTabBarItemContentLayoutResult): Boolean; Static;

    Public
        {
          Resolves final local rectangles for the text, signal and glyph.

          The algorithm is candidate-based:
          - each candidate is composed from scratch in a local flow/cross
            coordinate system starting at 0,0;
          - the container rectangle of the composed content is compared to the
            useful rectangle available inside the item;
          - when a candidate does not fit, it is discarded and the next candidate
            is composed from scratch.

          The order follows the visual priority:
          text > signal > glyph.

          Rendering must not reposition the returned rectangles. Empty
          rectangles mean that the corresponding element is not visible.
        }
        Class Procedure Resolve(
            Const AInput: TNoReflowTabBarItemContentLayoutInput;
            Out AResult: TNoReflowTabBarItemContentLayoutResult); Static;
    End;

    TNoReflowTabBarZoneLayoutEngine = Class
    private

        //Calcule le décalage horizontal du bloc complet en mode zones.
        //
        Class Function ResolveFlowStartOffset(
            ACanonicalClientWidth: Integer;
            AUsedBlockWidth: Integer;
            Const ALayout: TNoReflowTabBarLayout): Integer;

        //Construit l'ordre logique des indices de rendu pour le layout séquentiel.
        //
        //Cette méthode ne modifie jamais :
        //- l'ordre physique de la collection d'items ;
        //- l'ordre du tableau ARenderItems ;
        //- les index réels utilisés par le hit-test, le drag ou l'édition.
        //
        //Elle retourne uniquement une séquence d'indices à parcourir.
        Class Procedure BuildSequentialRenderOrder(
            AFlowOrder: TNoReflowTabBarFlowOrder;
            Const ARenderItems: TArray<TNoReflowTabBarRenderItem>;
            Var AOrderedIndexes: TArray<Integer>);

        //Calcule le décalage horizontal du bloc séquentiel complet.
        //
        //En mode séquentiel multi-ligne, on aligne volontairement le bloc global
        //et non chaque ligne individuellement.
        Class Function ResolveSequentialFlowOffset(
            ACanonicalClientWidth: Integer;
            ABlockWidth: Integer;
            Const ALayout: TNoReflowTabBarLayout): Integer;

        Class Procedure BuildCanonicalGridFromRenderItems(
            AGrid: TNoReflowTabBarZoneLayoutGrid;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            AFlowOrder: TNoReflowTabBarFlowOrder;
            Const ARenderItems: TArray<TNoReflowTabBarRenderItem>);

        Class Procedure ComputeCanonicalZoneOrigins(
            AGrid: TNoReflowTabBarZoneLayoutGrid;
            AFlowOrder: TNoReflowTabBarFlowOrder;
            AMarginLeft: Integer;
            ATabOverlap: Integer;
            Out AStartX: Integer;
            Out ACenterX: Integer;
            Out AEndX: Integer);

        Class Procedure ApplyCanonicalZoneLayout(
            AZone: TNoReflowTabBarZoneLayoutZone;
            AZoneX: Integer;
            AZoneY: Integer;
            ATotalHeight: Integer;
            ATabOverlap: Integer;
            ARowSpacing: Integer;
            Var ARenderItems: TArray<TNoReflowTabBarRenderItem>);

        Class Function GetCanonicalZoneFirstRowTop(
            AZone: TNoReflowTabBarZoneLayoutZone;
            AZoneY: Integer;
            ATotalHeight: Integer;
            ARowSpacing: Integer): Integer;

        Class Procedure BuildZoneLayoutCanonical(
            ACanonicalClientWidth: Integer;
            AActualClientWidth: Integer;
            AActualClientHeight: Integer;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            ABarPosition: TNoReflowTabBarPosition;
            ABarMode: TNoReflowTabBarMode;
            AFlowOrder: TNoReflowTabBarFlowOrder;
            Const ALayout: TNoReflowTabBarLayout;
            Const ATabLayout: TNoReflowTabBarLayoutTabs;
            Const AButtonLayout: TNoReflowTabBarLayoutButtons;
            Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
            Out UsedPrimarySize: Integer;
            Out UsedSecondarySize: Integer;
            Out ALayoutInfo: TNoReflowTabBarZoneLayoutInfo);

        Class Procedure BuildSequentialLayoutCanonical(
            ACanonicalClientWidth: Integer;
            AActualClientWidth: Integer;
            AActualClientHeight: Integer;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            ABarPosition: TNoReflowTabBarPosition;
            ABarMode: TNoReflowTabBarMode;
            AFlowOrder: TNoReflowTabBarFlowOrder;
            Const ALayout: TNoReflowTabBarLayout;
            Const ATabLayout: TNoReflowTabBarLayoutTabs;
            Const AButtonLayout: TNoReflowTabBarLayoutButtons;
            Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
            Out UsedPrimarySize: Integer;
            Out UsedSecondarySize: Integer);

        Class Procedure ComputeUsedSizesFromBounds(
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            Const ARenderItems: TArray<TNoReflowTabBarRenderItem>;
            Out UsedPrimarySize: Integer;
            Out UsedSecondarySize: Integer);

        Class Procedure TransformAllCanonicalRectsToActual(
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            ABarPosition: TNoReflowTabBarPosition;
            AActualClientWidth: Integer;
            AActualClientHeight: Integer;
            Var ARenderItems: TArray<TNoReflowTabBarRenderItem>);

    public
        Class Function TransformCanonicalPointToActual(
            Const P: TPoint;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            ABarPosition: TNoReflowTabBarPosition;
            AActualClientWidth: Integer;
            AActualClientHeight: Integer): TPoint;

        Class Function TransformCanonicalDirectionToActual(
            Const ADirection: TPoint;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            ABarPosition: TNoReflowTabBarPosition): TPoint;

        Class Function TransformActualPointToCanonical(
            Const P: TPoint;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            ABarPosition: TNoReflowTabBarPosition;
            AActualClientWidth: Integer;
            AActualClientHeight: Integer): TPoint;

        Class Function TransformCanonicalRectToActual(
            Const R: TRect;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            ABarPosition: TNoReflowTabBarPosition;
            AActualClientWidth: Integer;
            AActualClientHeight: Integer): TRect;

        Class Function TransformActualRectToCanonical(
            Const R: TRect;
            AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
            ABarPosition: TNoReflowTabBarPosition;
            AActualClientWidth: Integer;
            AActualClientHeight: Integer): TRect;

        Class Function TryGetCanonicalZoneRect(
            AGrid: TNoReflowTabBarZoneLayoutGrid;
            APinZone: TNoReflowTabBarPinZone;
            AStartX: Integer;
            ACenterX: Integer;
            AEndX: Integer;
            ATopY: Integer;
            ATotalHeight: Integer;
            ATabOverlap: Integer;
            Out R: TRect): Boolean;

        Class Function BuildCanonicalHeaderRect(
            Const ACanonicalZoneRect: TRect;
            AHeaderSize: Integer): TRect;

        Class Procedure BuildHorizontalZoneLayout(
            AClientWidth: Integer;
            AClientHeight: Integer;
            ABarPosition: TNoReflowTabBarPosition;
            ABarMode: TNoReflowTabBarMode;
            AFlowOrder: TNoReflowTabBarFlowOrder;
            Const ALayout: TNoReflowTabBarLayout;
            Const ATabLayout: TNoReflowTabBarLayoutTabs;
            Const AButtonLayout: TNoReflowTabBarLayoutButtons;
            Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
            Out UsedPrimarySize: Integer;
            Out UsedSecondarySize: Integer;
            Out ALayoutInfo: TNoReflowTabBarZoneLayoutInfo);

        //Point d'entree vertical : ne doit pas contenir de placement vertical
        //specifique. Il transpose uniquement les dimensions client vers le
        //repere canonique horizontal, puis laisse le moteur commun travailler.
        Class Procedure BuildVerticalZoneLayout(
            AClientWidth: Integer;
            AClientHeight: Integer;
            ABarPosition: TNoReflowTabBarPosition;
            ABarMode: TNoReflowTabBarMode;
            AFlowOrder: TNoReflowTabBarFlowOrder;
            Const ALayout: TNoReflowTabBarLayout;
            Const ATabLayout: TNoReflowTabBarLayoutTabs;
            Const AButtonLayout: TNoReflowTabBarLayoutButtons;
            Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
            Out UsedPrimarySize: Integer;
            Out UsedSecondarySize: Integer;
            Out ALayoutInfo: TNoReflowTabBarZoneLayoutInfo);

        Class Procedure BuildHorizontalSequentialLayout(
            AClientWidth: Integer;
            AClientHeight: Integer;
            ABarPosition: TNoReflowTabBarPosition;
            ABarMode: TNoReflowTabBarMode;
            AFlowOrder: TNoReflowTabBarFlowOrder;
            Const ALayout: TNoReflowTabBarLayout;
            Const ATabLayout: TNoReflowTabBarLayoutTabs;
            Const AButtonLayout: TNoReflowTabBarLayoutButtons;
            Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
            Out UsedWidth: Integer;
            Out UsedHeight: Integer);

        //Point d'entree sequentiel vertical : meme garde-fou que
        //BuildVerticalZoneLayout. Pas de second moteur vertical.
        Class Procedure BuildVerticalSequentialLayout(
            AClientWidth: Integer;
            AClientHeight: Integer;
            ABarPosition: TNoReflowTabBarPosition;
            ABarMode: TNoReflowTabBarMode;
            AFlowOrder: TNoReflowTabBarFlowOrder;
            Const ALayout: TNoReflowTabBarLayout;
            Const ATabLayout: TNoReflowTabBarLayoutTabs;
            Const AButtonLayout: TNoReflowTabBarLayoutButtons;
            Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
            Out UsedWidth: Integer;
            Out UsedHeight: Integer);
    End;

Implementation


{ TNoReflowTabBarItemContentLayoutResult }

Procedure TNoReflowTabBarItemContentLayoutResult.Init;
Begin
    //-------------------------------------------------------------------------
    //Do not call TRect.Empty here.
    //
    //Depending on Delphi version / helper resolution, Empty can be interpreted
    //as a query-style helper and not as a clearing operation. The debug trace
    //showed stale / garbage GlyphRect and SignalRect values even when
    //HasGlyph=False and HasSignal=False.
    //
    //SetRectEmpty is explicit and guarantees that all rectangle fields are
    //reset to 0.
    //-------------------------------------------------------------------------
    TextRect := Rect(0, 0, 0, 0);
    GlyphRect := Rect(0, 0, 0, 0);
    SignalRect := Rect(0, 0, 0, 0);

    TextAnchorX := 0;
    TextAnchorY := 0;
End;

{ TNoReflowTabBarItemContentLayoutEngine }

Class Function TNoReflowTabBarItemContentLayoutEngine.ResolvePhysicalGlyphPosition(
    AGlyphPosition: TNoReflowTabBarGlyphPosition;
    ATextOrientation: TNoReflowTabBarTextOrientation): TNoReflowTabBarGlyphPosition;
Begin
    //-------------------------------------------------------------------------
    //Converts the user-facing glyph position to the physical side used by the
    //effective text orientation.
    //
    //The public GlyphPosition remains logical:
    //- Left means before the text in the usual horizontal mental model;
    //- Right means after it;
    //- Top / Bottom mean above / below that model.
    //
    //For rotated text this logical position must be converted once, inside the
    //layout engine. RenderSupport must not repeat or second-guess this mapping.
    //
    //GUARD RAIL: do not use the resolved physical position to decide whether a
    //behavior belongs to the Top/Bottom or Left/Right family. Behavioral rules
    //must remain based on the canonical horizontal position. Only placement and
    //drawing may use this physical value.
    //-------------------------------------------------------------------------

    Result := AGlyphPosition;

    Case ATextOrientation Of
        nrttoVerticalUp: Begin
                Case AGlyphPosition Of
                    nrgpLeft:
                        Result := nrgpBottom;

                    nrgpRight:
                        Result := nrgpTop;

                    nrgpTop:
                        Result := nrgpLeft;

                    nrgpBottom:
                        Result := nrgpRight;
                End;
            End;

        nrttoVerticalDown: Begin
                Case AGlyphPosition Of
                    nrgpLeft:
                        Result := nrgpTop;

                    nrgpRight:
                        Result := nrgpBottom;

                    nrgpTop:
                        Result := nrgpRight;

                    nrgpBottom:
                        Result := nrgpLeft;
                End;
            End;
    End;
End;

Class Function TNoReflowTabBarItemContentLayoutEngine.BuildContentContainerRect(
    Const AResult: TNoReflowTabBarItemContentLayoutResult;
    Out AContainerRect: TRect): Boolean;

    Procedure IncludeRect(Const ARect: TRect);
    Begin
        If ARect.IsEmpty Then
            Exit;

        If AContainerRect.IsEmpty Then
            AContainerRect := ARect
        Else Begin
            If ARect.Left < AContainerRect.Left Then
                AContainerRect.Left := ARect.Left;

            If ARect.Top < AContainerRect.Top Then
                AContainerRect.Top := ARect.Top;

            If ARect.Right > AContainerRect.Right Then
                AContainerRect.Right := ARect.Right;

            If ARect.Bottom > AContainerRect.Bottom Then
                AContainerRect.Bottom := ARect.Bottom;
        End;
    End;

Begin
    AContainerRect := Rect(0, 0, 0, 0);

    IncludeRect(AResult.TextRect);
    IncludeRect(AResult.SignalRect);
    IncludeRect(AResult.GlyphRect);

    Result := Not AContainerRect.IsEmpty;
End;

Class Function TNoReflowTabBarItemContentLayoutEngine.RectFits(
    Const AOuterRect: TRect;
    Const AInnerRect: TRect): Boolean;
Begin
    Result :=
        (AInnerRect.Right > AInnerRect.Left) And
        (AInnerRect.Bottom > AInnerRect.Top) And
        (AInnerRect.Left >= AOuterRect.Left) And
        (AInnerRect.Top >= AOuterRect.Top) And
        (AInnerRect.Right <= AOuterRect.Right) And
        (AInnerRect.Bottom <= AOuterRect.Bottom);
End;

Class Function TNoReflowTabBarItemContentLayoutEngine.ComposeFlowCandidate(
    Const AInput: TNoReflowTabBarItemContentLayoutInput;
    AElements: TNoReflowTabBarItemContentElementSet;
    ATextFlow: Integer;
    Out AResult: TNoReflowTabBarItemContentLayoutResult;
    Out AContainerRect: TRect): Boolean;
Var
    PhysicalGlyphPosition: TNoReflowTabBarGlyphPosition;
    GlyphFlow:            Integer;
    GlyphCross:           Integer;
    TextCross:            Integer;
    TextGlyphFlow:        Integer;
    TextGlyphCross:       Integer;
    TextGlyphOffsetFlow:  Integer;
    TextGlyphOffsetCross: Integer;
    SignalBefore:         Boolean;
    BlockFlow:            Integer;
    BlockCross:           Integer;

    Procedure SetTextRect(AFlow, ACross, AFlowSize, ACrossSize: Integer);
    Begin
        AResult.TextRect := Rect(
            AFlow,
            ACross,
            AFlow + AFlowSize,
            ACross + ACrossSize);
    End;

    Procedure SetGlyphRect(AFlow, ACross, AFlowSize, ACrossSize: Integer);
    Begin
        AResult.GlyphRect := Rect(
            AFlow,
            ACross,
            AFlow + AFlowSize,
            ACross + ACrossSize);
    End;

    Procedure SetSignalRect(AFlow, ACross: Integer);
    Begin
        AResult.SignalRect := Rect(
            AFlow,
            ACross,
            AFlow + AInput.SignalDiameter,
            ACross + AInput.SignalDiameter);
    End;

    Procedure OffsetRectIfNotEmpty(Var ARect: TRect; AFlowDelta, ACrossDelta: Integer);
    Begin
        If ARect.IsEmpty Then
            Exit;

        OffsetRect(
            ARect,
            AFlowDelta,
            ACrossDelta);
    End;

Begin
    //-------------------------------------------------------------------------
    //Composes one complete candidate in a local flow/cross coordinate system.
    //
    //Important design rule:
    //this routine does not repair, trim or reinterpret a candidate after it has
    //been built. It only builds the requested combination of elements from
    //scratch:
    //
    //- text;
    //- optional signal;
    //- optional glyph.
    //
    //The caller later compares the resulting container rectangle with the
    //available local rectangle. If it does not fit, the candidate is discarded
    //and another candidate is composed from a clean state.
    //
    //This is what prevents the old class of bugs where text, glyph and signal
    //were individually moved or hidden after the initial layout decision.
    //-------------------------------------------------------------------------

    AResult.Init;
    AContainerRect := Rect(0, 0, 0, 0);
    Result := False;

    If ATextFlow <= 0 Then
        Exit;

    TextCross := AInput.TextHeight;

    If TextCross <= 0 Then
        Exit;

    PhysicalGlyphPosition := ResolvePhysicalGlyphPosition(
        AInput.GlyphPosition,
        AInput.TextOrientation);

    If AInput.TextOrientation = nrttoHorizontal Then Begin
        GlyphFlow := AInput.GlyphWidth;
        GlyphCross := AInput.GlyphHeight;
    End Else Begin
        GlyphFlow := AInput.GlyphHeight;
        GlyphCross := AInput.GlyphWidth;
    End;

    //---------------------------------------------------------------------
    //Compose text + glyph as a sub-block.
    //---------------------------------------------------------------------
    TextGlyphFlow := ATextFlow;
    TextGlyphCross := TextCross;

    If nrtcesGlyph In AElements Then Begin
        Case PhysicalGlyphPosition Of
            nrgpLeft, nrgpRight, nrgpTop, nrgpBottom: Begin
                    If PhysicalGlyphPosition In [nrgpLeft, nrgpTop] Then Begin
                        //Handled below as flow-before or cross-before.
                    End;
                End;
        End;

        Case AInput.TextOrientation Of
            nrttoHorizontal: Begin
                    Case PhysicalGlyphPosition Of
                        nrgpLeft, nrgpRight: Begin
                                TextGlyphFlow := GlyphFlow + AInput.GlyphSpacing + ATextFlow;
                                TextGlyphCross := Max(GlyphCross, TextCross);
                            End;

                        nrgpTop, nrgpBottom: Begin
                                TextGlyphFlow := Max(GlyphFlow, ATextFlow);
                                TextGlyphCross := GlyphCross + AInput.GlyphSpacing + TextCross;
                            End;
                    End;
                End;
        Else Begin
                Case PhysicalGlyphPosition Of
                    nrgpTop, nrgpBottom: Begin
                            TextGlyphFlow := GlyphFlow + AInput.GlyphSpacing + ATextFlow;
                            TextGlyphCross := Max(GlyphCross, TextCross);
                        End;

                    nrgpLeft, nrgpRight: Begin
                            TextGlyphFlow := Max(GlyphFlow, ATextFlow);
                            TextGlyphCross := GlyphCross + AInput.GlyphSpacing + TextCross;
                        End;
                End;
            End;
        End;
    End;

    SetTextRect(
        0,
        (TextGlyphCross - TextCross) Div 2,
        ATextFlow,
        TextCross);

    If nrtcesGlyph In AElements Then Begin
        Case AInput.TextOrientation Of
            nrttoHorizontal: Begin
                    Case PhysicalGlyphPosition Of
                        nrgpLeft: Begin
                                SetGlyphRect(
                                    0,
                                    (TextGlyphCross - GlyphCross) Div 2,
                                    GlyphFlow,
                                    GlyphCross);

                                SetTextRect(
                                    GlyphFlow + AInput.GlyphSpacing,
                                    (TextGlyphCross - TextCross) Div 2,
                                    ATextFlow,
                                    TextCross);
                            End;

                        nrgpRight: Begin
                                SetTextRect(
                                    0,
                                    (TextGlyphCross - TextCross) Div 2,
                                    ATextFlow,
                                    TextCross);

                                SetGlyphRect(
                                    ATextFlow + AInput.GlyphSpacing,
                                    (TextGlyphCross - GlyphCross) Div 2,
                                    GlyphFlow,
                                    GlyphCross);
                            End;

                        nrgpTop: Begin
                                SetGlyphRect(
                                    (TextGlyphFlow - GlyphFlow) Div 2,
                                    0,
                                    GlyphFlow,
                                    GlyphCross);

                                SetTextRect(
                                    (TextGlyphFlow - ATextFlow) Div 2,
                                    GlyphCross + AInput.GlyphSpacing,
                                    ATextFlow,
                                    TextCross);
                            End;

                        nrgpBottom: Begin
                                SetTextRect(
                                    (TextGlyphFlow - ATextFlow) Div 2,
                                    0,
                                    ATextFlow,
                                    TextCross);

                                SetGlyphRect(
                                    (TextGlyphFlow - GlyphFlow) Div 2,
                                    TextCross + AInput.GlyphSpacing,
                                    GlyphFlow,
                                    GlyphCross);
                            End;
                    End;
                End;
        Else Begin
                Case PhysicalGlyphPosition Of
                    nrgpTop: Begin
                            SetGlyphRect(
                                0,
                                (TextGlyphCross - GlyphCross) Div 2,
                                GlyphFlow,
                                GlyphCross);

                            SetTextRect(
                                GlyphFlow + AInput.GlyphSpacing,
                                (TextGlyphCross - TextCross) Div 2,
                                ATextFlow,
                                TextCross);
                        End;

                    nrgpBottom: Begin
                            SetTextRect(
                                0,
                                (TextGlyphCross - TextCross) Div 2,
                                ATextFlow,
                                TextCross);

                            SetGlyphRect(
                                ATextFlow + AInput.GlyphSpacing,
                                (TextGlyphCross - GlyphCross) Div 2,
                                GlyphFlow,
                                GlyphCross);
                        End;

                    nrgpLeft: Begin
                            SetGlyphRect(
                                (TextGlyphFlow - GlyphFlow) Div 2,
                                0,
                                GlyphFlow,
                                GlyphCross);

                            SetTextRect(
                                (TextGlyphFlow - ATextFlow) Div 2,
                                GlyphCross + AInput.GlyphSpacing,
                                ATextFlow,
                                TextCross);
                        End;

                    nrgpRight: Begin
                            SetTextRect(
                                (TextGlyphFlow - ATextFlow) Div 2,
                                0,
                                ATextFlow,
                                TextCross);

                            SetGlyphRect(
                                (TextGlyphFlow - GlyphFlow) Div 2,
                                TextCross + AInput.GlyphSpacing,
                                GlyphFlow,
                                GlyphCross);
                        End;
                End;
            End;
        End;
    End;

    //---------------------------------------------------------------------
    //Compose optional signal around the text+glyph sub-block.
    //---------------------------------------------------------------------
    SignalBefore := AInput.SignalPosition = nrtspBefore;

    BlockFlow := TextGlyphFlow;
    BlockCross := TextGlyphCross;
    TextGlyphOffsetFlow := 0;
    TextGlyphOffsetCross := 0;

    If nrtcesSignal In AElements Then Begin
        BlockFlow := AInput.SignalDiameter + AInput.SignalSpacing + TextGlyphFlow;
        BlockCross := Max(
            TextGlyphCross,
            AInput.SignalDiameter);

        TextGlyphOffsetCross := (BlockCross - TextGlyphCross) Div 2;

        If SignalBefore Then Begin
            SetSignalRect(
                0,
                (BlockCross - AInput.SignalDiameter) Div 2);

            TextGlyphOffsetFlow := AInput.SignalDiameter + AInput.SignalSpacing;
        End Else Begin
            SetSignalRect(
                TextGlyphFlow + AInput.SignalSpacing,
                (BlockCross - AInput.SignalDiameter) Div 2);
        End;
    End;

    OffsetRectIfNotEmpty(
        AResult.TextRect,
        TextGlyphOffsetFlow,
        TextGlyphOffsetCross);

    OffsetRectIfNotEmpty(
        AResult.GlyphRect,
        TextGlyphOffsetFlow,
        TextGlyphOffsetCross);

    If Not BuildContentContainerRect(
        AResult,
        AContainerRect) Then
        Exit;

    Result := True;
End;

Class Procedure TNoReflowTabBarItemContentLayoutEngine.OffsetFlowCandidate(
    Var AResult: TNoReflowTabBarItemContentLayoutResult;
    ADeltaFlow: Integer;
    ADeltaCross: Integer);
Begin
    If Not AResult.TextRect.IsEmpty Then
        OffsetRect(
            AResult.TextRect,
            ADeltaFlow,
            ADeltaCross);

    If Not AResult.GlyphRect.IsEmpty Then
        OffsetRect(
            AResult.GlyphRect,
            ADeltaFlow,
            ADeltaCross);

    If Not AResult.SignalRect.IsEmpty Then
        OffsetRect(
            AResult.SignalRect,
            ADeltaFlow,
            ADeltaCross);
End;

Class Function TNoReflowTabBarItemContentLayoutEngine.BuildPhysicalCandidate(
    Const AInput: TNoReflowTabBarItemContentLayoutInput;
    AElements: TNoReflowTabBarItemContentElementSet;
    ATextFlow: Integer;
    Out AResult: TNoReflowTabBarItemContentLayoutResult): Boolean;
Var
    InnerRect:      TRect;
    LocalMaxRect:   TRect;
    ContainerRect:  TRect;
    FlowStart:      Integer;
    FlowEnd:        Integer;
    CrossStart:     Integer;
    CrossEnd:       Integer;
    DeltaFlow:      Integer;
    DeltaCross:     Integer;
    SavedFlowStart: Integer;

    Function FlowToPhysicalRect(Const ARect: TRect): TRect;
    Begin
        Result := Rect(0, 0, 0, 0);

        If ARect.IsEmpty Then
            Exit;

        Case AInput.TextOrientation Of
            nrttoVerticalUp: Begin
                    Result := Rect(
                        ARect.Top,
                        AInput.ItemHeight - ARect.Right,
                        ARect.Bottom,
                        AInput.ItemHeight - ARect.Left);
                End;

            nrttoVerticalDown: Begin
                    Result := Rect(
                        ARect.Top,
                        ARect.Left,
                        ARect.Bottom,
                        ARect.Right);
                End;
        Else
            Result := ARect;
        End;
    End;

Begin
    AResult.Init;
    Result := False;

    If (AInput.ItemWidth <= 0) Or (AInput.ItemHeight <= 0) Then
        Exit;

    //---------------------------------------------------------------------
    //Build the useful inner rectangle first.
    //
    //This rectangle is the only area in which content may be placed. It already
    //contains:
    //- TextSpaceBefore / TextSpaceAfter;
    //- TextSpaceOver / TextSpaceUnder;
    //- tab slant pads;
    //- shape insets.
    //
    //Candidate composition is then done in a local coordinate system whose
    //origin is InnerRect.Left/Top, but expressed as 0,0 during composition.
    //
    //Algorithm:
    //1) build InnerRect in item coordinates;
    //2) create LocalMaxRect = Rect(0,0,InnerRect.Width,InnerRect.Height);
    //3) compose a candidate at 0,0;
    //4) compare the candidate container to LocalMaxRect;
    //5) translate accepted rectangles by InnerRect.Left/Top;
    //6) transform flow/cross rectangles back to physical item coordinates.
    //---------------------------------------------------------------------

    If AInput.TextOrientation = nrttoHorizontal Then Begin
        Case AInput.TabPosition Of
            nrtbpTop: Begin
                    FlowStart := AInput.SlantPadFirst + AInput.TextSpaceBefore;
                    FlowEnd := AInput.ItemWidth - AInput.SlantPadSecond - AInput.TextSpaceAfter;
                End;
        Else Begin
                FlowStart := AInput.TextSpaceBefore;
                FlowEnd := AInput.ItemWidth - AInput.TextSpaceAfter;
            End;
        End;

        CrossStart := AInput.TopInset + AInput.TextSpaceOver;
        CrossEnd := AInput.ItemHeight - AInput.BottomInset - AInput.TextSpaceUnder;
    End Else Begin
        Case AInput.TabPosition Of
            nrtbpLeft: Begin
                    FlowStart := AInput.SlantPadSecond + AInput.TextSpaceBefore;
                    FlowEnd := AInput.ItemHeight - AInput.SlantPadFirst - AInput.TextSpaceAfter;
                End;

            nrtbpRight: Begin
                    FlowStart := AInput.SlantPadFirst + AInput.TextSpaceBefore;
                    FlowEnd := AInput.ItemHeight - AInput.SlantPadSecond - AInput.TextSpaceAfter;
                End;
        Else Begin
                FlowStart := AInput.TextSpaceBefore;
                FlowEnd := AInput.ItemHeight - AInput.TextSpaceAfter;
            End;
        End;

        If AInput.TextOrientation = nrttoVerticalUp Then Begin
            SavedFlowStart := FlowStart;
            FlowStart := AInput.ItemHeight - FlowEnd;
            FlowEnd := AInput.ItemHeight - SavedFlowStart;
        End;

        CrossStart := AInput.LeftInset + AInput.TextSpaceOver;
        CrossEnd := AInput.ItemWidth - AInput.RightInset - AInput.TextSpaceUnder;
    End;

    If (FlowEnd <= FlowStart) Or (CrossEnd <= CrossStart) Then
        Exit;

    InnerRect := Rect(
        FlowStart,
        CrossStart,
        FlowEnd,
        CrossEnd);

    LocalMaxRect := Rect(
        0,
        0,
        InnerRect.Width,
        InnerRect.Height);

    If Not ComposeFlowCandidate(
        AInput,
        AElements,
        ATextFlow,
        AResult,
        ContainerRect) Then
        Exit;

    //---------------------------------------------------------------------
    //Text-only candidate.
    //
    //This candidate is the final fallback when richer candidates do not fit.
    //It must therefore be validated against the drawing rectangle that will
    //actually be returned to the renderer, not against the measured text
    //height.
    //
    //This is especially important with ForcedThickness: the forced cross size
    //may be smaller than the measured text height, but the text should still be
    //drawn, clipped and centered in the available inner rectangle instead of
    //making the whole item empty.
    //
    //For text-only, the returned TextRect is deliberately the full useful local
    //inner rectangle. This preserves margins and gives DrawText enough area for
    //DT_VCENTER and DT_END_ELLIPSIS.
    //---------------------------------------------------------------------
    If AElements = [nrtcesText] Then Begin
        AResult.TextRect.Left := LocalMaxRect.Left;
        AResult.TextRect.Right := LocalMaxRect.Right;
        AResult.TextRect.Top := LocalMaxRect.Top;
        AResult.TextRect.Bottom := LocalMaxRect.Bottom;

        ContainerRect := LocalMaxRect;
    End;

    If Not RectFits(
        LocalMaxRect,
        ContainerRect) Then
        Exit;

    //---------------------------------------------------------------------
    //Place the accepted local candidate inside the useful inner rectangle.
    //
    //The candidate has been composed in local coordinates starting at 0,0.
    //The final flow origin is the left/top edge of the inner rectangle. This
    //preserves the configured margins because InnerRect already includes them.
    //
    //Only the cross axis is centered for composed content.
    //---------------------------------------------------------------------
    DeltaFlow := InnerRect.Left;
    DeltaCross := InnerRect.Top + ((InnerRect.Height - ContainerRect.Height) Div 2);

    If AElements = [nrtcesText] Then
        DeltaCross := InnerRect.Top;

    OffsetFlowCandidate(
        AResult,
        DeltaFlow,
        DeltaCross);

    AResult.TextRect := FlowToPhysicalRect(AResult.TextRect);
    AResult.GlyphRect := FlowToPhysicalRect(AResult.GlyphRect);
    AResult.SignalRect := FlowToPhysicalRect(AResult.SignalRect);

    Case AInput.TextOrientation Of
        nrttoVerticalUp: Begin
                AResult.TextAnchorX := AResult.TextRect.Left;
                AResult.TextAnchorY := AResult.TextRect.Bottom;
            End;

        nrttoVerticalDown: Begin
                AResult.TextAnchorX := AResult.TextRect.Right;
                AResult.TextAnchorY := AResult.TextRect.Top;
            End;
    Else Begin
            AResult.TextAnchorX := AResult.TextRect.Left;
            AResult.TextAnchorY := AResult.TextRect.Top;
        End;
    End;

    Result := True;
End;

Class Function TNoReflowTabBarItemContentLayoutEngine.TryCandidateWithShortText(
    Const AInput: TNoReflowTabBarItemContentLayoutInput;
    AElements: TNoReflowTabBarItemContentElementSet;
    Out AResult: TNoReflowTabBarItemContentLayoutResult): Boolean;
Var
    LowFlow:    Integer;
    HighFlow:   Integer;
    MidFlow:    Integer;
    BestResult: TNoReflowTabBarItemContentLayoutResult;
    TestResult: TNoReflowTabBarItemContentLayoutResult;
Begin
    AResult.Init;
    BestResult.Init;

    Result := False;
    LowFlow := 1;
    HighFlow := AInput.TextWidth;

    While LowFlow <= HighFlow Do Begin
        MidFlow := (LowFlow + HighFlow) Div 2;

        If BuildPhysicalCandidate(
            AInput,
            AElements,
            MidFlow,
            TestResult) Then Begin
            BestResult := TestResult;
            Result := True;
            LowFlow := MidFlow + 1;
        End Else
            HighFlow := MidFlow - 1;
    End;

    If Result Then
        AResult := BestResult;
End;

Class Procedure TNoReflowTabBarItemContentLayoutEngine.Resolve(
    Const AInput: TNoReflowTabBarItemContentLayoutInput;
    Out AResult: TNoReflowTabBarItemContentLayoutResult);
Var
    FullSet:     TNoReflowTabBarItemContentElementSet;
    TextSignal: TNoReflowTabBarItemContentElementSet;
    TextOnly:   TNoReflowTabBarItemContentElementSet;
Begin
    //-------------------------------------------------------------------------
    //Resolution is performed by composing complete candidates from scratch.
    //
    //No after-the-fact correction is performed. If a candidate does not fit,
    //it is discarded and the next candidate is composed from a clean state.
    //
    //Priority rule:
    //
    //  1) signal
    //  2) text
    //  3) glyph
    //
    //The signal is an important status indicator. The text can be completed by
    //the item hint, so when there is not enough room for the complete caption,
    //the resolver now tries "short text + signal" before removing the signal.
    //
    //The absence of a signal or glyph may come from either:
    //- the item/user configuration, through HasSignal / HasGlyph;
    //- an automatic fallback when the richer candidate does not fit.
    //
    //In both cases the result uses the same contract:
    //empty rectangle = element not visible.
    //-------------------------------------------------------------------------

    AResult.Init;

    TextOnly := [nrtcesText];
    TextSignal := TextOnly;
    FullSet := TextOnly;

    If AInput.HasSignal And (AInput.SignalDiameter > 0) Then Begin
        Include(
            TextSignal,
            nrtcesSignal);

        Include(
            FullSet,
            nrtcesSignal);
    End;

    If AInput.HasGlyph And (AInput.GlyphWidth > 0) And (AInput.GlyphHeight > 0) Then
        Include(
            FullSet,
            nrtcesGlyph);

    //---------------------------------------------------------------------
    //1. Richest candidate.
    //---------------------------------------------------------------------
    If BuildPhysicalCandidate(
        AInput,
        FullSet,
        AInput.TextWidth,
        AResult) Then
        Exit;

    //---------------------------------------------------------------------
    //2. Remove the glyph before degrading the text or the signal.
    //---------------------------------------------------------------------
    If (nrtcesSignal In TextSignal) And BuildPhysicalCandidate(
        AInput,
        TextSignal,
        AInput.TextWidth,
        AResult) Then
        Exit;

    //---------------------------------------------------------------------
    //3. Keep the signal if possible, even with shortened text.
    //---------------------------------------------------------------------
    If nrtcesSignal In TextSignal Then Begin
        If TryCandidateWithShortText(
            AInput,
            TextSignal,
            AResult) Then
            Exit;
    End;

    //---------------------------------------------------------------------
    //4. Only now remove the signal and try full text alone.
    //---------------------------------------------------------------------
    If BuildPhysicalCandidate(
        AInput,
        TextOnly,
        AInput.TextWidth,
        AResult) Then
        Exit;

    //---------------------------------------------------------------------
    //5. Final fallback: shortened text alone.
    //---------------------------------------------------------------------
    TryCandidateWithShortText(
        AInput,
        TextOnly,
        AResult);
End;

Const
    CCenterMinWidthFactor = 2;

    //===============================================================================================================================
    //Helpers
    //===============================================================================================================================

Function MaxIntLocal(A, B: Integer): Integer;
Begin
    If A > B Then
        Result := A
    Else
        Result := B;
End;

Function IsButtonBarMode(Const ABarMode: TNoReflowTabBarMode): Boolean;
Begin
    //-------------------------------------------------------------------------
    //Indique si le mode courant doit être rendu et placé comme une barre
    //de boutons plutôt que comme une barre d'onglets.
    //
    //Les trois modes boutons partagent la même logique géométrique :
    //- aucune superposition entre items ;
    //- espacement positif entre deux boutons consécutifs ;
    //- dimensions potentiellement forcées par BarLayoutButtons.
    //-------------------------------------------------------------------------
    Result := ABarMode In [nrbmPushButtons, nrbmSelectButtons, nrbmCheckButtons];
End;

Function ResolveItemOverlap(
    Const ABarMode: TNoReflowTabBarMode;
    Const ATabLayout: TNoReflowTabBarLayoutTabs;
    Const AButtonLayout: TNoReflowTabBarLayoutButtons): Integer;
Begin
    //-------------------------------------------------------------------------
    //Résout la valeur de pas utilisée par le moteur existant.
    //
    //Le moteur de layout historique raisonne avec la formule :
    //
    //position suivante = position courante + taille item - overlap
    //
    //En mode onglets :
    //- overlap est positif ;
    //- les formes se recouvrent visuellement.
    //
    //En mode boutons :
    //- les items ne doivent pas se recouvrir ;
    //- on encode donc l'espacement comme un overlap négatif.
    //
    //Exemple :
    //- ButtonSpacing = 6 ;
    //- ItemOverlap = -6 ;
    //- position suivante = position courante + taille item - (-6)
    //= position courante + taille item + 6.
    //-------------------------------------------------------------------------
    Result := 0;

    If IsButtonBarMode(ABarMode) Then Begin
        If AButtonLayout <> Nil Then
            Result := -Max(0, AButtonLayout.ButtonSpacing);

        Exit;
    End;

    If ATabLayout <> Nil Then
        Result := ATabLayout.TabOverlap;
End;

Function VisibleZoneSpacingCount(AHasStart, AHasCenter, AHasEnd: Boolean): Integer;
Var
    CountVisibleZones: Integer;
Begin
    CountVisibleZones := 0;

    If AHasStart Then
        Inc(CountVisibleZones);

    If AHasCenter Then
        Inc(CountVisibleZones);

    If AHasEnd Then
        Inc(CountVisibleZones);

    If CountVisibleZones > 1 Then
        Result := CountVisibleZones - 1
    Else
        Result := 0;
End;

procedure TNoReflowTabBarSingleZoneLayoutInfo.Init;
begin
    HasZone := False;
    OuterCanonicalRect := Rect(
        0,
        0,
        0,
        0);
    FirstRowCanonicalTop := 0;
end;

procedure TNoReflowTabBarZoneLayoutInfo.Init;
begin
    //Initialisation des sous-records
    StartZone.Init;
    CenterZone.Init;
    EndZone.Init;
end;

//===============================================================================================================================
//TNoReflowTabBarZoneLayoutItem
//===============================================================================================================================

Constructor TNoReflowTabBarZoneLayoutItem.Create(
    ARenderIndex: Integer;
    AItem: TNoReflowTabBarItem;
    APinZone: TNoReflowTabBarPinZone;
    AWidth: Integer;
    AHeight: Integer);
Begin
    Inherited Create;

    FRenderIndex := ARenderIndex;
    FItem := AItem;
    FPinZone := APinZone;
    FWidth := AWidth;
    FHeight := AHeight;
    FColumnIndex := 0;
End;

//===============================================================================================================================
//TNoReflowTabBarZoneLayoutZone
//===============================================================================================================================

Constructor TNoReflowTabBarZoneLayoutZone.Create(APinZone: TNoReflowTabBarPinZone);
Begin
    Inherited Create;
    FPinZone := APinZone;
    FItems := TObjectList<TNoReflowTabBarZoneLayoutItem>.Create(True);
End;

Destructor TNoReflowTabBarZoneLayoutZone.Destroy;
Begin
    FItems.Free;
    Inherited Destroy;
End;

Procedure TNoReflowTabBarZoneLayoutZone.Clear;
Begin
    FItems.Clear;
End;

Procedure TNoReflowTabBarZoneLayoutZone.AddItem(AItem: TNoReflowTabBarZoneLayoutItem);
Begin
    If AItem = Nil Then
        Exit;

    FItems.Add(AItem);
End;

Function TNoReflowTabBarZoneLayoutZone.GetCount: Integer;
Begin
    Result := FItems.Count;
End;

Function TNoReflowTabBarZoneLayoutZone.GetItem(AAbsoluteItemIndex: Integer): TNoReflowTabBarZoneLayoutItem;
Begin
    Result := FItems[AAbsoluteItemIndex];
End;

Function TNoReflowTabBarZoneLayoutZone.HasVisibleContent: Boolean;
Begin
    Result := FItems.Count > 0;
End;

Function TNoReflowTabBarZoneLayoutZone.GetDefaultColumnAlign: TNoReflowTabBarZoneColumnAlign;
Begin
    Result := nrtzcaStart;
End;

Procedure TNoReflowTabBarZoneLayoutZone.CopyState(
    Const ASource: TNoReflowTabBarZoneState;
    Var ADest: TNoReflowTabBarZoneState);
Var
    I: Integer;
Begin
    ADest.ColumnCount := ASource.ColumnCount;
    ADest.UsedWidth := ASource.UsedWidth;
    ADest.UsedHeight := ASource.UsedHeight;

    SetLength(
        ADest.ColumnAssignments,
        Length(ASource.ColumnAssignments));

    For I := 0 To High(ASource.ColumnAssignments) Do
        ADest.ColumnAssignments[I] := ASource.ColumnAssignments[I];
End;

Function TNoReflowTabBarZoneLayoutZone.GetMaxColumnIndexForState(Const AState: TNoReflowTabBarZoneState): Integer;
Var
    I: Integer;
Begin
    Result := 0;

    If Length(AState.ColumnAssignments) = 0 Then
        Exit;

    For I := 0 To High(AState.ColumnAssignments) Do
        If AState.ColumnAssignments[I] > Result Then
            Result := AState.ColumnAssignments[I];
End;

Function TNoReflowTabBarZoneLayoutZone.GetColumnWidthForState(
    Const AState: TNoReflowTabBarZoneState;
    AColumnIndex: Integer;
    ATabOverlap: Integer): Integer;
Var
    I:           Integer;
    ColumnWidth: Integer;
Begin
    ColumnWidth := 0;

    For I := 0 To High(AState.ColumnAssignments) Do Begin
        If AState.ColumnAssignments[I] <> AColumnIndex Then
            Continue;

        If ColumnWidth = 0 Then
            ColumnWidth := FItems[I].Width
        Else
            ColumnWidth := ColumnWidth + FItems[I].Width - ATabOverlap;
    End;

    Result := ColumnWidth;
End;

Function TNoReflowTabBarZoneLayoutZone.GetColumnHeightForState(
    Const AState: TNoReflowTabBarZoneState;
    AColumnIndex: Integer): Integer;
Var
    I:            Integer;
    ColumnHeight: Integer;
Begin
    ColumnHeight := 0;

    For I := 0 To High(AState.ColumnAssignments) Do Begin
        If AState.ColumnAssignments[I] <> AColumnIndex Then
            Continue;

        If FItems[I].Height > ColumnHeight Then
            ColumnHeight := FItems[I].Height;
    End;

    Result := ColumnHeight;
End;

Function TNoReflowTabBarZoneLayoutZone.GetMonoColumnWidth(ATabOverlap: Integer): Integer;
Var
    I: Integer;
Begin
    Result := 0;

    If FItems.Count = 0 Then
        Exit;

    For I := 0 To FItems.Count - 1 Do Begin
        If Result = 0 Then
            Result := FItems[I].Width
        Else
            Result := Result + FItems[I].Width - ATabOverlap;
    End;
End;

Function TNoReflowTabBarZoneLayoutZone.GetMaxItemWidth: Integer;
Var
    I: Integer;
Begin
    Result := 0;

    For I := 0 To FItems.Count - 1 Do
        If FItems[I].Width > Result Then
            Result := FItems[I].Width;
End;

Procedure TNoReflowTabBarZoneLayoutZone.RecalcZoneStateMetrics(
    Var AState: TNoReflowTabBarZoneState;
    ATabOverlap: Integer;
    ARowSpacing: Integer);
Var
    ColumnIndex:    Integer;
    MaxColumnIndex: Integer;
    ColumnWidth:    Integer;
    ColumnHeight:   Integer;
Begin
    AState.ColumnCount := 0;
    AState.UsedWidth := 0;
    AState.UsedHeight := 0;

    If Length(AState.ColumnAssignments) = 0 Then
        Exit;

    MaxColumnIndex := GetMaxColumnIndexForState(AState);
    AState.ColumnCount := MaxColumnIndex + 1;

    For ColumnIndex := 0 To MaxColumnIndex Do Begin
        ColumnWidth := GetColumnWidthForState(
            AState,
            ColumnIndex,
            ATabOverlap);
        If ColumnWidth > AState.UsedWidth Then
            AState.UsedWidth := ColumnWidth;

        ColumnHeight := GetColumnHeightForState(
            AState,
            ColumnIndex);
        If ColumnHeight > 0 Then Begin
            If AState.UsedHeight > 0 Then
                Inc(
                    AState.UsedHeight,
                    ARowSpacing);

            Inc(
                AState.UsedHeight,
                ColumnHeight);
        End;
    End;
End;

Procedure TNoReflowTabBarZoneLayoutZone.BuildInitialZoneState(
    Out AState: TNoReflowTabBarZoneState;
    ATabOverlap: Integer;
    ARowSpacing: Integer);
Var
    I: Integer;
Begin
    AState.ColumnCount := 0;
    AState.UsedWidth := 0;
    AState.UsedHeight := 0;

    SetLength(
        AState.ColumnAssignments,
        FItems.Count);

    For I := 0 To FItems.Count - 1 Do
        AState.ColumnAssignments[I] := 0;

    RecalcZoneStateMetrics(
        AState,
        ATabOverlap,
        ARowSpacing);
End;

Function TNoReflowTabBarZoneLayoutZone.BuildSequentialStateForTargetWidth(
    ATargetWidth: Integer;
    ATabOverlap: Integer;
    ARowSpacing: Integer;
    Out AState: TNoReflowTabBarZoneState): Boolean;
Var
    I:                    Integer;
    CurrentColumn:        Integer;
    CurrentWidth:         Integer;
    NextWidth:            Integer;
    EffectiveTargetWidth: Integer;
Begin
    Result := False;

    AState.ColumnCount := 0;
    AState.UsedWidth := 0;
    AState.UsedHeight := 0;
    SetLength(
        AState.ColumnAssignments,
        0);

    If FItems.Count = 0 Then Begin
        Result := True;
        Exit;
    End;

    EffectiveTargetWidth := MaxIntLocal(
        ATargetWidth,
        GetMaxItemWidth);

    SetLength(
        AState.ColumnAssignments,
        FItems.Count);

    CurrentColumn := 0;
    CurrentWidth := 0;

    For I := 0 To FItems.Count - 1 Do Begin
        If CurrentWidth = 0 Then
            NextWidth := FItems[I].Width
        Else
            NextWidth := CurrentWidth + FItems[I].Width - ATabOverlap;

        If (CurrentWidth > 0) And (NextWidth > EffectiveTargetWidth) Then Begin
            Inc(CurrentColumn);
            CurrentWidth := FItems[I].Width;
        End
        Else
            CurrentWidth := NextWidth;

        AState.ColumnAssignments[I] := CurrentColumn;
    End;

    RecalcZoneStateMetrics(
        AState,
        ATabOverlap,
        ARowSpacing);
    Result := True;
End;

Function TNoReflowTabBarZoneLayoutZone.GetAppliedMaxColumnIndex: Integer;
Var
    I: Integer;
Begin
    Result := 0;

    For I := 0 To FItems.Count - 1 Do
        If FItems[I].ColumnIndex > Result Then
            Result := FItems[I].ColumnIndex;
End;

Function TNoReflowTabBarZoneLayoutZone.GetAppliedZoneWidth(ATabOverlap: Integer): Integer;
Var
    ColumnIndex: Integer;
    ItemIndex:   Integer;
    ColumnWidth: Integer;
    MaxColumn:   Integer;
Begin
    Result := 0;

    If FItems.Count = 0 Then
        Exit;

    MaxColumn := GetAppliedMaxColumnIndex;

    For ColumnIndex := 0 To MaxColumn Do Begin
        ColumnWidth := 0;

        For ItemIndex := 0 To FItems.Count - 1 Do Begin
            If FItems[ItemIndex].ColumnIndex <> ColumnIndex Then
                Continue;

            If ColumnWidth = 0 Then
                ColumnWidth := FItems[ItemIndex].Width
            Else
                ColumnWidth := ColumnWidth + FItems[ItemIndex].Width - ATabOverlap;
        End;

        If ColumnWidth > Result Then
            Result := ColumnWidth;
    End;
End;

Function TNoReflowTabBarZoneLayoutZone.GetAppliedZoneHeight(ARowSpacing: Integer): Integer;
Var
    ColumnIndex:    Integer;
    MaxColumnIndex: Integer;
    ColumnHeight:   Integer;
    ItemIndex:      Integer;
Begin
    Result := 0;

    If FItems.Count = 0 Then
        Exit;

    MaxColumnIndex := GetAppliedMaxColumnIndex;

    For ColumnIndex := 0 To MaxColumnIndex Do Begin
        ColumnHeight := 0;

        For ItemIndex := 0 To FItems.Count - 1 Do Begin
            If FItems[ItemIndex].ColumnIndex <> ColumnIndex Then
                Continue;

            If FItems[ItemIndex].Height > ColumnHeight Then
                ColumnHeight := FItems[ItemIndex].Height;
        End;

        If ColumnHeight > 0 Then Begin
            If Result > 0 Then
                Inc(
                    Result,
                    ARowSpacing);

            Inc(
                Result,
                ColumnHeight);
        End;
    End;
End;

Procedure TNoReflowTabBarZoneLayoutZone.ApplyZoneState(Const AState: TNoReflowTabBarZoneState);
Var
    I: Integer;
Begin
    If Length(AState.ColumnAssignments) <> FItems.Count Then
        Exit;

    For I := 0 To FItems.Count - 1 Do
        FItems[I].ColumnIndex := AState.ColumnAssignments[I];
End;

//===============================================================================================================================
//TNoReflowTabBarZoneLayoutGrid
//===============================================================================================================================

Constructor TNoReflowTabBarZoneLayoutGrid.Create;
Begin
    Inherited Create;

    FStartZone := TNoReflowTabBarZoneLayoutZone.Create(nrtpzStart);
    FCenterZone := TNoReflowTabBarZoneLayoutZone.Create(nrtpzCenter);
    FEndZone := TNoReflowTabBarZoneLayoutZone.Create(nrtpzEnd);

    FZoneSpacing := 12;
    FFlowOrder := nrtfoNormal;
End;

Destructor TNoReflowTabBarZoneLayoutGrid.Destroy;
Begin
    FStartZone.Free;
    FCenterZone.Free;
    FEndZone.Free;
    Inherited Destroy;
End;

Procedure TNoReflowTabBarZoneLayoutGrid.Clear;
Begin
    FStartZone.Clear;
    FCenterZone.Clear;
    FEndZone.Clear;

    SetLength(
        FStartState.ColumnAssignments,
        0);
    SetLength(
        FCenterState.ColumnAssignments,
        0);
    SetLength(
        FEndState.ColumnAssignments,
        0);
End;

Function TNoReflowTabBarZoneLayoutGrid.GetVisibleZoneCount: Integer;
Begin
    Result := 0;

    If HasStart Then
        Inc(Result);

    If HasCenter Then
        Inc(Result);

    If HasEnd Then
        Inc(Result);
End;

Function TNoReflowTabBarZoneLayoutGrid.GetZoneByPinZone(APinZone: TNoReflowTabBarPinZone): TNoReflowTabBarZoneLayoutZone;
Begin
    Case APinZone Of
        nrtpzStart:
            Result := FStartZone;
        nrtpzCenter:
            Result := FCenterZone;
        nrtpzEnd:
            Result := FEndZone;
    Else
        Result := FCenterZone;
    End;
End;

Function TNoReflowTabBarZoneLayoutGrid.HasStart: Boolean;
Begin
    Result := FStartZone.HasVisibleContent;
End;

Function TNoReflowTabBarZoneLayoutGrid.HasCenter: Boolean;
Begin
    Result := FCenterZone.HasVisibleContent;
End;

Function TNoReflowTabBarZoneLayoutGrid.HasEnd: Boolean;
Begin
    Result := FEndZone.HasVisibleContent;
End;

Function TNoReflowTabBarZoneLayoutGrid.GetSpacingCount: Integer;
Begin
    Result := VisibleZoneSpacingCount(
        HasStart,
        HasCenter,
        HasEnd);
End;

Function TNoReflowTabBarZoneLayoutGrid.GetGlobalWidth: Integer;
Begin
    Result := 0;

    If HasStart Then
        Inc(
            Result,
            FStartState.UsedWidth);

    If HasCenter Then
        Inc(
            Result,
            FCenterState.UsedWidth);

    If HasEnd Then
        Inc(
            Result,
            FEndState.UsedWidth);

    Inc(
        Result,
        GetSpacingCount * FZoneSpacing);
End;

Procedure TNoReflowTabBarZoneLayoutGrid.InitZoneStates(
    ATabOverlap: Integer;
    ARowSpacing: Integer);
Begin
    FStartZone.BuildInitialZoneState(
        FStartState,
        ATabOverlap,
        ARowSpacing);
    FCenterZone.BuildInitialZoneState(
        FCenterState,
        ATabOverlap,
        ARowSpacing);
    FEndZone.BuildInitialZoneState(
        FEndState,
        ATabOverlap,
        ARowSpacing);
End;

Procedure TNoReflowTabBarZoneLayoutGrid.ApplyStatesToZones;
Begin
    If HasStart Then
        FStartZone.ApplyZoneState(FStartState);

    If HasCenter Then
        FCenterZone.ApplyZoneState(FCenterState);

    If HasEnd Then
        FEndZone.ApplyZoneState(FEndState);
End;

Function TNoReflowTabBarZoneLayoutGrid.GetLeadingZone: TNoReflowTabBarZoneLayoutZone;
Begin
    //-------------------------------------------------------------------------
    //Retourne la première zone du flux logique.
    //
    //nrtfoNormal :
    //Start -> Center -> End, donc Leading = Start.
    //
    //nrtfoReverseZones / nrtfoReverseZonesAndItems :
    //End -> Center -> Start, donc Leading = End.
    //
    //La zone retournée conserve toujours son identité réelle.
    //-------------------------------------------------------------------------

    Case FFlowOrder Of
        nrtfoReverseZones, nrtfoReverseZonesAndItems:
            Result := FEndZone;
    Else
        Result := FStartZone;
    End;
End;

Function TNoReflowTabBarZoneLayoutGrid.GetTrailingZone: TNoReflowTabBarZoneLayoutZone;
Begin
    //-------------------------------------------------------------------------
    //Retourne la dernière zone du flux logique.
    //
    //Cette notion est utilisée pour conserver la règle historique de
    //compactage :
    //- priorité au centre ;
    //- puis à la zone située en fin de flux ;
    //- puis à la zone située en début de flux.
    //
    //Avec nrtfoNormal :
    //Trailing = End.
    //
    //Avec nrtfoReverseZones / nrtfoReverseZonesAndItems :
    //Trailing = Start.
    //-------------------------------------------------------------------------

    Case FFlowOrder Of
        nrtfoReverseZones, nrtfoReverseZonesAndItems:
            Result := FStartZone;
    Else
        Result := FEndZone;
    End;
End;

Function TNoReflowTabBarZoneLayoutGrid.WrapToFit(
    AAvailableWidth: Integer;
    AItemOverlap: Integer;
    ARowSpacing: Integer): Boolean;
Var
    LeadingZone:          TNoReflowTabBarZoneLayoutZone;
    TrailingZone:         TNoReflowTabBarZoneLayoutZone;
    LeadingState:         TNoReflowTabBarZoneState;
    TrailingState:        TNoReflowTabBarZoneState;
    LeadingMonoWidth:     Integer;
    TrailingMonoWidth:    Integer;
    LeadingMaxItemWidth:  Integer;
    CenterMaxItemWidth:   Integer;
    TrailingMaxItemWidth: Integer;
    SpacingWidth:         Integer;
    CenterTargetWidth:    Integer;
    TrailingTargetWidth:  Integer;
    LeadingTargetWidth:   Integer;
    CandidateZoneState:   TNoReflowTabBarZoneState;
Begin
    Result := False;

    If AAvailableWidth < 1 Then
        Exit;

    InitZoneStates(
        AItemOverlap,
        ARowSpacing);

    If GetGlobalWidth <= AAvailableWidth Then Begin
        ApplyStatesToZones;
        Result := True;
        Exit;
    End;

    LeadingZone := GetLeadingZone;
    TrailingZone := GetTrailingZone;

    //On copie les états réels dans des variables de travail logiques.
    //Les zones gardent leur identité réelle, mais la priorité de compactage
    //suit maintenant le flux logique choisi par BarFlowOrder.
    If LeadingZone = FStartZone Then
        LeadingState := FStartState
    Else
        LeadingState := FEndState;

    If TrailingZone = FStartZone Then
        TrailingState := FStartState
    Else
        TrailingState := FEndState;

    LeadingMonoWidth := LeadingZone.GetMonoColumnWidth(AItemOverlap);
    TrailingMonoWidth := TrailingZone.GetMonoColumnWidth(AItemOverlap);

    LeadingMaxItemWidth := LeadingZone.GetMaxItemWidth;
    CenterMaxItemWidth := FCenterZone.GetMaxItemWidth;
    TrailingMaxItemWidth := TrailingZone.GetMaxItemWidth;

    SpacingWidth := GetSpacingCount * FZoneSpacing;

    //------------------------------------------------------------------------------------------------
    //Première passe :
    //on garde une largeur mini esthétique au centre.
    //
    //La règle historique est conservée, mais exprimée en flux logique :
    //1) centre ;
    //2) zone de fin de flux ;
    //3) zone de début de flux.
    //
    //En ordre normal :
    //Center -> End -> Start.
    //
    //En ordre inversé :
    //Center -> Start -> End.
    //------------------------------------------------------------------------------------------------

    If HasCenter Then Begin
        CenterTargetWidth := AAvailableWidth - LeadingMonoWidth - TrailingMonoWidth - SpacingWidth;
        CenterTargetWidth := MaxIntLocal(
            CenterTargetWidth,
            CenterMaxItemWidth * CCenterMinWidthFactor);

        If FCenterZone.BuildSequentialStateForTargetWidth(CenterTargetWidth, AItemOverlap, ARowSpacing, CandidateZoneState) Then
            FCenterZone.CopyState(
                CandidateZoneState,
                FCenterState);

        If GetGlobalWidth <= AAvailableWidth Then Begin
            ApplyStatesToZones;
            Result := True;
            Exit;
        End;
    End;

    If TrailingZone.HasVisibleContent Then Begin
        TrailingTargetWidth := AAvailableWidth - LeadingMonoWidth - FCenterState.UsedWidth - SpacingWidth;
        TrailingTargetWidth := MaxIntLocal(
            TrailingTargetWidth,
            TrailingMaxItemWidth);

        If TrailingZone.BuildSequentialStateForTargetWidth(TrailingTargetWidth, AItemOverlap, ARowSpacing, CandidateZoneState) Then
            TrailingZone.CopyState(
                CandidateZoneState,
                TrailingState);

        If TrailingZone = FStartZone Then
            FStartState := TrailingState
        Else
            FEndState := TrailingState;

        If GetGlobalWidth <= AAvailableWidth Then Begin
            ApplyStatesToZones;
            Result := True;
            Exit;
        End;
    End;

    If LeadingZone.HasVisibleContent Then Begin
        If TrailingZone = FStartZone Then
            TrailingState := FStartState
        Else
            TrailingState := FEndState;

        LeadingTargetWidth := AAvailableWidth - FCenterState.UsedWidth - TrailingState.UsedWidth - SpacingWidth;
        LeadingTargetWidth := MaxIntLocal(
            LeadingTargetWidth,
            LeadingMaxItemWidth);

        If LeadingZone.BuildSequentialStateForTargetWidth(LeadingTargetWidth, AItemOverlap, ARowSpacing, CandidateZoneState) Then
            LeadingZone.CopyState(
                CandidateZoneState,
                LeadingState);

        If LeadingZone = FStartZone Then
            FStartState := LeadingState
        Else
            FEndState := LeadingState;

        If GetGlobalWidth <= AAvailableWidth Then Begin
            ApplyStatesToZones;
            Result := True;
            Exit;
        End;
    End;

    //------------------------------------------------------------------------------------------------
    //Deuxième passe :
    //si cela ne suffit pas, on relâche la contrainte esthétique du centre
    //et on l'autorise à descendre jusqu'à un item par column.
    //
    //On conserve le même ordre logique que dans la première passe.
    //------------------------------------------------------------------------------------------------

    If HasCenter Then Begin
        CenterTargetWidth := CenterMaxItemWidth;

        If FCenterZone.BuildSequentialStateForTargetWidth(CenterTargetWidth, AItemOverlap, ARowSpacing, CandidateZoneState) Then
            FCenterZone.CopyState(
                CandidateZoneState,
                FCenterState);
    End;

    If TrailingZone.HasVisibleContent Then Begin
        TrailingTargetWidth := AAvailableWidth - LeadingMonoWidth - FCenterState.UsedWidth - SpacingWidth;
        TrailingTargetWidth := MaxIntLocal(
            TrailingTargetWidth,
            TrailingMaxItemWidth);

        If TrailingZone.BuildSequentialStateForTargetWidth(TrailingTargetWidth, AItemOverlap, ARowSpacing, CandidateZoneState) Then
            TrailingZone.CopyState(
                CandidateZoneState,
                TrailingState);

        If TrailingZone = FStartZone Then
            FStartState := TrailingState
        Else
            FEndState := TrailingState;
    End;

    If LeadingZone.HasVisibleContent Then Begin
        If TrailingZone = FStartZone Then
            TrailingState := FStartState
        Else
            TrailingState := FEndState;

        LeadingTargetWidth := AAvailableWidth - FCenterState.UsedWidth - TrailingState.UsedWidth - SpacingWidth;
        LeadingTargetWidth := MaxIntLocal(
            LeadingTargetWidth,
            LeadingMaxItemWidth);

        If LeadingZone.BuildSequentialStateForTargetWidth(LeadingTargetWidth, AItemOverlap, ARowSpacing, CandidateZoneState) Then
            LeadingZone.CopyState(
                CandidateZoneState,
                LeadingState);

        If LeadingZone = FStartZone Then
            FStartState := LeadingState
        Else
            FEndState := LeadingState;
    End;

    ApplyStatesToZones;
    Result := GetGlobalWidth <= AAvailableWidth;
End;

Function TNoReflowTabBarZoneLayoutGrid.TotalWidth(ATabOverlap: Integer): Integer;
Begin
    Result := 0;

    If HasStart Then
        Inc(
            Result,
            FStartZone.GetAppliedZoneWidth(ATabOverlap));

    If HasCenter Then
        Inc(
            Result,
            FCenterZone.GetAppliedZoneWidth(ATabOverlap));

    If HasEnd Then
        Inc(
            Result,
            FEndZone.GetAppliedZoneWidth(ATabOverlap));

    Inc(
        Result,
        GetSpacingCount * FZoneSpacing);
End;

Function TNoReflowTabBarZoneLayoutGrid.TotalHeight(ARowSpacing: Integer): Integer;
Begin
    Result := 0;

    If HasStart Then
        Result := MaxIntLocal(
            Result,
            FStartZone.GetAppliedZoneHeight(ARowSpacing));

    If HasCenter Then
        Result := MaxIntLocal(
            Result,
            FCenterZone.GetAppliedZoneHeight(ARowSpacing));

    If HasEnd Then
        Result := MaxIntLocal(
            Result,
            FEndZone.GetAppliedZoneHeight(ARowSpacing));
End;

Class Function TNoReflowTabBarZoneLayoutEngine.TransformCanonicalPointToActual(
    Const P: TPoint;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    ABarPosition: TNoReflowTabBarPosition;
    AActualClientWidth: Integer;
    AActualClientHeight: Integer): TPoint;
Begin
    Case AFlowOrientation Of
        nrtzfoHorizontal: Begin
                Case ABarPosition Of
                    nrtbpTop:
                        Result := P;

                    nrtbpBottom:
                        Result := Point(P.X, AActualClientHeight - P.Y);
                Else
                    Result := P;
                End;
            End;

        nrtzfoVertical: Begin
                Case ABarPosition Of
                    nrtbpRight:
                        Result := Point(AActualClientWidth - P.Y, P.X);

                    nrtbpLeft:
                        Result := Point(P.Y, AActualClientHeight - P.X);
                Else
                    Result := P;
                End;
            End;
    Else
        Result := P;
    End;
End;

Class Function TNoReflowTabBarZoneLayoutEngine.TransformCanonicalDirectionToActual(
    Const ADirection: TPoint;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    ABarPosition: TNoReflowTabBarPosition): TPoint;
Begin
    Case AFlowOrientation Of
        nrtzfoHorizontal: Begin
                Case ABarPosition Of
                    nrtbpTop:
                        Result := ADirection;

                    nrtbpBottom:
                        Result := Point(ADirection.X, -ADirection.Y);
                Else
                    Result := ADirection;
                End;
            End;

        nrtzfoVertical: Begin
                Case ABarPosition Of
                    nrtbpRight:
                        //Rotation 90° horaire du repère canonique.
                        Result := Point(-ADirection.Y, ADirection.X);

                    nrtbpLeft:
                        //Rotation 90° anti-horaire du repère canonique.
                        //Donc une direction canonique +X devient visuellement vers le haut.
                        Result := Point(ADirection.Y, -ADirection.X);
                Else
                    Result := ADirection;
                End;
            End;
    Else
        Result := ADirection;
    End;
End;

Class Function TNoReflowTabBarZoneLayoutEngine.TransformActualPointToCanonical(
    Const P: TPoint;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    ABarPosition: TNoReflowTabBarPosition;
    AActualClientWidth: Integer;
    AActualClientHeight: Integer): TPoint;
Begin
    Case AFlowOrientation Of
        nrtzfoHorizontal: Begin
                Case ABarPosition Of
                    nrtbpTop:
                        Result := P;

                    nrtbpBottom:
                        Result := Point(P.X, AActualClientHeight - P.Y);
                Else
                    Result := P;
                End;
            End;

        nrtzfoVertical: Begin
                Case ABarPosition Of
                    nrtbpRight:
                        Result := Point(P.Y, AActualClientWidth - P.X);

                    nrtbpLeft:
                        Result := Point(AActualClientHeight - P.Y, P.X);
                Else
                    Result := P;
                End;
            End;
    Else
        Result := P;
    End;
End;

Class Function TNoReflowTabBarZoneLayoutEngine.TransformActualRectToCanonical(
    Const R: TRect;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    ABarPosition: TNoReflowTabBarPosition;
    AActualClientWidth: Integer;
    AActualClientHeight: Integer): TRect;
Var
    P1: TPoint;
    P2: TPoint;
Begin
    P1 := TransformActualPointToCanonical(
        Point(R.Left, R.Top),
        AFlowOrientation,
        ABarPosition,
        AActualClientWidth,
        AActualClientHeight);

    P2 := TransformActualPointToCanonical(
        Point(R.Right, R.Bottom),
        AFlowOrientation,
        ABarPosition,
        AActualClientWidth,
        AActualClientHeight);

    Result := Rect(
        Min(P1.X, P2.X),
        Min(P1.Y, P2.Y),
        Max(P1.X, P2.X),
        Max(P1.Y, P2.Y));
End;

Class Function TNoReflowTabBarZoneLayoutEngine.TryGetCanonicalZoneRect(
    AGrid: TNoReflowTabBarZoneLayoutGrid;
    APinZone: TNoReflowTabBarPinZone;
    AStartX: Integer;
    ACenterX: Integer;
    AEndX: Integer;
    ATopY: Integer;
    ATotalHeight: Integer;
    ATabOverlap: Integer;
    Out R: TRect): Boolean;
Var
    Zone:      TNoReflowTabBarZoneLayoutZone;
    ZoneX:     Integer;
    ZoneWidth: Integer;
Begin
    //-------------------------------------------------------------------------
    //Returns the canonical outer rectangle of a logical zone.
    //
    //This rectangle is also the reference width used by zone headers. It must
    //therefore match the applied layout width after wrapping and overlap/spacing
    //resolution, not an arbitrary sum of item widths.
    //
    //The rendering layer may ellipsize the header caption inside this width,
    //but it must not invent a wider header rectangle.
    //-------------------------------------------------------------------------
    Result := False;
    R := Rect(
        0,
        0,
        0,
        0);

    If AGrid = Nil Then
        Exit;

    Zone := AGrid.ZoneByPinZone[APinZone];
    If Zone = Nil Then
        Exit;

    If Not Zone.HasVisibleContent Then
        Exit;

    Case APinZone Of
        nrtpzStart:
            ZoneX := AStartX;

        nrtpzCenter:
            ZoneX := ACenterX;

        nrtpzEnd:
            ZoneX := AEndX;
    Else
        ZoneX := ACenterX;
    End;

    ZoneWidth := Zone.GetAppliedZoneWidth(ATabOverlap);
    If ZoneWidth <= 0 Then
        Exit;

    R := Rect(
        ZoneX,
        ATopY,
        ZoneX + ZoneWidth,
        ATopY + ATotalHeight);

    Result := True;
End;

Class Function TNoReflowTabBarZoneLayoutEngine.BuildCanonicalHeaderRect(
    Const ACanonicalZoneRect: TRect;
    AHeaderSize: Integer): TRect;
Begin
    //-------------------------------------------------------------------------
    //Builds a header rectangle from a canonical zone rectangle.
    //
    //The header keeps exactly the same left/right bounds as the zone. Caption
    //overflow is handled later by ellipsis in the rendering layer. Keeping this
    //function width-neutral avoids mismatches between zone layout and header
    //drawing.
    //-------------------------------------------------------------------------
    Result := Rect(
        ACanonicalZoneRect.Left,
        ACanonicalZoneRect.Top - AHeaderSize,
        ACanonicalZoneRect.Right,
        ACanonicalZoneRect.Top);
End;


//===============================================================================================================================
//TNoReflowTabBarZoneLayoutEngine - construction canonique
//===============================================================================================================================

Class Procedure TNoReflowTabBarZoneLayoutEngine.BuildCanonicalGridFromRenderItems(
    AGrid: TNoReflowTabBarZoneLayoutGrid;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    AFlowOrder: TNoReflowTabBarFlowOrder;
    Const ARenderItems: TArray<TNoReflowTabBarRenderItem>);
Var
    I:            Integer;
    LayoutItem:   TNoReflowTabBarZoneLayoutItem;
    PinZone:      TNoReflowTabBarPinZone;
    ItemWidth:    Integer;
    ItemHeight:   Integer;
    ReverseItems: Boolean;
Begin
    If AGrid = Nil Then
        Exit;

    AGrid.Clear;
    AGrid.FlowOrder := AFlowOrder;

    //L'inversion des items est volontairement séparée de l'inversion des zones.
    //
    //nrtfoReverseZones :
    //les zones changent d'ordre, mais chaque zone conserve son ordre naturel.
    //
    //nrtfoReverseZonesAndItems :
    //les zones changent d'ordre et les items sont relus à l'envers dans chaque
    //zone. Comme les items sont ensuite ajoutés à leur zone réelle, parcourir
    //ARenderItems à l'envers suffit à inverser l'ordre interne de chaque zone.
    ReverseItems := AFlowOrder = nrtfoReverseZonesAndItems;

    If ReverseItems Then
        I := High(ARenderItems)
    Else
        I := 0;

    While (I >= 0) And (I <= High(ARenderItems)) Do Begin
        If ARenderItems[I].Visible And (ARenderItems[I].Item <> Nil) Then Begin
            PinZone := ARenderItems[I].Item.PinZone;

            //Canonisation des dimensions :
            //- en horizontal, la métrique canonique reprend Width / Height
            //- en vertical, la dimension contrainte devient la hauteur réelle
            //et l'épaisseur devient la largeur réelle.
            If AFlowOrientation = nrtzfoHorizontal Then Begin
                ItemWidth := ARenderItems[I].Metrics.ButtonWidth;
                ItemHeight := ARenderItems[I].Metrics.ButtonHeight;
            End Else Begin
                ItemWidth := ARenderItems[I].Metrics.ButtonHeight;
                ItemHeight := ARenderItems[I].Metrics.ButtonWidth;
            End;

            LayoutItem := TNoReflowTabBarZoneLayoutItem.Create(
                I,
                ARenderItems[I].Item,
                PinZone,
                ItemWidth,
                ItemHeight);

            AGrid.ZoneByPinZone[PinZone].AddItem(LayoutItem);
        End;

        If ReverseItems Then
            Dec(I)
        Else
            Inc(I);
    End;
End;

Class Function TNoReflowTabBarZoneLayoutEngine.ResolveFlowStartOffset(
    ACanonicalClientWidth: Integer;
    AUsedBlockWidth: Integer;
    Const ALayout: TNoReflowTabBarLayout): Integer;
Var
    AvailableWidth: Integer;
    ExtraSpace:     Integer;
Begin
    //-------------------------------------------------------------------------
    //Calcule le point de départ réel du bloc complet dans l'axe principal.
    //
    //Le moteur de layout calcule d'abord la largeur nécessaire au bloc :
    //- zones Start / Center / End ;
    //- ZoneSpacing entre zones visibles ;
    //- recouvrement d'onglets ou espacement de boutons.
    //
    //Ensuite seulement, on décide où placer ce bloc dans l'espace disponible.
    //
    //Important :
    //MarginStart et MarginEnd restent des marges minimales.
    //FlowAlignment ne les remplace pas, il répartit seulement l'espace libre
    //restant entre ces deux marges.
    //-------------------------------------------------------------------------

    Result := ALayout.MarginStart;

    If ALayout = Nil Then
        Exit;

    AvailableWidth := ACanonicalClientWidth - ALayout.MarginStart - ALayout.MarginEnd;

    If AvailableWidth < 1 Then
        Exit;

    ExtraSpace := AvailableWidth - AUsedBlockWidth;

    If ExtraSpace < 0 Then
        ExtraSpace := 0;

    Case ALayout.FlowAlignment Of
        nrtfaCenter:
            Result := ALayout.MarginStart + (ExtraSpace Div 2);

        nrtfaEnd:
            Result := ALayout.MarginStart + ExtraSpace;
    Else
        Result := ALayout.MarginStart;
    End;
End;

Class Procedure TNoReflowTabBarZoneLayoutEngine.BuildSequentialRenderOrder(
    AFlowOrder: TNoReflowTabBarFlowOrder;
    Const ARenderItems: TArray<TNoReflowTabBarRenderItem>;
    Var AOrderedIndexes: TArray<Integer>);
Var
    StartIndexes:  TList<Integer>;
    CenterIndexes: TList<Integer>;
    EndIndexes:    TList<Integer>;
    I:             Integer;
    OutputIndex:   Integer;

    Procedure AddZoneIndexes(
        AList: TList<Integer>;
        AReverseItems: Boolean);
    Var
        J: Integer;
    Begin
        //---------------------------------------------------------------------
        //Ajoute les indices d'une zone dans le tableau de sortie.
        //
        //On ne copie pas les items eux-mêmes :
        //on conserve uniquement les indices réels dans ARenderItems.
        //---------------------------------------------------------------------

        If AList = Nil Then
            Exit;

        If AReverseItems Then Begin
            For J := AList.Count - 1 Downto 0 Do Begin
                AOrderedIndexes[OutputIndex] := AList[J];
                Inc(OutputIndex);
            End;
        End Else Begin
            For J := 0 To AList.Count - 1 Do Begin
                AOrderedIndexes[OutputIndex] := AList[J];
                Inc(OutputIndex);
            End;
        End;
    End;

Begin
    SetLength(
        AOrderedIndexes,
        0);

    StartIndexes := TList<Integer>.Create;
    CenterIndexes := TList<Integer>.Create;
    EndIndexes := TList<Integer>.Create;
    Try
        //---------------------------------------------------------------------
        //Première passe :
        //on regroupe les render items visibles par zone réelle.
        //
        //Les zones servent uniquement de critère de lecture logique.
        //La collection physique n'est jamais modifiée.
        //---------------------------------------------------------------------
        For I := 0 To High(ARenderItems) Do Begin
            If Not ARenderItems[I].Visible Then
                Continue;

            If ARenderItems[I].Item = Nil Then
                Continue;

            Case ARenderItems[I].Item.PinZone Of
                nrtpzStart:
                    StartIndexes.Add(I);

                nrtpzCenter:
                    CenterIndexes.Add(I);

                nrtpzEnd:
                    EndIndexes.Add(I);
            Else
                CenterIndexes.Add(I);
            End;
        End;

        SetLength(
            AOrderedIndexes,
            StartIndexes.Count + CenterIndexes.Count + EndIndexes.Count);

        OutputIndex := 0;

        //---------------------------------------------------------------------
        //Deuxième passe :
        //on expose au moteur séquentiel l'ordre logique demandé.
        //
        //nrtfoNormal :
        //Start -> Center -> End, items naturels.
        //
        //nrtfoReverseZones :
        //End -> Center -> Start, items naturels dans chaque zone.
        //
        //nrtfoReverseZonesAndItems :
        //End -> Center -> Start, items inversés dans chaque zone.
        //---------------------------------------------------------------------
        Case AFlowOrder Of
            nrtfoReverseZones: Begin
                    AddZoneIndexes(
                        EndIndexes,
                        False);
                    AddZoneIndexes(
                        CenterIndexes,
                        False);
                    AddZoneIndexes(
                        StartIndexes,
                        False);
                End;

            nrtfoReverseZonesAndItems: Begin
                    AddZoneIndexes(
                        EndIndexes,
                        True);
                    AddZoneIndexes(
                        CenterIndexes,
                        True);
                    AddZoneIndexes(
                        StartIndexes,
                        True);
                End;
        Else Begin
                AddZoneIndexes(
                    StartIndexes,
                    False);
                AddZoneIndexes(
                    CenterIndexes,
                    False);
                AddZoneIndexes(
                    EndIndexes,
                    False);
            End;
        End;
    Finally
        EndIndexes.Free;
        CenterIndexes.Free;
        StartIndexes.Free;
    End;
End;

Class Function TNoReflowTabBarZoneLayoutEngine.ResolveSequentialFlowOffset(
    ACanonicalClientWidth: Integer;
    ABlockWidth: Integer;
    Const ALayout: TNoReflowTabBarLayout): Integer;
Var
    AvailableWidth: Integer;
    ExtraSpace:     Integer;
Begin
    //-------------------------------------------------------------------------
    //Calcule le X de départ du bloc séquentiel complet.
    //
    //Le layout séquentiel construit d'abord ses lignes à partir de MarginStart,
    //comme historiquement. Ensuite, si FlowAlignment le demande, on translate
    //tout le bloc d'un même DeltaX.
    //
    //En multi-ligne, cela évite d'obtenir des lignes centrées séparément, ce qui
    //donnerait une barre visuellement instable.
    //-------------------------------------------------------------------------

    If ALayout = Nil Then Begin
        Result := 0;
        Exit;
    End;

    Result := ALayout.MarginStart;

    AvailableWidth := ACanonicalClientWidth - ALayout.MarginStart - ALayout.MarginEnd;

    If AvailableWidth < 1 Then
        Exit;

    ExtraSpace := AvailableWidth - ABlockWidth;

    If ExtraSpace < 0 Then
        ExtraSpace := 0;

    Case ALayout.FlowAlignment Of
        nrtfaCenter:
            Result := ALayout.MarginStart + (ExtraSpace Div 2);

        nrtfaEnd:
            Result := ALayout.MarginStart + ExtraSpace;
    Else
        Result := ALayout.MarginStart;
    End;
End;

Class Procedure TNoReflowTabBarZoneLayoutEngine.ComputeCanonicalZoneOrigins(
    AGrid: TNoReflowTabBarZoneLayoutGrid;
    AFlowOrder: TNoReflowTabBarFlowOrder;
    AMarginLeft: Integer;
    ATabOverlap: Integer;
    Out AStartX: Integer;
    Out ACenterX: Integer;
    Out AEndX: Integer);
Var
    CurrentX:        Integer;
    ZoneIndex:       Integer;
    PinZone:         TNoReflowTabBarPinZone;
    Zone:            TNoReflowTabBarZoneLayoutZone;
    ZoneWidth:       Integer;
    HasPreviousZone: Boolean;
    OrderedZones:    Array [0 .. 2] Of TNoReflowTabBarPinZone;
Begin
    //-------------------------------------------------------------------------
    //Calcule l'origine canonique de chaque zone réelle.
    //
    //Important :
    //les variables de sortie restent attachées aux zones réelles :
    //- AStartX  correspond toujours à nrtpzStart ;
    //- ACenterX correspond toujours à nrtpzCenter ;
    //- AEndX    correspond toujours à nrtpzEnd.
    //
    //Seul l'ordre dans lequel ces zones sont posées dans le flux canonique
    //change selon AFlowOrder.
    //-------------------------------------------------------------------------

    AStartX := AMarginLeft;
    ACenterX := AMarginLeft;
    AEndX := AMarginLeft;

    Case AFlowOrder Of
        nrtfoReverseZones, nrtfoReverseZonesAndItems: Begin
                OrderedZones[0] := nrtpzEnd;
                OrderedZones[1] := nrtpzCenter;
                OrderedZones[2] := nrtpzStart;
            End;
    Else Begin
            OrderedZones[0] := nrtpzStart;
            OrderedZones[1] := nrtpzCenter;
            OrderedZones[2] := nrtpzEnd;
        End;
    End;

    CurrentX := AMarginLeft;
    HasPreviousZone := False;

    For ZoneIndex := Low(OrderedZones) To High(OrderedZones) Do Begin
        PinZone := OrderedZones[ZoneIndex];
        Zone := AGrid.ZoneByPinZone[PinZone];

        If (Zone = Nil) Or (Not Zone.HasVisibleContent) Then
            Continue;

        If HasPreviousZone Then
            Inc(
                CurrentX,
                AGrid.ZoneSpacing);

        Case PinZone Of
            nrtpzStart:
                AStartX := CurrentX;

            nrtpzCenter:
                ACenterX := CurrentX;

            nrtpzEnd:
                AEndX := CurrentX;
        End;

        ZoneWidth := Zone.GetAppliedZoneWidth(ATabOverlap);

        Inc(
            CurrentX,
            ZoneWidth);

        HasPreviousZone := True;
    End;
End;

Class Procedure TNoReflowTabBarZoneLayoutEngine.ApplyCanonicalZoneLayout(
    AZone: TNoReflowTabBarZoneLayoutZone;
    AZoneX: Integer;
    AZoneY: Integer;
    ATotalHeight: Integer;
    ATabOverlap: Integer;
    ARowSpacing: Integer;
    Var ARenderItems: TArray<TNoReflowTabBarRenderItem>);
Var
    ColumnIndex:  Integer;
    MaxColumn:    Integer;
    ZoneWidth:    Integer;
    ZoneHeight:   Integer;
    ColumnWidth:  Integer;
    ColumnHeight: Integer;
    CurrentY:     Integer;
    CurrentX:     Integer;
    ColumnStartX: Integer;
    ItemIndex:    Integer;
    R:            TRect;
    AlignMode:    TNoReflowTabBarZoneColumnAlign;
    ItemWidth:    Integer;
Begin
    If AZone = Nil Then
        Exit;

    If Not AZone.HasVisibleContent Then
        Exit;

    ZoneWidth := AZone.GetAppliedZoneWidth(ATabOverlap);
    ZoneHeight := AZone.GetAppliedZoneHeight(ARowSpacing);
    MaxColumn := AZone.GetAppliedMaxColumnIndex;
    AlignMode := AZone.GetDefaultColumnAlign;

    //Alignement de la Zone entière sur le bord INTERNE dans le repère canonique top :
    //la Zone est posée en bas de la hauteur totale utilisée.
    CurrentY := AZoneY + (ATotalHeight - ZoneHeight);

    For ColumnIndex := 0 To MaxColumn Do Begin
        ColumnWidth := 0;
        ColumnHeight := 0;

        For ItemIndex := 0 To AZone.Count - 1 Do Begin
            If AZone.Items[ItemIndex].ColumnIndex <> ColumnIndex Then
                Continue;

            If ColumnWidth = 0 Then
                ColumnWidth := AZone.Items[ItemIndex].Width
            Else
                ColumnWidth := ColumnWidth + AZone.Items[ItemIndex].Width - ATabOverlap;

            If AZone.Items[ItemIndex].Height > ColumnHeight Then
                ColumnHeight := AZone.Items[ItemIndex].Height;
        End;

        Case AlignMode Of
            nrtzcaStart:
                ColumnStartX := AZoneX;
            nrtzcaCenter:
                ColumnStartX := AZoneX + ((ZoneWidth - ColumnWidth) Div 2);
            nrtzcaEnd:
                ColumnStartX := AZoneX + (ZoneWidth - ColumnWidth);
        Else
            ColumnStartX := AZoneX;
        End;

        CurrentX := ColumnStartX;

        For ItemIndex := 0 To AZone.Count - 1 Do Begin
            If AZone.Items[ItemIndex].ColumnIndex <> ColumnIndex Then
                Continue;

            ItemWidth := AZone.Items[ItemIndex].Width;

            R := Rect(
                CurrentX,
                CurrentY + ColumnHeight - AZone.Items[ItemIndex].Height,
                CurrentX + ItemWidth,
                CurrentY + ColumnHeight);

            ARenderItems[AZone.Items[ItemIndex].RenderIndex].Bounds := R;

            CurrentX := CurrentX + ItemWidth - ATabOverlap;
        End;

        Inc(
            CurrentY,
            ColumnHeight);

        If ColumnIndex < MaxColumn Then
            Inc(
                CurrentY,
                ARowSpacing);
    End;
End;

//===============================================================================================================================
//TNoReflowTabBarZoneLayoutEngine - projection canonique -> réel
//===============================================================================================================================

Class Function TNoReflowTabBarZoneLayoutEngine.TransformCanonicalRectToActual(
    Const R: TRect;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    ABarPosition: TNoReflowTabBarPosition;
    AActualClientWidth: Integer;
    AActualClientHeight: Integer): TRect;
Begin
    Case AFlowOrientation Of
        nrtzfoHorizontal: Begin
                //En horizontal, le repère canonique correspond à TOP.
                //BOTTOM est une simple symétrie verticale.
                Case ABarPosition Of
                    nrtbpTop:
                        Result := R;

                    nrtbpBottom:
                        Result := Rect(R.Left, AActualClientHeight - R.Bottom, R.Right, AActualClientHeight - R.Top);
                Else
                    Result := R;
                End;
            End;

        nrtzfoVertical: Begin
                //En vertical, le repère canonique a :
                //- largeur canonique = hauteur réelle
                //- hauteur canonique = largeur réelle
                //
                //RIGHT = rotation 90° horaire
                //LEFT  = rotation 90° anti-horaire

                Case ABarPosition Of
                    nrtbpRight:
                        Result := Rect(AActualClientWidth - R.Bottom, R.Left, AActualClientWidth - R.Top, R.Right);

                    nrtbpLeft:
                        Result := Rect(R.Top, AActualClientHeight - R.Right, R.Bottom, AActualClientHeight - R.Left);
                Else
                    Result := R;
                End;
            End;
    Else
        Result := R;
    End;
End;

Class Function TNoReflowTabBarZoneLayoutEngine.GetCanonicalZoneFirstRowTop(
    AZone: TNoReflowTabBarZoneLayoutZone;
    AZoneY: Integer;
    ATotalHeight: Integer;
    ARowSpacing: Integer): Integer;
Var
    ZoneHeight: Integer;
Begin
    Result := AZoneY;

    If AZone = Nil Then
        Exit;

    If Not AZone.HasVisibleContent Then
        Exit;

    ZoneHeight := AZone.GetAppliedZoneHeight(ARowSpacing);

    //En repère canonique TOP, la zone est alignée sur le bas
    //de la hauteur totale utilisée. La première ligne visible
    //commence donc ici.
    Result := AZoneY + (ATotalHeight - ZoneHeight);
End;

Class Procedure TNoReflowTabBarZoneLayoutEngine.TransformAllCanonicalRectsToActual(
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    ABarPosition: TNoReflowTabBarPosition;
    AActualClientWidth: Integer;
    AActualClientHeight: Integer;
    Var ARenderItems: TArray<TNoReflowTabBarRenderItem>);
Var
    I: Integer;
Begin
    For I := 0 To High(ARenderItems) Do Begin
        If Not ARenderItems[I].Visible Then
            Continue;

        ARenderItems[I].Bounds := TransformCanonicalRectToActual(
            ARenderItems[I].Bounds,
            AFlowOrientation,
            ABarPosition,
            AActualClientWidth,
            AActualClientHeight);
    End;
End;

//===============================================================================================================================
//TNoReflowTabBarZoneLayoutEngine - calcul principal
//===============================================================================================================================

Class Procedure TNoReflowTabBarZoneLayoutEngine.BuildZoneLayoutCanonical(
    ACanonicalClientWidth: Integer;
    AActualClientWidth: Integer;
    AActualClientHeight: Integer;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    ABarPosition: TNoReflowTabBarPosition;
    ABarMode: TNoReflowTabBarMode;
    AFlowOrder: TNoReflowTabBarFlowOrder;
    Const ALayout: TNoReflowTabBarLayout;
    Const ATabLayout: TNoReflowTabBarLayoutTabs;
    Const AButtonLayout: TNoReflowTabBarLayoutButtons;
    Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
    Out UsedPrimarySize: Integer;
    Out UsedSecondarySize: Integer;
    Out ALayoutInfo: TNoReflowTabBarZoneLayoutInfo);
Var
    Grid:           TNoReflowTabBarZoneLayoutGrid;
    AvailableWidth: Integer;
    FlowStartX:     Integer;
    StartX:         Integer;
    CenterX:        Integer;
    EndX:           Integer;
    I:              Integer;
    TotalHeight:    Integer;
    ItemOverlap:    Integer;
Begin
    //-------------------------------------------------------------------------
    //Construit le layout complet dans le repère canonique TOP.
    //
    //Le moteur travaille volontairement avec une notion générique d'overlap :
    //
    //- en mode onglets :
    //ItemOverlap = BarLayoutTabs.TabOverlap ;
    //les items peuvent donc se recouvrir.
    //
    //- en mode boutons :
    //ItemOverlap = -BarLayoutButtons.ButtonSpacing ;
    //la formule historique "position + taille - overlap" devient alors
    //"position + taille + spacing".
    //
    //Cette convention permet de conserver l'algorithme existant sans créer
    //deux moteurs de layout parallèles.
    //-------------------------------------------------------------------------
    UsedPrimarySize := 0;
    UsedSecondarySize := 0;
    ALayoutInfo.Init;

    If Length(ARenderItems) = 0 Then
        Exit;

    ItemOverlap := ResolveItemOverlap(
        ABarMode,
        ATabLayout,
        AButtonLayout);

    Grid := TNoReflowTabBarZoneLayoutGrid.Create;
    Try
        Grid.ZoneSpacing := ALayout.ZoneSpacing;

        BuildCanonicalGridFromRenderItems(
            Grid,
            AFlowOrientation,
            AFlowOrder,
            ARenderItems);

        AvailableWidth := ACanonicalClientWidth - ALayout.MarginStart - ALayout.MarginEnd;
        If AvailableWidth < 1 Then
            Exit;

        Grid.WrapToFit(
            AvailableWidth,
            ItemOverlap,
            ALayout.RowSpacing);

        TotalHeight := Grid.TotalHeight(ALayout.RowSpacing);

        //-------------------------------------------------------------------------
        //Position de départ effective du bloc complet.
        //
        //Historiquement, le bloc démarrait toujours à MarginStart.
        //FlowAlignment permet maintenant de conserver ce comportement ou de
        //centrer / aligner à la fin le bloc complet dans l'espace disponible.
        //
        //Le calcul utilise la largeur appliquée réelle de la grille après
        //WrapToFit, afin de tenir compte :
        //- des lignes créées ;
        //- des zones visibles ;
        //- du recouvrement des onglets ;
        //- de l'espacement des boutons.
        //-------------------------------------------------------------------------
        FlowStartX := ResolveFlowStartOffset(
            ACanonicalClientWidth,
            Grid.TotalWidth(ItemOverlap),
            ALayout);

        ComputeCanonicalZoneOrigins(
            Grid,
            AFlowOrder,
            FlowStartX,
            ItemOverlap,
            StartX,
            CenterX,
            EndX);

        If TryGetCanonicalZoneRect(Grid, nrtpzStart, StartX, CenterX, EndX, ALayout.MarginFirstRow, TotalHeight, ItemOverlap, ALayoutInfo.StartZone.OuterCanonicalRect) Then
            ALayoutInfo.StartZone.HasZone := True;

        If TryGetCanonicalZoneRect(Grid, nrtpzCenter, StartX, CenterX, EndX, ALayout.MarginFirstRow, TotalHeight, ItemOverlap, ALayoutInfo.CenterZone.OuterCanonicalRect) Then
            ALayoutInfo.CenterZone.HasZone := True;

        If TryGetCanonicalZoneRect(Grid, nrtpzEnd, StartX, CenterX, EndX, ALayout.MarginFirstRow, TotalHeight, ItemOverlap, ALayoutInfo.EndZone.OuterCanonicalRect) Then
            ALayoutInfo.EndZone.HasZone := True;

        If ALayoutInfo.StartZone.HasZone Then
            ALayoutInfo.StartZone.FirstRowCanonicalTop := GetCanonicalZoneFirstRowTop(
                Grid.StartZone,
                ALayout.MarginFirstRow,
                TotalHeight,
                ALayout.RowSpacing);

        If ALayoutInfo.CenterZone.HasZone Then
            ALayoutInfo.CenterZone.FirstRowCanonicalTop := GetCanonicalZoneFirstRowTop(
                Grid.CenterZone,
                ALayout.MarginFirstRow,
                TotalHeight,
                ALayout.RowSpacing);

        If ALayoutInfo.EndZone.HasZone Then
            ALayoutInfo.EndZone.FirstRowCanonicalTop := GetCanonicalZoneFirstRowTop(
                Grid.EndZone,
                ALayout.MarginFirstRow,
                TotalHeight,
                ALayout.RowSpacing);

        For I := 0 To High(ARenderItems) Do
            If Not ARenderItems[I].Visible Then
                ARenderItems[I].Bounds := Rect(
                    0,
                    0,
                    0,
                    0);

        ApplyCanonicalZoneLayout(
            Grid.StartZone,
            StartX,
            ALayout.MarginFirstRow,
            TotalHeight,
            ItemOverlap,
            ALayout.RowSpacing,
            ARenderItems);

        ApplyCanonicalZoneLayout(
            Grid.CenterZone,
            CenterX,
            ALayout.MarginFirstRow,
            TotalHeight,
            ItemOverlap,
            ALayout.RowSpacing,
            ARenderItems);

        ApplyCanonicalZoneLayout(
            Grid.EndZone,
            EndX,
            ALayout.MarginFirstRow,
            TotalHeight,
            ItemOverlap,
            ALayout.RowSpacing,
            ARenderItems);

        TransformAllCanonicalRectsToActual(
            AFlowOrientation,
            ABarPosition,
            AActualClientWidth,
            AActualClientHeight,
            ARenderItems);


        //-------------------------------------------------------------------------
        //Encombrement logique retourné au composant.
        //
        //Important :
        //il ne faut pas recalculer la taille utilisée à partir de la boîte
        //englobante des Bounds déjà projetés.
        //
        //Pourquoi ?
        //Les items sont volontairement posés à partir de MarginFirstRow dans le
        //repère canonique. Si on calcule ensuite :
        //
        //UsedHeight = MaxBottom - MinTop
        //
        //on perd cette marge de première ligne, puisque MinTop vaut justement
        //MarginFirstRow.
        //
        //Conséquence visible :
        //- les métriques internes de l'item sont bonnes ;
        //- TextSpaceOver / TextSpaceUnder sont bien présents ;
        //- mais la taille totale du contrôle est trop petite ;
        //- la dernière ligne est alors coupée contre la frontière du composant.
        //
        //La source de vérité est donc le layout canonique :
        //- Primary   = longueur utilisée dans l'axe du flux ;
        //- Secondary = épaisseur totale de la barre.
        //
        //MarginStart / MarginEnd appartiennent à l'axe primaire.
        //MarginFirstRow appartient à l'axe secondaire.
        //-------------------------------------------------------------------------
        UsedPrimarySize := FlowStartX + Grid.TotalWidth(ItemOverlap) + ALayout.MarginEnd;
        UsedSecondarySize := ALayout.MarginFirstRow + TotalHeight;
    Finally Grid.Free;
    End;
End;

Class Procedure TNoReflowTabBarZoneLayoutEngine.BuildSequentialLayoutCanonical(
    ACanonicalClientWidth: Integer;
    AActualClientWidth: Integer;
    AActualClientHeight: Integer;
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    ABarPosition: TNoReflowTabBarPosition;
    ABarMode: TNoReflowTabBarMode;
    AFlowOrder: TNoReflowTabBarFlowOrder;
    Const ALayout: TNoReflowTabBarLayout;
    Const ATabLayout: TNoReflowTabBarLayoutTabs;
    Const AButtonLayout: TNoReflowTabBarLayoutButtons;
    Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
    Out UsedPrimarySize: Integer;
    Out UsedSecondarySize: Integer);
Var
    I:                Integer;
    K:                Integer;
    OrderedIndex:     Integer;
    OrderedIndexes:   TArray<Integer>;
    ItemWidth:        Integer;
    ItemHeight:       Integer;
    CurrentZone:      TNoReflowTabBarPinZone;
    PrevZone:         TNoReflowTabBarPinZone;
    ZoneChanged:      Boolean;
    IsFirstInLine:    Boolean;
    LineStart:        Integer;
    LineEnd:          Integer;
    LineExtent:       Integer;
    PrevVisibleIndex: Integer;
    X:                Integer;
    Y:                Integer;
    NextX:            Integer;
    TempX:            Integer;
    ItemOverlap:      Integer;
    R:                TRect;
    TotalHeight:      Integer;
    MaxLineRight:     Integer;
    HasVisibleItem:   Boolean;
    BlockWidth:       Integer;
    FlowStartX:       Integer;
    DeltaX:           Integer;
Begin
    //-------------------------------------------------------------------------
    //Construit le layout séquentiel dans le même repère canonique TOP que le
    //moteur par zones.
    //
    //Le mode séquentiel profite maintenant des deux propriétés globales :
    //
    //- BarFlowOrder :
    //ne modifie pas la collection, mais change l'ordre logique dans lequel
    //les render items sont présentés à l'algorithme séquentiel.
    //
    //- BarLayout.FlowAlignment :
    //ne change pas le wrapping. Le layout est d'abord calculé normalement à
    //partir de MarginStart, puis le bloc complet est déplacé globalement.
    //
    //En cas de multi-ligne, toutes les lignes sont déplacées ensemble.
    //Les lignes ne sont donc pas centrées ou alignées individuellement.
    //-------------------------------------------------------------------------
    UsedPrimarySize := 0;
    UsedSecondarySize := 0;

    If Length(ARenderItems) = 0 Then
        Exit;

    ItemOverlap := ResolveItemOverlap(
        ABarMode,
        ATabLayout,
        AButtonLayout);

    For I := 0 To High(ARenderItems) Do Begin
        If Not ARenderItems[I].Visible Then
            ARenderItems[I].Bounds := Rect(
                0,
                0,
                0,
                0);
    End;

    BuildSequentialRenderOrder(
        AFlowOrder,
        ARenderItems,
        OrderedIndexes);

    If Length(OrderedIndexes) = 0 Then Begin
        UsedPrimarySize := ALayout.MarginStart + ALayout.MarginEnd;
        UsedSecondarySize := ALayout.MarginFirstRow;
        Exit;
    End;

    X := ALayout.MarginStart;
    Y := ALayout.MarginFirstRow;
    MaxLineRight := ALayout.MarginStart;
    HasVisibleItem := False;

    If (ACanonicalClientWidth - ALayout.MarginEnd) < 20 Then
        Exit;

    OrderedIndex := 0;

    While OrderedIndex < Length(OrderedIndexes) Do Begin
        LineStart := OrderedIndex;
        LineEnd := OrderedIndex - 1;
        LineExtent := 0;
        TempX := X;
        IsFirstInLine := True;
        PrevZone := nrtpzCenter;
        PrevVisibleIndex := -1;

        //---------------------------------------------------------------------
        //Première passe de ligne :
        //on détermine jusqu'où la ligne peut aller dans l'ordre logique fourni
        //par OrderedIndexes.
        //---------------------------------------------------------------------
        While OrderedIndex < Length(OrderedIndexes) Do Begin
            I := OrderedIndexes[OrderedIndex];

            If Not ARenderItems[I].Visible Then Begin
                Inc(OrderedIndex);
                Continue;
            End;

            If ARenderItems[I].Item = Nil Then Begin
                Inc(OrderedIndex);
                Continue;
            End;

            If AFlowOrientation = nrtzfoHorizontal Then Begin
                ItemWidth := ARenderItems[I].Metrics.ButtonWidth;
                ItemHeight := ARenderItems[I].Metrics.ButtonHeight;
            End Else Begin
                ItemWidth := ARenderItems[I].Metrics.ButtonHeight;
                ItemHeight := ARenderItems[I].Metrics.ButtonWidth;
            End;

            CurrentZone := ARenderItems[I].Item.PinZone;

            If IsFirstInLine Then Begin
                NextX := TempX;
                ZoneChanged := False;
            End Else Begin
                ZoneChanged := CurrentZone <> PrevZone;

                If ZoneChanged Then
                    NextX := TempX + ALayout.ZoneSpacing
                Else
                    NextX := TempX - ItemOverlap;
            End;

            If (Not IsFirstInLine) And (NextX + ItemWidth > ACanonicalClientWidth - ALayout.MarginEnd) Then
                Break;

            TempX := NextX + ItemWidth;

            If ItemHeight > LineExtent Then
                LineExtent := ItemHeight;

            LineEnd := OrderedIndex;
            PrevVisibleIndex := I;
            PrevZone := CurrentZone;
            IsFirstInLine := False;

            Inc(OrderedIndex);
        End;

        //---------------------------------------------------------------------
        //Sécurité :
        //si aucun item n'a été accepté dans la ligne, on consomme au moins un
        //indice pour éviter toute boucle infinie sur un item très large.
        //---------------------------------------------------------------------
        If LineEnd < LineStart Then Begin
            If OrderedIndex < Length(OrderedIndexes) Then
                Inc(OrderedIndex);

            Continue;
        End;

        TempX := X;
        PrevZone := nrtpzCenter;
        PrevVisibleIndex := -1;

        //---------------------------------------------------------------------
        //Deuxième passe de ligne :
        //on pose réellement les rectangles dans les render items d'origine.
        //
        //K parcourt ici les positions dans OrderedIndexes, pas les index réels
        //du tableau ARenderItems.
        //---------------------------------------------------------------------
        For K := LineStart To LineEnd Do Begin
            I := OrderedIndexes[K];

            If Not ARenderItems[I].Visible Then
                Continue;

            If ARenderItems[I].Item = Nil Then
                Continue;

            If AFlowOrientation = nrtzfoHorizontal Then Begin
                ItemWidth := ARenderItems[I].Metrics.ButtonWidth;
                ItemHeight := ARenderItems[I].Metrics.ButtonHeight;
            End Else Begin
                ItemWidth := ARenderItems[I].Metrics.ButtonHeight;
                ItemHeight := ARenderItems[I].Metrics.ButtonWidth;
            End;

            CurrentZone := ARenderItems[I].Item.PinZone;

            If PrevVisibleIndex < 0 Then
                NextX := TempX
            Else Begin
                ZoneChanged := CurrentZone <> PrevZone;

                If ZoneChanged Then
                    NextX := TempX + ALayout.ZoneSpacing
                Else
                    NextX := TempX - ItemOverlap;
            End;

            R := Rect(
                NextX,
                Y + LineExtent - ItemHeight,
                NextX + ItemWidth,
                Y + LineExtent);

            ARenderItems[I].Bounds := R;

            TempX := NextX + ItemWidth;
            PrevVisibleIndex := I;
            PrevZone := CurrentZone;
            HasVisibleItem := True;
        End;

        If TempX > MaxLineRight Then
            MaxLineRight := TempX;

        X := ALayout.MarginStart;
        Inc(
            Y,
            LineExtent + ALayout.RowSpacing);
    End;

    TotalHeight := Y - ALayout.RowSpacing;

    If TotalHeight < ALayout.MarginFirstRow Then
        TotalHeight := ALayout.MarginFirstRow;

    //---------------------------------------------------------------------
    //Application de FlowAlignment.
    //
    //On aligne le bloc global calculé entre MarginStart et MarginEnd.
    //Le wrapping reste celui calculé depuis MarginStart, ce qui évite de
    //changer la composition des lignes lorsque l'utilisateur change seulement
    //l'alignement.
    //---------------------------------------------------------------------
    If HasVisibleItem Then Begin
        BlockWidth := MaxLineRight - ALayout.MarginStart;

        If BlockWidth < 0 Then
            BlockWidth := 0;

        FlowStartX := ResolveSequentialFlowOffset(
            ACanonicalClientWidth,
            BlockWidth,
            ALayout);

        DeltaX := FlowStartX - ALayout.MarginStart;

        If DeltaX <> 0 Then Begin
            For I := 0 To High(ARenderItems) Do Begin
                If Not ARenderItems[I].Visible Then
                    Continue;

                If IsRectEmpty(ARenderItems[I].Bounds) Then
                    Continue;

                OffsetRect(
                    ARenderItems[I].Bounds,
                    DeltaX,
                    0);
            End;
        End;

        UsedPrimarySize := FlowStartX + BlockWidth + ALayout.MarginEnd;
    End
    Else
        UsedPrimarySize := ALayout.MarginStart + ALayout.MarginEnd;

    UsedSecondarySize := TotalHeight;

    TransformAllCanonicalRectsToActual(
        AFlowOrientation,
        ABarPosition,
        AActualClientWidth,
        AActualClientHeight,
        ARenderItems);
End;

Class Procedure TNoReflowTabBarZoneLayoutEngine.ComputeUsedSizesFromBounds(
    AFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
    Const ARenderItems: TArray<TNoReflowTabBarRenderItem>;
    Out UsedPrimarySize: Integer;
    Out UsedSecondarySize: Integer);
Var
    I:           Integer;
    LMinLeft:    Integer;
    LMinTop:     Integer;
    LMaxRight:   Integer;
    LMaxBottom:  Integer;
    LHasVisible: Boolean;
    LUsedWidth:  Integer;
    LUsedHeight: Integer;
Begin
    //-------------------------------------------------------------------------
    //Calcule l'encombrement réellement occupé par les rectangles visibles.
    //
    //Important :
    //on ne se contente pas de prendre Max(Right) / Max(Bottom), car ce serait
    //faux pour les barres Bottom ou Right lorsque les rectangles sont projetés
    //près du bord opposé du contrôle.
    //
    //On calcule donc une vraie boîte englobante :
    //- largeur utilisée = MaxRight - MinLeft
    //- hauteur utilisée = MaxBottom - MinTop
    //
    //Cela rend le calcul indépendant du côté auquel les items sont collés.
    //-------------------------------------------------------------------------
    UsedPrimarySize := 0;
    UsedSecondarySize := 0;

    LHasVisible := False;

    LMinLeft := 0;
    LMinTop := 0;
    LMaxRight := 0;
    LMaxBottom := 0;

    For I := 0 To High(ARenderItems) Do Begin
        If Not ARenderItems[I].Visible Then
            Continue;

        If IsRectEmpty(ARenderItems[I].Bounds) Then
            Continue;

        If Not LHasVisible Then Begin
            LMinLeft := ARenderItems[I].Bounds.Left;
            LMinTop := ARenderItems[I].Bounds.Top;
            LMaxRight := ARenderItems[I].Bounds.Right;
            LMaxBottom := ARenderItems[I].Bounds.Bottom;
            LHasVisible := True;
        End Else Begin
            If ARenderItems[I].Bounds.Left < LMinLeft Then
                LMinLeft := ARenderItems[I].Bounds.Left;

            If ARenderItems[I].Bounds.Top < LMinTop Then
                LMinTop := ARenderItems[I].Bounds.Top;

            If ARenderItems[I].Bounds.Right > LMaxRight Then
                LMaxRight := ARenderItems[I].Bounds.Right;

            If ARenderItems[I].Bounds.Bottom > LMaxBottom Then
                LMaxBottom := ARenderItems[I].Bounds.Bottom;
        End;
    End;

    If Not LHasVisible Then
        Exit;

    LUsedWidth := LMaxRight - LMinLeft;
    LUsedHeight := LMaxBottom - LMinTop;

    If LUsedWidth < 0 Then
        LUsedWidth := 0;

    If LUsedHeight < 0 Then
        LUsedHeight := 0;

    Case AFlowOrientation Of
        nrtzfoHorizontal: Begin
                //Barre Top / Bottom :
                //Primary = largeur, Secondary = hauteur.
                UsedPrimarySize := LUsedWidth;
                UsedSecondarySize := LUsedHeight;
            End;

        nrtzfoVertical: Begin
                //Barre Left / Right :
                //Primary = hauteur, Secondary = largeur.
                UsedPrimarySize := LUsedHeight;
                UsedSecondarySize := LUsedWidth;
            End;
    Else Begin
            UsedPrimarySize := LUsedWidth;
            UsedSecondarySize := LUsedHeight;
        End;
    End;
End;

//===============================================================================================================================
//Entrées publiques
//===============================================================================================================================

Class Procedure TNoReflowTabBarZoneLayoutEngine.BuildHorizontalZoneLayout(
    AClientWidth: Integer;
    AClientHeight: Integer;
    ABarPosition: TNoReflowTabBarPosition;
    ABarMode: TNoReflowTabBarMode;
    AFlowOrder: TNoReflowTabBarFlowOrder;
    Const ALayout: TNoReflowTabBarLayout;
    Const ATabLayout: TNoReflowTabBarLayoutTabs;
    Const AButtonLayout: TNoReflowTabBarLayoutButtons;
    Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
    Out UsedPrimarySize: Integer;
    Out UsedSecondarySize: Integer;
    Out ALayoutInfo: TNoReflowTabBarZoneLayoutInfo);
Begin
    //-------------------------------------------------------------------------
    //Entrée publique pour les barres Top / Bottom.
    //
    //Dans ce cas, le repère canonique TOP a la même largeur que le client réel.
    //
    //AFlowOrder est transmis au moteur canonique afin de modifier l'ordre
    //logique des zones et, éventuellement, des items, sans toucher aux
    //transformations géométriques finales.
    //-------------------------------------------------------------------------
    BuildZoneLayoutCanonical(
        AClientWidth,
        AClientWidth,
        AClientHeight,
        nrtzfoHorizontal,
        ABarPosition,
        ABarMode,
        AFlowOrder,
        ALayout,
        ATabLayout,
        AButtonLayout,
        ARenderItems,
        UsedPrimarySize,
        UsedSecondarySize,
        ALayoutInfo);
End;

Class Procedure TNoReflowTabBarZoneLayoutEngine.BuildVerticalZoneLayout(
    AClientWidth: Integer;
    AClientHeight: Integer;
    ABarPosition: TNoReflowTabBarPosition;
    ABarMode: TNoReflowTabBarMode;
    AFlowOrder: TNoReflowTabBarFlowOrder;
    Const ALayout: TNoReflowTabBarLayout;
    Const ATabLayout: TNoReflowTabBarLayoutTabs;
    Const AButtonLayout: TNoReflowTabBarLayoutButtons;
    Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
    Out UsedPrimarySize: Integer;
    Out UsedSecondarySize: Integer;
    Out ALayoutInfo: TNoReflowTabBarZoneLayoutInfo);
Begin
    //-------------------------------------------------------------------------
    //Entrée publique pour les barres Left / Right.
    //
    //En vertical, le moteur canonique travaille dans un espace tourné :
    //- largeur canonique = hauteur réelle du client ;
    //- hauteur canonique = largeur réelle du client.
    //
    //AFlowOrder reste volontairement appliqué avant projection géométrique.
    //Cela permet d'inverser le flux logique sans toucher aux conversions
    //Left / Right déjà utilisées par le rendu, le hit-test et le drag.
    //-------------------------------------------------------------------------
    BuildZoneLayoutCanonical(
        AClientHeight,
        AClientWidth,
        AClientHeight,
        nrtzfoVertical,
        ABarPosition,
        ABarMode,
        AFlowOrder,
        ALayout,
        ATabLayout,
        AButtonLayout,
        ARenderItems,
        UsedPrimarySize,
        UsedSecondarySize,
        ALayoutInfo);
End;

Class Procedure TNoReflowTabBarZoneLayoutEngine.BuildHorizontalSequentialLayout(
    AClientWidth: Integer;
    AClientHeight: Integer;
    ABarPosition: TNoReflowTabBarPosition;
    ABarMode: TNoReflowTabBarMode;
    AFlowOrder: TNoReflowTabBarFlowOrder;
    Const ALayout: TNoReflowTabBarLayout;
    Const ATabLayout: TNoReflowTabBarLayoutTabs;
    Const AButtonLayout: TNoReflowTabBarLayoutButtons;
    Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
    Out UsedWidth: Integer;
    Out UsedHeight: Integer);
Begin
    //-------------------------------------------------------------------------
    //Entrée publique pour le layout séquentiel horizontal.
    //
    //Le calcul interne passe maintenant par le repère canonique TOP commun au
    //moteur par zones, puis par la même projection vers Top / Bottom.
    //-------------------------------------------------------------------------
    BuildSequentialLayoutCanonical(
        AClientWidth,
        AClientWidth,
        AClientHeight,
        nrtzfoHorizontal,
        ABarPosition,
        ABarMode,
        AFlowOrder,
        ALayout,
        ATabLayout,
        AButtonLayout,
        ARenderItems,
        UsedWidth,
        UsedHeight);
End;

Class Procedure TNoReflowTabBarZoneLayoutEngine.BuildVerticalSequentialLayout(
    AClientWidth: Integer;
    AClientHeight: Integer;
    ABarPosition: TNoReflowTabBarPosition;
    ABarMode: TNoReflowTabBarMode;
    AFlowOrder: TNoReflowTabBarFlowOrder;
    Const ALayout: TNoReflowTabBarLayout;
    Const ATabLayout: TNoReflowTabBarLayoutTabs;
    Const AButtonLayout: TNoReflowTabBarLayoutButtons;
    Var ARenderItems: TArray<TNoReflowTabBarRenderItem>;
    Out UsedWidth: Integer;
    Out UsedHeight: Integer);
Var
    UsedPrimarySize:   Integer;
    UsedSecondarySize: Integer;
Begin
    //-------------------------------------------------------------------------
    //Entrée publique pour le layout séquentiel vertical.
    //
    //Comme pour le mode par zones, le flux vertical est désormais calculé dans
    //un repère canonique TOP tourné :
    //- largeur canonique = hauteur réelle du client ;
    //- hauteur canonique = largeur réelle du client.
    //-------------------------------------------------------------------------
    BuildSequentialLayoutCanonical(
        AClientHeight,
        AClientWidth,
        AClientHeight,
        nrtzfoVertical,
        ABarPosition,
        ABarMode,
        AFlowOrder,
        ALayout,
        ATabLayout,
        AButtonLayout,
        ARenderItems,
        UsedPrimarySize,
        UsedSecondarySize);

    UsedWidth := UsedSecondarySize;
    UsedHeight := UsedPrimarySize;
End;

End.
