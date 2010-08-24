(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Aсez, Caracas, Venezuela.          *
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
  WantClassesTest,
  uTestClasses;

type
  TSVNTestsSetup = class(TTestCaseSetup)
  protected
    FDir: string;
    FCommitCount: Integer;
    procedure RunCmd(const pCmd: string);
    procedure DelDir(const pDir: string);
    procedure CreateRepo;
    procedure CheckoutRepo;
    procedure AddTestCommits;
    procedure Commit(const pMessage: string);
    procedure AddTag(const pTag: string);
    function ToSystemPath(const pDir: string): string;
  public
    function GetName: string; override;

    procedure SetUp; override;
    procedure TearDown; override;
  end;

  TTestCustomSVNTaskClass = class(TCustomSVNTask)
  public
  end;

  TCustomSVNTaskTest = class(TProjectBaseCase)
  protected
    FPrevPath: string;
  public
    procedure SetUp;    override;
    procedure TearDown; override;
  end;

  TTestTSVNTaskPaths = class(TCustomSVNTaskTest)
  protected
    FCustomSVNTask: TTestCustomSVNTaskClass;
  public
    procedure SetUp;    override;
    procedure TearDown; override;
  published
    procedure TestGetRepoPath;
    procedure TestPathIsURL;
    procedure TestDecodeURL;
    procedure TestPathToURL; 
    procedure Testtags;
  end;

  TTestTSVNTask = class(TCustomSVNTaskTest)
  protected
    FSVNTask: TSVNTask;
  public
    procedure SetUp;    override;
    procedure TearDown; override;
  published
    procedure Testtags;
  end;

  TTestTSVNLastRevisionTask = class(TCustomSVNTaskTest)
  protected
    FSVNLastRevisionTask: TSVNLastRevisionTask;
  public
    procedure SetUp;    override;
    procedure TearDown; override;
  published
    procedure TestLastRevision;
  end;

  TTestTSVNInfoTask = class(TCustomSVNTaskTest)
  protected
    FSVNInfoTask: TSVNInfoTask;
  public
    procedure SetUp;    override;
    procedure TearDown; override;
  published
    procedure TestInfo;
  end;

  TTestTSVNLog = class(TCustomSVNTaskTest)
  protected
    FSVNLogTask: TSVNLogTask;
  public
    procedure SetUp;    override;
    procedure TearDown; override;
  published
    procedure Testtrunkonly;
    procedure Testrevision;
    procedure Testrevision_tags;
    procedure TestGetTrunkPointsTo;
    procedure TestLog;
  end;

implementation

uses
  Windows;

const
  cLastRevision = '10';
var
  FCheckoutDir: string;
  FRepoDir: string;

{ TCustomSVNTaskTests }

procedure TTestTSVNTaskPaths.SetUp;
begin
  inherited;
  FCustomSVNTask := TTestCustomSVNTaskClass.Create(FProject);
end;

procedure TTestTSVNTaskPaths.TearDown;
begin
  FreeAndNil(FCustomSVNTask);
  inherited;
end;

procedure TTestTSVNTaskPaths.TestDecodeURL;
begin
  CheckEquals('file://c:/Program files/Path',
    TCustomSVNTask.DecodeURL('file://c:/Program%20files/Path'));
end;

procedure TTestTSVNTaskPaths.TestGetRepoPath;
begin
  CheckEquals('http://localhost/project+name/tags',
    TCustomSVNTask.GetRepoPath('http://localhost/project+name/trunk',
      '../tags'));
end;

procedure TTestTSVNTaskPaths.TestPathIsURL;
begin
  CheckFalse(FCustomSVNTask.PathIsURL('c:/path/to/file'));
  CheckTrue(FCustomSVNTask.PathIsURL('svn://path/to/file'));
  CheckTrue(FCustomSVNTask.PathIsURL('http://path/to/file'));
end;

procedure TTestTSVNTaskPaths.TestPathToURL;
begin
  CheckTrue(AnsiSameText('file:///c:/Program%20files/path%2Bpath/',
    TCustomSVNTask.PathToURL('c:\Program%20files\path+path')),
    TCustomSVNTask.PathToURL('c:\Program%20files\path+path'));
end;

procedure TTestTSVNTaskPaths.Testtags;
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

procedure TTestTSVNTask.SetUp;
begin
  inherited;
  FSVNTask := TSVNTask.Create(FProject);
end;

procedure TTestTSVNTask.TearDown;
begin
  FreeAndNil(FSVNTask);
end;

procedure TTestTSVNTask.Testtags;
begin
  FSVNTask.repo := 'http://localhost/path/';
  FSVNTask.tags := '../tags';
  CheckEquals('http://localhost/tags', FSVNTask.tags);
end;

{ TSVNTestsSetup }

procedure TSVNTestsSetup.AddTag(const pTag: string);
begin
  // create tag
  RunCmd('svn copy trunk tags/v' + pTag);
  // commit
  Commit('tagged v' + pTag);
end;

procedure TSVNTestsSetup.AddTestCommits;
var
  pp: string;
begin
  pp := GetCurrentDir;
  ChDir(FCheckoutDir);
  try
    // first commit
    // add dirs "trunk" and "tags" and "branches"
    RunCmd('cmd.exe /c mkdir trunk tags branches');
    // add files
    RunCmd('cmd.exe /c echo generated file > file.txt');
    RunCmd('cmd.exe /c echo generated trunk file > trunk/file.txt');
    // add to svn
    RunCmd('svn add *');
    // commit then - revision 1
    Commit('');
    AddTag('_');

    // second commit
    // add file
    RunCmd('cmd.exe /c echo generated file 2 > file2.txt');
    RunCmd('svn add file2.txt');
    // create tag v11.1 - revision 2
    AddTag('11_1');

    // third commit
    RunCmd('cmd.exe /c echo added line to trunk/file >> trunk/file.txt');
    // commit - revision 3
    Commit('');

    // modify trunk
    RunCmd('cmd.exe /c echo added line to trunk/file.txt >>'
      + ' trunk/file.txt');
    //  - revision 4 points to revision 3
    AddTag('1_2');

    // revision 5 points to revision 4
    RunCmd('svn copy trunk branches/v1_3');
    Commit('branch trunk to v1_3');
    // modify branch
    RunCmd('cmd.exe /c echo added line to branch/v1_3/file >>'
      + ' branches/v1_3/file.txt');
    // revision 6
    Commit('modified branch v1_3');

    // create tag v11.31 - revision 7
    AddTag('11_31');

    // create tag v11.32 - revision 8 points to revision 7
    RunCmd('svn copy branches/v1_3 tags/v11_32');
    Commit('tagged branch v1_3 to v11_32');

    // modify trunk
    RunCmd('cmd.exe /c echo added one more line to trunk/file.txt >>'
      + ' trunk/file.txt');
    // commit - revision 10
    Commit('one more line changes');

    // remove "tags" folder to test relavitely trunk and repository only
    RunCmd('cmd.exe /c rmdir /q /s tags');
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

procedure TSVNTestsSetup.Commit(const pMessage: string);
begin
  Inc(FCommitCount);
  RunCmd(Format('svn commit -m "%d commit; %s"', [FCommitCount, pMessage]));
  // update WC to actualize latest revision
  RunCmd('svn up');
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
  FDir := ExtractFilePath(ParamStr(0)) + 'svn+tests';
  FRepoDir := ExpandFileName(FDir + '/repo');
  FCheckoutDir := ExpandFileName(FDir + '/checkout');
  FDir := ExpandFileName(FDir);
  DelDir(FDir);
  ForceDirectories(FDir);
  ForceDirectories(FRepoDir);
  ForceDirectories(FCheckoutDir);

  CreateRepo;
  CheckoutRepo;
  FCommitCount := 0;
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

procedure TTestTSVNLog.SetUp;
begin
  inherited;
  FSVNLogTask := TSVNLogTask.Create(FProject);
end;

procedure TTestTSVNLog.TearDown;
begin
  DeleteFile(PAnsiChar(FSVNLogTask.output));
  FreeAndNil(FSVNLogTask);
  inherited;
end;

procedure TTestTSVNLog.TestLog;
begin
  FSVNLogTask.trunk := '.';
  FSVNLogTask.xml := True;
  FSVNLogTask.output := 'log.log';
  FSVNLogTask.Execute;
end;

procedure TTestTSVNLog.Testrevision;
begin
  FSVNLogTask.trunk := '.';
  FSVNLogTask.Execute;
  CheckEquals(cLastRevision, FSVNLogTask.revision);
end;

procedure TTestTSVNLog.TestGetTrunkPointsTo;
begin
  FSVNLogTask.repo := FSVNLogTask.PathToURL(
      ExtractFilePath(ParamStr(0)) + 'svn+tests/repo/tags') + 'v1_2';
  CheckTrue(FSVNLogTask.GetTrunkPointsTo);
  CheckEquals('4', FSVNLogTask.TrunkPointsTo);

  FSVNLogTask.ClearArguments;
  FSVNLogTask.repo := FSVNLogTask.PathToURL(
      ExtractFilePath(ParamStr(0)) + 'svn+tests/repo/tags') + 'v11_1';
  CheckTrue(FSVNLogTask.GetTrunkPointsTo);
  CheckEquals('2', FSVNLogTask.TrunkPointsTo);
end;

procedure TTestTSVNLog.Testrevision_tags;
begin
  FSVNLogTask.trunk := '.';
  FSVNLogTask.tags := '../tags';
  FSVNLogTask.Execute;
  CheckEquals(cLastRevision + ':9', FSVNLogTask.revision);

  // + version filter
  FSVNLogTask.ClearArguments;
  FSVNLogTask.versionfilter := '^v_.*';
  FSVNLogTask.filter := 'commit';
  FSVNLogTask.Execute;
  CheckEquals(cLastRevision + ':2', FSVNLogTask.revision);

  // + version filter
  FSVNLogTask.ClearArguments;
  FSVNLogTask.versionfilter := 'v1_.*';
  FSVNLogTask.Execute;
  // берём лог со следующей после последней ревизии 
  CheckEquals(cLastRevision + ':5', FSVNLogTask.revision);

  // v1.x
  FSVNLogTask.ClearArguments;
  FSVNLogTask.branches := '../branches/v1_3';
  FSVNLogTask.tags := '../tags';
  FSVNLogTask.Execute;
  CheckEquals('7:5', FSVNLogTask.revision);

  // v11.x
  FSVNLogTask.ClearArguments;
  FSVNLogTask.versionfilter := 'v11_.*';
  FSVNLogTask.Execute;
  CheckEquals('7:9', FSVNLogTask.revision);
end;

procedure TTestTSVNLog.Testtrunkonly;
var
  s: string;
begin
  FSVNLogTask.trunk := '.';
  s := TCustomSVNTask.PathToURL(FRepoDir + '\trunk');
  CheckTrue(AnsiSameText(s, FSVNLogTask.trunk + URLDelimiter),
    s + ' = ' + FSVNLogTask.trunk + URLDelimiter);
end;

{ TSVNTaskTestsCommon }

procedure TCustomSVNTaskTest.SetUp;
begin
  inherited;
  if Assigned(FProject.Listener) then
    FProject.Listener.Level := vlDebug;
  FPrevPath := GetCurrentDir;
  ChDir(FCheckoutDir + '\trunk');
end;

procedure TCustomSVNTaskTest.TearDown;
begin
  ChDir(FPrevPath);
  inherited;
end;

{ TTestTSVNLastRevisionTask }

procedure TTestTSVNLastRevisionTask.SetUp;
begin
  inherited;
  FSVNLastRevisionTask := TSVNLastRevisionTask.Create(FProject);
end;

procedure TTestTSVNLastRevisionTask.TearDown;
begin
  FreeAndNil(FSVNLastRevisionTask);
  inherited;
end;

procedure TTestTSVNLastRevisionTask.TestLastRevision;
var
  FSVNLogTask: TSVNLogTask;
begin
  FSVNLogTask := TSVNLogTask.Create(FProject);
  try
    FSVNLogTask.trunk := '.';
    FSVNLastRevisionTask.repo := FSVNLogTask.trunk;
  finally
    FreeAndNil(FSVNLogTask);
  end;
  FSVNLastRevisionTask.tags := '../tags';
  FSVNLastRevisionTask.last := 0;
  FSVNLastRevisionTask.fullpath := True;
//  FSVNLastRevisionTask.versionfilter := '';
  FSVNLastRevisionTask.Execute;
  CheckTrue(AnsiSameText(FSVNLastRevisionTask.PathToURL(
      ExtractFilePath(ParamStr(0)) + 'svn+tests/repo/tags') + 'v11_32',
    FSVNLastRevisionTask.LastRevision),
    FSVNLastRevisionTask.PathToURL(
      ExtractFilePath(ParamStr(0)) + 'svn+tests/repo/tags') + 'v11_32');
end;

{ TTestTSVNInfoTask }

procedure TTestTSVNInfoTask.SetUp;
begin
  inherited;
  FSVNInfoTask := TSVNInfoTask.Create(FProject);
end;

procedure TTestTSVNInfoTask.TearDown;
begin
  FreeAndNil(FSVNInfoTask);
  inherited;
end;

procedure TTestTSVNInfoTask.TestInfo;
begin
  FSVNInfoTask.SetItem(FSVNInfoTask.PathToURL(
      ExtractFilePath(ParamStr(0)) + 'svn+tests/repo/tags') + 'v11_32');
  FSVNInfoTask.Execute_(False);
  CheckEquals('9', FSVNInfoTask.Items[0].CommitRevision);
end;

initialization
  RegisterTest(TSVNTestsSetup.Create([
    TTestTSVNTaskPaths.Suite,
    TTestTSVNTask.Suite,
    TTestTSVNLastRevisionTask.Suite,
    TTestTSVNInfoTask.Suite,
    TTestTSVNLog.Suite]));
end.
