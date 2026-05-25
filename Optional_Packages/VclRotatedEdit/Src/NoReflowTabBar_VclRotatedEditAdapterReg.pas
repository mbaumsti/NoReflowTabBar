Unit NoReflowTabBar_VclRotatedEditAdapterReg;

{
  NoReflowTabBar_VclRotatedEditAdapterReg.pas

  Design-time marker unit for the optional NoReflowTabBar / VclRotatedEdit
  adapter package.

  The runtime adapter performs the actual registration through its
  initialization section. This unit intentionally registers no component in the
  palette: it only gives the optional design package a clear design-time entry
  point and a place for future property editors if they become necessary.
}

Interface

Procedure Register;

Implementation

Procedure Register;
Begin
    //-------------------------------------------------------------------------
    //No design-time registration is currently required.
    //
    //The unit is kept deliberately because an installable design-time package is
    //clearer for Delphi users than asking them to install a runtime-only adapter
    //package manually in the IDE.
    //-------------------------------------------------------------------------
End;

End.
