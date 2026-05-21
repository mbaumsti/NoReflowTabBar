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
    NoReflowTabBar_ZoneLayout,
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
    //  doivent rester visibles.
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

end.

