(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id: DelphiTasksTest.pas 789 2004-12-11 02:16:33Z juanco $ }

unit DelphiTasksTest;

interface

uses
  JclFileUtils,
  WildPaths,
  WantClasses,
  DelphiTasks,
  TestFramework,
  WantClassesTest;

type
  TDelphiCompileTests = class(TProjectBaseCase)
    FDelphiTask: TDelphiCompileTask;
  protected
    procedure BuildProject;
    procedure SetUp;    override;
    procedure TearDown; override;
  published
    procedure TestCompile;
  end;

implementation

{ TDelphiCompileTests }

procedure TDelphiCompileTests.BuildProject;
var
  T: TTarget;
begin
  with FProject do
  begin
    BaseDir := PathConcat(SuperPath(ToPath(GetModulePath(hInstance))), '..');
    Name := 'delphi_compile';

    T := AddTarget('compile');
    FDelphiTask := TDelphiCompileTask.Create(T);
    with FDelphiTask do
    begin
      if PathIsDir('src') then
        basedir := 'src'
      else if PathIsDir('../src') then
        basedir := '../src'
      else if PathIsDir('../../src') then
        basedir := '../src';
      SetAttribute('source', 'Want.dpr');
      source    := 'Want.dpr';
      exeoutput := ToPath(Evaluate('%{temp}/want.test'));
      dcuoutput := ToPath(Evaluate('%{temp}/want.test'));

      build   := true;
      quiet   := true;
      uselibrarypath := false;

      AddUnitPath('../lib/**');
      AddUnitPath('../src/**');
      AddResourcePath('../bin');
      AddIncludePath('../lib/**');
    end;
  end;
end;

procedure TDelphiCompileTests.SetUp;
begin
  inherited SetUp;
  BuildProject;
end;

procedure TDelphiCompileTests.TearDown;
begin
  FDelphiTask := nil;
end;

procedure TDelphiCompileTests.TestCompile;
var
  exe:  string;
begin
  MakeDir(FDelphiTask.exeoutput);
  exe := PathConcat(FDelphiTask.exeoutput, 'Want.exe');
  if PathIsFile(exe) then
    DeleteFile(exe);
  RunProject('compile');
  Check(PathIsFile(exe), 'Want exe not found');
end;

{ TTestIncVerRcTask }

initialization
  RegisterTests('Delphi Tasks', [TDelphiCompileTests.Suite]);
end.
