unit uselectimage;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ExtDlgs, ComCtrls,
  { image manipulation units }
  BGRABitmap, BGRABitmapTypes, BGRAPalette, BGRAColorQuantization;

type

  { TfrmSelectImage }

  TfrmSelectImage = class(TForm)
    Bevel1: TBevel;
    btnLoadImageLarge: TButton;
    btnLoadBgImageLarge: TButton;
    btnUseDefaultBgImage: TButton;
    btnLoadImageSmall: TButton;
    btnLoadBgImageSmall: TButton;
    btnOk: TButton;
    btnCancel: TButton;
    chkUseLargeForSmall: TCheckBox;
    chkUseLargeForSmallBg: TCheckBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    imgBgLarge: TImage;
    imgBgSmall: TImage;
    imgFrontLarge: TImage;
    imgUserBgLarge: TImage;
    imgUserBgSmall: TImage;
    imgLarge: TImage;
    imgFrontSmall: TImage;
    imgSmall: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    PageControl1: TPageControl;
    OpenPictureDialog1: TOpenPictureDialog;
    selColorPalette: TComboBox;
    selBgColorPalette: TComboBox;
    selPaletteMode: TComboBox;
    selBgPaletteMode: TComboBox;
    selResize: TComboBox;
    selBgResize: TComboBox;
    tabImage: TTabSheet;
    tabBgImage: TTabSheet;
    procedure btnLoadBgImageLargeClick(Sender: TObject);
    procedure btnLoadBgImageSmallClick(Sender: TObject);
    procedure btnUseDefaultBgImageClick(Sender: TObject);
    procedure btnLoadImageLargeClick(Sender: TObject);
    procedure btnLoadImageSmallClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure updateBgImageView(Sender: TObject);
    procedure updateImageView(Sender: TObject);
  private
    Quantizer: TBGRAColorQuantizer;      { handles resize and color palette }
    BgWorkPalette: TBGRAIndexedPalette;    { holds the loco color palette for background image }
    WorkPalette: TBGRAIndexedPalette;    { holds the loco color palette }

    procedure LoadBgColorPalette;
    procedure LoadColorPalette;
    procedure ProcessLargeBgImage;
    procedure ProcessSmallBgImage;
    procedure ProcessLargeImage;
    procedure ProcessSmallImage;
  public
    img: TBGRABitmap;
    in_file_large: string;
    in_file_small: string;
    in_file_bg_large: string;
    in_file_bg_small: string;
    old_file_bg_large: string;   // keep previous loaded background image
    old_file_bg_small: string;

  end;

var
  frmSelectImage: TfrmSelectImage;

implementation

{$R *.lfm}

uses uMain;

{ TfrmSelectImage }

procedure TfrmSelectImage.LoadBgColorPalette;
begin
// reset palette if previously loaded
if BgWorkPalette <> nil then BgWorkPalette.Free;

BgWorkPalette := TBGRAIndexedPalette.Create;

{ palettes are stored in the binary - see project options -> resources }
{ bgra also accepts normal file name and derives resource name from it - see BGRABitmapTypes - GetWinResourceType function }
if selBgColorPalette.ItemIndex = 0 then BgWorkPalette.LoadFromResource('openloco', palJascPSP)
else
  if selBgColorPalette.ItemIndex = 1 then BgWorkPalette.LoadFromResource('openloco_cc', palJascPSP)
else
  BgWorkPalette.LoadFromResource('openloco_occ', palJascPSP);
end;

procedure TfrmSelectImage.LoadColorPalette;
begin
// reset palette if previously loaded
if WorkPalette <> nil then WorkPalette.Free;

WorkPalette := TBGRAIndexedPalette.Create;

{ palettes are stored in the binary - see project options -> resources }
{ bgra also accepts normal file name and derives resource name from it - see BGRABitmapTypes - GetWinResourceType function }
if selColorPalette.ItemIndex = 0 then WorkPalette.LoadFromResource('openloco', palJascPSP)
else
  if selColorPalette.ItemIndex = 1 then WorkPalette.LoadFromResource('openloco_cc', palJascPSP)
else
  WorkPalette.LoadFromResource('openloco_occ', palJascPSP);
end;



procedure TfrmSelectImage.ProcessLargeBgImage;
var Image: TBGRABitmap;
    new_x, new_y, new_w, new_h: integer;
    ar: Double;
begin
// check if user background image was loaded
if in_file_bg_large = '' then exit;

// load color palette
LoadBgColorPalette;

Image := TBGRABitmap.Create(in_file_bg_large);

new_x := 0;
new_y := 0;
new_w := spriteSizeLarge;
new_h := spriteSizeLarge;

ar := Image.Width / Image.Height;
if ar <> 1 then
   begin
   if Image.Width > Image.Height then
      begin
      if selBgResize.ItemIndex = 0 then  // resize no crop
         begin
         new_h := Round(spriteSizeLarge / ar);
         new_y := Round((spriteSizeLarge - new_h) / 2);
         end
      else  // resize with crop
         begin
         new_w := Round(spriteSizeLarge * ar);
         new_x := Round((spriteSizeLarge - new_w) / 2);
         end;
      end
   else
      begin
      if selBgResize.ItemIndex = 0 then  // resize no crop
         begin
         new_w := Round(spriteSizeLarge * ar);
         new_x := Round((spriteSizeLarge - new_w) / 2);
         end
      else  // resize with crop
         begin
         new_h := Round(spriteSizeLarge / ar);
         new_y := Round((spriteSizeLarge - new_h) / 2);
         end;
      end;
   end;


// resize only if needed
if (Image.Width <> spriteSizeLarge) or (Image.Height <> spriteSizeLarge) then
   Image := Image.Resample(new_w, new_h, TResampleMode.rmFineResample);


if selBgPaletteMode.ItemIndex <> 2 then
   begin
   Quantizer := TBGRAColorQuantizer.Create(BgWorkPalette, false, 256);
   try
     if selBgPaletteMode.ItemIndex = 0 then Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daFloydSteinberg, Image)
                                       else Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daNearestNeighbor, Image);
   finally
     Quantizer.Free;
   end;

   end;

if img <> nil then img.Free;

img := TBGRABitmap.Create(spriteSizeLarge, spriteSizeLarge, BGRAPixelTransparent);
//img.Canvas.Draw(0, 0, imgBgLarge.Picture.Graphic);

img.PutImage(new_x, new_y, Image, dmDrawWithTransparency);

Image.Free;

imgBgLarge.Picture.Assign(img);

img.Free;

if in_file_large = '' then imgLarge.Picture.Assign(imgBgLarge.Picture);
end;


procedure TfrmSelectImage.ProcessSmallBgImage;
var Image: TBGRABitmap;
    new_x, new_y, new_w, new_h: integer;
    ar: Double;
begin
// use large file if checked
if chkUseLargeForSmallBg.Checked then in_file_bg_small := in_file_bg_large;

// check if image was loaded
if in_file_bg_small = '' then exit;

// load color palette
LoadBgColorPalette;

//Image := TBGRABitmap.Create(imgBgLarge.Picture.Bitmap);
Image := TBGRABitmap.Create(in_file_bg_small);

new_x := 0;
new_y := 0;
new_w := spriteSizeSmall;
new_h := spriteSizeSmall;

ar := Image.Width / Image.Height;
if ar <> 1 then
   begin
   if Image.Width > Image.Height then
      begin
      if selBgResize.ItemIndex = 0 then  // resize no crop
         begin
         new_h := Round(spriteSizeSmall / ar);
         new_y := Round((spriteSizeSmall - new_h) / 2);
         end
      else  // resize with crop
         begin
         new_w := Round(spriteSizeSmall * ar);
         new_x := Round((spriteSizeSmall - new_w) / 2);
         end;
      end
   else
      begin
      if selBgResize.ItemIndex = 0 then  // resize no crop
         begin
         new_w := Round(spriteSizeSmall * ar);
         new_x := Round((spriteSizeSmall - new_w) / 2);
         end
      else  // resize with crop
         begin
         new_h := Round(spriteSizeSmall / ar);
         new_y := Round((spriteSizeSmall - new_h) / 2);
         end;
      end;
   end;


// resize only if needed
if (Image.Width <> spriteSizeSmall) or (Image.Height <> spriteSizeSmall) then
   Image := Image.Resample(new_w, new_h, TResampleMode.rmFineResample);


if selBgPaletteMode.ItemIndex <> 2 then
   begin
   Quantizer := TBGRAColorQuantizer.Create(BgWorkPalette, false, 256);
   try
     if selBgPaletteMode.ItemIndex = 0 then Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daFloydSteinberg, Image)
                                       else Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daNearestNeighbor, Image);
   finally
     Quantizer.Free;
   end;

   end;

if img <> nil then img.Free;

img := TBGRABitmap.Create(spriteSizeSmall, spriteSizeSmall, BGRAPixelTransparent);
img.Canvas.Draw(0, 0, imgBgSmall.Picture.Graphic);

img.PutImage(new_x, new_y, Image, dmDrawWithTransparency);

Image.Free;

imgBgSmall.Picture.Assign(img);

img.Free;

if in_file_small = '' then imgSmall.Picture.Assign(imgBgSmall.Picture);
end;





procedure TfrmSelectImage.ProcessLargeImage;
var Image: TBGRABitmap;
    new_x, new_y, new_w, new_h: integer;
    ar: Double;
begin
// check if image was loaded
if in_file_large = '' then exit;

// make sure background is updated
ProcessLargeBgImage;

// load color palette
LoadColorPalette;

//Image := TBGRABitmap.Create(imgBgLarge.Picture.Bitmap);
Image := TBGRABitmap.Create(in_file_large);

new_x := 0;
new_y := 0;
new_w := spriteSizeLarge;
new_h := spriteSizeLarge;

ar := Image.Width / Image.Height;
if ar <> 1 then
   begin
   if Image.Width > Image.Height then
      begin
      if selResize.ItemIndex = 0 then  // resize no crop
         begin
         new_h := Round(spriteSizeLarge / ar);
         new_y := Round((spriteSizeLarge - new_h) / 2);
         end
      else  // resize with crop
         begin
         new_w := Round(spriteSizeLarge * ar);
         new_x := Round((spriteSizeLarge - new_w) / 2);
         end;
      end
   else
      begin
      if selResize.ItemIndex = 0 then  // resize no crop
         begin
         new_w := Round(spriteSizeLarge * ar);
         new_x := Round((spriteSizeLarge - new_w) / 2);
         end
      else  // resize with crop
         begin
         new_h := Round(spriteSizeLarge / ar);
         new_y := Round((spriteSizeLarge - new_h) / 2);
         end;
      end;
   end;


// resize only if needed
if (Image.Width <> spriteSizeLarge) or (Image.Height <> spriteSizeLarge) then
   Image := Image.Resample(new_w, new_h, TResampleMode.rmFineResample);


if selPaletteMode.ItemIndex <> 2 then
   begin
   Quantizer := TBGRAColorQuantizer.Create(WorkPalette, false, 256);
   try
     if selPaletteMode.ItemIndex = 0 then Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daFloydSteinberg, Image)
                                     else Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daNearestNeighbor, Image);
   finally
     Quantizer.Free;
   end;

   end;

if img <> nil then img.Free;

img := TBGRABitmap.Create(spriteSizeLarge, spriteSizeLarge, BGRAPixelTransparent);
img.Canvas.Draw(0, 0, imgBgLarge.Picture.Graphic);

img.PutImage(new_x, new_y, Image, dmDrawWithTransparency);

Image.Free;

imgLarge.Picture.Assign(img);

img.Free;
end;

procedure TfrmSelectImage.ProcessSmallImage;
var Image: TBGRABitmap;
    new_x, new_y, new_w, new_h: integer;
    ar: Double;
begin
// use large file if checked
if chkUseLargeForSmall.Checked then in_file_small := in_file_large;

// check if image was loaded
if in_file_small = '' then exit;

// make sure background is updated
ProcessSmallBgImage;

// load color palette
LoadColorPalette;

//Image := TBGRABitmap.Create(imgBgLarge.Picture.Bitmap);
Image := TBGRABitmap.Create(in_file_small);

new_x := 0;
new_y := 0;
new_w := spriteSizeSmall;
new_h := spriteSizeSmall;

ar := Image.Width / Image.Height;
if ar <> 1 then
   begin
   if Image.Width > Image.Height then
      begin
      if selResize.ItemIndex = 0 then  // resize no crop
         begin
         new_h := Round(spriteSizeSmall / ar);
         new_y := Round((spriteSizeSmall - new_h) / 2);
         end
      else  // resize with crop
         begin
         new_w := Round(spriteSizeSmall * ar);
         new_x := Round((spriteSizeSmall - new_w) / 2);
         end;
      end
   else
      begin
      if selResize.ItemIndex = 0 then  // resize no crop
         begin
         new_w := Round(spriteSizeSmall * ar);
         new_x := Round((spriteSizeSmall - new_w) / 2);
         end
      else  // resize with crop
         begin
         new_h := Round(spriteSizeSmall / ar);
         new_y := Round((spriteSizeSmall - new_h) / 2);
         end;
      end;
   end;


// resize only if needed
if (Image.Width <> spriteSizeSmall) or (Image.Height <> spriteSizeSmall) then
   Image := Image.Resample(new_w, new_h, TResampleMode.rmFineResample);


if selPaletteMode.ItemIndex <> 2 then
   begin
   Quantizer := TBGRAColorQuantizer.Create(WorkPalette, false, 256);
   try
     if selPaletteMode.ItemIndex = 0 then Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daFloydSteinberg, Image)
                                     else Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daNearestNeighbor, Image);
   finally
     Quantizer.Free;
   end;

   end;

if img <> nil then img.Free;

img := TBGRABitmap.Create(spriteSizeSmall, spriteSizeSmall, BGRAPixelTransparent);
img.Canvas.Draw(0, 0, imgBgSmall.Picture.Graphic);

img.PutImage(new_x, new_y, Image, dmDrawWithTransparency);

Image.Free;

imgSmall.Picture.Assign(img);

img.Free;
end;


procedure TfrmSelectImage.btnLoadImageLargeClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
     begin
     in_file_large := OpenPictureDialog1.FileName;
     imgFrontLarge.Picture.LoadFromFile(in_file_large);

     ProcessLargeImage;

     if chkUseLargeForSmall.Checked then
        begin
        in_file_small := in_file_large;
        imgFrontSmall.Picture.LoadFromFile(in_file_small);

        ProcessSmallImage;
        end;
     end;
end;

procedure TfrmSelectImage.btnUseDefaultBgImageClick(Sender: TObject);
begin
in_file_bg_large := '';
in_file_bg_small := '';

old_file_bg_large := '';
old_file_bg_small := '';

imgUserBgLarge.Picture.Clear;
imgUserBgSmall.Picture.Clear;

imgBgLarge.Picture.LoadFromResourceName(HInstance, 'BGLARGE', TPortableNetworkGraphic);
imgBgSmall.Picture.LoadFromResourceName(HInstance, 'BGSMALL', TPortableNetworkGraphic);

if in_file_large = '' then imgLarge.Picture.Assign(imgBgLarge.Picture);
if in_file_small = '' then imgSmall.Picture.Assign(imgBgSmall.Picture);

end;

procedure TfrmSelectImage.btnLoadBgImageLargeClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
     begin
     in_file_bg_large := OpenPictureDialog1.FileName;
     imgUserBgLarge.Picture.LoadFromFile(in_file_bg_large);

     ProcessLargeBgImage;

     if chkUseLargeForSmallBg.Checked then
        begin
        in_file_bg_small := in_file_bg_large;
        imgUserBgSmall.Picture.LoadFromFile(in_file_bg_small);

        ProcessSmallBgImage;
        end;
     end;
end;

procedure TfrmSelectImage.btnLoadBgImageSmallClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
     begin
     // reset use same file for small image if set
     if chkUseLargeForSmallBg.Checked then chkUseLargeForSmallBg.Checked := false;

     in_file_bg_small := OpenPictureDialog1.FileName;
     imgUserBgSmall.Picture.LoadFromFile(in_file_bg_small);

     ProcessSmallBgImage;
     end;
end;

procedure TfrmSelectImage.btnLoadImageSmallClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
     begin
     // reset use same file for small image if set
     if chkUseLargeForSmall.Checked then chkUseLargeForSmall.Checked := false;

     in_file_small := OpenPictureDialog1.FileName;
     imgFrontSmall.Picture.LoadFromFile(in_file_small);

     ProcessSmallImage;
     end;
end;

procedure TfrmSelectImage.btnOkClick(Sender: TObject);
begin
if in_file_large = '' then
   begin
   ModalResult := mrNone;
   ShowMessage('No image selected! Select an image before proceeding!');
   Exit;
   end;
if not chkUseLargeForSmall.Checked and (in_file_small = '') then
   begin
   ModalResult := mrNone;
   ShowMessage('Either select an image for the small sprite or enable the option "Use same file for small image!');
   Exit;
   end;

ProcessLargeImage;
ProcessSmallImage;

in_file_large := '';
in_file_small := '';

// keep a copy of the selected background images
old_file_bg_large := in_file_bg_large;
old_file_bg_small := in_file_bg_small;

end;

procedure TfrmSelectImage.FormCreate(Sender: TObject);
begin
btnUseDefaultBgImageClick(Sender); // load default background resources
end;
procedure TfrmSelectImage.FormShow(Sender: TObject);
var png: TPortableNetworkGraphic;
begin
in_file_large := '';
in_file_small := '';

in_file_bg_large := old_file_bg_large;
in_file_bg_small := old_file_bg_small;

png := TPortableNetworkGraphic.Create;
png.Width := spriteSizeLarge;
png.Height := spriteSizeLarge;
png.Canvas.Brush.Color:= $00FFFFDD;
png.Canvas.Brush.Style:= bsSolid;
png.Canvas.FillRect(0,0,spriteSizeLarge, spriteSizeLarge);
imgFrontLarge.Picture.Assign(png);
imgUserBgLarge.Picture.Assign(png);

png := TPortableNetworkGraphic.Create;
png.Width := spriteSizeSmall;
png.Height := spriteSizeSmall;
png.Canvas.Brush.Color:= $00FFFFDD;
png.Canvas.Brush.Style:= bsSolid;
png.Canvas.FillRect(0,0,spriteSizeLarge, spriteSizeLarge);
imgFrontSmall.Picture.Assign(png);
imgUserBgSmall.Picture.Assign(png);

png.Free;

PageControl1.ActivePageIndex := 0;
ActiveControl := btnLoadImageLarge;

updateBgImageView(Sender);

imgLarge.Picture.Assign(imgBgLarge.Picture);
imgSmall.Picture.Assign(imgBgSmall.Picture);


end;

procedure TfrmSelectImage.updateBgImageView(Sender: TObject);
begin
ProcessLargeBgImage;
ProcessSmallBgImage;
end;

procedure TfrmSelectImage.updateImageView(Sender: TObject);
begin
ProcessLargeImage;
ProcessSmallImage;
end;


end.

