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
}

unit JalZipStreams;

interface
uses
  SysUtils,
  Classes,

  JclSysUtils,

  JalUtils,
  JalPaths,

  ZipUtils,
  ZIP,
  UNZIP;

type
  EZipFileException = class(Exception);
  EZipFileError = class(EZipFileException);

  TCompressionLevel = (
     zlDefault,
     zlNone,
     zlBestSpeed,
     zlBestCompression
   );


  TZipStream = class(TStream)
  private
  protected
    FZipFileName :TPath;
    FEntryName   :TPath;
    FEntryOpen   :boolean;
    FComment     :string;

    FCompress    :boolean;
    FCompression :TCompressionLevel;

    FZipFile     :ZipUtils.ZipFile;

    FPaths       :TStringList;

    procedure Error(Msg :string);
    procedure NotImplementedError(Msg :string);

    function CheckFileTime(const Path :IPath; Time :TDateTime = 0) :TDateTime;
  public
    constructor Create(const ZipFileName :TPath);
    destructor  Destroy; override;

    function Read(var Buffer; Count: Longint): Longint;    override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;

    procedure NewEntry(  const EntryName    :TPath;
                               Attributes   :TFileAttributes;
                               Time         :TDateTime;
                               Compress     :boolean;
                               Comment      :string = ''); overload;
    procedure CloseEntry;

    procedure WriteDirEntry(const Dir :IPath; Time:TDateTime = 0;  Comment :string = '');

    procedure WriteStream(const EntryName  :TPath;
                                Stream     :TStream;
                                Attributes :TFileAttributes;
                                Time       :TDateTime;
                                Comment    :string = ''); overload;

    procedure WriteFile(const FileName :TPath;  Comment :string = '';
                              preservePath :boolean = true ); 

  public
    property ZipFileName      :TPath    read FZipFileName write FZipFileName;
    property EntryName        :TPath    read FEntryName   write FEntryName;
    property EntryOpen        :boolean  read FEntryOpen   write FEntryOpen;
    property Comment          :string   read FComment     write FComment;

    property Compress         :boolean  read FCompress    write FCompress default true;
    property CompressionLevel :TCompressionLevel read FCompression write FCompression;
  end;



  TUnzipStream = class(TStream)
  private
  protected
    FZipFileName :TPath;
    FEntryOpen   :boolean;

    FUnzipFile   :ZipUtils.UnzFile;

    FEntries     :TStrings;
    FAtLastEntry :boolean;

    procedure Error(Msg :string);
    procedure NotImplementedError(Msg :string);

    function CheckFileTime(const Path :IPath; Time :TDateTime = 0) :TDateTime;

    function EntryInfo : unz_file_info;                           overload;
    function EntryInfo(const EntryName :TPath) : unz_file_info;   overload;
  public
    constructor Create(const ZipFileName :TPath);
    destructor  Destroy; override;

    function Read(var Buffer; Count: Longint): Longint;    override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;

    procedure LocateEntry(const EntryName    :TPath);
    procedure OpenEntry(  const EntryName    :TPath);
    procedure CloseEntry;


    function EntryAttributes :TFileAttributes;                         overload;
    function EntryAttributes(const EntryName :TPath) :TFileAttributes; overload;
    function EntrySize :Cardinal;                                      overload;
    function EntrySize(const EntryName :TPath):Cardinal;               overload;
    function EntryName :string;

    procedure GotoFirstEntry;
    procedure GotoNextEntry;
    function  HasMoreEntries : boolean;

    procedure ReadStream(const EntryName  :TPath; Stream     :TStream);

    procedure ExtractFile(const FileName :TPath; const ToDir :TPath = '');
    procedure ExtractAll(const ToDir :TPath = '');

  public
    property ZipFileName      :TPath    read FZipFileName write FZipFileName;
    property EntryOpen        :boolean  read FEntryOpen   write FEntryOpen;

    property Entries :TStrings read FEntries;
  end;

procedure ExtractAll(const ZipFileName :TPath; const ToDir :TPath= '');

implementation
uses
  ZLIB;

const
  CompressionMap : array[TCompressionLevel] of Integer = (
   Z_DEFAULT_COMPRESSION,
   Z_NO_COMPRESSION,
   Z_BEST_SPEED,
   Z_BEST_COMPRESSION
   );

procedure ExtractAll(const ZipFileName :TPath; const ToDir :TPath= '');
var
  UnzipStream :TUnzipStream;
begin
  UnzipStream := TUnzipStream.Create(ZipFileName);
  try
    UnzipStream.ExtractAll(ToDir);
  finally
    FreeAndNil(UnzipStream);
  end;
end;

{ TZipStream }

constructor TZipStream.Create(const ZipFileName: TPath);
begin
  inherited Create;
  FPaths := TStringList.Create;
  FPaths.Sorted := True;
  FPaths.Duplicates := dupIgnore;

  FCompress := True;

  FZipFileName := ZipFileName;

  FZipFile  := ZIP.ZipOpen(PChar(NewPath(ZipFileName).asLocalPath), 0 {DO NOT APPEND});
  if FZipFile = nil then
     Error(Format('Could not open zip file "%s"', [ZipFileName]));
end;

destructor TZipStream.Destroy;
var
  Err :Integer;
begin
  FreeAndNil(FPaths);
  if EntryOpen then
     CloseEntry;
  Err := ZIP_OK;
  if FZipFile <> nil then
    Err := ZipClose(FZipFile, PChar(Comment));
  inherited Destroy;
  if Err <> ZIP_OK then
    Error('Could not close zip file');
end;

procedure TZipStream.Error(Msg: string);
begin
  raise EZipFileError.Create(Msg);
end;

procedure TZipStream.NotImplementedError(Msg: string);
begin
  Error(Format('"%s" not implemented in %s', [Msg, ClassName]));
end;


function TZipStream.CheckFileTime(const Path :IPath; Time :TDateTime = 0) :TDateTime;
begin
  if Time <= 0 then
    Result := Path.Time
  else
    Result := Time;

  if Result <= 0 then
    Result := Now;
end;


function TZipStream.Read(var Buffer; Count: Integer): Longint;
begin
  Result := -1;
  NotImplementedError('Read');
end;

function TZipStream.Seek(Offset: Integer; Origin: Word): Longint;
begin
  Result := -1;
  NotImplementedError('Seek');
end;

function TZipStream.Write(const Buffer; Count: Integer): Longint;
var
  Err         :Integer;
begin
  Result := -1;
  if not EntryOpen then
    Error('Need to open a zip entry first')
  else
  begin
    Err := zipWriteInFileInZip (FZipFile, @Buffer, Count);
    if Err < 0 then
      Error('Could not write to zip file entry');
    Result := Count;
  end;
end;



procedure TZipStream.NewEntry(  const EntryName :TPath;
                                Attributes      :TFileAttributes;
                                Time            :TDateTime;
                                Compress        :boolean;
                                Comment         :string);
var
  Err            :Integer;
  ZipFileInfo    :zip_fileinfo;
  CompressMethod :Integer;
begin
  FEntryName := EntryName;

  FillChar(ZipFileInfo, SizeOf(ZipFileInfo), 0);

  ZipFileInfo.external_fa := FileAttributesToSystemAttributes(Attributes);
  ZipFileInfo.dosDate     := TimeToSystemFileTime(Time);

  if Compress then
    CompressMethod := Z_DEFLATED
  else
    CompressMethod := 0 {Z_STORED};

  Err := zipOpenNewFileInZip( FZipFile,
                              PChar(FEntryName),
                              @ZipFileInfo,
                              NIL,             { const extrafield_local : voidp; }
                              0,               { size_extrafield_local : uInt; }
                              NIL,             { const extrafield_global : voidp; }
                              0,               { size_extrafield_global : uInt; }
                              PChar(Comment),  { const comment : PChar;}
                              CompressMethod,
                              CompressionMap[CompressionLevel]);
  if Err <> ZIP_OK then
    Error(Format('Error creating zip file entry "%s"', [EntryName]));

  FEntryOpen := True;
end;

procedure TZipStream.CloseEntry;
var
  Err :Integer;
begin
  FEntryOpen := False;
  Err := ZipCloseFileInZip (FZipFile);
  if Err <> ZIP_OK then
    Error('Could not close zip file entry');
end;




procedure TZipStream.WriteStream( const EntryName  :TPath;
                                        Stream     :TStream;
                                        Attributes :TFileAttributes;
                                        Time       :TDateTime;
                                        Comment    :string );
begin
  NewEntry(EntryName, Attributes, Time, FCompress, Comment);
  try
    Self.CopyFrom(Stream, Stream.Size);
  finally
    CloseEntry;
  end;
end;

procedure TZipStream.WriteFile(const FileName: TPath;  Comment :string; preservePath: boolean);
var
  Stream  :TFileStream;
  Path    :IPath;
  Dir     :IPath;
begin
  Path := NewPath(FileName);
  if Path.IsDirectory then
    WriteDirEntry(Path, CheckFileTime(Path), Comment)
  else
  begin
    Dir := Path.Super;
    if Dir.IsDirectory and preservePath then
       WriteDirEntry(Dir);
    Stream := TFileStream.Create(Path.asLocalPath, fmOpenRead or fmShareDenyWrite);
    try
      if preservePath then
        WriteStream( FileName, Stream,
                               Path.Attributes,
                               CheckFileTime(Path),
                               Comment)
      else
        WriteStream( Path.Resource , Stream,
                               Path.Attributes,
                               CheckFileTime(Path),
                               Comment)
    finally
      FreeAndNil(Stream);
    end;
  end;
end;

procedure TZipStream.WriteDirEntry(const Dir: IPath; Time:TDateTime; Comment :string);
begin
  if (Dir.Length > 0) and (FPaths.IndexOf(Dir.asString) < 0) then
  begin
    NewEntry( Dir.AsString + '/',
              [Directory] + Dir.Attributes - [NoFile],
              CheckFileTime(Dir, Time),
              False, { do not compress }
              Comment);
    try
      FPaths.Add(Dir.AsString);
    finally
      CloseEntry;
    end;
  end;
end;




{ TUnzipStream }

constructor TUnzipStream.Create(const ZipFileName: TPath);
begin
  inherited Create;
  FZipFileName := ZipFileName;

  FUnzipFile  := UNZIP.UnzOpen(PChar(NewPath(ZipFileName).asLocalPath));
  if FUnzipFile = nil then
     Error(Format('Could not open zip file "%s"', [ZipFileName]));

  FEntries := TStringList.Create;
  with TStringList(FEntries)do
  begin
    Sorted := True;
    Duplicates := dupIgnore;
  end;

  GotoFirstEntry;
  while HasMoreEntries do
  begin
    FEntries.Add(EntryName);
    GotoNextEntry;
  end;
end;

destructor TUnzipStream.Destroy;
var
  Err :Integer;
begin
  FreeAndNil(FEntries);
  if EntryOpen then
     CloseEntry;
  Err := UNZ_OK;
  if FUnzipFile <> nil then
    Err := UnzClose(FUnzipFile);
  inherited Destroy;
  if Err <> UNZ_OK then
    Error('Could not close zip file');
end;

procedure TUnzipStream.Error(Msg: string);
begin
  raise EZipFileError.Create(Msg);
end;

procedure TUnzipStream.NotImplementedError(Msg: string);
begin
  Error(Format('"%s" not implemented in %s', [Msg, ClassName]));
end;


function TUnzipStream.CheckFileTime(const Path :IPath; Time :TDateTime = 0) :TDateTime;
begin
  if Time <= 0 then
    Result := Path.Time
  else
    Result := Time;

  if Result <= 0 then
    Result := Now;
end;


function TUnzipStream.Read(var Buffer; Count: Integer): Longint;
begin
  Result := -1;
  if not EntryOpen then
    Error('Need to open a zip entry first')
  else
  begin
    Result := unzReadCurrentFile(FUnzipFile, @Buffer, Count);
    if Result < 0 then
      Error('Could not read from zip file entry');
  end;
end;

function TUnzipStream.Seek(Offset: Integer; Origin: Word): Longint;
begin
  Result := -1;
  NotImplementedError('Seek');
end;

function TUnzipStream.Write(const Buffer; Count: Integer): Longint;
begin
  Result := -1;
  NotImplementedError('Seek');
end;



procedure TUnzipStream.LocateEntry(const EntryName: TPath);
var
  Err            :Integer;
  Name           :IPath;
begin
  Name := NewPath(EntryName);

  Err := UNZIP.UnzLocateFile(FUnzipFile, PChar(Name.asString), 0);
  if Err <> ZIP_OK then
    Error(Format('Could not find zip file entry "%s"', [EntryName]));
end;

procedure TUnzipStream.OpenEntry(const EntryName  :TPath);
var
  Err            :Integer;
begin
  LocateEntry(EntryName);

  Err := UNZIP.UnzOpenCurrentFile(FUnzipFile);
  if Err <> ZIP_OK then
    Error(Format('Could not open zip file entry "%s"', [EntryName]));

  FEntryOpen := True;
end;

procedure TUnzipStream.CloseEntry;
var
  Err :Integer;
begin
  FEntryOpen := False;
  Err := UNZIP.UnzCloseCurrentFile(FUnzipFile);
  if Err <> ZIP_OK then
    Error('Could not close zip file entry');
end;




procedure TUnzipStream.ReadStream( const EntryName  :TPath; Stream     :TStream);
begin
  OpenEntry(EntryName);
  try
    Stream.CopyFrom(Self, EntrySize);
  finally
    CloseEntry;
  end;
end;


procedure TUnzipStream.ExtractFile(const FileName: TPath; const ToDir :TPath);
var
  Stream   :TFileStream;
  Dest     :IPath;
begin
  Dest := NewPath(ToDir).Concat(FileName);
  if Directory in EntryAttributes(FileName) then
    Dest.MakeDir
  else
  begin
    Dest.Super.MakeDir;
    Stream := TFileStream.Create(Dest.asLocalPath, fmCreate or fmShareDenyWrite);
    try
      ReadStream(FileName, Stream);
    finally
      FreeAndNil(Stream);
    end;
  end;
end;


procedure TUnzipStream.ExtractAll(const ToDir: TPath);
var
  e :Integer;
begin
  for e := 0 to Entries.Count-1 do
    ExtractFile(Entries[e], ToDir);
end;

function TUnzipStream.EntryInfo(const EntryName :TPath): unz_file_info;
begin
  LocateEntry(EntryName);
  Result := EntryInfo;
end;


function TUnzipStream.EntryInfo: unz_file_info;
var
  Err :Integer;
begin
  Err := unzGetCurrentFileInfo(FUnzipFile, @Result, nil, 0, nil, 0, nil, 0);
  if Err <> UNZ_OK then
    Error('Could not read entry information');
end;

function TUnzipStream.EntryAttributes( const EntryName: TPath): TFileAttributes;
begin
  LocateEntry(EntryName);
  Result := EntryAttributes;
end;

function TUnzipStream.EntryAttributes: TFileAttributes;
begin
  Result := TFileAttributes(Byte(EntryInfo.external_fa));
end;

function TUnzipStream.EntrySize(const EntryName: TPath): Cardinal;
begin
  LocateEntry(EntryName);
  Result := EntrySize;
end;

function TUnzipStream.EntrySize: Cardinal;
begin
  Result := EntryInfo.uncompressed_size;
end;

procedure TUnzipStream.GotoFirstEntry;
var
  Err :Integer;
begin
  Err := UNZIP.unzGoToFirstFile(FUnzipFile);
  if Err <> UNZ_OK then
    Error('Could not move to first file');
  FAtLastEntry := False;
end;

procedure TUnzipStream.GotoNextEntry;
var
  Err :Integer;
begin
  Err := UNZIP.unzGoToNextFile(FUnzipFile);
  if Err = UNZ_END_OF_LIST_OF_FILE then
    FAtLastEntry := True
  else if Err <> UNZ_OK then
    Error('Could not move to first file');
end;

function TUnzipStream.HasMoreEntries: boolean;
begin
  Result := not FAtLastEntry;
end;

function TUnzipStream.EntryName: string;
var
  Err :Integer;
begin
  SetLength(Result, EntryInfo.size_filename);
  Err := unzGetCurrentFileInfo(FUnzipFile, nil, @Result[1], Length(Result), nil, 0, nil, 0);
  if Err <> UNZ_OK then
    Error('Could not read entry information');
  Result := Trim(Result);
end;



end.
