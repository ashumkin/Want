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
    @brief Apliying XSL transformations to xml files

    @author Juanco Añez
    @author Radim Novotny <radimnov@seznam.cz>
    @author Bob Arnson <sf@bobs.org>
}

unit TempFileTasks;

interface

uses
  SysUtils,
  Classes,
	{$IFDEF VER130}
	FileCtrl,
	{$ENDIF VER130}
  WantClasses,
  WildPaths;

type
  TTempFileTask = class(TTask)
  private
    FDestDir     :string;
    FPrefix      :string;
    FProperty    :string;
    FSuffix      :string;
    FFileName: string;
  public
    procedure Init;    override;
    procedure Execute; override;

    property FileName: string read FFileName;
  published
    property destdir   :string read FDestDir  write FDestDir;
    property prefix    :string read FPrefix   write FPrefix;
    property _property :string read FProperty write FProperty;
    property suffix    :string read FSuffix   write FSuffix;
  end;

implementation

{ TTempFileTask }

{$IFDEF VER130}
//
// utility functions that exist in Delphi 6 and later but not in Delphi 5
//

function IncludeTrailingPathDelimiter(const ADirName: string): string;
begin
	Result := IncludeTrailingBackslash(ADirName);
end;
{$ENDIF VER130}


procedure TTempFileTask.Execute;
var
  bDirName : string;
  bTempFileName : string;
begin
  inherited;
  if FDestDir <> '' then
  begin
    bDirName := IncludeTrailingPathDelimiter(FDestDir);
    if not DirectoryExists(bDirName) then
      TaskError('Destination directory does not exists: ' + FDestDir);
  end
  else
    bDirName := '';
  bDirName := ToAbsolutePath(bDirName);
  if FSuffix = '' then
    FSuffix := '.tmp';
  Randomize;
  repeat
    // temp file name is in Want path format
    bTempFileName := MovePath(FPrefix + Format('%.4x', [Random(65535)]), '', bDirName);
    bTempFileName := bTempFileName + FSuffix;
  until not FileExists(ToSystemPath(bTempFileName));
  if Assigned(Owner) then
  begin
    Project.SetProperty(FProperty, bTempFileName);
  end;
  FFileName := bTempFileName;
end;

procedure TTempFileTask.Init;
begin
  inherited;
  RequireAttribute('property');
end;

initialization
  RegisterTask(TTempFileTask);
end.
