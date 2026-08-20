{
  LocoObjectDefs.pas

  Per-object-type fixed "header struct" definitions - the first field of an
  object's decoded data blob, before whatever variable-length data follows
  it (string table(s), and for most - but NOT all - types, an image table
  afterwards; see "Which types have an image table" below).

  This library implements 6 object types' fixed structs (Climate, Currency,
  Cargo, Region, ScenarioText, TownNames) as worked examples of the
  pattern. The other 28 types are NOT implemented here (to avoid guessing
  at layouts this library hasn't verified byte-for-byte) -
  LocoObjectFixedHeaderSize below documents which is which, and "Adding
  another object type" in README.md explains how to add one from the
  matching OpenLoco/include/OpenLoco/Objects/*.h header.

  Most types follow the same overall recipe once you know 3 things from
  their header/.cpp:
    1. the fixed struct layout (a #pragma pack(push,1) struct in the .h)
    2. how many string table fields it has (kNumStringsPerObjectType in
       OpenLoco's Objects/ObjectStringTable.cpp, reproduced below)
    3. whether an image table follows, and at what offset - see below,
       this is NOT simply "always, right after the string table(s))"

  Part of the LocoDat Pascal library.
}
unit LocoObjectDefs;

{$mode delphi}{$H+}

interface

uses
  SysUtils, LocoTypes, LocoStringTable;

type
  { Climate object - OpenLoco include/OpenLoco/Objects/ClimateObject.h
    static_assert(sizeof(ClimateObject) == 0xA); 1 string table follows,
    and NOTHING after that - Climate objects have no image table at all
    (verified against ClimateObject::load in Objects/ClimateObject.cpp,
    which asserts remainingData.size() == 0 right after the string table). }
  TLocoClimateObject = packed record
    NameStringId: UInt16;
    FirstSeason: Byte;
    SeasonLength: array[0..3] of Byte;
    WinterSnowLine: Byte;
    SummerSnowLine: Byte;
    Pad09: Byte;
  end;

  { Currency object - Objects/CurrencyObject.h
    static_assert(sizeof(CurrencyObject) == 0xC); 3 string tables follow
    (name, prefixSymbol, suffixSymbol), then an image table.
    Always written with SawyerEncoding = runLengthMulti (see
    DefaultEncodingFor in LocoObjectFile.pas). }
  TLocoCurrencyObject = packed record
    NameStringId: UInt16;
    PrefixSymbolStringId: UInt16;
    SuffixSymbolStringId: UInt16;
    ObjectIcon: UInt32;
    Separator: Byte;
    Factor: Byte;
  end;

  { Cargo object - Objects/CargoObject.h
    static_assert(sizeof(CargoObject) == 0x1F); 4 string tables follow
    (name, unitsAndCargoName, unitNameSingular, unitNamePlural), then an
    image table. }
  TLocoCargoObject = packed record
    NameStringId: UInt16;
    UnitWeight: UInt16;
    CargoTransferTime: UInt16;
    UnitsAndCargoNameStringId: UInt16;
    UnitNameSingularStringId: UInt16;
    UnitNamePluralStringId: UInt16;
    UnitInlineSprite: UInt32;
    CargoCategory: UInt16;   // see CargoCategory enum in CargoObject.h
    Flags: Byte;             // see CargoObjectFlags in CargoObject.h
    NumPlatformVariations: Byte;
    StationCargoDensity: Byte;
    PremiumDays: Byte;
    MaxNonPremiumDays: Byte;
    NonPremiumRate: UInt16;
    PenaltyRate: UInt16;
    PaymentFactor: UInt16;
    PaymentIndex: Byte;
    UnitSize: Byte;
  end;

  { Region object - Objects/RegionObject.h
    static_assert(sizeof(RegionObject) == 0x12). 1 string table follows,
    but the image table does NOT come right after it like Currency/Cargo -
    see RegionObject::load in Objects/RegionObject.cpp:
      1 string table
      NumCargoInfluenceObjects * ObjectHeader (16 bytes each) - cargo
        dependency references
      a further run of ObjectHeader entries ("will load" dependencies),
        terminated by a single $FF byte (not a full empty ObjectHeader)
      THEN the image table.
    Use LocateRegionImageTableOffset (or TryLocateImageTableOffset) below
    rather than assuming string-table-end == image-table-start for this
    type. }
  TLocoRegionObject = packed record
    NameStringId: UInt16;
    Image: UInt32;
    Flags: UInt16;            // see RegionObjectFlags in RegionObject.h
    NumCargoInfluenceObjects: Byte;
    CargoInfluenceObjectIds: array[0..3] of Byte;
    CargoInfluenceTownFilter: array[0..3] of Byte; // CargoInfluenceTownFilterType
    Pad11: Byte;
  end;

  { Scenario text object - Objects/ScenarioTextObject.h. 2 string tables
    follow (name, details), then NOTHING - no image table (verified
    against ScenarioTextObject::load in Objects/ScenarioTextObject.cpp,
    which asserts remainingData.size() == 0 right after the 2nd string
    table). }
  TLocoScenarioTextObject = packed record
    NameStringId: UInt16;
    DetailsStringId: UInt16;
    Pad04: array[0..1] of Byte;
  end;

  { Town names object - Objects/TownNamesObject.h
    static_assert(sizeof(TownNamesObject) == 0x1A). 1 string table follows
    (the object's own display name only), then a custom "name parts" data
    block - NOT a string table and NOT an image table (verified against
    TownNamesObject::load in Objects/TownNamesObject.cpp, whose comment
    literally says "Town name object has an additional structure after
    this point so can't assert its size"). Each Category's Offset indexes
    into that block to find Count null-terminated name-part strings; this
    library does not parse that block yet (undocumented in the .cpp beyond
    the Category fields themselves - it's read on demand elsewhere at
    runtime, not during load()), so only the fixed struct + display-name
    string table are exposed here. Town names objects have no image table
    at all. }
  TLocoTownNamesCategory = packed record
    Count: Byte;
    Bias: Byte;
    Offset: UInt16;
  end;

  TLocoTownNamesObject = packed record
    NameStringId: UInt16;
    Categories: array[0..5] of TLocoTownNamesCategory;
  end;

const
  { Number of string table fields following the fixed struct, one per
    object type. Reproduced from kNumStringsPerObjectType in OpenLoco's
    Objects/ObjectStringTable.cpp - needed to know how many times to call
    DecodeStringTable before whatever comes next (see
    "Which types have an image table" below - it is NOT always an image
    table). }
  LocoNumStringTables: array[TLocoObjectType] of Integer = (
    1,  // otInterfaceSkin
    1,  // otSound
    3,  // otCurrency
    1,  // otSteam
    1,  // otCliffEdge
    1,  // otWater
    1,  // otLand
    1,  // otTownNames
    4,  // otCargo
    1,  // otWall
    2,  // otTrackSignal
    1,  // otLevelCrossing
    1,  // otStreetLight
    1,  // otTunnel
    1,  // otBridge
    1,  // otTrainStation
    1,  // otTrackExtra
    1,  // otTrack
    1,  // otRoadStation
    1,  // otRoadExtra
    1,  // otRoad
    1,  // otAirport
    1,  // otDock
    1,  // otVehicle
    1,  // otTree
    1,  // otSnow
    1,  // otClimate
    1,  // otHillShapes
    1,  // otBuilding
    1,  // otScaffolding
    8,  // otIndustry
    1,  // otRegion
    2,  // otCompetitor
    2   // otScenarioText
  );

  { Fixed-header byte size of each object type's leading struct, taken from
    the static_assert(sizeof(...)) in the matching OpenLoco header. -1 means
    "not transcribed into this library yet" - see the .h file named in the
    comment for the authoritative layout. }
  LocoObjectFixedHeaderSize: array[TLocoObjectType] of Integer = (
    -1,   // otInterfaceSkin  - Objects/InterfaceSkinObject.h
    -1,   // otSound          - Objects/SoundObject.h (has an embedded WAV, no image table - see below)
    $0C,  // otCurrency       - Objects/CurrencyObject.h (TLocoCurrencyObject)
    -1,   // otSteam          - Objects/SteamObject.h
    -1,   // otCliffEdge      - Objects/CliffEdgeObject.h
    -1,   // otWater          - Objects/WaterObject.h
    -1,   // otLand           - Objects/LandObject.h
    $1A,  // otTownNames      - Objects/TownNamesObject.h (TLocoTownNamesObject; no image table)
    $1F,  // otCargo          - Objects/CargoObject.h (TLocoCargoObject)
    -1,   // otWall           - Objects/WallObject.h
    -1,   // otTrackSignal    - Objects/TrainSignalObject.h
    -1,   // otLevelCrossing  - Objects/LevelCrossingObject.h
    -1,   // otStreetLight    - Objects/StreetLightObject.h
    -1,   // otTunnel         - Objects/TunnelObject.h
    -1,   // otBridge         - Objects/BridgeObject.h
    -1,   // otTrainStation   - Objects/TrainStationObject.h
    -1,   // otTrackExtra     - Objects/TrackExtraObject.h
    -1,   // otTrack          - Objects/TrackObject.h
    -1,   // otRoadStation    - Objects/RoadStationObject.h
    -1,   // otRoadExtra      - Objects/RoadExtraObject.h
    -1,   // otRoad           - Objects/RoadObject.h
    -1,   // otAirport        - Objects/AirportObject.h
    -1,   // otDock           - Objects/DockObject.h
    -1,   // otVehicle        - Objects/VehicleObject.h
    -1,   // otTree           - Objects/TreeObject.h
    -1,   // otSnow           - Objects/SnowObject.h
    $0A,  // otClimate        - Objects/ClimateObject.h (TLocoClimateObject; no image table)
    -1,   // otHillShapes     - Objects/HillShapesObject.h
    -1,   // otBuilding       - Objects/BuildingObject.h
    -1,   // otScaffolding    - Objects/ScaffoldingObject.h
    -1,   // otIndustry       - Objects/IndustryObject.h
    $12,  // otRegion         - Objects/RegionObject.h (TLocoRegionObject)
    -1,   // otCompetitor     - Objects/CompetitorObject.h
    $06   // otScenarioText   - Objects/ScenarioTextObject.h (TLocoScenarioTextObject; no image table)
  );

{ ==================== Which types have an image table ====================

  Most object types are: fixed struct -> string table(s) -> image table.
  Known exceptions (verified against each type's OpenLoco Objects/*.cpp):

    otClimate       - fixed struct + 1 string table, nothing else. No image table.
    otScenarioText  - fixed struct + 2 string tables, nothing else. No image table.
    otTownNames     - fixed struct + 1 string table + a custom "name parts"
                       block (not parsed by this library yet - see
                       TLocoTownNamesObject above). No image table.
    otSound         - has an embedded WAV file instead of an image table.
                       Not implemented by this library yet.
    otRegion        - DOES have an image table, but it is not immediately
                       after the string table - see TLocoRegionObject above
                       and LocateRegionImageTableOffset below.

  All other types are unverified either way (LocoObjectFixedHeaderSize is
  -1 for them) - check the type's own Objects/<Type>Object.cpp load()
  before assuming the generic "string tables then image table" layout. }

{ Region-specific: walks past the NumCargoInfluenceObjects dependency
  ObjectHeaders and the $FF-terminated "will load" ObjectHeader list that
  sit between Region's string table and its image table. Pass the offset
  immediately after decoding the (single) string table. }
function LocateRegionImageTableOffset(const Data: TBytes; AfterStringTableOffset: Integer;
  NumCargoInfluenceObjects: Integer): Integer;

{ Attempts to locate where Type's image table starts within Data (the
  object's full decoded data blob). Returns False (and leaves Offset
  undefined) if this type is known to have no image table (Climate,
  ScenarioText, TownNames), has an unimplemented image table (Sound), or
  its fixed struct layout isn't transcribed into this library yet. Handles
  Region's extra dependency lists automatically. }
function TryLocateImageTableOffset(ObjType: TLocoObjectType; const Data: TBytes;
  out Offset: Integer): Boolean;

implementation

function LocateRegionImageTableOffset(const Data: TBytes; AfterStringTableOffset: Integer;
  NumCargoInfluenceObjects: Integer): Integer;
const
  kObjectHeaderSize = 16;
var
  pos, len: Integer;
begin
  len := Length(Data);
  pos := AfterStringTableOffset + NumCargoInfluenceObjects * kObjectHeaderSize;

  while (pos < len) and (Data[pos] <> $FF) do
    Inc(pos, kObjectHeaderSize);

  if pos >= len then
    raise Exception.Create('Region object: "will load" dependency list ran past end of data without a terminator');

  Inc(pos); // skip the single $FF terminator byte
  Result := pos;
end;

function TryLocateImageTableOffset(ObjType: TLocoObjectType; const Data: TBytes;
  out Offset: Integer): Boolean;
var
  fixedSize, numStrings, i, consumed: Integer;
  entries: TArray<TLocoStringEntry>;
  region: TLocoRegionObject;
begin
  Result := False;
  Offset := 0;

  case ObjType of
    otClimate, otScenarioText, otTownNames, otSound:
      Exit; // no image table (Sound: not implemented by this library yet)
  end;

  fixedSize := LocoObjectFixedHeaderSize[ObjType];
  if fixedSize < 0 then
    Exit; // struct layout not transcribed into this library yet

  numStrings := LocoNumStringTables[ObjType];
  Offset := fixedSize;
  for i := 1 to numStrings do
  begin
    consumed := DecodeStringTable(Data, Offset, entries);
    Inc(Offset, consumed);
  end;

  if ObjType = otRegion then
  begin
    if Length(Data) < SizeOf(region) then
      Exit;
    Move(Data[0], region, SizeOf(region));
    Offset := LocateRegionImageTableOffset(Data, Offset, region.NumCargoInfluenceObjects);
  end;

  Result := True;
end;

end.
