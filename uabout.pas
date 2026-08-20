unit uabout;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LCLIntf;

type

  { TfrmAbout }

  TfrmAbout = class(TForm)
    Bevel1: TBevel;
    btnOk: TButton;
    Image1: TImage;
    Label1: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lblWebsite: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lblVersion: TLabel;
    lblWebsite1: TLabel;
    Memo1: TMemo;
    procedure FormShow(Sender: TObject);
    procedure Label6Click(Sender: TObject);
    procedure lblWebsite1Click(Sender: TObject);
    procedure lblWebsiteClick(Sender: TObject);
    procedure lblWebsiteMouseEnter(Sender: TObject);
    procedure lblWebsiteMouseLeave(Sender: TObject);
  private

  public

    procedure OpenCElink;

  end;

const
  olce_author_link = 'https://github.com/shusaura85';
  openloco_company_editor_link = 'https://github.com/shusaura85/OpenLocoCompanyEditor';
  openloco_object_editor_link = 'https://github.com/OpenLoco/ObjectEditor';

var
  frmAbout: TfrmAbout;

implementation

{$R *.lfm}

uses umain;

{ TfrmAbout }

procedure TfrmAbout.OpenCElink;
begin
  OpenURL(openloco_company_editor_link);
end;

procedure TfrmAbout.lblWebsiteClick(Sender: TObject);
begin
  OpenURL(openloco_company_editor_link);
end;

procedure TfrmAbout.lblWebsiteMouseEnter(Sender: TObject);
begin
  (Sender as TLabel).Font.Color := clBlue;
end;

procedure TfrmAbout.lblWebsiteMouseLeave(Sender: TObject);
begin
  (Sender as TLabel).Font.Color := clDefault;
end;

procedure TfrmAbout.FormShow(Sender: TObject);
begin
  lblVersion.Caption := 'Version: '+CE_Version;
  lblWebsite.Caption := openloco_company_editor_link;
end;

procedure TfrmAbout.Label6Click(Sender: TObject);
begin
  OpenURL(olce_author_link);
end;

procedure TfrmAbout.lblWebsite1Click(Sender: TObject);
begin
  OpenURL(openloco_object_editor_link);
end;

end.

