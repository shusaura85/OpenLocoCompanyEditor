{
  LocoCompetitorObjectFile.pas

  Full read/write access to a Competitor (.DAT) object, extending
  TLocoObjectFile - an AI opponent's identity, personality and portrait.
  Transcribed from:

    - Objects/CompetitorObject.h    (CompetitorObject struct)
    - Objects/CompetitorObject.cpp  (CompetitorObject::load / ::validate /
                                      ::drawPreviewImage - the
                                      authoritative field order, validation
                                      rule, and how the Images/Emotions
                                      fields relate to each other, that
                                      this class mirrors/documents)

  NOTE: LocoObjectDefs.pas (in ..\..\src\) does not have a fixed struct for
  this type yet - its LocoObjectFixedHeaderSize entry for otCompetitor is
  still -1. TLocoCompetitorObject is defined locally below instead, same
  as LocoCliffEdgeObjectFile.pas's TLocoCliffEdgeObject.

  On-disk layout of a Competitor object's decoded data (see
  CompetitorObject::load):
    TLocoCompetitorObject (0x38 = 56 bytes)
    string table  - firstName
    string table  - lastName
    image table   - CompetitorObject::load fills all 9 Images[] entries
                    with the image table's base offset, then walks
                    Emotions bit-by-bit (0..8): for every set bit i it
                    adds a running "emotion image offset" (starting at 0,
                    +2 per set bit encountered) onto Images[i] - i.e. each
                    portrait "emotion" after the first that's actually
                    used consumes 2 images from the table. Images[] is
                    entirely unused at rest (recomputed every load), so
                    it isn't exposed as a settable property here -
                    EmotionFlag[0..8] (which drives that computation) is,
                    instead.

  Competitor objects are always written with SawyerEncoding = uncompressed
  - already handled for you by TLocoObjectFile.DefaultEncodingFor
  (LocoObjectFile.pas), unchanged by this class.

  AvailableNamePrefixes and AvailablePlayStyles are genuine, persisted
  32-bit bitmasks (load() never overwrites them, unlike Images), but this
  library has no documented per-bit meaning for either beyond their name -
  exposed as raw UInt32 rather than guessed at. Same for Var37 (raw Byte,
  no documented meaning at all in the source available to this library).

  Emotions is also a persisted 32-bit bitmask, but bit 0 specifically IS
  documented: CompetitorObject::validate() requires it set, and
  ::load's per-emotion image offsetting (see above) only iterates bits
  0..8 - so, per the same reasoning as LocoCargoObjectFile.pas/
  LocoLandObjectFile.pas/LocoWallObjectFile.pas, Emotions is exposed both
  as a raw UInt32 (every bit round-trips exactly) and via an indexed
  EmotionFlag[0..8]: Boolean convenience property.

  Same rebuild caveat as the other classes in this folder: saving after
  any mutation regenerates the whole variable-length region (string
  tables, image table) from the in-memory data rather than patching
  original bytes, so a re-saved file is semantically identical but not
  guaranteed byte-identical to the original.

  Part of the LocoDat Pascal library. Extends, and does not modify,
  LocoObjectFile.pas / LocoObjectDefs.pas / LocoImageTable.pas.
}
unit LocoCompetitorObjectFile;

{$mode delphi}{$H+}

interface

uses
  SysUtils, LocoTypes, LocoObjectFile, LocoStringTable, LocoImageTable;

type
  ELocoCompetitorError = class(Exception);

  { CompetitorObject.h : CompetitorObject struct.
    static_assert(sizeof(CompetitorObject) == 0x38). }
  TLocoCompetitorObject = packed record
    FirstNameStringId: UInt16;
    LastNameStringId: UInt16;
    AvailableNamePrefixes: UInt32;
    AvailablePlayStyles: UInt32;
    Emotions: UInt32;
    Images: array[0..8] of UInt32; // unused at rest - see unit header comment
    Intelligence: Byte;
    Aggressiveness: Byte;
    Competitiveness: Byte;
    Var37: Byte; // undocumented in the OpenLoco source available to this library
  end;

  TLocoCompetitorObjectFile = class(TLocoObjectFile)
  private
    FFixed: TLocoCompetitorObject;
    FFirstNames: TArray<TLocoStringEntry>;
    FLastNames: TArray<TLocoStringEntry>;
    FImageTable: TLocoImageTable;
    procedure ParseFromData;
    procedure Rebuild;
    procedure CheckEmotionIndex(Index: Integer);

    function GetFirstNames: TArray<TLocoStringEntry>;
    procedure SetFirstNames(const Value: TArray<TLocoStringEntry>);
    function GetLastNames: TArray<TLocoStringEntry>;
    procedure SetLastNames(const Value: TArray<TLocoStringEntry>);
    function GetImageTable: TLocoImageTable;
    procedure SetImageTable(const Value: TLocoImageTable);

    function GetAvailableNamePrefixes: UInt32;
    procedure SetAvailableNamePrefixes(Value: UInt32);
    function GetAvailableNamePrefixFlag(Index: Integer): Boolean;           // added manually
    procedure SetAvailableNamePrefixFlag(Index: Integer; Value: Boolean);   // added manually
    function GetAvailablePlayStyles: UInt32;
    procedure SetAvailablePlayStyles(Value: UInt32);
    function GetAvailablePlayStyleFlag(Index: Integer): Boolean;            // added manually
    procedure SetAvailablePlayStyleFlag(Index: Integer; Value: Boolean);    // added manually
    function GetEmotions: UInt32;
    procedure SetEmotions(Value: UInt32);
    function GetEmotionFlag(Index: Integer): Boolean;
    procedure SetEmotionFlag(Index: Integer; Value: Boolean);
    function GetIntelligence: Byte;
    procedure SetIntelligence(Value: Byte);
    function GetAggressiveness: Byte;
    procedure SetAggressiveness(Value: Byte);
    function GetCompetitiveness: Byte;
    procedure SetCompetitiveness(Value: Byte);
    function GetVar37: Byte;
    procedure SetVar37(Value: Byte);
  public
    { Loads FileName via TLocoObjectFile.LoadFromFile, then parses the
      Competitor-specific data on top. Raises if the file isn't a
      Competitor object. }
    class function LoadFromFile(const FileName: string): TLocoCompetitorObjectFile;

    { Builds a brand new, empty Competitor object (no names, all-zero
      fields, no images) ready for you to populate and save. }
    class function CreateNew(const ObjectName: string; Source: TLocoSourceGame): TLocoCompetitorObjectFile;

    { The competitor's first and last name, each as multi-language
      entries. }
    property FirstNames: TArray<TLocoStringEntry> read GetFirstNames write SetFirstNames;
    property LastNames: TArray<TLocoStringEntry> read GetLastNames write SetLastNames;

    { Raw bitmasks - genuinely persisted (unlike Images below) but this
      library has no documented per-bit meaning for either beyond their
      name; exposed as-is rather than guessed at. }
    property AvailableNamePrefixes: UInt32 read GetAvailableNamePrefixes write SetAvailableNamePrefixes;
    property AvailablePlayStyles: UInt32 read GetAvailablePlayStyles write SetAvailablePlayStyles;

    { Convenient bit-level access to AvailableNamePrefixes bits }
    property AvailableNamePrefixFlag[Index: Integer]: Boolean read GetAvailableNamePrefixFlag write SetAvailableNamePrefixFlag;
    { Convenient bit-level access to AvailablePlayStyles bits }
    property AvailablePlayStyleFlag[Index: Integer]: Boolean read GetAvailablePlayStyleFlag write SetAvailablePlayStyleFlag;

    { Raw emotions bitmask - every bit is preserved on save, including
      ones this class doesn't know the meaning of. Bit 0 must be set for
      CompetitorObject::validate() to pass; bits 0..8 each control whether
      the corresponding portrait "emotion" is included when the image
      table is built (see the unit header comment) - use EmotionFlag for
      convenient access to those. }
    property Emotions: UInt32 read GetEmotions write SetEmotions;
    { Convenient bit-level access to Emotions bits 0..8 - see the Emotions
      property comment and the unit header comment for what setting a bit
      here means for image table layout. }
    property EmotionFlag[Index: Integer]: Boolean read GetEmotionFlag write SetEmotionFlag;

    { 1-9 rating used by CompetitorObject::validate() and shown in the
      company details window (aiRatingToLevel maps it to Low/Medium/High). }
    property Intelligence: Byte read GetIntelligence write SetIntelligence;
    property Aggressiveness: Byte read GetAggressiveness write SetAggressiveness;
    property Competitiveness: Byte read GetCompetitiveness write SetCompetitiveness;

    { Undocumented byte - not referenced by name anywhere in the OpenLoco
      source available to this library. }
    property Var37: Byte read GetVar37 write SetVar37;

    { The competitor's portrait images - element 0 (+1) is the object
      selection preview; see the unit header comment for how Emotions
      determines which further images are used. Compose with
      LocoObjectSprites.pas to export/import individual sprites as PNG. }
    property ImageTable: TLocoImageTable read GetImageTable write SetImageTable;

    { Mirrors CompetitorObject::validate(): Emotions bit 0 set, and
      Intelligence/Aggressiveness/Competitiveness all in 1..9. OpenLoco
      itself refuses to load a Competitor object that fails this check. }
    function Validate: Boolean;
  end;

implementation

procedure TLocoCompetitorObjectFile.CheckEmotionIndex(Index: Integer);
begin
  if (Index < 0) or (Index > 8) then
    raise ELocoCompetitorError.CreateFmt('Emotion index %d out of range (must be 0..8)', [Index]);
end;

procedure TLocoCompetitorObjectFile.ParseFromData;
var
  offset: Integer;
begin
  if Length(Data) < SizeOf(FFixed) then
    raise ELocoCompetitorError.Create('Competitor object data too short for its fixed struct');
  Move(Data[0], FFixed, SizeOf(FFixed));

  offset := SizeOf(FFixed);
  Inc(offset, DecodeStringTable(Data, offset, FFirstNames));
  Inc(offset, DecodeStringTable(Data, offset, FLastNames));

  DecodeImageTable(Copy(Data, offset, Length(Data) - offset), FImageTable);
end;

procedure TLocoCompetitorObjectFile.Rebuild;
var
  firstBytes, lastBytes, imageBytes, newData: TBytes;
  pos, totalLen: Integer;
begin
  firstBytes := EncodeStringTable(FFirstNames);
  lastBytes := EncodeStringTable(FLastNames);
  imageBytes := EncodeImageTable(FImageTable);

  totalLen := SizeOf(FFixed) + Length(firstBytes) + Length(lastBytes) + Length(imageBytes);
  SetLength(newData, totalLen);

  pos := 0;
  Move(FFixed, newData[pos], SizeOf(FFixed));
  Inc(pos, SizeOf(FFixed));

  if Length(firstBytes) > 0 then
    Move(firstBytes[0], newData[pos], Length(firstBytes));
  Inc(pos, Length(firstBytes));

  if Length(lastBytes) > 0 then
    Move(lastBytes[0], newData[pos], Length(lastBytes));
  Inc(pos, Length(lastBytes));

  if Length(imageBytes) > 0 then
    Move(imageBytes[0], newData[pos], Length(imageBytes));

  Data := newData; // inherited property; call UpdateChecksum (inherited) before saving
end;

class function TLocoCompetitorObjectFile.LoadFromFile(const FileName: string): TLocoCompetitorObjectFile;
var
  tmp: TLocoObjectFile;
begin
  tmp := TLocoObjectFile.LoadFromFile(FileName);
  try
    if tmp.ObjectType <> otCompetitor then
      raise ELocoCompetitorError.CreateFmt('%s is a %s object, not a Competitor object',
        [FileName, LocoObjectTypeNames[tmp.ObjectType]]);
    Result := TLocoCompetitorObjectFile.Create(tmp.Header, tmp.Data);
  finally
    tmp.Free;
  end;
  Result.ParseFromData;
end;

class function TLocoCompetitorObjectFile.CreateNew(const ObjectName: string;
  Source: TLocoSourceGame): TLocoCompetitorObjectFile;
var
  hdr: TObjectHeader;
begin
  hdr := MakeObjectHeader(otCompetitor, Source, ObjectName);
  Result := TLocoCompetitorObjectFile.Create(hdr, nil);
  FillChar(Result.FFixed, SizeOf(Result.FFixed), 0);
  Result.Rebuild;
end;

function TLocoCompetitorObjectFile.GetFirstNames: TArray<TLocoStringEntry>;
begin
  Result := FFirstNames;
end;

procedure TLocoCompetitorObjectFile.SetFirstNames(const Value: TArray<TLocoStringEntry>);
begin
  FFirstNames := Value;
  Rebuild;
end;

function TLocoCompetitorObjectFile.GetLastNames: TArray<TLocoStringEntry>;
begin
  Result := FLastNames;
end;

procedure TLocoCompetitorObjectFile.SetLastNames(const Value: TArray<TLocoStringEntry>);
begin
  FLastNames := Value;
  Rebuild;
end;

function TLocoCompetitorObjectFile.GetImageTable: TLocoImageTable;
begin
  Result := FImageTable;
end;

procedure TLocoCompetitorObjectFile.SetImageTable(const Value: TLocoImageTable);
begin
  FImageTable := Value;
  Rebuild;
end;

function TLocoCompetitorObjectFile.GetAvailableNamePrefixes: UInt32;
begin
  Result := FFixed.AvailableNamePrefixes;
end;

procedure TLocoCompetitorObjectFile.SetAvailableNamePrefixes(Value: UInt32);
begin
  FFixed.AvailableNamePrefixes := Value;
  Rebuild;
end;

function TLocoCompetitorObjectFile.GetAvailableNamePrefixFlag(Index: Integer): Boolean;
begin
  Result := (FFixed.AvailableNamePrefixes and (UInt32(1) shl Index)) <> 0;
end;

procedure TLocoCompetitorObjectFile.SetAvailableNamePrefixFlag(Index: Integer; Value: Boolean);
begin
  if Value then
    FFixed.AvailableNamePrefixes := FFixed.AvailableNamePrefixes or (UInt32(1) shl Index)
  else
    FFixed.AvailableNamePrefixes := FFixed.AvailableNamePrefixes and not (UInt32(1) shl Index);
  Rebuild;
end;


function TLocoCompetitorObjectFile.GetAvailablePlayStyles: UInt32;
begin
  Result := FFixed.AvailablePlayStyles;
end;

procedure TLocoCompetitorObjectFile.SetAvailablePlayStyles(Value: UInt32);
begin
  FFixed.AvailablePlayStyles := Value;
  Rebuild;
end;

function TLocoCompetitorObjectFile.GetAvailablePlayStyleFlag(Index: Integer): Boolean;
begin
  Result := (FFixed.AvailablePlayStyles and (UInt32(1) shl Index)) <> 0;
end;

procedure TLocoCompetitorObjectFile.SetAvailablePlayStyleFlag(Index: Integer; Value: Boolean);
begin
  if Value then
    FFixed.AvailablePlayStyles := FFixed.AvailablePlayStyles or (UInt32(1) shl Index)
  else
    FFixed.AvailablePlayStyles := FFixed.AvailablePlayStyles and not (UInt32(1) shl Index);
  Rebuild;
end;




function TLocoCompetitorObjectFile.GetEmotions: UInt32;
begin
  Result := FFixed.Emotions;
end;

procedure TLocoCompetitorObjectFile.SetEmotions(Value: UInt32);
begin
  FFixed.Emotions := Value;
  Rebuild;
end;

function TLocoCompetitorObjectFile.GetEmotionFlag(Index: Integer): Boolean;
begin
  CheckEmotionIndex(Index);
  Result := (FFixed.Emotions and (UInt32(1) shl Index)) <> 0;
end;

procedure TLocoCompetitorObjectFile.SetEmotionFlag(Index: Integer; Value: Boolean);
begin
  CheckEmotionIndex(Index);
  if Value then
    FFixed.Emotions := FFixed.Emotions or (UInt32(1) shl Index)
  else
    FFixed.Emotions := FFixed.Emotions and not (UInt32(1) shl Index);
  Rebuild;
end;

function TLocoCompetitorObjectFile.GetIntelligence: Byte;
begin
  Result := FFixed.Intelligence;
end;

procedure TLocoCompetitorObjectFile.SetIntelligence(Value: Byte);
begin
  FFixed.Intelligence := Value;
  Rebuild;
end;

function TLocoCompetitorObjectFile.GetAggressiveness: Byte;
begin
  Result := FFixed.Aggressiveness;
end;

procedure TLocoCompetitorObjectFile.SetAggressiveness(Value: Byte);
begin
  FFixed.Aggressiveness := Value;
  Rebuild;
end;

function TLocoCompetitorObjectFile.GetCompetitiveness: Byte;
begin
  Result := FFixed.Competitiveness;
end;

procedure TLocoCompetitorObjectFile.SetCompetitiveness(Value: Byte);
begin
  FFixed.Competitiveness := Value;
  Rebuild;
end;

function TLocoCompetitorObjectFile.GetVar37: Byte;
begin
  Result := FFixed.Var37;
end;

procedure TLocoCompetitorObjectFile.SetVar37(Value: Byte);
begin
  FFixed.Var37 := Value;
  Rebuild;
end;

function TLocoCompetitorObjectFile.Validate: Boolean;
begin
  Result := ((FFixed.Emotions and 1) <> 0)
    and (FFixed.Intelligence >= 1) and (FFixed.Intelligence <= 9)
    and (FFixed.Aggressiveness >= 1) and (FFixed.Aggressiveness <= 9)
    and (FFixed.Competitiveness >= 1) and (FFixed.Competitiveness <= 9);
end;

end.
