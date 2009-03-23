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

program want;

{$R 'usage.res' 'usage.rc'}
{%File 'usage.txt'}

uses
  ShareMem,
  SysUtils,
  SysConst,
  WIN32 in 'win32\WIN32.pas',
  CRT32 in 'win32\CRT32.pas',
  Win32Implementations in 'win32\Win32Implementations.pas',
  Resources in 'win32\Resources.pas',
  EditTasks in 'tasks\EditTasks.pas',
  WantStandardTasks in 'tasks\WantStandardTasks.pas',
  Attributes in 'elements\Attributes.pas',
  DUnitTasks in 'tasks\DUnitTasks.pas',
  WildPaths in 'lib\WildPaths.pas',
  ZipTasks in 'tasks\ZipTasks.pas',
  DelphiTasks in 'tasks\DelphiTasks.pas',
  EchoTasks in 'tasks\EchoTasks.pas',
  ExecTasks in 'tasks\ExecTasks.pas',
  FileTasks in 'tasks\FileTasks.pas',
  LoggerTask in 'tasks\LoggerTask.pas',
  StandardTasks in 'tasks\StandardTasks.pas',
  CustomTasks in 'tasks\CustomTasks.pas',
  TimeElements in 'elements\TimeElements.pas',
  PatternSets in 'elements\PatternSets.pas',
  Properties in 'elements\Properties.pas',
  RegexpElements in 'elements\RegexpElements.pas',
  StandardElements in 'elements\StandardElements.pas',
  ScriptParser in 'lib\ScriptParser.pas',
  ScriptRunner in 'ScriptRunner.pas',
  WantClasses in 'WantClasses.pas',
  WantTasks in 'tasks\WantTasks.pas',
  WantResources in 'WantResources.pas',
  ConsoleScriptRunner in 'win32\ConsoleScriptRunner.pas',
  BuildListeners in 'BuildListeners.pas',
  WantUtils in 'WantUtils.pas',
  IniFileTasks in 'tasks\IniFileTasks.pas',
  StyleTasks in 'tasks\StyleTasks.pas',
  MSXMLEngineImpl in 'win32\MSXMLEngineImpl.pas',
  CVSTasks in 'tasks\CVSTasks.pas',
  GZipTasks in 'tasks\GZipTasks.pas',
  HashTasks in 'tasks\HashTasks.pas',
  EncodeDecodeTasks in 'tasks\EncodeDecodeTasks.pas',
  SVNTasks in 'tasks\SVNTasks.pas',
  ConsoleListener in 'win32\ConsoleListener.pas',
  FileListener in 'win32\FileListener.pas';

{$APPTYPE CONSOLE}

{$r wantver.res}
{$r license.res }

const
  SwitchChars = ['-', '/'];

procedure Run;
var
  Runner  :TConsoleScriptRunner;
begin
  try
    Runner := TConsoleScriptRunner.Create;
    try
      Runner.Execute;
    finally
      FreeAndNil(Runner);
    end;
  except
    on e :EWantException do
      Halt(1);
    on e :Exception do
    begin
      Writeln(e.Message);
      Halt(2);
    end;
  end;
end;

begin
  Run;
end.

