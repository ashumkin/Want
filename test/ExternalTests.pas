(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id: ExternalTests.pas 771 2004-05-08 16:15:25Z juanco $ }

unit ExternalTests;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Math,

  Dialogs,

  JclSysUtils,
  JclFileUtils,
  JclMiscel,
  JclShell,

  JalZipStreams,

  WildPaths,
  WantClasses,
  ScriptRunner,
  ConsoleScriptRunner,

  TestFramework;


type
  TExternalTest = class(TTestCase)
  private
    FTestPath: TPath;
    FRootPath: TPath;
    FBuildFileName :TPath;

    procedure SetTestName;
    procedure SetTestPath(const Value: TPath);
  protected
    class function CompareFiles(AFileName, BFileName: string): boolean;
    procedure CompareActualToFinal;
    procedure DeleteSubFolders;
    function FinalFileName: string;
    function SetupFileName: string;
    procedure Unzip(ZipFileName, Directory: TPath);
    procedure UnzipFinal;
    procedure UnzipSetup;
    procedure VerifyFinal;

    function SetupPath :TPath;
    function FinalPath :TPath;
  public
    constructor Create; reintroduce; overload;
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure DoTest;

    property TestPath: TPath read FTestPath write SetTestPath;
  end;

implementation


procedure LoadTests;
var
  Files: TPaths;
  i: Integer;
  ATest: TExternalTest;
  BasePath: string;
begin
  Files := nil;
  try
    BasePath := PathConcat(CurrentDir, 'test/data');
    if not PathIsDir(BasePath) then
      BasePath := PathConcat(CurrentDir, '../test/data');
    if not PathIsDir(BasePath) then
      BasePath := PathConcat(CurrentDir, '../../test/data');
    if not PathIsDir(BasePath) then
      raise Exception.Create('could not find test data in ' + ToSystemPath(BasePath));
    Files := WildPaths.Wild('**/want.xml', BasePath);
    for i := 0 to High(Files) do
    begin
      if (Pos('CVS', Files[i]) = 0) and (Pos('svn', Files[i]) = 0) then
      begin
        ATest := TExternalTest.Create;
        ATest.TestPath := SuperPath(Files[i]);
        ATest.FBuildFileName := MovePath(Files[i], ATest.TestPath, '');
        RegisterTest(PathConcat('External Tests',ToRelativePath(ATest.TestPath, BasePath)), ATest);
      end;
    end;
    Files := WildPaths.Wild('**/build.xml', BasePath);
    for i := 0 to High(Files) do
    begin
      if (Pos('CVS', Files[i]) = 0) and (Pos('svn', Files[i]) = 0) then
      begin
        ATest := TExternalTest.Create;
        ATest.TestPath := SuperPath(Files[i]);
        ATest.FBuildFileName := MovePath(Files[i], ATest.TestPath, '');
        RegisterTest(PathConcat('External Tests',ToRelativePath(ATest.TestPath, BasePath)), ATest);
      end;
    end;
  except
    on e :Exception do
      ShowMessage('Error loading external tests: ' + e. Message);
  end;
end;

{ TExternalTest }

function TExternalTest.SetupPath: TPath;
begin
  Result := PathConcat(FRootPath, 'setup');
end;

function TExternalTest.FinalPath: TPath;
begin
  Result := PathConcat(FRootPath, 'final');
end;

procedure TExternalTest.CompareActualToFinal;
var
  SetupFiles :TStrings;
  FinalFiles :TStrings;
  SF,
  FF         :TPath;
  p :Integer;
begin
  SetupFiles := TStringList.Create;
  FinalFiles := TStringList.Create;
  try
     Wild(SetupFiles, '**', SetupPath);
     Wild(FinalFiles, '**', FinalPath);

     ToRelativePaths(SetupFiles, SetupPath);
     ToRelativePaths(FinalFiles, FinalPath);

     for p := SetupFiles.Count-1 downto 0 do
       if (Pos('CVS', SetupFiles[p]) <> 0) or (Pos('svn', SetupFiles[p]) <> 0) then
         SetupFiles.Delete(p);

     for p := FinalFiles.Count-1 downto 0 do
       if (Pos('CVS', FinalFiles[p]) <> 0) or (Pos('svn', FinalFiles[p]) <> 0) then
         FinalFiles.Delete(p);

     for p := 0 to SetupFiles.Count-1 do
       Check(FinalFiles.IndexOf(SetupFiles[p]) >= 0, Format('%s in setup but not in final', [SetupFiles[p]]));

     for p := 0 to FinalFiles.Count-1 do
       Check(SetupFiles.IndexOf(FinalFiles[p]) >= 0, Format('%s in final but not in setup', [FinalFiles[p]]));

     for p := 0 to Min(SetupFiles.Count, FinalFiles.Count)-1 do
     begin
       SF := PathConcat(SetupPath, SetupFiles[p]);
       FF := PathConcat(FinalPath, FinalFiles[p]);

       CheckEquals(   IsDirectory(SF),
                      IsDirectory(FF),
                      Format('%s files not both directories', [SetupFiles[p]]));;

       if PathExists(SF)
       and PathExists(FF)
       and not PathIsDir(SF)
       and not PathIsDir(FF) then
       begin
         if not CompareFiles(SF, FF) then
           Fail(Format('%s files are different', [SetupFiles[p]]));;
       end;
     end;
  finally
    SetupFiles.Free;
    FinalFiles.Free;
  end;
end;

class function TExternalTest.CompareFiles(AFileName, BFileName: string): boolean;
var
  A: TFileStream;
  B: TFileStream;
  ARead: Integer;
  BRead: Integer;
  ABuf: array[1..2048] of Char;
  BBuf: array[1..2048] of Char;
begin
  { read-only, required for read-only files, and all we need here anyway }
  FileMode := 0;
  A := TFileStream.Create(ToSystemPath(AFileName), fmOpenRead);
  try
    B := TFileStream.Create(ToSystemPath(BFileName), fmOpenRead);
    try
      repeat
        FillChar(ABuf, SizeOf(ABuf), #0);
        FillChar(BBuf, SizeOf(BBuf), #0);

        ARead := A.Read(ABuf, SizeOf(ABuf));
        BRead := B.Read(BBuf, SizeOf(BBuf));

        if ARead = BRead then
          Result := (ABuf = BBuf)
        else
          Result := False;
      until (not Result) or (ARead <> SizeOf(ABuf));
    finally
      FreeAndNil(B);
    end;
  finally
    FreeAndNil(A);
  end;
end;

constructor TExternalTest.Create;
begin
  Create('DoTest');

  FRootPath := PathConcat(ToPath(ExtractFilePath(ParamStr(0))) ,'test_tmp');
end;

procedure TExternalTest.DeleteSubFolders;
begin
  ChDir(ExtractFileDir(ParamStr(0)));
  { make sure we haven't got off on the root dir or something heinous }
  if ExtractFileDir(ParamStr(0)) <> GetCurrentDir then
    EXIT;
  if   (FRootPath <> '')
  and  PathIsDir(FRootPath)
  and  PathIsDir(SetupPath)
  and  PathIsDir(FinalPath)
  and  PathIsFile(PathConcat(SetupPath, FBuildFileName))
  then
  begin
    DeleteFiles('**', FRootPath, True);
    RemoveDir(SetupPath);
    RemoveDir(FinalPath);
    RemoveDir(ToSystemPath(FRootPath));
  end;
end;

procedure TExternalTest.DoTest;
var
  Runner: TScriptRunner;
begin
  {$IFDEF USE_TEXT_RUNNER}
  Runner := TScriptRunner.Create;
  {$ELSE}
  Runner := TConsoleScriptRunner.Create;   
  {$ENDIF}
  try
    Runner.Build(PathConcat(SetupPath, FBuildFileName), vlVerbose);
  finally
    Runner.Free;
  end;
  VerifyFinal;
end;

function TExternalTest.FinalFileName: string;
begin
  Result := 'final.zip';
end;

procedure TExternalTest.SetTestName;
begin
  FTestName := ToRelativePath(FTestPath, SuperPath(FTestPath));
end;

procedure TExternalTest.SetTestPath(const Value: TPath);
begin
  FTestPath := Value;
  SetTestName;
end;

procedure TExternalTest.Setup;
begin
  inherited;
  DeleteSubFolders;
  UnzipSetup;
end;

function TExternalTest.SetupFileName: string;
begin
  Result := 'setup.zip';
end;

procedure TExternalTest.TearDown;
begin
  DeleteSubFolders;
  inherited;
end;

procedure TExternalTest.Unzip(ZipFileName, Directory: TPath);

  procedure DoCopy(FileName: TPath);
  begin
    CopyFiles(FileName, FTestPath, Directory);
  end;
var
  ZipLocation  :TPath;
  DirLocation  :TPath;
begin
  MakeDir(FRootPath);
  ChangeDir(FRootPath);

  MakeDir(Directory);

  DoCopy(FBuildFileName);

  ZipLocation := PathConcat(FTestPath, ZipFileName);
  if PathIsFile(ZipLocation) then
    JalZipStreams.ExtractAll(ZipLocation, Directory)
  else
  begin
    DirLocation := ChangeFileExt(ZipLocation, '');
    if PathIsDir(DirLocation) then
      CopyFiles('**', DirLocation, Directory)
    else
      Fail('Could not find ' + ZipLocation);
  end;
end;

procedure TExternalTest.UnzipFinal;
begin
  Unzip(FinalFileName, FinalPath);
end;

procedure TExternalTest.UnzipSetup;
begin
  Unzip(SetupFileName, SetupPath)
end;

procedure TExternalTest.VerifyFinal;
begin
  UnzipFinal;
  CompareActualToFinal;
end;

initialization
  LoadTests;
end.

