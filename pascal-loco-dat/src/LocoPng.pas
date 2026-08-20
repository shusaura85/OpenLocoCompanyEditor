{
  LocoPng.pas

  A small, self-contained PNG reader/writer used to export/import decoded
  sprite pixels. Implemented directly against the PNG specification (chunk
  framing, CRC32, scanline filtering) rather than FPC's higher-level
  fpImage/FPWritePNG classes, specifically so the on-disk pixel format is
  fully under our control and easy to verify - see "Why RGBA, not an
  indexed PNG" below.

  Compression uses Free Pascal's own zstream unit (TCompressionStream /
  TDecompressionStream, part of the standard "paszlib" package that ships
  with FPC) - only the raw DEFLATE/INFLATE work is delegated; chunk
  framing, filtering and colour handling are all done here.

  Exported PNGs are written as 8-bit RGBA (colour type 6):
    - every opaque pixel's RGB is one of the 256 LocoPalette colours
    - transparent pixels (from RLE sprite gaps) get alpha = 0

  Why RGBA, not an indexed PNG: PNG's indexed colour type expresses
  transparency via a tRNS table keyed by *palette index* - i.e. transparency
  becomes a property of a colour, not of a pixel. Locomotion's RLE sprite
  gaps are transparent independently of colour (a fully opaque black pixel,
  palette index 0, is common), so an indexed PNG using LocoPalette directly
  cannot represent both "opaque black" and "transparent" without collision.
  RGBA sidesteps this entirely and opens correctly with true colours in any
  image editor.

  ImportSpriteFromPNG accepts RGB, RGBA, or indexed PNGs (any 8-bit tool
  export); colours are snapped to the nearest LocoPalette entry (exact
  matches, e.g. round-tripped exports, always win) and alpha = 0 becomes a
  transparent pixel.

  Part of the LocoDat Pascal library.
}
unit LocoPng;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, zstream, LocoPalette, LocoSprite;

type
  ELocoPngError = class(Exception);

procedure ExportSpriteToPNG(const Pixels: TLocoSpritePixels; const FileName: string);
procedure ExportSpriteToPNGStream(const Pixels: TLocoSpritePixels; Stream: TStream);
function ImportSpriteFromPNG(const FileName: string): TLocoSpritePixels;
function ImportSpriteFromPNGStream(Stream: TStream): TLocoSpritePixels;

implementation

{ ================================ CRC32 ================================== }
{ Standard zlib/PNG/zip CRC-32 (polynomial 0xEDB88320). }

var
  gCRCTable: array[0..255] of UInt32;
  gCRCTableReady: Boolean = False;

procedure EnsureCRCTable;
var
  n, k: Integer;
  c: UInt32;
begin
  if gCRCTableReady then
    Exit;
  for n := 0 to 255 do
  begin
    c := UInt32(n);
    for k := 0 to 7 do
    begin
      if (c and 1) <> 0 then
        c := $EDB88320 xor (c shr 1)
      else
        c := c shr 1;
    end;
    gCRCTable[n] := c;
  end;
  gCRCTableReady := True;
end;

function CRC32Of(const Data: TBytes): UInt32;
var
  i: Integer;
  crc: UInt32;
begin
  EnsureCRCTable;
  crc := $FFFFFFFF;
  for i := 0 to High(Data) do
    crc := gCRCTable[(crc xor Data[i]) and $FF] xor (crc shr 8);
  Result := crc xor $FFFFFFFF;
end;

{ ============================ big-endian I/O ============================= }

procedure WriteUInt32BE(Stream: TStream; Value: UInt32);
var
  b: array[0..3] of Byte;
begin
  b[0] := (Value shr 24) and $FF;
  b[1] := (Value shr 16) and $FF;
  b[2] := (Value shr 8) and $FF;
  b[3] := Value and $FF;
  Stream.WriteBuffer(b, 4);
end;

function ReadUInt32BE(Stream: TStream): UInt32;
var
  b: array[0..3] of Byte;
begin
  Stream.ReadBuffer(b, 4);
  Result := (UInt32(b[0]) shl 24) or (UInt32(b[1]) shl 16) or (UInt32(b[2]) shl 8) or UInt32(b[3]);
end;

{ =============================== chunk I/O ================================ }

const
  kPngSignature: array[0..7] of Byte = (137, 80, 78, 71, 13, 10, 26, 10);

procedure WritePngChunk(Stream: TStream; const ChunkType: AnsiString; const Data: TBytes);
var
  typeBytes: array[0..3] of Byte;
  crcInput: TBytes;
  i: Integer;
begin
  WriteUInt32BE(Stream, UInt32(Length(Data)));

  for i := 0 to 3 do
    typeBytes[i] := Byte(ChunkType[i + 1]);
  Stream.WriteBuffer(typeBytes, 4);

  if Length(Data) > 0 then
    Stream.WriteBuffer(Data[0], Length(Data));

  SetLength(crcInput, 4 + Length(Data));
  Move(typeBytes, crcInput[0], 4);
  if Length(Data) > 0 then
    Move(Data[0], crcInput[4], Length(Data));
  WriteUInt32BE(Stream, CRC32Of(crcInput));
end;

{ ============================ PNG scanline filters ========================= }

function PaethPredictor(a, b, c: Integer): Integer;
var
  p, pa, pb, pc: Integer;
begin
  p := a + b - c;
  pa := Abs(p - a);
  pb := Abs(p - b);
  pc := Abs(p - c);
  if (pa <= pb) and (pa <= pc) then
    Result := a
  else if pb <= pc then
    Result := b
  else
    Result := c;
end;

{ ================================= export ================================= }

procedure ExportSpriteToPNGStream(const Pixels: TLocoSpritePixels; Stream: TStream);
var
  ihdrData: TBytes;
  raw: TBytes;
  pos, x, y, idx: Integer;
  rgb: TLocoRGB;
  compressed: TMemoryStream;
  comp: TCompressionStream;
  compBytes: TBytes;
  sigBytes: TBytes;
begin
  if (Pixels.Width <= 0) or (Pixels.Height <= 0) then
    raise ELocoPngError.Create('Cannot export a sprite with zero width/height');

  SetLength(sigBytes, 8);
  Move(kPngSignature[0], sigBytes[0], 8);
  Stream.WriteBuffer(sigBytes[0], 8);

  SetLength(ihdrData, 13);
  ihdrData[0] := (Pixels.Width shr 24) and $FF;
  ihdrData[1] := (Pixels.Width shr 16) and $FF;
  ihdrData[2] := (Pixels.Width shr 8) and $FF;
  ihdrData[3] := Pixels.Width and $FF;
  ihdrData[4] := (Pixels.Height shr 24) and $FF;
  ihdrData[5] := (Pixels.Height shr 16) and $FF;
  ihdrData[6] := (Pixels.Height shr 8) and $FF;
  ihdrData[7] := Pixels.Height and $FF;
  ihdrData[8] := 8; // bit depth
  ihdrData[9] := 6; // colour type: truecolour + alpha
  ihdrData[10] := 0; // compression method
  ihdrData[11] := 0; // filter method
  ihdrData[12] := 0; // interlace method
  WritePngChunk(Stream, 'IHDR', ihdrData);

  // Raw filtered scanlines: filter-type byte (always 0/None) + Width*4 RGBA bytes, per row.
  SetLength(raw, Pixels.Height * (1 + Pixels.Width * 4));
  pos := 0;
  for y := 0 to Pixels.Height - 1 do
  begin
    raw[pos] := 0;
    Inc(pos);
    for x := 0 to Pixels.Width - 1 do
    begin
      idx := y * Pixels.Width + x;
      if Pixels.Opaque[idx] then
      begin
        rgb := LocoPalette.LocoPalette[Pixels.Indices[idx]];
        raw[pos] := rgb.R;
        raw[pos + 1] := rgb.G;
        raw[pos + 2] := rgb.B;
        raw[pos + 3] := 255;
      end
      else
      begin
        raw[pos] := 0;
        raw[pos + 1] := 0;
        raw[pos + 2] := 0;
        raw[pos + 3] := 0;
      end;
      Inc(pos, 4);
    end;
  end;

  compressed := TMemoryStream.Create;
  try
    comp := TCompressionStream.Create(clDefault, compressed);
    try
      if Length(raw) > 0 then
        comp.WriteBuffer(raw[0], Length(raw));
    finally
      comp.Free; // flushes the remaining zlib stream on destruction
    end;

    SetLength(compBytes, compressed.Size);
    if compressed.Size > 0 then
    begin
      compressed.Position := 0;
      compressed.ReadBuffer(compBytes[0], compressed.Size);
    end;
  finally
    compressed.Free;
  end;

  WritePngChunk(Stream, 'IDAT', compBytes);
  WritePngChunk(Stream, 'IEND', nil);
end;

procedure ExportSpriteToPNG(const Pixels: TLocoSpritePixels; const FileName: string);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmCreate);
  try
    ExportSpriteToPNGStream(Pixels, fs);
  finally
    fs.Free;
  end;
end;

{ ================================= import ================================= }

function ImportSpriteFromPNGStream(Stream: TStream): TLocoSpritePixels;
var
  sigBytes: array[0..7] of Byte;
  i: Integer;
  chunkLen: UInt32;
  chunkTypeBytes: array[0..3] of Byte;
  chunkType: AnsiString;
  chunkData: TBytes;
  dummyCrc: UInt32;
  width, height: Integer;
  bitDepth, colorType: Byte;
  plte: TArray<TLocoRGB>;
  trns: TBytes;
  idatAccum: TMemoryStream;
  doneIEND: Boolean;
  decompStream: TDecompressionStream;
  rawScanlines: TBytes;
  bpp, rowBytes: Integer;
  y, x: Integer;
  prior, curr: TBytes;
  filterType: Byte;
  a, b, c, pr: Integer;
  reconByte: Byte;
  idx: Integer;
  r8, g8, b8, a8: Byte;
  palIndex: Byte;
  exactIdx: Integer;
begin
  Stream.ReadBuffer(sigBytes, 8);
  for i := 0 to 7 do
    if sigBytes[i] <> kPngSignature[i] then
      raise ELocoPngError.Create('Not a valid PNG file (bad signature)');

    width := 0;
    height := 0;
    bitDepth := 0;
    colorType := 255;
    SetLength(plte, 0);
    SetLength(trns, 0);
    doneIEND := False;

    idatAccum := TMemoryStream.Create;
    try
      while (not doneIEND) and (Stream.Position < Stream.Size) do
      begin
        chunkLen := ReadUInt32BE(Stream);
        Stream.ReadBuffer(chunkTypeBytes, 4);
        SetString(chunkType, PAnsiChar(@chunkTypeBytes[0]), 4);

        SetLength(chunkData, chunkLen);
        if chunkLen > 0 then
          Stream.ReadBuffer(chunkData[0], chunkLen);
        Stream.ReadBuffer(dummyCrc, 4); // CRC not re-validated on read

        if chunkType = 'IHDR' then
        begin
          if chunkLen < 13 then
            raise ELocoPngError.Create('Malformed IHDR chunk');
          width := (Integer(chunkData[0]) shl 24) or (Integer(chunkData[1]) shl 16)
            or (Integer(chunkData[2]) shl 8) or Integer(chunkData[3]);
          height := (Integer(chunkData[4]) shl 24) or (Integer(chunkData[5]) shl 16)
            or (Integer(chunkData[6]) shl 8) or Integer(chunkData[7]);
          bitDepth := chunkData[8];
          colorType := chunkData[9];
          if chunkData[12] <> 0 then
            raise ELocoPngError.Create('Interlaced PNGs are not supported');
          if bitDepth <> 8 then
            raise ELocoPngError.CreateFmt('Only 8-bit PNGs are supported (got %d-bit)', [bitDepth]);
        end
        else if chunkType = 'PLTE' then
        begin
          SetLength(plte, chunkLen div 3);
          for i := 0 to High(plte) do
          begin
            plte[i].R := chunkData[i * 3];
            plte[i].G := chunkData[i * 3 + 1];
            plte[i].B := chunkData[i * 3 + 2];
          end;
        end
        else if chunkType = 'tRNS' then
        begin
          SetLength(trns, chunkLen);
          if chunkLen > 0 then
            Move(chunkData[0], trns[0], chunkLen);
        end
        else if chunkType = 'IDAT' then
        begin
          if chunkLen > 0 then
            idatAccum.WriteBuffer(chunkData[0], chunkLen);
        end
        else if chunkType = 'IEND' then
          doneIEND := True;
        // any other ancillary chunk is skipped
      end;

      if (width <= 0) or (height <= 0) then
        raise ELocoPngError.Create('PNG is missing a valid IHDR chunk');
      if not (colorType in [2, 3, 6]) then
        raise ELocoPngError.CreateFmt('Unsupported PNG colour type %d (only RGB, indexed and RGBA are supported)', [colorType]);
      if (colorType = 3) and (Length(plte) = 0) then
        raise ELocoPngError.Create('Indexed PNG is missing its PLTE chunk');

      case colorType of
        2: bpp := 3;
        3: bpp := 1;
      else
        bpp := 4; // colorType 6
      end;
      rowBytes := width * bpp;

      idatAccum.Position := 0;
      decompStream := TDecompressionStream.Create(idatAccum);
      try
        SetLength(rawScanlines, height * (1 + rowBytes));
        if Length(rawScanlines) > 0 then
          decompStream.ReadBuffer(rawScanlines[0], Length(rawScanlines));
      finally
        decompStream.Free;
      end;
    finally
      idatAccum.Free;
    end;

    Result.Width := width;
    Result.Height := height;
    SetLength(Result.Indices, width * height);
    SetLength(Result.Opaque, width * height);

    SetLength(prior, rowBytes);
    FillChar(prior[0], rowBytes, 0);
    SetLength(curr, rowBytes);

    for y := 0 to height - 1 do
    begin
      filterType := rawScanlines[y * (1 + rowBytes)];

      for x := 0 to rowBytes - 1 do
      begin
        reconByte := rawScanlines[y * (1 + rowBytes) + 1 + x];
        if x >= bpp then
          a := curr[x - bpp]
        else
          a := 0;
        b := prior[x];
        if x >= bpp then
          c := prior[x - bpp]
        else
          c := 0;

        case filterType of
          0: ; // None - reconByte unchanged
          1: reconByte := Byte(reconByte + a);
          2: reconByte := Byte(reconByte + b);
          3: reconByte := Byte(reconByte + (a + b) div 2);
          4:
            begin
              pr := PaethPredictor(a, b, c);
              reconByte := Byte(reconByte + pr);
            end;
        else
          raise ELocoPngError.CreateFmt('Unsupported PNG filter type %d', [filterType]);
        end;

        curr[x] := reconByte;
      end;

      for x := 0 to width - 1 do
      begin
        idx := y * width + x;
        case colorType of
          2:
            begin
              r8 := curr[x * 3];
              g8 := curr[x * 3 + 1];
              b8 := curr[x * 3 + 2];
              a8 := 255;
            end;
          3:
            begin
              palIndex := curr[x];
              if palIndex > High(plte) then
                raise ELocoPngError.Create('PNG pixel references a palette index outside PLTE');
              r8 := plte[palIndex].R;
              g8 := plte[palIndex].G;
              b8 := plte[palIndex].B;
              if palIndex < Length(trns) then
                a8 := trns[palIndex]
              else
                a8 := 255;
            end;
        else // colorType 6
          begin
            r8 := curr[x * 4];
            g8 := curr[x * 4 + 1];
            b8 := curr[x * 4 + 2];
            a8 := curr[x * 4 + 3];
          end;
        end;

        if a8 = 0 then
        begin
          Result.Opaque[idx] := False;
          Result.Indices[idx] := 0;
        end
        else
        begin
          Result.Opaque[idx] := True;
          exactIdx := FindExactPaletteIndex(r8, g8, b8);
          if exactIdx >= 0 then
            Result.Indices[idx] := Byte(exactIdx)
          else
            Result.Indices[idx] := FindNearestPaletteIndex(r8, g8, b8);
        end;
      end;

      Move(curr[0], prior[0], rowBytes);
    end;
end;

function ImportSpriteFromPNG(const FileName: string): TLocoSpritePixels;
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := ImportSpriteFromPNGStream(fs);
  finally
    fs.Free;
  end;
end;

end.
