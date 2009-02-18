(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id: TempFileTests.pas 678 2003-04-27 12:18:13Z radimnov $ }

{
  Contributors:
    Radim Novotny <radimnov@seznam.cz>
}

unit TempFileTests;

interface

uses
  TestFramework,
  WantClasses,
  ScriptParser,
  WantClassesTest;

type
  TTempFileTests = class(TProjectBaseCase)
  published
    procedure TempFileTest;
  end;

implementation

uses
  WildPaths,
  SysUtils;

{ TFilterChainsTests }

procedure TTempFileTests.TempFileTest;
const
  BUILD_XML = ''
   + #10'<project name="test" default="dotest" >'
   + #10'  <target name="dotest">'
   + #10'    <tempfile property="temp.file" prefix="tmp"/>'
   + #10'  </target>'
   + #10'</project>'
   + #10'';
var
  bTmpFile : string;
begin
  TScriptParser.ParseText(FProject, BUILD_XML);
  RunProject;
  bTmpFile := ToSystemPath(FProject.Targets[0].PropertyValue('temp.file'));
  bTmpFile := ExtractFileName(bTmpFile);
  CheckEquals( 'tmp', Copy(bTmpfile, 1, 3));                  { check prefix }
  CheckEquals('.tmp', Copy(bTmpfile, Length(bTmpFile)-3, 4)); { check default suffix}
  CheckEquals(    11, Length(bTmpFile));                      { check length }
end;

initialization
  RegisterTests('TempFile Task', [TTempFileTests.Suite]);
end.
