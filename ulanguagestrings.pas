unit ulanguagestrings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type

  { TfrmLanguageStrings }

  TfrmLanguageStrings = class(TForm)
    Bevel1: TBevel;
    btnCancel: TButton;
    btnOk: TButton;
    edLanguageId0: TEdit;
    edLanguageId13: TEdit;
    edLanguageId5: TEdit;
    edLanguageId4: TEdit;
    edLanguageId3: TEdit;
    edLanguageId2: TEdit;
    edLanguageId1: TEdit;
    edLanguageId12: TEdit;
    edLanguageId11: TEdit;
    edLanguageId10: TEdit;
    edLanguageId9: TEdit;
    edLanguageId8: TEdit;
    edLanguageId7: TEdit;
    edLanguageId6: TEdit;
    gbMain: TGroupBox;
    Label1: TLabel;
    Panel1: TPanel;
    Panel10: TPanel;
    Panel11: TPanel;
    Panel12: TPanel;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  frmLanguageStrings: TfrmLanguageStrings;

implementation

{$R *.lfm}

{ TfrmLanguageStrings }

procedure TfrmLanguageStrings.FormShow(Sender: TObject);
begin
  ActiveControl := edLanguageId0;
end;

end.

