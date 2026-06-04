Unit NoReflowTabBar_RenderBackend;

{
  NoReflowTabBar_RenderBackend.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Common rendering backend contract of the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    See LICENSE file.

  ------------------------------------------------------------------------------

  Socle commun des backends de rendu du composant NoReflowTabBar.

  Cette unite fixe le contrat commun des backends de rendu. Elle ne dessine pas.
  Elle declare uniquement :

  - le type de backend demande par la barre ;
  - les options de peinture partagees ;
  - les structures de primitives deja resolues ;
  - le contexte minimal expose aux backends separes.

  Regle d'architecture
  --------------------
  Le layout prepare les positions, rectangles, contours, metriques et donnees
  de contenu. Les backends GDI et Direct2D doivent uniquement dessiner ces
  primitives. Ils ne doivent pas recalculer localement les positions pour
  contourner un probleme visuel.

  Les unites concretes de rendu doivent rester isolees :

  - NoReflowTabBar_RenderBackend_GDI ne depend pas du backend Direct2D ;
  - NoReflowTabBar_RenderBackend_Direct2D ne depend pas du backend GDI.

  Toute logique commune doit remonter dans LayoutSupport ou RenderSupport.
}

Interface

Uses
    System.Types,
    Winapi.Windows,
    Vcl.Graphics,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_RenderTypes;

Type
    {
      Identifie la famille de backend de rendu demandee par le composant.

      ntrbkGDI conserve le renderer historique GDI/GDI+. Il reste disponible
      pour la compatibilite, les comparaisons de rendu et les personnalisations
      TCanvas exposees par OnGDIPaintItem.

      ntrbkDirect2D selectionne le backend Direct2D stabilise en version
      publique 1.3. Ce backend dessine nativement les items, les textes, les
      glyphs, les signaux et les headers a partir des donnees communes. Pour les
      styles VCL textures, le fond general peut etre peint par VCL/GDI avant le
      contenu Direct2D afin de reproduire fidelement le style.
    }
    TNoReflowTabBarRenderBackendKind = (
        ntrbkGDI,
        ntrbkDirect2D
    );

    {
      Option de peinture commune aux backends.

      Cette granularite permet de separer proprement les couches deja peintes
      par un backend natif et celles qui restent a produire par le chemin
      historique. Elle sert notamment au rendu hybride limite du fond style VCL
      texture, sans autoriser les backends a recalculer le layout.
    }
    TNoReflowTabBarRenderPaintOption = (
        //---------------------------------------------------------------------
        // Le fond general de la barre a deja ete peint par le backend appelant.
        // Le fallback GDI doit donc conserver les headers et les items, mais ne
        // doit pas effacer a nouveau le ClientRect.
        //---------------------------------------------------------------------
        ntrpoSkipBarBackground,

        //---------------------------------------------------------------------
        // Les surfaces standard des items ont deja ete peintes par le backend
        // appelant. Le fallback GDI doit encore parcourir le pipeline des items
        // pour conserver evenements, voyants, glyphs, texte et focus, mais il
        // ne doit pas redessiner les fonds ni les bordures standard.
        //---------------------------------------------------------------------
        ntrpoSkipItemSurfaces
    );

    TNoReflowTabBarRenderPaintOptions = Set Of TNoReflowTabBarRenderPaintOption;


    {
      Donnees resolues d'une surface d'item pouvant etre peinte par un backend
      separe.

      Ce record contient volontairement des couleurs et une geometrie finales.
      Le backend Direct2D n'a donc pas a recalculer la palette, l'etat visuel,
      le mode bouton/onglet, le bord ouvert de l'onglet selectionne ni la
      politique de bordure des boutons.
    }
    TNoReflowTabBarDirect2DItemSurfaceInfo = Record
        RenderItem: TNoReflowTabBarRenderItem;
        VisualState: TNoReflowTabBarItemVisualState;
        IsButton: Boolean;
        DrawBorder: Boolean;
        DrawClosedBorder: Boolean;
        BorderWidth: Single;
        TopColor: TColor;
        BottomColor: TColor;
        BorderColor: TColor;

        //---------------------------------------------------------------------
        // Donnees de contenu pre-resolues pour le backend Direct2D autonome.
        //
        // Le backend Direct2D ne doit pas rappeler le backend GDI pour obtenir
        // le texte, les couleurs ou la police effective de l'item. Le contexte
        // fournit donc ici les valeurs finales calculees par le meme pipeline
        // que le rendu historique : texte resolu, couleur de texte, police
        // standard enrichie par le style de selection, et couleurs du voyant.
        //---------------------------------------------------------------------
        Text: String;
        TextColor: TColor;
        FontName: String;
        FontSize: Integer;
        FontHeight: Integer;
        FontStyle: TFontStyles;
        SignalBrushColor: TColor;
        SignalPenColor: TColor;

        //---------------------------------------------------------------------
        // Focus clavier resolu par le contexte du composant.
        //
        // Le backend Direct2D ne doit pas interroger l'etat VCL du controle ni
        // recalculer la zone utile du contenu. Si DrawFocus=True, FocusRect est
        // deja exprime dans le repere final du controle et peut etre dessine
        // directement par le backend natif.
        //---------------------------------------------------------------------
        DrawFocus: Boolean;
        FocusRect: TRect;
        FocusColor: TColor;
    End;



    {
      Segment de filet decoratif d'un header de zone.

      Les points sont deja exprimes dans le repere final du controle. Le backend
      Direct2D ne doit donc plus appliquer la transformation canonique de layout
      a ces segments : cette responsabilite reste dans le contexte du composant,
      au meme endroit que pour le backend GDI historique.
    }
    TNoReflowTabBarDirect2DZoneHeaderSegment = Record
        P1: TPoint;
        P2: TPoint;
    End;

    {
      Donnees resolues d'un header de zone pour un backend separe.

      Depuis v71, le header est calcule par la couche layout du composant, car
      il depend de la zone logique, de la position de barre, du mode de placement
      du header et de la transformation canonique du moteur de zones. Le backend
      Direct2D recoit uniquement les primitives finales : segments, point
      d'ancrage du texte, metriques et police.
    }
    TNoReflowTabBarDirect2DZoneHeaderInfo = Record
        PinZone: TNoReflowTabBarPinZone;
        Text: String;
        FullText: String;
        TextColor: TColor;
        LineColor: TColor;
        FontName: String;
        FontSize: Integer;
        FontHeight: Integer;
        FontStyle: TFontStyles;
        TextOrientation: TNoReflowTabBarTextOrientation;
        TextInsertPoint: TPoint;
        TextWidth: Integer;
        TextHeight: Integer;
        SegmentCount: Integer;
        Segments: Array[0..3] Of TNoReflowTabBarDirect2DZoneHeaderSegment;
    End;

    {
      Contexte minimal fourni aux backends separes.

      Le backend Direct2D n'herite pas du composant ni du backend GDI. Il a
      pourtant besoin de quelques informations stables pour dessiner dans le
      repere final du controle : le rectangle client et, pour cette premiere
      passe native, la couleur de fond solide de la barre.

      Les methodes restent volontairement limitees. Toute nouvelle information
      exposee ici devra correspondre a un besoin reel du backend natif, afin de
      ne pas reconstituer implicitement toute la classe du composant dans une
      interface trop large.
    }
    INoReflowTabBarRenderContext = Interface
        ['{74EC7D69-1B8B-4F69-83F2-29C7C314C3B8}']

        Function GetRenderClientRect: TRect;
        Function CanUseDirect2DSolidBarBackground: Boolean;
        Function GetDirect2DSolidBarBackgroundColor: TColor;

        //Dessine le fond general par le chemin VCL/GDI commun lorsque le fond
        //ne peut pas etre reduit a une couleur solide Direct2D.
        //
        //Cette methode est principalement destinee au cas BarPaletteMode =
        //nrtcmStyle : le style VCL peut y produire un fond parent texture,
        //degrade ou dependant du theme. Le backend Direct2D ne doit pas
        //inventer une approximation locale de ce fond.
        //
        //Important : cette methode ne delegue pas le rendu complet au backend
        //GDI. Elle peint seulement la couche de fond avant les passes natives
        //Direct2D.
        Function PaintBarBackgroundToCanvas(ACanvas: TCanvas): Boolean;

        Function CanUseDirect2DItemSurfaces: Boolean;

        Procedure PrepareDirect2DItemSurfaces;
        Function GetDirect2DItemSurfaceCount: Integer;
        Function GetDirect2DItemSurfaceInfo(
            AIndex: Integer;
            Out ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;

        //Prepare les donnees de headers de zones pour le backend Direct2D.
        //Comme pour les items, le layout reste proprietaire du positionnement
        //et de la transformation canonique ; le backend natif ne lit que des
        //donnees finales deja resolues.
        Procedure PrepareDirect2DZoneHeaders;
        Function GetDirect2DZoneHeaderCount: Integer;
        Function GetDirect2DZoneHeaderInfo(
            AIndex: Integer;
            Out AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Boolean;

        //Remplit ABitmap avec le glyph issu de BarImages.
        //Le bitmap reste possede par l'appelant : le contexte ne fait que le
        //charger depuis l'ImageList courante, afin que le backend Direct2D
        //puisse ensuite le convertir en ID2D1Bitmap sans connaitre FBarImages.
        Function GetDirect2DItemGlyphBitmap(
            AImageIndex: Integer;
            ABitmap: TBitmap): Boolean;
    End;

    {
      Contrat commun d'un backend de rendu complet.

      PaintToCanvas conserve le point d'entree simple utilise par le composant.
      PaintToCanvasWithOptions est utilise entre backends pendant la migration :
      il permet au backend Direct2D de confier le reste du rendu au fallback GDI
      sans lui demander de redessiner une partie deja prise en charge nativement.
    }
    INoReflowTabBarRenderBackend = Interface
        ['{BBD5A7A5-5F62-4D8B-A0E2-BE89D96E1D79}']

        Function GetBackendName: String;

        Procedure PaintToCanvas(ACanvas: TCanvas);
        Procedure PaintToCanvasWithOptions(
            ACanvas: TCanvas;
            AOptions: TNoReflowTabBarRenderPaintOptions);

        Property BackendName: String Read GetBackendName;
    End;

{
  Cree le backend effectif pour le type demande.

  Le cas GDI retourne le fallback historique porte par la chaine d'heritage du
  composant. Le cas Direct2D cree un objet separe et lui injecte a la fois le
  fallback GDI et le contexte de lecture minimal.
}
Function CreateNoReflowTabBarRenderBackend(
    ABackendKind: TNoReflowTabBarRenderBackendKind;
    AFallbackBackend: INoReflowTabBarRenderBackend;
    ARenderContext: INoReflowTabBarRenderContext): INoReflowTabBarRenderBackend;

Implementation

Uses
    NoReflowTabBar_RenderBackend_Direct2D;

Function CreateNoReflowTabBarRenderBackend(
    ABackendKind: TNoReflowTabBarRenderBackendKind;
    AFallbackBackend: INoReflowTabBarRenderBackend;
    ARenderContext: INoReflowTabBarRenderContext): INoReflowTabBarRenderBackend;
Begin
    Case ABackendKind Of
        ntrbkGDI:
            Result := AFallbackBackend;

        ntrbkDirect2D:
            Begin
                //-----------------------------------------------------------------
                // Le backend Direct2D reste cree uniquement ici afin que ses
                // dependances natives ne remontent ni dans le coeur du composant,
                // ni dans l'unite GDI historique.
                //-----------------------------------------------------------------
                Result := TNoReflowTabBarDirect2DRenderBackend.Create(
                    AFallbackBackend,
                    ARenderContext);
            End;
    Else
        Result := AFallbackBackend;
    End;
End;

End.
