(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 2001-2003 Juancarlo Anez, Caracas, Venezuela.              *
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

    @author Juanco Añez
}
unit XPerlRE;

interface
uses
  SysUtils,
  JclSysUtils,
  UPerlRE;

const

  PCRE_CASELESS        = UPerlRE.PCRE_CASELESS;
  PCRE_MULTILINE       = UPerlRE.PCRE_MULTILINE;
  PCRE_DOTALL          = UPerlRE.PCRE_DOTALL;
  PCRE_SINGLELINE      = UPerlRE.PCRE_SINGLELINE;
  PCRE_EXTENDED        = UPerlRE.PCRE_EXTENDED;
  PCRE_ANCHORED        = UPerlRE.PCRE_ANCHORED;
  PCRE_DOLLAR_ENDONLY  = UPerlRE.PCRE_DOLLAR_ENDONLY;
  PCRE_EXTRA           = UPerlRE.PCRE_EXTRA;
  PCRE_NOTBOL          = UPerlRE.PCRE_NOTBOL;
  PCRE_NOTEOL          = UPerlRE.PCRE_NOTEOL;
  PCRE_UNGREEDY        = UPerlRE.PCRE_UNGREEDY;

  // Exec-time error codes

  PCRE_ERROR_NOMATCH        = UPerlRE.PCRE_ERROR_NOMATCH;
  PCRE_ERROR_NULL           = UPerlRE.PCRE_ERROR_NULL;
  PCRE_ERROR_BADOPTION      = UPerlRE.PCRE_ERROR_BADOPTION;
  PCRE_ERROR_BADMAGIC       = UPerlRE.PCRE_ERROR_BADMAGIC;
  PCRE_ERROR_UNKNOWN_NODE   = UPerlRE.PCRE_ERROR_UNKNOWN_NODE;
  PCRE_ERROR_NOMEMORY       = UPerlRE.PCRE_ERROR_NOMEMORY;

  // maximum number of sub expression, not incl. the 0th part
  MAX_SUBEXP = UPerlRE.MAX_SUBEXP;

type
  TSubExpRange = UPerlRe.TSubExpRange;
  TOffsets     = UPerlRe.TOffsets;
  TSubExp      = UPerlRe.TSubExp;

  TXRegexp = class(TPerlRE)
  public
    function Replace(Pattern, Subst, Text:string; All :boolean = true) :string; overload;
    function Replace(Subst :string; All :boolean = true) :string;          overload;
  end;

var
  regex :TXRegexp = nil;

function Match(Pattern, Text :string) :boolean;
function Replace(Pattern, Subst, Text :string; All :boolean = true) :string;

implementation

function Match(Pattern, Text :string) :boolean;
begin
  Result := regex.Match(Pattern, Text);
end;

function Replace(Pattern, Subst, Text :string; All :boolean = true) :string;
begin
  Result := regex.Replace(Pattern, Subst, Text, True);
end;



{ TXRegexp }

function TXRegexp.Replace(Pattern, Subst, Text: string; All :boolean): string;
begin
  Self.Text    := Text;
  Self.RegExp  := Pattern;
  Result       := Self.Replace(Subst, All);
end;

function TXRegexp.Replace(Subst: string; All :boolean): string;
var
  p           :Integer;
  i           :Integer;
  Matched     :TSubExp;
  Replacement :string;
  Offset      :Integer;
begin
  Result := Self.Text;

  Offset := 0;
  while Match do
  begin
    Matched := SubExp[0];
    Replacement := '';
    p := 1;
    while p <= Length(Subst) do
    begin
      if Subst[p] <> '\' then
        Replacement := Replacement + Subst[p]
      else begin
        Inc(p);
        if not (Subst[p] in ['0'..'9']) then
          Replacement := Replacement + Subst[p]
        else
        begin
          i := StrToInt(Subst[p]);
          if i < SubExpCount then
            Replacement := Replacement + SubExp[i].Text;
        end;
      end;
      Inc(p);
    end;
    System.Delete(Result, Offset+Matched.StartP, Matched.Len);
    System.Insert(Replacement, Result, Offset+Matched.StartP);

    if not All then
      break;

    Offset := Length(Replacement) - Matched.Len;
  end;
end;

initialization
  regex := TXRegexp.Create;
  //with regex do
  //  Options := Options or PCRE_EXTENDED;
finalization
  regex.Free;
end.
