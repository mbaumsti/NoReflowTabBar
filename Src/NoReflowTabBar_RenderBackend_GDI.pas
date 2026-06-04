Unit NoReflowTabBar_RenderBackend_GDI;

{
  NoReflowTabBar_RenderBackend_GDI.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Rendering support layer of the NoReflowTabBar VCL component.

  Repository:
  https://github.com/mbaumsti/NoReflowTabBar

  License:
  See LICENSE file.

  ------------------------------------------------------------------------------

  Couche de support du rendu du composant NoReflowTabBar.

  Cette unité fournit le backend de dessin GDI historique. Les calculs de
  métriques, de rectangles, de contours et de placement communs aux backends
  ont été remontés dans NoReflowTabBar_LayoutSupport.pas afin que GDI et
  Direct2D consomment les mêmes primitives.

  Elle ne publie pas l'API design-time : elle constitue une couche interne entre
  le layout logique et la peinture finale du contrôle.

  ------------------------------------------------------------------------------

  GARDE-FOUS DE GEOMETRIE

  Ce composant raisonne d'abord dans un repere logique de contenu, puis seulement
  ensuite dans les coordonnees physiques du controle.

  Regles imperatives :
  - Length designe toujours l'axe logique principal du contenu ;
  - Thickness designe toujours l'axe logique secondaire ;
  - Length ne veut pas dire Width ;
  - Thickness ne veut pas dire Height ;
  - X/Y, Width/Height ne doivent etre utilises que lorsque le code convertit
    explicitement le repere logique vers les coordonnees locales finales ;
  - les corrections visuelles liees a MinimumLength doivent etre appliquees sur
    l'axe logique de flux, pas directement sur une coordonnee physique supposee.

  Toute modification du layout doit preserver cette separation. Les regressions
  les plus faciles a introduire sont :
  - travailler trop tot dans le repere physique final ;
  - confondre Length avec une largeur horizontale ;
  - corriger uniquement le cas horizontal et oublier que le meme raisonnement
    doit s'appliquer a l'axe logique lorsque le texte est vertical.

  GARDE-FOU MAJEUR : PIPELINE HORIZONTAL CANONIQUE

  Le placement global des items et des zones ne doit jamais etre duplique pour
  Top / Bottom / Left / Right. Le fonctionnement recherche est le suivant :

  1) calculer les dimensions logiques de chaque item ;
  2) construire le layout dans le repere canonique horizontal TOP, c'est-a-dire
     comme si la barre etait horizontale ;
  3) transformer ensuite les rectangles canoniques vers la position reelle de
     la barre.

  Si une correction de placement est necessaire pour les barres verticales, il
  faut d'abord verifier si elle appartient au moteur canonique, puis corriger le
  repere logique commun. Il ne faut pas ajouter une correction locale en X/Y
  final qui ne fonctionnerait que pour Left ou Right.

  REGLE D'OR v71 : IL NE FAUT PAS FAIRE DE CALCUL DE POSITION ICI.

  Cette unite dessine. Elle ne decide pas la geometrie.

  En particulier, il est interdit de corriger localement dans ce renderer :
  - la position des items ;
  - les rectangles de texte ;
  - les rectangles de glyph ;
  - les rectangles de voyant ;
  - les points d'insertion du texte ;
  - les segments ou ancrages des headers de zones.

  Toute anomalie de placement doit etre corrigee dans le layout commun :
  - NoReflowTabBar_ZoneLayout.pas pour les zones et transformations globales ;
  - TNoReflowTabBarItemContentLayoutEngine pour le contenu interne des items ;
  - BuildZoneHeaderRenderInfo dans NoReflowTabBar_LayoutSupport.pas pour les
    headers de zones.

  Les renderers GDI et Direct2D doivent consommer les memes primitives. Un
  contournement local dans ce fichier recreerait immediatement une divergence
  entre backends et provoquerait une regression.
}


Interface

Uses
    Winapi.Windows,
    Winapi.Messages,
    Winapi.CommCtrl,
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
    Vcl.ImgList,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_Library,
    NoReflowTabBar_Items,
    NoReflowTabBar_RenderTypes,
    NoReflowTabBar_ZoneLayout,
    NoReflowTabBar_LayoutSupport,
    NoReflowTabBar_RenderBackend;

Type
    TNoReflowTabBarGDIRenderBackendSupport = Class(TNoReflowTabBarLayoutSupport, INoReflowTabBarRenderBackend)
    protected
        //---------------------------------------------------------------------
        // Options de peinture actives pendant la passe courante.
        //
        // Elles sont principalement utilisees pendant la migration progressive
        // vers Direct2D : le backend appelant peut deja avoir dessine certaines
        // couches natives, tout en laissant le pipeline GDI dessiner le contenu
        // non encore migre.
        //---------------------------------------------------------------------
        FCurrentPaintOptions: TNoReflowTabBarRenderPaintOptions;

        //Dessine le fond dégradé de l’onglet dans son contour réel.
        Procedure DrawTabBackground(
            Const ABounds: TRect;
            Const ARegionPoints: TArray<TPoint>;
            ATopColor: TColor;
            ABottomColor: TColor);

        //Dessine la bordure de l’onglet, fermée ou ouverte selon l’état.
        Procedure DrawTabBorder(
            Const ARegionPoints: TArray<TPoint>;
            ABorderColor: TColor;
            AVisualState: TNoReflowTabBarItemVisualState;
            AWidth: Single;
            AClosed: Boolean);

        //Dessine le voyant coloré de l’item si présent.
        Procedure DrawTabSignal(
            Const ARenderItem: TNoReflowTabBarRenderItem;
            ASignalBrushColor: TColor;
            ASignalPenColor: TColor);

        //Dessine le texte de l’item avec l’orientation appropriée.
        Procedure DrawTabText(
            Const ARenderItem: TNoReflowTabBarRenderItem;
            ATextColor: TColor;
            ASelected: Boolean);

        //Résout les couleurs réellement utilisées pour dessiner un bouton.
        //
        //Cette routine est volontairement séparée de ResolveTabRenderColors :
        //- les onglets conservent leur palette historique Tab* ;
        //- les boutons utilisent la palette Button* ;
        //- l'état pressé possède une couleur dédiée en mode bouton.
        Procedure ResolveButtonRenderColors(
            Const APalette: TNoReflowTabBarPalette;
            AVisualState: TNoReflowTabBarItemVisualState;
            ASignalCode: Integer;
            Out ATopColor: TColor;
            Out ABottomColor: TColor;
            Out ATextColor: TColor;
            Out ABorderColor: TColor;
            Out ASignalBrushColor: TColor;
            Out ASignalPenColor: TColor);

        //Ajuste les couleurs de fond selon le mode de rendu effectif.
        //
        //Important :
        //- nrrmFlat force un aplat ;
        //- nrrmGradient garantit un vrai dégradé contrôlé ;
        //- en palette custom, le dégradé explicite de l'utilisateur est respecté.
        Procedure AdjustBackgroundColorsForRenderMode(
            ARenderMode: TNoReflowTabBarRenderMode;
            APaletteMode: TNoReflowTabBarPaletteMode;
            Var ATopColor: TColor;
            Var ABottomColor: TColor);
        //Dessine le fond d'un bouton dans son contour réel.
        //
        //Le contour est généralement rectangulaire arrondi, mais on conserve
        //le même mécanisme que pour les onglets afin d'avoir un pipeline unique.
        Procedure DrawButtonBackground(
            Const ABounds: TRect;
            Const ARegionPoints: TArray<TPoint>;
            ATopColor: TColor;
            ABottomColor: TColor);

        //Dessine la bordure d'un bouton si BarLayoutButtons.DrawBorder=True.
        Procedure DrawButtonBorder(
            Const ARegionPoints: TArray<TPoint>;
            ABorderColor: TColor;
            AVisualState: TNoReflowTabBarItemVisualState);

        //Dessine le rendu standard complet d'un bouton.
        //
        //Cette méthode utilise :
        //- les couleurs Button* de la palette active ;
        //- la géométrie BarLayoutButtons ;
        //- le même contenu interne que les onglets : texte, glyph, signal.
        Procedure DefaultPaintButton(
            Const ARenderItem: TNoReflowTabBarRenderItem;
            AVisualState: TNoReflowTabBarItemVisualState);

        //Dessine le rectangle de focus interne sur l’item sélectionné.
        Procedure DrawItemFocusOutline(Const ARenderItem: TNoReflowTabBarRenderItem);

        //Dessine le rendu standard complet d’un onglet.
        //
        //Cette méthode est volontairement exposée au niveau protected afin
        //de pouvoir être réutilisée depuis un descendant ou depuis un handler
        //d’événement déclenché au cours du Paint.
        //
        //Elle correspond au pipeline de rendu interne standard :
        //- résolution des couleurs
        //- fond
        //- bordure
        //- voyant éventuel
        //- texte
        //- focus éventuel
        Procedure DefaultPaintTab(
            Const ARenderItem: TNoReflowTabBarRenderItem;
            AVisualState: TNoReflowTabBarItemVisualState);

        //Dessine un item complet à partir d’un render item.
        Procedure DrawSingleItem(
            Const ARenderItem: TNoReflowTabBarRenderItem;
            AVisualState: TNoReflowTabBarItemVisualState);

        //Dessine le header décoratif d'une zone.
        Procedure DrawSingleZoneHeader(
            APinZone: TNoReflowTabBarPinZone;
            Const AZoneBounds: TRect);

        //Dessine tous les headers de zones visibles.
        Procedure DrawZoneHeaders;

        //Dessine une image issue de BarImages dans un bitmap temporaire,
        //puis délègue le dessin orienté à DrawOrientedGlyphBitmap.
        Procedure DrawOrientedImageListGlyph(
            AImageIndex: Integer;
            Const AGlyphRect: TRect;
            ATextOrientation: TNoReflowTabBarTextOrientation);

        //Dessine le glyph d'un item si les métriques indiquent qu'il existe.
        Procedure DrawItemGlyph(Const ARenderItem: TNoReflowTabBarRenderItem);

        Procedure WMEraseBkgnd(Var Message: TWMEraseBkgnd); message WM_ERASEBKGND;

        //Dessine le fond général de la barre.
        //
        //Important :
        //le mode de rendu Flat / Gradient concerne les items eux-mêmes.
        //Il ne doit pas nécessairement écraser le fond du contrôle.
        //
        //Quand la palette vient du style VCL, on laisse le style dessiner le
        //fond parent / client afin de conserver les éventuels bitmaps,
        //textures ou effets définis par le style.
        Procedure DrawBarBackground;

        //Retourne le nom technique du backend de rendu effectif.
        //
        //Cette méthode appartient au contrat INoReflowTabBarRenderBackend.
        //Le nom sert au diagnostic lorsque l'application alterne entre le
        //backend historique GDI/GDI+ et le backend Direct2D.
        Function GetBackendName: String;

        //Dessine l'intégralité de la barre sur le canvas fourni.
        //
        //Cette méthode implémente le contrat INoReflowTabBarRenderBackend pour
        //le backend historique GDI/GDI+. Elle doit uniquement dessiner les
        //primitives deja preparees par le layout commun.
        Procedure PaintToCanvas(ACanvas: TCanvas);

        //Dessine la barre avec des options de composition inter-backends.
        //
        //Ces options servent notamment au rendu hybride limite du fond style
        //VCL texture. Elles ne doivent pas etre utilisees pour faire du GDI un
        //correctif de layout ou pour contourner une primitive Direct2D mal
        //preparee.
        Procedure PaintToCanvasWithOptions(
            ACanvas: TCanvas;
            AOptions: TNoReflowTabBarRenderPaintOptions);

    End;

Implementation

Procedure TNoReflowTabBarGDIRenderBackendSupport.WMEraseBkgnd(Var Message: TWMEraseBkgnd);
Begin
    Message.Result := 1;
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawTabBackground(
Const ABounds: TRect;
Const ARegionPoints: TArray<TPoint>;
ATopColor: TColor;
ABottomColor: TColor);
Var
ClipRgn:   HRGN;
SavedDC:   Integer;
FillColor: TColor;
Begin
 //-------------------------------------------------------------------------
 //Dessine le fond complet d’un onglet.
 //
 //Le fond n’est jamais dessiné comme un simple rectangle :
 //il est limité au contour polygonal réel de l’onglet
 //(avec slants et coins arrondis).
 //
 //Stratégie :
 //- si GDI+ est disponible :
 //1) pré-remplissage plein de la forme
    //2) remplissage dégradé dans le path
    //
    //- sinon en GDI classique :
    //1) remplissage polygonal plein
    //2) clipping sur la forme
    //3) dessin du gradient dans le rectangle englobant
    //-------------------------------------------------------------------------

    //Un fond n’a de sens que si la forme contient au moins 3 points.
    If Length(ARegionPoints) < 3 Then
        Exit;

    //Couleur de "bouchage" utilisée avant le gradient
    //pour éviter certains petits jours visuels.
    FillColor := GetGDIPrefillColor(
        ATopColor,
        ABottomColor);

    //-------------------------------------------------------------------------
    //Rendu plat.
    //
    //nrrmFlat :
    //on remplit avec la couleur haute résolue.
    //Le rendu ne délègue plus le chrome des items à TStyleServices : les
    //couleurs viennent de la palette active, la géométrie reste celle du
    //composant.
    //-------------------------------------------------------------------------
    If GetEffectiveBarRenderMode = nrrmFlat Then Begin

        If UseGDIPlus Then
            FillSolidPathGDIPlus(
                PaintCanvas,
                ARegionPoints,
                ATopColor)
        Else Begin
            PaintCanvas.Brush.Style := bsSolid;
            PaintCanvas.Brush.Color := ATopColor;
            PaintCanvas.Pen.Color := ATopColor;
            PaintCanvas.Pen.Width := 1;
            PaintCanvas.Polygon(ARegionPoints);
        End;

        Exit;
    End;

    If UseGDIPlus Then Begin
        //Version GDI+ :
        //le path réel de l’onglet est respecté pour le remplissage.
        FillSolidPathGDIPlus(
            PaintCanvas,
            ARegionPoints,
            FillColor);
        FillGradientInPath(
            PaintCanvas,
            ABounds,
            ARegionPoints,
            ATopColor,
            ABottomColor,
            IsVerticalBar);
    End Else Begin
        //Version GDI classique :
        //on remplit d’abord la forme, puis on clippe le DC
        //pour tracer un gradient limité à cette zone.
        PaintCanvas.Brush.Style := bsSolid;
        PaintCanvas.Brush.Color := FillColor;
        PaintCanvas.Pen.Color := FillColor;
        PaintCanvas.Pen.Width := 1;
        PaintCanvas.Polygon(ARegionPoints);

        ClipRgn := CreatePolygonRgn(
            PPoint(ARegionPoints),
            Length(ARegionPoints),
            WINDING);
        Try
            SavedDC := SaveDC(PaintCanvas.Handle);
            Try
                SelectClipRgn(
                    PaintCanvas.Handle,
                    ClipRgn);

                GradientFillRectEx(
                    PaintCanvas,
                    ABounds,
                    ABottomColor,
                    ATopColor,
                    IsVerticalBar);
            Finally
                RestoreDC(
                    PaintCanvas.Handle,
                    SavedDC);
            End;
        Finally
            DeleteObject(ClipRgn);
        End;
    End;
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawTabBorder(
    Const ARegionPoints: TArray<TPoint>;
    ABorderColor: TColor;
    AVisualState: TNoReflowTabBarItemVisualState;
    AWidth: Single;
    AClosed: Boolean);
Var
    Width: Single;
Begin
    //-------------------------------------------------------------------------
    //Dessine la bordure de l’onglet à partir de son contour réel.
    //
    //AClosed = True  :
    //la forme est fermée complètement.
    //
    //AClosed = False :
    //le dernier segment de fermeture n’est pas tracé.
    //C’est le cas typique de l’onglet sélectionné, pour conserver
    //l’effet de continuité visuelle avec la page associée.
    //-------------------------------------------------------------------------

    //Une bordure nécessite au moins 2 points.
    If Length(ARegionPoints) < 2 Then
        Exit;

    PaintCanvas.Pen.Color := ABorderColor;
    PaintCanvas.Pen.Width := trunc(SimpleRoundTo(AWidth, 0));
    PaintCanvas.Brush.Style := bsClear;

    If UseGDIPlus Then
        DrawAntiAliasedBorder(
            PaintCanvas,
            ARegionPoints,
            ABorderColor,
            AWidth,
            AClosed)
    Else Begin
        If AClosed Then
            PaintCanvas.Polygon(ARegionPoints)
        Else
            PaintCanvas.Polyline(ARegionPoints);
    End;
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawTabSignal(
    Const ARenderItem: TNoReflowTabBarRenderItem;
    ASignalBrushColor: TColor;
    ASignalPenColor: TColor);
Var
    SignalRect:     TRect;
    LPercent:       Double;
    LStartAngleDeg: Double;
Begin
    //-------------------------------------------------------------------------
    //Dessine le voyant coloré de l’onglet.
    //
    //Le voyant peut fonctionner selon deux modes :
    //
    //1) mode classique plein
    //- si SignalMax <= 0
    //
    //2) mode remplissage partiel
    //- si SignalMax > 0
    //- le taux de remplissage est calculé à partir de
    //SignalValue / SignalMax
    //-------------------------------------------------------------------------

    //Aucun signal logique pour cet onglet.
    If Not ARenderItem.Metrics.HasSignal Then
        Exit;

    //Rectangle de signal non défini ou vide.
    If IsRectEmpty(ARenderItem.Metrics.SignalRect) Then
        Exit;

    SignalRect := ARenderItem.Metrics.SignalRect;
    OffsetRect(
        SignalRect,
        ARenderItem.Bounds.Left,
        ARenderItem.Bounds.Top);

    LPercent := NormalizeSignalFillPercent(
        ARenderItem.Item.SignalValue,
        ARenderItem.Item.SignalMax);

    LPercent := NormalizeSignalFillPercent(
        ARenderItem.Item.SignalValue,
        ARenderItem.Item.SignalMax);

    Case ARenderItem.Metrics.TextOrientation Of
        nrttoVerticalUp:
            LStartAngleDeg := 180.0; //90° antihoraire depuis 12h

        nrttoVerticalDown:
            LStartAngleDeg := 0.0; //90° horaire depuis 12h
    Else
        LStartAngleDeg := -90.0; //horizontal : 12h
    End;

    DrawSignalIndicator(
        PaintCanvas,
        SignalRect,
        ASignalBrushColor,
        ASignalPenColor,
        LPercent,
        LStartAngleDeg);
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawTabText(
    Const ARenderItem: TNoReflowTabBarRenderItem;
    ATextColor: TColor;
    ASelected: Boolean);
Var
    M:               TNoReflowTabBarItemMetrics;
    R:               TRect;
    SaveOrientation: Integer;
    SaveAlign:       UINT;
    SaveBkMode:      Integer;
    SaveBkColor:     TColorRef;
    SaveClipState:   Integer;
    TextToDraw:      String;
    ClipRect:        TRect;
    TextX:           Integer;
    TextY:           Integer;
    DrawFlags:       Integer;

    Function FitTextWithEllipsisToFlow(
        Const AText: String;
        AAvailableFlow: Integer): String;
    Var
        EllipsisText: String;
        LowIndex: Integer;
        HighIndex: Integer;
        MidIndex: Integer;
        BestIndex: Integer;
        CandidateText: String;
    Begin
        Result := AText;

        If AAvailableFlow <= 0 Then Begin
            Result := '';
            Exit;
        End;

        If PaintCanvas.TextWidth(Result) <= AAvailableFlow Then
            Exit;

        EllipsisText := '...';

        If PaintCanvas.TextWidth(EllipsisText) > AAvailableFlow Then Begin
            Result := '';
            Exit;
        End;

        LowIndex := 0;
        HighIndex := Length(AText);
        BestIndex := 0;

        While LowIndex <= HighIndex Do Begin
            MidIndex := (LowIndex + HighIndex) Div 2;
            CandidateText := Copy(AText, 1, MidIndex) + EllipsisText;

            If PaintCanvas.TextWidth(CandidateText) <= AAvailableFlow Then Begin
                BestIndex := MidIndex;
                LowIndex := MidIndex + 1;
            End Else
                HighIndex := MidIndex - 1;
        End;

        Result := Copy(AText, 1, BestIndex) + EllipsisText;
    End;

Begin
    //-------------------------------------------------------------------------
    //Dessine le texte de l’onglet.
    //
    //Particularités importantes :
    //- le texte peut être horizontal ou vertical
    //- les coordonnées mémorisées dans les métriques sont locales au bouton
    //- l’état GDI texte est sauvegardé/restauré pour ne pas polluer
    //le reste du pipeline de dessin
    //-------------------------------------------------------------------------

    M := ARenderItem.Metrics;
    R := ARenderItem.Bounds;

    //Prépare la police correcte, notamment si l’onglet est sélectionné.
    SetupItemCanvasFont(ASelected);

    PaintCanvas.Font.Color := ATextColor;
    PaintCanvas.Brush.Style := bsClear;
    PaintCanvas.Brush.Color := Color;

    //Sauvegarde complète de l’état GDI texte.
    SaveOrientation := PaintCanvas.Font.Orientation;
    SaveAlign := GetTextAlign(PaintCanvas.Handle);
    SaveBkMode := GetBkMode(PaintCanvas.Handle);
    SaveBkColor := GetBkColor(PaintCanvas.Handle);
    Try
        SetBkMode(
            PaintCanvas.Handle,
            TRANSPARENT);

        //L’orientation GDI et l’alignement doivent être adaptés
        //au sens de lecture demandé.
        Case M.TextOrientation Of
            nrttoHorizontal: Begin
                    PaintCanvas.Font.Orientation := 0;
                    SetTextAlign(
                        PaintCanvas.Handle,
                        TA_LEFT Or TA_TOP Or TA_NOUPDATECP);
                End;

            nrttoVerticalUp: Begin
                    //---------------------------------------------------------
                    // v50 : le layout fournit deja le point d'appel GDI du
                    // texte vertical.
                    //
                    // Pour VerticalUp, ce point correspond au bas/gauche du
                    // rectangle physique de clipping, c'est-a-dire au coin
                    // haut/gauche canonique apres rotation. Le renderer ne le
                    // recalcule pas depuis TextClipRect.
                    //---------------------------------------------------------
                    PaintCanvas.Font.Orientation := 900;
                    SetTextAlign(
                        PaintCanvas.Handle,
                        TA_LEFT Or TA_TOP Or TA_NOUPDATECP);
                End;

            nrttoVerticalDown: Begin
                    //---------------------------------------------------------
                    // Pour VerticalDown, le point fourni par le layout
                    // correspond au haut/droit du rectangle physique de
                    // clipping. Il est directement compatible avec TextOut et
                    // l'orientation 2700.
                    //---------------------------------------------------------
                    PaintCanvas.Font.Orientation := 2700;
                    SetTextAlign(
                        PaintCanvas.Handle,
                        TA_LEFT Or TA_TOP Or TA_NOUPDATECP);
                End;
        End;

        TextToDraw := ResolveItemText(
            ARenderItem.ItemIndex,
            ARenderItem.Item);

        If Not IsRectEmpty(M.TextClipRect) Then Begin
            //-----------------------------------------------------------------
            // Le layout fournit la zone finale de composition.
            //
            // Horizontal : DrawText sait centrer et ellipser directement.
            // Vertical : GDI ne fournit pas un DrawText vertical equivalent avec
            // ellipsis fiable. On utilise donc le meme rectangle comme zone de
            // clipping stricte, puis on convertit le coin haut/gauche fourni par
            // le layout en ancre TextOut adaptee a Font.Orientation.
            //-----------------------------------------------------------------
            ClipRect := Rect(
                ARenderItem.Bounds.Left + M.TextClipRect.Left,
                ARenderItem.Bounds.Top + M.TextClipRect.Top,
                ARenderItem.Bounds.Left + M.TextClipRect.Right,
                ARenderItem.Bounds.Top + M.TextClipRect.Bottom);

            If M.TextOrientation = nrttoHorizontal Then Begin
                //-------------------------------------------------------------
                // REGLE D'OR v74 : le renderer ne choisit pas d'ellipser.
                //
                // DT_END_ELLIPSIS n'est ajouté que si le layout a explicitement
                // autorisé le raccourcissement du texte. En mode onglet naturel,
                // le caption complet reste prioritaire.
                //-------------------------------------------------------------
                DrawFlags := DT_SINGLELINE Or DT_CENTER Or DT_VCENTER Or DT_NOPREFIX;

                If M.AllowTextTrimming Then
                    DrawFlags := DrawFlags Or DT_END_ELLIPSIS;

                DrawText(
                    PaintCanvas.Handle,
                    PChar(TextToDraw),
                    Length(TextToDraw),
                    ClipRect,
                    DrawFlags);
            End Else Begin
                //-----------------------------------------------------------------
                // v50 : TextX/TextY est le point d'appel calcule par le layout.
                //
                // Horizontal : coin haut/gauche.
                // VerticalUp : point bas/gauche du rectangle physique.
                // VerticalDown : point haut/droit du rectangle physique.
                //
                // Le renderer ne derive rien de TextClipRect ; il applique
                // seulement l'orientation GDI et consomme l'ancre fournie.
                //-----------------------------------------------------------------
                TextX := ARenderItem.Bounds.Left + M.TextX;
                TextY := ARenderItem.Bounds.Top + M.TextY;

                // GDI ne propose pas d'equivalent fiable de DT_END_ELLIPSIS
                // pour un TextOut vertical. Le rectangle de clipping reste une
                // donnee de layout ; cette etape ne repositionne rien, elle
                // prepare seulement la chaine affichee dans la longueur de flux
                // deja calculee par le layout.
                If M.AllowTextTrimming Then
                    TextToDraw := FitTextWithEllipsisToFlow(
                        TextToDraw,
                        ClipRect.Bottom - ClipRect.Top);

                SaveClipState := SaveDC(PaintCanvas.Handle);
                Try
                    IntersectClipRect(
                        PaintCanvas.Handle,
                        ClipRect.Left,
                        ClipRect.Top,
                        ClipRect.Right,
                        ClipRect.Bottom);

                    PaintCanvas.TextOut(
                        TextX,
                        TextY,
                        TextToDraw);
                Finally
                    RestoreDC(
                        PaintCanvas.Handle,
                        SaveClipState);
                End;
            End;
        End Else Begin
            PaintCanvas.TextOut(
                M.TextX + R.Left,
                M.TextY + R.Top,
                TextToDraw);
        End;
    Finally
        //Restauration impérative de l’état initial.
        SetBkMode(
            PaintCanvas.Handle,
            SaveBkMode);
        SetBkColor(
            PaintCanvas.Handle,
            SaveBkColor);
        PaintCanvas.Font.Orientation := SaveOrientation;
        SetTextAlign(
            PaintCanvas.Handle,
            SaveAlign);
    End;
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.ResolveButtonRenderColors(
    Const APalette: TNoReflowTabBarPalette;
    AVisualState: TNoReflowTabBarItemVisualState;
    ASignalCode: Integer;
    Out ATopColor: TColor;
    Out ABottomColor: TColor;
    Out ATextColor: TColor;
    Out ABorderColor: TColor;
    Out ASignalBrushColor: TColor;
    Out ASignalPenColor: TColor);
Var
    LSignalDef: TNoReflowTabBarSignalDef;
Begin
    //-------------------------------------------------------------------------
    //Résout les couleurs concrètes utilisées pour dessiner un bouton.
    //
    //Cette méthode est séparée de ResolveTabRenderColors afin de ne pas
    //mélanger :
    //- la palette historique des onglets : Tab* ;
    //- la palette spécifique des boutons : Button*.
    //
    //L'état nrtvsPressed est ici pleinement exploité.
    //-------------------------------------------------------------------------

    Case AVisualState Of
        nrtvsNormal: Begin
                ATopColor := APalette.ButtonNormalTop;
                ABottomColor := APalette.ButtonNormalBottom;
                ATextColor := APalette.ButtonNormalText;
                ABorderColor := APalette.ButtonNormalBorder;
            End;

        nrtvsHot: Begin
                ATopColor := APalette.ButtonHotTop;
                ABottomColor := APalette.ButtonHotBottom;
                ATextColor := APalette.ButtonHotText;
                ABorderColor := APalette.ButtonHotBorder;
            End;

        nrtvsPressed: Begin
                ATopColor := APalette.ButtonPressedTop;
                ABottomColor := APalette.ButtonPressedBottom;
                ATextColor := APalette.ButtonPressedText;
                ABorderColor := APalette.ButtonPressedBorder;
            End;

        nrtvsSelected: Begin
                ATopColor := APalette.ButtonSelectedTop;
                ABottomColor := APalette.ButtonSelectedBottom;
                ATextColor := APalette.ButtonSelectedText;
                ABorderColor := APalette.ButtonSelectedBorder;
            End;

        nrtvsDisabled: Begin
                ATopColor := APalette.ButtonDisabledTop;
                ABottomColor := APalette.ButtonDisabledBottom;
                ATextColor := APalette.ButtonDisabledText;
                ABorderColor := APalette.ButtonDisabledBorder;
            End;
    Else Begin
            //Fallback défensif.
            ATopColor := APalette.ButtonNormalTop;
            ABottomColor := APalette.ButtonNormalBottom;
            ATextColor := APalette.ButtonNormalText;
            ABorderColor := APalette.ButtonNormalBorder;
        End;
    End;

    //Le voyant conserve sa sémantique indépendante du mode onglet/bouton.
    LSignalDef := FindSignalDefByCode(ASignalCode);

    If LSignalDef <> Nil Then Begin
        ASignalBrushColor := LSignalDef.FillColor;
        ASignalPenColor := LSignalDef.BorderColor;
    End Else Begin
        ASignalBrushColor := clNone;
        ASignalPenColor := clNone;
    End;
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.AdjustBackgroundColorsForRenderMode(
    ARenderMode: TNoReflowTabBarRenderMode;
    APaletteMode: TNoReflowTabBarPaletteMode;
    Var ATopColor: TColor;
    Var ABottomColor: TColor);
Var
    LBaseColor:       TColor;
    LTopCandidate:    TColor;
    LBottomCandidate: TColor;
    LBaseLum:         Double;

    Function ResolveStyleBaseColor: TColor;
    Begin
        //---------------------------------------------------------------------
        //Les palettes dérivées d'un style peuvent contenir un couple Top/Bottom
        //issu d'une résolution imparfaite ou d'une normalisation précédente.
        //Utiliser systématiquement Bottom peut rendre certains styles très
        //sombres en mode Flat, notamment les styles à base anthracite.
        //
        //On prend donc une couleur de référence moyenne lorsque Top et Bottom
        //sont réellement distinctes. Si elles sont identiques ou très proches,
        //cela revient pratiquement à conserver Bottom.
        //---------------------------------------------------------------------
        Result := ColorToRGB(BlendColorPourcent(ATopColor, ABottomColor, 50));
    End;

Begin
    //-------------------------------------------------------------------------
    //Applique la politique de rendu aux couleurs déjà résolues.
    //
    //La palette fournit les couleurs de référence. BarRenderMode décide ensuite
    //comment les rendre : aplat ou dégradé.
    //
    //Règles :
    //- Flat + palette custom :
    //utilise la couleur basse, qui reste la couleur de référence historique.
    //
    //- Flat + palette style :
    //utilise une couleur moyenne Top/Bottom afin d'éviter qu'un style dont le bas
    //est très sombre produise un aplat trop dur.
    //
    //- Gradient + palette custom :
    //respecte strictement Top / Bottom, car ces couleurs expriment une
    //intention explicite de l'utilisateur.
    //
    //- Gradient + palette style :
    //reconstruit un gradient contrôlé depuis la couleur basse.
    //-------------------------------------------------------------------------

    Case ARenderMode Of
        nrrmFlat: Begin
                If APaletteMode = nrtcmCustom Then
                    LBaseColor := ColorToRGB(ABottomColor)
                Else
                    LBaseColor := ResolveStyleBaseColor;

                ATopColor := LBaseColor;
                ABottomColor := LBaseColor;
            End;

        nrrmGradient: Begin
                If APaletteMode = nrtcmCustom Then Begin
                    ATopColor := ColorToRGB(ATopColor);
                    ABottomColor := ColorToRGB(ABottomColor);
                    Exit;
                End;

                LBaseLum := ColorLuminance(ABottomColor);

                //Sur les styles sombres, un gradient trop contrasté donne vite
                //un haut trop lumineux et un bas presque noir. On réduit donc
                //les écarts autorisés lorsque la base est déjà sombre.
                If LBaseLum < 60 Then Begin
                    //-----------------------------------------------------------------
                    //Styles très sombres :
                    //-----------------------------------------------------------------
                    LTopCandidate := MakeColorLumaLighter(
                        ABottomColor,
                        70);

                    LBottomCandidate := MakeColorLumaLighter(
                        ABottomColor,
                        20);
                End Else If LBaseLum < 110 Then Begin
                    //-----------------------------------------------------------------
                    //Styles sombres / anthracite :
                    //-----------------------------------------------------------------
                    LTopCandidate := MakeColorLumaLighter(
                        ABottomColor,
                        65);

                    LBottomCandidate := MakeColorLumaLighter(
                        ABottomColor,
                        15);
                End Else If LBaseLum < 185 Then Begin
                    //-----------------------------------------------------------------
                    //Styles intermédiaires :
                    //rendu standard.
                    //-----------------------------------------------------------------
                    LTopCandidate := MakeColorLumaLighter(
                        ABottomColor,
                        60);

                    LBottomCandidate := MakeColorLumaDarker(
                        ABottomColor,
                        10);
                End Else Begin
                    //-----------------------------------------------------------------
                    //Styles clairs :
                    //-----------------------------------------------------------------
                    LTopCandidate := MakeColorLumaLighter(
                        ABottomColor,
                        70);

                    LBottomCandidate := MakeColorLumaDarker(
                        ABottomColor,
                        20);
                End;

                ATopColor := ColorToRGB(LTopCandidate);
                ABottomColor := ColorToRGB(LBottomCandidate);
            End;
    End;
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawButtonBackground(
    Const ABounds: TRect;
    Const ARegionPoints: TArray<TPoint>;
    ATopColor: TColor;
    ABottomColor: TColor);
Begin
    //-------------------------------------------------------------------------
    //Dessine le fond d'un bouton dans son contour réel.
    //
    //Le composant ne délègue plus le chrome des boutons à TStyleServices.
    //La palette fournit les couleurs, puis le rendu Flat / Gradient décide
    //comment les appliquer.
    //
    //On réutilise le même moteur que les onglets.
    //DrawTabBackground décide lui-même si le remplissage est plat ou dégradé
    //en fonction du BarRenderMode effectif.
    //-------------------------------------------------------------------------

    DrawTabBackground(
        ABounds,
        ARegionPoints,
        ATopColor,
        ABottomColor);
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawButtonBorder(
    Const ARegionPoints: TArray<TPoint>;
    ABorderColor: TColor;
    AVisualState: TNoReflowTabBarItemVisualState);
Var
    Width: Single;
Begin

    //-------------------------------------------------------------------------
    //Dessine la bordure d'un bouton.
    //
    //Contrairement à l'onglet sélectionné, un bouton reste une forme autonome :
    //sa bordure est donc toujours fermée.
    //
    //Si BarLayoutButtons.DrawBorder=False, aucune bordure n'est dessinée.
    //-------------------------------------------------------------------------

    If FLayoutButtons <> Nil Then
        If Not FLayoutButtons.DrawBorder Then
            Exit;

    Width := 1.25;
    Case AVisualState Of
        nrtvsHot:
            Width := 1.8;

        nrtvsPressed, nrtvsSelected:
            Width := 1.8;
    End;

    DrawTabBorder(
        ARegionPoints,
        ABorderColor,
        AVisualState,
        Width,
        True);
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DefaultPaintButton(
    Const ARenderItem: TNoReflowTabBarRenderItem;
    AVisualState: TNoReflowTabBarItemVisualState);
Var
    TopColor:         TColor;
    BottomColor:      TColor;
    BorderColor:      TColor;
    TextColor:        TColor;
    SignalBrushColor: TColor;
    SignalPenColor:   TColor;
    Palette:          TNoReflowTabBarPalette;
    LRenderItem:      TNoReflowTabBarRenderItem;
    OffsetValue:      Integer;
Begin
    //-------------------------------------------------------------------------
    //Exécute le pipeline standard complet de dessin d'un bouton.
    //
    //Cette première version conserve le même contenu interne que les onglets :
    //- fond ;
    //- bordure ;
    //- signal ;
    //- glyph ;
    //- texte ;
    //- focus.
    //
    //Différences principales :
    //- couleurs Button* ;
    //- contour bouton ;
    //- bordure toujours fermée ;
    //- décalage visuel possible quand l'état est Pressed.
    //-------------------------------------------------------------------------

    If Not ARenderItem.Visible Then
        Exit;

    Palette := GetActivePalette;

    ResolveButtonRenderColors(
        Palette,
        AVisualState,
        ARenderItem.Item.SignalCode,
        TopColor,
        BottomColor,
        TextColor,
        BorderColor,
        SignalBrushColor,
        SignalPenColor);

    AdjustBackgroundColorsForRenderMode(
        GetEffectiveBarRenderMode,
        FPaletteMode,
        TopColor,
        BottomColor);

    If Not (ntrpoSkipItemSurfaces In FCurrentPaintOptions) Then Begin
        DrawButtonBackground(
            ARenderItem.Bounds,
            ARenderItem.RegionPoints,
            TopColor,
            BottomColor);

        DrawButtonBorder(
            ARenderItem.RegionPoints,
            BorderColor,
            AVisualState);
    End;

    //Copie locale modifiable.
    //
    //Elle permet d'appliquer le PressedOffset au contenu sans déplacer :
    //- le fond ;
    //- la bordure ;
    //- le hit-test ;
    //- les données persistantes de FRenderItems.
    LRenderItem := ARenderItem;

    If (AVisualState = nrtvsPressed) And (FLayoutButtons <> Nil) Then Begin
        OffsetValue := FLayoutButtons.PressedOffset;

        If OffsetValue > 0 Then
            OffsetRect(
                LRenderItem.Bounds,
                OffsetValue,
                OffsetValue);
    End;

    DrawTabSignal(
        LRenderItem,
        SignalBrushColor,
        SignalPenColor);

    DrawItemGlyph(LRenderItem);

    DrawTabText(
        LRenderItem,
        TextColor,
        AVisualState In [nrtvsSelected, nrtvsPressed]);

    If ARenderItem.ItemIndex = GetFocusVisualItemIndex Then
        DrawItemFocusOutline(LRenderItem);
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawItemFocusOutline(Const ARenderItem: TNoReflowTabBarRenderItem);
Var
    M:              TNoReflowTabBarItemMetrics;
    TabBounds:      TRect;
    TextRect:       TRect;
    SignalRect:     TRect;
    FocusRect:      TRect;
    HasContentRect: Boolean;
    FocusColor:     TColor;
    Graphics:       TGPGraphics;
    Pen:            TGPPen;
    GPRect:         TGPRectF;
    GlyphRect:      TRect;
    DashPattern:    Array [0 .. 1] Of Single;
Begin
    //-------------------------------------------------------------------------
    //Dessine le cadre de focus clavier sur l’item courant.
    //
    //Le focus n’englobe pas tout l’item, mais uniquement la zone utile :
    //- le texte
    //- le voyant éventuel
    //
    //Cela donne un rendu plus discret et plus proche d’un focus "interne".
    //-------------------------------------------------------------------------

    //Le focus n’apparaît que si l’option est activée.
    If Not FShowFocus Then
        Exit;

    //Le contrôle doit réellement posséder le focus clavier.
    If Not Focused Then
        Exit;

    //Sécurité : inutile de dessiner sur un item invisible.
    If Not ARenderItem.Visible Then
        Exit;

    M := ARenderItem.Metrics;
    TabBounds := ARenderItem.Bounds;
    HasContentRect := False;

    SetRectEmpty(TextRect);
    SetRectEmpty(SignalRect);
    SetRectEmpty(FocusRect);

    Case M.TextOrientation Of
        nrttoHorizontal: Begin
                //Emprise naturelle du texte horizontal.
                TextRect := Rect(
                    TabBounds.Left + M.TextX,
                    TabBounds.Top + M.TextY,
                    TabBounds.Left + M.TextX + M.TextWidth,
                    TabBounds.Top + M.TextY + M.TextHeight);
                HasContentRect := True;
            End;

        nrttoVerticalUp, nrttoVerticalDown: Begin
                //Approximation volontaire de l’emprise du texte tourné.
                //Pour le focus, cette approximation est suffisante
                //et évite une logique plus coûteuse.
                TextRect := Rect(
                    TabBounds.Left + M.TextX - M.TextHeight,
                    TabBounds.Top + M.TextY - M.TextWidth,
                    TabBounds.Left + M.TextX,
                    TabBounds.Top + M.TextY);
                HasContentRect := True;
            End;
    End;

    //Si un signal existe, on élargit la zone de focus pour couvrir
    //l’ensemble du contenu utile.
    If M.HasSignal And Not IsRectEmpty(M.SignalRect) Then Begin
        SignalRect := M.SignalRect;
        OffsetRect(
            SignalRect,
            TabBounds.Left,
            TabBounds.Top);

        If HasContentRect Then
            UnionRect(
                FocusRect,
                TextRect,
                SignalRect)
        Else
            FocusRect := SignalRect;

        HasContentRect := True;
    End Else If HasContentRect Then
        FocusRect := TextRect;

    //Si un glyph existe, on élargit également la zone de focus pour couvrir
    //l'ensemble du contenu réellement affiché.
    If M.HasGlyph And Not IsRectEmpty(M.GlyphRect) Then Begin
        GlyphRect := M.GlyphRect;
        OffsetRect(
            GlyphRect,
            TabBounds.Left,
            TabBounds.Top);

        If HasContentRect Then
            UnionRect(
                FocusRect,
                FocusRect,
                GlyphRect)
        Else
            FocusRect := GlyphRect;

        HasContentRect := True;
    End;

    If Not HasContentRect Then
        Exit;

    //Petite respiration autour du contenu.
    InflateRect(
        FocusRect,
        3,
        2);

    //On borne le focus à une zone intérieure raisonnable,
    //pour éviter qu’il ne touche les bords de la forme.
    IntersectRect(
        FocusRect,
        FocusRect,
        Rect(TabBounds.Left + 3, TabBounds.Top + 3, TabBounds.Right - 3, TabBounds.Bottom - 3));

    If (FocusRect.Right <= FocusRect.Left) Or (FocusRect.Bottom <= FocusRect.Top) Then
        Exit;

    //On réutilise la couleur de texte sélectionné
    //comme couleur de focus.
    FocusColor := GetActivePalette.TabSelectedText;

    If UseGDIPlus Then Begin
        //Version GDI+ :
        //cadre pointillé plus propre et plus stable visuellement.
        Graphics := TGPGraphics.Create(PaintCanvas.Handle);
        Try
            Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
            Graphics.SetPixelOffsetMode(PixelOffsetModeHalf);
            Graphics.SetCompositingQuality(CompositingQualityHighQuality);

            GPRect.X := FocusRect.Left + 0.5;
            GPRect.Y := FocusRect.Top + 0.5;
            GPRect.Width := FocusRect.Right - FocusRect.Left - 1.0;
            GPRect.Height := FocusRect.Bottom - FocusRect.Top - 1.0;

            If (GPRect.Width <= 0) Or (GPRect.Height <= 0) Then
                Exit;

            Pen := TGPPen.Create(
                ColorToGDIPlusColor(FocusColor),
                1.25);
            Try
                Pen.SetLineJoin(LineJoinRound);
                Pen.SetStartCap(LineCapRound);
                Pen.SetEndCap(LineCapRound);

                DashPattern[0] := 1.5;
                DashPattern[1] := 1.5;
                Pen.SetDashPattern(
                    @DashPattern[0],
                    Length(DashPattern));

                Graphics.DrawRectangle(
                    Pen,
                    GPRect);
            Finally Pen.Free;
            End;
        Finally Graphics.Free;
        End;
    End Else Begin
        //Version GDI classique :
        //simple rectangle en pointillé.
        PaintCanvas.Brush.Style := bsClear;
        PaintCanvas.Pen.Style := psDot;
        PaintCanvas.Pen.Width := 1;
        PaintCanvas.Pen.Color := FocusColor;
        PaintCanvas.Rectangle(FocusRect);
        PaintCanvas.Pen.Style := psSolid;
    End;
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DefaultPaintTab(
    Const ARenderItem: TNoReflowTabBarRenderItem;
    AVisualState: TNoReflowTabBarItemVisualState);
Var
    TopColor:         TColor;
    BottomColor:      TColor;
    BorderColor:      TColor;
    TextColor:        TColor;
    SignalBrushColor: TColor;
    SignalPenColor:   TColor;
    DrawClosedEdge:   Boolean;
    Palette:          TNoReflowTabBarPalette;
Begin
    //-------------------------------------------------------------------------
    //Exécute le pipeline standard complet de dessin d’un item.
    //
    //Cette méthode constitue la version réutilisable du rendu interne.
    //Elle est utile dans deux cas :
    //- un descendant veut compléter le rendu sans réécrire toute la logique
    //- un handler OnPaintTab veut personnaliser un item puis déléguer tout
    //ou partie du dessin standard au composant
    //
    //Ordre volontaire :
    //1) résolution des couleurs
    //2) fond
    //3) bordure
    //4) voyant éventuel
    //5) texte
    //6) focus éventuel
    //
    //Cet ordre garantit que :
    //- le texte et le voyant restent au-dessus du fond
    //- la bordure reste lisible
    //- le focus surligne bien le contenu final
    //-------------------------------------------------------------------------

    If Not ARenderItem.Visible Then
        Exit;

    Palette := GetActivePalette;

    ResolveTabRenderColors(
        Palette,
        AVisualState,
        ARenderItem.Item.SignalCode,
        TopColor,
        BottomColor,
        TextColor,
        BorderColor,
        SignalBrushColor,
        SignalPenColor);

    AdjustBackgroundColorsForRenderMode(
        GetEffectiveBarRenderMode,
        FPaletteMode,
        TopColor,
        BottomColor);

    DrawClosedEdge := ShouldDrawClosedEdgeForTab(ARenderItem.ItemIndex);

    If Not (ntrpoSkipItemSurfaces In FCurrentPaintOptions) Then Begin
        DrawTabBackground(
            ARenderItem.Bounds,
            ARenderItem.RegionPoints,
            TopColor,
            BottomColor);

        DrawTabBorder(
            ARenderItem.RegionPoints,
            BorderColor,
            AVisualState,
            1.25,
            DrawClosedEdge);
    End;

    DrawTabSignal(
        ARenderItem,
        SignalBrushColor,
        SignalPenColor);

    DrawItemGlyph(ARenderItem);

    DrawTabText(
        ARenderItem,
        TextColor,
        AVisualState = nrtvsSelected);

    //Le focus clavier n’est affiché que sur l’item courant.
    If ARenderItem.ItemIndex = GetFocusVisualItemIndex Then
        DrawItemFocusOutline(ARenderItem);
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawSingleItem(
    Const ARenderItem: TNoReflowTabBarRenderItem;
    AVisualState: TNoReflowTabBarItemVisualState);
Var
    DefaultDraw: Boolean;
    TextToDraw:  String;
Begin
    //-------------------------------------------------------------------------
    //Point d’entrée effectivement utilisé par Paint pour chaque item.
    //
    //Cette méthode permet au code utilisateur de personnaliser le rendu via
    //OnGDIPaintItem.
    //
    //Attention :
    //si un handler positionne DefaultDraw à False, le composant ne dessine plus
    //ni le fond standard, ni la bordure standard, ni le signal, ni le glyph,
    //ni le texte standard. Le handler devient alors entièrement responsable du
    //rendu complet de l'item.
    //
    //Ce point est important en exécution : un événement branché dynamiquement
    //peut expliquer une différence totale entre design-time et run-time.
    //-------------------------------------------------------------------------

    If Not ARenderItem.Visible Then
        Exit;

    DefaultDraw := True;

    TextToDraw := ResolveItemText(
        ARenderItem.ItemIndex,
        ARenderItem.Item);

    If Assigned(FOnGDIPaintItem) Then
        FOnGDIPaintItem(
            Self,
            FPaintCanvas,
            ARenderItem.ItemIndex,
            ARenderItem.Item,
            TextToDraw,
            ARenderItem.Bounds,
            ARenderItem.RegionPoints,
            ARenderItem.Metrics,
            AVisualState,
            DefaultDraw);

    If DefaultDraw Then Begin
        If IsButtonBarMode Then
            DefaultPaintButton(
                ARenderItem,
                AVisualState)
        Else
            DefaultPaintTab(
                ARenderItem,
                AVisualState);
    End;
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawSingleZoneHeader(
    APinZone: TNoReflowTabBarPinZone;
    Const AZoneBounds: TRect);
Var
    HeaderInfo:      TNoReflowTabBarDirect2DZoneHeaderInfo;
    SegmentIndex:    Integer;
    SaveOrientation: Integer;
    SaveAlign:       UINT;
    SaveBkMode:      Integer;
Begin
    //-------------------------------------------------------------------------
    // Dessine le header decoratif d'une zone.
    //
    // REGLE D'OR v71 : IL NE FAUT PAS FAIRE DE CALCUL DE POSITION ICI.
    //
    // Cette methode est volontairement reduite a une consommation de primitives
    // deja calculees par le layout commun. Si le header est mal place, trop
    // long, mal ancre en vertical, ou si les segments ne tombent pas au bon
    // endroit, la correction doit etre faite dans BuildZoneHeaderRenderInfo,
    // pas dans ce renderer GDI.
    //-------------------------------------------------------------------------

    If PaintCanvas = Nil Then
        Exit;

    If Not BuildZoneHeaderRenderInfo(
        APinZone,
        AZoneBounds,
        HeaderInfo) Then
        Exit;

    PaintCanvas.Font.Name := HeaderInfo.FontName;
    PaintCanvas.Font.Size := HeaderInfo.FontSize;
    PaintCanvas.Font.Height := HeaderInfo.FontHeight;
    PaintCanvas.Font.Style := HeaderInfo.FontStyle;
    PaintCanvas.Font.Color := HeaderInfo.TextColor;

    PaintCanvas.Brush.Style := bsClear;
    PaintCanvas.Pen.Color := HeaderInfo.LineColor;
    PaintCanvas.Pen.Style := psSolid;
    PaintCanvas.Pen.Width := 1;

    For SegmentIndex := 0 To HeaderInfo.SegmentCount - 1 Do Begin
        PaintCanvas.MoveTo(
            HeaderInfo.Segments[SegmentIndex].P1.X,
            HeaderInfo.Segments[SegmentIndex].P1.Y);

        PaintCanvas.LineTo(
            HeaderInfo.Segments[SegmentIndex].P2.X,
            HeaderInfo.Segments[SegmentIndex].P2.Y);
    End;

    SaveOrientation := PaintCanvas.Font.Orientation;
    SaveAlign := GetTextAlign(PaintCanvas.Handle);
    SaveBkMode := GetBkMode(PaintCanvas.Handle);

    Try
        SetBkMode(
            PaintCanvas.Handle,
            TRANSPARENT);

        Case HeaderInfo.TextOrientation Of
            nrttoHorizontal:
                PaintCanvas.Font.Orientation := 0;

            nrttoVerticalUp:
                PaintCanvas.Font.Orientation := 900;

            nrttoVerticalDown:
                PaintCanvas.Font.Orientation := 2700;
        Else
            PaintCanvas.Font.Orientation := 0;
        End;

        SetTextAlign(
            PaintCanvas.Handle,
            TA_LEFT Or TA_TOP Or TA_NOUPDATECP);

        //----------------------------------------------------------------------
        // Aucune correction d'ancrage ici : TextInsertPoint est deja le point
        // final resolu par le layout. Modifier X/Y dans ce renderer casserait
        // immediatement la parite avec Direct2D.
        //----------------------------------------------------------------------
        PaintCanvas.TextOut(
            HeaderInfo.TextInsertPoint.X,
            HeaderInfo.TextInsertPoint.Y,
            HeaderInfo.Text);
    Finally
        PaintCanvas.Font.Orientation := SaveOrientation;

        SetTextAlign(
            PaintCanvas.Handle,
            SaveAlign);

        SetBkMode(
            PaintCanvas.Handle,
            SaveBkMode);
    End;
End;
Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawZoneHeaders;
Begin
    //-------------------------------------------------------------------------
    //Dessine les headers des zones visibles.
    //
    //REGLE D'OR v71 : cette routine choisit seulement quelles zones existent.
    //Elle ne calcule pas la geometrie des headers. DrawSingleZoneHeader appellera
    //BuildZoneHeaderRenderInfo, qui appartient a la couche layout.
    //-------------------------------------------------------------------------

    If FLayoutMode <> nrblmByZones Then
        Exit;

    If FZoneHeader = Nil Then
        Exit;

    If Not FZoneHeader.Visible Then
        Exit;

    If GetZoneHeaderReservedSize <= 0 Then
        Exit;

    If FZoneLayoutInfo.StartZone.HasZone Then
        DrawSingleZoneHeader(
            nrtpzStart,
            FZoneLayoutInfo.StartZone.OuterCanonicalRect);

    If FZoneLayoutInfo.CenterZone.HasZone Then
        DrawSingleZoneHeader(
            nrtpzCenter,
            FZoneLayoutInfo.CenterZone.OuterCanonicalRect);

    If FZoneLayoutInfo.EndZone.HasZone Then
        DrawSingleZoneHeader(
            nrtpzEnd,
            FZoneLayoutInfo.EndZone.OuterCanonicalRect);
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawOrientedImageListGlyph(
    AImageIndex: Integer;
    Const AGlyphRect: TRect;
    ATextOrientation: TNoReflowTabBarTextOrientation);
Var
    LBitmap:   TBitmap;
    LGraphics: TGPGraphics;
    LImage:    TGPBitmap;
    LMatrix:   TGPMatrix;
    LCenterX:  Single;
    LCenterY:  Single;
    LAngle:    Single;
    LWidth:    Integer;
    LHeight:   Integer;
Begin
    //-------------------------------------------------------------------------
    //Dessine un glyph issu exclusivement de BarImages + GlyphIndex.
    //
    //Le composant ne prend plus en charge de bitmap stocké directement dans
    //l'item. Cela simplifie fortement le pipeline :
    //- le layout réserve la taille effective de FBarImages ;
    //- le rendu horizontal délègue directement à l'ImageList ;
    //- le rendu vertical passe par un bitmap temporaire uniquement pour pouvoir
    //appliquer une rotation GDI+.
    //-------------------------------------------------------------------------

    If FBarImages = Nil Then
        Exit;

    If AImageIndex < 0 Then
        Exit;

    If AImageIndex >= FBarImages.Count Then
        Exit;

    If IsRectEmpty(AGlyphRect) Then
        Exit;

    LWidth := AGlyphRect.Right - AGlyphRect.Left;
    LHeight := AGlyphRect.Bottom - AGlyphRect.Top;

    If (LWidth <= 0) Or (LHeight <= 0) Then
        Exit;

    //Cas horizontal : chemin direct, le plus fiable et le plus simple.
    If ATextOrientation = nrttoHorizontal Then Begin
        FBarImages.Draw(
            PaintCanvas,
            AGlyphRect.Left,
            AGlyphRect.Top,
            AImageIndex);

        Exit;
    End;

    Case ATextOrientation Of
        nrttoVerticalUp:
            LAngle := -90.0;

        nrttoVerticalDown:
            LAngle := 90.0;
    Else
        LAngle := 0.0;
    End;

    //Cas défensif : si l'orientation redevient horizontale ou inconnue.
    If Abs(LAngle) < 0.01 Then Begin
        FBarImages.Draw(
            PaintCanvas,
            AGlyphRect.Left,
            AGlyphRect.Top,
            AImageIndex);

        Exit;
    End;

    //-------------------------------------------------------------------------
    //Cas vertical :
    //
    //TCustomImageList ne sait pas dessiner une image tournée directement.
    //On dessine donc l'image dans un bitmap temporaire à sa taille native, puis
    //on applique la rotation autour du centre du rectangle cible.
    //-------------------------------------------------------------------------

    LBitmap := TBitmap.Create;
    Try
        LBitmap.PixelFormat := pf32bit;
        LBitmap.SetSize(
            FBarImages.Width,
            FBarImages.Height);

        LBitmap.Canvas.Brush.Style := bsSolid;
        LBitmap.Canvas.Brush.Color := Color;
        LBitmap.Canvas.FillRect(Rect(0, 0, LBitmap.Width, LBitmap.Height));

        FBarImages.Draw(
            LBitmap.Canvas,
            0,
            0,
            AImageIndex);

        If LBitmap.Empty Then
            Exit;

        LGraphics := TGPGraphics.Create(PaintCanvas.Handle);
        Try
            LGraphics.SetSmoothingMode(SmoothingModeHighQuality);
            LGraphics.SetInterpolationMode(InterpolationModeHighQualityBicubic);
            LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);

            LImage := TGPBitmap.Create(
                LBitmap.Handle,
                LBitmap.Palette);
            Try
                LMatrix := TGPMatrix.Create;
                Try
                    LCenterX := (AGlyphRect.Left + AGlyphRect.Right) / 2.0;
                    LCenterY := (AGlyphRect.Top + AGlyphRect.Bottom) / 2.0;

                    LMatrix.Translate(
                        LCenterX,
                        LCenterY);

                    LMatrix.Rotate(LAngle);

                    LMatrix.Translate(
                        -LCenterX,
                        -LCenterY);

                    LGraphics.SetTransform(LMatrix);

                    LGraphics.DrawImage(
                        LImage,
                        AGlyphRect.Left,
                        AGlyphRect.Top,
                        LWidth,
                        LHeight);

                    LGraphics.ResetTransform;
                Finally
                    LMatrix.Free;
                End;
            Finally
                LImage.Free;
            End;
        Finally
            LGraphics.Free;
        End;
    Finally
        LBitmap.Free;
    End;
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawItemGlyph(Const ARenderItem: TNoReflowTabBarRenderItem);
Var
    GlyphRect: TRect;
Begin
    //-------------------------------------------------------------------------
    //Dessine le glyph de l'item.
    //
    //Depuis la suppression du bitmap local dans TNoReflowTabBarItem, le glyph
    //provient exclusivement de :
    //
    //- FBarImages ;
    //- Item.GlyphIndex.
    //
    //Le rectangle mémorisé dans Metrics.GlyphRect est local à l'item. Il est
    //donc translaté avec Bounds.Left / Bounds.Top avant dessin.
    //-------------------------------------------------------------------------

    If Not ARenderItem.Visible Then
        Exit;

    If ARenderItem.Item = Nil Then
        Exit;

    If Not ARenderItem.Metrics.HasGlyph Then
        Exit;

    If IsRectEmpty(ARenderItem.Metrics.GlyphRect) Then
        Exit;

    If FBarImages = Nil Then
        Exit;

    If ARenderItem.Item.GlyphIndex < 0 Then
        Exit;

    If ARenderItem.Item.GlyphIndex >= FBarImages.Count Then
        Exit;

    GlyphRect := ARenderItem.Metrics.GlyphRect;

    OffsetRect(
        GlyphRect,
        ARenderItem.Bounds.Left,
        ARenderItem.Bounds.Top);

    DrawOrientedImageListGlyph(
        ARenderItem.Item.GlyphIndex,
        GlyphRect,
        ARenderItem.Metrics.TextOrientation);
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.DrawBarBackground;
Var
    R:       TRect;
    Palette: TNoReflowTabBarPalette;
    LStyle:  TCustomStyleServices;
Begin
    //-------------------------------------------------------------------------
    //Dessine le fond général de la barre.
    //
    //Cette méthode est volontairement distincte du rendu Flat / Gradient des
    //items.
    //
    //Raison :
    //- Flat signifie "fond des items en aplat" ;
    //- il ne doit pas signifier "écraser le fond stylé du contrôle".
    //
    //Avec certains styles VCL, le fond n'est pas une simple couleur :
    //il peut contenir un bitmap, une texture, un dégradé ou un effet propre au
    //style. Un FillRect direct avec Palette.BarBackground détruit ces détails.
    //-------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // Option de composition inter-backends.
    //
    // Certaines passes, notamment le rendu Direct2D avec fond style VCL texture,
    // peuvent deja avoir peint le fond general avant d'utiliser le chemin GDI
    // pour une couche precise. Dans ce cas, le GDI ne doit pas re-effacer le
    // client, sinon il recouvrirait les primitives deja produites.
    //--------------------------------------------------------------------------
    If ntrpoSkipBarBackground In FCurrentPaintOptions Then
        Exit;

    R := ClientRect;

    If IsRectEmpty(R) Then
        Exit;

    //-------------------------------------------------------------------------
    //Palette issue du style :
    //
    //On demande au style VCL de redessiner le fond parent/client.
    //Cela préserve les éventuels bitmaps ou effets de fond du style actif.
    //
    //seClient est respecté afin de ne pas imposer un rendu stylé si le contrôle
    //a explicitement exclu les éléments client de StyleElements.
    //-------------------------------------------------------------------------
    LStyle := ResolveControlStyleServices;

    If (FPaletteMode = nrtcmStyle) And
       (LStyle <> Nil) And
       LStyle.Enabled And
       (seClient In StyleElements) Then Begin
        LStyle.DrawParentBackground(
            Handle,
            PaintCanvas.Handle,
            Nil,
            False,
            @R);

        Exit;
    End;

    //-------------------------------------------------------------------------
    //Palette custom :
    //
    //Ici, l'utilisateur attend explicitement le fond défini par la palette du
    //composant. On conserve donc le comportement historique.
    //-------------------------------------------------------------------------
    Palette := GetActivePalette;

    PaintCanvas.Brush.Style := bsSolid;
    PaintCanvas.Brush.Color := Palette.BarBackground;
    PaintCanvas.FillRect(R);
End;

Function TNoReflowTabBarGDIRenderBackendSupport.GetBackendName: String;
Begin
    Result := 'GDI';
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.PaintToCanvas(ACanvas: TCanvas);
Begin
    PaintToCanvasWithOptions(
        ACanvas,
        []);
End;

Procedure TNoReflowTabBarGDIRenderBackendSupport.PaintToCanvasWithOptions(
    ACanvas: TCanvas;
    AOptions: TNoReflowTabBarRenderPaintOptions);
Var
    I:           Integer;
    VisualState: TNoReflowTabBarItemVisualState;
Begin
    //-------------------------------------------------------------------------
    //Peinture complète de la barre.
    //
    //Règle générale :
    //- le fond de barre est effacé en premier ;
    //- les headers de zones sont peints ensuite ;
    //- les items visibles sont ensuite peints selon le mode courant.
    //
    //Différence importante entre modes :
    //
    //Mode onglets :
    //- les onglets peuvent se recouvrir ;
    //- l'onglet sélectionné doit donc être peint en dernier pour rester au-dessus.
    //
    //Mode boutons :
    //- les boutons sont des formes autonomes ;
    //- le bouton sélectionné ne doit pas recevoir un ordre de peinture spécial ;
    //- sinon on réintroduit un comportement d'onglet dans un rendu de bouton,
    //avec des effets parasites possibles autour de l'item sélectionné.
    //-------------------------------------------------------------------------
    If ACanvas = Nil Then
        Exit;

    FPaintCanvas := ACanvas;
    FCurrentPaintOptions := AOptions;
    Try

        //Dessine le fond général de la barre.
        //
        //Le fond général reste indépendant du mode Flat / Gradient des items.
        //En palette style, cela permet de conserver les éventuels bitmaps ou
        //textures du style VCL.
        DrawBarBackground;

        EnsureRenderInfo;

        //Dessine d'abord les ornements de zones.
        DrawZoneHeaders;

        If IsButtonBarMode Then Begin
            //-----------------------------------------------------------------
            //Mode boutons.
            //
            //On peint chaque bouton une seule fois, sans traitement spécial
            //pour le bouton sélectionné.
            //
            //Contrairement aux onglets, les boutons ne doivent pas dépendre
            //d'un ordre de recouvrement sélectionné/non sélectionné.
            //-----------------------------------------------------------------
            For I := 0 To High(FRenderItems) Do Begin
                If Not FRenderItems[I].Visible Then
                    Continue;

                VisualState := GetItemVisualState(FRenderItems[I].ItemIndex);

                DrawSingleItem(
                    FRenderItems[I],
                    VisualState);
            End;
        End Else Begin
            //-----------------------------------------------------------------
            //Mode onglets.
            //
            //On conserve le comportement historique :
            //- les onglets non sélectionnés sont peints d'abord ;
            //- l'onglet sélectionné est peint en dernier.
            //-----------------------------------------------------------------
            For I := High(FRenderItems) Downto 0 Do Begin
                If Not FRenderItems[I].Visible Then
                    Continue;

                If FRenderItems[I].Selected Then
                    Continue;

                VisualState := GetItemVisualState(FRenderItems[I].ItemIndex);

                DrawSingleItem(
                    FRenderItems[I],
                    VisualState);
            End;

            //L’onglet sélectionné est systématiquement dessiné en dernier
            //uniquement en mode onglets.
            If (FItemIndex >= 0) And (FItemIndex <= High(FRenderItems)) Then Begin
                If FRenderItems[FItemIndex].Visible Then Begin
                    VisualState := GetItemVisualState(FItemIndex);

                    DrawSingleItem(
                        FRenderItems[FItemIndex],
                        VisualState);
                End;
            End;
        End;
    Finally
        FCurrentPaintOptions := [];
        FPaintCanvas := Nil;
    End;
End;

End.
