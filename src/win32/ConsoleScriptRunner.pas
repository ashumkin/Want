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

unit ConsoleScriptRunner;

interface
uses
  SysUtils,
  Classes,

  JclStrings,
  JalStrings,

  CRT32,

  WildPaths,
  WantUtils,
  WantClasses,
  WantResources,
  ConsoleListener,
  ScriptRunner;

const
  rcs_id :string = '#(@)$Id: ConsoleScriptRunner.pas 706 2003-05-14 22:13:46Z hippoman $';

type
  TConsoleScriptRunner = class(TScriptRunner)
  protected
    FBuildFile   :string;
    FTargets     :TStringArray;
    FDoNotStopOnVersion   :boolean;

    procedure ParseCommandLine(Project :TProject); overload; virtual;
    function  ParseArgument(Project: TProject; var N :Integer;
      const Argument: string) :boolean;  virtual;
    function  ParseOption(Project: TProject; var N: Integer;
      Switch: string; CommandLine: TStringList): boolean; virtual;

    function  GetUseColor :boolean;
    procedure SetUseColor(Value :boolean);
  public
    procedure ParseCommandLine(Project :TProject;
      CommandLine: TStringList); overload; virtual;
    procedure CreateListener; override;
    property  UseColor :Boolean read GetUseColor write SetUseColor;

    procedure Execute;    virtual;
  end;

implementation

{ TConsoleScriptRunner }


procedure TConsoleScriptRunner.CreateListener;
begin
  FListener := TConsoleListener.Create;
end;

function TConsoleScriptRunner.GetUseColor: boolean;
begin
  Result := TConsoleListener(Listener).UseColor;
end;

procedure TConsoleScriptRunner.SetUseColor(Value: boolean);
begin
  TConsoleListener(Listener).UseColor := Value;
end;

procedure More(Text :string);
var
  S :TStrings;
  i :Integer;
begin
  S := TStringList.Create;
  try
    S.Text := Text;
    i := 0;
    while i < S.Count do
    begin
      if (Pos('---', S[i]) <> 1) then
      begin
        Writeln(S[i]);
        Inc(i);
      end
      else
      begin
        Write(Format('-- More (%d%%) --'#13, [100*(i+2) div S.Count]));
        Inc(i);
        repeat until ReadKey in [' ',#13,#10, 'q'];
        writeln(#13' ': 70);
      end;
    end;
  finally
    S.Free;
  end;
end;


procedure TConsoleScriptRunner.Execute;
var
  Project :TProject;
begin
  Project := TProject.Create;
  try
    Project.Listener := Listener;
    ParseCommandLine(Project);
    if FBuildFile = '' then
      FBuildFile := FindBuildFile(True);
    LoadProject(Project, FBuildFile);
    BuildProject(Project, FTargets);
  finally
    FreeAndNil(Project);
  end;
end;


procedure TConsoleScriptRunner.ParseCommandLine(Project: TProject);
var
  i: Integer;
  TSL: TStringList;
begin
  TSL := TStringList.Create;
  try
    for i := 1 to ParamCount do
      TSL.Add(ParamStr(i));
    ParseCommandLine(Project, TSL);
  finally
    FreeAndNil(TSL);
  end;
end;


function TConsoleScriptRunner.ParseArgument(Project: TProject; var N: Integer;
  const Argument: string): boolean;
begin
  SetLength(FTargets, 1+Length(FTargets));
  FTargets[High(FTargets)] := Argument;
  Result := True;
end;

function TConsoleScriptRunner.ParseOption(Project: TProject; var N: Integer;
  Switch: string; CommandLine: TStringList): boolean;
var
  PropName:  string;
  PropValue: string;
  EqPos:     Integer;
begin
  Result := True;
  if (Switch = 'h')
    or (Switch = 'H')
    or (Switch = '?')
    or (Switch = 'help') then
  begin
    WriteLn(Copyright );
    Usage;
    Halt(2);
  end
  else if AnsiSameText(Switch, 'dsv')
      or AnsiSameText(Switch, 'dont-stop-version')
      or AnsiSameText(Switch, '-dont-stop-version') then
    FDoNotStopOnVersion := True
  else if (Switch = 'v')
    or (Switch = 'version')
    or (Switch = '-version') then
  begin
    WriteLn(Copyright);
    if not FDoNotStopOnVersion then
      Halt(2);
  end
  else if (Switch = 'L') then
  begin
    More(License);
    Halt(3);
  end
  else if (Switch = 'buildfile')
    or (Switch = 'b') then
  begin
    Inc(N);
    FBuildFile := ToPath(CommandLine.Strings[N]);
  end
  else if Switch = 'verbose' then
    Listener.Level := vlVerbose
  else if Switch = 'ansi' then
    Listener.ANSI := True
  else if Switch = 'debug' then
  begin
    Listener.Level := vlDebug;
    Log(vlDebug, 'Parsing commandline');
  end
  else if (Switch = 'quiet') 
      or (Switch = 'q')
      or (Switch = 'warnings') then
    Listener.Level := vlQuiet
  else if (Switch = 'n') then
    Project.NoChanges := true
  else if Switch = 'nocolor'then
    UseColor := False
  else if Copy(Switch, 1, 1) = 'D' then
  begin
    Delete(Switch, 1, 1);

    EqPos := Pos('=', Switch);

    if EqPos = 0 then
       EqPos := 1 + Length(Switch);

    PropName  := Copy(Switch, 1, EqPos-1);
    PropValue := Copy(Switch, EqPos+1, Length(Switch));

    PropValue := StrTrimQuotes(PropValue);

    Project.SetProperty(PropName, PropValue);
  end
  else
    Result := False;
end;

procedure TConsoleScriptRunner.ParseCommandLine(Project: TProject;
  CommandLine: TStringList);
var
  p:         Integer;
  Param:     string;
begin
  try
    p := 0;
    while p < CommandLine.Count do
    begin
      Param := CommandLine.Strings[p];
      if Param[1] in ['-','/'] then
      begin
        if not ParseOption(Project, p, Copy(Param, 2, Length(Param)), CommandLine) then
          raise EWantError.Create('Unknown commandline option: ' + Param);
      end
      else if not ParseArgument(Project, p, Param) then
          raise EWantError.Create('Don''t know what to do with argument : ' + Param);
      Inc(p);
    end;
  except
    on e :Exception do
    begin
      Listener.Log(vlErrors, e.Message);
      raise;
    end;
  end;
end;

end.
