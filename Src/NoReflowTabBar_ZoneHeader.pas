Unit NoReflowTabBar_ZoneHeader;

{
  NoReflowTabBar_ZoneHeader.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Zone header configuration object for the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Persistent configuration object for NoReflowTabBar logical zone headers.

  This unit provides:
  - TNoReflowTabBarZoneHeader, the persistent configuration object used to
    describe the optional decorative captions displayed for the Start, Center
    and End zones.

  Role of this unit:
  - group the visual and textual settings of zone headers;
  - expose these settings as a persistent sub-object editable in the Delphi
    Object Inspector;
  - notify the owning component whenever a setting changes;
  - remain independent from the layout and rendering engines.

  Notes:
  - this unit does not draw anything by itself;
  - it does not compute zone geometry;
  - it only stores the configuration required by the rendering layer;
  - when Visible is False or no caption is defined, GetTotalHeight returns 0.
}

Interface

Uses
    System.Classes,
    System.SysUtils,
    Vcl.Graphics,
    NoReflowTabBar_CommonTypes;

Type
    {
      Persistent configuration object describing decorative zone headers.

      A zone header can display separate captions for the Start, Center and End
      logical zones. The object stores only configuration data: visibility,
      captions, font, margins, dimensions, placement and colors.

      Actual layout computation and drawing are handled by the specialised
      layout and rendering layers of the component.
    }
    TNoReflowTabBarZoneHeader = Class(TPersistent)
    Private
        FOwner:         TPersistent;
        FOnChanged:     TNotifyEvent;

        FVisible:       Boolean;

        FStartCaption:  String;
        FCenterCaption: String;
        FEndCaption:    String;

        FFont:          TFont;

        FHeight:        Integer;
        FTopMargin:     Integer;
        FBottomMargin:  Integer;
        FTextPadding:   Integer;
        FTickSize:      Integer;
        FPlacement: TNoReflowZoneHeaderPlacement;

        FLineColor:     TColor;
        FTextColor:     TColor;

        Procedure SetVisible(Const Value: Boolean);

        Procedure SetStartCaption(Const Value: String);
        Procedure SetCenterCaption(Const Value: String);
        Procedure SetEndCaption(Const Value: String);

        Procedure SetFont(Const Value: TFont);

        Procedure SetHeight(Const Value: Integer);
        Procedure SetTopMargin(Const Value: Integer);
        Procedure SetBottomMargin(Const Value: Integer);
        Procedure SetTextPadding(Const Value: Integer);
        Procedure SetTickSize(Const Value: Integer);
        Procedure SetPlacement(Const Value: TNoReflowZoneHeaderPlacement);

        Procedure SetLineColor(Const Value: TColor);
        Procedure SetTextColor(Const Value: TColor);

        Procedure FontChanged(Sender: TObject);
        Procedure Changed;
    Protected
        {
          Returns the persistent owner of the zone-header configuration object.

          This allows the Object Inspector and streaming system to associate the
          sub-object with its owning component.
        }
        Function GetOwner: TPersistent; Override;
    Public
        {
          Creates the zone-header configuration object and stores its owner.
        }
        Constructor Create(AOwner: TPersistent);

        {
          Releases the owned font object.
        }
        Destructor Destroy; Override;

        {
          Copies all zone-header settings from another compatible persistent
          object.
        }
        Procedure Assign(Source: TPersistent); Override;

        {
          Returns True when at least one of the Start, Center or End captions is
          not empty.
        }
        Function HasAnyCaption: Boolean;

        {
          Returns the total vertical size consumed by the zone header.

          The result is 0 when the header is not visible or when all captions are
          empty. Otherwise it includes the configured top margin, header height
          and bottom margin.
        }
        Function GetTotalHeight: Integer;

        {
          Event fired when any setting changes.

          The owning control uses this notification to invalidate layout and/or
          repaint itself without the configuration object depending directly on
          the final component class.
        }
        Property OnChanged: TNotifyEvent Read FOnChanged Write FOnChanged;
    Published
        {
          Enables or disables zone-header drawing.
        }
        Property Visible: Boolean Read FVisible Write SetVisible Default False;

        {
          Defines where the zone header is placed relative to the bar content.

          nrthpOuterBand reserves a dedicated band outside the item area.
          nrthpAboveZone draws the header above its zone within the zone layout
          context.
        }
        Property Placement: TNoReflowZoneHeaderPlacement
            Read FPlacement
            Write SetPlacement
            Default nrthpOuterBand;

        {
          Caption displayed for the Start logical zone.
        }
        Property CaptionStart: String Read FStartCaption Write SetStartCaption;

        {
          Caption displayed for the Center logical zone.
        }
        Property CaptionCenter: String Read FCenterCaption Write SetCenterCaption;

        {
          Caption displayed for the End logical zone.
        }
        Property CaptionEnd: String Read FEndCaption Write SetEndCaption;

        {
          Font used to draw zone-header captions.

          This font is independent from the item font.
        }
        Property Font: TFont Read FFont Write SetFont;

        {
          Useful height of the header line itself, excluding top and bottom
          margins.
        }
        Property Height: Integer Read FHeight Write SetHeight Default 14;

        {
          Margin inserted above the header.
        }
        Property TopMargin: Integer Read FTopMargin Write SetTopMargin Default 6;

        {
          Margin inserted below the header.
        }
        Property BottomMargin: Integer Read FBottomMargin Write SetBottomMargin Default 6;

        {
          Space kept between the caption text and the decorative horizontal
          line.
        }
        Property TextPadding: Integer Read FTextPadding Write SetTextPadding Default 6;

        {
          Size of the small vertical tick drawn at the ends of the decorative
          line.
        }
        Property TickSize: Integer Read FTickSize Write SetTickSize Default 10;

        {
          Color of the decorative zone-header line.
        }
        Property LineColor: TColor Read FLineColor Write SetLineColor Default clActiveBorder;

        {
          Color of the zone-header caption text.
        }
        Property TextColor: TColor Read FTextColor Write SetTextColor Default clCaptionText;
    End;

Implementation


//===============================================================================================================================
//TNoReflowTabBarZoneHeader
//===============================================================================================================================

Constructor TNoReflowTabBarZoneHeader.Create(AOwner: TPersistent);
Begin
    Inherited Create;

    FOwner := AOwner;

    FVisible := False;
    FPlacement := nrthpOuterBand;

    FStartCaption := '';
    FCenterCaption := '';
    FEndCaption := '';

    FFont := TFont.Create;
    FFont.Name := 'Segoe UI';
    FFont.Size := 8;
    FFont.Style := [fsItalic];
    FFont.OnChange := FontChanged;

    FHeight := 14;
    FTopMargin := 6;
    FBottomMargin := 6;
    FTextPadding := 6;
    FTickSize := 10;

    FLineColor := clActiveBorder;
    FTextColor := clCaptionText;
End;

Destructor TNoReflowTabBarZoneHeader.Destroy;
Begin
    FFont.Free;
    Inherited Destroy;
End;

Function TNoReflowTabBarZoneHeader.GetOwner: TPersistent;
Begin
    Result := FOwner;
End;

Procedure TNoReflowTabBarZoneHeader.Assign(Source: TPersistent);
Var
    LSource: TNoReflowTabBarZoneHeader;
Begin
    If Source Is TNoReflowTabBarZoneHeader Then Begin
        LSource := TNoReflowTabBarZoneHeader(Source);

        FVisible := LSource.FVisible;
        FPlacement := LSource.FPlacement;
        FStartCaption := LSource.FStartCaption;
        FCenterCaption := LSource.FCenterCaption;
        FEndCaption := LSource.FEndCaption;

        FFont.Assign(LSource.FFont);

        FHeight := LSource.FHeight;
        FTopMargin := LSource.FTopMargin;
        FBottomMargin := LSource.FBottomMargin;
        FTextPadding := LSource.FTextPadding;
        FTickSize := LSource.FTickSize;

        FLineColor := LSource.FLineColor;
        FTextColor := LSource.FTextColor;

        Changed;
    End
    Else
        Inherited Assign(Source);
End;

Procedure TNoReflowTabBarZoneHeader.Changed;
Begin
    If Assigned(FOnChanged) Then
        FOnChanged(Self);
End;

Procedure TNoReflowTabBarZoneHeader.FontChanged(Sender: TObject);
Begin
    Changed;
End;

Function TNoReflowTabBarZoneHeader.HasAnyCaption: Boolean;
Begin
    Result :=
        (Trim(FStartCaption) <> '') Or
        (Trim(FCenterCaption) <> '') Or
        (Trim(FEndCaption) <> '');
End;

Function TNoReflowTabBarZoneHeader.GetTotalHeight: Integer;
Begin
    If (Not FVisible) Or (Not HasAnyCaption) Then Begin
        Result := 0;
        Exit;
    End;

    Result := FTopMargin + FHeight + FBottomMargin;
End;

Procedure TNoReflowTabBarZoneHeader.SetVisible(Const Value: Boolean);
Begin
    If FVisible = Value Then
        Exit;

    FVisible := Value;
    Changed;
End;

Procedure TNoReflowTabBarZoneHeader.SetStartCaption(Const Value: String);
Begin
    If FStartCaption = Value Then
        Exit;

    FStartCaption := Value;
    Changed;
End;

Procedure TNoReflowTabBarZoneHeader.SetCenterCaption(Const Value: String);
Begin
    If FCenterCaption = Value Then
        Exit;

    FCenterCaption := Value;
    Changed;
End;

Procedure TNoReflowTabBarZoneHeader.SetEndCaption(Const Value: String);
Begin
    If FEndCaption = Value Then
        Exit;

    FEndCaption := Value;
    Changed;
End;

Procedure TNoReflowTabBarZoneHeader.SetFont(Const Value: TFont);
Begin
    FFont.Assign(Value);
End;

Procedure TNoReflowTabBarZoneHeader.SetHeight(Const Value: Integer);
Var
    LValue: Integer;
Begin
    LValue := Value;
    If LValue < 0 Then
        LValue := 0;

    If FHeight = LValue Then
        Exit;

    FHeight := LValue;
    Changed;
End;

Procedure TNoReflowTabBarZoneHeader.SetTopMargin(Const Value: Integer);
Var
    LValue: Integer;
Begin
    LValue := Value;
    If LValue < 0 Then
        LValue := 0;

    If FTopMargin = LValue Then
        Exit;

    FTopMargin := LValue;
    Changed;
End;

Procedure TNoReflowTabBarZoneHeader.SetBottomMargin(Const Value: Integer);
Var
    LValue: Integer;
Begin
    LValue := Value;
    If LValue < 0 Then
        LValue := 0;

    If FBottomMargin = LValue Then
        Exit;

    FBottomMargin := LValue;
    Changed;
End;

Procedure TNoReflowTabBarZoneHeader.SetTextPadding(Const Value: Integer);
Var
    LValue: Integer;
Begin
    LValue := Value;
    If LValue < 0 Then
        LValue := 0;

    If FTextPadding = LValue Then
        Exit;

    FTextPadding := LValue;
    Changed;
End;

Procedure TNoReflowTabBarZoneHeader.SetTickSize(Const Value: Integer);
Var
    LValue: Integer;
Begin
    LValue := Value;
    If LValue < 0 Then
        LValue := 0;

    If FTickSize = LValue Then
        Exit;

    FTickSize := LValue;
    Changed;
End;

Procedure TNoReflowTabBarZoneHeader.SetPlacement(Const Value: TNoReflowZoneHeaderPlacement);
Begin
    If FPlacement = Value Then
        Exit;

    FPlacement := Value;
    Changed;
End;

Procedure TNoReflowTabBarZoneHeader.SetLineColor(Const Value: TColor);
Begin
    If FLineColor = Value Then
        Exit;

    FLineColor := Value;
    Changed;
End;

Procedure TNoReflowTabBarZoneHeader.SetTextColor(Const Value: TColor);
Begin
    If FTextColor = Value Then
        Exit;

    FTextColor := Value;
    Changed;
End;

End.

