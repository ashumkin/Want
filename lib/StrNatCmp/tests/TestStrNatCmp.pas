unit TestStrNatCmp;

interface

uses
  TestFramework,
  StrNatCmp;

type
  TTestStrNatCmp = class(TTestCase)
  protected
    procedure NatCompareText(pRes: Integer; const v1, v2: string);
  public
  published
    procedure TestNatCompareText;
    procedure TestCompare_NaturalSort;
  end;

implementation

uses
  Classes, SysUtils, StrUtils;
  
{ TTestStrNatCmp }

const
  CRLF = #13#10;
  
procedure TTestStrNatCmp.NatCompareText(pRes: Integer; const v1, v2: string);
begin
  CheckEquals(pRes, StrNatCmp.NatCompareText(v1, v2),
    Format('"%s" vs "%s"', [v1, v2]));
end;

procedure TTestStrNatCmp.TestCompare_NaturalSort;
const
  cHasToBeStr =
    'v2_5_11_494\' + CRLF
    + 'v2_5_10_489\' + CRLF
    + 'v2_5_1_335\' + CRLF
    + 'v2_4_12_440\' + CRLF
    + 'v2_4_11_422\' + CRLF
    + 'v2_4_10_365\' + CRLF
    + 'v2_4_5_247\' + CRLF
    + 'v2_4_4_210\' + CRLF
    + 'v2_4_3_195\' + CRLF
    + 'v2_4_2_175\' + CRLF
    + 'v2_4_1_169\' + CRLF
    + 'v2_3_24_158\' + CRLF
    + 'v2_3_22_154\' + CRLF;
var
  TSL: TStringList;
begin
  TSL := TStringList.Create;
  try
    TSL.Text :=
      'v2_3_22_154\' + CRLF
      + 'v2_3_24_158\' + CRLF
      + 'v2_4_1_169\' + CRLF
      + 'v2_4_10_365\' + CRLF
      + 'v2_4_11_422\' + CRLF
      + 'v2_4_12_440\' + CRLF
      + 'v2_4_2_175\' + CRLF
      + 'v2_4_3_195\' + CRLF
      + 'v2_4_4_210\' + CRLF
      + 'v2_4_5_247\' + CRLF
      + 'v2_5_1_335\' + CRLF
      + 'v2_5_10_489\' + CRLF
      + 'v2_5_11_494\';
    InvertCompare_NaturalSort := True;
    // due to bug(?) of Compare_NaturalSort
    // replace _ with * (as filenames cannot contain *)
    TSL.Text := AnsiReplaceText(TSL.Text, '_', '*');
    TSL.CustomSort(@Compare_NaturalSort);
    // replace back
    TSL.Text := AnsiReplaceText(TSL.Text, '*', '_');
    CheckEquals(cHasToBeStr, TSL.Text);
  finally
    FreeAndNil(TSL);
  end;
end;

procedure TTestStrNatCmp.TestNatCompareText;
begin
  NatCompareText(0, 'v1_11', 'v1_11');

  NatCompareText(1, 'v1_12', 'v1_11');
  NatCompareText(-1, 'v1_10', 'v1_11');

  NatCompareText(-1, 'v1_1', 'v1_11');
  NatCompareText(-1, 'v1_2', 'v1_11');

  NatCompareText(1, 'v1_20', 'v1_11');
  NatCompareText(1, 'v1_20', 'v1_1');

  NatCompareText(1, 'v2_20', 'v1_11');
  NatCompareText(1, 'v2_20', 'v2_1');

  NatCompareText(-1, '1-', '10-');
  NatCompareText(-1, 'v2.1.335', 'v2.10.489');
  NatCompareText(-1, 'v2*4*1*', 'v2*4*10*');
//  NatCompareText(-1, 'v2_4_1_', 'v2_4_10_');
end;

initialization
  RegisterTest(TTestStrNatCmp.Suite);
  
end.