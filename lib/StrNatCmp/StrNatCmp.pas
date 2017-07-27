unit StrNatCmp;

(*
  strnatcmp Delphi wrapper
  by I.Runge 2006
  www.irsoft.de
  
  Do with this source what you'd like to, but please keep this note in-place.
  
  strnatcmp by Martin Pool: http://sourcefrog.net/projects/natsort/
*)

interface

uses SysUtils, Windows, Classes;

function NatCompareText(const S1, S2: String): Integer;
function NatCompareStr(const S1, S2: String): Integer;
function Compare_NaturalSort(List: TStringList; Index1, Index2: Integer): Integer;

var
  InvertCompare_NaturalSort: boolean = False;
implementation

{$INCLUDE 'CHelpers.pas'}

{$LINK 'strnatcmp.obj'}

function _strnatcmp(const a, b: PChar): Integer; cdecl; external;
function _strnatcasecmp(const a, b: PChar): Integer; cdecl; external;


function NatCompareText(const S1, S2: String): Integer;
begin
  // IMPORTANT!!
  // accoring this implementaion
  // 'v2.4.1.' < 'v2.4.10.'
  // BUT!!!
  // 'v2_4_1_' > 'v2_4_10_'
  // note "_" (underscore) at the end of string
  Result := _strnatcasecmp(PChar(S1), PChar(S2));
end;

function NatCompareStr(const S1, S2: String): Integer;
begin
  Result := _strnatcmp(PChar(S1), PChar(S2));
end;

function Compare_NaturalSort(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result := NatCompareText(List[Index1], List[Index2]);
  if InvertCompare_NaturalSort then
    Result := -Result;
end;

end.








