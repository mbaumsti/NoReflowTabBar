Unit NoReflowTabBar_HintSupport;

{
  NoReflowTabBar_HintSupport.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Hint management layer of the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Specialised hint management layer of the NoReflowTabBar component.

  This unit provides:
  - TNoReflowTabBarHintSupport, the intermediate layer responsible for manually
    displaying hints associated with virtual items.

  Role of this unit:
  - bypass the standard VCL hint mechanism for this custom-drawn control;
  - display a THintWindow controlled by the component;
  - keep the visible hint synchronised with the item currently under the mouse;
  - hide the hint cleanly when the mouse leaves, the hovered item changes, or the
    component is destroyed.

  Notes:
  - this unit does not modify the item model;
  - it relies on ResolveItemHint so hint text follows the same resolution logic
    as the rest of the component;
  - upper layers can call HideCustomHint without knowing the implementation
    details.
}

Interface

Uses
    Winapi.Windows,
    System.Types,
    System.Classes,
    System.sysutils,
    Vcl.Controls,
    Vcl.Graphics,
    Vcl.Forms,
    NoReflowTabBar_RenderSupport;

Type
    {
      Manual hint support layer for virtual bar items.

      TNoReflowTabBar draws its own items and performs polygon-based hit testing.
      A standard control hint is therefore not precise enough to represent the
      item currently under the mouse. This class owns a THintWindow and keeps it
      synchronised with the resolved item hint.
    }
    TNoReflowTabBarHintSupport = Class(TNoReflowTabBarRenderSupport)
    protected
        {
          Window used to display the currently active custom hint.
        }
        FHintWindow: THintWindow;

        {
          True when the custom hint window is currently visible.
        }
        FHintVisible: Boolean;

        {
          Absolute index of the item whose hint is currently displayed.
        }
        FHintItemIndex: Integer;

        {
          Last mouse position known by the hint support layer.
        }
        FLastMousePos: TPoint;

        Constructor Create(AOwner: TComponent); override;
        Destructor Destroy; override;

        {
          Handles the VCL CM_HINTSHOW message.

          The component provides its own item hint handling, so this message is
          used to suppress or redirect the standard VCL hint mechanism.
        }
        Procedure CMHintShow(Var Message: TCMHintShow); message CM_HINTSHOW;

        {
          Returns the resolved hint text for an item.
        }
        Function GetTabHintText(AIndex: Integer): String;

        {
          Returns the screen rectangle used to display the hint for an item.
        }
        Function GetTabHintScreenRect(AIndex: Integer): TRect;

        {
          Shows the custom hint for the specified item index.
        }
        Procedure ShowCustomHint(AIndex: Integer);

        {
          Updates the currently displayed custom hint according to the current
          mouse position and hovered item.
        }
        Procedure UpdateCustomHint;

        {
          Hides the current custom hint.

          This method is virtual so upper support layers can hide hints when
          another interaction takes priority, for example inline editing.
        }
        Procedure HideCustomHint; override;
    End;

Implementation


Constructor TNoReflowTabBarHintSupport.Create(AOwner: TComponent);
Begin
    Inherited Create(AOwner);

    //Initialisation de l'état interne de gestion des hints.
    FHintWindow := Nil;
    FHintVisible := False;
    FHintItemIndex := -1;
    FLastMousePos := Point(
        -1,
        -1);
End;

Destructor TNoReflowTabBarHintSupport.Destroy;
Begin
    //Libère d'abord le hint manuel éventuel.
    HideCustomHint;
    FreeAndNil(FHintWindow);
    Inherited Destroy;
End;

Procedure TNoReflowTabBarHintSupport.CMHintShow(Var Message: TCMHintShow);
Begin
    //-------------------------------------------------------------------------
    //Le composant neutralise le mécanisme standard des hints VCL
    //et gère lui-même l'affichage via THintWindow.
    //
    //On neutralise donc le mécanisme standard des hints VCL pour éviter
    //les interactions imprévisibles entre :
    //- le hot-tracking interne
    //- les changements d'item sous la souris
    //- les messages CM_HINTSHOW / CM_MOUSELEAVE
    //-------------------------------------------------------------------------

    Inherited;
    Message.Result := 1;
End;

Function TNoReflowTabBarHintSupport.GetTabHintText(AIndex: Integer): String;
Begin
    //-------------------------------------------------------------------------
    //Retourne le texte de hint à utiliser pour un item donné.
    //
    //Priorité :
    //- hint spécifique de l'item si renseigné ;
    //- sinon Caption.
    //
    //Si l'index est invalide, ou si l'item ne doit pas afficher de hint,
    //la fonction renvoie une chaîne vide.
    //-------------------------------------------------------------------------

    Result := '';

    If (AIndex < 0) Or (AIndex >= FItems.Count) Then
        Exit;

    If FItems[AIndex] = Nil Then
        Exit;

    If Not FItems[AIndex].ShowHint Then
        Exit;

    If Not ResolveItemHint(
        AIndex,
        FItems[AIndex],
        Result) Then
        Result := '';
End;

Function TNoReflowTabBarHintSupport.GetTabHintScreenRect(AIndex: Integer): TRect;
Begin
    //-------------------------------------------------------------------------
    //Retourne en coordonnées écran le rectangle de l'item.
    //
    //Ce rectangle sert de zone de référence pour positionner le hint
    //manuel à proximité de l'item survolé.
    //-------------------------------------------------------------------------

    SetRectEmpty(Result);

    EnsureRenderInfo;

    If (AIndex < 0) Or (AIndex >= Length(FRenderItems)) Then
        Exit;

    If Not FRenderItems[AIndex].Visible Then
        Exit;

    Result := FRenderItems[AIndex].Bounds;
    Result.TopLeft := ClientToScreen(Result.TopLeft);
    Result.BottomRight := ClientToScreen(Result.BottomRight);
End;

Procedure TNoReflowTabBarHintSupport.HideCustomHint;
Begin
    //-------------------------------------------------------------------------
    //Cache le hint manuel actuellement affiché.
    //-------------------------------------------------------------------------

    If FHintWindow <> Nil Then
        FHintWindow.ReleaseHandle;

    FHintVisible := False;
    FHintItemIndex := -1;
End;

Procedure TNoReflowTabBarHintSupport.ShowCustomHint(AIndex: Integer);
Var
    S:        String;
    TabRect:  TRect;
    HintRect: TRect;
    HintPos:  TPoint;
Begin
    //-------------------------------------------------------------------------
    //Affiche le hint manuel pour l'item demandé.
    //
    //Cette méthode remplace le mécanisme standard CM_HINTSHOW
    //devenu trop aléatoire pour un contrôle custom multi-zones.
    //-------------------------------------------------------------------------

    S := GetTabHintText(AIndex);
    If S = '' Then Begin
        HideCustomHint;
        Exit;
    End;

    If FHintWindow = Nil Then
        FHintWindow := THintWindow.Create(Self);

    TabRect := GetTabHintScreenRect(AIndex);
    If IsRectEmpty(TabRect) Then Begin
        HideCustomHint;
        Exit;
    End;

    //Position du hint :
    //on le place légèrement décalé sous la souris / sous l'item.
    HintPos := ClientToScreen(FLastMousePos);
    Inc(
        HintPos.X,
        12);
    Inc(
        HintPos.Y,
        20);

    HintRect := FHintWindow.CalcHintRect(
        Screen.Width Div 2,
        S,
        Nil);
    OffsetRect(
        HintRect,
        HintPos.X,
        HintPos.Y);

    FHintWindow.ActivateHint(
        HintRect,
        S);

    FHintVisible := True;
    FHintItemIndex := AIndex;
End;

Procedure TNoReflowTabBarHintSupport.UpdateCustomHint;
Var
    S: String;
Begin
    //-------------------------------------------------------------------------
    //Met à jour le hint manuel en fonction de l'item hot courant.
    //
    //Cas gérés :
    //- aucun item hot      -> on cache le hint
    //- item sans hint      -> on cache le hint
    //- nouvel item hot     -> on réaffiche le hint
    //- même item hot       -> on ne fait rien
    //-------------------------------------------------------------------------

    If Not ShowHint Then Begin
        HideCustomHint;
        Exit;
    End;

    If FHotItemIndex < 0 Then Begin
        HideCustomHint;
        Exit;
    End;

    S := GetTabHintText(FHotItemIndex);
    If S = '' Then Begin
        HideCustomHint;
        Exit;
    End;

    If FHintVisible And (FHintItemIndex = FHotItemIndex) Then
        Exit;

    ShowCustomHint(FHotItemIndex);
End;

End.

