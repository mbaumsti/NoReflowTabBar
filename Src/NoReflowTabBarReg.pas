Unit NoReflowTabBarReg;

{
  NoReflowTabBarReg.pas

  NoReflowTabBar
  Copyright (c) 2026 Marc BAUMSTIMLER

  Design-time registration unit for the NoReflowTabBar VCL component.

  Repository:
    https://github.com/mbaumsti/NoReflowTabBar

  License:
    Mozilla Public License 2.0.
    See LICENSE file.

  ------------------------------------------------------------------------------

  Design-time registration unit for the NoReflowTabBar component.

  This unit provides:
  - registration of the component in the Delphi component palette;
  - specialised property editors;
  - collection editors for BarItems and BarSignals;
  - protection of built-in system signals;
  - synchronisation of collection editor selection with the Delphi designer.

  Notes:
  - this unit is intended for the design-time package only;
  - it must not be linked into the runtime package;
  - it does not modify the runtime behaviour or business logic of the component.
}


Interface

Uses
    System.Classes,
    vcl.ComCtrls,
    vcl.Graphics,
    DesignIntf,
    DesignEditors,
    VCLEditors,
    ColnEdit,
    NoReflowTabBar,
    NoreflowTabBar_Library,
    NoReflowTabBar_Items,
    System.SysUtils;

Type
    {
      Property editor used for TNoReflowTabBarItem.SignalName.

      It exposes the available signal names as a design-time value list so item
      signals can be selected by readable name instead of by numeric code.
    }
    TNoReflowTabBarItemSignalNameProperty = Class(TStringProperty)
    public
        {
          Returns the design-time attributes of the property editor.
        }
        Function GetAttributes: TPropertyAttributes; override;

        {
          Enumerates all signal names available in the owning component.
        }
        Procedure GetValues(Proc: TGetStrProc); override;
    End;

    {
      Property editor used for signal codes.

      It protects reserved built-in signal codes from accidental modification at
      design time.
    }
    TNoReflowTabBarSignalCodeProperty = Class(TIntegerProperty)
    public
        {
          Returns the design-time attributes of the property editor.
        }
        Function GetAttributes: TPropertyAttributes; override;
    End;

    {
      Collection editor used for BarItems.

      The standard collection editor physically moves collection items when Add,
      Move Up or Move Down are used. NoReflowTabBar maintains a logical zone
      order based on PinZone and ZoneIndex, so those actions must be routed
      through the component business API instead.
    }
    TNoReflowTabBarItemsEditor = Class(TCollectionEditor)
    private
        {
          Custom handler for the Add button.

          The standard editor first creates the item. The editor then finds the
          item that was actually added and forces the Delphi designer selection
          to that object, even if the component immediately moved it inside the
          collection to preserve Start / Center / End ordering.
        }
        Procedure AddClickAndReselect(Sender: TObject);

        {
          Custom handler for the Move Up button.

          This deliberately avoids the standard physical collection move. The
          item is moved through the component API so zone ordering remains
          coherent.
        }
        Procedure MoveUpClickAndReselect(Sender: TObject);

        {
          Custom handler for the Move Down button.

          The move is routed through the component API rather than through a
          direct physical collection index change.
        }
        Procedure MoveDownClickAndReselect(Sender: TObject);

        {
          Forces design-time selection of a persistent object and resynchronises
          the collection editor.
        }
        Procedure SelectPersistentInDesigner(APersistent: TPersistent);

        {
          Finds the collection item that did not exist in a previous snapshot.
        }
        Function FindNewItem(AOldItems: TList): TCollectionItem;

        {
          Returns the currently selected collection editor item, typed as
          TNoReflowTabBarItem when possible.
        }
        Function GetSelectedItem: TNoReflowTabBarItem;
    protected
        {
          Hook used to replace selected actions of the standard collection
          editor.

          Replaced actions:
          - Add;
          - Move Up;
          - Move Down.

          This keeps design-time behaviour consistent with the component logical
          item model.
        }
        Procedure Loaded; override;
    End;

    {
      Collection editor used for BarSignals.

      It keeps built-in signal definitions protected while allowing custom
      signals to be added and edited at design time.
    }
    TNoReflowTabBarSignalsEditor = Class(TCollectionEditor)
    private
        {
          Custom Add handler that creates a signal and reselects it in the
          designer.
        }
        Procedure AddClickAndReselect(Sender: TObject);

        {
          Custom Delete handler that prevents deletion of built-in signals and
          keeps selection synchronised after deletion.
        }
        Procedure DeleteClickAndReselect(Sender: TObject);

        {
          Custom Move Up handler that prevents moving protected built-in signals
          in an invalid way.
        }
        Procedure MoveUpClickAndReselect(Sender: TObject);

        {
          Custom Move Down handler that prevents moving protected built-in
          signals in an invalid way.
        }
        Procedure MoveDownClickAndReselect(Sender: TObject);

        {
          Forces design-time selection of a persistent object and resynchronises
          the collection editor.
        }
        Procedure SelectPersistentInDesigner(APersistent: TPersistent);

        {
          Returns the currently selected signal definition, when possible.
        }
        Function GetSelectedSignal: TNoReflowTabBarSignalDef;

        {
          Returns True when the signal definition is one of the built-in system
          signals.
        }
        Function IsBuiltInSignal(ASignal: TNoReflowTabBarSignalDef): Boolean;

        {
          Returns the next available non-reserved signal code for a new custom
          signal.
        }
        Function GetNextAvailableSignalCode: Integer;
    protected
        {
          Hook used to replace selected actions of the standard collection
          editor so built-in signals remain protected.
        }
        Procedure Loaded; override;
    End;

    {
      Collection property editor used to open the custom BarSignals editor.
    }
    TNoReflowTabBarSignalsProperty = Class(TCollectionProperty)
    public
        {
          Opens the custom signal collection editor.
        }
        Procedure Edit; override;

        {
          Returns the design-time attributes of the property editor.
        }
        Function GetAttributes: TPropertyAttributes; override;
    End;

    {
      Collection property editor used to open the custom BarItems editor.
    }
    TNoReflowTabBarItemsProperty = Class(TCollectionProperty)
    public
        {
          Opens the custom item collection editor.
        }
        Procedure Edit; override;

        {
          Returns the design-time attributes of the property editor.
        }
        Function GetAttributes: TPropertyAttributes; override;
    End;

{
  Registers the NoReflowTabBar component and its design-time property editors.
}
Procedure Register;

Implementation


Function GetTabBarFromOwnedCollection(ACollection: TOwnedCollection): TNoReflowTabBar;
Begin
    Result := Nil;

    If ACollection = Nil Then
        Exit;

    If ACollection.Owner Is TNoReflowTabBar Then
        Result := TNoReflowTabBar(ACollection.Owner);
End;

Function GetTabBarFromTabItem(AItem: TNoReflowTabBarItem): TNoReflowTabBar;
Begin
    Result := Nil;

    If AItem = Nil Then
        Exit;

    If AItem.Collection Is TNoReflowTabBarItems Then
        Result := GetTabBarFromOwnedCollection(TNoReflowTabBarItems(AItem.Collection));
End;

Function GetTabBarFromSignalDef(ASignal: TNoReflowTabBarSignalDef): TNoReflowTabBar;
Begin
    Result := Nil;

    If ASignal = Nil Then
        Exit;

    If ASignal.Collection Is TNoReflowTabBarSignalDefs Then
        Result := GetTabBarFromOwnedCollection(TNoReflowTabBarSignalDefs(ASignal.Collection));
End;

//===============================================================================================================================
// TNoReflowTabBarItemSignalNameProperty
//===============================================================================================================================

Function TNoReflowTabBarItemSignalNameProperty.GetAttributes: TPropertyAttributes;
Begin
    Result := [paValueList, paSortList];
End;

Procedure TNoReflowTabBarItemSignalNameProperty.GetValues(Proc: TGetStrProc);
Var
    LItem: TPersistent;
    LBarItem: TNoReflowTabBarItem;
    LTabBar: TNoReflowTabBar;
    I: Integer;
Begin
    // -------------------------------------------------------------------------
    // Alimente la liste déroulante de la propriété SignalName
    // à partir de la collection BarSignals du composant propriétaire.
    // -------------------------------------------------------------------------

    LItem := GetComponent(0);

    If Not (LItem Is TNoReflowTabBarItem) Then
        Exit;

    LBarItem := TNoReflowTabBarItem(LItem);
    LTabBar := GetTabBarFromTabItem(LBarItem);

    If LTabBar = Nil Then
        Exit;

    For I := 0 To LTabBar.BarSignals.Count - 1 Do
        Proc(LTabBar.BarSignals[I].Name);
End;

//===============================================================================================================================
// TNoReflowTabBarSignalCodeProperty
//===============================================================================================================================

Function TNoReflowTabBarSignalCodeProperty.GetAttributes: TPropertyAttributes;
Var
    LItem: TPersistent;
    LSignal: TNoReflowTabBarSignalDef;
Begin
    Result := Inherited GetAttributes;

    LItem := GetComponent(0);
    If LItem Is TNoReflowTabBarSignalDef Then Begin
        LSignal := TNoReflowTabBarSignalDef(LItem);

        // Les voyants système 1..4 restent visibles,
        // mais leur code ne doit pas être modifiable.
        If LSignal.Code In [
            nrtSignalGray,
            nrtSignalGreen,
            nrtSignalOrange,
            nrtSignalRed
            ] Then
            Result := Result + [paReadOnly];
    End;
End;

//===============================================================================================================================
// TNoReflowTabBarItemsEditor
//===============================================================================================================================

Procedure TNoReflowTabBarItemsEditor.Loaded;
Begin
    Inherited;

    // -------------------------------------------------------------------------
    // L'éditeur standard de collection sélectionne classiquement
    // le dernier item visible après un ajout.
    //
    // Dans notre cas, ce comportement devient faux dès que le composant
    // déplace immédiatement le nouvel item pour respecter la structure
    // logique de ses zones.
    //
    // On remplace donc l'action Add standard par notre propre gestionnaire.
    //
    // Même problème pour Move Up / Move Down :
    // le déplacement physique standard par index n'est plus compatible
    // avec le modèle logique du composant, basé sur :
    // - PinZone
    // - ZoneIndex
    //
    // On remplace donc aussi ces deux actions.
    // -------------------------------------------------------------------------
    If AddCmd <> Nil Then
        AddCmd.OnExecute := AddClickAndReselect;

    If MoveUpCmd <> Nil Then
        MoveUpCmd.OnExecute := MoveUpClickAndReselect;

    If MoveDownCmd <> Nil Then
        MoveDownCmd.OnExecute := MoveDownClickAndReselect;
End;

Function TNoReflowTabBarItemsEditor.FindNewItem(AOldItems: TList): TCollectionItem;
Var
    I: Integer;
    LItem: TCollectionItem;
Begin
    // -------------------------------------------------------------------------
    // Recherche l'objet nouvellement créé en comparant :
    // - la liste des objets avant ajout
    // - la collection après ajout
    //
    // On ne se base pas sur l'index, car justement le composant
    // peut déplacer immédiatement l'item.
    // -------------------------------------------------------------------------

    Result := Nil;

    If Collection = Nil Then
        Exit;

    For I := 0 To Collection.Count - 1 Do Begin
        LItem := Collection.Items[I];
        If AOldItems.IndexOf(LItem) < 0 Then Begin
            Result := LItem;
            Exit;
        End;
    End;
End;

Function TNoReflowTabBarItemsEditor.GetSelectedItem: TNoReflowTabBarItem;
Var
    LSelection: IDesignerSelections;
    LPersistent: TPersistent;
Begin
    // -------------------------------------------------------------------------
    // Retourne l'objet actuellement sélectionné dans l'éditeur de collection.
    //
    // On ne passe pas par GetCurrentListItem, car cette méthode n'est pas
    // disponible sur toutes les versions de Delphi / tous les TCollectionEditor.
    //
    // On récupère donc la sélection courante du designer, puis on prend
    // le premier objet sélectionné s'il s'agit bien d'un TNoReflowTabBarItem.
    // -------------------------------------------------------------------------

    Result := Nil;

    If Designer = Nil Then
        Exit;

    LSelection := CreateSelectionList;
    Designer.GetSelections(LSelection);

    If (LSelection = Nil) Or (LSelection.Count = 0) Then
        Exit;

    LPersistent := LSelection[0];
    If LPersistent Is TNoReflowTabBarItem Then
        Result := TNoReflowTabBarItem(LPersistent);
End;




Procedure TNoReflowTabBarItemsEditor.SelectPersistentInDesigner(APersistent: TPersistent);
Var
    LItem: TCollectionItem;
    LIndex: Integer;
Begin
    If (APersistent = Nil) Or Not (APersistent Is TCollectionItem) Then
        Exit;

    LItem := TCollectionItem(APersistent);

    // Recrée la liste visuelle à partir de l'état courant de la collection.
    UpdateListbox;

    LIndex := LItem.Index;
    If (LIndex < 0) Or (LIndex >= ListView1.Items.Count) Then
        Exit;

    // Très important :
    // pendant qu'on manipule la sélection visuelle, on bloque la synchro
    // interne du CollectionEditor pour éviter qu'il remette l'ancienne sélection.
    LockState;
    Try
        SelectNone(False);

        ListView1.Items[LIndex].Selected := True;
        ListView1.ItemFocused := ListView1.Items[LIndex];
        ListView1.Items[LIndex].MakeVisible(False);
    Finally
        UnlockState;
    End;

    // Point clé :
    // on pousse ensuite la sélection du ListView vers le designer
    // en passant par l'API interne du CollectionEditor.
    SetSelection;
End;



Procedure TNoReflowTabBarItemsEditor.AddClickAndReselect(Sender: TObject);
Var
    LTabBar: TNoReflowTabBar;
    LNewItem: TNoReflowTabBarItem;
Begin
    If (Collection <> Nil) And (Collection Is TNoReflowTabBarItems) Then
        LTabBar := GetTabBarFromOwnedCollection(TNoReflowTabBarItems(Collection))
    Else
        LTabBar := Nil;

    If LTabBar = Nil Then Begin
        Inherited AddClick(Sender);
        Exit;
    End;

    LNewItem := LTabBar.AddCenterItem('Item', 0);
    If LNewItem = Nil Then
        Exit;

    If Designer <> Nil Then
        Designer.Modified;

    SelectPersistentInDesigner(LNewItem);
    ListView1.SetFocus;
End;

Procedure TNoReflowTabBarItemsEditor.MoveUpClickAndReselect(Sender: TObject);
Var
    LItem: TNoReflowTabBarItem;
    LTabBar: TNoReflowTabBar;
Begin
    // -------------------------------------------------------------------------
    // Déplace l'item sélectionné d'un cran vers le début de sa zone logique.
    //
    // Point essentiel :
    // on n'utilise pas le déplacement standard de TCollectionEditor,
    // car celui-ci agit sur l'index physique brut de la collection.
    //
    // Or notre composant reconstruit ensuite son ordre selon :
    // - PinZone
    // - ZoneIndex
    //
    // Si on laissait l'éditeur standard agir, le déplacement visuel
    // serait annulé ou deviendrait incohérent.
    // -------------------------------------------------------------------------

    LItem := GetSelectedItem;
    If LItem = Nil Then
        Exit;

    LTabBar := GetTabBarFromTabItem(LItem);
    If LTabBar = Nil Then
        Exit;

    LTabBar.MoveItemPriorInZone(LItem);

    If Designer <> Nil Then
        Designer.Modified;

    UpdateListbox;
    SelectPersistentInDesigner(LItem);
End;

Procedure TNoReflowTabBarItemsEditor.MoveDownClickAndReselect(Sender: TObject);
Var
    LItem: TNoReflowTabBarItem;
    LTabBar: TNoReflowTabBar;
Begin
    // -------------------------------------------------------------------------
    // Déplace l'item sélectionné d'un cran vers la fin de sa zone logique.
    //
    // Même logique que pour MoveUpClickAndReselect :
    // le déplacement doit impérativement passer par l'API métier
    // du composant pour rester compatible avec l'ordre logique
    // Start / Center / End + ZoneIndex.
    // -------------------------------------------------------------------------

    LItem := GetSelectedItem;
    If LItem = Nil Then
        Exit;

    LTabBar := GetTabBarFromTabItem(LItem);
    If LTabBar = Nil Then
        Exit;

    LTabBar.MoveItemNextInZone(LItem);

    If Designer <> Nil Then
        Designer.Modified;

    UpdateListbox;
    SelectPersistentInDesigner(LItem);
End;

//===============================================================================================================================
// TNoReflowTabBarItemsProperty
//===============================================================================================================================

Function TNoReflowTabBarItemsProperty.GetAttributes: TPropertyAttributes;
Begin
    // -------------------------------------------------------------------------
    // Ajoute paDialog pour permettre l'ouverture de l'éditeur spécialisé
    // de collection depuis l'inspecteur d'objets.
    // -------------------------------------------------------------------------
    Result := Inherited GetAttributes + [paDialog];
End;

Procedure TNoReflowTabBarItemsProperty.Edit;
Begin
    // -------------------------------------------------------------------------
    // Ouvre notre éditeur de collection spécialisé à la place
    // de l'éditeur standard.
    //
    // Cet éditeur spécialisé ne change pas le fonctionnement général
    // de l'IDE, mais corrige le comportement de sélection après ajout
    // et de déplacement logique pour la collection d'items du composant.
    // -------------------------------------------------------------------------
    ShowCollectionEditorClass(
        Designer,
        TNoReflowTabBarItemsEditor,
        GetComponent(0) As TComponent,
        TCollection(GetOrdValue),
        GetName,
        [coAdd, coDelete, coMove]
        );
End;

//===============================================================================================================================
// TNoReflowTabBarSignalsProperty
//===============================================================================================================================

Function TNoReflowTabBarSignalsProperty.GetAttributes: TPropertyAttributes;
Begin
    Result := Inherited GetAttributes + [paDialog];
End;

Procedure TNoReflowTabBarSignalsProperty.Edit;
Begin
    ShowCollectionEditorClass(
        Designer,
        TNoReflowTabBarSignalsEditor,
        GetComponent(0) As TComponent,
        TCollection(GetOrdValue),
        GetName,
        [coAdd, coDelete, coMove]
        );
End;


//===============================================================================================================================
// TNoReflowTabBarSignalsEditor
//===============================================================================================================================

Procedure TNoReflowTabBarSignalsEditor.Loaded;
Begin
    Inherited;

    If AddCmd <> Nil Then
        AddCmd.OnExecute := AddClickAndReselect;

    If DeleteCmd <> Nil Then
        DeleteCmd.OnExecute := DeleteClickAndReselect;

    If MoveUpCmd <> Nil Then
        MoveUpCmd.OnExecute := MoveUpClickAndReselect;

    If MoveDownCmd <> Nil Then
        MoveDownCmd.OnExecute := MoveDownClickAndReselect;
End;

Function TNoReflowTabBarSignalsEditor.IsBuiltInSignal(ASignal: TNoReflowTabBarSignalDef): Boolean;
Begin
    Result := False;

    If ASignal = Nil Then
        Exit;

    Result := ASignal.Code In [
        nrtSignalGray,
        nrtSignalGreen,
        nrtSignalOrange,
        nrtSignalRed
        ];
End;

Function TNoReflowTabBarSignalsEditor.GetSelectedSignal: TNoReflowTabBarSignalDef;
Var
    LSelection: IDesignerSelections;
    LPersistent: TPersistent;
Begin
    Result := Nil;

    If Designer = Nil Then
        Exit;

    LSelection := CreateSelectionList;
    Designer.GetSelections(LSelection);

    If (LSelection = Nil) Or (LSelection.Count = 0) Then
        Exit;

    LPersistent := LSelection[0];
    If LPersistent Is TNoReflowTabBarSignalDef Then
        Result := TNoReflowTabBarSignalDef(LPersistent);
End;

Function TNoReflowTabBarSignalsEditor.GetNextAvailableSignalCode: Integer;
Var
    LSignals: TNoReflowTabBarSignalDefs;
    LCode: Integer;
Begin
    Result := 5;

    If (Collection = Nil) Or Not (Collection Is TNoReflowTabBarSignalDefs) Then
        Exit;

    LSignals := TNoReflowTabBarSignalDefs(Collection);
    LCode := 5;

    While LSignals.FindByCode(LCode) <> Nil Do
        Inc(LCode);

    Result := LCode;
End;

Procedure TNoReflowTabBarSignalsEditor.SelectPersistentInDesigner(APersistent: TPersistent);
Var
    LItem: TCollectionItem;
    LIndex: Integer;
Begin
    If (APersistent = Nil) Or Not (APersistent Is TCollectionItem) Then
        Exit;

    LItem := TCollectionItem(APersistent);

    UpdateListbox;

    LIndex := LItem.Index;
    If (LIndex < 0) Or (LIndex >= ListView1.Items.Count) Then
        Exit;

    LockState;
    Try
        SelectNone(False);

        ListView1.Items[LIndex].Selected := True;
        ListView1.ItemFocused := ListView1.Items[LIndex];
        ListView1.Items[LIndex].MakeVisible(False);
    Finally
        UnlockState;
    End;

    SetSelection;
End;

Procedure TNoReflowTabBarSignalsEditor.AddClickAndReselect(Sender: TObject);
Var
    LSignals: TNoReflowTabBarSignalDefs;
    LNewSignal: TNoReflowTabBarSignalDef;
    LNewCode: Integer;
Begin
    If (Collection = Nil) Or Not (Collection Is TNoReflowTabBarSignalDefs) Then Begin
        Inherited AddClick(Sender);
        Exit;
    End;

    LSignals := TNoReflowTabBarSignalDefs(Collection);
    LNewCode := GetNextAvailableSignalCode;

    LSignals.BeginUpdate;
    Try
        LNewSignal := LSignals.Add;
        LNewSignal.Code := LNewCode;
        LNewSignal.Name := Format('Signal%d', [LNewCode]);
        LNewSignal.FillColor := clGray;
        LNewSignal.BorderColor := clDkGray;
    Finally
        LSignals.EndUpdate;
    End;

    If Designer <> Nil Then
        Designer.Modified;

    SelectPersistentInDesigner(LNewSignal);
    ListView1.SetFocus;
End;

Procedure TNoReflowTabBarSignalsEditor.DeleteClickAndReselect(Sender: TObject);
Var
    LSignal: TNoReflowTabBarSignalDef;
    LNextIndex: Integer;
Begin
    LSignal := GetSelectedSignal;
    If LSignal = Nil Then
        Exit;

    // Les voyants système ne doivent pas être supprimés.
    If IsBuiltInSignal(LSignal) Then
        Exit;

    LNextIndex := LSignal.Index;
    If LNextIndex >= Collection.Count - 1 Then
        LNextIndex := Collection.Count - 2;

    LSignal.Free;

    If Designer <> Nil Then
        Designer.Modified;

    UpdateListbox;

    If (LNextIndex >= 0) And (LNextIndex < Collection.Count) Then
        SelectPersistentInDesigner(Collection.Items[LNextIndex])
    Else
        SelectNone(False);

    ListView1.SetFocus;
End;

Procedure TNoReflowTabBarSignalsEditor.MoveUpClickAndReselect(Sender: TObject);
Var
    LSignal: TNoReflowTabBarSignalDef;
Begin
    LSignal := GetSelectedSignal;
    If LSignal = Nil Then
        Exit;

    // Les voyants système restent figés.
    If IsBuiltInSignal(LSignal) Then
        Exit;

    If LSignal.Index <= 4 Then
        Exit;

    LSignal.Index := LSignal.Index - 1;

    If Designer <> Nil Then
        Designer.Modified;

    SelectPersistentInDesigner(LSignal);
End;

Procedure TNoReflowTabBarSignalsEditor.MoveDownClickAndReselect(Sender: TObject);
Var
    LSignal: TNoReflowTabBarSignalDef;
Begin
    LSignal := GetSelectedSignal;
    If LSignal = Nil Then
        Exit;

    // Les voyants système restent figés.
    If IsBuiltInSignal(LSignal) Then
        Exit;

    If LSignal.Index >= Collection.Count - 1 Then
        Exit;

    LSignal.Index := LSignal.Index + 1;

    If Designer <> Nil Then
        Designer.Modified;

    SelectPersistentInDesigner(LSignal);
End;

//===============================================================================================================================
// Register
//===============================================================================================================================

Procedure Register;
Begin
    RegisterComponents('NoReflowTabBar', [TNoReflowTabBar]);

    RegisterPropertyEditor(
        TypeInfo(String),
        TNoReflowTabBarItem,
        'SignalName',
        TNoReflowTabBarItemSignalNameProperty
        );

    RegisterPropertyEditor(
        TypeInfo(TNoReflowTabBarItems),
        TNoReflowTabBar,
        'BarItems',
        TNoReflowTabBarItemsProperty
        );

    RegisterPropertyEditor(
        TypeInfo(Integer),
        TNoReflowTabBarSignalDef,
        'Code',
        TNoReflowTabBarSignalCodeProperty
        );

    RegisterPropertyEditor(
        TypeInfo(TNoReflowTabBarSignalDefs),
        TNoReflowTabBar,
        'BarSignals',
        TNoReflowTabBarSignalsProperty
        );
End;

End.


