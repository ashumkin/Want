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

    @author Juanco Añez
}

unit WantTasks;

interface
uses
  SysUtils,
  Classes,

  JclSysUtils,

  WantClasses,
  ScriptRunner,
  ConsoleScriptRunner,
  WildPaths,
  PatternSets,
  Properties;

type
  TSubProjectPropertyElement = class(TPropertyElement)
  public
    class function TagName :string;              override;
    property path;
    property _file;
    property section;
  end;

  TSubProjectOutputPropertyElement = class(TScriptElement)
  private
    FProperty: string;
    Ffrom: string;
  public
    procedure Init; override;
    class function TagName :string;              override;
  published
    property _property: string read FProperty write FProperty;
    property from: string read Ffrom write Ffrom;
  end;

  TCustomWantTask = class(TTask)
  protected
    FTarget     :string;
  public
    property _target   :string read FTarget    write FTarget;
  end;

  TWantTask = class(TCustomWantTask)
  private
    Fbasedir: TPath;
  protected
    FANSI: boolean;
    FBuildFile  : TPath;
    FSubProject : TProject;
    FDir        : TPath;
  public
    constructor Create(Owner: TScriptElement = nil); override;
    destructor  Destroy; override;

    procedure Init; override;
    procedure Execute;  override;
  published
    function CreateProperty: TSubProjectPropertyElement;

    property _target;
    property ANSI: boolean read FANSI write FANSI;
    property buildfile :TPath read FBuildFile write FBuildFile;
    property dir       :TPath read FDir write FDir;
    property basedir   :TPath read Fbasedir write Fbasedir;
  end;


implementation

uses JALOwnedTrees;

{ TWantTask }

constructor TWantTask.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
end;

destructor TWantTask.Destroy;
begin
  FSubProject.Free;
  inherited Destroy;
end;


procedure TWantTask.Init;
begin
  inherited Init;
  FreeAndNil(FSubProject);
  FSubProject := TProject.Create(nil);
  FSubProject.Listener := Project.Listener;

  FSubProject.RootPath := ToAbsolutePath(PathConcat(Project.RootPath, Dir));
  if basedir <> '' then
    FSubProject.basedir := basedir;
  Log(vlDebug, 'dir=%s(%s)', [dir, ToAbsolutePath(dir)]);
  Log(vlDebug, 'BasePath=%s(%s)', [BasePath, ToAbsolutePath(BasePath)]);
  Log(vlDebug, 'FSubProject.RootPath=%s(%s)',
    [FSubProject.RootPath, ToAbsolutePath(FSubProject.RootPath)]);
end;

procedure TWantTask.Execute;
var
  FRunner :TScriptRunner;
  i: Integer;
  sp: TSubProjectOutputPropertyElement;
begin
  ChangeDir(BasePath);
  Log(vlDebug, 'dir=%s(%s)', [dir, ToAbsolutePath(dir)]);
  Log(vlDebug, 'basePath=%s(%s)', [BasePath, ToAbsolutePath(BasePath)]);
  try
    FRunner := TScriptRunner.Create;
    try
      FRunner.Listener  := Self.Project.Listener;
//      FSubProject.Parent := nil;
      ChangeDir(FSubProject.basepath);
      Log(vlDebug, 'FSubProject.basepath=%s(%s)',
        [FSubProject.basepath, ToAbsolutePath(FSubProject.basepath)]);
      for i := 0 to ChildCount - 1 do
        if Children[i] is TSubProjectPropertyElement
            and Children[i].Enabled then
        begin
          Log(vlVerbose, 'Set subproject property "%s" = "%s" ',
            [TSubProjectPropertyElement(Children[i]).name,
            TSubProjectPropertyElement(Children[i]).value]);
          FSubProject.SetProperty(
            TSubProjectPropertyElement(Children[i]).name,
            TSubProjectPropertyElement(Children[i]).value,
            False);
        end;
      FRunner.LoadProject(FSubProject, buildfile, false);
      FRunner.BuildProject(FSubProject, _target);
      for i := 0 to ChildCount - 1 do
        if Children[i] is TSubProjectOutputPropertyElement then
        begin
          sp := TSubProjectOutputPropertyElement(Children[i]);
          if sp.Enabled then
          begin
            Log(vlVerbose, 'Get subproject property "%s" = "%s" to "%s"',
              [sp.from,
               FSubProject.PropertyValue(sp.from),
               sp._property
              ]);
            SetProperty(sp._property, FSubProject.PropertyValue(sp.from), True);
          end;
        end;
    finally
//      FSubProject.Parent := Self;
      FRunner.Free;
    end;
  except
    on e :Exception do
      TaskError(e.Message, ExceptAddr);
  end;
end;

function TWantTask.CreateProperty: TSubProjectPropertyElement;
begin
  Result := TSubProjectPropertyElement.Create(Self);
end;

{ TSubProjectPropertyElement }

class function TSubProjectPropertyElement.TagName: string;
begin
  Result := 'property';
end;

{ TSubProjectOutputPropertyElement }

procedure TSubProjectOutputPropertyElement.Init;
begin
  inherited;
  RequireAttributes(['property', 'from']);
end;

class function TSubProjectOutputPropertyElement.TagName: string;
begin
  Result := 'output';
end;

initialization
  RegisterTasks([TWantTask]);
  RegisterElements(TWantTask,
    [TSubProjectPropertyElement, TSubProjectOutputPropertyElement]);
end.
