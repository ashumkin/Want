(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 1995-2003 Juancarlo Anez, Caracas, Venezuela.              *
 * All rights reserved.                                                     *
 *                                                                          *
 * This library is free software; you can redistribute it and/or            *
 * modify it under the terms of the GNU Lesser General Public               *
 * License as published by the Free Software Foundation; either             *
 * version 2.1 of the License, or (at your option) any later version.       *
 *                                                                          *
 * This library is distributed in the hope that it will be useful,          *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 * Lesser General Public License for more details.                          *
 *                                                                          *
 * You should have received a copy of the GNU Lesser General Public         *
 * License along with this library; if not, write to the Free Software      *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA *
 ****************************************************************************)
{
    @brief 

    @author Juancarlo Añez
    @author Bob Arnson <sf@bobs.org>
}

unit JALGZipStreams;

interface
uses
  SysUtils,
  Classes,
  {$IFDEF VER130}
  FileCtrl,
  {$ENDIF VER130}

  JalStrings,
  JalProxyStreams,

  gZLib;

const
  rcs_id :string = '$Id: JALGZipStreams.pas 725 2003-06-05 03:39:01Z barnson $';

  gzMAGIC = $8B1F;

type
  EGZipError = class(Exception);

  TZFlushType = (
    zfNone,
    zfPartial,
    zfSync,
    zfFull,
    zfFinish
  );

  TGZipHeaderFlags = set of (
     gzFTEXT,   // is the data ASCII??
     gzFHCRC,   // does the header include a CRC16 field?
     gzFEXTRA,  // does the header include an "extra" field?
     gzFNAME,   // does the header include a filename field?
     gzFCOMMENT // does the header include a file comment field?
  );

  TGZipOS = (
    {  0 } gosFAT,
    {  1 } gosAmiga,
    {  2 } gosVMS,
    {  3 } gosUnix,
    {  4 } gosVM_CMS,
    {  5 } gosAtari,
    {  6 } gosHPFS,
    {  7 } gosMacintosh,
    {  8 } gosZ_System,
    {  9 } gosCP_M,
    { 10 } gosTOPS_20,
    { 11 } gosNTFS,
    { 12 } gosQDOS,
    { 13 } gosAcorn
    { 255  unknown }
  );

  // use small buffers to maximize interaction with underlying stream
  TGZBuf = array[0..4*1024-1] of byte;

  TGZipHeader = packed record
    magic             :Word;     // always $1F/$8B
    compressionMethod :byte;     // only 8:deflate defined
    flags             :TGZipHeaderFlags;
    modificationTime  :LongWord; // Unix format: seconds since 0:00:00 GMT, Jan 1, 1970
    extraFlags        :byte;     // compression level
    OS                :TGZipOS;
  end;

  TCRCStream = class(TStreamProxy)
     _crc :LongWord;
  public
     function Read(var Buffer; Count: Integer): Longint;    override;
     function Write(const Buffer; Count: Integer): Longint; override;
     function Seek(Offset: Longint; Origin: Word): Longint; override;

     function crc32 :LongWord;
     function crc16 :Word;
  end;

  TGZStream = class(TStreamProxy)
  protected
    _zstream  :z_stream;
     _crc32   :LongWord;

    _fileName :string;
    _comment  :string;
    _closed   :boolean;
  protected
     function Process(const Buffer; Count: Integer; flush :TZFlushType): Longint;
     virtual; abstract;

     function  getCompressedSize :Longint; virtual; abstract;
     function  getSize :Longint;           reintroduce; virtual; abstract; 
  public
     constructor Create(Strm :TStream);
     destructor Destroy; override;

     function Read(var Buffer; Count: Integer): Longint;  override;
     function Write(const Buffer; Count: Integer): Longint; override;
     function Seek(Offset: Longint; Origin: Word): Longint; override;

     procedure SetSize(Value: Longint); override;

     procedure SetFileName(fname :string); virtual;


     procedure Close; virtual;
     procedure Flush; virtual;

     property fileName :string
       read  _fileName
       write setFileName;

     property comment :string
       read  _comment
       write _comment;

     property Size :Longint
       read  getSize;

     property compressedSize :Longint
       read getCompressedSize;

     property crc32 :LongWord
       read _crc32;
  end;

  TGZipStream = class(TGZStream)
    constructor Create(Dest :TStream);

    function  Read(var Buffer; Count: Longint): Longint;  override;
    function  Seek(Offset: Longint; Origin: Word): Longint; override;
    procedure Close; override;
  protected
    _headerWritten :boolean;
    
    function  Process(const Buffer; Count: Integer; flush :TZFlushType): Longint;
    override;

    function  getCompressedSize :Longint; override;
    function  getSize :Longint;           override;

    procedure writeHeader; virtual;
  end;

  TGUnzipStream = class(TGZStream)
    constructor Create(Src :TStream);

    function  Write(const Buffer; Count: Longint): Longint;  override;
    function  Seek(Offset: Longint; Origin: Word): Longint; override;
    procedure Close; override;
  protected
    zbuf :TGZBuf;
    
    function  Process(const Buffer; Count: Integer; flush :TZFlushType): Longint;
    override;

    function  getCompressedSize :Longint; override;
    function  getSize :Longint;           override;

    procedure readHeader; virtual;
  end;

  procedure gzip(const Src :string; const Dst :string = '');
  procedure gunzip(const Src :string; const Dst :string = '');

///////////////////////////////////////////////////////////////
implementation
uses
  ZINFLATE,
  ZDEFLATE,
  CRC;

const
  Z_NO_COMPRESSION       =   0;
  Z_BEST_SPEED           =   1;
  Z_BEST_COMPRESSION     =   9;
  Z_DEFAULT_COMPRESSION  = $FF;

  SECONDS_IN_DAY = 24*60*60;

var
  UnixBaseDate :TDateTime = 0;

function check(strm :z_stream; code: Integer): Integer;
begin
  Result := code;
  if code < 0 then
    raise EGZipError.Create(format('%d: %s', [code, strm.msg]));
end;

procedure deflateInit(var strm : z_stream);
begin
  check(strm,
     deflateInit2(  strm,
                             -1, // Z_DEFAULT_COMPRESSION,
                             Z_DEFLATED,
                            -MAX_WBITS, // undocumented: negative to supress zlib wrapper
                             MAX_MEM_LEVEL,
                             Z_DEFAULT_STRATEGY)
     )
end;

procedure deflateEnd(var strm : z_stream);
begin
  check(strm, ZDeflate.deflateEnd(strm));
end;

// return the number of bytes written to the output buffer
function deflate(var strm : z_stream; flush :TZFlushType) :Integer;
begin
  result := check(strm, ZDeflate.deflate(strm, ord(flush)));
end;

procedure inflateInit(var strm : z_stream);
begin
  check(strm, Zinflate.inflateInit2(strm, -MAX_WBITS))
end;

procedure inflateReset(var strm : z_stream);
begin
  check(strm, Zinflate.inflateReset(strm))
end;

procedure inflateEnd(var strm : z_stream);
begin
  check(strm, Zinflate.inflateEnd(strm));
end;

// return the number of bytes written to the output buffer
function inflate(var strm : z_stream; flush :TZFlushType) :Integer;
begin
  result := check(strm, Zinflate.inflate(strm, ord(flush)));
end;

procedure gzip(const Src :string; const Dst :string);
var
  SrcStrm  :TFileStream;
  DstStrm  :TFileStream;
  ZipStrm  :TGZipStream;
  DestName :string;
begin
  SrcStrm := TFileStream.Create(Src, fmOpenRead or fmShareDenyWrite);
  try
    DestName := Dst;
    if DestName = '' then
      DestName := Src + '.gz';
    DstStrm := TFileStream.Create(DestName, fmCreate or fmShareDenyWrite);
    try
      ZipStrm := TGZipStream.Create(DstStrm);
      try
         ZipStrm.fileName := ExtractFileName(Src);
         ZipStrm.CopyFrom(SrcStrm, 0);
         ZipStrm.Close;
      finally
        ZipStrm.Free;
      end;
    finally
      DstStrm.Free;
    end;
  finally
    SrcStrm.Free;
  end;
end;

procedure gunzip(const Src :string; const Dst :string);
var
  SrcStrm  :TFileStream;
  DstStrm  :TFileStream;
  ZipStrm  :TGUnzipStream;
  DestName :string;
begin
  SrcStrm := TFileStream.Create(Src, fmOpenRead or fmShareDenyWrite);
  try
    ZipStrm := TGUnzipStream.Create(SrcStrm);
    try
      DestName := Dst;
      if (DestName = '')  then
        DestName := ExtractFileDir(Src);

      if DirectoryExists(DestName) then
      begin
        if ZipStrm.fileName <> '' then
           DestName := DestName + '/' + ZipStrm.fileName
        else if StrEndsWith(Src, '.gz') then
           DestName := DestName + '/' + StrLeft(ExtractFileName(Src), Length(Src)-3)
        else
           DestName := '';
      end;
      if DestName = '' then
        raise EGZipError.CreateFmt('Could not figure out uncompressed file name for "%s"', [Src]);

      DstStrm := TFileStream.Create(DestName, fmCreate or fmShareDenyWrite);
      try
         DstStrm.CopyFrom(ZipStrm, 0);
      finally
        DstStrm.Free;
      end;
    finally
      ZipStrm.Free;
    end;
  finally
    SrcStrm.Free;
  end;
end;


{ TCRCStream }

function TCRCStream.crc16: Word;
begin
  result := Word(_crc)
end;

function TCRCStream.crc32: LongWord;
begin
  result := LongWord(_crc)
end;

function TCRCStream.Read(var Buffer; Count: Integer): Longint;
begin
  result := inherited Read(Buffer, Count);
  _crc := CRC.crc32(_crc, @Buffer, Count);
end;

function TCRCStream.Seek(Offset: Integer; Origin: Word): Longint;
begin
  result := _strm.Seek(Offset, Origin);
  if (Offset = 0) and (Origin = soFromBeginning) then
    _crc := 0;
end;

function TCRCStream.Write(const Buffer; Count: Integer): Longint;
begin
  result := inherited Write(Buffer, Count);
  _crc := CRC.crc32(_crc, @Buffer, Count);
end;

{ TGZStream }

constructor TGZStream.Create(Strm: TStream);
begin
  inherited Create(TCRCStream.Create(Strm));
end;

destructor TGZStream.Destroy;
begin
  Close;
  _strm.Free; // it's a crc proxy !!
  inherited Destroy;
end;

function TGZStream.Read(var Buffer; Count: Integer): Longint;
begin
   result := Process(Buffer, Count, zfNone);
end;

function TGZStream.Write(const Buffer; Count: Integer): Longint;
begin
   result := Process(Buffer, Count, zfNone);
end;

function TGZStream.Seek(Offset: Integer; Origin: Word): Longint;
begin
  raise EGZipError.Create('Seek not allowed');
end;

procedure TGZStream.setFileName(fname: string);
begin
  _fileName := trim(ExtractFileName(fname));
end;

procedure TGZStream.setSize(Value: Longint);
begin
  raise EGZipError.Create('Setting size not allowed');
end;

procedure TGZStream.Flush;
var
   dummy :byte;
begin
   Process(dummy, 0, zfFull);
end;

procedure TGZStream.Close;
var
  dummy :byte;
begin
  if not _closed then begin
    Process(dummy, 0, zfFinish);
    _closed := true;
  end
end;

{ TGZipStream }

constructor TGZipStream.Create(Dest :TStream);
begin
  inherited Create(Dest);
  deflateInit(_zstream);
end;

procedure TGZipStream.Close;
var
  s :LongWord;
begin
  if not _closed then begin
    inherited Close;
    deflateEnd(_zstream);
    s := _zstream.total_in;
    _strm.WriteBuffer(_crc32, sizeOf(_crc32));
    _strm.WriteBuffer(s,      sizeOf(s));
  end
end;

procedure TGZipStream.writeHeader;
var
   header    :TGZipHeader;
   //headerCRC :Word;
begin
  if _headerWritten then
    EXIT;
  // write the simplest of headers to the destination stream
  fillChar(header, sizeOf(header), 0);
  with header do begin
    magic := gzMAGIC;

    compressionMethod := Z_DEFLATED;
    modificationTime  := Round(SECONDS_IN_DAY*(Now - UnixBaseDate));
    //!!!extraFlags        := Levels[_compressionLevel];
    OS                := gosUnix;

    //!!! include(flags, gzFHCRC);
    if length(fileName) > 0 then
      Include(flags, gzFNAME);
    if length(comment) > 0 then
      Include(flags, gzFCOMMENT);
  end;
  _strm.WriteBuffer(header, sizeOf(header));
   if length(fileName) > 0 then
     _strm.WriteBuffer(PChar(fileName)^, length(fileName)+1);
   if length(comment) > 0 then
     _strm.WriteBuffer(PChar(comment)^, length(comment)+1);
   (*!!! CRC not compatible with older versions of GUNZIP
   headerCRC := (_strm as TCRCStream).crc16;
   _strm.WriteBuffer( headerCRC, 2);
   *)
  _headerWritten := true;
end;

function TGZipStream.Seek(Offset: Integer; Origin: Word): Longint;
begin
  if (Origin = soFromCurrent) and (Offset = 0) then
    result := _zstream.total_in
  else
    result := inherited Seek(Offset, Origin);
end;

function TGZipStream.getCompressedSize: Longint;
begin
  result := _strm.Size
end;

function TGZipStream.getSize: Longint;
begin
  result := _zstream.total_out;
end;

function TGZipStream.Read(var Buffer; Count: Integer): Longint;
begin
  raise EGZipError.Create('Reading not allowed');
end;

function TGZipStream.Process(const Buffer; Count :Integer; flush: TZFlushType): Longint;
var
  zbuf :TGZBuf;
  n    :Integer;
  code :Integer;
begin
  writeHeader;
  code := 0;
  _zstream.next_in := @Buffer;
  _zstream.avail_in := Count;
  while (_zstream.avail_in > 0)
  or ((flush = zfFinish) and (code <> Z_STREAM_END))
  do begin
    _zstream.next_out := @zbuf;
    _zstream.avail_out := sizeof(zbuf);

    n := Longint(_zstream.avail_out);
    code := deflate(_zstream, flush);
    n := n - Longint(_zstream.avail_out);

    _strm.WriteBuffer(zbuf, n);
  end;
  _crc32 := CRC.crc32(_crc32, @Buffer, Count);
  Result := Count;
end;

{ TGUnzipStream }

constructor TGUnzipStream.Create(Src: TStream);
begin
  inherited Create(Src);
  inflateInit(_zstream);
  readHeader;
end;

procedure TGUnzipStream.readHeader;

function readString :string;
var
  c      :char;
begin
   result := '';
   repeat
      _strm.ReadBuffer(c, 1);
      result := result + c;
   until c = #0;
   result := trim(result);
end;

var
  header :TGZipHeader;
  extra  :Longint;
  buf    :TGZBuf;
  crc16     :Word;
  headerCRC :Word;
begin
  _strm.ReadBuffer(header, sizeOf(header));
  if header.magic <> gzMAGIC then
    raise EGZipError.Create('nog in gzip format');
  if gzFEXTRA in header.flags then begin
    _strm.ReadBuffer(extra, sizeOf(extra));
    while extra > 0 do
       if extra > sizeOf(buf) then
         _strm.ReadBuffer(buf, sizeOf(buf))
       else
         _strm.ReadBuffer(buf, extra);
       dec(extra, sizeOf(buf));
  end;
  if gzFNAME in header.flags then
     _fileName := readString;
  if gzFCOMMENT in header.flags then
     _comment := readString;
  if gzFHCRC in header.flags then begin
    headerCRC := (_strm as TCRCStream).crc16;
    _strm.ReadBuffer(crc16, sizeOf(crc16));
    if crc16 <> headerCRC then
      raise EGZipError.Create('corrupted header');
  end;
  _crc32 := 0;
end;

procedure TGUnzipStream.Close;
begin
  if not _closed then begin
    inherited Close;
     seek(0, soFromEnd);
     inflateEnd(_zstream);
  end
end;

function TGUnzipStream.getCompressedSize: Longint;
begin
  result := _strm.size
end;

function TGUnzipStream.getSize: Longint;
var
  c, s :Longint;
  pos  :Longint;
begin
  pos := _strm.Position;
  try
    _strm.Seek(-8, soFromEnd);
    _strm.ReadBuffer(c, sizeOf(c));
    _strm.ReadBuffer(s, sizeOf(s));

    Result := s;
  finally
    _strm.Seek(pos, soFromBeginning);
  end;
end;


function TGUnzipStream.Write(const Buffer; Count: Integer): Longint;
begin
  raise EGZipError.Create('Writing not allowed');
end;

function TGUnzipStream.Process(const Buffer; Count: Integer; flush: TZFlushType): Longint;
var
  c     :LongWord;
  s     :LongWord;
  atEnd :boolean;
begin
  if (Count = 0) then
  begin
    Result := 0;
    EXIT;
  end;

  _zstream.next_out := @Buffer;
  _zstream.avail_out := Count;
  atEnd := false;
  while _zstream.avail_out > 0 do begin
    if _zstream.avail_in = 0 then begin
      _zstream.next_in  := @zbuf;
      _zstream.avail_in := _strm.Read(zbuf, sizeof(zbuf));
    end;
    if _zstream.avail_in = 0 then
      BREAK;
    if inflate(_zstream, flush) = Z_STREAM_END then begin
      atEnd := true;
      BREAK;
    end
  end;

  Result := Count - Longint(_zstream.avail_out);
  _crc32 := CRC.crc32(_crc32, @Buffer, Result);

  if atEnd then
  begin
    _strm.Seek(-8, soFromEnd);
    _strm.ReadBuffer(c, sizeOf(c));
    _strm.ReadBuffer(s, sizeOf(s));
    if (_crc32 <> c) or (_zstream.total_out <> s) then
      raise EGZipError.Create('corrupted data');
  end
end;


function TGUnzipStream.Seek(Offset: Integer; Origin: Word): Longint;
var
  n,  c :Integer;
  Buf   :TGZBuf;
  currentPos :Longint;
begin
  currentPos := _zstream.total_out;
  if Origin = soFromCurrent then
     Inc(Offset, currentPos)
  else if Origin = soFromEnd then
    Offset := Size - Offset;

  if Offset < currentPos then begin
    inflateReset(_zstream);
    _zstream.avail_in := 0;
    _strm.Position := 0;
    readHeader;
    currentPos := 0;
  end;

  if Offset = currentPos then
  begin
    Result := currentPos;
    Exit;
  end;

  n := (Offset - currentPos);
  c := 1;
  while (n >= sizeOf(buf)) and (c > 0) do begin
    c := Read(Buf, sizeOf(Buf));
    Dec(n, c);
  end;
  if c > 0 then
    Read(Buf, n);
  Result := _zstream.total_out
end;

initialization
  UnixBaseDate := EncodeDate(1970, 1, 1) + EncodeTime(0,0,0,0)
end.





