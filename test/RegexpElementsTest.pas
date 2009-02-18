(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id: RegexpElementsTest.pas 385 2001-05-11 17:18:14Z juanca $ }

unit RegexpElementsTest;

interface
uses
  TestFramework,
  WantClasses,
  ScriptParser,
  WantClassesTest,
  RegexpElements;

type
  TRegexpTests = class(TProjectBaseCase)
  published
    procedure Test;
  end;


implementation

{ TRegexpTests }

procedure TRegexpTests.Test;
const
  build_xml = ''
  +#10'<project name="test" default="dotest" >'
  +#10'  <target name="dotest">'
  +#10'    <regexp property="subst" pattern="\." subst="_" text="1.2.3">'
  +#10'    </regexp>'
  +#10'  </target>'
  +#10'</project>'
  +'';
begin
  TScriptParser.ParseText(FProject, build_xml);
  RunProject;
  CheckEquals('1_2_3', FProject.Targets[0].PropertyValue('subst'));
end;

initialization
  RegisterTests('Regexp', [TRegexpTests.Suite]);
end.
