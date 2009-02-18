(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id: FileTasksTest.pas 643 2003-03-09 19:37:17Z juanco $ }

unit FileTasksTest;

interface

uses
  SysUtils,
  TestFramework,
  WildPaths,
  FileTasks,
  WantClassesTest;

type
  TTestDeleteTask = class(TTestDirCase)
  private
    FDeleteTask: TDeleteTask;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestDeleteDir;
    procedure TestDeleteDirRelative;
  end;

  TTestMkDirTask = class(TTestDirCase)
  private
    FMkDirTask: TMkDirTask;
  protected
    procedure DoTest;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestMkDirTaskAbsolute;
    procedure TestMkDirTaskRelative;
  end;

implementation

uses JclFileUtils;

{ TTestDeleteTask }

procedure TTestDeleteTask.Setup;
begin
  inherited;
  FDeleteTask := TDeleteTask.Create(FProject.AddTarget('test_delete_task'));
  FProject.basedir := SuperPath(FTestDir);
end;

procedure TTestDeleteTask.TearDown;
begin
  FDeleteTask.Free;
  inherited;
end;

procedure TTestDeleteTask.TestDeleteDir;
begin

  CheckEquals('delete', TDeleteTask.TagName, 'TagName is wrong');
  MakeSampleTextFile;
  Check(DirectoryExists(FTestDir), 'no directory to start with');
  FDeleteTask.Dir := FTestDir;

  FDeleteTask.Configure;

  FDeleteTask.DoExecute;

  // the following test was reversed in the previous version
  Check(not DirectoryExists(FTestDir), 'directory not deleted');

  // ensure it doesn't blow up trying to delete a directory that's gone
  FDeleteTask.DoExecute;
end;

procedure TTestDeleteTask.TestDeleteDirRelative;
var
  SiblingDir: string;
begin
  MakeSampleTextFile;

  // need routine (add to clLib) to grab FTestDir parent (ExtractFilePathParent)
  SiblingDir := FTestDir;

end;

{ TTestMkDirTask }

procedure TTestMkDirTask.DoTest;
begin
  FMkDirTask.Execute;
  try
    Check(DirectoryExists(FMkDirTask.ToSystemPath(FMkDirTask.dir)), 'directory not made');
    Check(WildPaths.PathIsDir(FMkDirTask.dir), 'directory not made');
  finally
    WildPaths.DeleteFile(FMkDirTask.dir);
  end;
end;

procedure TTestMkDirTask.Setup;
begin
  inherited;
  FMkDirTask := TMkDirTask.Create(FProject.AddTarget('test'));
end;

procedure TTestMkDirTask.TearDown;
begin
  FMkDirTask.Free;
  inherited;

end;

procedure TTestMkDirTask.TestMkDirTaskAbsolute;
begin
  FMkDirTask.dir := FMkDirTask.ToWantPath(FTestDir + '\new');
  DoTest;
end;

procedure TTestMkDirTask.TestMkDirTaskRelative;
begin
  FMkDirTask.dir := './test/new';
  DoTest;
end;

initialization
  RegisterTests('File Tasks', [TTestDeleteTask.Suite, TTestMkDirTask.Suite]);

end.

