Unit NoReflowTabBar_RenderSupport;

{
  NoReflowTabBar_RenderSupport.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Rendering support layer of the NoReflowTabBar VCL component.

  Repository:
  https://github.com/mbaumsti/NoReflowTabBar

  License:
  See LICENSE file.

  ------------------------------------------------------------------------------

  Couche de support du rendu du composant NoReflowTabBar.

  Cette unité fournit les calculs de métriques, les informations de rendu, les
  contours d'items, les palettes effectives et les routines de dessin utilisées
  par la façade finale du composant.

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

  Nuance importante : les routines CalcHorizontalContentLayout et
  CalcVerticalContentLayout ci-dessous ne remplacent pas ce pipeline. Elles ne
  positionnent que le contenu local d'un item deja dimensionne. La routine
  verticale existe parce que le rendu GDI d'un texte tourne utilise des points
  d'ancrage differents. Toute nouvelle regle de layout local, notamment autour
  de MinimumLength, doit donc etre exprimee en Flow/Cross et reportee de facon
  symetrique dans les deux routines, sans raisonner directement en Width/Height
  ou X/Y final.
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
    NoReflowTabBar_LayoutSupport;

Type
    TNoReflowTabBarRenderSupport = Class(TNoReflowTabBarLayoutSupport)
    protected

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

        //1 canvas
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

        //Calcule la position locale du texte, du glyph et du voyant lorsque
        //le texte est horizontal.
        //
        //GARDE-FOU : cette routine est la reference lisible du layout local
        //de contenu. Toute nouvelle regle introduite ici doit etre exprimee
        //en Flow/Cross, puis verifiee dans CalcVerticalContentLayout.
        Procedure CalcHorizontalContentLayout(
            Var AMetrics: TNoReflowTabBarItemMetrics;
            AHasSignal: Boolean;
            TextW: Integer;
            TextH: Integer;
            SignalDiameter: Integer;
            TopInset: Integer;
            BottomInset: Integer;
            Var ATextX: Integer;
            Var ATextY: Integer;
            Var ASignalRect: TRect);

        //Calcule la position locale du texte, du glyph et du voyant lorsque
        //le texte est vertical.
        //
        //GARDE-FOU : cette routine n'est pas un second moteur de layout en
        //coordonnees finales. Elle est seulement l'adaptateur local necessaire
        //au rendu GDI du texte tourne. Les decisions doivent rester identiques
        //a celles de CalcHorizontalContentLayout et etre exprimees en
        //Flow/Cross.
        //
        //AMetrics est passe en Var car cette methode complete aussi
        //AMetrics.GlyphRect, comme CalcHorizontalContentLayout le fait deja.
        Procedure CalcVerticalContentLayout(
            Var AMetrics: TNoReflowTabBarItemMetrics;
            AHasSignal: Boolean;
            TextW: Integer;
            TextH: Integer;
            SignalDiameter: Integer;
            LeftInset: Integer;
            RightInset: Integer;
            Var ATextX: Integer;
            Var ATextY: Integer;
            Var ASignalRect: TRect);

        //Calcule les quatre points de base de la forme de l’item.
        //Ces points sont ensuite arrondis et enrichis en contour polygonal.
        Procedure CalcOutlineBasePoints(
            Const ARect: TRect;
            Out P0, P1, P2, P3: TPoint;
            Out Radius1, Radius2: Integer);

        //Construit le contour final d’un onglet sous forme de polygone.
        Procedure BuildTabOutlinePoints(
            Const ARect: TRect;
            APoints: TList<TPoint>);

        //Construit le contour final d'un bouton sous forme de polygone.
        //
        //Contrairement au contour d'onglet, ce contour :
        //- ne possède pas de slant ;
        //- ne dépend pas de la position Top / Bottom / Left / Right ;
        //- utilise uniquement le rayon défini par BarLayoutButtons.CornerRadius.
        //
        //Le résultat reste un tableau de points afin que le reste du pipeline
        //puisse continuer à utiliser RegionPoints pour :
        //- le remplissage ;
        //- la bordure ;
        //- le hit-test.
        Procedure BuildButtonOutlinePoints(
            Const ARect: TRect;
            APoints: TList<TPoint>);

        //Construit le contour final d'un item selon le mode de barre courant.
        //
        //En mode onglets, on conserve exactement la géométrie historique.
        //En mode boutons, on bascule vers une forme rectangulaire arrondie
        //indépendante des slants.
        Procedure BuildItemOutlinePoints(
            Const ARect: TRect;
            APoints: TList<TPoint>);

        //Construit les contours polygonaux finaux des items.
        //Ces polygones servent au rendu et au hit-test.
        Procedure BuildRenderItemRegions;

        //Reconstruit entièrement la représentation intermédiaire.
        Procedure RebuildRenderInfo;

        //Reconstruit FRenderItems à la demande si nécessaire.
        Procedure EnsureRenderInfo; override;

        //Initialise FRenderItems à partir de FItems avant placement final.
        Procedure InitRenderItems;

        //Prépare la police du canvas pour la mesure ou le rendu.
        Procedure SetupItemCanvasFont(ASelected: Boolean);

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

        //Résout la position effective du glyph pour un item.
        //
        //L'item peut imposer sa propre position avec GlyphPosition.
        //Si l'item reste en nrigpDefault, la position globale du layout est utilisée.
        //Resout la position logique du glyph pour un item.
        //
        //GARDE-FOU : cette position reste dans le repere canonique horizontal.
        //Elle ne doit pas etre tournee. Elle sert aux regles fonctionnelles qui
        //doivent produire le meme resultat avant transformation finale.
        Function ResolveLogicalGlyphPosition(AItem: TNoReflowTabBarItem): TNoReflowTabBarGlyphPosition;

        //Resout la position physique du glyph pour un item.
        //
        //La position logique obtenue est ensuite adaptee a l'orientation du texte
        //uniquement pour le placement/dessin local.
        Function ResolveGlyphPosition(AItem: TNoReflowTabBarItem): TNoReflowTabBarGlyphPosition;

        //Résout l'orientation effective du texte des headers de zones.
        //
        //Le header doit suivre la même règle que les item :
        //- BarTextOrientation = nrttoAuto : orientation déduite de BarPosition ;
        //- BarTextOrientation forcé      : orientation imposée explicitement.
        Function ResolveZoneHeaderTextOrientation: TNoReflowTabBarTextOrientation;

        //Convertit une position logique de glyph dans le repère du texte
        //horizontal canonique vers la position réellement exploitable dans
        //le repère local de l'item.
        //
        //Objectif :
        //- ne pas disperser les règles de rotation dans les calculs ;
        //- garantir que mesure, placement et dessin utilisent la même logique ;
        //- rendre les positions Left / Right / Top / Bottom cohérentes avec
        //l'orientation effective du texte.
        Function RotateGlyphPositionForTextOrientation(
            AGlyphPosition: TNoReflowTabBarGlyphPosition;
            ATextOrientation: TNoReflowTabBarTextOrientation): TNoReflowTabBarGlyphPosition;

        //Résout la taille effective du glyph pour un item.
        //
        //Retourne False si aucun glyph ne doit être dessiné.
        //Retourne True et renseigne AGlyphW / AGlyphH si un glyph est exploitable.
        Function ResolveGlyphSize(
            AItem: TNoReflowTabBarItem;
            Out AGlyphW: Integer;
            Out AGlyphH: Integer): Boolean;

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

        //Dessine l'intégralité de la barre sur le canvas fourni.
        Procedure PaintToCanvas(ACanvas: TCanvas);

        //Retourne le canvas effectivement utilisé pour peindre.
        Function PaintCanvas: TCanvas;
    End;

Implementation

Procedure TNoReflowTabBarRenderSupport.WMEraseBkgnd(Var Message: TWMEraseBkgnd);
Begin
    Message.Result := 1;
End;

Function TNoReflowTabBarRenderSupport.CalcBaseContentLength(AItem: TNoReflowTabBarItem): Integer;
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

Function TNoReflowTabBarRenderSupport.CalcBaseContentThickness(AItem: TNoReflowTabBarItem): Integer;
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

Procedure TNoReflowTabBarRenderSupport.RecalcMaxTabContentLength;
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

Procedure TNoReflowTabBarRenderSupport.CalcMetricsBaseSizes(
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
        If AMetrics.TabPosition = nrtbpBottom Then Begin
            AMetrics.SlantPadFirst := MulDiv(
                FLayoutTabs.ShapeSlantSecond,
                2,
                3);

            AMetrics.SlantPadSecond := MulDiv(
                FLayoutTabs.ShapeSlantFirst,
                2,
                3);
        End Else Begin
            AMetrics.SlantPadFirst := MulDiv(
                FLayoutTabs.ShapeSlantFirst,
                2,
                3);

            AMetrics.SlantPadSecond := MulDiv(
                FLayoutTabs.ShapeSlantSecond,
                2,
                3);
        End;
    End;
End;

Procedure TNoReflowTabBarRenderSupport.CalcTabMetrics(
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

    //Termine par le placement précis du contenu selon l’orientation retenue.
    If AMetrics.TextOrientation = nrttoHorizontal Then
        CalcHorizontalContentLayout(
            AMetrics,
            AMetrics.HasSignal,
            TextW,
            TextH,
            SignalDiameter,
            TopInset,
            BottomInset,
            AMetrics.TextX,
            AMetrics.TextY,
            AMetrics.SignalRect)
    Else
        CalcVerticalContentLayout(
            AMetrics,
            AMetrics.HasSignal,
            TextW,
            TextH,
            SignalDiameter,
            LeftInset,
            RightInset,
            AMetrics.TextX,
            AMetrics.TextY,
            AMetrics.SignalRect);
End;

Function TNoReflowTabBarRenderSupport.IsTabBarMode: Boolean;
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

Function TNoReflowTabBarRenderSupport.IsButtonBarMode: Boolean;
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

Function TNoReflowTabBarRenderSupport.UseSameLength: Boolean;
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

Function TNoReflowTabBarRenderSupport.UseSameThickness: Boolean;
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

Function TNoReflowTabBarRenderSupport.GetMaxTabContentLength: Integer;
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

Procedure TNoReflowTabBarRenderSupport.ResolveMetricsTextOrientation(Var AMetrics: TNoReflowTabBarItemMetrics);
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

Procedure TNoReflowTabBarRenderSupport.CalcMetricsButtonSize(Var AMetrics: TNoReflowTabBarItemMetrics);
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
        //Dimensionnement sp�cifique au mode boutons.
        //
        //R�gle imp�rative : Length et Thickness sont des dimensions logiques.
        //Ils ne doivent jamais �tre assimil�s directement � Width et Height.
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
        //cas, la longueur naturelle calcul�e plus haut reste prioritaire tant
        //qu'elle d�passe le minimum demand�. Les boutons courts sont simplement
        //allong�s jusqu'� cette limite, sans changer l'�paisseur.
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

Procedure TNoReflowTabBarRenderSupport.CalcMetricsInsets(
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

Procedure TNoReflowTabBarRenderSupport.CalcHorizontalContentLayout(
    Var AMetrics: TNoReflowTabBarItemMetrics;
    AHasSignal: Boolean;
    TextW: Integer;
    TextH: Integer;
    SignalDiameter: Integer;
    TopInset: Integer;
    BottomInset: Integer;
    Var ATextX: Integer;
    Var ATextY: Integer;
    Var ASignalRect: TRect);
Var
    CrossStart:       Integer;
    CrossEnd:         Integer;
    CrossSize:        Integer;
    FlowStart:        Integer;
    FlowEnd:          Integer;
    SignalBefore:            Boolean;
    SignalAfter:             Boolean;
    SignalAtItemEnd:         Boolean;
    CenterStackedGlyphTextInFlow: Boolean;
    SignalTop:               Integer;
    ContentStart:            Integer;
    ContentTop:              Integer;
    ContentFlowSize:         Integer;
    ContentCrossSize:        Integer;
    ContentAreaStart:        Integer;
    ContentAreaEnd:          Integer;
    ContentFlowAreaLength:   Integer;
    GlyphRect:               TRect;
Begin
    //-------------------------------------------------------------------------
    //Place le texte, le signal et le glyph dans le cas d’un texte horizontal.
    //
    //Dans cette configuration :
    //- l'axe "cross" est la hauteur physique du bouton ;
    //- l'axe "flow"  est la longueur logique du contenu.
    //
    //GARDE-FOU : le fait que le flow horizontal soit actuellement stocke dans
    //ButtonWidth ne doit pas faire oublier que le raisonnement reste logique.
    //Toute correction liee a MinimumLength doit viser l'axe flow, pas une
    //coordonne X choisie par reflexe.
    //
    //Le signal est placé avant ou après le bloc "glyph + texte".
    //Le glyph est ensuite placé par rapport au texte selon GlyphPosition.
    //-------------------------------------------------------------------------

    CrossStart := TopInset;
    CrossEnd := AMetrics.ButtonHeight - 1 - BottomInset;
    CrossSize := CrossEnd - CrossStart;

    If CrossSize < 1 Then
        CrossSize := 1;

    Case AMetrics.TabPosition Of
        nrtbpTop: Begin
                FlowStart := AMetrics.SlantPadFirst + FLayout.TextSpaceBefore;
                FlowEnd := AMetrics.ButtonWidth - AMetrics.SlantPadSecond - FLayout.TextSpaceAfter;
            End;

        nrtbpBottom: Begin
                FlowStart := FLayout.TextSpaceBefore;
                FlowEnd := AMetrics.ButtonWidth - FLayout.TextSpaceAfter;
            End;

        nrtbpLeft, nrtbpRight: Begin
                FlowStart := FLayout.TextSpaceBefore;
                FlowEnd := AMetrics.ButtonWidth - FLayout.TextSpaceAfter;
            End;
    Else Begin
            FlowStart := FLayout.TextSpaceBefore;
            FlowEnd := AMetrics.ButtonWidth - FLayout.TextSpaceAfter;
        End;
    End;

    If FlowEnd <= FlowStart Then
        FlowEnd := FlowStart + 1;

    SetRectEmpty(ASignalRect);
    SetRectEmpty(GlyphRect);

    SignalBefore := FSignalPosition = nrtspBefore;
    SignalAfter := FSignalPosition = nrtspAfter;
    SignalAtItemEnd := FSignalPosition = nrtspItemEnd;

    ContentStart := FlowStart;
    ContentAreaStart := FlowStart;
    ContentAreaEnd := FlowEnd;

    //---------------------------------------------------------------------
    //Taille du bloc glyph + texte.
    //---------------------------------------------------------------------
    ContentFlowSize := TextW;
    ContentCrossSize := TextH;

    If AMetrics.HasGlyph Then Begin
        Case AMetrics.GlyphPosition Of
            nrgpLeft, nrgpRight: Begin
                    ContentFlowSize := TextW + FLayout.GlyphSpacing + AMetrics.GlyphWidth;
                    ContentCrossSize := Max(
                        TextH,
                        AMetrics.GlyphHeight);
                End;

            nrgpTop, nrgpBottom: Begin
                    ContentFlowSize := Max(
                        TextW,
                        AMetrics.GlyphWidth);
                    ContentCrossSize := TextH + FLayout.GlyphSpacing + AMetrics.GlyphHeight;
                End;
        End;
    End;

    SignalTop := CrossStart + FLayout.TextSpaceOver + ((CrossSize - FLayout.TextSpaceOver - FLayout.TextSpaceUnder - SignalDiameter) Div 2);

    CenterStackedGlyphTextInFlow := False;

    If IsButtonBarMode And
       AMetrics.HasGlyph And
       ((AMetrics.LogicalGlyphPosition = nrgpTop) Or
        (AMetrics.LogicalGlyphPosition = nrgpBottom)) And
       (FLayoutButtons <> Nil) And
       (FLayoutButtons.ForcedLength <= 0) And
       (FLayoutButtons.MinimumLength > 0) And
       (AMetrics.ButtonWidth > AMetrics.ContentLength) Then
        CenterStackedGlyphTextInFlow := True;

    If AHasSignal And SignalAtItemEnd Then Begin
        //---------------------------------------------------------------------
        //nrtspItemEnd keeps the signal aligned with the useful end edge of the
        //item, independently from the current text length.
        //---------------------------------------------------------------------
        ASignalRect.Right := FlowEnd;
        ASignalRect.Left := ASignalRect.Right - SignalDiameter;
        ASignalRect.Top := SignalTop;
        ASignalRect.Bottom := ASignalRect.Top + SignalDiameter;

        If CenterStackedGlyphTextInFlow Then
            ContentAreaEnd := ASignalRect.Left - FLayout.SignalSpacing;
    End Else If AHasSignal And SignalBefore Then Begin
        ASignalRect.Left := FlowStart;
        ASignalRect.Right := ASignalRect.Left + SignalDiameter;
        ASignalRect.Top := SignalTop;
        ASignalRect.Bottom := ASignalRect.Top + SignalDiameter;

        ContentStart := ASignalRect.Right + FLayout.SignalSpacing;
        ContentAreaStart := ContentStart;
    End Else If AHasSignal And SignalAfter And CenterStackedGlyphTextInFlow Then Begin
        //---------------------------------------------------------------------
        //En correction légère de MinimumLength, le signal placé après le
        //bloc texte/glyph est réservé du côté droit utile du bouton.
        //
        //Le signal reste ainsi dans son rôle visuel de voyant à droite, tandis
        //que le couple vertical glyph + texte est recentré dans l'espace
        //restant. Le comportement historique de nrtspAfter est conservé pour
        //les glyphs gauche/droite et pour les boutons non élargis par
        //MinimumLength.
        //---------------------------------------------------------------------
        ASignalRect.Right := FlowEnd;
        ASignalRect.Left := ASignalRect.Right - SignalDiameter;
        ASignalRect.Top := SignalTop;
        ASignalRect.Bottom := ASignalRect.Top + SignalDiameter;

        ContentAreaEnd := ASignalRect.Left - FLayout.SignalSpacing;
    End;

    If CenterStackedGlyphTextInFlow Then Begin
        //---------------------------------------------------------------------
        //MinimumLength augmente uniquement la longueur logique finale du bouton.
        //
        //Pour un glyph au-dessus ou au-dessous du texte, le contenu forme un
        //bloc vertical qui paraît naturellement devoir être centré. On centre
        //donc uniquement ce bloc glyph + texte dans la zone utile restante.
        //
        //Les signaux ne sont pas déplacés avec ce bloc : ils conservent leur
        //ancrage gauche/droite et réduisent simplement la zone disponible.
        //Pour les glyphs gauche/droite, aucun recentrage n'est appliqué afin
        //de conserver l'impression historique de boutons calés à gauche.
        //---------------------------------------------------------------------
        ContentFlowAreaLength := ContentAreaEnd - ContentAreaStart;

        If ContentFlowAreaLength < ContentFlowSize Then
            ContentFlowAreaLength := ContentFlowSize;

        ContentStart := ContentAreaStart + ((ContentFlowAreaLength - ContentFlowSize) Div 2);
    End;

    ContentTop := CrossStart + FLayout.TextSpaceOver + ((CrossSize - FLayout.TextSpaceOver - FLayout.TextSpaceUnder - ContentCrossSize) Div 2);

    //---------------------------------------------------------------------
    //Placement relatif du glyph et du texte.
    //---------------------------------------------------------------------
    If AMetrics.HasGlyph Then Begin
        Case AMetrics.GlyphPosition Of
            nrgpLeft: Begin
                    GlyphRect.Left := ContentStart;
                    GlyphRect.Top := ContentTop + ((ContentCrossSize - AMetrics.GlyphHeight) Div 2);
                    GlyphRect.Right := GlyphRect.Left + AMetrics.GlyphWidth;
                    GlyphRect.Bottom := GlyphRect.Top + AMetrics.GlyphHeight;

                    ATextX := GlyphRect.Right + FLayout.GlyphSpacing;
                    ATextY := ContentTop + ((ContentCrossSize - TextH) Div 2);
                End;

            nrgpRight: Begin
                    ATextX := ContentStart;
                    ATextY := ContentTop + ((ContentCrossSize - TextH) Div 2);

                    GlyphRect.Left := ATextX + TextW + FLayout.GlyphSpacing;
                    GlyphRect.Top := ContentTop + ((ContentCrossSize - AMetrics.GlyphHeight) Div 2);
                    GlyphRect.Right := GlyphRect.Left + AMetrics.GlyphWidth;
                    GlyphRect.Bottom := GlyphRect.Top + AMetrics.GlyphHeight;
                End;

            nrgpTop: Begin
                    GlyphRect.Left := ContentStart + ((ContentFlowSize - AMetrics.GlyphWidth) Div 2);
                    GlyphRect.Top := ContentTop;
                    GlyphRect.Right := GlyphRect.Left + AMetrics.GlyphWidth;
                    GlyphRect.Bottom := GlyphRect.Top + AMetrics.GlyphHeight;

                    ATextX := ContentStart + ((ContentFlowSize - TextW) Div 2);
                    ATextY := GlyphRect.Bottom + FLayout.GlyphSpacing;
                End;

            nrgpBottom: Begin
                    ATextX := ContentStart + ((ContentFlowSize - TextW) Div 2);
                    ATextY := ContentTop;

                    GlyphRect.Left := ContentStart + ((ContentFlowSize - AMetrics.GlyphWidth) Div 2);
                    GlyphRect.Top := ATextY + TextH + FLayout.GlyphSpacing;
                    GlyphRect.Right := GlyphRect.Left + AMetrics.GlyphWidth;
                    GlyphRect.Bottom := GlyphRect.Top + AMetrics.GlyphHeight;
                End;
        End;
    End Else Begin
        ATextX := ContentStart;
        ATextY := ContentTop + ((ContentCrossSize - TextH) Div 2);
    End;

    AMetrics.GlyphRect := GlyphRect;

    If AHasSignal And
       (Not SignalBefore) And
       (Not SignalAtItemEnd) And
       IsRectEmpty(ASignalRect) Then Begin
        ASignalRect.Left := ContentStart + ContentFlowSize + FLayout.SignalSpacing;
        ASignalRect.Right := ASignalRect.Left + SignalDiameter;
        ASignalRect.Top := SignalTop;
        ASignalRect.Bottom := ASignalRect.Top + SignalDiameter;
    End;
End;

Procedure TNoReflowTabBarRenderSupport.CalcVerticalContentLayout(
    Var AMetrics: TNoReflowTabBarItemMetrics;
    AHasSignal: Boolean;
    TextW: Integer;
    TextH: Integer;
    SignalDiameter: Integer;
    LeftInset: Integer;
    RightInset: Integer;
    Var ATextX: Integer;
    Var ATextY: Integer;
    Var ASignalRect: TRect);
Var
    LogicalCrossStart:            Integer;
    LogicalCrossEnd:              Integer;
    LogicalCrossSize:             Integer;
    LogicalFlowStart:             Integer;
    LogicalFlowEnd:               Integer;
    LogicalFlowLength:            Integer;
    SignalBefore:                 Boolean;
    SignalAfter:                  Boolean;
    SignalAtItemEnd:              Boolean;
    CenterStackedGlyphTextInFlow: Boolean;
    SignalCrossStart:             Integer;
    ContentFlowStart:             Integer;
    ContentCrossStart:            Integer;
    ContentFlowSize:              Integer;
    ContentCrossSize:             Integer;
    ContentFlowAreaStart:         Integer;
    ContentFlowAreaEnd:           Integer;
    ContentFlowAreaLength:        Integer;
    GlyphRect:                    TRect;
Begin
    //-------------------------------------------------------------------------
    //Place le texte, le signal et le glyph dans le cas d'un texte vertical.
    //
    //GARDE-FOU IMPORTANT : cette routine ne doit pas etre comprise comme un
    //travail direct en repere final X/Y. Elle utilise un repere logique :
    //- axe flow  : axe principal du contenu vertical ;
    //- axe cross : axe secondaire du contenu vertical.
    //
    //Dans l'implementation GDI actuelle, ce repere logique est stocke dans des
    //coordonnees locales physiques parce que TextOut attend un point d'ancrage
    //reel. Cela ne doit pas faire oublier la regle de conception : les decisions
    //de layout doivent etre prises sur flow/cross, pas sur Width/Height par
    //reflexe.
    //
    //Regle MinimumLength :
    //- MinimumLength agit sur l'axe logique Length ;
    //- quand le texte est vertical, cet axe est materialise par la hauteur
    //  physique du bouton, mais il reste une longueur logique ;
    //- le recentrage du couple glyph + texte doit donc se faire sur l'axe flow,
    //  ce qui devient visuellement un centrage vertical.
    //
    //Important :
    //AMetrics.LogicalGlyphPosition conserve la position demandee dans le
    //repere horizontal canonique. AMetrics.GlyphPosition contient seulement la
    //position physique adaptee a TextOrientation pour le dessin local.
    //
    //GARDE-FOU FONCTIONNEL : la regle MinimumLength doit comparer la position
    //logique, pas la position physique. Sinon VerticalUp / VerticalDown peuvent
    //appliquer le recentrage au cas inverse du cas horizontal.
    //-------------------------------------------------------------------------

    LogicalCrossStart := LeftInset;
    LogicalCrossEnd := AMetrics.ButtonWidth - 1 - RightInset;
    LogicalCrossSize := LogicalCrossEnd - LogicalCrossStart;

    If LogicalCrossSize < 1 Then
        LogicalCrossSize := 1;

    Case AMetrics.TabPosition Of
        nrtbpLeft: Begin
                LogicalFlowStart := AMetrics.SlantPadSecond + FLayout.TextSpaceBefore;
                LogicalFlowEnd := AMetrics.ButtonHeight - AMetrics.SlantPadFirst - FLayout.TextSpaceAfter;
            End;

        nrtbpRight: Begin
                LogicalFlowStart := AMetrics.SlantPadFirst + FLayout.TextSpaceBefore;
                LogicalFlowEnd := AMetrics.ButtonHeight - AMetrics.SlantPadSecond - FLayout.TextSpaceAfter;
            End;

        nrtbpTop, nrtbpBottom: Begin
                LogicalFlowStart := FLayout.TextSpaceBefore;
                LogicalFlowEnd := AMetrics.ButtonHeight - FLayout.TextSpaceAfter;
            End;
    Else Begin
            LogicalFlowStart := FLayout.TextSpaceBefore;
            LogicalFlowEnd := AMetrics.ButtonHeight - FLayout.TextSpaceAfter;
        End;
    End;

    LogicalFlowLength := LogicalFlowEnd - LogicalFlowStart;
    If LogicalFlowLength < 1 Then Begin
        LogicalFlowLength := 1;
        LogicalFlowEnd := LogicalFlowStart + LogicalFlowLength;
    End;

    SetRectEmpty(ASignalRect);
    SetRectEmpty(GlyphRect);

    SignalBefore := FSignalPosition = nrtspBefore;
    SignalAfter := FSignalPosition = nrtspAfter;
    SignalAtItemEnd := FSignalPosition = nrtspItemEnd;

    //---------------------------------------------------------------------
    //Taille du bloc glyph + texte dans le repere logique vertical.
    //
    //Le texte tourne occupe :
    //- TextW dans l'axe flow ;
    //- TextH dans l'axe cross.
    //---------------------------------------------------------------------
    ContentFlowSize := TextW;
    ContentCrossSize := TextH;

    If AMetrics.HasGlyph Then Begin
        Case AMetrics.GlyphPosition Of
            nrgpTop, nrgpBottom: Begin
                    ContentFlowSize := TextW + FLayout.GlyphSpacing + AMetrics.GlyphHeight;
                    ContentCrossSize := Max(
                        TextH,
                        AMetrics.GlyphWidth);
                End;

            nrgpLeft, nrgpRight: Begin
                    ContentFlowSize := Max(
                        TextW,
                        AMetrics.GlyphHeight);
                    ContentCrossSize := TextH + FLayout.GlyphSpacing + AMetrics.GlyphWidth;
                End;
        End;
    End;

    //---------------------------------------------------------------------
    //Decision de recentrage liee a MinimumLength.
    //
    //Meme si la coordonnee physique concernee est ici Y/ButtonHeight, la regle
    //reste strictement logique : on centre le bloc glyph + texte sur l'axe flow
    //lorsque MinimumLength a allonge l'item et que le glyph est LOGIQUEMENT
    //au-dessus ou au-dessous du texte dans le repere horizontal canonique.
    //
    //Les glyphs gauche/droite conservent le comportement historique : le bloc
    //reste cale au debut logique afin que les boutons donnent le meme effet
    //d'alignement qu'avant l'introduction de MinimumLength.
    //---------------------------------------------------------------------
    CenterStackedGlyphTextInFlow := False;

    If IsButtonBarMode And
       AMetrics.HasGlyph And
       ((AMetrics.LogicalGlyphPosition = nrgpTop) Or
        (AMetrics.LogicalGlyphPosition = nrgpBottom)) And
       (FLayoutButtons <> Nil) And
       (FLayoutButtons.ForcedLength <= 0) And
       (FLayoutButtons.MinimumLength > 0) And
       (AMetrics.ButtonHeight > AMetrics.ContentLength) Then
        CenterStackedGlyphTextInFlow := True;

    //---------------------------------------------------------------------
    //Zone utile de centrage dans l'axe flow.
    //
    //Les signaux ne font pas partie du bloc centre. Ils restent ancres au debut,
    //a la fin ou apres le contenu selon la regle de signal existante. Lorsqu'un
    //recentrage est necessaire, ils reduisent seulement la zone restante dans
    //laquelle le bloc glyph + texte peut etre centre.
    //---------------------------------------------------------------------
    ContentFlowAreaStart := LogicalFlowStart;
    ContentFlowAreaEnd := LogicalFlowEnd;

    If AMetrics.TextOrientation = nrttoVerticalUp Then
        ContentFlowStart := LogicalFlowEnd - ContentFlowSize
    Else
        ContentFlowStart := LogicalFlowStart;

    If AHasSignal Then Begin
        SignalCrossStart := LogicalCrossStart + FLayout.TextSpaceOver + ((LogicalCrossSize - FLayout.TextSpaceOver - FLayout.TextSpaceUnder - SignalDiameter) Div 2);

        If SignalAtItemEnd Then Begin
            If AMetrics.TextOrientation = nrttoVerticalUp Then Begin
                //---------------------------------------------------------
                //VerticalUp + ItemEnd :
                //la fin logique du flux texte correspond au haut physique.
                //---------------------------------------------------------
                ASignalRect.Top := LogicalFlowStart;
                ASignalRect.Bottom := ASignalRect.Top + SignalDiameter;

                If CenterStackedGlyphTextInFlow Then
                    ContentFlowAreaStart := ASignalRect.Bottom + FLayout.SignalSpacing;
            End Else Begin
                //---------------------------------------------------------
                //VerticalDown + ItemEnd :
                //la fin logique correspond au bas physique.
                //---------------------------------------------------------
                ASignalRect.Bottom := LogicalFlowEnd;
                ASignalRect.Top := ASignalRect.Bottom - SignalDiameter;

                If CenterStackedGlyphTextInFlow Then
                    ContentFlowAreaEnd := ASignalRect.Top - FLayout.SignalSpacing;
            End;
        End Else If SignalBefore Then Begin
            If AMetrics.TextOrientation = nrttoVerticalUp Then Begin
                //---------------------------------------------------------
                //VerticalUp + Before :
                //le signal est au debut logique, donc en bas physique.
                //---------------------------------------------------------
                ASignalRect.Bottom := LogicalFlowEnd;
                ASignalRect.Top := ASignalRect.Bottom - SignalDiameter;

                If CenterStackedGlyphTextInFlow Then
                    ContentFlowAreaEnd := ASignalRect.Top - FLayout.SignalSpacing
                Else
                    ContentFlowStart := ASignalRect.Top - FLayout.SignalSpacing - ContentFlowSize;
            End Else Begin
                //---------------------------------------------------------
                //VerticalDown + Before :
                //debut logique = debut physique du flux.
                //---------------------------------------------------------
                ASignalRect.Top := LogicalFlowStart;
                ASignalRect.Bottom := ASignalRect.Top + SignalDiameter;

                If CenterStackedGlyphTextInFlow Then
                    ContentFlowAreaStart := ASignalRect.Bottom + FLayout.SignalSpacing
                Else
                    ContentFlowStart := ASignalRect.Bottom + FLayout.SignalSpacing;
            End;
        End Else If SignalAfter Then Begin
            If CenterStackedGlyphTextInFlow Then Begin
                //---------------------------------------------------------
                //Correction legere MinimumLength :
                //le signal place apres le bloc est reserve du cote fin logique
                //de l'item. Le bloc glyph + texte est ensuite centre dans la
                //zone restante.
                //---------------------------------------------------------
                If AMetrics.TextOrientation = nrttoVerticalUp Then Begin
                    ASignalRect.Top := LogicalFlowStart;
                    ASignalRect.Bottom := ASignalRect.Top + SignalDiameter;

                    ContentFlowAreaStart := ASignalRect.Bottom + FLayout.SignalSpacing;
                End Else Begin
                    ASignalRect.Bottom := LogicalFlowEnd;
                    ASignalRect.Top := ASignalRect.Bottom - SignalDiameter;

                    ContentFlowAreaEnd := ASignalRect.Top - FLayout.SignalSpacing;
                End;
            End Else If AMetrics.TextOrientation = nrttoVerticalUp Then Begin
                //---------------------------------------------------------
                //VerticalUp + After historique :
                //le texte/glyph commence au debut logique, donc en bas
                //physique. Le signal suit apres le texte, donc au-dessus du
                //bloc texte/glyph.
                //---------------------------------------------------------
                ContentFlowStart := LogicalFlowEnd - ContentFlowSize;

                ASignalRect.Bottom := ContentFlowStart - FLayout.SignalSpacing;
                ASignalRect.Top := ASignalRect.Bottom - SignalDiameter;
            End Else Begin
                //---------------------------------------------------------
                //VerticalDown + After historique :
                //signal apres le bloc texte/glyph.
                //---------------------------------------------------------
                ASignalRect.Top := ContentFlowStart + ContentFlowSize + FLayout.SignalSpacing;
                ASignalRect.Bottom := ASignalRect.Top + SignalDiameter;
            End;
        End;

        ASignalRect.Left := SignalCrossStart;
        ASignalRect.Right := ASignalRect.Left + SignalDiameter;
    End;

    If CenterStackedGlyphTextInFlow Then Begin
        ContentFlowAreaLength := ContentFlowAreaEnd - ContentFlowAreaStart;

        If ContentFlowAreaLength < ContentFlowSize Then
            ContentFlowAreaLength := ContentFlowSize;

        ContentFlowStart := ContentFlowAreaStart + ((ContentFlowAreaLength - ContentFlowSize) Div 2);
    End;

    //---------------------------------------------------------------------
    //Placement du bloc texte + glyph dans l'axe secondaire.
    //---------------------------------------------------------------------
    ContentCrossStart := LogicalCrossStart + FLayout.TextSpaceOver + ((LogicalCrossSize - FLayout.TextSpaceOver - FLayout.TextSpaceUnder - ContentCrossSize) Div 2);

    //---------------------------------------------------------------------
    //Placement relatif glyph / texte.
    //
    //Rappel GDI :
    //- nrttoVerticalUp utilise un ancrage texte en bas ;
    //- nrttoVerticalDown utilise un ancrage texte en haut/droite.
    //
    //ATextX / ATextY restent donc des points d'ancrage TextOut, pas le coin
    //haut-gauche d'un rectangle de texte.
    //---------------------------------------------------------------------
    If AMetrics.HasGlyph Then Begin
        Case AMetrics.GlyphPosition Of
            nrgpTop: Begin
                    GlyphRect.Left := ContentCrossStart + ((ContentCrossSize - AMetrics.GlyphWidth) Div 2);
                    GlyphRect.Top := ContentFlowStart;
                    GlyphRect.Right := GlyphRect.Left + AMetrics.GlyphWidth;
                    GlyphRect.Bottom := GlyphRect.Top + AMetrics.GlyphHeight;

                    ATextX := ContentCrossStart + ((ContentCrossSize - TextH) Div 2) + TextH;
                    ATextY := GlyphRect.Bottom + FLayout.GlyphSpacing + TextW;
                End;

            nrgpBottom: Begin
                    ATextX := ContentCrossStart + ((ContentCrossSize - TextH) Div 2) + TextH;
                    ATextY := ContentFlowStart + TextW;

                    GlyphRect.Left := ContentCrossStart + ((ContentCrossSize - AMetrics.GlyphWidth) Div 2);
                    GlyphRect.Top := ContentFlowStart + TextW + FLayout.GlyphSpacing;
                    GlyphRect.Right := GlyphRect.Left + AMetrics.GlyphWidth;
                    GlyphRect.Bottom := GlyphRect.Top + AMetrics.GlyphHeight;
                End;

            nrgpLeft: Begin
                    GlyphRect.Left := ContentCrossStart;
                    GlyphRect.Top := ContentFlowStart + ((ContentFlowSize - AMetrics.GlyphHeight) Div 2);
                    GlyphRect.Right := GlyphRect.Left + AMetrics.GlyphWidth;
                    GlyphRect.Bottom := GlyphRect.Top + AMetrics.GlyphHeight;

                    ATextX := GlyphRect.Right + FLayout.GlyphSpacing + TextH;
                    ATextY := ContentFlowStart + ((ContentFlowSize - TextW) Div 2) + TextW;
                End;

            nrgpRight: Begin
                    ATextX := ContentCrossStart + TextH;
                    ATextY := ContentFlowStart + ((ContentFlowSize - TextW) Div 2) + TextW;

                    GlyphRect.Left := ContentCrossStart + TextH + FLayout.GlyphSpacing;
                    GlyphRect.Top := ContentFlowStart + ((ContentFlowSize - AMetrics.GlyphHeight) Div 2);
                    GlyphRect.Right := GlyphRect.Left + AMetrics.GlyphWidth;
                    GlyphRect.Bottom := GlyphRect.Top + AMetrics.GlyphHeight;
                End;
        End;
    End Else Begin
        ATextX := ContentCrossStart + ((ContentCrossSize - TextH) Div 2) + TextH;
        ATextY := ContentFlowStart + TextW;
    End;

    AMetrics.GlyphRect := GlyphRect;
End;

Procedure TNoReflowTabBarRenderSupport.CalcOutlineBasePoints(
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

Procedure TNoReflowTabBarRenderSupport.BuildTabOutlinePoints(
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

Procedure TNoReflowTabBarRenderSupport.BuildButtonOutlinePoints(
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

Procedure TNoReflowTabBarRenderSupport.BuildItemOutlinePoints(
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

Procedure TNoReflowTabBarRenderSupport.BuildRenderItemRegions;
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

Procedure TNoReflowTabBarRenderSupport.RebuildRenderInfo;
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

Procedure TNoReflowTabBarRenderSupport.EnsureRenderInfo;
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

Procedure TNoReflowTabBarRenderSupport.InitRenderItems;
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

Procedure TNoReflowTabBarRenderSupport.SetupItemCanvasFont(ASelected: Boolean);
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

Procedure TNoReflowTabBarRenderSupport.DrawTabBackground(
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

Procedure TNoReflowTabBarRenderSupport.DrawTabBorder(
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

Procedure TNoReflowTabBarRenderSupport.DrawTabSignal(
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

Procedure TNoReflowTabBarRenderSupport.DrawTabText(
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
    TextToDraw:      String;
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
                    PaintCanvas.Font.Orientation := 900;
                    SetTextAlign(
                        PaintCanvas.Handle,
                        TA_LEFT Or TA_BOTTOM Or TA_NOUPDATECP);
                End;

            nrttoVerticalDown: Begin
                    PaintCanvas.Font.Orientation := 2700;
                    SetTextAlign(
                        PaintCanvas.Handle,
                        TA_RIGHT Or TA_TOP Or TA_NOUPDATECP);
                End;
        End;

        TextToDraw := ResolveItemText(
            ARenderItem.ItemIndex,
            ARenderItem.Item);
        PaintCanvas.TextOut(
            M.TextX + R.Left,
            M.TextY + R.Top,
            TextToDraw);
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

Procedure TNoReflowTabBarRenderSupport.ResolveButtonRenderColors(
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

Procedure TNoReflowTabBarRenderSupport.AdjustBackgroundColorsForRenderMode(
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

Procedure TNoReflowTabBarRenderSupport.DrawButtonBackground(
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

Procedure TNoReflowTabBarRenderSupport.DrawButtonBorder(
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

Procedure TNoReflowTabBarRenderSupport.DefaultPaintButton(
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

    DrawButtonBackground(
        ARenderItem.Bounds,
        ARenderItem.RegionPoints,
        TopColor,
        BottomColor);

    DrawButtonBorder(
        ARenderItem.RegionPoints,
        BorderColor,
        AVisualState);

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

Procedure TNoReflowTabBarRenderSupport.DrawItemFocusOutline(Const ARenderItem: TNoReflowTabBarRenderItem);
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

Procedure TNoReflowTabBarRenderSupport.DefaultPaintTab(
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

    DrawTabBackground(
        ARenderItem.Bounds,
        ARenderItem.RegionPoints,
        TopColor,
        BottomColor);

    DrawClosedEdge := ShouldDrawClosedEdgeForTab(ARenderItem.ItemIndex);

    DrawTabBorder(
        ARenderItem.RegionPoints,
        BorderColor,
        AVisualState,
        1.25,
        DrawClosedEdge);

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

Procedure TNoReflowTabBarRenderSupport.DrawSingleItem(
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
    //OnPaintItem.
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

    If Assigned(FOnPaintItem) Then
        FOnPaintItem(
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

Procedure TNoReflowTabBarRenderSupport.DrawSingleZoneHeader(
    APinZone: TNoReflowTabBarPinZone;
    Const AZoneBounds: TRect);
Var
    CaptionText:     String;
    HeaderReserve:   Integer;
    FlowOrientation: TNoReflowTabBarZoneFlowOrientation;

    CanonZoneRect:   TRect;
    CanonHeaderRect: TRect;
    CanonTextRect:   TRect;

    TextW:         Integer;
    TextFlowSize:  Integer;
    TextCrossSize: Integer;
    VisualTextH:   Integer;
    CanonLineY:    Integer;

    TickSize:      Integer;
    GapBeforeText: Integer;
    GapAfterText:  Integer;

    P1: TPoint;
    P2: TPoint;

    SaveOrientation: Integer;
    SaveAlign:       UINT;
    SaveBkMode:      Integer;

    Metrics: TTextMetric;
    Palette: TNoReflowTabBarPalette;

    HeaderTextOrientation: TNoReflowTabBarTextOrientation;
    CanonInsertPoint:      TPoint;

    Function CanonicalPointToActual(Const P: TPoint): TPoint;
    Begin
        Result := TNoReflowTabBarZoneLayoutEngine.TransformCanonicalPointToActual(
            P,
            FlowOrientation,
            FBarPosition,
            ClientWidth,
            ClientHeight);
    End;

    Procedure DrawCanonicalSegment(
        X1: Integer;
        Y1: Integer;
        X2: Integer;
        Y2: Integer);
    Begin
        //-------------------------------------------------------------------------
        //Dessine un segment exprimé dans le repère canonique TOP.
        //
        //Le moteur de layout se charge ensuite de projeter ce segment dans
        //le repère réel de la barre :
        //- Top    : pas de rotation ;
        //- Bottom : symétrie verticale ;
        //- Left   : rotation vers la gauche ;
        //- Right  : rotation vers la droite.
        //-------------------------------------------------------------------------

        P1 := CanonicalPointToActual(Point(X1, Y1));
        P2 := CanonicalPointToActual(Point(X2, Y2));

        PaintCanvas.MoveTo(
            P1.X,
            P1.Y);

        PaintCanvas.LineTo(
            P2.X,
            P2.Y);
    End;

    Procedure BuildCanonicalTextRectAndInsertPoint;
    Begin
        //-------------------------------------------------------------------------
        //Calcule le rectangle texte et son point d'insertion dans le repère
        //canonique TOP.
        //
        //Principe :
        //- le header est toujours raisonné comme une ligne horizontale en TOP ;
        //- le rectangle texte est posé dans ce repère ;
        //- selon la future position réelle de la barre et le sens du texte,
        //ce rectangle doit parfois être placé à droite de la zone canonique ;
        //- le point d'insertion est ensuite choisi dans ce rectangle ;
        //- la transformation de layout est appliquée uniquement à ce point.
        //
        //Convention utilisée :
        //- le rectangle représente l'emprise logique du texte dans la ligne ;
        //- le sens du texte est considéré comme allant de P1 vers P2 ;
        //- pour un texte horizontal ou descendant, le point de départ est le
        //coin haut/gauche logique ;
        //- pour certains cas verticaux projetés, le point de départ logique
        //doit être le coin opposé pour que la rotation donne le bon ancrage.
        //-------------------------------------------------------------------------

        SetRectEmpty(CanonTextRect);

        Case FBarPosition Of
            nrtbpTop: Begin
                    //-----------------------------------------------------------------
                    //Barre haute.
                    //
                    //Cas canonique pur :
                    //- la ligne du header est horizontale ;
                    //- le texte est horizontal ;
                    //- le point d'insertion GDI est le coin haut/gauche du texte.
                    //-----------------------------------------------------------------
                    CanonTextRect.Left := CanonHeaderRect.Left + TickSize + GapBeforeText;
                    CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                    CanonTextRect.Right := CanonTextRect.Left + TextFlowSize;
                    CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                    CanonInsertPoint := Point(
                        CanonTextRect.Left,
                        CanonTextRect.Top);
                End;

            nrtbpBottom: Begin
                    //-----------------------------------------------------------------
                    //Barre basse.
                    //
                    //Le texte reste horizontal, mais le repère canonique est projeté par
                    //symétrie verticale.
                    //
                    //Si on utilise directement le Top canonique du rectangle, la symétrie
                    //place visuellement le texte trop bas. Il faut donc choisir comme
                    //point canonique le bas du rectangle logique, afin qu'après projection
                    //le point d'insertion réel corresponde au haut visuel du texte.
                    //
                    //Le rectangle reste centré autour de CanonLineY pour que les filets
                    //décoratifs restent cohérents avec le cas Top.
                    //-----------------------------------------------------------------
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
                                //-----------------------------------------------------
                                //Barre gauche + texte descendant.
                                //
                                //Dans le repère canonique TOP, il faut poser le
                                //rectangle côté droit de la zone. Après projection
                                //vers la gauche, ce côté devient le bon côté réel.
                                //
                                //Le point d'insertion est pris au coin bas/droit du
                                //rectangle canonique, conformément au raisonnement :
                                //le rectangle donne le sens du texte de P1 vers P2.
                                //-----------------------------------------------------
                                CanonTextRect.Right := CanonHeaderRect.Right - TickSize - GapBeforeText;
                                CanonTextRect.Left := CanonTextRect.Right - TextFlowSize;
                                CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                                CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                                CanonInsertPoint := Point(
                                    CanonTextRect.Right,
                                    CanonTextRect.Bottom);
                            End;

                        nrttoVerticalUp: Begin
                                //-----------------------------------------------------
                                //Barre gauche + texte montant.
                                //
                                //Ici le rectangle reste côté gauche canonique.
                                //La projection du point haut/gauche donne le bon
                                //ancrage réel pour le sens montant.
                                //-----------------------------------------------------
                                CanonTextRect.Left := CanonHeaderRect.Left + TickSize + GapBeforeText;
                                CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                                CanonTextRect.Right := CanonTextRect.Left + TextFlowSize;
                                CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                                CanonInsertPoint := Point(
                                    CanonTextRect.Left,
                                    CanonTextRect.Top);
                            End;
                    Else Begin
                            //---------------------------------------------------------
                            //Fallback défensif.
                            //
                            //Même si ResolveZoneHeaderTextOrientation devrait toujours
                            //renvoyer un texte vertical pour une barre verticale, on
                            //conserve un cas simple et stable.
                            //---------------------------------------------------------
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
                                //-----------------------------------------------------
                                //Barre droite + texte descendant.
                                //
                                //Symétrique du cas gauche montant :
                                //on conserve le rectangle côté gauche canonique.
                                //-----------------------------------------------------
                                CanonTextRect.Left := CanonHeaderRect.Left + TickSize + GapBeforeText;
                                CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                                CanonTextRect.Right := CanonTextRect.Left + TextFlowSize;
                                CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                                CanonInsertPoint := Point(
                                    CanonTextRect.Left,
                                    CanonTextRect.Top);
                            End;

                        nrttoVerticalUp: Begin
                                //-----------------------------------------------------
                                //Barre droite + texte montant.
                                //
                                //Le rectangle doit être posé côté droit canonique.
                                //Le point d'insertion est le coin bas/droit pour que
                                //la projection vers la droite donne le départ visuel
                                //correct du texte.
                                //-----------------------------------------------------
                                CanonTextRect.Right := CanonHeaderRect.Right - TickSize - GapBeforeText;
                                CanonTextRect.Left := CanonTextRect.Right - TextFlowSize;
                                CanonTextRect.Top := CanonLineY - (TextCrossSize Div 2);
                                CanonTextRect.Bottom := CanonTextRect.Top + TextCrossSize;

                                CanonInsertPoint := Point(
                                    CanonTextRect.Right,
                                    CanonTextRect.Bottom);
                            End;
                    Else Begin
                            //---------------------------------------------------------
                            //Fallback défensif.
                            //---------------------------------------------------------
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
                //---------------------------------------------------------------------
                //Fallback général.
                //---------------------------------------------------------------------
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

    Procedure DrawCanonicalText(
        Const ACanonInsertPoint: TPoint;
        Const AText: String);
    Var
        TextPt: TPoint;
    Begin
        //-------------------------------------------------------------------------
        //Dessine le texte à partir d'un point d'insertion canonique.
        //
        //Le point fourni est déjà le bon point logique dans le repère TOP.
        //Cette méthode ne recalcule donc plus le coin d'ancrage selon la
        //position de barre. Elle se limite à :
        //1) appliquer l'orientation GDI du texte ;
        //2) transformer le point canonique vers le repère réel ;
        //3) appeler TextOut.
        //
        //On garde volontairement TA_LEFT / TA_TOP pour toutes les orientations :
        //le point d'insertion a déjà été choisi pour correspondre au départ
        //visuel souhaité du texte.
        //-------------------------------------------------------------------------

        SaveOrientation := PaintCanvas.Font.Orientation;
        SaveAlign := GetTextAlign(PaintCanvas.Handle);
        SaveBkMode := GetBkMode(PaintCanvas.Handle);

        Try
            SetBkMode(
                PaintCanvas.Handle,
                TRANSPARENT);

            Case HeaderTextOrientation Of
                nrttoHorizontal: Begin
                        PaintCanvas.Font.Orientation := 0;
                    End;

                nrttoVerticalUp: Begin
                        PaintCanvas.Font.Orientation := 900;
                    End;

                nrttoVerticalDown: Begin
                        PaintCanvas.Font.Orientation := 2700;
                    End;
            Else
                PaintCanvas.Font.Orientation := 0;
            End;

            SetTextAlign(
                PaintCanvas.Handle,
                TA_LEFT Or TA_TOP Or TA_NOUPDATECP);

            TextPt := CanonicalPointToActual(ACanonInsertPoint);

            PaintCanvas.TextOut(
                TextPt.X,
                TextPt.Y,
                AText);

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

Begin
    //-------------------------------------------------------------------------
    //Dessine le header décoratif d'une zone.
    //
    //AZoneBounds est exprimé dans le repère canonique du layout de zones.
    //Toute la géométrie est donc calculée dans ce repère, puis transformée
    //ponctuellement vers le repère réel au moment du dessin.
    //-------------------------------------------------------------------------

    If PaintCanvas = Nil Then
        Exit;

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

    PaintCanvas.Font.Assign(FZoneHeader.Font);

    Palette := GetActivePalette;

    PaintCanvas.Font.Color := Palette.ZoneHeaderText;
    PaintCanvas.Brush.Style := bsClear;
    PaintCanvas.Pen.Color := Palette.ZoneHeaderLine;
    PaintCanvas.Pen.Style := psSolid;
    PaintCanvas.Pen.Width := 1;

    CanonZoneRect := AZoneBounds;

    //-------------------------------------------------------------------------
    //Calcule la bande canonique du header.
    //
    //nrthpOuterBand :
    //le header est dans la réserve globale du haut canonique.
    //
    //nrthpAboveZone :
    //le header est placé juste avant la première ligne canonique de la zone.
    //-------------------------------------------------------------------------

    Case FZoneHeader.Placement Of
        nrthpOuterBand:
            CanonHeaderRect := Rect(CanonZoneRect.Left, 0, CanonZoneRect.Right, HeaderReserve);

        nrthpAboveZone:
            CanonHeaderRect := Rect(CanonZoneRect.Left, GetZoneFirstRowCanonicalTop(APinZone) - HeaderReserve, CanonZoneRect.Right, GetZoneFirstRowCanonicalTop(APinZone));
    Else
        CanonHeaderRect := Rect(CanonZoneRect.Left, 0, CanonZoneRect.Right, HeaderReserve);
    End;

    TextW := PaintCanvas.TextWidth(CaptionText);

    GetTextMetrics(
        PaintCanvas.Handle,
        Metrics);

    //-------------------------------------------------------------------------
    //Hauteur visuelle utile du texte.
    //
    //On évite TextHeight ici car l'external leading peut décaler visuellement
    //le centrage du header. tmAscent + tmDescent donne une base plus stable.
    //-------------------------------------------------------------------------

    VisualTextH := Metrics.tmAscent + Metrics.tmDescent;

    HeaderTextOrientation := ResolveZoneHeaderTextOrientation;

    //-------------------------------------------------------------------------
    //Dans le repère canonique, la ligne décorative suit toujours l'axe X.
    //
    //Même pour une barre Left / Right, cette ligne sera ensuite projetée par
    //le moteur de layout. La longueur occupée par le texte le long de cette
    //ligne reste donc TextW.
    //
    //TextCrossSize représente l'épaisseur visuelle du texte par rapport à
    //cette ligne.
    //-------------------------------------------------------------------------

    TextFlowSize := TextW;
    TextCrossSize := VisualTextH;

    CanonLineY := CanonHeaderRect.Top + FZoneHeader.TopMargin + (FZoneHeader.Height Div 2);

    BuildCanonicalTextRectAndInsertPoint;

    //-------------------------------------------------------------------------
    //Dessine les deux segments horizontaux canoniques autour du texte.
    //
    //On utilise CanonTextRect.Left / Right pour que le filet s'interrompe
    //autour de l'emprise réelle du texte, même lorsque le rectangle texte a
    //été posé côté droit de la zone canonique.
    //-------------------------------------------------------------------------

    DrawCanonicalSegment(
        CanonHeaderRect.Left,
        CanonLineY,
        CanonTextRect.Left - GapBeforeText,
        CanonLineY);

    DrawCanonicalSegment(
        CanonTextRect.Right + GapAfterText,
        CanonLineY,
        CanonHeaderRect.Right,
        CanonLineY);

    //-------------------------------------------------------------------------
    //Ticks de début et de fin de zone.
    //-------------------------------------------------------------------------

    DrawCanonicalSegment(
        CanonHeaderRect.Left,
        CanonLineY,
        CanonHeaderRect.Left,
        CanonLineY + TickSize);

    DrawCanonicalSegment(
        CanonHeaderRect.Right - 1,
        CanonLineY,
        CanonHeaderRect.Right - 1,
        CanonLineY + TickSize);

    DrawCanonicalText(
        CanonInsertPoint,
        CaptionText);
End;

Procedure TNoReflowTabBarRenderSupport.DrawZoneHeaders;
Begin
    //-------------------------------------------------------------------------
    //Dessine les headers des zones visibles à partir des rects canoniques
    //fournis directement par le moteur de layout.
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

Procedure TNoReflowTabBarRenderSupport.DrawOrientedImageListGlyph(
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

Function TNoReflowTabBarRenderSupport.RotateGlyphPositionForTextOrientation(
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

Function TNoReflowTabBarRenderSupport.ResolveLogicalGlyphPosition(AItem: TNoReflowTabBarItem): TNoReflowTabBarGlyphPosition;
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

Function TNoReflowTabBarRenderSupport.ResolveGlyphPosition(AItem: TNoReflowTabBarItem): TNoReflowTabBarGlyphPosition;
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

Function TNoReflowTabBarRenderSupport.ResolveZoneHeaderTextOrientation: TNoReflowTabBarTextOrientation;
Begin
    //-------------------------------------------------------------------------
    //Résout l'orientation effective du texte des headers de zones.
    //
    //Règle importante :
    //le header suit l'orientation physique de la barre.
    //
    //- barre Top / Bottom :
    //le header reste horizontal, même si BarTextOrientation force une valeur
    //verticale. Un header vertical sur une barre horizontale serait illisible
    //et incohérent avec la ligne décorative.
    //
    //- barre Left / Right :
    //le header reste vertical, mais son sens respecte BarTextOrientation
    //si celui-ci force explicitement VerticalUp ou VerticalDown.
    //
    //Ainsi, BarTextOrientation influence bien le sens du header vertical,
    //sans casser la cohérence générale du composant.
    //-------------------------------------------------------------------------

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
                        //Mode automatique, ou orientation horizontale forcée :
                        //le header reste vertical car la barre est verticale.
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

Function TNoReflowTabBarRenderSupport.ResolveGlyphSize(
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

Procedure TNoReflowTabBarRenderSupport.DrawItemGlyph(Const ARenderItem: TNoReflowTabBarRenderItem);
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

Function TNoReflowTabBarRenderSupport.PaintCanvas: TCanvas;
Begin
    If FPaintCanvas <> Nil Then
        Result := FPaintCanvas
    Else
        Result := Canvas;
End;

Procedure TNoReflowTabBarRenderSupport.DrawBarBackground;
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

Procedure TNoReflowTabBarRenderSupport.PaintToCanvas(ACanvas: TCanvas);
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
        FPaintCanvas := Nil;
    End;
End;

End.
