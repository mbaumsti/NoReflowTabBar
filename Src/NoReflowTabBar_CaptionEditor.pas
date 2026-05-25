Unit NoReflowTabBar_CaptionEditor;

{
  NoReflowTabBar_CaptionEditor.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Inline caption editor abstraction used by NoReflowTabBar.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Purpose of this unit:
  - define the narrow contract used by NoReflowTabBar to edit item captions;
  - keep NoReflowTabBar_EditSupport independent from a concrete editor class;
  - provide the default implementation based on the standard VCL TEdit;
  - expose a small global factory hook for optional editor packages;
  - prepare future optional editor implementations, especially one based on
    TRotatedEdit, without introducing a mandatory dependency on VclRotatedEdit.

  Important design rule:
  - this unit belongs to the NoReflowTabBar runtime package;
  - it must not reference TRotatedEdit or any optional package;
  - optional packages may implement INoReflowTabBarCaptionEditor later.
}

Interface

Uses
    System.Classes,
    System.Types,
    System.Math,
    Vcl.Controls,
    Vcl.Forms,
    Vcl.StdCtrls,
    Vcl.Graphics,
    Vcl.Themes,
    NoReflowTabBar_CommonTypes;

Type
    {
      Explicit geometry passed by NoReflowTabBar to an inline caption editor.

      This record intentionally avoids exposing a raw TRect as the main
      contract. A rectangle can be ambiguous once text orientation enters the
      picture: it may represent a physical projected area, a logical layout
      area, or a GDI TextOut reference area.

      The editor receives instead the information it actually needs:
      - TextCenter:      center of the text reference area in host coordinates;
      - TextLength:      useful text length in the text flow direction;
      - TextThickness:   useful text thickness perpendicular to the flow;
      - TextOrientation: effective rendered orientation of the edited caption.

      Each concrete editor decides how to map this neutral geometry to its own
      control model:
      - TEdit builds a horizontal VCL edit box centered on TextCenter;
      - TRotatedEdit maps TextLength/TextThickness to its logical geometry and
        then centers its projected control around TextCenter.
    }
    TNoReflowTabBarCaptionEditorGeometry = Record
        TextCenter:      TPoint;
        TextLength:      Integer;
        TextThickness:   Integer;
        TextOrientation: TNoReflowTabBarTextOrientation;
    End;

    {
      Minimal interface implemented by an inline caption editor.

      The TabBar uses this interface instead of manipulating TEdit directly.
      The exposed surface is intentionally small: only the operations required
      by the edit lifecycle are present. This prevents the core component from
      depending on implementation details of the concrete editor control.
    }
    INoReflowTabBarCaptionEditor = Interface
        ['{B59DEFD1-7692-4B5D-B6F4-62A3FEC93B6A}']

        {
          Returns the real VCL control used as editor.

          The returned control is used by the edit support layer for parenting,
          positioning, visibility, focus and z-order operations.
        }
        Function GetEditorControl: TWinControl;

        {
          Returns the current editor text.
        }
        Function GetEditorText: String;

        {
          Replaces the current editor text.
        }
        Procedure SetEditorText(Const AValue: String);

        {
          Selects all editable text, when supported by the concrete control.
        }
        Procedure SelectAllEditorText;

        {
          Connects the events required by the TabBar edit lifecycle.
        }
        Procedure AssignEditorEvents(
            AOnExit: TNotifyEvent;
            AOnKeyDown: TKeyEvent;
            AOnKeyPress: TKeyPressEvent);

        {
          Clears the events previously assigned by AssignEditorEvents.
        }
        Procedure ClearEditorEvents;

        {
          Applies the neutral editor settings shared by all editor types.
        }
        Procedure ApplyEditorBaseSettings(
            AParentFont: Boolean;
            AParentColor: Boolean;
            AStyleElements: TStyleElements;
            ATabStop: Boolean);
        {
          Applies the text orientation selected by the TabBar for the edited item.

          The default TEdit implementation intentionally ignores this value
          because a standard edit control cannot rotate its text. Optional
          editors, such as the VclRotatedEdit adapter, can translate the
          direction into their own angle/orientation model.
        }
        Procedure ApplyEditorTextOrientation(
            ATextOrientation: TNoReflowTabBarTextOrientation);

        {
          Applies the explicit text geometry calculated by NoReflowTabBar.

          The editor receives a center point, a logical length, a logical
          thickness and the effective text orientation. It must then convert
          this neutral geometry to its own positioning model.
        }
        Procedure ApplyEditorTextGeometry(
            Const AGeometry: TNoReflowTabBarCaptionEditorGeometry);

        {
          Replaces the editor font with the specified font.
        }
        Procedure AssignEditorFont(AFont: TFont);

        {
          Adds the specified style flags to the current editor font.
        }
        Procedure AddEditorFontStyle(AStyle: TFontStyles);

        {
          Applies VCL style participation flags to the concrete editor.
        }
        Procedure SetEditorStyleElements(AValue: TStyleElements);

        {
          Applies explicit background and text colors to the editor.
        }
        Procedure SetEditorColors(
            ABackgroundColor: TColor;
            ATextColor: TColor);
    End;

    {
      Factory used to create the inline caption editor.

      The default factory creates TNoReflowTabBarStandardCaptionEdit. Optional
      packages may register another factory, for example one returning an
      adapter based on TRotatedEdit.

      The factory remains in the runtime package because the editor is used at
      runtime too, not only inside the Delphi IDE.
    }
    TNoReflowTabBarCaptionEditorFactory = Function(
        AOwner: TComponent): INoReflowTabBarCaptionEditor;

    {
      Default inline caption editor based on the standard VCL TEdit.

      This is the historical editor used by NoReflowTabBar. It is now wrapped
      behind INoReflowTabBarCaptionEditor so that the rest of the component can
      be validated unchanged before an optional TRotatedEdit adapter is added.
    }
    TNoReflowTabBarStandardCaptionEdit = Class(TEdit, INoReflowTabBarCaptionEditor)
    protected
        Function GetEditorControl: TWinControl;
        Function GetEditorText: String;
        Procedure SetEditorText(Const AValue: String);
        Procedure SelectAllEditorText;
        Procedure AssignEditorEvents(
            AOnExit: TNotifyEvent;
            AOnKeyDown: TKeyEvent;
            AOnKeyPress: TKeyPressEvent);
        Procedure ClearEditorEvents;
        Procedure ApplyEditorBaseSettings(
            AParentFont: Boolean;
            AParentColor: Boolean;
            AStyleElements: TStyleElements;
            ATabStop: Boolean);
        Procedure ApplyEditorTextOrientation(
            ATextOrientation: TNoReflowTabBarTextOrientation);
        Procedure ApplyEditorTextGeometry(
            Const AGeometry: TNoReflowTabBarCaptionEditorGeometry);
        Procedure AssignEditorFont(AFont: TFont);
        Procedure AddEditorFontStyle(AStyle: TFontStyles);
        Procedure SetEditorStyleElements(AValue: TStyleElements);
        Procedure SetEditorColors(
            ABackgroundColor: TColor;
            ATextColor: TColor);
    public
        Constructor Create(AOwner: TComponent); override;
    End;

{
  Registers the global editor factory used by NoReflowTabBar.

  Passing Nil clears the current optional factory and restores the standard
  TEdit-based editor. Only one optional factory is supported deliberately: this
  keeps the rule deterministic and avoids priority/order problems between
  packages.
}
Procedure RegisterNoReflowTabBarCaptionEditorFactory(
    AFactory: TNoReflowTabBarCaptionEditorFactory);

{
  Removes the factory only if it is still the specified one.

  This makes finalization code safe when several packages are loaded/unloaded,
  even though the public rule remains that only one optional factory should be
  active at a time.
}
Procedure UnregisterNoReflowTabBarCaptionEditorFactory(
    AFactory: TNoReflowTabBarCaptionEditorFactory);

{
  Creates the caption editor used by the TabBar.

  If an optional package registered a factory, that factory is used. Otherwise
  the historical TEdit-based editor is created. If an optional factory returns
  Nil, the standard editor is used as a safety fallback.
}
Function CreateNoReflowTabBarCaptionEditor(
    AOwner: TComponent): INoReflowTabBarCaptionEditor;

Implementation

Var
    GNoReflowTabBarCaptionEditorFactory: TNoReflowTabBarCaptionEditorFactory;

//===============================================================================================================================
//Global editor factory
//===============================================================================================================================

Procedure RegisterNoReflowTabBarCaptionEditorFactory(
    AFactory: TNoReflowTabBarCaptionEditorFactory);
Begin
    //-------------------------------------------------------------------------
    //A Nil factory intentionally restores the built-in editor.
    //This is useful for tests and for package finalization paths.
    //-------------------------------------------------------------------------

    GNoReflowTabBarCaptionEditorFactory := AFactory;
End;

Procedure UnregisterNoReflowTabBarCaptionEditorFactory(
    AFactory: TNoReflowTabBarCaptionEditorFactory);
Begin
    //-------------------------------------------------------------------------
    //Only the package that registered the current factory may remove it.
    //The @ operator is used to compare procedural variables themselves instead
    //of accidentally calling them.
    //-------------------------------------------------------------------------

    If @GNoReflowTabBarCaptionEditorFactory = @AFactory Then
        GNoReflowTabBarCaptionEditorFactory := Nil;
End;

Function CreateNoReflowTabBarCaptionEditor(
    AOwner: TComponent): INoReflowTabBarCaptionEditor;
Begin
    //-------------------------------------------------------------------------
    //Factory resolution used by NoReflowTabBar_EditSupport.
    //
    //Default behavior must remain exactly the historical TEdit editor when no
    //optional package is installed.
    //-------------------------------------------------------------------------

    Result := Nil;

    If Assigned(GNoReflowTabBarCaptionEditorFactory) Then
        Result := GNoReflowTabBarCaptionEditorFactory(AOwner);

    If Result = Nil Then
        Result := TNoReflowTabBarStandardCaptionEdit.Create(AOwner);
End;

//===============================================================================================================================
//TNoReflowTabBarStandardCaptionEdit
//===============================================================================================================================

Constructor TNoReflowTabBarStandardCaptionEdit.Create(AOwner: TComponent);
Begin
    Inherited Create(AOwner);

    //-------------------------------------------------------------------------
    //Historical inline editor defaults.
    //
    //They are kept in the concrete editor implementation so that
    //NoReflowTabBar_EditSupport no longer has to know that the default editor
    //is a TEdit.
    //-------------------------------------------------------------------------

    BorderStyle := bsSingle;
    TabStop := False;
End;

Function TNoReflowTabBarStandardCaptionEdit.GetEditorControl: TWinControl;
Begin
    Result := Self;
End;

Function TNoReflowTabBarStandardCaptionEdit.GetEditorText: String;
Begin
    Result := Text;
End;

Procedure TNoReflowTabBarStandardCaptionEdit.SetEditorText(Const AValue: String);
Begin
    Text := AValue;
End;

Procedure TNoReflowTabBarStandardCaptionEdit.SelectAllEditorText;
Begin
    SelectAll;
End;

Procedure TNoReflowTabBarStandardCaptionEdit.AssignEditorEvents(
    AOnExit: TNotifyEvent;
    AOnKeyDown: TKeyEvent;
    AOnKeyPress: TKeyPressEvent);
Begin
    OnExit := AOnExit;
    OnKeyDown := AOnKeyDown;
    OnKeyPress := AOnKeyPress;
End;

Procedure TNoReflowTabBarStandardCaptionEdit.ClearEditorEvents;
Begin
    OnExit := Nil;
    OnKeyDown := Nil;
    OnKeyPress := Nil;
End;

Procedure TNoReflowTabBarStandardCaptionEdit.ApplyEditorBaseSettings(
    AParentFont: Boolean;
    AParentColor: Boolean;
    AStyleElements: TStyleElements;
    ATabStop: Boolean);
Begin
    ParentFont := AParentFont;
    ParentColor := AParentColor;
    StyleElements := AStyleElements;
    TabStop := ATabStop;
End;

Procedure TNoReflowTabBarStandardCaptionEdit.ApplyEditorTextOrientation(
    ATextOrientation: TNoReflowTabBarTextOrientation);
Begin
    //-------------------------------------------------------------------------
    //TEdit standard does not support rotated text.
    //
    //The method is intentionally empty so the default editor keeps the exact
    //historical behavior while optional editors can react to the same contract.
    //-------------------------------------------------------------------------
End;

Procedure TNoReflowTabBarStandardCaptionEdit.ApplyEditorTextGeometry(
    Const AGeometry: TNoReflowTabBarCaptionEditorGeometry);
Var
    LTextLength:    Integer;
    LTextThickness: Integer;
    LEditWidth:     Integer;
    LEditHeight:    Integer;
Begin
    //-------------------------------------------------------------------------
    //The standard VCL TEdit only edits horizontally.
    //
    //NoReflowTabBar no longer gives this editor a final TEdit rectangle. It
    //gives an explicit text geometry instead. The standard editor therefore
    //chooses a comfortable horizontal edit box centered on the text reference
    //area, regardless of the original text orientation.
    //-------------------------------------------------------------------------

    LTextLength := AGeometry.TextLength;
    LTextThickness := AGeometry.TextThickness;

    If LTextLength < 1 Then
        LTextLength := 1;

    If LTextThickness < 1 Then
        LTextThickness := 1;

    If AGeometry.TextOrientation = nrttoHorizontal Then Begin
        LEditWidth := Max(
            LTextLength + 8,
            90);

        LEditHeight := Max(
            LTextThickness + 6,
            22);
    End Else Begin
        LEditWidth := Max(
            LTextLength + 24,
            90);

        LEditHeight := Max(
            LTextThickness + 8,
            22);
    End;

    SetBounds(
        AGeometry.TextCenter.X - (LEditWidth Div 2),
        AGeometry.TextCenter.Y - (LEditHeight Div 2),
        LEditWidth,
        LEditHeight);
End;
Procedure TNoReflowTabBarStandardCaptionEdit.AssignEditorFont(AFont: TFont);
Begin
    If AFont = Nil Then
        Exit;

    Font.Assign(AFont);
End;

Procedure TNoReflowTabBarStandardCaptionEdit.AddEditorFontStyle(AStyle: TFontStyles);
Begin
    Font.Style := Font.Style + AStyle;
End;

Procedure TNoReflowTabBarStandardCaptionEdit.SetEditorStyleElements(AValue: TStyleElements);
Begin
    StyleElements := AValue;
End;

Procedure TNoReflowTabBarStandardCaptionEdit.SetEditorColors(
    ABackgroundColor: TColor;
    ATextColor: TColor);
Begin
    Color := ABackgroundColor;
    Font.Color := ATextColor;
End;

End.
