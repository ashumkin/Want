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

unit JALFiles;

interface
uses
  Windows,
  SysUtils;

type
   ECouldNotRenameToBackup = class(EInOutError);

function FileIsWriteable(const FName :string):boolean;
function RenameFileToBackup(const FileName :string):string;

procedure LogToFile(const FileName :string; const Msg :string);

implementation

{$IFDEF VER130}
//
// utility functions that exist in Delphi 6 and later but not in Delphi 5
//

function FileIsReadOnly(const AFileName: string): boolean;
begin
  Result := FileGetAttr(AFileName) and faReadOnly > 0;
end;
{$ENDIF VER130}

function FileIsWriteable(const FName :string):boolean;
begin
  if FileExists(FName) then
     result := not FileIsReadOnly(FName)
  else
     result := not FileIsReadOnly(ExtractFileDir(FName));
end;

function RenameFileToBackup(const FileName :string):string;
var
  Path,
  Name,
  Ext   :string;
  Tag   :string;
  n     :Integer;

begin
  Path := ExtractFilePath(FileName) + 'backups';
  Name := ChangeFileExt(ExtractFileName(FileName), '');
  Ext  := ExtractFileExt(FileName);

  CreateDir(Path);

  n := 1;
  repeat
    Tag := FormatDateTime('yyyy-mm-dd', Now);
    Result := Format('%s\%s-%s-%3.3d%s', [Path, Name, Tag, n, Ext]);
    Inc(n);
  until not FileExists(Result);

  if not MoveFile(PChar(FileName), PChar(Result)) then
  begin
    // try copy and delete (MoveFileEx doesn't work on Win98 and relatives)
    if CopyFile(PChar(FileName), PChar(Result), TRUE) then
    begin
      if not DeleteFile(PChar(FileName)) then
        raise ECouldNotRenameToBackup.CreateFmt('Delete old file %s', [FileName]);
    end
    else
      raise ECouldNotRenameToBackup.CreateFmt('Could move old version of %s to %s', [FileName, Result]);
  end;
end;

procedure LogToFile(const FileName :string; const Msg :string);
var
  T :Text;
begin
  Assign(T, FileName);
  if not FileExists(FileName) then
    Rewrite(T)
  else
    Append(T);
  try
    Writeln(T, Msg);
  finally
    Close(T);
  end;
end;


end.
