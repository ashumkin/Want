(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id: ExecTasksTest.pas 772 2004-05-19 14:30:12Z juanco $ }

unit ExecTasksTest;

interface

uses
  SysUtils,
  TestFramework,
  WantClasses,
  ScriptParser,
  WantClassesTest,
  ExecTasks;

type
  THackedCustomExecTask = class(TCustomExecTask);
  THackedShellTask = class(TShellTask);

  TTestCustomExecTask = class(TTestCase)
  private
    FCustomExecTask: THackedCustomExecTask;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestBuildCmdLine;
  end;

  TTestShellTask = class(TTestCase)
  private
    FShellTask: THackedShellTask;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestBuildCmdLine;
  end;

  TTestExecTask = class(TProjectBaseCase)
  published
    procedure TestArgs;
  end;

  TTestExecCopyTask = class(TTestDirCase)
  private
    FExecTask: TExecTask;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestExecTask;
  end;

implementation

uses JclSysInfo;

{ TTestCustomExecTask }

procedure TTestCustomExecTask.Setup;
begin
  inherited;
  FCustomExecTask := THackedCustomExecTask.Create(nil);
end;

procedure TTestCustomExecTask.TearDown;
begin
  FCustomExecTask.Free;
  inherited;
end;

procedure TTestCustomExecTask.TestBuildCmdLine;
begin
  FCustomExecTask.Executable := 'cmd.exe';
  FCustomExecTask.ArgumentList.AddOption('/c ','copy');
  FCustomExecTask.ArgumentList.AddValue('file1.txt');
  FCustomExecTask.ArgumentList.AddValue('c:\dir w space\filecpy.txt');
  CheckEquals(
    'cmd.exe /c copy file1.txt "c:\dir w space\filecpy.txt"',
    FCustomExecTask.BuildCmdLine, 'BuildCmdLine failed');
end;

{ TTestShellTask }

procedure TTestShellTask.Setup;
begin
  inherited;
  FShellTask := THackedShellTask.Create(nil);
end;

procedure TTestShellTask.TearDown;
begin
  FShellTask.Free;
  inherited;
end;

procedure TTestShellTask.TestBuildCmdLine;
const
  SHELL_VAR = 'COMSPEC';
var
  ComSpec :string;
begin
  if GetEnvironmentVar(SHELL_VAR, Comspec, false) then
  begin
    FShellTask.Executable := 'dir';
    CheckEquals(Comspec + ' /c dir', FShellTask.BuildCmdLine);
  end;
end;

{ TTestExecTask }

procedure TTestExecTask.TestArgs;
const
  build_xml =
      '<project name="test" default="dotest" >'
  +#10'  <target name="dotest">'
  +#10'    <exec executable="any.exe"'
  +#10'          arguments="first,second"'
  +#10'          failonerror="no"'
  +#10'    >'
  +#10'      <arg value="third" />'
  +#10'    </exec>'
  +#10'  </target>'
  +#10'</project>';
var
  ExecTask :THackedCustomExecTask;
begin
  TScriptParser.ParseText(FProject, build_xml);

  ExecTask := THackedCustomExecTask(FProject.Targets[0].Tasks[0] as TExecTask);
  ExecTask.Configure;
  CheckEquals('first second third', ExecTask.BuildArguments);
  CheckEquals(false, ExecTask.failonerror);
end;

{ TTestExecTask }

procedure TTestExecCopyTask.Setup;
begin
  inherited;
  FExecTask := TShellTask.Create(FProject.AddTarget('test_exec_task'));
end;

procedure TTestExecCopyTask.TearDown;
begin
  FExecTask.Free;
  inherited;
end;

procedure TTestExecCopyTask.TestExecTask;
var
  CurrentFileName: string;
  NewFileName: string;
begin
  CurrentFileName := MakeSampleTextFile;
  NewFileName := ExtractFilePath(CurrentFileName) + 'new.txt';
  FExecTask.Executable := 'copy';
  FExecTask.ArgumentList.AddValue(CurrentFileName);
  FExecTask.ArgumentList.AddValue(NewFileName);
  FExecTask.Execute;
  Check(FileExists(NewFileName), 'TExecTask copy file failed');
end;


initialization
  RegisterTests('Exec Tasks', [
           TTestCustomExecTask.Suite,
           TTestShellTask.Suite,
           TTestExecTask.Suite,
           TTestExecCopyTask.Suite
           ]);
end.

