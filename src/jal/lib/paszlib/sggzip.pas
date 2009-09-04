unit sggzip;

{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}

interface

uses
  SysUtils, Classes, gzIO, ZUtil, sgstreams;

const
  // Large buffer significantly improves speed - regardless of
  // kind of working streams!
  cDefZipBuffer=1024*256;  

type
  TZipCompressionLevel=0..9;
  TZipProgressEvent=procedure(Sender: TObject; DoneBytes: integer) of object;

  // This is a Universal Compression/Decompression Engine :)

  // TGZip is a perfect solution if you wnat to compress or decompress
  // something at once.
  TGZip=class
    protected
      buf: Pointer;
      BUFLEN: cardinal;
      vOnProgress: TZipProgressEvent;
      procedure AllocBuf(sz: cardinal);
      // Low level (Stream<->gzFile)...
      procedure Compress(infile: TStream; outfile: gzFile); overload;
      procedure UnCompress(infile: gzFile; outfile: TStream); overload;
    public
      GZ_SUFFIX: string;
      EraseSource: boolean;
      CompressionLevel: 0..9;
      constructor Create; overload;
      constructor Create(bufsz: cardinal); overload;
      procedure Free;
      // "Normal" level (Stream<->Stream)...
      procedure Compress(infile: TStream; outfile: TStream); overload;
      procedure UnCompress(infile: TStream; outfile: TStream); overload;
      // High level (Filename<->Filename)...
      procedure Compress(inf, outf: string); overload;
      procedure UnCompress(inf, outf: string); overload;

      // These two functions work as real gzip:
      // when file is compressed, GZ_SUFFIX added
      // when file is decompressed, GZ_SUFFIX is removed
      // (if there is no GZ_SUFFIX, an exception is raised).
      procedure Compress(filename: string); overload;
      procedure UnCompress(filename: string); overload;

      // Next two functions do the same as Compress/UnCompress, but also
      // add/check StreamBlockHeader, which allows to write a number
      // of objects into one stream. Temporary TMemoryStream is used.
      procedure CompressAsBlock(inpstr, blockstr: TStream);
      procedure UnCompressFromBlock(blockstr, outstr: TStream);

      property BufferSize: cardinal read BUFLEN write AllocBuf;

      // This event notifies about total bytes processed from input stream.
      // If program needs to know %done, it should calculate it itself
      // from <input-stream>.Size and DoneBytes.
      property OnProgress: TZipProgressEvent read vOnProgress write vOnProgress;
  end;


  // I/O classes below (on-the-fly compression and decompression)
  // can help to reduce memory usage in some cases.
  // They don't offer any additional buffering and can be used on top of
  // only one Stream object (associated with any compressed storage).

  // This is just a base class for TGZipStream and TGUnzipStream.
  // s parameter of Create is a stream which will be associated with
  // [underlying] input/output target of the stream, e.g. TFileStream.
  // It is not closed in this classes and must be freed somewhere else! 
  TGZipStrClass=class(TStream)
    protected
      gzf: gzFile;
      Pos: int64;
    public
      constructor Create(s: TStream); virtual;
      procedure Free; virtual;
      function Seek(Offset: Longint; Origin: Word): Longint; override;
      property Position: int64 read Pos;

      // Below are stubs
      function Write(const Buffer; Count: Longint): Longint; override;
      function Read(var Buffer; Count: Longint): Longint; override;
  end;

  // Compression stream, output only.
  // Large blocks in Write are highly recommended!
  TGZipStream=class(TGZipStrClass)
    public
      constructor Create(s: TStream); overload; override;
      constructor CreateC(s: TStream; Compression: TZipCompressionLevel); overload;
      function Write(const Buffer; Count: Longint): Longint; override;
  end;

  // Decompression stream, input only.
  // Large blocks in Read are highly recommended!
  TGUnzipStream=class(TGZipStrClass)
    public
      constructor Create(s: TStream); override;
      function Read(var Buffer; Count: Longint): Longint; override;
  end;

implementation

procedure TGZip.AllocBuf(sz: cardinal);
begin
  if Assigned(buf) then FreeMem(buf);
  GetMem(buf, sz);
  BUFLEN:=sz;
end;

constructor TGZip.Create;
begin
  Create(cDefZipBuffer);
end;

constructor TGZip.Create(bufsz: cardinal);
begin
  inherited Create;
  vOnProgress:=nil;
  GZ_SUFFIX:='.gz';
  EraseSource:=false;
  CompressionLevel:=9;
  buf:=nil;
  AllocBuf(bufsz);
end;

procedure TGZip.Free;
begin
  FreeMem(buf);
  inherited Free;
end;

procedure TGZip.Compress(infile: TStream; outfile: gzFile);
var total, len, err: integer;
begin
  total:=0;
  try
    while true do begin
      //blockread(infile, buf, BUFLEN, len);
      len:=infile.Read(buf^, BUFLEN);
      total:=total+len;
      if Assigned(vOnProgress) then vOnProgress(Self, total);
      if len=0 then break;
      if gzwrite(outfile, buf, len)<>len then
        raise Exception.Create('gzwrite error: '+gzerror(outfile, err));
    end; {WHILE}
  except
    on E: Exception do raise Exception.Create('Compress(Stream->gzFile): '+E.Message);
  end;
end;

procedure TGZip.UnCompress(infile: gzFile; outfile: TStream);
var len, total, written, err: integer; 
begin
  total:=0;
  try
    while true do begin
      len:=gzread(infile, buf, BUFLEN);
      if len<0 then raise Exception.Create(gzerror(infile, err));
      total:=total+len;
      if Assigned(vOnProgress) then vOnProgress(Self, total);
      if len=0 then break;
      //blockwrite (outfile, buf, len, written);
      written:=outfile.Write(buf^, len);
      if written<>len then
        raise Exception.Create('write error');
    end; {WHILE}
  except
    on E: Exception do raise Exception.Create('Uncompress(gzFile->Stream): '+E.Message);
  end;
end;

procedure TGZip.Compress(infile: TStream; outfile: TStream);
var outgzfile : gzFile; mode: string;
begin
  try
    mode:='w'+intToStr(CompressionLevel);
    outgzfile:=gzopen(outfile, mode, false);
    if outgzfile=nil then raise Exception.Create('can''t gzopen');
    try
      Compress(infile, outgzfile); // calling lower-level function
    finally
      if (gzclose(outgzfile) <> 0{Z_OK}) then
        raise Exception.Create('gzclose error');
    end;
  except
    on E: Exception do raise Exception.Create('Compress(Stream->Stream): '+E.Message);
  end;
end;

procedure TGZip.UnCompress(infile: TStream; outfile: TStream);
var ingzfile: gzFile;
begin
  try
    ingzfile:=gzopen(infile, 'r', false);
    if ingzfile=nil then raise Exception.Create('can''t gzopen');
    try
      Uncompress (ingzfile, outfile); // calling lower-level function
    finally
      if (gzclose (ingzfile) <> 0{Z_OK}) then raise Exception.Create('gzclose error');
    end;
  except
    on E: Exception do raise Exception.Create('UnCompress(Stream->Stream): '+E.Message);
  end;
end;

procedure TGZip.Compress(inf, outf: string);
var infile, outfile: TFileStream;
begin
  try
    infile:=TFileStream.Create(inf, fmOpenRead);
    try
      outfile:=TFileStream.Create(outf, fmCreate);
      try
        Compress(infile, outfile);
        if EraseSource then DeleteFile(inf);
      finally
        outfile.Free;
      end;
    finally
      infile.Free;
    end;
  except
    on E: Exception do raise Exception.Create('Compress(File->File): '+E.Message);
  end;
end;

procedure TGZip.UnCompress(inf, outf: string);
var infile, outfile: TFileStream;
begin
  try
    infile:=TFileStream.Create(inf, fmOpenRead);
    try
      outfile:=TFileStream.Create(outf, fmCreate);
      try
        Uncompress (infile, outfile);
        if EraseSource then DeleteFile(inf);
      finally
        outfile.Free;
      end;
    finally
      infile.Free;
    end;
  except
    on E: Exception do raise Exception.Create('UnCompress(File->File): '+E.Message);
  end;
end;

procedure TGZip.Compress(filename: string);
begin
  Compress(filename, filename+GZ_SUFFIX);
end;

procedure TGZip.UnCompress(filename: string);
var l, g: integer;
begin
  l:=Length(filename);
  g:=Length(GZ_SUFFIX);
  if Copy(filename, l-g+1, g)<>GZ_SUFFIX then
    raise Exception.Create('UnCompress(gzip mode): file '+filename+' doesn''t have '+GZ_SUFFIX+' suffix.')
  else
    UnCompress(filename, Copy(filename, 1, l-g));
end;

procedure TGZip.CompressAsBlock(inpstr, blockstr: TStream);
var tmp: TStreamBlock;
begin
  tmp:=TStreamBlock.Create;
  try
    Compress(inpstr, tmp);
    tmp.SaveToStream(blockstr);
  finally
    tmp.Free;
  end;
end;

procedure TGZip.UnCompressFromBlock(blockstr, outstr: TStream);
var tmp: TStreamBlock;
begin
  tmp:=TStreamBlock.Create;
  try
    tmp.LoadFromStream(blockstr);
    UnCompress(tmp, outstr);
  finally
    tmp.Free;
  end;
end;








constructor TGZipStrClass.Create(s: TStream);
begin
  inherited Create;
end;

procedure TGZipStrClass.Free;
begin
  if (gzclose(gzf) <> 0{Z_OK}) then
    raise Exception.Create('gzclose error!');
  inherited Free;
end;

function TGZipStrClass.Seek(Offset: Longint; Origin: Word): Longint;
begin
  Result:=Position;
end;

function TGZipStrClass.Write(const Buffer; Count: Longint): Longint;
begin
  Result:=0;
end;

function TGZipStrClass.Read(var Buffer; Count: Longint): Longint;
begin
  Result:=0;
end;

constructor TGZipStream.CreateC(s: TStream; Compression: TZipCompressionLevel); 
begin
  inherited Create(s);
  Pos:=0;
  gzf:=gzopen(s, 'w'+IntToStr(Compression), false);
  if gzf=nil then raise Exception.Create('Can''t gzopen.');
end;

constructor TGZipStream.Create(s: TStream);
begin
  CreateC(s, 9);
end;

function TGZipStream.Write(const Buffer; Count: Longint): Longint;
begin
  Pos:=Pos+Count;
  Result:=gzwrite(gzf, @Buffer, Count);
end;

constructor TGUnzipStream.Create(s: TStream);
begin
  inherited Create(s);
  gzf:=gzopen(s, 'r', false);
  if gzf=nil then raise Exception.Create('Can''t gzopen.');
end;

function TGUnzipStream.Read(var Buffer; Count: Longint): Longint;
var err: integer;
begin
  Pos:=Pos+Count;
  Result:=gzread(gzf, @Buffer, Count);
  if Result<0 then raise Exception.Create(gzerror(gzf, err));
end;

end.
