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

unit ScriptRunner;

interface

uses
  SysUtils,
  Classes,

  JclFileUtils,

  JALStrings,

  WildPaths,

  WantUtils,
  WantClasses,
  BuildListeners,
  ScriptParser;


type
  TScriptRunner = class
  protected
    FListener    :TBuildListener;
    FListenerCreated :boolean;

    procedure DoCreateListener;  virtual;
    procedure CreateListener;    virtual;
    procedure SetListener(Value :TBuildListener);

    procedure BuildTarget(Target :TTarget);
    procedure ExecuteTask(Task :TTask);

  public
    constructor Create;
    destructor  Destroy; override;

    procedure LoadProject(Project :TProject; BuildFile: TPath; SearchUp :boolean = false);

    procedure BuildProject(Project :TProject; Target: string = '');   overload;
    procedure BuildProject(Project :TProject; Targets: TStringArray); overload;

    procedure Build(BuildFile: TPath; Targets :TStringArray; Level :TLogLevel = vlNormal); overload;
    procedure Build(BuildFile: TPath; Target  :string;       Level :TLogLevel = vlNormal); overload;
    procedure Build(BuildFile: TPath; Level   :TLogLevel = vlNormal); overload;

    procedure Log(Level: TLogLevel; Msg: string);

    class function DefaultBuildFileName: TPath;
    function FindBuildFile(BuildFile: TPath; SearchUp :boolean = False):TPath; overload;
    function FindBuildFile(SearchUp :boolean= False) :TPath; overload;

    property Listener :TBuildListener read FListener write SetListener;
    property ListenerCreated :boolean read FListenerCreated;
  end;

implementation



{ TScriptRunner }

constructor TScriptRunner.Create;
begin
  inherited Create;
  DoCreateListener;
end;

destructor TScriptRunner.Destroy;
begin
  if ListenerCreated then
  begin
    FListener.BuildFinished;
    FreeAndNil(FListener);
  end;
  inherited Destroy;
end;

procedure TScriptRunner.LoadProject(Project :TProject; BuildFile: TPath; SearchUp :boolean);
begin
  if not IsLocalPath(BuildFile) then
    BuildFile := ToPath(BuildFile);
  BuildFile := FindBuildFile(BuildFile, SearchUp);

  try
    TScriptParser.Parse(Project, BuildFile);
    Listener.BuildFileLoaded(Project, WildPaths.ToRelativePath(BuildFile, CurrentDir));
  except
    on e :Exception do
    begin
      Listener.BuildFailed(Project, e.Message);
      raise;
    end;
  end;
end;

procedure TScriptRunner.Build( BuildFile: TPath;
                               Targets:    TStringArray;
                               Level:      TLogLevel = vlNormal);
var
  Project :TProject;
begin
  Listener.Level := Level;
  Project := TProject.Create;
  try
    Project.Listener := Listener;
    try
      LoadProject(Project, BuildFile);
      BuildProject(Project, Targets);
    except
      on e :EWantException do
      begin
        Log(vlDebug, e.Message);
        raise;
      end;
      on e :Exception do
      begin
        Log(vlDebug, e.Message);
        Listener.BuildFailed(Project, e.Message);
        raise;
      end;
    end;
  finally
    Project.Free;
  end;
end;


procedure TScriptRunner.DoCreateListener;
begin
  if Listener = nil then
  begin
    CreateListener;
    FListenerCreated := True;
  end;
end;

procedure TScriptRunner.CreateListener;
begin
  FListener := TBasicListener.Create;
end;

procedure TScriptRunner.Build(BuildFile: TPath; Level: TLogLevel);
begin
  Build(BuildFile, nil, Level);
end;

procedure TScriptRunner.Build(BuildFile: TPath; Target: string; Level: TLogLevel);
var
  T :TStringArray;
begin
  SetLength(T, 1);
  T[0] := Target;
  Build(BuildFile, T, Level);
end;


procedure TScriptRunner.BuildProject(Project: TProject; Target: string);
begin
  if Trim(Target) <> '' then
    BuildProject(Project, StringArray(Target))
  else
    BuildProject(Project, nil);
end;

procedure TScriptRunner.BuildProject(Project: TProject; Targets: TStringArray);
var
  i:       Integer;
  Sched:   TTargetArray;
  LastDir: TPath;
begin
  Sched := nil;
  Listener.ProjectStarted(Project);
  try
    try
      Sched := nil;
      Project.Listener := Listener;

      Project.Configure;
      
      Log(vlDebug, Format('rootdir="%s"',   [Project.RootPath]));
      Log(vlDebug, Format('basedir="%s"',   [Project.BaseDir]));
      Log(vlDebug, Format('basepath="%s"',  [Project.BasePath]));


      if Length(Targets) = 0 then
      begin
        if Project._Default <> '' then
          Targets := StringArray(Project._Default)
        else
          raise ENoDefaultTargetError.Create('No default target');
      end;
    except
      on e :Exception do
      begin
        Log(vlDebug, e.Message);
        if e is ETaskException then
          Listener.BuildFailed(Project)
        else
          Listener.BuildFailed(Project, e.Message);
        raise;
      end;
    end;

    try
      Sched := Project.Schedule(Targets);

      if Length(Sched) = 0 then
        Listener.Log(vlWarnings, 'Nothing to build')
      else
      begin
        LastDir := CurrentDir;
        try
          for i := Low(Sched) to High(Sched) do
          begin
              ChangeDir(Project.BasePath);
              BuildTarget(Sched[i]);
          end;
        finally
          ChangeDir(LastDir);
        end;
      end;
    except
      on e :Exception do
      begin
        Log(vlDebug, e.Message);
        if e is ETaskException then
          Listener.BuildFailed(Project)
        else
          Listener.BuildFailed(Project, e.Message);
        raise;
      end;
    end;
  finally
    Listener.ProjectFinished(Project);
    Project.Listener := nil;
  end;
end;

procedure TScriptRunner.BuildTarget(Target: TTarget);
var
  i :Integer;
  p :Integer;
  LastDir :TPath;
  PathList :TPaths;
begin
  if not Target.Enabled then
    EXIT;

  Listener.TargetStarted(Target);

  Log(vlDebug, Format('basedir="%s"',   [Target.BaseDir]));
  Log(vlDebug, Format('basepath="%s"',  [Target.BasePath]));

  LastDir := CurrentDir;
  try
    Target.Configure(false);
    ChangeDir(Target.BasePath);

    if Target.ForEachList then
      PathList := SplitListToPaths(Target.ForEach)
    else
      PathList := WildPaths.Wild(Target.ForEach);
    if Length(PathList) = 0 then
    begin
      SetLength(PathList, 1);
      PathList[0] := '';
    end;

    for p := Low(PathList) to High(PathList) do
    begin
      Target.SetProperty(Target._Property, PathList[p], true);
      Log(vlDebug, Format('foreach.property_value="%s"', [Target.PropertyValue(Target._Property)]));
      for i := 0 to Target.TaskCount-1 do
        ExecuteTask(Target.Tasks[i]);
      Target.SetProperty(Target._Property, '');
    end;

    Listener.TargetFinished(Target);
  finally
    ChangeDir(LastDir)
  end;
end;


procedure TScriptRunner.ExecuteTask(Task: TTask);
begin
  if not Task.Enabled then
  begin
    Log(vlVerbose, Format('skipping disabled task <%s>', [Task.TagName]));
    EXIT;
  end;
  Listener.TaskStarted(Task);

  Log(vlDebug, Format('basedir="%s"',   [Task.BaseDir]));
  Log(vlDebug, Format('basepath="%s"',  [Task.BasePath]));

  try
    Task.DoExecute;
    Listener.TaskFinished(Task);
  except
    on e: Exception do
    begin
      Log(vlDebug, 'caught: ' + e.Message);
      if e is EWantException then
      begin
        Listener.TaskFailed(Task, e.Message);
        raise
      end
      else
      begin
        Log(vlErrors, e.Message);
        Listener.TaskFailed(Task, e.Message);
        raise ETaskError.Create(e.Message);
      end;
    end;
  end;
end;


procedure TScriptRunner.Log(Level: TLogLevel; Msg: string);
begin
  Assert(Listener <> nil);
  Listener.Log(Level, Msg);
end;

procedure TScriptRunner.SetListener(Value: TBuildListener);
begin
  if FListener <> Value then
  begin
    if FListenerCreated then
    begin
      FListener.Free;
      FListener := nil;
    end;
    FListenerCreated := False;
    FListener := Value;
  end;
end;

class function TScriptRunner.DefaultBuildFileName: TPath;
var
  AppName :string;
begin
  AppName := ExtractFileName(GetModulePath(hInstance));
  Result  := ChangeFileExt(LowerCase(AppName),'.xml');
end;

function TScriptRunner.FindBuildFile(BuildFile: TPath; SearchUp: boolean): TPath;
var
  Dir: TPath;
begin
  if BuildFile = '' then
    Result := FindBuildFile(SearchUp)
  else
  begin
    Log(vlDebug, Format('Finding buildfile %s', [BuildFile]));
    Result := PathConcat(CurrentDir, BuildFile);
    Dir    := SuperPath(Result);

    Log(vlDebug, Format('Looking for "%s in "%s"', [BuildFile, Dir]));
    while not PathIsFile(Result)
    and SearchUp
    and (Dir <> '')
    and (Dir <> SuperPath(Dir))
    do
    begin
      if PathIsDir(Dir) then
      begin
        Result := PathConcat(Dir, BuildFile);
        Dir    := SuperPath(Dir);
        Log(vlDebug, Format('Looking for "%s in "%s"', [BuildFile, Dir]));
      end
      else
        break;
    end;

    if not PathIsFile(Result) then
      Result := BuildFile;
  end;
end;



function TScriptRunner.FindBuildFile(SearchUp: boolean): TPath;
begin
  Result := FindBuildFile(DefaultBuildFileName, SearchUp);
  if not PathIsFile(Result) then
     Result := FindBuildFile(AntBuildFileName, SearchUp);
  if not PathIsFile(Result) then
     Result := DefaultBuildFileName;
end;

end.


