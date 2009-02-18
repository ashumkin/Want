program JalDXFTests;

uses
  TestFramework,
  GUITestRunner,
  JalDXF in '..\JalDXF.pas',
  TestDXFParse in 'TestDXFParse.pas';

{$R *.RES}

begin
  GUITestRunner.RunRegisteredTests;
end.
