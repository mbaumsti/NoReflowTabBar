Unit NoReflowTabBar;

{
  NoReflowTabBar.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Main public facade of the NoReflowTabBar VCL component.

  Repository:
  https://github.com/mbaumsti/NoReflowTabBar

  License:
  See LICENSE file.

  ------------------------------------------------------------------------------

  Façade finale publiée du composant NoReflowTabBar.

  Cette unité fournit :
  - TNoReflowTabBar : contrôle final exposé à l'utilisateur et au design-time.

  Rôle de cette unité :
  - publier l'API finale du composant ;
  - exposer les propriétés design-time ;
  - gérer les messages VCL liés au contrôle visuel ;
  - finaliser la peinture complète de la barre ;
  - proposer des helpers publics sans exposer les structures internes.

  Ce que cette unité ajoute par rapport à NoReflowTabBar_Core :
  - les propriétés published visibles dans l'inspecteur d'objets ;
  - les messages VCL :
  - changement de couleur ;
  - changement de style ;
  - changement de police ;
  - gestion souris et clavier ;
  - la peinture finale et le marqueur de drag ;
  - quelques helpers publics de façade.

  Pipeline interne du composant :
  1) BarItems contient les données métier.
  2) RebuildRenderInfo construit FRenderItems.
  3) Chaque render item reçoit ses métriques, bounds et polygones.
  4) Paint dessine la barre à partir de FRenderItems.
  5) ItemAtPos réutilise les polygones calculés pour le hit-test.

  Fonctionnalités principales du composant :
  - affichage d'onglets ou de boutons multi-lignes avec recouvrement ;
  - stabilité visuelle du layout lors du changement de sélection ;
  - gestion des états normal, hot, selected, pressed, checked et disabled ;
  - palette custom ou dérivée du style VCL actif ;
  - gestion de voyants colorés optionnels ;
  - manipulation des items par index, par objet ou par ItemUserId ;
  - support des zones logiques Start / Center / End ;
  - support du drag interne, inter-zones et inter-barres ;
  - peinture finale et marqueur de drag ;
  - support des hints via NoReflowTabBar_HintSupport.

  Remarques :
  - cette unité constitue le point d'entrée normal pour utiliser le composant ;
  - la majorité de la mécanique interne reste volontairement dans
  NoReflowTabBar_Core ;
  - la séparation entre façade publiée et moteur facilite la maintenance,
  le refactoring et l'extension future du composant.
}

Interface

Uses
    Winapi.Windows,
    Winapi.Messages,
    System.Classes,
    System.SysUtils,
    Vcl.Controls,
    Vcl.Graphics,
    Vcl.Forms,
    Vcl.ImgList,
    Vcl.ExtCtrls,
    NoReflowTabBar_CommonTypes,
    NoreflowTabBar_Library,
    NoReflowtabBar_EventsTypes,
    NoReflowTabBar_Core,
    NoReflowTabBar_Items,
    NoReflowTabBar_AppearanceAndLayout,
    NoReflowTabBar_ZoneHeader,
    NoReflowTabBar_StorageSupport,
    NoReflowTabBar_DragSupport,
    NoReflowTabBar_ZoneLayout;

Type

    //Contrôle principal affichant et pilotant l'ensemble des items.
    //
    //Pipeline interne :
    //1) FItems contient les données métier
    //2) RebuildRenderInfo construit FRenderItems
    //3) chaque render item reçoit ses métriques, bounds et polygones
    //4) Paint dessine la barre à partir de FRenderItems
    //5) ItemAtPos réutilise les polygones calculés pour le hit-test
    //
    //En pratique, FRenderItems est la représentation intermédiaire centrale
    //entre les données métier et le rendu.
    TNoReflowTabBar = Class(TNoReflowTabBarStorageSupport)
    private
        //-----------------------------------------------------------------
        //Suivi du clic souris métier
        //-----------------------------------------------------------------

        FMouseDownItemIndex: Integer;
        FMouseDownPos:       TPoint;
        FMouseDownButton:    TMouseButton;

        //Indique que le double-clic courant a déjà consommé l'action souris.
        //
        //Le MouseUp final du double-clic ne doit alors pas déclencher OnItemClick.
        FSuppressNextMouseUpClick: Boolean;

        //-----------------------------------------------------------------
        //Temporisation interne du clic item
        //-----------------------------------------------------------------

        //Timer interne utilisé uniquement lorsqu'un OnItemDblClick est branché.
        //
        //Dans ce cas, OnItemClick est différé pendant le délai système de
        //double-clic. Si un vrai double-clic arrive, le clic en attente est
        //annulé par DblClick.
        FDelayedItemClickTimer:  TTimer;
        FDelayedItemClickIndex:  Integer;
        FDelayedItemClickKey:    Integer;
        FDelayedItemClickButton: TMouseButton;
        FDelayedItemClickShift:  TShiftState;
        FDelayedItemClickPos:    TPoint;

        //Annule le clic item actuellement en attente.
        Procedure CancelDelayedItemClick;

        //Programme le déclenchement différé de OnItemClick.
        Procedure ScheduleDelayedItemClick(
            AItemIndex: Integer;
            Button: TMouseButton;
            Shift: TShiftState;
            X, Y: Integer);

        //Déclenche réellement le OnItemClick différé si l'item est encore valide.
        Procedure ExecuteDelayedItemClick;

        //Gestionnaire du timer interne de clic différé.
        Procedure DelayedItemClickTimer(Sender: TObject);

        //-----------------------------------------------------------------
        //Trace / diagnostic
        //-----------------------------------------------------------------

        //Active les traces de diagnostic du composant.
        Procedure DebugTrace(Const AMsg: String);

        //Retourne une description courte d'un item pour les traces.
        Function DebugItemLabel(AIndex: Integer): String;

        //-----------------------------------------------------------------
        //Gestion des voyants
        //-----------------------------------------------------------------

        //Recopie une collection de dfinitions de voyants dans la collection interne.
        Procedure SetSignals(Const Value: TNoReflowTabBarSignalDefs);

        //-----------------------------------------------------------------
        //Messages VCL
        //-----------------------------------------------------------------

        //Réagit à un changement de couleur du contrôle.
        Procedure CMColorChanged(Var Message: TMessage); message CM_COLORCHANGED;

        //Réagit à un changement de style VCL.
        Procedure CMStyleChanged(Var Message: TMessage); message CM_STYLECHANGED;

        //Réagit à un changement direct de police.
        Procedure CMFontChanged(Var Message: TMessage); message CM_FONTCHANGED;

        //Réagit à un changement de police héritée du parent.
        Procedure CMParentFontChanged(Var Message: TMessage); message CM_PARENTFONTCHANGED;

        //Réagit à la sortie de la souris du contrôle.
        Procedure CMMouseLeave(Var Message: TMessage); message CM_MOUSELEAVE;

        //Demande la réception des touches clavier utiles à la navigation.
        Procedure WMGetDlgCode(Var Message: TWMGetDlgCode); message WM_GETDLGCODE;

    protected
        //Finalise l'état du composant après chargement.
        Procedure Loaded; override;

        //Retourne la couleur du marqueur d'insertion de drag.
        Function GetDragInsertMarkerColor: TColor;

        //Dessine le marqueur d'insertion du drag :
        //trait + petite flèche orientée vers la zone d'insertion.
        Procedure DrawDragInsertMarker(ACanvas: TCanvas);

        //Peinture complète de la barre.
        //Les items non sélectionnés sont peints d'abord selon l'ordre
        //de recouvrement, puis l'item sélectionné est peint en dernier.
        Procedure Paint; override;

        //Réagit à un redimensionnement du contrôle.
        Procedure Resize; override;

        //Met à jour l'item survolé en fonction de la souris.
        Procedure MouseMove(
            Shift: TShiftState;
            X, Y: Integer); override;

        //Gère la sélection d'un item au clic.
        Procedure MouseDown(
            Button: TMouseButton;
            Shift: TShiftState;
            X, Y: Integer); override;

        Procedure MouseUp(
            Button: TMouseButton;
            Shift: TShiftState;
            X, Y: Integer); override;

        //Gère la navigation clavier entre les items.
        Procedure KeyDown(
            Var Key: Word;
            Shift: TShiftState); override;

        //Réagit à l'obtention du focus clavier.
        Procedure DoEnter; override;

        //Réagit à la perte du focus clavier.
        Procedure DoExit; override;

        //Gère le double-clic métier sur un item.
        Procedure DblClick; override;

    public
        Constructor Create(AOwner: TComponent); override;
        Destructor Destroy; override;

        //Retourne le contour polygonal actuellement calcul pour un item.
        //
        //Ce helper permet à un code externe de récupérer le bord réel de la
        //rgion d'un item sans dépendre directement de la structure interne
        //FRenderItems.
        //
        //Si l'index n'est pas valide, un tableau vide est renvoy.
        Function GetItemRegionPoints(AAbsoluteItemIndex: Integer): TArray<TPoint>;

        //Retourne les métriques actuellement calculées pour un item.
        //
        //Ces métriques décrivent l'implantation interne du texte et du voyant.
        //Si l'index n'est pas valide, la fonction renvoie False et AMetrics est
        //remis à zéro.
        Function TryGetItemMetrics(
            AAbsoluteItemIndex: Integer;
            Out AMetrics: TNoReflowTabBarItemMetrics): Boolean;

        //Retourne le texte réellement affiché pour un item.
        //
        //Cette méthode applique la même logique que le pipeline interne :
        //- Caption de l'item
        //- puis OnGetItemText si un handler est affecté
        //
        //Elle permet au code applicatif, notamment dans OnPaintItem, de
        //récupérer le libellé final sans dupliquer la logique du composant.
        Function GetItemDisplayText(AAbsoluteItemIndex: Integer): String;

        //Exécute le rendu standard complet d'un item à partir de son index.
        //
        //Cette méthode sert principalement aux handlers OnPaintItem qui veulent
        //prendre la main sur un item tout en pouvant réutiliser le rendu
        //standard du composant sans dépendre de TNoReflowTabBarRenderItem.
        //Si l'index est invalide ou si l'item n'est pas visible, la
        //méthode ne fait rien.
        Procedure DefaultPaintItemByIndex(
            AAbsoluteItemIndex: Integer;
            AVisualState: TNoReflowTabBarItemVisualState);

        //Accès pratique au nombre d'items par zone.
        Property ZoneItemsCount[APinZone: TNoReflowTabBarPinZone]: Integer Read GetItemsCountInZone;

        //Retourne l'item courant principal.
        //
        //Selon BarMode :
        //- nrbmItems          : item sélectionné ;
        //- nrbmSelectButtons : bouton sélectionné ;
        //- nrbmCheckButtons  : dernier bouton courant / dernier activé ;
        //- nrbmPushButtons   : item courant éventuel, sans état sélectionné
        //persistant.
        //
        //Pour obtenir tous les items actifs dans le mode courant, utiliser
        //SelectedItems.
        Property BarCurrentItem: TNoReflowTabBarItem Read GetBarCurrentItem;

        //Retourne les items considérés comme sélectionnés ou actifs selon
        //le mode fonctionnel courant de la barre.
        //
        //- nrbmItems :
        //retourne l'item courant si un item est sélectionné.
        //
        //- nrbmSelectButtons :
        //retourne le bouton sélectionné si un bouton est sélectionné.
        //
        //- nrbmCheckButtons :
        //retourne tous les boutons cochés.
        //
        //- nrbmPushButtons :
        //retourne un tableau vide, car un bouton push ne porte pas d'état
        //sélectionné persistant.
        Function GetBarSelectedItems: TArray<TNoReflowTabBarItem>;

        //Retourne le nombre d'items sélectionnés ou actifs selon le mode courant.
        Function GetBarSelectedCount: Integer;

        //Retourne True si au moins un item est sélectionné ou actif.
        Function HasBarSelectedItems: Boolean;

        //Retourne tous les items cochés, indépendamment du BarMode.
        //
        //Cette méthode est plus explicite que SelectedItems lorsque le code
        //appelant veut réellement interroger l'état Checked porté par les items.
        Function GetBarCheckedItems: TArray<TNoReflowTabBarItem>;

        //Retourne le nombre d'items Checked=True.
        Function GetBarCheckedCount: Integer;

        //Décoche tous les items.
        //
        //Utile surtout en mode nrbmCheckButtons.
        //En mode nrbmTabs / nrbmSelectButtons, un prochain changement de
        //BarCurrentItemIndex resynchronisera l'état exclusif.
        Procedure ClearBarCheckedItems;

        //Retourne l'état Checked d'un item par index absolu.
        Function IsBarItemChecked(AAbsoluteItemIndex: Integer): Boolean;

        //Affecte l'état Checked d'un item par index absolu.
        //
        //En nrbmCheckButtons, c'est l'API normale pour cocher/décocher un item.
        //En nrbmTabs / nrbmSelectButtons, il vaut mieux utiliser BarCurrentItemIndex,
        //car ces modes imposent normalement une sélection exclusive.
        Procedure SetBarItemChecked(
            AIndex: Integer;
            AChecked: Boolean);

        //Inverse l'état Checked d'un item par index absolu.
        Procedure ToggleBarItemChecked(AIndex: Integer);

        //Accès pluriel aux items actifs selon BarMode.
        Property BarSelectedItems: TArray<TNoReflowTabBarItem> Read GetBarSelectedItems;

        //Nombre d'items actifs selon BarMode.
        Property BarSelectedCount: Integer Read GetBarSelectedCount;

        //Accès explicite aux items Checked=True.
        Property BarCheckedItems: TArray<TNoReflowTabBarItem> Read GetBarCheckedItems;

        //Nombre d'items Checked=True.
        Property BarCheckedCount: Integer Read GetBarCheckedCount;

        //Accès indexé à la visibilitéé via identifiant métier.
        Property FirstItemVisibleByUserId[AItemUserId: Integer]: Boolean Read IsItemVisible Write SetItemVisible;

        //Retourne le Id de l'item courant principal.
        //
        //Renvoie 0 si aucun item courant n'est défini.
        Property BarItemUserId: Integer Read GetBarItemUserId;

        //Retourne l'index de l'item situé sous un point client.
        //
        //Cette méthode expose publiquement le hit-test interne du composant.
        //Le test utilisée le polygone réel de l'item, et non son simple
        //rectangle englobant. Il respecte donc les formes inclinées,
        //recouvrements, coins arrondis et layouts multi-lignes.
        //
        //Retourne -1 si aucun item n'est trouvé.
        Function ItemAtPos(Const P: TPoint): Integer; reintroduce;

    published
        //Sous-objet contenant toutes les couleurs custom du composant.
        Property BarAppearance: TNoReflowTabBarAppearance Read FAppearance Write SetAppearance;

        //Détermine si les couleurs proviennent de BarAppearance
        //ou du style VCL actif.
        Property BarPaletteMode: TNoReflowTabBarPaletteMode Read FPaletteMode Write SetPaletteMode default nrtcmCustom;

        //Détermine la stratégie de rendu commune aux onglets et aux boutons.
        //
        //- nrrmAuto :
        //choix automatique selon BarPaletteMode.
        //
        //- nrrmFlat :
        //rendu maison plat.
        //Les couleurs viennent de BarPaletteMode.
        //
        //- nrrmGradient :
        //rendu maison dégradé.
        //Les couleurs viennent de BarPaletteMode.
        Property BarRenderMode: TNoReflowTabBarRenderMode Read FBarRenderMode Write SetBarRenderMode default nrrmAuto;

        //Mode fonctionnel global de la barre.
        //
        //Ce mode exprime l'intention principale du composant :
        //- nrbmTabs          : barre d'onglets classique ;
        //- nrbmPushButtons   : boutons d'action sans sélection persistante ;
        //- nrbmSelectButtons : boutons avec sélection unique ;
        //- nrbmCheckButtons  : boutons cochables indépendants.
        //
        Property BarMode: TNoReflowTabBarMode Read FBarMode Write SetBarMode default nrbmTabs;

        //Choisit le moteur de placement utilisé par la barre.
        //
        //- nrtlmSequential :
        //placement séquentiel historique, avec séparation simple par zones.
        //
        //- nrtlmByZones :
        //placement par zones Start / Center / End, avec calcul canonique
        //commun aux orientations Top / Bottom / Left / Right.
        Property BarLayoutMode: TNoReflowTabBarLayoutMode Read FLayoutMode Write SetLayoutMode default nrblmByZones;

        //Ordre logique présenté au moteur de layout par zones.
        //
        //Cette propriété ne modifie pas l'ordre physique des items dans la
        //collection et ne modifie pas les transformations géométriques.
        //
        //Elle sert uniquement à changer l'ordre dans lequel le layout parcourt
        //les zones et, selon le mode choisi, les items dans chaque zone.
        //
        //Modes :
        //- nrtfoNormal :
        //Start -> Center -> End, items dans leur ordre naturel.
        //
        //- nrtfoReverseZones :
        //End -> Center -> Start, items dans leur ordre naturel.
        //
        //- nrtfoReverseZonesAndItems :
        //End -> Center -> Start, items inversés dans chaque zone.
        Property BarFlowOrder: TNoReflowTabBarFlowOrder Read FFlowOrder Write SetFlowOrder default nrtfoNormal;

        //Détermine si l'utilisateur peut réordonner les items par drag souris.
        //
        //- nrttrmNone         : aucun réordonnancement
        //- nrttrmSameZoneOnly : réordonnancement uniquement dans la zone de départ
        //- nrttrmAllZones     : réordonnancement complet, y compris changement de zone
        Property BarDragReorderMode: TNoReflowTabBarDragReorderMode Read FItemsReorderMode Write SetItemsReorderMode default nrbrmNone;

        //Détermine quelles zones acceptent le réordonnancement par drag.
        //
        //Cette propriété complète BarDragReorderMode :
        //- si BarDragReorderMode = nrttrmNone, aucun drag n'est possible
        //- sinon, seules les zones cochées peuvent servir de source et de cible
        //
        //Par défaut, les trois zones acceptent le drag.
        Property BarDragReorderZones: TNoReflowTabBarZones Read FItemsReorderZones Write SetItemsReorderZones default [nrtzStart, nrtzCenter, nrtzEnd];

        //Mode de dialogue drag/drop avec les autres barres.
        //
        //Cette propriété ne concerne que le drag inter-barres. Le drag interne
        //reste piloté par BarDragReorderMode et BarDragReorderZones.
        Property BarDragInterBarMode: TNoReflowTabBarDragInterBarMode Read FItemsInterBarMode Write FItemsInterBarMode default nrtbimNone;

        //Groupe logique de dialogue entre barres.
        //
        //Le drag inter-barres automatique n'est autorisé que si la barre source
        //et la barre cible portent exactement le même groupe. La chaîne vide est
        //le groupe par défaut.
        Property BarDragInterBarGroup: String Read FItemsInterBarGroup Write FItemsInterBarGroup;

        //Active ou désactive l'édition directe du texte des items.
        //
        //Quand cette propriété vaut True, l'utilisateur peut renommer
        //un item autorisé :
        //- par double-clic ;
        //- par F2 sur l'item sélectionné.
        //
        //La validation se fait par Entrée ou perte de focus.
        //L'annulation se fait par Échap.
        Property BarEditEnabled: Boolean Read FItemsEditEnabled Write SetItemsEditEnabled default False;

        //Détermine quelles zones autorisent l'édition directe du texte.
        //
        //Cette propriété est indépendante de BarItemsReorderZones.
        //Une zone peut donc être déplaçable sans être renommable,
        //ou renommable sans être déplaçable.
        Property BarEditZones: TNoReflowTabBarEditZones Read FItemEditZones Write SetItemEditZones default [nrtezStart, nrtezCenter, nrtezEnd];

        //Collection des voyants disponibles pour les items.
        //
        //Cette collection est préremplie avec les 4 voyants historiques
        //du composant, mais l'utilisateur peut la compléter librement.
        Property BarSignals: TNoReflowTabBarSignalDefs Read FSignals Write SetSignals;

        //Sous-objet contenant les espacements communs aux onglets et aux  boutons.
        //
        //Ce layout regroupe uniquement ce qui décrit le contenu et le placement :
        //- marges générales ;
        //- espacements entre zones ;
        //- espacements entre lignes ou colonnes ;
        //- espaces autour du texte ;
        //- voyant ;
        //- glyph.
        //
        //Il ne contient pas la forme propre des items :
        //les slants, rayons et recouvrements sont maintenant dans BarLayoutTabs.
        Property BarLayout: TNoReflowTabBarLayout Read FLayout Write SetLayout;

        //Sous-objet contenant la géométrie spécifique au mode onglets.
        //
        //Ce layout regroupe les propriétés qui n'ont de sens que pour le rendu
        //classique en onglets :
        //- éégalisation de longueur ;
        //- éégalisation d'éépaisseur ;
        //- recouvrement entre onglets ;
        //- slants ;
        //- rayons de forme.
        //
        //Cette séparation évite de polluer le mode boutons avec des
        //notions propres aux onglets, comme le recouvrement ou les pentes.
        Property BarLayoutTabs: TNoReflowTabBarLayoutTabs Read FLayoutTabs Write SetLayoutTabs;

        //Sous-objet contenant la géométrie spécifique au mode boutons.
        //
        //Ce layout est prévu pour le mode boutons :
        //- largeur force optionnelle ;
        //- hauteur force optionnelle ;
        //- espacement entre boutons ;
        //- rayon de bouton ;
        //
        Property BarLayoutButtons: TNoReflowTabBarLayoutButtons Read FLayoutButtons Write SetLayoutButtons;

        //ImageList globale utilisée comme source d'images pour les items.
        //
        //Cette ImageList est utilisée lorsqu'un item ne possède pas de Glyph
        //local exploitable, mais possède un GlyphIndex valide.
        //
        //Ordre de priorité prévu pour le rendu :
        //1) Glyph local de l'item ;
        //2) BarImages + GlyphIndex ;
        //3) éventuellement plus tard GlyphName ou événement dédié.
        //
        //Le composant ne devient pas propriétaire de cette ImageList.
        //Elle peut donc être partagée avec d'autres contrôles VCL.
        Property BarImages: TCustomImageList Read FBarImages Write SetBarImages;

        //Sous-objet contenant la configuration du header décoratif des zones.
        Property BarZoneHeader: TNoReflowTabBarZoneHeader Read FZoneHeader Write SetZoneHeader;

        //Détermine l'orientation visuelle interne de la barre.
        //
        //Cette propriété est indépendante de Align.
        //
        //- Align contrôle la position VCL du contrôle dans son parent
        //- BarPosition contrôle le sens du layout, la géométrie des items
        //et l'orientation automatique du texte
        //
        //Cette dissociation permet des combinaisons libres entre
        //le positionnement VCL du contrôle et l'orientation visuelle des items.
        Property BarPosition: TNoReflowTabBarPosition Read FBarPosition Write SetBarPosition default nrtbpTop;

        //Position logique du voyant : avant le texte, après le texte ou au bout utile de l’item.
        Property BarSignalPosition: TNoReflowTabBarSignalPosition Read FSignalPosition Write SetSignalPosition default nrtspBefore;

        //Collection des items métier gérés par la barre.
        //
        //La collection reste physiquement ordonnée selon les trois zones réelles :
        //- Start
        //- Center
        //- End
        //
        //Pour le code applicatif, les helpers Add*/Insert*/Clear*/Move*
        //restent l'API recommandée, car ils expriment directement
        //l'intention métier et respectent naturéellement cette organisation.
        Property BarItems: TNoReflowTabBarItems Read FItems Write SetItems;

        //Index absolu de l'item courant.
        //
        //Selon BarMode :
        //- nrbmTabs : item sélectionné ;
        //- nrbmSelectButtons : bouton sélectionné ;
        //- nrbmCheckButtons : dernier item courant ou dernier item activé ;
        //- nrbmPushButtons : dernier item activé, sans état persistant.
        Property BarCurrentItemIndex: Integer Read FItemIndex Write SetBarCurrentItemIndex default -1;

        //Orientation du texte ; nrttoAuto délègue le choix à la position de barre.
        Property BarTextOrientation: TNoReflowTabBarTextOrientation Read FTextOrientation Write SetTextOrientation default nrttoAuto;

        //Active le dessin d'un focus visuel sur l'item courant.
        //
        //Selon le mode :
        //- nrbmTabs / nrbmSelectButtons : item sélectionné ;
        //- nrbmPushButtons / nrbmCheckButtons : item courant de navigation
        // / dernier item activé.
        Property BarShowFocus: Boolean Read FShowFocus Write SetShowFocus default True;

        //Style de police supplémentaire appliqué à l'item sélectionné.
        Property BarActiveFontStyle: TFontStyles Read FSelectedFontStyle Write SetSelectedFontStyle default [fsBold];

        //Propriétés VCL standard.
        Property Align;
        Property AlignWithMargins;
        Property Anchors;
        Property Color default clBtnFace;
        Property Constraints;
        Property Cursor;
        Property DockSite;
        Property DoubleBuffered;
        Property DragCursor;
        Property DragKind;
        Property DragMode;
        Property Enabled;
        Property Font;
        Property HelpContext;
        Property HelpKeyword;
        Property HelpType;
        Property Hint;
        Property Margins;
        Property Padding;
        Property ParentColor default False;
        Property ParentDoubleBuffered;
        Property ParentFont;
        Property ParentShowHint;
        Property PopupMenu;
        Property ShowHint;
        Property StyleElements;
        Property TabOrder;
        Property TabStop default True;
        Property Touch;
        Property Visible;

        //Événements.
        //événement déclenché juste avant un changement de sélection.
        //
        //Le handler reçoit directement l'ancien item et le nouvel item.
        //Il peut refuser la transition en positionnant Allow à False.
        Property OnChanging: TNoReflowTabBarChangingEvent Read FOnChanging Write FOnChanging;

        //Événement déclenché après application effective d'une nouvelle sélection.
        //
        //Le handler reçoit directement l'ancien item et le nouvel item.
        Property OnChange: TNoReflowTabBarChangeEvent Read FOnChange Write FOnChange;

        Property OnItemClick:    TNoReflowTabBarClickEvent Read FOnItemClick Write FOnItemClick;
        Property OnItemDblClick: TNoReflowTabBarDblClickEvent Read FOnItemDblClick Write FOnItemDblClick;

        //Événement déclenché lorsque le drag d'un item devient réellement actif.
        Property OnBeginItemDrag: TNoReflowTabBarBeginDragItemEvent Read FOnBeginItemDrag Write FOnBeginItemDrag;

        //Événement déclenché à la fin d'un drag d'item.
        //
        //ADropped vaut True uniquement si un déplacement a réellement t appliqu.
        Property OnEndItemDrag: TNoReflowTabBarEndDragItemEvent Read FOnEndItemDrag Write FOnEndItemDrag;

        //Événement permettant dautoriser ou refuser un réordonnancement.
        Property OnCanReorderItem: TNoReflowTabBarCanReorderItemEvent Read FOnCanReorderItems Write FOnCanReorderItems;

        //Événement permettant d'autoriser ou refuser le dépôt d'un item.
        //
        //Il couvre à la fois le drag interne et le drag inter-barres.
        Property OnCanDropItem: TNoReflowTabBarCanDropItemEvent Read FOnCanDropItem Write FOnCanDropItem;

        //Événement déclenché après un dépôt accepté par cette barre.
        Property OnItemDropped: TNoReflowTabBarItemDroppedEvent Read FOnItemDropped Write FOnItemDropped;

        //Déclenché lorsqu'un item est survolé pendant le drag d'un item.
        //
        //Cet événement ne remplace pas OnCanDropItem :
        //il sert aux réactions fonctionnelles au survol, par exemple activer
        //une page de menu lorsque l'utilisateur déplace un bouton au-dessus
        //d'un onglet.
        Property OnItemDragOver: TNoReflowTabBarItemDragOverEvent Read FOnItemDragOver Write FOnItemDragOver;

        //Déclenché lorsque le drag quitte l'item précédemment survolé.
        Property OnItemDragLeave: TNoReflowTabBarItemDragLeaveEvent Read FOnItemDragLeave Write FOnItemDragLeave;

        //Événement appelé avant de démarrer l'édition directe du Caption.
        //
        //Le handler peut refuser l'édition en mettant Allow à False.
        Property OnCanEditItemCaption: TNoReflowTabBarCanEditItemCaptionEvent Read FOnCanEditItemCaption Write FOnCanEditItemCaption;

        //Événement appelé avant d'accepter le nouveau Caption.
        //
        //ANewCaption peut être modifié par le handler.
        //Accept permet de refuser la modification.
        Property OnValidateItemCaption: TNoReflowTabBarValidateItemCaptionEvent Read FOnValidateItemCaption Write FOnValidateItemCaption;

        //Événement appelé après modification effective du Caption.
        //
        //C'est l'événement à brancher côté application pour sauvegarder
        //le renommage dans une base, un fichier ou un profil utilisateur.
        Property OnItemCaptionEdited: TNoReflowTabBarItemCaptionEditedEvent Read FOnItemCaptionEdited Write FOnItemCaptionEdited;

        Property OnGetItemText: TNoReflowTabBarGetItemTextEvent Read FOnGetItemText Write FOnGetItemText;
        Property OnGetItemHint: TNoReflowTabBarGetItemHintEvent Read FOnGetItemHint Write FOnGetItemHint;
        Property OnMeasureItem: TNoReflowTabBarMeasureItemEvent Read FOnMeasureItem Write FOnMeasureItem;
        Property OnPaintItem:   TNoReflowTabBarPaintEvent Read FOnPaintItem Write FOnPaintItem;

        //Événement déclenché lorsque la souris entre dans un item.
        Property OnItemMouseEnter: TNoReflowTabBarMouseEvent Read FOnItemMouseEnter Write FOnItemMouseEnter;

        //Événement déclenché lorsque la souris quitte un item.
        Property OnItemMouseLeave: TNoReflowTabBarMouseEvent Read FOnItemMouseLeave Write FOnItemMouseLeave;

        //Événement déclenché lorsque la souris entre dans une zone logique.
        Property OnZoneMouseEnter: TNoReflowTabBarZoneMouseEvent Read FOnZoneMouseEnter Write FOnZoneMouseEnter;

        //Événement déclenché lorsque la souris quitte une zone logique.
        Property OnZoneMouseLeave: TNoReflowTabBarZoneMouseEvent Read FOnZoneMouseLeave Write FOnZoneMouseLeave;

        Property OnContextPopup;
        Property OnEnter;
        Property OnExit;
        Property OnGesture;
        Property OnMouseDown;
        Property OnMouseMove;
        Property OnMouseUp;
        Property OnMouseEnter;
        Property OnMouseLeave;
        Property OnMouseActivate;
        Property OnResize;

    End;

Implementation

// *****************************************************************************************************************************
//
//TNoReflowTabBar
//
// *****************************************************************************************************************************

Constructor TNoReflowTabBar.Create(AOwner: TComponent);
Begin
    Inherited Create(AOwner);

    FSuppressNextMouseUpClick := False;

    FDelayedItemClickIndex := -1;
    FDelayedItemClickKey := 0;
    FDelayedItemClickButton := mbLeft;
    FDelayedItemClickShift := [];
    FDelayedItemClickPos := Point(
        -1,
        -1);

    FDelayedItemClickTimer := TTimer.Create(Self);
    FDelayedItemClickTimer.Enabled := False;
    FDelayedItemClickTimer.Interval := GetDoubleClickTime + 10;
    FDelayedItemClickTimer.OnTimer := DelayedItemClickTimer;
End;

Destructor TNoReflowTabBar.Destroy;
Begin
    CancelDelayedItemClick;
    FreeAndNil(FDelayedItemClickTimer);

    Inherited Destroy;
End;

Procedure TNoReflowTabBar.DebugTrace(Const AMsg: String);
Var
    S: String;
Begin
    //-------------------------------------------------------------------------
    //Émet une trace de diagnostic dans le debugger.
    //
    //Cette routine est volontairement centralise pour pouvoir :
    //- activer / désactiver facilement les traces
    //- uniformiser leur format
    //- éviter de dupliquer OutputDebugString partout
    //-------------------------------------------------------------------------

{$IFDEF DEBUG}
    S := Format(
        '[NoReflowTabBar %p] %s',
        [Pointer(Self), AMsg]);
    OutputDebugString(PChar(S));
{$ENDIF}
End;

Function TNoReflowTabBar.DebugItemLabel(AIndex: Integer): String;
Begin
    //-------------------------------------------------------------------------
    //Retourne une description courte d'un item pour faciliter
    //la lecture des traces.
    //-------------------------------------------------------------------------

    If (AIndex < 0) Or (AIndex >= FItems.Count) Then Begin
        Result := Format(
            '%d:<none>',
            [AIndex]);
        Exit;
    End;

    Result := Format(
        '%d:"%s"',
        [AIndex, FItems[AIndex].Caption]);
End;

//===============================================================================================================================
//TNoReflowTabBar : Fonctions sur les voyants
//===============================================================================================================================

Procedure TNoReflowTabBar.SetSignals(Const Value: TNoReflowTabBarSignalDefs);
Begin
    If Value = Nil Then
        Exit;

    FSignals.BeginUpdate;
    Try FSignals.Assign(Value);
    Finally FSignals.EndUpdate;
    End;

    InvalidateLayout;
End;

//===============================================================================================================================
//TNoReflowTabBar : palette, couleurs et états visuels
//===============================================================================================================================

Function TNoReflowTabBar.GetItemRegionPoints(AAbsoluteItemIndex: Integer): TArray<TPoint>;
Begin
    //-------------------------------------------------------------------------
    //Expose le contour polygonal actuellement calcul pour un item.
    //
    //Cette mthode évite dexposer directement FRenderItems tout en permettant
    //du code externe de récupérer la forme exacte utilisée pour le rendu
    //et le hit-test.
    //-------------------------------------------------------------------------

    EnsureRenderInfo;

    If (AAbsoluteItemIndex < 0) Or (AAbsoluteItemIndex >= Length(FRenderItems)) Then Begin
        SetLength(
            Result,
            0);
        Exit;
    End;

    Result := Copy(FRenderItems[AAbsoluteItemIndex].RegionPoints);
End;

Function TNoReflowTabBar.TryGetItemMetrics(
    AAbsoluteItemIndex: Integer;
    Out AMetrics: TNoReflowTabBarItemMetrics): Boolean;
Begin
    //-------------------------------------------------------------------------
    //Expose les métriques actuellement calculées pour un item.
    //
    //Cela permet à un code externe de connatre la position locale du texte,
    //du voyant et les dimensions réellement retenues, sans dépendre de la
    //structure interne complète du render item.
    //-------------------------------------------------------------------------

    EnsureRenderInfo;

    FillChar(
        AMetrics,
        SizeOf(AMetrics),
        0);
    Result := (AAbsoluteItemIndex >= 0) And (AAbsoluteItemIndex < Length(FRenderItems)) And FRenderItems[AAbsoluteItemIndex].Visible;

    If Result Then
        AMetrics := FRenderItems[AAbsoluteItemIndex].Metrics;
End;

Function TNoReflowTabBar.GetItemDisplayText(AAbsoluteItemIndex: Integer): String;
Var
    LTab: TNoReflowTabBarItem;
Begin
    Result := '';

    If (AAbsoluteItemIndex < 0) Or (AAbsoluteItemIndex >= FItems.Count) Then
        Exit;

    LTab := FItems[AAbsoluteItemIndex];

    Result := ResolveItemText(
        AAbsoluteItemIndex,
        LTab);
End;

Procedure TNoReflowTabBar.DefaultPaintItemByIndex(
    AAbsoluteItemIndex: Integer;
    AVisualState: TNoReflowTabBarItemVisualState);
Begin
    //-------------------------------------------------------------------------
    //Version publique de DefaultPaintTab base sur l'index ditem.
    //
    //Cette façade permet à un code externe de réutiliser le rendu standard
    //sans manipuler directement la structure interne TNoreflowTabRenderItem.
    //-------------------------------------------------------------------------

    EnsureRenderInfo;

    If (AAbsoluteItemIndex < 0) Or (AAbsoluteItemIndex >= Length(FRenderItems)) Then
        Exit;

    If Not FRenderItems[AAbsoluteItemIndex].Visible Then
        Exit;

    DefaultPaintTab(
        FRenderItems[AAbsoluteItemIndex],
        AVisualState);
End;

Function TNoReflowTabBar.GetBarSelectedItems: TArray<TNoReflowTabBarItem>;
Var
    LTab: TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Retourne les items considrs comme actifs selon le mode fonctionnel.
    //
    //Cette mthode fournit une façade cohérente pour les quatre BarMode :
    //
    //- nrbmTabs / nrbmSelectButtons :
    //l'état actif est exclusif et correspond  SelectedItem.
    //
    //- nrbmCheckButtons :
    //l'état actif est multiple et correspond aux items Checked=True.
    //
    //- nrbmPushButtons :
    //il n'existe pas d'état actif persistant.
    //-------------------------------------------------------------------------

    SetLength(
        Result,
        0);

    Case FBarMode Of
        nrbmTabs, nrbmSelectButtons: Begin
                LTab := GetBarCurrentItem;

                If LTab <> Nil Then Begin
                    SetLength(
                        Result,
                        1);

                    Result[0] := LTab;
                End;
            End;

        nrbmCheckButtons: Begin
                Result := GetBarCheckedItems;
            End;

        nrbmPushButtons: Begin
                //Boutons d'action purs : pas de sélection persistante.
            End;
    End;
End;

Function TNoReflowTabBar.GetBarSelectedCount: Integer;
Var
    LTabs: TArray<TNoReflowTabBarItem>;
Begin
    LTabs := GetBarSelectedItems;
    Result := Length(LTabs);
End;

Function TNoReflowTabBar.HasBarSelectedItems: Boolean;
Begin
    Result := GetBarSelectedCount > 0;
End;

Function TNoReflowTabBar.GetBarCheckedItems: TArray<TNoReflowTabBarItem>;
Var
    I:      Integer;
    LCount: Integer;
    LTab:   TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Retourne tous les items dont Checked=True.
    //
    //Cette mthode ne dépend pas de BarMode. Elle lit uniquement l'état port
    //par les items.
    //-------------------------------------------------------------------------

    SetLength(
        Result,
        0);

    If FItems = Nil Then
        Exit;

    LCount := 0;

    For I := 0 To FItems.Count - 1 Do Begin
        LTab := FItems[I];

        If LTab = Nil Then
            Continue;

        If Not LTab.Checked Then
            Continue;

        SetLength(
            Result,
            LCount + 1);

        Result[LCount] := LTab;
        Inc(LCount);
    End;
End;

Function TNoReflowTabBar.GetBarCheckedCount: Integer;
Var
    I:    Integer;
    LTab: TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Compte les items Checked=True sans construire de tableau intermédiaire.
    //-------------------------------------------------------------------------

    Result := 0;

    If FItems = Nil Then
        Exit;

    For I := 0 To FItems.Count - 1 Do Begin
        LTab := FItems[I];

        If LTab = Nil Then
            Continue;

        If LTab.Checked Then
            Inc(Result);
    End;
End;

Procedure TNoReflowTabBar.ClearBarCheckedItems;
Var
    I:        Integer;
    LChanged: Boolean;
    LTab:     TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Décoche tous les items.
    //
    //On utilisée SetCheckedDirect pour éviter une notification par item.
    //Une seule invalidation globale est faite  la fin si nécessaire.
    //-------------------------------------------------------------------------

    If FItems = Nil Then
        Exit;

    LChanged := False;

    For I := 0 To FItems.Count - 1 Do Begin
        LTab := FItems[I];

        If LTab = Nil Then
            Continue;

        If LTab.Checked Then Begin
            LTab.SetCheckedDirect(False);
            LChanged := True;
        End;
    End;

    If LChanged Then
        InvalidateLayout;
End;

Function TNoReflowTabBar.IsBarItemChecked(AAbsoluteItemIndex: Integer): Boolean;
Begin
    //-------------------------------------------------------------------------
    //Retourne l'état Checked d'un item par index absolu.
    //-------------------------------------------------------------------------

    Result := False;

    If FItems = Nil Then
        Exit;

    If (AAbsoluteItemIndex < 0) Or (AAbsoluteItemIndex >= FItems.Count) Then
        Exit;

    If FItems[AAbsoluteItemIndex] = Nil Then
        Exit;

    Result := FItems[AAbsoluteItemIndex].Checked;
End;

Procedure TNoReflowTabBar.SetBarItemChecked(
    AIndex: Integer;
    AChecked: Boolean);
Begin
    //-------------------------------------------------------------------------
    //Affecte Checked sur un item par index absolu.
    //
    //Cette mthode passe par la propriété publique Checked de l'item afin de
    //conserver la notification standard du modèle.
    //-------------------------------------------------------------------------

    If FItems = Nil Then
        Exit;

    If (AIndex < 0) Or (AIndex >= FItems.Count) Then
        Exit;

    If FItems[AIndex] = Nil Then
        Exit;

    If FItems[AIndex].Checked = AChecked Then
        Exit;

    FItems[AIndex].Checked := AChecked;
End;

Procedure TNoReflowTabBar.ToggleBarItemChecked(AIndex: Integer);
Begin
    //-------------------------------------------------------------------------
    //Inverse Checked sur un item par index absolu.
    //-------------------------------------------------------------------------

    If FItems = Nil Then
        Exit;

    If (AIndex < 0) Or (AIndex >= FItems.Count) Then
        Exit;

    If FItems[AIndex] = Nil Then
        Exit;

    SetBarItemChecked(
        AIndex,
        Not FItems[AIndex].Checked);
End;

Procedure TNoReflowTabBar.Paint;
Var
    Buffer: TBitmap;
Begin
    If (ClientWidth <= 0) Or (ClientHeight <= 0) Then
        Exit;

    Buffer := TBitmap.Create;
    Try
        Buffer.PixelFormat := pf32bit;
        Buffer.SetSize(
            ClientWidth,
            ClientHeight);

        PaintToCanvas(Buffer.Canvas);

        //Marqueur de drag dessin au-dessus de la barre déjà rendue.
        DrawDragInsertMarker(Buffer.Canvas);

        BitBlt(
            Canvas.Handle,
            0,
            0,
            ClientWidth,
            ClientHeight,
            Buffer.Canvas.Handle,
            0,
            0,
            SRCCOPY);
    Finally Buffer.Free;
    End;
End;

//===============================================================================================================================
//TNoReflowTabBar : messages VCL lis  l'apparence
//===============================================================================================================================

Procedure TNoReflowTabBar.CMColorChanged(Var Message: TMessage);
Begin
    //-------------------------------------------------------------------------
    //Réagit à une modification de la propriété Color du contrôle.
    //
    //Dans ce composant, Color intervient notamment comme :
    //- couleur de fond de la barre
    //- base potentielle de certaines couleurs résolues
    //
    //Il faut donc invalider la palette active puis redessiner.
    //-------------------------------------------------------------------------

    Inherited;

    //La couleur de fond de barre dépend de Color.
    InvalidatePalette;
    InvalidateRenderInfo;

    Invalidate;
End;

Procedure TNoReflowTabBar.CMStyleChanged(Var Message: TMessage);
Begin
    //-------------------------------------------------------------------------
    //Réagit à un changement de style VCL.
    //
    //Un changement de style peut modifier :
    //- les couleurs système utilisées pour la palette en mode style
    //- la police héritée
    //- certaines métriques perçues
    //
    //Il faut donc invalider explicitement la palette puis relancer
    //le recalcul complet du layout et du rendu.
    //-------------------------------------------------------------------------
    Inherited;

    InvalidatePalette;
    InvalidateLayout;
End;

Procedure TNoReflowTabBar.CMFontChanged(Var Message: TMessage);
Begin
    //-------------------------------------------------------------------------
    //Réagit à une modification directe de la police du contrôle.
    //
    //La police influence :
    //- la largeur du texte
    //- la hauteur du texte
    //- donc les métriques de chaque item
    //- et potentiellement le nombre de lignes / colonnes calculées
    //-------------------------------------------------------------------------

    Inherited;

    //Toute variation de police impose un recalcul des métriques.
    InvalidateLayout;
End;

Procedure TNoReflowTabBar.CMParentFontChanged(Var Message: TMessage);
Begin
    //-------------------------------------------------------------------------
    //Réagit à une modification de la police héritée du parent.
    //
    //Mme si la police n'a pas été modifiée localement sur le contrôle,
    //un changement ct parent peut modifier les mesures effectives.
    //-------------------------------------------------------------------------

    Inherited;

    //Mme logique si la police héritée du parent change.
    InvalidateLayout;
End;

//===============================================================================================================================
//TNoReflowTabBar : messages VCL lis  la souris / clavier / hints
//===============================================================================================================================

Procedure TNoReflowTabBar.CMMouseLeave(Var Message: TMessage);
Var
    OldHot:  Integer;
    OldZone: TNoReflowTabBarPinZone;
    OldTab:  TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Réagit à la sortie de la souris du contrôle.
    //
    //Avec le hint manuel, on cache explicitement le hint dès que le curseur
    //quitte réellement le composant.
    //
    //On déclenche aussi les événements métier de sortie :
    //- OnItemMouseLeave si un item était survolé ;
    //- OnZoneMouseLeave si une zone était survolée.
    //-------------------------------------------------------------------------

    Inherited;

    //-------------------------------------------------------------------------
    //Si un vrai drag est actif, la sortie de souris est normale :
    //- drag inter-barres ;
    //- déplacement avec capture souris ;
    //- prévisualisation éventuelle sur une autre barre.
    //
    //Dans ce cas, on ne touche pas à l'état de drag.
    //
    //En revanche, si seul FDragTracking est actif, cela signifie que la souris
    //était en phase "clic appuyé / seuil de drag pas encore franchi".
    //
    //Si la souris quitte le contrôle dans cet état, il faut annuler ce pré-drag.
    //Sinon un clic ou double-clic ultérieur peut réutiliser un ancien
    //FDragSourceIndex et donner l'impression que le bouton repart en drag.
    //-------------------------------------------------------------------------
    If FDragActive Then
        Exit;

    If FDragTracking Then Begin
        ResetTabDragState;
        FMouseDownItemIndex := -1;

        Invalidate;
    End;

    HideCustomHint;

    If FHotItemIndex <> -1 Then Begin
        OldHot := FHotItemIndex;
        FHotItemIndex := -1;

        OldTab := Nil;

        If (OldHot >= 0) And (OldHot < FItems.Count) Then
            OldTab := FItems[OldHot];

        DoItemMouseLeave(
            OldHot,
            OldTab,
            [],
            FLastMousePos.X,
            FLastMousePos.Y);

        InvalidateItem(OldHot);
    End;

    If FHotZone <> nrtpzNone Then Begin
        OldZone := FHotZone;
        FHotZone := nrtpzNone;

        DoZoneMouseLeave(
            OldZone,
            [],
            FLastMousePos.X,
            FLastMousePos.Y);
    End;
End;

Procedure TNoReflowTabBar.WMGetDlgCode(Var Message: TWMGetDlgCode);
Begin
    //-------------------------------------------------------------------------
    //Indique à Windows / VCL quels types de touches le contrôle
    //souhaite recevoir directement.
    //
    //Ici, la barre veut gérer elle-même :
    //- les flèches de navigation
    //- les caractres ventuels
    //
    //Cela évite que ces touches soient consommées plus haut
    //par le système de dialogue standard.
    //-------------------------------------------------------------------------

    Inherited;

    //Le contrôle demande explicitement  recevoir les flèches clavier
    //et les caractres, afin de piloter la navigation lui-même.
    Message.Result := Message.Result Or DLGC_WANTARROWS Or DLGC_WANTCHARS;
End;

//===============================================================================================================================
//TNoReflowTabBar : événements du contrôle
//===============================================================================================================================

Procedure TNoReflowTabBar.Loaded;
Begin
    //-------------------------------------------------------------------------
    //Une fois tout le DFM chargé :
    //- tous les items existent
    //- toutes leurs propriétés ont été lues
    //- les propriétés cachées streamées par DefineProperties, comme Item.Key,
    //ont éégalement été relues
    //
    //On peut alors :
    //- garantir les clés techniques uniques
    //- reprojeter PinZone + ZoneIndex dans l'ordre physique réel
    //- reconstruire l'état sélection/layout/rendu
    //-------------------------------------------------------------------------

    Inherited;

    If FItems <> Nil Then
        FItems.EnsureUniqueItemsKeys;

    InvalidatePalette;

    NormalizeItemsOrderByZone;
    ItemsChanged;
End;

Procedure TNoReflowTabBar.Resize;
Begin
    //-------------------------------------------------------------------------
    //Réagit à un changement de taille du contrôle.
    //
    //Un redimensionnement peut modifier le nombre de lignes / colonnes
    //nécessaires, donc impose un recalcul du layout.
    //
    //Important :
    //la barre doit continuer à s'ajuster automatiquement à son contenu :
    //- en top/bottom : ajustement de Height
    //- en left/right : ajustement de Width
    //
    //On repasse donc ici par InvalidateLayout, qui relance RelayoutTabs.
    //-------------------------------------------------------------------------
    Inherited;

    //Si le redimensionnement provient d'un ajustement interne pilot
    //par RelayoutTabs, il ne faut pas relancer un nouveau cycle complet.
    If FInternalSizing Then
        Exit;

    InvalidateLayout;
End;

Function TNoReflowTabBar.GetDragInsertMarkerColor: TColor;
Var
    Palette: TNoReflowTabBarPalette;
Begin
    //-------------------------------------------------------------------------
    //Couleur du marqueur d'insertion pendant un drag.
    //
    //On se base sur la palette réellement active du composant afin de rester
    //cohérent avec :
    //- le mode custom
    //- le mode style VCL
    //
    //Le texte sélectionné fournit généralement une couleur bien contraste
    //et déjà pense pour ressortir sur le fond actif.
    //-------------------------------------------------------------------------
    Palette := GetActivePalette;
    //Result := ColorToRGB(Palette.TabHotBorder);
    Result := Palette.DragInsertMarker;

    //Petit filet de sécurité si une couleur non exploitable remonte.
    If Result = clNone Then
        Result := Palette.TabHotBorder; //ColorToRGB(clHighlight);
End;

Procedure TNoReflowTabBar.DrawDragInsertMarker(ACanvas: TCanvas);
Const
    CMarkerThickness = 2;
    CArrowHeadLength = 8;
    CArrowHeadHalfSize = 6;
    CArrowNeckHalfSize = 2;
    CArrowStemOverlap = 3;
    CInnerPad = 2;
Var
    MarkerRect:      TRect;
    CanonicalRect:   TRect;
    MarkerColor:     TColor;
    ArrowPoints:     Array [0 .. 4] Of TPoint;
    CenterX:         Integer;
    CenterY:         Integer;
    TipX:            Integer;
    TipY:            Integer;
    Dir:             TPoint;
    ActualDir:       TPoint;
    LineRect:        TRect;
    P0:              TPoint;
    P1:              TPoint;
    P2:              TPoint;
    P3:              TPoint;
    FlowOrientation: TNoReflowTabBarZoneFlowOrientation;

    Procedure DrawArrowHead(
        ATipX: Integer;
        ATipY: Integer;
        ADirectionX: Integer;
        ADirectionY: Integer);
    Begin
        If ADirectionX > 0 Then Begin
            ArrowPoints[0] := Point(
                ATipX,
                ATipY);
            ArrowPoints[1] := Point(
                ATipX - CArrowHeadLength,
                ATipY - CArrowHeadHalfSize);
            ArrowPoints[2] := Point(
                ATipX - CArrowHeadLength + 3,
                ATipY - CArrowNeckHalfSize);
            ArrowPoints[3] := Point(
                ATipX - CArrowHeadLength + 3,
                ATipY + CArrowNeckHalfSize);
            ArrowPoints[4] := Point(
                ATipX - CArrowHeadLength,
                ATipY + CArrowHeadHalfSize);
        End Else If ADirectionX < 0 Then Begin
            ArrowPoints[0] := Point(
                ATipX,
                ATipY);
            ArrowPoints[1] := Point(
                ATipX + CArrowHeadLength,
                ATipY - CArrowHeadHalfSize);
            ArrowPoints[2] := Point(
                ATipX + CArrowHeadLength - 3,
                ATipY - CArrowNeckHalfSize);
            ArrowPoints[3] := Point(
                ATipX + CArrowHeadLength - 3,
                ATipY + CArrowNeckHalfSize);
            ArrowPoints[4] := Point(
                ATipX + CArrowHeadLength,
                ATipY + CArrowHeadHalfSize);
        End Else If ADirectionY > 0 Then Begin
            ArrowPoints[0] := Point(
                ATipX,
                ATipY);
            ArrowPoints[1] := Point(
                ATipX - CArrowHeadHalfSize,
                ATipY - CArrowHeadLength);
            ArrowPoints[2] := Point(
                ATipX - CArrowNeckHalfSize,
                ATipY - CArrowHeadLength + 3);
            ArrowPoints[3] := Point(
                ATipX + CArrowNeckHalfSize,
                ATipY - CArrowHeadLength + 3);
            ArrowPoints[4] := Point(
                ATipX + CArrowHeadHalfSize,
                ATipY - CArrowHeadLength);
        End Else Begin
            ArrowPoints[0] := Point(
                ATipX,
                ATipY);
            ArrowPoints[1] := Point(
                ATipX - CArrowHeadHalfSize,
                ATipY + CArrowHeadLength);
            ArrowPoints[2] := Point(
                ATipX - CArrowNeckHalfSize,
                ATipY + CArrowHeadLength - 3);
            ArrowPoints[3] := Point(
                ATipX + CArrowNeckHalfSize,
                ATipY + CArrowHeadLength - 3);
            ArrowPoints[4] := Point(
                ATipX + CArrowHeadHalfSize,
                ATipY + CArrowHeadLength);
        End;

        ACanvas.Polygon(ArrowPoints);
    End;

    Function CanonicalPointToActual(Const APoint: TPoint): TPoint;
    Begin
        Result := TNoReflowTabBarZoneLayoutEngine.TransformCanonicalPointToActual(
            APoint,
            FlowOrientation,
            FBarPosition,
            ClientWidth,
            ClientHeight);
    End;

Begin
    If ACanvas = Nil Then
        Exit;

    If Not FDragActive Then
        Exit;

    If Not FDragTarget.Valid Then
        Exit;

    FlowOrientation := GetZoneFlowOrientation;

    MarkerColor := GetDragInsertMarkerColor;

    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := MarkerColor;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Width := CMarkerThickness;
    ACanvas.Pen.Color := MarkerColor;

    If FDragTarget.TargetKind = nrtdtkInterZone Then Begin
        CanonicalRect := FDragTarget.MarkerCanonicalRect;
        Dir := FDragTarget.MarkerCanonicalDirection;

        If IsRectEmpty(CanonicalRect) Then
            Exit;

        If (Dir.X = 0) And (Dir.Y = 0) Then
            Exit;

        If Dir.X > 0 Then Begin
            P0 := Point(
                CanonicalRect.Left,
                CanonicalRect.Top + CInnerPad);
            P1 := Point(
                CanonicalRect.Left,
                CanonicalRect.Bottom - CInnerPad);
            P2 := Point(
                CanonicalRect.Right,
                CanonicalRect.Bottom - CInnerPad);
            P3 := Point(
                P2.X - CArrowHeadLength + CArrowStemOverlap,
                P2.Y);
        End Else Begin
            P0 := Point(
                CanonicalRect.Right,
                CanonicalRect.Top + CInnerPad);
            P1 := Point(
                CanonicalRect.Right,
                CanonicalRect.Bottom - CInnerPad);
            P2 := Point(
                CanonicalRect.Left,
                CanonicalRect.Bottom - CInnerPad);
            P3 := Point(
                P2.X + CArrowHeadLength - CArrowStemOverlap,
                P2.Y);
        End;

        P0 := CanonicalPointToActual(P0);
        P1 := CanonicalPointToActual(P1);
        P2 := CanonicalPointToActual(P2);
        P3 := CanonicalPointToActual(P3);

        ActualDir := TNoReflowTabBarZoneLayoutEngine.TransformCanonicalDirectionToActual(
            Dir,
            FlowOrientation,
            FBarPosition);

        ACanvas.MoveTo(
            P0.X,
            P0.Y);
        ACanvas.LineTo(
            P1.X,
            P1.Y);
        ACanvas.LineTo(
            P3.X,
            P3.Y);

        DrawArrowHead(
            P2.X,
            P2.Y,
            ActualDir.X,
            ActualDir.Y);

        Exit;
    End;

    MarkerRect := GetDragInsertMarkerRect(FDragTarget);
    If IsRectEmpty(MarkerRect) Then
        Exit;

    Dir := FDragTarget.MarkerDirection;

    If (Dir.X = 0) And (Dir.Y = 0) Then Begin
        If (FDragTarget.MarkerCanonicalDirection.X <> 0) Or (FDragTarget.MarkerCanonicalDirection.Y <> 0) Then
            Dir := TNoReflowTabBarZoneLayoutEngine.TransformCanonicalDirectionToActual(
                FDragTarget.MarkerCanonicalDirection,
                FlowOrientation,
                FBarPosition);
    End;

    If (Dir.X = 0) And (Dir.Y = 0) Then
        Exit;

    CenterX := (MarkerRect.Left + MarkerRect.Right) Div 2;
    CenterY := (MarkerRect.Top + MarkerRect.Bottom) Div 2;

    If Dir.X > 0 Then Begin
        TipX := MarkerRect.Left + CInnerPad;
        TipY := CenterY;

        LineRect := Rect(
            TipX + CArrowHeadLength - CArrowStemOverlap,
            CenterY - (CMarkerThickness Div 2),
            MarkerRect.Right - CInnerPad,
            CenterY - (CMarkerThickness Div 2) + CMarkerThickness);

        ACanvas.FillRect(LineRect);
        DrawArrowHead(
            TipX,
            TipY,
            1,
            0);
    End Else If Dir.X < 0 Then Begin
        TipX := MarkerRect.Right - CInnerPad - 1;
        TipY := CenterY;

        LineRect := Rect(
            MarkerRect.Left + CInnerPad,
            CenterY - (CMarkerThickness Div 2),
            TipX - CArrowHeadLength + CArrowStemOverlap,
            CenterY - (CMarkerThickness Div 2) + CMarkerThickness);

        ACanvas.FillRect(LineRect);
        DrawArrowHead(
            TipX,
            TipY,
            -1,
            0);
    End Else If Dir.Y > 0 Then Begin
        TipX := CenterX;
        TipY := MarkerRect.Top + CInnerPad;

        LineRect := Rect(
            CenterX - (CMarkerThickness Div 2),
            TipY + CArrowHeadLength - CArrowStemOverlap,
            CenterX - (CMarkerThickness Div 2) + CMarkerThickness,
            MarkerRect.Bottom - CInnerPad);

        ACanvas.FillRect(LineRect);
        DrawArrowHead(
            TipX,
            TipY,
            0,
            1);
    End Else Begin
        TipX := CenterX;
        TipY := MarkerRect.Bottom - CInnerPad - 1;

        LineRect := Rect(
            CenterX - (CMarkerThickness Div 2),
            MarkerRect.Top + CInnerPad,
            CenterX - (CMarkerThickness Div 2) + CMarkerThickness,
            TipY - CArrowHeadLength + CArrowStemOverlap);

        ACanvas.FillRect(LineRect);
        DrawArrowHead(
            TipX,
            TipY,
            0,
            -1);
    End;
End;

Function TNoReflowTabBar.ItemAtPos(Const P: TPoint): Integer;
Begin
    //-------------------------------------------------------------------------
    //Wrapper public autour du hit-test interne.
    //
    //TNoReflowTabBarCore possède déjà la logique complète de détection.
    //On l'expose ici pour les usages applicatifs légitimes :
    //- menu contextuel sur un item ;
    //- sélection d'un item sous la souris ;
    //- intégration avec un gestionnaire externe.
    //-------------------------------------------------------------------------
    Result := Inherited ItemAtPos(P);
End;

Procedure TNoReflowTabBar.MouseMove(
    Shift: TShiftState;
    X, Y: Integer);
Const
    CDragThreshold = 4;
Var
    NewHot:    Integer;
    OldHot:    Integer;
    NewTarget: TNoReflowTabBarDragTarget;
    OldTab:    TNoReflowTabBarItem;
    NewTab:    TNoReflowTabBarItem;
    OldZone:   TNoReflowTabBarPinZone;
    NewZone:   TNoReflowTabBarPinZone;
Begin
    //-------------------------------------------------------------------------
    //Gère le déplacement de la souris au-dessus du contrôle.
    //
    //Le but ici est de maintenir  jour :
    //- FHotTabIndex pour le rendu de l'état hot
    //- FHotZone pour les événements de survol de zone
    //- le hint manuel pilot par le composant
    //- la cible de drag lorsque le réordonnancement est actif
    //-------------------------------------------------------------------------

    Inherited;

    If IsEditingItemCaption Then
        Exit;

    FLastMousePos := Point(
        X,
        Y);

    EnsureRenderInfo;

    //-------------------------------------------------------------------------
    //Gestion de la zone survolée.
    //
    //La zone est volontairement traite avant le drag :
    //cela permet au composant de connatre la dernire zone réellement
    //survolée tant qu'on n'est pas encore dans un drag actif.
    //
    //nrtpzNone signifie qu'aucune zone logique n'est sous la souris.
    //-------------------------------------------------------------------------

    OldZone := FHotZone;

    If Not ZoneAtPos(FLastMousePos, NewZone) Then
        NewZone := nrtpzNone;

    If OldZone <> NewZone Then Begin
        FHotZone := NewZone;

        If OldZone <> nrtpzNone Then
            DoZoneMouseLeave(
                OldZone,
                Shift,
                X,
                Y);

        If NewZone <> nrtpzNone Then
            DoZoneMouseEnter(
                NewZone,
                Shift,
                X,
                Y);
    End;

    //-------------------------------------------------------------------------
    //Gestion du drag d'item.
    //
    //On conserve ici votre logique existante :
    //- seuil de départ
    //- SetCapture
    //- DoBeginTabDrag
    //- TryBuildTabDragTarget
    //- invalidation uniquement si la cible change
    //
    //Si le drag est actif, on sort avant la gestion du hot item afin d'éviter
    //que le survol visuel des items interfère avec le marqueur d'insertion.
    //-------------------------------------------------------------------------

    If FDragTracking Then Begin
        If (Not FDragActive) And ((Abs(X - FDragStartPos.X) >= CDragThreshold) Or (Abs(Y - FDragStartPos.Y) >= CDragThreshold)) Then Begin

            If FHotItemIndex <> -1 Then Begin
                OldHot := FHotItemIndex;

                OldTab := Nil;
                If (OldHot >= 0) And (OldHot < FItems.Count) Then
                    OldTab := FItems[OldHot];

                FHotItemIndex := -1;

                DoItemMouseLeave(
                    OldHot,
                    OldTab,
                    Shift,
                    X,
                    Y);

                HideCustomHint;
                InvalidateItem(OldHot);
            End;

            FDragActive := True;
            SetCapture(Handle);
            DoBeginTabDrag;
        End;

        If FDragActive Then Begin
            If UpdateExternalDraggedBarItemPreview(ClientToScreen(Point(X, Y))) Then Begin
                //Une autre barre compatible prend en chargée la prévisualisation.
                //On efface donc la cible interne de la barre source afin de ne
                //pas afficher deux marqueurs concurrents.
                If FDragTarget.Valid Then Begin
                    FDragTarget.Init;
                    Invalidate;
                End;

                Exit;
            End;

            NewTarget.Init;
            TryBuildTabDragTarget(
                Point(X, Y),
                NewTarget);

            If (NewTarget.Valid <> FDragTarget.Valid) Or (NewTarget.TargetKind <> FDragTarget.TargetKind) Or (NewTarget.PinZone <> FDragTarget.PinZone) Or
                (NewTarget.InsertKind <> FDragTarget.InsertKind) Or (NewTarget.TargetItemIndex <> FDragTarget.TargetItemIndex) Or
                (NewTarget.ZoneInsertIndex <> FDragTarget.ZoneInsertIndex) Then Begin
                FDragTarget := NewTarget;
                Invalidate;
            End;

            Exit;
        End;
    End;

    //-------------------------------------------------------------------------
    //Gestion de l'item survol.
    //
    //FHotTabIndex reste l'état visuel historique utilisé par le rendu.
    //Les événements OnItemMouseLeave / OnItemMouseEnter sont déclenchés
    //uniquement quand l'item réellement survol change.
    //-------------------------------------------------------------------------

    NewHot := ItemAtPos(Point(X, Y));

    //DebugTrace(Format('MouseMove X=%d Y=%d oldHot=%s newHot=%s', [X, Y, DebugTabLabel(FHotTabIndex), DebugTabLabel(NewHot)]));

    If FHotItemIndex <> NewHot Then Begin
        OldHot := FHotItemIndex;

        OldTab := Nil;
        If (OldHot >= 0) And (OldHot < FItems.Count) Then
            OldTab := FItems[OldHot];

        NewTab := Nil;
        If (NewHot >= 0) And (NewHot < FItems.Count) Then
            NewTab := FItems[NewHot];

        FHotItemIndex := NewHot;

        //DebugTrace(Format('MouseMove change oldHot=%s newHot=%s', [DebugTabLabel(OldHot), DebugTabLabel(FHotTabIndex)]));

        If OldHot >= 0 Then Begin
            DoItemMouseLeave(
                OldHot,
                OldTab,
                Shift,
                X,
                Y);

            InvalidateItem(OldHot);
        End;

        If FHotItemIndex >= 0 Then Begin
            DoItemMouseEnter(
                FHotItemIndex,
                NewTab,
                Shift,
                X,
                Y);

            InvalidateItem(FHotItemIndex);
        End;

        UpdateCustomHint;
    End;
End;

Procedure TNoReflowTabBar.MouseDown(
    Button: TMouseButton;
    Shift: TShiftState;
    X, Y: Integer);
Var
    Idx:           Integer;
    EditorControl: TWinControl;
Begin
    //-------------------------------------------------------------------------
    //Gère le bouton souris enfoncé.
    //
    //Important :
    //- la sélection simple ne doit pas dépendre du drag d'items
    //- le drag tracking ne sert qu'au reorder
    //- le clic métier sera validé dans MouseUp si la souris est relâchée
    //sur le même item
    //-------------------------------------------------------------------------

    Inherited;

    //-------------------------------------------------------------------------
    //Si une édition inline est en cours, un clic souris sur la TabBar doit
    //d'abord décider du sort de l'éditeur.
    //
    //Cas important :
    //- si le contrôle éditeur possède encore le focus, le MouseDown provient
    //  normalement de l'éditeur lui-même ou d'une séquence qui doit lui rester
    //  propre ; on laisse donc l'éditeur traiter l'événement.
    //
    //- si le focus n'est plus sur l'éditeur, le clic concerne la barre ou un
    //  autre contrôle ; on valide l'édition avant de poursuivre le traitement
    //  normal du MouseDown.
    //
    //Depuis l'abstraction INoReflowTabBarCaptionEditor, FItemEdit n'est plus
    //un TEdit concret. Les propriétés VCL comme Focused doivent donc être
    //consultées sur le TWinControl réel retourné par GetEditorControl.
    //-------------------------------------------------------------------------
    If IsEditingItemCaption Then Begin
        EditorControl := Nil;

        If FItemEdit <> Nil Then
            EditorControl := FItemEdit.GetEditorControl;

        If (EditorControl <> Nil) And EditorControl.Focused Then
            Exit;

        EndEditItemCaption(True);
    End;

    HideCustomHint;

    //-------------------------------------------------------------------------
    //Un nouveau MouseDown démarre une nouvelle séquence souris.
    //
    //Le flag FSuppressNextMouseUpClick ne doit survivre qu'au MouseUp final
    //d'un double-clic déjà traité. Si une nouvelle séquence commence ensuite,
    //on repart d'un état propre.
    //-------------------------------------------------------------------------
    If Not FSuppressNextMouseUpClick Then
        CancelDelayedItemClick;

    FMouseDownItemIndex := -1;
    FMouseDownPos := Point(
        X,
        Y);
    FMouseDownButton := Button;

    If Button <> mbLeft Then
        Exit;

    If CanFocus And (Not Focused) Then Begin
        FSuppressFocusInvalidate := True;
        Try
            SetFocus;
        Finally
            FSuppressFocusInvalidate := False;
        End;
    End;

    EnsureRenderInfo;
    Idx := ItemAtPos(Point(X, Y));

    FMouseDownItemIndex := Idx;

    ResetTabDragState;

    //-------------------------------------------------------------------------
    //Deuxième MouseDown d'un double-clic.
    //
    //Très important :
    //ce MouseDown ne doit jamais armer FDragTracking.
    //
    //Sinon, si le double-clic ouvre une boîte de dialogue modale, le composant
    //peut rester avec un pré-drag armé après fermeture du dialogue, ce qui donnée
    //l'impression que le bouton repart en drag.
    //-------------------------------------------------------------------------
    If ssDouble In Shift Then Begin
        CancelDelayedItemClick;

        FSuppressNextMouseUpClick := True;

        FDragTracking := False;
        FDragActive := False;
        FDragSourceIndex := -1;
        FDragStartPos := Point(
            -1,
            -1);
        FDragTarget.Init;

        FPressedItemIndex := -1;
        FMouseDownItemIndex := -1;

        ClearExternalDraggedBarItemPreview;
        ClearItemDragHotItem;

        If GetCapture = Handle Then
            ReleaseCapture;

        Invalidate;
        Exit;
    End;

    //-------------------------------------------------------------------------
    //État press temporaire pour les modes boutons.
    //
    //On le positionne après ResetTabDragState, car cette routine annule les
    //états temporaires de souris.
    //
    //Le mode nrbmTabs conserve son comportement historique : l'item n'utilisée
    //pas d'état Pressed transitoire pendant le clic.
    //-------------------------------------------------------------------------
    If (FBarMode <> nrbmTabs) And (Idx >= 0) And IsItemSelectable(Idx) Then Begin
        FPressedItemIndex := Idx;
        InvalidateItem(Idx);
    End;

    If (FItemsReorderMode <> nrbrmNone) And (Idx >= 0) And IsItemSelectable(Idx) Then Begin
        If (FItems[Idx] <> Nil) And IsTabReorderZoneAllowed(FItems[Idx].PinZone) Then Begin
            FDragTracking := True;
            FDragActive := False;
            FDragSourceIndex := Idx;
            FDragStartPos := Point(
                X,
                Y);
            FDragTarget.Init;
        End;
    End;
End;

Procedure TNoReflowTabBar.MouseUp(
    Button: TMouseButton;
    Shift: TShiftState;
    X, Y: Integer);
Var
    LDraggedTab:         TNoReflowTabBarItem;
    LSourceIndex:        Integer;
    LSourceZone:         TNoReflowTabBarPinZone;
    LTargetZone:         TNoReflowTabBarPinZone;
    LTargetZoneIndex:    Integer;
    LDropped:            Boolean;
    LMouseUpIndex:       Integer;
    LOldPressedIndex:    Integer;
    LTargetItem:         TNoReflowTabBarItem;
    LExternalTargetBar:  TNoReflowTabBarDragSupport;
    LExternalDropActive: Boolean;
    LExternalTarget:     TNoReflowTabBarDragTarget;
Begin
    Inherited;

    If IsEditingItemCaption Then
        Exit;

    If Button <> mbLeft Then
        Exit;

    //-------------------------------------------------------------------------
    //Fin de l'état press temporaire.
    //
    //On l'annule ds le MouseUp, que le clic soit finalement validé ou non.
    //-------------------------------------------------------------------------
    LOldPressedIndex := FPressedItemIndex;
    FPressedItemIndex := -1;

    If LOldPressedIndex >= 0 Then
        InvalidateItem(LOldPressedIndex);

    If FDragActive Then Begin
        If GetCapture = Handle Then
            ReleaseCapture;

        LDraggedTab := Nil;
        LSourceIndex := FDragSourceIndex;
        LSourceZone := nrtpzNone;
        LTargetZone := nrtpzNone;
        LTargetZoneIndex := -1;
        LDropped := False;

        If (FDragSourceIndex >= 0) And (FDragSourceIndex < FItems.Count) Then Begin
            LDraggedTab := FItems[FDragSourceIndex];
            If LDraggedTab <> Nil Then
                LSourceZone := LDraggedTab.PinZone;
        End;

        LTargetItem := Nil;
        LExternalTargetBar := FDragExternalTargetBar;
        LExternalDropActive := LExternalTargetBar <> Nil;

        If LExternalDropActive Then Begin
            If LExternalTargetBar.GetCurrentDragTarget(LExternalTarget) Then Begin
                LTargetZone := LExternalTarget.PinZone;
                LTargetZoneIndex := LExternalTarget.ZoneInsertIndex;
            End;

            LDropped := DropExternalDraggedBarItem(
                ClientToScreen(Point(X, Y)),
                LTargetItem);
        End Else If FDragTarget.Valid Then Begin
            LTargetZone := FDragTarget.PinZone;
            LTargetZoneIndex := FDragTarget.ZoneInsertIndex;

            LDropped := ApplyDraggedTabToTarget(
                FDragSourceIndex,
                FDragTarget);
        End;

        DoEndTabDrag(
            LDraggedTab,
            LSourceIndex,
            LSourceZone,
            LTargetZone,
            LTargetZoneIndex,
            LDropped);

        If LExternalDropActive And LDropped And (LDraggedTab <> Nil) Then Begin
            LDraggedTab.Free;
            LDraggedTab := Nil;
            InvalidateRenderInfo;
        End;

        FPressedItemIndex := -1;

        ResetTabDragState;
        FMouseDownItemIndex := -1;
        Invalidate;
        Exit;
    End;

    EnsureRenderInfo;

    LMouseUpIndex := ItemAtPos(Point(X, Y));

    //-------------------------------------------------------------------------
    //Si un double-clic vient d'être traité, le MouseUp final du second clic ne
    //doit pas déclencher l'action de clic simple.
    //-------------------------------------------------------------------------
    If FSuppressNextMouseUpClick Then Begin
        FSuppressNextMouseUpClick := False;
        ResetTabDragState;
        FMouseDownItemIndex := -1;
        Exit;
    End;

    If (FMouseDownItemIndex >= 0) And (FMouseDownItemIndex = LMouseUpIndex) And IsItemSelectable(LMouseUpIndex) Then Begin

        //-------------------------------------------------------------------------
        //Si un gestionnaire de double-clic est branché, le simple clic doit être
        //temporisé pendant le délai système de double-clic.
        //
        //Cela évite la séquence indésirable :
        //- premier MouseUp  -> OnItemClick
        //- DblClick         -> OnItemDblClick
        //
        //Si aucun OnItemDblClick n'est branché, on conserve le comportement
        //immédiat historique.
        //-------------------------------------------------------------------------
        //If Assigned(FOnItemDblClick) Then
        //ScheduleDelayedItemClick(
        //LMouseUpIndex,
        //Button,
        //Shift,
        //X,
        //Y)
        //Else
        //ExecuteItemActivation(
        //LMouseUpIndex,
        //Button,
        //Shift,
        //X,
        //Y);
        If Assigned(FOnItemDblClick) Then Begin
            //-------------------------------------------------------------------------
            //Un gestionnaire de double-clic est branché.
            //
            //On sépare volontairement deux responsabilités :
            //
            //1) Activation interne immédiate :
            //- sélection visuelle ;
            //- BarCurrentItemIndex ;
            //- état Checked éventuel ;
            //- OnChanging / OnChange.
            //
            //Cette partie doit rester immédiate, sinon un simple clic semble ne rien
            //faire tant que le délai de double-clic n'est pas écoulé.
            //
            //2) Notification applicative OnItemClick :
            //- elle est différée pendant le délai système de double-clic ;
            //- elle sera annulée si un vrai double-clic est confirmé.
            //
            //Cette organisation évite la séquence indésirable :
            //premier MouseUp -> OnItemClick
            //DblClick        -> OnItemDblClick
            //
            //tout en conservant une interface immédiatement réactive.
            //-------------------------------------------------------------------------
            ApplyItemActivationState(LMouseUpIndex);

            ScheduleDelayedItemClick(
                LMouseUpIndex,
                Button,
                Shift,
                X,
                Y);
        End
        Else
            ExecuteItemActivation(
                LMouseUpIndex,
                Button,
                Shift,
                X,
                Y);
    End;

    ResetTabDragState;
    FMouseDownItemIndex := -1;
End;

Procedure TNoReflowTabBar.KeyDown(
    Var Key: Word;
    Shift: TShiftState);
Var
    Idx: Integer;
Begin
    //-------------------------------------------------------------------------
    //Gère la navigation clavier dans la barre.
    //
    //Règles retenues :
    //- barre horizontale : flèches gauche / droite
    //- barre verticale   : flèches haut / bas
    //- Home              : premier item sélectionnable
    //- End               : dernier item sélectionnable
    //
    //Quand une touche est consommée par le composant, Key est remis à 0
    //pour empêcher un traitement supplémentaire en aval.
    //-------------------------------------------------------------------------

    Inherited;

    //Navigation clavier simple :
    //- horizontal : gauche / droite
    //- vertical   : haut / bas
    //- home / end : premier / dernier item selectable
    Case Key Of
        VK_F2: Begin
                If BeginEditItemCaption(FItemIndex) Then
                    Key := 0;
            End;

        VK_LEFT: Begin
                If IsHorizontalBar Then Begin
                    SelectPrevious;
                    Key := 0;
                End;
            End;

        VK_RIGHT: Begin
                If IsHorizontalBar Then Begin
                    SelectNext;
                    Key := 0;
                End;
            End;

        VK_UP: Begin
                If IsVerticalBar Then Begin
                    SelectPrevious;
                    Key := 0;
                End;
            End;

        VK_DOWN: Begin
                If IsVerticalBar Then Begin
                    SelectNext;
                    Key := 0;
                End;
            End;

        VK_HOME: Begin
                Idx := FindNextSelectableItem(0);
                If Idx >= 0 Then Begin
                    SetBarCurrentItemIndex(Idx);
                    Key := 0;
                End;
            End;

        VK_END: Begin
                Idx := FindPreviousSelectableTab(FItems.Count - 1);
                If Idx >= 0 Then Begin
                    SetBarCurrentItemIndex(Idx);
                    Key := 0;
                End;
            End;
    End;
End;

Procedure TNoReflowTabBar.DoEnter;
Begin
    //-------------------------------------------------------------------------
    //Appelée quand le contrôle reçoit le focus clavier.
    //
    //Le focus peut modifier l'apparence de l'item courant
    //si BarShowFocus est actif. Il suffit donc d'invalider cet item.
    //-------------------------------------------------------------------------

    Inherited;

    //Si l'entrée de focus provient d'un clic qui va immédiatement
    //changer la sélection, on évite un repaint intermédiaire inutile.
    If FSuppressFocusInvalidate Then
        Exit;

    //Lapparence de l'item courant peut changer
    //quand le contrôle prend le focus.
    InvalidateItem(GetFocusVisualItemIndex);
End;

Procedure TNoReflowTabBar.DoExit;
Begin
    //-------------------------------------------------------------------------
    //Appelée quand le contrôle perd le focus clavier.
    //
    //Mme logique que DoEnter : seul l'item courant a potentiellement
    //besoin dtre redessin pour enlever lindication visuelle de focus.
    //-------------------------------------------------------------------------

    Inherited;

    HideCustomHint;

    //Mme logique quand le contrôle perd le focus.
    InvalidateItem(GetFocusVisualItemIndex);
End;

Procedure TNoReflowTabBar.CancelDelayedItemClick;
Begin
    //-------------------------------------------------------------------------
    //Annule un OnItemClick en attente.
    //
    //Cette méthode est appelée notamment lorsqu'un double-clic est confirmé :
    //le premier clic ne doit alors plus déclencher OnItemClick.
    //-------------------------------------------------------------------------

    If FDelayedItemClickTimer <> Nil Then
        FDelayedItemClickTimer.Enabled := False;

    FDelayedItemClickIndex := -1;
    FDelayedItemClickKey := 0;
    FDelayedItemClickButton := mbLeft;
    FDelayedItemClickShift := [];
    FDelayedItemClickPos := Point(
        -1,
        -1);
End;

Procedure TNoReflowTabBar.ScheduleDelayedItemClick(
    AItemIndex: Integer;
    Button: TMouseButton;
    Shift: TShiftState;
    X, Y: Integer);
Var
    Item: TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Programme le déclenchement différé de OnItemClick.
    //
    //On mémorise l'index et la clé technique de l'item.
    //La clé permet de vérifier au moment du timer que l'index pointe encore
    //sur le même item, même si la collection a été modifiée entre-temps.
    //-------------------------------------------------------------------------

    If FDelayedItemClickTimer = Nil Then
        Exit;

    If (AItemIndex < 0) Or (AItemIndex >= FItems.Count) Then
        Exit;

    Item := FItems[AItemIndex];

    If Item = Nil Then
        Exit;

    FDelayedItemClickTimer.Enabled := False;

    FDelayedItemClickIndex := AItemIndex;
    FDelayedItemClickKey := Item.ItemKey;
    FDelayedItemClickButton := Button;
    FDelayedItemClickShift := Shift;
    FDelayedItemClickPos := Point(
        X,
        Y);

    FDelayedItemClickTimer.Interval := GetDoubleClickTime + 10;
    FDelayedItemClickTimer.Enabled := True;
End;

Procedure TNoReflowTabBar.ExecuteDelayedItemClick;
Var
    ItemIndex: Integer;
    ItemKey:   Integer;
    Button:    TMouseButton;
    Shift:     TShiftState;
    Pos:       TPoint;
    Item:      TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Exécute le clic différé.
    //
    //On repasse volontairement par ExecuteItemActivation plutôt que par
    //DoItemClick directement.
    //
    //Raison :
    //ExecuteItemActivation est le chemin normal du composant. Il applique les
    //règles internes liées au mode de barre :
    //- sélection d'onglet ;
    //- bouton sélectionnable ;
    //- bouton checkable ;
    //- bouton push ;
    //- notification OnItemClick.
    //
    //Le timer ne doit donc pas court-circuiter cette logique.
    //-------------------------------------------------------------------------

    ItemIndex := FDelayedItemClickIndex;
    ItemKey := FDelayedItemClickKey;
    Button := FDelayedItemClickButton;
    Shift := FDelayedItemClickShift;
    Pos := FDelayedItemClickPos;

    CancelDelayedItemClick;

    If (ItemIndex < 0) Or (ItemIndex >= FItems.Count) Then
        Exit;

    If Not IsItemSelectable(ItemIndex) Then
        Exit;

    Item := FItems[ItemIndex];

    If Item = Nil Then
        Exit;

    If Item.ItemKey <> ItemKey Then
        Exit;

    //-------------------------------------------------------------------------
    //Le MouseUp a déjà validé que l'utilisateur avait bien cliqué sur l'item.
    //
    //Ici, le timer ne doit plus refaire toute l'activation interne, car cette
    //méthode est conçue pour le cycle souris immédiat.
    //
    //Le rôle du timer est uniquement de déclencher OnItemClick après expiration
    //du délai de double-clic, si aucun DblClick n'a annulé l'action.
    //-------------------------------------------------------------------------
    DoItemClick(
        ItemIndex,
        Item,
        Button,
        Shift,
        Pos.X,
        Pos.Y);
End;

Procedure TNoReflowTabBar.DelayedItemClickTimer(Sender: TObject);
Begin
    If FDelayedItemClickTimer <> Nil Then
        FDelayedItemClickTimer.Enabled := False;

    ExecuteDelayedItemClick;
End;

Procedure TNoReflowTabBar.DblClick;
Var
    P:    TPoint;
    Idx:  Integer;
    Item: TNoReflowTabBarItem;
Begin
    Inherited;

    EnsureRenderInfo;

    P := ScreenToClient(Mouse.CursorPos);
    Idx := ItemAtPos(P);

    If (Idx < 0) Or (Idx >= FItems.Count) Then
        Exit;

    If Not IsItemSelectable(Idx) Then
        Exit;

    //-------------------------------------------------------------------------
    //Un vrai double-clic vient d'être confirmé.
    //
    //Le clic simple qui avait été programmé lors du premier MouseUp ne doit
    //plus être exécuté.
    //
    //Important :
    //il faut annuler ce timer AVANT BeginEditItemCaption ou DoItemDblClick,
    //car ces appels peuvent ouvrir un éditeur ou une boîte de dialogue modale.
    //Si le timer reste actif, il peut se déclencher pendant ou juste après
    //cette boîte de dialogue.
    //-------------------------------------------------------------------------
    CancelDelayedItemClick;

    //-------------------------------------------------------------------------
    //Le double-clic consommée aussi le MouseUp final du second clic.
    //
    //La séquence Windows typique est :
    //1) MouseDown
    //2) MouseUp       -> clic simple potentiel, maintenant différé
    //3) MouseDown
    //4) DblClick
    //5) MouseUp       -> ne doit surtout pas redevenir un clic simple
    //-------------------------------------------------------------------------
    FSuppressNextMouseUpClick := True;

    //-------------------------------------------------------------------------
    //Le second MouseDown du double-clic a pu réarmer le pré-drag.
    //On annule donc explicitement l'état de drag/tracking avant d'appeler le
    //code applicatif.
    //-------------------------------------------------------------------------
    FDragTracking := False;
    FDragActive := False;
    FDragSourceIndex := -1;
    FDragStartPos := Point(
        -1,
        -1);
    FDragTarget.Init;

    FPressedItemIndex := -1;
    FMouseDownItemIndex := -1;

    ClearExternalDraggedBarItemPreview;
    ClearItemDragHotItem;

    If GetCapture = Handle Then
        ReleaseCapture;

    Screen.Cursor := crDefault;
    HideCustomHint;
    Invalidate;

    //Priorité à l'édition directe si elle est autorisée.
    If BeginEditItemCaption(Idx) Then
        Exit;

    Item := FItems[Idx];

    DoItemDblClick(
        Idx,
        Item,
        KeyboardStateToShiftState,
        P.X,
        P.Y);
End;

Initialization

InitGDIPlus;

Finalization

ShutdownGDIPlus;

End.
