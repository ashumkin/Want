(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id: WantTests.dpr 776 2004-05-28 17:52:27Z juanco $ }
program WantTests;

uses
  GUITestRunner,
  TextTestRunner,
  TestFramework,
  RunnerTests,

  TestuURI in '..\lib\Common\tests\TestuURI.pas',
  TestuProps in '..\lib\Common\tests\TestuProps.pas',
  WantClassesTest in 'WantClassesTest.pas',
  FileSetTests in 'FileSetTests.pas',
  ExecTasksTest in 'ExecTasksTest.pas',
  FileTasksTest in 'FileTasksTest.pas',
  DelphiTasksTest in 'DelphiTasksTest.pas',
  WildPathsTest in 'WildPathsTest.pas',
  RegexpElementsTest in 'RegexpElementsTest.pas',
  ExternalTests in 'ExternalTests.pas',
  ConsoleScriptRunner in '..\src\win32\ConsoleScriptRunner.pas',
  StyleTasks in '..\src\tasks\StyleTasks.pas',
  MSXMLEngineImpl in '..\src\win32\MSXMLEngineImpl.pas',
  //!!! CVSTasksTests in 'CVSTasksTests.pas',
  XmlPropertyTests in 'XmlPropertyTests.pas',
  FilterElementsTests in 'FilterElementsTests.pas',
  LoadFileTests in 'LoadFileTests.pas',
  TempFileTests in 'TempFileTests.pas',
  SVNTasksTest in 'SVNTasksTest.pas',
  SpecialTest in 'SpecialTest.pas',
  TestStrNatCmp in '..\lib\StrNatCmp\tests\TestStrNatCmp.pas';

{$R *.RES}

begin
  {$IFDEF USE_TEXT_RUNNER}
    TextTestRunner.RunRegisteredTests(rxbHaltOnFailures)
  {$ELSE}
    GUITestRunner.RunRegisteredTests;
  {$ENDIF}
end.

