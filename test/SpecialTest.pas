unit SpecialTest;

interface

uses
  TestFramework;

type
  TTestSpecial = class(TTestCase)
  published
    procedure TestSpecial;
  end;


implementation

uses
  SysUtils;

{ TTestSpecial }

procedure TTestSpecial.TestSpecial;
begin
  raise Exception.Create('Special exception');
end;

initialization
  {$IFOPT D+}
  RegisterTest(TTestSpecial.Suite);
  {$ENDIF}
  
end.