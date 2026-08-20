unit object_handler;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, ExtCtrls, Graphics, DateUtils, StrUtils,
  baseConvert,
  { core library files }
  LocoSawyer,
  LocoTypes,
  LocoObjectFile,
  LocoStringTable,
  LocoImageTable,
  LocoObjectDefs,
  LocoObjectSprites,
  LocoSprite,
  LocoPng,
  LocoCompetitorObjectFile { actual object code }
  ;

function VerifyObject(filename: string): boolean;
procedure LoadObject(filename: string);
procedure SaveObject(filename: string);

function SetNewObjectId: string;

implementation

uses uMain;

const
  prefix_name_bytes = #136;

{ private use - load the specified sprite in the specified image }
procedure SetSpriteInForm(source_obj:TLocoCompetitorObjectFile; idx:integer; dest:TImage);
var ms:TMemoryStream;
begin
ms:= TMemoryStream.Create;
ExportElementToPNGStream(source_obj.ImageTable, idx, ms);
ms.Position:= 0;
dest.Picture.LoadFromStream(ms);
ms.Free;
end;

{ private use - save the specified sprite to the loco image table }
procedure SetSpriteFromForm(src:TImage; var dest:TLocoImageTable);
var ms:TMemoryStream;
    png:TPortableNetworkGraphic;
begin
ms:= TMemoryStream.Create;
// we use an explicit PNG image here as source might not be a PNG graphic
png := TPortableNetworkGraphic.Create;
png.Width := src.Picture.Width;
png.Height:= src.Picture.Height;
png.Canvas.Draw(0, 0, src.Picture.Graphic);
png.SaveToStream(ms);

ms.Position := 0;
AddElementFromPNGStream(dest, ms, false);

ms.Free;
png.Free;
end;

function VerifyObject(filename: string): boolean;
var
  peek: TLocoObjectFile;
  objType: TLocoObjectType;
begin
Result := false;

if IsValidLocoObjectFile(filename) then
begin
try
  peek := TLocoObjectFile.LoadFromFile(filename);
except
  on E: Exception do
     begin
     end;
end;

if peek <> nil then
   begin
   objType := peek.ObjectType;
   if objType = otCompetitor then Result := true;
   peek.Free;
   end;

end;

end;

procedure LoadObject(filename: string);
var obj: TLocoCompetitorObjectFile;
    obj_src: TLocoSourceGame;
    i: integer;
    //enabled_emotions: integer;
    s: string;
    ms:TMemoryStream;
begin
obj := TLocoCompetitorObjectFile.LoadFromFile(filename);

frmMain.edOwnerName.Text := Copy(obj.FirstNames[0].text, 2, Length(obj.FirstNames[0].text));
frmMain.edCompanyName.Text := obj.LastNames[0].text;

//frmMain.edChecksum.Text := IntToStr(ByteLength(obj.FirstNames[0].Text)) + ' / '+IntToStr(Length(obj.FirstNames[0].Text));
//s := obj.FirstNames[0].text;    frmMain.edChecksum.Text := '';
//for i:= 1 to Length(s) do frmMain.edChecksum.Text := frmMain.edChecksum.Text + ' ' + IntToStr(Ord(s[i]));

//s := prefix_name_bytes;    frmMain.edChecksumHex.Text := '';
//for i:= 1 to Length(s) do frmMain.edChecksumHex.Text := frmMain.edChecksumHex.Text + ' ' + IntToStr(Ord(s[i]));

for i := 0 to High(obj.FirstNames) do
    frmMain.owner_names[ ord(obj.FirstNames[i].LanguageId) ] := Copy(obj.FirstNames[i].text, 2, Length(obj.FirstNames[i].text));

for i := 0 to High(obj.LastNames) do
    frmMain.company_names[ ord(obj.LastNames[i].LanguageId) ] := obj.LastNames[i].text;

//enabled_emotions := 1;   // neutral emotion must always be enabled

{ emotions }
frmMain.chkEmotionHappy.Checked := obj.EmotionFlag[1];
frmMain.chkEmotionWorried.Checked := obj.EmotionFlag[2];
frmMain.chkEmotionThinking.Checked := obj.EmotionFlag[3];
frmMain.chkEmotionDejected.Checked := obj.EmotionFlag[4];
frmMain.chkEmotionSurprised.Checked := obj.EmotionFlag[5];
frmMain.chkEmotionScared.Checked := obj.EmotionFlag[6];
frmMain.chkEmotionAngry.Checked := obj.EmotionFlag[7];
frmMain.chkEmotionDisgusted.Checked := obj.EmotionFlag[8];

//if frmMain.chkEmotionHappy.Checked then Inc(enabled_emotions);
//if frmMain.chkEmotionWorried.Checked then Inc(enabled_emotions);
//if frmMain.chkEmotionThinking.Checked then Inc(enabled_emotions);
//if frmMain.chkEmotionDejected.Checked then Inc(enabled_emotions);
//if frmMain.chkEmotionSurprised.Checked then Inc(enabled_emotions);
//if frmMain.chkEmotionScared.Checked then Inc(enabled_emotions);
//if frmMain.chkEmotionAngry.Checked then Inc(enabled_emotions);
//if frmMain.chkEmotionDisgusted.Checked then Inc(enabled_emotions);

{ available name prefixes }
frmMain.chkNamePrefix1.Checked := obj.AvailableNamePrefixFlag[0];
frmMain.chkNamePrefix2.Checked := obj.AvailableNamePrefixFlag[1];
frmMain.chkNamePrefix3.Checked := obj.AvailableNamePrefixFlag[2];
frmMain.chkNamePrefix4.Checked := obj.AvailableNamePrefixFlag[3];
frmMain.chkNamePrefix5.Checked := obj.AvailableNamePrefixFlag[4];
frmMain.chkNamePrefix6.Checked := obj.AvailableNamePrefixFlag[5];
frmMain.chkNamePrefix7.Checked := obj.AvailableNamePrefixFlag[6];
frmMain.chkNamePrefix8.Checked := obj.AvailableNamePrefixFlag[7];
frmMain.chkNamePrefix9.Checked := obj.AvailableNamePrefixFlag[8];
frmMain.chkNamePrefix10.Checked := obj.AvailableNamePrefixFlag[9];
frmMain.chkNamePrefix11.Checked := obj.AvailableNamePrefixFlag[10];
frmMain.chkNamePrefix12.Checked := obj.AvailableNamePrefixFlag[11];
frmMain.chkNamePrefix13.Checked := obj.AvailableNamePrefixFlag[12];
{ available play styles }
frmMain.chkNameSuffix1.Checked := obj.AvailablePlayStyleFlag[0];
frmMain.chkNameSuffix2.Checked := obj.AvailablePlayStyleFlag[1];
frmMain.chkNameSuffix3.Checked := obj.AvailablePlayStyleFlag[2];
frmMain.chkNameSuffix4.Checked := obj.AvailablePlayStyleFlag[3];
frmMain.chkNameSuffix5.Checked := obj.AvailablePlayStyleFlag[4];
frmMain.chkNameSuffix6.Checked := obj.AvailablePlayStyleFlag[5];
frmMain.chkNameSuffix7.Checked := obj.AvailablePlayStyleFlag[6];
frmMain.chkNameSuffix8.Checked := obj.AvailablePlayStyleFlag[7];
frmMain.chkNameSuffix9.Checked := obj.AvailablePlayStyleFlag[8];
frmMain.chkNameSuffix10.Checked := obj.AvailablePlayStyleFlag[9];
frmMain.chkNameSuffix11.Checked := obj.AvailablePlayStyleFlag[10];
frmMain.chkNameSuffix12.Checked := obj.AvailablePlayStyleFlag[11];
frmMain.chkNameSuffix13.Checked := obj.AvailablePlayStyleFlag[12];


frmMain.tbIntelligence.Position := obj.Intelligence;
frmMain.tbAggressiveness.Position := obj.Aggressiveness;
frmMain.tbCompetitiveness.Position := obj.Competitiveness;

{ object header }
frmMain.edObjectID.Text := obj.ObjectName;
frmMain.edChecksum.Text := IntToStr(obj.Header.Checksum);
frmMain.edChecksumHex.Text := intToBaseStr(obj.Header.Checksum, 16);

{ object source }
obj_src := GetSourceGame(obj.Header);
if obj_src = sgVanilla then frmMain.selObjectSource.ItemIndex := 2
else
if obj_src = sgOpenLoco then frmMain.selObjectSource.ItemIndex := 1
else
  frmMain.selObjectSource.ItemIndex := 0;

{ images }
{
if (High(obj.ImageTable.Elements)+1) = (enabled_emotions*2) then
   begin
    if G1ElementHasFlag(obj.ImageTable.Elements[i], gfDuplicatePrevious) then
       begin
       // duplicate previous sprite
       end;
   end
else ShowMessage('Sprite count mismatch');
}



i := 0;
// neutral emotion
SetSpriteInForm(obj, 0, frmMain.imgNeutralSmall);
SetSpriteInForm(obj, 1, frmMain.imgNeutralLarge);
{ms:= TMemoryStream.Create;
ExportElementToPNGStream(obj.ImageTable, 0, ms);
ms.Position:= 0;
frmMain.imgNeutralSmall.Picture.LoadFromStream(ms);
ms.Free;

ms:= TMemoryStream.Create;
ExportElementToPNGStream(obj.ImageTable, 1, ms);
ms.Position:= 0;
frmMain.imgNeutralLarge.Picture.LoadFromStream(ms);
ms.Free;  }

i := i+2;

// happy emotion
if obj.EmotionFlag[1] then
   begin
   SetSpriteInForm(obj, i, frmMain.imgHappySmall);
   SetSpriteInForm(obj, i+1, frmMain.imgHappyLarge);
   i := i+2;
   end;
if obj.EmotionFlag[2] then
   begin
   SetSpriteInForm(obj, i, frmMain.imgWorriedSmall);
   SetSpriteInForm(obj, i+1, frmMain.imgWorriedLarge);
   i := i+2;
   end;
if obj.EmotionFlag[3] then
   begin
   SetSpriteInForm(obj, i, frmMain.imgThinkingSmall);
   SetSpriteInForm(obj, i+1, frmMain.imgThinkingLarge);
   i := i+2;
   end;
if obj.EmotionFlag[4] then
   begin
   SetSpriteInForm(obj, i, frmMain.imgDejectedSmall);
   SetSpriteInForm(obj, i+1, frmMain.imgDejectedLarge);
   i := i+2;
   end;
if obj.EmotionFlag[5] then
   begin
   SetSpriteInForm(obj, i, frmMain.imgSurprisedSmall);
   SetSpriteInForm(obj, i+1, frmMain.imgSurprisedLarge);
   i := i+2;
   end;
if obj.EmotionFlag[6] then
   begin
   SetSpriteInForm(obj, i, frmMain.imgScaredSmall);
   SetSpriteInForm(obj, i+1, frmMain.imgScaredLarge);
   i := i+2;
   end;
if obj.EmotionFlag[7] then
   begin
   SetSpriteInForm(obj, i, frmMain.imgAngrySmall);
   SetSpriteInForm(obj, i+1, frmMain.imgAngryLarge);
   i := i+2;
   end;
if obj.EmotionFlag[7] then
   begin
   SetSpriteInForm(obj, i, frmMain.imgDisgustedSmall);
   SetSpriteInForm(obj, i+1, frmMain.imgDisgustedLarge);
   end;

obj.Free;
end;


procedure SaveObject(filename: string);
var obj:TLocoCompetitorObjectFile;
    header:TObjectHeader;
    s: String;
    object_source: TLocoSourceGame;
    ownerName, companyName: array of TLocoStringEntry;

    i: integer;
    sprites: TLocoImageTable;

begin
{ object source }
if frmMain.selObjectSource.ItemIndex = 2 then object_source := sgVanilla
else
if frmMain.selObjectSource.ItemIndex = 1 then object_source := sgOpenLoco
else object_source := sgCustom;

s := frmMain.edObjectID.Text;
if s = '' then s := SetNewObjectId; // ensure we have an id
obj := TLocoCompetitorObjectFile.CreateNew(frmMain.edObjectID.Text, object_source);

obj.Intelligence:= frmMain.tbIntelligence.Position;
obj.Aggressiveness:= frmMain.tbAggressiveness.Position;
obj.Competitiveness:= frmMain.tbCompetitiveness.Position;

{ available name prefixes }
obj.AvailableNamePrefixFlag[0] := frmMain.chkNamePrefix1.Checked;
obj.AvailableNamePrefixFlag[1] := frmMain.chkNamePrefix2.Checked;
obj.AvailableNamePrefixFlag[2] := frmMain.chkNamePrefix3.Checked;
obj.AvailableNamePrefixFlag[3] := frmMain.chkNamePrefix4.Checked;
obj.AvailableNamePrefixFlag[4] := frmMain.chkNamePrefix5.Checked;
obj.AvailableNamePrefixFlag[5] := frmMain.chkNamePrefix6.Checked;
obj.AvailableNamePrefixFlag[6] := frmMain.chkNamePrefix7.Checked;
obj.AvailableNamePrefixFlag[7] := frmMain.chkNamePrefix8.Checked;
obj.AvailableNamePrefixFlag[8] := frmMain.chkNamePrefix9.Checked;
obj.AvailableNamePrefixFlag[9] := frmMain.chkNamePrefix10.Checked;
obj.AvailableNamePrefixFlag[10] := frmMain.chkNamePrefix11.Checked;
obj.AvailableNamePrefixFlag[11] := frmMain.chkNamePrefix12.Checked;
obj.AvailableNamePrefixFlag[12] := frmMain.chkNamePrefix13.Checked;
{ available play styles }
obj.AvailablePlayStyleFlag[0] := frmMain.chkNameSuffix1.Checked;
obj.AvailablePlayStyleFlag[1] := frmMain.chkNameSuffix2.Checked;
obj.AvailablePlayStyleFlag[2] := frmMain.chkNameSuffix3.Checked;
obj.AvailablePlayStyleFlag[3] := frmMain.chkNameSuffix4.Checked;
obj.AvailablePlayStyleFlag[4] := frmMain.chkNameSuffix5.Checked;
obj.AvailablePlayStyleFlag[5] := frmMain.chkNameSuffix6.Checked;
obj.AvailablePlayStyleFlag[6] := frmMain.chkNameSuffix7.Checked;
obj.AvailablePlayStyleFlag[7] := frmMain.chkNameSuffix8.Checked;
obj.AvailablePlayStyleFlag[8] := frmMain.chkNameSuffix9.Checked;
obj.AvailablePlayStyleFlag[9] := frmMain.chkNameSuffix10.Checked;
obj.AvailablePlayStyleFlag[10] := frmMain.chkNameSuffix11.Checked;
obj.AvailablePlayStyleFlag[11] := frmMain.chkNameSuffix12.Checked;
obj.AvailablePlayStyleFlag[12] := frmMain.chkNameSuffix13.Checked;

// strings table
if frmMain.chkUseDifferentLanguageNames.Checked then
   begin
   // fill only empty name strings
   for i := 0 to 13 do
       if frmMain.owner_names[i] = '' then frmMain.owner_names[i] := frmMain.edOwnerName.Text;

   for i := 0 to 13 do
       if frmMain.company_names[i] = '' then frmMain.company_names[i] := frmMain.edCompanyName.Text;
   end
else
   begin
   // owner names
   for i := 0 to 13 do frmMain.owner_names[i] := frmMain.edOwnerName.Text;
   // company names
   for i := 0 to 13 do frmMain.company_names[i] := frmMain.edCompanyName.Text;
   end;


SetLength(ownerName, 14);
for i:= 0 to 13 do
    begin
    ownerName[i].LanguageId := i;
    ownerName[i].Text := prefix_name_bytes + frmMain.owner_names[i]; //frmMain.edOwnerName.Text;
    end;
obj.FirstNames := ownerName;

SetLength(companyName, 14);
for i:= 0 to 13 do
    begin
    companyName[i].LanguageId := i;
    companyName[i].Text := frmMain.company_names[i]; //frmMain.edCompanyName.Text;
    end;
obj.LastNames := companyName;


// emotions and sprites
obj.EmotionFlag[0] := true;

//SetLength(sprites.Elements, 2);
SetSpriteFromForm(frmMain.imgNeutralSmall, sprites);
SetSpriteFromForm(frmMain.imgNeutralLarge, sprites);

if frmMain.chkEmotionHappy.Checked then
   begin
   obj.EmotionFlag[1] := true;

   SetSpriteFromForm(frmMain.imgHappySmall, sprites);
   SetSpriteFromForm(frmMain.imgHappyLarge, sprites);
   end;

if frmMain.chkEmotionWorried.Checked then
   begin
   obj.EmotionFlag[2] := true;

   SetSpriteFromForm(frmMain.imgWorriedSmall, sprites);
   SetSpriteFromForm(frmMain.imgWorriedLarge, sprites);
   end;

if frmMain.chkEmotionThinking.Checked then
   begin
   obj.EmotionFlag[3] := true;

   SetSpriteFromForm(frmMain.imgThinkingSmall, sprites);
   SetSpriteFromForm(frmMain.imgThinkingLarge, sprites);
   end;

if frmMain.chkEmotionDejected.Checked then
   begin
   obj.EmotionFlag[4] := true;

   SetSpriteFromForm(frmMain.imgDejectedSmall, sprites);
   SetSpriteFromForm(frmMain.imgDejectedLarge, sprites);
   end;

if frmMain.chkEmotionSurprised.Checked then
   begin
   obj.EmotionFlag[5] := true;

   SetSpriteFromForm(frmMain.imgSurprisedSmall, sprites);
   SetSpriteFromForm(frmMain.imgSurprisedLarge, sprites);
   end;

if frmMain.chkEmotionScared.Checked then
   begin
   obj.EmotionFlag[6] := true;

   SetSpriteFromForm(frmMain.imgScaredSmall, sprites);
   SetSpriteFromForm(frmMain.imgScaredLarge, sprites);
   end;

if frmMain.chkEmotionAngry.Checked then
   begin
   obj.EmotionFlag[7] := true;

   SetSpriteFromForm(frmMain.imgAngrySmall, sprites);
   SetSpriteFromForm(frmMain.imgAngryLarge, sprites);
   end;

if frmMain.chkEmotionDisgusted.Checked then
   begin
   obj.EmotionFlag[8] := true;

   SetSpriteFromForm(frmMain.imgDisgustedSmall, sprites);
   SetSpriteFromForm(frmMain.imgDisgustedLarge, sprites);
   end;

{ save image table }
obj.ImageTable := sprites;

obj.UpdateChecksum;
obj.SaveToFile(filename, TSawyerEncoding.seUncompressed);

frmMain.edObjectID.Text := obj.ObjectName;
// show new checksum
frmMain.edChecksum.Text := IntToStr(obj.Header.Checksum);
frmMain.edChecksumHex.Text := intToBaseStr(obj.Header.Checksum, 16);

obj.Free;
end;


function SetNewObjectId: string;
begin
Result := 'CE' + AddChar('0', baseToBase(IntToStr(DayOfTheYear(Now)), 10, 36), 2)
               + AddChar('0', baseToBase(IntToStr(SecondOfTheDay(Now)), 10, 36), 4);
end;

end.

