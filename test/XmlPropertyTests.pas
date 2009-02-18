(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id: XmlPropertyTests.pas 678 2003-04-27 12:18:13Z radimnov $ }

{
  Contributors:
    Radim Novotny <radimnov@seznam.cz>
}

unit XmlPropertyTests;

interface

uses
  TestFramework,
  WantClasses,
  ScriptParser,
  WantClassesTest;

type
  TXmlPropertyTests = class(TProjectBaseCase)
  published
    procedure XmlPropertyTest;
  end;

implementation

uses
  Classes,
  JclFileUtils,
  SysUtils;

{ TFilterChainsTests }

procedure TXmlPropertyTests.XmlPropertyTest;
const
  TEST_XML = ''
    +    '<?xml version="1.0" encoding="iso-8859-1"?>'
    + #10'<root-tag myattr="value">'
    + #10'  <inner-tag someattr="val" otherattr="val2">Text</inner-tag>'
    + #10'  <a2><a3><a4>false</a4></a3></a2>'
    + #10'</root-tag>'
    + #10'';
  BUILD_XML = ''
    +    '<?xml version="1.0" encoding="iso-8859-1"?>'
    + #10'<project name="test_xml" basedir="." default="test">'
    + #10'  <target name="test" >'
    + #10'    <xmlproperty file="${test.file}"/>'
    + #10'  </target>'
    + #10'</project>'
    + #10'';
var
  bSL  :TStringList;
  bTmp :string;
begin
  TScriptParser.ParseText(FProject, BUILD_XML);
  bSL := TStringList.Create;
  try
    bSL.Text := TEST_XML;
    bTmp := FileGetTempName('tmp');
    bSL.SaveToFile(bTmp);
  finally
    bSL.Free;
  end;
  FProject.Targets[0].SetProperty('test.file', bTmp);
  RunProject;
  CheckEquals('value',FProject.Targets[0].PropertyValue('root-tag(myattr)'));
  CheckEquals('val',  FProject.Targets[0].PropertyValue('root-tag.inner-tag(someattr)'));
  CheckEquals('val2', FProject.Targets[0].PropertyValue('root-tag.inner-tag(otherattr)'));
  CheckEquals('Text', FProject.Targets[0].PropertyValue('root-tag.inner-tag'));
  CheckEquals('false',FProject.Targets[0].PropertyValue('root-tag.a2.a3.a4'));
  DeleteFile(bTmp);
end;

initialization
  RegisterTests('XmlProperty Task', [TXmlPropertyTests.Suite]);
end.
