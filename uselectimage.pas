unit uselectimage;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ExtDlgs,
  { image manipulation units }
  BGRABitmap, BGRABitmapTypes, BGRAPalette, BGRAColorQuantization;

type

  { TfrmSelectImage }

  TfrmSelectImage = class(TForm)
    Bevel1: TBevel;
    btnLoadImageLarge: TButton;
    btnLoadImageSmall: TButton;
    btnOk: TButton;
    btnCancel: TButton;
    chkUseLargeForSmall: TCheckBox;
    selColorPalette: TComboBox;
    Label4: TLabel;
    selResize: TComboBox;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    imgLarge: TImage;
    imgBgLarge: TImage;
    imgSmall: TImage;
    imgBgSmall: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    OpenPictureDialog1: TOpenPictureDialog;
    chkPalette: TRadioGroup;
    procedure btnLoadImageLargeClick(Sender: TObject);
    procedure btnLoadImageSmallClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    Quantizer: TBGRAColorQuantizer;      { handles resize and color palette }
    WorkPalette: TBGRAIndexedPalette;    { holds the loco color palette }

    procedure LoadColorPalette;
    procedure ProcessLargeImage;
    procedure ProcessSmallImage;
  public
    img: TBGRABitmap;
    in_file_large: string;
    in_file_small: string;

  end;

var
  frmSelectImage: TfrmSelectImage;

implementation

{$R *.lfm}

uses uMain;

{ TfrmSelectImage }

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

procedure TfrmSelectImage.ProcessLargeImage;
var Image: TBGRABitmap;
    new_x, new_y, new_w, new_h: integer;
    ar: Double;
begin
LoadColorPalette;

//Image := TBGRABitmap.Create(imgBgLarge.Picture.Bitmap);
Image := TBGRABitmap.Create(in_file_large);
//Image.SaveToFile('prequantized_image.png');

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


Image := Image.Resample(new_w, new_h, TResampleMode.rmFineResample);
//Image.SaveToFile('resampled_image.png');


if chkPalette.ItemIndex <> 2 then
   begin
   Quantizer := TBGRAColorQuantizer.Create(WorkPalette, false, 256);
   try
     if chkPalette.ItemIndex = 1 then Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daFloydSteinberg, Image)
                                 else Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daNearestNeighbor, Image);

    // Image.SaveToFile('quantized_image.png');
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
LoadColorPalette;

// use large file if checked
if chkUseLargeForSmall.Checked then in_file_small := in_file_large;


//Image := TBGRABitmap.Create(imgBgLarge.Picture.Bitmap);
Image := TBGRABitmap.Create(in_file_small);
//Image.SaveToFile('prequantized_image.png');

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


Image := Image.Resample(new_w, new_h, TResampleMode.rmFineResample);
//Image.SaveToFile('resampled_image.png');


if chkPalette.ItemIndex <> 2 then
   begin
   Quantizer := TBGRAColorQuantizer.Create(WorkPalette, false, 256);
   try
     if chkPalette.ItemIndex = 1 then Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daFloydSteinberg, Image)
                                 else Quantizer.ApplyDitheringInplace(TDitheringAlgorithm.daNearestNeighbor, Image);

    // Image.SaveToFile('quantized_image.png');
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
     imgLarge.Picture.LoadFromFile(in_file_large);

     if chkUseLargeForSmall.Checked then
        begin
        in_file_small := in_file_large;
        imgSmall.Picture.LoadFromFile(in_file_small);
        end;
     end;
end;

procedure TfrmSelectImage.btnLoadImageSmallClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
     begin
     // reset use same file for small image if set
     if chkUseLargeForSmall.Checked then chkUseLargeForSmall.Checked := false;

     in_file_small := OpenPictureDialog1.FileName;
     imgSmall.Picture.LoadFromFile(in_file_small);
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
end;


procedure TfrmSelectImage.FormShow(Sender: TObject);
var png: TPortableNetworkGraphic;
begin
png := TPortableNetworkGraphic.Create;
png.Width := spriteSizeLarge;
png.Height := spriteSizeLarge;
png.Canvas.Brush.Color:= $00FFFFDD;
png.Canvas.Brush.Style:= bsSolid;
png.Canvas.FillRect(0,0,spriteSizeLarge, spriteSizeLarge);
imgLarge.Picture.Assign(png);

png := TPortableNetworkGraphic.Create;
png.Width := spriteSizeSmall;
png.Height := spriteSizeSmall;
png.Canvas.Brush.Color:= $00FFFFDD;
png.Canvas.Brush.Style:= bsSolid;
png.Canvas.FillRect(0,0,spriteSizeLarge, spriteSizeLarge);
imgSmall.Picture.Assign(png);

png.Free;

ActiveControl := btnLoadImageLarge;

end;

end.

