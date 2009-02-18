(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id: WantClassesTest.pas 789 2004-12-11 02:16:33Z juanco $ }

unit WantClassesTest;

interface

uses
  SysUtils,
  Classes,

  JclFileUtils,
  JclShell,

  WildPaths,
  WantClasses,
  ScriptParser,
  StandardElements,

  Properties,
  ExecTasks,
  DelphiTasks,
  ConsoleListener,
  ScriptRunner,
  ConsoleScriptRunner,

  TestFramework;




type
  TProjectBaseCase = class(TTestCase)
  protected
    FLogger : TConsoleListener;
    FProject: TProject;

    procedure SetUp;    override;
    procedure TearDown; override;

    procedure RunProject(target :string ='');
  published
  end;

  TTestDirCase = class(TProjectBaseCase)
  protected
    FLongFNTestDir: string;
    FTestDir: string;
    FWantTestDir: string;
    FFileNameInc: Integer;

    function MakeSampleTextFile: string;

  public
    procedure Setup; override;
    procedure TearDown; override;
  end;

  TSaveProjectTests = class(TProjectBaseCase)
    procedure BuildTestProject;
  published
    procedure TestInMemoryConstruction;
    procedure TestParseXML;
  end;

  TBuildTests = class(TProjectBaseCase)
  private
  protected
    procedure BuildProject;
    procedure SetUp; override;
  published
    procedure TestSchedule;
    procedure TestBuild;
  end;

  TPropertyTests = class(TProjectBaseCase)
  published
    procedure TestLocalProperties;
    procedure TestValidPath;
    procedure TestInvalidPath;
  end;

  TTestWantElement = class(TProjectBaseCase)
  private
    FWantElement: TScriptElement;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestWantElementPaths;
  end;


  // tasks used in tests

  TDummyTask1 = class(TTask)
  public
    class function TagName :string; override;
    procedure Execute; override;
  end;

  TDummyTask2 = class(TDummyTask1)
    class function TagName :string; override;
  end;

  TDummyTask3 = class(TDummyTask1)
  protected
    FAProp: string;
  published
    class function TagName :string; override;
    property AProp: string read FAProp write FAProp;
  end;

  TCompareValuesTask = class(TTask)
  protected
    FExpected :string;
    FActual   :string;
  public
    class function TagName :string; override;
    procedure Init;    override;
    procedure Execute; override;
  published
    property expected :string read FExpected write FExpected;
    property actual   :string read FActual   write FActual;
  end;

  TWithPathTask = class(TTask)
  protected
    FPath :TPath;
  published
    property path :TPath read FPath write FPath;
  end;

implementation


{ TProjectBaseCase }

procedure TProjectBaseCase.RunProject(target: string);
var
  Runner :TScriptRunner;
begin
  {$IFDEF USE_TEXT_RUNNER}
  Runner := TScriptRunner.Create;
  {$ELSE}
  Runner := TConsoleScriptRunner.Create;
  {$ENDIF}
  try
    Runner.BuildProject(FProject, target);
  finally
    Runner.Free;
  end;
end;


procedure TProjectBaseCase.SetUp;
begin
  FProject := TProject.Create;
  {$IFNDEF USE_TEXT_RUNNER}
    FLogger  := TConsoleListener.Create;
    FLogger.UseColor := True;
    FProject.Listener := FLogger;
  {$ENDIF}
end;

procedure TProjectBaseCase.TearDown;
begin
  FProject.Free;
  FLogger.Free;
end;

{ TTestDirCase }

function TTestDirCase.MakeSampleTextFile: string;
var
  F: TextFile;
begin
  Inc(FFileNameInc);
  Result := FTestDir + '\sample' + IntToStr(FFileNameInc) + '.txt';
  AssignFile(F, Result);
  Rewrite(F);
  WriteLn(F, 'this is a sample file');
  CloseFile(F);
end;

procedure TTestDirCase.Setup;
begin
  inherited;
  FFileNameInc := 0;

  FTestDir := ExtractFilePath(ParamStr(0)) + 'dunit_tmp';
  FLongFNTestDir := ExtractFilePath(ParamStr(0)) + 'my test dir';
  JclFileUtils.ForceDirectories(FTestDir);
  JclFileUtils.ForceDirectories(FLongFNTestDir);

  FWantTestDir := WildPaths.ToPath(FTestDir);
end;

procedure TTestDirCase.TearDown;
begin
  JclShell.SHDeleteFolder(0, FTestDir, [doSilent, doAllowUndo]);
  JclShell.SHDeleteFolder(0, FLongFNTestDir, [doSilent, doAllowUndo]);
  inherited;
end;

{ TSaveProjectTests }

const
  CR = #13#10;

  ExpectedXML =
    CR+
    '<project basedir="." default="compile" description="a test project" name="test">' + CR +
    '  <target name="prepare">'                                            + CR +
    '    <dummy1 />'                                                       + CR +
    '  </target>'                                                          + CR +
    '  <target depends="prepare" name="compile">'                          + CR +
    '    <dummy2 />'                                                       + CR +
    '    <dummy3 aprop="25" />'                                            + CR +
    '  </target>'                                                          + CR +
    '</project>'                                                           + CR;


procedure TSaveProjectTests.BuildTestProject;
var
  T: TTarget;
begin
  with FProject do
  begin
    BaseDir := '..';
    Name := 'my_project';
    T := AddTarget('prepare');
    TDummyTask1.Create(T);

    T := AddTarget('compile');
    TDummyTask2.Create(T);
    TDummyTask3.Create(T).AProp := 'aValue';
  end;
end;

procedure TSaveProjectTests.TestInMemoryConstruction;
begin
  BuildTestProject;
  CheckEquals(2, FProject.TargetCount);
  CheckEquals(1, FProject[0].TaskCount);
  CheckEquals(2, FProject[1].TaskCount);
  CheckEquals('TDummyTask3', FProject[1][1].ClassName);
end;

procedure TSaveProjectTests.TestParseXML;
begin
  TScriptParser.ParseText(FProject, ExpectedXML);
end;

{ TBuildTests }

procedure TBuildTests.BuildProject;
var
  T: TTarget;
  fname: string;
begin
  with FProject do
  begin
    Name := 'my_project';
    T := AddTarget('prepare');
    TDummyTask1.Create(T);

    T := AddTarget('compile');
    T.Depends := 'prepare';
    TDummyTask2.Create(T);
    TDummyTask3.Create(T);

    T := AddTarget('copy');
    T.Depends := 'compile';
    with TShellTask.Create(T) do
    begin
      SetAttribute('executable', 'copy');
      fname := ExtractFilePath(ParamStr(0)) + 'test\sample.txt';
      ArgumentList.AddValue(fname);
      fname := ExtractFilePath(fname) + 'new.txt';
      ArgumentList.AddValue(fname);
    end;
  end;
end;


procedure TBuildTests.SetUp;
begin
  inherited SetUp;
  BuildProject;
end;

procedure TBuildTests.TestSchedule;
var
  S: TTargetArray;
begin
  S := FProject.Schedule('copy');
  CheckEquals(3, Length(S));
  CheckEquals('prepare', S[0].Name);
  CheckEquals('compile', S[1].Name);
  CheckEquals('copy',    S[2].Name);
end;

procedure TBuildTests.TestBuild;
var
  OldFileName,
  NewFileName: string;
  F          :Text;
begin
 with FProject.TargetNames['copy'].Tasks[0] as TExecTask do
 begin
   OldFileName := ArgumentList.StringsUnquoted[0];
   NewFileName := ArgumentList.StringsUnquoted[1];
 end;

 try
   CreateDir(ExtractFileDir(OldFileName));
   Assign(F, OldFileName);
   Rewrite(F);
   Writeln(F, 'A test');
   Close(F);

   Check(not FileExists(NewFileName), 'file not copied');

   RunProject('copy');

   Check(FileExists(NewFileName), 'file not copied');
 finally
   SysUtils.DeleteFile(OldFileName);
   SysUtils.DeleteFile(NewFileName);
   RemoveDir(ExtractFileDir(OldFileName));
 end;
end;

{ TDummyTask1 }

procedure TDummyTask1.Execute;
begin
end;

class function TDummyTask1.TagName: string;
begin
  Result := 'dummy1';
end;
{ TDummyTask2 }

class function TDummyTask2.TagName: string;
begin
  Result := 'dummy2';
end;

{ TDummyTask3 }

class function TDummyTask3.TagName: string;
begin
  Result := 'dummy3';
end;

{ TCompareValuesTask }

class function TCompareValuesTask.TagName: string;
begin
  Result := 'check';
end;

procedure TCompareValuesTask.Init;
begin
  inherited Init;
  RequireAttribute('expected');
  RequireAttribute('actual');
end;

procedure TCompareValuesTask.Execute;
begin
  if expected <> actual then
    raise ETestFailure.Create(Format('Expected <%s> but was <%s>.', [expected, actual]) );
end;

{ TPropertyTests }

procedure TPropertyTests.TestLocalProperties;
const
  build_xml = ''
  +#10'<project name="test" default="dotest" >'
  +#10'  <property name="global"   value="0" />'
  +#10'  <property name="derived"  value="_${global}_" />'
  +#10'  <target name="target1">'
  +#10'    <property name="local"  value="1" />'
  +#10'    <property name="global" value="1" />'
  +#10'    <check expected="1" actual="${local}" />'
  +#10'    <check expected="0" actual="${global}" />'
  +#10'  </target>'
  +#10'  <target name="target2">'
  +#10'    <property name="local"  value="2" />'
  +#10'    <property name="global" value="2" />'
  +#10'    <check expected="2" actual="${local}" />'
  +#10'    <check expected="0" actual="${global}" />'
  +#10'  </target>'
  +#10'  <target name="dotest" depends="target1,target2" />'
  +#10'</project>'
  +'';
var
  P0, P1 :TPropertyElement;
begin
  TScriptParser.ParseText(FProject, build_xml);
  P0  := (FProject.Children[0] as TPropertyElement);
  P1 := (FProject.Children[1] as TPropertyElement);

  CheckEquals('0', P0.Attributes.Values['value']);
  CheckEquals('_${global}_', P1.Attributes.Values['value']);
  CheckEquals('', P0.Value);
  CheckEquals('', P1.Value);
  CheckEquals('${global}',  FProject.PropertyValue('global'));
  CheckEquals('${derived}', FProject.PropertyValue('derived'));
  FProject.Configure;
  CheckEquals('0',   P0.Value);
  CheckEquals('_0_', P1.Value);
  CheckEquals('0',   FProject.PropertyValue('global'));
  CheckEquals('_0_', FProject.PropertyValue('derived'));
  RunProject;
  CheckEquals('0',   P0.Value);
  CheckEquals('_0_', P1.Value);
  CheckEquals('0',   FProject.PropertyValue('global'));
  CheckEquals('_0_', FProject.PropertyValue('derived'));
end;

procedure TPropertyTests.TestValidPath;
const
  build_xml = ''
  +#10'<project name="test" default="dotest" >'
  +#10'  <target name="dotest">'
  +#10'    <withpath path="/c:/a/valid/path" />'
  +#10'  </target>'
  +#10'</project>'
  +'';
begin
  TScriptParser.ParseText(FProject, build_xml);
  RunProject;
end;

procedure TPropertyTests.TestInvalidPath;
const
  build_xml = ''
  +#10'<project name="test" default="dotest" >'
  +#10'  <target name="dotest">'
  +#10'    <withpath path="c:\awindows\path" />'
  +#10'  </target>'
  +#10'</project>'
  +'';
begin
  TScriptParser.ParseText(FProject, build_xml);
  RunProject;
  CheckEquals( '/c:/awindows/path',
               FProject.ToAbsolutePath((FProject.Targets[0].Tasks[0] as TWithPathTask).path)
               );
end;


{ TTestWantElement }

procedure TTestWantElement.Setup;
begin
  inherited;
  FWantElement := TScriptElement.Create(FProject.AddTarget('test'));
end;

procedure TTestWantElement.TearDown;
begin
  FWantElement.Free;
  inherited;
end;

procedure TTestWantElement.TestWantElementPaths;
var
  AbsPath: string;
begin
  AbsPath := LowerCase(ExtractFileDir(ParamStr(0)));
  CheckEquals(
    AbsPath,
    WildPaths.ToSystemPath(FWantElement.ToAbsolutePath(ToPath(AbsPath))),
    'ToAbsolutePath');
  CheckEquals(
    FWantElement.ToAbsolutePath(AbsPath),
    ToPath(AbsPath),
    'ToAbsolutePath');
end;

initialization
  RegisterTasks([ TDummyTask1,
                  TDummyTask2,
                  TDummyTask3,
                  TCompareValuesTask,
                  TWithPathTask]);

  RegisterTests('Want Classes', [
             TSaveProjectTests.Suite,
             TBuildTests.Suite,
             TPropertyTests.Suite,
             TTestWantElement.Suite
           ]);
end.

