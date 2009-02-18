(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 1995-2003 Juancarlo Anez, Caracas, Venezuela.              *
 * All rights reserved.                                                     *
 *                                                                          *
 * This library is free software; you can redistribute it and/or            *
 * modify it under the terms of the GNU Lesser General Public               *
 * License as published by the Free Software Foundation; either             *
 * version 2.1 of the License, or (at your option) any later version.       *
 *                                                                          *
 * This library is distributed in the hope that it will be useful,          *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 * Lesser General Public License for more details.                          *
 *                                                                          *
 * You should have received a copy of the GNU Lesser General Public         *
 * License along with this library; if not, write to the Free Software      *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA *
 ****************************************************************************)
{
    @brief 

    @author Juancarlo Añez
    @author Bob Arnson <sf@bobs.org>
}

unit JALStrings;

interface
uses
  SysUtils,
  {$IFDEF VER140}
  Types,
  {$ENDIF}
  Classes;

{$IFDEF VER130}
const
	sLineBreak = #13#10;
{$ENDIF}

type
  {$IFDEF VER140}
  TStringDynArray = Types.TStringDynArray;
  {$ELSE}
  TStringDynArray = array of string;
  {$ENDIF}
  TStringArray = TStringDynArray;

  TTrimType = (ttNone, ttLeft, ttRight, ttBoth);

  TCharSet   = set of Char;

function StringArray(const A : array of string) :TStringDynArray;

function StringToArray(const Str :string; const Sep :string =','; TrimType :TTrimType = ttNone):TStringDynArray;
function ArrayToString(const A :TStringDynArray; const Sep :string =','; TrimType :TTrimType = ttNone) :string;

function StringsToArray(const S :TStrings; TrimType :TTrimType = ttNone) :TStringDynArray;
procedure StringArrayAppend(var A :TStringArray; const S :string);

function DLMStringToArray(const Str :string; TrimType :TTrimType = ttNone) :TStringDynArray;
function UnquoteDLMArray(A :array of string; TrimType :TTrimType = ttNone) :TStringDynArray;
function ArrayToDLMString(const A :TStringDynArray) :string;

procedure StrToStrings(S: string; Sep: string; const List: TStrings);
function  StrTrimQuotes(S: string): string;

function  StrTrim(const S :string; TrimType :TTrimType = ttBoth) :string;
procedure TrimStringArray(var A : TStringDynArray; TrimType :TTrimType = ttBoth);

function StrLast(const S :string) :Char;
function StrLeft(const S: string; Count: Integer): string;
function StrRight(const S: string; Count: Integer): string;

function StrEndsWith(const S :string; const ends :string):boolean;

procedure DeleteStrings(var S :TStrings; Start, Len :Integer);

function LoadStrings(var fin :Text) :TStrings; overload;

function LoadString(const FileName :string) :string;

function FileToString(const FileName: AnsiString): AnsiString;
procedure StringToFile(const FileName, Contents: AnsiString);

function Pack(const A :TStringDynArray) :TStringDynArray;

function FileToStringArray(const FileName:AnsiString) :TStringArray;
procedure StringArrayToFile(const FileName:AnsiString; const A :TStringArray; const Sep :string = sLineBreak; TrimType :TTrimType = ttNone);
function ConfFileToStringArray(const FileName:AnsiString) :TStringArray;


function StrToken(var S: string; Separator: char): string;
function ParseULName(const name :string; const HeadPrune : TCharSet):string;
function StrRepeat(const S: AnsiString; Count: Integer): AnsiString;

implementation

procedure StrToStrings(S: string; Sep: string; const List: TStrings);
var
  I, L: Integer;
  Left: string;
begin
  Assert(List <> nil);
  List.Clear;
  L := Length(Sep);
  I := Pos(Sep, S);
  while (I > 0) do
  begin
    Left := StrLeft(S, I - 1);
    List.Add(Left);
    Delete(S, 1, I + L - 1);
    I := Pos(Sep, S);
  end;
  if S <> '' then
    List.Add(S);
end;

function StrTrimQuotes(S: string): string;
var
  First, Last: Char;
  L: Integer;
begin
  S := Trim(S);
  L := Length(S);
  if L > 1 then
  begin
    First := S[1];
    Last := S[L];
    if (First = Last) and ((First = '''') or (First = '"')) then
      Result := Copy(S, 2, L - 2)
    else
      Result := S;
  end
  else
    Result := S;
end;

function StringArray(const A : array of string) :TStringDynArray;
var
  i :Integer;
begin
  SetLength(Result, Length(A));
  for i := Low(A) to High(A) do
    Result[i] := A[i];
end;


function StringsToArray(const S :TStrings; TrimType :TTrimType) :TStringDynArray;
var
  i    :Integer;
begin
  Result := nil;
  SetLength(Result, S.Count);
  if TrimType <> ttNone then
    for i := 0 to S.Count-1 do
      Result[i] := StrTrim(S[i], TrimType)
  else
    for i := 0 to S.Count-1 do
      Result[i] := S[i]
end;

function StrTrim(const S :string; TrimType :TTrimType) :string;
begin
  case TrimType of
    ttLeft  : Result := TrimLeft(  S);
    ttRight : Result := TrimRight( S);
    ttBoth  : Result := Trim(      S);
  else
    Result  := S;
  end;
end;

procedure TrimStringArray(var A : TStringDynArray; TrimType :TTrimType);
var
  i :Integer;
begin
  for  i := 0 to  High(A) do
  begin
    A[i] := StrTrim(A[i], TrimType);
  end;
end;

function StringToArray(const Str, Sep :string; TrimType :TTrimType):TStringDynArray;
var
  List :TStrings;
begin
  Result := nil;
  List := TStringList.Create;
  try
    StrToStrings(Str, Sep, List);
    Result := StringsToArray(List, TrimType);
  finally
    List.Free;
  end;
end;

function DLMStringToArray(const Str :string; TrimType :TTrimType) :TStringDynArray;
begin
  Result := StringToArray(Str, ',');
  Result := UnquoteDLMArray(Result, TrimType);
end;

function UnquoteDLMArray(A :array of string; TrimType :TTrimType) :TStringDynArray;
var
  i :Integer;
begin
  SetLength(Result, Length(A));
  for i := Low(A) to High(A) do
  begin
    Result[i] := StrTrim(StrTrimQuotes(A[i]), TrimType);
  end;
end;

function ArrayToString(const A :TStringDynArray; const Sep :string; TrimType :TTrimType) :string;
var
  i :Integer;
begin
  Result := '';
  if Length(A) > 0 then
  begin
    Result := A[Low(A)];
    for i := Low(A)+1 to High(A) do
      Result := Result + Sep + StrTrim(A[i], TrimType);
  end;
end;

function ArrayToDLMString(const A :TStringDynArray) :string;
begin
  Result := ArrayToString(A, ',');
end;

function StrLast(const S :string) :Char;
begin
  Result := S[Length(S)];
end;

function StrLeft(const S: string; Count: Integer): string;
begin
  Result := Copy(S, 1, Count);
end;

function StrRight(const S: string; Count: Integer): string;
begin
  if Count < 0 then Count := 0;
  Result := Copy(S, Length(S) - (Count-1), Count);
end;

procedure DeleteStrings(var S :TStrings; Start, Len :Integer);
var
  i :Integer;
begin
  for i := (Start + Len - 1) downto Start do
    S.Delete(i);
end;


function LoadStrings(var fin :Text) :TStrings;
var
  S :string;
begin
  Result := TStringList.Create;
  try
    while not eof(fin) do
    begin
      Readln(fin, S);
      Result.Add(PChar(S));
    end;
  except
    Result.Free;
    raise;
  end;
end;

function LoadString(const FileName :string) :string;
var
  S :TStrings;
begin
  S := TStringList.Create;
  try
    S.LoadFromFile(FileName);
    Result := S.Text;
  finally
    S.Free;
  end;
end;

function FileToString(const FileName: AnsiString): AnsiString;
var
  F: File;
  Size: Integer;
  Buffer: Pointer;
  SaveFileMode: integer;
begin
  SaveFileMode := FileMode;
  try
    FileMode := fmOpenRead;
    AssignFile(F, FileName);
    Reset(F, 1);
  finally
    FileMode := SaveFileMode;
  end;
  try
    Size := FileSize(F);
    SetLength(Result, Size);
    Buffer := PChar(Result);
    BlockRead(F, Buffer^, Size);
  finally
    CloseFile(F);
  end;
end;

//------------------------------------------------------------------------------

procedure StringToFile(const FileName, Contents: AnsiString);
var
  F: File;
  Size: Integer;
  Buffer: Pointer;
begin
  AssignFile(F, FileName);
  Rewrite(F, 1);
  try
    Size := Length(Contents);
    Buffer := PChar(Contents);
    BlockWrite(F, Buffer^, Size);
  finally
    CloseFile(F);
  end;
end;

function Pack(const A :TStringDynArray) :TStringDynArray;
var
  i, Count :Integer;
begin
  SetLength(Result, Length(A));

  Count := 0;
  for i := 0 to High(A) do
    if Length(A[i]) > 0 then
    begin
      Result[Count] := A[i];
      Inc(Count);
    end;

  SetLength(Result, Count);
end;

function FileToStringArray(const FileName:AnsiString) :TStringArray;
var
  S :TStrings;
begin
  S := TStringList.Create;
  try
    S.LoadFromFile(FileName);
    Result := StringsToArray(S, ttBoth);
  finally
    S.Free;
  end;
end;

function ConfFileToStringArray(const FileName:AnsiString) :TStringArray;
var
  i :Integer;
begin
  Result := FileToStringArray(FileName);
  for i := 0 to High(Result) do
    if Pos('#', Result[i]) = 1 then
      Result[i] := '';
  Result := Pack(Result);
end;


function StrEndsWith(const S :string; const ends :string):boolean;
begin
  Result := ends = StrRight(S, Length(ends));
end;

function StrToken(var S: string; Separator: char): string;
var
  i: Integer;
begin
  i := Pos(Separator, S);
  if i <> 0 then
  begin
    Result := Copy(S, 1, i - 1);
    Delete(S, 1, i);
  end
  else
  begin
    Result := S;
    S := '';
  end;
end;

procedure StringArrayToFile(const FileName:AnsiString; const A :TStringArray; const Sep :string; TrimType :TTrimType);
var
  S :string;
begin
  S := ArrayToString(A, Sep, TrimType);
  StringToFile(FileName, S);
end;

procedure StringArrayAppend(var A :TStringArray; const S :string);
begin
  SetLength(A, Length(A)+1);
  A[High(A)] := S;
end;


function ParseULName(const name :string; const HeadPrune : TCharSet):string;
const
    Uppers = ['A'..'Z'];

var
   i :Integer;
   S :String;

    function AddUpperRun(j :Integer):Integer;
    begin
         while (j < Length(name)) and (name[j+1] in Uppers) do begin
               S := S+name[j+1];
               Inc(j)
         end;
         Result := j
    end;
begin
     S := '';
     if length(name) > 0 then begin
        i := 1;
        if name[i] in HeadPrune then
              Inc(i);
        while (i <= length(name)) and (name[i] in Uppers) do begin
              S := S + name[i];
              Inc(i)
        end;
        while i <= length(name) do begin
            case name[i] of
              '_': begin
                  S := S + ' ';
                  i := AddUpperRun(i);
              end;
              'A'..'Z':
                 if (i >= length(name)) then
                    S := S + name[i]
                 else if not (name[i+1] in Uppers) then
                    S := S+' '+LowerCase(name[i])
                 else begin
                    S := S+' '+name[i];
                    i := AddUpperRun(i);
                 end
            else
                S := S+name[i]
            end;
            Inc(i)
        end
     end;
     Result := S
end;

function StrRepeat(const S: AnsiString; Count: Integer): AnsiString;
var
  L: Integer;
  P: PChar;
begin
  L := Length(S);
  SetLength(Result, Count * L);
  P := Pointer(Result);
  while Count > 0 do
  begin
    Move(Pointer(S)^, P^, L);
    P := P + L;
    Dec(Count);
  end;
end;

end.

