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

unit JalSetup;

interface
uses
  Windows,
  SysUtils,

  JclRegistry,

  JalStrings;

const
  SYSTEM_ENV = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment';

procedure AddSystemSearchPath(const path :string; const pattern :string = '');
procedure AddUserSearchPath(const path :string; const pattern :string = '');

implementation

function ChangePath(PathSet, NewPath, Pattern :string) :string;
var
  Paths :TStringArray;
  i     :Integer;
begin
  Paths := StringToArray(PathSet, ';');

  if Pattern <> '' then
  begin
    Pattern := UpperCase(Pattern);
    for i := 0 to High(Paths) do
      if (Trim(Paths[i]) = '') or (Pos(Pattern, UpperCase(Paths[i])) <> 0) then
        Paths[i] := '';
    Paths := Pack(Paths);
  end;

  if NewPath <> '' then
  begin
    if (Pos(' ', NewPath) <> 0) and (NewPath[1] <> '"') then
       NewPath := '"' + NewPath + '"';

    StringArrayAppend(Paths, NewPath);
  end;

  Result := ArrayToString(Paths, ';');
end;

procedure ChangeAutoExecPath(NewPath, Pattern :string);
const
  autoexec_bat = 'C:\AUTOEXEC.BAT';
var
  autoexec :TStringArray;
  i        :Integer;
begin
  autoexec := nil;
  if FileExists(autoexec_bat) then
  begin
    autoexec := FileToStringArray(autoexec_bat);
    StringArrayToFile('C:\AUTOEXEC.TUS', autoexec);

    if Pattern <> '' then
    begin
      Pattern := UpperCase(Pattern);
      for i := 0 to High(autoexec) do
      begin
        if (Pos('PATH', autoexec[i]) = 1)
        and (Pos(Pattern, UpperCase(autoexec[i])) <> 0 )
        then
            autoexec[i] := '';
      end;
      autoexec := Pack(autoexec);
    end;

    if NewPath <> '' then
      StringArrayAppend(autoexec, Format('PATH %%PATH%%;%s', [NewPath]));

    StringArrayToFile(autoexec_bat, autoexec);
  end;
end;

procedure ChangeEnvironmentPath(const root :HKEY; key, path :string; pattern :string);
var
  CurrentValue :string;
  NewValue     :string;
begin
  CurrentValue := RegReadString(root, key, 'Path');
  NewValue := ChangePath(CurrentValue, path, pattern);
  if NewValue <> CurrentValue then
  begin
    RegWriteString(root, key, 'Path', NewValue);
  end;
end;

procedure AddSystemSearchPath(const path :string; const pattern :string = '');
begin
  ChangeEnvironmentPath(HKEY_LOCAL_MACHINE, SYSTEM_ENV, path, pattern);
  ChangeAutoexecPath(path, pattern);
end;

procedure AddUserSearchPath(const path :string; const pattern :string = '');
begin
  ChangeEnvironmentPath(HKEY_CURRENT_USER, 'Environment', path, pattern);
end;

end.
