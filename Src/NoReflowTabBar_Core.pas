Unit NoReflowTabBar_Core;

{
  NoReflowTabBar_Core.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Internal core layer of the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    See LICENSE file.

  ------------------------------------------------------------------------------

  Socle interne du composant NoReflowTabBar.

  Cette unité fournit :
  - les événements principaux du composant ;
  - TNoReflowTabBarCore, classe racine interne du contrôle.

  Rôle de cette unité :
  - maintenir l'état métier du contrôle ;
  - gérer la collection d'items ;
  - gérer la sélection et sa conservation par référence objet ;
  - synchroniser l'ordre logique des zones avec l'ordre physique de la collection ;
  - gérer les sous-objets persistants Appearance / BarLayout /
    BarLayoutTabs / BarLayoutButtons / ZoneHeader ;
  - fournir les mécanismes d'invalidation et les hooks virtuels utilisés
    par les couches spécialisées.

  Couches descendantes :
  - NoReflowTabBar_LayoutSupport : placement des items et informations de zones ;
  - NoReflowTabBar_RenderSupport : métriques, render items, contours et dessin ;
  - NoReflowTabBar_DragSupport   : drag & drop des items ;
  - NoReflowTabBar               : façade publiée et messages VCL finaux.
}

Interface

Uses
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
    Vcl.ImgList,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_RenderTypes,
    NoReflowTabBar_EventsTypes,
    NoReflowTabBar_Library,
    NoReflowTabBar_Items,
    NoReflowTabBar_AppearanceAndLayout,
    NoReflowTabBar_ZoneLayout,
    NoReflowTabBar_ZoneHeader;

Type

    //Classe de base du composant NoReflowTabBar.
    //
    //Cette classe regroupe le socle interne du contrôle :
    //- état métier
    //- sélection
    //- synchronisation des zones
    //- sous-objets persistants d'apparence, de layout commun,
    //de layout onglets, de layout boutons et de headers de zones
    //- palette et états visuels
    //- hooks virtuels de layout, rendu, hints et drag
    //
    //La classe publiée TNoReflowTabBar expose ensuite l’API finale,
    //les propriétés design-time et les messages VCL spécialisés.
    TNoReflowTabBarCore = Class(TCustomControl, INoReflowTabBarModelHost)
    protected
        //-----------------------------------------------------------------
        //État interne
        //-----------------------------------------------------------------

        FInitializing: Boolean;
        FItemIndex:    Integer;

        FOnChanging:       TNoReflowTabBarChangingEvent;
        FOnChange:         TNoReflowTabBarChangeEvent;
        FOnItemClick:      TNoReflowTabBarClickEvent;
        FOnItemDblClick:   TNoReflowTabBarDblClickEvent;
        FOnItemMouseEnter: TNoReflowTabBarMouseEvent;
        FOnItemMouseLeave: TNoReflowTabBarMouseEvent;
        FOnZoneMouseEnter: TNoReflowTabBarZoneMouseEvent;
        FOnZoneMouseLeave: TNoReflowTabBarZoneMouseEvent;
        FOnGetItemText:    TNoReflowTabBarGetItemTextEvent;
        FOnGetItemHint:    TNoReflowTabBarGetItemHintEvent;
        FOnMeasureItem:    TNoReflowTabBarMeasureItemEvent;
        FOnPaintItem:      TNoReflowTabBarPaintEvent;
        FItems:            TNoReflowTabBarItems;

        FHotZone: TNoReflowTabBarPinZone;

        FPaletteMode: TNoReflowTabBarPaletteMode;

        //Mode de rendu global de la barre.
        //
        //Ce mode pilote la stratégie de dessin commune aux onglets et aux boutons :
        //- plat maison ;
        //- dégradé maison ;
        //- automatique.
        //
        //Il ne remplace pas BarPaletteMode :
        //BarPaletteMode continue à indiquer d'où viennent les couleurs.
        FBarRenderMode: TNoReflowTabBarRenderMode;

        FCustomPalette: TNoReflowTabBarPalette;
        FAppearance:    TNoReflowTabBarAppearance;

        //Mode fonctionnel global de la barre.
        //
        //Ce mode pilote :
        //- le type de rendu principal : onglets ou boutons ;
        //- le comportement de sélection ;
        //- l'interprétation des états Selected / Checked / Pressed.
        //
        //Les modes boutons sont désormais pris en compte par le pipeline de
        //layout, de rendu et de gestion d'état. Les différences restantes
        //doivent être traitées comme des ajustements de comportement ou de
        //rendu, et non comme une API simplement préparatoire.
        FBarMode: TNoReflowTabBarMode;

        FLayout:        TNoReflowTabBarLayout; //commun
        FLayoutTabs:    TNoReflowTabBarLayoutTabs; //spécifique onglets
        FLayoutButtons: TNoReflowTabBarLayoutButtons; //spécifique boutons

        FZoneLayoutInfo: TNoReflowTabBarZoneLayoutInfo;
        FZoneHeader:     TNoReflowTabBarZoneHeader;

        //Choisit le moteur de layout horizontal utilisé pour les barres
        //top/bottom.
        //
        //- nrtlmSequential : disposition séquentielle
        //- nrtlmByZones    : disposition par zones
        FLayoutMode: TNoReflowTabBarLayoutMode;

        //Ordre logique transmis au moteur de layout.
        //
        //Cette propriété ne modifie pas l'ordre physique de FItems.
        //Elle ne modifie pas non plus les rectangles après calcul.
        //
        //Elle change uniquement l'ordre de lecture utilisé par le moteur :
        //- ordre des zones ;
        //- ordre des items dans les zones, selon le mode choisi ;
        //- priorité de compactage multi-ligne.
        FFlowOrder: TNoReflowTabBarFlowOrder;

        //Choisit le comportement du drag des items
        FItemsReorderMode: TNoReflowTabBarDragReorderMode;

        //Mode de dialogue drag/drop avec les autres barres.
        //Cette valeur ne concerne que les échanges inter-barres. Elle ne doit
        //jamais empêcher le réordonnancement interne de cette barre.
        FItemsInterBarMode: TNoReflowTabBarDragInterBarMode;

        //Groupe logique de dialogue entre barres.
        //Deux barres n'échangent automatiquement des items que si leurs groupes
        //sont identiques. La chaîne vide constitue le groupe par défaut.
        FItemsInterBarGroup: String;



        //Détermine quelles zones acceptent le drag d'items.
        //
        //Cette propriété complète BarItemsReorderMode :
        //- BarItemsReorderMode définit la portée du déplacement
        //- FItemsReorderZones définit les zones autorisées comme source/cible
        FItemsReorderZones: TNoReflowTabBarZones;

        //Canvas actuellement utilisé par le pipeline de rendu.
        //
        //Par défaut, il vaut le Canvas du contrôle lui-même.
        //Pendant un paint off-screen, il pointe temporairement vers
        //le canvas d'un bitmap mémoire.
        FPaintCanvas: TCanvas;

        FBarPosition:             TNoReflowTabBarPosition;
        FTextOrientation:         TNoReflowTabBarTextOrientation;
        FSignalPosition:          TNoReflowTabBarSignalPosition;
        FMaxItemContentLength:    Integer;
        FMaxItemMinorSize:        Integer;
        FMaxItemContentThickness: Integer;

        //ImageList globale utilisée comme source de glyphes pour les items.
        //
        //Ordre de priorité prévu pour le rendu :
        //1) glyph local de l'item, si présent ;
        //2) BarImages + GlyphIndex, si GlyphIndex est valide ;
        //3) éventuellement plus tard GlyphName ou événement dédié.
        //
        //Le composant ne devient pas propriétaire de cette ImageList.
        //Il conserve seulement une référence et utilise FreeNotification
        //pour être informé si elle est détruite avant lui.
        FBarImages: TCustomImageList;

        //-----------------------------------------------------------------
        //Suivi des changements de l'ImageList associée à la barre
        //-----------------------------------------------------------------

        //Lien VCL standard permettant au composant d'être averti quand BarImages
        //change réellement de contenu.
        //
        //C'est indispensable avec TVirtualImageList :
        //- l'objet peut être affecté au composant pendant le streaming DFM ;
        //- son Count peut encore valoir 0 à ce moment ;
        //- les images peuvent devenir disponibles seulement après l'initialisation
        //complète de la collection d'images.
        //
        //Sans ce lien, FRenderItems peut être construit trop tôt avec
        //Metrics.HasGlyph=False, puis rester dans cet état.
        FBarImagesChangeLink: TChangeLink;

        FRenderItems:  TArray<TNoReflowTabBarRenderItem>;
        FHotItemIndex: Integer;

        //Index de l'item actuellement pressé par la souris.
        //
        //Cet état est strictement temporaire :
        //- il est positionné au MouseDown ;
        //- il est effacé au MouseUp, au drag ou à l'annulation du drag ;
        //- il sert uniquement à produire l'état visuel nrtvsPressed.
        //
        //Il ne doit pas être confondu avec :
        //- FItemIndex : item courant / sélection logique ;
        //- Checked   : état persistant porté par chaque item.
        FPressedItemIndex: Integer;

        FRenderDirty:      Boolean;
        FLayoutUsedWidth:  Integer;
        FLayoutUsedHeight: Integer;

        FActivePaletteCache: TNoReflowTabBarPalette;
        FPaletteDirty:       Boolean;

        FShowFocus:         Boolean;
        FSelectedFontStyle: TFontStyles;
        FSignals:           TNoReflowTabBarSignalDefs;

        //Indique qu'un redimensionnement interne du contrôle est en cours.
        FInternalSizing: Boolean;

        //Permet de ne pas redessiner le focus pendant un clic qui
        //va immédiatement provoquer un changement de sélection.
        FSuppressFocusInvalidate: Boolean;

        //Référence stable vers l'item actuellement sélectionné.
        //
        //Cette référence sert à conserver la sélection par objet métier
        //lorsque la collection est modifiée (insertions, suppressions,
        //déplacements implicites par changement d'index).
        //
        //Tant que l'objet item existe encore, cette référence permet
        //de retrouver sa nouvelle position réelle dans FItems.
        FSelectedItemRef: TNoReflowTabBarItem;

        //Indique qu'une normalisation interne de l'ordre des items
        //est en cours.
        //
        //Ce garde-fou évite les réentrances du type :
        //NormalizeItemsOrderByZone -> FItems.EndUpdate -> ItemsChanged
        //-> NormalizeItemsOrderByZone
        //
        //Sans cette protection, l'ordre peut devenir instable
        //entre conception, chargement DFM et exécution.
        FNormalizingItemsOrder: Boolean;

        //----------------------------------------------------------------------------
        //Les initialisations
        //----------------------------------------------------------------------------

        //Crée les voyants système par défaut : gris, vert, orange, rouge.
        Procedure InitDefaultSignals;

        //Initialise la palette custom par défaut du composant.
        Procedure InitDefaultCustomPalette;

        //-----------------------------------------------------------------
        //Pipeline de rendu / invalidation
        //-----------------------------------------------------------------

        //Marque la représentation intermédiaire comme obsolète.
        Procedure InvalidateRenderInfo;

        //Invalide uniquement la zone d’un item déjà calculé.
        Procedure InvalidateItem(AIndex: Integer);

        //Réagit à un changement de BarAppearance.
        //
        //La classe TNoReflowTabBarAppearance ne dépend plus directement
        //du composant principal. Elle notifie désormais ses modifications
        //via un callback branché sur cette méthode.
        Procedure AppearanceChanged(Sender: TObject);

        //Réagit à un changement d'un des sous-objets de layout.
        //
        //Les classes de layout ne dépendent pas directement du composant principal.
        //Elles notifient leurs modifications via un callback commun branché ici.
        //
        //Cela concerne :
        //- BarLayout       : layout commun ;
        //- BarLayoutTabs    : layout spécifique aux onglets ;
        //- BarLayoutButtons : layout spécifique aux boutons.
        Procedure LayoutChanged(Sender: TObject);

        //Réagit à un changement du sous-objet ZoneHeader.
        Procedure ZoneHeaderChanged(Sender: TObject);

        //Reconstruit FRenderItems à la demande si nécessaire.
        Procedure EnsureRenderInfo; virtual;

        Function GetZoneHeaderReservedSize: Integer; virtual;

        //Ajuste la taille physique du contrôle aux bounds calculés.
        Procedure RelayoutItems; virtual;

        //Change le moteur de layout horizontal utilisé pour les barres
        //top/bottom.
        Procedure SetLayoutMode(Const Value: TNoReflowTabBarLayoutMode);

        //Change l'ordre logique présenté au moteur de layout.
        Procedure SetFlowOrder(Const Value: TNoReflowTabBarFlowOrder);

        //Réagit à une modification du contenu ou de l'état de BarImages.
        Procedure BarImagesChanged(Sender: TObject);

        //-----------------------------------------------------------------
        //Helpers généraux
        //-----------------------------------------------------------------

        //Indique si le composant est dans un état où les sous-objets
        //peuvent notifier des changements sans perturber le chargement.
        Function CanApplySubObjectChanges: Boolean;

        //-----------------------------------------------------------------
        //Palette / couleurs / états visuels
        //-----------------------------------------------------------------

        //Retourne les services de style VCL à utiliser pour résoudre
        //les couleurs et les fonds du composant.
        //
        //Règle importante en design-time : lorsque la barre est posée sur une
        //fiche ou un conteneur dans le designer Delphi, le style réellement
        //visible est porté par le contexte parent. On privilégie donc le parent
        //en conception, puis on retombe sur le contrôle lui-même et enfin sur
        //le style actif global.
        Function ResolveControlStyleServices: TCustomStyleServices;

        //Construit une palette à partir du style VCL actif ou du style résolu
        //dans le contexte design-time du contrôle.
        Function BuildStylePalette: TNoReflowTabBarPalette;

        //Invalide le cache de palette résolue.
        Procedure InvalidatePalette;

        //Retourne la palette réellement utilisée au moment courant.
        Function GetActivePalette: TNoReflowTabBarPalette;

        //Résout les couleurs réellement utilisées pour un état visuel donné.
        Procedure ResolveTabRenderColors(
            Const APalette: TNoReflowTabBarPalette;
            AVisualState: TNoReflowTabBarItemVisualState;
            ASignalCode: Integer;
            Out ATopColor: TColor;
            Out ABottomColor: TColor;
            Out ATextColor: TColor;
            Out ABorderColor: TColor;
            Out ASignalBrushColor: TColor;
            Out ASignalPenColor: TColor);

        //Retourne l’état visuel courant d’un item.
        Function GetItemVisualState(AIndex: Integer): TNoReflowTabBarItemVisualState;

        //Retourne l'index de l'item qui doit porter l'indication visuelle
        //de focus clavier.
        //
        //Règle retenue :
        //- nrbmTabs / nrbmSelectButtons : l'item sélectionné ;
        //- nrbmPushButtons / nrbmCheckButtons : l'item courant de navigation
        // / dernier item activé, même s'il n'existe pas d'état Selected
        //persistant.
        //
        //Dans l'état actuel, cela correspond à FItemIndex si celui-ci reste
        //dans les bornes de FItems.
        Function GetFocusVisualItemIndex: Integer;

        //Indique si la bordure doit être fermée pour cet onglet.
        //L’onglet sélectionné garde son bord de contact ouvert.
        Function ShouldDrawClosedEdgeForTab(AIndex: Integer): Boolean;

        //Donne la couleur de pré-remplissage à utiliser avant le gradient
        //pour éviter un jour visuel sur certaines orientations.
        Function GetGDIPrefillColor(ATopColor, ABottomColor: TColor): TColor;

        //Recopie un sous-objet d’apparence dans l’instance interne.
        Procedure SetAppearance(Const Value: TNoReflowTabBarAppearance);

        //Recopie un sous-objet de header de zones dans l'instance interne.
        Procedure SetZoneHeader(Const Value: TNoReflowTabBarZoneHeader);

        //Recopie un sous-objet de layout commun dans l'instance interne.
        Procedure SetLayout(Const Value: TNoReflowTabBarLayout);

        //Recopie un sous-objet de layout onglets dans l'instance interne.
        Procedure SetLayoutTabs(Const Value: TNoReflowTabBarLayoutTabs);

        //Recopie un sous-objet de layout boutons dans l'instance interne.
        Procedure SetLayoutButtons(Const Value: TNoReflowTabBarLayoutButtons);

        //Change le mode de palette.
        Procedure SetPaletteMode(Const Value: TNoReflowTabBarPaletteMode);

        //Change le mode de rendu global.
        //
        //Ce mode ne décrit pas la source des couleurs, mais la manière de
        //dessiner les items :
        //- plat ;
        //- dégradé ;
        //- automatique.
        Procedure SetBarRenderMode(Const Value: TNoReflowTabBarRenderMode);

        //Retourne le mode de rendu réellement appliqué.
        //
        //Cette méthode résout nrrmAuto en une valeur concrète afin que le
        //pipeline de rendu puisse raisonner sur un mode effectif simple.
        Function GetEffectiveBarRenderMode: TNoReflowTabBarRenderMode;

        //Change le mode fonctionnel global de la barre.
        //
        //Le mode détermine :
        //- le rendu utilisé ;
        //- le comportement de sélection ;
        //- l'interprétation des états visuels.
        //
        //Le setter invalide complètement le layout afin que le changement de
        //mode soit immédiatement répercuté dans le calcul des zones, le rendu
        //et les états internes associés aux onglets ou aux boutons.
        Procedure SetBarMode(Const Value: TNoReflowTabBarMode);

        //Affecte l'ImageList globale utilisée par les items.
        //
        //Cette source est utilisée quand un item ne possède pas de glyph local
        //mais possède un GlyphIndex valide.
        Procedure SetBarImages(Const Value: TCustomImageList);

        //Retourne le texte réellement utilisé pour un item.
        //
        //Cette méthode centralise le fallback Caption + l'événement
        //OnGetItemText afin que mesure, layout, rendu et hints restent
        //cohérents.
        Function ResolveItemText(
            AIndex: Integer;
            AItem: TNoReflowTabBarItem): String;

        //Retourne le hint réellement utilisé pour un item.
        //
        //Le résultat vaut True si un hint doit être affiché. AHint contient
        //alors le texte à présenter dans la fenêtre de hint.
        Function ResolveItemHint(
            AIndex: Integer;
            ATab: TNoReflowTabBarItem;
            Out AHint: String): Boolean;

        //Mesure le texte résolu d'un item et donne au code utilisateur
        //un point d'extension contrôlé via OnMeasureItem.
        Procedure MeasureItemText(
            ACanvas: TCanvas;
            AIndex: Integer;
            AItem: TNoReflowTabBarItem;
            ASelectedFont: Boolean;
            Out ATextWidth: Integer;
            Out ATextHeight: Integer);

        //Déclenche OnItemClick si un handler est affecté.
        Procedure DoItemClick(
            AItemIndex: Integer;
            ATab: TNoReflowTabBarItem;
            Button: TMouseButton;
            Shift: TShiftState;
            X, Y: Integer);

        //Synchronise Checked avec l'index courant lorsque le mode impose une
        //sélection exclusive.
        //
        //Modes concernés :
        //- nrbmTabs ;
        //- nrbmSelectButtons.
        //
        //Modes non concernés :
        //- nrbmPushButtons  : pas d'état persistant automatique ;
        //- nrbmCheckButtons : Checked reste indépendant sur chaque item.
        Procedure SyncCheckedStateFromCurrentIndex;

        //Affecte l'état Checked d'un item sans changer la sélection logique.
        Procedure SetItemCheckedDirect(
            AItemIndex: Integer;
            AChecked: Boolean);

        //Inverse l'état Checked d'un item.
        Procedure ToggleItemCheckedByIndex(AItemIndex: Integer);

        //Applique uniquement l'état interne lié à l'activation d'un item.
        //
        //Cette méthode ne déclenche pas OnItemClick.
        //Elle permet à la façade TNoReflowTabBar de différer uniquement
        //l'événement de clic lorsque OnItemDblClick est branché, sans retarder :
        //- la sélection ;
        //- l'état Checked ;
        //- l'état courant ;
        //- les notifications OnChanging / OnChange.
        Procedure ApplyItemActivationState(AItemIndex: Integer);

        //Exécute le comportement métier associé à un clic validé sur un item.
        //
        //Cette méthode centralise la différence entre :
        //- onglets classiques ;
        //- boutons push ;
        //- boutons à sélection unique ;
        //- boutons cochables.
        Procedure ExecuteItemActivation(
            AItemIndex: Integer;
            Button: TMouseButton;
            Shift: TShiftState;
            X, Y: Integer);

        //Déclenche OnItemDblClick si un handler est affecté.
        Procedure DoItemDblClick(
            AItemIndex: Integer;
            ATab: TNoReflowTabBarItem;
            Shift: TShiftState;
            X, Y: Integer);

        //Retourne la caption de header associée à une zone logique.
        Function GetZoneHeaderCaption(APinZone: TNoReflowTabBarPinZone): String;

        Function GetZoneFirstRowCanonicalTop(APinZone: TNoReflowTabBarPinZone): Integer;

        //----------------------------------------------------------------------------
        //Navigation dans les items
        //----------------------------------------------------------------------------

        //Change l’item sélectionné via son index.
        Procedure SetBarCurrentItemIndex(Const Value: Integer);

        //Retourne l'index absolu d'un item donné dans la collection.
        //
        //Si l'item ne fait pas partie de cette barre, la fonction renvoie -1.
        Function IndexOfItem(ATab: TNoReflowTabBarItem): Integer;

        //Retourne l’index de l’item sous le point donné.
        //Le test se fait sur le polygone réel et non sur le rectangle brut.
        Function ItemAtPos(Const P: TPoint): Integer;

        //Retourne la zone logique située sous un point client.
        //
        //Le résultat vaut False si aucune zone réelle n'est trouvée.
        //Dans ce cas, APinZone vaut nrtpzNone.
        //
        //Important :
        //cette méthode retourne des TNoReflowTabBarPinZone car elle doit
        //pouvoir représenter l'absence de zone avec nrtpzNone.
        Function ZoneAtPos(
            Const P: TPoint;
            Out APinZone: TNoReflowTabBarPinZone): Boolean;

        //Déclenche OnItemMouseEnter si un handler est affecté.
        Procedure DoItemMouseEnter(
            AItemIndex: Integer;
            ATab: TNoReflowTabBarItem;
            Shift: TShiftState;
            X, Y: Integer);

        //Déclenche OnItemMouseLeave si un handler est affecté.
        Procedure DoItemMouseLeave(
            AItemIndex: Integer;
            ATab: TNoReflowTabBarItem;
            Shift: TShiftState;
            X, Y: Integer);

        //Déclenche OnZoneMouseEnter si un handler est affecté.
        Procedure DoZoneMouseEnter(
            APinZone: TNoReflowTabBarPinZone;
            Shift: TShiftState;
            X, Y: Integer);

        //Déclenche OnZoneMouseLeave si un handler est affecté.
        Procedure DoZoneMouseLeave(
            APinZone: TNoReflowTabBarPinZone;
            Shift: TShiftState;
            X, Y: Integer);

        //Applique une nouvelle sélection après validation de l’index.
        Procedure ApplyItemIndex(
            ANewIndex: Integer;
            ARaiseEvent: Boolean);

        //Indique si un item est actuellement sélectionnable.
        Function IsItemSelectable(AIndex: Integer): Boolean;

        //Cherche le prochain item sélectionnable à partir d’un index.
        Function FindNextSelectableItem(AStartIndex: Integer): Integer;

        //Cherche l’item sélectionnable précédent à partir d’un index.
        Function FindPreviousSelectableTab(AStartIndex: Integer): Integer;

        //Retourne le ItemUserId de l'item sélectionné.
        Function GetBarItemUserId: Integer;

        //Retourne l'item actuellement sélectionné.
        Function GetBarCurrentItem: TNoReflowTabBarItem;

        Function CompareItemsForZoneOrder(ALeft, ARight: TNoReflowTabBarItem): Integer;

        Procedure RebuildStoredZoneIndexes;

        //Déplace physiquement un item de collection d'un index absolu
        //vers un autre index absolu.
        Procedure MoveCollectionItem(
            AFromIndex: Integer;
            AToIndex: Integer);

        //Retourne l'index absolu où insérer un item dans une zone donnée
        //à une position relative donnée dans cette zone.
        Function GetAbsoluteIndexForZonePosition(
            APinZone: TNoReflowTabBarPinZone;
            AZoneIndex: Integer): Integer;

        //Active ou non le dessin du focus sur l’item sélectionné.
        Procedure SetShowFocus(Const Value: Boolean);

        //Définit le style de police appliqué à l’item sélectionné.
        Procedure SetSelectedFontStyle(Const Value: TFontStyles);

        //Change la position logique de la barre.
        Procedure SetBarPosition(Const Value: TNoReflowTabBarPosition);

        //Change l’orientation du texte des items.
        Procedure SetTextOrientation(Const Value: TNoReflowTabBarTextOrientation);

        //Change la position logique du voyant par rapport au texte ou au bout utile de l’item.
        Procedure SetSignalPosition(Const Value: TNoReflowTabBarSignalPosition);

        //Recopie une collection externe dans la collection interne.
        Procedure SetItems(Const Value: TNoReflowTabBarItems);

        //Active ou non la fermeture complète de la bordure des onglets.
        Procedure SetShowClosingEdge(Const Value: Boolean);

        //Retourne l'état de fermeture de bordure actuellement défini
        //dans le layout spécifique aux onglets.
        //
        //Cette méthode sert de passerelle de compatibilité pour l'ancienne
        //propriété BarShowClosingEdge, dont la source de vérité est maintenant
        //BarLayoutTabs.ShowClosingEdge.
        Function GetShowClosingEdge: Boolean;

        //Accès pratique à la visibilité via ItemUserId.
        Function IsItemVisible(AItemUserId: Integer): Boolean;

        //Modifie la visibilité du premier item trouvé pour ce ItemUserId.
        Procedure SetItemVisible(
            AItemUserId: Integer;
            AVisible: Boolean);


        //----------------------------------------------------------------------------
        //Les méthodes d'interface
        //----------------------------------------------------------------------------

        //Réagit aux changements de collection et tente de conserver
        //une sélection valide.
        Procedure ItemsChanged;

        //Invalidation complète du layout : métriques, bounds, taille du contrôle.
        Procedure InvalidateLayout;

        //Notification interne appelée lorsqu'un item va être détruit.
        //
        //Si cet item correspond à la sélection mémorisée par objet,
        //la référence stable est remise à Nil pour éviter tout pointeur
        //obsolète après destruction.
        Procedure SelectedItemReferenceRemoved(ATab: TNoReflowTabBarItem);

        //Recherche un voyant par son code.
        Function FindSignalDefByCode(ACode: Integer): TNoReflowTabBarSignalDef;

        //Recherche un voyant par son nom.
        Function FindSignalDefByName(Const AName: String): TNoReflowTabBarSignalDef;

        Function IsHostLoading: Boolean;

        //Synchronisation des index des items entre ordre logique et ordre physique.
        Procedure NormalizeItemsOrderByZone;

        //Retourne le nombre d'items appartenant à une zone donnée.
        Function GetItemsCountInZoneInternal(APinZone: TNoReflowTabBarPinZone): Integer;

        Procedure HideCustomHint; virtual;

        //Réapplique les conséquences internes d’un changement de BarPosition
        //puis relance le recalcul du layout.
        Procedure ApplyBarPosition; virtual;

        //Surveille la destruction de BarImages.
        //
        //Si l'ImageList affectée à BarImages est détruite ailleurs dans
        //l'application, le composant remet sa référence à Nil pour éviter
        //tout accès à un composant libéré.
        Procedure Notification(
            AComponent: TComponent;
            Operation: TOperation); override;

    public
        //Crée le contrôle et initialise ses sous-objets internes.
        Constructor Create(AOwner: TComponent); override;

        //Libère les sous-objets internes du composant.
        Destructor Destroy; override;

        //Indique l'orientation du flux
        Function GetZoneFlowOrientation: TNoReflowTabBarZoneFlowOrientation; virtual;

        //-----------------------------------------------------------------
        //Création / suppression des items
        //-----------------------------------------------------------------
        //Retourne l'index relatif de zone pour un index absolu donné.
        //
        //Si l'index est invalide, la fonction renvoie -1.
        Function GetItemZoneIndex(AIndex: Integer): Integer;

        //Convertit un index relatif de zone en index absolu dans FItems.
        //
        //Si l'index de zone est hors plage, il est clampé.
        Function GetAbsoluteIndexFromZoneIndex(
            APinZone: TNoReflowTabBarPinZone;
            AZoneIndex: Integer): Integer;

        //Retourne le nombre d'items appartenant à une zone donnée.
        Function GetItemsCountInZone(APinZone: TNoReflowTabBarPinZone): Integer;

        //Ajoute un nouvel item en fin de zone centrale.
        Function AddItem(
            Const ACaption: String;
            ASignalCode: Integer = 0;
            AItemUserId: Integer = 0;
            AEnabled: Boolean = True): TNoReflowTabBarItem;

        //Insère un nouvel item à un index relatif dans une zone donnée.
        Function InsertItemInZone(
            APinZone: TNoReflowTabBarPinZone;
            AZoneIndex: Integer;
            Const ACaption: String;
            ASignalCode: Integer = 0;
            AItemUserId: Integer = 0;
            AEnabled: Boolean = True): TNoReflowTabBarItem;

        //Insère un item dans la zone de début.
        Function InsertStartItem(
            AZoneIndex: Integer;
            Const ACaption: String;
            ASignalCode: Integer = 0;
            AItemUserId: Integer = 0;
            AEnabled: Boolean = True): TNoReflowTabBarItem;

        //Insère un item dans la zone centrale.
        Function InsertCenterItem(
            AZoneIndex: Integer;
            Const ACaption: String;
            ASignalCode: Integer = 0;
            AItemUserId: Integer = 0;
            AEnabled: Boolean = True): TNoReflowTabBarItem;

        //Insère un item dans la zone de fin.
        Function InsertEndItem(
            AZoneIndex: Integer;
            Const ACaption: String;
            ASignalCode: Integer = 0;
            AItemUserId: Integer = 0;
            AEnabled: Boolean = True): TNoReflowTabBarItem;

        //Ajoute un nouvel item en fin de zone de début.
        Function AddStartItem(
            Const ACaption: String;
            ASignalCode: Integer = 0;
            AItemUserId: Integer = 0;
            AEnabled: Boolean = True): TNoReflowTabBarItem;

        //Ajoute un nouvel item en fin de zone centrale.
        Function AddCenterItem(
            Const ACaption: String;
            ASignalCode: Integer = 0;
            AItemUserId: Integer = 0;
            AEnabled: Boolean = True): TNoReflowTabBarItem;

        //Ajoute un nouvel item en fin de zone de fin.
        Function AddEndItem(
            Const ACaption: String;
            ASignalCode: Integer = 0;
            AItemUserId: Integer = 0;
            AEnabled: Boolean = True): TNoReflowTabBarItem;

        //Supprime tous les items
        Procedure ClearItems;

        //Supprime tous les items de la zone de début.
        Procedure ClearStartItems;

        //Supprime tous les items de la zone centrale.
        Procedure ClearCenterItems;

        //Supprime tous les items de la zone de fin.
        Procedure ClearEndItems;

        //Sélectionne un item à partir de sa zone logique et de son index
        //relatif dans cette zone.
        Procedure SelectItemInZone(
            APinZone: TNoReflowTabBarPinZone;
            AZoneIndex: Integer);

        //Sélectionne le prochain item sélectionnable.
        Procedure SelectNext;

        //Sélectionne l’item sélectionnable précédent.
        Procedure SelectPrevious;

        //Recherche l'item par sa clé unique
        Function GetItemByKey(AItemKey: Integer): TNoReflowTabBarItem;
        //Recherche le premier item correspondant à un identifiant utilisateur.
        Function GetItemByUserId(AItemUserId: Integer): TNoReflowTabBarItem;

        //Retourne l’index de l'item trouvé pour cette clé unique
        Function IndexOfItemKey(AItemKey: Integer): Integer;
        //Retourne l’index du premier item trouvé pour cet identifiant.
        Function IndexOfItemUserId(AItemUserId: Integer): Integer;

        //Sélectionne l'item
        Function SelectItem(AItem: TNoReflowTabBarItem): Boolean;

        //Sélectionne l'item possédant cette clé
        Function SelectItemByKey(AItemKey: Integer): Boolean;
        //Sélectionne le premier item trouvable pour cet identifiant.
        Function SelectItemByUserId(AItemUserId: Integer): Boolean;

        //Accès indexé à l'item par clé technique unique.
        Property ItemByKey[AItemKey: Integer]: TNoReflowTabBarItem Read GetItemByKey;

        //Retourne directement le premier item trouvé pour cet identifiant utilisateur.
        //
        //Attention : ItemUserId n'est pas imposé unique par le composant.
        //Si plusieurs items ont le même ItemUserId, cette propriété retourne le premier.
        Property ItemByUserId[AItemUserId: Integer]: TNoReflowTabBarItem Read GetItemByUserId;

        //Déplace un item donné à une nouvelle position relative
        //dans sa zone logique actuelle.
        Procedure MoveItemInZone(
            ATab: TNoReflowTabBarItem;
            ANewZoneIndex: Integer);

        //Déplace un item donné vers une autre zone logique
        //et à une position donnée dans cette nouvelle zone.
        Procedure MoveItemToZone(
            ATab: TNoReflowTabBarItem;
            ANewPinZone: TNoReflowTabBarPinZone;
            ANewZoneIndex: Integer);

        //Déplace l'item d'un cran vers le début de sa zone.
        Procedure MoveItemPriorInZone(ATab: TNoReflowTabBarItem);

        //Déplace l'item d'un cran vers la fin de sa zone.
        Procedure MoveItemNextInZone(ATab: TNoReflowTabBarItem);

        Procedure MoveSelectedItemPriorInZone;
        Procedure MoveSelectedItemNextInZone;
    End;

Implementation

//===============================================================================================================================
//TNoReflowTabBarCore - initialisations
//===============================================================================================================================

Constructor TNoReflowTabBarCore.Create(AOwner: TComponent);
Begin
    //-------------------------------------------------------------------------
    //Le constructeur initialise :
    //- l’état interne du composant
    //- les sous-objets persistants :
    //Tabs / Appearance / BarLayout / BarLayoutTabs / BarLayoutButtons / ZoneHeader
    //- les valeurs par défaut de comportement et d’apparence
    //- la position initiale de la barre
    //
    //Le flag FInitializing empêche les sous-objets de déclencher trop tôt
    //des invalidations pendant que le composant est encore en construction.
    //-------------------------------------------------------------------------
    FInitializing := True;
    Try
        Inherited Create(AOwner);

        //Au démarrage, tout le pipeline de rendu et la palette sont considérés
        //comme non calculés. Ils seront reconstruits à la demande.
        FRenderDirty := True;
        FPaletteDirty := True;
        FInternalSizing := False;
        FSuppressFocusInvalidate := False;

        FPaintCanvas := Nil;
        FBarImages := Nil;
        FMaxItemContentLength := 0;
        FMaxItemMinorSize := 0;
        FMaxItemContentThickness := 0;

        //Aucun item survolé au départ.
        FHotItemIndex := -1;

        //Aucun item pressé au départ.
        FPressedItemIndex := -1;

        //Aucune sélection stable au démarrage.
        FSelectedItemRef := Nil;

        //Initialise explicitement le tableau de rendu vide.
        SetLength(
            FRenderItems,
            0);

        //csOpaque :
        //le contrôle promet de peindre entièrement son fond lui-même,
        //ce qui limite les scintillements.
        ControlStyle := ControlStyle + [csOpaque, csDoubleClicks];

        //Taille initiale raisonnable du contrôle à la création.
        Width := 300;
        Height := 46;

        //Couleur et comportement visuel standard du contrôle.
        Color := clBtnFace;
        ParentColor := False;
        DoubleBuffered := True;

        //Le composant doit pouvoir recevoir le focus clavier
        //pour gérer la navigation par flèches.
        TabStop := True;

        //Le contenu de BarImages influence directement les métriques :
        //- présence ou absence d'un glyph ;
        //- largeur et hauteur réservées au glyph ;
        //- taille finale de chaque item ;
        //- nombre de lignes ou colonnes possibles.
        //
        //On utilise donc le mécanisme VCL standard TChangeLink plutôt qu'un
        //recalcul différé côté fiche utilisatrice.
        FBarImagesChangeLink := TChangeLink.Create;
        FBarImagesChangeLink.OnChange := BarImagesChanged;

        //---------------------------------------------------------------------
        //Valeurs par défaut des propriétés métier / visuelles.
        //---------------------------------------------------------------------

        //Aucun item sélectionné tant que la collection est vide.
        FItemIndex := -1;

        //Par défaut, le composant conserve son comportement historique :
        //une barre d'onglets classique avec sélection unique.
        //
        //Les modes boutons sont préparés dans les types, layouts et palettes,
        //mais ne deviennent actifs que lorsque le rendu correspondant sera
        //branché dans les couches spécialisées.
        FBarMode := nrbmTabs;

        //Par défaut, on démarre en palette custom.
        FPaletteMode := nrtcmCustom;

        //Par défaut, on laisse le composant choisir une stratégie compatible
        //avec l'historique :
        //- palette style  -> rendu plat ;
        //- palette custom -> rendu gradient.
        FBarRenderMode := nrrmAuto;

        //Par défaut, on active le moteur horizontal par zones.
        FLayoutMode := nrblmByZones;

        //Ordre historique par défaut : Start -> Center -> End.
        //
        //Ce choix garantit une compatibilité visuelle complète avec le
        //comportement actuel tant que l'utilisateur ne change pas explicitement
        //BarFlowOrder.
        FFlowOrder := nrtfoNormal;

        FHotZone := nrtpzNone;

        //Par défaut, le réordonnancement par drag est désactivé.
        FItemsReorderMode := nrbrmNone;

        //Par défaut, la barre ne dialogue pas avec les autres barres.
        //Le drag interne reste uniquement piloté par FItemsReorderMode.
        FItemsInterBarMode := nrtbimNone;
        FItemsInterBarGroup := '';

        //Par défaut, toutes les zones acceptent le drag.
        FItemsReorderZones := [nrtzStart, nrtzCenter, nrtzEnd];



        //Position standard : barre en haut.
        FBarPosition := nrtbpTop;

        //Orientation automatique du texte en fonction de la position.
        FTextOrientation := nrttoAuto;

        //Le voyant est placé avant le texte par défaut.
        FSignalPosition := nrtspBefore;

        //Le focus clavier est affiché par défaut.
        FShowFocus := True;

        //L’item sélectionné sera affiché en gras par défaut.
        FSelectedFontStyle := [fsBold];

        //Création de la collection d’items interne.
        FItems := TNoReflowTabBarItems.Create(
            Self,
            Self);

        //Création de la collection des voyants
        FSignals := TNoReflowTabBarSignalDefs.Create(
            Self,
            Self);
        InitDefaultSignals;

        //Important :
        //Le contrôle garde ShowHint actif avec un Hint non vide,
        //mais l’affichage réel des hints est géré manuellement
        //via THintWindow selon l’item survolé.
        ShowHint := True;
        ParentShowHint := False;
        Hint := ' ';

        //Initialise la palette custom interne de référence.
        InitDefaultCustomPalette;

        //---------------------------------------------------------------------
        //Création de l’objet BarAppearance.
        //
        //Cet objet expose les couleurs en mode custom dans l’inspecteur.
        //On le remplit à partir de la palette custom par défaut afin que :
        //- l’état interne
        //- les propriétés publiées
        //soient parfaitement synchronisés dès le départ.
        //---------------------------------------------------------------------
        FAppearance := TNoReflowTabBarAppearance.Create(Self);
        FAppearance.OnChanged := AppearanceChanged;
        FAppearance.BeginUpdate;
        Try
            FAppearance.TabNormalTop := FCustomPalette.TabNormalTop;
            FAppearance.TabNormalBottom := FCustomPalette.TabNormalBottom;
            FAppearance.TabNormalText := FCustomPalette.TabNormalText;
            FAppearance.TabNormalBorder := FCustomPalette.TabNormalBorder;

            FAppearance.TabHotTop := FCustomPalette.TabHotTop;
            FAppearance.TabHotBottom := FCustomPalette.TabHotBottom;
            FAppearance.TabHotText := FCustomPalette.TabHotText;
            FAppearance.TabHotBorder := FCustomPalette.TabHotBorder;

            FAppearance.TabSelectedTop := FCustomPalette.TabSelectedTop;
            FAppearance.TabSelectedBottom := FCustomPalette.TabSelectedBottom;
            FAppearance.TabSelectedText := FCustomPalette.TabSelectedText;
            FAppearance.TabSelectedBorder := FCustomPalette.TabSelectedBorder;

            FAppearance.TabDisabledTop := FCustomPalette.TabDisabledTop;
            FAppearance.TabDisabledBottom := FCustomPalette.TabDisabledBottom;
            FAppearance.TabDisabledText := FCustomPalette.TabDisabledText;
            FAppearance.TabDisabledBorder := FCustomPalette.TabDisabledBorder;

            //Couleurs custom du futur mode bouton.
            //
            //Elles sont recopiées depuis la palette custom interne pour que
            //les valeurs publiées dans l'inspecteur d'objets soient alignées
            //avec le rendu effectif dès la création du composant.
            FAppearance.ButtonNormalTop := FCustomPalette.ButtonNormalTop;
            FAppearance.ButtonNormalBottom := FCustomPalette.ButtonNormalBottom;
            FAppearance.ButtonNormalText := FCustomPalette.ButtonNormalText;
            FAppearance.ButtonNormalBorder := FCustomPalette.ButtonNormalBorder;

            FAppearance.ButtonHotTop := FCustomPalette.ButtonHotTop;
            FAppearance.ButtonHotBottom := FCustomPalette.ButtonHotBottom;
            FAppearance.ButtonHotText := FCustomPalette.ButtonHotText;
            FAppearance.ButtonHotBorder := FCustomPalette.ButtonHotBorder;

            FAppearance.ButtonPressedTop := FCustomPalette.ButtonPressedTop;
            FAppearance.ButtonPressedBottom := FCustomPalette.ButtonPressedBottom;
            FAppearance.ButtonPressedText := FCustomPalette.ButtonPressedText;
            FAppearance.ButtonPressedBorder := FCustomPalette.ButtonPressedBorder;

            FAppearance.ButtonSelectedTop := FCustomPalette.ButtonSelectedTop;
            FAppearance.ButtonSelectedBottom := FCustomPalette.ButtonSelectedBottom;
            FAppearance.ButtonSelectedText := FCustomPalette.ButtonSelectedText;
            FAppearance.ButtonSelectedBorder := FCustomPalette.ButtonSelectedBorder;

            FAppearance.ButtonDisabledTop := FCustomPalette.ButtonDisabledTop;
            FAppearance.ButtonDisabledBottom := FCustomPalette.ButtonDisabledBottom;
            FAppearance.ButtonDisabledText := FCustomPalette.ButtonDisabledText;
            FAppearance.ButtonDisabledBorder := FCustomPalette.ButtonDisabledBorder;

            FAppearance.ButtonLightEdge := FCustomPalette.ButtonLightEdge;
            FAppearance.ButtonShadowEdge := FCustomPalette.ButtonShadowEdge;

            FAppearance.FocusColor := FCustomPalette.FocusColor;
        Finally
            FAppearance.EndUpdate;
        End;

        //---------------------------------------------------------------------
        //Création du layout commun.
        //
        //Ce sous-objet contient les paramètres partagés entre les modes onglets
        //et boutons : marges, espacements internes, signal, glyph, etc.
        //Il conserve volontairement le nom interne FLayout car une grande partie
        //du moteur existant s'appuie déjà sur ce champ pour les données communes.
        //---------------------------------------------------------------------
        FLayout := TNoReflowTabBarLayout.Create(Self);
        FLayout.OnChanged := LayoutChanged;

        //---------------------------------------------------------------------
        //Création du layout spécifique aux onglets.
        //
        //Ce sous-objet contient uniquement les paramètres qui décrivent la forme
        //et le comportement visuel des onglets : recouvrement, slants, rayons,
        //bordure de fermeture.
        //---------------------------------------------------------------------
        FLayoutTabs := TNoReflowTabBarLayoutTabs.Create(Self);
        FLayoutTabs.OnChanged := LayoutChanged;

        //---------------------------------------------------------------------
        //Création du layout spécifique aux boutons.
        //
        //Il est créé dès maintenant pour stabiliser l'API et le streaming DFM,
        //même si le rendu bouton sera branché dans une étape suivante.
        //---------------------------------------------------------------------
        FLayoutButtons := TNoReflowTabBarLayoutButtons.Create(Self);
        FLayoutButtons.OnChanged := LayoutChanged;

        //Initialisation de la structure de layout des zones.
        FZoneLayoutInfo.Init;

        //Création de l'objet de header de zones.
        //Il reste purement décoratif et indépendant de la géométrie
        //interne des items eux-mêmes.
        FZoneHeader := TNoReflowTabBarZoneHeader.Create(Self);
        FZoneHeader.OnChanged := ZoneHeaderChanged;

        //Déclenche le premier layout cohérent.
        //
        //Contrairement aux versions précédentes,
        //on ne force plus Align à partir de FBarPosition.
        ApplyBarPosition;
    Finally
        //À partir d’ici, les sous-objets peuvent notifier normalement.
            FInitializing := False;
    End;
End;

Destructor TNoReflowTabBarCore.Destroy;
Begin
    //-------------------------------------------------------------------------
    //BarImages n'appartient pas au composant.
    //On annule seulement la notification de destruction si une ImageList
    //était encore référencée.
    //-------------------------------------------------------------------------

    If FBarImages <> Nil Then Begin
        FBarImages.RemoveFreeNotification(Self);

        If FBarImagesChangeLink <> Nil Then
            FBarImages.UnRegisterChanges(FBarImagesChangeLink);
    End;

    //Libération des sous-objets internes possédés par le composant.
    FreeAndNil(FBarImagesChangeLink);
    FItems.Free;
    FAppearance.Free;
    FLayout.Free;
    FLayoutTabs.Free;
    FLayoutButtons.Free;
    FZoneHeader.Free;
    FSignals.Free;

    Inherited Destroy;
End;

Procedure TNoReflowTabBarCore.InitDefaultSignals;
Var
    LSig: TNoReflowTabBarSignalDef;
Begin
    If FSignals = Nil Then
        Exit;

    FSignals.BeginUpdate;
    Try
        FSignals.Clear;

        LSig := FSignals.Add;
        LSig.InitBuiltIn(
            nrtSignalGray,
            'Gray',
            RGB(175, 175, 175),
            RGB(122, 122, 122));

        LSig := FSignals.Add;
        LSig.InitBuiltIn(
            nrtSignalGreen,
            'Green',
            RGB(57, 170, 52),
            RGB(63, 121, 60));

        LSig := FSignals.Add;
        LSig.InitBuiltIn(
            nrtSignalOrange,
            'Orange',
            RGB(252, 175, 38),
            RGB(155, 120, 59));

        LSig := FSignals.Add;
        LSig.InitBuiltIn(
            nrtSignalRed,
            'Red',
            RGB(230, 50, 41),
            RGB(146, 77, 74));
    Finally
        FSignals.EndUpdate;
    End;
End;

Procedure TNoReflowTabBarCore.InitDefaultCustomPalette;
Begin
    //-------------------------------------------------------------------------
    //Initialise la palette custom interne par défaut.
    //
    //Cette palette sert de base lors de la création du composant :
    //elle est ensuite recopiée dans FAppearance pour exposer des valeurs
    //éditables dans l’inspecteur d’objets.
    //
    //Le choix des couleurs ci-dessous correspond à l’identité visuelle
    //retenue pour le composant par défaut.
    //-------------------------------------------------------------------------

    FCustomPalette.BarBackground := RGB(
        235,
        235,
        235);

    FCustomPalette.TabNormalTop := RGB(
        201,
        201,
        201);
    FCustomPalette.TabNormalBottom := RGB(
        156,
        156,
        156);
    FCustomPalette.TabNormalText := clBlack;
    FCustomPalette.TabNormalBorder := RGB(
        201,
        201,
        201);

    FCustomPalette.TabHotTop := RGB(
        94,
        117,
        141);
    FCustomPalette.TabHotBottom := RGB(
        78,
        97,
        117);
    FCustomPalette.TabHotText := clWhite;
    FCustomPalette.TabHotBorder := RGB(
        201,
        201,
        201);

    //-------------------------------------------------------------------------
    //Couleurs custom par défaut de l'état pressé côté onglets.
    //
    //Le rendu onglet historique utilise rarement cet état de manière explicite,
    //mais il est préférable de le définir proprement pour éviter un fallback
    //implicite vers Hot.
    //-------------------------------------------------------------------------
    FCustomPalette.TabPressedTop := FCustomPalette.TabHotTop;
    FCustomPalette.TabPressedBottom := FCustomPalette.TabHotBottom;
    FCustomPalette.TabPressedText := FCustomPalette.TabHotText;
    FCustomPalette.TabPressedBorder := FCustomPalette.TabHotBorder;

    FCustomPalette.TabLightEdge := clWhite;
    FCustomPalette.TabShadowEdge := RGB(
        128,
        128,
        128);

    FCustomPalette.TabSelectedTop := RGB(
        235,
        235,
        235);
    FCustomPalette.TabSelectedBottom := RGB(
        235,
        235,
        235);
    FCustomPalette.TabSelectedText := RGB(
        0,
        102,
        204);
    FCustomPalette.TabSelectedBorder := RGB(
        201,
        201,
        201);

    FCustomPalette.TabDisabledTop := RGB(
        235,
        235,
        235);
    FCustomPalette.TabDisabledBottom := RGB(
        235,
        235,
        235);
    FCustomPalette.TabDisabledText := RGB(
        150,
        150,
        150);
    FCustomPalette.TabDisabledBorder := RGB(
        201,
        201,
        201);

    //-------------------------------------------------------------------------
    //Couleurs custom par défaut du mode bouton.
    //
    //Ces valeurs préparent le rendu bouton sans modifier le rendu onglet
    //actuel. Elles sont volontairement cohérentes avec la palette d'onglets,
    //mais séparées pour permettre ensuite une personnalisation indépendante.
    //-------------------------------------------------------------------------

    FCustomPalette.ButtonNormalTop := RGB(
        245,
        245,
        245);
    FCustomPalette.ButtonNormalBottom := RGB(
        220,
        220,
        220);
    FCustomPalette.ButtonNormalText := clBlack;
    FCustomPalette.ButtonNormalBorder := RGB(
        160,
        160,
        160);

    FCustomPalette.ButtonHotTop := RGB(
        235,
        242,
        250);
    FCustomPalette.ButtonHotBottom := RGB(
        205,
        222,
        240);
    FCustomPalette.ButtonHotText := clBlack;
    FCustomPalette.ButtonHotBorder := RGB(
        0,
        102,
        204);

    FCustomPalette.ButtonPressedTop := RGB(
        180,
        200,
        220);
    FCustomPalette.ButtonPressedBottom := RGB(
        215,
        230,
        245);
    FCustomPalette.ButtonPressedText := clBlack;
    FCustomPalette.ButtonPressedBorder := RGB(
        0,
        84,
        168);

    FCustomPalette.ButtonSelectedTop := RGB(
        0,
        122,
        204);
    FCustomPalette.ButtonSelectedBottom := RGB(
        0,
        102,
        184);
    FCustomPalette.ButtonSelectedText := clWhite;
    FCustomPalette.ButtonSelectedBorder := RGB(
        0,
        84,
        168);

    FCustomPalette.ButtonDisabledTop := RGB(
        235,
        235,
        235);
    FCustomPalette.ButtonDisabledBottom := RGB(
        225,
        225,
        225);
    FCustomPalette.ButtonDisabledText := RGB(
        150,
        150,
        150);
    FCustomPalette.ButtonDisabledBorder := RGB(
        190,
        190,
        190);

    FCustomPalette.ButtonLightEdge := clWhite;
    FCustomPalette.ButtonShadowEdge := RGB(
        128,
        128,
        128);

    FCustomPalette.FocusColor := RGB(
        0,
        102,
        204);

    FCustomPalette.ZoneHeaderText := clBtnText;
    FCustomPalette.ZoneHeaderLine := clBtnShadow;
    FCustomPalette.DragInsertMarker := RGB(
        0,
        102,
        204);
End;


//===============================================================================================================================
//TNoReflowTabBar : invalidation générale et pipeline de rendu
//===============================================================================================================================

Procedure TNoReflowTabBarCore.InvalidateRenderInfo;
Begin
    //-------------------------------------------------------------------------
    //Marque la représentation intermédiaire comme périmée.
    //
    //Cela ne déclenche pas immédiatement de recalcul.
    //Le but est justement de différer ce travail au moment où il sera
    //réellement nécessaire, via EnsureRenderInfo.
    //
    //Concrètement, cela invalide :
    //- les métriques calculées
    //- les bounds des items
    //- les polygones de contour
    //-------------------------------------------------------------------------
    FRenderDirty := True;
End;

Procedure TNoReflowTabBarCore.InvalidateItem(AIndex: Integer);
Var
    R: TRect;
Begin
    //-------------------------------------------------------------------------
    //Invalidation fine d’un seul item déjà calculé.
    //
    //Cette routine est utile lorsqu’un changement n’impacte
    //qu’une petite zone :
    //- apparition / disparition du focus
    //- éventuel changement visuel local
    //
    //On évite ainsi un repaint complet de la barre quand ce n’est pas utile.
    //-------------------------------------------------------------------------

    //Index hors plage : rien à faire.
    If (AIndex < 0) Or (AIndex > High(FRenderItems)) Then
        Exit;

    //Un item non visible n’a aucune surface à invalider.
    If Not FRenderItems[AIndex].Visible Then
        Exit;

    //On élargit légèrement la zone pour couvrir confortablement :
    //- les bordures
    //- l’antialiasing GDI+
    //- le rectangle de focus éventuel
    R := FRenderItems[AIndex].Bounds;
    InflateRect(
        R,
        2,
        2);

    InvalidateRect(
        Handle,
        @R,
        False);
End;

Procedure TNoReflowTabBarCore.AppearanceChanged(Sender: TObject);
Begin
    //-------------------------------------------------------------------------
    //Réagit à une modification du sous-objet BarAppearance.
    //
    //Depuis l'extraction de TNoReflowTabBarAppearance dans une unité dédiée,
    //le sous-objet ne notifie plus directement la barre.
    //Il déclenche à la place son callback OnChanged, branché ici.
    //
    //Un changement d'apparence impacte :
    //- la palette active si le mode custom est utilisé,
    //- le rendu des items,
    //- éventuellement la perception visuelle globale de la barre.
    //
    //En revanche, la géométrie pure n'est pas censée changer ici.
    //-------------------------------------------------------------------------
    If Not CanApplySubObjectChanges Then
        Exit;

    InvalidatePalette;
    Invalidate;
End;

Procedure TNoReflowTabBarCore.LayoutChanged(Sender: TObject);
Begin
    //-------------------------------------------------------------------------
    //Réagit à une modification d'un des sous-objets de layout.
    //
    //Les layouts sont maintenant séparés :
    //- FLayout       : paramètres communs à tous les modes ;
    //- FLayoutTabs    : paramètres propres au rendu onglets ;
    //- FLayoutButtons : paramètres propres au rendu boutons.
    //
    //Même si certains changements pourraient théoriquement n'impacter que
    //le dessin, on choisit ici une invalidation complète du layout.
    //
    //Raison :
    //les dimensions finales peuvent dépendre de nombreux paramètres croisés :
    //- espaces internes ;
    //- glyph ;
    //- signal ;
    //- rayons ;
    //- slants ;
    //- futur mode boutons avec dimensions forcées.
    //-------------------------------------------------------------------------
    If Not CanApplySubObjectChanges Then
        Exit;

    InvalidateLayout;
End;

Procedure TNoReflowTabBarCore.ZoneHeaderChanged(Sender: TObject);
Begin
    //-------------------------------------------------------------------------
    //Réagit à une modification du sous-objet ZoneHeader.
    //
    //Le header de zones est un élément décoratif indépendant des items,
    //mais sa présence peut modifier l'encombrement total de la barre.
    //
    //On demande donc une invalidation complète du layout.
    //-------------------------------------------------------------------------
    If Not CanApplySubObjectChanges Then
        Exit;

    InvalidateLayout;
End;

Procedure TNoReflowTabBarCore.HideCustomHint;
Begin
    //Hook volontairement vide au niveau Core.
    //
    //La gestion concrète des hints est implémentée dans
    //TNoReflowTabBarHintSupport. Cette méthode existe ici pour permettre
    //au socle Core d'annuler un hint sans dépendre de la couche spécialisée.
End;

Procedure TNoReflowTabBarCore.ApplyBarPosition;
Begin
    //-------------------------------------------------------------------------
    //Réapplique les conséquences visuelles d’un changement de BarPosition.
    //
    //Cette méthode ne modifie pas Align.
    //Elle relance uniquement le recalcul interne du layout et du rendu.
    //-------------------------------------------------------------------------
    HideCustomHint;
    FHotItemIndex := -1;
    FHotZone := nrtpzNone;
    //ResetTabDragState;
    InvalidateLayout;
End;

Procedure TNoReflowTabBarCore.Notification(
    AComponent: TComponent;
    Operation: TOperation);
Begin
    Inherited Notification(AComponent, Operation);

    //Si l'ImageList associée est détruite ailleurs, le composant ne doit pas
    //conserver un pointeur invalide.
    If (Operation = opRemove) And (AComponent = FBarImages) Then Begin
        If FBarImagesChangeLink <> Nil Then
            FBarImages.UnRegisterChanges(FBarImagesChangeLink);

        FBarImages := Nil;
        InvalidateLayout;
    End;
End;

Procedure TNoReflowTabBarCore.SetLayoutMode(Const Value: TNoReflowTabBarLayoutMode);
Begin
    //-------------------------------------------------------------------------
    //Change le moteur de layout horizontal utilisé pour les barres
    //top/bottom.
    //-------------------------------------------------------------------------
    If FLayoutMode = Value Then
        Exit;

    FLayoutMode := Value;
    InvalidateLayout;
End;

Procedure TNoReflowTabBarCore.SetFlowOrder(Const Value: TNoReflowTabBarFlowOrder);
Begin
    //-------------------------------------------------------------------------
    //Change l'ordre logique présenté au moteur de layout.
    //
    //Important :
    //on ne normalise pas FItems ;
    //on ne modifie pas les ZoneIndex ;
    //on ne touche pas aux transformations géométriques.
    //
    //Le changement influence uniquement la prochaine reconstruction du layout :
    //- ordre de lecture des zones ;
    //- ordre de lecture des items dans les zones ;
    //- priorité de compactage multi-ligne.
    //-------------------------------------------------------------------------

    If FFlowOrder = Value Then
        Exit;

    FFlowOrder := Value;

    InvalidateLayout;
End;


//===============================================================================================================================
//TNoReflowTabBarCore : placement des items dans la barre
//===============================================================================================================================

Procedure TNoReflowTabBarCore.EnsureRenderInfo;
Begin
    //volontairement vide au niveau Core
End;

Function TNoReflowTabBarCore.GetZoneHeaderReservedSize: Integer;
Begin
    Result := 0;
End;

Procedure TNoReflowTabBarCore.RelayoutItems;
Var
    HeaderReserve:     Integer;
    FallbackSecondary: Integer;
    NewWidth:          Integer;
    NewHeight:         Integer;
    SizeChanged:       Boolean;
Begin
    //-------------------------------------------------------------------------
    //Ajuste la taille physique du contrôle à partir de l'encombrement exact
    //communiqué par le moteur de layout.
    //
    //Le contrôle ne mesure plus les RegionPoints après coup :
    //- le layout connaît déjà la place réellement utilisée
    //- les contours polygonaux servent au dessin et au hit-test
    //- l'autosize ne doit pas dépendre d'une marge empirique
    //-------------------------------------------------------------------------

    If csDestroying In ComponentState Then
        Exit;

    If FInitializing Then
        Exit;

    If csLoading In ComponentState Then
        Exit;

    If csReading In ComponentState Then
        Exit;

    If FInternalSizing Then
        Exit;

    EnsureRenderInfo;

    HeaderReserve := GetZoneHeaderReservedSize;

    If HeaderReserve > 0 Then
        FallbackSecondary := HeaderReserve
    Else
        //La marge de première ligne appartient au layout commun,
        //car elle sert autant aux onglets qu'aux boutons.
        FallbackSecondary := FLayout.MarginFirstRow;

    NewWidth := Width;
    NewHeight := Height;

    Case FBarPosition Of
        nrtbpTop, nrtbpBottom: Begin
                If FLayoutUsedHeight > 0 Then
                    NewHeight := FLayoutUsedHeight
                Else
                    NewHeight := FallbackSecondary;
            End;

        nrtbpLeft, nrtbpRight: Begin
                If FLayoutUsedWidth > 0 Then
                    NewWidth := FLayoutUsedWidth
                Else
                    NewWidth := FallbackSecondary;
            End;
    End;

    SizeChanged := (Width <> NewWidth) Or (Height <> NewHeight);

    If SizeChanged Then Begin
        FInternalSizing := True;
        Try
            If Width <> NewWidth Then
                Width := NewWidth;

            If Height <> NewHeight Then
                Height := NewHeight;
        Finally FInternalSizing := False;
        End;

        //La taille cliente a changé :
        //il faut recalculer immédiatement la géométrie finale.
        InvalidateRenderInfo;
        EnsureRenderInfo;
    End;
End;

//===============================================================================================================================
//TNoReflowTabBarCore : helpers généraux d'état et d'orientation
//===============================================================================================================================

Function TNoReflowTabBarCore.CanApplySubObjectChanges: Boolean;
Begin
    //-------------------------------------------------------------------------
    //Indique si les sous-objets persistants du composant
    //(BarAppearance, BarLayout, BarLayoutTabs, BarLayoutButtons et ZoneHeader)
    //peuvent notifier librement leurs changements au contrôle propriétaire.
    //
    //Cette protection évite des recalculs trop précoces pendant les phases
    //sensibles du cycle de vie du composant :
    //- pendant le constructeur, tant que l’objet n’est pas entièrement prêt
    //- pendant le chargement du DFM
    //- pendant la lecture de flux
    //
    //Sans ce garde-fou, un simple setter appelé dans un sous-objet pourrait
    //provoquer :
    //- des invalidations inutiles
    //- des recalculs partiels sur un composant encore incomplet
    //- voire des incohérences de layout pendant le chargement
    //-------------------------------------------------------------------------
    Result := (Not FInitializing) And (Not(csLoading In ComponentState)) And (Not(csReading In ComponentState));
End;





//===============================================================================================================================
//TNoReflowTabBarCore : Gestion des items - déplacement
//===============================================================================================================================

Procedure TNoReflowTabBarCore.SetBarCurrentItemIndex(Const Value: Integer);
Begin
    //-------------------------------------------------------------------------
    //Setter public de l’index sélectionné.
    //
    //Toute la logique réelle de validation et d’application de sélection
    //est centralisée dans ApplyItemIndex afin d’éviter les duplications.
    //-------------------------------------------------------------------------

    ApplyItemIndex(
        Value,
        True);
End;

Function TNoReflowTabBarCore.IndexOfItem(ATab: TNoReflowTabBarItem): Integer;
Begin
    //-------------------------------------------------------------------------
    //Retourne l'index absolu d'un item donné.
    //
    //Comme l'item est un TCollectionItem, son Index donne déjà sa position
    //courante, mais on vérifie d'abord qu'il appartient bien à cette barre.
    //-------------------------------------------------------------------------

    Result := -1;

    If ATab = Nil Then
        Exit;

    If ATab.Collection <> FItems Then
        Exit;

    Result := ATab.Index;
End;

Function TNoReflowTabBarCore.ItemAtPos(Const P: TPoint): Integer;
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Détermine quel item contient le point P.
    //
    //Point important :
    //le test ne se fait pas sur le simple rectangle Bounds,
    //mais sur le polygone réel de l’item via PointInPolygon.
    //
    //Cela permet un hit-test fidèle à la vraie forme visuelle :
    //slants, coins arrondis et recouvrements compris.
    //-------------------------------------------------------------------------

    Result := -1;

    If (FItemIndex >= 0) And (FItemIndex <= High(FRenderItems)) Then Begin
        If FRenderItems[FItemIndex].Visible And (Length(FRenderItems[FItemIndex].RegionPoints) >= 3) And PointInPolygon(P, FRenderItems[FItemIndex].RegionPoints) Then Begin
            Result := FItemIndex;

            Exit;
        End;
    End;

    For I := 0 To High(FRenderItems) Do Begin
        If I = FItemIndex Then
            Continue;

        If Not FRenderItems[I].Visible Then
            Continue;

        If Length(FRenderItems[I].RegionPoints) < 3 Then
            Continue;

        If PointInPolygon(P, FRenderItems[I].RegionPoints) Then Begin
            Result := FRenderItems[I].ItemIndex;

            Exit;
        End;
    End;

End;

Function TNoReflowTabBarCore.ZoneAtPos(
    Const P: TPoint;
    Out APinZone: TNoReflowTabBarPinZone): Boolean;
Var
    LCanonicalPoint: TPoint;
Begin
    //-------------------------------------------------------------------------
    //Retourne la zone logique située sous un point client.
    //
    //La méthode travaille sur les rectangles canoniques du layout de zones.
    //Le point reçu est donc transformé depuis le repère réel du contrôle vers
    //le repère canonique utilisé par TNoReflowTabBarZoneLayoutEngine.
    //
    //nrtpzNone signifie ici "aucune zone trouvée".
    //-------------------------------------------------------------------------

    Result := False;
    APinZone := nrtpzNone;

    If FLayoutMode <> nrblmByZones Then
        Exit;

    EnsureRenderInfo;

    LCanonicalPoint := TNoReflowTabBarZoneLayoutEngine.TransformActualPointToCanonical(
        P,
        GetZoneFlowOrientation,
        FBarPosition,
        ClientWidth,
        ClientHeight);

    If FZoneLayoutInfo.StartZone.HasZone And PtInRect(FZoneLayoutInfo.StartZone.OuterCanonicalRect, LCanonicalPoint) Then Begin
        APinZone := nrtpzStart;
        Result := True;
        Exit;
    End;

    If FZoneLayoutInfo.CenterZone.HasZone And PtInRect(FZoneLayoutInfo.CenterZone.OuterCanonicalRect, LCanonicalPoint) Then Begin
        APinZone := nrtpzCenter;
        Result := True;
        Exit;
    End;

    If FZoneLayoutInfo.EndZone.HasZone And PtInRect(FZoneLayoutInfo.EndZone.OuterCanonicalRect, LCanonicalPoint) Then Begin
        APinZone := nrtpzEnd;
        Result := True;
        Exit;
    End;
End;

Procedure TNoReflowTabBarCore.DoItemMouseEnter(
    AItemIndex: Integer;
    ATab: TNoReflowTabBarItem;
    Shift: TShiftState;
    X, Y: Integer);
Begin
    If Assigned(FOnItemMouseEnter) Then
        FOnItemMouseEnter(
            Self,
            AItemIndex,
            ATab,
            Shift,
            X,
            Y);
End;

Procedure TNoReflowTabBarCore.DoItemMouseLeave(
    AItemIndex: Integer;
    ATab: TNoReflowTabBarItem;
    Shift: TShiftState;
    X, Y: Integer);
Begin
    If Assigned(FOnItemMouseLeave) Then
        FOnItemMouseLeave(
            Self,
            AItemIndex,
            ATab,
            Shift,
            X,
            Y);
End;

Procedure TNoReflowTabBarCore.DoZoneMouseEnter(
    APinZone: TNoReflowTabBarPinZone;
    Shift: TShiftState;
    X, Y: Integer);
Begin
    //On ne déclenche pas d'événement pour "aucune zone".
    If APinZone = nrtpzNone Then
        Exit;

    If Assigned(FOnZoneMouseEnter) Then
        FOnZoneMouseEnter(
            Self,
            APinZone,
            Shift,
            X,
            Y);
End;

Procedure TNoReflowTabBarCore.DoZoneMouseLeave(
    APinZone: TNoReflowTabBarPinZone;
    Shift: TShiftState;
    X, Y: Integer);
Begin
    //On ne déclenche pas d'événement pour "aucune zone".
    If APinZone = nrtpzNone Then
        Exit;

    If Assigned(FOnZoneMouseLeave) Then
        FOnZoneMouseLeave(
            Self,
            APinZone,
            Shift,
            X,
            Y);
End;

Procedure TNoReflowTabBarCore.ApplyItemIndex(
    ANewIndex: Integer;
    ARaiseEvent: Boolean);
Var
    NeedChange: Boolean;
    Allow:      Boolean;
    OldIndex:   Integer;
    OldTab:     TNoReflowTabBarItem;
    NewTab:     TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Applique une nouvelle sélection après normalisation et validation.
    //
    //Cette méthode est le point central de changement de sélection.
    //Elle gère :
    //- la normalisation de l’index
    //- le refus d’un item non sélectionnable
    //- la mise à jour de la référence stable par objet
    //- l’invalidation du layout
    //- le déclenchement conditionnel des événements
    //
    //Les événements exposent directement les objets métier
    //plutôt que des index bruts.
    //-------------------------------------------------------------------------

    If ANewIndex < -1 Then
        ANewIndex := -1;

    If ANewIndex >= FItems.Count Then
        ANewIndex := FItems.Count - 1;

    //En mode boutons à sélection unique, on n'autorise pas la désélection
    //complète tant qu'il existe au moins un item sélectionnable.
    //
    //Cela garantit la règle officielle du mode nrbmSelectButtons :
    //une sélection unique persistante, sauf impossibilité matérielle
    //lorsqu'aucun item sélectionnable n'existe.
    If (FBarMode = nrbmSelectButtons) And (ANewIndex < 0) Then
        ANewIndex := FindNextSelectableItem(0);

    If (ANewIndex >= 0) And (ANewIndex < FItems.Count) Then
        If Not IsItemSelectable(ANewIndex) Then
            Exit;

    OldIndex := FItemIndex;

    If (OldIndex >= 0) And (OldIndex < FItems.Count) Then
        OldTab := FItems[OldIndex]
    Else
        OldTab := Nil;

    If (ANewIndex >= 0) And (ANewIndex < FItems.Count) Then
        NewTab := FItems[ANewIndex]
    Else
        NewTab := Nil;

    NeedChange := OldTab <> NewTab;

    If NeedChange And ARaiseEvent And Assigned(FOnChanging) Then Begin
        Allow := True;
        FOnChanging(
            Self,
            OldTab,
            NewTab,
            Allow);
        If Not Allow Then
            Exit;
    End;

    FItemIndex := ANewIndex;
    FSelectedItemRef := NewTab;

    //En mode onglets et en mode boutons à sélection unique, Checked reflète
    //l'item actif.
    //
    //Cela permet d'avoir un état persistant cohérent au niveau des items,
    //sans transformer Checked en source de vérité pour les modes exclusifs.
    SyncCheckedStateFromCurrentIndex;

    //La sélection influence :
    //- l’état visuel des items
    //- potentiellement les dimensions si la police sélectionnée diffère
    //On force donc un recalcul complet.
    InvalidateLayout;

    If NeedChange And ARaiseEvent And Assigned(FOnChange) Then
        FOnChange(
            Self,
            OldTab,
            NewTab);
End;

Function TNoReflowTabBarCore.IsItemSelectable(AIndex: Integer): Boolean;
Begin
    //-------------------------------------------------------------------------
    //Détermine si un item peut réellement devenir actif.
    //
    //Un item sélectionnable doit :
    //- exister dans la collection
    //- être visible
    //- être activé
    //-------------------------------------------------------------------------

    Result := (AIndex >= 0) And (AIndex < FItems.Count) And FItems[AIndex].Visible And FItems[AIndex].Enabled;
End;

Function TNoReflowTabBarCore.FindNextSelectableItem(AStartIndex: Integer): Integer;
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Recherche le prochain item sélectionnable en partant d’un index donné.
    //
    //La recherche est linéaire et inclusive de AStartIndex.
    //Retour :
    //- index trouvé
    //- ou -1 si aucun item admissible n’existe après ce point
    //-------------------------------------------------------------------------

    Result := -1;

    For I := AStartIndex To FItems.Count - 1 Do
        If IsItemSelectable(I) Then Begin
            Result := I;
            Exit;
        End;
End;

Function TNoReflowTabBarCore.FindPreviousSelectableTab(AStartIndex: Integer): Integer;
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Recherche le précédent item sélectionnable en partant d’un index donné.
    //
    //La recherche est linéaire et inclusive de AStartIndex.
    //Retour :
    //- index trouvé
    //- ou -1 si aucun item admissible n’existe avant ce point
    //-------------------------------------------------------------------------

    Result := -1;

    For I := AStartIndex Downto 0 Do
        If IsItemSelectable(I) Then Begin
            Result := I;
            Exit;
        End;
End;

Function TNoReflowTabBarCore.GetBarItemUserId: Integer;
Var
    LSelectedItem: TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Retourne le ItemUserId de l'item sélectionné.
    //-------------------------------------------------------------------------
    LSelectedItem := GetBarCurrentItem;
    If LSelectedItem <> Nil Then
        Result := LSelectedItem.UserId
    Else
        Result := 0;
End;

Function TNoReflowTabBarCore.GetBarCurrentItem: TNoReflowTabBarItem;
Var
    LIndex: Integer;
Begin
    //-------------------------------------------------------------------------
    //Retourne l’item actuellement sélectionné.
    //
    //La priorité est donnée à la référence stable mémorisée par objet.
    //Si elle est encore valide dans FItems, elle représente la vraie sélection.
    //
    //En repli, on utilise FItemIndex si celui-ci reste dans les bornes.
    //-------------------------------------------------------------------------

    Result := Nil;

    If FSelectedItemRef <> Nil Then Begin
        LIndex := IndexOfItem(FSelectedItemRef);
        If LIndex >= 0 Then Begin
            Result := FSelectedItemRef;
            Exit;
        End;
    End;

    If (FItemIndex >= 0) And (FItemIndex < FItems.Count) Then
        Result := FItems[FItemIndex];
End;

Function TNoReflowTabBarCore.CompareItemsForZoneOrder(ALeft, ARight: TNoReflowTabBarItem): Integer;
Begin
    //-------------------------------------------------------------------------
    //Compare deux onglets appartenant déjà à la même zone.
    //
    //Ordre retenu :
    //1) ZoneIndex mémorisé
    //2) Index physique courant comme tie-breaker stable
    //-------------------------------------------------------------------------

    Result := ALeft.ZoneIndex - ARight.ZoneIndex;

    If Result = 0 Then
        Result := ALeft.Index - ARight.Index;
End;

Procedure TNoReflowTabBarCore.RebuildStoredZoneIndexes;
Var
    I:            Integer;
    LStartIndex:  Integer;
    LCenterIndex: Integer;
    LEndIndex:    Integer;
Begin
    //-------------------------------------------------------------------------
    //Reconstruit les ZoneIndex mémorisés à partir de l'ordre physique
    //courant de FItems.
    //
    //Après toute normalisation ou déplacement effectif, cette méthode garantit
    //que les positions mémorisées redeviennent compactes et cohérentes :
    //- Start : 0..N-1
    //- Center  : 0..N-1
    //- End   : 0..N-1
    //-------------------------------------------------------------------------

    LStartIndex := 0;
    LCenterIndex := 0;
    LEndIndex := 0;

    FItems.BeginUpdate;
    Try
        For I := 0 To FItems.Count - 1 Do Begin
            Case FItems[I].PinZone Of
                nrtpzStart: Begin
                        FItems[I].SetZoneIndexDirect(LStartIndex);
                        Inc(LStartIndex);
                    End;

                nrtpzCenter: Begin
                        FItems[I].SetZoneIndexDirect(LCenterIndex);
                        Inc(LCenterIndex);
                    End;

                nrtpzEnd: Begin
                        FItems[I].SetZoneIndexDirect(LEndIndex);
                        Inc(LEndIndex);
                    End;
            End;
        End;
    Finally
        FItems.EndUpdate;
    End;
End;

Procedure TNoReflowTabBarCore.MoveCollectionItem(
    AFromIndex: Integer;
    AToIndex: Integer);
Var
    LItem: TNoReflowTabBarItem;
Begin
    If AFromIndex = AToIndex Then
        Exit;

    If (AFromIndex < 0) Or (AFromIndex >= FItems.Count) Then
        Exit;

    If AToIndex < 0 Then
        AToIndex := 0;

    If AToIndex >= FItems.Count Then
        AToIndex := FItems.Count - 1;

    If AFromIndex = AToIndex Then
        Exit;

    LItem := FItems[AFromIndex];
    LItem.Index := AToIndex;
End;

Function TNoReflowTabBarCore.GetAbsoluteIndexForZonePosition(
    APinZone: TNoReflowTabBarPinZone;
    AZoneIndex: Integer): Integer;
Var
    StartCount:  Integer;
    CenterCount: Integer;
    EndCount:    Integer;
    ZoneIndex:   Integer;
Begin
    //-------------------------------------------------------------------------
    //Convertit un index relatif à une zone en index absolu dans FItems.
    //
    //Structure logique de la collection :
    //- [Start]
    //- [Center]
    //- [End]
    //
    //L'index de zone est clampé dans l'intervalle valide d'insertion,
    //c'est-à-dire entre 0 et CountZone.
    //-------------------------------------------------------------------------

    StartCount := GetItemsCountInZoneInternal(nrtpzStart);
    CenterCount := GetItemsCountInZoneInternal(nrtpzCenter);
    EndCount := GetItemsCountInZoneInternal(nrtpzEnd);

    ZoneIndex := AZoneIndex;
    If ZoneIndex < 0 Then
        ZoneIndex := 0;

    Case APinZone Of
        nrtpzStart: Begin
                If ZoneIndex > StartCount Then
                    ZoneIndex := StartCount;

                Result := ZoneIndex;
            End;

        nrtpzCenter: Begin
                If ZoneIndex > CenterCount Then
                    ZoneIndex := CenterCount;

                Result := StartCount + ZoneIndex;
            End;

        nrtpzEnd: Begin
                If ZoneIndex > EndCount Then
                    ZoneIndex := EndCount;

                Result := StartCount + CenterCount + ZoneIndex;
            End;
    Else Begin
            Result := FItems.Count;
        End;
    End;
End;

//===============================================================================================================================
//TNoReflowTabBarCore : créations / suppression des items
//===============================================================================================================================

Function TNoReflowTabBarCore.AddItem(
    Const ACaption: String;
    ASignalCode: Integer = 0;
    AItemUserId: Integer = 0;
    AEnabled: Boolean = True): TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Ajoute un nouvel item standard dans la zone centrale.
    //
    //Cette méthode constitue l'alias de compatibilité du composant.
    //Pour tout nouveau code, les méthodes explicites :
    //- AddStartItem
    //- AddCenterItem
    //- AddEndItem
    //sont préférables car elles rendent l'intention plus claire.
    //-------------------------------------------------------------------------

    Result := AddCenterItem(
        ACaption,
        ASignalCode,
        AItemUserId,
        AEnabled);
End;

Function TNoReflowTabBarCore.InsertItemInZone(
    APinZone: TNoReflowTabBarPinZone;
    AZoneIndex: Integer;
    Const ACaption: String;
    ASignalCode: Integer = 0;
    AItemUserId: Integer = 0;
    AEnabled: Boolean = True): TNoReflowTabBarItem;
Var
    InsertIndex: Integer;
    ZoneIndex:   Integer;
Begin
    //-------------------------------------------------------------------------
    //Insère un nouvel item à une position donnée dans une zone donnée.
    //
    //Important :
    //ici, l'index absolu est déjà calculé correctement avant insertion.
    //Il ne faut donc surtout pas repasser ensuite par la propriété PinZone,
    //car son setter déclenche une logique de déplacement supplémentaire.
    //
    //Pour un item nouvellement créé, on affecte donc directement sa position
    //logique de zone sans passer par les setters publics.
    //-------------------------------------------------------------------------

    InsertIndex := GetAbsoluteIndexForZonePosition(
        APinZone,
        AZoneIndex);
    ZoneIndex := AZoneIndex;
    If ZoneIndex < 0 Then
        ZoneIndex := 0;

    FItems.BeginUpdate;
    Try
        Result := FItems.Insert(InsertIndex);

        //Affectation directe de la zone et de l'index dans la zone :
        //l'item est déjà inséré au bon endroit dans la collection.
        Result.SetZonePlacementDirect(
            APinZone,
            ZoneIndex);

        Result.Caption := ACaption;
        Result.SignalCode := ASignalCode;
        Result.UserId := AItemUserId;
        Result.Visible := True;
        Result.Enabled := AEnabled;
    Finally
        FItems.EndUpdate;
    End;
End;

Function TNoReflowTabBarCore.InsertStartItem(
    AZoneIndex: Integer;
    Const ACaption: String;
    ASignalCode: Integer = 0;
    AItemUserId: Integer = 0;
    AEnabled: Boolean = True): TNoReflowTabBarItem;
Begin
    Result := InsertItemInZone(
        nrtpzStart,
        AZoneIndex,
        ACaption,
        ASignalCode,
        AItemUserId,
        AEnabled);
End;

Function TNoReflowTabBarCore.InsertCenterItem(
    AZoneIndex: Integer;
    Const ACaption: String;
    ASignalCode: Integer = 0;
    AItemUserId: Integer = 0;
    AEnabled: Boolean = True): TNoReflowTabBarItem;
Begin
    Result := InsertItemInZone(
        nrtpzCenter,
        AZoneIndex,
        ACaption,
        ASignalCode,
        AItemUserId,
        AEnabled);
End;

Function TNoReflowTabBarCore.InsertEndItem(
    AZoneIndex: Integer;
    Const ACaption: String;
    ASignalCode: Integer = 0;
    AItemUserId: Integer = 0;
    AEnabled: Boolean = True): TNoReflowTabBarItem;
Begin
    Result := InsertItemInZone(
        nrtpzEnd,
        AZoneIndex,
        ACaption,
        ASignalCode,
        AItemUserId,
        AEnabled);
End;

Function TNoReflowTabBarCore.AddStartItem(
    Const ACaption: String;
    ASignalCode: Integer = 0;
    AItemUserId: Integer = 0;
    AEnabled: Boolean = True): TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Ajoute un item en fin de zone Start.
    //-------------------------------------------------------------------------

    Result := InsertStartItem(
        GetItemsCountInZoneInternal(nrtpzStart),
        ACaption,
        ASignalCode,
        AItemUserId,
        AEnabled);
End;

Function TNoReflowTabBarCore.AddCenterItem(
    Const ACaption: String;
    ASignalCode: Integer = 0;
    AItemUserId: Integer = 0;
    AEnabled: Boolean = True): TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Ajoute un item en fin de zone centrale.
    //-------------------------------------------------------------------------

    Result := InsertCenterItem(
        GetItemsCountInZoneInternal(nrtpzCenter),
        ACaption,
        ASignalCode,
        AItemUserId,
        AEnabled);
End;

Function TNoReflowTabBarCore.AddEndItem(
    Const ACaption: String;
    ASignalCode: Integer = 0;
    AItemUserId: Integer = 0;
    AEnabled: Boolean = True): TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Ajoute un item en fin de zone End.
    //-------------------------------------------------------------------------

    Result := InsertEndItem(
        GetItemsCountInZoneInternal(nrtpzEnd),
        ACaption,
        ASignalCode,
        AItemUserId,
        AEnabled);
End;

Procedure TNoReflowTabBarCore.ClearItems;
Begin
    //-------------------------------------------------------------------------
    //Supprime tous les items de la barre.
    //
    //L’opération est groupée pour éviter une cascade de recalculs
    //pendant la suppression unitaire des items.
    //-------------------------------------------------------------------------

    FSelectedItemRef := Nil;

    FItems.BeginUpdate;
    Try FItems.Clear;
    Finally
        FItems.EndUpdate;
    End;
End;

Procedure TNoReflowTabBarCore.ClearStartItems;
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Supprime tous les items appartenant à la zone de début.
    //
    //Le parcours se fait à rebours pour permettre la suppression
    //directe dans la collection sans perturber les indices restants.
    //-------------------------------------------------------------------------

    FItems.BeginUpdate;
    Try
        For I := FItems.Count - 1 Downto 0 Do
            If FItems[I].PinZone = nrtpzStart Then
                FItems[I].Free;
    Finally
        FItems.EndUpdate;
    End;
End;

Procedure TNoReflowTabBarCore.ClearCenterItems;
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Supprime tous les items de la zone centrale.
    //
    //Cette méthode sera particulièrement utile dans FcFiches2
    //pour conserver les items fixes de début et de fin,
    //tout en régénérant uniquement les items métier centraux.
    //-------------------------------------------------------------------------

    FItems.BeginUpdate;
    Try
        For I := FItems.Count - 1 Downto 0 Do
            If FItems[I].PinZone = nrtpzCenter Then
                FItems[I].Free;
    Finally
        FItems.EndUpdate;
    End;
End;

Procedure TNoReflowTabBarCore.ClearEndItems;
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Supprime tous les items appartenant à la zone de fin.
    //-------------------------------------------------------------------------

    FItems.BeginUpdate;
    Try
        For I := FItems.Count - 1 Downto 0 Do
            If FItems[I].PinZone = nrtpzEnd Then
                FItems[I].Free;
    Finally
        FItems.EndUpdate;
    End;
End;

Function TNoReflowTabBarCore.GetZoneFlowOrientation: TNoReflowTabBarZoneFlowOrientation;
Begin
    //-------------------------------------------------------------------------
    //Repli défensif du Core.
    //
    //La vraie logique est redéfinie dans NoReflowTabBar_LayoutSupport, où
    //l'orientation est déduite de BarPosition.
    //
    //On retourne néanmoins une valeur stable ici afin d'éviter toute fonction
    //sans résultat si cette méthode est appelée depuis le socle de base.
    //-------------------------------------------------------------------------
    Result := nrtzfoHorizontal;
End;

Function TNoReflowTabBarCore.GetItemZoneIndex(AIndex: Integer): Integer;
Var
    I:     Integer;
    LZone: TNoReflowTabBarPinZone;
Begin
    //-------------------------------------------------------------------------
    //Retourne l'index relatif de zone d'un item à partir de son index absolu.
    //
    //Exemple :
    //- si l'item absolu 5 est le 2e item de sa zone, la fonction renvoie 1
    //-------------------------------------------------------------------------

    Result := -1;

    If (AIndex < 0) Or (AIndex >= FItems.Count) Then
        Exit;

    LZone := FItems[AIndex].PinZone;
    Result := 0;

    For I := 0 To AIndex - 1 Do
        If FItems[I].PinZone = LZone Then
            Inc(Result);
End;

Function TNoReflowTabBarCore.GetAbsoluteIndexFromZoneIndex(
    APinZone: TNoReflowTabBarPinZone;
    AZoneIndex: Integer): Integer;
Begin
    //-------------------------------------------------------------------------
    //Convertit un index relatif de zone en index absolu dans FItems.
    //
    //Cette méthode remplace conceptuellement l'ancien raisonnement purement
    //absolu par un adressage métier :
    //- zone Start
    //- zone centrale
    //- zone End
    //-------------------------------------------------------------------------

    Result := GetAbsoluteIndexForZonePosition(
        APinZone,
        AZoneIndex);
End;

Procedure TNoReflowTabBarCore.SelectItemInZone(
    APinZone: TNoReflowTabBarPinZone;
    AZoneIndex: Integer);
Var
    LAbsIndex: Integer;
Begin
    //-------------------------------------------------------------------------
    //Sélectionne un item à partir de son index relatif dans une zone.
    //
    //Si l'item ciblé n'est pas sélectionnable, la sélection n'est pas modifiée.
    //-------------------------------------------------------------------------

    LAbsIndex := GetAbsoluteIndexFromZoneIndex(
        APinZone,
        AZoneIndex);

    If Not IsItemSelectable(LAbsIndex) Then
        Exit;

    SetBarCurrentItemIndex(LAbsIndex);
End;

Procedure TNoReflowTabBarCore.SelectNext;
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Sélectionne le prochain item sélectionnable après l’item courant.
    //
    //Aucun bouclage circulaire n’est effectué :
    //si aucun item valide n’existe après, la sélection ne change pas.
    //-------------------------------------------------------------------------

    If FItems.Count = 0 Then
        Exit;

    I := FindNextSelectableItem(FItemIndex + 1);
    If I >= 0 Then
        SetBarCurrentItemIndex(I);
End;

Procedure TNoReflowTabBarCore.SelectPrevious;
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Sélectionne l’item sélectionnable précédent avant l’item courant.
    //
    //Aucun bouclage circulaire n’est effectué :
    //si aucun item valide n’existe avant, la sélection ne change pas.
    //-------------------------------------------------------------------------

    If FItems.Count = 0 Then
        Exit;

    I := FindPreviousSelectableTab(FItemIndex - 1);
    If I >= 0 Then
        SetBarCurrentItemIndex(I);
End;

Function TNoReflowTabBarCore.GetItemByKey(AItemKey: Integer): TNoReflowTabBarItem;
Var
    Index: Integer;
Begin
    Result := Nil;

    Index := IndexOfItemKey(AItemKey);

    If Index >= 0 Then
        Result := FItems[Index];
End;

Function TNoReflowTabBarCore.IndexOfItemKey(AItemKey: Integer): Integer;
Var
    I:    Integer;
    Item: TNoReflowTabBarItem;
Begin
    Result := -1;

    If AItemKey <= 0 Then
        Exit;

    For I := 0 To FItems.Count - 1 Do Begin
        Item := FItems[I];

        If Item = Nil Then
            Continue;

        If Item.ItemKey = AItemKey Then Begin
            Result := I;
            Exit;
        End;
    End;
End;

Function TNoReflowTabBarCore.SelectItem(AItem: TNoReflowTabBarItem): Boolean;
begin
    Result := SelectItemByKey(AItem.ItemKey);
end;

Function TNoReflowTabBarCore.SelectItemByKey(AItemKey: Integer): Boolean;
Var
    Index: Integer;
Begin
    Result := False;

    Index := IndexOfItemKey(AItemKey);

    If Index < 0 Then
        Exit;

    If Not IsItemSelectable(Index) Then
        Exit;

    SetBarCurrentItemIndex(Index);
    Result := True;
End;

Function TNoReflowTabBarCore.IndexOfItemUserId(AItemUserId: Integer): Integer;
Var
    I: Integer;
Begin
    //Retourne l'index du premier item portant l'identifiant utilisateur demandé.
    //
    //Important : ItemUserId n'est pas imposé unique par le composant.
    //Si plusieurs items ont le même ItemUserId, cette méthode retourne
    //l'index du premier dans l'ordre courant de la collection.

    Result := -1;

    For I := 0 To FItems.Count - 1 Do
        If FItems[I].UserId = AItemUserId Then Begin
            Result := I;
            Exit;
        End;
End;

Procedure TNoReflowTabBarCore.MoveItemInZone(
    ATab: TNoReflowTabBarItem;
    ANewZoneIndex: Integer);
Var
    LZoneItems:    TList<TNoReflowTabBarItem>;
    I:             Integer;
    LOldZoneIndex: Integer;
    LNewZoneIndex: Integer;
Begin
    //-------------------------------------------------------------------------
    //Déplace un item à une nouvelle position dans sa zone logique actuelle.
    //
    //La source de vérité est :
    //- PinZone
    //- ZoneIndex
    //
    //Il ne suffit pas de modifier uniquement ZoneIndex de l'item déplacé,
    //car cela créerait facilement des doublons d'index logiques dans la zone.
    //
    //La bonne stratégie est donc :
    //1) reconstruire la liste complète des items de la zone
    //2) retirer l'item déplacé de sa position actuelle
    //3) le réinsérer à la nouvelle position logique demandée
    //4) réattribuer des ZoneIndex compacts à toute la zone
    //5) normaliser ensuite l'ordre physique de FItems
    //-------------------------------------------------------------------------

    If ATab = Nil Then
        Exit;

    If ATab.Collection <> FItems Then
        Exit;

    LZoneItems := TList<TNoReflowTabBarItem>.Create;
    Try
        //Construit la liste ordonnée actuelle des items de la zone.
        For I := 0 To FItems.Count - 1 Do
            If FItems[I].PinZone = ATab.PinZone Then
                LZoneItems.Add(FItems[I]);

        If LZoneItems.Count <= 1 Then
            Exit;

        LOldZoneIndex := LZoneItems.IndexOf(ATab);
        If LOldZoneIndex < 0 Then
            Exit;

        LNewZoneIndex := ANewZoneIndex;

        If LNewZoneIndex < 0 Then
            LNewZoneIndex := 0;

        If LNewZoneIndex > LZoneItems.Count - 1 Then
            LNewZoneIndex := LZoneItems.Count - 1;

        If LOldZoneIndex = LNewZoneIndex Then
            Exit;

        //Réorganise l'ordre logique dans la liste temporaire.
        LZoneItems.Delete(LOldZoneIndex);
        LZoneItems.Insert(
            LNewZoneIndex,
            ATab);

        FItems.BeginUpdate;
        Try
            //Réattribue des index logiques compacts à toute la zone.
            For I := 0 To LZoneItems.Count - 1 Do
                LZoneItems[I].SetZoneIndexDirect(I);

            //Projette ensuite cet ordre logique dans l'ordre physique réel.
            NormalizeItemsOrderByZone;
        Finally
            FItems.EndUpdate;
        End;

        ItemsChanged;
    Finally
        LZoneItems.Free;
    End;
End;

Procedure TNoReflowTabBarCore.MoveItemPriorInZone(ATab: TNoReflowTabBarItem);
Begin
    //-------------------------------------------------------------------------
    //Déplace l'item d'un cran vers le début de sa zone.
    //-------------------------------------------------------------------------

    If ATab = Nil Then
        Exit;

    MoveItemInZone(
        ATab,
        ATab.ZoneIndex - 1);
End;

Procedure TNoReflowTabBarCore.MoveItemNextInZone(ATab: TNoReflowTabBarItem);
Begin
    //-------------------------------------------------------------------------
    //Déplace l'item d'un cran vers la fin de sa zone.
    //-------------------------------------------------------------------------

    If ATab = Nil Then
        Exit;

    MoveItemInZone(
        ATab,
        ATab.ZoneIndex + 1);
End;

Procedure TNoReflowTabBarCore.MoveSelectedItemPriorInZone;
Begin
    MoveItemPriorInZone(GetBarCurrentItem);
End;

Procedure TNoReflowTabBarCore.MoveSelectedItemNextInZone;
Begin
    MoveItemNextInZone(GetBarCurrentItem);
End;

Function TNoReflowTabBarCore.SelectItemByUserId(AItemUserId: Integer): Boolean;
Var
    Idx: Integer;
Begin
    //-------------------------------------------------------------------------
    //Sélectionne le premier item correspondant à un identifiant métier.
    //
    //La sélection n’est appliquée que si :
    //- un item a été trouvé
    //- cet item est réellement sélectionnable
    //-------------------------------------------------------------------------

    Result := False;

    Idx := IndexOfItemUserId(AItemUserId);

    If Idx < 0 Then
        Exit;

    If Not IsItemSelectable(Idx) Then
        Exit;

    SetBarCurrentItemIndex(Idx);
    Result := True;
End;

Function TNoReflowTabBarCore.GetItemByUserId(AItemUserId: Integer): TNoReflowTabBarItem;
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Retourne le premier item portant l'identifiant utilisateur demandé.
    //
    //Important : ItemUserId n'est pas imposé unique par le composant.
    //Si plusieurs items ont le même ItemUserId, cette méthode retourne le premier.
    //Si aucun item ne correspond, elle retourne Nil.
    //-------------------------------------------------------------------------

    Result := Nil;

    For I := 0 To FItems.Count - 1 Do
        If FItems[I].UserId = AItemUserId Then Begin
            Result := FItems[I];
            Exit;
        End;
End;

Function TNoReflowTabBarCore.IsItemVisible(AItemUserId: Integer): Boolean;
Var
    Item: TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Indique si le premier item trouvé pour ce ItemUserId est visible.
    //
    //Si aucun item ne correspond, le résultat est False.
    //-------------------------------------------------------------------------

    Item := GetItemByUserId(AItemUserId);
    Result := Assigned(Item) And Item.Visible;
End;

Procedure TNoReflowTabBarCore.SetItemVisible(
    AItemUserId: Integer;
    AVisible: Boolean);
Var
    Item: TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Modifie la visibilité du premier item trouvé pour ce ItemUserId.
    //
    //Cette méthode agit via la propriété Visible de l’item métier,
    //ce qui laisse à TNoReflowTabBarItem / TNoReflowTabBarItems la responsabilité
    //de déclencher la cascade normale de mise à jour.
    //-------------------------------------------------------------------------

    Item := GetItemByUserId(AItemUserId);
    If Item = Nil Then
        Exit;

    If Item.Visible = AVisible Then
        Exit;

    //Le setter de TNoReflowTabBarItem déclenchera lui-même la cascade de mise à jour.
    Item.Visible := AVisible;
End;


//===============================================================================================================================
//TNoReflowTabBarCore : Modification des états
//===============================================================================================================================

Procedure TNoReflowTabBarCore.SetBarMode(Const Value: TNoReflowTabBarMode);
Begin
    //-------------------------------------------------------------------------
    //Change le mode fonctionnel global de la barre.
    //
    //Ce mode est volontairement plus haut niveau qu'un simple choix de rendu :
    //il décrit le comportement attendu par l'utilisateur du composant.
    //
    //Modes prévus :
    //- nrbmTabs :
    //comportement historique de barre d'onglets, avec un seul onglet actif ;
    //
    //- nrbmPushButtons :
    //boutons d'action sans sélection persistante automatique ;
    //
    //- nrbmSelectButtons :
    //boutons avec sélection unique, proches d'une barre de navigation ;
    //
    //- nrbmCheckButtons :
    //boutons cochables indépendants, utiles pour des filtres ou options.
    //
    //-------------------------------------------------------------------------

    If FBarMode = Value Then
        Exit;

    FBarMode := Value;

    //Un changement de mode annule l'état pressé transitoire.
    FPressedItemIndex := -1;

    //Important :
    //le changement de mode doit remettre l'état courant dans une situation
    //cohérente avec la sémantique du nouveau mode.
    //
    //nrbmTabs / nrbmSelectButtons :
    //- il existe une sélection exclusive ;
    //- BarCurrentItemIndex représente l'item sélectionné ;
    //- Checked doit être synchronisé avec cet item.
    //
    //nrbmPushButtons / nrbmCheckButtons :
    //- il n'existe pas de sélection automatique au changement de mode ;
    //- BarCurrentItemIndex représente seulement le dernier bouton cliqué / activé ;
    //- au moment du changement de mode, aucun bouton n'a encore été activé
    //dans ce nouveau mode.
    //
    //On remet donc FItemIndex à -1 pour éviter de conserver une ancienne
    //sélection issue du mode onglets.
    Case FBarMode Of
        nrbmTabs, nrbmSelectButtons: Begin
                //En mode exclusif, l'index courant doit pointer vers un item sélectionnable.
                //Si l'ancien index n'est plus valide ou vaut -1, on sélectionne le premier
                //item sélectionnable disponible.
                If Not IsItemSelectable(FItemIndex) Then
                    FItemIndex := FindNextSelectableItem(0);

                If IsItemSelectable(FItemIndex) Then
                    FSelectedItemRef := FItems[FItemIndex]
                Else
                    FSelectedItemRef := Nil;

                SyncCheckedStateFromCurrentIndex;
            End;

        nrbmPushButtons, nrbmCheckButtons: Begin
                FItemIndex := -1;
                FSelectedItemRef := Nil;
            End;
    End;

    HideCustomHint;
    FHotItemIndex := -1;
    FHotZone := nrtpzNone;

    InvalidateLayout;
End;

Procedure TNoReflowTabBarCore.SetShowFocus(Const Value: Boolean);
Begin
    //-------------------------------------------------------------------------
    //Active ou désactive l’affichage du focus clavier sur l’item courant.
    //
    //Cette propriété ne change pas la géométrie :
    //elle ne modifie que la présence ou non du cadre de focus interne.
    //-------------------------------------------------------------------------

    //Ne rien faire si la propriété ne change pas.
    If FShowFocus = Value Then
        Exit;

    //Mémorise le nouveau comportement.
    FShowFocus := Value;

    //Le focus n’a d’impact visuel que sur l’item actuellement porteur
    //du focus visuel. Il est donc inutile de redessiner toute la barre.
    InvalidateItem(GetFocusVisualItemIndex);
End;

Procedure TNoReflowTabBarCore.SetSelectedFontStyle(Const Value: TFontStyles);
Begin
    //-------------------------------------------------------------------------
    //Définit le ou les styles de police appliqués à l’item sélectionné.
    //
    //Exemples classiques :
    //- [fsBold]
    //- []
    //- [fsBold, fsUnderline]
    //
    //Cette propriété impacte :
    //- les mesures de texte
    //- la taille potentielle des items
    //- le rendu final du libellé sélectionné
    //-------------------------------------------------------------------------

    If FSelectedFontStyle = Value Then
        Exit;

    FSelectedFontStyle := Value;

    //Comme la taille du texte sélectionné peut changer,
    //il faut recalculer tout le layout.
    InvalidateLayout;
End;

Procedure TNoReflowTabBarCore.SetShowClosingEdge(Const Value: Boolean);
Begin
    //-------------------------------------------------------------------------
    //Alias de compatibilité pour l'ancienne propriété BarShowClosingEdge.
    //
    //La source de vérité est maintenant :
    //- BarLayoutTabs.ShowClosingEdge.
    //
    //Cette méthode permet de conserver le code existant et les anciens DFM,
    //tout en évitant de maintenir deux états séparés pour la même notion.
    //-------------------------------------------------------------------------

    If FLayoutTabs = Nil Then
        Exit;

    If FLayoutTabs.ShowClosingEdge = Value Then
        Exit;

    FLayoutTabs.ShowClosingEdge := Value;

    //Le setter du sous-objet déclenche déjà LayoutChanged.
    //On ne force donc pas une deuxième invalidation ici.
End;

Function TNoReflowTabBarCore.GetShowClosingEdge: Boolean;
Begin
    //-------------------------------------------------------------------------
    //Retourne l'état de fermeture de bordure des onglets.
    //
    //La propriété historique BarShowClosingEdge ne possède plus son propre champ.
    //Elle redirige maintenant vers BarLayoutTabs.ShowClosingEdge afin de garder
    //une seule source de vérité pour la géométrie spécifique aux onglets.
    //-------------------------------------------------------------------------

    If FLayoutTabs <> Nil Then
        Result := FLayoutTabs.ShowClosingEdge
    Else
        Result := False;
End;

Procedure TNoReflowTabBarCore.SetBarPosition(Const Value: TNoReflowTabBarPosition);
Begin
    //-------------------------------------------------------------------------
    //Définit l’orientation visuelle interne de la barre.
    //
    //Important :
    //cette propriété est volontairement indépendante de Align.
    //
    //- Align contrôle la position VCL du contrôle dans son parent
    //- BarPosition contrôle le sens visuel du layout et du rendu
    //
    //Cela permet à l’utilisateur de combiner librement :
    //- le docking du contrôle
    //- l’orientation des items
    //-------------------------------------------------------------------------
    If FBarPosition = Value Then
        Exit;

    FBarPosition := Value;
    ApplyBarPosition;
End;

Procedure TNoReflowTabBarCore.SetTextOrientation(Const Value: TNoReflowTabBarTextOrientation);
Begin
    //-------------------------------------------------------------------------
    //Setter de l’orientation du texte des items.
    //
    //Valeurs possibles :
    //- nrttoAuto
    //- nrttoHorizontal
    //- nrttoVerticalUp
    //- nrttoVerticalDown
    //
    //Cette propriété influe directement sur :
    //- les métriques du texte
    //- la taille du bouton
    //- le placement du voyant
    //- l’algorithme de rendu du libellé
    //-------------------------------------------------------------------------

    If FTextOrientation = Value Then
        Exit;

    FTextOrientation := Value;

    //Changer l’orientation revient à recalculer tout le contenu interne.
    InvalidateLayout;
End;

Procedure TNoReflowTabBarCore.SetSignalPosition(Const Value: TNoReflowTabBarSignalPosition);
Begin
    //-------------------------------------------------------------------------
    //Setter de la position logique du voyant par rapport au texte ou au bout utile de l’item.
    //
    //Valeurs :
    //- nrtspBefore
    //- nrtspAfter
    //
    //Cette notion reste logique :
    //en rendu vertical, l’effet visuel dépend ensuite aussi
    //du sens du texte (VerticalUp / VerticalDown).
    //-------------------------------------------------------------------------

    //Ne rien faire si la position ne change pas.
    If FSignalPosition = Value Then
        Exit;

    FSignalPosition := Value;

    //Le voyant fait partie intégrante de la mise en page interne,
    //donc toute modification impose un recalcul des métriques.
    InvalidateLayout;
End;

Procedure TNoReflowTabBarCore.SetItems(Const Value: TNoReflowTabBarItems);
Begin
    //-------------------------------------------------------------------------
    //Recopie une collection externe d’items dans la collection interne.
    //
    //Important :
    //- le composant reste propriétaire de sa propre collection FItems
    //- on ne remplace pas l’instance
    //- on en recopie simplement le contenu via Assign
    //-------------------------------------------------------------------------

    If Value = Nil Then
        Exit;

    //Copie le contenu de la collection fournie.
    FItems.Assign(Value);

    //Les notifications de collection déclencheront ensuite ItemsChanged.
End;

//===============================================================================================================================
//TNoReflowTabBarCore : palette, couleurs et états visuels
//===============================================================================================================================

//Normalise une palette issue du style VCL.
//
//Pourquoi cette routine existe :
//les styles VCL donnent des couleurs cohérentes globalement, mais pas
//toujours suffisamment différenciées pour ce composant précis.
//
//Or ici on veut impérativement distinguer clairement :
//- l’état normal,
//- l’état hot,
//- l’état sélectionné.
//
//Cette routine applique donc quelques corrections heuristiques pour :
//- augmenter la différence entre normal et hot,
//- augmenter la différence entre normal et selected,
//- éviter que hot et selected soient trop proches,
//- garantir enfin un contraste acceptable pour le texte sélectionné.
Procedure NormalizeStylePalette(Var APalette: TNoReflowTabBarPalette);
Const
    //Différence minimale visuelle souhaitée entre selected et normal.
    CMinSelectedVsNormal = 80;

    //Différence minimale visuelle souhaitée entre hot et normal.
    CMinHotVsNormal = 55;

    //Écart minimal de luminance entre texte sélectionné et fond.
    CMinTextLumDiff = 110;
Var
    NormalRef:   TColor;
    HotRef:      TColor;
    SelectedRef: TColor;
Begin
    //On résume chaque état par une couleur "moyenne" du dégradé,
    //prise ici à 50 % entre top et bottom.
    NormalRef := BlendColorPourcent(
        APalette.TabNormalTop,
        APalette.TabNormalBottom,
        50);
    HotRef := BlendColorPourcent(
        APalette.TabHotTop,
        APalette.TabHotBottom,
        50);
    SelectedRef := BlendColorPourcent(
        APalette.TabSelectedTop,
        APalette.TabSelectedBottom,
        50);

    //Si l’état hot est trop proche de l’état normal,
    //on le pousse dans la direction opposée à la luminance du normal :
    //- si normal est sombre, on éclaircit hot
    //- si normal est clair, on assombrit hot
    If ColorDistance(NormalRef, HotRef) < CMinHotVsNormal Then Begin
        If ColorLuminance(NormalRef) < 128 Then Begin
            APalette.TabHotTop := MakeColorLighter(
                APalette.TabHotTop,
                70);
            APalette.TabHotBottom := MakeColorLighter(
                APalette.TabHotBottom,
                70);
        End Else Begin
            APalette.TabHotTop := MakeColorDarker(
                APalette.TabHotTop,
                70);
            APalette.TabHotBottom := MakeColorDarker(
                APalette.TabHotBottom,
                70);
        End;
    End;

    //On recalcule la référence après éventuelle correction.
    HotRef := BlendColorPourcent(
        APalette.TabHotTop,
        APalette.TabHotBottom,
        50);

    //Même logique pour selected si selected et normal sont trop proches.
    If ColorDistance(NormalRef, SelectedRef) < CMinSelectedVsNormal Then Begin
        If ColorLuminance(NormalRef) < 128 Then Begin
            APalette.TabSelectedTop := MakeColorLighter(
                APalette.TabSelectedTop,
                110);
            APalette.TabSelectedBottom := MakeColorLighter(
                APalette.TabSelectedBottom,
                110);
        End Else Begin
            APalette.TabSelectedTop := MakeColorDarker(
                APalette.TabSelectedTop,
                110);
            APalette.TabSelectedBottom := MakeColorDarker(
                APalette.TabSelectedBottom,
                110);
        End;
    End;

    SelectedRef := BlendColorPourcent(
        APalette.TabSelectedTop,
        APalette.TabSelectedBottom,
        50);

    //Si hot et selected restent encore trop proches entre eux,
    //on accentue selected une deuxième fois.
    If ColorDistance(HotRef, SelectedRef) < 50 Then Begin
        If ColorLuminance(HotRef) < 128 Then Begin
            APalette.TabSelectedTop := MakeColorLighter(
                APalette.TabSelectedTop,
                60);
            APalette.TabSelectedBottom := MakeColorLighter(
                APalette.TabSelectedBottom,
                60);
        End Else Begin
            APalette.TabSelectedTop := MakeColorDarker(
                APalette.TabSelectedTop,
                60);
            APalette.TabSelectedBottom := MakeColorDarker(
                APalette.TabSelectedBottom,
                60);
        End;
    End;

    //Référence finale de l’état sélectionné après toutes corrections.
    SelectedRef := BlendColorPourcent(
        APalette.TabSelectedTop,
        APalette.TabSelectedBottom,
        50);

    //Dernière sécurité : on ajuste la couleur du texte sélectionné
    //si le contraste avec le fond reste insuffisant.
    APalette.TabSelectedText := EnsureTextContrastByLuminance(
        APalette.TabSelectedText,
        SelectedRef,
        CMinTextLumDiff);
End;

Function TryGetNoReflowStyleColor(
    AStyle: TCustomStyleServices;
    Const ADetails: TThemedElementDetails;
    AElementColor: TElementColor;
    Out AColor: TColor): Boolean;
Begin
    //-------------------------------------------------------------------------
    //Tente de récupérer une couleur directement depuis un élément du style VCL.
    //
    //Pourquoi ce helper ?
    //Les couleurs système comme clBtnText ou clHighlightText ne suffisent pas
    //toujours à reproduire correctement l'état réel d'un contrôle stylé.
    //
    //Exemple typique :
    //un bouton survolé peut avoir un texte blanc dans le style, alors que
    //clBtnText reste noir. Il faut donc demander ecTextColor à l'élément
    //tbPushButtonHot plutôt que raisonner uniquement avec les couleurs système.
    //-------------------------------------------------------------------------

    Result := False;
    AColor := clNone;

    If AStyle = Nil Then
        Exit;

    Try
        Result := AStyle.GetElementColor(
            ADetails,
            AElementColor,
            AColor);
    Except
        //Certains styles ou certaines versions de Delphi ne renseignent pas
        //toutes les couleurs pour tous les éléments.
        //
        //Dans ce cas, le code appelant utilisera son fallback.
        Result := False;
        AColor := clNone;
    End;
End;

Function ResolveNoReflowStyleColor(
    AStyle: TCustomStyleServices;
    Const ADetails: TThemedElementDetails;
    AElementColor: TElementColor;
    AFallbackColor: TColor): TColor;
Begin
    //-------------------------------------------------------------------------
    //Retourne une couleur de style si elle existe, sinon un fallback stable.
    //-------------------------------------------------------------------------

    If Not TryGetNoReflowStyleColor(AStyle, ADetails, AElementColor, Result) Then
        Result := AFallbackColor;
End;

{$IFDEF DEBUG}

Function DebugColorToText(AColor: TColor): String;
Var
    LColor: TColor;
Begin
    LColor := ColorToRGB(AColor);

    Result := Format(
        '$%.6x RGB(%d,%d,%d)',
        [LColor And $FFFFFF, GetRValue(LColor), GetGValue(LColor), GetBValue(LColor)]);
End;

Procedure DebugStyleElementColor(
    Const ACaption: String;
    AStyle: TCustomStyleServices;
    Const ADetails: TThemedElementDetails;
    AElementColor: TElementColor);
Var
    LColor: TColor;
    LText:  String;
Begin
    If AStyle = Nil Then Begin
        OutputDebugString(PChar(ACaption + ' = <no style>'));
        Exit;
    End;

    LColor := clNone;

    If AStyle.GetElementColor(ADetails, AElementColor, LColor) Then
        LText := DebugColorToText(LColor)
    Else
        LText := '<not provided>';

    OutputDebugString(PChar(Format('[NoReflowTabBar BuildStylePalette] %s = %s', [ACaption, LText])));
End;

Procedure DebugResolvedColor(
    Const ACaption: String;
    AColor: TColor);
Begin
    OutputDebugString(PChar(Format('[NoReflowTabBar BuildStylePalette] %s = %s', [ACaption, DebugColorToText(AColor)])));
End;
{$ENDIF}

Function TNoReflowTabBarCore.ResolveControlStyleServices: TCustomStyleServices;
Begin
    //-------------------------------------------------------------------------
    //Résout les services de style à utiliser par NoReflowTabBar.
    //
    //En runtime, StyleServices(Self) suffit généralement : le contrôle est dans
    //son contexte VCL réel.
    //
    //En design-time, les couleurs réellement visibles dans le designer sont
    //souvent déterminées par le conteneur parent. C'est le même principe que
    //celui validé dans VclRotatedEdit : on privilégie donc StyleServices(Parent)
    //lorsque le composant est en conception.
    //
    //Le parent n'est pas supposé être "le designer Delphi". Il représente
    //simplement le contexte visuel dans lequel la TabBar est placée : fiche,
    //frame, panel, page, card, etc.
    //-------------------------------------------------------------------------

    Result := Nil;

    If (csDesigning In ComponentState) And (Parent <> Nil) Then
        Result := StyleServices(Parent);

    If Result = Nil Then
        Result := StyleServices(Self);

    If Result = Nil Then
        Result := TStyleManager.ActiveStyle;
End;

Function TNoReflowTabBarCore.BuildStylePalette: TNoReflowTabBarPalette;
Var
    LStyle:                  TCustomStyleServices;
    BtnFace:                 TColor;
    BtnText:                 TColor;
    BtnShadow:               TColor;
    Highlight:               TColor;
    HighlightText:           TColor;
    WindowColor:             TColor;
    GrayText:                TColor;
    ActiveBorder:            TColor;
    InactiveBorder:          TColor;
    BtnFocused:              TColor;
    BtnDisabled:             TColor;
    ButtonNormalTextColor:   TColor;
    ButtonHotTextColor:      TColor;
    ButtonPressedTextColor:  TColor;
    ButtonSelectedBaseColor: TColor;

    ButtonNormalDetails:   TThemedElementDetails;
    ButtonHotDetails:      TThemedElementDetails;
    ButtonPressedDetails:  TThemedElementDetails;
    ButtonDisabledDetails: TThemedElementDetails;

    TabNormalDetails:   TThemedElementDetails;
    TabHotDetails:      TThemedElementDetails;
    TabPressedDetails:  TThemedElementDetails;
    TabSelectedDetails: TThemedElementDetails;
    TabDisabledDetails: TThemedElementDetails;

    LColor:                TColor;
    LButtonHotHasFill:     Boolean;
    LButtonPressedHasFill: Boolean;

    Function TryResolveStyleColor(
        Const ADetails: TThemedElementDetails;
        AElementColor: TElementColor;
        Out AColor: TColor): Boolean;
    Begin
        //-------------------------------------------------------------------------
        //Tente de récupérer une couleur directement depuis le style VCL.
        //
        //Cette fonction retourne True uniquement si le style fournit explicitement
        //la couleur demandée pour l'élément et l'état concernés.
        //
        //Important :
        //un style peut fournir ecTextColor sans fournir ecFillColor.
        //Il ne faut donc pas confondre :
        //- couleur réellement fournie par le style ;
        //- couleur de repli calculée par notre composant.
        //-------------------------------------------------------------------------

        Result := False;
        AColor := clNone;

        If LStyle = Nil Then Begin
{$IFDEF DEBUG}
            OutputDebugString(PChar('[NoReflowTabBar BuildStylePalette] TryResolveStyleColor: no style'));
{$ENDIF}
            Exit;
        End;

        Try Result := LStyle.GetElementColor(
                ADetails,
                AElementColor,
                AColor);
        Except
            //Certains styles ou certaines versions de Delphi peuvent lever une
            //exception sur des combinaisons Element / Part / State / Color non
            //supportées.
            //
            //Dans ce cas, on considère simplement que la couleur n'est pas fournie.
            Result := False;
            AColor := clNone;
        End;
    End;

    Function ResolveStyleColor(
        Const ACaption: String;
        Const ADetails: TThemedElementDetails;
        AElementColor: TElementColor;
        AFallbackColor: TColor): TColor;
    Var
        LStyleColor: TColor;
        LUsedStyle:  Boolean;
        LColorName:  String;
    Begin
        //-------------------------------------------------------------------------
        //Retourne une couleur de style si elle existe, sinon une couleur de repli.
        //
        //ACaption permet d'identifier précisément l'appel dans la sortie debug :
        //exemples :
        //- ButtonNormalTop
        //- ButtonHotText
        //- ButtonPressedTop
        //- ButtonSelectedBorder
        //
        //Cela évite de devoir deviner quel appel a produit quelle couleur.
        //-------------------------------------------------------------------------

        LStyleColor := clNone;

        LUsedStyle := TryResolveStyleColor(
            ADetails,
            AElementColor,
            LStyleColor);

        If LUsedStyle And (LStyleColor <> clNone) Then
            Result := LStyleColor
        Else
            Result := AFallbackColor;

{$IFDEF DEBUG}
        Case AElementColor Of
            ecBorderColor:
                LColorName := 'ecBorderColor';

            ecFillColor:
                LColorName := 'ecFillColor';

            ecTextColor:
                LColorName := 'ecTextColor';

            ecEdgeHighLightColor:
                LColorName := 'ecEdgeHighLightColor';

            ecEdgeShadowColor:
                LColorName := 'ecEdgeShadowColor';

            ecGradientColor1:
                LColorName := 'ecGradientColor1';

            ecGradientColor2:
                LColorName := 'ecGradientColor2';

            ecGradientColor3:
                LColorName := 'ecGradientColor3';

            ecGradientColor4:
                LColorName := 'ecGradientColor4';

            ecGradientColor5:
                LColorName := 'ecGradientColor5';

            ecTransparentColor:
                LColorName := 'ecTransparentColor';
        Else
            LColorName := 'ElementColor=' + IntToStr(Ord(AElementColor));
        End;

        If LUsedStyle Then Begin
            OutputDebugString(PChar(Format('[NoReflowTabBar BuildStylePalette] ResolveStyleColor %-28s %-18s STYLE    %s', [ACaption, LColorName, DebugColorToText(Result)])));
        End Else Begin
            OutputDebugString(PChar(Format('[NoReflowTabBar BuildStylePalette] ResolveStyleColor %-28s %-18s FALLBACK %s', [ACaption, LColorName, DebugColorToText(Result)])));
        End;
{$ENDIF}
    End;

Begin
    //-------------------------------------------------------------------------
    //Construit une palette de rendu à partir du style VCL actif.
    //
    //Règles retenues :
    //
    //1) Le composant ne délègue pas son dessin au style VCL.
    //Il conserve sa géométrie propre :
    //- slants et recouvrements pour les onglets ;
    //- rectangles / coins arrondis pour les boutons.
    //
    //2) En revanche, en mode style, les couleurs doivent venir autant que
    //possible du style VCL actif.
    //
    //3) Les couleurs de TabItem du style VCL ne sont pas toujours exploitables.
    //Exemple constaté avec le style Windows :
    //ttTabItemNormal / Hot / Selected peuvent renvoyer la même couleur bleue,
    //ce qui donne des items entièrement bleus.
    //
    //Pour les onglets, on conserve donc une palette reconstruite à partir des
    //couleurs système du style : WindowColor, BtnFace, Highlight, etc.
    //
    //4) Les boutons utilisent davantage les détails tbPushButton*, notamment
    //pour récupérer le texte Hot / Pressed si le style le fournit.
    //
    //5) Si le style ne fournit pas de fond Hot / Pressed pour les boutons, on
    //fabrique une couleur soutenue à partir de Highlight.
    //-------------------------------------------------------------------------

    LStyle := ResolveControlStyleServices;

    If LStyle <> Nil Then Begin
        //---------------------------------------------------------------------
        //Couleurs système principales fournies par le style actif.
        //---------------------------------------------------------------------
        BtnFace := LStyle.GetSystemColor(clBtnFace);
        BtnFocused := LStyle.GetStyleColor(scButtonFocused);
        BtnDisabled := LStyle.GetStyleColor(scButtonDisabled);
        BtnText := LStyle.GetSystemColor(clBtnText);
        BtnShadow := LStyle.GetSystemColor(clBtnShadow);
        Highlight := LStyle.GetSystemColor(clHighlight);
        HighlightText := LStyle.GetSystemColor(clHighlightText);
        WindowColor := LStyle.GetSystemColor(clWindow);
        GrayText := LStyle.GetSystemColor(clGrayText);
        ActiveBorder := LStyle.GetSystemColor(clActiveBorder);
        InactiveBorder := LStyle.GetSystemColor(clInactiveBorder);

        //---------------------------------------------------------------------
        //Détails thématiques des boutons VCL.
        //
        //Ces détails sont utiles pour récupérer les couleurs particulières des
        //états Normal / Hot / Pressed / Disabled.
        //---------------------------------------------------------------------
        ButtonNormalDetails := LStyle.GetElementDetails(tbPushButtonNormal);
        ButtonHotDetails := LStyle.GetElementDetails(tbPushButtonHot);
        ButtonPressedDetails := LStyle.GetElementDetails(tbPushButtonPressed);
        ButtonDisabledDetails := LStyle.GetElementDetails(tbPushButtonDisabled);

        //---------------------------------------------------------------------
        //Détails thématiques des onglets VCL.
        //
        //Ils restent disponibles pour debug ou évolution future, mais la palette
        //onglet ci-dessous ne s'appuie volontairement plus directement sur
        //ecFillColor de ttTabItem*, car certains styles donnent une base
        //inexploitable pour notre géométrie.
        //---------------------------------------------------------------------
        TabNormalDetails := LStyle.GetElementDetails(ttTabItemNormal);
        TabHotDetails := LStyle.GetElementDetails(ttTabItemHot);

        //TabPressedDetails := LStyle.GetElementDetails(ttTabItemHot);
        TabPressedDetails := LStyle.GetElementDetails(ttTabItemFocused);

        TabSelectedDetails := LStyle.GetElementDetails(ttTabItemSelected);
        TabDisabledDetails := LStyle.GetElementDetails(ttTabItemDisabled);
    End Else Begin
        //---------------------------------------------------------------------
        //Repli défensif si aucun style n'est réellement disponible.
        //
        //Dans ce cas, on retombe sur les couleurs système classiques.
        //---------------------------------------------------------------------
        BtnFace := clBtnFace;
        BtnFocused := clBtnHighlight;
        BtnText := clBtnText;
        BtnShadow := clBtnShadow;
        Highlight := clHighlight;
        HighlightText := clHighlightText;
        WindowColor := clWindow;
        GrayText := clGrayText;
        ActiveBorder := clActiveBorder;
        InactiveBorder := clInactiveBorder;

        BtnDisabled := BlendColorPourcent(
            BtnFace,
            WindowColor,
            40);

        //---------------------------------------------------------------------
        //Initialisation défensive des détails thématiques.
        //
        //Même si LStyle = nil, on initialise ces structures pour éviter toute
        //valeur indéfinie dans les appels internes de résolution.
        //---------------------------------------------------------------------
        ButtonNormalDetails.Element := teButton;
        ButtonNormalDetails.Part := 0;
        ButtonNormalDetails.State := 0;

        ButtonHotDetails := ButtonNormalDetails;
        ButtonPressedDetails := ButtonNormalDetails;
        ButtonDisabledDetails := ButtonNormalDetails;

        TabNormalDetails.Element := teTab;
        TabNormalDetails.Part := 0;
        TabNormalDetails.State := 0;

        TabHotDetails := TabNormalDetails;
        TabPressedDetails := TabNormalDetails;
        TabSelectedDetails := TabNormalDetails;
        TabDisabledDetails := TabNormalDetails;
    End;

    //-------------------------------------------------------------------------
    //Fond général de la barre.
    //
    //En rendu style, le fond suit la surface standard du style VCL.
    //-------------------------------------------------------------------------
    Result.BarBackground := BtnFace;

    //=========================================================================
    //PALETTE DES ONGLETS
    //=========================================================================

    //-------------------------------------------------------------------------
    //Onglet normal.
    //
    //On utilise une surface claire inspirée de WindowColor et BtnFace.
    //Cela évite le problème des styles qui renvoient une couleur d'accent pour
    //ttTabItemNormal.ecFillColor.
    //-------------------------------------------------------------------------
    Result.TabNormalTop := WindowColor;
    Result.TabNormalBottom := BlendColorPourcent(
        BtnFace,
        WindowColor,
        40);
    Result.TabNormalText := BtnText;
    Result.TabNormalBorder := ActiveBorder;

    //-------------------------------------------------------------------------
    //Onglet survolé.
    //
    //Le survol est inspiré de Highlight, mais reste moins fort qu'un bouton
    //sélectionné. NormalizeStylePalette pourra ensuite renforcer l'écart si le
    //contraste est trop faible.
    //-------------------------------------------------------------------------
    Result.TabHotTop := BlendColorPourcent(
        Highlight,
        WindowColor,
        60);
    Result.TabHotBottom := BlendColorPourcent(
        Highlight,
        BtnShadow,
        35);
    Result.TabHotText := BtnText;
    Result.TabHotBorder := ActiveBorder;

    //-------------------------------------------------------------------------
    //Onglet pressé.
    //
    //Pour les onglets, l'état pressé reste visuellement proche du survol.
    //-------------------------------------------------------------------------
    Result.TabPressedTop := Result.TabHotTop;
    Result.TabPressedBottom := Result.TabHotBottom;
    Result.TabPressedText := Result.TabHotText;
    Result.TabPressedBorder := Result.TabHotBorder;

    //-------------------------------------------------------------------------
    //Onglet sélectionné.
    //
    //BtnFocused donne souvent une surface proche du style actif.
    //NormalizeStylePalette pourra corriger si l'état sélectionné est trop proche
    //du normal ou du hot.
    //-------------------------------------------------------------------------
    Result.TabSelectedTop := BtnFocused;
    Result.TabSelectedBottom := BtnFocused;
    //Pour un onglet sélectionné persistant, on évite HighlightText.
    //Certains styles, comme Glow, utilisent un texte d'accent (ex. vert)
    //sur les surfaces sélectionnées, alors que HighlightText force un blanc
    //prévu pour une sélection système classique.
    Result.TabSelectedText := ResolveStyleColor(
        'TabSelectedText',
        TabSelectedDetails,
        ecTextColor,
        BtnText);
    Result.TabSelectedBorder := ActiveBorder;

    //-------------------------------------------------------------------------
    //Onglet désactivé.
    //-------------------------------------------------------------------------
    Result.TabDisabledTop := BtnDisabled;
    Result.TabDisabledBottom := BtnDisabled;
    Result.TabDisabledText := GrayText;
    Result.TabDisabledBorder := InactiveBorder;

    //-------------------------------------------------------------------------
    //Reliefs optionnels pour les onglets.
    //-------------------------------------------------------------------------
    Result.TabLightEdge := WindowColor;
    Result.TabShadowEdge := BtnShadow;


    //=========================================================================
    //PALETTE DES BOUTONS
    //=========================================================================

    //-------------------------------------------------------------------------
    //Textes des états bouton.
    //
    //On les résout une seule fois pour pouvoir ensuite conserver une cohérence
    //fond / texte.
    //-------------------------------------------------------------------------
    ButtonNormalTextColor := ResolveStyleColor(
        'ButtonNormalText',
        ButtonNormalDetails,
        ecTextColor,
        BtnText);

    ButtonHotTextColor := ResolveStyleColor(
        'ButtonHotText',
        ButtonHotDetails,
        ecTextColor,
        ButtonNormalTextColor);

    ButtonPressedTextColor := ResolveStyleColor(
        'ButtonPressedText',
        ButtonPressedDetails,
        ecTextColor,
        ButtonHotTextColor);

    //-------------------------------------------------------------------------
    //Bouton normal.
    //
    //Pour les fonds de boutons, on privilégie les couleurs TStyleColor.
    //
    //Raison :
    //les éléments tbPushButtonNormal / Hot / Pressed ne fournissent pas toujours
    //ecFillColor. Dans ce cas, utiliser ecFillColor force le composant à tomber
    //sur un fallback qui peut être faux ou trop générique.
    //
    //scButtonNormal est la couleur prévue par le style VCL pour la surface
    //normale d'un bouton.
    //-------------------------------------------------------------------------
    Result.ButtonNormalTop := LStyle.GetStyleColor(scButtonNormal);
    Result.ButtonNormalBottom := Result.ButtonNormalTop;

    Result.ButtonNormalText := ButtonNormalTextColor;

    Result.ButtonNormalBorder := LStyle.GetStyleColor(scBorder);

    //-------------------------------------------------------------------------
    //Bouton survolé.
    //
    //scButtonHot est la couleur de fond prévue par le style pour un bouton
    //survolé.
    //
    //On ne cherche donc plus ecFillColor sur tbPushButtonHot pour le fond.
    //En revanche, on continue à chercher ecTextColor, car certains styles
    //peuvent changer la couleur du texte au survol.
    //-------------------------------------------------------------------------
    Result.ButtonHotTop := LStyle.GetStyleColor(scButtonHot);
    Result.ButtonHotBottom := Result.ButtonHotTop;

    Result.ButtonHotText := ButtonHotTextColor;

    Result.ButtonHotBorder := Highlight;

    //-------------------------------------------------------------------------
    //Bouton pressé.
    //
    //scButtonPressed est la couleur prévue par le style pour un bouton appuyé.
    //
    //C'est cette couleur qui doit servir de référence au rendu Pressed, et non
    //clHighlight ni ecFillColor.
    //-------------------------------------------------------------------------
    Result.ButtonPressedTop := LStyle.GetStyleColor(scButtonPressed);
    Result.ButtonPressedBottom := Result.ButtonPressedTop;

    Result.ButtonPressedText := ButtonPressedTextColor;

    Result.ButtonPressedBorder := Highlight;

    //-------------------------------------------------------------------------
    //Bouton sélectionné.
    //
    //Un bouton sélectionné NoReflow est un état persistant.
    //
    //Le meilleur équivalent côté style VCL est scButtonFocused :
    //- ce n'est pas un simple Highlight système ;
    //- c'est bien une couleur spécifique au bouton ;
    //- dans vos traces, c'est précisément cette famille de couleur qui semble
    //correspondre au rendu attendu.
    //-------------------------------------------------------------------------
    Result.ButtonSelectedTop := LStyle.GetStyleColor(scButtonFocused);
    Result.ButtonSelectedBottom := Result.ButtonSelectedTop;
    //Un bouton sélectionné NoReflow est un état persistant, pas un clic
    //temporaire. On ne reprend donc pas le texte Pressed : certains styles
    //le rendent blanc alors que le rendu sélectionné attendu conserve la
    //couleur de texte normale/accentuée du style.
    Result.ButtonSelectedText := ResolveStyleColor(
        'ButtonSelectedText',
        ButtonNormalDetails,
        ecTextColor,
        ButtonNormalTextColor);
    Result.ButtonSelectedBorder := Highlight;

    //-------------------------------------------------------------------------
    //Bouton désactivé.
    //
    //Même logique : le fond vient de TStyleColor, le texte peut venir des détails
    //thématiques si le style le fournit.
    //-------------------------------------------------------------------------
    Result.ButtonDisabledTop := LStyle.GetStyleColor(scButtonDisabled);
    Result.ButtonDisabledBottom := Result.ButtonDisabledTop;

    Result.ButtonDisabledText := ResolveStyleColor(
        'ButtonDisabledText',
        ButtonDisabledDetails,
        ecTextColor,
        GrayText);

    Result.ButtonDisabledBorder := InactiveBorder;

    //-------------------------------------------------------------------------
    //Reliefs optionnels pour les boutons.
    //-------------------------------------------------------------------------
    Result.ButtonLightEdge := WindowColor;
    Result.ButtonShadowEdge := BtnShadow;

{$IFDEF DEBUG}
    DebugResolvedColor(
        'ButtonNormalTop from scButtonNormal',
        Result.ButtonNormalTop);

    DebugResolvedColor(
        'ButtonHotTop from scButtonHot',
        Result.ButtonHotTop);

    DebugResolvedColor(
        'ButtonPressedTop from scButtonPressed',
        Result.ButtonPressedTop);

    DebugResolvedColor(
        'ButtonSelectedTop from scButtonFocused',
        Result.ButtonSelectedTop);

    DebugResolvedColor(
        'ButtonDisabledTop from scButtonDisabled',
        Result.ButtonDisabledTop);
{$ENDIF}
    //-------------------------------------------------------------------------
    //Focus, headers de zones et marqueur de drag.
    //-------------------------------------------------------------------------
    Result.FocusColor := Highlight;
    Result.ZoneHeaderText := BtnText;
    Result.ZoneHeaderLine := Highlight;
    Result.DragInsertMarker := Highlight;

    //=========================================================================
    //CONVERSION RGB
    //=========================================================================

    //-------------------------------------------------------------------------
    //On convertit toutes les couleurs résolues en RGB.
    //
    //Cela fige la palette au moment du calcul et évite de conserver des valeurs
    //système ou style dépendantes du contexte GDI courant.
    //-------------------------------------------------------------------------

    Result.BarBackground := ColorToRGB(Result.BarBackground);

    Result.TabNormalTop := ColorToRGB(Result.TabNormalTop);
    Result.TabNormalBottom := ColorToRGB(Result.TabNormalBottom);
    Result.TabNormalText := ColorToRGB(Result.TabNormalText);
    Result.TabNormalBorder := ColorToRGB(Result.TabNormalBorder);

    Result.TabHotTop := ColorToRGB(Result.TabHotTop);
    Result.TabHotBottom := ColorToRGB(Result.TabHotBottom);
    Result.TabHotText := ColorToRGB(Result.TabHotText);
    Result.TabHotBorder := ColorToRGB(Result.TabHotBorder);

    Result.TabPressedTop := ColorToRGB(Result.TabPressedTop);
    Result.TabPressedBottom := ColorToRGB(Result.TabPressedBottom);
    Result.TabPressedText := ColorToRGB(Result.TabPressedText);
    Result.TabPressedBorder := ColorToRGB(Result.TabPressedBorder);

    Result.TabSelectedTop := ColorToRGB(Result.TabSelectedTop);
    Result.TabSelectedBottom := ColorToRGB(Result.TabSelectedBottom);
    Result.TabSelectedText := ColorToRGB(Result.TabSelectedText);
    Result.TabSelectedBorder := ColorToRGB(Result.TabSelectedBorder);

    Result.TabDisabledTop := ColorToRGB(Result.TabDisabledTop);
    Result.TabDisabledBottom := ColorToRGB(Result.TabDisabledBottom);
    Result.TabDisabledText := ColorToRGB(Result.TabDisabledText);
    Result.TabDisabledBorder := ColorToRGB(Result.TabDisabledBorder);

    Result.TabLightEdge := ColorToRGB(Result.TabLightEdge);
    Result.TabShadowEdge := ColorToRGB(Result.TabShadowEdge);

    Result.ButtonNormalTop := ColorToRGB(Result.ButtonNormalTop);
    Result.ButtonNormalBottom := ColorToRGB(Result.ButtonNormalBottom);
    Result.ButtonNormalText := ColorToRGB(Result.ButtonNormalText);
    Result.ButtonNormalBorder := ColorToRGB(Result.ButtonNormalBorder);

    Result.ButtonHotTop := ColorToRGB(Result.ButtonHotTop);
    Result.ButtonHotBottom := ColorToRGB(Result.ButtonHotBottom);
    Result.ButtonHotText := ColorToRGB(Result.ButtonHotText);
    Result.ButtonHotBorder := ColorToRGB(Result.ButtonHotBorder);

    Result.ButtonPressedTop := ColorToRGB(Result.ButtonPressedTop);
    Result.ButtonPressedBottom := ColorToRGB(Result.ButtonPressedBottom);
    Result.ButtonPressedText := ColorToRGB(Result.ButtonPressedText);
    Result.ButtonPressedBorder := ColorToRGB(Result.ButtonPressedBorder);

    Result.ButtonSelectedTop := ColorToRGB(Result.ButtonSelectedTop);
    Result.ButtonSelectedBottom := ColorToRGB(Result.ButtonSelectedBottom);
    Result.ButtonSelectedText := ColorToRGB(Result.ButtonSelectedText);
    Result.ButtonSelectedBorder := ColorToRGB(Result.ButtonSelectedBorder);

    Result.ButtonDisabledTop := ColorToRGB(Result.ButtonDisabledTop);
    Result.ButtonDisabledBottom := ColorToRGB(Result.ButtonDisabledBottom);
    Result.ButtonDisabledText := ColorToRGB(Result.ButtonDisabledText);
    Result.ButtonDisabledBorder := ColorToRGB(Result.ButtonDisabledBorder);

    Result.ButtonLightEdge := ColorToRGB(Result.ButtonLightEdge);
    Result.ButtonShadowEdge := ColorToRGB(Result.ButtonShadowEdge);

    Result.FocusColor := ColorToRGB(Result.FocusColor);

    Result.ZoneHeaderText := ColorToRGB(Result.ZoneHeaderText);
    Result.ZoneHeaderLine := ColorToRGB(Result.ZoneHeaderLine);
    Result.DragInsertMarker := ColorToRGB(Result.DragInsertMarker);

    //-------------------------------------------------------------------------
    //Normalisation des couleurs d'items.
    //
    //On conserve cette étape car elle ne sert pas uniquement à fabriquer une
    //palette : elle sécurise aussi les écarts de contraste entre les états.
    //
    //Important :
    //dans l'état actuel, NormalizeStylePalette doit rester centrée sur les
    //couleurs Tab*. Elle ne doit pas écraser ButtonSelected*, ButtonHot*, etc.
    //-------------------------------------------------------------------------
    NormalizeStylePalette(Result);
End;

Procedure TNoReflowTabBarCore.InvalidatePalette;
Begin
    //-------------------------------------------------------------------------
    //Marque le cache de palette comme obsolète.
    //
    //La reconstruction réelle est différée jusqu’au prochain appel
    //à GetActivePalette.
    //-------------------------------------------------------------------------
    FPaletteDirty := True;
End;

Function TNoReflowTabBarCore.GetActivePalette: TNoReflowTabBarPalette;
Begin
    //-------------------------------------------------------------------------
    //Retourne la palette réellement utilisée par le composant.
    //
    //Deux décisions sont volontairement séparées :
    //
    //1) BarRenderMode décide COMMENT dessiner :
    //- Flat     : rendu maison plat ;
    //- Gradient : rendu maison dégradé.
    //
    //2) BarPaletteMode décide D'OÙ viennent les couleurs :
    //- nrtcmStyle  : couleurs dérivées du style VCL actif ;
    //- nrtcmCustom : couleurs de BarAppearance.
    //
    //Le composant ne délègue plus le chrome des items à TStyleServices. Le mode
    //style historique est remplacé par la combinaison :
    //BarPaletteMode = nrtcmStyle + BarRenderMode = nrrmFlat.
    //-------------------------------------------------------------------------

    If FPaletteDirty Then Begin
        Case FPaletteMode Of
            nrtcmStyle: Begin
                    //---------------------------------------------------------
                    //Couleurs issues du style VCL actif.
                    //---------------------------------------------------------
                    FActivePaletteCache := BuildStylePalette;
                End;

        Else Begin
                //-------------------------------------------------------------
                //Couleurs custom.
                //-------------------------------------------------------------
                FActivePaletteCache.BarBackground := Color;

                FActivePaletteCache.TabNormalTop := FAppearance.TabNormalTop;
                FActivePaletteCache.TabNormalBottom := FAppearance.TabNormalBottom;
                FActivePaletteCache.TabNormalText := FAppearance.TabNormalText;
                FActivePaletteCache.TabNormalBorder := FAppearance.TabNormalBorder;

                FActivePaletteCache.TabHotTop := FAppearance.TabHotTop;
                FActivePaletteCache.TabHotBottom := FAppearance.TabHotBottom;
                FActivePaletteCache.TabHotText := FAppearance.TabHotText;
                FActivePaletteCache.TabHotBorder := FAppearance.TabHotBorder;

                //-------------------------------------------------------------
                //Etat pressé des onglets.
                //-------------------------------------------------------------
                FActivePaletteCache.TabPressedTop := FAppearance.TabPressedTop;
                FActivePaletteCache.TabPressedBottom := FAppearance.TabPressedBottom;
                FActivePaletteCache.TabPressedText := FAppearance.TabPressedText;
                FActivePaletteCache.TabPressedBorder := FAppearance.TabPressedBorder;

                FActivePaletteCache.TabSelectedTop := FAppearance.TabSelectedTop;
                FActivePaletteCache.TabSelectedBottom := FAppearance.TabSelectedBottom;
                FActivePaletteCache.TabSelectedText := FAppearance.TabSelectedText;
                FActivePaletteCache.TabSelectedBorder := FAppearance.TabSelectedBorder;

                FActivePaletteCache.TabDisabledTop := FAppearance.TabDisabledTop;
                FActivePaletteCache.TabDisabledBottom := FAppearance.TabDisabledBottom;
                FActivePaletteCache.TabDisabledText := FAppearance.TabDisabledText;
                FActivePaletteCache.TabDisabledBorder := FAppearance.TabDisabledBorder;

                FActivePaletteCache.TabLightEdge := FAppearance.TabLightEdge;
                FActivePaletteCache.TabShadowEdge := FAppearance.TabShadowEdge;

                FActivePaletteCache.ButtonNormalTop := FAppearance.ButtonNormalTop;
                FActivePaletteCache.ButtonNormalBottom := FAppearance.ButtonNormalBottom;
                FActivePaletteCache.ButtonNormalText := FAppearance.ButtonNormalText;
                FActivePaletteCache.ButtonNormalBorder := FAppearance.ButtonNormalBorder;

                FActivePaletteCache.ButtonHotTop := FAppearance.ButtonHotTop;
                FActivePaletteCache.ButtonHotBottom := FAppearance.ButtonHotBottom;
                FActivePaletteCache.ButtonHotText := FAppearance.ButtonHotText;
                FActivePaletteCache.ButtonHotBorder := FAppearance.ButtonHotBorder;

                FActivePaletteCache.ButtonPressedTop := FAppearance.ButtonPressedTop;
                FActivePaletteCache.ButtonPressedBottom := FAppearance.ButtonPressedBottom;
                FActivePaletteCache.ButtonPressedText := FAppearance.ButtonPressedText;
                FActivePaletteCache.ButtonPressedBorder := FAppearance.ButtonPressedBorder;

                FActivePaletteCache.ButtonSelectedTop := FAppearance.ButtonSelectedTop;
                FActivePaletteCache.ButtonSelectedBottom := FAppearance.ButtonSelectedBottom;
                FActivePaletteCache.ButtonSelectedText := FAppearance.ButtonSelectedText;
                FActivePaletteCache.ButtonSelectedBorder := FAppearance.ButtonSelectedBorder;

                FActivePaletteCache.ButtonDisabledTop := FAppearance.ButtonDisabledTop;
                FActivePaletteCache.ButtonDisabledBottom := FAppearance.ButtonDisabledBottom;
                FActivePaletteCache.ButtonDisabledText := FAppearance.ButtonDisabledText;
                FActivePaletteCache.ButtonDisabledBorder := FAppearance.ButtonDisabledBorder;

                FActivePaletteCache.ButtonLightEdge := FAppearance.ButtonLightEdge;
                FActivePaletteCache.ButtonShadowEdge := FAppearance.ButtonShadowEdge;

                FActivePaletteCache.FocusColor := FAppearance.FocusColor;

                If FZoneHeader <> Nil Then Begin
                    FActivePaletteCache.ZoneHeaderText := ColorToRGB(FZoneHeader.TextColor);
                    FActivePaletteCache.ZoneHeaderLine := ColorToRGB(FZoneHeader.LineColor);
                End Else Begin
                    FActivePaletteCache.ZoneHeaderText := clBtnText;
                    FActivePaletteCache.ZoneHeaderLine := clBtnShadow;
                End;

                FActivePaletteCache.DragInsertMarker := FCustomPalette.DragInsertMarker;
            End;
        End;

        //---------------------------------------------------------------------
        //Respect partiel de StyleElements pour les textes.
        //
        //Quand seFont n'est pas actif, le composant ne doit pas imposer la
        //couleur de texte issue du style. On revient donc à Font.Color.
        //---------------------------------------------------------------------
        If Not(seFont In StyleElements) Then Begin
            FActivePaletteCache.TabNormalText := Font.Color;
            FActivePaletteCache.TabHotText := Font.Color;
            FActivePaletteCache.TabSelectedText := Font.Color;
            FActivePaletteCache.TabDisabledText := clGrayText;
            FActivePaletteCache.TabPressedText := Font.Color;

            FActivePaletteCache.ButtonNormalText := Font.Color;
            FActivePaletteCache.ButtonHotText := Font.Color;
            FActivePaletteCache.ButtonPressedText := Font.Color;
            FActivePaletteCache.ButtonSelectedText := Font.Color;
            FActivePaletteCache.ButtonDisabledText := Font.Color;

            FActivePaletteCache.ZoneHeaderText := Font.Color;
        End;

        //---------------------------------------------------------------------
        //Respect partiel de StyleElements pour le fond général.
        //
        //Si seClient n'est pas actif, le fond du contrôle doit suivre Color.
        //---------------------------------------------------------------------
        If Not(seClient In StyleElements) Then
            FActivePaletteCache.BarBackground := Color;

        FPaletteDirty := False;
    End;

    Result := FActivePaletteCache;
End;

Procedure TNoReflowTabBarCore.ResolveTabRenderColors(
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
    //Résout toutes les couleurs concrètes à utiliser pour dessiner un onglet.
    //
    //Entrées :
    //- APalette      : palette déjà résolue, prête à l’emploi
    //- AVisualState  : état visuel courant de l’onglet
    //- ASignalCode   : code logique du voyant éventuel
    //
    //Sorties :
    //- couleurs de fond haut / bas pour le gradient
    //- couleur de texte
    //- couleur de bordure
    //- couleurs de remplissage / contour du voyant
    //
    //Cette routine centralise la traduction :
    //- d’un état métier/visuel
    //- vers des couleurs de rendu effectives
    //-------------------------------------------------------------------------

    Case AVisualState Of
        nrtvsNormal: Begin
                ATopColor := APalette.TabNormalTop;
                ABottomColor := APalette.TabNormalBottom;
                ATextColor := APalette.TabNormalText;
                ABorderColor := APalette.TabNormalBorder;
            End;

        nrtvsHot: Begin
                ATopColor := APalette.TabHotTop;
                ABottomColor := APalette.TabHotBottom;
                ATextColor := APalette.TabHotText;
                ABorderColor := APalette.TabHotBorder;
            End;

        nrtvsPressed: Begin
                ATopColor := APalette.TabPressedTop;
                ABottomColor := APalette.TabPressedBottom;
                ATextColor := APalette.TabPressedText;
                ABorderColor := APalette.TabPressedBorder;
            End;

        nrtvsSelected: Begin
                ATopColor := APalette.TabSelectedTop;
                ABottomColor := APalette.TabSelectedBottom;
                ATextColor := APalette.TabSelectedText;
                ABorderColor := APalette.TabSelectedBorder;
            End;

        nrtvsDisabled: Begin
                ATopColor := APalette.TabDisabledTop;
                ABottomColor := APalette.TabDisabledBottom;
                ATextColor := APalette.TabDisabledText;
                ABorderColor := APalette.TabDisabledBorder;
            End;
    Else Begin
            //Fallback défensif :
            //si un état inattendu apparaît, on retombe sur l’état normal.
            ATopColor := APalette.TabNormalTop;
            ABottomColor := APalette.TabNormalBottom;
            ATextColor := APalette.TabNormalText;
            ABorderColor := APalette.TabNormalBorder;
        End;
    End;

    //Résolution indépendante des couleurs du voyant.
    //Le voyant n’est pas lié à l’état visuel de l’onglet : il garde sa sémantique
    //propre (gris, vert, orange, rouge).
    LSignalDef := FindSignalDefByCode(ASignalCode);

    If LSignalDef <> Nil Then Begin
        ASignalBrushColor := LSignalDef.FillColor;
        ASignalPenColor := LSignalDef.BorderColor;
    End Else Begin
        ASignalBrushColor := clNone;
        ASignalPenColor := clNone;
    End;
End;

Function TNoReflowTabBarCore.GetFocusVisualItemIndex: Integer;
Begin
    //-------------------------------------------------------------------------
    //Retourne l'item qui doit porter l'indication visuelle de focus clavier.
    //
    //Important :
    //- ce n'est pas forcément un item "Selected" au sens visuel ;
    //- en modes boutons push / check, il s'agit simplement de l'item courant
    //pour la navigation clavier et le dernier item activé.
    //
    //On centralise cette règle ici pour éviter que le rendu, DoEnter/DoExit
    //et les invalidations locales ne réinterprètent différemment FItemIndex.
    //-------------------------------------------------------------------------

    If (FItemIndex >= 0) And (FItemIndex < FItems.Count) Then
        Result := FItemIndex
    Else
        Result := -1;
End;

Function TNoReflowTabBarCore.GetItemVisualState(AIndex: Integer): TNoReflowTabBarItemVisualState;
Var
    LTab: TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Détermine l'état visuel courant d'un item.
    //
    //Priorité retenue :
    //1) Disabled
    //2) Pressed
    //3) Selected / Checked selon le mode
    //4) Hot
    //5) Normal
    //
    //Rôle de Checked selon BarMode :
    //
    //- nrbmTabs :
    //Checked est synchronisé avec FItemIndex, mais le rendu reste basé sur
    //FItemIndex pour préserver le comportement historique.
    //
    //- nrbmSelectButtons :
    //Checked est synchronisé avec FItemIndex, et l'item courant est affiché
    //comme Selected.
    //
    //- nrbmCheckButtons :
    //Checked devient la vraie source de l'état Selected.
    //
    //- nrbmPushButtons :
    //Checked n'est pas interprété automatiquement par le rendu.
    //-------------------------------------------------------------------------

    Result := nrtvsNormal;

    If (AIndex < 0) Or (AIndex >= FItems.Count) Then
        Exit;

    LTab := FItems[AIndex];

    If LTab = Nil Then
        Exit;

    If Not LTab.Enabled Then Begin
        Result := nrtvsDisabled;
        Exit;
    End;

    If AIndex = FPressedItemIndex Then Begin
        Result := nrtvsPressed;
        Exit;
    End;

    Case FBarMode Of
        nrbmTabs, nrbmSelectButtons: Begin
                If AIndex = FItemIndex Then Begin
                    Result := nrtvsSelected;
                    Exit;
                End;
            End;

        nrbmCheckButtons: Begin
                If LTab.Checked Then Begin
                    Result := nrtvsSelected;
                    Exit;
                End;
            End;
    End;

    If AIndex = FHotItemIndex Then
        Result := nrtvsHot;
End;

Function TNoReflowTabBarCore.ShouldDrawClosedEdgeForTab(AIndex: Integer): Boolean;
Begin
    //-------------------------------------------------------------------------
    //Indique si la bordure de l’onglet doit être complètement fermée.
    //
    //Cas général :
    //- on suit la valeur de la propriété BarShowClosingEdge
    //
    //Exception volontaire :
    //- l’onglet sélectionné ne ferme jamais son bord de contact
    //avec la page / zone cliente
    //
    //C’est un choix visuel essentiel pour conserver l’illusion classique
    //d’un onglet actif qui "fusionne" avec son contenu.
    //-------------------------------------------------------------------------

    If FLayoutTabs <> Nil Then
        Result := FLayoutTabs.ShowClosingEdge
    Else
        Result := False;

    If AIndex = FItemIndex Then
        Result := False;
End;

Function TNoReflowTabBarCore.GetGDIPrefillColor(ATopColor, ABottomColor: TColor): TColor;
Begin
    //-------------------------------------------------------------------------
    //Choisit la couleur de pré-remplissage utilisée avant le gradient GDI+.
    //
    //Pourquoi ?
    //Un pré-remplissage plein de la forme réduit certains petits artefacts
    //visuels sur les bords, notamment quand le gradient est clipé dans
    //un polygone antialiasé.
    //
    //La couleur choisie dépend du côté "dominant" visuellement selon
    //la position de la barre.
    //-------------------------------------------------------------------------

    Case FBarPosition Of
        nrtbpTop:
            Result := ABottomColor;

        nrtbpBottom:
            Result := ATopColor;

        nrtbpLeft:
            Result := ABottomColor;

        nrtbpRight:
            Result := ATopColor;
    Else
        //Fallback défensif.
        Result := ABottomColor;
    End;
End;

Procedure TNoReflowTabBarCore.SetAppearance(Const Value: TNoReflowTabBarAppearance);
Begin
    //-------------------------------------------------------------------------
    //Recopie une apparence externe dans le sous-objet interne FAppearance.
    //
    //On ne remplace pas l’instance interne elle-même :
    //cela évite de casser les liens de propriété, notifications et streaming.
    //-------------------------------------------------------------------------

    If Value = Nil Then
        Exit;

    FAppearance.Assign(Value);
End;

Procedure TNoReflowTabBarCore.SetZoneHeader(Const Value: TNoReflowTabBarZoneHeader);
Begin
    //-------------------------------------------------------------------------
    //Recopie un header de zones externe dans le sous-objet interne FZoneHeader.
    //
    //On ne remplace pas l’instance interne elle-même :
    //cela évite de casser les liens de propriété, notifications et streaming.
    //-------------------------------------------------------------------------

    If Value = Nil Then
        Exit;

    FZoneHeader.Assign(Value);
End;

Procedure TNoReflowTabBarCore.SetLayout(Const Value: TNoReflowTabBarLayout);
Begin
    //-------------------------------------------------------------------------
    //Recopie un layout commun externe dans le sous-objet interne FLayout.
    //
    //On ne remplace pas l'instance interne :
    //cela préserve le streaming, les notifications et les références publiées.
    //-------------------------------------------------------------------------

    If Value = Nil Then
        Exit;

    FLayout.Assign(Value);
End;

Procedure TNoReflowTabBarCore.SetLayoutTabs(Const Value: TNoReflowTabBarLayoutTabs);
Begin
    //-------------------------------------------------------------------------
    //Recopie un layout d'onglets externe dans le sous-objet interne FLayoutTabs.
    //
    //Ce layout contient uniquement les paramètres propres à la forme onglet :
    //- recouvrement ;
    //- slants ;
    //- rayons ;
    //- bordure de fermeture.
    //-------------------------------------------------------------------------

    If Value = Nil Then
        Exit;

    FLayoutTabs.Assign(Value);
End;

Procedure TNoReflowTabBarCore.SetLayoutButtons(Const Value: TNoReflowTabBarLayoutButtons);
Begin
    //-------------------------------------------------------------------------
    //Recopie un layout de boutons externe dans le sous-objet interne
    //FLayoutButtons.
    //
    //Le layout bouton est désormais exploité par le pipeline de layout et de
    //rendu lorsque BarMode sélectionne un mode bouton. Le sous-objet reste
    //possédé par le Core pour stabiliser l'API et le streaming DFM.
    //-------------------------------------------------------------------------

    If Value = Nil Then
        Exit;

    FLayoutButtons.Assign(Value);
End;

Procedure TNoReflowTabBarCore.SetPaletteMode(Const Value: TNoReflowTabBarPaletteMode);
Begin
    //-------------------------------------------------------------------------
    //Change le mode de construction de la palette active :
    //- nrtcmCustom : couleurs prises dans BarAppearance
    //- nrtcmStyle  : couleurs dérivées du style VCL actif
    //
    //Remarque :
    //BarPaletteMode indique uniquement la source des couleurs.
    //La stratégie de dessin elle-même est maintenant portée par BarRenderMode.
    //
    //Si BarRenderMode = nrrmAuto, BarPaletteMode sert à choisir le rendu
    //effectif :
    //- nrtcmStyle  -> nrrmFlat ;
    //- nrtcmCustom -> nrrmGradient.
    //-------------------------------------------------------------------------

    If FPaletteMode = Value Then
        Exit;

    FPaletteMode := Value;

    InvalidatePalette;
    InvalidateRenderInfo;
    Invalidate;
End;

Procedure TNoReflowTabBarCore.SetBarRenderMode(Const Value: TNoReflowTabBarRenderMode);
Begin
    //-------------------------------------------------------------------------
    //Change le mode de rendu global de la barre.
    //
    //Important :
    //BarRenderMode ne remplace pas BarPaletteMode.
    //
    //- BarRenderMode décide COMMENT dessiner :
    //plat, dégradé ou automatique.
    //
    //- BarPaletteMode décide D'OÙ viennent les couleurs lorsque le rendu est
    //maison :
    //couleurs custom ou couleurs dérivées du style.
    //
    //BarPaletteMode reste toujours la source des couleurs : style ou custom.
    //-------------------------------------------------------------------------

    If FBarRenderMode = Value Then
        Exit;

    FBarRenderMode := Value;

    //Le changement de mode peut modifier :
    //- la palette effective ;
    //- la présence ou non d'un dégradé ;
    //- la manière de traiter les bordures ;
    //- l'apparence globale des onglets et boutons.
    //
    //On invalide donc à la fois la palette et le rendu.
    InvalidatePalette;
    InvalidateRenderInfo;
    Invalidate;
End;

Function TNoReflowTabBarCore.GetEffectiveBarRenderMode: TNoReflowTabBarRenderMode;
Begin
    //-------------------------------------------------------------------------
    //Résout le mode de rendu réellement utilisé.
    //
    //nrrmAuto conserve le comportement attendu :
    //- palette style  : rendu plat avec couleurs issues du style ;
    //- palette custom : rendu dégradé historique.
    //
    //Les autres valeurs sont déjà explicites et sont retournées telles quelles.
    //-------------------------------------------------------------------------

    Result := FBarRenderMode;

    If Result <> nrrmAuto Then
        Exit;

    Case FPaletteMode Of
        nrtcmStyle:
            Result := nrrmFlat;
    Else
        Result := nrrmGradient;
    End;
End;

Procedure TNoReflowTabBarCore.SetBarImages(Const Value: TCustomImageList);
Begin
    //Même si l'objet ImageList reste identique, son contenu peut avoir changé
    //après streaming, surtout avec TVirtualImageList.
    //
    //En revanche, si l'objet est identique, il ne faut pas réenregistrer
    //inutilement le ChangeLink. On invalide simplement le layout.
    If FBarImages = Value Then Begin
        InvalidateLayout;
        Exit;
    End;

    //Ancienne ImageList :
    //- suppression de la notification de destruction ;
    //- désabonnement aux changements de contenu.
    If FBarImages <> Nil Then Begin
        FBarImages.RemoveFreeNotification(Self);

        If FBarImagesChangeLink <> Nil Then
            FBarImages.UnRegisterChanges(FBarImagesChangeLink);
    End;

    FBarImages := Value;

    //Nouvelle ImageList :
    //- notification si le composant ImageList est détruit ;
    //- abonnement aux changements de contenu.
    If FBarImages <> Nil Then Begin
        FBarImages.FreeNotification(Self);

        If FBarImagesChangeLink <> Nil Then
            FBarImages.RegisterChanges(FBarImagesChangeLink);
    End;

    //BarImages modifie les métriques, pas seulement le dessin.
    //Il faut donc reconstruire FRenderItems, pas seulement repeindre.
    InvalidateLayout;
End;

Procedure TNoReflowTabBarCore.BarImagesChanged(Sender: TObject);
Begin
    //Réaction standard à toute modification de BarImages.
    //
    //Cas couverts :
    //- TVirtualImageList qui devient réellement disponible après streaming ;
    //- changement de taille d'images ;
    //- changement de collection source ;
    //- ajout/suppression/remplacement d'images ;
    //- modification DPI/style pouvant régénérer les images virtuelles.
    //
    //Les glyphes influencent directement les dimensions des items, donc une
    //simple invalidation visuelle ne suffit pas.
    InvalidateLayout;
End;

Function TNoReflowTabBarCore.ResolveItemText(
    AIndex: Integer;
    AItem: TNoReflowTabBarItem): String;
Begin
    Result := '';

    If AItem = Nil Then
        Exit;

    Result := AItem.Caption;

    If Assigned(FOnGetItemText) Then
        FOnGetItemText(
            Self,
            AIndex,
            AItem,
            Result);
End;

Function TNoReflowTabBarCore.ResolveItemHint(
    AIndex: Integer;
    ATab: TNoReflowTabBarItem;
    Out AHint: String): Boolean;
Var
    LShowHint: Boolean;
Begin
    AHint := '';
    Result := False;

    If ATab = Nil Then
        Exit;

    If Not ATab.ShowHint Then
        Exit;

    If ATab.Hint <> '' Then
        AHint := ATab.Hint
    Else
        AHint := ResolveItemText(
            AIndex,
            ATab);

    LShowHint := AHint <> '';

    If Assigned(FOnGetItemHint) Then
        FOnGetItemHint(
            Self,
            AIndex,
            ATab,
            AHint,
            LShowHint);

    Result := LShowHint And (AHint <> '');
End;

Procedure TNoReflowTabBarCore.MeasureItemText(
    ACanvas: TCanvas;
    AIndex: Integer;
    AItem: TNoReflowTabBarItem;
    ASelectedFont: Boolean;
    Out ATextWidth: Integer;
    Out ATextHeight: Integer);
Var
    LText:    String;
    LWidth:   Integer;
    LHeight:  Integer;
    LHandled: Boolean;
Begin
    ATextWidth := 0;
    ATextHeight := 0;

    If (ACanvas = Nil) Or (AItem = Nil) Then
        Exit;

    LText := ResolveItemText(
        AIndex,
        AItem);

    ATextWidth := ACanvas.TextWidth(LText);
    ATextHeight := ACanvas.TextHeight(LText);

    If Assigned(FOnMeasureItem) Then Begin
        LWidth := ATextWidth;
        LHeight := ATextHeight;
        LHandled := False;

        FOnMeasureItem(
            Self,
            ACanvas,
            AIndex,
            AItem,
            ASelectedFont,
            LWidth,
            LHeight,
            LHandled);

        If LHandled Then Begin
            ATextWidth := Max(
                0,
                LWidth);

            ATextHeight := Max(
                0,
                LHeight);
        End;
    End;
End;

Procedure TNoReflowTabBarCore.DoItemClick(
    AItemIndex: Integer;
    ATab: TNoReflowTabBarItem;
    Button: TMouseButton;
    Shift: TShiftState;
    X, Y: Integer);
Begin
    If Assigned(FOnItemClick) Then
        FOnItemClick(
            Self,
            AItemIndex,
            ATab,
            Button,
            Shift,
            X,
            Y);
End;

Procedure TNoReflowTabBarCore.SyncCheckedStateFromCurrentIndex;
Var
    I:              Integer;
    LExpectedValue: Boolean;
Begin
    //-------------------------------------------------------------------------
    //Synchronise Checked avec FItemIndex lorsque le BarMode impose une sélection
    //exclusive.
    //
    //Important :
    //on n'utilise volontairement PAS FItems.BeginUpdate / FItems.EndUpdate ici.
    //
    //Pourquoi ?
    //Cette méthode peut être appelée depuis ItemsChanged. Or EndUpdate peut
    //déclencher Update, puis ItemsChanged, ce qui provoquerait une récursion
    //infinie et donc un débordement de pile.
    //
    //SetCheckedDirect ne déclenche pas Changed(False), donc aucune mise à jour
    //de collection n'est nécessaire pendant cette synchronisation interne.
    //-------------------------------------------------------------------------

    If Not(FBarMode In [nrbmTabs, nrbmSelectButtons]) Then
        Exit;

    If FItems = Nil Then
        Exit;

    For I := 0 To FItems.Count - 1 Do Begin
        If FItems[I] = Nil Then
            Continue;

        LExpectedValue := I = FItemIndex;

        If FItems[I].Checked <> LExpectedValue Then
            FItems[I].SetCheckedDirect(LExpectedValue);
    End;
End;

Procedure TNoReflowTabBarCore.SetItemCheckedDirect(
    AItemIndex: Integer;
    AChecked: Boolean);
Begin
    //-------------------------------------------------------------------------
    //Cette méthode modifie Checked sans passer par le setter public de l'item.
    //
    //Pourquoi ?
    //Le setter public déclenche la notification de collection. C'est souhaitable
    //pour une modification directe faite par le code utilisateur, mais trop coûteux
    //ici, car cette méthode est utilisée dans les chemins internes du composant.
    //
    //En particulier, lors des changements de BarMode ou en design-time, une cascade
    //de notifications peut provoquer de nombreux recalculs et ralentir fortement
    //l'IDE.
    //
    //La notification fonctionnelle du clic reste assurée au niveau de la barre
    //par ExecuteItemActivation / DoItemClick.
    //-------------------------------------------------------------------------

    If (AItemIndex < 0) Or (AItemIndex >= FItems.Count) Then
        Exit;

    If FItems[AItemIndex] = Nil Then
        Exit;

    If FItems[AItemIndex].Checked = AChecked Then
        Exit;

    FItems[AItemIndex].SetCheckedDirect(AChecked);
End;

Procedure TNoReflowTabBarCore.ToggleItemCheckedByIndex(AItemIndex: Integer);
Begin
    //-------------------------------------------------------------------------
    //Inverse l'état Checked d'un item.
    //
    //Utilisé par nrbmCheckButtons.
    //
    //Important :
    //on ne décoche pas les autres items, car ce mode autorise plusieurs items
    //cochés simultanément.
    //-------------------------------------------------------------------------

    If (AItemIndex < 0) Or (AItemIndex >= FItems.Count) Then
        Exit;

    If FItems[AItemIndex] = Nil Then
        Exit;

    SetItemCheckedDirect(
        AItemIndex,
        Not FItems[AItemIndex].Checked);
End;

Procedure TNoReflowTabBarCore.ApplyItemActivationState(AItemIndex: Integer);
Begin
    //-------------------------------------------------------------------------
    //Applique uniquement le comportement interne associé à un clic validé.
    //
    //Important :
    //cette méthode ne déclenche pas OnItemClick.
    //
    //Elle sert à séparer clairement :
    //- l'état du composant : sélection, Checked, item courant ;
    //- la notification applicative OnItemClick.
    //
    //Cette séparation permet de différer OnItemClick quand un OnItemDblClick
    //est branché, sans rendre l'interface visuellement lente ou incohérente.
    //-------------------------------------------------------------------------

    If Not IsItemSelectable(AItemIndex) Then
        Exit;

    Case FBarMode Of
        nrbmTabs,
        nrbmSelectButtons: Begin
                SetBarCurrentItemIndex(AItemIndex);
            End;

        nrbmPushButtons: Begin
                //Bouton d'action pur.
                //
                //On mémorise quand même le dernier bouton activé afin que
                //l'API publique reste cohérente :
                //- BarCurrentItem ;
                //- BarItemUserId ;
                //- OnChange si l'item courant change.
                SetBarCurrentItemIndex(AItemIndex);
            End;

        nrbmCheckButtons: Begin
                //En mode boutons cochables, l'item courant est mis à jour,
                //puis l'état Checked de l'item cliqué est inversé.
                SetBarCurrentItemIndex(AItemIndex);

                ToggleItemCheckedByIndex(AItemIndex);

                InvalidateLayout;
            End;
    End;
End;

Procedure TNoReflowTabBarCore.ExecuteItemActivation(
    AItemIndex: Integer;
    Button: TMouseButton;
    Shift: TShiftState;
    X, Y: Integer);
Var
    LClickedItem: TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Exécute le comportement fonctionnel associé à un clic validé.
    //
    //Cette méthode conserve le comportement historique complet :
    //1) application de l'état interne du composant ;
    //2) déclenchement de OnItemClick.
    //
    //La séparation avec ApplyItemActivationState permet maintenant à la façade
    //de différer uniquement OnItemClick lorsque le composant doit distinguer
    //simple-clic et double-clic.
    //-------------------------------------------------------------------------

    If Not IsItemSelectable(AItemIndex) Then
        Exit;

    LClickedItem := FItems[AItemIndex];

    ApplyItemActivationState(AItemIndex);

    DoItemClick(
        AItemIndex,
        LClickedItem,
        Button,
        Shift,
        X,
        Y);
End;

Procedure TNoReflowTabBarCore.DoItemDblClick(
    AItemIndex: Integer;
    ATab: TNoReflowTabBarItem;
    Shift: TShiftState;
    X, Y: Integer);
Begin
    If Assigned(FOnItemDblClick) Then
        FOnItemDblClick(
            Self,
            AItemIndex,
            ATab,
            Shift,
            X,
            Y);
End;

Function TNoReflowTabBarCore.GetZoneHeaderCaption(APinZone: TNoReflowTabBarPinZone): String;
Begin
    //-------------------------------------------------------------------------
    //Retourne le libellé de header configuré pour une zone logique donnée.
    //-------------------------------------------------------------------------
    Result := '';

    If FZoneHeader = Nil Then
        Exit;

    Case APinZone Of
        nrtpzStart:
            Result := FZoneHeader.CaptionStart;

        nrtpzCenter:
            Result := FZoneHeader.CaptionCenter;

        nrtpzEnd:
            Result := FZoneHeader.CaptionEnd;
    End;
End;

Function TNoReflowTabBarCore.GetZoneFirstRowCanonicalTop(APinZone: TNoReflowTabBarPinZone): Integer;
Begin
    Result := 0;

    Case APinZone Of
        nrtpzStart:
            If FZoneLayoutInfo.StartZone.HasZone Then
                Result := FZoneLayoutInfo.StartZone.FirstRowCanonicalTop;

        nrtpzCenter:
            If FZoneLayoutInfo.CenterZone.HasZone Then
                Result := FZoneLayoutInfo.CenterZone.FirstRowCanonicalTop;

        nrtpzEnd:
            If FZoneLayoutInfo.EndZone.HasZone Then
                Result := FZoneLayoutInfo.EndZone.FirstRowCanonicalTop;
    End;
End;


//===============================================================================================================================
//TNoReflowTabBarCore  - Interface
//===============================================================================================================================

Procedure TNoReflowTabBarCore.ItemsChanged;
Var
    OldIndex:       Integer;
    NewIndex:       Integer;
    LSelectedIndex: Integer;
Begin
    //-------------------------------------------------------------------------
    //Réagit à toute modification de la collection d’items.
    //
    //Stratégie retenue :
    //1) si l'item sélectionné existe encore, on le retrouve par objet
    //2) sinon on cherche un repli cohérent à partir de l'ancien index
    //3) si rien n'est sélectionnable, on désélectionne
    //
    //Cette approche permet de conserver la sélection sur le même item
    //métier malgré les insertions/suppressions qui décalent les index.
    //-------------------------------------------------------------------------

    If csDestroying In ComponentState Then
        Exit;

    //-------------------------------------------------------------------------
    //Si une normalisation interne est déjà en cours, il ne faut surtout pas
    //relancer immédiatement une nouvelle normalisation.
    //
    //Dans ce cas on se contente de remettre le layout/rendu à jour plus tard.
    //-------------------------------------------------------------------------
    If FNormalizingItemsOrder Then Begin
        InvalidateLayout;
        Exit;
    End;

    NormalizeItemsOrderByZone;

    //-------------------------------------------------------------------------
    //Modes non exclusifs.
    //
    //Dans ces modes, la barre ne doit pas chercher automatiquement un item
    //sélectionnable au démarrage ou après modification de la collection.
    //
    //nrbmPushButtons :
    //- BarCurrentItemIndex représente le dernier bouton cliqué ;
    //- au démarrage, aucun bouton n'a encore été cliqué.
    //
    //nrbmCheckButtons :
    //- BarCurrentItemIndex représente le dernier bouton activé ;
    //- les états actifs réels sont portés par Checked ;
    //- au démarrage, aucun bouton n'a encore été activé par l'utilisateur.
    //-------------------------------------------------------------------------
    If FBarMode In [nrbmPushButtons, nrbmCheckButtons] Then Begin
        If (FItemIndex < 0) Or (FItemIndex >= FItems.Count) Or Not IsItemSelectable(FItemIndex) Then Begin
            FItemIndex := -1;
            FSelectedItemRef := Nil;
        End Else Begin
            FSelectedItemRef := FItems[FItemIndex];
        End;

        InvalidateLayout;

        If csDesigning In ComponentState Then
            Repaint;

        Exit;
    End;

    OldIndex := FItemIndex;
    NewIndex := -1;

    //-------------------------------------------------------------------------
    //Priorité absolue :
    //si l'item sélectionné existe encore, on conserve cet objet métier.
    //-------------------------------------------------------------------------
    If FSelectedItemRef <> Nil Then Begin
        LSelectedIndex := IndexOfItem(FSelectedItemRef);
        If (LSelectedIndex >= 0) And IsItemSelectable(LSelectedIndex) Then
            NewIndex := LSelectedIndex;
    End;

    //-------------------------------------------------------------------------
    //Si l'ancien item n'existe plus ou n'est plus sélectionnable,
    //on retombe sur une stratégie de voisinage cohérente.
    //-------------------------------------------------------------------------
    If NewIndex < 0 Then Begin
        If FItems.Count = 0 Then
            NewIndex := -1
        Else Begin
            //Recale d'abord l'ancien index dans les bornes plausibles.
            If OldIndex >= FItems.Count Then
                OldIndex := FItems.Count - 1;

            If OldIndex < 0 Then
                OldIndex := 0;

            //1) essayer à l'ancien emplacement logique
            If IsItemSelectable(OldIndex) Then
                NewIndex := OldIndex;

            //2) sinon regarder vers la gauche / avant
            If NewIndex < 0 Then
                NewIndex := FindPreviousSelectableTab(OldIndex - 1);

            //3) sinon vers la droite / après
            If NewIndex < 0 Then
                NewIndex := FindNextSelectableItem(OldIndex);

            //4) dernier filet de sécurité : depuis le début
            If NewIndex < 0 Then
                NewIndex := FindNextSelectableItem(0);
        End;
    End;

    If NewIndex < -1 Then
        NewIndex := -1;

    //-------------------------------------------------------------------------
    //Si l'objet sélectionné change réellement, on passe par ApplyItemIndex.
    //Si seul l'index bouge pour retrouver le même objet, aucun événement
    //métier ne doit être émis, mais l'état interne doit être resynchronisé.
    //-------------------------------------------------------------------------
    If GetBarCurrentItem <> Nil Then Begin
        If (NewIndex >= 0) And (NewIndex < FItems.Count) And (FItems[NewIndex] = GetBarCurrentItem) Then Begin
            FItemIndex := NewIndex;
            FSelectedItemRef := FItems[NewIndex];

            //Même si l'objet sélectionné n'a pas changé, son index réel peut
            //avoir changé après insertion, suppression ou normalisation.
            //
            //On resynchronise donc Checked pour les modes exclusifs.
            SyncCheckedStateFromCurrentIndex;

            InvalidateLayout;
            Exit;
        End;
    End;

    ApplyItemIndex(
        NewIndex,
        True);

    If csDesigning In ComponentState Then
        Repaint;
End;

Procedure TNoReflowTabBarCore.InvalidateLayout;
Begin
    //-------------------------------------------------------------------------
    //Invalidation "forte" du composant.
    //
    //À utiliser lorsqu’un changement impacte potentiellement :
    //- les métriques internes d’un item
    //- le placement ligne / colonne
    //- les contours polygonaux
    //- la taille physique de la barre elle-même
    //
    //Séquence choisie :
    //1) marquer FRenderItems comme obsolète
    //2) recalculer l’encombrement de la barre
    //3) demander le repaint
    //-------------------------------------------------------------------------

    InvalidateRenderInfo;
    RelayoutItems;
    Invalidate;
End;

Procedure TNoReflowTabBarCore.SelectedItemReferenceRemoved(ATab: TNoReflowTabBarItem);
Begin
    //-------------------------------------------------------------------------
    //Invalide la référence stable de sélection lorsqu'un item sélectionné
    //est effectivement en cours de destruction.
    //-------------------------------------------------------------------------

    If FSelectedItemRef = ATab Then
        FSelectedItemRef := Nil;
End;

Function TNoReflowTabBarCore.FindSignalDefByCode(ACode: Integer): TNoReflowTabBarSignalDef;
Begin
    Result := Nil;

    If FSignals <> Nil Then
        Result := FSignals.FindByCode(ACode);
End;

Function TNoReflowTabBarCore.FindSignalDefByName(Const AName: String): TNoReflowTabBarSignalDef;
Begin
    Result := Nil;

    If FSignals <> Nil Then
        Result := FSignals.FindByName(AName);
End;

Function TNoReflowTabBarCore.IsHostLoading: Boolean;
Begin
    Result := (csLoading In ComponentState) Or (csReading In ComponentState);
End;

Procedure TNoReflowTabBarCore.MoveItemToZone(
    ATab: TNoReflowTabBarItem;
    ANewPinZone: TNoReflowTabBarPinZone;
    ANewZoneIndex: Integer);
Var
    LZoneItems:    TList<TNoReflowTabBarItem>;
    I:             Integer;
    LNewZoneIndex: Integer;
Begin
    //-------------------------------------------------------------------------
    //Déplace un item vers une autre zone logique.
    //
    //La source de vérité reste :
    //- PinZone
    //- ZoneIndex
    //
    //Comme pour MoveItemInZone, il ne faut pas seulement modifier l'item
    //déplacé isolément, sinon on laisse des doublons ou des trous dans la
    //numérotation logique de la zone cible.
    //
    //La bonne stratégie est donc :
    //1) reconstruire la liste complète de la zone cible
    //2) y insérer l'item à la position logique demandée
    //3) réattribuer à toute la zone cible des couples cohérents
    //PinZone / ZoneIndex
    //4) normaliser enfin l'ordre physique global FItems
    //
    //Remarque :
    //les anciennes zones seront elles aussi compactées indirectement
    //par NormalizeItemsOrderByZone puis RebuildStoredZoneIndexes.
    //-------------------------------------------------------------------------

    If ATab = Nil Then
        Exit;

    If ATab.Collection <> FItems Then
        Exit;

    If ANewPinZone = nrtpzNone Then
        ANewPinZone := nrtpzCenter;

    LZoneItems := TList<TNoReflowTabBarItem>.Create;
    Try
        FItems.BeginUpdate;
        Try
            //Construit la liste actuelle de la zone cible,
            //sans l'item déplacé.
            For I := 0 To FItems.Count - 1 Do
                If (FItems[I] <> ATab) And (FItems[I].PinZone = ANewPinZone) Then
                    LZoneItems.Add(FItems[I]);

            LNewZoneIndex := ANewZoneIndex;

            If LNewZoneIndex < 0 Then
                LNewZoneIndex := 0;

            If LNewZoneIndex > LZoneItems.Count Then
                LNewZoneIndex := LZoneItems.Count;

            //Insère l'item à sa nouvelle position logique.
            LZoneItems.Insert(
                LNewZoneIndex,
                ATab);

            //Réattribue des couples cohérents zone/index à toute la zone cible.
            For I := 0 To LZoneItems.Count - 1 Do
                LZoneItems[I].SetZonePlacementDirect(
                    ANewPinZone,
                    I);

            //Projette ensuite l'ordre logique global dans FItems.
            NormalizeItemsOrderByZone;
        Finally
            FItems.EndUpdate;
        End;

        ItemsChanged;
    Finally
        LZoneItems.Free;
    End;
End;

Function TNoReflowTabBarCore.GetItemsCountInZoneInternal(APinZone: TNoReflowTabBarPinZone): Integer;
Var
    I: Integer;
Begin
    //-------------------------------------------------------------------------
    //Compte le nombre d'items appartenant à une zone donnée.
    //-------------------------------------------------------------------------

    Result := 0;

    For I := 0 To FItems.Count - 1 Do
        If FItems[I].PinZone = APinZone Then
            Inc(Result);
End;

Function TNoReflowTabBarCore.GetItemsCountInZone(APinZone: TNoReflowTabBarPinZone): Integer;
Begin
    //-------------------------------------------------------------------------
    //Variante publique du comptage d'items par zone.
    //-------------------------------------------------------------------------

    Result := GetItemsCountInZoneInternal(APinZone);
End;

Procedure TNoReflowTabBarCore.NormalizeItemsOrderByZone;
Var
    LOrdered:    TList<TNoReflowTabBarItem>;
    I:           Integer;
    LTargetItem: TNoReflowTabBarItem;

    Procedure AppendZoneSorted(APinZone: TNoReflowTabBarPinZone);
    Var
        LZoneItems: TList<TNoReflowTabBarItem>;
        J:          Integer;
        K:          Integer;
        LCurrent:   TNoReflowTabBarItem;
    Begin
        LZoneItems := TList<TNoReflowTabBarItem>.Create;
        Try
            For J := 0 To FItems.Count - 1 Do
                If FItems[J].PinZone = APinZone Then
                    LZoneItems.Add(FItems[J]);

            //Tri stable explicite sur ZoneIndex puis Index courant.
            For J := 1 To LZoneItems.Count - 1 Do Begin
                LCurrent := LZoneItems[J];
                K := J - 1;

                While (K >= 0) And (CompareItemsForZoneOrder(LZoneItems[K], LCurrent) > 0) Do Begin
                    LZoneItems[K + 1] := LZoneItems[K];
                    Dec(K);
                End;

                LZoneItems[K + 1] := LCurrent;
            End;

            For J := 0 To LZoneItems.Count - 1 Do
                LOrdered.Add(LZoneItems[J]);
        Finally
            LZoneItems.Free;
        End;
    End;

Begin
    //Important :
    //FItems reste la collection physique réellement streamée par Delphi,
    //mais son ordre n'est plus libre.
    //Il est projeté à partir de deux informations métier :
    //- PinZone
    //- ZoneIndex
    //
    //Cette méthode est donc le point central de synchronisation
    //entre ordre logique et ordre physique.

    If FItems = Nil Then
        Exit;

    If FItems.Count <= 1 Then
        Exit;

    If FNormalizingItemsOrder Then
        Exit;

    FNormalizingItemsOrder := True;
    Try
        LOrdered := TList<TNoReflowTabBarItem>.Create;
        Try
            AppendZoneSorted(nrtpzStart);
            AppendZoneSorted(nrtpzCenter);
            AppendZoneSorted(nrtpzEnd);

            If LOrdered.Count <> FItems.Count Then
                Exit;

            FItems.BeginUpdate;
            Try
                //Projection sûre :
                //à chaque position I, on amène explicitement le bon item.
                For I := 0 To LOrdered.Count - 1 Do Begin
                    LTargetItem := LOrdered[I];

                    If LTargetItem.Index <> I Then
                        MoveCollectionItem(
                            LTargetItem.Index,
                            I);
                End;

                RebuildStoredZoneIndexes;
            Finally
                FItems.EndUpdate;
            End;
        Finally
            LOrdered.Free;
        End;
    Finally
        FNormalizingItemsOrder := False;
    End;
End;

End.

