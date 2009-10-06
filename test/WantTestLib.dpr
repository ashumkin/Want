{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{                                              }
{   \\\                                        }
{  -(j)-                                       }
{    /juanca (R)                               }
{    ~                                         }
{     Copyright (C) 1995,2001 Juancarlo Añez   }
{     All rights reserved.                     }
{            http://www.suigeneris.org/juanca  }
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

{#(@)$Id: WantTestLib.dpr 771 2004-05-08 16:15:25Z juanco $}

library WantTestLib;

uses
  ShareMem,
  TestFramework,
  Win32Implementations in '..\src\win32\Win32Implementations.pas',

  TestuURI in '..\lib\Common\tests\TestuURI.pas',
  
  WantClassesTest in 'WantClassesTest.pas',
  FileSetTests in 'FileSetTests.pas',
  ExecTasksTest in 'ExecTasksTest.pas',
  FileTasksTest in 'FileTasksTest.pas',
  DelphiTasksTest in 'DelphiTasksTest.pas',
  WildPathsTest in 'WildPathsTest.pas',
  {!!! these tests need a better implementation
  CVSTasksTests in 'CVSTasksTests.pas',
  }
  RegexpElementsTest in 'RegexpElementsTest.pas',
  WantStandardTasks in '..\src\tasks\WantStandardTasks.pas',
  StandardTasks in '..\src\tasks\StandardTasks.pas',
  TempFileTests in 'TempFileTests.pas',
  XmlPropertyTests in 'XmlPropertyTests.pas',
  FilterElementsTests in 'FilterElementsTests.pas',
  LoadFileTests in 'LoadFileTests.pas',
  SVNTasksTest in 'SVNTasksTest.pas';

{$R *.RES}

exports
  RegisteredTests name 'Test';
end.

