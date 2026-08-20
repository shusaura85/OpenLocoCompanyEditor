{
  LocoSprite.pas

  Codec for an individual sprite's *pixel* data - the bytes a G1Element's
  Offset points at within an image table's pixel blob. This is a completely
  different, unrelated encoding from the Sawyer stream chunk encoding
  (LocoSawyer.pas): it operates on already-decoded object data, and is the
  same per-sprite format Locomotion/OpenLoco use for the game's whole G1.DAT
  graphics file too.

  Transcribed from OpenLoco's sprite blitters, which are read/decode logic
  in reverse:
    - include/OpenLoco/Graphics/DrawSpriteRLE.hpp  (drawRLESprite)
    - include/OpenLoco/Graphics/DrawSpriteBMP.hpp  (drawBMPSprite)
    - src/Graphics/SoftwareDrawingContext.cpp        (isRLECompressed dispatch)
    - include/OpenLoco/Graphics/DrawSprite.h         ("Pixel value of 0
      represents transparent" - BITMAP only; RLE encodes transparency via
      the run-length gaps themselves)

  Two on-disk formats, selected by G1ElementFlags.isRLECompressed:

    BMP (uncompressed):
      Width*Height bytes, row-major, one palette-index byte per pixel.
      No transparency is stored in the data itself.

    RLE:
      Height * 2 bytes: per-row UInt16 LE byte offsets (relative to the
      start of this sprite's own pixel data) to that row's run list.
      Each row is then a sequence of runs:
        Byte  dataSize    bit 7 = last run in this row, bits 0-6 = pixel count (0-127)
        Byte  firstPixelX  x coordinate (within the row) of this run's first pixel
        Byte[pixel count]  raw palette-index bytes
      x positions not covered by any run are transparent gaps.

  Part of the LocoDat Pascal library.
}
unit LocoSprite;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils;

type
  ELocoSpriteError = class(Exception);

  { A fully decoded sprite, one entry per pixel, row-major (index = y*Width+x). }
  TLocoSpritePixels = record
    Width, Height: Integer;
    Indices: TBytes;          // palette index per pixel; meaningless where Opaque[i] = False
    Opaque: TArray<Boolean>;   // False = transparent pixel
  end;

{ Decodes Width x Height pixels starting at PixelData[ElementOffset], using
  the BMP or RLE format according to IsRLE (pass
  G1ElementHasFlag(element, gfIsRLECompressed), from LocoTypes). }
function DecodeSpritePixels(const PixelData: TBytes; ElementOffset, Width, Height: Integer;
  IsRLE: Boolean): TLocoSpritePixels;

{ Encodes Pixels back to on-disk sprite bytes in the requested format.
  For RLE, note that a single run is limited to 127 pixels (dataSize is a
  7-bit field) and firstPixelX is a single byte, so Width must be <= 255 -
  both are real limits of the original format, not something added here. }
function EncodeSpritePixels(const Pixels: TLocoSpritePixels; IsRLE: Boolean): TBytes;

implementation

function DecodeSpritePixels(const PixelData: TBytes; ElementOffset, Width, Height: Integer;
  IsRLE: Boolean): TLocoSpritePixels;
var
  x, y, idx, k: Integer;
  pos, lineOffset, dataSizeByte, firstPixelX, numPixels: Integer;
  isEndOfLine: Boolean;
  dataLen: Integer;
begin
  if (Width <= 0) or (Height <= 0) then
    raise ELocoSpriteError.Create('Sprite width/height must be positive');

  Result.Width := Width;
  Result.Height := Height;
  SetLength(Result.Indices, Width * Height);
  SetLength(Result.Opaque, Width * Height); // dynamic array: defaults to False

  dataLen := Length(PixelData);

  if not IsRLE then
  begin
    if ElementOffset + Width * Height > dataLen then
      raise ELocoSpriteError.Create('BMP sprite data truncated');
    for idx := 0 to Width * Height - 1 do
    begin
      Result.Indices[idx] := PixelData[ElementOffset + idx];
      Result.Opaque[idx] := True;
    end;
    Exit;
  end;

  if ElementOffset + Height * 2 > dataLen then
    raise ELocoSpriteError.Create('RLE sprite row-offset table truncated');

  for y := 0 to Height - 1 do
  begin
    lineOffset := PixelData[ElementOffset + y * 2] or (PixelData[ElementOffset + y * 2 + 1] shl 8);
    pos := ElementOffset + lineOffset;
    isEndOfLine := False;
    while not isEndOfLine do
    begin
      if pos + 1 >= dataLen then
        raise ELocoSpriteError.Create('RLE sprite run header truncated');
      dataSizeByte := PixelData[pos];
      firstPixelX := PixelData[pos + 1];
      Inc(pos, 2);
      isEndOfLine := (dataSizeByte and $80) <> 0;
      numPixels := dataSizeByte and $7F;

      if pos + numPixels > dataLen then
        raise ELocoSpriteError.Create('RLE sprite run data truncated');

      for k := 0 to numPixels - 1 do
      begin
        x := firstPixelX + k;
        if (x >= 0) and (x < Width) then
        begin
          idx := y * Width + x;
          Result.Indices[idx] := PixelData[pos + k];
          Result.Opaque[idx] := True;
        end;
      end;
      Inc(pos, numPixels);
    end;
  end;
end;

type
  TRun = record
    FirstX, Count: Integer;
  end;

function BuildRowRuns(const Pixels: TLocoSpritePixels; y: Integer): TArray<TRun>;
var
  x, w, runStart, runLen, n: Integer;
  runs: TArray<TRun>;
begin
  w := Pixels.Width;
  SetLength(runs, 0);
  n := 0;
  x := 0;
  while x < w do
  begin
    if Pixels.Opaque[y * w + x] then
    begin
      runStart := x;
      runLen := 0;
      while (x < w) and Pixels.Opaque[y * w + x] and (runLen < 127) do
      begin
        Inc(runLen);
        Inc(x);
      end;
      SetLength(runs, n + 1);
      runs[n].FirstX := runStart;
      runs[n].Count := runLen;
      Inc(n);
    end
    else
      Inc(x);
  end;

  if n = 0 then
  begin
    // Entirely transparent row: still needs one (empty) terminating run.
    SetLength(runs, 1);
    runs[0].FirstX := 0;
    runs[0].Count := 0;
  end;

  Result := runs;
end;

function EncodeSpritePixels(const Pixels: TLocoSpritePixels; IsRLE: Boolean): TBytes;
var
  w, h, i, y, idx: Integer;
  allRuns: TArray<TArray<TRun>>;
  rowOffset: TArray<UInt32>;
  offset: Int64;
  ms: TMemoryStream;
  b: Byte;
begin
  w := Pixels.Width;
  h := Pixels.Height;

  if (w <= 0) or (h <= 0) then
    raise ELocoSpriteError.Create('Sprite width/height must be positive');
  if w > 255 then
    raise ELocoSpriteError.Create('Sprite width > 255 cannot be represented (firstPixelX is a single byte)');

  if not IsRLE then
  begin
    SetLength(Result, w * h);
    for idx := 0 to w * h - 1 do
    begin
      if Pixels.Opaque[idx] then
        Result[idx] := Pixels.Indices[idx]
      else
        Result[idx] := 0; // BMP format has no transparency of its own; 0 is the game's convention
    end;
    Exit;
  end;

  SetLength(allRuns, h);
  for y := 0 to h - 1 do
    allRuns[y] := BuildRowRuns(Pixels, y);

  SetLength(rowOffset, h);
  offset := h * 2;
  for y := 0 to h - 1 do
  begin
    if offset > 65535 then
      raise ELocoSpriteError.Create('Sprite too large to RLE-encode (row offset exceeds 65535 bytes)');
    rowOffset[y] := UInt32(offset);
    for i := 0 to High(allRuns[y]) do
      Inc(offset, 2 + allRuns[y][i].Count);
  end;

  ms := TMemoryStream.Create;
  try
    for y := 0 to h - 1 do
    begin
      b := Byte(rowOffset[y] and $FF);
      ms.WriteBuffer(b, 1);
      b := Byte((rowOffset[y] shr 8) and $FF);
      ms.WriteBuffer(b, 1);
    end;

    for y := 0 to h - 1 do
    begin
      for i := 0 to High(allRuns[y]) do
      begin
        b := Byte(allRuns[y][i].Count);
        if i = High(allRuns[y]) then
          b := b or $80;
        ms.WriteBuffer(b, 1);

        b := Byte(allRuns[y][i].FirstX);
        ms.WriteBuffer(b, 1);

        if allRuns[y][i].Count > 0 then
          ms.WriteBuffer(Pixels.Indices[y * w + allRuns[y][i].FirstX], allRuns[y][i].Count);
      end;
    end;

    SetLength(Result, ms.Size);
    if ms.Size > 0 then
    begin
      ms.Position := 0;
      ms.ReadBuffer(Result[0], ms.Size);
    end;
  finally
    ms.Free;
  end;
end;

end.
