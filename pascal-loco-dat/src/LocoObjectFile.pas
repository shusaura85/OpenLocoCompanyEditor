{
  LocoObjectFile.pas

  High-level read/write API for a single-object Locomotion/OpenLoco ".DAT"
  file. A file is:

    TObjectHeader          16 raw (not sawyer-encoded) bytes
    <sawyer chunk>          1 byte encoding + 4 byte length + encoded data

  decoding the chunk gives you the object's data blob: a type-specific fixed
  struct, followed by one or more string tables, followed by an image table
  (exact composition/order is defined per object type - see
  LocoObjectDefs.pas and the Objects/*.cpp `T::load()` functions in
  OpenLoco for the type you care about).

  This matches OpenLoco's ObjectManager::findAndPreLoadObject (read side)
  and ObjectManager::installObject / writePackedObjects (write side) in
  Objects/ObjectManager.cpp.

  Part of the LocoDat Pascal library.
}
unit LocoObjectFile;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, LocoTypes, LocoSawyer;

type
  ELocoObjectFileError = class(Exception);

  TLocoObjectFile = class
  private
    FHeader: TObjectHeader;
    FData: TBytes;
  public
    constructor Create; overload;
    constructor Create(const AHeader: TObjectHeader; const AData: TBytes); overload;

    class function LoadFromStream(Stream: TStream): TLocoObjectFile;
    class function LoadFromFile(const FileName: string): TLocoObjectFile;

    procedure SaveToStream(Stream: TStream); overload;
    procedure SaveToStream(Stream: TStream; Encoding: TSawyerEncoding); overload;
    procedure SaveToFile(const FileName: string); overload;
    procedure SaveToFile(const FileName: string; Encoding: TSawyerEncoding); overload;

    { True if Header.Checksum matches the (header, Data) pair as currently
      held in memory. }
    function ChecksumValid: Boolean;

    { Recomputes and stores Header.Checksum from the current Data. Call this
      after mutating Data and before saving. }
    procedure UpdateChecksum;

    function ObjectType: TLocoObjectType;
    function SourceGame: TLocoSourceGame;
    function ObjectName: string;

    property Header: TObjectHeader read FHeader write FHeader;
    property Data: TBytes read FData write FData;
  end;

{ The encoding OpenLoco itself picks per object type when packing/installing
  objects (ObjectManager::getBestEncodingForObjectType). Used as the default
  by SaveToFile/SaveToStream overloads that don't take an explicit encoding. }
function DefaultEncodingFor(ObjType: TLocoObjectType): TSawyerEncoding;

{ True if FileName can be opened and fully parsed as a TLocoObjectFile -
  readable, a well-formed sawyer-encoded chunk, and an in-range object type
  in the header. Never raises; any failure (missing file, truncated data,
  corrupt RLE, unknown chunk encoding, out-of-range object type, ...) just
  yields False. This checks structural validity only, not
  Header.Checksum - use LoadFromFile + ChecksumValid if you also need to
  confirm the checksum matches. }
function IsValidLocoObjectFile(const FileName: string): Boolean;

{ As IsValidLocoObjectFile, but reads from Stream instead of a file. Leaves
  Stream's position wherever parsing stopped (start of stream, if opening
  and reading the header fails). }
function IsValidLocoObjectFileStream(Stream: TStream): Boolean;

implementation

function DefaultEncodingFor(ObjType: TLocoObjectType): TSawyerEncoding;
begin
  case ObjType of
    otCompetitor:
      Result := seUncompressed;
    otCurrency:
      Result := seRunLengthMulti;
    otTownNames, otScenarioText:
      Result := seRotate;
  else
    Result := seRunLengthSingle;
  end;
end;

constructor TLocoObjectFile.Create;
begin
  inherited Create;
  FillChar(FHeader, SizeOf(FHeader), 0);
  SetLength(FData, 0);
end;

constructor TLocoObjectFile.Create(const AHeader: TObjectHeader; const AData: TBytes);
begin
  inherited Create;
  FHeader := AHeader;
  FData := AData;
end;

class function TLocoObjectFile.LoadFromStream(Stream: TStream): TLocoObjectFile;
var
  reader: TSawyerStreamReader;
  hdr: TObjectHeader;
  data: TBytes;
begin
  reader := TSawyerStreamReader.Create(Stream);
  try
    reader.ReadRaw(hdr, SizeOf(hdr));
    data := reader.ReadChunk;
  finally
    reader.Free;
  end;
  Result := TLocoObjectFile.Create(hdr, data);
end;

class function TLocoObjectFile.LoadFromFile(const FileName: string): TLocoObjectFile;
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := LoadFromStream(fs);
  finally
    fs.Free;
  end;
end;

procedure TLocoObjectFile.SaveToStream(Stream: TStream; Encoding: TSawyerEncoding);
var
  writer: TSawyerStreamWriter;
begin
  writer := TSawyerStreamWriter.Create(Stream);
  try
    writer.WriteHeader(FHeader);
    writer.WriteChunk(Encoding, FData);
  finally
    writer.Free;
  end;
end;

procedure TLocoObjectFile.SaveToStream(Stream: TStream);
begin
  SaveToStream(Stream, DefaultEncodingFor(ObjectType));
end;

procedure TLocoObjectFile.SaveToFile(const FileName: string; Encoding: TSawyerEncoding);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(fs, Encoding);
  finally
    fs.Free;
  end;
end;

procedure TLocoObjectFile.SaveToFile(const FileName: string);
begin
  SaveToFile(FileName, DefaultEncodingFor(ObjectType));
end;

function TLocoObjectFile.ChecksumValid: Boolean;
begin
  Result := VerifyObjectChecksum(FHeader, FData);
end;

procedure TLocoObjectFile.UpdateChecksum;
begin
  FHeader.Checksum := ComputeObjectChecksum(FHeader, FData);
end;

function TLocoObjectFile.ObjectType: TLocoObjectType;
begin
  Result := GetObjectType(FHeader);
end;

function TLocoObjectFile.SourceGame: TLocoSourceGame;
begin
  Result := GetSourceGame(FHeader);
end;

function TLocoObjectFile.ObjectName: string;
begin
  Result := GetObjectName(FHeader);
end;

function IsValidLocoObjectFileStream(Stream: TStream): Boolean;
var
  obj: TLocoObjectFile;
begin
  Result := False;
  obj := nil;
  try
    try
      obj := TLocoObjectFile.LoadFromStream(Stream);
      obj.ObjectType; // raises ERangeError if the header's type bits are out of range
      Result := True;
    except
      Result := False;
    end;
  finally
    obj.Free;
  end;
end;

function IsValidLocoObjectFile(const FileName: string): Boolean;
var
  fs: TFileStream;
begin
  Result := False;
  try
    fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  except
    Exit(False);
  end;
  try
    Result := IsValidLocoObjectFileStream(fs);
  finally
    fs.Free;
  end;
end;

end.
