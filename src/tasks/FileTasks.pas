(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 2001-2003 Juancarlo Anez, Caracas, Venezuela.              *
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

unit FileTasks;

interface

uses
  SysUtils,
  Classes,

  JALStrings,

  WantClasses,
  WildPaths,
  PatternSets;


type
  TFileTask = class(TTask)
  protected
    FDir :TPath;
    property dir:TPath read FDir write FDir;
  end;

  TFileSetTask = class(TFileTask)
  protected
    FFileSets: array of TFileSet;
    FDefaultExcludes: boolean;

    function  MyFileSet :TFileSet;

    procedure Init; override;

    procedure AddDefaultPatterns; virtual;

    procedure AddCommaSeparatedIncludes(Value: string);
    procedure AddCommaSeparatedExcludes(Value: string);

    procedure DoFileset(Fileset: TFileSet); virtual;

  public
    constructor Create(Owner: TScriptElement); override;

    procedure Execute; override;
  published
    function CreateFileSet: TFileSet;
    function CreateInclude: TIncludeElement;
    function CreateExclude: TExcludeElement;

    property DefaultExcludes: boolean
      read FDefaultExcludes write FDefaultExcludes default True;
  end;

  TMkDirTask = class(TFileTask)
  public
    procedure Init; override;
    procedure Execute;  override;
  published
    property dir;
  end;

  TTouchTask = class(TFileTask)
  protected
    FFile: string;
  public
    procedure Init; override;
    procedure Execute; override;
  published
    property _File:  string read FFile write FFile;
  end;

  TDeleteTask = class(TFileSetTask)
  protected
    FDeleteReadOnly: boolean;
    FFile: TPath;

    procedure AddDefaultPatterns; override;

    procedure SetFile(Value: TPath);

    procedure DoFileset(Fileset: TFileSet); override;
  published
    property basedir;
    property _File: TPath  read FFile write SetFile stored True;
    property dir;

    property DeleteReadOnly: boolean read FDeleteReadOnly write FDeleteReadOnly;
  end;

  TMoveCopyTask = class(TFileSetTask)
  protected
    FToDir:  string;
    FToFile: string;

    procedure DoFileset(Fileset: TFileSet); override;

    procedure DoPaths(Fileset: TFileSet; FromPaths, ToPaths: TPaths); virtual;
    procedure DoFiles(Fileset: TFileSet; FromPath, ToPath: TPath);    virtual; abstract;
  public
    procedure Init; override;
    procedure Execute; override;
  published
    property todir : string read FToDir  write FToDir;
    property tofile: string read FToFile write FToFile;
  end;

  TCopyTask = class(TMoveCopyTask)
  protected
    procedure DoPaths(Fileset: TFileSet; FromPaths, ToPaths: TPaths); override;
    procedure DoFiles(Fileset: TFileSet; FromPath, ToPath: TPath);    override;
  end;

  TMoveTask = class(TMoveCopyTask)
  protected
    procedure DoPaths(Fileset: TFileSet; FromPaths, ToPaths: TPaths); override;
    procedure DoFiles(Fileset: TFileSet; FromPath, ToPath: TPath);    override;
  end;

implementation

{ TFileSetTask }

constructor TFileSetTask.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  DefaultExcludes := True;
end;

procedure TFileSetTask.Init;
begin
  inherited;
end;

function TFileSetTask.CreateInclude: TIncludeElement;
begin
  Result := MyFileSet.CreateInclude;
end;

function TFileSetTask.CreateExclude: TExcludeElement;
begin
  Result := MyFileSet.CreateExclude;
end;

procedure TFileSetTask.AddDefaultPatterns;
var
  i: Integer;
begin
  if DefaultExcludes then
  begin
    for i := Low(FFileSets) to High(FFileSets) do
      if FFileSets[i] <> nil then
        FFileSets[i].AddDefaultPatterns;
  end;
end;

procedure TFileSetTask.AddCommaSeparatedIncludes(Value: string);
var
  Paths: TStringArray;
  p    : Integer;
begin
  Paths := StringToArray(Value);
  for p := Low(Paths) to High(Paths) do
    MyFileSet.Include(Paths[p]);
end;

procedure TFileSetTask.AddCommaSeparatedExcludes(Value: string);
var
  Paths: TStringArray;
  p    : Integer;
begin
  Paths := StringToArray(Value);
  for p := Low(Paths) to High(Paths) do
    MyFileSet.Exclude(Paths[p]);
end;



function TFileSetTask.CreateFileSet: TFileSet;
begin
  Result := TFileSet.Create(Self);

  SetLength(FFileSets, 1 + Length(FFileSets));
  FFileSets[High(FFileSets)] := Result;
end;

procedure TFileSetTask.DoFileset(Fileset: TFileSet);
begin

end;

procedure TFileSetTask.Execute;
var
  f: Integer;
begin
  inherited Execute;
  AddDefaultPatterns;
  for f := Low(FFileSets) to High(FFileSets) do
  begin
    if FFileSets[f] <> nil then
    begin
      if PathIsDir(FFileSets[f].BasePath) then
      begin
        ChangeDir(FFileSets[f].BasePath);
        Self.DoFileset(FFileSets[f]);
      end;
    end;
  end;
end;

function TFileSetTask.MyFileSet :TFileSet;
begin
  if Length(FFileSets) = 0 then
    CreateFileSet;
  Result := FFileSets[0];
end;

{ TMkDirTask }

procedure TMkDirTask.Init;
begin
  inherited Init;
  RequireAttribute('dir');
end;


procedure TMkDirTask.Execute;
begin
  Log(vlVerbose, Format('creating dir %s', [ToSystempath(ToAbsolutePath(dir))]) );
  if dir = '' then
    TaskError('<dir> attribute not set');
  if not PathIsDir(dir) then
  begin
    if PathExists(dir) then
      TaskFailure(Format('cannot create dir %s. A file is in the way.', [dir]));
    Log(ToRelativePath(dir));
    if not NoChanges then
    begin
      WildPaths.MakeDir(ToAbsolutePath(dir));
      if not PathIsDir(dir) then
        TaskFailure(Format('cannot create dir %s.', [dir]));
    end;
  end;
end;


{ TTouchTask }

procedure TTouchTask.Execute;
begin
  if _File = '' then
    TaskError('<file> attribute not set');
  Log(ToRelativePath(_File));
  WildPaths.TouchFile(_File);
end;


procedure TTouchTask.Init;
begin
  inherited Init;
  RequireAttribute('file');
end;

{ TDeleteTask }

procedure TDeleteTask.AddDefaultPatterns;
var
  i    :Integer;
  base :string;
begin
  if (dir <> '') and (Length(FFileSets) = 0) then
  begin
    // then they wanto to delete the whole directory
    MyFileSet.Include(dir);
    MyFileSet.Include(PathConcat(dir, '**'));
  end
  else
  begin
    inherited AddDefaultPatterns;
    if FDir <> '' then
    begin
      base := PathConcat(BasePath, FDir);
      for i := 0 to High(FFileSets) do
        FFileSets[i].basedir := base;
    end;
  end;
end;

procedure TDeleteTask.DoFileset(Fileset: TFileSet);
var
  Paths : TPaths;
  p     : Integer;
  path  : string;
  msg   : string;
begin
  inherited DoFileSet(Fileset);

  Log(vlDebug, 'fileset basepath=%s', [Fileset.BasePath]);
  Paths := Fileset.Paths;

  if Paths = nil then
    Log(vlVerbose, 'nothing to delete')
  else begin
    if _file <> '' then
      Log(ToRelativePath(_file))
    else if dir <> '' then
      Log(' %4d files from %s', [Length(Paths), ToRelativePath(dir)])
    else
      Log(' %4d files from %s', [Length(Paths), ToRelativePath(BasePath)]);

    for p := High(Paths) downto Low(Paths) do
    begin
      path := Paths[p];
      Log(vlVerbose, 'del ' + ToSystemPath(path));
      AboutToScratchPath(path);
      if not NoChanges then
      begin
        WildPaths.DeleteFile(path, FDeleteReadOnly);
        if PathExists(path) then
        begin
          msg := Format('Could not delete %s', [  ToSystemPath(path) ]);
          TaskFailure( msg );
        end;
      end;
    end;
  end;
end;

procedure TDeleteTask.SetFile(Value: TPath);
begin
  FFile := Value;
  MyFileSet.Include(Value);
end;

{ TMoveCopyTask }


procedure TMoveCopyTask.DoPaths(Fileset: TFileSet; FromPaths, ToPaths: TPaths);
var
  p      : Integer;
  ToPath :string;
begin
  Assert(Length(FromPaths) = Length(ToPaths));
  for p := Low(FromPaths) to High(FromPaths) do
  begin
    ToPath := ToPaths[p];
    if FToFile <> '' then
       ToPath := PathConcat(SuperPath(ToPath), TPath(ToFile));
    DoFiles(Fileset, FromPaths[p], ToPath);
  end;
end;

procedure TMoveCopyTask.DoFileset(Fileset: TFileSet);
var
  FromPaths,
  ToPaths  : TPaths;
begin
  inherited DoFileSet(Fileset);

  FromPaths := Fileset.Paths;
  ToPaths   := Fileset.MovePaths(todir);

  DoPaths(Fileset, FromPaths, ToPaths);
end;

procedure TMoveCopyTask.Init;
begin
  inherited Init;
  RequireAttribute('todir|tofile');
end;

procedure TMoveCopyTask.Execute;
begin
  Log('to %s', [ToRelativePath(todir)]);
  inherited Execute;
end;

{ TCopyTask }

procedure TCopyTask.DoFiles(Fileset: TFileSet; FromPath, ToPath: TPath);
begin
  Log(vlVerbose, ' %s -> %s', [ToSystemPath(FromPath), ToSystemPath(ToPath)]);
  AboutToScratchPath(ToPath);
  if not PathIsDir(FromPath) then
  begin
    MakeDir(SuperPath(ToPath));
    if not NoChanges then
    begin
      WildPaths.CopyFile(FromPath, ToPath);
      if not PathExists(ToPath) then
        TaskFailure(Format('could not copy %s to %s', [ToRelativepath(FromPath), ToRelativepath(ToPath)]));
      end;
  end;
end;

procedure TCopyTask.DoPaths(Fileset: TFileSet; FromPaths, ToPaths: TPaths);
begin
  if Length(FromPaths) > 0 then
    Log(' %4d files from %s', [Length(FromPaths), ToRelativePath(Fileset.dir)]);
  inherited DoPaths(Fileset, FromPaths, ToPaths);
end;

{ TMoveTask }

procedure TMoveTask.DoFiles(Fileset: TFileSet; FromPath, ToPath: TPath);
begin
  Log(vlVerbose, '%s -> %s', [ToSystemPath(FromPath), ToSystemPath(ToPath)]);
  AboutToScratchPath(ToPath);
  if not PathIsDir(FromPath) then
  begin
    MakeDir(SuperPath(ToPath));
    if not NoChanges then
    begin
      WildPaths.MoveFile(FromPath, ToPath);
      if not PathExists(ToPath) then
        TaskFailure(Format('Could not move %s to %s', [ToRelativepath(FromPath), ToRelativepath(ToPath)]));
    end;
  end;
end;

procedure TMoveTask.DoPaths(Fileset: TFileSet; FromPaths, ToPaths: TPaths);
var
  i: Integer;
begin
  Assert(Length(FromPaths) = Length(ToPaths));
  if Length(FromPaths) > 0 then
    Log('%4d files from %s', [Length(FromPaths), ToRelativePath(FileSet.dir)]);
  inherited DoPaths(Fileset, FromPaths, ToPaths);

  for i := High(FromPaths) downto 0 do
  begin
    if PathIsDir(FromPaths[i]) then
      WildPaths.DeleteFile(FromPaths[i]);
  end;
end;



initialization
  RegisterTasks([ TMkDirTask,
                  TTouchTask,
                  TDeleteTask,
                  TCopyTask,
                  TMoveTask]
  );
end.

