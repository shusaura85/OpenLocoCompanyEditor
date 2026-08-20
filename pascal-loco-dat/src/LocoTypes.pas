{
  LocoTypes.pas

  Core on-disk types for Chris Sawyer's Locomotion / OpenLoco ".DAT" object
  files. Layouts transcribed from the OpenLoco C++ source:

    - Objects/Object.h            (ObjectHeader, ObjectType)
    - S5/SawyerStream.h           (SawyerEncoding)
    - Graphics/Gfx.h              (G1Header, G1Element32, G1ElementFlags)

  Part of the LocoDat Pascal library.
}
unit LocoTypes;

{$mode delphi}{$H+}

interface

uses
  SysUtils;

type
  { The four Sawyer stream chunk encodings. Stored on disk as a single byte
    immediately before a chunk's 4-byte length (see LocoSawyer.pas). }
  TSawyerEncoding = (
    seUncompressed    = 0,
    seRunLengthSingle = 1,
    seRunLengthMulti  = 2,
    seRotate          = 3
  );

  { Bits 6-7 of ObjectHeader.Flags. }
  TLocoSourceGame = (
    sgCustom   = 0,
    sgData     = 1,
    sgVanilla  = 2,
    sgOpenLoco = 3
  );

  { Bits 0-5 of ObjectHeader.Flags. Order matches OpenLoco::ObjectType exactly
    (Objects/Object.h) - do not reorder. }
  TLocoObjectType = (
    otInterfaceSkin = 0,
    otSound,
    otCurrency,
    otSteam,
    otCliffEdge,
    otWater,
    otLand,
    otTownNames,
    otCargo,
    otWall,
    otTrackSignal,
    otLevelCrossing,
    otStreetLight,
    otTunnel,
    otBridge,
    otTrainStation,
    otTrackExtra,
    otTrack,
    otRoadStation,
    otRoadExtra,
    otRoad,
    otAirport,
    otDock,
    otVehicle,
    otTree,
    otSnow,
    otClimate,
    otHillShapes,
    otBuilding,
    otScaffolding,
    otIndustry,
    otRegion,
    otCompetitor,
    otScenarioText
  );

const
  kMaxObjectTypes = 34;

  LocoObjectTypeNames: array[TLocoObjectType] of string = (
    'InterfaceSkin', 'Sound', 'Currency', 'Steam', 'CliffEdge', 'Water',
    'Land', 'TownNames', 'Cargo', 'Wall', 'TrackSignal', 'LevelCrossing',
    'StreetLight', 'Tunnel', 'Bridge', 'TrainStation', 'TrackExtra', 'Track',
    'RoadStation', 'RoadExtra', 'Road', 'Airport', 'Dock', 'Vehicle', 'Tree',
    'Snow', 'Climate', 'HillShapes', 'Building', 'Scaffolding', 'Industry',
    'Region', 'Competitor', 'ScenarioText'
  );

  { Magic seed used by OpenLoco's ObjectManager::computeChecksum. }
  kObjectChecksumMagic: UInt32 = $F369A75B;

type
  { The raw, 16-byte, NOT sawyer-encoded header that precedes every object's
    data chunk in a .DAT file. static_assert(sizeof(ObjectHeader) == 0x10)
    in Objects/Object.h. }
  TObjectHeader = packed record
    Flags: UInt32;
    Name: array[0..7] of AnsiChar;
    Checksum: UInt32;
  end;

  { Sprite table header (Graphics/Gfx.h : G1Header). Precedes the array of
    G1Element32 entries inside an object's image table. }
  TG1Header = packed record
    NumEntries: UInt32;
    TotalSize: UInt32;
  end;

  TG1ElementFlag = (
    gfHasTransparency   = 0,
    gfUnk1              = 1,
    gfIsRLECompressed   = 2,
    gfIsR8G8B8Palette   = 3,
    gfHasZoomSprites    = 4,
    gfNoZoomDraw        = 5,
    gfDuplicatePrevious = 6
  );

  { On-disk 16-byte sprite descriptor (Graphics/Gfx.h : G1Element32). }
  TG1Element32 = packed record
    Offset: UInt32;
    Width: SmallInt;
    Height: SmallInt;
    XOffset: SmallInt;
    YOffset: SmallInt;
    Flags: UInt16;
    ZoomOffset: SmallInt;
  end;

function G1ElementHasFlag(const Element: TG1Element32; Flag: TG1ElementFlag): Boolean; inline;

function GetObjectType(const Header: TObjectHeader): TLocoObjectType; inline;
function GetSourceGame(const Header: TObjectHeader): TLocoSourceGame; inline;

{ Trimmed, human readable object name (trailing space padding removed). }
function GetObjectName(const Header: TObjectHeader): string;

{ Raw, untrimmed 8-character object name exactly as stored on disk. }
function GetObjectNameRaw(const Header: TObjectHeader): string;

function MakeObjectFlags(ObjType: TLocoObjectType; Source: TLocoSourceGame): UInt32;

function MakeObjectHeader(ObjType: TLocoObjectType; Source: TLocoSourceGame;
  const Name: string): TObjectHeader;

function HeaderIsEmpty(const Header: TObjectHeader): Boolean;
function EmptyObjectHeader: TObjectHeader;

implementation

function G1ElementHasFlag(const Element: TG1Element32; Flag: TG1ElementFlag): Boolean;
begin
  Result := (Element.Flags and (UInt16(1) shl Ord(Flag))) <> 0;
end;

function GetObjectType(const Header: TObjectHeader): TLocoObjectType;
var
  v: Byte;
begin
  v := Header.Flags and $3F;
  if v > Ord(High(TLocoObjectType)) then
    raise ERangeError.CreateFmt('Object header has out-of-range type value %d', [v]);
  Result := TLocoObjectType(v);
end;

function GetSourceGame(const Header: TObjectHeader): TLocoSourceGame;
begin
  Result := TLocoSourceGame((Header.Flags shr 6) and $3);
end;

function GetObjectNameRaw(const Header: TObjectHeader): string;
begin
  SetString(Result, PAnsiChar(@Header.Name[0]), 8);
end;

function GetObjectName(const Header: TObjectHeader): string;
begin
  Result := TrimRight(GetObjectNameRaw(Header));
end;

function MakeObjectFlags(ObjType: TLocoObjectType; Source: TLocoSourceGame): UInt32;
begin
  Result := (UInt32(Ord(ObjType)) and $3F) or ((UInt32(Ord(Source)) and $3) shl 6);
end;

function MakeObjectHeader(ObjType: TLocoObjectType; Source: TLocoSourceGame;
  const Name: string): TObjectHeader;
var
  i: Integer;
  paddedName: string;
begin
  Result.Flags := MakeObjectFlags(ObjType, Source);
  paddedName := Copy(Name, 1, 8);
  while Length(paddedName) < 8 do
    paddedName := paddedName + ' ';
  for i := 0 to 7 do
    Result.Name[i] := AnsiChar(paddedName[i + 1]);
  Result.Checksum := 0; // caller should populate via ComputeObjectChecksum (see LocoSawyer.pas)
end;

function EmptyObjectHeader: TObjectHeader;
var
  i: Integer;
begin
  Result.Flags := $FFFFFFFF;
  for i := 0 to 7 do
    Result.Name[i] := AnsiChar(Byte($FF));
  Result.Checksum := $FFFFFFFF;
end;

function HeaderIsEmpty(const Header: TObjectHeader): Boolean;
var
  e: TObjectHeader;
begin
  e := EmptyObjectHeader;
  Result := (Header.Flags = e.Flags) and (Header.Checksum = e.Checksum);
end;

end.
