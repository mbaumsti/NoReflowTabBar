Unit NoReflowTabBar_CommonTypes;

{
  NoReflowTabBar_CommonTypes.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Common low-level types shared by the NoReflowTabBar VCL component.

  Repository:
  https://github.com/mbaumsti/NoReflowTabBar

  License:
  See LICENSE file.

  ------------------------------------------------------------------------------

  Types communs du composant NoReflowTabBar.

  Cette unité fournit :
  - les énumérations fondamentales du composant ;
  - les constantes logiques partagées ;
  - les types simples utilisés par plusieurs unités du projet.

  Rôle de cette unité :
  - centraliser les types de base indépendants de l'implémentation ;
  - éviter les dépendances circulaires entre unités ;
  - fournir un vocabulaire commun au modèle, au style et au rendu.

  Types généralement définis ici :
  - position de barre ;
  - orientation du texte ;
  - position du voyant ;
  - zones logiques des items ;
  - états visuels ;
  - modes de couleur ;
  - codes système des voyants.

  Position dans l'architecture :
  - cette unité se situe au plus bas niveau de dépendance ;
  - elle peut être utilisée par :
  - NoReflowTabBar_Items ;
  - NoReflowTabBar_AppearanceAndLayout ;
  - NoReflowTabBar_RenderTypes ;
  - NoReflowTabBar_Core ;
  - NoReflowTabBar.

  Remarques :
  - cette unité ne contient pas de logique métier ;
  - elle ne dépend pas du contrôle principal ;
  - son contenu doit rester stable, simple et transversal.
}

Interface

Uses
    system.Types,
    Vcl.Graphics;

Type

    TNoReflowZoneHeaderPlacement = (nrthpOuterBand, nrthpAboveZone);

    //Mode fonctionnel global de la barre.
    //
    //Ce mode exprime l'intention principale du composant :
    //
    //- nrbmTabs :
    //mode onglets classique. Le rendu est celui d'une barre d'onglets
    //et un seul item est sélectionné à la fois.
    //
    //- nrbmPushButtons :
    //mode boutons simples. Les items se comportent comme des boutons
    //d'action : un clic déclenche les événements, mais aucun état
    //sélectionné persistant n'est maintenu automatiquement.
    //
    //- nrbmSelectButtons :
    //mode boutons à sélection unique. Le rendu est celui de boutons,
    //mais la barre maintient un seul item actif, comme une barre de
    //navigation ou un groupe de boutons radio.
    //
    //- nrbmCheckButtons :
    //mode boutons cochables indépendants. Chaque item pourra porter
    //son propre état Checked, ce qui permet de construire des groupes
    //de filtres ou d'options activables séparément.
    //
    //Important :
    //Ce type regroupe volontairement rendu et comportement pour éviter
    //d'exposer dans l'inspecteur des combinaisons peu naturelles comme
    //"onglets + sélection multiple" ou "onglets sans sélection".
    TNoReflowTabBarMode = (nrbmTabs, nrbmPushButtons, nrbmSelectButtons, nrbmCheckButtons);

    //Mode de répartition des items.
    TNoReflowTabBarLayoutMode = (nrblmSequential, nrblmByZones);

    //Alignement global du flux de layout dans l'axe principal.
    //
    //Cette option ne change pas l'ordre des items.
    //Elle ne change pas non plus l'ordre des zones.
    //
    //Elle agit uniquement après le calcul du bloc complet à positionner.
    //
    //En mode par zones, le bloc complet correspond à l'ensemble visible :
    //Start / Center / End, avec les espacements inter-zones.
    //
    //En mode séquentiel, le bloc complet correspond à l'ensemble des items
    //placés par le layout séquentiel. En cas de multi-ligne, l'alignement est
    //appliqué au bloc global et non ligne par ligne.
    //
    //- nrtfaStart :
    //comportement historique, départ à MarginStart.
    //
    //- nrtfaCenter :
    //le bloc est centré entre MarginStart et MarginEnd.
    //
    //- nrtfaEnd :
    //le bloc est aligné sur la fin de l'espace disponible, en conservant
    //MarginEnd.
    TNoReflowTabBarFlowAlignment = (nrtfaStart, nrtfaCenter, nrtfaEnd);

    //Ordre logique présenté au moteur de layout.
    //
    //Important :
    //ce type ne modifie pas la géométrie finale du composant.
    //Il ne change pas les transformations Top / Bottom / Left / Right.
    //
    //Il agit uniquement sur l'ordre dans lequel le moteur de layout reçoit
    //les zones et, éventuellement, les items contenus dans ces zones.
    //
    //- nrtfoNormal :
    //ordre historique Start -> Center -> End.
    //
    //- nrtfoReverseZones :
    //ordre logique End -> Center -> Start, mais les items restent dans leur
    //ordre naturel à l'intérieur de chaque zone.
    //
    //- nrtfoReverseZonesAndItems :
    //ordre logique End -> Center -> Start, avec inversion de l'ordre des items
    //dans chaque zone.
    TNoReflowTabBarFlowOrder = (nrtfoNormal, nrtfoReverseZones, nrtfoReverseZonesAndItems);

    //Mode de réordonnancement des items par drag souris.
    //
    //- nrttrmNone         : aucun déplacement d'item par drag
    //- nrttrmSameZoneOnly : déplacement uniquement dans la zone actuelle
    //- nrttrmAllZones     : déplacement dans la zone actuelle et entre zones
    TNoReflowTabBarDragReorderMode = (nrbrmNone, nrbrmSameZoneOnly, nrbrmAllZones);

    //Mode de dialogue drag/drop entre plusieurs barres.
    //
    //Ce mode ne concerne que le drag inter-barres. Il ne bloque jamais le
    //réordonnancement interne de la barre, qui reste piloté par
    //BarDragReorderMode et BarDragReorderZones.
    //
    //- nrtbimNone            : aucun dialogue avec les autres barres ;
    //- nrtbimSourceOnly      : la barre peut envoyer ses items vers une autre
    //barre compatible, mais ne reçoit pas ;
    //- nrtbimTargetOnly      : la barre peut recevoir des items externes, mais
    //n'envoie pas ses propres items ;
    //- nrtbimSourceAndTarget : la barre peut envoyer et recevoir.
    TNoReflowTabBarDragInterBarMode = (nrtbimNone, nrtbimSourceOnly, nrtbimTargetOnly, nrtbimSourceAndTarget);

    //État visuel résolu au moment du rendu.
    //
    //Cet état dépend :
    //- de Enabled ;
    //- du survol souris ;
    //- de l'appui souris ;
    //- de la sélection ou de l'état coché selon le mode de barre.
    //
    //Remarque :
    //Ce type est désormais utilisé pour les onglets ET les boutons.
    TNoReflowTabBarItemVisualState = (nrtvsNormal, nrtvsHot, nrtvsPressed, nrtvsSelected, nrtvsDisabled);

    //Mode de construction de la palette visuelle.
    //- nrtcmCustom : utilise les couleurs exposées par BarAppearance
    //- nrtcmStyle  : reconstruit les couleurs à partir du style VCL actif
    TNoReflowTabBarPaletteMode = (nrtcmCustom, nrtcmStyle);

    //Mode de rendu global de la barre.
    //
    //Ce mode est volontairement commun aux onglets et aux boutons afin
    //d'éviter d'avoir deux stratégies visuelles différentes selon BarMode.
    //
    //Le rendu ne délègue plus le chrome des items à TStyleServices.
    //La palette décide uniquement de l'origine des couleurs :
    //- nrtcmStyle  : couleurs reconstruites depuis le style VCL actif ;
    //- nrtcmCustom : couleurs exposées par BarAppearance.
    //
    //nrrmAuto :
    //le composant choisit automatiquement une stratégie raisonnable :
    //- BarPaletteMode = nrtcmStyle  -> rendu plat avec palette style ;
    //- BarPaletteMode = nrtcmCustom -> rendu gradient historique.
    //
    //nrrmFlat :
    //rendu maison plat.
    //Les couleurs utilisées viennent de BarPaletteMode.
    //
    //nrrmGradient :
    //rendu maison dégradé.
    //Les couleurs utilisées viennent de BarPaletteMode.
    TNoReflowTabBarRenderMode = (nrrmAuto, nrrmFlat, nrrmGradient);

    //Position logique de la barre.
    //Cette position influence :
    //- le sens du layout
    //- la géométrie des items
    //- l'orientation automatique du texte
    //
    //Elle ne modifie pas la propriété Align du contrôle.
    TNoReflowTabBarPosition = (nrtbpTop, nrtbpBottom, nrtbpLeft, nrtbpRight);

    //Orientation du texte des items.
    //- nrttoAuto : orientation déduite de la position de la barre
    //- nrttoHorizontal : texte horizontal
    //- nrttoVerticalUp : texte vertical montant
    //- nrttoVerticalDown : texte vertical descendant
    TNoReflowTabBarTextOrientation = (nrttoAuto, nrttoHorizontal, nrttoVerticalUp, nrttoVerticalDown);

    //Position logique du voyant.
    //
    //- nrtspBefore  : le voyant est placé avant le bloc texte/glyph.
    //- nrtspAfter   : le voyant est placé après le bloc texte/glyph.
    //- nrtspItemEnd : le voyant est placé au bout utile de l'item, dans l'axe
    //du texte, indépendamment de la longueur réelle du texte.
    //
    //nrtspItemEnd est utile pour garder les indicateurs d'état alignés sur le
    //bord final des boutons ou onglets compacts.
    TNoReflowTabBarSignalPosition = (nrtspBefore, nrtspAfter, nrtspItemEnd);

    //Position globale du glyph par rapport au texte de l'item.
    //
    //Cette position est utilisée par défaut pour tous les items qui ne
    //redéfinissent pas eux-mêmes leur position de glyph.
    //
    //- nrgpLeft   : glyph à gauche du texte
    //- nrgpRight  : glyph à droite du texte
    //- nrgpTop    : glyph au-dessus du texte
    //- nrgpBottom : glyph sous le texte
    //
    //Remarque :
    //Le terme "glyph" est volontairement conservé, car il correspond bien
    //au vocabulaire VCL des boutons graphiques, tout en restant utilisable
    //pour les items.
    TNoReflowTabBarGlyphPosition = (nrgpLeft, nrgpRight, nrgpTop, nrgpBottom);

    //Position du glyph propre à un item.
    //
    //- nrigpDefault : utilise la position globale définie par la barre
    //- nrigpLeft    : force le glyph à gauche du texte pour cet item
    //- nrigpRight   : force le glyph à droite du texte pour cet item
    //- nrigpTop     : force le glyph au-dessus du texte pour cet item
    //- nrigpBottom  : force le glyph sous le texte pour cet item
    //
    //Cette séparation entre position globale et position d'item évite
    //d'introduire une valeur "Default" dans la propriété globale de la
    //barre, où elle n'aurait pas de signification claire.
    TNoReflowTabBarItemGlyphPosition = (nrigpDefault, nrigpLeft, nrigpRight, nrigpTop, nrigpBottom);

    //====================================================================
    //Zone logique interne de la barre.
    //
    //Ce type sert aux traitements internes qui doivent pouvoir représenter
    //à la fois une zone réelle et l'absence de zone :
    //
    //- nrtpzNone   : aucune zone logique / état invalide / hit-test négatif
    //- nrtpzStart  : zone ancrée au début
    //- nrtpzCenter : zone centrale / normale
    //- nrtpzEnd    : zone ancrée à la fin
    //
    //Important :
    //nrtpzNone ne doit pas être utilisé comme zone affectable à un item.
    //Pour les propriétés publiées dans l'inspecteur, utiliser
    //TNoReflowTabBarZone.
    //
    //Cette notion est utilisée pour :
    //- les hit-tests de zone
    //- les états temporaires de survol
    //- les cibles de drag & drop
    //- les marqueurs d'insertion
    //- les traitements internes nécessitant une valeur "aucune zone"
    //====================================================================

    TNoReflowTabBarPinZone = (nrtpzNone, //Aucune zone logique
        nrtpzStart, //Zone ancrée au début
        nrtpzCenter, //Zone centrale / normale
        nrtpzEnd //Zone ancrée à la fin
        );

    //====================================================================
    //Zone logique affectable à un item par l'utilisateur.
    //
    //Ce type est volontairement limité aux zones réelles disponibles dans
    //l'inspecteur d'objets. Il ne contient pas de valeur "None", car un
    //item doit toujours appartenir à une zone effective.
    //
    //Cette notion est utilisée pour :
    //- la propriété publiée PinZone de TNoReflowTabBarItem
    //- la structuration physique de la collection en trois blocs
    //- les insertions utilisateur
    //- les déplacements réels d'items entre zones
    //- les autorisations de zones pour le drag/reorder
    //====================================================================
    TNoReflowTabBarZone = (nrtzStart, nrtzCenter, nrtzEnd);

    // //Autorisation du drag par zone
    //TNoReflowTabBarDragReorderZone = (nrtrzStart, nrtrzCenter, nrtrzEnd);

    TNoReflowTabBarZones = Set Of TNoReflowTabBarZone;

    //Metriques calculees pour un item donne.
    //
    //GARDE-FOU : cette structure melange volontairement deux niveaux :
    //- les dimensions logiques ContentLength / MinorSize ;
    //- les dimensions physiques ButtonWidth / ButtonHeight uniquement apres
    //  conversion vers le rectangle local du controle.
    //
    //Regle imperieuse pour les futures modifications :
    //- ContentLength suit l'axe logique principal du contenu ;
    //- MinorSize suit l'axe logique secondaire ;
    //- Length ne doit jamais etre assimile automatiquement a Width ;
    //- Thickness ne doit jamais etre assimile automatiquement a Height ;
    //- quand VerticalFlow=True, l'axe logique Length est materialise par
    //  ButtonHeight, mais il reste une longueur logique ;
    //- quand VerticalFlow=False, l'axe logique Length est materialise par
    //  ButtonWidth.
    //
    //Le code de layout doit raisonner autant que possible avec des noms flow /
    //cross ou Length / Thickness. Les noms X/Y/Width/Height doivent etre reserves
    //aux points ou la conversion vers les coordonnees locales finales est
    //explicitement faite.
    TNoReflowTabBarItemMetrics = Record
        //Position de barre prise en compte pour le calcul.
        TabPosition: TNoReflowTabBarPosition;

        //Orientation réellement retenue pour le texte.
        TextOrientation: TNoReflowTabBarTextOrientation;

        //Indique si le flux principal du contenu est vertical.
        VerticalFlow: Boolean;

        //Longueur utile du contenu texte + voyant + marges internes.
        //
        //ATTENTION : longueur logique, pas largeur physique. Selon VerticalFlow,
        //cette valeur sera convertie vers ButtonWidth ou ButtonHeight.
        ContentLength: Integer;

        //Dimension secondaire minimale necessaire au contenu.
        //
        //ATTENTION : epaisseur logique, pas hauteur physique automatique. Selon
        //VerticalFlow, cette valeur sera convertie vers ButtonHeight ou
        //ButtonWidth.
        MinorSize: Integer;

        //Compensation à ajouter côté "premier slant".
        SlantPadFirst: Integer;

        //Compensation à ajouter côté "second slant".
        SlantPadSecond: Integer;

        //Largeur finale physique du bouton calcule.
        //
        //Cette valeur est une coordonnee locale finale. Elle ne doit pas etre
        //utilisee comme synonyme de Length sans verifier VerticalFlow.
        ButtonWidth: Integer;

        //Hauteur finale physique du bouton calcule.
        //
        //Cette valeur est une coordonnee locale finale. Elle ne doit pas etre
        //utilisee comme synonyme de Length sans verifier VerticalFlow.
        ButtonHeight: Integer;

        //Point d'appel X du texte dans les coordonnees locales du bouton.
        //
        //Regle imperative : ce point est calcule par le layout et consomme
        //tel quel par les renderers. Il ne doit pas etre reconstruit depuis
        //TextClipRect dans GDI ou Direct2D.
        TextX: Integer;

        //Point d'appel Y du texte dans les coordonnees locales du bouton.
        //
        //Pour le texte horizontal, TextX/TextY correspond au coin haut/gauche
        //du rectangle texte. Pour les textes verticaux, il correspond au point
        //d'appel deja projete : bas/gauche en VerticalUp, haut/droit en
        //VerticalDown.
        TextY: Integer;

        //Largeur mesurée du texte.
        TextWidth: Integer;

        //Hauteur mesurée du texte.
        TextHeight: Integer;

        //Indique si le renderer a le droit d'afficher une ellipse lorsque
        //le texte ne tient pas dans TextClipRect.
        //
        //REGLE D'OR v74 : cette décision vient du layout, pas du backend.
        //En mode onglet naturel, le texte doit rester entier ; DirectWrite ne
        //doit donc pas inventer une ellipse parce que ses métriques diffèrent
        //légèrement de celles utilisées par le layout historique GDI.
        //
        //Le cas prévu est le bouton avec ForcedLength, où l'utilisateur impose
        //volontairement une longueur éventuellement insuffisante.
        AllowTextTrimming: Boolean;

        //Rectangle local de composition/clipping du texte.
        //
        //Règle d'architecture : ce rectangle est calculé par le layout, pas par
        //les renderers. Les backends GDI et Direct2D doivent seulement le
        //consommer pour borner le dessin du texte horizontal, notamment lorsque
        //la longueur des boutons est forcée.
        //
        //TextWidth/TextHeight restent les metriques naturelles du texte.
        //TextX/TextY restent l'ancre de dessin calculee par le layout.
        //TextClipRect represente la zone utile dans laquelle le texte peut
        //reellement etre compose sans empieter sur le glyph, le voyant, les
        //slants ou les marges internes.
        TextClipRect: TRect;

        //Rectangle local du glyph si présent.
        //
        //Le rectangle est exprimé dans les coordonnées locales du bouton,
        //comme TextX/TextY et SignalRect.
        //
        //Il est calculé pendant la phase de métriques, puis consommé par
        //le moteur de rendu. Si HasGlyph vaut False, ce rectangle doit être
        //ignoré par le dessin.
        GlyphRect: TRect;

        //Indique si l'item possède un glyph réellement dessinable.
        //
        //Cette information est résolue après application des différentes
        //sources possibles :
        //- événement OnGetTabGlyph
        //- glyph propre à l'item
        //- Images + ImageIndex
        HasGlyph: Boolean;

        //Largeur réelle du glyph retenu pour le rendu.
        //
        //Cette valeur permet au calcul de layout de réserver correctement
        //l'espace horizontal quand le glyph est placé à gauche ou à droite
        //du texte.
        GlyphWidth: Integer;

        //Hauteur réelle du glyph retenu pour le rendu.
        //
        //Cette valeur permet au calcul de layout de réserver correctement
        //l'espace vertical quand le glyph est placé au-dessus ou au-dessous
        //du texte.
        GlyphHeight: Integer;

        //Position logique retenue pour le glyph de cet item.
        //
        //GARDE-FOU IMPORTANT : cette valeur reste exprimee dans le repere
        //canonique horizontal, avant toute adaptation a l'orientation effective
        //du texte. Elle represente donc la demande metier/publication :
        //- Left / Right : avant ou apres le texte dans le modele horizontal ;
        //- Top / Bottom : au-dessus ou au-dessous du texte dans ce meme modele.
        //
        //Cette position doit etre utilisee pour les decisions de comportement
        //qui doivent rester identiques entre texte horizontal et texte vertical,
        //notamment la regle MinimumLength : on recentre seulement lorsque le
        //glyph est logiquement au-dessus ou au-dessous du texte.
        LogicalGlyphPosition: TNoReflowTabBarGlyphPosition;

        //Position physique retenue pour le glyph de cet item.
        //
        //Cette valeur est derivee de LogicalGlyphPosition apres application de
        //l'orientation effective du texte. Elle sert uniquement au placement
        //et au dessin locaux.
        //
        //GARDE-FOU : ne pas utiliser cette position pour decider si une regle
        //fonctionnelle doit s'appliquer. Sinon VerticalUp / VerticalDown peuvent
        //inverser le comportement par rapport au cas horizontal canonique.
        GlyphPosition: TNoReflowTabBarGlyphPosition;

        //Rectangle local du voyant si présent.
        SignalRect: TRect;

        //Indique si l'item possède un voyant.
        HasSignal: Boolean;

        Function GetTextRect: TRect;
        Procedure SetTextRect(Const ARect: TRect);
        Property TextRect: TRect Read GetTextRect Write SetTextRect;
    End;

    //Palette complète utilisée au moment du dessin.
    //
    //Cette structure est la forme résolue des couleurs réellement utilisées
    //par le moteur de rendu, quel que soit le mode choisi (custom ou style).
    TNoReflowTabBarPalette = Record
        //Couleur de fond de la barre elle-même.
        BarBackground: TColor;

        //Dégradé haut de l'onglet normal.
        TabNormalTop: TColor;

        //Dégradé bas de l'onglet normal.
        TabNormalBottom: TColor;

        //Couleur du texte de l'onglet normal.
        TabNormalText: TColor;

        //Couleur de bord de l'onglet normal.
        TabNormalBorder: TColor;

        //Dégradé haut de l'onglet survolé.
        TabHotTop: TColor;
        //Dégradé bas de l'onglet survolé.
        TabHotBottom: TColor;
        //Couleur du texte de l'onglet survolé.
        TabHotText: TColor;
        //Couleur de bord de l'onglet survolé.
        TabHotBorder: TColor;

        //Dégradé haut de l'onglet sélectionné.
        TabSelectedTop: TColor;
        //Dégradé bas de l'onglet sélectionné.
        TabSelectedBottom: TColor;
        //Couleur du texte de l'onglet sélectionné.
        TabSelectedText: TColor;
        //Couleur de bord de l'onglet sélectionné.
        TabSelectedBorder: TColor;

        //Dégradé haut de l'onglet désactivé.
        TabDisabledTop: TColor;
        //Dégradé bas de l'onglet désactivé.
        TabDisabledBottom: TColor;
        //Couleur du texte de l'onglet désactivé.
        TabDisabledText: TColor;
        //Couleur de bord de l'onglet désactivé.
        TabDisabledBorder: TColor;

        //Couleurs du mode onglets : état pressé.
        //
        //Même si l'état pressé est moins central pour un onglet classique que
        //pour un bouton, il existe dans le pipeline visuel du composant.
        //Le garder explicitement évite de rabattre artificiellement Pressed
        //sur Hot, ce qui devient faux en mode style.
        TabPressedTop: TColor;
        TabPressedBottom: TColor;
        TabPressedText: TColor;
        TabPressedBorder: TColor;

        //Couleurs de relief optionnelles pour le rendu onglet.
        //
        //Elles permettent de rapprocher le dessin maison du style VCL actif
        //sans déléguer la géométrie complète au moteur Windows.
        TabLightEdge: TColor;
        TabShadowEdge: TColor;

        //Dégradé haut d'un bouton normal.
        ButtonNormalTop: TColor;

        //Dégradé bas d'un bouton normal.
        ButtonNormalBottom: TColor;

        //Couleur du texte d'un bouton normal.
        ButtonNormalText: TColor;

        //Couleur de bord d'un bouton normal.
        ButtonNormalBorder: TColor;

        //Dégradé haut d'un bouton survolé.
        ButtonHotTop: TColor;

        //Dégradé bas d'un bouton survolé.
        ButtonHotBottom: TColor;

        //Couleur du texte d'un bouton survolé.
        ButtonHotText: TColor;

        //Couleur de bord d'un bouton survolé.
        ButtonHotBorder: TColor;

        //Dégradé haut d'un bouton pressé.
        ButtonPressedTop: TColor;

        //Dégradé bas d'un bouton pressé.
        ButtonPressedBottom: TColor;

        //Couleur du texte d'un bouton pressé.
        ButtonPressedText: TColor;

        //Couleur de bord d'un bouton pressé.
        ButtonPressedBorder: TColor;

        //Dégradé haut d'un bouton sélectionné ou coché.
        ButtonSelectedTop: TColor;

        //Dégradé bas d'un bouton sélectionné ou coché.
        ButtonSelectedBottom: TColor;

        //Couleur du texte d'un bouton sélectionné ou coché.
        ButtonSelectedText: TColor;

        //Couleur de bord d'un bouton sélectionné ou coché.
        ButtonSelectedBorder: TColor;

        //Dégradé haut d'un bouton désactivé.
        ButtonDisabledTop: TColor;

        //Dégradé bas d'un bouton désactivé.
        ButtonDisabledBottom: TColor;

        //Couleur du texte d'un bouton désactivé.
        ButtonDisabledText: TColor;

        //Couleur de bord d'un bouton désactivé.
        ButtonDisabledBorder: TColor;

        //Couleur du filet clair utilisé pour un rendu bouton avec relief.
        ButtonLightEdge: TColor;

        //Couleur du filet sombre utilisé pour un rendu bouton avec relief.
        ButtonShadowEdge: TColor;

        //Couleur du cadre de focus clavier.
        //
        //Jusqu'ici, le focus utilisait implicitement TabSelectedText.
        //Cette couleur dédiée évite ce couplage et sera utile autant pour les
        //onglets que pour les boutons.
        FocusColor: TColor;

        //Couleurs du header de zones.
        ZoneHeaderText: TColor;
        ZoneHeaderLine: TColor;

        //Couleur du marqueur d'insertion affiché pendant un drag.
        DragInsertMarker: TColor;

    End;

    //Zone autorisant l'édition directe du texte des items.
    //
    //Ce type est volontairement séparé de TNoReflowTabReorderZone :
    //- une zone peut autoriser le drag sans autoriser le renommage
    //- une zone peut autoriser le renommage sans autoriser le drag
    //
    //Cela évite de mélanger deux permissions fonctionnelles différentes.
    TNoReflowTabBarEditZone = (nrtezStart, nrtezCenter, nrtezEnd);

    TNoReflowTabBarEditZones = Set Of TNoReflowTabBarEditZone;

    //Orientation du marqueur d'insertion affiché pendant un drag d'item.
    //
    //- nrtdioVertical   : barre verticale dans une barre top/bottom
    //- nrtdioHorizontal : barre horizontale dans une barre left/right
    TNoReflowTabBarDragInsertOrientation = (nrtdioVertical, nrtdioHorizontal);

    //Cible de drag calculée à partir de la souris.
    //
    //Cette structure décrit :
    //- la zone logique visée
    //- l'index relatif d'insertion dans cette zone
    //- la géométrie écran du marqueur à dessiner
    TNoReflowTabBarDragInsertKind = (nrtdikNone, nrtdikBeforeTab, nrtdikAfterTab, nrtdikAtZoneEnd, nrtdikIntoEmptyZone);

    //Type logique de cible pendant un drag d'item.
    //
    //- nrtdtkNone      : aucune cible
    //- nrtdtkSameZone  : insertion dans la zone actuelle
    //- nrtdtkInterZone : insertion provoquant un changement de zone
    TNoReflowTabBarDragTargetKind = (nrtdtkNone, nrtdtkSameZone, nrtdtkInterZone);

    TNoReflowTabBarDragTarget = record
        Valid: Boolean;
        TargetKind: TNoReflowTabBarDragTargetKind;
        PinZone: TNoReflowTabBarPinZone;
        InsertKind: TNoReflowTabBarDragInsertKind;
        TargetItemIndex: Integer;
        ZoneInsertIndex: Integer;

        //Marqueur standard, en coordonnées réelles.
        MarkerPoint: TPoint;
        MarkerDirection: TPoint;
        MarkerRect: TRect;

        //Marqueur interzone, conservé en repère canonique.
        MarkerCanonicalRect: TRect;
        MarkerCanonicalDirection: TPoint;

        procedure Init;
    end;

    TNoReflowTabBarDragBestCandidate = Record
        Valid: Boolean;
        Dist2: Int64;
        TargetKind: TNoReflowTabBarDragTargetKind;
        TargetItemIndex: Integer;
        PinZone: TNoReflowTabBarPinZone;
        ZoneInsertIndex: Integer;
        CanonicalPoint: TPoint;
        MarkerRect: TRect;
        MarkerCanonicalRect: TRect;
        MarkerCanonicalDirection: TPoint;
        InterZoneDirection: Integer;
        procedure Init;
    End;

    //===============================================================================================================================
    //Helpers
    //===============================================================================================================================

Function TabZoneToPinZone(Const AZone: TNoReflowTabBarZone): TNoReflowTabBarPinZone;
Function PinZoneToTabZone(Const APinZone: TNoReflowTabBarPinZone): TNoReflowTabBarZone;
Function PinZoneToReorderZone(APinZone: TNoReflowTabBarPinZone): TNoReflowTabBarZone;
Function ReorderZonesAll: TNoReflowTabBarZones;

Implementation

//===============================================================================================================================
//TNoReflowTabBarItemMetrics
//===============================================================================================================================

Function TNoReflowTabBarItemMetrics.GetTextRect: TRect;
Begin
    Result := Rect(
        TextX,
        TextY,
        TextX + TextWidth,
        TextY + TextHeight);
End;


Procedure TNoReflowTabBarItemMetrics.SetTextRect(Const ARect: TRect);
Begin
    TextX := ARect.Left;
    TextY := ARect.Top;
    TextWidth := ARect.Right - ARect.Left;
    TextHeight := ARect.Bottom - ARect.Top;

    If TextWidth < 0 Then
        TextWidth := 0;

    If TextHeight < 0 Then
        TextHeight := 0;

    TextClipRect := Rect(
        TextX,
        TextY,
        TextX + TextWidth,
        TextY + TextHeight);
End;

//===============================================================================================================================
//TNoReflowTabDragTarget
//===============================================================================================================================

Procedure TNoReflowTabBarDragTarget.Init;
Begin
    Valid := False;
    TargetKind := nrtdtkNone;
    PinZone := nrtpzCenter;
    InsertKind := nrtdikNone;
    TargetItemIndex := -1;
    ZoneInsertIndex := -1;
    MarkerDirection := Point(
        0,
        0);

    MarkerPoint := Point(
        0,
        0);

    MarkerRect := Rect(
        0,
        0,
        0,
        0);
    MarkerCanonicalRect := Rect(
        0,
        0,
        0,
        0);
    MarkerCanonicalDirection := Point(
        0,
        0);
End;

Procedure TNoReflowTabBarDragBestCandidate.Init;
Begin
    Valid := False;
    Dist2 := High(Int64);
    TargetKind := nrtdtkNone;
    TargetItemIndex := -1;
    PinZone := nrtpzCenter;
    ZoneInsertIndex := -1;
    CanonicalPoint := Point(
        0,
        0);
    MarkerRect := Rect(
        0,
        0,
        0,
        0);
    MarkerCanonicalRect := Rect(
        0,
        0,
        0,
        0);
    MarkerCanonicalDirection := Point(
        0,
        0);
    InterZoneDirection := 0;
End;

Function TabZoneToPinZone(Const AZone: TNoReflowTabBarZone): TNoReflowTabBarPinZone;
Begin
    Case AZone Of
        nrtzStart:
            Result := nrtpzStart;

        nrtzCenter:
            Result := nrtpzCenter;

        nrtzEnd:
            Result := nrtpzEnd;
    Else
        Result := nrtpzCenter;
    End;
End;

Function PinZoneToTabZone(Const APinZone: TNoReflowTabBarPinZone): TNoReflowTabBarZone;
Begin
    Case APinZone Of
        nrtpzStart:
            Result := nrtzStart;

        nrtpzCenter:
            Result := nrtzCenter;

        nrtpzEnd:
            Result := nrtzEnd;
    Else
        Result := nrtzCenter;
    End;
End;

Function PinZoneToReorderZone(APinZone: TNoReflowTabBarPinZone): TNoReflowTabBarZone;
Begin
    Result := PinZoneToTabZone(APinZone);
End;

Function ReorderZonesAll: TNoReflowTabBarZones;
Begin
    Result := [nrtzStart, nrtzCenter, nrtzEnd];
End;

End.
