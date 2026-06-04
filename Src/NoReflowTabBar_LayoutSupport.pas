unit NoReflowTabBar_LayoutSupport;

{
  NoReflowTabBar_LayoutSupport.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Layout support layer of the NoReflowTabBar VCL component.

  Repository:
  https://github.com/mbaumsti/NoReflowTabBar

  License:
  Mozilla Public License 2.0.
  See LICENSE file.

  ------------------------------------------------------------------------------

  Item placement support layer of the NoReflowTabBar component.

  This unit provides:
  - bar orientation helpers;
  - routing between horizontal and vertical layout;
  - routing between sequential and zone-based layout engines;
  - space reservation for zone headers;
  - secondary adjustments required by button mode.

  Role of this unit:
  - keep NoReflowTabBar_Core independent from placement details;
  - centralise layout decisions based on BarPosition and BarLayoutMode;
  - adapt the canonical dimensions computed by NoReflowTabBar_ZoneLayout to the
  actual dimensions of the VCL control;
  - apply offsets related to headers and secondary margins.

  Notes:
  - this unit does not draw anything directly;
  - it prepares item Bounds and zone information used later by rendering,
  hit testing and drag and drop;
  - detailed geometric calculations remain delegated to NoReflowTabBar_ZoneLayout.
}

interface

uses
    Winapi.Windows,
    Winapi.Messages,
    Winapi.GDIPAPI,
    Winapi.GDIPOBJ,
    System.Types,
    System.Classes,
    System.Generics.Collections,
    System.sysutils,
    System.Math,
    Vcl.Graphics,
    Vcl.Controls,
    Vcl.Forms,
    Vcl.Themes,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_RenderTypes,
    NoReflowTabBar_Items,
    NoReflowTabBar_ZoneLayout,
    NoReflowTabBar_RenderBackend,
    NoReflowTabBar_Library,
    NoReflowTabBar_Core;

Type
    {
      Layout support layer for NoReflowTabBar.

      This class converts logical layout settings into final render item bounds.
      It selects the appropriate layout path according to BarPosition and
      BarLayoutMode, reserves zone header space when needed, and performs the
      final coordinate adjustments before rendering and hit testing.
    }
    TNoReflowTabBarLayoutSupport = Class(TNoReflowTabBarCore)
    protected

        {
          Measures and prepares the common item metrics used by every renderer.

          ARCHITECTURE RULE:
          These routines belong to the layout/preparation layer. They may use a
          Canvas only to measure text and prepare final rectangles, bounds and
          polygons. They must never draw. GDI and Direct2D must consume the
          resulting data instead of recalculating positions locally.
        }
        //Calcule la longueur de contenu d’un item indépendamment
        //de son placement final.
        Function CalcBaseContentLength(AItem: TNoReflowTabBarItem): Integer;

        //Calcule l'épaisseur utile de contenu d’un item indépendamment
        //de son placement final.
        //
        //Cette mesure est utilisée par SameThickness pour uniformiser la hauteur
        //ou la largeur secondaire des items selon l'orientation de la barre.
        Function CalcBaseContentThickness(AItem: TNoReflowTabBarItem): Integer;

        //Recalcule la longueur maximale du contenu lorsque SameLength=True.
        Procedure RecalcMaxTabContentLength;

        //Calcule les mesures de base du contenu : texte, voyant, longueurs utiles.
        Procedure CalcMetricsBaseSizes(
            AItem: TNoReflowTabBarItem;
            ASelected: Boolean;
            Var AMetrics: TNoReflowTabBarItemMetrics;
            Out TextW, TextH, SignalDiameter: Integer);

        //Calcule toutes les métriques nécessaires au rendu d’un item :
        //dimensions, orientation, texte et voyant.
        Procedure CalcTabMetrics(
            AItem: TNoReflowTabBarItem;
            ASelected: Boolean;
            Out AMetrics: TNoReflowTabBarItemMetrics);

        //Indique si la barre fonctionne actuellement avec une géométrie d'onglets.
        Function IsTabBarMode: Boolean;

        //Indique si la barre fonctionne actuellement avec une géométrie de boutons.
        Function IsButtonBarMode: Boolean;

        //Indique si l’égalisation de longueur est active.
        Function UseSameLength: Boolean;

        //Indique si l’égalisation d’épaisseur est active.
        Function UseSameThickness: Boolean;

        //Retourne la longueur maximale de contenu actuellement calculée.
        Function GetMaxTabContentLength: Integer;

        //Détermine l’orientation effectivement utilisée pour le texte.
        Procedure ResolveMetricsTextOrientation(Var AMetrics: TNoReflowTabBarItemMetrics);

        //Déduit les dimensions globales du bouton à partir des métriques.
        Procedure CalcMetricsButtonSize(Var AMetrics: TNoReflowTabBarItemMetrics);

        //Calcule les marges internes imposées par la géométrie de la forme.
        Procedure CalcMetricsInsets(
            Const AMetrics: TNoReflowTabBarItemMetrics;
            Out TopInset, BottomInset, LeftInset, RightInset: Integer);

        //Applique le moteur canonique de layout de contenu.
        Procedure ApplyContentLayoutEngine(
            Var AMetrics: TNoReflowTabBarItemMetrics;
            TextW: Integer;
            TextH: Integer;
            SignalDiameter: Integer;
            TopInset: Integer;
            BottomInset: Integer;
            LeftInset: Integer;
            RightInset: Integer);

        //Calcule les quatre points de base de la forme de l’item.
        Procedure CalcOutlineBasePoints(
            Const ARect: TRect;
            Out P0, P1, P2, P3: TPoint;
            Out Radius1, Radius2: Integer);

        //Construit le contour final d’un onglet sous forme de polygone.
        Procedure BuildTabOutlinePoints(
            Const ARect: TRect;
            APoints: TList<TPoint>);

        //Construit le contour final d'un bouton sous forme de polygone.
        Procedure BuildButtonOutlinePoints(
            Const ARect: TRect;
            APoints: TList<TPoint>);

        //Construit le contour final d'un item selon le mode de barre courant.
        Procedure BuildItemOutlinePoints(
            Const ARect: TRect;
            APoints: TList<TPoint>);

        //Construit les contours polygonaux finaux des items.
        Procedure BuildRenderItemRegions;

        //Reconstruit entièrement la représentation intermédiaire.
        Procedure RebuildRenderInfo;

        //Reconstruit FRenderItems à la demande si nécessaire.
        Procedure EnsureRenderInfo; override;

        //Initialise FRenderItems à partir de FItems avant placement final.
        Procedure InitRenderItems;

        //Prépare la police du canvas pour la mesure ou le rendu.
        Procedure SetupItemCanvasFont(ASelected: Boolean);

        //Résout la position logique du glyph pour un item.
        Function ResolveLogicalGlyphPosition(AItem: TNoReflowTabBarItem): TNoReflowTabBarGlyphPosition;

        //Résout la position physique du glyph pour un item.
        Function ResolveGlyphPosition(AItem: TNoReflowTabBarItem): TNoReflowTabBarGlyphPosition;

        //Convertit une position logique de glyph dans le repère du texte horizontal.
        Function RotateGlyphPositionForTextOrientation(
            AGlyphPosition: TNoReflowTabBarGlyphPosition;
            ATextOrientation: TNoReflowTabBarTextOrientation): TNoReflowTabBarGlyphPosition;

        //Résout la taille effective du glyph pour un item.
        Function ResolveGlyphSize(
            AItem: TNoReflowTabBarItem;
            Out AGlyphW: Integer;
            Out AGlyphH: Integer): Boolean;

        //Retourne le canvas utilisé pour les mesures de layout et le rendu GDI.
        Function PaintCanvas: TCanvas;

        {
          Returns True when the bar is positioned horizontally.
        }
        Function IsHorizontalBar: Boolean;

        {
          Returns True when the bar is positioned vertically.
        }
        Function IsVerticalBar: Boolean;

        {
          Returns the canonical flow orientation used by the zone layout engine.
        }
        Function GetZoneFlowOrientation: TNoReflowTabBarZoneFlowOrientation; override;

        {
          Returns the secondary size reserved for zone headers.

          The value is expressed in the canonical secondary layout axis. Zone
          headers are only relevant for the zone-based layout mode.
        }
        Function GetZoneHeaderReservedSize: Integer; override;

        {
          Offsets all visible render item bounds.

          This is used to insert an independent decorative band before the real
          item area.
        }
        Procedure OffsetVisibleRenderItems(ADeltaX, ADeltaY: Integer);

        {
          Offsets the canonical zone rectangles returned by the layout engine.

          FZoneLayoutInfo is expressed in canonical Top coordinates. Reserving a
          header band therefore always moves zones downward in that canonical
          space, regardless of the final physical bar position after rotation or
          mirroring.
        }
        Procedure OffsetZoneLayoutInfoCanonical(ADeltaX, ADeltaY: Integer);

        {
          Initialise explicitly the shared zone-header render information.

          This routine belongs to the layout layer because the record contains
          geometry that must be consumed, not recalculated, by the renderers.
        }
        Procedure InitializeZoneHeaderRenderInfo(Out AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo);

        {
          Resolves the effective text orientation used by zone headers.

          The result is part of the header layout contract: renderers may apply
          the matching drawing transform, but must not choose a different
          orientation or anchor point locally.
        }
        Function ResolveZoneHeaderTextOrientation: TNoReflowTabBarTextOrientation;

        {
          Builds the final render primitives for one zone header.

          IMPORTANT: this is layout work. It computes the clipped caption,
          text insertion point and decorative line segments in the final control
          coordinate system. GDI and Direct2D must only draw the returned
          primitives. They must not recalculate header placement locally.
        }
        Function BuildZoneHeaderRenderInfo(
            APinZone: TNoReflowTabBarPinZone;
            Const AZoneBounds: TRect;
            Out AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Boolean;

        {
          Applies the final secondary end margin used in button mode.

          In tab mode, no adjustment is applied because contact with the bar edge
          is intentional and part of the historical tab rendering. In button
          mode, an additional margin is reserved on the side opposite to
          MarginFirstRow so the closed button border remains visible.

          This method still acts during the layout phase. The modified bounds are
          therefore the final bounds used later by outlines, hit testing and
          painting.
        }
        Procedure ApplyButtonSecondaryEndMargin(
            Var UsedWidth: Integer;
            Var UsedHeight: Integer);

        {
          Places items for Left / Right bars using the sequential layout engine.
        }
        Procedure LayoutVerticalItemsSequential(Out UsedWidth, UsedHeight: Integer);

        {
          Places items for Left / Right bars using the zone-based layout engine.
        }
        Procedure LayoutVerticalItemsByZones(Out UsedWidth, UsedHeight: Integer);

        {
          Current vertical layout entry point.

          This method switches between layout engines according to BarLayoutMode.
        }
        Procedure LayoutVerticalItems(Out UsedWidth, UsedHeight: Integer);

        {
          Current horizontal layout entry point.

          This method switches between layout engines according to BarLayoutMode.
        }
        Procedure LayoutHorizontalItems(Out UsedWidth, UsedHeight: Integer);

        {
          Places items for Top / Bottom bars using the sequential layout engine.

          In tab mode, items may overlap according to BarLayoutTabs.TabOverlap.
          In button mode, items remain independent and use
          BarLayoutButtons.ButtonSpacing.
        }
        Procedure LayoutHorizontalItemsSequential(Out UsedWidth, UsedHeight: Integer);

        {
          Places items for Top / Bottom bars using the zone-based layout engine.
        }
        Procedure LayoutHorizontalItemsByZones(Out UsedWidth, UsedHeight: Integer);
    End;

implementation

Function TNoReflowTabBarLayoutSupport.IsHorizontalBar: Boolean;
Begin
    //-------------------------------------------------------------------------
    //Helper sémantique :
    //retourne True quand la position logique de la barre
    //est horizontale (top ou bottom).
    //-------------------------------------------------------------------------
    Result := FBarPosition In [nrtbpTop, nrtbpBottom];
End;

Function TNoReflowTabBarLayoutSupport.IsVerticalBar: Boolean;
Begin
    //-------------------------------------------------------------------------
    //Helper sémantique :
    //retourne True quand la position logique de la barre
    //est verticale (left ou right).
    //-------------------------------------------------------------------------
    Result := FBarPosition In [nrtbpLeft, nrtbpRight];
End;

Function TNoReflowTabBarLayoutSupport.GetZoneFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
Begin
    //-------------------------------------------------------------------------
    //Retourne l'orientation de flux utilisée par le moteur de layout.
    //
    //Le moteur de zones travaille dans un repère canonique :
    //- horizontal pour Top / Bottom ;
    //- vertical pour Left / Right.
    //
    //La projection écran réelle reste ensuite centralisée dans
    //TNoReflowTabBarZoneLayoutEngine.
    //-------------------------------------------------------------------------
    If IsHorizontalBar Then
        Result := nrtzfoHorizontal
    Else
        Result := nrtzfoVertical;
End;

Function TNoReflowTabBarLayoutSupport.GetZoneHeaderReservedSize: Integer;
Begin
    //-------------------------------------------------------------------------
    //Le header de zones est un élément décoratif indépendant des items.
    //
    //Il ne doit réserver de place que :
    //- si le layout par zones est actif ;
    //- si le sous-objet ZoneHeader existe ;
    //- si le header est visible ;
    //- si sa hauteur calculée est positive.
    //
    //Cette taille est ensuite appliquée dans le repère canonique, puis projetée
    //vers la position réelle de la barre.
    //-------------------------------------------------------------------------

    Result := 0;

    If FLayoutMode <> nrblmByZones Then
        Exit;

    If FZoneHeader = Nil Then
        Exit;

    If Not FZoneHeader.Visible Then
        Exit;

    Result := FZoneHeader.GetTotalHeight;
End;

Procedure TNoReflowTabBarLayoutSupport.InitializeZoneHeaderRenderInfo(Out AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo);
Var
    LIndex: Integer;
Begin
    //--------------------------------------------------------------------------
    //Initialisation explicite compatible Delphi classique.
    //
    //Le record conserve son nom historique Direct2D parce qu'il a d'abord ete
    //introduit pour alimenter le backend natif. Depuis v71, il devient la
    //structure partagee des primitives de header : GDI et Direct2D consomment
    //donc les memes donnees resolues par le layout.
    //--------------------------------------------------------------------------
    AHeaderInfo.PinZone := nrtpzStart;
    AHeaderInfo.Text := '';
    AHeaderInfo.FullText := '';
    AHeaderInfo.TextColor := clNone;
    AHeaderInfo.LineColor := clNone;
    AHeaderInfo.FontName := '';
    AHeaderInfo.FontSize := 0;
    AHeaderInfo.FontHeight := 0;
    AHeaderInfo.FontStyle := [];
    AHeaderInfo.TextOrientation := nrttoHorizontal;
    AHeaderInfo.TextInsertPoint := Point(
        0,
        0);
    AHeaderInfo.TextWidth := 0;
    AHeaderInfo.TextHeight := 0;
    AHeaderInfo.SegmentCount := 0;

    For LIndex := Low(AHeaderInfo.Segments) To High(AHeaderInfo.Segments) Do Begin
        AHeaderInfo.Segments[LIndex].P1 := Point(
            0,
            0);
        AHeaderInfo.Segments[LIndex].P2 := Point(
            0,
            0);
    End;
End;

Function TNoReflowTabBarLayoutSupport.ResolveZoneHeaderTextOrientation: TNoReflowTabBarTextOrientation;
Begin
    //--------------------------------------------------------------------------
    //Resout l'orientation effective du texte des headers de zones.
    //
    //Cette decision appartient au layout, pas aux renderers : le choix du point
    //d'insertion depend de cette orientation. Modifier cette logique dans GDI
    //ou Direct2D recreerait immediatement deux pipelines divergents.
    //--------------------------------------------------------------------------
    Case FBarPosition Of
        nrtbpTop, nrtbpBottom:
            Result := nrttoHorizontal;

        nrtbpLeft, nrtbpRight: Begin
                Case FTextOrientation Of
                    nrttoVerticalUp:
                        Result := nrttoVerticalUp;

                    nrttoVerticalDown:
                        Result := nrttoVerticalDown;
                Else Begin
                        If FBarPosition = nrtbpLeft Then
                            Result := nrttoVerticalUp
                        Else
                            Result := nrttoVerticalDown;
                    End;
                End;
            End;
    Else
        Result := nrttoHorizontal;
    End;
End;

Function TNoReflowTabBarLayoutSupport.BuildZoneHeaderRenderInfo(
    APinZone: TNoReflowTabBarPinZone;
    Const AZoneBounds: TRect;
    Out AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Boolean;
Var
    CaptionText:           String;
    HeaderReserve:         Integer;
    FlowOrientation:       TNoReflowTabBarZoneFlowOrientation;
    CanonZoneRect:         TRect;
    CanonHeaderRect:       TRect;
    CanonTextRect:         TRect;
    CanonInsertPoint:      TPoint;
    TextW:                 Integer;
    MaxTextFlowSize:       Integer;
    TextFlowSize:          Integer;
    TextCrossSize:         Integer;
    VisualTextH:           Integer;
    CanonLineY:            Integer;
    TickSize:              Integer;
    GapBeforeText:         Integer;
    GapAfterText:          Integer;
    Metrics:               TTextMetric;
    Palette:               TNoReflowTabBarPalette;
    HeaderTextOrientation: TNoReflowTabBarTextOrientation;
    MeasureBitmap:         TBitmap;

    Function CanonicalPointToActual(Const P: TPoint): TPoint;
    Begin
        Result := TNoReflowTabBarZoneLayoutEngine.TransformCanonicalPointToActual(
            P,
            FlowOrientation,
            FBarPosition,
            ClientWidth,
            ClientHeight);
    End;

    Procedure AddCanonicalSegment(
        X1: Integer;
        Y1: Integer;
        X2: Integer;
        Y2: Integer);
    Var
        LIndex: Integer;
    Begin
        //----------------------------------------------------------------------
        //Ajoute un segment exprime en repere canonique TOP, puis le projette
        //immediatement dans le repere final du controle.
        //
        //REGLE D'OR : les renderers ne doivent pas recalculer cette projection.
        //Ils ne doivent faire que MoveTo/LineTo ou l'equivalent Direct2D sur
        //les points deja resolus ici.
        //----------------------------------------------------------------------
        If AHeaderInfo.SegmentCount > High(AHeaderInfo.Segments) Then
            Exit;

        LIndex := AHeaderInfo.SegmentCount;

        AHeaderInfo.Segments[LIndex].P1 := CanonicalPointToActual(Point(X1, Y1));
        AHeaderInfo.Segments[LIndex].P2 := CanonicalPointToActual(Point(X2, Y2));

        Inc(AHeaderInfo.SegmentCount);
    End;

    Function FitHeaderTextToFlow(
        Const AText: String;
        AMaxFlowSize: Integer;
        ACanvas: TCanvas): String;
    Var
        LCandidate: String;
        LEllipsis:  String;
        LLen:       Integer;
    Begin
        //----------------------------------------------------------------------
        //Raccourcit le texte dans la phase de layout du header.
        //
        //Il est volontairement interdit de faire ce travail dans GDI ou dans
        //Direct2D : les deux backends doivent recevoir le meme texte resolu,
        //la meme largeur et le meme point d'insertion.
        //----------------------------------------------------------------------
        Result := AText;

        If AMaxFlowSize <= 0 Then Begin
            Result := '';
            Exit;
        End;

        If ACanvas.TextWidth(Result) <= AMaxFlowSize Then
            Exit;

        LEllipsis := '...';
        If ACanvas.TextWidth(LEllipsis) > AMaxFlowSize Then Begin
            Result := '';
            Exit;
        End;

        LCandidate := AText;
        LLen := Length(LCandidate);

        While LLen > 0 Do Begin
            LCandidate := Copy(AText, 1, LLen) + LEllipsis;

            If ACanvas.TextWidth(LCandidate) <= AMaxFlowSize Then Begin
                Result := LCandidate;
                Exit;
            End;

            Dec(LLen);
        End;

        Result := LEllipsis;
    End;

    Procedure BuildCanonicalTextRectAndInsertPoint;
    Begin
        //----------------------------------------------------------------------
        //Calcule le rectangle texte et son point d'insertion dans le repere
        //canonique TOP.
        //
        //REGLE D'OR : ce point d'insertion est definitif. Le renderer peut
        //seulement l'utiliser avec l'orientation de police/matrice demandee.
        //S'il semble faux, la correction doit etre faite ici, jamais dans
        //DrawSingleZoneHeader ni dans PaintOneDirect2DZoneHeaderText.
        //----------------------------------------------------------------------
        SetRectEmpty(CanonTextRect);

        Case FBarPosition Of
            nrtbpTop: Begin
                    CanonTextRect.Left := CanonHeaderRect.Left + TickSize + GapBeforeText;
                    CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                    CanonTextRect.Right := CanonTextRect.Left + TextFlowSize;
                    CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                    CanonInsertPoint := Point(
                        CanonTextRect.Left,
                        CanonTextRect.Top);
                End;

            nrtbpBottom: Begin
                    CanonTextRect.Left := CanonHeaderRect.Left + TickSize + GapBeforeText;
                    CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                    CanonTextRect.Right := CanonTextRect.Left + TextFlowSize;
                    CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                    CanonInsertPoint := Point(
                        CanonTextRect.Left,
                        CanonTextRect.Bottom);
                End;

            nrtbpLeft: Begin
                    Case HeaderTextOrientation Of
                        nrttoVerticalDown: Begin
                                CanonTextRect.Right := CanonHeaderRect.Right - TickSize - GapBeforeText;
                                CanonTextRect.Left := CanonTextRect.Right - TextFlowSize;
                                CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                                CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                                CanonInsertPoint := Point(
                                    CanonTextRect.Right,
                                    CanonTextRect.Bottom);
                            End;

                        nrttoVerticalUp: Begin
                                CanonTextRect.Left := CanonHeaderRect.Left + TickSize + GapBeforeText;
                                CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                                CanonTextRect.Right := CanonTextRect.Left + TextFlowSize;
                                CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                                CanonInsertPoint := Point(
                                    CanonTextRect.Left,
                                    CanonTextRect.Top);
                            End;
                    Else Begin
                            CanonTextRect.Left := CanonHeaderRect.Left + TickSize + GapBeforeText;
                            CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                            CanonTextRect.Right := CanonTextRect.Left + TextFlowSize;
                            CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                            CanonInsertPoint := Point(
                                CanonTextRect.Left,
                                CanonTextRect.Top);
                        End;
                    End;
                End;

            nrtbpRight: Begin
                    Case HeaderTextOrientation Of
                        nrttoVerticalDown: Begin
                                CanonTextRect.Left := CanonHeaderRect.Left + TickSize + GapBeforeText;
                                CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                                CanonTextRect.Right := CanonTextRect.Left + TextFlowSize;
                                CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                                CanonInsertPoint := Point(
                                    CanonTextRect.Left,
                                    CanonTextRect.Top);
                            End;

                        nrttoVerticalUp: Begin
                                CanonTextRect.Right := CanonHeaderRect.Right - TickSize - GapBeforeText;
                                CanonTextRect.Left := CanonTextRect.Right - TextFlowSize;
                                CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                                CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                                CanonInsertPoint := Point(
                                    CanonTextRect.Right,
                                    CanonTextRect.Bottom);
                            End;
                    Else Begin
                            CanonTextRect.Left := CanonHeaderRect.Left + TickSize + GapBeforeText;
                            CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                            CanonTextRect.Right := CanonTextRect.Left + TextFlowSize;
                            CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                            CanonInsertPoint := Point(
                                CanonTextRect.Left,
                                CanonTextRect.Top);
                        End;
                    End;
                End;
        Else Begin
                CanonTextRect.Left := CanonHeaderRect.Left + TickSize + GapBeforeText;
                CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                CanonTextRect.Right := CanonTextRect.Left + TextFlowSize;
                CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                CanonInsertPoint := Point(
                    CanonTextRect.Left,
                    CanonTextRect.Top);
            End;
        End;
    End;

Begin
    //--------------------------------------------------------------------------
    //Construit les primitives finales d'un header de zone sans rien dessiner.
    //
    //REGLE D'OR v71 : tout le positionnement du header est centralise ici.
    //Les renderers GDI et Direct2D ne doivent pas contourner cette methode par
    //des corrections locales. En cas de bug visuel, corriger le layout ici.
    //--------------------------------------------------------------------------
    InitializeZoneHeaderRenderInfo(AHeaderInfo);
    Result := False;

    If FZoneHeader = Nil Then
        Exit;

    If Not FZoneHeader.Visible Then
        Exit;

    CaptionText := Trim(GetZoneHeaderCaption(APinZone));
    If CaptionText = '' Then
        Exit;

    HeaderReserve := GetZoneHeaderReservedSize;
    If HeaderReserve <= 0 Then
        Exit;

    FlowOrientation := GetZoneFlowOrientation;
    TickSize := FZoneHeader.TickSize;
    GapBeforeText := FZoneHeader.TextPadding;
    GapAfterText := FZoneHeader.TextPadding;
    Palette := GetActivePalette;

    CanonZoneRect := AZoneBounds;

    Case FZoneHeader.Placement Of
        nrthpOuterBand:
            CanonHeaderRect := Rect(CanonZoneRect.Left, 0, CanonZoneRect.Right, HeaderReserve);

        nrthpAboveZone:
            CanonHeaderRect := Rect(CanonZoneRect.Left, GetZoneFirstRowCanonicalTop(APinZone) - HeaderReserve, CanonZoneRect.Right, GetZoneFirstRowCanonicalTop(APinZone));
    Else
        CanonHeaderRect := Rect(CanonZoneRect.Left, 0, CanonZoneRect.Right, HeaderReserve);
    End;

    MeasureBitmap := TBitmap.Create;
    Try
        MeasureBitmap.SetSize(
            1,
            1);
        MeasureBitmap.Canvas.Font.Assign(FZoneHeader.Font);

        MaxTextFlowSize := (CanonHeaderRect.Right - CanonHeaderRect.Left) - (2 * TickSize) - GapBeforeText - GapAfterText;

        CaptionText := FitHeaderTextToFlow(
            CaptionText,
            MaxTextFlowSize,
            MeasureBitmap.Canvas);

        If CaptionText = '' Then
            Exit;

        TextW := MeasureBitmap.Canvas.TextWidth(CaptionText);

        If Not GetTextMetrics(MeasureBitmap.Canvas.Handle, Metrics) Then
            VisualTextH := MeasureBitmap.Canvas.TextHeight(CaptionText)
        Else
            VisualTextH := Metrics.tmAscent + Metrics.tmDescent;
    Finally MeasureBitmap.Free;
    End;

    HeaderTextOrientation := ResolveZoneHeaderTextOrientation;

    TextFlowSize := TextW;
    TextCrossSize := VisualTextH;
    CanonLineY := CanonHeaderRect.Top + FZoneHeader.TopMargin + (FZoneHeader.Height Div 2);

    BuildCanonicalTextRectAndInsertPoint;

    AHeaderInfo.PinZone := APinZone;
    AHeaderInfo.Text := CaptionText;
    AHeaderInfo.FullText := Trim(GetZoneHeaderCaption(APinZone));
    AHeaderInfo.TextColor := Palette.ZoneHeaderText;
    AHeaderInfo.LineColor := Palette.ZoneHeaderLine;
    AHeaderInfo.FontName := FZoneHeader.Font.Name;
    AHeaderInfo.FontSize := FZoneHeader.Font.Size;
    AHeaderInfo.FontHeight := FZoneHeader.Font.Height;
    AHeaderInfo.FontStyle := FZoneHeader.Font.Style;
    AHeaderInfo.TextOrientation := HeaderTextOrientation;
    AHeaderInfo.TextInsertPoint := CanonicalPointToActual(CanonInsertPoint);
    AHeaderInfo.TextWidth := TextFlowSize;
    AHeaderInfo.TextHeight := TextCrossSize;
    AHeaderInfo.SegmentCount := 0;

    AddCanonicalSegment(
        CanonHeaderRect.Left,
        CanonLineY,
        CanonTextRect.Left - GapBeforeText,
        CanonLineY);

    AddCanonicalSegment(
        CanonTextRect.Right + GapAfterText,
        CanonLineY,
        CanonHeaderRect.Right - 1,
        CanonLineY);

    AddCanonicalSegment(
        CanonHeaderRect.Left,
        CanonLineY,
        CanonHeaderRect.Left,
        CanonLineY + TickSize);

    AddCanonicalSegment(
        CanonHeaderRect.Right - 1,
        CanonLineY,
        CanonHeaderRect.Right - 1,
        CanonLineY + TickSize);

    Result := True;
End;

Procedure TNoReflowTabBarLayoutSupport.OffsetVisibleRenderItems(ADeltaX, ADeltaY: Integer);
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Décale tous les rectangles déjà calculés pour les items visibles.
    //
    //Cette translation est utilisée pour réserver physiquement une bande
    //secondaire dédiée au header décoratif des zones, sans compliquer
    //inutilement les moteurs de layout eux-mêmes.
    //-------------------------------------------------------------------------

    If (ADeltaX = 0) And (ADeltaY = 0) Then
        Exit;

    For I := 0 To High(FRenderItems) Do Begin
        If Not FRenderItems[I].Visible Then
            Continue;

        OffsetRect(
            FRenderItems[I].Bounds,
            ADeltaX,
            ADeltaY);
    End;
End;

Procedure TNoReflowTabBarLayoutSupport.OffsetZoneLayoutInfoCanonical(ADeltaX, ADeltaY: Integer);
Begin
    //-------------------------------------------------------------------------
    //Décale les rectangles de zones conservés en repère canonique.
    //
    //Important :
    //- il ne s'agit PAS d'un décalage écran ;
    //- en barre horizontale, Canonical Y correspond bien au Y écran ;
    //- en barre verticale, Canonical Y correspond à l'épaisseur de barre,
    //donc à un décalage horizontal réel après projection.
    //
    //Cette méthode doit donc rester exprimée uniquement dans le repère
    //canonique utilisé par le moteur de layout.
    //-------------------------------------------------------------------------

    If (ADeltaX = 0) And (ADeltaY = 0) Then
        Exit;

    If FZoneLayoutInfo.StartZone.HasZone Then Begin
        OffsetRect(
            FZoneLayoutInfo.StartZone.OuterCanonicalRect,
            ADeltaX,
            ADeltaY);

        Inc(
            FZoneLayoutInfo.StartZone.FirstRowCanonicalTop,
            ADeltaY);
    End;

    If FZoneLayoutInfo.CenterZone.HasZone Then Begin
        OffsetRect(
            FZoneLayoutInfo.CenterZone.OuterCanonicalRect,
            ADeltaX,
            ADeltaY);

        Inc(
            FZoneLayoutInfo.CenterZone.FirstRowCanonicalTop,
            ADeltaY);
    End;

    If FZoneLayoutInfo.EndZone.HasZone Then Begin
        OffsetRect(
            FZoneLayoutInfo.EndZone.OuterCanonicalRect,
            ADeltaX,
            ADeltaY);

        Inc(
            FZoneLayoutInfo.EndZone.FirstRowCanonicalTop,
            ADeltaY);
    End;
End;

Procedure TNoReflowTabBarLayoutSupport.ApplyButtonSecondaryEndMargin(
    Var UsedWidth: Integer;
    Var UsedHeight: Integer);
Var
    LMargin:      Integer;
    LOffsetX:     Integer;
    LOffsetY:     Integer;
    LZoneOffsetX: Integer;
    LZoneOffsetY: Integer;
Begin
    //-------------------------------------------------------------------------
    //Ajoute la marge secondaire finale nécessaire au mode bouton.
    //
    //Cette correction ne concerne pas les onglets :
    //- en mode onglets, le contact avec la frontière de la barre est volontaire ;
    //- en mode boutons, chaque item est une forme fermée dont les quatre côtés
    //doivent rester visibles.
    //
    //Point important :
    //les headers de zones utilisent FZoneLayoutInfo, qui est exprimé dans le
    //repère canonique du moteur de zones. Si les boutons sont déplacés pour
    //préserver leur bordure en Bottom ou Right, les rectangles de zones doivent
    //être déplacés dans le même repère logique, sinon les headers restent
    //visuellement attachés à l'ancienne position.
    //-------------------------------------------------------------------------

    If Not(FBarMode In [nrbmPushButtons, nrbmSelectButtons, nrbmCheckButtons]) Then
        Exit;

    If FLayout = Nil Then
        Exit;

    LMargin := FLayout.MarginFirstRow;

    If LMargin < 1 Then
        LMargin := 1;

    LOffsetX := 0;
    LOffsetY := 0;
    LZoneOffsetX := 0;
    LZoneOffsetY := 0;

    Case FBarPosition Of
        nrtbpTop: Begin
                //Barre haute :
                //la frontière avec la zone cliente est en bas.
                //On ajoute seulement de la hauteur utile après les boutons.
                //Les boutons et les headers restent à leur position calculée.
                Inc(
                    UsedHeight,
                    LMargin);
            End;

        nrtbpBottom: Begin
                //Barre basse :
                //la frontière avec la zone cliente est en haut.
                //On descend les boutons pour rendre leur bord supérieur visible.
                //
                //En horizontal, le repère canonique TOP a le même axe Y que
                //l'écran pour ce type de correction secondaire.
                LOffsetY := LMargin;
                LZoneOffsetY := -LMargin;

                Inc(
                    UsedHeight,
                    LMargin);
            End;

        nrtbpLeft: Begin
                //Barre gauche :
                //la frontière avec la zone cliente est à droite.
                //On ajoute seulement de la largeur utile après les boutons.
                //Les boutons et les headers restent à leur position calculée.
                Inc(
                    UsedWidth,
                    LMargin);
            End;

        nrtbpRight: Begin
                //Barre droite :
                //la frontière avec la zone cliente est à gauche.
                //On décale les boutons vers la droite pour rendre leur bord
                //gauche visible.
                //
                //En layout vertical, le décalage horizontal écran correspond
                //à un décalage secondaire dans le repère canonique, donc à Y.
                LOffsetX := LMargin;
                LZoneOffsetY := -LMargin;

                Inc(
                    UsedWidth,
                    LMargin);
            End;
    End;

    If (LOffsetX <> 0) Or (LOffsetY <> 0) Then
        OffsetVisibleRenderItems(
            LOffsetX,
            LOffsetY);

    If (LZoneOffsetX <> 0) Or (LZoneOffsetY <> 0) Then
        OffsetZoneLayoutInfoCanonical(
            LZoneOffsetX,
            LZoneOffsetY);
End;

Procedure TNoReflowTabBarLayoutSupport.LayoutHorizontalItems(Out UsedWidth, UsedHeight: Integer);
Var
    HeaderReserve: Integer;
    OffsetY:       Integer;
Begin
    //-------------------------------------------------------------------------
    //Point d'entrée du layout horizontal.
    //
    //Le layout est d'abord calculé sans tenir compte de la bande décorative
    //des headers. On ajoute ensuite cette bande en décalant les items et
    //les informations de zones.
    //
    //Cette séparation garde les moteurs de placement concentrés sur les items,
    //et laisse cette couche gérer l'encombrement décoratif.
    //-------------------------------------------------------------------------

    Case FLayoutMode Of
        nrblmSequential:
            LayoutHorizontalItemsSequential(UsedWidth, UsedHeight);

        nrblmByZones:
            LayoutHorizontalItemsByZones(UsedWidth, UsedHeight);
    Else
        LayoutHorizontalItemsByZones(UsedWidth, UsedHeight);
    End;

    ApplyButtonSecondaryEndMargin(
        UsedWidth,
        UsedHeight);

    HeaderReserve := GetZoneHeaderReservedSize;

    If HeaderReserve > 0 Then Begin
        Case FBarPosition Of
            nrtbpTop:
                OffsetY := HeaderReserve;

            nrtbpBottom:
                OffsetY := -HeaderReserve;
        Else
            OffsetY := 0;
        End;

        OffsetVisibleRenderItems(
            0,
            OffsetY);

        //En repère canonique TOP, la zone d’items est toujours repoussée
        //vers le bas quand une bande de header est réservée.
        OffsetZoneLayoutInfoCanonical(
            0,
            HeaderReserve);

        Inc(
            UsedHeight,
            HeaderReserve);
    End;
End;

Procedure TNoReflowTabBarLayoutSupport.LayoutVerticalItems(Out UsedWidth, UsedHeight: Integer);
Var
    HeaderReserve: Integer;
    OffsetX:       Integer;
Begin
    //-------------------------------------------------------------------------
    //Point d'entrée du layout vertical.
    //
    //Le moteur calcule d'abord les items comme si toute la largeur utile
    //était disponible. Si un header de zone est actif, on réserve ensuite une
    //bande secondaire :
    //- à gauche pour une barre Left ;
    //- à droite pour une barre Right.
    //
    //Le décalage des zones reste toujours exprimé dans le repère canonique.
    //-------------------------------------------------------------------------

    Case FLayoutMode Of
        nrblmSequential:
            LayoutVerticalItemsSequential(UsedWidth, UsedHeight);

        nrblmByZones:
            LayoutVerticalItemsByZones(UsedWidth, UsedHeight);
    Else
        LayoutVerticalItemsByZones(UsedWidth, UsedHeight);
    End;

    ApplyButtonSecondaryEndMargin(
        UsedWidth,
        UsedHeight);

    HeaderReserve := GetZoneHeaderReservedSize;

    If HeaderReserve > 0 Then Begin
        Case FBarPosition Of
            nrtbpLeft:
                OffsetX := HeaderReserve;

            nrtbpRight:
                OffsetX := -HeaderReserve;
        Else
            OffsetX := 0;
        End;

        OffsetVisibleRenderItems(
            OffsetX,
            0);

        //Même règle : en canonique TOP, les zones sont repoussées vers le bas.
        //Après projection Left / Right, ce déplacement devient un décalage
        //horizontal réel.
        OffsetZoneLayoutInfoCanonical(
            0,
            HeaderReserve);

        Inc(
            UsedWidth,
            HeaderReserve);
    End;
End;

Procedure TNoReflowTabBarLayoutSupport.LayoutHorizontalItemsSequential(Out UsedWidth, UsedHeight: Integer);
Begin
    //-------------------------------------------------------------------------
    //Layout horizontal séquentiel.
    //
    //Le moteur reçoit maintenant :
    //- FBarMode      : mode fonctionnel global de la barre ;
    //- FLayout       : paramètres communs aux onglets et boutons ;
    //- FLayoutTabs    : paramètres propres au rendu onglet ;
    //- FLayoutButtons : paramètres propres au rendu bouton.
    //
    //Cette séparation permet au moteur de choisir proprement :
    //- TabOverlap en mode onglets ;
    //- ButtonSpacing en mode boutons.
    //
    //On évite ainsi de détourner TabOverlap pour simuler un espacement
    //de boutons, ce qui rendrait la logique difficile à maintenir.
    //
    //Le layout séquentiel reçoit aussi FFlowOrder.
    //
    //Cela permet au mode nrblmSequential d'utiliser le même ordre logique que
    //le layout par zones, sans changer la collection physique :
    //- ordre normal ;
    //- zones inversées ;
    //- zones inversées avec items inversés.
    //-------------------------------------------------------------------------
    UsedWidth := 0;
    UsedHeight := 0;

    TNoReflowTabBarZoneLayoutEngine.BuildHorizontalSequentialLayout(
        ClientWidth,
        ClientHeight,
        FBarPosition,
        FBarMode,
        FFlowOrder,
        FLayout,
        FLayoutTabs,
        FLayoutButtons,
        FRenderItems,
        UsedWidth,
        UsedHeight);
End;

Procedure TNoReflowTabBarLayoutSupport.LayoutHorizontalItemsByZones(Out UsedWidth, UsedHeight: Integer);
Begin
    //------------------------------------------------------------------------
    //Moteur horizontal par zones.
    //
    //Objectifs :
    //- conserver la logique Start / Center / End ;
    //- autoriser le multi-ligne à l'intérieur des zones ;
    //- utiliser le layout commun pour les marges / espacements globaux ;
    //- utiliser le layout onglets pour les paramètres propres aux onglets ;
    //- utiliser le layout boutons pour les paramètres propres aux boutons.
    //
    //Le choix concret du pas entre deux items dépend maintenant de FBarMode :
    //- mode onglets : recouvrement via BarLayoutTabs.TabOverlap ;
    //- mode boutons : espacement positif via BarLayoutButtons.ButtonSpacing.
    //
    //Remarque importante :
    //cette routine délègue tout le calcul à l'unité
    //NoReflowTabBar_ZoneLayout, afin de ne pas alourdir
    //NoReflowTabBar_Core.
    //------------------------------------------------------------------------

    UsedWidth := 0;
    UsedHeight := 0;

    TNoReflowTabBarZoneLayoutEngine.BuildHorizontalZoneLayout(
        ClientWidth,
        ClientHeight,
        FBarPosition,
        FBarMode,
        FFlowOrder,
        FLayout,
        FLayoutTabs,
        FLayoutButtons,
        FRenderItems,
        UsedWidth,
        UsedHeight,
        FZoneLayoutInfo);
End;

Procedure TNoReflowTabBarLayoutSupport.LayoutVerticalItemsSequential(Out UsedWidth, UsedHeight: Integer);
Begin
    //-------------------------------------------------------------------------
    //Layout vertical séquentiel.
    //
    //Même séparation que pour le layout horizontal :
    //- FBarMode      indique si l'on place des onglets ou des boutons ;
    //- FLayout       contient les paramètres communs ;
    //- FLayoutTabs    contient les paramètres spécifiques aux onglets ;
    //- FLayoutButtons contient les paramètres spécifiques aux boutons.
    //
    //En mode boutons, les items ne doivent jamais se recouvrir :
    //le moteur utilisera donc ButtonSpacing au lieu de TabOverlap.
    //
    //Même en mode vertical, FFlowOrder reste appliqué dans le repère canonique.
    //La projection Left / Right reste inchangée et continue d'être centralisée
    //dans NoReflowTabBar_ZoneLayout.
    //-------------------------------------------------------------------------
    UsedWidth := 0;
    UsedHeight := 0;

    TNoReflowTabBarZoneLayoutEngine.BuildVerticalSequentialLayout(
        ClientWidth,
        ClientHeight,
        FBarPosition,
        FBarMode,
        FFlowOrder,
        FLayout,
        FLayoutTabs,
        FLayoutButtons,
        FRenderItems,
        UsedWidth,
        UsedHeight);
End;

Procedure TNoReflowTabBarLayoutSupport.LayoutVerticalItemsByZones(Out UsedWidth, UsedHeight: Integer);
Var
    UsedPrimarySize:   Integer;
    UsedSecondarySize: Integer;
Begin
    //-------------------------------------------------------------------------
    //Layout vertical par zones.
    //
    //Le moteur travaille en dimensions logiques :
    //- Primary   = hauteur logique de placement ;
    //- Secondary = largeur logique de la barre.
    //
    //Le mode de barre est transmis au moteur pour qu'il choisisse la bonne
    //stratégie d'espacement entre items :
    //- onglets : recouvrement ;
    //- boutons : espacement positif.
    //
    //On reconvertit ensuite ces dimensions en UsedWidth / UsedHeight pour
    //le contrôle VCL réel.
    //-------------------------------------------------------------------------

    UsedWidth := 0;
    UsedHeight := 0;

    TNoReflowTabBarZoneLayoutEngine.BuildVerticalZoneLayout(
        ClientWidth,
        ClientHeight,
        FBarPosition,
        FBarMode,
        FFlowOrder,
        FLayout,
        FLayoutTabs,
        FLayoutButtons,
        FRenderItems,
        UsedPrimarySize,
        UsedSecondarySize,
        FZoneLayoutInfo);

    //En vertical :
    //- Primary   = hauteur logique ;
    //- Secondary = largeur logique.
    UsedWidth := UsedSecondarySize;
    UsedHeight := UsedPrimarySize;
End;


{ Common item metric, geometry and glyph-placement helpers moved from the GDI backend. }

Function TNoReflowTabBarLayoutSupport.CalcBaseContentLength(AItem: TNoReflowTabBarItem): Integer;
Var
    TextW:          Integer;
    TextH:          Integer;
    SignalBlock:    Integer;
    SignalDiameter: Integer;
    GlyphW:         Integer;
    GlyphH:         Integer;
    HasGlyph:       Boolean;
    GlyphPosition:  TNoReflowTabBarGlyphPosition;
    Metrics:        TNoReflowTabBarItemMetrics;
    TextGlyphFlow:  Integer;
Begin
    //-------------------------------------------------------------------------
    //Calcule la longueur utile de contenu d’un item,
    //indépendamment de son placement final dans la barre.
    //
    //Cette longueur correspond à l’espace minimal nécessaire pour loger :
    //- la marge avant le contenu ;
    //- le voyant éventuel ;
    //- le couple glyph + texte ;
    //- la marge après le contenu.
    //
    //Important :
    //La mesure est faite avec la police de l'état sélectionné afin d'éviter
    //qu'un changement de style de police ne modifie la largeur de l'item
    //au moment de la sélection.
    //-------------------------------------------------------------------------

    Result := 0;

    If AItem = Nil Then
        Exit;

    SetupItemCanvasFont(True);

    MeasureItemText(
        PaintCanvas,
        IndexOfItem(AItem),
        AItem,
        True,
        TextW,
        TextH);

    FillChar(
        Metrics,
        SizeOf(Metrics),
        0);

    Metrics.TabPosition := FBarPosition;
    ResolveMetricsTextOrientation(Metrics);

    GlyphPosition := RotateGlyphPositionForTextOrientation(
        ResolveLogicalGlyphPosition(AItem),
        Metrics.TextOrientation);
    HasGlyph := ResolveGlyphSize(
        AItem,
        GlyphW,
        GlyphH);

    //Longueur du couple texte + glyph dans l'axe principal.
    //
    //Pour un texte horizontal :
    //- glyph gauche/droite : le glyph consomme de la longueur ;
    //- glyph haut/bas     : le glyph consomme surtout de l'épaisseur.
    //
    //Pour un texte vertical, l'axe principal est vertical :
    //- glyph haut/bas     : le glyph consomme de la longueur ;
    //- glyph gauche/droite : le glyph consomme surtout de l'épaisseur.
    TextGlyphFlow := TextW;

    If HasGlyph Then Begin
        If Not Metrics.VerticalFlow Then Begin
            Case GlyphPosition Of
                nrgpLeft, nrgpRight:
                    TextGlyphFlow := TextW + FLayout.GlyphSpacing + GlyphW;

                nrgpTop, nrgpBottom:
                    TextGlyphFlow := Max(TextW, GlyphW);
            End;
        End Else Begin
            Case GlyphPosition Of
                nrgpTop, nrgpBottom:
                    TextGlyphFlow := TextW + FLayout.GlyphSpacing + GlyphH;

                nrgpLeft, nrgpRight:
                    TextGlyphFlow := Max(TextW, GlyphH);
            End;
        End;
    End;

    SignalDiameter := FLayout.SignalSize;
    SignalBlock := 0;

    If FindSignalDefByCode(AItem.SignalCode) <> Nil Then
        SignalBlock := SignalDiameter + FLayout.SignalSpacing;

    Result := FLayout.TextSpaceBefore + SignalBlock + TextGlyphFlow + FLayout.TextSpaceAfter;
End;


Function TNoReflowTabBarLayoutSupport.CalcBaseContentThickness(AItem: TNoReflowTabBarItem): Integer;
Var
    TextW:          Integer;
    TextH:          Integer;
    SignalDiameter: Integer;
    GlyphW:         Integer;
    GlyphH:         Integer;
    HasGlyph:       Boolean;
    GlyphPosition:  TNoReflowTabBarGlyphPosition;
    Metrics:        TNoReflowTabBarItemMetrics;
    TextGlyphCross: Integer;
Begin
    //-------------------------------------------------------------------------
    //Calcule l'épaisseur utile d'un item.
    //
    //Cette valeur correspond à la taille nécessaire dans l'axe secondaire
    //du contenu, avant ajout des effets de forme externes.
    //
    //Elle sert à SameThickness :
    //- sans uniformisation, chaque item garde son épaisseur naturelle ;
    //- avec uniformisation, tous les items visibles reçoivent la plus grande
    //épaisseur naturelle calculée.
    //
    //Important :
    //on utilise aussi la police sélectionnée, comme pour CalcBaseContentLength,
    //afin d'éviter qu'une sélection ne modifie l'épaisseur au dernier moment.
    //-------------------------------------------------------------------------
    Result := 0;

    If AItem = Nil Then
        Exit;

    SetupItemCanvasFont(True);

    MeasureItemText(
        PaintCanvas,
        IndexOfItem(AItem),
        AItem,
        True,
        TextW,
        TextH);

    FillChar(
        Metrics,
        SizeOf(Metrics),
        0);

    Metrics.TabPosition := FBarPosition;
    ResolveMetricsTextOrientation(Metrics);

    GlyphPosition := RotateGlyphPositionForTextOrientation(
        ResolveLogicalGlyphPosition(AItem),
        Metrics.TextOrientation);
    HasGlyph := ResolveGlyphSize(
        AItem,
        GlyphW,
        GlyphH);

    TextGlyphCross := TextH;

    If HasGlyph Then Begin
        If Not Metrics.VerticalFlow Then Begin
            Case GlyphPosition Of
                nrgpLeft, nrgpRight:
                    TextGlyphCross := Max(TextH, GlyphH);

                nrgpTop, nrgpBottom:
                    TextGlyphCross := TextH + FLayout.GlyphSpacing + GlyphH;
            End;
        End Else Begin
            Case GlyphPosition Of
                nrgpTop, nrgpBottom:
                    TextGlyphCross := Max(TextH, GlyphW);

                nrgpLeft, nrgpRight:
                    TextGlyphCross := TextH + FLayout.GlyphSpacing + GlyphW;
            End;
        End;
    End;

    SignalDiameter := FLayout.SignalSize;

    Result := Max(TextGlyphCross, SignalDiameter) + FLayout.TextSpaceOver + FLayout.TextSpaceUnder;
End;


Procedure TNoReflowTabBarLayoutSupport.RecalcMaxTabContentLength;
Var
    I:         Integer;
    L:         Integer;
    Thickness: Integer;
    Item:      TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Recalcule les métriques partagées entre items visibles.
    //
    //Historiquement, cette routine ne calculait que la longueur maximale
    //utilisée par SameLength.
    //
    //Elle calcule maintenant aussi l'épaisseur maximale utilisée par
    //SameThickness, afin de garder les items visuellement homogènes lorsque
    //certains contenus sont plus hauts ou plus larges que les autres.
    //
    //On ignore volontairement les items invisibles :
    //ils ne participent pas au layout courant et ne doivent donc pas influencer
    //les dimensions communes des items affichés.
    //-------------------------------------------------------------------------
    FMaxItemContentLength := 0;
    FMaxItemMinorSize := 0;

    If (Not UseSameLength) And (Not UseSameThickness) Then
        Exit;

    For I := 0 To FItems.Count - 1 Do Begin
        Item := FItems[I];

        If (Item = Nil) Or (Not Item.Visible) Then
            Continue;

        If UseSameLength Then Begin
            L := CalcBaseContentLength(Item);

            If L > FMaxItemContentLength Then
                FMaxItemContentLength := L;
        End;

        If UseSameThickness Then Begin
            Thickness := CalcBaseContentThickness(Item);

            If Thickness > FMaxItemMinorSize Then
                FMaxItemMinorSize := Thickness;
        End;
    End;
End;


Procedure TNoReflowTabBarLayoutSupport.CalcMetricsBaseSizes(
    AItem: TNoReflowTabBarItem;
    ASelected: Boolean;
    Var AMetrics: TNoReflowTabBarItemMetrics;
    Out TextW, TextH, SignalDiameter: Integer);
Var
    SignalBlock:    Integer;
    GlyphW:         Integer;
    GlyphH:         Integer;
    TextGlyphFlow:  Integer;
    TextGlyphCross: Integer;
Begin
    //-------------------------------------------------------------------------
    //Première phase de calcul des métriques.
    //
    //Cette routine rassemble toutes les informations "brutes" nécessaires :
    //- mesures du texte ;
    //- présence ou non d’un signal ;
    //- présence ou non d’un glyph ;
    //- taille transversale minimale ;
    //- longueur utile du contenu ;
    //- compensations visuelles liées aux slants.
    //-------------------------------------------------------------------------

    SetupItemCanvasFont(ASelected);

    MeasureItemText(
        PaintCanvas,
        IndexOfItem(AItem),
        AItem,
        ASelected,
        TextW,
        TextH);

    AMetrics.TextWidth := TextW;
    AMetrics.TextHeight := TextH;
    AMetrics.AllowTextTrimming := False;

    //---------------------------------------------------------------------
    // Zone de composition du texte.
    //
    // Elle sera affinee plus tard par ApplyContentLayoutEngine, qui delegue au
    // moteur commun TNoReflowTabBarItemContentLayoutEngine. Le point important
    // est architectural : le renderer ne doit pas recalculer cette zone. Le
    // layout reste proprietaire des rectangles et positions consommes ensuite
    // par GDI ou Direct2D.
    //---------------------------------------------------------------------
    AMetrics.TextClipRect := Rect(0, 0, TextW, TextH);

    AMetrics.HasSignal := FindSignalDefByCode(AItem.SignalCode) <> Nil;

    SignalDiameter := FLayout.SignalSize;
    SignalBlock := 0;

    If AMetrics.HasSignal Then
        SignalBlock := SignalDiameter + FLayout.SignalSpacing;

    //---------------------------------------------------------------------
    //Glyph.
    //---------------------------------------------------------------------
    AMetrics.LogicalGlyphPosition := ResolveLogicalGlyphPosition(AItem);
    AMetrics.GlyphPosition := RotateGlyphPositionForTextOrientation(
        AMetrics.LogicalGlyphPosition,
        AMetrics.TextOrientation);

    AMetrics.HasGlyph := ResolveGlyphSize(
        AItem,
        GlyphW,
        GlyphH);

    If AMetrics.HasGlyph Then Begin
        AMetrics.GlyphWidth := GlyphW;
        AMetrics.GlyphHeight := GlyphH;
    End Else Begin
        AMetrics.GlyphWidth := 0;
        AMetrics.GlyphHeight := 0;
    End;

    SetRectEmpty(AMetrics.GlyphRect);

    //---------------------------------------------------------------------
    //Calcule la taille du couple texte + glyph.
    //
    //TextGlyphFlow  : longueur dans l'axe principal du contenu.
    //TextGlyphCross : épaisseur dans l'axe secondaire.
    //---------------------------------------------------------------------
    TextGlyphFlow := TextW;
    TextGlyphCross := TextH;

    If AMetrics.HasGlyph Then Begin
        If Not AMetrics.VerticalFlow Then Begin
            Case AMetrics.GlyphPosition Of
                nrgpLeft, nrgpRight: Begin
                        TextGlyphFlow := TextW + FLayout.GlyphSpacing + GlyphW;
                        TextGlyphCross := Max(
                            TextH,
                            GlyphH);
                    End;

                nrgpTop, nrgpBottom: Begin
                        TextGlyphFlow := Max(
                            TextW,
                            GlyphW);
                        TextGlyphCross := TextH + FLayout.GlyphSpacing + GlyphH;
                    End;
            End;
        End Else Begin
            Case AMetrics.GlyphPosition Of
                nrgpTop, nrgpBottom: Begin
                        TextGlyphFlow := TextW + FLayout.GlyphSpacing + GlyphH;
                        TextGlyphCross := Max(
                            TextH,
                            GlyphW);
                    End;

                nrgpLeft, nrgpRight: Begin
                        TextGlyphFlow := Max(
                            TextW,
                            GlyphH);
                        TextGlyphCross := TextH + FLayout.GlyphSpacing + GlyphW;
                    End;
            End;
        End;
    End;

    AMetrics.MinorSize := Max(TextGlyphCross, SignalDiameter) + FLayout.TextSpaceOver + FLayout.TextSpaceUnder;

    //Si SameThickness est actif, tous les items visibles reçoivent la même
    //épaisseur utile. Cela évite qu'un seul glyph placé en haut ou en bas
    //augmente uniquement l'item concerné.
    If UseSameThickness And (FMaxItemMinorSize > 0) Then
        AMetrics.MinorSize := FMaxItemMinorSize;

    AMetrics.ContentLength := FLayout.TextSpaceBefore + SignalBlock + TextGlyphFlow + FLayout.TextSpaceAfter;

    If UseSameLength Then
        AMetrics.ContentLength := FMaxItemContentLength;

    //-------------------------------------------------------------------------
    //Compensations liées à la forme de l'item.
    //
    //En mode onglets :
    //- les slants consomment une partie de la longueur utile ;
    //- on ajoute donc des compensations pour éviter que le contenu ne vienne
    //trop près des pentes.
    //
    //En mode boutons :
    //- il n'y a pas de slant ;
    //- les boutons sont des formes indépendantes ;
    //- les compensations restent donc nulles.
    //-------------------------------------------------------------------------
    AMetrics.SlantPadFirst := 0;
    AMetrics.SlantPadSecond := 0;

    If IsTabBarMode And (FLayoutTabs <> Nil) Then Begin
        //---------------------------------------------------------------------
        // v52 : les slants definissent la zone utile reelle de l'onglet.
        //
        // L'ancienne compensation aux 2/3 etait suffisante pour un placement
        // visuel approximatif, mais elle n'etait pas un vrai contrat de layout :
        // avec des textes verticaux, des glyphs ou un voyant en fin d'item, le
        // contenu pouvait encore empieter sur la partie inclinee. Le moteur de
        // contenu doit recevoir les retraits complets et non une approximation,
        // car les backends ne doivent plus reparer localement les positions.
        //---------------------------------------------------------------------
        Case AMetrics.TabPosition Of
            nrtbpBottom: Begin
                    //-----------------------------------------------------------------
                    // v79 :
                    // Bottom retourne la forme de l'onglet verticalement, mais ne
                    // retourne pas le flux logique du texte horizontal.
                    //
                    // Le contenu reste compose de gauche a droite dans le repere
                    // canonique de l'item. Les retraits de slant doivent donc rester
                    // dans le meme ordre logique que pour Top :
                    //
                    // - ShapeSlantFirst  protege le debut du flux ;
                    // - ShapeSlantSecond protege la fin du flux.
                    //
                    // L'ancienne inversion First/Second decalait tout le contenu vers
                    // la droite lorsque ShapeSlantSecond etait non nul, notamment en
                    // position horizontale Bottom.
                    //-----------------------------------------------------------------
                    AMetrics.SlantPadFirst := FLayoutTabs.ShapeSlantFirst;
                    AMetrics.SlantPadSecond := FLayoutTabs.ShapeSlantSecond;
                End;

            nrtbpLeft: Begin
                    //-----------------------------------------------------------------
                    // v54 : Left ne peut pas etre traite avec une inversion unique.
                    //
                    // Pour une barre a gauche et un texte vertical, le cote de la
                    // pente rencontre par le debut du flux depend du sens du texte :
                    // - VerticalDown progresse dans le sens physique haut -> bas et
                    //   doit recevoir les retraits inverses ;
                    // - VerticalUp progresse dans le sens physique bas -> haut et
                    //   retombe sur l'ordre naturel First / Second.
                    //
                    // Le choix reste ici, dans les metriques/layout. Les renderers
                    // consomment uniquement les rectangles et ancres prepares.
                    //-----------------------------------------------------------------
                    If AMetrics.TextOrientation = nrttoVerticalDown Then Begin
                        AMetrics.SlantPadFirst := FLayoutTabs.ShapeSlantSecond;
                        AMetrics.SlantPadSecond := FLayoutTabs.ShapeSlantFirst;
                    End Else Begin
                        AMetrics.SlantPadFirst := FLayoutTabs.ShapeSlantFirst;
                        AMetrics.SlantPadSecond := FLayoutTabs.ShapeSlantSecond;
                    End;
                End;

            nrtbpRight: Begin
                    //-----------------------------------------------------------------
                    // Symetrie de Left : sur une barre a droite, c'est le flux
                    // VerticalUp qui rencontre les pentes dans l'ordre inverse.
                    //-----------------------------------------------------------------
                    If AMetrics.TextOrientation = nrttoVerticalUp Then Begin
                        AMetrics.SlantPadFirst := FLayoutTabs.ShapeSlantSecond;
                        AMetrics.SlantPadSecond := FLayoutTabs.ShapeSlantFirst;
                    End Else Begin
                        AMetrics.SlantPadFirst := FLayoutTabs.ShapeSlantFirst;
                        AMetrics.SlantPadSecond := FLayoutTabs.ShapeSlantSecond;
                    End;
                End;
        Else Begin
                AMetrics.SlantPadFirst := FLayoutTabs.ShapeSlantFirst;
                AMetrics.SlantPadSecond := FLayoutTabs.ShapeSlantSecond;
            End;
        End;
    End;
End;


Procedure TNoReflowTabBarLayoutSupport.ApplyContentLayoutEngine(
    Var AMetrics: TNoReflowTabBarItemMetrics;
    TextW: Integer;
    TextH: Integer;
    SignalDiameter: Integer;
    TopInset: Integer;
    BottomInset: Integer;
    LeftInset: Integer;
    RightInset: Integer);
Var
    LInput:  TNoReflowTabBarItemContentLayoutInput;
    LResult: TNoReflowTabBarItemContentLayoutResult;
Begin
    //-------------------------------------------------------------------------
    // Moteur canonique de contenu.
    //
    // Les anciennes routines locales CalcHorizontalContentLayout et
    // CalcVerticalContentLayout ont ete supprimees en v71 pour eviter toute
    // tentation de correction locale dans le renderer. Le resultat final
    // consomme par les backends doit provenir du moteur de layout commun
    // TNoReflowTabBarItemContentLayoutEngine.
    //
    // Ce moteur porte la regle de degradation fonctionnelle :
    // 1) tenter texte + voyant + glyph ;
    // 2) supprimer le glyph si le contenu complet ne tient pas ;
    // 3) retirer les elements optionnels avant de degrader le texte naturel ;
    // 4) raccourcir le texte uniquement si une contrainte externe l'autorise.
    //
    // Ainsi, GDI et Direct2D partagent exactement les memes rectangles locaux :
    // - TextClipRect ;
    // - GlyphRect ;
    // - SignalRect ;
    // - ancre GDI/DirectWrite du texte.
    //-------------------------------------------------------------------------
    LInput.ItemWidth := AMetrics.ButtonWidth;
    LInput.ItemHeight := AMetrics.ButtonHeight;
    LInput.TabPosition := AMetrics.TabPosition;
    LInput.TextOrientation := AMetrics.TextOrientation;

    LInput.TextWidth := TextW;
    LInput.TextHeight := TextH;

    LInput.HasSignal := AMetrics.HasSignal;
    LInput.SignalDiameter := SignalDiameter;
    LInput.SignalPosition := FSignalPosition;

    LInput.HasGlyph := AMetrics.HasGlyph;
    LInput.GlyphWidth := AMetrics.GlyphWidth;
    LInput.GlyphHeight := AMetrics.GlyphHeight;

    //---------------------------------------------------------------------
    // Le moteur attend la position logique publique du glyph.
    //
    // Il se charge lui-meme de la convertir en position physique selon
    // l'orientation du texte. Il ne faut donc pas lui transmettre
    // AMetrics.GlyphPosition, qui est deja la position tournee.
    //---------------------------------------------------------------------
    LInput.GlyphPosition := AMetrics.LogicalGlyphPosition;

    LInput.TextSpaceBefore := FLayout.TextSpaceBefore;
    LInput.TextSpaceAfter := FLayout.TextSpaceAfter;
    LInput.TextSpaceOver := FLayout.TextSpaceOver;
    LInput.TextSpaceUnder := FLayout.TextSpaceUnder;
    LInput.SignalSpacing := FLayout.SignalSpacing;
    LInput.GlyphSpacing := FLayout.GlyphSpacing;

    LInput.SlantPadFirst := AMetrics.SlantPadFirst;
    LInput.SlantPadSecond := AMetrics.SlantPadSecond;

    //---------------------------------------------------------------------
    //REGLE D'OR v73 : le renderer ne decide pas de raccourcir un texte.
    //
    //Il transmet seulement au moteur de layout le fait qu'une contrainte
    //externe existe. En mode onglet naturel, aucune contrainte de ce type
    //n'existe : le texte doit rester entier.
    //
    //Le seul cas actuellement autorise est le mode bouton avec ForcedLength,
    //car l'utilisateur impose alors explicitement une longueur pouvant etre
    //inferieure au contenu naturel.
    //---------------------------------------------------------------------
    LInput.AllowTextShortening :=
        IsButtonBarMode And
        (FLayoutButtons <> Nil) And
        (FLayoutButtons.ForcedLength > 0);

    //---------------------------------------------------------------------
    //REGLE D'OR v74 : l'autorisation d'ellipse est une donnée de layout.
    //
    //Les renderers GDI et Direct2D peuvent avoir des métriques de police
    //légèrement différentes. Ils ne doivent donc pas décider seuls qu'un texte
    //naturel doit devenir "Ong...".
    //
    //Même règle que pour le raccourcissement fonctionnel : ellipse autorisée
    //uniquement lorsqu'une contrainte externe volontaire existe.
    //---------------------------------------------------------------------
    AMetrics.AllowTextTrimming := LInput.AllowTextShortening;

    LInput.LeftInset := LeftInset;
    LInput.TopInset := TopInset;
    LInput.RightInset := RightInset;
    LInput.BottomInset := BottomInset;

    TNoReflowTabBarItemContentLayoutEngine.Resolve(
        LInput,
        LResult);

    AMetrics.TextClipRect := LResult.TextRect;
    AMetrics.TextX := LResult.TextAnchorX;
    AMetrics.TextY := LResult.TextAnchorY;

    AMetrics.GlyphRect := LResult.GlyphRect;
    AMetrics.SignalRect := LResult.SignalRect;

    //---------------------------------------------------------------------
    // Les flags de rendu doivent etre derives du resultat de layout final,
    // pas de la configuration utilisateur initiale.
    //
    // C'est ce qui garantit que le glyph ne sera plus dessine lorsqu'il a ete
    // supprime par le moteur parce que la largeur forcee est insuffisante.
    //---------------------------------------------------------------------
    AMetrics.HasGlyph := Not IsRectEmpty(AMetrics.GlyphRect);
    AMetrics.HasSignal := Not IsRectEmpty(AMetrics.SignalRect);
End;


Procedure TNoReflowTabBarLayoutSupport.CalcTabMetrics(
    AItem: TNoReflowTabBarItem;
    ASelected: Boolean;
    Out AMetrics: TNoReflowTabBarItemMetrics);
Var
    TextW:          Integer;
    TextH:          Integer;
    SignalDiameter: Integer;
    TopInset:       Integer;
    BottomInset:    Integer;
    LeftInset:      Integer;
    RightInset:     Integer;

Begin
    //-------------------------------------------------------------------------
    //Routine centrale de construction d’un TNoreflowTabMetrics complet.
    //
    //Cette méthode orchestre tout le calcul géométrique interne d’un onglet :
    //1) orientation réelle du texte
    //2) mesures de base
    //3) dimensions externes du bouton
    //4) retraits imposés par la géométrie
    //5) position finale du texte et du signal
    //
    //Le résultat peut ensuite être utilisé :
    //- pour le layout des lignes / colonnes
    //- pour le dessin
    //- pour le calcul des bounds
    //-------------------------------------------------------------------------

    //Réinitialisation complète de la structure.
    FillChar(
        AMetrics,
        SizeOf(AMetrics),
        0);

    //La position actuelle de la barre fait partie intégrante des métriques.
    AMetrics.TabPosition := FBarPosition;

    //Détermine le sens réel du texte.
    ResolveMetricsTextOrientation(AMetrics);

    //Calcule les mesures fondamentales.
    CalcMetricsBaseSizes(
        AItem,
        ASelected,
        AMetrics,
        TextW,
        TextH,
        SignalDiameter);

    //Déduit la taille finale du bouton.
    CalcMetricsButtonSize(AMetrics);

    //Calcule les retraits internes dus à la géométrie.
    CalcMetricsInsets(
        AMetrics,
        TopInset,
        BottomInset,
        LeftInset,
        RightInset);

    //Termine par le placement precis du contenu selon l'orientation retenue.
    //
    // REGLE D'ARCHITECTURE : le layout calcule les rectangles, les points
    // d'ancrage et les decisions de degradation. Les renderers GDI/Direct2D ne
    // doivent pas corriger localement ces positions.
    //
    // En v46, les textes verticaux etaient revenus a une routine locale
    // specifique pour restaurer les ancres validees en v38. Cette correction
    // etait visuellement utile mais elle reinstallait deux chemins de calcul :
    // - moteur commun pour Horizontal ;
    // - routine historique pour VerticalUp / VerticalDown.
    //
    // La v47 remet donc toutes les orientations dans le meme moteur canonique.
    // La correction des textes verticaux est portee dans
    // TNoReflowTabBarItemContentLayoutEngine lui-meme : le moteur retourne les
    // ancres TextX/TextY compatibles avec TextOut/DirectWrite apres rotation.
    ApplyContentLayoutEngine(
        AMetrics,
        TextW,
        TextH,
        SignalDiameter,
        TopInset,
        BottomInset,
        LeftInset,
        RightInset);
End;


Function TNoReflowTabBarLayoutSupport.IsTabBarMode: Boolean;
Begin
    //-------------------------------------------------------------------------
    //Indique si le mode courant doit utiliser la géométrie historique d'onglets.
    //
    //Pour l'instant, seul nrbmTabs utilise :
    //- les slants ;
    //- le recouvrement ;
    //- l'arête de contact éventuellement ouverte ;
    //- le dessin sélectionné au-dessus des autres onglets.
    //-------------------------------------------------------------------------
    Result := FBarMode = nrbmTabs;
End;


Function TNoReflowTabBarLayoutSupport.IsButtonBarMode: Boolean;
Begin
    //-------------------------------------------------------------------------
    //Indique si le mode courant doit utiliser la géométrie bouton.
    //
    //Les trois modes boutons partagent le même rendu de base :
    //- boutons simples ;
    //- boutons à sélection unique ;
    //- boutons cochables.
    //
    //Leur différence est surtout comportementale. Le rendu exploite ensuite
    //l'état visuel résolu : normal, hot, pressed, selected ou disabled.
    //-------------------------------------------------------------------------
    Result := FBarMode In [nrbmPushButtons, nrbmSelectButtons, nrbmCheckButtons];
End;


Function TNoReflowTabBarLayoutSupport.UseSameLength: Boolean;
Begin
    //-------------------------------------------------------------------------
    //Indique si l'égalisation de longueur est active.
    //
    //Cette option appartient maintenant au layout commun TNoReflowTabBarLayout.
    //Elle s'applique donc aussi bien :
    //- aux onglets ;
    //- aux boutons.
    //
    //En mode bouton, cette option reste cohérente avec ForcedLength :
    //- ForcedLength, s'il est défini, aura priorité ;
    //- sinon SameLength peut uniformiser la longueur naturelle.
    //-------------------------------------------------------------------------
    Result := (FLayout <> Nil) And FLayout.SameLength;
End;


Function TNoReflowTabBarLayoutSupport.UseSameThickness: Boolean;
Begin
    //-------------------------------------------------------------------------
    //Indique si l'égalisation d'épaisseur est active.
    //
    //Cette option appartient au layout commun TNoReflowTabBarLayout.
    //Elle reste donc utilisable par les onglets et par les boutons.
    //
    //En mode bouton, cette option reste cohérente avec ForcedThickness :
    //- ForcedThickness, s'il est défini, aura priorité ;
    //- sinon SameThickness peut uniformiser l'épaisseur naturelle.
    //-------------------------------------------------------------------------
    Result := (FLayout <> Nil) And FLayout.SameThickness;
End;


Function TNoReflowTabBarLayoutSupport.GetMaxTabContentLength: Integer;
Begin
    //-------------------------------------------------------------------------
    //Retourne simplement la valeur actuellement mémorisée
    //pour la plus grande longueur de contenu.
    //
    //Cette fonction est surtout un point d’accès propre à une donnée interne,
    //utile si l’on veut debugger, journaliser ou réutiliser cette valeur
    //sans exposer directement le champ.
    //-------------------------------------------------------------------------
    Result := FMaxItemContentLength;
End;


Procedure TNoReflowTabBarLayoutSupport.ResolveMetricsTextOrientation(Var AMetrics: TNoReflowTabBarItemMetrics);
Begin
    //-------------------------------------------------------------------------
    //Détermine l’orientation effectivement utilisée pour afficher le texte.
    //
    //Le composant peut fonctionner :
    //- en orientation imposée par BarTextOrientation
    //- ou en mode automatique (nrttoAuto)
    //
    //En mode automatique :
    //- top / bottom  -> texte horizontal
    //- left          -> texte vertical montant
    //- right         -> texte vertical descendant
    //
    //Cette routine ne place rien encore.
    //Elle fixe seulement la stratégie d’affichage du texte
    //pour les calculs qui suivent.
    //-------------------------------------------------------------------------

    //Point de départ : on reprend la valeur demandée par la propriété publique.
    AMetrics.TextOrientation := FTextOrientation;

    //Si l’orientation est automatique, on la déduit de la position de barre.
    If AMetrics.TextOrientation = nrttoAuto Then Begin
        Case FBarPosition Of
            nrtbpTop, nrtbpBottom:
                AMetrics.TextOrientation := nrttoHorizontal;

            nrtbpLeft:
                AMetrics.TextOrientation := nrttoVerticalUp;

            nrtbpRight:
                AMetrics.TextOrientation := nrttoVerticalDown;
        End;
    End;

    //Ce booléen est un raccourci très utile pour tout le reste du pipeline :
    //il permet de savoir immédiatement si le contenu doit être raisonné
    //dans un flux vertical ou non.
    AMetrics.VerticalFlow := AMetrics.TextOrientation In [nrttoVerticalUp, nrttoVerticalDown];
End;


Procedure TNoReflowTabBarLayoutSupport.CalcMetricsButtonSize(Var AMetrics: TNoReflowTabBarItemMetrics);
var
    ShapeSlantFirst:  Integer;
    ShapeSlantSecond: Integer;
    LengthUsesHeight: Boolean;
Begin
    //-------------------------------------------------------------------------
    //Déduit la taille externe complète de l'item.
    //
    //Cette routine combine :
    //- les dimensions de contenu calculées avec le layout commun ;
    //- les compensations de forme issues du layout onglet.
    //
    //Découpage important :
    //- ContentLength / MinorSize viennent des espacements communs ;
    //- les slants viennent de FLayoutTabs, car ils sont propres au rendu onglet.
    //-------------------------------------------------------------------------

    ShapeSlantFirst := 0;
    ShapeSlantSecond := 0;

    If IsTabBarMode And (FLayoutTabs <> Nil) Then Begin
        ShapeSlantFirst := FLayoutTabs.ShapeSlantFirst;
        ShapeSlantSecond := FLayoutTabs.ShapeSlantSecond;
    End;

    Case AMetrics.TabPosition Of
        nrtbpTop, nrtbpBottom: Begin
                If Not AMetrics.VerticalFlow Then Begin
                    //-----------------------------------------------------------------
                    //Barre horizontale + texte horizontal.
                    //-----------------------------------------------------------------
                    AMetrics.ButtonHeight := AMetrics.MinorSize + 1;
                    AMetrics.ButtonWidth := AMetrics.ContentLength + AMetrics.SlantPadFirst + AMetrics.SlantPadSecond;
                End Else Begin
                    //-----------------------------------------------------------------
                    //Barre horizontale + texte vertical.
                    //-----------------------------------------------------------------
                    AMetrics.ButtonWidth := AMetrics.MinorSize + ShapeSlantFirst + ShapeSlantSecond + 1;

                    AMetrics.ButtonHeight := AMetrics.ContentLength;
                End;
            End;

        nrtbpLeft, nrtbpRight: Begin
                If Not AMetrics.VerticalFlow Then Begin
                    //-----------------------------------------------------------------
                    //Barre verticale + texte horizontal.
                    //-----------------------------------------------------------------
                    AMetrics.ButtonHeight := AMetrics.MinorSize + ShapeSlantFirst + ShapeSlantSecond + 1;

                    AMetrics.ButtonWidth := AMetrics.ContentLength;
                End Else Begin
                    //-----------------------------------------------------------------
                    //Barre verticale + texte vertical.
                    //-----------------------------------------------------------------
                    AMetrics.ButtonWidth := AMetrics.MinorSize + 1;
                    AMetrics.ButtonHeight := AMetrics.ContentLength + AMetrics.SlantPadFirst + AMetrics.SlantPadSecond;
                End;
            End;
    End;

    If IsButtonBarMode And (FLayoutButtons <> Nil) Then Begin
        //---------------------------------------------------------------------
        //Dimensionnement spcifique au mode boutons.
        //
        //Rgle imprative : Length et Thickness sont des dimensions logiques.
        //Ils ne doivent jamais tre assimils directement  Width et Height.
        //
        //Length suit l'axe de flux du contenu :
        //- texte horizontal  -> dimension physique X, donc ButtonWidth ;
        //- texte vertical    -> dimension physique Y, donc ButtonHeight.
        //
        //Thickness suit l'axe secondaire, perpendiculaire au flux :
        //- texte horizontal  -> dimension physique Y, donc ButtonHeight ;
        //- texte vertical    -> dimension physique X, donc ButtonWidth.
        //
        //ForcedLength conserve son comportement historique sur l'axe logique :
        //il impose une longueur fixe et ignore donc la taille naturelle du
        //contenu.
        //
        //MinimumLength ne s'applique que lorsque ForcedLength vaut 0. Dans ce
        //cas, la longueur naturelle calcule plus haut reste prioritaire tant
        //qu'elle dpasse le minimum demand. Les boutons courts sont simplement
        //allongs jusqu' cette limite, sans changer l'paisseur.
        //---------------------------------------------------------------------
        LengthUsesHeight := AMetrics.VerticalFlow;

        If LengthUsesHeight Then Begin
            If FLayoutButtons.ForcedLength > 0 Then
                AMetrics.ButtonHeight := FLayoutButtons.ForcedLength
            Else If (FLayoutButtons.MinimumLength > 0) And
                    (AMetrics.ButtonHeight < FLayoutButtons.MinimumLength) Then
                AMetrics.ButtonHeight := FLayoutButtons.MinimumLength;

            If FLayoutButtons.ForcedThickness > 0 Then
                AMetrics.ButtonWidth := FLayoutButtons.ForcedThickness;
        End Else Begin
            If FLayoutButtons.ForcedLength > 0 Then
                AMetrics.ButtonWidth := FLayoutButtons.ForcedLength
            Else If (FLayoutButtons.MinimumLength > 0) And
                    (AMetrics.ButtonWidth < FLayoutButtons.MinimumLength) Then
                AMetrics.ButtonWidth := FLayoutButtons.MinimumLength;

            If FLayoutButtons.ForcedThickness > 0 Then
                AMetrics.ButtonHeight := FLayoutButtons.ForcedThickness;
        End;
    End;
End;


Procedure TNoReflowTabBarLayoutSupport.CalcMetricsInsets(
    Const AMetrics: TNoReflowTabBarItemMetrics;
    Out TopInset, BottomInset, LeftInset, RightInset: Integer);
Begin
    //-------------------------------------------------------------------------
    //Détermine les retraits internes imposés par la géométrie de l'item.
    //
    //Les retraits liés aux pentes utilisent maintenant FLayoutTabs, car les
    //slants appartiennent à la forme d'onglet et non au layout commun.
    //-------------------------------------------------------------------------

    TopInset := 0;
    BottomInset := 0;
    LeftInset := 0;
    RightInset := 0;

    If Not IsTabBarMode Then
        Exit;

    If FLayoutTabs = Nil Then
        Exit;

    Case AMetrics.TabPosition Of
        nrtbpTop: Begin
                If AMetrics.VerticalFlow Then Begin
                    LeftInset := FLayoutTabs.ShapeSlantFirst;
                    RightInset := FLayoutTabs.ShapeSlantSecond;
                End;
            End;

        nrtbpBottom: Begin
                If AMetrics.VerticalFlow Then Begin
                    LeftInset := FLayoutTabs.ShapeSlantFirst;
                    RightInset := FLayoutTabs.ShapeSlantSecond;
                End;
            End;

        nrtbpLeft: Begin
                If Not AMetrics.VerticalFlow Then Begin
                    TopInset := FLayoutTabs.ShapeSlantSecond;
                    BottomInset := FLayoutTabs.ShapeSlantFirst;
                End;
            End;

        nrtbpRight: Begin
                If Not AMetrics.VerticalFlow Then Begin
                    TopInset := FLayoutTabs.ShapeSlantFirst;
                    BottomInset := FLayoutTabs.ShapeSlantSecond;
                End;
            End;
    End;
End;


Procedure TNoReflowTabBarLayoutSupport.CalcOutlineBasePoints(
    Const ARect: TRect;
    Out P0, P1, P2, P3: TPoint;
    Out Radius1, Radius2: Integer);
Var
    R:      TRect;
    LSlant: Integer;
    RSlant: Integer;
Begin
    //-------------------------------------------------------------------------
    //Calcule les 4 sommets principaux de la forme de l'item.
    //
    //La forme de l'onglet est maintenant pilotée par FLayoutTabs :
    //- ShapeSlantFirst / ShapeSlantSecond ;
    //- ShapeRadiusFirst / ShapeRadiusSecond.
    //
    //Le layout commun ne doit pas porter ces propriétés, car le mode
    //boutons a géométrie propre, sans slant.
    //-------------------------------------------------------------------------

    R := ARect;

    If R.Right <= R.Left Then
        R.Right := R.Left + 1;

    If R.Bottom <= R.Top Then
        R.Bottom := R.Top + 1;

    LSlant := FLayoutTabs.ShapeSlantFirst;
    RSlant := FLayoutTabs.ShapeSlantSecond;

    Case FBarPosition Of
        nrtbpTop: Begin
                P0 := Point(
                    R.Left,
                    R.Bottom - 1);

                P1 := Point(
                    R.Left + LSlant,
                    R.Top);

                P2 := Point(
                    R.Right - 1 - RSlant,
                    R.Top);

                P3 := Point(
                    R.Right - 1,
                    R.Bottom - 1);

                Radius1 := FLayoutTabs.ShapeRadiusFirst;
                Radius2 := FLayoutTabs.ShapeRadiusSecond;
            End;

        nrtbpBottom: Begin
                P0 := Point(
                    R.Right - 1,
                    R.Top);

                P1 := Point(
                    R.Right - 1 - RSlant,
                    R.Bottom - 1);

                P2 := Point(
                    R.Left + LSlant,
                    R.Bottom - 1);

                P3 := Point(
                    R.Left,
                    R.Top);

                Radius1 := FLayoutTabs.ShapeRadiusSecond;
                Radius2 := FLayoutTabs.ShapeRadiusFirst;
            End;

        nrtbpLeft: Begin
                P0 := Point(
                    R.Right - 1,
                    R.Bottom - 1);

                P1 := Point(
                    R.Left,
                    R.Bottom - 1 - LSlant);

                P2 := Point(
                    R.Left,
                    R.Top + RSlant);

                P3 := Point(
                    R.Right - 1,
                    R.Top);

                Radius1 := FLayoutTabs.ShapeRadiusFirst;
                Radius2 := FLayoutTabs.ShapeRadiusSecond;
            End;

        nrtbpRight: Begin
                P0 := Point(
                    R.Left,
                    R.Top);

                P1 := Point(
                    R.Right - 1,
                    R.Top + LSlant);

                P2 := Point(
                    R.Right - 1,
                    R.Bottom - 1 - RSlant);

                P3 := Point(
                    R.Left,
                    R.Bottom - 1);

                Radius1 := FLayoutTabs.ShapeRadiusFirst;
                Radius2 := FLayoutTabs.ShapeRadiusSecond;
            End;
    Else Begin
            P0 := Point(
                R.Left,
                R.Bottom - 1);

            P1 := Point(
                R.Left + LSlant,
                R.Top);

            P2 := Point(
                R.Right - 1 - RSlant,
                R.Top);

            P3 := Point(
                R.Right - 1,
                R.Bottom - 1);

            Radius1 := FLayoutTabs.ShapeRadiusFirst;
            Radius2 := FLayoutTabs.ShapeRadiusSecond;
        End;
    End;
End;


Procedure TNoReflowTabBarLayoutSupport.BuildTabOutlinePoints(
    Const ARect: TRect;
    APoints: TList<TPoint>);
Const
    CMaxRadiusFactor = 0.45;
Var
    P0:       TPoint;
    P1:       TPoint;
    P2:       TPoint;
    P3:       TPoint;
    Radius1:  Integer;
    Radius2:  Integer;
    SafeRad1: Double;
    SafeRad2: Double;
    Dist01:   Double;
    Dist12:   Double;
    Dist23:   Double;
Begin
    //-------------------------------------------------------------------------
    //Construit le contour polygonal final de l’onglet.
    //
    //Cette routine transforme la charpente géométrique calculée par
    //CalcOutlineBasePoints en une vraie suite de points exploitable :
    //- pour le remplissage
    //- pour le tracé de bordure
    //- pour le hit-test polygonal
    //
    //Si des rayons sont demandés, les coins P1 et P2 sont remplacés
    //par une approximation discrète d’arc arrondi.
    //-------------------------------------------------------------------------

    //Nettoyage impératif du buffer de sortie.
    APoints.Clear;

    //Récupère les 4 points de base et les rayons théoriques.
    CalcOutlineBasePoints(
        ARect,
        P0,
        P1,
        P2,
        P3,
        Radius1,
        Radius2);

    //Mesure des longueurs des trois segments principaux.
    //
    //Ces distances servent à vérifier qu’un rayon demandé est réaliste
    //par rapport à la taille réelle de l'item.
    Dist01 := Sqrt(Sqr(P1.X - P0.X) + Sqr(P1.Y - P0.Y));
    Dist12 := Sqrt(Sqr(P2.X - P1.X) + Sqr(P2.Y - P1.Y));
    Dist23 := Sqrt(Sqr(P3.X - P2.X) + Sqr(P3.Y - P2.Y));

    //-------------------------------------------------------------------------
    //Sécurisation du rayon du premier coin.
    //
    //Un rayon trop grand provoquerait :
    //- un coin qui "mange" tout le segment
    //- un arrondi incohérent
    //- voire une géométrie auto-chevauchante
    //
    //On borne donc le rayon à une fraction de chacun des segments adjacents.
    //-------------------------------------------------------------------------
    SafeRad1 := Radius1;
    If SafeRad1 > Dist01 * CMaxRadiusFactor Then
        SafeRad1 := Dist01 * CMaxRadiusFactor;
    If SafeRad1 > Dist12 * CMaxRadiusFactor Then
        SafeRad1 := Dist12 * CMaxRadiusFactor;

    //Même logique pour le second coin.
    SafeRad2 := Radius2;
    If SafeRad2 > Dist12 * CMaxRadiusFactor Then
        SafeRad2 := Dist12 * CMaxRadiusFactor;
    If SafeRad2 > Dist23 * CMaxRadiusFactor Then
        SafeRad2 := Dist23 * CMaxRadiusFactor;

    //-------------------------------------------------------------------------
    //Construction effective du chemin.
    //
    //On démarre sur P0, puis :
    //- on remplace le coin P1 par un arrondi si nécessaire
    //- on remplace le coin P2 par un arrondi si nécessaire
    //- on termine sur P3
    //
    //AddPointIfNeeded évite les doublons de sommets.
    //AddRoundedCorner insère soit un simple point d’angle,
    //soit plusieurs points intermédiaires si un rayon est actif.
    //-------------------------------------------------------------------------
    AddPointIfNeeded(
        APoints,
        P0);
    AddRoundedCorner(
        APoints,
        P0,
        P1,
        P2,
        SafeRad1);
    AddRoundedCorner(
        APoints,
        P1,
        P2,
        P3,
        SafeRad2);
    AddPointIfNeeded(
        APoints,
        P3);
End;


Procedure TNoReflowTabBarLayoutSupport.BuildButtonOutlinePoints(
    Const ARect: TRect;
    APoints: TList<TPoint>);
Var
    R:      TRect;
    Radius: Integer;
    MaxRad: Integer;

    Procedure AddButtonPoint(AX, AY: Integer);
    Begin
        AddPointIfNeeded(
            APoints,
            Point(AX, AY));
    End;

Begin
    //-------------------------------------------------------------------------
    //Construit le contour polygonal d'un bouton.
    //
    //Contrairement aux onglets, un bouton est une forme autonome et fermée.
    //Son contour doit donc contenir explicitement les quatre côtés, y compris
    //le côté gauche.
    //
    //Pourquoi ne pas déléguer uniquement à AddRoundedCorner ?
    //
    //AddRoundedCorner fonctionne très bien pour les coins d'onglets, mais pour
    //un bouton fermé elle peut produire un chemin visuellement correct pour le
    //remplissage tout en laissant un côté insuffisamment explicite pour le tracé
    //anti-aliasé de la bordure.
    //
    //Ici, on construit donc un contour fermé dans un ordre clair :
    //- haut gauche vers haut droit ;
    //- côté droit ;
    //- bas ;
    //- côté gauche.
    //
    //Le hit-test, le remplissage et la bordure utilisent ainsi exactement la
    //même géométrie.
    //-------------------------------------------------------------------------

    If APoints = Nil Then
        Exit;

    APoints.Clear;

    R := ARect;

    If R.Right <= R.Left Then
        R.Right := R.Left + 1;

    If R.Bottom <= R.Top Then
        R.Bottom := R.Top + 1;

    Radius := 0;

    If FLayoutButtons <> Nil Then
        Radius := FLayoutButtons.CornerRadius;

    If Radius < 0 Then
        Radius := 0;

    //Le rayon ne doit jamais dépasser la moitié de la largeur ou de la hauteur,
    //sinon les coins peuvent se croiser sur les petits boutons.
    MaxRad := Min(
        (R.Right - R.Left) Div 2,
        (R.Bottom - R.Top) Div 2);

    If Radius > MaxRad Then
        Radius := MaxRad;

    //Rectangle simple.
    //
    //On ajoute volontairement les quatre coins dans l'ordre complet.
    //Le dernier segment, de bas-gauche vers haut-gauche, sera tracé par la
    //fermeture de la bordure.
    If Radius = 0 Then Begin
        AddButtonPoint(
            R.Left,
            R.Top);

        AddButtonPoint(
            R.Right - 1,
            R.Top);

        AddButtonPoint(
            R.Right - 1,
            R.Bottom - 1);

        AddButtonPoint(
            R.Left,
            R.Bottom - 1);

        Exit;
    End;

    //Rectangle arrondi.
    //
    //Les points intermédiaires restent volontairement simples.
    //L'objectif ici n'est pas de générer une courbe mathématique parfaite, mais
    //un contour fermé, stable, lisible, compatible avec le remplissage et le
    //tracé anti-aliasé.
    AddButtonPoint(
        R.Left + Radius,
        R.Top);

    AddButtonPoint(
        R.Right - 1 - Radius,
        R.Top);

    AddRoundedCorner(
        APoints,
        Point(R.Left + Radius, R.Top),
        Point(R.Right - 1, R.Top),
        Point(R.Right - 1, R.Top + Radius),
        Radius);

    AddButtonPoint(
        R.Right - 1,
        R.Bottom - 1 - Radius);

    AddRoundedCorner(
        APoints,
        Point(R.Right - 1, R.Top + Radius),
        Point(R.Right - 1, R.Bottom - 1),
        Point(R.Right - 1 - Radius, R.Bottom - 1),
        Radius);

    AddButtonPoint(
        R.Left + Radius,
        R.Bottom - 1);

    AddRoundedCorner(
        APoints,
        Point(R.Right - 1 - Radius, R.Bottom - 1),
        Point(R.Left, R.Bottom - 1),
        Point(R.Left, R.Bottom - 1 - Radius),
        Radius);

    AddButtonPoint(
        R.Left,
        R.Top + Radius);

    AddRoundedCorner(
        APoints,
        Point(R.Left, R.Bottom - 1 - Radius),
        Point(R.Left, R.Top),
        Point(R.Left + Radius, R.Top),
        Radius);
End;


Procedure TNoReflowTabBarLayoutSupport.BuildItemOutlinePoints(
    Const ARect: TRect;
    APoints: TList<TPoint>);
Begin
    //-------------------------------------------------------------------------
    //Construit le contour réel d'un item selon le mode courant.
    //
    //Mode onglets :
    //- contour historique avec slants et rayons issus de BarLayoutTabs.
    //
    //Modes boutons :
    //- contour de bouton indépendant, sans slant ni recouvrement.
    //-------------------------------------------------------------------------

    If IsButtonBarMode Then
        BuildButtonOutlinePoints(
            ARect,
            APoints)
    Else
        BuildTabOutlinePoints(
            ARect,
            APoints);
End;


Procedure TNoReflowTabBarLayoutSupport.BuildRenderItemRegions;
Var
    I:      Integer;
    Points: TList<TPoint>;
Begin
    //-------------------------------------------------------------------------
    //Construit le contour polygonal réel de chaque item visible.
    //
    //On le fait après le layout, car la forme dépend du rectangle final.
    //
    //Ces polygones servent ensuite simultanément à :
    //- remplir le fond de l’item
    //- tracer la bordure
    //- effectuer un hit-test précis à la souris
    //
    //Une liste temporaire est réutilisée pour éviter de réallouer
    //une structure intermédiaire complète à chaque itération.
    //-------------------------------------------------------------------------

    Points := TList<TPoint>.Create;
    Try
        For I := 0 To High(FRenderItems) Do Begin
            If Not FRenderItems[I].Visible Then
                Continue;

            BuildItemOutlinePoints(
                FRenderItems[I].Bounds,
                Points);
            FRenderItems[I].RegionPoints := Points.ToArray;
        End;
    Finally
        Points.Free;
    End;
End;


Procedure TNoReflowTabBarLayoutSupport.RebuildRenderInfo;
Begin
    //-------------------------------------------------------------------------
    //Recalcule intégralement la structure de rendu FRenderItems.
    //
    //Ordre logique :
    //1) adapter la taille du tableau au nombre d’items métier
    //2) recalculer la longueur max si SameLength = True
    //3) initialiser les render items avec leurs métriques de base
    //4) positionner les items selon l’orientation de la barre
    //5) construire les contours polygonaux réels
    //
    //UsedWidth / UsedHeight servent à récupérer l’encombrement global
    //du layout produit, même si ce n’est pas cette routine qui ajuste
    //directement la taille physique du contrôle.
    //-------------------------------------------------------------------------

    FZoneLayoutInfo.Init;

    //Le tableau de rendu a exactement la même cardinalité que FTabs.
    SetLength(
        FRenderItems,
        FItems.Count);

    //Si les items doivent être uniformisés en longueur,
    //on calcule d’abord la longueur de référence.
    RecalcMaxTabContentLength;

    //Prépare chaque render item avant placement final.
    InitRenderItems;

    FLayoutUsedWidth := 0;
    FLayoutUsedHeight := 0;

    Case FBarPosition Of
        nrtbpTop, nrtbpBottom:
            LayoutHorizontalItems(FLayoutUsedWidth, FLayoutUsedHeight);

        nrtbpLeft, nrtbpRight:
            LayoutVerticalItems(FLayoutUsedWidth, FLayoutUsedHeight);
    End;

    //Une fois les bounds calculés et éventuellement ajustés, on peut construire
    //les vrais contours utilisés pour le rendu et le hit-test.
    BuildRenderItemRegions;
End;


Procedure TNoReflowTabBarLayoutSupport.EnsureRenderInfo;
Begin
    //-------------------------------------------------------------------------
    //Point d’entrée paresseux du pipeline de rendu.
    //
    //Dès qu’une méthode a besoin de FRenderItems fiable
    //(paint, hit-test, relayout, etc.), elle passe ici.
    //
    //Si rien n’a changé depuis le dernier calcul, on ne fait rien.
    //Sinon, on reconstruit entièrement la structure intermédiaire.
    //-------------------------------------------------------------------------
    If FRenderDirty Then Begin
        RebuildRenderInfo;
        FRenderDirty := False;
    End;
End;


Procedure TNoReflowTabBarLayoutSupport.InitRenderItems;
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Initialise FRenderItems à partir de FItems.
    //
    //À ce stade, on ne connaît pas encore la position finale de chaque item
    //dans la barre, mais on peut déjà calculer :
    //- son état logique
    //- ses métriques propres
    //- sa taille de base
    //
    //Point important :
    //les métriques de layout sont toujours calculées avec la police de l'état
    //sélectionné, même pour les items actuellement non sélectionnés.
    //
    //Pourquoi ?
    //La sélection peut ajouter du gras, du souligné, etc. Si l'on mesurait les
    //items non sélectionnés avec la police normale, un item pourrait changer
    //de largeur ou d'épaisseur au moment où il devient sélectionné.
    //
    //Le layout doit donc réserver dès le départ la place maximale nécessaire.
    //Le rendu, lui, reste indépendant :
    //- DrawTabText reçoit encore l'état réel de sélection ;
    //- seul l'item réellement sélectionné est dessiné avec la police enrichie.
    //
    //Cette règle vaut autant pour le mode onglets que pour les modes boutons.
    //Elle évite tout "saut" de taille au changement de sélection.
    //
    //Les Bounds créés ici sont donc seulement des rectangles "locaux"
    //initialisés à l’origine, qui seront repositionnés ensuite
    //par LayoutHorizontalTabs ou LayoutVerticalTabs.
    //-------------------------------------------------------------------------

    For I := 0 To FItems.Count - 1 Do Begin
        //Lien direct vers l’item métier source.
        FRenderItems[I].Item := FItems[I];
        FRenderItems[I].ItemIndex := I;

        //Copie des états métier utiles au rendu.
        FRenderItems[I].Visible := FItems[I].Visible;
        FRenderItems[I].Enabled := FItems[I].Enabled;

        //États dérivés de la sélection et du hot-tracking courant.
        FRenderItems[I].Selected := I = FItemIndex;
        FRenderItems[I].Hot := I = FHotItemIndex;

        //Les métriques n’ont de sens que pour un item visible.
        //Pour un item masqué, on remet simplement la structure à zéro.
        If FRenderItems[I].Visible Then
            CalcTabMetrics(
                FItems[I],
                True,
                FRenderItems[I].Metrics)
        Else
            FillChar(
                FRenderItems[I].Metrics,
                SizeOf(TNoReflowTabBarItemMetrics),
                0);

        //Bounds provisoire :
        //largeur / hauteur connues, mais position finale encore inconnue.
        FRenderItems[I].Bounds := Rect(
            0,
            0,
            FRenderItems[I].Metrics.ButtonWidth,
            FRenderItems[I].Metrics.ButtonHeight);

        //Le contour polygonal exact sera calculé dans un second temps,
        //une fois les Bounds définitifs connus.
        SetLength(
            FRenderItems[I].RegionPoints,
            0);
    End;
End;


Procedure TNoReflowTabBarLayoutSupport.SetupItemCanvasFont(ASelected: Boolean);
Begin
    //-------------------------------------------------------------------------
    //Prépare la police du canvas avant une mesure ou un dessin de texte.
    //
    //Règle :
    //- on repart toujours de la police standard du contrôle
    //- si l’item est sélectionné, on ajoute les styles spécifiques
    //
    //Cette centralisation évite d’avoir plusieurs variantes de logique
    //éparpillées dans les routines de mesure et de rendu.
    //-------------------------------------------------------------------------

    //Repart toujours de la police de base du contrôle.
    PaintCanvas.Font.Assign(Font);

    //Si l’item est sélectionné, on enrichit le style de police.
    If ASelected Then
        PaintCanvas.Font.Style := PaintCanvas.Font.Style + FSelectedFontStyle;
End;


Function TNoReflowTabBarLayoutSupport.RotateGlyphPositionForTextOrientation(
    AGlyphPosition: TNoReflowTabBarGlyphPosition;
    ATextOrientation: TNoReflowTabBarTextOrientation): TNoReflowTabBarGlyphPosition;
Begin
    //-------------------------------------------------------------------------
    //Convertit une position logique de glyph autour d'un texte horizontal
    //canonique vers la position réelle autour du texte effectivement dessiné.
    //
    //Convention logique de départ :
    //- Left   : avant le texte sur l'axe horizontal ;
    //- Right  : après le texte sur l'axe horizontal ;
    //- Top    : au-dessus du texte ;
    //- Bottom : au-dessous du texte.
    //
    //Quand le texte est vertical, ces positions doivent être tournées avec le
    //texte, sinon le glyph reste positionné comme si le texte était horizontal.
    //
    //Cas nrttoVerticalUp :
    //- le texte est tourné vers le haut ;
    //- Left devient Bottom ;
    //- Right devient Top ;
    //- Top devient Left ;
    //- Bottom devient Right.
    //
    //Cas nrttoVerticalDown :
    //- le texte est tourné vers le bas ;
    //- Left devient Top ;
    //- Right devient Bottom ;
    //- Top devient Right ;
    //- Bottom devient Left.
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


Function TNoReflowTabBarLayoutSupport.ResolveLogicalGlyphPosition(AItem: TNoReflowTabBarItem): TNoReflowTabBarGlyphPosition;
Begin
    //-------------------------------------------------------------------------
    //Resout la position logique du glyph.
    //
    //GARDE-FOU MAJEUR : cette fonction ne tient volontairement pas compte de
    //TextOrientation. Elle retourne la position dans le repere horizontal
    //canonique, c'est-a-dire le repere dans lequel les regles publiques sont
    //definies.
    //
    //Cette position doit etre utilisee pour decider si un comportement doit
    //etre applique de la meme maniere en horizontal, VerticalUp et VerticalDown.
    //Exemple critique : MinimumLength recentre le bloc glyph + texte uniquement
    //si le glyph est LOGIQUEMENT au-dessus ou au-dessous du texte.
    //-------------------------------------------------------------------------

    Result := FLayout.GlyphPosition;

    If AItem <> Nil Then Begin
        Case AItem.GlyphPosition Of
            nrigpLeft:
                Result := nrgpLeft;

            nrigpRight:
                Result := nrgpRight;

            nrigpTop:
                Result := nrgpTop;

            nrigpBottom:
                Result := nrgpBottom;

            nrigpDefault:
                Result := FLayout.GlyphPosition;
        Else
            Result := FLayout.GlyphPosition;
        End;
    End;
End;


Function TNoReflowTabBarLayoutSupport.ResolveGlyphPosition(AItem: TNoReflowTabBarItem): TNoReflowTabBarGlyphPosition;
Var
    LMetrics: TNoReflowTabBarItemMetrics;
Begin
    //-------------------------------------------------------------------------
    //Resout la position physique du glyph.
    //
    //La position logique est d'abord resolue dans le repere horizontal
    //canonique, puis tournee selon l'orientation effective du texte.
    //
    //GARDE-FOU : cette valeur physique doit servir au placement et au dessin.
    //Elle ne doit pas remplacer la position logique pour les decisions
    //fonctionnelles, sous peine d'inverser les comportements en VerticalUp ou
    //VerticalDown.
    //-------------------------------------------------------------------------

    FillChar(
        LMetrics,
        SizeOf(LMetrics),
        0);

    LMetrics.TabPosition := FBarPosition;

    ResolveMetricsTextOrientation(LMetrics);

    Result := RotateGlyphPositionForTextOrientation(
        ResolveLogicalGlyphPosition(AItem),
        LMetrics.TextOrientation);
End;


Function TNoReflowTabBarLayoutSupport.ResolveGlyphSize(
    AItem: TNoReflowTabBarItem;
    Out AGlyphW: Integer;
    Out AGlyphH: Integer): Boolean;
Begin
    //-------------------------------------------------------------------------
    //Détermine si l'item possède un glyph réellement exploitable.
    //
    //Depuis la suppression du bitmap local dans TNoReflowTabBarItem, un glyph
    //ne peut venir que de :
    //
    //- FBarImages ;
    //- AItem.GlyphIndex.
    //
    //La taille réservée par le layout est donc toujours la taille effective de
    //l'ImageList. Cela reste cohérent avec TVirtualImageList, qui gère déjà le
    //DPI, l'ImageCollection et le scaling.
    //-------------------------------------------------------------------------

    Result := False;
    AGlyphW := 0;
    AGlyphH := 0;

    If AItem = Nil Then
        Exit;

    If Not AItem.ShowGlyph Then
        Exit;

    If FBarImages = Nil Then
        Exit;

    If AItem.GlyphIndex < 0 Then
        Exit;

    If AItem.GlyphIndex >= FBarImages.Count Then
        Exit;

    AGlyphW := FBarImages.Width;
    AGlyphH := FBarImages.Height;

    Result := (AGlyphW > 0) And (AGlyphH > 0);

    If Not Result Then Begin
        AGlyphW := 0;
        AGlyphH := 0;
    End;
End;


Function TNoReflowTabBarLayoutSupport.PaintCanvas: TCanvas;
Begin
    If FPaintCanvas <> Nil Then
        Result := FPaintCanvas
    Else
        Result := Canvas;
End;


end.
