{
  LocoStringTable.pas

  Codec for the multi-language "string table" fields embedded in an object's
  decoded data blob. Transcribed from OpenLoco's
  Objects/ObjectStringTable.cpp (loadStringTable) and
  Localisation/Languages.h (LocoLanguageId).

  On disk, one string table field is a sequence of:
    [1 byte language id][N bytes text][1 byte #0 terminator]
  repeated for each language variant provided, and the whole field is
  terminated by a single $FF byte.

  Most object types have more than one string table field one after another
  (e.g. Cargo has 4 - see kNumStringsPerObjectType in ObjectStringTable.cpp,
  reproduced in LocoObjectDefs.pas) - call DecodeStringTable repeatedly,
  advancing your offset by the returned length each time.

  Part of the LocoDat Pascal library.
}
unit LocoStringTable;

{$mode delphi}{$H+}

interface

uses
  SysUtils, LocoTypes;

type
  { Matches OpenLoco::Localisation::LocoLanguageId. Kept alongside a raw Byte
    field on TLocoStringEntry since some mods use ids outside this list. }
  TLocoLanguageId = (
    lidEnglishUK          = 0,
    lidEnglishUS           = 1,
    lidFrench              = 2,
    lidGerman              = 3,
    lidSpanish             = 4,
    lidItalian             = 5,
    lidDutch                = 6,
    lidSwedish              = 7,
    lidJapanese             = 8,
    lidKorean               = 9,
    lidChineseSimplified   = 10,
    lidChineseTraditional  = 11,
    lidId12                 = 12,
    lidPortuguese           = 13,
    lidBlank                = 254,
    lidEnd                  = 255
  );

  TLocoStringEntry = record
    LanguageId: Byte;
    Text: AnsiString;
  end;

{ Decodes one string table field starting at Data[StartOffset]. Returns the
  number of bytes consumed (including the $FF terminator) so the caller can
  advance to the next field (fixed struct -> string table(s) -> image table,
  see LocoObjectFile.pas / LocoImageTable.pas). }
function DecodeStringTable(const Data: TBytes; StartOffset: Integer;
  out Entries: TArray<TLocoStringEntry>): Integer;

{ Encodes a string table field back to bytes, including the $FF terminator. }
function EncodeStringTable(const Entries: TArray<TLocoStringEntry>): TBytes;

{ Convenience fallback-picker approximating loadStringTable's language
  selection: prefers PreferredLanguageId, then English (UK, then US), then
  whatever was found first. }
function PickString(const Entries: TArray<TLocoStringEntry>;
  PreferredLanguageId: Byte): AnsiString;

implementation

function DecodeStringTable(const Data: TBytes; StartOffset: Integer;
  out Entries: TArray<TLocoStringEntry>): Integer;
var
  pos, strStart, len, count: Integer;
begin
  len := Length(Data);
  pos := StartOffset;
  count := 0;
  SetLength(Entries, 0);

  while (pos < len) and (Data[pos] <> $FF) do
  begin
    SetLength(Entries, count + 1);
    Entries[count].LanguageId := Data[pos];
    Inc(pos);

    strStart := pos;
    while (pos < len) and (Data[pos] <> 0) do
      Inc(pos);
    SetString(Entries[count].Text, PAnsiChar(@Data[strStart]), pos - strStart);

    if pos < len then
      Inc(pos); // skip the string's #0 terminator

    Inc(count);
  end;

  if pos < len then
    Inc(pos); // skip the field's $FF terminator

  Result := pos - StartOffset;
end;

function EncodeStringTable(const Entries: TArray<TLocoStringEntry>): TBytes;
var
  total, pos, i: Integer;
begin
  total := 1; // final $FF
  for i := 0 to High(Entries) do
    total := total + 1 + Length(Entries[i].Text) + 1;

  SetLength(Result, total);
  pos := 0;
  for i := 0 to High(Entries) do
  begin
    Result[pos] := Entries[i].LanguageId;
    Inc(pos);
    if Length(Entries[i].Text) > 0 then
    begin
      Move(Entries[i].Text[1], Result[pos], Length(Entries[i].Text));
      Inc(pos, Length(Entries[i].Text));
    end;
    Result[pos] := 0;
    Inc(pos);
  end;
  Result[pos] := $FF;
  Inc(pos);
end;

function PickString(const Entries: TArray<TLocoStringEntry>;
  PreferredLanguageId: Byte): AnsiString;
var
  i: Integer;
  engBackup, anyStr, target: AnsiString;
  haveEng, haveAny, haveTarget: Boolean;
begin
  haveEng := False;
  haveAny := False;
  haveTarget := False;

  for i := 0 to High(Entries) do
  begin
    if Entries[i].LanguageId = Ord(lidEnglishUK) then
    begin
      engBackup := Entries[i].Text;
      haveEng := True;
    end
    else if (Entries[i].LanguageId = Ord(lidEnglishUS)) and (not haveEng) then
    begin
      engBackup := Entries[i].Text;
      haveEng := True;
    end;

    if Entries[i].LanguageId = PreferredLanguageId then
    begin
      target := Entries[i].Text;
      haveTarget := True;
    end;

    if (not haveEng) and (not haveTarget) and (not haveAny) then
    begin
      anyStr := Entries[i].Text;
      haveAny := True;
    end;
  end;

  if haveTarget then
    Result := target
  else if haveEng then
    Result := engBackup
  else if haveAny then
    Result := anyStr
  else
    Result := '';
end;

end.
