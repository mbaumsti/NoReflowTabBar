Unit NoReflowTabBar_VclRotatedEditAdapter;

{
  NoReflowTabBar_VclRotatedEditAdapter.pas

  NoReflowTabBar optional package
  Copyright (c) 2026 Marc BAUMSTIMLER

  Optional adapter allowing NoReflowTabBar to use TRotatedEdit as its inline
  caption editor.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Purpose of this unit:
  - keep the main NoReflowTabBar runtime package independent from VclRotatedEdit;
  - register an optional editor factory when this package is loaded;
  - unregister that factory when this package is unloaded;
  - provide the bridge between INoReflowTabBarCaptionEditor and TRotatedEdit.

  Important package rule:
  - this unit must live only in the optional adapter package;
  - it must not be added to NoReflowTabBarR;
  - it requires both NoReflowTabBarR and VclRotatedEditR.

  Current scope:
  - this adapter registers a TRotatedEdit-backed inline editor;
  - it receives the effective TabBar text orientation and maps it to the
    TRotatedEdit angle/orientation model;
  - it receives the rendered text bounds from NoReflowTabBar and converts them
    to TRotatedEdit's public logical geometry model.
}

Interface

Uses
    System.Classes,
    System.Types,
    Vcl.Controls,
    Vcl.Forms,
    Vcl.Graphics,
    Vcl.Themes,
    Vcl.StdCtrls,
    VclRotatedEdit,
    VclRotatedEdit_Types,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_CaptionEditor;

Type
    {
      TRotatedEdit implementation of INoReflowTabBarCaptionEditor.

      The class derives directly from TRotatedEdit so the real editor control is
      also the interface implementor. This keeps ownership, focus handling,
      parenting and event dispatch identical to the standard TEdit adapter used
      by the main package.
    }
    TNoReflowTabBarRotatedCaptionEdit = Class(TRotatedEdit, INoReflowTabBarCaptionEditor)
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
        Constructor Create(AOwner: TComponent); Override;
    End;

Implementation

//===============================================================================================================================
//Factory
//===============================================================================================================================

Function CreateRotatedCaptionEditor(
    AOwner: TComponent): INoReflowTabBarCaptionEditor;
Begin
    //-------------------------------------------------------------------------
    //Factory registered by the optional package.
    //
    //NoReflowTabBar itself only knows the interface. The concrete dependency on
    //TRotatedEdit remains isolated in this adapter package.
    //-------------------------------------------------------------------------

    Result := TNoReflowTabBarRotatedCaptionEdit.Create(AOwner);
End;

//===============================================================================================================================
//TNoReflowTabBarRotatedCaptionEdit
//===============================================================================================================================

Constructor TNoReflowTabBarRotatedCaptionEdit.Create(AOwner: TComponent);
Begin
    Inherited Create(AOwner);

    //-------------------------------------------------------------------------
    //Keep the same baseline behavior as the standard TEdit adapter.
    //
    //TRotatedEdit is owner-drawn, but it exposes VCL-compatible Text, Font,
    //Color, BorderStyle, TabStop and keyboard events. That makes it suitable as
    //a first drop-in implementation behind INoReflowTabBarCaptionEditor.
    //-------------------------------------------------------------------------

    BorderStyle := bsSingle;
    TabStop := False;
End;

Function TNoReflowTabBarRotatedCaptionEdit.GetEditorControl: TWinControl;
Begin
    Result := Self;
End;

Function TNoReflowTabBarRotatedCaptionEdit.GetEditorText: String;
Begin
    Result := Text;
End;

Procedure TNoReflowTabBarRotatedCaptionEdit.SetEditorText(Const AValue: String);
Begin
    Text := AValue;
End;

Procedure TNoReflowTabBarRotatedCaptionEdit.SelectAllEditorText;
Begin
    SelectAll;
End;

Procedure TNoReflowTabBarRotatedCaptionEdit.AssignEditorEvents(
    AOnExit: TNotifyEvent;
    AOnKeyDown: TKeyEvent;
    AOnKeyPress: TKeyPressEvent);
Begin
    OnExit := AOnExit;
    OnKeyDown := AOnKeyDown;
    OnKeyPress := AOnKeyPress;
End;

Procedure TNoReflowTabBarRotatedCaptionEdit.ClearEditorEvents;
Begin
    OnExit := Nil;
    OnKeyDown := Nil;
    OnKeyPress := Nil;
End;

Procedure TNoReflowTabBarRotatedCaptionEdit.ApplyEditorBaseSettings(
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

Procedure TNoReflowTabBarRotatedCaptionEdit.ApplyEditorTextOrientation(
    ATextOrientation: TNoReflowTabBarTextOrientation);
Begin
    //-------------------------------------------------------------------------
    //Keep this method as the orientation-only entry point.
    //
    //The actual geometry method calls it after assigning Left / Top and the
    //logical size. This avoids using SetBounds, which can recursively interact
    //with TRotatedEdit's projected VCL geometry.
    //-------------------------------------------------------------------------

    Case ATextOrientation Of
        nrttoVerticalDown: Begin
            Orientation := reoVerticalDown;
            Angle := 270.0;
        End;

        nrttoVerticalUp: Begin
            Orientation := reoVerticalUp;
            Angle := 90.0;
        End;
    Else
        Orientation := reoHorizontal;
        Angle := 0.0;
    End;
End;

Procedure TNoReflowTabBarRotatedCaptionEdit.ApplyEditorTextGeometry(
    Const AGeometry: TNoReflowTabBarCaptionEditorGeometry);
Var
    LTextLength:    Integer;
    LTextThickness: Integer;
Begin
    //-------------------------------------------------------------------------
    //TRotatedEdit exposes a logical geometry model.
    //
    //NoReflowTabBar no longer gives this adapter a raw reference rectangle to
    //interpret. It provides an explicit center point, logical text length,
    //logical text thickness and orientation.
    //
    //Important:
    //Do not call SetBounds here. SetBounds works on the projected VCL rectangle
    //and can recursively trigger geometry recalculations inside TRotatedEdit,
    //especially for vertical angles.
    //-------------------------------------------------------------------------

    LTextLength := AGeometry.TextLength;
    LTextThickness := AGeometry.TextThickness;

    If LTextLength < 1 Then
        LTextLength := 1;

    If LTextThickness < 1 Then
        LTextThickness := 1;

    LogicalLength := LTextLength;
    LogicalThickness := LTextThickness;

    Case AGeometry.TextOrientation Of
        nrttoVerticalDown:
            Angle := 270.0;

        nrttoVerticalUp:
            Angle := 90.0;
    Else
        Angle := 0.0;
    End;

    //-------------------------------------------------------------------------
    //Angle and logical dimensions may update the projected VCL Width/Height.
    //Left/Top are therefore assigned last so the final editor control is
    //centered on the text reference center supplied by the TabBar.
    //-------------------------------------------------------------------------

    Left := AGeometry.TextCenter.X - (Width Div 2);
    Top := AGeometry.TextCenter.Y - (Height Div 2);
End;
Procedure TNoReflowTabBarRotatedCaptionEdit.AssignEditorFont(AFont: TFont);
Begin
    If AFont = Nil Then
        Exit;

    Font.Assign(AFont);
End;

Procedure TNoReflowTabBarRotatedCaptionEdit.AddEditorFontStyle(AStyle: TFontStyles);
Begin
    Font.Style := Font.Style + AStyle;
End;

Procedure TNoReflowTabBarRotatedCaptionEdit.SetEditorStyleElements(AValue: TStyleElements);
Begin
    StyleElements := AValue;
End;

Procedure TNoReflowTabBarRotatedCaptionEdit.SetEditorColors(
    ABackgroundColor: TColor;
    ATextColor: TColor);
Begin
    Color := ABackgroundColor;
    Font.Color := ATextColor;
End;

Initialization
    //-------------------------------------------------------------------------
    //Loading this optional package enables the TRotatedEdit editor globally for
    //NoReflowTabBar instances created afterwards.
    //-------------------------------------------------------------------------

    RegisterNoReflowTabBarCaptionEditorFactory(CreateRotatedCaptionEditor);

Finalization
    //-------------------------------------------------------------------------
    //Unregister only our own factory. If another package replaced it later, the
    //runtime package helper will leave that newer registration untouched.
    //-------------------------------------------------------------------------

    UnregisterNoReflowTabBarCaptionEditorFactory(CreateRotatedCaptionEditor);

End.
