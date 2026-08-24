program ol_company_editor;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazcontrols, uMain, uselectimage, ulanguagestrings, uabout
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Title:='OpenLoco Company Editor';
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmSelectImage, frmSelectImage);
  Application.CreateForm(TfrmLanguageStrings, frmLanguageStrings);
  Application.CreateForm(TfrmAbout, frmAbout);
  Application.Run;
end.

