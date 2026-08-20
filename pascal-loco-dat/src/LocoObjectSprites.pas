{
  LocoObjectSprites.pas

  High-level "one sprite in, one sprite out" API for exporting individual
  images from a TLocoImageTable (LocoImageTable.pas) to PNG and importing
  them back, going through the sprite pixel codec (LocoSprite.pas) and PNG
  codec (LocoPng.pas). This is the unit most callers want; LocoSprite.pas
  and LocoPng.pas are the lower-level pieces it's built from.

  Part of the LocoDat Pascal library.
}
unit LocoObjectSprites;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, LocoTypes, LocoImageTable, LocoSprite, LocoPng;

{ Decodes image table element Index and writes it out as a PNG (8-bit RGBA;
  see LocoPng.pas for why RGBA rather than an indexed PNG). }
procedure ExportElementToPNG(const Table: TLocoImageTable; Index: Integer; const FileName: string);

{ As ExportElementToPNG, but writes the encoded PNG to Stream instead of a file. }
procedure ExportElementToPNGStream(const Table: TLocoImageTable; Index: Integer; Stream: TStream);

{ Reads FileName and replaces element Index's pixel data with it, keeping
  that element's current encoding (RLE vs BMP - whichever it already used).
  Updates Elements[Index].Width/Height and re-splices PixelData, shifting
  every later element's Offset to account for the size change. Raises if
  Index refers to a gfDuplicatePrevious element (those own no pixel data of
  their own - see LocoTypes.TG1ElementFlag) - replace the element it
  duplicates instead. }
procedure ImportElementFromPNG(var Table: TLocoImageTable; Index: Integer; const FileName: string);

{ As ImportElementFromPNG, but reads the PNG from Stream instead of a file. }
procedure ImportElementFromPNGStream(var Table: TLocoImageTable; Index: Integer; Stream: TStream);

{ As ImportElementFromPNG, but lets you force the on-disk encoding instead
  of keeping the element's current one. }
procedure ImportElementFromPNGAs(var Table: TLocoImageTable; Index: Integer;
  const FileName: string; UseRLE: Boolean);

{ As ImportElementFromPNGAs, but reads the PNG from Stream instead of a file. }
procedure ImportElementFromPNGStreamAs(var Table: TLocoImageTable; Index: Integer;
  Stream: TStream; UseRLE: Boolean);

{ Appends a new element to the end of the image table, populated from the
  PNG at FileName, and returns its new index. Use this instead of
  ImportElementFromPNG(As) when you're growing the table (adding a sprite
  that doesn't exist yet) rather than replacing an existing element's art -
  ImportElementFromPNG(As)/ReplaceElementPixels all require Index to already
  refer to a populated element and will corrupt the table if used to append. }
function AddElementFromPNG(var Table: TLocoImageTable; const FileName: string;
  UseRLE: Boolean): Integer;

{ As AddElementFromPNG, but reads the PNG from Stream instead of a file. }
function AddElementFromPNGStream(var Table: TLocoImageTable; Stream: TStream;
  UseRLE: Boolean): Integer;

{ Appends a new element to the end of the image table with the given
  in-memory Pixels - the primitive AddElementFromPNG(Stream) is built on.
  Returns the new element's index. XOffset/YOffset/ZoomOffset default to 0
  (a freshly authored sprite); pass explicit values to match the
  conventions of the surrounding table, e.g. giving every frame of an
  animation the same offsets. }
function AddElementPixels(var Table: TLocoImageTable; const Pixels: TLocoSpritePixels;
  UseRLE: Boolean; XOffset: SmallInt = 0; YOffset: SmallInt = 0; ZoomOffset: SmallInt = 0): Integer;

{ Replaces element Index's pixel data in memory (no file I/O) - the
  primitive ImportElementFromPNG(As) is built on. Useful if you're
  generating or editing pixels programmatically rather than via a PNG file. }
procedure ReplaceElementPixels(var Table: TLocoImageTable; Index: Integer;
  const Pixels: TLocoSpritePixels; UseRLE: Boolean);

implementation

procedure ExportElementToPNGStream(const Table: TLocoImageTable; Index: Integer; Stream: TStream);
var
  isRLE: Boolean;
  pixels: TLocoSpritePixels;
begin
  if (Index < 0) or (Index > High(Table.Elements)) then
    raise Exception.CreateFmt('Element index %d out of range (table has %d elements)',
      [Index, Length(Table.Elements)]);

  isRLE := G1ElementHasFlag(Table.Elements[Index], gfIsRLECompressed);
  pixels := DecodeSpritePixels(Table.PixelData, Integer(Table.Elements[Index].Offset),
    Table.Elements[Index].Width, Table.Elements[Index].Height, isRLE);
  ExportSpriteToPNGStream(pixels, Stream);
end;

procedure ExportElementToPNG(const Table: TLocoImageTable; Index: Integer; const FileName: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmCreate);
  try
    ExportElementToPNGStream(Table, Index, fs);
  finally
    fs.Free;
  end;
end;

procedure ReplaceElementPixels(var Table: TLocoImageTable; Index: Integer;
  const Pixels: TLocoSpritePixels; UseRLE: Boolean);
var
  oldOffset, oldLen, newLen, delta, tailLen, i: Integer;
  newPixelBytes, newBlob: TBytes;
begin
  if (Index < 0) or (Index > High(Table.Elements)) then
    raise Exception.CreateFmt('Element index %d out of range (table has %d elements)',
      [Index, Length(Table.Elements)]);
  if G1ElementHasFlag(Table.Elements[Index], gfDuplicatePrevious) then
    raise Exception.Create('Cannot replace pixels of a "duplicate previous" element - it owns no pixel data of its own; replace the element it duplicates instead');

  if not GetElementPixelRange(Table, Index, oldOffset, oldLen) then
    raise Exception.CreateFmt('Could not determine the current pixel range for element %d', [Index]);

  newPixelBytes := EncodeSpritePixels(Pixels, UseRLE);
  newLen := Length(newPixelBytes);
  delta := newLen - oldLen;

  SetLength(newBlob, Length(Table.PixelData) + delta);
  if oldOffset > 0 then
    Move(Table.PixelData[0], newBlob[0], oldOffset);
  if newLen > 0 then
    Move(newPixelBytes[0], newBlob[oldOffset], newLen);
  tailLen := Length(Table.PixelData) - (oldOffset + oldLen);
  if tailLen > 0 then
    Move(Table.PixelData[oldOffset + oldLen], newBlob[oldOffset + newLen], tailLen);
  Table.PixelData := newBlob;

  Table.Elements[Index].Width := Pixels.Width;
  Table.Elements[Index].Height := Pixels.Height;
  if UseRLE then
    Table.Elements[Index].Flags := Table.Elements[Index].Flags or (UInt16(1) shl Ord(gfIsRLECompressed))
  else
    Table.Elements[Index].Flags := Table.Elements[Index].Flags and not (UInt16(1) shl Ord(gfIsRLECompressed));

  // Elements are stored in ascending-Offset order (true for every vanilla
  // and OpenLoco object) - shift everything that came after the replaced
  // element's old data by the size delta. gfDuplicatePrevious elements'
  // Offset field is unused at runtime (they borrow the previous element's
  // pixels instead - see ObjectImageTable.cpp), so a stale value there is
  // harmless even if left unshifted.
  for i := 0 to High(Table.Elements) do
  begin
    if (i <> Index) and (Integer(Table.Elements[i].Offset) > oldOffset) then
      Table.Elements[i].Offset := UInt32(Integer(Table.Elements[i].Offset) + delta);
  end;

  Table.Header.NumEntries := Length(Table.Elements);
  Table.Header.TotalSize := Length(Table.PixelData);
end;

function AddElementPixels(var Table: TLocoImageTable; const Pixels: TLocoSpritePixels;
  UseRLE: Boolean; XOffset: SmallInt = 0; YOffset: SmallInt = 0; ZoomOffset: SmallInt = 0): Integer;
var
  newPixelBytes: TBytes;
  newElement: TG1Element32;
begin
  newPixelBytes := EncodeSpritePixels(Pixels, UseRLE);

  newElement.Offset := UInt32(Length(Table.PixelData));
  newElement.Width := Pixels.Width;
  newElement.Height := Pixels.Height;
  newElement.XOffset := XOffset;
  newElement.YOffset := YOffset;
  newElement.Flags := 0;
  if UseRLE then
    newElement.Flags := newElement.Flags or (UInt16(1) shl Ord(gfIsRLECompressed));
  newElement.ZoomOffset := ZoomOffset;

  // Pixel data is appended past the current end of the blob, so no other
  // element's Offset needs shifting (unlike ReplaceElementPixels, which
  // splices into the middle of the blob).
  SetLength(Table.PixelData, Length(Table.PixelData) + Length(newPixelBytes));
  if Length(newPixelBytes) > 0 then
    Move(newPixelBytes[0], Table.PixelData[Integer(newElement.Offset)], Length(newPixelBytes));

  SetLength(Table.Elements, Length(Table.Elements) + 1);
  Table.Elements[High(Table.Elements)] := newElement;
  Result := High(Table.Elements);

  Table.Header.NumEntries := Length(Table.Elements);
  Table.Header.TotalSize := Length(Table.PixelData);
end;

function AddElementFromPNGStream(var Table: TLocoImageTable; Stream: TStream;
  UseRLE: Boolean): Integer;
var
  pixels: TLocoSpritePixels;
begin
  pixels := ImportSpriteFromPNGStream(Stream);
  Result := AddElementPixels(Table, pixels, UseRLE);
end;

function AddElementFromPNG(var Table: TLocoImageTable; const FileName: string;
  UseRLE: Boolean): Integer;
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := AddElementFromPNGStream(Table, fs, UseRLE);
  finally
    fs.Free;
  end;
end;

procedure ImportElementFromPNGStreamAs(var Table: TLocoImageTable; Index: Integer;
  Stream: TStream; UseRLE: Boolean);
var
  pixels: TLocoSpritePixels;
begin
  pixels := ImportSpriteFromPNGStream(Stream);
  ReplaceElementPixels(Table, Index, pixels, UseRLE);
end;

procedure ImportElementFromPNGAs(var Table: TLocoImageTable; Index: Integer;
  const FileName: string; UseRLE: Boolean);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    ImportElementFromPNGStreamAs(Table, Index, fs, UseRLE);
  finally
    fs.Free;
  end;
end;

procedure ImportElementFromPNGStream(var Table: TLocoImageTable; Index: Integer; Stream: TStream);
var
  isRLE: Boolean;
begin
  if (Index < 0) or (Index > High(Table.Elements)) then
    raise Exception.CreateFmt('Element index %d out of range (table has %d elements)',
      [Index, Length(Table.Elements)]);
  isRLE := G1ElementHasFlag(Table.Elements[Index], gfIsRLECompressed);
  ImportElementFromPNGStreamAs(Table, Index, Stream, isRLE);
end;

procedure ImportElementFromPNG(var Table: TLocoImageTable; Index: Integer; const FileName: string);
var
  isRLE: Boolean;
begin
  if (Index < 0) or (Index > High(Table.Elements)) then
    raise Exception.CreateFmt('Element index %d out of range (table has %d elements)',
      [Index, Length(Table.Elements)]);
  isRLE := G1ElementHasFlag(Table.Elements[Index], gfIsRLECompressed);
  ImportElementFromPNGAs(Table, Index, FileName, isRLE);
end;

end.
