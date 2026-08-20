unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Menus, ComCtrls, PopupNotifier, object_handler, baseconvert;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    Button1: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    Button13: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    chkUseDifferentLanguageNames: TCheckBox;
    chkEmotionHappy: TCheckBox;
    chkNamePrefix2: TCheckBox;
    chkNamePrefix3: TCheckBox;
    chkNamePrefix5: TCheckBox;
    chkNamePrefix6: TCheckBox;
    chkNamePrefix7: TCheckBox;
    chkNamePrefix8: TCheckBox;
    chkNamePrefix4: TCheckBox;
    chkNamePrefix13: TCheckBox;
    chkNamePrefix12: TCheckBox;
    chkNamePrefix11: TCheckBox;
    chkEmotionWorried: TCheckBox;
    chkNamePrefix10: TCheckBox;
    chkNamePrefix9: TCheckBox;
    chkNameSuffix1: TCheckBox;
    chkNameSuffix2: TCheckBox;
    chkNameSuffix3: TCheckBox;
    chkNameSuffix5: TCheckBox;
    chkNameSuffix6: TCheckBox;
    chkNameSuffix7: TCheckBox;
    chkNameSuffix8: TCheckBox;
    chkNameSuffix13: TCheckBox;
    chkEmotionThinking: TCheckBox;
    chkNameSuffix12: TCheckBox;
    chkNameSuffix11: TCheckBox;
    chkNameSuffix10: TCheckBox;
    chkNameSuffix9: TCheckBox;
    chkNameSuffix4: TCheckBox;
    chkEmotionDejected: TCheckBox;
    chkEmotionSurprised: TCheckBox;
    chkEmotionScared: TCheckBox;
    chkEmotionAngry: TCheckBox;
    chkEmotionDisgusted: TCheckBox;
    chkNamePrefix1: TCheckBox;
    ImageList1: TImageList;
    MenuItem9: TMenuItem;
    Separator2: TMenuItem;
    OpenDialog1: TOpenDialog;
    PopupNotifier1: TPopupNotifier;
    SaveDialog1: TSaveDialog;
    selObjectSource: TComboBox;
    edChecksum: TEdit;
    edChecksumHex: TEdit;
    edOwnerName: TEdit;
    edCompanyName: TEdit;
    edObjectID: TEdit;
    GroupBox1: TGroupBox;
    GroupBox10: TGroupBox;
    GroupBox11: TGroupBox;
    GroupBox12: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    GroupBox6: TGroupBox;
    GroupBox7: TGroupBox;
    GroupBox8: TGroupBox;
    GroupBox9: TGroupBox;
    imgHappyLarge: TImage;
    imgDejectedSmall: TImage;
    imgSurprisedLarge: TImage;
    imgSurprisedSmall: TImage;
    imgScaredLarge: TImage;
    imgScaredSmall: TImage;
    imgAngryLarge: TImage;
    imgAngrySmall: TImage;
    imgDisgustedLarge: TImage;
    imgDisgustedSmall: TImage;
    imgHappySmall: TImage;
    imgNeutralLarge: TImage;
    imgNeutralSmall: TImage;
    imgWorriedLarge: TImage;
    imgWorriedSmall: TImage;
    imgThinkingLarge: TImage;
    imgThinkingSmall: TImage;
    imgDejectedLarge: TImage;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    lblIntelligenceValue: TLabel;
    lblAggressivenessValue: TLabel;
    lblCompetitivenessValue: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    Separator1: TMenuItem;
    tbIntelligence: TTrackBar;
    tbAggressiveness: TTrackBar;
    tbCompetitiveness: TTrackBar;
    timerError: TTimer;
    timerNotification: TTimer;
    procedure Button10Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure tbIntelligenceChange(Sender: TObject);
    procedure tbAggressivenessChange(Sender: TObject);
    procedure tbCompetitivenessChange(Sender: TObject);
    procedure timerErrorTimer(Sender: TObject);
    procedure timerNotificationTimer(Sender: TObject);
  private

    procedure InitNewCompany;
  public
    loaded_file: string;
    owner_names, company_names: array[0..13] of string;

  end;

const spriteSizeLarge = 64;
      spriteSizeSmall = 24;

      sSpecLow = 'Low';
      sSpecMid = 'Medium';
      sSpecHigh = 'High';

      CE_Version = '0.9';   // application version - shown in about

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

uses uselectimage, ulanguagestrings, uabout;

{ TfrmMain }

procedure TfrmMain.InitNewCompany;
var png: TPortableNetworkGraphic;
    i: integer;
begin
  loaded_file := '';

  for i:= 0 to 13 do owner_names[i] := '';
  for i:= 0 to 13 do company_names[i] := '';

  png := TPortableNetworkGraphic.Create;
  png.Width := spriteSizeLarge;
  png.Height := spriteSizeLarge;
  png.Canvas.Pen.Color := $00000040;
  png.Canvas.Pen.Width:= 2;
  png.Canvas.Brush.Color:= $00FFFFDD;
  png.Canvas.Brush.Style:= bsSolid; //bsDiagCross;
  png.Canvas.FillRect(0,0,spriteSizeLarge, spriteSizeLarge);
//  png.Canvas.Line(0, 0, spriteSizeLarge, spriteSizeLarge);
//  png.Canvas.Line(0, spriteSizeLarge, spriteSizeLarge, 0);
  png.Canvas.TextOut(15, 10, 'Select');
  png.Canvas.TextOut(15, 25, 'Image');
  png.Canvas.TextOut(20, 40, 'File');

//  bmp := TBitmap.Create;
//  bmp.Width := spriteSizeLarge;
//  bmp.Height := spriteSizeLarge;
//  bmp.Canvas.FloodFill(0,0, clBlack, TFillStyle.fsSurface);
  imgNeutralLarge.Picture.Assign(png);
  imgHappyLarge.Picture.Assign(png);
  imgWorriedLarge.Picture.Assign(png);
  imgThinkingLarge.Picture.Assign(png);
  imgDejectedLarge.Picture.Assign(png);
  imgSurprisedLarge.Picture.Assign(png);
  imgScaredLarge.Picture.Assign(png);
  imgAngryLarge.Picture.Assign(png);
  imgDisgustedLarge.Picture.Assign(png);


  png := TPortableNetworkGraphic.Create;
  png.Width := spriteSizeSmall;
  png.Height := spriteSizeSmall;
  png.Canvas.Pen.Color := $00000040;
  png.Canvas.Pen.Width:= 2;
  png.Canvas.Brush.Color:= $00FFFFDD;
  png.Canvas.Brush.Style:= bsSolid;
  png.Canvas.FillRect(0,0,spriteSizeSmall, spriteSizeSmall);
  png.Canvas.Line(0, 0, spriteSizeSmall, spriteSizeSmall);
  png.Canvas.Line(0, spriteSizeSmall, spriteSizeSmall, 0);

  //bmp.Width := spriteSizeSmall;
  //bmp.Height := spriteSizeSmall;
  //bmp.Canvas.FloodFill(0,0, clBlack, TFillStyle.fsSurface);
  imgNeutralSmall.Picture.Assign(png);
  imgHappySmall.Picture.Assign(png);
  imgWorriedSmall.Picture.Assign(png);
  imgThinkingSmall.Picture.Assign(png);
  imgDejectedSmall.Picture.Assign(png);
  imgSurprisedSmall.Picture.Assign(png);
  imgScaredSmall.Picture.Assign(png);
  imgAngrySmall.Picture.Assign(png);
  imgDisgustedSmall.Picture.Assign(png);

  png.Free;

  edOwnerName.Text := 'Owner Name';

  chkEmotionHappy.Checked := false;
  chkEmotionWorried.Checked := false;
  chkEmotionThinking.Checked := false;
  chkEmotionDejected.Checked := false;
  chkEmotionSurprised.Checked := false;
  chkEmotionScared.Checked := false;
  chkEmotionAngry.Checked := false;
  chkEmotionDisgusted.Checked := false;

  chkNamePrefix1.Checked := true;
  chkNamePrefix2.Checked := true;
  chkNamePrefix3.Checked := true;
  chkNamePrefix4.Checked := true;
  chkNamePrefix5.Checked := true;
  chkNamePrefix6.Checked := true;
  chkNamePrefix7.Checked := true;
  chkNamePrefix8.Checked := true;
  chkNamePrefix9.Checked := true;
  chkNamePrefix10.Checked := true;
  chkNamePrefix11.Checked := true;
  chkNamePrefix12.Checked := true;
  chkNamePrefix13.Checked := true;

  edCompanyName.Text := 'Company';

  chkNameSuffix1.Checked := true;
  chkNameSuffix2.Checked := true;
  chkNameSuffix3.Checked := true;
  chkNameSuffix4.Checked := true;
  chkNameSuffix5.Checked := true;
  chkNameSuffix6.Checked := true;
  chkNameSuffix7.Checked := true;
  chkNameSuffix8.Checked := true;
  chkNameSuffix9.Checked := true;
  chkNameSuffix10.Checked := true;
  chkNameSuffix11.Checked := true;
  chkNameSuffix12.Checked := true;
  chkNameSuffix13.Checked := true;


  tbIntelligence.Position := 5;
  tbAggressiveness.Position := 5;
  tbCompetitiveness.Position := 5;

  edObjectID.Text := SetNewObjectId;

  selObjectSource.ItemIndex := 0;

  edChecksum.Text := '';
  edChecksumHex.Text := '';

end;



procedure TfrmMain.tbIntelligenceChange(Sender: TObject);
begin
if (Sender as TTrackBar).Position < 4   then lblIntelligenceValue.Caption := sSpecLow + ' ('+IntToStr((Sender as TTrackBar).Position)+')'
else
  if (Sender as TTrackBar).Position < 7 then lblIntelligenceValue.Caption := sSpecMid + ' ('+IntToStr((Sender as TTrackBar).Position)+')'
else
                                             lblIntelligenceValue.Caption := sSpecHigh + ' ('+IntToStr((Sender as TTrackBar).Position)+')';
end;

procedure TfrmMain.tbAggressivenessChange(Sender: TObject);
begin
if (Sender as TTrackBar).Position < 4   then lblAggressivenessValue.Caption := sSpecLow + ' ('+IntToStr((Sender as TTrackBar).Position)+')'
else
  if (Sender as TTrackBar).Position < 7 then lblAggressivenessValue.Caption := sSpecMid + ' ('+IntToStr((Sender as TTrackBar).Position)+')'
else
                                             lblAggressivenessValue.Caption := sSpecHigh + ' ('+IntToStr((Sender as TTrackBar).Position)+')';
end;

procedure TfrmMain.tbCompetitivenessChange(Sender: TObject);
begin
if (Sender as TTrackBar).Position < 4   then lblCompetitivenessValue.Caption := sSpecLow + ' ('+IntToStr((Sender as TTrackBar).Position)+')'
else
  if (Sender as TTrackBar).Position < 7 then lblCompetitivenessValue.Caption := sSpecMid + ' ('+IntToStr((Sender as TTrackBar).Position)+')'
else
                                             lblCompetitivenessValue.Caption := sSpecHigh + ' ('+IntToStr((Sender as TTrackBar).Position)+')';
end;

procedure TfrmMain.timerErrorTimer(Sender: TObject);
begin
  PopupNotifier1.Hide;
  timerError.Enabled := false;
end;

procedure TfrmMain.timerNotificationTimer(Sender: TObject);
begin
  PopupNotifier1.Hide;
  timerNotification.Enabled := false;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  InitNewCompany;
end;

procedure TfrmMain.FormDropFiles(Sender: TObject;
  const FileNames: array of string);
begin
  // only look at the first file
if not VerifyObject(FileNames[0]) then
   begin
   PopupNotifier1.Text:= 'The selected file is not a valid competitor object!';
   PopupNotifier1.ShowAtPos(Left + (ClientWidth div 2) - (PopupNotifier1.vNotifierForm.Width div 2), Top);
   timerError.Enabled := true;
//   ShowMessage('The selected file is not a valid competitor object!');
   Exit;
   end;

InitNewCompany;  // reset state
loaded_file := FileNames[0];
LoadObject(loaded_file);
end;

procedure TfrmMain.MenuItem2Click(Sender: TObject);
begin
  InitNewCompany;
end;

procedure TfrmMain.MenuItem3Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
     begin
     if not VerifyObject(OpenDialog1.FileName) then
            begin
            PopupNotifier1.Text:= 'The selected file is not a valid competitor object!';
            PopupNotifier1.ShowAtPos(Left + (ClientWidth div 2) - (PopupNotifier1.vNotifierForm.Width div 2), Top);
            timerError.Enabled := true;
//            ShowMessage('The selected file is not a valid competitor object!');
            Exit;
            end;

     InitNewCompany;  // reset state
     loaded_file := OpenDialog1.FileName;
     LoadObject(OpenDialog1.FileName);
     end;
end;

procedure TfrmMain.MenuItem4Click(Sender: TObject);
begin
  if loaded_file = '' then
     begin
     SaveDialog1.FileName := edObjectID.Text + '.dat';

     if SaveDialog1.Execute then
        loaded_file := SaveDialog1.FileName
     else Exit;
     end;

  SaveObject(loaded_file);

  PopupNotifier1.Text:= 'The object '+edObjectID.Text+' was saved!';
  PopupNotifier1.ShowAtPos(Left + (ClientWidth div 2) - (PopupNotifier1.vNotifierForm.Width div 2), Top);
  timerNotification.Enabled := true;
end;

procedure TfrmMain.MenuItem5Click(Sender: TObject);
begin
  if loaded_file = '' then SaveDialog1.FileName := edObjectID.Text + '.dat'
  else
     begin
     SaveDialog1.InitialDir := ExtractFilePath(loaded_file);
     SaveDialog1.FileName := ExtractFileName(loaded_file);
     end;

  if SaveDialog1.Execute then
     begin
     SaveObject(SaveDialog1.FileName);
     loaded_file := SaveDialog1.FileName;

     PopupNotifier1.Text:= 'The object '+edObjectID.Text+' was saved to '+#13#10
                           +SaveDialog1.FileName;
     PopupNotifier1.ShowAtPos(Left + (ClientWidth div 2) - (PopupNotifier1.vNotifierForm.Width div 2), Top);
     timerNotification.Enabled := true;
     end;
end;

procedure TfrmMain.MenuItem6Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.MenuItem8Click(Sender: TObject);
begin
  frmAbout.ShowModal;
end;

procedure TfrmMain.MenuItem9Click(Sender: TObject);
begin
  frmAbout.OpenCElink;
end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
if frmSelectImage.ShowModal = mrOk then
   begin
   imgNeutralLarge.Picture.Assign(frmSelectImage.imgLarge.Picture);
   imgNeutralLarge.Invalidate;

   imgNeutralSmall.Picture.Assign(frmSelectImage.imgSmall.Picture);
   imgNeutralSmall.Invalidate;
   end;
end;

procedure TfrmMain.Button11Click(Sender: TObject);
begin
  chkNamePrefix1.Checked := not chkNamePrefix1.Checked;
  chkNamePrefix2.Checked := not chkNamePrefix2.Checked;
  chkNamePrefix3.Checked := not chkNamePrefix3.Checked;
  chkNamePrefix4.Checked := not chkNamePrefix4.Checked;
  chkNamePrefix5.Checked := not chkNamePrefix5.Checked;
  chkNamePrefix6.Checked := not chkNamePrefix6.Checked;
  chkNamePrefix7.Checked := not chkNamePrefix7.Checked;
  chkNamePrefix8.Checked := not chkNamePrefix8.Checked;
  chkNamePrefix9.Checked := not chkNamePrefix9.Checked;
  chkNamePrefix10.Checked := not chkNamePrefix10.Checked;
  chkNamePrefix11.Checked := not chkNamePrefix11.Checked;
  chkNamePrefix12.Checked := not chkNamePrefix12.Checked;
  chkNamePrefix13.Checked := not chkNamePrefix13.Checked;
end;

procedure TfrmMain.Button10Click(Sender: TObject);
begin
  frmLanguageStrings.gbMain.Caption:= 'Owner name';

  frmLanguageStrings.edLanguageId0.Text := edOwnerName.Text; //owner_names[0];
  frmLanguageStrings.edLanguageId1.Text := owner_names[1];
  frmLanguageStrings.edLanguageId2.Text := owner_names[2];
  frmLanguageStrings.edLanguageId3.Text := owner_names[3];
  frmLanguageStrings.edLanguageId4.Text := owner_names[4];
  frmLanguageStrings.edLanguageId5.Text := owner_names[5];
  frmLanguageStrings.edLanguageId6.Text := owner_names[6];
  frmLanguageStrings.edLanguageId7.Text := owner_names[7];
  frmLanguageStrings.edLanguageId8.Text := owner_names[8];
  frmLanguageStrings.edLanguageId9.Text := owner_names[9];
  frmLanguageStrings.edLanguageId10.Text := owner_names[10];
  frmLanguageStrings.edLanguageId11.Text := owner_names[11];
  frmLanguageStrings.edLanguageId12.Text := owner_names[12];
  frmLanguageStrings.edLanguageId13.Text := owner_names[13];

  if frmLanguageStrings.ShowModal = mrOk then
     begin
     owner_names[0] := frmLanguageStrings.edLanguageId0.Text;
     owner_names[1] := frmLanguageStrings.edLanguageId1.Text;
     owner_names[2] := frmLanguageStrings.edLanguageId2.Text;
     owner_names[3] := frmLanguageStrings.edLanguageId3.Text;
     owner_names[4] := frmLanguageStrings.edLanguageId4.Text;
     owner_names[5] := frmLanguageStrings.edLanguageId5.Text;
     owner_names[6] := frmLanguageStrings.edLanguageId6.Text;
     owner_names[7] := frmLanguageStrings.edLanguageId7.Text;
     owner_names[8] := frmLanguageStrings.edLanguageId8.Text;
     owner_names[9] := frmLanguageStrings.edLanguageId9.Text;
     owner_names[10] := frmLanguageStrings.edLanguageId10.Text;
     owner_names[11] := frmLanguageStrings.edLanguageId11.Text;
     owner_names[12] := frmLanguageStrings.edLanguageId12.Text;
     owner_names[13] := frmLanguageStrings.edLanguageId13.Text;

     edOwnerName.Text := frmLanguageStrings.edLanguageId0.Text;
     end;
end;

procedure TfrmMain.Button12Click(Sender: TObject);
begin
  chkNameSuffix1.Checked := not chkNameSuffix1.Checked;
  chkNameSuffix2.Checked := not chkNameSuffix2.Checked;
  chkNameSuffix3.Checked := not chkNameSuffix3.Checked;
  chkNameSuffix4.Checked := not chkNameSuffix4.Checked;
  chkNameSuffix5.Checked := not chkNameSuffix5.Checked;
  chkNameSuffix6.Checked := not chkNameSuffix6.Checked;
  chkNameSuffix7.Checked := not chkNameSuffix7.Checked;
  chkNameSuffix8.Checked := not chkNameSuffix8.Checked;
  chkNameSuffix9.Checked := not chkNameSuffix9.Checked;
  chkNameSuffix10.Checked := not chkNameSuffix10.Checked;
  chkNameSuffix11.Checked := not chkNameSuffix11.Checked;
  chkNameSuffix12.Checked := not chkNameSuffix12.Checked;
  chkNameSuffix13.Checked := not chkNameSuffix13.Checked;
end;

procedure TfrmMain.Button13Click(Sender: TObject);
begin
  frmLanguageStrings.gbMain.Caption:= 'Company name';

  frmLanguageStrings.edLanguageId0.Text := edCompanyName.Text; //company_names[0];
  frmLanguageStrings.edLanguageId1.Text := company_names[1];
  frmLanguageStrings.edLanguageId2.Text := company_names[2];
  frmLanguageStrings.edLanguageId3.Text := company_names[3];
  frmLanguageStrings.edLanguageId4.Text := company_names[4];
  frmLanguageStrings.edLanguageId5.Text := company_names[5];
  frmLanguageStrings.edLanguageId6.Text := company_names[6];
  frmLanguageStrings.edLanguageId7.Text := company_names[7];
  frmLanguageStrings.edLanguageId8.Text := company_names[8];
  frmLanguageStrings.edLanguageId9.Text := company_names[9];
  frmLanguageStrings.edLanguageId10.Text := company_names[10];
  frmLanguageStrings.edLanguageId11.Text := company_names[11];
  frmLanguageStrings.edLanguageId12.Text := company_names[12];
  frmLanguageStrings.edLanguageId13.Text := company_names[13];

  if frmLanguageStrings.ShowModal = mrOk then
     begin
     company_names[0] := frmLanguageStrings.edLanguageId0.Text;
     company_names[1] := frmLanguageStrings.edLanguageId1.Text;
     company_names[2] := frmLanguageStrings.edLanguageId2.Text;
     company_names[3] := frmLanguageStrings.edLanguageId3.Text;
     company_names[4] := frmLanguageStrings.edLanguageId4.Text;
     company_names[5] := frmLanguageStrings.edLanguageId5.Text;
     company_names[6] := frmLanguageStrings.edLanguageId6.Text;
     company_names[7] := frmLanguageStrings.edLanguageId7.Text;
     company_names[8] := frmLanguageStrings.edLanguageId8.Text;
     company_names[9] := frmLanguageStrings.edLanguageId9.Text;
     company_names[10] := frmLanguageStrings.edLanguageId10.Text;
     company_names[11] := frmLanguageStrings.edLanguageId11.Text;
     company_names[12] := frmLanguageStrings.edLanguageId12.Text;
     company_names[13] := frmLanguageStrings.edLanguageId13.Text;

     edCompanyName.Text := frmLanguageStrings.edLanguageId0.Text;
     end;
end;

procedure TfrmMain.Button2Click(Sender: TObject);
begin
  if frmSelectImage.ShowModal = mrOk then
   begin
   if not chkEmotionHappy.Checked then chkEmotionHappy.Checked := true;

   imgHappyLarge.Picture.Assign(frmSelectImage.imgLarge.Picture);
   imgHappyLarge.Invalidate;

   imgHappySmall.Picture.Assign(frmSelectImage.imgSmall.Picture);
   imgHappySmall.Invalidate;
   end;
end;

procedure TfrmMain.Button3Click(Sender: TObject);
begin
  if frmSelectImage.ShowModal = mrOk then
   begin
   if not chkEmotionWorried.Checked then chkEmotionWorried.Checked := true;

   imgWorriedLarge.Picture.Assign(frmSelectImage.imgLarge.Picture);
   imgWorriedLarge.Invalidate;

   imgWorriedSmall.Picture.Assign(frmSelectImage.imgSmall.Picture);
   imgWorriedSmall.Invalidate;
   end;
end;

procedure TfrmMain.Button4Click(Sender: TObject);
begin
  if frmSelectImage.ShowModal = mrOk then
   begin
   if not chkEmotionThinking.Checked then chkEmotionThinking.Checked := true;

   imgThinkingLarge.Picture.Assign(frmSelectImage.imgLarge.Picture);
   imgThinkingLarge.Invalidate;

   imgThinkingSmall.Picture.Assign(frmSelectImage.imgSmall.Picture);
   imgThinkingSmall.Invalidate;
   end;
end;

procedure TfrmMain.Button5Click(Sender: TObject);
begin
  if frmSelectImage.ShowModal = mrOk then
   begin
   if not chkEmotionDejected.Checked then chkEmotionDejected.Checked := true;

   imgDejectedLarge.Picture.Assign(frmSelectImage.imgLarge.Picture);
   imgDejectedLarge.Invalidate;

   imgDejectedSmall.Picture.Assign(frmSelectImage.imgSmall.Picture);
   imgDejectedSmall.Invalidate;
   end;
end;

procedure TfrmMain.Button6Click(Sender: TObject);
begin
  if frmSelectImage.ShowModal = mrOk then
   begin
   if not chkEmotionSurprised.Checked then chkEmotionSurprised.Checked := true;

   imgSurprisedLarge.Picture.Assign(frmSelectImage.imgLarge.Picture);
   imgSurprisedLarge.Invalidate;

   imgSurprisedSmall.Picture.Assign(frmSelectImage.imgSmall.Picture);
   imgSurprisedSmall.Invalidate;
   end;
end;

procedure TfrmMain.Button7Click(Sender: TObject);
begin
  if frmSelectImage.ShowModal = mrOk then
   begin
   if not chkEmotionScared.Checked then chkEmotionScared.Checked := true;

   imgScaredLarge.Picture.Assign(frmSelectImage.imgLarge.Picture);
   imgScaredLarge.Invalidate;

   imgScaredSmall.Picture.Assign(frmSelectImage.imgSmall.Picture);
   imgScaredSmall.Invalidate;
   end;
end;

procedure TfrmMain.Button8Click(Sender: TObject);
begin
  if frmSelectImage.ShowModal = mrOk then
   begin
   if not chkEmotionAngry.Checked then chkEmotionAngry.Checked := true;

   imgAngryLarge.Picture.Assign(frmSelectImage.imgLarge.Picture);
   imgAngryLarge.Invalidate;

   imgAngrySmall.Picture.Assign(frmSelectImage.imgSmall.Picture);
   imgAngrySmall.Invalidate;
   end;
end;

procedure TfrmMain.Button9Click(Sender: TObject);
begin
  if frmSelectImage.ShowModal = mrOk then
   begin
   if not chkEmotionDisgusted.Checked then chkEmotionDisgusted.Checked := true;

   imgDisgustedLarge.Picture.Assign(frmSelectImage.imgLarge.Picture);
   imgDisgustedLarge.Invalidate;

   imgDisgustedSmall.Picture.Assign(frmSelectImage.imgSmall.Picture);
   imgDisgustedSmall.Invalidate;
   end;
end;

end.

