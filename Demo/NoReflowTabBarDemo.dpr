program NoReflowTabBarDemo;

uses
  Vcl.Forms,
  NoReflowTabBarDemoMain in 'NoReflowTabBarDemoMain.pas' {FrmOngletBtn},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.name := 'AppTestBoutons';
  TStyleManager.TrySetStyle('Wedgewood Light');
  Application.CreateForm(TFrmOngletBtn, FrmOngletBtn);
  Application.Run;
end.
