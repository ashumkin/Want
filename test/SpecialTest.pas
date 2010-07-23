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

type
  ESpecialException = class(Exception);

{ TTestSpecial }

procedure TTestSpecial.TestSpecial;
begin
  raise ESpecialException.Create('Special exception');
end;

initialization
  {$IFOPT D+}
  RegisterTest(TTestSpecial.Suite);
  {$ENDIF}
  
end.