{
  LocoImageTable.pas

  Codec for the "image table" (a.k.a. G1 sprite table) embedded in an
  object's decoded data blob. Transcribed from OpenLoco's
  Objects/ObjectImageTable.cpp/.h and Graphics/Gfx.h.

  On-disk layout, starting wherever the image table begins within the
  object's data (almost always the last field, right after the string
  table(s)):

    TG1Header                     (8 bytes: NumEntries, TotalSize)
    TG1Element32[NumEntries]      (16 bytes each: offset/size/flags...)
    <TotalSize> bytes             raw pixel/sprite data blob

  Each element's Offset indexes into the pixel blob. This library treats
  the pixel blob as opaque bytes (it does not decode Locomotion's sprite
  RLE / palette compression, only preserves it byte-for-byte) - that is
  enough to losslessly read, inspect and rewrite objects, add/remove/
  reorder elements, or splice in new pixel data prepared by other tools.

  Part of the LocoDat Pascal library.
}
unit LocoImageTable;

{$mode delphi}{$H+}

interface

uses
  SysUtils, LocoTypes;

type
  TLocoImageTable = record
    Header: TG1Header;
    Elements: TArray<TG1Element32>;
    PixelData: TBytes; // opaque blob; Elements[i].Offset indexes into this
  end;

{ Parses an image table starting at Data[0] (slice your object's data blob
  down to the relevant sub-range with Copy() before calling, e.g. via the
  offset returned by earlier DecodeStringTable calls). Returns the number of
  bytes consumed. }
function DecodeImageTable(const Data: TBytes; out Table: TLocoImageTable): Integer;

{ Serialises a TLocoImageTable back to its on-disk byte layout. Header is
  regenerated from Elements/PixelData, so you don't need to keep it in sync
  by hand. }
function EncodeImageTable(const Table: TLocoImageTable): TBytes;

{ Returns the byte range within PixelData belonging to element Index,
  assuming elements are stored in ascending Offset order (true for every
  vanilla and OpenLoco object). Elements flagged gfDuplicatePrevious re-use
  the previous element's pixel data (with an xOffset/yOffset adjustment) and
  do not own pixel data of their own - check that flag before relying on
  the returned range. }
function GetElementPixelRange(const Table: TLocoImageTable; Index: Integer;
  out PixelOffset, PixelLength: Integer): Boolean;

implementation

function DecodeImageTable(const Data: TBytes; out Table: TLocoImageTable): Integer;
var
  pos, i: Integer;
begin
  if Length(Data) < SizeOf(TG1Header) then
    raise Exception.Create('Image table truncated: missing header');
  Move(Data[0], Table.Header, SizeOf(TG1Header));
  pos := SizeOf(TG1Header);

  if Int64(Length(Data) - pos) < Int64(Table.Header.NumEntries) * SizeOf(TG1Element32) then
    raise Exception.Create('Image table truncated: missing element array');
  SetLength(Table.Elements, Table.Header.NumEntries);
  for i := 0 to Integer(Table.Header.NumEntries) - 1 do
  begin
    Move(Data[pos], Table.Elements[i], SizeOf(TG1Element32));
    Inc(pos, SizeOf(TG1Element32));
  end;

  if Int64(Length(Data) - pos) < Int64(Table.Header.TotalSize) then
    raise Exception.Create('Image table truncated: missing pixel data');
  SetLength(Table.PixelData, Table.Header.TotalSize);
  if Table.Header.TotalSize > 0 then
    Move(Data[pos], Table.PixelData[0], Table.Header.TotalSize);
  Inc(pos, Table.Header.TotalSize);

  Result := pos;
end;

function EncodeImageTable(const Table: TLocoImageTable): TBytes;
var
  totalLen, pos, i: Integer;
  hdr: TG1Header;
begin
  hdr.NumEntries := Length(Table.Elements);
  hdr.TotalSize := Length(Table.PixelData);

  totalLen := SizeOf(TG1Header) + Length(Table.Elements) * SizeOf(TG1Element32)
    + Length(Table.PixelData);
  SetLength(Result, totalLen);

  pos := 0;
  Move(hdr, Result[pos], SizeOf(TG1Header));
  Inc(pos, SizeOf(TG1Header));

  for i := 0 to High(Table.Elements) do
  begin
    Move(Table.Elements[i], Result[pos], SizeOf(TG1Element32));
    Inc(pos, SizeOf(TG1Element32));
  end;

  if Length(Table.PixelData) > 0 then
    Move(Table.PixelData[0], Result[pos], Length(Table.PixelData));
end;

function GetElementPixelRange(const Table: TLocoImageTable; Index: Integer;
  out PixelOffset, PixelLength: Integer): Boolean;
begin
  Result := False;
  PixelOffset := 0;
  PixelLength := 0;
  if (Index < 0) or (Index > High(Table.Elements)) then
    Exit;

  PixelOffset := Table.Elements[Index].Offset;
  if Index < High(Table.Elements) then
    PixelLength := Integer(Table.Elements[Index + 1].Offset) - PixelOffset
  else
    PixelLength := Length(Table.PixelData) - PixelOffset;

  Result := True;
end;

end.
