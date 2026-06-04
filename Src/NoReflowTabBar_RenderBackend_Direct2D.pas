Unit NoReflowTabBar_RenderBackend_Direct2D;

{
  NoReflowTabBar_RenderBackend_Direct2D.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Direct2D rendering backend of the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    See LICENSE file.

  ------------------------------------------------------------------------------

  Backend Direct2D du composant NoReflowTabBar.

  Responsabilites
  ----------------
  Cette unite contient le backend Direct2D autonome du composant. Lorsque
  BarRenderBackendKind vaut ntrbkDirect2D, le rendu standard est produit par
  Direct2D / DirectWrite sans repasse GDI silencieuse.

  Les hooks reposant sur TCanvas restent volontairement rattaches au backend
  GDI, notamment OnGDIPaintItem. Un futur hook Direct2D devra exposer un contrat
  natif adapte, sans melanger les deux backends pendant la meme passe de rendu.

  Regle d'architecture imperative
  -------------------------------
  Le backend Direct2D doit dessiner directement dans le repere final de la barre.
  Il ne doit pas dessiner une barre GDI dans un bitmap intermediaire pour ensuite
  la convertir ou la projeter avec Direct2D.

  Cette unite n'herite pas du backend GDI. Le fallback GDI reste conserve sous
  forme d'interface pour les strategies hybrides limitees, notamment le fond
  style VCL texture. Il ne doit pas devenir un moyen de corriger localement le
  layout ou de masquer une primitive Direct2D mal preparee.

  REGLE D'OR v71 : IL NE FAUT PAS FAIRE DE CALCUL DE POSITION ICI.

  Direct2D dessine les primitives deja resolues par le contexte/layout :
  - polygons d'items ;
  - rectangles et points de texte ;
  - rectangles de glyph ;
  - rectangles de voyant ;
  - segments et points d'insertion des headers de zones.

  Les matrices Direct2D sont autorisees uniquement comme transformations de
  dessin autour de primitives finales. Elles ne doivent pas devenir des
  corrections de layout. Toute anomalie de placement doit etre corrigee dans
  NoReflowTabBar_ZoneLayout.pas, NoReflowTabBar_LayoutSupport.pas ou
  TNoReflowTabBarItemContentLayoutEngine, jamais dans ce backend.
}

Interface

Uses
    System.SysUtils,
    System.Types,
    System.Math,
    Winapi.Windows,
    Winapi.DXGIFormat,
    Winapi.D2D1,
    Vcl.Graphics,
    NoReflowTabBar_RenderBackend,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_Library;

Type
    {
      Etat interne du backend Direct2D.

      L'enumeration reste privee a cette unite : l'API publique choisit un type
      de backend, mais ne doit pas connaitre les details du cycle de vie natif.
    }
    TNoReflowTabBarDirect2DRenderState = (
        ntd2dNotInitialized,
        ntd2dFactoryAvailable,
        ntd2dFactoryFailed,
        ntd2dDirectWriteFactoryFailed,
        ntd2dDirectWriteFactoryQueryFailed,
        ntd2dDCRenderTargetFailed,
        ntd2dDCRenderTargetBindFailed,
        ntd2dDCRenderTargetBound,
        ntd2dSolidBackgroundCompleted,
        ntd2dItemSurfacesCompleted,
        ntd2dItemContentsCompleted,
        ntd2dZoneHeadersCompleted,
        ntd2dItemSurfaceDebugCompleted,
        ntd2dItemGeometryDebugCompleted,
        ntd2dRenderFailed,
        ntd2dReleased
    );

    {
      Backend Direct2D separe.

      Le backend Direct2D dessine le rendu standard complet dans le repere final
      du controle : headers, surfaces, gradients, texte, glyphs, signaux et
      focus. Le fond general peut etre peint par le chemin VCL/GDI uniquement
      lorsque le style actif utilise une texture qu'une couleur Direct2D solide
      ne peut pas reproduire. Ce cas reste limite au background.
    }
    TNoReflowTabBarDirect2DRenderBackend = Class(TInterfacedObject, INoReflowTabBarRenderBackend)
    private
        //---------------------------------------------------------------------
        // Fallback vers le backend historique valide.
        //---------------------------------------------------------------------
        FFallbackBackend: INoReflowTabBarRenderBackend;

        //---------------------------------------------------------------------
        // Contexte minimal fourni par la facade du composant.
        //---------------------------------------------------------------------
        FRenderContext: INoReflowTabBarRenderContext;

        //---------------------------------------------------------------------
        // Ressources natives Direct2D.
        //---------------------------------------------------------------------
        FD2DFactory: ID2D1Factory;
        FDWriteFactory: IDWriteFactory;
        FDCRenderTarget: ID2D1DCRenderTarget;

        //---------------------------------------------------------------------
        // Etat de diagnostic interne.
        //---------------------------------------------------------------------
        FRenderState: TNoReflowTabBarDirect2DRenderState;
        FLastNativeError: HResult;

        Procedure InitializeDirect2DResources;
        Procedure ReleaseDirect2DResources;
        Procedure ReleaseDirect2DRenderTarget;
        Procedure CreateDirect2DRenderTarget;

        Function Direct2DResourcesAvailable: Boolean;
        Function Direct2DRenderTargetAvailable: Boolean;
        Function DirectWriteResourcesAvailable: Boolean;
        Function BindDirect2DRenderTargetToCanvas(
            ACanvas: TCanvas;
            Const AClientRect: TRect): Boolean;

        Function PaintSolidBarBackgroundWithDirect2D(ACanvas: TCanvas): Boolean;
        Function PaintBarBackgroundWithDirect2D(ACanvas: TCanvas): Boolean;
        Function PaintZoneHeadersWithDirect2D(ACanvas: TCanvas): Boolean;
        Function PaintItemSurfacesWithDirect2D(ACanvas: TCanvas): Boolean;
        Function PaintItemContentsWithDirect2D(ACanvas: TCanvas): Boolean;
        Function PaintItemGeometryDebugWithDirect2D(ACanvas: TCanvas): Boolean;
        Function PaintItemSurfaceDebugWithDirect2D(ACanvas: TCanvas): Boolean;

        Function ColorToDirect2DColor(AColor: TColor): D2D1_COLOR_F;
        Function ColorToDirect2DColorWithAlpha(
            AColor: TColor;
            AAlpha: Single): D2D1_COLOR_F;
        Function CreateSolidBrush(
            Const AColor: D2D1_COLOR_F;
            Out ABrush: ID2D1SolidColorBrush): Boolean;
        Function CreateItemFillBrush(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo;
            AFillAlpha: Single;
            Out ABrush: ID2D1Brush): Boolean;
        Function BuildPolygonGeometry(
            Const APoints: TArray<TPoint>;
            AClosed: Boolean;
            Out AGeometry: ID2D1PathGeometry): Boolean;
        Function IsSolidDirect2DSurfaceSet: Boolean;
        Function PaintOneDirect2DItemSurfaceCore(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo;
            AFillAlpha: Single;
            ABorderAlpha: Single;
            ABorderWidth: Single): Boolean;
        Function PaintOneDirect2DItemSurface(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
        Function PaintOneDirect2DItemSurfaceDebug(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
        Function PaintOneDirect2DZoneHeader(
            Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Boolean;
        Function PaintOneDirect2DZoneHeaderText(
            Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Boolean;
        Function CreateZoneHeaderTextFormat(
            Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo;
            Out ATextFormat: IDWriteTextFormat): Boolean;
        Function ResolveDirectWriteZoneHeaderFontWeight(
            Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): DWRITE_FONT_WEIGHT;
        Function ResolveDirectWriteZoneHeaderFontStyle(
            Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): DWRITE_FONT_STYLE;
        Function ResolveDirectWriteZoneHeaderFontSize(
            Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Single;
        Function PaintOneDirect2DItemContent(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
        Function PaintOneDirect2DItemSignal(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
        Function BuildDirect2DSignalPieGeometry(
            Const ASignalRect: TRect;
            APercent: Double;
            AStartAngleDeg: Double;
            Out AGeometry: ID2D1PathGeometry): Boolean;
        Function PaintOneDirect2DItemGlyph(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
        Function CreateDirect2DBitmapFromVclBitmap(
            ABitmap: TBitmap;
            Out ADirectBitmap: ID2D1Bitmap): Boolean;
        Function PaintOneDirect2DItemText(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
        Function PaintOneDirect2DItemFocus(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
        Function CreateItemTextFormat(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo;
            Out ATextFormat: IDWriteTextFormat): Boolean;
        Function ResolveDirectWriteFontWeight(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): DWRITE_FONT_WEIGHT;
        Function ResolveDirectWriteFontStyle(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): DWRITE_FONT_STYLE;
        Function ResolveDirectWriteFontSize(
            Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Single;

        Function Direct2DRenderStateToText(
            AState: TNoReflowTabBarDirect2DRenderState): String;
        Function LastNativeErrorText: String;

        Procedure FallbackPaintToCanvas(
            ACanvas: TCanvas;
            AOptions: TNoReflowTabBarRenderPaintOptions);

    public
        Constructor Create(
            AFallbackBackend: INoReflowTabBarRenderBackend;
            ARenderContext: INoReflowTabBarRenderContext);
        Destructor Destroy; Override;

        Function GetBackendName: String;

        Procedure PaintToCanvas(ACanvas: TCanvas);
        Procedure PaintToCanvasWithOptions(
            ACanvas: TCanvas;
            AOptions: TNoReflowTabBarRenderPaintOptions);
    End;

Implementation

Constructor TNoReflowTabBarDirect2DRenderBackend.Create(
    AFallbackBackend: INoReflowTabBarRenderBackend;
    ARenderContext: INoReflowTabBarRenderContext);
Begin
    Inherited Create;

    //--------------------------------------------------------------------------
    // Les deux references sont injectees par la factory commune :
    // - le fallback conserve le comportement historique ;
    // - le contexte donne les informations minimales utiles au rendu natif.
    //--------------------------------------------------------------------------
    FFallbackBackend := AFallbackBackend;
    FRenderContext := ARenderContext;
    FRenderState := ntd2dNotInitialized;
    FLastNativeError := 0;

    InitializeDirect2DResources;
End;

Destructor TNoReflowTabBarDirect2DRenderBackend.Destroy;
Begin
    ReleaseDirect2DResources;

    FRenderContext := Nil;
    FFallbackBackend := Nil;

    Inherited Destroy;
End;

Procedure TNoReflowTabBarDirect2DRenderBackend.InitializeDirect2DResources;
Var
    LResult: HResult;
    LWriteResult: HResult;
    LWriteFactoryUnknown: IUnknown;
Begin
    //--------------------------------------------------------------------------
    // Creation non bloquante de la factory Direct2D.
    //
    // Important : ne jamais lever d'exception ici. Si Direct2D est indisponible,
    // le backend reste utilisable via le fallback GDI.
    //--------------------------------------------------------------------------
    FD2DFactory := Nil;
    FDWriteFactory := Nil;
    FDCRenderTarget := Nil;
    LWriteFactoryUnknown := Nil;
    FLastNativeError := 0;
    FRenderState := ntd2dNotInitialized;

    LResult := D2D1CreateFactory(
        D2D1_FACTORY_TYPE_SINGLE_THREADED,
        ID2D1Factory,
        Nil,
        FD2DFactory);

    If LResult < 0 Then Begin
        FRenderState := ntd2dFactoryFailed;
        FLastNativeError := LResult;
        FD2DFactory := Nil;
        Exit;
    End;

    //--------------------------------------------------------------------------
    // Creation non bloquante de la factory DirectWrite.
    //
    // Le backend Direct2D utilise DirectWrite pour le texte des items. La
    // factory DirectWrite reste independante de la factory Direct2D : si elle
    // echoue, les surfaces peuvent encore etre peintes, mais le contenu texte
    // restera absent, ce qui signale clairement le blocage natif.
    //--------------------------------------------------------------------------
    LWriteResult := DWriteCreateFactory(
        DWRITE_FACTORY_TYPE_SHARED,
        IDWriteFactory,
        LWriteFactoryUnknown);

    If LWriteResult < 0 Then Begin
        FRenderState := ntd2dDirectWriteFactoryFailed;
        FLastNativeError := LWriteResult;
        FDWriteFactory := Nil;
    End Else If Not Supports(LWriteFactoryUnknown, IDWriteFactory, FDWriteFactory) Then Begin
        FRenderState := ntd2dDirectWriteFactoryQueryFailed;
        FLastNativeError := 0;
        FDWriteFactory := Nil;
    End Else Begin
        FRenderState := ntd2dFactoryAvailable;
        FLastNativeError := 0;
    End;

    LWriteFactoryUnknown := Nil;

    CreateDirect2DRenderTarget;
End;

Procedure TNoReflowTabBarDirect2DRenderBackend.ReleaseDirect2DResources;
Begin
    //--------------------------------------------------------------------------
    // Liberation explicite des references COM natives. Cela rend le cycle de vie
    // lisible au design-time, lors des changements de propriete ou lors de la
    // destruction du composant.
    //--------------------------------------------------------------------------
    ReleaseDirect2DRenderTarget;
    FDWriteFactory := Nil;
    FD2DFactory := Nil;
    FRenderState := ntd2dReleased;
    FLastNativeError := 0;
End;

Procedure TNoReflowTabBarDirect2DRenderBackend.ReleaseDirect2DRenderTarget;
Begin
    FDCRenderTarget := Nil;
End;

Procedure TNoReflowTabBarDirect2DRenderBackend.CreateDirect2DRenderTarget;
Var
    LProperties: D2D1_RENDER_TARGET_PROPERTIES;
    LResult: HResult;
Begin
    //--------------------------------------------------------------------------
    // Le render target DC est cree une seule fois puis rebinde sur le HDC VCL de
    // chaque passe de peinture. Cette separation rend les erreurs de creation et
    // les erreurs de BindDC faciles a diagnostiquer.
    //--------------------------------------------------------------------------
    ReleaseDirect2DRenderTarget;

    If FD2DFactory = Nil Then
        Exit;

    LProperties := D2D1RenderTargetProperties(
        D2D1_RENDER_TARGET_TYPE_DEFAULT,
        D2D1PixelFormat(
            DXGI_FORMAT_B8G8R8A8_UNORM,
            D2D1_ALPHA_MODE_IGNORE),
        0.0,
        0.0,
        D2D1_RENDER_TARGET_USAGE_NONE,
        D2D1_FEATURE_LEVEL_DEFAULT);

    LResult := FD2DFactory.CreateDCRenderTarget(
        LProperties,
        FDCRenderTarget);

    If LResult < 0 Then Begin
        FRenderState := ntd2dDCRenderTargetFailed;
        FLastNativeError := LResult;
        FDCRenderTarget := Nil;
        Exit;
    End;

    FRenderState := ntd2dFactoryAvailable;
    FLastNativeError := 0;
End;

Function TNoReflowTabBarDirect2DRenderBackend.Direct2DResourcesAvailable: Boolean;
Begin
    Result := FD2DFactory <> Nil;
End;

Function TNoReflowTabBarDirect2DRenderBackend.Direct2DRenderTargetAvailable: Boolean;
Begin
    Result := FDCRenderTarget <> Nil;
End;

Function TNoReflowTabBarDirect2DRenderBackend.DirectWriteResourcesAvailable: Boolean;
Begin
    Result := FDWriteFactory <> Nil;
End;

Function TNoReflowTabBarDirect2DRenderBackend.BindDirect2DRenderTargetToCanvas(
    ACanvas: TCanvas;
    Const AClientRect: TRect): Boolean;
Var
    LResult: HResult;
Begin
    Result := False;

    If ACanvas = Nil Then
        Exit;

    If FDCRenderTarget = Nil Then
        Exit;

    If IsRectEmpty(AClientRect) Then
        Exit;

    //--------------------------------------------------------------------------
    // La declaration Delphi de BindDC attend le TRect lui-meme, pas un pointeur.
    // C'est le meme point de compatibilite que celui valide dans VclRotatedEdit.
    //--------------------------------------------------------------------------
    LResult := FDCRenderTarget.BindDC(
        ACanvas.Handle,
        AClientRect);

    If LResult < 0 Then Begin
        FRenderState := ntd2dDCRenderTargetBindFailed;
        FLastNativeError := LResult;
        Exit;
    End;

    FRenderState := ntd2dDCRenderTargetBound;
    FLastNativeError := 0;
    Result := True;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintSolidBarBackgroundWithDirect2D(
    ACanvas: TCanvas): Boolean;
Var
    LClientRect: TRect;
    LColor: TColor;
    LRGBColor: TColor;
    LD2DColor: D2D1_COLOR_F;
    LBrush: ID2D1SolidColorBrush;
    LD2DRect: D2D1_RECT_F;
    LResult: HResult;
Begin
    Result := False;

    If ACanvas = Nil Then
        Exit;

    If FRenderContext = Nil Then
        Exit;

    If Not FRenderContext.CanUseDirect2DSolidBarBackground Then
        Exit;

    If Not Direct2DResourcesAvailable Then
        Exit;

    If Not Direct2DRenderTargetAvailable Then
        Exit;

    LClientRect := FRenderContext.GetRenderClientRect;

    If IsRectEmpty(LClientRect) Then
        Exit;

    If Not BindDirect2DRenderTargetToCanvas(
        ACanvas,
        LClientRect) Then
        Exit;

    //--------------------------------------------------------------------------
    // Conversion TColor -> D2D1_COLOR_F.
    // ColorToRGB est indispensable pour figer les couleurs systeme ou style en
    // valeurs RGB reelles avant normalisation.
    //--------------------------------------------------------------------------
    LColor := FRenderContext.GetDirect2DSolidBarBackgroundColor;
    LRGBColor := ColorToRGB(LColor);

    LD2DColor.r := GetRValue(LRGBColor) / 255.0;
    LD2DColor.g := GetGValue(LRGBColor) / 255.0;
    LD2DColor.b := GetBValue(LRGBColor) / 255.0;
    LD2DColor.a := 1.0;

    LResult := FDCRenderTarget.CreateSolidColorBrush(
        LD2DColor,
        Nil,
        LBrush);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        LBrush := Nil;
        Exit;
    End;

    LD2DRect.left := LClientRect.Left;
    LD2DRect.top := LClientRect.Top;
    LD2DRect.right := LClientRect.Right;
    LD2DRect.bottom := LClientRect.Bottom;

    FDCRenderTarget.BeginDraw;
    FDCRenderTarget.FillRectangle(
        LD2DRect,
        LBrush);
    LResult := FDCRenderTarget.EndDraw(Nil, Nil);

    LBrush := Nil;

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        Exit;
    End;

    FRenderState := ntd2dSolidBackgroundCompleted;
    FLastNativeError := 0;
    Result := True;
End;


Function TNoReflowTabBarDirect2DRenderBackend.PaintBarBackgroundWithDirect2D(
    ACanvas: TCanvas): Boolean;
Var
    LClientRect: TRect;
    LColor: TColor;
    LRGBColor: TColor;
    LD2DColor: D2D1_COLOR_F;
    LBrush: ID2D1SolidColorBrush;
    LD2DRect: D2D1_RECT_F;
    LResult: HResult;
Begin
    //--------------------------------------------------------------------------
    // v78 : fond Direct2D avec preservation des styles VCL textures.
    //
    // Un fond de barre issu de BarPaletteMode = nrtcmStyle ne doit pas etre
    // remplace localement par une couleur Direct2D supposee equivalente. Les
    // styles VCL peuvent utiliser le parent background, des textures, des
    // degrades ou des details que Direct2D ne peut pas deduire d'un TColor.
    //
    // Lorsque le contexte indique qu'un fond solide Direct2D est autorise, ce
    // backend le peint nativement. Sinon, il demande au contexte de peindre
    // uniquement le fond par le chemin VCL/GDI commun, puis continue toutes les
    // autres couches en Direct2D.
    //
    // Ce n'est pas une correction de position, ce n'est pas un calcul de layout
    // et ce n'est pas un fallback GDI complet : c'est la seule maniere fiable de
    // conserver une texture de style VCL sans reimplementer le moteur de style
    // dans Direct2D.
    //--------------------------------------------------------------------------
    Result := False;

    If ACanvas = Nil Then
        Exit;

    If FRenderContext = Nil Then
        Exit;

    If Not FRenderContext.CanUseDirect2DSolidBarBackground Then Begin
        Result := FRenderContext.PaintBarBackgroundToCanvas(ACanvas);
        Exit;
    End;

    If Not Direct2DResourcesAvailable Then
        Exit;

    If Not Direct2DRenderTargetAvailable Then
        Exit;

    LClientRect := FRenderContext.GetRenderClientRect;

    If IsRectEmpty(LClientRect) Then
        Exit;

    If Not BindDirect2DRenderTargetToCanvas(
        ACanvas,
        LClientRect) Then
        Exit;

    LColor := FRenderContext.GetDirect2DSolidBarBackgroundColor;
    LRGBColor := ColorToRGB(LColor);

    LD2DColor.r := GetRValue(LRGBColor) / 255.0;
    LD2DColor.g := GetGValue(LRGBColor) / 255.0;
    LD2DColor.b := GetBValue(LRGBColor) / 255.0;
    LD2DColor.a := 1.0;

    LResult := FDCRenderTarget.CreateSolidColorBrush(
        LD2DColor,
        Nil,
        LBrush);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        LBrush := Nil;
        Exit;
    End;

    LD2DRect.left := LClientRect.Left;
    LD2DRect.top := LClientRect.Top;
    LD2DRect.right := LClientRect.Right;
    LD2DRect.bottom := LClientRect.Bottom;

    FDCRenderTarget.BeginDraw;
    FDCRenderTarget.FillRectangle(
        LD2DRect,
        LBrush);
    LResult := FDCRenderTarget.EndDraw(Nil, Nil);

    LBrush := Nil;

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        Exit;
    End;

    FRenderState := ntd2dSolidBackgroundCompleted;
    FLastNativeError := 0;
    Result := True;
End;


Function TNoReflowTabBarDirect2DRenderBackend.ColorToDirect2DColor(AColor: TColor): D2D1_COLOR_F;
Begin
    Result := ColorToDirect2DColorWithAlpha(
        AColor,
        1.0);
End;

Function TNoReflowTabBarDirect2DRenderBackend.ColorToDirect2DColorWithAlpha(
    AColor: TColor;
    AAlpha: Single): D2D1_COLOR_F;
Var
    LRGBColor: TColor;
Begin
    //--------------------------------------------------------------------------
    // Convertit un TColor VCL, y compris une couleur systeme, en couleur Direct2D
    // normalisee.
    //
    // AAlpha est principalement utilise par les diagnostics non destructifs : le
    // remplissage Direct2D peut ainsi etre observe par-dessus le rendu GDI sans
    // devenir le rendu fonctionnel de reference.
    //--------------------------------------------------------------------------
    LRGBColor := ColorToRGB(AColor);

    Result.r := GetRValue(LRGBColor) / 255.0;
    Result.g := GetGValue(LRGBColor) / 255.0;
    Result.b := GetBValue(LRGBColor) / 255.0;
    Result.a := AAlpha;
End;

Function TNoReflowTabBarDirect2DRenderBackend.CreateSolidBrush(
    Const AColor: D2D1_COLOR_F;
    Out ABrush: ID2D1SolidColorBrush): Boolean;
Var
    LResult: HResult;
Begin
    Result := False;
    ABrush := Nil;

    If FDCRenderTarget = Nil Then
        Exit;

    LResult := FDCRenderTarget.CreateSolidColorBrush(
        AColor,
        Nil,
        ABrush);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        ABrush := Nil;
        Exit;
    End;

    Result := True;
End;

Function TNoReflowTabBarDirect2DRenderBackend.CreateItemFillBrush(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo;
    AFillAlpha: Single;
    Out ABrush: ID2D1Brush): Boolean;
Var
    LSolidBrush: ID2D1SolidColorBrush;
    LGradientBrush: ID2D1LinearGradientBrush;
    LGradientStops: Array[0..1] Of D2D1_GRADIENT_STOP;
    LGradientStopCollection: ID2D1GradientStopCollection;
    LGradientProperties: D2D1_LINEAR_GRADIENT_BRUSH_PROPERTIES;
    LBounds: TRect;
    LHorizontalGradient: Boolean;
    LResult: HResult;
Begin
    //--------------------------------------------------------------------------
    // Cree la brosse de remplissage d'un item Direct2D.
    //
    // La geometrie et le rectangle final restent ceux calcules par le layout.
    // Cette routine ne decide donc pas ou dessiner : elle choisit uniquement
    // comment remplir la surface deja fournie.
    //
    // Regle reprise du backend GDI/GDI+ :
    // - barre horizontale : gradient haut -> bas ;
    // - barre verticale   : gradient gauche -> droite.
    //
    // Si TopColor et BottomColor sont identiques, on conserve une brosse solide
    // afin d'eviter de creer inutilement une collection de stops.
    //--------------------------------------------------------------------------
    Result := False;
    ABrush := Nil;
    LSolidBrush := Nil;
    LGradientBrush := Nil;
    LGradientStopCollection := Nil;

    If FDCRenderTarget = Nil Then
        Exit;

    If ColorToRGB(ASurfaceInfo.TopColor) = ColorToRGB(ASurfaceInfo.BottomColor) Then Begin
        If Not CreateSolidBrush(
            ColorToDirect2DColorWithAlpha(
                ASurfaceInfo.TopColor,
                AFillAlpha),
            LSolidBrush) Then
            Exit;

        ABrush := LSolidBrush As ID2D1Brush;
        Result := True;
        Exit;
    End;

    LBounds := ASurfaceInfo.RenderItem.Bounds;

    If IsRectEmpty(LBounds) Then
        Exit;

    LGradientStops[0].position := 0.0;
    LGradientStops[0].color := ColorToDirect2DColorWithAlpha(
        ASurfaceInfo.TopColor,
        AFillAlpha);
    LGradientStops[1].position := 1.0;
    LGradientStops[1].color := ColorToDirect2DColorWithAlpha(
        ASurfaceInfo.BottomColor,
        AFillAlpha);

    LResult := FDCRenderTarget.CreateGradientStopCollection(
        @LGradientStops[0],
        Length(LGradientStops),
        D2D1_GAMMA_2_2,
        D2D1_EXTEND_MODE_CLAMP,
        LGradientStopCollection);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        LGradientStopCollection := Nil;
        Exit;
    End;

    LHorizontalGradient := ASurfaceInfo.RenderItem.Metrics.TabPosition In [
        nrtbpLeft,
        nrtbpRight];

    If LHorizontalGradient Then Begin
        LGradientProperties.startPoint.x := LBounds.Left;
        LGradientProperties.startPoint.y := LBounds.Top;
        LGradientProperties.endPoint.x := LBounds.Right;
        LGradientProperties.endPoint.y := LBounds.Top;
    End Else Begin
        LGradientProperties.startPoint.x := LBounds.Left;
        LGradientProperties.startPoint.y := LBounds.Top;
        LGradientProperties.endPoint.x := LBounds.Left;
        LGradientProperties.endPoint.y := LBounds.Bottom;
    End;

    LResult := FDCRenderTarget.CreateLinearGradientBrush(
        LGradientProperties,
        Nil,
        LGradientStopCollection,
        LGradientBrush);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        LGradientBrush := Nil;
        LGradientStopCollection := Nil;
        Exit;
    End;

    ABrush := LGradientBrush As ID2D1Brush;
    Result := True;
End;

Function TNoReflowTabBarDirect2DRenderBackend.BuildPolygonGeometry(
    Const APoints: TArray<TPoint>;
    AClosed: Boolean;
    Out AGeometry: ID2D1PathGeometry): Boolean;
Var
    LResult: HResult;
    LGeometrySink: ID2D1GeometrySink;
    LIndex: Integer;
    LD2DPoint: D2D1_POINT_2F;
Begin
    //--------------------------------------------------------------------------
    // Construit une geometrie Direct2D dans le repere final du controle a partir
    // du contour polygonal deja calcule par le moteur de layout historique.
    //
    // AClosed=True est utilise pour les remplissages. AClosed=False permet de
    // respecter le bord ouvert de l'onglet selectionne, comme DrawTabBorder le
    // faisait en GDI/GDI+.
    //--------------------------------------------------------------------------
    Result := False;
    AGeometry := Nil;

    If FD2DFactory = Nil Then
        Exit;

    If Length(APoints) < 2 Then
        Exit;

    LResult := FD2DFactory.CreatePathGeometry(AGeometry);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        AGeometry := Nil;
        Exit;
    End;

    LResult := AGeometry.Open(LGeometrySink);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        AGeometry := Nil;
        Exit;
    End;

    LD2DPoint.x := APoints[0].X;
    LD2DPoint.y := APoints[0].Y;

    LGeometrySink.BeginFigure(
        LD2DPoint,
        D2D1_FIGURE_BEGIN_FILLED);

    For LIndex := 1 To High(APoints) Do Begin
        LD2DPoint.x := APoints[LIndex].X;
        LD2DPoint.y := APoints[LIndex].Y;
        LGeometrySink.AddLine(LD2DPoint);
    End;

    If AClosed Then
        LGeometrySink.EndFigure(D2D1_FIGURE_END_CLOSED)
    Else
        LGeometrySink.EndFigure(D2D1_FIGURE_END_OPEN);

    LResult := LGeometrySink.Close;
    LGeometrySink := Nil;

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        AGeometry := Nil;
        Exit;
    End;

    Result := True;
End;

Function TNoReflowTabBarDirect2DRenderBackend.IsSolidDirect2DSurfaceSet: Boolean;
Var
    LIndex: Integer;
    LCount: Integer;
    LSurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo;
Begin
    //--------------------------------------------------------------------------
    // v20 ne migre que les surfaces assimilables a un aplat. En mode degrade,
    // les couleurs Top/Bottom restent distinctes apres resolution : on garde
    // alors l'integralite du rendu item dans le backend GDI pour eviter toute
    // regression visuelle.
    //--------------------------------------------------------------------------
    Result := False;

    If FRenderContext = Nil Then
        Exit;

    LCount := FRenderContext.GetDirect2DItemSurfaceCount;

    For LIndex := 0 To LCount - 1 Do Begin
        If Not FRenderContext.GetDirect2DItemSurfaceInfo(
            LIndex,
            LSurfaceInfo) Then
            Continue;

        If ColorToRGB(LSurfaceInfo.TopColor) <> ColorToRGB(LSurfaceInfo.BottomColor) Then
            Exit;
    End;

    Result := True;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintOneDirect2DItemSurfaceCore(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo;
    AFillAlpha: Single;
    ABorderAlpha: Single;
    ABorderWidth: Single): Boolean;
Var
    LFillBrush: ID2D1Brush;
    LBorderBrush: ID2D1SolidColorBrush;
    LFillGeometry: ID2D1PathGeometry;
    LBorderGeometry: ID2D1PathGeometry;
    LFillColor: D2D1_COLOR_F;
    LBorderColor: D2D1_COLOR_F;
    LBorderTransform: D2D1_MATRIX_3X2_F;
    LIdentityTransform: D2D1_MATRIX_3X2_F;
Begin
    Result := False;

    LFillBrush := Nil;
    LBorderBrush := Nil;
    LFillGeometry := Nil;
    LBorderGeometry := Nil;

    If Length(ASurfaceInfo.RenderItem.RegionPoints) < 3 Then
        Exit;

    //-------------------------------------------------------------------------
    // Routine commune v30.
    //
    // REGLE D'OR v71 : IL NE FAUT PAS FAIRE DE CALCUL DE POSITION ICI.
    // Cette routine dessine le polygone final de l'item. Si RegionPoints ou
    // Bounds semblent faux, la correction appartient au layout, pas a Direct2D.
    //
    // Les versions precedentes avaient deux chemins de dessin :
    // - un chemin fonctionnel opaque ;
    // - un chemin SurfaceDebug translucide.
    //
    // Le symptome observe montrait que seul le chemin SurfaceDebug produisait
    // effectivement un rendu visible. Pour supprimer cette divergence, le
    // rendu reel et le diagnostic passent maintenant par exactement la meme
    // routine Direct2D. Les seules differences sont les alphas et l'epaisseur
    // de trait demandes par l'appelant.
    //-------------------------------------------------------------------------
    LFillColor := ColorToDirect2DColorWithAlpha(
        ASurfaceInfo.TopColor,
        AFillAlpha);

    //-------------------------------------------------------------------------
    // v64 : le remplissage Direct2D prend maintenant en charge le degrade
    // TopColor -> BottomColor. La couleur solide LFillColor reste calculee ici
    // uniquement pour conserver une lecture claire du chemin aplat :
    // CreateItemFillBrush choisit elle-meme une brosse solide lorsque les deux
    // couleurs sont identiques.
    //-------------------------------------------------------------------------
    If Not CreateItemFillBrush(
        ASurfaceInfo,
        AFillAlpha,
        LFillBrush) Then
        Exit;

    If Not BuildPolygonGeometry(
        ASurfaceInfo.RenderItem.RegionPoints,
        True,
        LFillGeometry) Then
        Exit;

    FDCRenderTarget.FillGeometry(
        LFillGeometry,
        LFillBrush,
        Nil);

    If ASurfaceInfo.DrawBorder Then Begin
        LBorderColor := ColorToDirect2DColorWithAlpha(
            ASurfaceInfo.BorderColor,
            ABorderAlpha);

        If Not CreateSolidBrush(
            LBorderColor,
            LBorderBrush) Then
            Exit;

        If Not BuildPolygonGeometry(
            ASurfaceInfo.RenderItem.RegionPoints,
            ASurfaceInfo.DrawClosedBorder,
            LBorderGeometry) Then
            Exit;

        //---------------------------------------------------------------------
        // v63 : bordure Direct2D alignee sur les centres de pixels.
        //
        // Le trait fractionnaire anti-aliase de la v62 permettait de reduire
        // l'epaisseur apparente, mais il eclaircissait fortement la couleur du
        // contour : avec une largeur de 0.2 DIP, Direct2D ne couvre qu'une
        // faible fraction des pixels et melange donc majoritairement le trait
        // avec le fond.
        //
        // La correction n'est pas de recalculer la geometrie ni de foncer
        // artificiellement la couleur. On dessine plutot le trait sur les
        // centres de pixels, ce qui est l'equivalent Direct2D du trait GDI/GDI+
        // net d'un pixel :
        //   - la geometrie fournie par le layout reste intacte ;
        //   - le remplissage n'est pas deplace ;
        //   - seule la phase de tracage du contour applique une translation
        //     de 0.5 pixel, standard pour aligner un trait de 1 DIP sur la
        //     grille des pixels.
        //
        // Le renderer reste donc strictement consommateur de la geometrie de
        // layout. Il ne modifie aucun rectangle, aucune ancre et aucun point
        // metier.
        //---------------------------------------------------------------------
        FillChar(LBorderTransform, SizeOf(LBorderTransform), 0);
        LBorderTransform._11 := 1.0;
        LBorderTransform._22 := 1.0;
        LBorderTransform._31 := 0.5;
        LBorderTransform._32 := 0.5;

        FillChar(LIdentityTransform, SizeOf(LIdentityTransform), 0);
        LIdentityTransform._11 := 1.0;
        LIdentityTransform._22 := 1.0;

        FDCRenderTarget.SetAntialiasMode(D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
        FDCRenderTarget.SetTransform(LBorderTransform);
        Try
            FDCRenderTarget.DrawGeometry(
                LBorderGeometry,
                LBorderBrush,
                ABorderWidth,
                Nil);
        Finally
            FDCRenderTarget.SetTransform(LIdentityTransform);
        End;
    End;

    Result := True;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintOneDirect2DItemSurface(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
Begin
    //-------------------------------------------------------------------------
    // Rendu fonctionnel : opaque et sans voile de diagnostic.
    //
    // Depuis v64, le remplissage interne de PaintOneDirect2DItemSurfaceCore
    // utilise une brosse lineaire Direct2D lorsque TopColor et BottomColor sont
    // distinctes. Le contour valide en v63 est conserve : trait logique 1 DIP
    // aligne sur les centres de pixels.
    //-------------------------------------------------------------------------
    Result := PaintOneDirect2DItemSurfaceCore(
        ASurfaceInfo,
        1.0,
        1.0,
        1.0);
End;



Function TNoReflowTabBarDirect2DRenderBackend.ResolveDirectWriteZoneHeaderFontWeight(
    Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): DWRITE_FONT_WEIGHT;
Begin
    If fsBold In AHeaderInfo.FontStyle Then
        Result := DWRITE_FONT_WEIGHT_BOLD
    Else
        Result := DWRITE_FONT_WEIGHT_NORMAL;
End;

Function TNoReflowTabBarDirect2DRenderBackend.ResolveDirectWriteZoneHeaderFontStyle(
    Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): DWRITE_FONT_STYLE;
Begin
    If fsItalic In AHeaderInfo.FontStyle Then
        Result := DWRITE_FONT_STYLE_ITALIC
    Else
        Result := DWRITE_FONT_STYLE_NORMAL;
End;

Function TNoReflowTabBarDirect2DRenderBackend.ResolveDirectWriteZoneHeaderFontSize(
    Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Single;
Begin
    //--------------------------------------------------------------------------
    // Les headers sont mesures cote contexte avec le Canvas GDI de
    // ZoneHeader.Font. Pour reduire l'ecart visuel avec ce rendu historique, on
    // privilegie donc Font.Height lorsqu'il est disponible : c'est la hauteur
    // logique reellement utilisee par le HFONT VCL.
    //
    // Font.Size reste un repli utile si une police externe fournit un Height nul.
    //--------------------------------------------------------------------------
    If AHeaderInfo.FontHeight <> 0 Then
        Result := Abs(AHeaderInfo.FontHeight)
    Else If AHeaderInfo.FontSize > 0 Then
        Result := AHeaderInfo.FontSize * 96.0 / 72.0
    Else
        Result := 12.0;
End;

Function TNoReflowTabBarDirect2DRenderBackend.CreateZoneHeaderTextFormat(
    Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo;
    Out ATextFormat: IDWriteTextFormat): Boolean;
Var
    LFontName: WideString;
    LLocaleName: WideString;
    LResult: HResult;
    LTrimming: DWRITE_TRIMMING;
    LTrimmingSign: IDWriteInlineObject;
Begin
    Result := False;
    ATextFormat := Nil;

    If Not DirectWriteResourcesAvailable Then
        Exit;

    LFontName := AHeaderInfo.FontName;

    If LFontName = '' Then
        LFontName := 'Segoe UI';

    LLocaleName := 'fr-FR';

    LResult := FDWriteFactory.CreateTextFormat(
        PWideChar(LFontName),
        Nil,
        ResolveDirectWriteZoneHeaderFontWeight(AHeaderInfo),
        ResolveDirectWriteZoneHeaderFontStyle(AHeaderInfo),
        DWRITE_FONT_STRETCH_NORMAL,
        ResolveDirectWriteZoneHeaderFontSize(AHeaderInfo),
        PWideChar(LLocaleName),
        ATextFormat);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        ATextFormat := Nil;
        Exit;
    End;

    ATextFormat.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
    ATextFormat.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_LEADING);
    ATextFormat.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_NEAR);

    //--------------------------------------------------------------------------
    // Le texte fourni par le layout est normalement deja raccourci. On conserve
    // neanmoins le trimming DirectWrite comme securite de clipping, sans en
    // faire une decision de layout locale au backend.
    //--------------------------------------------------------------------------
    FillChar(LTrimming, SizeOf(LTrimming), 0);
    LTrimming.granularity := DWRITE_TRIMMING_GRANULARITY_CHARACTER;

    LTrimmingSign := Nil;
    If FDWriteFactory.CreateEllipsisTrimmingSign(
        ATextFormat,
        LTrimmingSign) >= 0 Then
        ATextFormat.SetTrimming(
            LTrimming,
            LTrimmingSign);

    Result := ATextFormat <> Nil;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintOneDirect2DZoneHeaderText(
    Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Boolean;
Var
    LTextBrush: ID2D1SolidColorBrush;
    LTextColor: D2D1_COLOR_F;
    LTextFormat: IDWriteTextFormat;
    LTextRect: D2D1_RECT_F;
    LText: WideString;
    LTextX: Single;
    LTextY: Single;
    LTextWidth: Single;
    LTextHeight: Single;
    LTransform: D2D1_MATRIX_3X2_F;
    LIdentityTransform: D2D1_MATRIX_3X2_F;
    LRad: Double;
    LCos: Double;
    LSin: Double;
Begin
    //--------------------------------------------------------------------------
    // Texte du header en DirectWrite.
    //
    // REGLE D'OR v71 : IL NE FAUT PAS FAIRE DE CALCUL DE POSITION ICI.
    // TextInsertPoint, TextWidth, TextHeight et TextOrientation sont deja
    // resolus par BuildZoneHeaderRenderInfo dans la couche layout.
    //
    // Contrairement aux items, le GDI historique des headers utilise toujours
    // TA_LEFT + TA_TOP. Le point TextInsertPoint fourni par le contexte a deja
    // ete choisi dans le repere canonique puis projete en repere final. Le
    // backend Direct2D ne doit donc pas reparer cet ancrage : il consomme le
    // point et les metriques tels quels.
    //--------------------------------------------------------------------------
    Result := True;

    If AHeaderInfo.Text = '' Then
        Exit;

    If (AHeaderInfo.TextWidth <= 0) Or (AHeaderInfo.TextHeight <= 0) Then
        Exit;

    If Not DirectWriteResourcesAvailable Then
        Exit;

    LTextColor := ColorToDirect2DColor(AHeaderInfo.TextColor);

    If Not CreateSolidBrush(LTextColor, LTextBrush) Then Begin
        Result := False;
        Exit;
    End;

    If Not CreateZoneHeaderTextFormat(AHeaderInfo, LTextFormat) Then Begin
        LTextBrush := Nil;
        Result := False;
        Exit;
    End;

    LText := AHeaderInfo.Text;
    LTextX := AHeaderInfo.TextInsertPoint.X;
    LTextY := AHeaderInfo.TextInsertPoint.Y;
    LTextWidth := AHeaderInfo.TextWidth;
    LTextHeight := AHeaderInfo.TextHeight;

    FillChar(LIdentityTransform, SizeOf(LIdentityTransform), 0);
    LIdentityTransform._11 := 1.0;
    LIdentityTransform._22 := 1.0;

    Case AHeaderInfo.TextOrientation Of
        nrttoHorizontal: Begin
                LTextRect.left := LTextX;
                LTextRect.top := LTextY;
                LTextRect.right := LTextX + LTextWidth;
                LTextRect.bottom := LTextY + LTextHeight;

                FDCRenderTarget.DrawText(
                    PWideChar(LText),
                    Length(LText),
                    LTextFormat,
                    LTextRect,
                    LTextBrush,
                    D2D1_DRAW_TEXT_OPTIONS_CLIP,
                    DWRITE_MEASURING_MODE_GDI_CLASSIC);
            End;

        nrttoVerticalUp: Begin
                LRad := -Pi / 2.0;
                LCos := Cos(LRad);
                LSin := Sin(LRad);

                FillChar(LTransform, SizeOf(LTransform), 0);
                LTransform._11 := Single(LCos);
                LTransform._12 := Single(LSin);
                LTransform._21 := Single(-LSin);
                LTransform._22 := Single(LCos);
                LTransform._31 := LTextX;
                LTransform._32 := LTextY;

                LTextRect.left := 0.0;
                LTextRect.top := 0.0;
                LTextRect.right := LTextWidth;
                LTextRect.bottom := LTextHeight;

                FDCRenderTarget.SetTransform(LTransform);
                Try
                    FDCRenderTarget.DrawText(
                        PWideChar(LText),
                        Length(LText),
                        LTextFormat,
                        LTextRect,
                        LTextBrush,
                        D2D1_DRAW_TEXT_OPTIONS_CLIP,
                        DWRITE_MEASURING_MODE_GDI_CLASSIC);
                Finally
                    FDCRenderTarget.SetTransform(LIdentityTransform);
                End;
            End;

        nrttoVerticalDown: Begin
                LRad := Pi / 2.0;
                LCos := Cos(LRad);
                LSin := Sin(LRad);

                FillChar(LTransform, SizeOf(LTransform), 0);
                LTransform._11 := Single(LCos);
                LTransform._12 := Single(LSin);
                LTransform._21 := Single(-LSin);
                LTransform._22 := Single(LCos);
                LTransform._31 := LTextX;
                LTransform._32 := LTextY;

                LTextRect.left := 0.0;
                LTextRect.top := 0.0;
                LTextRect.right := LTextWidth;
                LTextRect.bottom := LTextHeight;

                FDCRenderTarget.SetTransform(LTransform);
                Try
                    FDCRenderTarget.DrawText(
                        PWideChar(LText),
                        Length(LText),
                        LTextFormat,
                        LTextRect,
                        LTextBrush,
                        D2D1_DRAW_TEXT_OPTIONS_CLIP,
                        DWRITE_MEASURING_MODE_GDI_CLASSIC);
                Finally
                    FDCRenderTarget.SetTransform(LIdentityTransform);
                End;
            End;
    Else Begin
            LTextRect.left := LTextX;
            LTextRect.top := LTextY;
            LTextRect.right := LTextX + LTextWidth;
            LTextRect.bottom := LTextY + LTextHeight;

            FDCRenderTarget.DrawText(
                PWideChar(LText),
                Length(LText),
                LTextFormat,
                LTextRect,
                LTextBrush,
                D2D1_DRAW_TEXT_OPTIONS_CLIP,
                DWRITE_MEASURING_MODE_GDI_CLASSIC);
        End;
    End;

    LTextFormat := Nil;
    LTextBrush := Nil;
End;

//Function TNoReflowTabBarDirect2DRenderBackend.PaintOneDirect2DZoneHeader(
//    Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Boolean;
//Var
//    LLineBrush: ID2D1SolidColorBrush;
//    LLineColor: D2D1_COLOR_F;
//    LIndex: Integer;
//    LP1: D2D1_POINT_2F;
//    LP2: D2D1_POINT_2F;
//Begin
//    //--------------------------------------------------------------------------
//    // Dessine un header de zone deja resolu par le contexte : segments du filet,
//    // ticks de bord et texte.
//    //
//    // REGLE D'OR v71 : IL NE FAUT PAS FAIRE DE CALCUL DE POSITION ICI.
//    // Les coordonnees sont finales ; aucune conversion canonique et aucune
//    // correction locale ne doivent etre ajoutees dans ce backend.
//    //--------------------------------------------------------------------------
//    Result := False;
//
//    LLineColor := ColorToDirect2DColor(AHeaderInfo.LineColor);
//
//    If Not CreateSolidBrush(LLineColor, LLineBrush) Then
//        Exit;
//
//    //--------------------------------------------------------------------------
//    // Le trait GDI historique du header est un trait pixelise et dur.
//    // Direct2D, en antialiasing per-primitive, repartit naturellement un trait
//    // de 1 DIP sur plusieurs pixels lorsqu'il tombe sur une coordonnee entiere,
//    // ce qui donne une impression de filet trop epais. On trace donc uniquement
//    // les filets de header en mode aliased, sans modifier les coordonnees
//    // calculees par le contexte.
//    //--------------------------------------------------------------------------
//    FDCRenderTarget.SetAntialiasMode(D2D1_ANTIALIAS_MODE_ALIASED);
//    Try
//        For LIndex := 0 To AHeaderInfo.SegmentCount - 1 Do Begin
//            LP1.x := AHeaderInfo.Segments[LIndex].P1.X;
//            LP1.y := AHeaderInfo.Segments[LIndex].P1.Y;
//            LP2.x := AHeaderInfo.Segments[LIndex].P2.X;
//            LP2.y := AHeaderInfo.Segments[LIndex].P2.Y;
//
//            FDCRenderTarget.DrawLine(
//                LP1,
//                LP2,
//                LLineBrush,
//                1.0,
//                Nil);
//        End;
//    Finally
//        FDCRenderTarget.SetAntialiasMode(D2D1_ANTIALIAS_MODE_PER_PRIMITIVE);
//    End;
//
//    LLineBrush := Nil;
//
//    Result := PaintOneDirect2DZoneHeaderText(AHeaderInfo);
//End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintOneDirect2DZoneHeader(
    Const AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Boolean;
Var
    LLineBrush: ID2D1SolidColorBrush;
    LLineColor: D2D1_COLOR_F;
    LIndex: Integer;
    LRect: D2D1_RECT_F;
    LP1: TPoint;
    LP2: TPoint;
    LLeft: Integer;
    LTop: Integer;
    LRight: Integer;
    LBottom: Integer;

    Procedure DrawPixelSegment(Const AP1: TPoint; Const AP2: TPoint);
    Begin
        //----------------------------------------------------------------------
        // Trace un segment de header deja calcule par le layout.
        //
        // REGLE D'OR v71 :
        // IL NE FAUT PAS FAIRE DE CALCUL DE POSITION ICI.
        //
        // Cette routine ne decide pas ou placer le header. Elle convertit
        // uniquement un segment final horizontal/vertical en rectangle rempli
        // de 1 pixel, afin d'eviter les differences de rasterisation entre :
        // - GDI MoveTo/LineTo ;
        // - Direct2D DrawLine.
        //
        // Les headers sont decoratifs et composes de traits orthogonaux.
        // FillRectangle donne ici une couverture pixel exacte, sans cap, sans
        // demi-pixel implicite et sans deplacement visuel du segment entier.
        //----------------------------------------------------------------------

        If AP1.Y = AP2.Y Then Begin
            LLeft := Min(AP1.X, AP2.X);
            LRight := Max(AP1.X, AP2.X);

            If LRight <= LLeft Then
                Exit;

            LRect.left := LLeft;
            LRect.top := AP1.Y;
            LRect.right := LRight;
            LRect.bottom := AP1.Y + 1;

            FDCRenderTarget.FillRectangle(
                LRect,
                LLineBrush);

            Exit;
        End;

        If AP1.X = AP2.X Then Begin
            LTop := Min(AP1.Y, AP2.Y);
            LBottom := Max(AP1.Y, AP2.Y);

            If LBottom <= LTop Then
                Exit;

            LRect.left := AP1.X;
            LRect.top := LTop;
            LRect.right := AP1.X + 1;
            LRect.bottom := LBottom;

            FDCRenderTarget.FillRectangle(
                LRect,
                LLineBrush);

            Exit;
        End;

        //----------------------------------------------------------------------
        // Securite defensive :
        // le layout actuel ne produit que des segments horizontaux/verticaux.
        // Si un jour un segment diagonal est ajoute, on ne le corrige pas ici :
        // il faudra alors definir explicitement une nouvelle primitive de layout.
        //----------------------------------------------------------------------
        LP1 := AP1;
        LP2 := AP2;

        LRect.left := Min(LP1.X, LP2.X);
        LRect.top := Min(LP1.Y, LP2.Y);
        LRect.right := Max(LP1.X, LP2.X);
        LRect.bottom := Max(LP1.Y, LP2.Y);

        If (LRect.right > LRect.left) And (LRect.bottom > LRect.top) Then
            FDCRenderTarget.FillRectangle(
                LRect,
                LLineBrush);
    End;

Begin
    //--------------------------------------------------------------------------
    // Dessine un header de zone deja resolu par le contexte : segments du filet,
    // ticks de bord et texte.
    //
    // REGLE D'OR v71 : IL NE FAUT PAS FAIRE DE CALCUL DE POSITION ICI.
    //
    // Les coordonnees sont finales. Cette methode ne doit pas convertir un
    // repere canonique, ne doit pas deplacer les points, et ne doit pas corriger
    // localement le layout.
    //
    // Particularite Direct2D :
    // les filets de header sont des traits decoratifs de 1 pixel. Pour eviter
    // les decalages visuels de DrawLine par rapport au rendu GDI historique, on
    // les rasterise comme des rectangles remplis de 1 pixel. Ce n'est pas une
    // correction de position : c'est uniquement le choix de la primitive de
    // dessin la plus stable pour un filet pixelise.
    //--------------------------------------------------------------------------
    Result := False;

    LLineColor := ColorToDirect2DColor(AHeaderInfo.LineColor);

    If Not CreateSolidBrush(LLineColor, LLineBrush) Then
        Exit;

    For LIndex := 0 To AHeaderInfo.SegmentCount - 1 Do Begin
        DrawPixelSegment(
            AHeaderInfo.Segments[LIndex].P1,
            AHeaderInfo.Segments[LIndex].P2);
    End;

    LLineBrush := Nil;

    Result := PaintOneDirect2DZoneHeaderText(AHeaderInfo);
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintZoneHeadersWithDirect2D(
    ACanvas: TCanvas): Boolean;
Var
    LClientRect: TRect;
    LResult: HResult;
    LIndex: Integer;
    LCount: Integer;
    LHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo;
    LPaintOk: Boolean;
    LPaintedCount: Integer;
Begin
    //--------------------------------------------------------------------------
    // Headers de zones Direct2D v39.
    //
    // Le backend Direct2D reste autonome : il ne rappelle pas DrawZoneHeaders
    // du backend GDI. Le contexte lui fournit les segments et le texte deja
    // resolus dans le repere final, ce qui limite le risque de divergence avec
    // le moteur de layout historique.
    //--------------------------------------------------------------------------
    Result := False;

    If ACanvas = Nil Then
        Exit;

    If FRenderContext = Nil Then
        Exit;

    If Not Direct2DResourcesAvailable Then
        Exit;

    If Not Direct2DRenderTargetAvailable Then
        Exit;

    If Not DirectWriteResourcesAvailable Then
        Exit;

    FRenderContext.PrepareDirect2DZoneHeaders;

    LClientRect := FRenderContext.GetRenderClientRect;

    If IsRectEmpty(LClientRect) Then
        Exit;

    If Not BindDirect2DRenderTargetToCanvas(
        ACanvas,
        LClientRect) Then
        Exit;

    LCount := FRenderContext.GetDirect2DZoneHeaderCount;

    If LCount <= 0 Then
        Exit;

    LPaintOk := True;
    LPaintedCount := 0;

    FDCRenderTarget.BeginDraw;

    For LIndex := 0 To LCount - 1 Do Begin
        If Not FRenderContext.GetDirect2DZoneHeaderInfo(
            LIndex,
            LHeaderInfo) Then
            Continue;

        If Not PaintOneDirect2DZoneHeader(LHeaderInfo) Then Begin
            LPaintOk := False;
            Break;
        End;

        Inc(LPaintedCount);
    End;

    LResult := FDCRenderTarget.EndDraw(Nil, Nil);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        Exit;
    End;

    If Not LPaintOk Then Begin
        FRenderState := ntd2dRenderFailed;
        Exit;
    End;

    If LPaintedCount <= 0 Then
        Exit;

    FRenderState := ntd2dZoneHeadersCompleted;
    FLastNativeError := 0;
    Result := True;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintItemSurfacesWithDirect2D(
    ACanvas: TCanvas): Boolean;
Var
    LClientRect: TRect;
    LResult: HResult;
    LIndex: Integer;
    LCount: Integer;
    LSelectedIndex: Integer;
    LSurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo;
    LIsButtonMode: Boolean;
    LPaintOk: Boolean;
    LPaintedCount: Integer;
Begin
    Result := False;

    If ACanvas = Nil Then
        Exit;

    If FRenderContext = Nil Then
        Exit;

    //-------------------------------------------------------------------------
    // Les surfaces et le contenu sont peints dans la meme passe Direct2D et
    // dans le meme ordre de z-order.
    //
    // Peindre d'abord toutes les surfaces, puis tous les contenus dans une
    // seconde passe globale serait incorrect en mode onglet avec recouvrement :
    // le voyant d'un onglet sous-jacent pourrait passer au-dessus de l'onglet
    // voisin, car il serait dessine apres toutes les surfaces.
    //
    // La regle correcte est celle du rendu GDI historique : pour chaque item,
    // la surface puis son contenu standard sont peints ensemble, puis l'item
    // suivant peut naturellement recouvrir ce qui doit l'etre.
    //-------------------------------------------------------------------------

    If Not Direct2DResourcesAvailable Then
        Exit;

    If Not Direct2DRenderTargetAvailable Then
        Exit;

    FRenderContext.PrepareDirect2DItemSurfaces;

    LClientRect := FRenderContext.GetRenderClientRect;

    If IsRectEmpty(LClientRect) Then
        Exit;

    If Not BindDirect2DRenderTargetToCanvas(
        ACanvas,
        LClientRect) Then
        Exit;

    LCount := FRenderContext.GetDirect2DItemSurfaceCount;

    If LCount <= 0 Then
        Exit;

    LIsButtonMode := True;

    For LIndex := 0 To LCount - 1 Do Begin
        If FRenderContext.GetDirect2DItemSurfaceInfo(
            LIndex,
            LSurfaceInfo) Then Begin
            LIsButtonMode := LSurfaceInfo.IsButton;
            Break;
        End;
    End;

    LSelectedIndex := -1;
    LPaintOk := True;
    LPaintedCount := 0;

    FDCRenderTarget.BeginDraw;

    If LIsButtonMode Then Begin
        //---------------------------------------------------------------------
        // En mode boutons, l'ordre physique des render items est deja l'ordre
        // de peinture attendu.
        //---------------------------------------------------------------------
        For LIndex := 0 To LCount - 1 Do Begin
            If Not FRenderContext.GetDirect2DItemSurfaceInfo(
                LIndex,
                LSurfaceInfo) Then
                Continue;

            If Not PaintOneDirect2DItemSurface(LSurfaceInfo) Then Begin
                LPaintOk := False;
                Break;
            End;

            If Not PaintOneDirect2DItemContent(LSurfaceInfo) Then Begin
                LPaintOk := False;
                Break;
            End;

            Inc(LPaintedCount);
        End;
    End Else Begin
        //---------------------------------------------------------------------
        // En mode onglets, on conserve l'ordre deja valide pour les surfaces :
        // les onglets non selectionnes sont peints dans l'ordre inverse, puis
        // l'onglet selectionne est peint en dernier. Le contenu suit maintenant
        // immediatement sa surface afin de respecter les recouvrements.
        //---------------------------------------------------------------------
        For LIndex := LCount - 1 Downto 0 Do Begin
            If Not FRenderContext.GetDirect2DItemSurfaceInfo(
                LIndex,
                LSurfaceInfo) Then
                Continue;

            If LSurfaceInfo.RenderItem.Selected Then Begin
                LSelectedIndex := LIndex;
                Continue;
            End;

            If Not PaintOneDirect2DItemSurface(LSurfaceInfo) Then Begin
                LPaintOk := False;
                Break;
            End;

            If Not PaintOneDirect2DItemContent(LSurfaceInfo) Then Begin
                LPaintOk := False;
                Break;
            End;

            Inc(LPaintedCount);
        End;

        If LPaintOk And (LSelectedIndex >= 0) Then Begin
            If FRenderContext.GetDirect2DItemSurfaceInfo(
                LSelectedIndex,
                LSurfaceInfo) Then Begin
                If Not PaintOneDirect2DItemSurface(LSurfaceInfo) Then
                    LPaintOk := False
                Else If Not PaintOneDirect2DItemContent(LSurfaceInfo) Then
                    LPaintOk := False
                Else
                    Inc(LPaintedCount);
            End;
        End;
    End;

    LResult := FDCRenderTarget.EndDraw(Nil, Nil);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        Exit;
    End;

    If Not LPaintOk Then Begin
        FRenderState := ntd2dRenderFailed;
        Exit;
    End;

    If LPaintedCount <= 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        Exit;
    End;

    FRenderState := ntd2dItemSurfacesCompleted;
    FLastNativeError := 0;
    Result := True;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintOneDirect2DItemSurfaceDebug(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
Begin
    //-------------------------------------------------------------------------
    // Diagnostic : meme routine que le rendu reel, mais avec une opacite reduite
    // pour permettre une lecture en surimpression.
    //-------------------------------------------------------------------------
    Result := PaintOneDirect2DItemSurfaceCore(
        ASurfaceInfo,
        0.35,
        0.85,
        0.65);
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintItemSurfaceDebugWithDirect2D(
    ACanvas: TCanvas): Boolean;
Begin
    Result := False;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintItemGeometryDebugWithDirect2D(
    ACanvas: TCanvas): Boolean;
Begin
    Result := False;
End;

Function TNoReflowTabBarDirect2DRenderBackend.ResolveDirectWriteFontWeight(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): DWRITE_FONT_WEIGHT;
Begin
    //-------------------------------------------------------------------------
    // Conversion volontairement limitee aux styles typographiques utiles au
    // rendu standard. Le layout fournit deja la police effective et les
    // metriques finales ; cette fonction traduit uniquement le style VCL vers
    // DirectWrite sans recalculer le placement du texte.
    //-------------------------------------------------------------------------
    If fsBold In ASurfaceInfo.FontStyle Then
        Result := DWRITE_FONT_WEIGHT_BOLD
    Else
        Result := DWRITE_FONT_WEIGHT_NORMAL;
End;

Function TNoReflowTabBarDirect2DRenderBackend.ResolveDirectWriteFontStyle(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): DWRITE_FONT_STYLE;
Begin
    If fsItalic In ASurfaceInfo.FontStyle Then
        Result := DWRITE_FONT_STYLE_ITALIC
    Else
        Result := DWRITE_FONT_STYLE_NORMAL;
End;

Function TNoReflowTabBarDirect2DRenderBackend.ResolveDirectWriteFontSize(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Single;
Begin
    //-------------------------------------------------------------------------
    // DirectWrite attend une taille en DIPs. Quand Font.Size est positif, il est
    // exprime en points typographiques VCL : conversion 72 points -> 96 DIPs.
    // Si seule Font.Height est renseignee, on l'utilise comme approximation en
    // pixels logiques, comme dans le backend VclRotatedEdit valide.
    //-------------------------------------------------------------------------
    If ASurfaceInfo.FontSize > 0 Then
        Result := ASurfaceInfo.FontSize * 96.0 / 72.0
    Else If ASurfaceInfo.FontHeight <> 0 Then
        Result := Abs(ASurfaceInfo.FontHeight)
    Else
        Result := 12.0;
End;

Function TNoReflowTabBarDirect2DRenderBackend.CreateItemTextFormat(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo;
    Out ATextFormat: IDWriteTextFormat): Boolean;
Var
    LFontName: WideString;
    LLocaleName: WideString;
    LResult: HResult;
    LTrimming: DWRITE_TRIMMING;
    LTrimmingSign: IDWriteInlineObject;
Begin
    Result := False;
    ATextFormat := Nil;

    If Not DirectWriteResourcesAvailable Then
        Exit;

    LFontName := ASurfaceInfo.FontName;

    If LFontName = '' Then
        LFontName := 'Segoe UI';

    LLocaleName := 'fr-FR';

    LResult := FDWriteFactory.CreateTextFormat(
        PWideChar(LFontName),
        Nil,
        ResolveDirectWriteFontWeight(ASurfaceInfo),
        ResolveDirectWriteFontStyle(ASurfaceInfo),
        DWRITE_FONT_STRETCH_NORMAL,
        ResolveDirectWriteFontSize(ASurfaceInfo),
        PWideChar(LLocaleName),
        ATextFormat);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        ATextFormat := Nil;
        Exit;
    End;

    //---------------------------------------------------------------------
    // Le layout fournit la zone finale de composition du texte. DirectWrite
    // doit donc seulement composer dans cette zone : pas de recalcul local de
    // la place disponible dans le renderer.
    //---------------------------------------------------------------------
    ATextFormat.SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);

    If ASurfaceInfo.IsButton Then Begin
        //-----------------------------------------------------------------
        // Le rectangle de texte fourni par le layout est deja la zone finale
        // de composition, quelle que soit l'orientation. Le centrage doit donc
        // etre applique dans cette zone pour les boutons horizontaux comme
        // pour les boutons verticaux projetes depuis le repere canonique.
        //-----------------------------------------------------------------
        ATextFormat.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
        ATextFormat.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
    End Else Begin
        ATextFormat.SetTextAlignment(DWRITE_TEXT_ALIGNMENT_LEADING);
        ATextFormat.SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_NEAR);
    End;

    //---------------------------------------------------------------------
    // REGLE D'OR v74 : Direct2D ne decide pas seul d'ellipser le texte.
    //
    // Les métriques DirectWrite peuvent être légèrement différentes des
    // métriques GDI utilisées par le layout historique. Si on active toujours
    // le trimming DirectWrite, un onglet naturel pourtant dimensionné pour son
    // caption complet peut devenir "Ong..." uniquement en Direct2D.
    //
    // Le trimming n'est donc activé que lorsque le layout l'a autorisé, par
    // exemple pour un bouton soumis à ForcedLength.
    //---------------------------------------------------------------------
    If ASurfaceInfo.RenderItem.Metrics.AllowTextTrimming Then Begin
        FillChar(
            LTrimming,
            SizeOf(LTrimming),
            0);
        LTrimming.granularity := DWRITE_TRIMMING_GRANULARITY_CHARACTER;
        LTrimming.delimiter := 0;
        LTrimming.delimiterCount := 0;

        LTrimmingSign := Nil;
        LResult := FDWriteFactory.CreateEllipsisTrimmingSign(
            ATextFormat,
            LTrimmingSign);

        If LResult >= 0 Then
            ATextFormat.SetTrimming(
                LTrimming,
                LTrimmingSign);

        LTrimmingSign := Nil;
    End;

    Result := ATextFormat <> Nil;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintOneDirect2DItemContent(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
Begin
    //-------------------------------------------------------------------------
    // Peint le contenu standard d'un item dans la meme passe et dans le meme
    // z-order que sa surface.
    //
    // v34 ajoute les glyphs ImageList dans cette meme passe. Cela evite de
    // recreer une couche globale de glyphs qui repasserait au-dessus d'onglets
    // censes recouvrir l'item precedent.
    //
    // Cette petite routine evite de recreer une passe globale de contenu qui
    // ferait passer les voyants et les textes au-dessus d'items censes les
    // recouvrir. Les glyphs ImageList et les hooks personnalises restent hors
    // perimetre tant qu'ils ne sont pas portes en Direct2D.
    //-------------------------------------------------------------------------
    Result := False;

    If Not PaintOneDirect2DItemSignal(ASurfaceInfo) Then
        Exit;

    If Not PaintOneDirect2DItemGlyph(ASurfaceInfo) Then
        Exit;

    If Not PaintOneDirect2DItemText(ASurfaceInfo) Then
        Exit;

    If Not PaintOneDirect2DItemFocus(ASurfaceInfo) Then
        Exit;

    Result := True;
End;

Function TNoReflowTabBarDirect2DRenderBackend.BuildDirect2DSignalPieGeometry(
    Const ASignalRect: TRect;
    APercent: Double;
    AStartAngleDeg: Double;
    Out AGeometry: ID2D1PathGeometry): Boolean;
Var
    LResult: HResult;
    LGeometrySink: ID2D1GeometrySink;
    LCenter: D2D1_POINT_2F;
    LPoint: D2D1_POINT_2F;
    LRadius: Single;
    LPercent: Double;
    LStartAngleRad: Double;
    LEndAngleRad: Double;
    LAngleRad: Double;
    LStepCount: Integer;
    LStepIndex: Integer;
Begin
    //--------------------------------------------------------------------------
    // Construit la geometrie du secteur rempli d'un voyant partiel.
    //
    // Le rendu GDI historique utilise Pie(), avec une progression visuelle dans
    // le sens horaire a partir d'un angle fourni par le layout/rendu metier.
    //
    // Direct2D pourrait utiliser un arc natif, mais pour rester compatible avec
    // les declarations Winapi.D2D1 des differentes versions de Delphi, cette
    // routine approxime le secteur par un polygone regulier. La taille des
    // voyants est faible ; une approximation de 48 segments pour un disque
    // complet est largement suffisante et evite toute dependance a AddArc().
    //
    // Important : cette routine ne calcule pas la position du voyant. Elle ne
    // fait que convertir le pourcentage en geometrie dans le rectangle deja
    // calcule par le layout.
    //--------------------------------------------------------------------------
    Result := False;
    AGeometry := Nil;

    If FD2DFactory = Nil Then
        Exit;

    If IsRectEmpty(ASignalRect) Then
        Exit;

    LPercent := APercent;
    If LPercent <= 0.0 Then
        Exit;
    If LPercent > 100.0 Then
        LPercent := 100.0;

    LCenter.x := (ASignalRect.Left + ASignalRect.Right) / 2.0;
    LCenter.y := (ASignalRect.Top + ASignalRect.Bottom) / 2.0;
    LRadius := Min(
        ASignalRect.Right - ASignalRect.Left,
        ASignalRect.Bottom - ASignalRect.Top) / 2.0;

    If LRadius <= 0.0 Then
        Exit;

    LStartAngleRad := AStartAngleDeg * Pi / 180.0;
    LEndAngleRad := (AStartAngleDeg + (LPercent / 100.0) * 360.0) * Pi / 180.0;

    LStepCount := Ceil(48.0 * LPercent / 100.0);
    If LStepCount < 2 Then
        LStepCount := 2;

    LResult := FD2DFactory.CreatePathGeometry(AGeometry);
    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        AGeometry := Nil;
        Exit;
    End;

    LResult := AGeometry.Open(LGeometrySink);
    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        AGeometry := Nil;
        Exit;
    End;

    LGeometrySink.BeginFigure(
        LCenter,
        D2D1_FIGURE_BEGIN_FILLED);

    For LStepIndex := 0 To LStepCount Do Begin
        LAngleRad := LStartAngleRad +
            ((LEndAngleRad - LStartAngleRad) * LStepIndex / LStepCount);

        LPoint.x := LCenter.x + Single(Cos(LAngleRad) * LRadius);
        LPoint.y := LCenter.y + Single(Sin(LAngleRad) * LRadius);

        LGeometrySink.AddLine(LPoint);
    End;

    LGeometrySink.EndFigure(D2D1_FIGURE_END_CLOSED);

    LResult := LGeometrySink.Close;
    LGeometrySink := Nil;

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        AGeometry := Nil;
        Exit;
    End;

    Result := True;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintOneDirect2DItemSignal(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
Var
    LSignalRect: TRect;
    LEllipse: D2D1_ELLIPSE;
    LBackColor: TColor;
    LBackBrush: ID2D1SolidColorBrush;
    LFillBrush: ID2D1SolidColorBrush;
    LBorderBrush: ID2D1SolidColorBrush;
    LBackD2DColor: D2D1_COLOR_F;
    LFillD2DColor: D2D1_COLOR_F;
    LBorderD2DColor: D2D1_COLOR_F;
    LPercent: Double;
    LStartAngleDeg: Double;
    LPieGeometry: ID2D1PathGeometry;
Begin
    //-------------------------------------------------------------------------
    // Voyant Direct2D v65.
    //
    // Le rendu Direct2D reprend maintenant le comportement du rendu GDI :
    // - disque de fond eclairci ;
    // - disque plein si le pourcentage vaut 100 % ;
    // - secteur partiel si 0 < pourcentage < 100 ;
    // - bordure externe complete repassee a la fin.
    //
    // La position du voyant reste entierement fournie par le layout via
    // Metrics.SignalRect. Le backend ne calcule ici que la geometrie interne du
    // secteur de remplissage.
    //-------------------------------------------------------------------------
    Result := True;

    If Not ASurfaceInfo.RenderItem.Metrics.HasSignal Then
        Exit;

    If IsRectEmpty(ASurfaceInfo.RenderItem.Metrics.SignalRect) Then
        Exit;

    LSignalRect := ASurfaceInfo.RenderItem.Metrics.SignalRect;
    OffsetRect(
        LSignalRect,
        ASurfaceInfo.RenderItem.Bounds.Left,
        ASurfaceInfo.RenderItem.Bounds.Top);

    If IsRectEmpty(LSignalRect) Then
        Exit;

    LBackColor := MakeColorLighter(
        ASurfaceInfo.SignalBrushColor,
        180);

    LBackD2DColor := ColorToDirect2DColor(LBackColor);
    LFillD2DColor := ColorToDirect2DColor(ASurfaceInfo.SignalBrushColor);
    LBorderD2DColor := ColorToDirect2DColor(ASurfaceInfo.SignalPenColor);

    If Not CreateSolidBrush(LBackD2DColor, LBackBrush) Then Begin
        Result := False;
        Exit;
    End;

    If Not CreateSolidBrush(LFillD2DColor, LFillBrush) Then Begin
        LBackBrush := Nil;
        Result := False;
        Exit;
    End;

    If Not CreateSolidBrush(LBorderD2DColor, LBorderBrush) Then Begin
        LBackBrush := Nil;
        LFillBrush := Nil;
        Result := False;
        Exit;
    End;

    LEllipse.point.x := (LSignalRect.Left + LSignalRect.Right) / 2.0;
    LEllipse.point.y := (LSignalRect.Top + LSignalRect.Bottom) / 2.0;
    LEllipse.radiusX := (LSignalRect.Right - LSignalRect.Left) / 2.0;
    LEllipse.radiusY := (LSignalRect.Bottom - LSignalRect.Top) / 2.0;

    FDCRenderTarget.FillEllipse(
        LEllipse,
        LBackBrush);

    LPercent := NormalizeSignalFillPercent(
        ASurfaceInfo.RenderItem.Item.SignalValue,
        ASurfaceInfo.RenderItem.Item.SignalMax);

    If LPercent >= 100.0 Then
        FDCRenderTarget.FillEllipse(
            LEllipse,
            LFillBrush)
    Else If LPercent > 0.0 Then Begin
        Case ASurfaceInfo.RenderItem.Metrics.TextOrientation Of
            nrttoVerticalUp:
                LStartAngleDeg := 180.0;

            nrttoVerticalDown:
                LStartAngleDeg := 0.0;
        Else
            LStartAngleDeg := -90.0;
        End;

        If BuildDirect2DSignalPieGeometry(
            LSignalRect,
            LPercent,
            LStartAngleDeg,
            LPieGeometry) Then Begin
            FDCRenderTarget.FillGeometry(
                LPieGeometry,
                LFillBrush,
                Nil);
            LPieGeometry := Nil;
        End Else Begin
            LBackBrush := Nil;
            LFillBrush := Nil;
            LBorderBrush := Nil;
            Result := False;
            Exit;
        End;
    End;

    FDCRenderTarget.DrawEllipse(
        LEllipse,
        LBorderBrush,
        1.0,
        Nil);

    LBackBrush := Nil;
    LFillBrush := Nil;
    LBorderBrush := Nil;
End;


Function TNoReflowTabBarDirect2DRenderBackend.CreateDirect2DBitmapFromVclBitmap(
    ABitmap: TBitmap;
    Out ADirectBitmap: ID2D1Bitmap): Boolean;
Var
    LBitmapSize: D2D1_SIZE_U;
    LBitmapProperties: D2D1_BITMAP_PROPERTIES;
    LPixels: TBytes;
    LSourceLine: PByte;
    LDestLine: PByte;
    LDestPixel: PByte;
    LSourcePixel: PByte;
    LRow: Integer;
    LCol: Integer;
    LPitch: Integer;
    LResult: HResult;
    LBlue: Byte;
    LGreen: Byte;
    LRed: Byte;
    LAlpha: Byte;
Begin
    //--------------------------------------------------------------------------
    // Convertit un TBitmap VCL pf32bit en ID2D1Bitmap.
    //
    // Cette conversion reste volontairement locale au backend Direct2D : le
    // contexte fournit seulement le bitmap source provenant de BarImages. Le
    // rendu final reste Direct2D, sans dessin GDI sur le canvas du controle.
    //
    // Convention v72 : le contexte fournit un bitmap pf32bit BGRA dont le canal
    // alpha est deja reconstruit a partir du glyph ImageList. Cette fonction ne
    // doit donc plus chercher une couleur transparente sentinelle. Elle doit
    // respecter l'alpha source et premultiplier les composantes RGB, car le
    // bitmap Direct2D est cree en D2D1_ALPHA_MODE_PREMULTIPLIED.
    //--------------------------------------------------------------------------
    Result := False;
    ADirectBitmap := Nil;

    If ABitmap = Nil Then
        Exit;

    If ABitmap.Empty Then
        Exit;

    If FDCRenderTarget = Nil Then
        Exit;

    ABitmap.PixelFormat := pf32bit;

    If (ABitmap.Width <= 0) Or (ABitmap.Height <= 0) Then
        Exit;

    LPitch := ABitmap.Width * 4;
    SetLength(
        LPixels,
        LPitch * ABitmap.Height);

    For LRow := 0 To ABitmap.Height - 1 Do Begin
        // TBitmap.ScanLine est indexe avec les coordonnees visuelles du bitmap :
        // la ligne 0 correspond a la ligne haute attendue par le code VCL qui a
        // dessine l'ImageList dans le TBitmap temporaire.
        //
        // La v34 inversait systematiquement les lignes en supposant un DIB
        // bottom-up brut. Cette hypothese est dangereuse avec les bitmaps issus
        // des ImageList/VirtualImageList : certains glyphs se retrouvaient
        // verticalement retournes alors que le texte et le layout etaient
        // horizontaux.
        //
        // On recopie donc les lignes dans le meme ordre logique que ScanLine.
        // Direct2D recoit ainsi un bitmap top-down coherent avec le rendu VCL
        // source, sans appliquer de retournement implicite.
        LSourceLine := ABitmap.ScanLine[LRow];
        LDestLine := @LPixels[LRow * LPitch];

        For LCol := 0 To ABitmap.Width - 1 Do Begin
            LSourcePixel := LSourceLine;
            Inc(LSourcePixel, LCol * 4);

            LDestPixel := LDestLine;
            Inc(LDestPixel, LCol * 4);

            LBlue := LSourcePixel^;
            LGreen := PByte(NativeUInt(LSourcePixel) + 1)^;
            LRed := PByte(NativeUInt(LSourcePixel) + 2)^;
            LAlpha := PByte(NativeUInt(LSourcePixel) + 3)^;

            If LAlpha = 0 Then Begin
                LDestPixel^ := 0;
                PByte(NativeUInt(LDestPixel) + 1)^ := 0;
                PByte(NativeUInt(LDestPixel) + 2)^ := 0;
                PByte(NativeUInt(LDestPixel) + 3)^ := 0;
            End Else Begin
                // Direct2D attend un bitmap premultiplie. Les composantes RGB
                // issues du TBitmap temporaire sont droites : on les multiplie
                // donc par alpha avant CreateBitmap. Sans cette etape, les
                // contours semi-transparents peuvent produire des halos.
                LDestPixel^ := Byte(MulDiv(LBlue, LAlpha, 255));
                PByte(NativeUInt(LDestPixel) + 1)^ := Byte(MulDiv(LGreen, LAlpha, 255));
                PByte(NativeUInt(LDestPixel) + 2)^ := Byte(MulDiv(LRed, LAlpha, 255));
                PByte(NativeUInt(LDestPixel) + 3)^ := LAlpha;
            End;
        End;
    End;

    LBitmapSize.width := ABitmap.Width;
    LBitmapSize.height := ABitmap.Height;

    FillChar(
        LBitmapProperties,
        SizeOf(LBitmapProperties),
        0);
    LBitmapProperties.pixelFormat.format := DXGI_FORMAT_B8G8R8A8_UNORM;
    LBitmapProperties.pixelFormat.alphaMode := D2D1_ALPHA_MODE_PREMULTIPLIED;
    LBitmapProperties.dpiX := 0.0;
    LBitmapProperties.dpiY := 0.0;

    LResult := FDCRenderTarget.CreateBitmap(
        LBitmapSize,
        @LPixels[0],
        LPitch,
        LBitmapProperties,
        ADirectBitmap);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        ADirectBitmap := Nil;
        Exit;
    End;

    Result := ADirectBitmap <> Nil;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintOneDirect2DItemGlyph(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
Var
    LGlyphRect: TRect;
    LBitmap: TBitmap;
    LD2DBitmap: ID2D1Bitmap;
    LDestRect: D2D1_RECT_F;
    LTransform: D2D1_MATRIX_3X2_F;
    LIdentityTransform: D2D1_MATRIX_3X2_F;
    LCenterX: Single;
    LCenterY: Single;
    LRad: Double;
    LCos: Double;
    LSin: Double;
Begin
    //--------------------------------------------------------------------------
    // Glyph Direct2D v34.
    //
    // Le glyph est peint dans la meme passe item que la surface, le voyant et le
    // texte. C'est indispensable pour conserver le z-order valide en v33 : un
    // item suivant doit pouvoir recouvrir le glyph d'un item precedent lorsque
    // les onglets se chevauchent.
    //
    // Le backend ne depend pas directement de FBarImages. Il demande au contexte
    // de remplir un bitmap temporaire, puis convertit ce bitmap en ID2D1Bitmap.
    //--------------------------------------------------------------------------
    Result := True;

    If FRenderContext = Nil Then
        Exit;

    If ASurfaceInfo.RenderItem.Item = Nil Then
        Exit;

    If Not ASurfaceInfo.RenderItem.Metrics.HasGlyph Then
        Exit;

    If IsRectEmpty(ASurfaceInfo.RenderItem.Metrics.GlyphRect) Then
        Exit;

    LGlyphRect := ASurfaceInfo.RenderItem.Metrics.GlyphRect;
    OffsetRect(
        LGlyphRect,
        ASurfaceInfo.RenderItem.Bounds.Left,
        ASurfaceInfo.RenderItem.Bounds.Top);

    If IsRectEmpty(LGlyphRect) Then
        Exit;

    LBitmap := TBitmap.Create;
    Try
        If Not FRenderContext.GetDirect2DItemGlyphBitmap(
            ASurfaceInfo.RenderItem.Item.GlyphIndex,
            LBitmap) Then
            Exit;

        If Not CreateDirect2DBitmapFromVclBitmap(
            LBitmap,
            LD2DBitmap) Then Begin
            Result := False;
            Exit;
        End;

        LDestRect.left := LGlyphRect.Left;
        LDestRect.top := LGlyphRect.Top;
        LDestRect.right := LGlyphRect.Right;
        LDestRect.bottom := LGlyphRect.Bottom;

        FillChar(
            LIdentityTransform,
            SizeOf(LIdentityTransform),
            0);
        LIdentityTransform._11 := 1.0;
        LIdentityTransform._22 := 1.0;

        Case ASurfaceInfo.RenderItem.Metrics.TextOrientation Of
            nrttoVerticalUp:
                LRad := -Pi / 2.0;

            nrttoVerticalDown:
                LRad := Pi / 2.0;
        Else
            LRad := 0.0;
        End;

        If Abs(LRad) < 0.01 Then Begin
            FDCRenderTarget.DrawBitmap(
                LD2DBitmap,
                @LDestRect,
                1.0,
                D2D1_BITMAP_INTERPOLATION_MODE_LINEAR,
                Nil);
        End Else Begin
            LCenterX := (LGlyphRect.Left + LGlyphRect.Right) / 2.0;
            LCenterY := (LGlyphRect.Top + LGlyphRect.Bottom) / 2.0;
            LCos := Cos(LRad);
            LSin := Sin(LRad);

            FillChar(
                LTransform,
                SizeOf(LTransform),
                0);
            LTransform._11 := Single(LCos);
            LTransform._12 := Single(LSin);
            LTransform._21 := Single(-LSin);
            LTransform._22 := Single(LCos);
            LTransform._31 := LCenterX - (LCenterX * Single(LCos)) + (LCenterY * Single(LSin));
            LTransform._32 := LCenterY - (LCenterX * Single(LSin)) - (LCenterY * Single(LCos));

            FDCRenderTarget.SetTransform(LTransform);
            Try
                FDCRenderTarget.DrawBitmap(
                    LD2DBitmap,
                    @LDestRect,
                    1.0,
                    D2D1_BITMAP_INTERPOLATION_MODE_LINEAR,
                    Nil);
            Finally
                FDCRenderTarget.SetTransform(LIdentityTransform);
            End;
        End;

        LD2DBitmap := Nil;
    Finally
        LBitmap.Free;
    End;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintOneDirect2DItemText(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
Var
    LTextBrush: ID2D1SolidColorBrush;
    LTextColor: D2D1_COLOR_F;
    LTextFormat: IDWriteTextFormat;
    LTextRect: D2D1_RECT_F;
    LText: WideString;
    LMetric: TNoReflowTabBarItemMetrics;
    LBounds: TRect;
    LTextX: Single;
    LTextY: Single;
    LTextWidth: Single;
    LTextHeight: Single;
    LTransform: D2D1_MATRIX_3X2_F;
    LIdentityTransform: D2D1_MATRIX_3X2_F;
    LRad: Double;
    LCos: Double;
    LSin: Double;
Begin
    Result := True;

    If ASurfaceInfo.Text = '' Then
        Exit;

    If Not DirectWriteResourcesAvailable Then
        Exit;

    LMetric := ASurfaceInfo.RenderItem.Metrics;
    LBounds := ASurfaceInfo.RenderItem.Bounds;

    If (LMetric.TextWidth <= 0) Or (LMetric.TextHeight <= 0) Then
        Exit;

    LTextColor := ColorToDirect2DColor(ASurfaceInfo.TextColor);

    If Not CreateSolidBrush(LTextColor, LTextBrush) Then Begin
        Result := False;
        Exit;
    End;

    If Not CreateItemTextFormat(ASurfaceInfo, LTextFormat) Then Begin
        LTextBrush := Nil;
        Result := False;
        Exit;
    End;

    LText := ASurfaceInfo.Text;

    LTextX := LBounds.Left + LMetric.TextX;
    LTextY := LBounds.Top + LMetric.TextY;

    //-------------------------------------------------------------------------
    // Les metriques TextWidth/TextHeight sont deja les dimensions logiques
    // utilisees par le layout GDI pour calculer les points d'ancrage TextOut.
    //
    // Il ne faut donc pas les gonfler ici pour compenser un eventuel clipping
    // DirectWrite : en texte vertical, ces dimensions participent directement
    // a la transformation qui reconstruit l'ancrage GDI TA_BOTTOM / TA_RIGHT.
    //
    // Ajouter quelques pixels au rectangle DirectWrite deplace mecaniquement le
    // texte :
    // - en VerticalUp, la hauteur ajoutee pousse le bloc vers la gauche ;
    // - en VerticalDown, la largeur ajoutee remonte le bloc vers le glyph.
    //
    // La correction doit donc conserver les dimensions calculees par le layout,
    // puis laisser DirectWrite dessiner dans le meme repere logique que GDI.
    //-------------------------------------------------------------------------
    LTextWidth := LMetric.TextWidth;
    LTextHeight := LMetric.TextHeight;

    FillChar(LIdentityTransform, SizeOf(LIdentityTransform), 0);
    LIdentityTransform._11 := 1.0;
    LIdentityTransform._22 := 1.0;

    Case LMetric.TextOrientation Of
        nrttoHorizontal: Begin
                If Not IsRectEmpty(LMetric.TextClipRect) Then Begin
                    //---------------------------------------------------------
                    // Texte horizontal : consommer la zone de clipping calculee
                    // par le layout. Le backend Direct2D ne recalcule pas cette
                    // zone afin de rester strictement aligne avec le backend GDI.
                    //---------------------------------------------------------
                    LTextRect.left := LBounds.Left + LMetric.TextClipRect.Left;
                    LTextRect.top := LBounds.Top + LMetric.TextClipRect.Top;
                    LTextRect.right := LBounds.Left + LMetric.TextClipRect.Right;
                    LTextRect.bottom := LBounds.Top + LMetric.TextClipRect.Bottom;
                End Else Begin
                    LTextRect.left := LTextX;
                    LTextRect.top := LTextY;
                    LTextRect.right := LTextX + LTextWidth;
                    LTextRect.bottom := LTextY + LTextHeight;
                End;

                FDCRenderTarget.DrawText(
                    PWideChar(LText),
                    Length(LText),
                    LTextFormat,
                    LTextRect,
                    LTextBrush,
                    D2D1_DRAW_TEXT_OPTIONS_CLIP,
                    DWRITE_MEASURING_MODE_GDI_CLASSIC);
            End;

        nrttoVerticalUp: Begin
                //-----------------------------------------------------------------
                // v48 : texte vertical issu du meme calcul canonique horizontal.
                //
                // TextClipRect est le rectangle physique final produit par le
                // layout apres projection. Direct2D reconstitue le rectangle
                // canonique en utilisant :
                // - largeur logique  = hauteur physique ;
                // - hauteur logique  = largeur physique.
                //
                // Rotation -90 degres :
                //   x' = y + tx
                //   y' = -x + ty
                // Pour obtenir le rectangle physique TextClipRect, il faut :
                //   tx = Left
                //   ty = Bottom
                //-----------------------------------------------------------------
                If Not IsRectEmpty(LMetric.TextClipRect) Then Begin
                    //---------------------------------------------------------
                    // v50 : l'ancre verticale est fournie par le layout.
                    // Pour VerticalUp, elle correspond au point bas/gauche du
                    // rectangle physique. Direct2D ne la reconstruit plus depuis
                    // les bords du rectangle.
                    //---------------------------------------------------------
                    LTextX := LBounds.Left + LMetric.TextX;
                    LTextY := LBounds.Top + LMetric.TextY;
                    LTextWidth := LMetric.TextClipRect.Bottom - LMetric.TextClipRect.Top;
                    LTextHeight := LMetric.TextClipRect.Right - LMetric.TextClipRect.Left;
                End;

                If (LTextWidth <= 0) Or (LTextHeight <= 0) Then
                    Exit;

                LRad := -Pi / 2.0;
                LCos := Cos(LRad);
                LSin := Sin(LRad);

                FillChar(LTransform, SizeOf(LTransform), 0);
                LTransform._11 := Single(LCos);
                LTransform._12 := Single(LSin);
                LTransform._21 := Single(-LSin);
                LTransform._22 := Single(LCos);
                LTransform._31 := LTextX;
                LTransform._32 := LTextY;

                LTextRect.left := 0.0;
                LTextRect.top := 0.0;
                LTextRect.right := LTextWidth;
                LTextRect.bottom := LTextHeight;

                FDCRenderTarget.SetTransform(LTransform);
                Try
                    FDCRenderTarget.DrawText(
                        PWideChar(LText),
                        Length(LText),
                        LTextFormat,
                        LTextRect,
                        LTextBrush,
                        D2D1_DRAW_TEXT_OPTIONS_CLIP,
                        DWRITE_MEASURING_MODE_GDI_CLASSIC);
                Finally
                    FDCRenderTarget.SetTransform(LIdentityTransform);
                End;
            End;

        nrttoVerticalDown: Begin
                //-----------------------------------------------------------------
                // v48 : meme rectangle canonique que VerticalUp, mais projection
                // par rotation +90 degres.
                //
                // Rotation +90 degres :
                //   x' = -y + tx
                //   y' =  x + ty
                // Pour obtenir le rectangle physique TextClipRect, il faut :
                //   tx = Right
                //   ty = Top
                //-----------------------------------------------------------------
                If Not IsRectEmpty(LMetric.TextClipRect) Then Begin
                    //---------------------------------------------------------
                    // v50 : l'ancre verticale est fournie par le layout.
                    // Pour VerticalDown, elle correspond au point haut/droit du
                    // rectangle physique. Direct2D ne la reconstruit plus depuis
                    // les bords du rectangle.
                    //---------------------------------------------------------
                    LTextX := LBounds.Left + LMetric.TextX;
                    LTextY := LBounds.Top + LMetric.TextY;
                    LTextWidth := LMetric.TextClipRect.Bottom - LMetric.TextClipRect.Top;
                    LTextHeight := LMetric.TextClipRect.Right - LMetric.TextClipRect.Left;
                End;

                If (LTextWidth <= 0) Or (LTextHeight <= 0) Then
                    Exit;

                LRad := Pi / 2.0;
                LCos := Cos(LRad);
                LSin := Sin(LRad);

                FillChar(LTransform, SizeOf(LTransform), 0);
                LTransform._11 := Single(LCos);
                LTransform._12 := Single(LSin);
                LTransform._21 := Single(-LSin);
                LTransform._22 := Single(LCos);
                LTransform._31 := LTextX;
                LTransform._32 := LTextY;

                LTextRect.left := 0.0;
                LTextRect.top := 0.0;
                LTextRect.right := LTextWidth;
                LTextRect.bottom := LTextHeight;

                FDCRenderTarget.SetTransform(LTransform);
                Try
                    FDCRenderTarget.DrawText(
                        PWideChar(LText),
                        Length(LText),
                        LTextFormat,
                        LTextRect,
                        LTextBrush,
                        D2D1_DRAW_TEXT_OPTIONS_CLIP,
                        DWRITE_MEASURING_MODE_GDI_CLASSIC);
                Finally
                    FDCRenderTarget.SetTransform(LIdentityTransform);
                End;
            End;
    End;

    LTextFormat := Nil;
    LTextBrush := Nil;
End;


Function TNoReflowTabBarDirect2DRenderBackend.PaintOneDirect2DItemFocus(
    Const ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
Var
    LFocusBrush: ID2D1SolidColorBrush;
    LFocusColor: D2D1_COLOR_F;
    LRect: TRect;
    LLeft: Single;
    LTop: Single;
    LRight: Single;
    LBottom: Single;

    Procedure DrawHorizontalDashes(
        AY: Single;
        AX1: Single;
        AX2: Single);
    Var
        LDashStart: Single;
        LDashEnd: Single;
        LDashLength: Single;
        LGapLength: Single;
        LP1: D2D1_POINT_2F;
        LP2: D2D1_POINT_2F;
    Begin
        LDashLength := 2.0;
        LGapLength := 2.0;
        LDashStart := AX1;

        While LDashStart < AX2 Do Begin
            LDashEnd := Min(
                LDashStart + LDashLength,
                AX2);

            LP1.x := LDashStart;
            LP1.y := AY;
            LP2.x := LDashEnd;
            LP2.y := AY;

            FDCRenderTarget.DrawLine(
                LP1,
                LP2,
                LFocusBrush,
                1.0,
                Nil);

            LDashStart := LDashEnd + LGapLength;
        End;
    End;

    Procedure DrawVerticalDashes(
        AX: Single;
        AY1: Single;
        AY2: Single);
    Var
        LDashStart: Single;
        LDashEnd: Single;
        LDashLength: Single;
        LGapLength: Single;
        LP1: D2D1_POINT_2F;
        LP2: D2D1_POINT_2F;
    Begin
        LDashLength := 2.0;
        LGapLength := 2.0;
        LDashStart := AY1;

        While LDashStart < AY2 Do Begin
            LDashEnd := Min(
                LDashStart + LDashLength,
                AY2);

            LP1.x := AX;
            LP1.y := LDashStart;
            LP2.x := AX;
            LP2.y := LDashEnd;

            FDCRenderTarget.DrawLine(
                LP1,
                LP2,
                LFocusBrush,
                1.0,
                Nil);

            LDashStart := LDashEnd + LGapLength;
        End;
    End;

Begin
    //-------------------------------------------------------------------------
    // Focus clavier en Direct2D.
    //
    // La zone de focus est fournie par le contexte dans FocusRect. Elle est deja
    // exprimee dans le repere final du controle et tient compte des metriques de
    // layout : texte, glyph et voyant. Le backend Direct2D ne reconstruit donc
    // pas l'emprise du contenu ; il se limite a dessiner un contour pointille
    // dans le rectangle prepare.
    //-------------------------------------------------------------------------
    Result := True;

    If Not ASurfaceInfo.DrawFocus Then
        Exit;

    LRect := ASurfaceInfo.FocusRect;

    If IsRectEmpty(LRect) Then
        Exit;

    If (LRect.Right <= LRect.Left) Or (LRect.Bottom <= LRect.Top) Then
        Exit;

    LFocusColor := ColorToDirect2DColor(ASurfaceInfo.FocusColor);

    If Not CreateSolidBrush(LFocusColor, LFocusBrush) Then Begin
        Result := False;
        Exit;
    End;

    //-------------------------------------------------------------------------
    // Alignement demi-pixel : comme pour les bordures v63, on dessine le trait
    // sur le centre des pixels afin d'obtenir une couleur franche sans epaissir
    // artificiellement le focus.
    //-------------------------------------------------------------------------
    LLeft := LRect.Left + 0.5;
    LTop := LRect.Top + 0.5;
    LRight := LRect.Right - 0.5;
    LBottom := LRect.Bottom - 0.5;

    If (LRight <= LLeft) Or (LBottom <= LTop) Then Begin
        LFocusBrush := Nil;
        Exit;
    End;

    DrawHorizontalDashes(
        LTop,
        LLeft,
        LRight);
    DrawHorizontalDashes(
        LBottom,
        LLeft,
        LRight);
    DrawVerticalDashes(
        LLeft,
        LTop,
        LBottom);
    DrawVerticalDashes(
        LRight,
        LTop,
        LBottom);

    LFocusBrush := Nil;
End;

Function TNoReflowTabBarDirect2DRenderBackend.PaintItemContentsWithDirect2D(
    ACanvas: TCanvas): Boolean;
Var
    LClientRect: TRect;
    LResult: HResult;
    LIndex: Integer;
    LCount: Integer;
    LSurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo;
    LPaintOk: Boolean;
    LPaintedCount: Integer;
Begin
    //-------------------------------------------------------------------------
    // Contenu autonome Direct2D.
    //
    // Cette methode dessine uniquement les elements standards du backend
    // Direct2D : signaux, glyphs, texte et focus. Elle n'appelle pas le hook
    // OnGDIPaintItem, qui est explicitement reserve au rendu GDI/VCL car il
    // expose un TCanvas.
    //
    // Un futur OnDirect2DPaintItem devra etre ajoute avec un contrat Direct2D
    // dedie si l'on veut permettre du custom painting natif dans ce backend.
    //-------------------------------------------------------------------------
    Result := False;

    If ACanvas = Nil Then
        Exit;

    If FRenderContext = Nil Then
        Exit;

    If Not Direct2DResourcesAvailable Then
        Exit;

    If Not Direct2DRenderTargetAvailable Then
        Exit;

    If Not DirectWriteResourcesAvailable Then
        Exit;

    FRenderContext.PrepareDirect2DItemSurfaces;

    LClientRect := FRenderContext.GetRenderClientRect;

    If IsRectEmpty(LClientRect) Then
        Exit;

    If Not BindDirect2DRenderTargetToCanvas(
        ACanvas,
        LClientRect) Then
        Exit;

    LCount := FRenderContext.GetDirect2DItemSurfaceCount;

    If LCount <= 0 Then
        Exit;

    LPaintOk := True;
    LPaintedCount := 0;

    FDCRenderTarget.BeginDraw;

    For LIndex := 0 To LCount - 1 Do Begin
        If Not FRenderContext.GetDirect2DItemSurfaceInfo(
            LIndex,
            LSurfaceInfo) Then
            Continue;

        If Not PaintOneDirect2DItemSignal(LSurfaceInfo) Then Begin
            LPaintOk := False;
            Break;
        End;

        If Not PaintOneDirect2DItemGlyph(LSurfaceInfo) Then Begin
            LPaintOk := False;
            Break;
        End;

        If Not PaintOneDirect2DItemText(LSurfaceInfo) Then Begin
            LPaintOk := False;
            Break;
        End;

        Inc(LPaintedCount);
    End;

    LResult := FDCRenderTarget.EndDraw(Nil, Nil);

    If LResult < 0 Then Begin
        FRenderState := ntd2dRenderFailed;
        FLastNativeError := LResult;
        Exit;
    End;

    If Not LPaintOk Then Begin
        FRenderState := ntd2dRenderFailed;
        Exit;
    End;

    If LPaintedCount <= 0 Then
        Exit;

    FRenderState := ntd2dItemContentsCompleted;
    FLastNativeError := 0;
    Result := True;
End;

Function TNoReflowTabBarDirect2DRenderBackend.Direct2DRenderStateToText(
    AState: TNoReflowTabBarDirect2DRenderState): String;
Begin
    Case AState Of
        ntd2dNotInitialized:
            Result := 'Direct2D resources not initialized';

        ntd2dFactoryAvailable:
            Result := 'Direct2D factory available';

        ntd2dFactoryFailed:
            Result := 'Direct2D factory creation failed';

        ntd2dDirectWriteFactoryFailed:
            Result := 'DirectWrite factory creation failed';

        ntd2dDirectWriteFactoryQueryFailed:
            Result := 'DirectWrite factory query failed';

        ntd2dDCRenderTargetFailed:
            Result := 'Direct2D DC render target creation failed';

        ntd2dDCRenderTargetBindFailed:
            Result := 'Direct2D DC render target BindDC failed';

        ntd2dDCRenderTargetBound:
            Result := 'Direct2D DC render target bound';

        ntd2dSolidBackgroundCompleted:
            Result := 'Direct2D solid bar background completed';

        ntd2dItemSurfacesCompleted:
            Result := 'Direct2D item surfaces completed';

        ntd2dItemContentsCompleted:
            Result := 'Direct2D item contents completed';

        ntd2dZoneHeadersCompleted:
            Result := 'Direct2D zone headers completed';

        ntd2dItemSurfaceDebugCompleted:
            Result := 'Direct2D item surface debug completed';

        ntd2dItemGeometryDebugCompleted:
            Result := 'Direct2D item geometry debug completed';

        ntd2dRenderFailed:
            Result := 'Direct2D render failed';

        ntd2dReleased:
            Result := 'Direct2D resources released';
    Else
        Result := 'Unknown Direct2D state';
    End;
End;

Function TNoReflowTabBarDirect2DRenderBackend.LastNativeErrorText: String;
Begin
    If FLastNativeError = 0 Then Begin
        Result := '';
        Exit;
    End;

    Result := ' HRESULT=$' + IntToHex(FLastNativeError, 8);
End;

Procedure TNoReflowTabBarDirect2DRenderBackend.FallbackPaintToCanvas(
    ACanvas: TCanvas;
    AOptions: TNoReflowTabBarRenderPaintOptions);
Begin
    If FFallbackBackend = Nil Then
        Exit;

    FFallbackBackend.PaintToCanvasWithOptions(
        ACanvas,
        AOptions);
End;

Function TNoReflowTabBarDirect2DRenderBackend.GetBackendName: String;
Begin
    Result := Direct2DRenderStateToText(FRenderState) + LastNativeErrorText;
End;

Procedure TNoReflowTabBarDirect2DRenderBackend.PaintToCanvas(ACanvas: TCanvas);
Begin
    PaintToCanvasWithOptions(
        ACanvas,
        []);
End;

Procedure TNoReflowTabBarDirect2DRenderBackend.PaintToCanvasWithOptions(
    ACanvas: TCanvas;
    AOptions: TNoReflowTabBarRenderPaintOptions);
Var
    LBackgroundPainted: Boolean;
    LZoneHeadersPainted: Boolean;
    LItemSurfacesPainted: Boolean;
    LItemContentsPainted: Boolean;
Begin
    //--------------------------------------------------------------------------
    // Passe Direct2D active.
    //
    // La v30 conservait encore un fallback GDI complet lorsque le backend
    // Direct2D ne parvenait pas a produire toutes les couches attendues. Cette
    // securite etait utile pour l'utilisateur final, mais elle rendait le
    // diagnostic impossible : une barre strictement identique au rendu GDI ne
    // permettait plus de savoir si Direct2D avait reussi ou si le fallback avait
    // simplement repris la main.
    //
    // Regle de cette passe : lorsque BarRenderBackendKind vaut ntrbkDirect2D,
    // cette classe ne delegue pas le rendu complet au backend GDI. La seule
    // exception admise depuis v78 concerne le fond general en mode style VCL,
    // car un style peut fournir une texture que Direct2D ne peut pas deduire
    // d'une couleur. Dans ce cas, le contexte peint seulement le fond VCL, puis
    // Direct2D dessine les headers, surfaces d'items et contenus par-dessus.
    //
    // Consequence volontaire : si une couche Direct2D echoue, le controle peut
    // apparaitre partiellement peint ou vide. C'est precisement le signal
    // recherche pour identifier l'etape native qui bloque encore.
    //--------------------------------------------------------------------------
    LBackgroundPainted := False;
    LZoneHeadersPainted := False;
    LItemSurfacesPainted := False;
    LItemContentsPainted := False;

    If Not (ntrpoSkipBarBackground In AOptions) Then
        LBackgroundPainted := PaintBarBackgroundWithDirect2D(ACanvas);

    LZoneHeadersPainted := PaintZoneHeadersWithDirect2D(ACanvas);

    If Not (ntrpoSkipItemSurfaces In AOptions) Then
        LItemSurfacesPainted := PaintItemSurfacesWithDirect2D(ACanvas);

    // v33 : le contenu standard est peint item par item dans
    // PaintItemSurfacesWithDirect2D afin de respecter les recouvrements.
    LItemContentsPainted := LItemSurfacesPainted;

    //--------------------------------------------------------------------------
    // Les deux variables sont volontairement conservees meme si elles ne
    // declenchent plus de fallback. Elles permettent de garder un point
    // d'observation clair au debogage et evitent que le compilateur signale des
    // appels sans lecture dans certains reglages.
    //--------------------------------------------------------------------------
    If LBackgroundPainted Or LZoneHeadersPainted Or LItemSurfacesPainted Or LItemContentsPainted Then Begin
        Exit;
    End;

    //--------------------------------------------------------------------------
    // Aucun fallback GDI complet ici. Si aucune couche Direct2D n'a pu etre
    // peinte, la barre reste vide ou partiellement peinte afin de rendre
    // l'echec visible. Le fond VCL texture eventuellement peint plus haut reste
    // une couche de background, pas une reprise du rendu par le backend GDI.
    //--------------------------------------------------------------------------
End;

End.
