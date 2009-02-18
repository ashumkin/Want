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
unit GZipTasks;

interface
uses
  SysUtils,
  Classes,

  JalUtils,
  JalPaths,
  JalGZipStreams,

  PatternSets,
  WantClasses,
  FileTasks;


type
  TGZipTask = class(TFileTask)
  protected
    FSrc       :TPath;
    FZipFile   :TPath;
    FCompress  :boolean;
  public
    constructor Create(Owner :TScriptElement); override;

    procedure Init; override;
    procedure Execute; override;
  published
    property basedir;

    property src      :TPath   read FSrc       write FSrc;
    property zipfile  :TPath   read FZipFile   write FZipFile;
  end;

  TGUnzipTask = class(TFileTask)
  protected
    FZipFile   :TPath;
    FToDir     :TPath;

  public
    procedure Init; override;
    procedure Execute; override;
  published
    property zipfile  :TPath read FZipFile write FZipFile;
    property src      :TPath read FZipFile write FZipFile;

    property todir    :TPath read FToDir     write FToDir;
    property dest     :TPath read FToDir     write FToDir;
  end;

implementation

{ TGZipTask }

constructor TGZipTask.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  FCompress := true;
end;

procedure TGZipTask.Init;
begin
  inherited Init;
  RequireAttribute('src');
  RequireAttribute('zipfile');
end;

procedure TGZipTask.Execute;
var
  target :IPath;
begin
  inherited Execute;
  target := NewPath(zipfile);
  Log('%s -> %s', [ToRelativePath(src), ToRelativePath(target.asString)]);
  AboutToScratchPath(zipfile);

  JalGZipStreams.gzip(NewPath(src).asLocalPath, target.asLocalPath);
end;


{ TGUnzipTask }

procedure TGUnzipTask.Init;
begin
  inherited Init;
  if FZipFile = '' then
    TaskError('zipfile (or src) attribute is required');
end;

procedure TGUnzipTask.Execute;
var
  source,
  target :IPath;
begin
  inherited Execute;
  source := NewPath(src);
  target := NewPath(todir).Concat(dest);
  Log('%s -> %s', [ToRelativePath(src), ToRelativePath(target.asString)]);
  if source.Time < target.Time then
    TaskFailure('target is newer than source')
  else
    gunzip(NewPath(src).asLocalPath, target.asLocalPath);
end;

initialization
  RegisterTasks([TGZipTask, TGUnzipTask]);
end.
