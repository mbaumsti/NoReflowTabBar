Unit NoReflowTabBar_StorageSupport;

{
  NoReflowTabBar_StorageSupport.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Storage and restoration layer for the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Logical storage layer for the NoReflowTabBar component.

  This unit provides:
  - TNoReflowTabBarStorageSupport, the component layer exposing storage APIs;
  - TNoReflowTabBarStorageEntry, the logical storage entry structure;
  - TNoReflowTabBarStorageEntryList, an in-memory list of storage entries;
  - TNoReflowTabBarStorageEnumerator, a snapshot enumerator over storage entries;
  - TNoReflowTabBarStorageOptions, the option record controlling what is saved
    or restored.

  Purpose:
  - allow the component to export a backend-independent logical data stream;
  - allow applications to store this state in text files, INI files, the
    registry, streams, databases, application settings, or third-party storage
    components without coupling NoReflowTabBar to any specific backend.

  Storage model:
  - Root identifies the bar, for example FcFiches2Form.ItemsRub;
  - Section groups related properties, for example General, Item.0, Item.1;
  - Name identifies the stored property, for example Id, Zone, ZoneIndex,
    Caption;
  - Kind describes the logical value type;
  - Value contains the already serialised textual value.

  Example logical entries:
    Root    = FcFiches2Form.ItemsRub
    Section = General
    Name    = Version
    Kind    = nrbsvkInteger
    Value   = 1

    Root    = FcFiches2Form.ItemsRub
    Section = Item.0
    Name    = UserId
    Kind    = nrbsvkInteger
    Value   = 12

  This model can be mapped directly to an INI file:
    [FcFiches2Form.ItemsRub.General]
    Version=1

    [FcFiches2Form.ItemsRub.Item.0]
    UserId=12

  It can also be mapped to database rows, TStrings, registry keys or any custom
  application storage format.

  Important notes:
  - reliable restoration primarily relies on ItemKey, the stable technical
    item identifier;
  - UserId remains available as an application-level identifier and historical
    fallback;
  - for dynamically recreated items, a stable application UserId remains useful.
}

Interface

Uses
    System.Classes,
    System.SysUtils,
    System.TypInfo,
    System.Generics.Collections,
    System.IniFiles,
    NoReflowTabBar_CommonTypes,
    NoReflowTabBar_Items,
    NoReflowTabBar_DragSupport;

Type
    {
      Defines which parts of each item can be saved and restored.

      The selected parts are used together with TNoReflowTabBarStorageOptions to
      decide which properties are exported to or imported from storage.
    }
    TNoReflowTabBarStoragePart = (
        nrbspPlacement,  // Zone and ZoneIndex.
        nrbspCaption,    // Caption.
        nrbspVisibility, // Visible.
        nrbspEnabled,    // Enabled.
        nrbspSignal,     // SignalCode, SignalValue and SignalMax.
        nrbspHint,       // Hint and ShowHint.

        {
          Simple glyph-related item properties.

          This part stores lightweight persistent properties only:
          - ShowGlyph;
          - GlyphIndex;
          - GlyphPosition.

          It intentionally does not serialise an embedded bitmap glyph. Bitmap
          glyph persistence requires a dedicated storage strategy and should not
          be mixed with this generic logical storage layer.
        }
        nrbspGlyph,

        {
          Persistent Checked state carried by the item model.

          This is primarily useful in nrbmCheckButtons mode, but it is kept as an
          independent state so storage can accurately preserve the model.
        }
        nrbspChecked,

        nrbspSelection   // Current selected item.
        );

    {
      Set of item storage parts.
    }
    TNoReflowTabBarStorageParts = Set Of TNoReflowTabBarStoragePart;

    {
      Item zones that can participate in save or restore operations.

      This type intentionally does not use TNoReflowTabBarPinZone because
      nrtpzNone must never be exposed as a user storage option.
    }
    TNoReflowTabBarStoredPinZone = (nrbszStart, nrbszCenter, nrbszEnd);

    {
      Set of stored zones.
    }
    TNoReflowTabBarStoredPinZones = Set Of TNoReflowTabBarStoredPinZone;

    {
      Defines how stored data is applied during restoration.

      nrbsmApplyExistingOnly updates only items already present in the bar.
      nrbsmCreateMissing creates missing items when enough identity data is
      available in storage.
      nrbsmReplaceAll replaces the items in the selected storage zones.
    }
    TNoReflowTabBarStorageRestoreMode = (
        nrbsmApplyExistingOnly,
        nrbsmCreateMissing,
        nrbsmReplaceAll
        );

    {
      Logical value type stored in a TNoReflowTabBarStorageEntry.

      A final backend may use this information or ignore it. For example, an INI
      file can store everything as text, while a registry or database backend can
      use the kind to choose a native value type.
    }
    TNoReflowTabBarStorageValueKind = (nrbsvkString, nrbsvkInteger, nrbsvkBoolean, nrbsvkFloat);

    {
      Logical storage entry produced or consumed by NoReflowTabBar.

      Root identifies the bar and allows several bars to share the same storage
      backend. Section groups related values. Name identifies the stored
      property. Kind describes the logical value type. Value contains the
      serialised textual value.
    }
    TNoReflowTabBarStorageEntry = Record
        Root: String;
        Section: String;
        Name: String;
        Kind: TNoReflowTabBarStorageValueKind;
        Value: String;

        {
          Creates and returns a storage entry.
        }
        Class Function Create(
            Const ARoot, ASection, AName: String;
            AKind: TNoReflowTabBarStorageValueKind;
            Const AValue: String): TNoReflowTabBarStorageEntry; Static;
    End;

    {
      Options controlling a storage save or restore operation.

      Parts defines which item properties are involved. Zones defines which
      logical zones are involved. RestoreMode defines how missing or existing
      items are handled. StorageRoot optionally overrides the automatically
      resolved root name.
    }
    TNoReflowTabBarStorageOptions = Record
        Parts: TNoReflowTabBarStorageParts;
        Zones: TNoReflowTabBarStoredPinZones;
        RestoreMode: TNoReflowTabBarStorageRestoreMode;

        {
          Logical storage root.

          When empty, the component automatically uses Owner.Name + '.' + Name
          when possible, otherwise the component Name. This allows several bars
          to be stored in the same file, INI, database, registry or custom
          backend without key collisions.
        }
        StorageRoot: String;

        {
          Returns an option set that stores and restores placement only.

          Typical use case: the application recreates the business items itself
          and the component only restores their order, zones and selection.
        }
        Class Function PlacementOnly: TNoReflowTabBarStorageOptions; Static;

        {
          Returns an option set that stores and restores all supported state.

          Typical use case: the stored state represents the whole bar and
          restoration may replace existing items.
        }
        Class Function FullStorage: TNoReflowTabBarStorageOptions; Static;

        {
          Returns an option set for user layout customisation without item
          recreation.

          Recommended when items already exist in the DFM or are recreated by the
          application. The storage layer should not destroy those items and
          design-time properties such as GlyphIndex, GlyphPosition, ShowGlyph,
          colours, handlers and other static configuration remain owned by the
          DFM or application code.

          This preset restores only:
          - zone and order;
          - visibility;
          - selection.
        }
        Class Function UserLayoutStorage: TNoReflowTabBarStorageOptions; Static;

        {
          Returns an option set that stores placement without selection.
        }
        Class Function PlacementWithoutSelection: TNoReflowTabBarStorageOptions; Static;

        {
          Returns an option set that stores placement and captions.

          This is useful when users can rename items through inline editing.
        }
        Class Function PlacementAndCaptions: TNoReflowTabBarStorageOptions; Static;

        {
          Returns an option set that stores only order and placement in the
          center zone.

          This is useful when Start and End zones contain fixed application
          items.
        }
        Class Function CenterPlacementOnly: TNoReflowTabBarStorageOptions; Static;

        {
          Creates a custom storage option set.

          This helper avoids filling the record fields manually and makes calling
          code more explicit.

          Example:
            Options := TNoReflowTabBarStorageOptions.Custom(
                [nrbspPlacement, nrbspSelection],
                [nrbszCenter],
                nrbsmApplyExistingOnly,
                'FcFiches2.ItemsRub');
        }
        Class Function Custom(
            Const AParts: TNoReflowTabBarStorageParts;
            Const AZones: TNoReflowTabBarStoredPinZones;
            ARestoreMode: TNoReflowTabBarStorageRestoreMode = nrbsmApplyExistingOnly;
            Const AStorageRoot: String = ''): TNoReflowTabBarStorageOptions; Static;
    End;

    {
      In-memory list of logical storage entries.

      This class is mainly used during restoration. A storage backend can fill
      this list from an INI file, database, registry, TStrings instance or any
      other source. The component can then retrieve values by Root, Section and
      Name.
    }
    TNoReflowTabBarStorageEntryList = Class
    Private
        FItems: TList<TNoReflowTabBarStorageEntry>;

        Function GetCount: Integer;
        Function GetItem(AIndex: Integer): TNoReflowTabBarStorageEntry;

    Public
        {
          Creates an empty storage entry list.
        }
        Constructor Create;

        {
          Destroys the internal entry list.
        }
        Destructor Destroy; Override;

        {
          Removes all entries.
        }
        Procedure Clear;

        {
          Adds an already built entry.
        }
        Procedure Add(Const AEntry: TNoReflowTabBarStorageEntry);

        {
          Returns the index of an entry matching Root, Section and Name, or -1
          when no entry exists.
        }
        Function FindIndex(Const ARoot, ASection, AName: String): Integer;

        {
          Returns True when an entry matching Root, Section and Name exists.
        }
        Function Exists(Const ARoot, ASection, AName: String): Boolean;

        {
          Writes a string value to the list.
        }
        Procedure WriteString(Const ARoot, ASection, AName, AValue: String);

        {
          Writes an integer value to the list.
        }
        Procedure WriteInteger(
            Const ARoot, ASection, AName: String;
            AValue: Integer);

        {
          Writes a Boolean value to the list.
        }
        Procedure WriteBoolean(
            Const ARoot, ASection, AName: String;
            AValue: Boolean);

        {
          Writes a floating-point value to the list.
        }
        Procedure WriteFloat(
            Const ARoot, ASection, AName: String;
            AValue: Double);

        {
          Reads a string value from the list, or returns ADefault when the entry
          does not exist.
        }
        Function ReadString(Const ARoot, ASection, AName, ADefault: String): String;

        {
          Reads an integer value from the list, or returns ADefault when the
          entry does not exist or cannot be converted.
        }
        Function ReadInteger(
            Const ARoot, ASection, AName: String;
            ADefault: Integer): Integer;

        {
          Reads a Boolean value from the list, or returns ADefault when the entry
          does not exist or cannot be converted.
        }
        Function ReadBoolean(
            Const ARoot, ASection, AName: String;
            ADefault: Boolean): Boolean;

        {
          Reads a floating-point value from the list, or returns ADefault when
          the entry does not exist or cannot be converted.
        }
        Function ReadFloat(
            Const ARoot, ASection, AName: String;
            ADefault: Double): Double;

        {
          Number of entries currently stored in the list.
        }
        Property Count: Integer Read GetCount;

        {
          Indexed access to stored entries.
        }
        Property Items[AIndex: Integer]: TNoReflowTabBarStorageEntry Read GetItem; Default;
    End;

    {
      Snapshot enumerator over storage entries.

      Typical use:

        Enumerator := ItemsRub.CreateStorageEnumerator(Options);
        Try
            While Enumerator.Next(Entry) Do
                SaveEntry(Entry);
        Finally
            Enumerator.Free;
        End;

      The enumerator works on a snapshot. Modifying the bar items while
      enumeration is in progress does not change the sequence already produced.
    }
    TNoReflowTabBarStorageEnumerator = Class
    Private
        FEntries: TArray<TNoReflowTabBarStorageEntry>;
        FIndex:   Integer;

        Function GetCurrent: TNoReflowTabBarStorageEntry;

    Public
        {
          Creates an enumerator from an entry array snapshot.
        }
        Constructor Create(Const AEntries: TArray<TNoReflowTabBarStorageEntry>);

        {
          Resets the enumerator before the first entry.
        }
        Procedure Reset;

        {
          Moves to the next entry.

          Returns True when Current contains a valid entry.
        }
        Function MoveNext: Boolean;

        {
          Moves to the next entry and returns it through AEntry.

          Returns False when there are no more entries.
        }
        Function Next(Out AEntry: TNoReflowTabBarStorageEntry): Boolean;

        {
          Current entry of the enumerator.
        }
        Property Current: TNoReflowTabBarStorageEntry Read GetCurrent;
    End;

    {
      Storage support layer of the NoReflowTabBar component.

      This class exposes backend-independent save and restore operations. It
      produces and consumes logical storage entries, then provides convenience
      wrappers for TStrings, UTF-8 streams, files and INI files.

      The class intentionally depends on no application-specific storage system.
    }
    TNoReflowTabBarStorageSupport = Class(TNoReflowTabBarDragSupport)
    Protected
        //-----------------------------------------------------------------
        // Logical root
        //-----------------------------------------------------------------

        {
          Resolves the storage root from options or component ownership.
        }
        Function ResolveStorageRoot(Const AOptions: TNoReflowTabBarStorageOptions): String;

        //-----------------------------------------------------------------
        // Zone conversion
        //-----------------------------------------------------------------

        {
          Converts an internal pin zone to a stored zone value.
        }
        Function PinZoneToStorageZone(APinZone: TNoReflowTabBarPinZone): TNoReflowTabBarStoredPinZone;

        {
          Converts a stored zone value back to an internal pin zone.
        }
        Function StorageZoneToPinZone(AZone: TNoReflowTabBarStoredPinZone): TNoReflowTabBarPinZone;

        {
          Returns True when a pin zone participates in the current storage
          options.
        }
        Function IsStorageZoneEnabled(
            APinZone: TNoReflowTabBarPinZone;
            Const AOptions: TNoReflowTabBarStorageOptions): Boolean;

        //-----------------------------------------------------------------
        // Storage sections
        //-----------------------------------------------------------------

        {
          Returns the logical section name used for general bar values.
        }
        Function StorageGeneralSection: String;

        {
          Returns the logical section name used for a stored item index.
        }
        Function StorageItemSection(AStorageIndex: Integer): String;

        //-----------------------------------------------------------------
        // Reading stored item data
        //-----------------------------------------------------------------

        {
          Reads the stored technical item key for a storage item index.
        }
        Function ReadStoredItemKey(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const ARoot: String;
            AStorageIndex: Integer): Integer;

        {
          Restores a stored technical item key on an item.
        }
        Procedure RestoreStoredItemKey(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const ARoot: String;
            AStorageIndex: Integer;
            ATab: TNoReflowTabBarItem);

        {
          Reads the stored application UserId for a storage item index.
        }
        Function ReadStoredItemUserId(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const ARoot: String;
            AStorageIndex: Integer): Integer;

        {
          Reads the stored pin zone for a storage item index.
        }
        Function ReadStoredItemZone(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const ARoot: String;
            AStorageIndex: Integer): TNoReflowTabBarPinZone;

        {
          Reads the stored zone index for a storage item index.
        }
        Function ReadStoredItemZoneIndex(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const ARoot: String;
            AStorageIndex: Integer): Integer;

        {
          Finds the existing item that corresponds to a stored item entry.
        }
        Function FindItemForStorage(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const ARoot: String;
            AStorageIndex: Integer): TNoReflowTabBarItem;

        //-----------------------------------------------------------------
        // Unit save / restore helpers
        //-----------------------------------------------------------------

        {
          Saves simple glyph-related properties for one item.

          This method uses RTTI to avoid depending on the exact GlyphPosition
          type. It saves only published properties available on the item.
        }
        Procedure SaveOneItemGlyphStorage(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const ARoot: String;
            Const ASection: String;
            ATab: TNoReflowTabBarItem);

        {
          Restores simple glyph-related properties for one item.

          Missing properties are ignored to preserve the current item values,
          especially values coming from the DFM.
        }
        Procedure RestoreOneItemGlyphStorage(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const ARoot: String;
            Const ASection: String;
            ATab: TNoReflowTabBarItem);

        {
          Saves one item according to the selected storage options.
        }
        Procedure SaveOneItemStorage(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const ARoot: String;
            AStorageIndex: Integer;
            ATab: TNoReflowTabBarItem;
            Const AOptions: TNoReflowTabBarStorageOptions);

        {
          Restores stored state to one existing item.
        }
        Procedure RestoreOneExistingItemStorage(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const ARoot: String;
            AStorageIndex: Integer;
            ATab: TNoReflowTabBarItem;
            Const AOptions: TNoReflowTabBarStorageOptions);

        {
          Creates a new item from stored data.
        }
        Function CreateItemFromStorage(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const ARoot: String;
            AStorageIndex: Integer;
            Const AOptions: TNoReflowTabBarStorageOptions): TNoReflowTabBarItem;

        //-----------------------------------------------------------------
        // Global restore helpers
        //-----------------------------------------------------------------

        {
          Clears items belonging to the zones involved in the storage options.
        }
        Procedure ClearItemsForStorageZones(Const AOptions: TNoReflowTabBarStorageOptions);

        //-----------------------------------------------------------------
        // TStrings conversion
        //-----------------------------------------------------------------

        {
          Serialises storage entries to a TStrings representation.
        }
        Procedure StorageEntriesToStrings(
            AEntries: TNoReflowTabBarStorageEntryList;
            AStrings: TStrings);

        {
          Parses storage entries from a TStrings representation.
        }
        Procedure StringsToStorageEntries(
            AStrings: TStrings;
            AEntries: TNoReflowTabBarStorageEntryList);

        //-----------------------------------------------------------------
        // INI conversion
        //-----------------------------------------------------------------

        {
          Builds the INI section name corresponding to a storage root and
          logical section.
        }
        Function StorageIniSectionName(
            Const ARoot: String;
            Const ASection: String): String;

        {
          Returns True when an INI section belongs to the specified storage root.
        }
        Function IsStorageIniSectionForRoot(
            Const AIniSectionName: String;
            Const ARoot: String): Boolean;

        {
          Extracts the logical storage section from an INI section name.
        }
        Function StorageSectionFromIniSectionName(
            Const AIniSectionName: String;
            Const ARoot: String): String;

    Public
        //-----------------------------------------------------------------
        // Main entry / enumerator API
        //-----------------------------------------------------------------

        {
          Fills a storage entry list with the requested state.
        }
        Procedure SaveStorageToEntries(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const AOptions: TNoReflowTabBarStorageOptions);

        {
          Restores state from a storage entry list.
        }
        Procedure LoadStorageFromEntries(
            AEntries: TNoReflowTabBarStorageEntryList;
            Const AOptions: TNoReflowTabBarStorageOptions);

        {
          Creates an enumerator over a snapshot of the requested state.
        }
        Function CreateStorageEnumerator(Const AOptions: TNoReflowTabBarStorageOptions): TNoReflowTabBarStorageEnumerator;

        //-----------------------------------------------------------------
        // Convenience wrappers
        //-----------------------------------------------------------------

        {
          Saves the requested state to a TStrings instance.
        }
        Procedure SaveStorageToStrings(
            AStrings: TStrings;
            Const AOptions: TNoReflowTabBarStorageOptions);

        {
          Restores state from a TStrings instance.
        }
        Procedure LoadStorageFromStrings(
            AStrings: TStrings;
            Const AOptions: TNoReflowTabBarStorageOptions);

        {
          Saves the requested state to a UTF-8 stream.
        }
        Procedure SaveStorageToStream(
            AStream: TStream;
            Const AOptions: TNoReflowTabBarStorageOptions);

        {
          Restores state from a UTF-8 stream.
        }
        Procedure LoadStorageFromStream(
            AStream: TStream;
            Const AOptions: TNoReflowTabBarStorageOptions);

        {
          Saves the requested state to a UTF-8 text file.
        }
        Procedure SaveStorageToFile(
            Const AFileName: String;
            Const AOptions: TNoReflowTabBarStorageOptions);

        {
          Restores state from a UTF-8 text file.
        }
        Procedure LoadStorageFromFile(
            Const AFileName: String;
            Const AOptions: TNoReflowTabBarStorageOptions);

        //-----------------------------------------------------------------
        // INI wrappers
        //-----------------------------------------------------------------

        {
          Saves the requested state to a TCustomIniFile.

          When AClearExisting is True, old sections for this bar are removed
          before writing the new state. This avoids keeping obsolete Item.X
          sections when items have been deleted.
        }
        Procedure SaveStorageToIni(
            AIni: TCustomIniFile;
            Const AOptions: TNoReflowTabBarStorageOptions;
            AClearExisting: Boolean = True);

        {
          Restores state from a TCustomIniFile.
        }
        Procedure LoadStorageFromIni(
            AIni: TCustomIniFile;
            Const AOptions: TNoReflowTabBarStorageOptions);

        {
          Saves the requested state to an INI file.
        }
        Procedure SaveStorageToIniFile(
            Const AFileName: String;
            Const AOptions: TNoReflowTabBarStorageOptions;
            AClearExisting: Boolean = True);

        {
          Restores state from an INI file.
        }
        Procedure LoadStorageFromIniFile(
            Const AFileName: String;
            Const AOptions: TNoReflowTabBarStorageOptions);
    End;

Implementation


Const
    cNoReflowStorageGeneralSection = 'General';
    cNoReflowStorageStringsDelimiter = '/';

    //===============================================================================================================================
    //Fonctions utilitaires globales
    //===============================================================================================================================

Function NoReflowStorageValueKindToString(AKind: TNoReflowTabBarStorageValueKind): String;
Begin
    Case AKind Of
        nrbsvkInteger:
            Result := 'Integer';

        nrbsvkBoolean:
            Result := 'Boolean';

        nrbsvkFloat:
            Result := 'Float';
    Else
        Result := 'String';
    End;
End;

Function NoReflowStorageStringToValueKind(Const AValue: String): TNoReflowTabBarStorageValueKind;
Begin
    If SameText(AValue, 'Integer') Then Begin
        Result := nrbsvkInteger;
        Exit;
    End;

    If SameText(AValue, 'Boolean') Then Begin
        Result := nrbsvkBoolean;
        Exit;
    End;

    If SameText(AValue, 'Float') Then Begin
        Result := nrbsvkFloat;
        Exit;
    End;

    Result := nrbsvkString;
End;

Function EncodeNoReflowStorageString(Const AValue: String): String;
Var
    I:  Integer;
    Ch: Char;
Begin
    //-------------------------------------------------------------------------
    //Encode les chaînes pour les rendre sûres dans un format ligne par ligne.
    //
    //Cela évite qu'un Caption ou Hint contenant un retour ligne ne casse
    //une sauvegarde TStrings.
    //
    //Les adaptateurs INI/registre/base peuvent choisir de l'utiliser ou non.
    //-------------------------------------------------------------------------

    Result := '';

    For I := 1 To Length(AValue) Do Begin
        Ch := AValue[I];

        Case Ch Of
            '\':
                Result := Result + '\\';

            #13:
                Result := Result + '\r';

            #10:
                Result := Result + '\n';

            #9:
                Result := Result + '\t';
        Else
            Result := Result + Ch;
        End;
    End;
End;

Function DecodeNoReflowStorageString(Const AValue: String): String;
Var
    I:  Integer;
    Ch: Char;
Begin
    Result := '';
    I := 1;

    While I <= Length(AValue) Do Begin
        Ch := AValue[I];

        If (Ch = '\') And (I < Length(AValue)) Then Begin
            Inc(I);
            Ch := AValue[I];

            Case Ch Of
                '\':
                    Result := Result + '\';

                'r':
                    Result := Result + #13;

                'n':
                    Result := Result + #10;

                't':
                    Result := Result + #9;
            Else
                Result := Result + Ch;
            End;
        End
        Else
            Result := Result + Ch;

        Inc(I);
    End;
End;

Function BoolToNoReflowStorageString(AValue: Boolean): String;
Begin
    Result := BoolToStr(
        AValue,
        True);
End;

Function NoReflowStorageStringToBool(
    Const AValue: String;
    ADefault: Boolean): Boolean;
Begin
    If SameText(AValue, 'True') Or SameText(AValue, '1') Or SameText(AValue, 'Yes') Or SameText(AValue, 'Oui') Then Begin
        Result := True;
        Exit;
    End;

    If SameText(AValue, 'False') Or SameText(AValue, '0') Or SameText(AValue, 'No') Or SameText(AValue, 'Non') Then Begin
        Result := False;
        Exit;
    End;

    Result := ADefault;
End;

Function FloatToNoReflowStorageString(AValue: Double): String;
Var
    FS: TFormatSettings;
Begin
    FS := TFormatSettings.Create;
    FS.DecimalSeparator := '.';

    Result := FloatToStr(
        AValue,
        FS);
End;

Function NoReflowStorageStringToFloat(
    Const AValue: String;
    ADefault: Double): Double;
Var
    FS: TFormatSettings;
Begin
    FS := TFormatSettings.Create;
    FS.DecimalSeparator := '.';

    Result := StrToFloatDef(
        AValue,
        ADefault,
        FS);
End;

Function MakeNoReflowStringsStorageKey(Const ARoot, ASection, AName: String): String;
Begin
    Result := ARoot + cNoReflowStorageStringsDelimiter + ASection + cNoReflowStorageStringsDelimiter + AName;
End;

Function ParseNoReflowStringsStorageKey(
    Const AKey: String;
    Out ARoot, ASection, AName: String): Boolean;
Var
    P1: Integer;
    P2: Integer;
Begin
    Result := False;
    ARoot := '';
    ASection := '';
    AName := '';

    P1 := Pos(
        cNoReflowStorageStringsDelimiter,
        AKey);
    If P1 <= 0 Then
        Exit;

    P2 := Pos(
        cNoReflowStorageStringsDelimiter,
        AKey,
        P1 + Length(cNoReflowStorageStringsDelimiter));

    If P2 <= 0 Then
        Exit;

    ARoot := Copy(
        AKey,
        1,
        P1 - 1);
    ASection := Copy(
        AKey,
        P1 + 1,
        P2 - P1 - 1);
    AName := Copy(
        AKey,
        P2 + 1,
        MaxInt);

    Result := (ARoot <> '') And (ASection <> '') And (AName <> '');
End;

Function TryGetNoReflowOrdProp(
    AObject: TObject;
    Const APropName: String;
    Out AValue: Integer): Boolean;
Var
    PropInfo: PPropInfo;
Begin
    //-------------------------------------------------------------------------
    //Lit une propriété ordinale publiée sans dépendre de son type exact.
    //
    //Utilisation principale :
    //- ShowGlyph       : booléen publié ;
    //- GlyphIndex      : entier publié ;
    //- GlyphPosition   : énumération publiée.
    //
    //Cette approche évite de dépendre ici du nom exact du type d'énumération
    //de GlyphPosition. StorageSupport reste ainsi moins couplé au modèle item.
    //-------------------------------------------------------------------------

    Result := False;
    AValue := 0;

    If AObject = Nil Then
        Exit;

    PropInfo := GetPropInfo(
        AObject.ClassInfo,
        APropName);

    If PropInfo = Nil Then
        Exit;

    Case PropInfo.PropType^.Kind Of
        tkInteger, tkEnumeration: Begin
                AValue := GetOrdProp(
                    AObject,
                    PropInfo);

                Result := True;
            End;
    End;
End;

Function TrySetNoReflowOrdProp(
    AObject: TObject;
    Const APropName: String;
    AValue: Integer): Boolean;
Var
    PropInfo: PPropInfo;
Begin
    //-------------------------------------------------------------------------
    //Affecte une propriété ordinale publiée sans dépendre de son type exact.
    //
    //L'affectation passe par le setter publié de la propriété. Le modèle item
    //conserve donc sa logique interne normale : validation, notification,
    //invalidation du layout, etc.
    //-------------------------------------------------------------------------

    Result := False;

    If AObject = Nil Then
        Exit;

    PropInfo := GetPropInfo(
        AObject.ClassInfo,
        APropName);

    If PropInfo = Nil Then
        Exit;

    Case PropInfo.PropType^.Kind Of
        tkInteger, tkEnumeration: Begin
                SetOrdProp(
                    AObject,
                    PropInfo,
                    AValue);

                Result := True;
            End;
    End;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageEntry
//===============================================================================================================================

Class Function TNoReflowTabBarStorageEntry.Create(
    Const ARoot, ASection, AName: String;
    AKind: TNoReflowTabBarStorageValueKind;
    Const AValue: String): TNoReflowTabBarStorageEntry;
Begin
    Result.Root := ARoot;
    Result.Section := ASection;
    Result.Name := AName;
    Result.Kind := AKind;
    Result.Value := AValue;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageEntryList
//===============================================================================================================================

Constructor TNoReflowTabBarStorageEntryList.Create;
Begin
    Inherited Create;

    FItems := TList<TNoReflowTabBarStorageEntry>.Create;
End;

Destructor TNoReflowTabBarStorageEntryList.Destroy;
Begin
    FItems.Free;

    Inherited Destroy;
End;

Function TNoReflowTabBarStorageEntryList.GetCount: Integer;
Begin
    Result := FItems.Count;
End;

Function TNoReflowTabBarStorageEntryList.GetItem(AIndex: Integer): TNoReflowTabBarStorageEntry;
Begin
    Result := FItems[AIndex];
End;

Procedure TNoReflowTabBarStorageEntryList.Clear;
Begin
    FItems.Clear;
End;

Procedure TNoReflowTabBarStorageEntryList.Add(Const AEntry: TNoReflowTabBarStorageEntry);
Var
    Index: Integer;
Begin
    //-------------------------------------------------------------------------
    //On remplace une entrée déjà présente pour éviter les doublons logiques.
    //C'est utile quand une application remplit la liste par étapes.
    //-------------------------------------------------------------------------

    Index := FindIndex(AEntry.Root, AEntry.Section, AEntry.Name);

    If Index >= 0 Then
        FItems[Index] := AEntry
    Else
        FItems.Add(AEntry);
End;

Function TNoReflowTabBarStorageEntryList.FindIndex(Const ARoot, ASection, AName: String): Integer;
Var
    I:     Integer;
    Entry: TNoReflowTabBarStorageEntry;
Begin
    Result := -1;

    For I := 0 To FItems.Count - 1 Do Begin
        Entry := FItems[I];

        If SameText(Entry.Root, ARoot) And SameText(Entry.Section, ASection) And SameText(Entry.Name, AName) Then Begin
            Result := I;
            Exit;
        End;
    End;
End;

Function TNoReflowTabBarStorageEntryList.Exists(Const ARoot, ASection, AName: String): Boolean;
Begin
    Result := FindIndex(ARoot, ASection, AName) >= 0;
End;

Procedure TNoReflowTabBarStorageEntryList.WriteString(Const ARoot, ASection, AName, AValue: String);
Begin
    Add(TNoReflowTabBarStorageEntry.Create(ARoot, ASection, AName, nrbsvkString, AValue));
End;

Procedure TNoReflowTabBarStorageEntryList.WriteInteger(
    Const ARoot, ASection, AName: String;
    AValue: Integer);
Begin
    Add(TNoReflowTabBarStorageEntry.Create(ARoot, ASection, AName, nrbsvkInteger, IntToStr(AValue)));
End;

Procedure TNoReflowTabBarStorageEntryList.WriteBoolean(
    Const ARoot, ASection, AName: String;
    AValue: Boolean);
Begin
    Add(TNoReflowTabBarStorageEntry.Create(ARoot, ASection, AName, nrbsvkBoolean, BoolToNoReflowStorageString(AValue)));
End;

Procedure TNoReflowTabBarStorageEntryList.WriteFloat(
    Const ARoot, ASection, AName: String;
    AValue: Double);
Begin
    Add(TNoReflowTabBarStorageEntry.Create(ARoot, ASection, AName, nrbsvkFloat, FloatToNoReflowStorageString(AValue)));
End;

Function TNoReflowTabBarStorageEntryList.ReadString(Const ARoot, ASection, AName, ADefault: String): String;
Var
    Index: Integer;
Begin
    Result := ADefault;

    Index := FindIndex(ARoot, ASection, AName);
    If Index >= 0 Then
        Result := FItems[Index].Value;
End;

Function TNoReflowTabBarStorageEntryList.ReadInteger(
    Const ARoot, ASection, AName: String;
    ADefault: Integer): Integer;
Begin
    Result := StrToIntDef(
        ReadString(ARoot, ASection, AName, IntToStr(ADefault)),
        ADefault);
End;

Function TNoReflowTabBarStorageEntryList.ReadBoolean(
    Const ARoot, ASection, AName: String;
    ADefault: Boolean): Boolean;
Begin
    Result := NoReflowStorageStringToBool(
        ReadString(ARoot, ASection, AName, BoolToNoReflowStorageString(ADefault)),
        ADefault);
End;

Function TNoReflowTabBarStorageEntryList.ReadFloat(
    Const ARoot, ASection, AName: String;
    ADefault: Double): Double;
Begin
    Result := NoReflowStorageStringToFloat(
        ReadString(ARoot, ASection, AName, FloatToNoReflowStorageString(ADefault)),
        ADefault);
End;

//===============================================================================================================================
//TNoReflowTabBarStorageEnumerator
//===============================================================================================================================

Constructor TNoReflowTabBarStorageEnumerator.Create(Const AEntries: TArray<TNoReflowTabBarStorageEntry>);
Var
    I: Integer;
Begin
    Inherited Create;

    SetLength(
        FEntries,
        Length(AEntries));

    For I := 0 To High(AEntries) Do
        FEntries[I] := AEntries[I];

    Reset;
End;

Procedure TNoReflowTabBarStorageEnumerator.Reset;
Begin
    FIndex := -1;
End;

Function TNoReflowTabBarStorageEnumerator.GetCurrent: TNoReflowTabBarStorageEntry;
Begin
    If (FIndex < 0) Or (FIndex > High(FEntries)) Then
        Raise EInvalidOperation.Create('Aucune entrée de stockage courante.');

    Result := FEntries[FIndex];
End;

Function TNoReflowTabBarStorageEnumerator.MoveNext: Boolean;
Begin
    Result := FIndex < High(FEntries);

    If Result Then
        Inc(FIndex);
End;

Function TNoReflowTabBarStorageEnumerator.Next(Out AEntry: TNoReflowTabBarStorageEntry): Boolean;
Begin
    Result := MoveNext;

    If Result Then
        AEntry := Current;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageOptions
//===============================================================================================================================

Class Function TNoReflowTabBarStorageOptions.PlacementOnly: TNoReflowTabBarStorageOptions;
Begin
    Result.Parts := [nrbspPlacement, nrbspSelection];

    Result.Zones := [nrbszStart, nrbszCenter, nrbszEnd];

    Result.RestoreMode := nrbsmApplyExistingOnly;
    Result.StorageRoot := '';
End;

Class Function TNoReflowTabBarStorageOptions.FullStorage: TNoReflowTabBarStorageOptions;
Begin
    //-------------------------------------------------------------------------
    //Sauvegarde complète logique.
    //
    //Attention :
    //ce preset reste volontairement destructif à la restauration, car son
    //RestoreMode est nrbsmReplaceAll.
    //
    //Il est donc adapté quand le stockage représente réellement toute la barre.
    //Pour une barre définie dans le DFM, préférer UserLayoutStorage.
    //
    //Depuis l'ajout de nrbspGlyph, FullStorage conserve aussi les glyphes
    //simples issus de BarImages :
    //- ShowGlyph
    //- GlyphIndex
    //- GlyphPosition
    //
    //Les bitmaps locaux éventuellement stockés dans un item ne sont pas encore
    //sérialisés par ce preset.
    //-------------------------------------------------------------------------
    Result.Parts := [nrbspPlacement, nrbspCaption, nrbspVisibility, nrbspEnabled, nrbspSignal, nrbspHint, nrbspGlyph, nrbspChecked, nrbspSelection];

    Result.Zones := [nrbszStart, nrbszCenter, nrbszEnd];

    Result.RestoreMode := nrbsmReplaceAll;
    Result.StorageRoot := '';
End;

Class Function TNoReflowTabBarStorageOptions.UserLayoutStorage: TNoReflowTabBarStorageOptions;
Begin
    //-------------------------------------------------------------------------
    //Preset recommandé pour une barre dont les items sont définis par le DFM
    //ou reconstruits par l'application.
    //
    //Contrairement à FullStorage, ce mode ne remplace pas les items existants.
    //Il applique uniquement l'état utilisateur sur les items retrouvés via :
    //- ItemKey en priorité ;
    //- UserId en fallback.
    //
    //Cela évite de perdre les propriétés de design-time non stockées ou non
    //stockables simplement, notamment les glyphes locaux, les paramètres fins
    //de rendu ou les handlers applicatifs.
    //-------------------------------------------------------------------------
    Result.Parts := [nrbspPlacement, nrbspVisibility, nrbspSelection];

    Result.Zones := [nrbszStart, nrbszCenter, nrbszEnd];

    Result.RestoreMode := nrbsmApplyExistingOnly;
    Result.StorageRoot := '';
End;

Class Function TNoReflowTabBarStorageOptions.PlacementWithoutSelection: TNoReflowTabBarStorageOptions;
Begin
    Result := Custom(
        [nrbspPlacement],
        [nrbszStart, nrbszCenter, nrbszEnd],
        nrbsmApplyExistingOnly,
        '');
End;

Class Function TNoReflowTabBarStorageOptions.PlacementAndCaptions: TNoReflowTabBarStorageOptions;
Begin
    Result := Custom(
        [nrbspPlacement, nrbspCaption, nrbspSelection],
        [nrbszStart, nrbszCenter, nrbszEnd],
        nrbsmApplyExistingOnly,
        '');
End;

Class Function TNoReflowTabBarStorageOptions.CenterPlacementOnly: TNoReflowTabBarStorageOptions;
Begin
    Result := Custom(
        [nrbspPlacement, nrbspSelection],
        [nrbszCenter],
        nrbsmApplyExistingOnly,
        '');
End;

Class Function TNoReflowTabBarStorageOptions.Custom(
    Const AParts: TNoReflowTabBarStorageParts;
    Const AZones: TNoReflowTabBarStoredPinZones;
    ARestoreMode: TNoReflowTabBarStorageRestoreMode = nrbsmApplyExistingOnly;
    Const AStorageRoot: String = ''): TNoReflowTabBarStorageOptions;
Begin
    Result.Parts := AParts;
    Result.Zones := AZones;
    Result.RestoreMode := ARestoreMode;
    Result.StorageRoot := AStorageRoot;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - racine logique
//===============================================================================================================================

Function TNoReflowTabBarStorageSupport.ResolveStorageRoot(Const AOptions: TNoReflowTabBarStorageOptions): String;
Var
    OwnerName: String;
Begin
    Result := Trim(AOptions.StorageRoot);

    If Result <> '' Then
        Exit;

    OwnerName := '';

    If (Owner <> Nil) And (Owner.Name <> '') Then
        OwnerName := Owner.Name;

    If (OwnerName <> '') And (Name <> '') Then Begin
        Result := OwnerName + '.' + Name;
        Exit;
    End;

    If Name <> '' Then Begin
        Result := Name;
        Exit;
    End;

    Result := ClassName;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - conversions de zones
//===============================================================================================================================

Function TNoReflowTabBarStorageSupport.PinZoneToStorageZone(APinZone: TNoReflowTabBarPinZone): TNoReflowTabBarStoredPinZone;
Begin
    Case APinZone Of
        nrtpzStart:
            Result := nrbszStart;

        nrtpzEnd:
            Result := nrbszEnd;
    Else
        Result := nrbszCenter;
    End;
End;

Function TNoReflowTabBarStorageSupport.StorageZoneToPinZone(AZone: TNoReflowTabBarStoredPinZone): TNoReflowTabBarPinZone;
Begin
    Case AZone Of
        nrbszStart:
            Result := nrtpzStart;

        nrbszCenter:
            Result := nrtpzCenter;

        nrbszEnd:
            Result := nrtpzEnd;
    Else
        Result := nrtpzCenter;
    End;
End;

Function TNoReflowTabBarStorageSupport.IsStorageZoneEnabled(
    APinZone: TNoReflowTabBarPinZone;
    Const AOptions: TNoReflowTabBarStorageOptions): Boolean;
Begin
    Case APinZone Of
        nrtpzStart:
            Result := nrbszStart In AOptions.Zones;

        nrtpzCenter:
            Result := nrbszCenter In AOptions.Zones;

        nrtpzEnd:
            Result := nrbszEnd In AOptions.Zones;
    Else
        Result := False;
    End;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - sections
//===============================================================================================================================

Function TNoReflowTabBarStorageSupport.StorageGeneralSection: String;
Begin
    Result := cNoReflowStorageGeneralSection;
End;

Function TNoReflowTabBarStorageSupport.StorageItemSection(AStorageIndex: Integer): String;
Begin
    Result := Format(
        'Item.%d',
        [AStorageIndex]);
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - lecture des données d'un item stocké
//===============================================================================================================================

Function TNoReflowTabBarStorageSupport.ReadStoredItemKey(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const ARoot: String;
    AStorageIndex: Integer): Integer;
Var
    Section: String;
Begin
    Section := StorageItemSection(AStorageIndex);

    Result := AEntries.ReadInteger(
        ARoot,
        Section,
        'ItemKey',
        0);
End;

Procedure TNoReflowTabBarStorageSupport.RestoreStoredItemKey(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const ARoot: String;
    AStorageIndex: Integer;
    ATab: TNoReflowTabBarItem);
Var
    Section: String;
    ItemKey:  Integer;
Begin
    If (AEntries = Nil) Or (ATab = Nil) Then
        Exit;

    Section := StorageItemSection(AStorageIndex);

    If Not AEntries.Exists(ARoot, Section, 'ItemKey') Then
        Exit;

    ItemKey := AEntries.ReadInteger(
        ARoot,
        Section,
        'ItemKey',
        0);

    If ATab.Collection Is TNoReflowTabBarItems Then
        TNoReflowTabBarItems(ATab.Collection).RestoreItemKey(ATab, ItemKey);
End;

Function TNoReflowTabBarStorageSupport.ReadStoredItemUserId(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const ARoot: String;
    AStorageIndex: Integer): Integer;
Var
    Section: String;
Begin
    Section := StorageItemSection(AStorageIndex);

    Result := AEntries.ReadInteger(
        ARoot,
        Section,
        'UserId',
        0);
End;

Function TNoReflowTabBarStorageSupport.ReadStoredItemZone(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const ARoot: String;
    AStorageIndex: Integer): TNoReflowTabBarPinZone;
Var
    Section:     String;
    ZoneName:    String;
    ZoneOrd:     Integer;
    StorageZone: TNoReflowTabBarStoredPinZone;
    TabZoneName: String;
    TabZoneOrd:  Integer;
    UserTabZone: TNoReflowTabBarZone;
Begin
    //-------------------------------------------------------------------------
    //Lit la zone d'un item stocké.
    //
    //Format propre :
    //- nom interne : PinZone = nrbszStart / nrbszCenter / nrbszEnd
    //- format utilisateur : Zone = nrtzStart / nrtzCenter / nrtzEnd
    //
    //En cas d'absence ou d'erreur, on retombe sur la zone centrale.
    //-------------------------------------------------------------------------

    Section := StorageItemSection(AStorageIndex);

    ZoneName := AEntries.ReadString(
        ARoot,
        Section,
        'PinZone',
        '');

    If ZoneName <> '' Then Begin
        ZoneOrd := GetEnumValue(
            TypeInfo(TNoReflowTabBarStoredPinZone),
            ZoneName);

        If ZoneOrd >= 0 Then Begin
            StorageZone := TNoReflowTabBarStoredPinZone(ZoneOrd);
            Result := StorageZoneToPinZone(StorageZone);
            Exit;
        End;
    End;

    TabZoneName := AEntries.ReadString(
        ARoot,
        Section,
        'Zone',
        'nrtzCenter');

    TabZoneOrd := GetEnumValue(
        TypeInfo(TNoReflowTabBarZone),
        TabZoneName);

    If TabZoneOrd >= 0 Then Begin
        UserTabZone := TNoReflowTabBarZone(TabZoneOrd);

        Case UserTabZone Of
            nrtzStart:
                Result := nrtpzStart;

            nrtzCenter:
                Result := nrtpzCenter;

            nrtzEnd:
                Result := nrtpzEnd;
        Else
            Result := nrtpzCenter;
        End;
    End
    Else
        Result := nrtpzCenter;
End;

Function TNoReflowTabBarStorageSupport.ReadStoredItemZoneIndex(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const ARoot: String;
    AStorageIndex: Integer): Integer;
Var
    Section: String;
Begin
    Section := StorageItemSection(AStorageIndex);

    Result := AEntries.ReadInteger(
        ARoot,
        Section,
        'ZoneIndex',
        0);
End;

Function TNoReflowTabBarStorageSupport.FindItemForStorage(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const ARoot: String;
    AStorageIndex: Integer): TNoReflowTabBarItem;
Var
    Section: String;
    ItemKey:  Integer;
    UserId:   Integer;
Begin
    Result := Nil;

    Section := StorageItemSection(AStorageIndex);

    //-------------------------------------------------------------------------
    //Priorité à ItemKey : c'est l'identifiant technique stable.
    //-------------------------------------------------------------------------

    If AEntries.Exists(ARoot, Section, 'ItemKey') Then Begin
        ItemKey := ReadStoredItemKey(
            AEntries,
            ARoot,
            AStorageIndex);

        Result := GetItemByKey(ItemKey);

        If Result <> Nil Then
            Exit;
    End;

    //-------------------------------------------------------------------------
    //Fallback historique / métier par UserId.
    //
    //Important :
    //UserId=0 est ambigu si plusieurs items n'ont pas d'identifiant métier.
    //On évite donc de l'utiliser comme fallback automatique.
    //-------------------------------------------------------------------------

    If Not AEntries.Exists(ARoot, Section, 'UserId') Then
        Exit;

    UserId := AEntries.ReadInteger(
        ARoot,
        Section,
        'UserId',
        0);

    If UserId <> 0 Then
        Result := GetItemByUserId(UserId);
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - sauvegarde unitaire
//===============================================================================================================================

Procedure TNoReflowTabBarStorageSupport.SaveOneItemGlyphStorage(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const ARoot: String;
    Const ASection: String;
    ATab: TNoReflowTabBarItem);
Var
    OrdValue: Integer;
Begin
    //-------------------------------------------------------------------------
    //Sauvegarde des propriétés de glyph simples.
    //
    //On reste volontairement sur des valeurs légères :
    //- ShowGlyph ;
    //- GlyphIndex ;
    //- GlyphPosition.
    //
    //Le bitmap local éventuel n'est pas sérialisé ici.
    //-------------------------------------------------------------------------

    If (AEntries = Nil) Or (ATab = Nil) Then
        Exit;

    If TryGetNoReflowOrdProp(ATab, 'ShowGlyph', OrdValue) Then
        AEntries.WriteBoolean(
            ARoot,
            ASection,
            'ShowGlyph',
            OrdValue <> 0);

    If TryGetNoReflowOrdProp(ATab, 'GlyphIndex', OrdValue) Then
        AEntries.WriteInteger(
            ARoot,
            ASection,
            'GlyphIndex',
            OrdValue);

    If TryGetNoReflowOrdProp(ATab, 'GlyphPosition', OrdValue) Then
        AEntries.WriteInteger(
            ARoot,
            ASection,
            'GlyphPosition',
            OrdValue);
End;

Procedure TNoReflowTabBarStorageSupport.RestoreOneItemGlyphStorage(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const ARoot: String;
    Const ASection: String;
    ATab: TNoReflowTabBarItem);
Var
    OrdValue: Integer;
Begin
    //-------------------------------------------------------------------------
    //Restauration des propriétés de glyph simples.
    //
    //Principe important :
    //si une valeur n'existe pas dans le stockage, on ne touche pas à la valeur
    //courante de l'item.
    //
    //Cela préserve les valeurs DFM et permet une compatibilité douce avec les
    //anciens fichiers INI qui ne contiennent pas encore ces champs.
    //-------------------------------------------------------------------------

    If (AEntries = Nil) Or (ATab = Nil) Then
        Exit;

    If AEntries.Exists(ARoot, ASection, 'ShowGlyph') Then Begin
        If AEntries.ReadBoolean(ARoot, ASection, 'ShowGlyph', True) Then
            OrdValue := 1
        Else
            OrdValue := 0;

        TrySetNoReflowOrdProp(
            ATab,
            'ShowGlyph',
            OrdValue);
    End;

    If AEntries.Exists(ARoot, ASection, 'GlyphIndex') Then Begin
        OrdValue := AEntries.ReadInteger(
            ARoot,
            ASection,
            'GlyphIndex',
            -1);

        TrySetNoReflowOrdProp(
            ATab,
            'GlyphIndex',
            OrdValue);
    End;

    If AEntries.Exists(ARoot, ASection, 'GlyphPosition') Then Begin
        OrdValue := AEntries.ReadInteger(
            ARoot,
            ASection,
            'GlyphPosition',
            0);

        TrySetNoReflowOrdProp(
            ATab,
            'GlyphPosition',
            OrdValue);
    End;
End;

Procedure TNoReflowTabBarStorageSupport.SaveOneItemStorage(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const ARoot: String;
    AStorageIndex: Integer;
    ATab: TNoReflowTabBarItem;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    Section:     String;
    StorageZone: TNoReflowTabBarStoredPinZone;
    UserZone:    TNoReflowTabBarZone;
Begin
    If (AEntries = Nil) Or (ATab = Nil) Then
        Exit;

    Section := StorageItemSection(AStorageIndex);

    AEntries.WriteInteger(
        ARoot,
        Section,
        'ItemKey',
        ATab.ItemKey);

    AEntries.WriteInteger(
        ARoot,
        Section,
        'UserId',
        ATab.UserId);

    If nrbspCaption In AOptions.Parts Then
        AEntries.WriteString(
            ARoot,
            Section,
            'Caption',
            ATab.Caption);

    If nrbspPlacement In AOptions.Parts Then Begin
        StorageZone := PinZoneToStorageZone(ATab.PinZone);
        UserZone := ATab.Zone;

        //Nom interne aligné sur la propriété de modèle PinZone.
        AEntries.WriteString(
            ARoot,
            Section,
            'PinZone',
            GetEnumName(TypeInfo(TNoReflowTabBarStoredPinZone), Ord(StorageZone)));

        //Nom utilisateur plus lisible.
        AEntries.WriteString(
            ARoot,
            Section,
            'Zone',
            GetEnumName(TypeInfo(TNoReflowTabBarZone), Ord(UserZone)));

        AEntries.WriteInteger(
            ARoot,
            Section,
            'ZoneIndex',
            ATab.ZoneIndex);
    End;

    If nrbspVisibility In AOptions.Parts Then
        AEntries.WriteBoolean(
            ARoot,
            Section,
            'Visible',
            ATab.Visible);

    If nrbspEnabled In AOptions.Parts Then
        AEntries.WriteBoolean(
            ARoot,
            Section,
            'Enabled',
            ATab.Enabled);

    If nrbspSignal In AOptions.Parts Then Begin
        AEntries.WriteInteger(
            ARoot,
            Section,
            'SignalCode',
            ATab.SignalCode);

        AEntries.WriteFloat(
            ARoot,
            Section,
            'SignalValue',
            ATab.SignalValue);

        AEntries.WriteFloat(
            ARoot,
            Section,
            'SignalMax',
            ATab.SignalMax);
    End;

    If nrbspChecked In AOptions.Parts Then
        AEntries.WriteBoolean(
            ARoot,
            Section,
            'Checked',
            ATab.Checked);

    If nrbspHint In AOptions.Parts Then Begin
        AEntries.WriteString(
            ARoot,
            Section,
            'Hint',
            ATab.Hint);

        AEntries.WriteBoolean(
            ARoot,
            Section,
            'ShowHint',
            ATab.ShowHint);
    End;

    If nrbspGlyph In AOptions.Parts Then
        SaveOneItemGlyphStorage(
            AEntries,
            ARoot,
            Section,
            ATab);
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - restauration unitaire
//===============================================================================================================================

Procedure TNoReflowTabBarStorageSupport.RestoreOneExistingItemStorage(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const ARoot: String;
    AStorageIndex: Integer;
    ATab: TNoReflowTabBarItem;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    Section:   String;
    PinZone:   TNoReflowTabBarPinZone;
    ZoneIndex: Integer;
Begin
    If (AEntries = Nil) Or (ATab = Nil) Then
        Exit;

    Section := StorageItemSection(AStorageIndex);

    RestoreStoredItemKey(
        AEntries,
        ARoot,
        AStorageIndex,
        ATab);

    If nrbspCaption In AOptions.Parts Then
        ATab.Caption := AEntries.ReadString(
            ARoot,
            Section,
            'Caption',
            ATab.Caption);

    If nrbspVisibility In AOptions.Parts Then
        ATab.Visible := AEntries.ReadBoolean(
            ARoot,
            Section,
            'Visible',
            ATab.Visible);

    If nrbspEnabled In AOptions.Parts Then
        ATab.Enabled := AEntries.ReadBoolean(
            ARoot,
            Section,
            'Enabled',
            ATab.Enabled);

    If nrbspSignal In AOptions.Parts Then Begin
        ATab.SignalCode := AEntries.ReadInteger(
            ARoot,
            Section,
            'SignalCode',
            ATab.SignalCode);

        ATab.SignalValue := AEntries.ReadFloat(
            ARoot,
            Section,
            'SignalValue',
            ATab.SignalValue);

        ATab.SignalMax := AEntries.ReadFloat(
            ARoot,
            Section,
            'SignalMax',
            ATab.SignalMax);
    End;

    If nrbspChecked In AOptions.Parts Then
        ATab.Checked := AEntries.ReadBoolean(
            ARoot,
            Section,
            'Checked',
            ATab.Checked);

    If nrbspHint In AOptions.Parts Then Begin
        ATab.Hint := AEntries.ReadString(
            ARoot,
            Section,
            'Hint',
            ATab.Hint);

        ATab.ShowHint := AEntries.ReadBoolean(
            ARoot,
            Section,
            'ShowHint',
            ATab.ShowHint);
    End;

    If nrbspGlyph In AOptions.Parts Then
        RestoreOneItemGlyphStorage(
            AEntries,
            ARoot,
            Section,
            ATab);

    If nrbspPlacement In AOptions.Parts Then Begin
        PinZone := ReadStoredItemZone(
            AEntries,
            ARoot,
            AStorageIndex);

        ZoneIndex := ReadStoredItemZoneIndex(
            AEntries,
            ARoot,
            AStorageIndex);

        MoveItemToZone(
            ATab,
            PinZone,
            ZoneIndex);
    End;
End;

Function TNoReflowTabBarStorageSupport.CreateItemFromStorage(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const ARoot: String;
    AStorageIndex: Integer;
    Const AOptions: TNoReflowTabBarStorageOptions): TNoReflowTabBarItem;
Var
    Section:    String;
    UserId:      Integer;
    Caption:    String;
    SignalCode: Integer;
    Enabled:    Boolean;
    PinZone:    TNoReflowTabBarPinZone;
    ZoneIndex:  Integer;
Begin
    Result := Nil;

    If AEntries = Nil Then
        Exit;

    Section := StorageItemSection(AStorageIndex);

    UserId := AEntries.ReadInteger(
        ARoot,
        Section,
        'UserId',
        0);

    Caption := AEntries.ReadString(
        ARoot,
        Section,
        'Caption',
        '');

    If Caption = '' Then
        Caption := 'Item';

    SignalCode := AEntries.ReadInteger(
        ARoot,
        Section,
        'SignalCode',
        0);

    Enabled := AEntries.ReadBoolean(
        ARoot,
        Section,
        'Enabled',
        True);

    If nrbspPlacement In AOptions.Parts Then Begin
        PinZone := ReadStoredItemZone(
            AEntries,
            ARoot,
            AStorageIndex);

        ZoneIndex := ReadStoredItemZoneIndex(
            AEntries,
            ARoot,
            AStorageIndex);
    End Else Begin
        PinZone := nrtpzCenter;
        ZoneIndex := GetItemsCountInZone(nrtpzCenter);
    End;

    If Not IsStorageZoneEnabled(PinZone, AOptions) Then
        Exit;

    Result := InsertItemInZone(
        PinZone,
        ZoneIndex,
        Caption,
        SignalCode,
        UserId,
        Enabled);

    If Result = Nil Then
        Exit;

    RestoreOneExistingItemStorage(
        AEntries,
        ARoot,
        AStorageIndex,
        Result,
        AOptions);
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - helpers globaux
//===============================================================================================================================

Procedure TNoReflowTabBarStorageSupport.ClearItemsForStorageZones(Const AOptions: TNoReflowTabBarStorageOptions);
Begin
    If AOptions.Zones = [nrbszStart, nrbszCenter, nrbszEnd] Then Begin
        ClearItems;
        Exit;
    End;

    If nrbszStart In AOptions.Zones Then
        ClearStartItems;

    If nrbszCenter In AOptions.Zones Then
        ClearCenterItems;

    If nrbszEnd In AOptions.Zones Then
        ClearEndItems;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - sauvegarde globale par entrées
//===============================================================================================================================

Procedure TNoReflowTabBarStorageSupport.SaveStorageToEntries(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    I:            Integer;
    StorageIndex: Integer;
    Item:          TNoReflowTabBarItem;
    Root:         String;
    Section:      String;
Begin
    If AEntries = Nil Then
        Exit;

    Root := ResolveStorageRoot(AOptions);
    Section := StorageGeneralSection;

    AEntries.WriteInteger(
        Root,
        Section,
        'Version',
        2);

    AEntries.WriteString(
        Root,
        Section,
        'Root',
        Root);

    StorageIndex := 0;

    For I := 0 To FItems.Count - 1 Do Begin
        Item := FItems[I];

        If Item = Nil Then
            Continue;

        If Not IsStorageZoneEnabled(Item.PinZone, AOptions) Then
            Continue;

        SaveOneItemStorage(
            AEntries,
            Root,
            StorageIndex,
            Item,
            AOptions);

        Inc(StorageIndex);
    End;

    AEntries.WriteInteger(
        Root,
        Section,
        'ItemCount',
        StorageIndex);

    If nrbspSelection In AOptions.Parts Then Begin
        If (FItemIndex >= 0) And (FItemIndex < FItems.Count) Then Begin
            Item := FItems[FItemIndex];

            If Item <> Nil Then
                AEntries.WriteInteger(
                    Root,
                    Section,
                    'SelectedItemKey',
                    Item.ItemKey);
        End;

        AEntries.WriteInteger(
            Root,
            Section,
            'SelectedItemUserId',
            GetBarItemUserId);

        AEntries.WriteInteger(
            Root,
            Section,
            'SelectedItemIndex',
            FItemIndex);
    End;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - restauration globale par entrées
//===============================================================================================================================

Procedure TNoReflowTabBarStorageSupport.LoadStorageFromEntries(
    AEntries: TNoReflowTabBarStorageEntryList;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    I:        Integer;
    ItemCount: Integer;
    Item:      TNoReflowTabBarItem;

    PinZone:       TNoReflowTabBarPinZone;
    SelectedId:    Integer;
    SelectedIndex: Integer;
    Root:          String;
    Section:       String;
    SelectedKey:   Integer;
Begin
    If AEntries = Nil Then
        Exit;

    Root := ResolveStorageRoot(AOptions);
    Section := StorageGeneralSection;

    ItemCount := AEntries.ReadInteger(
        Root,
        Section,
        'ItemCount',
        0);

    If ItemCount <= 0 Then
        Exit;

    FItems.BeginUpdate;
    Try
        Case AOptions.RestoreMode Of
            nrbsmApplyExistingOnly: Begin
                    For I := 0 To ItemCount - 1 Do Begin
                        PinZone := ReadStoredItemZone(
                            AEntries,
                            Root,
                            I);

                        If Not IsStorageZoneEnabled(PinZone, AOptions) Then
                            Continue;

                        Item := FindItemForStorage(
                            AEntries,
                            Root,
                            I);

                        If Item <> Nil Then
                            RestoreOneExistingItemStorage(
                                AEntries,
                                Root,
                                I,
                                Item,
                                AOptions);
                    End;
                End;

            nrbsmCreateMissing: Begin
                    For I := 0 To ItemCount - 1 Do Begin
                        PinZone := ReadStoredItemZone(
                            AEntries,
                            Root,
                            I);

                        If Not IsStorageZoneEnabled(PinZone, AOptions) Then
                            Continue;

                        Item := FindItemForStorage(
                            AEntries,
                            Root,
                            I);

                        If Item <> Nil Then
                            RestoreOneExistingItemStorage(
                                AEntries,
                                Root,
                                I,
                                Item,
                                AOptions)
                        Else Begin
                            //Sans identifiant stocké, CreateMissing recréerait
                            //potentiellement des doublons à chaque chargement.
                            If AEntries.Exists(Root, StorageItemSection(I), 'ItemKey') Or AEntries.Exists(Root, StorageItemSection(I), 'UserId') Then
                                CreateItemFromStorage(
                                    AEntries,
                                    Root,
                                    I,
                                    AOptions);
                        End;
                    End;
                End;

            nrbsmReplaceAll: Begin
                    ClearItemsForStorageZones(AOptions);

                    For I := 0 To ItemCount - 1 Do Begin
                        PinZone := ReadStoredItemZone(
                            AEntries,
                            Root,
                            I);

                        If Not IsStorageZoneEnabled(PinZone, AOptions) Then
                            Continue;

                        CreateItemFromStorage(
                            AEntries,
                            Root,
                            I,
                            AOptions);
                    End;
                End;
        End;
    Finally FItems.EndUpdate;
    End;

    FItems.EnsureUniqueItemsKeys;
    NormalizeItemsOrderByZone;

    If nrbspSelection In AOptions.Parts Then Begin
        If AEntries.Exists(Root, Section, 'SelectedItemKey') Then Begin
            SelectedKey := AEntries.ReadInteger(
                Root,
                Section,
                'SelectedItemKey',
                0);

            Item := GetItemByKey(SelectedKey);

            If Item <> Nil Then Begin
                SetBarCurrentItemIndex(Item.ItemIndex);
                ItemsChanged;
                Exit;
            End;
        End;

        If AEntries.Exists(Root, Section, 'SelectedItemUserId') Then Begin
            SelectedId := AEntries.ReadInteger(
                Root,
                Section,
                'SelectedItemUserId',
                0);

            //UserId=0 est ambigu : on préfère alors retomber sur l'index.
            If SelectedId <> 0 Then Begin
                SelectItemByUserId(SelectedId);
                ItemsChanged;
                Exit;
            End;
        End;

        If AEntries.Exists(Root, Section, 'SelectedItemIndex') Then Begin
            SelectedIndex := AEntries.ReadInteger(
                Root,
                Section,
                'SelectedItemIndex',
                -1);

            If (SelectedIndex >= 0) And (SelectedIndex < FItems.Count) Then
                SetBarCurrentItemIndex(SelectedIndex);
        End;
    End;

    ItemsChanged;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - enumerator
//===============================================================================================================================

Function TNoReflowTabBarStorageSupport.CreateStorageEnumerator(Const AOptions: TNoReflowTabBarStorageOptions): TNoReflowTabBarStorageEnumerator;
Var
    Entries: TNoReflowTabBarStorageEntryList;
    Items:   TArray<TNoReflowTabBarStorageEntry>;
    I:       Integer;
Begin
    Entries := TNoReflowTabBarStorageEntryList.Create;
    Try
        SaveStorageToEntries(
            Entries,
            AOptions);

        SetLength(
            Items,
            Entries.Count);

        For I := 0 To Entries.Count - 1 Do
            Items[I] := Entries[I];

        Result := TNoReflowTabBarStorageEnumerator.Create(Items);
    Finally Entries.Free;
    End;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - conversion TStrings
//===============================================================================================================================

Procedure TNoReflowTabBarStorageSupport.StorageEntriesToStrings(
    AEntries: TNoReflowTabBarStorageEntryList;
    AStrings: TStrings);
Var
    I:     Integer;
    Entry: TNoReflowTabBarStorageEntry;
    Key:   String;
Begin
    If (AEntries = Nil) Or (AStrings = Nil) Then
        Exit;

    AStrings.BeginUpdate;
    Try
        AStrings.Clear;

        For I := 0 To AEntries.Count - 1 Do Begin
            Entry := AEntries[I];

            Key := MakeNoReflowStringsStorageKey(
                Entry.Root,
                Entry.Section,
                Entry.Name);

            AStrings.Values[Key] := EncodeNoReflowStorageString(Entry.Value);
        End;
    Finally AStrings.EndUpdate;
    End;
End;

Procedure TNoReflowTabBarStorageSupport.StringsToStorageEntries(
    AStrings: TStrings;
    AEntries: TNoReflowTabBarStorageEntryList);
Var
    I:       Integer;
    Key:     String;
    Root:    String;
    Section: String;
    Name:    String;
    Value:   String;
    Entry:   TNoReflowTabBarStorageEntry;
Begin
    If (AStrings = Nil) Or (AEntries = Nil) Then
        Exit;

    AEntries.Clear;

    For I := 0 To AStrings.Count - 1 Do Begin
        Key := AStrings.Names[I];

        If Key = '' Then
            Continue;

        If Not ParseNoReflowStringsStorageKey(Key, Root, Section, Name) Then
            Continue;

        Value := DecodeNoReflowStorageString(AStrings.ValueFromIndex[I]);

        Entry := TNoReflowTabBarStorageEntry.Create(
            Root,
            Section,
            Name,
            nrbsvkString,
            Value);

        AEntries.Add(Entry);
    End;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - wrappers TStrings
//===============================================================================================================================

Procedure TNoReflowTabBarStorageSupport.SaveStorageToStrings(
    AStrings: TStrings;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    Entries: TNoReflowTabBarStorageEntryList;
Begin
    If AStrings = Nil Then
        Exit;

    Entries := TNoReflowTabBarStorageEntryList.Create;
    Try
        SaveStorageToEntries(
            Entries,
            AOptions);

        StorageEntriesToStrings(
            Entries,
            AStrings);
    Finally Entries.Free;
    End;
End;

Procedure TNoReflowTabBarStorageSupport.LoadStorageFromStrings(
    AStrings: TStrings;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    Entries: TNoReflowTabBarStorageEntryList;
Begin
    If AStrings = Nil Then
        Exit;

    Entries := TNoReflowTabBarStorageEntryList.Create;
    Try
        StringsToStorageEntries(
            AStrings,
            Entries);

        LoadStorageFromEntries(
            Entries,
            AOptions);
    Finally Entries.Free;
    End;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - stream / fichier
//===============================================================================================================================

Procedure TNoReflowTabBarStorageSupport.SaveStorageToStream(
    AStream: TStream;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    SL: TStringList;
Begin
    If AStream = Nil Then
        Exit;

    SL := TStringList.Create;
    Try
        SaveStorageToStrings(
            SL,
            AOptions);

        SL.SaveToStream(
            AStream,
            TEncoding.UTF8);
    Finally SL.Free;
    End;
End;

Procedure TNoReflowTabBarStorageSupport.LoadStorageFromStream(
    AStream: TStream;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    SL: TStringList;
Begin
    If AStream = Nil Then
        Exit;

    SL := TStringList.Create;
    Try
        SL.LoadFromStream(
            AStream,
            TEncoding.UTF8);

        LoadStorageFromStrings(
            SL,
            AOptions);
    Finally SL.Free;
    End;
End;

Procedure TNoReflowTabBarStorageSupport.SaveStorageToFile(
    Const AFileName: String;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    Stream: TFileStream;
Begin
    Stream := TFileStream.Create(
        AFileName,
        fmCreate);
    Try SaveStorageToStream(
            Stream,
            AOptions);
    Finally Stream.Free;
    End;
End;

Procedure TNoReflowTabBarStorageSupport.LoadStorageFromFile(
    Const AFileName: String;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    Stream: TFileStream;
Begin
    If Not FileExists(AFileName) Then
        Exit;

    Stream := TFileStream.Create(
        AFileName,
        fmOpenRead Or fmShareDenyWrite);
    Try LoadStorageFromStream(
            Stream,
            AOptions);
    Finally Stream.Free;
    End;
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - conversion INI
//===============================================================================================================================

Function TNoReflowTabBarStorageSupport.StorageIniSectionName(
    Const ARoot: String;
    Const ASection: String): String;
Begin
    //-------------------------------------------------------------------------
    //Nom de section INI.
    //
    //Exemple :
    //Root    = FrmItemBtn.TabBar1
    //Section = General
    //
    //Donne :
    //[FrmItemBtn.TabBar1.General]
    //
    //Cela permet de stocker plusieurs TabBar dans le même fichier INI.
    //-------------------------------------------------------------------------

    If ASection = '' Then
        Result := ARoot
    Else
        Result := ARoot + '.' + ASection;
End;

Function TNoReflowTabBarStorageSupport.IsStorageIniSectionForRoot(
    Const AIniSectionName: String;
    Const ARoot: String): Boolean;
Var
    Prefix: String;
Begin
    Prefix := ARoot + '.';

    Result := SameText(AIniSectionName, ARoot) Or SameText(Copy(AIniSectionName, 1, Length(Prefix)), Prefix);
End;

Function TNoReflowTabBarStorageSupport.StorageSectionFromIniSectionName(
    Const AIniSectionName: String;
    Const ARoot: String): String;
Var
    Prefix: String;
Begin
    Result := '';

    If SameText(AIniSectionName, ARoot) Then
        Exit;

    Prefix := ARoot + '.';

    If SameText(Copy(AIniSectionName, 1, Length(Prefix)), Prefix) Then
        Result := Copy(
            AIniSectionName,
            Length(Prefix) + 1,
            MaxInt);
End;

//===============================================================================================================================
//TNoReflowTabBarStorageSupport - wrappers INI
//===============================================================================================================================

Procedure TNoReflowTabBarStorageSupport.SaveStorageToIni(
    AIni: TCustomIniFile;
    Const AOptions: TNoReflowTabBarStorageOptions;
    AClearExisting: Boolean);
Var
    Entries:    TNoReflowTabBarStorageEntryList;
    Sections:   TStringList;
    Entry:      TNoReflowTabBarStorageEntry;
    I:          Integer;
    Root:       String;
    IniSection: String;
Begin
    If AIni = Nil Then
        Exit;

    Root := ResolveStorageRoot(AOptions);

    Entries := TNoReflowTabBarStorageEntryList.Create;
    Sections := TStringList.Create;
    Try
        SaveStorageToEntries(
            Entries,
            AOptions);

        //Nettoyage préalable des sections de cette TabBar.
        //
        //Important :
        //si des items ont été supprimés, d'anciennes sections Item.X
        //pourraient sinon rester dans le fichier.
        If AClearExisting Then Begin
            AIni.ReadSections(Sections);

            For I := 0 To Sections.Count - 1 Do Begin
                If IsStorageIniSectionForRoot(Sections[I], Root) Then
                    AIni.EraseSection(Sections[I]);
            End;
        End;

        For I := 0 To Entries.Count - 1 Do Begin
            Entry := Entries[I];

            IniSection := StorageIniSectionName(
                Entry.Root,
                Entry.Section);

            AIni.WriteString(
                IniSection,
                Entry.Name,
                Entry.Value);
        End;

        AIni.UpdateFile;
    Finally
        Sections.Free;
        Entries.Free;
    End;
End;

Procedure TNoReflowTabBarStorageSupport.LoadStorageFromIni(
    AIni: TCustomIniFile;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    Entries:        TNoReflowTabBarStorageEntryList;
    Sections:       TStringList;
    Values:         TStringList;
    I:              Integer;
    J:              Integer;
    Root:           String;
    IniSection:     String;
    StorageSection: String;
    PropName:       String;
    PropValue:      String;
    Entry:          TNoReflowTabBarStorageEntry;
Begin
    If AIni = Nil Then
        Exit;

    Root := ResolveStorageRoot(AOptions);

    Entries := TNoReflowTabBarStorageEntryList.Create;
    Sections := TStringList.Create;
    Values := TStringList.Create;
    Try
        AIni.ReadSections(Sections);

        For I := 0 To Sections.Count - 1 Do Begin
            IniSection := Sections[I];

            If Not IsStorageIniSectionForRoot(IniSection, Root) Then
                Continue;

            StorageSection := StorageSectionFromIniSectionName(
                IniSection,
                Root);

            If StorageSection = '' Then
                Continue;

            Values.Clear;

            AIni.ReadSectionValues(
                IniSection,
                Values);

            For J := 0 To Values.Count - 1 Do Begin
                PropName := Values.Names[J];

                If PropName = '' Then
                    Continue;

                PropValue := Values.ValueFromIndex[J];

                Entry := TNoReflowTabBarStorageEntry.Create(
                    Root,
                    StorageSection,
                    PropName,
                    nrbsvkString,
                    PropValue);

                Entries.Add(Entry);
            End;
        End;

        LoadStorageFromEntries(
            Entries,
            AOptions);
    Finally
        Values.Free;
        Sections.Free;
        Entries.Free;
    End;
End;

Procedure TNoReflowTabBarStorageSupport.SaveStorageToIniFile(
    Const AFileName: String;
    Const AOptions: TNoReflowTabBarStorageOptions;
    AClearExisting: Boolean);
Var
    Ini: TMemIniFile;
Begin
    Ini := TMemIniFile.Create(AFileName);
    Try
        SaveStorageToIni(
            Ini,
            AOptions,
            AClearExisting);
    Finally
        Ini.Free;
    End;
End;

Procedure TNoReflowTabBarStorageSupport.LoadStorageFromIniFile(
    Const AFileName: String;
    Const AOptions: TNoReflowTabBarStorageOptions);
Var
    Ini: TMemIniFile;
Begin
    If Not FileExists(AFileName) Then
        Exit;

    Ini := TMemIniFile.Create(AFileName);
    Try
        LoadStorageFromIni(
            Ini,
            AOptions);
    Finally
        Ini.Free;
    End;
End;

End.


