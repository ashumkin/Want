unit CVSTasksTests;
(*******************************************************************
*  WANT - A build management tool.                                 *
*  Copyright (c) 2001 Juancarlo Añez, Caracas, Venezuela.          *
*  All rights reserved.                                            *
*                                                                  *
*******************************************************************)

{ $Id: CVSTasksTests.pas 771 2004-05-08 16:15:25Z juanco $ }

{
  Contributors:
    Radim Novotny <radimnov@seznam.cz>
}

interface

uses
  JclFileUtils,
  WildPaths,
  WantClasses,
  CvsTasks,
  ScriptParser,
  TestFramework,
  TestExtensions,
  SysUtils,
  WantClassesTest;

type

  TCvsTestsSetup = class(TTestSetup)
    protected
      procedure SetUp; override;
      procedure TearDown; override;
    public
      function  GetName: string; override;
  end;

  TCvsTests = class(TProjectBaseCase)
    private
    protected
      FTestDirectory : string;
      procedure SetUp; override;
    published
      procedure TestLogin;
      procedure TestCheckout;
      procedure TestTagDiff;
      procedure TestChangeLog;
  end;

implementation

{ TCvsTests }

const
  CVSROOT   = ':pserver:anonymous@cvs.sourceforge.net:/cvsroot/want';
  CVSMODULE = 'cdata';
  CVSFILE   = 'cdata/cvstest.txt';

procedure TCvsTests.TestCheckout;
const
  build_xml = ''
  +#10'<project basedir="." name="cvs_test" default="cvs-checkout" >'
  +#10'  <target name="cvs-checkout">'
  +#10'    <cvs'
  +#10'        dest="cvstest"'
  +#10'        compression="3"'
  +#10'        cvsroot="' + CVSROOT + '"'
  +#10'        package="' + CVSMODULE + '"'
  +#10'        date="2003-09-10"'
  +#10'        hideOutput="false"'
  +#10'       >'
  +#10'    </cvs>'
  +#10'  </target>'
  +#10'</project>'
  +'';
var
  bPackage : string;
begin
  TScriptParser.ParseText(FProject, build_xml);
  RunProject;
  bPackage := FProject.GetTargetByName(FProject.GetAttribute('default')).Tasks[0].GetAttribute('package');
  if not FileExists(ToSystemPAth(fTestDirectory+SystemPathDelimiter+bPackage))
     then raise Exception.Create('Checkout test not passed');
end;

procedure TCvsTests.TestTagDiff;
const
  build_xml = ''
  +#10'<project basedir="." name="cvstagdiff_test" default="cvs-tagdiff" >'
  +#10'  <target name="cvs-tagdiff">'
  +#10'    <cvstagdiff'
  +#10'        compression="3"'
  +#10'        destfile="tagdiff.xml"'
  +#10'        cvsroot="' + CVSROOT + '"'
  +#10'        package="' + CVSFILE + '"'
  +#10'        startdate="2003-09-1"'
  +#10'        enddate="2003-09-10"'
  +#10'        hideOutput="false"'
  +#10'       >'
  +#10'    </cvstagdiff>'
  +#10'  </target>'
  +#10'</project>'
  +'';
var
   bDestfile : string;
begin
  TScriptParser.ParseText(FProject, build_xml);
  RunProject;
  bDestFile := FProject.GetTargetByName(FProject.GetAttribute('default')).Tasks[0].GetAttribute('destfile');
  if not FileExists(ToSystemPath(FProject.RootPath+SystemPathDelimiter+bDestFile))
     then raise Exception.Create('CvsTagDiff test not passed');
  DeleteFile(ToSystemPath(FProject.RootPath+SystemPathDelimiter+bDestFile));
end;

{ TCvsPassTests }

procedure TCvsTests.TestLogin;
const
  build_xml = ''
  +#10'<project basedir="." name="cvslogin_test" default="cvs-pass" >'
  +#10'  <target name="cvs-pass">'
  +#10'    <cvspass'
  +#10'        cvsroot=":pserver:anonymous@cvs.sourceforge.net:/cvsroot/want"'
  +#10'        emptypassword="true"'
  +#10'        hideOutput="false"'
  +#10'       >'
  +#10'    </cvspass>'
  +#10'  </target>'
  +#10'</project>'
  +'';
begin
  TScriptParser.ParseText(FProject, build_xml);
  RunProject;
end;

procedure TCvsTests.TestChangeLog;
const
  build_xml = ''
  +#10'<project basedir="." name="cvschangelog_test" default="cvs-changelog" >'
  +#10'  <target name="cvs-changelog">'
  +#10'    <cvschangelog'
  +#10'        dir="test/data/amodule"'
  +#10'        destfile="changelog.xml"'
  +#10'        start="2003-02-1"'
  +#10'        end="2003-02-28"'
  +#10'        hideOutput="false"'
  +#10'       >'
  +#10'    </cvschangelog>'
  +#10'  </target>'
  +#10'</project>'
  +'';
var
   bDestFile : string;
begin
  TScriptParser.ParseText(FProject, build_xml);
  RunProject;
  bDestFile := FProject.GetTargetByName(FProject.GetAttribute('default')).Tasks[0].GetAttribute('destfile');
  if not FileExists(ToSystemPath(FProject.RootPath+SystemPathDelimiter+bDestFile))
     then raise Exception.Create('CvsChangelog test not passed');
  DeleteFile(ToSystemPath(FProject.RootPath+SystemPathDelimiter+bDestFile));
end;

function TCvsTestsSetup.GetName: string;
begin
  Result:= 'CVS tests';
end;

procedure TCvsTestsSetup.SetUp;
begin
  inherited;
  if not IsDirectory('cvstest') then
      MkDir('cvstest');
end;

procedure TCvsTestsSetup.TearDown;
begin
  inherited;
  DeleteDirectory('cvstest', false);
end;

procedure TCvsTests.SetUp;
begin
  inherited;
  fTestDirectory := ToSystemPath('cvstest');
end;

initialization
  RegisterTests([  TCvsTestsSetup.Create(TCvsTests.Suite)]);

end.


