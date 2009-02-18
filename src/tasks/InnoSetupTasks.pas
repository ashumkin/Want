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
    @brief Enables want to compile InnoSetup Scripts using ISCC.exe

    @author Michael Elsdörfer

    TODO : Would be great if the path of the InnoSetup Compiler could be loaded
           from registry or from somewhere else. Until I'm not aware of such a
           possibility.    
}

unit InnoSetupTasks;

interface

uses
  {Delphi}
  Windows,
  SysUtils,
  Classes,
  TypInfo,

  {Jcl}
  JclBase,
  JclSysUtils,
  JclMiscel,
  JclSysInfo,
  JclRegistry,
  JclStrings,

  {Local}
  JalStrings,

  XPerlRe,

  WantUtils,
  WantClasses,
  ExecTasks,
  WildPaths,
  PatternSets,
  Attributes;

type
  TInnoSetupCompileTask = class(TCustomExecTask)
  private
    FSource: TPath;
    FISCCPath: TPath;
  protected
    procedure HandleOutputLine(Line :string); override;
    function FindISCC: string;
      
    function BuildArguments: string; override;
  public
    constructor Create(Owner: TScriptElement); override;
    class function TagName: string; override;

    function BuildExecutable: string; override;

    procedure Init; override;
    procedure Execute; override;
  published
    property basedir;       
    property source: TPath read FSource write FSource;
    property isccpath: TPath read FISCCPath write FISCCPath;

    property Arguments;
    property ArgumentList stored false;
    property SkipLines;
  end;

const
  ISCC_FILENAME = 'ISCC.exe';

implementation

{ TInnoSetupCompileTask }

(* How can the path be found automatically? I'm currently not aware of a solution. *)
function TInnoSetupCompileTask.FindISCC: string;
const ISCCPathProperty = 'iscc.path';
begin
  // If there is a iscc attribute, use it's value, otherwise look for iscc.path property.
  if (ISCCPath = '') then Result := PropertyValue(ISCCPathProperty)
  else Result := ISCCPath;

  // Check if we found something. If not, stop.
  if (Result = '') or (Result = '${' + ISCCPathProperty + '}') then
    TaskError('Could not find Inno Setup Compiler (ISCC)')
  else Begin
    // User can just give us the path, we will add the filename
    if (ExtractFileName(Result) = '') then Result := Result + ISCC_FILENAME
    else if (ExtractFileExt(Result) = '') then
      Result := Result + '\' + ISCC_FILENAME;  // Very probably there is just a \ missing  
  end;
end;

// Adapted from TDelphiCompileTask
procedure TInnoSetupCompileTask.HandleOutputLine(Line: string);
begin
 if (Pos(':', Line) <> 0) and XPerlre.regex.Match('^(.*)(\([0-9]+\)) *([HWEF][a-z]+:.*)$', Line) then
 begin
   with regex do
     Line := ToRelativePath(ToPath(SubExp[1].Text)) + ' ' + SubExp[2].Text + #10 + SubExp[3].Text;
   if (Pos('Fatal:', Line) <> 0) or  (Pos('Error:', Line) <> 0) then TaskFailure(Line)
   else Log(vlWarnings, Line);
 end
 else if (Pos('Fatal:', Line) <> 0) or  (Pos('Error:', Line) <> 0) then TaskFailure(Line)
 else if (Pos('File not found:', Line) <> 0) then TaskFailure(Line)
 else if (Pos('Warning', Line) <> 0) then Log(vlWarnings, Line)
 else inherited HandleOutputLine(Line);
end;

function TInnoSetupCompileTask.BuildExecutable: string;
begin
  Executable := ToWantPath(FindISCC);
  Result := inherited BuildExecutable;
end;

constructor TInnoSetupCompileTask.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  SkipLines  := 6;
end;

procedure TInnoSetupCompileTask.Init;
begin
  inherited Init;
  RequireAttribute('source');
end;

procedure TInnoSetupCompileTask.Execute;
begin                                     
  Log(ToRelativePath(source));
  try
    Executable := ToWantPath(FindISCC);
    inherited Execute;
  finally end;
end;

class function TInnoSetupCompileTask.TagName: string;
begin
  Result := 'iscc';
end;

function TInnoSetupCompileTask.BuildArguments: string;
begin
  // Note: ISCC does only support one script file, so wild cards are not allowed
  Log(vlVerbose, 'source %s', [ToRelativePath(source)]);
  if PathExists(source) then Begin
    Result := Result + ' ' + ToSystemPath(source);
    Result := Result + ' ' + inherited BuildArguments;
  end else
    TaskFailure(Format('Could not find %s to compile', [ToSystemPath(PathConcat(BasePath, source))]));
end;

initialization
  RegisterTasks( [TInnoSetupCompileTask]);
end.