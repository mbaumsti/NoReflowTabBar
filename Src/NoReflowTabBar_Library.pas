Unit NoReflowTabBar_Library;

{
  NoReflowTabBar_Library.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Utility library for the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Shared utility library of the NoReflowTabBar component.

  This unit provides:
  - global component constants;
  - French / English localised messages;
  - UI language and message selection helpers;
  - GDI / GDI+ helpers used by rendering;
  - geometry helpers for polygons, rounded corners and hit testing;
  - colour helpers for blending, contrast and variants;
  - reusable drawing routines used by the rendering engine.

  Role of this unit:
  - group cross-cutting technical helpers used by the component;
  - share drawing and calculation primitives;
  - avoid duplicating low-level helpers across other units;
  - provide a common technical base for rendering and visual calculations.

  Main content:
  - GDI+ initialisation and shutdown;
  - selection between classic GDI and GDI+ rendering paths;
  - conversion between VCL and GDI+ types;
  - antialiased shape filling and border drawing;
  - rounded corner construction and geometry helpers;
  - colour, contrast and gradient calculations;
  - signal fill normalisation;
  - localised messages related to signal management.

  Architecture position:
  - this unit is a shared toolbox;
  - it is used by NoReflowTabBar_Core, NoReflowTabBar, rendering support units,
    and model/style units when common helpers are needed.

  Notes:
  - this unit does not contain the item business model;
  - it does not contain the final published component facade;
  - nrtSignal* constants define the reserved built-in signal codes.
}

Interface

Uses
    Winapi.Windows,
    Winapi.Messages,
    Winapi.CommCtrl,
    Winapi.GDIPAPI,
    Winapi.GDIPOBJ,
    Winapi.GDIPUTIL,
    System.Classes,
    System.Types,
    System.SysUtils,
    Vcl.Controls,
    Vcl.StdCtrls,
    Vcl.Graphics,
    Vcl.Forms,
    Vcl.Themes,
    Vcl.GraphUtil,
    System.Math,
    System.Generics.Collections,
    NoreflowTabBar_CommonTypes;

Type
    {
      User interface language used to select localised component messages.
    }
    TNoReflowTabBarUiLanguage = (rsulFrench, rsulEnglish);

    {
      Pair of localised text values used by the component.

      Fr contains the French text. En contains the English text.
    }
    TNoReflowTabBarLocalizedText = Record
        Fr: String;
        En: String;
    End;

Const
    {
      Reserved signal code meaning "no signal".
    }
    nrtSignalNone = 0;

    {
      Reserved built-in gray signal code.
    }
    nrtSignalGray = 1;

    {
      Reserved built-in green signal code.
    }
    nrtSignalGreen = 2;

    {
      Reserved built-in orange signal code.
    }
    nrtSignalOrange = 3;

    {
      Reserved built-in red signal code.
    }
    nrtSignalRed = 4;

    {
      Message used when a signal code is set to zero.
    }
    CMsgSignalCodeCannotBeZero: TNoReflowTabBarLocalizedText = (Fr: 'Le code du voyant ne peut pas être 0.'; En: 'Signal code cannot be 0.');

    {
      Message used when a signal name is empty.
    }
    CMsgSignalNameCannotBeEmpty: TNoReflowTabBarLocalizedText = (Fr: 'Le nom du voyant ne peut pas être vide.'; En: 'Signal name cannot be empty.');

    {
      Message used when a signal code already exists.
    }
    CMsgSignalCodeAlreadyExists: TNoReflowTabBarLocalizedText = (Fr: 'Le code de voyant %d existe déjà.'; En: 'Signal code %d already exists.');

    {
      Message used when a signal name already exists.
    }
    CMsgSignalNameAlreadyExists: TNoReflowTabBarLocalizedText = (Fr: 'Le nom de voyant %s existe déjà.'; En: 'Signal name %s already exists.');

    {
      Message used when no signal matches a requested code.
    }
    CMsgSignalCodeNotExist: TNoReflowTabBarLocalizedText = (Fr: 'Aucun voyant ne correspond au code %d.'; En: 'No indicator light corresponds to the code %d');

    {
      Message used when trying to use a reserved signal code.
    }
    CMsgSignalCodeReserved: TNoReflowTabBarLocalizedText = (Fr: 'Le code de voyant %d est réservé.'; En: 'Signal code %d is reserved.');

    {
      Message used when trying to modify a built-in signal code.
    }
    CMsgBuiltInSignalCodeReadOnly: TNoReflowTabBarLocalizedText = (Fr: 'Le code des voyants système ne peut pas être modifié.'; En: 'Built-in signal codes cannot be modified.');

    {
      Message used when trying to modify a built-in signal name.
    }
    CMsgBuiltInSignalNameReadOnly: TNoReflowTabBarLocalizedText = (Fr: 'Le nom des voyants système ne peut pas être modifié.'; En: 'Built-in signal names cannot be modified.');

    {
      Message used when trying to modify built-in signal colours.
    }
    CMsgBuiltInSignalColorsReadOnly: TNoReflowTabBarLocalizedText = (Fr: 'Les couleurs des voyants système ne peuvent pas être modifiées.';
        En: 'Built-in signal colors cannot be modified.');

Var
    {
      Global token returned by GDI+ initialisation.

      While this value remains 0, GDI+ is considered unavailable and rendering
      must fall back to classic GDI routines.
    }
    GGDIPlusToken: ULONG_PTR = 0;

    {
      Safety switch used to force classic GDI rendering.

      Even when GDI+ is correctly initialised, this flag can force the component
      to use the classic rendering path. It is useful for diagnosing visual
      issues, comparing GDI and GDI+, or working around an undesirable graphics
      behaviour.
    }
    GForceClassicGDI: Boolean = False;


//===============================================================================================================================
// Message and language helpers
//===============================================================================================================================

{
  Returns the primary language identifier from a Windows LANGID value.
}
Function PrimaryLangID(ALangID: LANGID): Word;

{
  Returns the UI language currently selected for localised component messages.
}
Function GetUiLanguage: TNoReflowTabBarUiLanguage;

{
  Returns the localised text matching the current UI language.
}
Function Msg(Const AText: TNoReflowTabBarLocalizedText): String;


//===============================================================================================================================
// GDI / GDI+ helpers
//===============================================================================================================================

{
  Returns True when GDI+ has been successfully initialised.
}
Function GDIPlusAvailable: Boolean;

{
  Returns True when the component should use the GDI+ rendering path.
}
Function UseGDIPlus: Boolean;

{
  Initialises GDI+ for the component library.
}
Procedure InitGDIPlus;

{
  Shuts down GDI+ when it has been initialised by the component library.
}
Procedure ShutdownGDIPlus;


//===============================================================================================================================
// Geometry and drawing helpers
//===============================================================================================================================

{
  Compares two rectangles in the canonical Top coordinate system and returns
  True when they belong to the same canonical line.
}
Function SameCanonicalLine(
    Const R1: TRect;
    Const R2: TRect): Boolean;

{
  Tests whether a point belongs to a polygon.
}
Function PointInPolygon(
    Const P: TPoint;
    Const Poly: TArray<TPoint>): Boolean;

{
  Converts an array of TPoint values to an array of GDI+ TGPPointF values.
}
Procedure ConvertPointsToGPPoints(
    Const ASrc: TArray<TPoint>;
    Out ADst: TArray<TGPPointF>);

{
  Converts a VCL TColor to an opaque GDI+ colour.
}
Function ColorToGDIPlusColor(AColor: TColor): TGPColor;

{
  Draws an antialiased border on a polygonal outline.
}
Procedure DrawAntiAliasedBorder(
    ACanvas: TCanvas;
    Const APoints: TArray<TPoint>;
    ABorderColor: TColor;
    AWidth: Single;
    AClosed: Boolean);

{
  Draws a filled ellipse with a border.
}
Procedure DrawAntiAliasedEllipse(
    ACanvas: TCanvas;
    Const ARect: TRect;
    AFillColor: TColor;
    ABorderColor: TColor);

{
  Prefills a polygon with a solid colour using GDI+.
}
Procedure FillSolidPathGDIPlus(
    ACanvas: TCanvas;
    Const APoints: TArray<TPoint>;
    AFillColor: TColor);

{
  Fills a polygon with a GDI+ gradient clipped to the polygon shape.
}
Procedure FillGradientInPath(
    ACanvas: TCanvas;
    Const R: TRect;
    Const APoints: TArray<TPoint>;
    ATopColor: TColor;
    ABottomColor: TColor;
    AHorizontal: Boolean);

{
  Adds a point to a list only when it differs from the previous point.
}
Procedure AddPointIfNeeded(
    Var APoints: TList<TPoint>;
    Const APt: TPoint);

{
  Adds a rounded corner between two polygon segments.
}
Procedure AddRoundedCorner(
    Var APoints: TList<TPoint>;
    Const AStart, ACorner, AEnd: TPoint;
    ARadius: Double);

{
  Normalises a signal fill ratio to the 0.0 .. 1.0 range.

  When ASignalMax is less than or equal to 0, the signal is treated as full.
}
Function NormalizeSignalFillPercent(ASignalValue, ASignalMax: Double): Double;


//===============================================================================================================================
// Colour helpers
//===============================================================================================================================

{
  Blends two colours using a percentage in the 0..100 range.
}
Function BlendColorPourcent(
    AColor1, AColor2: TColor;
    APercent: Integer): TColor;

{
  Classic GDI fallback used to draw a horizontal or vertical gradient.
}
Procedure GradientFillRectEx(
    ACanvas: TCanvas;
    Const R: TRect;
    ABottomColor, ATopColor: TColor;
    AHorizontal: Boolean);

{
  Clamps an integer value to the valid byte range, 0..255.
}
Function ClampByte(AValue: Integer): Byte;

{
  Computes an approximate luminance value for a colour.
}
Function ColorLuminance(AColor: TColor): Double;

{
  Computes a simple distance between two colours.
}
Function ColorDistance(AColor1, AColor2: TColor): Integer;

{
  Blends two colours using an amount in the 0..255 range.
}
Function BlendColorAmount(
    AColor1, AColor2: TColor;
    AAmount: Byte): TColor;

{
  Returns a darker version of a colour using channel blending.
}
Function MakeColorDarker(
    AColor: TColor;
    AAmount: Byte): TColor;

{
  Returns a darker version of a colour using luminance adjustment.
}
Function MakeColorLumaDarker(
    AColor: TColor;
    APercent: Integer): TColor;

{
  Returns a lighter version of a colour using channel blending.
}
Function MakeColorLighter(
    AColor: TColor;
    AAmount: Byte): TColor;

{
  Returns a lighter version of a colour using luminance adjustment.
}
Function MakeColorLumaLighter(
    AColor: TColor;
    APercent: Integer): TColor;

{
  Returns the best binary text colour, either white or black, for a background.
}
Function BestTextColorForBackground(ABackground: TColor): TColor;

{
  Ensures that a text colour has enough luminance contrast with its background.

  When the contrast is too low, the function returns a better black or white
  fallback.
}
Function EnsureTextContrastByLuminance(
    ATextColor, ABackgroundColor: TColor;
    AMinLuminanceDiff: Double): TColor;

{
  Draws a signal indicator.

  APercent controls the fill level. AStartAngleDeg controls the start angle used
  for partial signal fill rendering.
}
Procedure DrawSignalIndicator(
    ACanvas: TCanvas;
    Const ARect: TRect;
    AFillColor: TColor;
    ABorderColor: TColor;
    APercent: Double;
    AStartAngleDeg: Double);

Implementation

//===============================================================================================================================
//Helpers Messages et langue
//===============================================================================================================================

Function PrimaryLangID(ALangID: LANGID): Word;
Begin
    Result := ALangID And $3FF;
End;

Function GetUiLanguage: TNoReflowTabBarUiLanguage;
Var
    LLang: LANGID;
Begin
    LLang := GetThreadUILanguage;
    If LLang = 0 Then
        LLang := GetUserDefaultUILanguage;

    If PrimaryLangID(LLang) = LANG_FRENCH Then
        Result := rsulFrench
    Else
        Result := rsulEnglish;
End;

Function Msg(Const AText: TNoReflowTabBarLocalizedText): String;
Begin
    If GetUiLanguage = rsulFrench Then
        Result := AText.Fr
    Else
        Result := AText.En;
End;

//===============================================================================================================================
//Helpers GDI / GDI+
//===============================================================================================================================

//Indique simplement si GDI+ a été initialisé avec succès.
//
//Cette fonction ne décide pas encore si le composant DOIT utiliser GDI+ ;
//elle répond uniquement à la question technique :
//"le moteur GDI+ est-il disponible ?"
Function GDIPlusAvailable: Boolean;
Begin
    Result := GGDIPlusToken <> 0;
End;

//Indique si le composant doit réellement passer par GDI+.
//
//On ne se contente pas de tester la disponibilité technique.
//On tient aussi compte du flag GForceClassicGDI qui peut imposer le
//rendu GDI classique, même si GDI+ fonctionne.
Function UseGDIPlus: Boolean;
Begin
    Result := GDIPlusAvailable And (Not GForceClassicGDI);
End;

//Initialise GDI+ au chargement de l’unité.
//
//Le token est stocké dans une variable globale pour être réutilisé par
//toutes les routines de dessin de cette unité.
//
//Remarques :
//- si l’initialisation a déjà été faite, on ne la refait pas ;
//- si GdiplusStartup échoue, on force GGDIPlusToken à 0 pour signaler
//proprement l’indisponibilité de GDI+.
Procedure InitGDIPlus;
Var
    StartupInput: TGDIPlusStartupInput;
Begin
    //Évite une double initialisation.
    If GGDIPlusToken <> 0 Then
        Exit;

    FillChar(
        StartupInput,
        SizeOf(StartupInput),
        0);
    StartupInput.GdiplusVersion := 1;

    If GdiplusStartup(GGDIPlusToken, @StartupInput, Nil) <> Ok Then
        GGDIPlusToken := 0;
End;

//Libère proprement GDI+ à la finalisation de l’unité.
//
//Cette routine ne fait rien si GDI+ n’avait jamais été initialisé.
Procedure ShutdownGDIPlus;
Begin
    If GGDIPlusToken <> 0 Then Begin
        GdiplusShutdown(GGDIPlusToken);
        GGDIPlusToken := 0;
    End;
End;

//===============================================================================================================================
//Helpers géométriques
//===============================================================================================================================

Function SameCanonicalLine(
    Const R1: TRect;
    Const R2: TRect): Boolean;
Begin
    //------------------------------------------------------------------
    //Compare deux rectangles dans le repère canonique TOP.
    //
    //Deux items sont considérés sur la même ligne si leurs centres
    //verticaux coïncident. Cela suffit ici car le layout produit des
    //lignes bien alignées.
    //------------------------------------------------------------------
    Result := ((R1.Top + R1.Bottom) Div 2) = ((R2.Top + R2.Bottom) Div 2);
End;

//Teste si un point appartient à un polygone.
//
//Cette routine est utilisée pour le hit-test souris sur la forme réelle
//des items. On ne teste donc pas un simple rectangle englobant, mais
//bien le contour polygonal calculé pour le rendu.
//
//Algorithme utilisé : ray casting.
//L’idée est de lancer un rayon horizontal et de compter le nombre
//d’intersections avec les arêtes du polygone.
Function PointInPolygon(
    Const P: TPoint;
    Const Poly: TArray<TPoint>): Boolean;
Var
    I:          Integer;
    J:          Integer;
    Denom:      Double;
    XIntersect: Double;
Begin
    Result := False;

    //Un polygone à moins de 3 points n’a pas de surface exploitable.
    If Length(Poly) < 3 Then
        Exit;

    J := High(Poly);
    For I := 0 To High(Poly) Do Begin
        //On ne traite que les arêtes qui croisent horizontalement le Y du point.
        If ((Poly[I].Y > P.Y) <> (Poly[J].Y > P.Y)) Then Begin
            Denom := Poly[J].Y - Poly[I].Y;

            //Protection contre une division quasi nulle.
            If Abs(Denom) > 0.0 Then Begin
                XIntersect := (Poly[J].X - Poly[I].X) * (P.Y - Poly[I].Y) / Denom + Poly[I].X;

                //Chaque intersection bascule l’état intérieur / extérieur.
                If P.X < XIntersect Then
                    Result := Not Result;
            End;
        End;

        J := I;
    End;
End;

//Convertit un tableau de TPoint vers un tableau de TGPPointF.
//
//GDI+ travaille plus naturellement avec des coordonnées flottantes.
//Le décalage de +0.5 permet souvent d’obtenir un tracé plus net,
//notamment sur les bordures fines antialiasées.
Procedure ConvertPointsToGPPoints(
    Const ASrc: TArray<TPoint>;
    Out ADst: TArray<TGPPointF>);
Var
    I: Integer;
Begin
    SetLength(
        ADst,
        Length(ASrc));

    For I := 0 To High(ASrc) Do Begin
        ADst[I].X := ASrc[I].X + 0.5;
        ADst[I].Y := ASrc[I].Y + 0.5;
    End;
End;

//Convertit une TColor VCL en TGPColor GDI+ opaque.
//
//On force ici un alpha à 255, donc aucune transparence.
//La conversion passe d’abord par ColorToRGB afin de figer la couleur réelle
//avant extraction des composantes R, G et B.
Function ColorToGDIPlusColor(AColor: TColor): TGPColor;
Var
    C: COLORREF;
Begin
    C := ColorToRGB(AColor);
    Result := MakeColor(
        255,
        GetRValue(C),
        GetGValue(C),
        GetBValue(C));
End;

//Dessine une bordure antialiasée sur un contour polygonal.
//
//AClosed = True
//-> le contour est fermé, donc on dessine un polygone complet.
//
//AClosed = False
//-> le contour reste ouvert, donc on dessine une polyline.
//C’est notamment utile pour ne pas tracer l’arête de contact de
//l’item sélectionné.
//
//Remarque importante :
//cette routine ne fait rien si GDI+ n’est pas utilisé.
//Le fallback GDI classique est géré plus haut dans la logique de rendu.
Procedure DrawAntiAliasedBorder(
    ACanvas: TCanvas;
    Const APoints: TArray<TPoint>;
    ABorderColor: TColor;
    AWidth: Single;
    AClosed: Boolean);
Var
    Graphics: TGPGraphics;
    Pen:      TGPPen;
    GPPoints: TArray<TGPPointF>;
Begin
    //Il faut au moins deux points pour tracer quelque chose.
    If Length(APoints) < 2 Then
        Exit;

    If Not UseGDIPlus Then
        Exit;

    ConvertPointsToGPPoints(
        APoints,
        GPPoints);

    Graphics := TGPGraphics.Create(ACanvas.Handle);
    Try
        //Qualité max pour les contours obliques et arrondis.
        Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
        Graphics.SetPixelOffsetMode(PixelOffsetModeHalf);
        Graphics.SetCompositingQuality(CompositingQualityHighQuality);

        Pen := TGPPen.Create(
            ColorToGDIPlusColor(ABorderColor),
            AWidth);
        Try
            //Les jonctions arrondies évitent les cassures visuelles
            //sur les coins reconstruits par plusieurs segments.
            Pen.SetLineJoin(LineJoinRound);
            Pen.SetStartCap(LineCapRound);
            Pen.SetEndCap(LineCapRound);

            If AClosed Then
                Graphics.DrawPolygon(
                    Pen,
                    PGPPointF(@GPPoints[0]),
                    Length(GPPoints))
            Else
                Graphics.DrawLines(
                    Pen,
                    PGPPointF(@GPPoints[0]),
                    Length(GPPoints));
        Finally Pen.Free;
        End;
    Finally Graphics.Free;
    End;
End;

//Dessine une ellipse remplie avec sa bordure.
//
//Cette routine sert principalement au voyant coloré ("feu") affiché
//dans certains items.
//
//Comportement :
//- si GDI+ est actif, on dessine en antialiasé ;
//- sinon on utilise la primitive Ellipse du canvas.
Procedure DrawAntiAliasedEllipse(
    ACanvas: TCanvas;
    Const ARect: TRect;
    AFillColor: TColor;
    ABorderColor: TColor);
Var
    Graphics: TGPGraphics;
    Brush:    TGPSolidBrush;
    Pen:      TGPPen;
    X:        Single;
    Y:        Single;
    W:        Single;
    H:        Single;
Begin
    //Rien à dessiner si le rectangle est vide.
    If IsRectEmpty(ARect) Then
        Exit;

    //Fallback GDI classique.
    If Not UseGDIPlus Then Begin
        ACanvas.Brush.Style := bsSolid;
        ACanvas.Brush.Color := AFillColor;
        ACanvas.Pen.Color := ABorderColor;
        ACanvas.Ellipse(ARect);
        Exit;
    End;

    //Ajustement demi-pixel pour un rendu GDI+ plus propre.
    X := ARect.Left + 0.5;
    Y := ARect.Top + 0.5;
    W := ARect.Right - ARect.Left - 1.0;
    H := ARect.Bottom - ARect.Top - 1.0;

    If (W <= 0) Or (H <= 0) Then
        Exit;

    Graphics := TGPGraphics.Create(ACanvas.Handle);
    Try
        Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
        Graphics.SetPixelOffsetMode(PixelOffsetModeHalf);
        Graphics.SetCompositingQuality(CompositingQualityHighQuality);

        //Remplissage intérieur du voyant.
        Brush := TGPSolidBrush.Create(ColorToGDIPlusColor(AFillColor));
        Try Graphics.FillEllipse(
                Brush,
                X,
                Y,
                W,
                H);
        Finally Brush.Free;
        End;

        //Contour du voyant.
        Pen := TGPPen.Create(
            ColorToGDIPlusColor(ABorderColor),
            1.0);
        Try
            Pen.SetAlignment(PenAlignmentCenter);
            Graphics.DrawEllipse(
                Pen,
                X,
                Y,
                W,
                H);
        Finally Pen.Free;
        End;
    Finally Graphics.Free;
    End;
End;

//Pré-remplit un polygone avec une couleur unie.
//
//Cette étape est utilisée avant l’application du gradient.
//En pratique, cela aide à éviter de petits jours visuels sur le bord
//de certaines formes, notamment avec antialiasing et contours obliques.
//
//La routine ne remplace pas le gradient ; elle prépare simplement une base
//pleine dans la forme exacte de l’item.
Procedure FillSolidPathGDIPlus(
    ACanvas: TCanvas;
    Const APoints: TArray<TPoint>;
    AFillColor: TColor);
Var
    Graphics: TGPGraphics;
    Path:     TGPGraphicsPath;
    Brush:    TGPSolidBrush;
    Pen:      TGPPen;
    GPPoints: TArray<TGPPointF>;
Begin
    //Il faut au moins 3 points pour former une surface.
    If Length(APoints) < 3 Then
        Exit;

    If Not UseGDIPlus Then
        Exit;

    ConvertPointsToGPPoints(
        APoints,
        GPPoints);

    Graphics := TGPGraphics.Create(ACanvas.Handle);
    Try
        Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
        Graphics.SetPixelOffsetMode(PixelOffsetModeHalf);
        Graphics.SetCompositingQuality(CompositingQualityHighQuality);

        Path := TGPGraphicsPath.Create;
        Try
            Path.AddPolygon(
                PGPPointF(@GPPoints[0]),
                Length(GPPoints));

            //Remplissage plein de la surface.
            Brush := TGPSolidBrush.Create(ColorToGDIPlusColor(AFillColor));
            Try Graphics.FillPath(
                    Brush,
                    Path);
            Finally Brush.Free;
            End;

            //Repassage léger sur le bord avec la même couleur pour
            //bien "fermer" visuellement la forme avant le gradient.
            Pen := TGPPen.Create(
                ColorToGDIPlusColor(AFillColor),
                1.25);
            Try
                Pen.SetLineJoin(LineJoinRound);
                Pen.SetStartCap(LineCapRound);
                Pen.SetEndCap(LineCapRound);
                Graphics.DrawPath(
                    Pen,
                    Path);
            Finally Pen.Free;
            End;
        Finally Path.Free;
        End;
    Finally Graphics.Free;
    End;
End;

//Remplit un polygone avec un gradient GDI+ réellement clipé à sa forme.
//
//Paramètres :
//- R : rectangle de référence utilisé pour orienter le gradient
//- APoints : contour réel de la forme à remplir
//- AHorizontal : True  -> gradient gauche -> droite
//False -> gradient haut -> bas
//
//Le clip suit ici le polygone réel, pas seulement un rectangle.
Procedure FillGradientInPath(
    ACanvas: TCanvas;
    Const R: TRect;
    Const APoints: TArray<TPoint>;
    ATopColor: TColor;
    ABottomColor: TColor;
    AHorizontal: Boolean);
Var
    Graphics: TGPGraphics;
    Path:     TGPGraphicsPath;
    Brush:    TGPLinearGradientBrush;
    GPPoints: TArray<TGPPointF>;
    P1:       TGPPointF;
    P2:       TGPPointF;
Begin
    //Sans surface exploitable, aucun remplissage possible.
    If Length(APoints) < 3 Then
        Exit;

    If Not UseGDIPlus Then
        Exit;

    ConvertPointsToGPPoints(
        APoints,
        GPPoints);

    Graphics := TGPGraphics.Create(ACanvas.Handle);
    Try
        Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
        Graphics.SetPixelOffsetMode(PixelOffsetModeHalf);
        Graphics.SetCompositingQuality(CompositingQualityHighQuality);

        Path := TGPGraphicsPath.Create;
        Try
            Path.AddPolygon(
                PGPPointF(@GPPoints[0]),
                Length(GPPoints));

            //Détermine l’axe du gradient dans le rectangle de référence.
            If AHorizontal Then Begin
                P1.X := R.Left;
                P1.Y := R.Top;
                P2.X := R.Right;
                P2.Y := R.Top;
            End Else Begin
                P1.X := R.Left;
                P1.Y := R.Top;
                P2.X := R.Left;
                P2.Y := R.Bottom;
            End;

            Brush := TGPLinearGradientBrush.Create(
                P1,
                P2,
                ColorToGDIPlusColor(ATopColor),
                ColorToGDIPlusColor(ABottomColor));
            Try Graphics.FillPath(
                    Brush,
                    Path);
            Finally Brush.Free;
            End;
        Finally Path.Free;
        End;
    Finally Graphics.Free;
    End;
End;

//Ajoute un point dans une liste uniquement s’il diffère du précédent.
//
//Cette petite routine évite de produire des points dupliqués
//dans les polygones générés. Cela simplifie ensuite :
//- le dessin,
//- les arrondis,
//- le hit-test.
Procedure AddPointIfNeeded(
    Var APoints: TList<TPoint>;
    Const APt: TPoint);
Begin
    If (APoints.Count = 0) Or (APoints.Last.X <> APt.X) Or (APoints.Last.Y <> APt.Y) Then
        APoints.Add(APt);
End;

//Ajoute un coin arrondi entre deux segments.
//
//Le coin géométrique est défini par :
//- AStart  : point du segment entrant
//- ACorner : sommet théorique du coin
//- AEnd    : point du segment sortant
//
//Le rayon demandé est ARadius.
//
//Implémentation :
//on calcule deux points d’entrée/sortie (P1/P2) sur les segments,
//puis on approxime l’arrondi par une petite courbe quadratique discrétisée
//en plusieurs segments.
//
//Ce n’est donc pas un arc mathématique parfait, mais une approximation
//suffisamment fine pour le rendu du composant.
Procedure AddRoundedCorner(
    Var APoints: TList<TPoint>;
    Const AStart, ACorner, AEnd: TPoint;
    ARadius: Double);
Var
    P1:    TPoint;
    P2:    TPoint;
    I:     Integer;
    T:     Double;
    PX:    Double;
    PY:    Double;
    Steps: Integer;
    Len1:  Double;
    Len2:  Double;
Begin
    //Si le rayon est nul ou négatif, on garde simplement le coin brut.
    If ARadius <= 0.0 Then Begin
        AddPointIfNeeded(
            APoints,
            ACorner);
        Exit;
    End;

    //Longueurs des segments avant et après le coin.
    Len1 := Sqrt(Sqr(ACorner.X - AStart.X) + Sqr(ACorner.Y - AStart.Y));
    Len2 := Sqrt(Sqr(AEnd.X - ACorner.X) + Sqr(AEnd.Y - ACorner.Y));

    //Si un des segments est trop court, l’arrondi n’est pas exploitable.
    If (Len1 <= 0.001) Or (Len2 <= 0.001) Then Begin
        AddPointIfNeeded(
            APoints,
            ACorner);
        Exit;
    End;

    //Point d’entrée dans l’arrondi sur le premier segment.
    P1.X := Round(ACorner.X + (AStart.X - ACorner.X) * (ARadius / Len1));
    P1.Y := Round(ACorner.Y + (AStart.Y - ACorner.Y) * (ARadius / Len1));

    //Point de sortie de l’arrondi sur le second segment.
    P2.X := Round(ACorner.X + (AEnd.X - ACorner.X) * (ARadius / Len2));
    P2.Y := Round(ACorner.Y + (AEnd.Y - ACorner.Y) * (ARadius / Len2));

    //Sur des segments strictement horizontaux, on recale Y pour éviter
    //de petites dérives d’arrondi dues aux calculs flottants.
    If AStart.Y = ACorner.Y Then
        P1.Y := ACorner.Y;

    If AEnd.Y = ACorner.Y Then
        P2.Y := ACorner.Y;

    AddPointIfNeeded(
        APoints,
        P1);

    //Nombre de segments utilisés pour approximer la courbe.
    //8 donne en général un compromis correct entre finesse et simplicité.
    Steps := 8;
    For I := 1 To Steps Do Begin
        T := I / Steps;

        PX := (Sqr(1 - T) * P1.X) + (2 * (1 - T) * T * ACorner.X) + (Sqr(T) * P2.X);

        PY := (Sqr(1 - T) * P1.Y) + (2 * (1 - T) * T * ACorner.Y) + (Sqr(T) * P2.Y);

        AddPointIfNeeded(
            APoints,
            Point(Round(PX), Round(PY)));
    End;
End;

Function NormalizeSignalFillPercent(ASignalValue, ASignalMax: Double): Double;
Begin
    //-------------------------------------------------------------------------
    //Convertit un couple (SignalValue / SignalMax) en pourcentage 0..100.
    //
    //Règles retenues :
    //- SignalMax <= 0  -> 100 %
    //Cela signifie : mode plein classique
    //
    //- SignalValue <= 0 -> 0 %
    //- SignalValue >= SignalMax -> 100 %
    //- sinon interpolation linéaire
    //-------------------------------------------------------------------------
    If ASignalMax <= 0.0 Then Begin
        Result := 100.0;
        Exit;
    End;

    If ASignalValue <= 0.0 Then Begin
        Result := 0.0;
        Exit;
    End;

    If ASignalValue >= ASignalMax Then Begin
        Result := 100.0;
        Exit;
    End;

    Result := (ASignalValue / ASignalMax) * 100.0;
End;

//===============================================================================================================================
//Helpers couleur
//===============================================================================================================================

Function AdjustColorLuma(
    AColor: TColor;
    APercent: Integer): TColor;
Var
    LColor: COLORREF;
Begin
    //-------------------------------------------------------------------------
    //Ajuste la luminance d'une couleur en s'appuyant sur l'API Windows.
    //
    //APercent :
    //- valeur positive : éclaircit la couleur ;
    //- valeur négative : assombrit la couleur ;
    //- plage utile habituelle : -100..100.
    //
    //Avantage par rapport à un BlendColorPourcent vers blanc/noir :
    //la teinte d'origine est mieux conservée, ce qui évite souvent l'effet
    //"couleur grisée" sur les bleus issus des styles VCL.
    //-------------------------------------------------------------------------
    If APercent < -100 Then
        APercent := -100
    Else If APercent > 100 Then
        APercent := 100;

    LColor := ColorToRGB(AColor);

    Result := TColor(ColorAdjustLuma(LColor, APercent, True));
End;

Function MakeColorLumaLighter(
    AColor: TColor;
    APercent: Integer): TColor;
Begin
    Result := AdjustColorLuma(
        AColor,
        Abs(APercent));
End;

Function MakeColorLumaDarker(
    AColor: TColor;
    APercent: Integer): TColor;
Begin
    Result := AdjustColorLuma(
        AColor,
        -Abs(APercent));
End;

//Mélange deux couleurs selon un pourcentage simple 0..100.
//
//Interprétation :
//- 0   -> on obtient exactement AColor1
//- 100 -> on obtient exactement AColor2
//- 50  -> mélange à parts égales
//
//Cette routine est utilisée dans plusieurs contextes :
//- calculer une couleur intermédiaire dans un gradient GDI,
//- produire une couleur "de référence" au milieu d’un dégradé,
//- comparer visuellement deux états via une teinte moyenne.
Function BlendColorPourcent(
    AColor1, AColor2: TColor;
    APercent: Integer): TColor;
Var
    C1: Longint;
    C2: Longint;
    R1: Integer;
    G1: Integer;
    B1: Integer;
    R2: Integer;
    G2: Integer;
    B2: Integer;
    R:  Integer;
    G:  Integer;
    B:  Integer;
Begin
    //Petit raccourci utile : si les deux couleurs sont identiques,
    //aucun calcul n’est nécessaire.
    If AColor1 = AColor2 Then
        Exit(AColor1);

    //On convertit d’abord les TColor VCL en couleurs RGB explicites.
    C1 := ColorToRGB(AColor1);
    C2 := ColorToRGB(AColor2);

    R1 := GetRValue(C1);
    G1 := GetGValue(C1);
    B1 := GetBValue(C1);

    R2 := GetRValue(C2);
    G2 := GetGValue(C2);
    B2 := GetBValue(C2);

    //Interpolation linéaire composante par composante.
    R := R1 + ((R2 - R1) * APercent) Div 100;
    G := G1 + ((G2 - G1) * APercent) Div 100;
    B := B1 + ((B2 - B1) * APercent) Div 100;

    Result := RGB(
        R,
        G,
        B);
End;

//Fallback GDI pour gradient horizontal ou vertical.
//
//Cette routine n’est utilisée que lorsque GDI+ n’est pas disponible
//ou lorsqu’on a volontairement forcé le mode classique.
//
//Principe :
//on remplit le rectangle ligne par ligne ou colonne par colonne avec
//des couleurs interpolées manuellement.
//
//Ce n’est pas aussi sophistiqué que le gradient GDI+ clipé dans un path,
//mais cela permet de conserver un rendu cohérent sur tous les systèmes.
Procedure GradientFillRectEx(
    ACanvas: TCanvas;
    Const R: TRect;
    ABottomColor, ATopColor: TColor;
    AHorizontal: Boolean);
Var
    I: Integer;
    N: Integer;
    C: TColor;
Begin
    If AHorizontal Then Begin
        //Nombre de colonnes à peindre.
        N := R.Right - R.Left;
        If N <= 0 Then
            Exit;

        //On trace une ligne verticale par colonne.
        For I := 0 To N - 1 Do Begin
            C := BlendColorPourcent(
                ATopColor,
                ABottomColor,
                (I * 100) Div N);
            ACanvas.Pen.Color := C;
            ACanvas.MoveTo(
                R.Left + I,
                R.Top);
            ACanvas.LineTo(
                R.Left + I,
                R.Bottom);
        End;
    End Else Begin
        //Nombre de lignes à peindre.
        N := R.Bottom - R.Top;
        If N <= 0 Then
            Exit;

        //On trace une ligne horizontale par rangée.
        For I := 0 To N - 1 Do Begin
            C := BlendColorPourcent(
                ATopColor,
                ABottomColor,
                (I * 100) Div N);
            ACanvas.Pen.Color := C;
            ACanvas.MoveTo(
                R.Left,
                R.Top + I);
            ACanvas.LineTo(
                R.Right,
                R.Top + I);
        End;
    End;
End;

//Force une valeur entière dans l’intervalle valide d’un octet : 0..255.
//
//Cette routine sert surtout à sécuriser les calculs de mélange couleur.
//Même si les formules devraient rester dans des bornes raisonnables,
//ce clamp évite tout débordement ou valeur hors plage.
Function ClampByte(AValue: Integer): Byte;
Begin
    If AValue < 0 Then
        Result := 0
    Else If AValue > 255 Then
        Result := 255
    Else
        Result := AValue;
End;

//Calcule une luminance approximative d’une couleur.
//
//Il ne s’agit pas d’une mesure colorimétrique parfaite, mais d’une
//heuristique simple et efficace pour estimer si une couleur est
//globalement claire ou sombre.
//
//Cette information est utilisée pour ajuster les contrastes texte/fond
//et pour décider s’il faut éclaircir ou assombrir une couleur.
Function ColorLuminance(AColor: TColor): Double;
Var
    C: Longint;
    R: Integer;
    G: Integer;
    B: Integer;
Begin
    C := ColorToRGB(AColor);
    R := GetRValue(C);
    G := GetGValue(C);
    B := GetBValue(C);

    //Formule classique pondérée tenant compte du fait que
    //l’œil perçoit davantage le vert que le rouge,
    //et davantage le rouge que le bleu.
    Result := 0.299 * R + 0.587 * G + 0.114 * B;
End;

//Calcule une "distance" simple entre deux couleurs.
//
//Cette distance n’est pas un écart perceptuel parfait,
//mais une heuristique légère suffisante pour les besoins du composant.
//
//Plus le résultat est élevé, plus les deux couleurs sont considérées
//comme différentes visuellement.
Function ColorDistance(AColor1, AColor2: TColor): Integer;
Var
    C1: Longint;
    C2: Longint;
    R1: Integer;
    G1: Integer;
    B1: Integer;
    R2: Integer;
    G2: Integer;
    B2: Integer;
Begin
    C1 := ColorToRGB(AColor1);
    C2 := ColorToRGB(AColor2);

    R1 := GetRValue(C1);
    G1 := GetGValue(C1);
    B1 := GetBValue(C1);

    R2 := GetRValue(C2);
    G2 := GetGValue(C2);
    B2 := GetBValue(C2);

    Result := Abs(R1 - R2) + Abs(G1 - G2) + Abs(B1 - B2);
End;

//Mélange deux couleurs avec un poids exprimé sur 0..255.
//
//Interprétation :
//- 0   -> AColor1 pur
//- 255 -> AColor2 pur
//
//Cette version est pratique pour créer rapidement une couleur plus claire
//ou plus sombre, en mélangeant avec blanc ou noir.
Function BlendColorAmount(
    AColor1, AColor2: TColor;
    AAmount: Byte): TColor;
Var
    C1: Longint;
    C2: Longint;
    R:  Integer;
    G:  Integer;
    B:  Integer;
Begin
    C1 := ColorToRGB(AColor1);
    C2 := ColorToRGB(AColor2);

    R := (GetRValue(C1) * (255 - AAmount) + GetRValue(C2) * AAmount) Div 255;
    G := (GetGValue(C1) * (255 - AAmount) + GetGValue(C2) * AAmount) Div 255;
    B := (GetBValue(C1) * (255 - AAmount) + GetBValue(C2) * AAmount) Div 255;

    Result := RGB(
        ClampByte(R),
        ClampByte(G),
        ClampByte(B));
End;

//Retourne une version assombrie d’une couleur.
//
//Le principe est simplement de mélanger la couleur d’origine avec noir.
Function MakeColorDarker(
    AColor: TColor;
    AAmount: Byte): TColor;
Begin
    Result := BlendColorAmount(
        AColor,
        clBlack,
        AAmount);
End;

//Retourne une version éclaircie d’une couleur.
//
//Le principe est simplement de mélanger la couleur d’origine avec blanc.
Function MakeColorLighter(
    AColor: TColor;
    AAmount: Byte): TColor;
Begin
    Result := BlendColorAmount(
        AColor,
        clWhite,
        AAmount);
End;

//Retourne la meilleure couleur de texte binaire : blanc ou noir.
//
//Cette routine est volontairement simple.
//Elle ne cherche pas la "meilleure" couleur absolue, mais choisit
//entre deux options robustes pour garder une bonne lisibilité.
//
//Elle est utilisée comme solution de repli lorsque la couleur de texte
//prévue par le style n’offre pas un contraste suffisant.
Function BestTextColorForBackground(ABackground: TColor): TColor;
Var
    DistWhite: Integer;
    DistBlack: Integer;
Begin
    DistWhite := ColorDistance(
        ABackground,
        clWhite);
    DistBlack := ColorDistance(
        ABackground,
        clBlack);

    If DistWhite > DistBlack Then
        Result := clWhite
    Else
        Result := clBlack;
End;

//Vérifie si une couleur de texte contraste suffisamment avec son fond.
//
//Si l’écart de luminance est jugé trop faible, on remplace la couleur
//de texte par noir ou blanc selon ce qui sera le plus lisible.
//
//Cela sert surtout pour les palettes dérivées du style VCL, car certains
//styles peuvent produire des combinaisons jolies globalement mais trop
//peu contrastées dans le cas précis d’un item sélectionné.
Function EnsureTextContrastByLuminance(
    ATextColor, ABackgroundColor: TColor;
    AMinLuminanceDiff: Double): TColor;
Begin
    Result := ATextColor;

    If Abs(ColorLuminance(Result) - ColorLuminance(ABackgroundColor)) < AMinLuminanceDiff Then
        Result := BestTextColorForBackground(ABackgroundColor);
End;

//Dessine un voyant
Procedure DrawSignalIndicator(
    ACanvas: TCanvas;
    Const ARect: TRect;
    AFillColor: TColor;
    ABorderColor: TColor;
    APercent: Double;
    AStartAngleDeg: Double);
Var
    LPercent:  Double;
    BackColor: TColor;
    CX:        Integer;
    CY:        Integer;
    Radius:    Integer;
    AngleRad:  Double;
    XStart:    Integer;
    YStart:    Integer;
    XEnd:      Integer;
    YEnd:      Integer;
Begin
    //-------------------------------------------------------------------------
    //Dessine un voyant circulaire avec niveau de remplissage.
    //
    //Comportement visuel retenu :
    //- fond du disque en version éclaircie de la couleur principale
    //- portion remplie en couleur pleine
    //- bordure du disque en couleur de contour
    //
    //Interprétation de APercent :
    //- <= 0   : disque vide
    //- >= 100 : disque plein
    //- sinon  : dessin d’un secteur ("camembert")
    //
    //Le remplissage démarre à 12h et progresse dans le sens horaire.
    //-------------------------------------------------------------------------

    If IsRectEmpty(ARect) Then
        Exit;

    //Clamp défensif du pourcentage entre 0 et 100.
    LPercent := APercent;
    If LPercent < 0.0 Then
        LPercent := 0.0;
    If LPercent > 100.0 Then
        LPercent := 100.0;

    //Couleur de fond du voyant :
    //on prend une version plus claire de la couleur principale
    //pour que la portion remplie se détache bien.
    BackColor := MakeColorLighter(
        AFillColor,
        180);

    //1) Fond complet du disque.
    //
    //Ce fond représente la capacité totale du voyant.
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := BackColor;
    ACanvas.Pen.Color := ABorderColor;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Ellipse(ARect);

    //2) Si rien n'est rempli, on s'arrête après le fond + bordure.
    If LPercent <= 0.0 Then
        Exit;

    //3) Si le remplissage est total, on dessine directement un disque plein.
    If LPercent >= 100.0 Then Begin
        ACanvas.Brush.Style := bsSolid;
        ACanvas.Brush.Color := AFillColor;
        ACanvas.Pen.Color := ABorderColor;
        ACanvas.Pen.Style := psSolid;
        ACanvas.Ellipse(ARect);
        Exit;
    End;

    //4) Cas intermédiaire : dessin en camembert.
    //
    //Le centre et le rayon servent à calculer le point final
    //du secteur à partir du pourcentage.
    CX := (ARect.Left + ARect.Right) Div 2;
    CY := (ARect.Top + ARect.Bottom) Div 2;
    Radius := Min(ARect.Width, ARect.Height) Div 2;

    //Point de départ selon l'angle demandé.
    AngleRad := AStartAngleDeg * Pi / 180.0;
    XStart := CX + Round(Cos(AngleRad) * Radius);
    YStart := CY + Round(Sin(AngleRad) * Radius);

    //Angle final :
    //on part de l'angle de départ puis on progresse
    //dans le sens horaire selon le pourcentage.
    AngleRad := (AStartAngleDeg + (LPercent / 100.0) * 360.0) * Pi / 180.0;

    XEnd := CX + Round(Cos(AngleRad) * Radius);
    YEnd := CY + Round(Sin(AngleRad) * Radius);

    //Dessin du secteur rempli.
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := AFillColor;

    //On évite de tracer le contour interne du secteur,
    //la bordure globale du disque sera redessinée ensuite.
    ACanvas.Pen.Style := psClear;

    //---------------------------------------------------------------------
    //Attention au sens de dessin de GDI Pie.
    //
    //Les points XStart/YStart et XEnd/YEnd sont calculés pour exprimer une
    //progression horaire depuis AStartAngleDeg. Or GDI Pie dessine l'arc dans
    //le sens inverse de celui attendu ici, ce qui remplit visuellement le
    //complément.
    //
    //Exemple sans inversion :
    //- 75 % demandé donne 25 % rempli.
    //
    //On inverse donc les points transmis à Pie pour que APercent représente
    //bien la portion pleine :
    //- 0   % = disque vide ;
    //- 25  % = un quart plein ;
    //- 75  % = trois quarts pleins ;
    //- 100 % = disque plein.
    //---------------------------------------------------------------------
    ACanvas.Pie(
        ARect.Left,
        ARect.Top,
        ARect.Right,
        ARect.Bottom,
        XEnd,
        YEnd,
        XStart,
        YStart);

    //5) Repassage final de la bordure externe complète du disque.
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Color := ABorderColor;
    ACanvas.Ellipse(ARect);
End;

End.

