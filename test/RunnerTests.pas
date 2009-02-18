(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id: RunnerTests.pas 632 2003-03-09 18:18:14Z juanco $ }

unit RunnerTests;

interface

uses
  SysUtils,
  TestFramework,
  WildPaths,
  WantClasses,
  ScriptRunner,
  ConsoleScriptRunner,
  WantClassesTest,
  StandardElements,
  StandardTasks,
  ExecTasks;

type
  TScriptRunnerTests = class(TTestDirCase)
  private
    FBuildFile: TextFile;
    FBuildFileName: string;
    FCopyOfFileName: string;
    FRunner: TScriptRunner;
    FNewCopyOfFileName: string;
    FNewDir: string;
    FCopyDir: string;
  protected
    procedure MakeTestBuildFile;
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestWantMain;
  end;

implementation

uses JclFileUtils;

{ TScriptRunnerTests }

procedure TScriptRunnerTests.MakeTestBuildFile;
const
  CR = #$D#$A;
var
  Content: string;
begin
  AssignFile(FBuildFile, FBuildFileName);
  Rewrite(FBuildFile);

  Content :=
    CR+
    '<project name="test_project" default="main">                    '+ CR +
    '  <property name="test" value="sample" />                       '+ CR +
    '  <target name="main">                                          '+ CR +
    '    <shell executable="mkdir" arguments='''
    + ExecTasks.AddOption('', FNewDir)
    + '''       '+ CR +
    '           failonerror="no" />                                  '+ CR +
    '    <mkdir dir="' + ToPath(FCopyDir) + '" />                    '+ CR +
    '    <shell executable="copy" arguments=''                        '+
             ExecTasks.AddOption('', FBuildFileName)
              + ' ' + ExecTasks.AddOption('', FCopyOfFileName)
              + '''             '+ CR +
    '           failonerror="no" />                                  '+ CR +
    '    <shell executable="copy" arguments=''                        '+
             ExecTasks.AddOption('', FBuildFileName)
              + ' ' + ExecTasks.AddOption('', FNewCopyOfFileName)
               + ''' />       '+ CR +
    '    <copy todir="' + ToPath(FCopyDir) + '">                     '+ CR +
    '      <fileset dir="' + ToPath(FNewDir) + '">                   '+ CR +
    '        <include name="**/*.*" />                               '+ CR +
    '      </fileset>                                                '+ CR +
    '    </copy>                                                     '+ CR +
    '    <delete dir="' + ToPath(FNewDir) + '" />                    '+ CR +
    '  </target>                                                     '+ CR +
    '</project>                                                      '+ CR;

  WriteLn(FBuildFile, Content);
  CloseFile(FBuildFile);
end;

procedure TScriptRunnerTests.Setup;
begin
  inherited;
  {$IFNDEF USE_TEXT_RUNNER}
  FRunner := TScriptRunner.Create;
  {$ELSE}
  FRunner := TConsoleScriptRunner.Create;
  {$ENDIF}

  FBuildFileName := FTestDir + '\build.xml';
  FCopyOfFileName := FTestDir + '\copyofbuild.xml';
  FNewDir := FTestDir + '\new';
  FNewCopyOfFileName := FNewDir + '\copyofbuild.xml';
  FCopyDir := FTestDir + '\copy';
end;

procedure TScriptRunnerTests.TearDown;
begin
  FRunner.Free;
  inherited;
end;

procedure TScriptRunnerTests.TestWantMain;
var
  CurDir: string;
begin
  CurDir := GetCurrentDir;
  MakeTestBuildFile;
  FRunner.Build(FBuildFileName, vlWarnings);

  { leaving CurrentDir is important for other tests depend on it, because
    TProject.FRootDir defaults to CurrentDir. }
  { sometimes GetCurrentDir will return an uppercase drive letter
    and sometimes a lower case one.
    Use ToPath to avoid problems.
  }
  CheckEquals(ToPath(CurDir), ToPath(GetCurrentDir), 'current dir not left intact');

  Check(FileExists(FCopyOfFileName), 'copy doesn''t exist');
  Check(not DirectoryExists(FNewDir), 'directory exists: ' + FNewDir);
  Check(FileExists(FCopyDir + '\copyofbuild.xml'), 'copy doesn''t exist');
end;

initialization
  RegisterTests('Acceptance Suite', [TScriptRunnerTests.Suite]);

end.

