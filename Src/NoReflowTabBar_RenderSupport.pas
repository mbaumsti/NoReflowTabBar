Unit NoReflowTabBar_RenderSupport;

{
  NoReflowTabBar_RenderSupport.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Rendering support facade of the NoReflowTabBar VCL component.

  Repository:
  https://github.com/mbaumsti/NoReflowTabBar

  License:
  See LICENSE file.

  ------------------------------------------------------------------------------

  Facade interne du rendu du composant NoReflowTabBar.

  Depuis la version interne v15, le rendu GDI/GDI+ concret vit dans
  NoReflowTabBar_RenderBackend_GDI.pas. Cette unite conserve le nom historique
  TNoReflowTabBarRenderSupport afin de ne pas casser la chaine d'heritage du
  composant.

  Role actuel
  -----------
  La facade implemente INoReflowTabBarRenderContext. Ce contexte donne aux
  backends separes les informations deja preparees par les couches communes :
  rectangle client, fond, surfaces d'items, textes resolus, glyphs, signaux et
  primitives de headers.

  Depuis la version publique 1.3, Direct2D n'est plus seulement une passe de
  preparation : il dessine nativement le contenu standard du composant. Le seul
  chemin hybride conserve concerne le fond general lorsque le style VCL actif
  utilise une texture que Direct2D ne peut pas deduire d'une simple couleur.

  Regle de maintenance
  --------------------
  RenderSupport orchestre et expose le contexte. Il ne doit pas devenir un
  renderer concret. Toute correction du dessin GDI doit rester dans
  NoReflowTabBar_RenderBackend_GDI.pas. Toute correction du dessin Direct2D doit
  rester dans NoReflowTabBar_RenderBackend_Direct2D.pas. Toute correction de
  position, rectangle, metrique, contour ou primitive partagee doit remonter
  dans LayoutSupport ou ZoneLayout.
}

Interface

Uses
    System.SysUtils,
    System.Types,
    System.classes,
    Winapi.Windows,
    Vcl.Graphics,
    Vcl.Themes,
    Vcl.Controls,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_ZoneLayout,
    NoReflowTabBar_RenderBackend,
    NoReflowTabBar_RenderBackend_GDI;

Type
    {
      Couche de compatibilite conservee dans la chaine d'heritage historique.

      Le composant continue d'heriter de cette classe, mais la peinture finale
      passe par ResolveRenderBackend et donc par INoReflowTabBarRenderBackend.
      En mode GDI, le backend resolu reste Self. En mode Direct2D, le backend
      resolu est un objet separe qui utilise Self uniquement comme fallback et
      comme contexte de lecture minimal.
    }
    TNoReflowTabBarRenderSupport = Class(TNoReflowTabBarGDIRenderBackendSupport, INoReflowTabBarRenderContext)
    protected
        //---------------------------------------------------------------------
        //Backend effectivement utilise par la derniere passe de rendu.
        //---------------------------------------------------------------------
        FResolvedRenderBackend: INoReflowTabBarRenderBackend;

        //---------------------------------------------------------------------
        //Type de backend ayant servi a construire FResolvedRenderBackend.
        //---------------------------------------------------------------------
        FResolvedBarRenderBackendKind: TNoReflowTabBarRenderBackendKind;

        //---------------------------------------------------------------------
        //Backend demande par le composant. Depuis le portage Direct2D complet,
        //le choix par defaut des nouvelles instances est ntrbkDirect2D.
        //---------------------------------------------------------------------
        FBarRenderBackendKind: TNoReflowTabBarRenderBackendKind;

        Procedure SetBarRenderBackendKind(Const Value: TNoReflowTabBarRenderBackendKind);
        //Invalide le backend resolu et force sa reconstruction au prochain Paint.
        Procedure InvalidateRenderBackend;

        //Retourne le backend de rendu actuellement utilise par le composant.
        Function ResolveRenderBackend: INoReflowTabBarRenderBackend;

        //INoReflowTabBarRenderContext : rectangle client final du controle.
        Function GetRenderClientRect: TRect;

        //INoReflowTabBarRenderContext : indique si le fond peut etre remplace
        //par un remplissage Direct2D solide sans perdre les effets du style VCL.
        Function CanUseDirect2DSolidBarBackground: Boolean;

        //INoReflowTabBarRenderContext : couleur solide de fond utilisable par
        //le backend Direct2D lorsque CanUseDirect2DSolidBarBackground=True.
        Function GetDirect2DSolidBarBackgroundColor: TColor;

        //INoReflowTabBarRenderContext : peint le fond general par le chemin
        //VCL/GDI commun lorsque Direct2D ne peut pas le representer fidelement
        //par une couleur solide.
        Function PaintBarBackgroundToCanvas(ACanvas: TCanvas): Boolean;

        //INoReflowTabBarRenderContext : indique si les surfaces standard
        //des items peuvent etre peintes nativement sans changer la semantique
        //des evenements de peinture personnalisee.
        Function CanUseDirect2DItemSurfaces: Boolean;

        //INoReflowTabBarRenderContext : prepare les render items avant lecture
        //par le backend natif.
        Procedure PrepareDirect2DItemSurfaces;

        //INoReflowTabBarRenderContext : nombre de render items disponibles.
        Function GetDirect2DItemSurfaceCount: Integer;

        //INoReflowTabBarRenderContext : retourne les donnees resolues d une
        //surface d item pour le backend Direct2D.
        Function GetDirect2DItemSurfaceInfo(
            AIndex: Integer;
            Out ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;

        //INoReflowTabBarRenderContext : prepare les donnees finales des
        //headers de zones pour le backend Direct2D.
        Procedure PrepareDirect2DZoneHeaders;

        //INoReflowTabBarRenderContext : nombre de headers de zones disponibles.
        Function GetDirect2DZoneHeaderCount: Integer;

        //INoReflowTabBarRenderContext : retourne les primitives resolues d'un
        //header de zone.
        Function GetDirect2DZoneHeaderInfo(
            AIndex: Integer;
            Out AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Boolean;

        //INoReflowTabBarRenderContext : copie un glyph depuis BarImages dans
        //un bitmap fourni par le backend natif. Le backend Direct2D reste ainsi
        //separe du composant et ne depend pas directement de FBarImages.
        Function GetDirect2DItemGlyphBitmap(
            AImageIndex: Integer;
            ABitmap: TBitmap): Boolean;

        //Choisit le backend de rendu bas niveau demande par la barre.
        Property BarRenderBackendKind: TNoReflowTabBarRenderBackendKind Read FBarRenderBackendKind Write SetBarRenderBackendKind default ntrbkDirect2D;
    public
        Constructor Create(AOwner: TComponent); override;

    End;

Implementation

Constructor TNoReflowTabBarRenderSupport.Create(AOwner: TComponent);
Begin
    Inherited Create(AOwner);

    FBarRenderBackendKind := ntrbkDirect2D;
    FResolvedBarRenderBackendKind := ntrbkGDI;
    FResolvedRenderBackend := Nil;
End;

Procedure TNoReflowTabBarRenderSupport.InvalidateRenderBackend;
Begin
    FResolvedRenderBackend := Nil;
End;

Procedure TNoReflowTabBarRenderSupport.SetBarRenderBackendKind(Const Value: TNoReflowTabBarRenderBackendKind);
Begin
    If FBarRenderBackendKind = Value Then
        Exit;

    FBarRenderBackendKind := Value;
    InvalidateRenderBackend;
    Invalidate;
End;

Function TNoReflowTabBarRenderSupport.ResolveRenderBackend: INoReflowTabBarRenderBackend;
Var
    LGDIFallback: INoReflowTabBarRenderBackend;
Begin
    //--------------------------------------------------------------------------
    //Le fallback GDI reste Self : le rendu historique vit encore dans
    //TNoReflowTabBarGDIRenderBackendSupport. Le backend Direct2D, lui, est un
    //objet separe cree par la factory commune.
    //--------------------------------------------------------------------------
    If (FResolvedRenderBackend = Nil) Or (FResolvedBarRenderBackendKind <> FBarRenderBackendKind) Then Begin
        LGDIFallback := Self As INoReflowTabBarRenderBackend;

        FResolvedRenderBackend := CreateNoReflowTabBarRenderBackend(
            FBarRenderBackendKind,
            LGDIFallback,
            Self As INoReflowTabBarRenderContext);

        FResolvedBarRenderBackendKind := FBarRenderBackendKind;
    End;

    Result := FResolvedRenderBackend;
End;

Function TNoReflowTabBarRenderSupport.GetRenderClientRect: TRect;
Begin
    //--------------------------------------------------------------------------
    //Le backend Direct2D dessine dans le repere final du controle. Le rectangle
    //client VCL est donc le rectangle naturel du render target DC.
    //--------------------------------------------------------------------------
    Result := ClientRect;
End;

Function TNoReflowTabBarRenderSupport.CanUseDirect2DSolidBarBackground: Boolean;
Var
    LStyle: TCustomStyleServices;
Begin
    //--------------------------------------------------------------------------
    // v78 : decision centrale pour le fond general en mode Direct2D.
    //
    // IMPORTANT : un fond issu du style VCL ne peut pas toujours etre reduit a
    // une couleur solide. Certains styles dessinent une texture, un motif, un
    // effet parent ou une surface dependant du theme. Dans ce cas, Direct2D ne
    // doit pas inventer une approximation a partir de Palette.BarBackground.
    //
    // La solution retenue est volontairement hybride mais limitee :
    // - le fond style est peint par PaintBarBackgroundToCanvas, donc par le
    //   moteur VCL qui connait la vraie texture du style ;
    // - les items, textes, glyphs, signaux et headers restent ensuite peints
    //   par le backend Direct2D ;
    // - aucun calcul de layout n'est effectue ici.
    //
    // En palette custom, le fond appartient au composant et se reduit bien a une
    // couleur commune. Direct2D peut donc le remplir nativement.
    //--------------------------------------------------------------------------
    Result := True;

    If FPaletteMode <> nrtcmStyle Then
        Exit;

    LStyle := ResolveControlStyleServices;

    If (LStyle <> Nil) And
       LStyle.Enabled And
       (seClient In StyleElements) Then
        Result := False;
End;

Function TNoReflowTabBarRenderSupport.GetDirect2DSolidBarBackgroundColor: TColor;
Var
    Palette: TNoReflowTabBarPalette;
Begin
    //--------------------------------------------------------------------------
    //La couleur vient de la meme palette active que DrawBarBackground. La
    //decision d'utiliser ou non cette couleur en Direct2D reste separee dans
    //CanUseDirect2DSolidBarBackground pour eviter de simplifier abusivement le
    //cas des styles VCL.
    //--------------------------------------------------------------------------
    Palette := GetActivePalette;
    Result := Palette.BarBackground;
End;

Function TNoReflowTabBarRenderSupport.PaintBarBackgroundToCanvas(ACanvas: TCanvas): Boolean;
Var
    R:       TRect;
    Palette: TNoReflowTabBarPalette;
    LStyle:  TCustomStyleServices;
Begin
    //--------------------------------------------------------------------------
    // Peint le fond general de la barre par le chemin VCL/GDI commun.
    //
    // REGLE v78 : cette methode est le chemin officiel des fonds de style qui
    // ne peuvent pas etre representes fidelement par une couleur Direct2D.
    //
    // Le backend Direct2D peut l'appeler AVANT ses propres passes natives pour
    // conserver les fonds textures du style VCL. Ce n'est pas un fallback GDI du
    // composant complet : seule la couche de fond est deleguee au moteur VCL.
    //
    // Cette methode ne fait aucun calcul de layout. Elle centralise uniquement
    // la politique de peinture du fond afin que GDI et Direct2D partagent la
    // meme source visuelle en mode nrtcmStyle.
    //--------------------------------------------------------------------------
    Result := False;

    If ACanvas = Nil Then
        Exit;

    R := ClientRect;

    If IsRectEmpty(R) Then
        Exit;

    LStyle := ResolveControlStyleServices;

    If (FPaletteMode = nrtcmStyle) And
       (LStyle <> Nil) And
       LStyle.Enabled And
       (seClient In StyleElements) Then Begin
        LStyle.DrawParentBackground(
            Handle,
            ACanvas.Handle,
            Nil,
            False,
            @R);

        Result := True;
        Exit;
    End;

    Palette := GetActivePalette;

    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := Palette.BarBackground;
    ACanvas.FillRect(R);

    Result := True;
End;

Function TNoReflowTabBarRenderSupport.CanUseDirect2DItemSurfaces: Boolean;
Begin
    //--------------------------------------------------------------------------
    //Cette methode reste dans le contrat pour permettre des restrictions
    //futures, mais elle ne bloque plus le rendu actif des surfaces Direct2D.
    //
    //OnGDIPaintItem est volontairement rattache au backend GDI : il recoit un
    //TCanvas et n'est pas appele par le backend Direct2D autonome. La presence
    //de cet evenement ne doit donc pas empecher le backend Direct2D de peindre
    //ses surfaces standards.
    //
    //Si un vrai hook Direct2D est ajoute plus tard, il devra recevoir un
    //contexte Direct2D dedie au lieu de melanger les backends pendant la meme
    //passe de rendu.
    //--------------------------------------------------------------------------
    Result := True;
End;

Procedure TNoReflowTabBarRenderSupport.PrepareDirect2DItemSurfaces;
Begin
    //--------------------------------------------------------------------------
    //EnsureRenderInfo reste proprietaire du calcul de layout historique :
    //positions finales, zones, recouvrements, contours polygonaux et metriques
    //de contenu sont calcules une seule fois, puis lus par le backend Direct2D.
    //--------------------------------------------------------------------------
    EnsureRenderInfo;
End;

Function TNoReflowTabBarRenderSupport.GetDirect2DItemSurfaceCount: Integer;
Begin
    Result := Length(FRenderItems);
End;

Function TNoReflowTabBarRenderSupport.GetDirect2DItemSurfaceInfo(
    AIndex: Integer;
    Out ASurfaceInfo: TNoReflowTabBarDirect2DItemSurfaceInfo): Boolean;
Var
    LPalette:          TNoReflowTabBarPalette;
    LTextColor:        TColor;
    LSignalBrushColor: TColor;
    LSignalPenColor:   TColor;
    LMetrics:          TNoReflowTabBarItemMetrics;
    LBounds:           TRect;
    LTextRect:         TRect;
    LGlyphRect:        TRect;
    LSignalRect:       TRect;
    LFocusRect:        TRect;
    LHasFocusRect:     Boolean;
Begin
    ASurfaceInfo := Default (TNoReflowTabBarDirect2DItemSurfaceInfo);

    Result := False;

    If AIndex < 0 Then
        Exit;

    If AIndex > High(FRenderItems) Then
        Exit;

    If Not FRenderItems[AIndex].Visible Then
        Exit;

    If Length(FRenderItems[AIndex].RegionPoints) < 3 Then
        Exit;

    LPalette := GetActivePalette;

    ASurfaceInfo.RenderItem := FRenderItems[AIndex];
    ASurfaceInfo.VisualState := GetItemVisualState(FRenderItems[AIndex].ItemIndex);
    ASurfaceInfo.IsButton := IsButtonBarMode;
    ASurfaceInfo.DrawFocus := False;
    ASurfaceInfo.FocusRect := Rect(
        0,
        0,
        0,
        0);
    ASurfaceInfo.FocusColor := clNone;

    If ASurfaceInfo.IsButton Then Begin
        ResolveButtonRenderColors(
            LPalette,
            ASurfaceInfo.VisualState,
            FRenderItems[AIndex].Item.SignalCode,
            ASurfaceInfo.TopColor,
            ASurfaceInfo.BottomColor,
            LTextColor,
            ASurfaceInfo.BorderColor,
            LSignalBrushColor,
            LSignalPenColor);

        ASurfaceInfo.DrawClosedBorder := True;
        ASurfaceInfo.DrawBorder := True;

        If FLayoutButtons <> Nil Then
            ASurfaceInfo.DrawBorder := FLayoutButtons.DrawBorder;

        ASurfaceInfo.BorderWidth := 1.25;

        Case ASurfaceInfo.VisualState Of
            nrtvsHot:
                ASurfaceInfo.BorderWidth := 1.8;

            nrtvsPressed, nrtvsSelected:
                ASurfaceInfo.BorderWidth := 1.8;
        End;
    End Else Begin
        ResolveTabRenderColors(
            LPalette,
            ASurfaceInfo.VisualState,
            FRenderItems[AIndex].Item.SignalCode,
            ASurfaceInfo.TopColor,
            ASurfaceInfo.BottomColor,
            LTextColor,
            ASurfaceInfo.BorderColor,
            LSignalBrushColor,
            LSignalPenColor);

        ASurfaceInfo.DrawClosedBorder := ShouldDrawClosedEdgeForTab(FRenderItems[AIndex].ItemIndex);
        ASurfaceInfo.DrawBorder := True;
        ASurfaceInfo.BorderWidth := 1.25;
    End;

    //-------------------------------------------------------------------------
    //Contenu Direct2D autonome.
    //
    //Le backend Direct2D ne rappelle pas le rendu GDI pour le contenu standard
    //lorsqu'il est selectionne.
    //Les donnees indispensables au contenu standard doivent donc etre exposees
    //avec la surface : texte resolu, couleur de texte, police effective et
    //couleurs de voyant. Cela evite de faire heriter le backend Direct2D du
    //renderer GDI tout en conservant une seule source de verite pour les
    //decisions de palette et de texte.
    //-------------------------------------------------------------------------
    ASurfaceInfo.Text := ResolveItemText(
        FRenderItems[AIndex].ItemIndex,
        FRenderItems[AIndex].Item);

    ASurfaceInfo.TextColor := LTextColor;
    ASurfaceInfo.SignalBrushColor := LSignalBrushColor;
    ASurfaceInfo.SignalPenColor := LSignalPenColor;

    ASurfaceInfo.FontName := Font.Name;
    ASurfaceInfo.FontSize := Font.Size;
    ASurfaceInfo.FontHeight := Font.Height;
    ASurfaceInfo.FontStyle := Font.Style;

    If ASurfaceInfo.VisualState In [nrtvsSelected, nrtvsPressed] Then
        ASurfaceInfo.FontStyle := ASurfaceInfo.FontStyle + FSelectedFontStyle;

    AdjustBackgroundColorsForRenderMode(
        GetEffectiveBarRenderMode,
        FPaletteMode,
        ASurfaceInfo.TopColor,
        ASurfaceInfo.BottomColor);

    //-------------------------------------------------------------------------
    //Focus Direct2D autonome.
    //
    //La zone de focus est resolue ici, dans le contexte du composant, car elle
    //depend de l'etat VCL du controle et des metriques finales produites par
    //le layout. Le backend Direct2D recevra uniquement un rectangle final a
    //dessiner, sans recalculer de position ni d'emprise de contenu.
    //-------------------------------------------------------------------------
    If FShowFocus And Focused And (FRenderItems[AIndex].ItemIndex = GetFocusVisualItemIndex) Then Begin
        LMetrics := FRenderItems[AIndex].Metrics;
        LBounds := FRenderItems[AIndex].Bounds;
        LHasFocusRect := False;

        SetRectEmpty(LTextRect);
        SetRectEmpty(LGlyphRect);
        SetRectEmpty(LSignalRect);
        SetRectEmpty(LFocusRect);

        If Not IsRectEmpty(LMetrics.TextClipRect) Then Begin
            LTextRect := LMetrics.TextClipRect;
            OffsetRect(
                LTextRect,
                LBounds.Left,
                LBounds.Top);

            LFocusRect := LTextRect;
            LHasFocusRect := True;
        End Else If (LMetrics.TextWidth > 0) And (LMetrics.TextHeight > 0) Then Begin
            LTextRect := Rect(
                LBounds.Left + LMetrics.TextX,
                LBounds.Top + LMetrics.TextY,
                LBounds.Left + LMetrics.TextX + LMetrics.TextWidth,
                LBounds.Top + LMetrics.TextY + LMetrics.TextHeight);

            LFocusRect := LTextRect;
            LHasFocusRect := True;
        End;

        If LMetrics.HasSignal And Not IsRectEmpty(LMetrics.SignalRect) Then Begin
            LSignalRect := LMetrics.SignalRect;
            OffsetRect(
                LSignalRect,
                LBounds.Left,
                LBounds.Top);

            If LHasFocusRect Then
                UnionRect(
                    LFocusRect,
                    LFocusRect,
                    LSignalRect)
            Else
                LFocusRect := LSignalRect;

            LHasFocusRect := True;
        End;

        If LMetrics.HasGlyph And Not IsRectEmpty(LMetrics.GlyphRect) Then Begin
            LGlyphRect := LMetrics.GlyphRect;
            OffsetRect(
                LGlyphRect,
                LBounds.Left,
                LBounds.Top);

            If LHasFocusRect Then
                UnionRect(
                    LFocusRect,
                    LFocusRect,
                    LGlyphRect)
            Else
                LFocusRect := LGlyphRect;

            LHasFocusRect := True;
        End;

        If LHasFocusRect Then Begin
            InflateRect(
                LFocusRect,
                3,
                2);

            IntersectRect(
                LFocusRect,
                LFocusRect,
                Rect(LBounds.Left + 3, LBounds.Top + 3, LBounds.Right - 3, LBounds.Bottom - 3));

            If Not IsRectEmpty(LFocusRect) Then Begin
                ASurfaceInfo.DrawFocus := True;
                ASurfaceInfo.FocusRect := LFocusRect;
                ASurfaceInfo.FocusColor := LPalette.TabSelectedText;
            End;
        End;
    End;

    Result := True;
End;

Procedure TNoReflowTabBarRenderSupport.PrepareDirect2DZoneHeaders;
Begin
    //--------------------------------------------------------------------------
    //Les headers de zones dependent des rectangles canoniques produits par le
    //layout. On force donc la preparation normale du rendu avant toute lecture
    //par le backend Direct2D, exactement comme pour les surfaces d'items.
    //--------------------------------------------------------------------------
    EnsureRenderInfo;
End;

Function TNoReflowTabBarRenderSupport.GetDirect2DZoneHeaderCount: Integer;
Begin
    //--------------------------------------------------------------------------
    //Les headers ne sont exposes au backend Direct2D que lorsque le mode zones
    //est actif et que le sous-objet ZoneHeader reserve effectivement de la
    //place. Le filtrage fin des captions vides reste fait dans
    //GetDirect2DZoneHeaderInfo / BuildZoneHeaderRenderInfo.
    //--------------------------------------------------------------------------
    Result := 0;

    If FLayoutMode <> nrblmByZones Then
        Exit;

    If FZoneHeader = Nil Then
        Exit;

    If Not FZoneHeader.Visible Then
        Exit;

    If GetZoneHeaderReservedSize <= 0 Then
        Exit;

    If FZoneLayoutInfo.StartZone.HasZone Then
        Inc(Result);

    If FZoneLayoutInfo.CenterZone.HasZone Then
        Inc(Result);

    If FZoneLayoutInfo.EndZone.HasZone Then
        Inc(Result);
End;

Function TNoReflowTabBarRenderSupport.GetDirect2DZoneHeaderInfo(
    AIndex: Integer;
    Out AHeaderInfo: TNoReflowTabBarDirect2DZoneHeaderInfo): Boolean;
Var
    LCurrentIndex: Integer;
Begin
    //--------------------------------------------------------------------------
    //Retourne le AIndex-ieme header existant selon l'ordre naturel des zones :
    //Start, Center, End. Chaque zone est ensuite filtree par le layout via
    //BuildZoneHeaderRenderInfo, notamment pour les captions vides.
    //--------------------------------------------------------------------------
    InitializeZoneHeaderRenderInfo(AHeaderInfo);
    Result := False;

    If AIndex < 0 Then
        Exit;

    If FLayoutMode <> nrblmByZones Then
        Exit;

    LCurrentIndex := 0;

    If FZoneLayoutInfo.StartZone.HasZone Then Begin
        If LCurrentIndex = AIndex Then Begin
            Result := BuildZoneHeaderRenderInfo(
                nrtpzStart,
                FZoneLayoutInfo.StartZone.OuterCanonicalRect,
                AHeaderInfo);
            Exit;
        End;

        Inc(LCurrentIndex);
    End;

    If FZoneLayoutInfo.CenterZone.HasZone Then Begin
        If LCurrentIndex = AIndex Then Begin
            Result := BuildZoneHeaderRenderInfo(
                nrtpzCenter,
                FZoneLayoutInfo.CenterZone.OuterCanonicalRect,
                AHeaderInfo);
            Exit;
        End;

        Inc(LCurrentIndex);
    End;

    If FZoneLayoutInfo.EndZone.HasZone Then Begin
        If LCurrentIndex = AIndex Then Begin
            Result := BuildZoneHeaderRenderInfo(
                nrtpzEnd,
                FZoneLayoutInfo.EndZone.OuterCanonicalRect,
                AHeaderInfo);
            Exit;
        End;
    End;
End;

Function TNoReflowTabBarRenderSupport.GetDirect2DItemGlyphBitmap(
    AImageIndex: Integer;
    ABitmap: TBitmap): Boolean;
Var
    LBlackBitmap: TBitmap;
    LWhiteBitmap: TBitmap;
    LRow: Integer;
    LCol: Integer;
    LBlackLine: PByte;
    LWhiteLine: PByte;
    LDestLine: PByte;
    LBlackPixel: PByte;
    LWhitePixel: PByte;
    LDestPixel: PByte;
    LBlackBlue: Integer;
    LBlackGreen: Integer;
    LBlackRed: Integer;
    LWhiteBlue: Integer;
    LWhiteGreen: Integer;
    LWhiteRed: Integer;
    LDeltaBlue: Integer;
    LDeltaGreen: Integer;
    LDeltaRed: Integer;
    LDelta: Integer;
    LAlpha: Integer;
    LRed: Integer;
    LGreen: Integer;
    LBlue: Integer;
Begin
    //--------------------------------------------------------------------------
    // Fournit au backend Direct2D une image source exploitable pour convertir un
    // glyph ImageList en ID2D1Bitmap.
    //
    // Regle importante : cette methode ne dessine jamais sur le canvas final du
    // controle. Elle charge uniquement un TBitmap temporaire fourni par
    // l'appelant. La separation des backends reste donc respectee : le backend
    // Direct2D ne rappelle pas le renderer GDI et ne connait pas FBarImages.
    //
    // Correction v72 : ne plus utiliser un fond sentinelle fuchsia. Avec les
    // icones modernes et les bords semi-transparents, l'ImageList melange les
    // pixels de contour avec le fond fuchsia avant que Direct2D ne les lise.
    // Les pixels completement transparents etaient bien supprimes, mais les
    // pixels partiellement transparents conservaient une composante rose visible
    // sous forme de filet autour du glyph.
    //
    // Pour retrouver un canal alpha continu, on dessine le meme glyph sur un
    // fond noir puis sur un fond blanc. La difference entre les deux rendus
    // donne l'opacite du pixel :
    //   blanc - noir = 255 * (1 - alpha)
    // Cette technique conserve les contours anti-aliases sans imposer de couleur
    // transparente arbitraire. Le bitmap retourne est un pf32bit BGRA dont le
    // canal alpha est volontairement renseigne pour le backend Direct2D.
    //--------------------------------------------------------------------------
    Result := False;

    If ABitmap = Nil Then
        Exit;

    If FBarImages = Nil Then
        Exit;

    If AImageIndex < 0 Then
        Exit;

    If AImageIndex >= FBarImages.Count Then
        Exit;

    If (FBarImages.Width <= 0) Or (FBarImages.Height <= 0) Then
        Exit;

    LBlackBitmap := TBitmap.Create;
    LWhiteBitmap := TBitmap.Create;
    Try
        ABitmap.PixelFormat := pf32bit;
        LBlackBitmap.PixelFormat := pf32bit;
        LWhiteBitmap.PixelFormat := pf32bit;

        ABitmap.SetSize(
            FBarImages.Width,
            FBarImages.Height);
        LBlackBitmap.SetSize(
            FBarImages.Width,
            FBarImages.Height);
        LWhiteBitmap.SetSize(
            FBarImages.Width,
            FBarImages.Height);

        LBlackBitmap.Canvas.Brush.Style := bsSolid;
        LBlackBitmap.Canvas.Brush.Color := clBlack;
        LBlackBitmap.Canvas.FillRect(Rect(0, 0, LBlackBitmap.Width, LBlackBitmap.Height));

        LWhiteBitmap.Canvas.Brush.Style := bsSolid;
        LWhiteBitmap.Canvas.Brush.Color := clWhite;
        LWhiteBitmap.Canvas.FillRect(Rect(0, 0, LWhiteBitmap.Width, LWhiteBitmap.Height));

        FBarImages.Draw(
            LBlackBitmap.Canvas,
            0,
            0,
            AImageIndex,
            True);

        FBarImages.Draw(
            LWhiteBitmap.Canvas,
            0,
            0,
            AImageIndex,
            True);

        For LRow := 0 To ABitmap.Height - 1 Do Begin
            LBlackLine := LBlackBitmap.ScanLine[LRow];
            LWhiteLine := LWhiteBitmap.ScanLine[LRow];
            LDestLine := ABitmap.ScanLine[LRow];

            For LCol := 0 To ABitmap.Width - 1 Do Begin
                LBlackPixel := LBlackLine;
                Inc(LBlackPixel, LCol * 4);

                LWhitePixel := LWhiteLine;
                Inc(LWhitePixel, LCol * 4);

                LDestPixel := LDestLine;
                Inc(LDestPixel, LCol * 4);

                LBlackBlue := LBlackPixel^;
                LBlackGreen := PByte(NativeUInt(LBlackPixel) + 1)^;
                LBlackRed := PByte(NativeUInt(LBlackPixel) + 2)^;

                LWhiteBlue := LWhitePixel^;
                LWhiteGreen := PByte(NativeUInt(LWhitePixel) + 1)^;
                LWhiteRed := PByte(NativeUInt(LWhitePixel) + 2)^;

                LDeltaBlue := LWhiteBlue - LBlackBlue;
                LDeltaGreen := LWhiteGreen - LBlackGreen;
                LDeltaRed := LWhiteRed - LBlackRed;

                If LDeltaBlue < 0 Then
                    LDeltaBlue := 0;
                If LDeltaGreen < 0 Then
                    LDeltaGreen := 0;
                If LDeltaRed < 0 Then
                    LDeltaRed := 0;

                LDelta := (LDeltaBlue + LDeltaGreen + LDeltaRed) Div 3;

                If LDelta > 255 Then
                    LDelta := 255;

                LAlpha := 255 - LDelta;

                If LAlpha <= 0 Then Begin
                    LDestPixel^ := 0;
                    PByte(NativeUInt(LDestPixel) + 1)^ := 0;
                    PByte(NativeUInt(LDestPixel) + 2)^ := 0;
                    PByte(NativeUInt(LDestPixel) + 3)^ := 0;
                End Else Begin
                    LBlue := MulDiv(LBlackBlue, 255, LAlpha);
                    LGreen := MulDiv(LBlackGreen, 255, LAlpha);
                    LRed := MulDiv(LBlackRed, 255, LAlpha);

                    If LBlue > 255 Then
                        LBlue := 255;
                    If LGreen > 255 Then
                        LGreen := 255;
                    If LRed > 255 Then
                        LRed := 255;

                    LDestPixel^ := Byte(LBlue);
                    PByte(NativeUInt(LDestPixel) + 1)^ := Byte(LGreen);
                    PByte(NativeUInt(LDestPixel) + 2)^ := Byte(LRed);
                    PByte(NativeUInt(LDestPixel) + 3)^ := Byte(LAlpha);
                End;
            End;
        End;

        Result := Not ABitmap.Empty;
    Finally
        LWhiteBitmap.Free;
        LBlackBitmap.Free;
    End;
End;

End.
