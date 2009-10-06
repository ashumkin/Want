(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id$ }

unit SVNTasksTest;

interface

uses
  SysUtils,
  StrUtils,
  JclFileUtils,
  
  uURI,

  WildPaths,
  WantClasses,
  SVNTasks,
  ExecTasks,

  TestFramework,
  TestExtensions,
  WantClassesTest;

type
  TSVNTestsSetup = class(TTestSetup)
  private
    FDir: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;

    procedure RunCmd(const pCmd: string);
    procedure DelDir(const pDir: string);
    procedure CreateRepo;
    procedure CheckoutRepo;
    procedure AddTestCommits;
    function ToSystemPath(const pDir: string): string;
  public
    function  GetName: string; override;
  end;

  TTestCustomSVNTaskClass = class(TCustomSVNTask)
  public
    function PathIsURL(const pPath: string): boolean;
  end;

  TSVNTaskTestsCommon = class(TProjectBaseCase)
  private
    FPrevPath: string;
  protected
    procedure SetUp;    override;
    procedure TearDown; override;
  end;

  TCustomSVNTaskTests = class(TSVNTaskTestsCommon)
    FCustomSVNTask: TTestCustomSVNTaskClass;
  protected
    procedure SetUp;    override;
    procedure TearDown; override;
  published
    procedure TestPathIsURL;
    procedure TestDecodeURL;
    procedure TestPathToURL; 
    procedure Testtags;
  end;

  TSVNTaskTests = class(TSVNTaskTestsCommon)
    FSVNTask: TSVNTask;
  protected
    procedure SetUp;    override;
    procedure TearDown; override;
  published
    procedure Testtags;
  end;

  TSVNLogTests = class(TSVNTaskTestsCommon)
    FSVNLogTask: TSVNLogTask;
  protected
    procedure SetUp;    override;
    procedure TearDown; override;
  published
    procedure TestLog;
    procedure Testtrunk;
  end;

implementation

var
  FCheckoutDir: string;
  FRepoDir: string;

{ TCustomSVNTaskTests }

procedure TCustomSVNTaskTests.SetUp;
begin
  inherited;
  FCustomSVNTask := TTestCustomSVNTaskClass.Create(FProject);
end;

procedure TCustomSVNTaskTests.TearDown;
begin
  FreeAndNil(FCustomSVNTask);
  inherited;
end;

procedure TCustomSVNTaskTests.TestDecodeURL;
begin
  CheckEquals('file://c:/Program files/Path',
    TCustomSVNTask.DecodeURL('file://c:/Program%20files/Path'));
end;

procedure TCustomSVNTaskTests.TestPathIsURL;
begin
  CheckFalse(FCustomSVNTask.PathIsURL('c:/path/to/file'));
  CheckTrue(FCustomSVNTask.PathIsURL('svn://path/to/file'));
  CheckTrue(FCustomSVNTask.PathIsURL('http://path/to/file'));
end;

procedure TCustomSVNTaskTests.TestPathToURL;
begin
  CheckTrue(AnsiSameText('file:///c:/Program%20files/path%2Bpath/',
    TCustomSVNTask.PathToURL('c:\Program%20files\path+path')),
    TCustomSVNTask.PathToURL('c:\Program%20files\path+path'));
end;

procedure TCustomSVNTaskTests.Testtags;
begin
  FCustomSVNTask.repo := 'http://localhost/path/';
  FCustomSVNTask.tags := './tags';
  CheckEquals('http://localhost/path/tags', FCustomSVNTask.tags);

  FCustomSVNTask.repo := 'http://localhost/path';
  FCustomSVNTask.tags := './tags';
  CheckEquals('http://localhost/path/tags', FCustomSVNTask.tags);

  FCustomSVNTask.tags := 'tags';
  CheckEquals('tags', FCustomSVNTask.tags);
end;

{ TSVNTaskTests }

procedure TSVNTaskTests.SetUp;
begin
  inherited;
  FSVNTask := TSVNTask.Create(FProject);
end;

procedure TSVNTaskTests.TearDown;
begin
  FreeAndNil(FSVNTask);
end;

procedure TSVNTaskTests.Testtags;
begin
  FSVNTask.repo := 'http://localhost/path/';
  FSVNTask.tags := '../tags';
  CheckEquals('http://localhost/tags', FSVNTask.tags);
end;

{ TTestCustomSVNTaskClass }

function TTestCustomSVNTaskClass.PathIsURL(const pPath: string): boolean;
begin
  Result := inherited PathIsURL(pPath);
end;

{ TSVNTestsSetup }

procedure TSVNTestsSetup.AddTestCommits;
var
  pp: string;
begin
  pp := GetCurrentDir;
  ChDir(FCheckoutDir);
  try
    RunCmd('cmd.exe /c echo generated file > file.txt');
    RunCmd('svn add file.txt');
    RunCmd('svn commit -m "first commit"');

    RunCmd('cmd.exe /c echo generated file 2 > file2.txt');
    RunCmd('svn add file2.txt');
    RunCmd('svn commit -m "second commit"');
    RunCmd('svn up');
  finally
    ChDir(pp);
  end;
end;

procedure TSVNTestsSetup.CheckoutRepo;
var
  s: string;
begin
  s := TCustomSVNTask.PathToURL(FRepoDir);
  RunCmd('svn checkout ' + s + ' ' + ToSystemPath(FCheckoutDir));
end;

procedure TSVNTestsSetup.CreateRepo;
begin
  RunCmd('svnadmin create ' + ToSystemPath(FRepoDir));
end;

procedure TSVNTestsSetup.DelDir(const pDir: string);
begin
  RunCmd('cmd.exe /c rmdir /q /s ' + ToSystemPath(pDir));
end;

function TSVNTestsSetup.GetName: string;
begin
  Result := 'SVN Tasks';
end;

procedure TSVNTestsSetup.RunCmd(const pCmd: string);
var
  et: TExecTask;
  pr: TProject;
begin
  pr := TProject.Create;
  try
    et := TExecTask.Create(pr);
    try
      et.quiet := True;
      et.Executable := '';
      et.Arguments := pCmd;
      et.failonerror := False;
      et.Execute;
    finally
      FreeAndNil(et);
    end;
  finally
    FreeAndNil(pr);
  end;
end;

procedure TSVNTestsSetup.SetUp;
begin
  inherited;
  FDir := './svn+tests';
  FRepoDir := ExpandFileName(FDir + '/repo');
  FCheckoutDir := ExpandFileName(FDir + '/checkout');
  FDir := ExpandFileName(FDir);
  DelDir(FDir);
  ForceDirectories(FDir);
  ForceDirectories(FRepoDir);
  ForceDirectories(FCheckoutDir);

  CreateRepo;
  CheckoutRepo;
  AddTestCommits;
end;

procedure TSVNTestsSetup.TearDown;
begin
  DelDir(FDir);
  inherited;
end;

function TSVNTestsSetup.ToSystemPath(const pDir: string): string;
begin
  Result := WildPaths.ToSystemPath(pDir);
  if Pos(' ', Result) > 0 then
    Result := '"' + Trim(Result) + '"';
end;

{ TSVNLogTests }

procedure TSVNLogTests.SetUp;
begin
  inherited;
  FSVNLogTask := TSVNLogTask.Create(FProject);
end;

procedure TSVNLogTests.TearDown;
begin
  FreeAndNil(FSVNLogTask);
  inherited;
end;

procedure TSVNLogTests.TestLog;
begin
  FSVNLogTask.trunk := '.';
  FSVNLogTask.xml := True;
  FSVNLogTask.output := 'log.log';
  FSVNLogTask.Execute;
end;

procedure TSVNLogTests.Testtrunk;
var
  s: string;
begin
  FSVNLogTask.trunk := '.';
  s := TCustomSVNTask.PathToURL(FRepoDir);
  CheckTrue(AnsiSameText(s, FSVNLogTask.trunk + URLDelimiter),
    s + ' = ' + FSVNLogTask.trunk + URLDelimiter);
end;

{ TSVNTaskTestsCommon }

procedure TSVNTaskTestsCommon.SetUp;
begin
  inherited;
  if Assigned(FProject.Listener) then
    FProject.Listener.Level := vlDebug;
  FPrevPath := GetCurrentDir;
  ChDir(FCheckoutDir);
end;

procedure TSVNTaskTestsCommon.TearDown;
begin
  ChDir(FPrevPath);
  inherited;
end;

initialization
  RegisterTests([TSVNTestsSetup.Create(TCustomSVNTaskTests.Suite)]);
  RegisterTests([TSVNTestsSetup.Create(TSVNTaskTests.Suite)]);
  RegisterTests([TSVNTestsSetup.Create(TSVNLogTests.Suite)]);
end.
