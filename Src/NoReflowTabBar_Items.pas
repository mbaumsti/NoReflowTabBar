Unit NoReflowTabBar_Items;

{
  NoReflowTabBar_Items.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Persistent item and signal model of the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Persistent model layer of the NoReflowTabBar component.

  This unit provides:
  - TNoReflowTabBarItem, the persistent logical description of one item;
  - TNoReflowTabBarItems, the streamed collection of bar items;
  - TNoReflowTabBarSignalDef, one available status indicator definition;
  - TNoReflowTabBarSignalDefs, the collection of available status indicators;
  - INoReflowTabBarModelHost, the notification interface used by the model to
    notify its owning control.

  Role of this unit:
  - store the persistent data exposed by the component;
  - model items independently from their visual rendering;
  - provide the collections streamed into DFM files;
  - notify the host control whenever the model changes.

  Main responsibilities:
  - store item captions, user identifiers, visibility and enabled state;
  - store logical zone information through PinZone and ZoneIndex;
  - store signal information through logical code, value and optional maximum;
  - expose persistent collections used by design-time and runtime code.

  Architectural position:
  - NoReflowTabBar_Items is the logical data source of the component;
  - NoReflowTabBar_Core consumes this model to compute layout and rendering;
  - NoReflowTabBar publishes this model through BarItems and BarSignals.

  Notes:
  - this unit does not render items directly;
  - this unit does not know the detailed rendering pipeline;
  - it acts as the persistent model layer between design-time data and the
    visual engine.
}

Interface

Uses
    System.Classes,
    System.SysUtils,
    System.Math,
    System.Generics.Collections,
    Vcl.Graphics,
    NoReflowTabBar_CommonTypes,
    NoreflowTabBar_Library;

Type
    TNoReflowTabBarItem = Class;
    TNoReflowTabBarItems = Class;
    TNoReflowTabBarSignalDef = Class;
    TNoReflowTabBarSignalDefs = Class;

    {
      Minimal host interface exposed by the owning component to the item model.

      The model classes use this interface instead of depending directly on
      TNoReflowTabBar. This keeps the item model independent from the final
      visual control and avoids circular dependencies between units.
    }
    INoReflowTabBarModelHost = Interface
        ['{D63F0A0B-7E48-4F8D-9F60-8F54A3FC1D21}']
        {
          Notifies the host that item or signal data has changed.
        }
        Procedure ItemsChanged;

        {
          Requests a layout invalidation on the host control.
        }
        Procedure InvalidateLayout;

        {
          Notifies the host that a selected item object is being removed.

          This lets the host clear or update any selection state stored by
          object reference before the item is destroyed.
        }
        Procedure SelectedItemReferenceRemoved(AItem: TNoReflowTabBarItem);

        {
          Finds a signal definition by its logical code.
        }
        Function FindSignalDefByCode(ACode: Integer): TNoReflowTabBarSignalDef;

        {
          Finds a signal definition by its display name.
        }
        Function FindSignalDefByName(Const AName: String): TNoReflowTabBarSignalDef;

        {
          Returns True while the host is loading streamed component data.
        }
        Function IsHostLoading: Boolean;

        {
          Moves an item to a target logical zone and zone-relative index.
        }
        Procedure MoveItemToZone(
            AItem: TNoReflowTabBarItem;
            ANewZone: TNoReflowTabBarPinZone;
            ANewZoneIndex: Integer);

        {
          Normalizes the physical item collection order by logical zone.
        }
        Procedure NormalizeItemsOrderByZone;

        {
          Returns the number of items currently stored in a logical zone.
        }
        Function GetItemsCountInZone(APinZone: TNoReflowTabBarPinZone): Integer;
    End;

    {
      Defines one status indicator that can be referenced by bar items.

      Each definition has a stable technical code, a readable name, a fill
      color and a border color. Items store the code through SignalCode; the
      name is mainly a design-time convenience and can also be used by the
      SignalName helper property.
    }
    TNoReflowTabBarSignalDef = Class(TCollectionItem)
    private
        FCode:        Integer;
        FName:        String;
        FFillColor:   TColor;
        FBorderColor: TColor;
        Function IsReservedSignalCode(AValue: Integer): Boolean;
        Function IsBuiltInSignal: Boolean;

        Procedure SetCode(Const Value: Integer);
        Procedure SetName(Const Value: String);
        Procedure SetFillColor(Const Value: TColor);
        Procedure SetBorderColor(Const Value: TColor);

        Function GetHost: INoReflowTabBarModelHost;
    protected
        // Returns the name displayed by the signal collection editor.
        Function GetDisplayName: String; override;
    public
        {
          Creates a signal definition with its default values.
        }
        Constructor Create(Collection: TCollection); override;

        {
          Copies another persistent signal definition.
        }
        Procedure Assign(Source: TPersistent); override;

        {
          Host interface exposed by the owning signal collection.
        }
        Property Host: INoReflowTabBarModelHost Read GetHost;

        {
          Initializes one built-in signal definition.

          This method is intended for the component initialization code. It lets
          the collection create reserved standard signals without going through
          the normal user-editable setter restrictions.
        }
        Procedure InitBuiltIn(
            ACode: Integer;
            Const AName: String;
            AFillColor: TColor;
            ABorderColor: TColor);
    published
        {
          Technical signal identifier.

          This code is the real key stored by items through SignalCode. Codes
          should be unique within one signal collection.
        }
        Property Code: Integer Read FCode Write SetCode default 0;

        {
          Readable signal name.

          The name is used in design-time display and by the item SignalName
          convenience property.
        }
        Property Name: String Read FName Write SetName;

        {
          Signal fill color.
        }
        Property FillColor: TColor Read FFillColor Write SetFillColor default clGray;

        {
          Signal border color.
        }
        Property BorderColor: TColor Read FBorderColor Write SetBorderColor default clDkGray;
    End;

    {
      Collection of signal definitions available to one bar.

      The collection is owned by TNoReflowTabBar and is used to provide built-in
      status indicators, add user-defined indicators, and resolve indicators by
      code or name.
    }
    TNoReflowTabBarSignalDefs = Class(TOwnedCollection)
    private
        FUpdateLock: Integer;
        FHost:       INoReflowTabBarModelHost;

        Function GetItem(Index: Integer): TNoReflowTabBarSignalDef;
        Procedure SetItem(
            Index: Integer;
            Const Value: TNoReflowTabBarSignalDef);

    public
        {
          Creates the collection and attaches it to a host component.
        }
        Constructor Create(
            AOwner: TPersistent;
            Const AHost: INoReflowTabBarModelHost);

        {
          Starts a grouped update on the collection.
        }
        Procedure BeginUpdate;

        {
          Ends a grouped update and notifies the host when needed.
        }
        Procedure EndUpdate;

        {
          Adds a new signal definition.
        }
        Function Add: TNoReflowTabBarSignalDef;

        {
          Finds a signal definition by its logical code.

          Returns Nil when no matching definition exists.
        }
        Function FindByCode(ACode: Integer): TNoReflowTabBarSignalDef;

        {
          Finds a signal definition by its name.

          Returns Nil when no matching definition exists.
        }
        Function FindByName(Const AName: String): TNoReflowTabBarSignalDef;

        {
          Indexed access to signal definitions.
        }
        Property Items[Index: Integer]: TNoReflowTabBarSignalDef Read GetItem Write SetItem; default;

        {
          Host interface notified when the collection changes.
        }
        Property Host: INoReflowTabBarModelHost Read FHost;
    protected
        // Reacts to any collection or item change.
        Procedure Update(Item: TCollectionItem); override;
    End;

    {
      Persistent logical item stored in a NoReflowTabBar item collection.

      This class contains no geometry and no rendering logic. It describes the
      item data: caption, visibility, enabled state, checked state, signal,
      user identifier, hint, logical zone and optional glyph information.
    }
    TNoReflowTabBarItem = Class(TCollectionItem)
    private
        FCaption:     String;
        FSignalCode:  Integer;
        FSignalValue: Double;
        FSignalMax:   Double;
        FItemUserId:  Integer; // Free user identifier, kept for compatibility.
        FItemKey:     Integer; // Unique technical key generated by the component.
        FVisible:     Boolean;
        FEnabled:     Boolean;

        // Persistent checked state carried by the item.
        //
        // The meaning depends on the bar mode:
        // - in tabs and single-selection button modes, it can reflect the active item;
        // - in check-button mode, it is the main item state;
        // - in push-button mode, it can be ignored by the automatic behaviour.
        FChecked:   Boolean;
        FHint:      String;
        FShowHint:  Boolean;
        FPinZone:   TNoReflowTabBarPinZone;
        FZoneIndex: Integer;
        FData:      TObject;

        //-----------------------------------------------------------------
        // Local item glyph data
        //-----------------------------------------------------------------

        // Optional index in the bar global ImageList.
        //
        // This is used as a fallback when no local glyph object is available.
        FGlyphIndex: Integer;

        // Optional symbolic glyph name.
        //
        // Reserved for a future name-based glyph resolution mechanism. It is
        // currently not connected to rendering, metrics or design-time editing.
        FGlyphName: String;

        // Indicates whether this item glyph should be displayed.
        //
        // This makes it possible to keep glyph information in memory while
        // temporarily hiding it from rendering.
        FShowGlyph: Boolean;

        // Item-specific glyph position.
        FGlyphPosition: TNoReflowTabBarItemGlyphPosition;

        // Sets the optional global ImageList index.
        Procedure SetGlyphIndex(Const Value: Integer);

        // Sets the item-specific glyph position.
        Procedure SetGlyphPosition(Const Value: TNoReflowTabBarItemGlyphPosition);

        // Sets the optional symbolic glyph name.
        Procedure SetGlyphName(Const Value: String);

        // Enables or disables glyph rendering for this item.
        Procedure SetShowGlyph(Const Value: Boolean);

        // Returns the name of the signal referenced by this item.
        Function GetSignalName: String;

        // Sets the signal code referenced by this item.
        Procedure SetSignalCode(Const Value: Integer);

        // Sets the signal by resolving a signal definition name.
        Procedure SetSignalName(Const Value: String);

        // Sets the current signal fill value.
        Procedure SetSignalValue(Const Value: Double);

        // Sets the maximum reference value used for partial signal rendering.
        Procedure SetSignalMax(Const Value: Double);

        // Sets the item-specific hint text.
        Procedure SetHint(Const Value: String);

        // Enables or disables hint display for this item.
        Procedure SetShowHint(Const Value: Boolean);

        // Sets the item caption.
        Procedure SetCaption(Const Value: String);

        // Sets the user identifier independently from the item index.
        Procedure SetItemUserId(Const Value: Integer);

        // Shows or hides the item.
        Procedure SetVisible(Const Value: Boolean);

        // Enables or disables item selection and hit testing.
        Procedure SetEnabled(Const Value: Boolean);

        // Sets the persistent checked state.
        Procedure SetChecked(Const Value: Boolean);

        // Returns the owning host, when available.
        Function GetHost: INoReflowTabBarModelHost;

        // Sets the internal logical pin zone.
        Procedure SetPinZone(Const Value: TNoReflowTabBarPinZone);

        // Sets the user-facing logical zone.
        Procedure SetZone(Const Value: TNoReflowTabBarZone);

        // Returns the user-facing logical zone.
        Function GetZone: TNoReflowTabBarZone;

        // Returns the current absolute index in the collection.
        Function GetItemIndex: Integer;

        // Returns the stored zone-relative index.
        Function GetZoneIndex: Integer;

        // Sets the stored zone-relative index.
        Procedure SetZoneIndex(Const Value: Integer);

        Procedure ReadItemKey(Reader: TReader);
        Procedure WriteItemKey(Writer: TWriter);

    protected
        // Copies persistent item data from another item.
        Procedure Assign(Source: TPersistent); override;

        // Sets the internal pin zone without invoking the normal move logic.
        Procedure SetPinZoneDirect(Const Value: TNoReflowTabBarPinZone);

        // Returns the name displayed by the collection editor.
        Function GetDisplayName: String; override;

        // Defines the hidden streamed technical key property.
        Procedure DefineProperties(Filer: TFiler); override;
    public
        {
          Creates an item with its default values.
        }
        Constructor Create(Collection: TCollection); override;

        {
          Destroys the item and notifies the host before destruction when this
          item is stored as the selected item reference.
        }
        Destructor Destroy; override;

        {
          Host interface of the owning collection.
        }
        Property Host: INoReflowTabBarModelHost Read GetHost;

        {
          Sets the internal pin zone and zone-relative index directly.

          This method is intended for the host component when it has already
          validated and normalized a zone move.
        }
        Procedure SetZonePlacementDirect(
            Const APinZone: TNoReflowTabBarPinZone;
            Const AZoneIndex: Integer);

        {
          Sets the stored zone-relative index directly.
        }
        Procedure SetZoneIndexDirect(Const Value: Integer);

        {
          Sets the checked state without using the public setter logic.

          This method is intended for the core component when several items must
          be synchronized at once, for example to enforce exclusive selection.
        }
        Procedure SetCheckedDirect(Const Value: Boolean);

        {
          Current absolute index of the item in its collection.

          The value is computed on demand from the owning collection.
        }
        Property ItemIndex: Integer Read GetItemIndex;

        {
          Unique technical item key.

          This key is generated automatically by the collection and is used for
          stable identification during persistence, restoration and internal
          operations that must not depend on the current collection index.

          Unlike UserId, this key has no business meaning and should not be
          modified by application code.
        }
        Property ItemKey: Integer Read FItemKey;

        {
          Internal logical pin zone of the item.

          This property is kept for component internals and is normalized to one
          of the effective zones: nrtpzStart, nrtpzCenter or nrtpzEnd.
        }
        Property PinZone: TNoReflowTabBarPinZone Read FPinZone Write SetPinZone default nrtpzCenter;

        {
          Free user object associated with the item.

          The tab bar does not own this object. The caller remains responsible
          for its lifetime.
        }
        Property Data: TObject Read FData Write FData;

        {
          Optional symbolic glyph name.

          This property is reserved for a future name-based glyph resolution
          mechanism. It is available to application code, but is not published
          because it is not currently an active design-time feature.
        }
        Property GlyphName: String Read FGlyphName Write SetGlyphName;

    published
        {
          Text displayed by the item.
        }
        Property Caption: String Read FCaption Write SetCaption;

        {
          Technical code of the signal used by the item.

          The value 0 means that the item has no signal.
        }
        Property SignalCode: Integer Read FSignalCode Write SetSignalCode default 0;

        {
          Name of the signal used by the item.

          This is a convenience view over SignalCode. It does not store any
          additional state. Reading the property returns the name matching the
          current code. Writing the property searches a signal with that name
          and updates SignalCode automatically.
        }
        Property SignalName: String Read GetSignalName Write SetSignalName stored False;

        {
          Current signal fill value.

          This value is meaningful only when SignalMax is greater than 0.
          Otherwise the signal is drawn as a full indicator.
        }
        Property SignalValue: Double Read FSignalValue Write SetSignalValue;

        {
          Maximum reference value for partial signal rendering.

          Examples:
          - SignalValue = 3 and SignalMax = 4 means 75 percent filled;
          - SignalValue = 75 and SignalMax = 100 means 75 percent filled.

          When SignalMax is less than or equal to 0, the signal is drawn as a
          full indicator.
        }
        Property SignalMax: Double Read FSignalMax Write SetSignalMax;

        {
          User-defined item identifier.

          This can be used to find or manipulate an item independently from its
          current collection index.
        }
        Property UserId: Integer Read FItemUserId Write SetItemUserId default 0;

        {
          Read-only design-time view of the internal technical key.

          The real persistence of the technical key is handled through
          DefineProperties; this property only makes the generated key visible
          for diagnostics in the Object Inspector.
        }
        Property KeyView: Integer Read FItemKey stored False;

        {
          Indicates whether the item participates in layout, rendering and hit
          testing.
        }
        Property Visible: Boolean Read FVisible Write SetVisible default True;

        {
          Indicates whether the item can be selected or activated.
        }
        Property Enabled: Boolean Read FEnabled Write SetEnabled default True;

        {
          Indicates whether the item is checked.

          The exact meaning depends on the bar mode:
          - tabs and single-selection buttons synchronize it with the active item;
          - check buttons use it as the independent state of each item;
          - push buttons do not automatically modify it when clicked.
        }
        Property Checked: Boolean Read FChecked Write SetChecked default False;

        {
          Item-specific hint text.

          When this is empty, the component may fall back to the item caption.
        }
        Property Hint: String Read FHint Write SetHint;

        {
          Enables or disables hint display for this item.
        }
        Property ShowHint: Boolean Read FShowHint Write SetShowHint default True;

        {
          User-facing logical zone of the item.

          nrtzStart keeps the item in the start block, nrtzCenter stores it in
          the regular center block, and nrtzEnd keeps it in the end block.
        }
        Property Zone: TNoReflowTabBarZone Read GetZone Write SetZone default nrtzCenter;

        {
          Relative item position inside its logical zone.

          This property reorders the item inside its current zone without
          changing the zone itself. Assigned values are automatically clamped to
          the valid range of the zone: 0 to zone item count - 1.
        }
        Property ZoneIndex: Integer Read FZoneIndex Write SetZoneIndex stored True;

        {
          Optional index in the bar global ImageList.

          The value -1 means that no image index is assigned.
        }
        Property GlyphIndex: Integer Read FGlyphIndex Write SetGlyphIndex default -1;

        {
          Item-specific glyph position.

          nrigpDefault uses the global position defined by the bar. Other values
          force the glyph to the left, right, top or bottom for this item only.
        }
        Property GlyphPosition: TNoReflowTabBarItemGlyphPosition Read FGlyphPosition Write SetGlyphPosition default nrigpDefault;

        {
          Determines whether this item's glyph should be displayed.
        }
        Property ShowGlyph: Boolean Read FShowGlyph Write SetShowGlyph default True;

    End;

    {
      Persistent collection of items exposed by the component.

      The collection centralizes item insertion, deletion and modification, then
      notifies the host control so it can update selection, layout and rendering.
    }
    TNoReflowTabBarItems = Class(TOwnedCollection)
    private
        FHost:        INoReflowTabBarModelHost;
        FUpdateLock:  Integer;
        FLastItemKey: Integer;

        // Returns the item at the requested index.
        Function GetItem(Index: Integer): TNoReflowTabBarItem;

        // Replaces the item at the requested index.
        Procedure SetItem(
            Index: Integer;
            Const Value: TNoReflowTabBarItem);

    public
        {
          Creates the collection and attaches it to a host component.
        }
        Constructor Create(
            AOwner: TPersistent;
            Const AHost: INoReflowTabBarModelHost);

        {
          Starts a grouped collection update.
        }
        Procedure BeginUpdate;

        {
          Ends a grouped collection update and notifies the host when needed.
        }
        Procedure EndUpdate;

        {
          Restores a technical key previously streamed for an item.
        }
        Procedure RestoreItemKey(
            AItem: TNoReflowTabBarItem;
            AKey: Integer);

        {
          Allocates a new unique technical item key.
        }
        Function AllocateItemKey: Integer;

        {
          Returns True if a technical item key already exists in the collection.

          AExceptItem can be used to ignore one item during validation.
        }
        Function ItemKeyExists(
            AKey: Integer;
            AExceptItem: TNoReflowTabBarItem = Nil): Boolean;

        {
          Ensures that all items have unique technical keys.
        }
        Procedure EnsureUniqueItemsKeys;

        {
          Adds a new item at the end of the collection.
        }
        Function Add: TNoReflowTabBarItem;

        {
          Inserts a new item at the requested absolute collection index.
        }
        Function Insert(Index: Integer): TNoReflowTabBarItem;

        {
          Indexed access to the items in the collection.
        }
        Property Items[Index: Integer]: TNoReflowTabBarItem Read GetItem Write SetItem; default;

        {
          Host interface notified when the collection changes.
        }
        Property Host: INoReflowTabBarModelHost Read FHost;
    protected
        // Reacts to collection or item modifications.
        Procedure Update(Item: TCollectionItem); override;

    End;

Implementation


//===============================================================================================================================
//TNoReflowTabSignalDef
//===============================================================================================================================

Constructor TNoReflowTabBarSignalDef.Create(Collection: TCollection);
Var
    LDefs: TNoReflowTabBarSignalDefs;
    LCode: Integer;
Begin
    Inherited Create(Collection);

    FName := 'Signal';
    FFillColor := clGray;
    FBorderColor := clDkGray;

    //Valeur par défaut sûre :
    //on évite 0 et on cherche un code libre au-dessus des codes réservés.
    LCode := 5;

    If Collection Is TNoReflowTabBarSignalDefs Then Begin
        LDefs := TNoReflowTabBarSignalDefs(Collection);
        While LDefs.FindByCode(LCode) <> Nil Do
            Inc(LCode);
    End;

    FCode := LCode;
End;

Procedure TNoReflowTabBarSignalDef.Assign(Source: TPersistent);
Begin
    If Source Is TNoReflowTabBarSignalDef Then Begin
        FCode := TNoReflowTabBarSignalDef(Source).Code;
        FName := TNoReflowTabBarSignalDef(Source).Name;
        FFillColor := TNoReflowTabBarSignalDef(Source).FillColor;
        FBorderColor := TNoReflowTabBarSignalDef(Source).BorderColor;
        Changed(False);
    End
    Else
        Inherited Assign(Source);
End;

Procedure TNoReflowTabBarSignalDef.InitBuiltIn(
    ACode: Integer;
    Const AName: String;
    AFillColor: TColor;
    ABorderColor: TColor);
Begin
    //Initialise directement une définition de signal intégrée.
    //
    //Cette méthode est utilisée par la barre pour recréer les signaux
    //par défaut sans passer par les validations des propriétés publiques,
    //qui interdisent la modification des signaux built-in.
    FCode := ACode;
    FName := Trim(AName);
    FFillColor := AFillColor;
    FBorderColor := ABorderColor;
    Changed(False);
End;

Function TNoReflowTabBarSignalDef.GetDisplayName: String;
Var
    LName: String;
    LKind: String;
Begin
    //-------------------------------------------------------------------------
    //Nom affiché dans l'éditeur de collection des voyants.
    //
    //Objectif :
    //- afficher un libellé utile en conception
    //- distinguer clairement les voyants système des voyants personnalisés
    //- conserver le code visible pour faciliter les affectations par SignalCode
    //-------------------------------------------------------------------------

    LName := Trim(FName);
    If LName = '' Then
        LName := 'Signal';

    If IsBuiltInSignal Then
        LKind := 'Built-in'
    Else
        LKind := 'Custom';

    Result := Format(
        '%s - Code=%d - %s',
        [LName, FCode, LKind]);
End;

Function TNoReflowTabBarSignalDef.GetHost: INoReflowTabBarModelHost;
Begin
    Result := Nil;

    If Collection Is TNoReflowTabBarSignalDefs Then
        Result := TNoReflowTabBarSignalDefs(Collection).Host;
End;

Function TNoReflowTabBarSignalDef.IsReservedSignalCode(AValue: Integer): Boolean;
Begin
    Result := AValue In [nrtSignalNone, nrtSignalGray, nrtSignalGreen, nrtSignalOrange, nrtSignalRed];
End;

Function TNoReflowTabBarSignalDef.IsBuiltInSignal: Boolean;
Begin
    Result := FCode In [nrtSignalGray, nrtSignalGreen, nrtSignalOrange, nrtSignalRed];
End;

Procedure TNoReflowTabBarSignalDef.SetCode(Const Value: Integer);
Var
    LHost:      INoReflowTabBarModelHost;
    LExisting:  TNoReflowTabBarSignalDef;
    LIsLoading: Boolean;
Begin
    If FCode = Value Then
        Exit;

    LHost := GetHost;
    LIsLoading := Assigned(LHost) And LHost.IsHostLoading;

    //0 = réservé à "aucun voyant"
    If Value = nrtSignalNone Then
        Raise EArgumentException.Create(Msg(CMsgSignalCodeCannotBeZero));

    //Pendant le chargement du DFM, on laisse Delphi relire les codes réservés.
    If Not LIsLoading Then Begin
        //Un voyant système existant garde son code figé.
        If IsBuiltInSignal Then
            Raise EArgumentException.Create(Msg(CMsgBuiltInSignalCodeReadOnly));

        //Les codes réservés 1..4 ne peuvent pas être attribués
        //à un voyant personnalisé.
        If Value In [nrtSignalGray, nrtSignalGreen, nrtSignalOrange, nrtSignalRed] Then
            Raise EArgumentException.CreateFmt(Msg(CMsgSignalCodeReserved), [Value]);
    End;

    If LHost <> Nil Then Begin
        LExisting := LHost.FindSignalDefByCode(Value);

        If (LExisting <> Nil) And (LExisting <> Self) Then
            Raise EArgumentException.CreateFmt(Msg(CMsgSignalCodeAlreadyExists), [Value]);
    End;

    FCode := Value;
    Changed(False);
End;

Procedure TNoReflowTabBarSignalDef.SetName(Const Value: String);
Var
    LHost:      INoReflowTabBarModelHost;
    LExisting:  TNoReflowTabBarSignalDef;
    LNewName:   String;
    LIsLoading: Boolean;
Begin
    LNewName := Trim(Value);

    If FName = LNewName Then
        Exit;

    LHost := GetHost;
    LIsLoading := Assigned(LHost) And LHost.IsHostLoading;

    If LNewName = '' Then
        Raise EArgumentException.Create(Msg(CMsgSignalNameCannotBeEmpty));

    //Hors chargement DFM, le nom des voyants système est figé.
    If (Not LIsLoading) And IsBuiltInSignal Then
        Raise EArgumentException.Create(Msg(CMsgBuiltInSignalNameReadOnly));

    If LHost <> Nil Then Begin
        LExisting := LHost.FindSignalDefByName(Value);

        If (LExisting <> Nil) And (LExisting <> Self) Then
            Raise EArgumentException.CreateFmt(Msg(CMsgSignalNameAlreadyExists), [LNewName]);
    End;

    FName := LNewName;
    Changed(False);
End;

Procedure TNoReflowTabBarSignalDef.SetFillColor(Const Value: TColor);
Var
    LHost:      INoReflowTabBarModelHost;
    LIsLoading: Boolean;
Begin
    If FFillColor = Value Then
        Exit;

    LHost := GetHost;
    LIsLoading := Assigned(LHost) And LHost.IsHostLoading;

    //Hors chargement DFM, les couleurs des voyants système sont figées.
    If (Not LIsLoading) And IsBuiltInSignal Then
        Raise EArgumentException.Create(Msg(CMsgBuiltInSignalColorsReadOnly));

    FFillColor := Value;
    Changed(False);
End;

Procedure TNoReflowTabBarSignalDef.SetBorderColor(Const Value: TColor);
Var
    LHost:      INoReflowTabBarModelHost;
    LIsLoading: Boolean;
Begin
    If FBorderColor = Value Then
        Exit;

    LHost := GetHost;
    LIsLoading := Assigned(LHost) And LHost.IsHostLoading;

    //Hors chargement DFM, les couleurs des voyants système sont figées.
    If (Not LIsLoading) And IsBuiltInSignal Then
        Raise EArgumentException.Create(Msg(CMsgBuiltInSignalColorsReadOnly));

    FBorderColor := Value;
    Changed(False);
End;

//===============================================================================================================================
//TNoReflowTabSignalDefs
//===============================================================================================================================

Constructor TNoReflowTabBarSignalDefs.Create(
    AOwner: TPersistent;
    Const AHost: INoReflowTabBarModelHost);
Begin
    Inherited Create(AOwner, TNoReflowTabBarSignalDef);
    FHost := AHost;
End;

Procedure TNoReflowTabBarSignalDefs.BeginUpdate;
Begin
    Inc(FUpdateLock);
End;

Procedure TNoReflowTabBarSignalDefs.EndUpdate;
Begin
    If FUpdateLock > 0 Then
        Dec(FUpdateLock);

    If (FUpdateLock = 0) And Assigned(FHost) Then
        FHost.InvalidateLayout;
End;

Function TNoReflowTabBarSignalDefs.Add: TNoReflowTabBarSignalDef;
Begin
    Result := TNoReflowTabBarSignalDef(Inherited Add);
End;

Function TNoReflowTabBarSignalDefs.GetItem(Index: Integer): TNoReflowTabBarSignalDef;
Begin
    Result := TNoReflowTabBarSignalDef(Inherited Items[Index]);
End;

Procedure TNoReflowTabBarSignalDefs.SetItem(
    Index: Integer;
    Const Value: TNoReflowTabBarSignalDef);
Begin
    Inherited Items[Index] := Value;
End;

Function TNoReflowTabBarSignalDefs.FindByCode(ACode: Integer): TNoReflowTabBarSignalDef;
Var
    I: Integer;
Begin
    Result := Nil;

    For I := 0 To Count - 1 Do Begin
        If Items[I].Code = ACode Then Begin
            Result := Items[I];
            Exit;
        End;
    End;
End;

Function TNoReflowTabBarSignalDefs.FindByName(Const AName: String): TNoReflowTabBarSignalDef;
Var
    I:     Integer;
    LName: String;
Begin
    Result := Nil;
    LName := Trim(AName);

    For I := 0 To Count - 1 Do Begin
        If SameText(Trim(Items[I].Name), LName) Then Begin
            Result := Items[I];
            Exit;
        End;
    End;
End;

Procedure TNoReflowTabBarSignalDefs.Update(Item: TCollectionItem);
Begin
    Inherited Update(Item);

    If FUpdateLock > 0 Then
        Exit;

    If Assigned(FHost) Then
        FHost.InvalidateLayout;
End;

//===============================================================================================================================
//TNoReflowTabBarItem
//===============================================================================================================================

//Construit un nouvel item de collection
//
//À ce stade, l'objet ne connaît encore ni sa géométrie ni sa position
//dans la barre. Il ne contient que les données métier de base.
//
//Les valeurs choisies ici correspondent à un item standard :
//- visible
//- activé
//- sans voyant
//- sans hint explicite
Constructor TNoReflowTabBarItem.Create(Collection: TCollection);
Begin
    Inherited Create(Collection);

    //---------------------------------------------------------------------
    //Initialisation du glyph local.
    //
    //Le bitmap appartient à l'item. Il reste donc stable pendant toute la
    //durée de vie de l'item, ce qui permet :
    //- le streaming DFM ;
    //- les affectations par Assign ;
    //- les modifications design-time ;
    //- les chargements dynamiques depuis le gestionnaire de menus.
    //---------------------------------------------------------------------

    FGlyphIndex := -1;
    FGlyphName := '';
    FShowGlyph := True;

    //Libellé par défaut affiché si l'appelant ne renseigne rien.
    FCaption := 'Item';

    //Par défaut, aucun voyant n'est affiché.
    FSignalCode := 0;

    //Niveau de remplissage par défaut.
    //
    //Avec SignalMax = 0, le composant considérera que le voyant
    //doit être affiché en mode plein classique.
    FSignalValue := 0.0;
    FSignalMax := 0.0;

    //Identifiant utilisateur libre.
    //Il peut être utilisé par le code appelant pour retrouver un item
    //autrement que par son index dans la collection.
    FItemUserId := 0;

    If Collection Is TNoReflowTabBarItems Then
        FItemKey := TNoReflowTabBarItems(Collection).AllocateItemKey
    Else
        FItemKey := 0;

    //L’item est visible par défaut.
    FVisible := True;

    //L’item est sélectionnable par défaut.
    FEnabled := True;

    //L'item n'est pas coché par défaut.
    //
    //La barre synchronisera éventuellement cette valeur selon son BarMode.
    FChecked := False;

    //Aucun hint personnalisé par défaut.
    //Si Hint reste vide, la barre pourra utiliser Caption comme repli.
    FHint := '';

    //Les hints sont autorisés par défaut pour cet item.
    FShowHint := True;

    //Par défaut, un item est un item "central" standard.
    FPinZone := nrtpzCenter;

    //Par défaut, l'item est le premier de sa zone logique.
    FZoneIndex := 0;

End;

Destructor TNoReflowTabBarItem.Destroy;
Var
    LHost: INoReflowTabBarModelHost;
Begin
    //-------------------------------------------------------------------------
    //Avant destruction réelle de l'item, on informe la barre propriétaire
    //pour qu'elle puisse invalider proprement toute référence stable vers
    //cet objet si celui-ci correspond à la sélection courante mémorisée.
    //
    //Important :
    //cette notification doit être faite AVANT Inherited Destroy, tant que
    //l'item possède encore sa collection et peut encore retrouver son host.
    //-------------------------------------------------------------------------

    LHost := GetHost;
    If Assigned(LHost) Then
        LHost.SelectedItemReferenceRemoved(Self);

    Inherited Destroy;
End;

//Retourne la barre propriétaire de cet item.
//
//Un TNoReflowTabBarItem appartient normalement à une collection TNoReflowTabBarItems,
//elle-même attachée à une TNoReflowTabBar.
//Cette méthode permet à l'item de remonter facilement à son contrôle
//propriétaire quand c'est nécessaire.
Function TNoReflowTabBarItem.GetHost: INoReflowTabBarModelHost;
Begin
    Result := Nil;

    If Collection Is TNoReflowTabBarItems Then
        Result := TNoReflowTabBarItems(Collection).Host;
End;

//Copie les données métier depuis un autre TNoReflowTabBarItem.
//
//Comme pour les autres sous-objets, on recopie les propriétés utiles
//puis on déclenche un unique Changed(False) pour notifier la collection.
Procedure TNoReflowTabBarItem.Assign(Source: TPersistent);
var
    Src: TNoReflowTabBarItem;

Begin
    If Source Is TNoReflowTabBarItem Then Begin
        Src := TNoReflowTabBarItem(Source);

        FCaption := Src.Caption;
        FSignalCode := Src.SignalCode;
        FSignalValue := Src.SignalValue;
        FSignalMax := Src.SignalMax;
        FItemUserId := Src.UserId;

        //On ne copie volontairement pas ItemKey.
        //Assign duplique le contenu métier, mais l'item cible doit conserver
        //ou recevoir sa propre identité technique.
        If Collection Is TNoReflowTabBarItems Then
            FItemKey := TNoReflowTabBarItems(Collection).AllocateItemKey
        Else
            FItemKey := 0;

        FVisible := Src.Visible;
        FEnabled := Src.Enabled;
        FChecked := Src.Checked;
        FHint := Src.Hint;
        FShowHint := Src.ShowHint;
        FPinZone := Src.PinZone;
        FZoneIndex := Src.ZoneIndex;

        FData := Nil;

        //-----------------------------------------------------------------
        //Copie des informations de glyph.
        //
        //FGlyph est un objet possédé par l'item cible : on ne remplace jamais
        //la référence, on copie seulement le contenu du bitmap.
        //-----------------------------------------------------------------
        FGlyphIndex := Src.GlyphIndex;
        FGlyphName := Src.GlyphName;
        FShowGlyph := Src.ShowGlyph;
        FGlyphPosition := Src.GlyphPosition;

        //Signale à la collection qu'un item a changé.
        //Le False signifie qu'on ne reconstruit pas l'identité de l'item,
        //on indique simplement une modification de contenu.
        Changed(False);
    End
    Else
        Inherited Assign(Source);
End;

Procedure TNoReflowTabBarItem.SetZone(Const Value: TNoReflowTabBarZone);
Begin
    SetPinZone(TabZoneToPinZone(Value));
End;

Function TNoReflowTabBarItem.GetZone: TNoReflowTabBarZone;
Begin
    Result := PinZoneToTabZone(FPinZone);
End;

Procedure TNoReflowTabBarItem.SetPinZone(Const Value: TNoReflowTabBarPinZone);
Var
    LHost:  INoReflowTabBarModelHost;
    LValue: TNoReflowTabBarPinZone;
Begin
    //-------------------------------------------------------------------------
    //Définit la zone logique d'ancrage de l'item.
    //
    //Important :
    //nrtpzNone est une valeur interne signifiant "aucune zone".
    //Un item réel doit toujours appartenir à une zone effective.
    //Si nrtpzNone est affecté par erreur ou par compatibilité, on le ramène
    //donc à nrtpzCenter.
    //
    //Pendant le chargement DFM, PinZone/Zone peut être lu avant TabZoneIndex.
    //Il ne faut donc surtout pas déclencher ici un déplacement réel dans la
    //collection, sinon l'item est déplacé avec un FZoneIndex encore
    //provisoire.
    //-------------------------------------------------------------------------

    LValue := Value;

    If LValue = nrtpzNone Then
        LValue := nrtpzCenter;

    If FPinZone = LValue Then
        Exit;

    LHost := GetHost;
    If Not Assigned(LHost) Then Begin
        FPinZone := LValue;
        Changed(False);
        Exit;
    End;

    If LHost.IsHostLoading Then Begin
        FPinZone := LValue;
        Changed(False);
        Exit;
    End;

    LHost.MoveItemToZone(
        Self,
        LValue,
        FZoneIndex);
End;

Function TNoReflowTabBarItem.GetItemIndex: Integer;
Begin
    //-------------------------------------------------------------------------
    //Retourne l'index absolu courant de l'item dans la collection.
    //
    //Comme TNoReflowTabBarItem hérite de TCollectionItem,
    //la propriété Index reflète déjà sa position réelle courante.
    //-------------------------------------------------------------------------

    Result := Index;
End;

Function TNoReflowTabBarItem.GetZoneIndex: Integer;
Begin
    //-------------------------------------------------------------------------
    //Retourne l'index logique mémorisé de l'item dans sa zone.
    //
    //Cette valeur est stockée dans FItemZoneIndex.
    //Elle est maintenue cohérente par les opérations de déplacement
    //et recompaquée lors des normalisations d'ordre.
    //-------------------------------------------------------------------------
    Result := FZoneIndex;
End;

Procedure TNoReflowTabBarItem.SetZoneIndex(Const Value: Integer);
Var
    LHost:         INoReflowTabBarModelHost;
    LOldZoneIndex: Integer;
    LNewZoneIndex: Integer;
    LZoneCount:    Integer;
    I:             Integer;
    LOtherItem:    TNoReflowTabBarItem;
    LItems:        TNoReflowTabBarItems;

Begin
    //-------------------------------------------------------------------------
    //Définit l'index logique mémorisé de l'item dans sa zone.
    //
    //Important :
    //une simple affectation de FItemZoneIndex ne suffit pas,
    //car il faut conserver un ordre logique cohérent dans la zone :
    //- sans doublons persistants
    //- sans "trous"
    //- avec déplacement réel de l'item dans l'ordre logique
    //
    //Le comportement attendu est donc celui d'une insertion :
    //- on retire l'item de sa position logique actuelle
    //- on décale les autres items de la zone si nécessaire
    //- on l'insère à la nouvelle position logique
    //- puis on normalise l'ordre physique
    //-------------------------------------------------------------------------

    LNewZoneIndex := Value;
    If LNewZoneIndex < 0 Then
        LNewZoneIndex := 0;

    LHost := GetHost;
    If Not Assigned(LHost) Then Begin
        If FZoneIndex <> LNewZoneIndex Then Begin
            FZoneIndex := LNewZoneIndex;
            Changed(False);
        End;
        Exit;
    End;

    //Pendant le chargement/lecture, on se contente de mémoriser la valeur.
    //La normalisation globale sera faite plus tard, quand le composant
    //sera complètement initialisé.
    If LHost.IsHostLoading Then Begin
        If FZoneIndex <> LNewZoneIndex Then Begin
            FZoneIndex := LNewZoneIndex;
            Changed(False);
        End;
        Exit;
    End;

    LZoneCount := LHost.GetItemsCountInZone(Self.PinZone);
    If LZoneCount <= 0 Then
        LZoneCount := 1;

    If LNewZoneIndex > LZoneCount - 1 Then
        LNewZoneIndex := LZoneCount - 1;

    LOldZoneIndex := FZoneIndex;

    If LOldZoneIndex = LNewZoneIndex Then
        Exit;

    //-------------------------------------------------------------------------
    //Réorganisation logique des index dans la zone.
    //
    //Cas 1 : déplacement vers le début
    //Exemple : 3 -> 1
    //Les éléments [1..2] doivent être décalés vers la fin.
    //
    //Cas 2 : déplacement vers la fin
    //Exemple : 1 -> 3
    //Les éléments [2..3] doivent être décalés vers le début.
    //-------------------------------------------------------------------------
    If Collection Is TNoReflowTabBarItems Then Begin
        LItems := TNoReflowTabBarItems(Collection);
        LItems.BeginUpdate;
        Try
            For I := 0 To LItems.Count - 1 Do Begin
                LOtherItem := LItems[I];

                If LOtherItem = Nil Then
                    Continue;

                If LOtherItem = Self Then
                    Continue;

                If LOtherItem.PinZone <> Self.PinZone Then
                    Continue;

                If LOldZoneIndex > LNewZoneIndex Then Begin
                    If (LOtherItem.FZoneIndex >= LNewZoneIndex) And (LOtherItem.FZoneIndex < LOldZoneIndex) Then
                        Inc(LOtherItem.FZoneIndex);
                End Else Begin
                    If (LOtherItem.FZoneIndex > LOldZoneIndex) And (LOtherItem.FZoneIndex <= LNewZoneIndex) Then
                        Dec(LOtherItem.FZoneIndex);
                End;
            End;

            FZoneIndex := LNewZoneIndex;
            LHost.NormalizeItemsOrderByZone;
        Finally
            LItems.EndUpdate;
        End;

        //On force la remise en cohérence complète sélection/layout/rendu.
        LHost.ItemsChanged;
    End;

    Changed(False);
End;

Procedure TNoReflowTabBarItem.SetChecked(Const Value: Boolean);
Begin
    //-------------------------------------------------------------------------
    //Modifie l'état coché persistant de l'item.
    //
    //Cette propriété ne décide pas elle-même de la stratégie globale de la
    //barre. Elle stocke seulement l'état porté par l'item.
    //
    //La barre décidera ensuite comment interpréter cet état selon BarMode :
    //- sélection exclusive ;
    //- bouton cochable indépendant ;
    //- ou état ignoré automatiquement en mode push.
    //-------------------------------------------------------------------------

    If FChecked = Value Then
        Exit;

    FChecked := Value;
    Changed(False);
End;

Procedure TNoReflowTabBarItem.SetCheckedDirect(Const Value: Boolean);
Begin
    //-------------------------------------------------------------------------
    //Affectation directe utilisée par la barre propriétaire.
    //
    //Elle évite de déclencher une notification intermédiaire pour chaque item
    //lorsque le Core synchronise un groupe complet d'items.
    //
    //Important : cette méthode ne déclenche pas Changed(False).
    //L'appelant doit invalider la barre une seule fois après synchronisation.
    //-------------------------------------------------------------------------

    FChecked := Value;
End;

Procedure TNoReflowTabBarItem.DefineProperties(Filer: TFiler);
Begin
    Inherited DefineProperties(Filer);

    //-------------------------------------------------------------------------
    //ItemKey est une clé technique interne.
    //
    //On veut :
    //- la conserver dans le DFM pour les items design-time
    //- ne pas l'exposer dans l'inspecteur d'objets
    //- éviter que l'utilisateur la modifie manuellement
    //
    //DefineProperties permet précisément de streamer une donnée cachée.
    //-------------------------------------------------------------------------

    Filer.DefineProperty(
        'ItemKey',
        ReadItemKey,
        WriteItemKey,
        FItemKey > 0);
End;

Procedure TNoReflowTabBarItem.ReadItemKey(Reader: TReader);
Begin
    //-------------------------------------------------------------------------
    //Lecture brute pendant le streaming.
    //
    //On ne passe pas par une validation stricte ici, car au moment où Delphi
    //relit les items du DFM, tous les items ne sont pas forcément encore
    //complètement relus.
    //
    //Les doublons éventuels seront corrigés ensuite par EnsureUniqueItemsKeys.
    //-------------------------------------------------------------------------

    FItemKey := Reader.ReadInteger;
End;

Procedure TNoReflowTabBarItem.WriteItemKey(Writer: TWriter);
Begin
    Writer.WriteInteger(FItemKey);
End;

Procedure TNoReflowTabBarItem.SetZonePlacementDirect(
    Const APinZone: TNoReflowTabBarPinZone;
    Const AZoneIndex: Integer);
Var
    LZoneIndex: Integer;
Begin
    LZoneIndex := AZoneIndex;
    If LZoneIndex < 0 Then
        LZoneIndex := 0;

    If APinZone = nrtpzNone Then
        FPinZone := nrtpzCenter
    Else
        FPinZone := APinZone;

    FZoneIndex := LZoneIndex;
    Changed(False);
End;

Procedure TNoReflowTabBarItem.SetZoneIndexDirect(Const Value: Integer);
Var
    LValue: Integer;
Begin
    LValue := Value;
    If LValue < 0 Then
        LValue := 0;

    If FZoneIndex = LValue Then
        Exit;

    FZoneIndex := LValue;
    Changed(False);
End;

Procedure TNoReflowTabBarItem.SetPinZoneDirect(Const Value: TNoReflowTabBarPinZone);
Begin
    If Value = nrtpzNone Then
        FPinZone := nrtpzCenter
    Else
        FPinZone := Value;
End;

Function TNoReflowTabBarItem.GetDisplayName: String;
Const
    CZoneNames: Array [TNoReflowTabBarZone] Of String = ('Start', 'Center', 'End');
Var
    LCaption: String;
Begin
    //-------------------------------------------------------------------------
    //Nom affiché dans l'éditeur de collection.
    //
    //Objectif :
    //- montrer autre chose que le simple nom de classe
    //- donner un libellé parlant en conception
    //- conserver une identification suffisante même si plusieurs items
    //ont le même Caption
    //-------------------------------------------------------------------------

    LCaption := Trim(FCaption);

    If LCaption = '' Then
        LCaption := 'Item';

    Result := Format(
        '%s - %s - UserId=%d - InternalKey=%d',
        [LCaption, CZoneNames[Zone], FItemUserId, FItemKey]);
End;



Procedure TNoReflowTabBarItem.SetGlyphIndex(Const Value: Integer);
Begin
    If FGlyphIndex = Value Then
        Exit;

    FGlyphIndex := Value;

    //---------------------------------------------------------------------
    //Un changement d'index d'image peut modifier le rendu et, plus tard,
    //les métriques si la taille du glyph intervient dans le layout.
    //---------------------------------------------------------------------
    Changed(False);
End;

Procedure TNoReflowTabBarItem.SetGlyphPosition(Const Value: TNoReflowTabBarItemGlyphPosition);
Begin
    If FGlyphPosition = Value Then
        Exit;

    FGlyphPosition := Value;

    //---------------------------------------------------------------------
    //Changer la position du glyph modifie la géométrie interne de l'item :
    //- glyph à gauche/droite : impact principal sur la longueur ;
    //- glyph en haut/bas     : impact principal sur l'épaisseur.
    //
    //On notifie donc l'item afin que la barre recalcule les métriques,
    //le layout et le rendu.
    //---------------------------------------------------------------------
    Changed(False);
End;

Procedure TNoReflowTabBarItem.SetGlyphName(Const Value: String);
Begin
    If FGlyphName = Value Then
        Exit;

    FGlyphName := Value;

    //---------------------------------------------------------------------
    //GlyphName est actuellement réservé pour un développement futur.
    //
    //On conserve néanmoins la notification standard afin que :
    //- le code applicatif qui manipule déjà cette propriété reste cohérent ;
    //- une future implémentation puisse se raccorder sans changer ce contrat ;
    //- le composant invalide proprement son état si cette propriété devient
    //un jour exploitable par le rendu ou par un résolveur dédié.
    //---------------------------------------------------------------------
    Changed(False);
End;

Procedure TNoReflowTabBarItem.SetShowGlyph(Const Value: Boolean);
Begin
    If FShowGlyph = Value Then
        Exit;

    FShowGlyph := Value;

    //---------------------------------------------------------------------
    //Afficher ou masquer le glyph peut modifier la largeur utile de l'item
    //dès que le rendu des glyphes sera raccordé au moteur de métriques.
    //---------------------------------------------------------------------
    Changed(False);
End;



Function TNoReflowTabBarItem.GetSignalName: String;
Var
    LHost: INoReflowTabBarModelHost;
    LDef:  TNoReflowTabBarSignalDef;
Begin
    Result := '';

    LHost := GetHost;
    If Not Assigned(LHost) Then
        Exit;

    LDef := LHost.FindSignalDefByCode(FSignalCode);
    If LDef <> Nil Then
        Result := LDef.Name;
End;

Procedure TNoReflowTabBarItem.SetSignalCode(Const Value: Integer);
Var
    LHost: INoReflowTabBarModelHost;
Begin
    If FSignalCode = Value Then
        Exit;

    //0 reste autorisé ici : cela signifie "aucun voyant"
    If Value <> 0 Then Begin
        LHost := GetHost;
        If Assigned(LHost) And (LHost.FindSignalDefByCode(Value) = Nil) Then
            Raise EArgumentException.CreateFmt(Msg(CMsgSignalCodeNotExist), [Value]);
    End;

    FSignalCode := Value;
    Changed(False);
End;

Procedure TNoReflowTabBarItem.SetSignalName(Const Value: String);
Var
    LHost:    INoReflowTabBarModelHost;
    LDef:     TNoReflowTabBarSignalDef;
    LNewCode: Integer;
Begin
    LHost := GetHost;
    If Not Assigned(LHost) Then
        Exit;

    If Trim(Value) = '' Then
        LNewCode := 0
    Else Begin
        LDef := LHost.FindSignalDefByName(Value);
        If LDef = Nil Then
            Exit;

        LNewCode := LDef.Code;
    End;

    SetSignalCode(LNewCode);
End;

Procedure TNoReflowTabBarItem.SetSignalValue(Const Value: Double);
Begin
    //Pas de mise à jour si la valeur ne change pas réellement.
    If SameValue(FSignalValue, Value) Then
        Exit;

    FSignalValue := Value;

    //Le rendu du voyant dépend directement de cette valeur.
    Changed(False);
End;

Procedure TNoReflowTabBarItem.SetSignalMax(Const Value: Double);
Begin
    //Pas de mise à jour si la valeur ne change pas réellement.
    If SameValue(FSignalMax, Value) Then
        Exit;

    FSignalMax := Value;

    //Le mode plein / partiel dépend directement de cette valeur.
    Changed(False);
End;

//Définit le hint spécifique de l'item.
//
//Si cette chaîne reste vide, le composant peut utiliser Caption
//comme texte de hint de secours.
Procedure TNoReflowTabBarItem.SetHint(Const Value: String);
Begin
    If FHint = Value Then
        Exit;

    FHint := Value;
    Changed(False);
End;

//Active ou désactive l'affichage du hint pour cet item.
//
//Cette propriété permet de couper les hints au niveau d'un item donné,
//même si la barre globale a ShowHint = True.
Procedure TNoReflowTabBarItem.SetShowHint(Const Value: Boolean);
Begin
    If FShowHint = Value Then
        Exit;

    FShowHint := Value;
    Changed(False);
End;

//Définit le libellé affiché sur l'item.
//
//Cette modification impacte typiquement :
//- le texte dessiné
//- les mesures de largeur / hauteur
//- le layout global si les items sont recalculés
Procedure TNoReflowTabBarItem.SetCaption(Const Value: String);
Begin
    If FCaption = Value Then
        Exit;

    FCaption := Value;
    Changed(False);
End;

//Définit l'identifiant utilisateur de l'item.
//
//Contrairement à l'index, ItemUserId n'est pas imposé par la collection
//et peut être choisi librement par le code appelant.
//
//Il n'est pas garanti unique : les méthodes par ItemUserId utilisent
//le premier item trouvé.
Procedure TNoReflowTabBarItem.SetItemUserId(Const Value: Integer);
Begin
    If FItemUserId = Value Then
        Exit;

    FItemUserId := Value;
    Changed(False);
End;

//Définit la visibilité de l'item.
//
//Un item invisible reste présent dans la collection,
//mais il n'est ni dessiné ni pris en compte dans le layout visible.
Procedure TNoReflowTabBarItem.SetVisible(Const Value: Boolean);
Begin
    If FVisible = Value Then
        Exit;

    FVisible := Value;
    Changed(False);
End;

//Définit si l'item est activé.
//
//Un item désactivé peut rester visible, mais il n'est plus sélectionnable
//et sera rendu avec l'état visuel nrtvsDisabled.
Procedure TNoReflowTabBarItem.SetEnabled(Const Value: Boolean);
Begin
    If FEnabled = Value Then
        Exit;

    FEnabled := Value;
    Changed(False);
End;

//===============================================================================================================================
//TNoReflowTabBarItems
//===============================================================================================================================

//Construit la collection d'items liée à une barre donnée.
//
//Le type d'item est fixé à TNoreflowTabBarItem.
//La référence FItemBar permet ensuite à la collection de prévenir
//son propriétaire lors des modifications.
Constructor TNoReflowTabBarItems.Create(
    AOwner: TPersistent;
    Const AHost: INoReflowTabBarModelHost);
Begin
    Inherited Create(AOwner, TNoReflowTabBarItem);
    FHost := AHost;
End;

//Entre en mode mise à jour groupée sur la collection.
//
//Tant que FUpdateLock > 0, les changements sur les items
//n'entraînent pas immédiatement TabsChanged.
//Cela permet d'ajouter, supprimer ou modifier plusieurs items
//sans recalculer la barre à chaque opération.
Procedure TNoReflowTabBarItems.BeginUpdate;
Begin
    //-------------------------------------------------------------------------
    //Important :
    //on prolonge le mécanisme standard de TCollection au lieu de le court-circuiter.
    //
    //Cela permet au streaming DFM, au designer et aux notifications internes
    //de fonctionner sur une vraie collection Delphi "normale".
    //-------------------------------------------------------------------------
    Inherited BeginUpdate;
    Inc(FUpdateLock);
End;

//Sort du mode mise à jour groupée.
//
//Quand le compteur revient à zéro, la collection déclenche
//une notification unique vers la barre propriétaire.
Procedure TNoReflowTabBarItems.EndUpdate;
Begin
    If FUpdateLock > 0 Then
        Dec(FUpdateLock);

    //-------------------------------------------------------------------------
    //On laisse TCollection terminer proprement son cycle de mise à jour.
    //Le rappel final passera ensuite par Update.
    //-------------------------------------------------------------------------
    Inherited EndUpdate;
End;

Procedure TNoReflowTabBarItems.RestoreItemKey(
    AItem: TNoReflowTabBarItem;
    AKey: Integer);
Var
    OldKey: Integer;
Begin
    //-------------------------------------------------------------------------
    //Restaure une clé technique depuis un stockage externe.
    //
    //Cette méthode est volontairement portée par la collection :
    //- elle connaît tous les items
    //- elle peut garantir l'unicité
    //- elle peut maintenir FLastItemKey
    //
    //Si la clé est invalide ou déjà utilisée par un autre item, on attribue
    //une nouvelle clé au lieu de provoquer une collision.
    //-------------------------------------------------------------------------

    If AItem = Nil Then
        Exit;

    OldKey := AItem.FItemKey;

    If (AKey > 0) And Not ItemKeyExists(AKey, AItem) Then
        AItem.FItemKey := AKey
    Else
        AItem.FItemKey := AllocateItemKey;

    If AItem.FItemKey > FLastItemKey Then
        FLastItemKey := AItem.FItemKey;

    If AItem.FItemKey <> OldKey Then
        AItem.Changed(False);
End;

Function TNoReflowTabBarItems.ItemKeyExists(
    AKey: Integer;
    AExceptItem: TNoReflowTabBarItem = Nil): Boolean;
Var
    I:    Integer;
    Item: TNoReflowTabBarItem;
Begin
    Result := False;

    If AKey <= 0 Then
        Exit;

    For I := 0 To Count - 1 Do Begin
        Item := Items[I];

        If Item = Nil Then
            Continue;

        If Item = AExceptItem Then
            Continue;

        If Item.ItemKey = AKey Then Begin
            Result := True;
            Exit;
        End;
    End;
End;

Function TNoReflowTabBarItems.AllocateItemKey: Integer;
Begin
    Repeat
        Inc(FLastItemKey);
    Until Not ItemKeyExists(FLastItemKey, Nil);

    Result := FLastItemKey;
End;

Procedure TNoReflowTabBarItems.EnsureUniqueItemsKeys;
Var
    I:        Integer;
    Item:     TNoReflowTabBarItem;
    UsedKeys: TDictionary<Integer, Boolean>;
    NewKey:   Integer;
Begin
    //-------------------------------------------------------------------------
    //Garantit que tous les items possèdent une clé technique unique.
    //
    //On conserve les premières clés valides rencontrées.
    //Seuls les items sans clé ou en doublon sont réaffectés.
    //-------------------------------------------------------------------------

    UsedKeys := TDictionary<Integer, Boolean>.Create;
    Try
        FLastItemKey := 0;

        For I := 0 To Count - 1 Do Begin
            Item := Items[I];

            If Item = Nil Then
                Continue;

            If Item.FItemKey > FLastItemKey Then
                FLastItemKey := Item.FItemKey;
        End;

        For I := 0 To Count - 1 Do Begin
            Item := Items[I];

            If Item = Nil Then
                Continue;

            If (Item.FItemKey <= 0) Or UsedKeys.ContainsKey(Item.FItemKey) Then Begin
                NewKey := AllocateItemKey;

                If Item.FItemKey <> NewKey Then Begin
                    Item.FItemKey := NewKey;
                    Item.Changed(False);
                End;
            End;

            UsedKeys.AddOrSetValue(
                Item.FItemKey,
                True);
        End;
    Finally UsedKeys.Free;
    End;
End;

Function TNoReflowTabBarItems.Add: TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Collection neutre :
    //aucun comportement métier ici.
    //
    //Très important pour le streaming DFM et pour le designer :
    //Add doit juste ajouter un item de collection standard.
    //-------------------------------------------------------------------------
    Result := TNoReflowTabBarItem(Inherited Add);
End;

Function TNoReflowTabBarItems.Insert(Index: Integer): TNoReflowTabBarItem;
Begin
    //-------------------------------------------------------------------------
    //Même principe :
    //Insert doit rester un insert physique pur.
    //-------------------------------------------------------------------------
    Result := TNoReflowTabBarItem(Inherited Insert(Index));
End;

//Accesseur typé pour lire un item de la collection.
//
//Cela évite d'avoir à faire un cast explicite à chaque accès.
Function TNoReflowTabBarItems.GetItem(Index: Integer): TNoReflowTabBarItem;
Begin
    Result := TNoReflowTabBarItem(Inherited Items[Index]);
End;

//Accesseur typé pour remplacer un item dans la collection.
//
//En pratique, ce setter est peu utilisé directement,
//mais il complète l'interface de la propriété par défaut.
Procedure TNoReflowTabBarItems.SetItem(
    Index: Integer;
    Const Value: TNoReflowTabBarItem);
Begin
    Inherited Items[Index] := Value;
End;

//Réagit à toute modification de la collection ou d'un item.
//
//Cette méthode est appelée automatiquement par l'infrastructure
//des collections Delphi lorsque :
//- un item est ajouté
//- un item est supprimé
//- un item appelle Changed(False)
//
//Si la collection n'est pas en BeginUpdate/EndUpdate,
//on propage immédiatement la notification vers la barre.
Procedure TNoReflowTabBarItems.Update(Item: TCollectionItem);
Begin
    Inherited Update(Item);

    //En mode groupé, on diffère la notification.
    If FUpdateLock > 0 Then
        Exit;

    //Pendant le chargement du DFM, on ne normalise rien.
    If Assigned(FHost) And FHost.IsHostLoading Then
        Exit;

    If Assigned(FHost) Then
        FHost.ItemsChanged;
End;

End.

