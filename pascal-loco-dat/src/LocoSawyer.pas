{
  LocoSawyer.pas

  "Sawyer stream" chunk encoding used throughout Locomotion / OpenLoco's
  .DAT object files (and, at the whole-file level, .SV4/.SV5 saves and
  scenarios). Transcribed byte-for-byte from OpenLoco's S5/SawyerStream.cpp
  and S5/SawyerStream.h, and Objects/ObjectManager.cpp's checksum routines.

  There are 4 encodings:
    - uncompressed     : stored as-is
    - runLengthSingle   : Locomotion's own single-buffer RLE
    - runLengthMulti    : an LZ-style back-reference scheme, itself wrapped
                           in an outer runLengthSingle pass on disk
    - rotate            : each byte bit-rotated by a cycling amount (1,3,5,7)

  Part of the LocoDat Pascal library.
}
unit LocoSawyer;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Math, LocoTypes;

type
  ESawyerError = class(Exception);

{ ---- Buffer-level encode / decode (no stream, no chunk framing) ---- }

function SawyerDecode(Encoding: TSawyerEncoding; const Data: TBytes): TBytes;
function SawyerEncode(Encoding: TSawyerEncoding; const Data: TBytes): TBytes;

type
  { Reads sawyer-encoded chunks from a stream. Mirrors OpenLoco's
    SawyerStreamReader. A "chunk" on disk is:
      [1 byte encoding][4 byte LE length][<length> bytes of encoded data]
    Object file headers themselves are NOT chunk-encoded - read them with
    ReadRaw before calling ReadChunk. }
  TSawyerStreamReader = class
  private
    FStream: TStream;
  public
    constructor Create(AStream: TStream);

    { Reads exactly Len raw bytes (no decoding), e.g. for an ObjectHeader. }
    procedure ReadRaw(var Buf; Len: Integer);

    { Reads one chunk and returns its decoded contents. }
    function ReadChunk: TBytes;

    { Whole-file trailing checksum used by .SV4/.SV5 save/scenario files
      (sum of every byte except the last 4, stored as a UInt32 LE trailer).
      NOT used by plain object .DAT files, which use the embedded
      ObjectHeader.Checksum instead (see ComputeObjectChecksum below).
      Restores the stream position afterwards. }
    function ValidateFileChecksum: Boolean;

    property Stream: TStream read FStream;
  end;

  { Writes sawyer-encoded chunks to a stream. Mirrors OpenLoco's
    SawyerStreamWriter. Tracks a running byte-sum checksum of everything
    written via Write/WriteBytes/WriteHeader/WriteChunk, for use with
    WriteChecksum on save-file style formats. }
  TSawyerStreamWriter = class
  private
    FStream: TStream;
    FChecksum: UInt32;
    procedure RawWrite(const Buf; Len: Integer);
  public
    constructor Create(AStream: TStream);

    { Writes raw bytes and accumulates them into the running checksum. }
    procedure Write(const Buf; Len: Integer); overload;
    procedure WriteBytes(const Data: TBytes);
    procedure WriteHeader(const Header: TObjectHeader);

    { Encodes Data with Encoding and writes the framed chunk. }
    procedure WriteChunk(Encoding: TSawyerEncoding; const Data: TBytes);

    { Appends the running checksum as a trailing 4-byte LE value. Only
      relevant for whole-file save/scenario checksums, see
      ValidateFileChecksum above; plain object .DAT files do not use this. }
    procedure WriteChecksum;

    property RunningChecksum: UInt32 read FChecksum;
  end;

{ ---- Object header checksum (Objects/ObjectManager.cpp) ---- }

{ Computes the checksum that belongs in ObjectHeader.Checksum for a given
  header + decoded object data blob. }
function ComputeObjectChecksum(const Header: TObjectHeader; const Data: TBytes): UInt32;

{ True if Header.Checksum matches ComputeObjectChecksum(Header, Data). }
function VerifyObjectChecksum(const Header: TObjectHeader; const Data: TBytes): Boolean;

implementation

{ ============================== TByteBuf ================================
  Small growable byte buffer used internally by the encode/decode routines.
  Mirrors the role of OpenLoco's MemoryStream in SawyerStream.cpp. }

type
  TByteBuf = record
  private
    FData: TBytes;
    FLen: Integer;
    procedure EnsureCapacity(NeedLen: Integer);
  public
    procedure Init;
    procedure AppendByte(b: Byte);
    procedure AppendFrom(const Src: TBytes; SrcOffset, Count: Integer);
    procedure AppendFill(b: Byte; Count: Integer);
    { Appends Count bytes copied from *within this same buffer*, starting at
      SrcIndex. Used by the runLengthMulti decoder's back-references. }
    procedure CopyFromSelf(SrcIndex, Count: Integer);
    function ToBytes: TBytes;
    property Len: Integer read FLen;
  end;

procedure TByteBuf.Init;
begin
  FLen := 0;
  SetLength(FData, 256);
end;

procedure TByteBuf.EnsureCapacity(NeedLen: Integer);
var
  newCap: Integer;
begin
  if NeedLen <= Length(FData) then
    Exit;
  newCap := Length(FData);
  if newCap < 256 then
    newCap := 256;
  while newCap < NeedLen do
    newCap := newCap * 2;
  SetLength(FData, newCap);
end;

procedure TByteBuf.AppendByte(b: Byte);
begin
  EnsureCapacity(FLen + 1);
  FData[FLen] := b;
  Inc(FLen);
end;

procedure TByteBuf.AppendFrom(const Src: TBytes; SrcOffset, Count: Integer);
begin
  if Count <= 0 then
    Exit;
  EnsureCapacity(FLen + Count);
  Move(Src[SrcOffset], FData[FLen], Count);
  Inc(FLen, Count);
end;

procedure TByteBuf.AppendFill(b: Byte; Count: Integer);
begin
  if Count <= 0 then
    Exit;
  EnsureCapacity(FLen + Count);
  FillChar(FData[FLen], Count, b);
  Inc(FLen, Count);
end;

procedure TByteBuf.CopyFromSelf(SrcIndex, Count: Integer);
var
  temp: array[0..63] of Byte;
  i: Integer;
begin
  if Count <= 0 then
    Exit;
  for i := 0 to Count - 1 do
    temp[i] := FData[SrcIndex + i];
  EnsureCapacity(FLen + Count);
  Move(temp[0], FData[FLen], Count);
  Inc(FLen, Count);
end;

function TByteBuf.ToBytes: TBytes;
begin
  SetLength(FData, FLen);
  Result := FData;
end;

{ ============================ rotate helpers ============================= }

function RotR8(v: Byte; n: Byte): Byte; inline;
begin
  n := n and 7;
  if n = 0 then
    Result := v
  else
    Result := Byte((v shr n) or (v shl (8 - n)));
end;

function RotL8(v: Byte; n: Byte): Byte; inline;
begin
  n := n and 7;
  if n = 0 then
    Result := v
  else
    Result := Byte((v shl n) or (v shr (8 - n)));
end;

{ ============================== decoders ================================= }

function DecodeRunLengthSingle(const Data: TBytes): TBytes;
var
  buf: TByteBuf;
  i, len, copyLen: Integer;
  rleCodeByte: Byte;
begin
  buf.Init;
  len := Length(Data);
  i := 0;
  while i < len do
  begin
    rleCodeByte := Data[i];
    if (rleCodeByte and $80) <> 0 then
    begin
      if i + 1 >= len then
        raise ESawyerError.Create('Invalid RLE run');
      copyLen := 257 - rleCodeByte;
      buf.AppendFill(Data[i + 1], copyLen);
      Inc(i, 2);
    end
    else
    begin
      copyLen := rleCodeByte + 1;
      if (i + 1 >= len) or (i + 1 + copyLen > len) then
        raise ESawyerError.Create('Invalid RLE run');
      buf.AppendFrom(Data, i + 1, copyLen);
      Inc(i, copyLen + 1);
    end;
  end;
  Result := buf.ToBytes;
end;

function DecodeRunLengthMulti(const Data: TBytes): TBytes;
var
  buf: TByteBuf;
  i, len, offset, copyLen: Integer;
begin
  buf.Init;
  len := Length(Data);
  i := 0;
  while i < len do
  begin
    if Data[i] = $FF then
    begin
      if i + 1 >= len then
        raise ESawyerError.Create('Invalid RLE run');
      buf.AppendByte(Data[i + 1]);
      Inc(i, 2);
    end
    else
    begin
      offset := (Data[i] shr 3) - 32; // always negative: -32..-1
      if (-offset) > buf.Len then
        raise ESawyerError.Create('Invalid RLE run');
      copyLen := (Data[i] and 7) + 1;
      buf.CopyFromSelf(buf.Len + offset, copyLen);
      Inc(i);
    end;
  end;
  Result := buf.ToBytes;
end;

function DecodeRotate(const Data: TBytes): TBytes;
var
  buf: TByteBuf;
  i: Integer;
  code: Byte;
begin
  buf.Init;
  code := 1;
  for i := 0 to Length(Data) - 1 do
  begin
    buf.AppendByte(RotR8(Data[i], code));
    code := (code + 2) and 7;
  end;
  Result := buf.ToBytes;
end;

{ ============================== encoders ================================= }

function EncodeRunLengthSingle(const Data: TBytes): TBytes;
var
  buf: TByteBuf;
  srcIdx, srcEndIdx, srcNormStart, count: Integer;
begin
  buf.Init;
  srcIdx := 0;
  srcEndIdx := Length(Data);
  srcNormStart := 0;
  count := 0;
  while srcIdx < srcEndIdx - 1 do
  begin
    if ((count <> 0) and (Data[srcIdx] = Data[srcIdx + 1])) or (count > 125) then
    begin
      buf.AppendByte(Byte(count - 1));
      buf.AppendFrom(Data, srcNormStart, count);
      Inc(srcNormStart, count);
      count := 0;
    end;
    if Data[srcIdx] = Data[srcIdx + 1] then
    begin
      count := 0;
      while (count < 125) and (srcIdx + count < srcEndIdx) do
      begin
        if Data[srcIdx] <> Data[srcIdx + count] then
          Break;
        Inc(count);
      end;
      buf.AppendByte(Byte(257 - count));
      buf.AppendByte(Data[srcIdx]);
      Inc(srcIdx, count);
      srcNormStart := srcIdx;
      count := 0;
    end
    else
    begin
      Inc(count);
      Inc(srcIdx);
    end;
  end;
  if srcIdx = srcEndIdx - 1 then
    Inc(count);
  if count <> 0 then
  begin
    buf.AppendByte(Byte(count - 1));
    buf.AppendFrom(Data, srcNormStart, count);
  end;
  Result := buf.ToBytes;
end;

function EncodeRunLengthMulti(const Data: TBytes): TBytes;
var
  buf: TByteBuf;
  srcLen, i, searchIndex, searchEnd: Integer;
  bestRepeatIndex, bestRepeatCount: Integer;
  repeatIndex, repeatCount, maxRepeatCount, j: Integer;
begin
  buf.Init;
  srcLen := Length(Data);
  if srcLen = 0 then
  begin
    Result := buf.ToBytes;
    Exit;
  end;

  buf.AppendByte($FF);
  buf.AppendByte(Data[0]);

  i := 1;
  while i < srcLen do
  begin
    if i < 32 then
      searchIndex := 0
    else
      searchIndex := i - 32;
    searchEnd := i - 1;

    bestRepeatIndex := 0;
    bestRepeatCount := 0;

    repeatIndex := searchIndex;
    while repeatIndex <= searchEnd do
    begin
      repeatCount := 0;
      maxRepeatCount := Min(Min(7, searchEnd - repeatIndex), srcLen - i - 1);
      j := 0;
      while j <= maxRepeatCount do
      begin
        if Data[repeatIndex + j] = Data[i + j] then
          Inc(repeatCount)
        else
          Break;
        Inc(j);
      end;
      if repeatCount > bestRepeatCount then
      begin
        bestRepeatIndex := repeatIndex;
        bestRepeatCount := repeatCount;
        if repeatCount = 8 then
          Break;
      end;
      Inc(repeatIndex);
    end;

    if bestRepeatCount = 0 then
    begin
      buf.AppendByte($FF);
      buf.AppendByte(Data[i]);
      Inc(i);
    end
    else
    begin
      buf.AppendByte(Byte((bestRepeatCount - 1) or ((32 - (i - bestRepeatIndex)) shl 3)));
      Inc(i, bestRepeatCount);
    end;
  end;

  Result := buf.ToBytes;
end;

function EncodeRotate(const Data: TBytes): TBytes;
var
  buf: TByteBuf;
  i: Integer;
  code: Byte;
begin
  buf.Init;
  code := 1;
  for i := 0 to Length(Data) - 1 do
  begin
    buf.AppendByte(RotL8(Data[i], code));
    code := (code + 2) and 7;
  end;
  Result := buf.ToBytes;
end;

{ ========================= public encode / decode ========================= }

function SawyerDecode(Encoding: TSawyerEncoding; const Data: TBytes): TBytes;
var
  intermediate: TBytes;
begin
  case Encoding of
    seUncompressed:
      Result := Data;
    seRunLengthSingle:
      Result := DecodeRunLengthSingle(Data);
    seRunLengthMulti:
      begin
        // On disk: runLengthSingle(runLengthMulti(raw)) - undo outer pass first.
        intermediate := DecodeRunLengthSingle(Data);
        Result := DecodeRunLengthMulti(intermediate);
      end;
    seRotate:
      Result := DecodeRotate(Data);
  else
    raise ESawyerError.Create('Unknown encoding');
  end;
end;

function SawyerEncode(Encoding: TSawyerEncoding; const Data: TBytes): TBytes;
var
  intermediate: TBytes;
begin
  case Encoding of
    seUncompressed:
      Result := Data;
    seRunLengthSingle:
      Result := EncodeRunLengthSingle(Data);
    seRunLengthMulti:
      begin
        intermediate := EncodeRunLengthMulti(Data);
        Result := EncodeRunLengthSingle(intermediate);
      end;
    seRotate:
      Result := EncodeRotate(Data);
  else
    raise ESawyerError.Create('Unknown encoding');
  end;
end;

{ =========================== TSawyerStreamReader =========================== }

constructor TSawyerStreamReader.Create(AStream: TStream);
begin
  inherited Create;
  FStream := AStream;
end;

procedure TSawyerStreamReader.ReadRaw(var Buf; Len: Integer);
begin
  if Len = 0 then
    Exit;
  if FStream.Read(Buf, Len) <> Len then
    raise ESawyerError.Create('Failed to read data from stream');
end;

function TSawyerStreamReader.ReadChunk: TBytes;
var
  encByte: Byte;
  chunkLen: UInt32;
  raw: TBytes;
begin
  ReadRaw(encByte, 1);
  if encByte > Ord(High(TSawyerEncoding)) then
    raise ESawyerError.CreateFmt('Unknown chunk encoding byte %d', [encByte]);

  ReadRaw(chunkLen, 4);
  SetLength(raw, Integer(chunkLen));
  if chunkLen > 0 then
    ReadRaw(raw[0], Integer(chunkLen));

  Result := SawyerDecode(TSawyerEncoding(encByte), raw);
end;

function TSawyerStreamReader.ValidateFileChecksum: Boolean;
var
  backupPos, fileLength: Int64;
  storedChecksum, actualChecksum: UInt32;
  buffer: array[0..2047] of Byte;
  i, readLen: Int64;
  j: Integer;
begin
  Result := False;
  backupPos := FStream.Position;
  fileLength := FStream.Size;
  if fileLength >= 4 then
  begin
    FStream.Position := fileLength - 4;
    ReadRaw(storedChecksum, 4);

    actualChecksum := 0;
    FStream.Position := 0;
    i := 0;
    while i < fileLength - 4 do
    begin
      readLen := Min(Int64(SizeOf(buffer)), fileLength - 4 - i);
      ReadRaw(buffer, Integer(readLen));
      for j := 0 to Integer(readLen) - 1 do
        Inc(actualChecksum, buffer[j]);
      Inc(i, readLen);
    end;

    Result := storedChecksum = actualChecksum;
  end;
  FStream.Position := backupPos;
end;

{ =========================== TSawyerStreamWriter =========================== }

constructor TSawyerStreamWriter.Create(AStream: TStream);
begin
  inherited Create;
  FStream := AStream;
  FChecksum := 0;
end;

procedure TSawyerStreamWriter.RawWrite(const Buf; Len: Integer);
begin
  if Len > 0 then
    FStream.WriteBuffer(Buf, Len);
end;

procedure TSawyerStreamWriter.Write(const Buf; Len: Integer);
var
  p: PByte;
  i: Integer;
begin
  RawWrite(Buf, Len);
  p := PByte(@Buf);
  for i := 0 to Len - 1 do
  begin
    Inc(FChecksum, p^);
    Inc(p);
  end;
end;

procedure TSawyerStreamWriter.WriteBytes(const Data: TBytes);
begin
  if Length(Data) > 0 then
    Write(Data[0], Length(Data));
end;

procedure TSawyerStreamWriter.WriteHeader(const Header: TObjectHeader);
begin
  Write(Header, SizeOf(Header));
end;

procedure TSawyerStreamWriter.WriteChunk(Encoding: TSawyerEncoding; const Data: TBytes);
var
  encoded: TBytes;
  encByte: Byte;
  lenVal: UInt32;
begin
  encoded := SawyerEncode(Encoding, Data);
  encByte := Byte(Encoding);
  Write(encByte, 1);
  lenVal := UInt32(Length(encoded));
  Write(lenVal, 4);
  WriteBytes(encoded);
end;

procedure TSawyerStreamWriter.WriteChecksum;
begin
  RawWrite(FChecksum, 4);
end;

{ ============================ object checksum ============================ }

function RotL32(v: UInt32; n: Byte): UInt32; inline;
begin
  Result := (v shl n) or (v shr (32 - n));
end;

function ChecksumByte(Seed: UInt32; b: Byte): UInt32; inline;
begin
  Result := RotL32(Seed xor UInt32(b), 11);
end;

function ComputeObjectChecksum(const Header: TObjectHeader; const Data: TBytes): UInt32;
var
  chk: UInt32;
  i: Integer;
begin
  // Only the first (low-order) byte of Flags is checksummed - matches
  // OpenLoco's computeObjectChecksum, which reads sizeof(1) byte from the
  // start of the in-memory (little-endian) ObjectHeader.
  chk := ChecksumByte(kObjectChecksumMagic, Byte(Header.Flags));
  for i := 0 to 7 do
    chk := ChecksumByte(chk, Byte(Header.Name[i]));
  for i := 0 to High(Data) do
    chk := ChecksumByte(chk, Data[i]);
  Result := chk;
end;

function VerifyObjectChecksum(const Header: TObjectHeader; const Data: TBytes): Boolean;
begin
  Result := ComputeObjectChecksum(Header, Data) = Header.Checksum;
end;

end.
