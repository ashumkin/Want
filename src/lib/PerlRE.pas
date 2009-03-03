(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 2001-2003 Juancarlo Anez, Caracas, Venezuela.              *
 * Copyright (c) 2008 Zapped                                                *
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

    @author Шумкин А. К.
}
unit PerlRE;

interface
uses
  SysUtils,
  JclSysUtils,
  RegExpr;

type
  TXRegexp = class(TRegExpr)
  private
    function GetSubExp(Index: Integer): string;
  public
    function ExMatch(const Pattern, Text: string): boolean;
    property SubExp[Index: Integer]: string read GetSubExp;
  end;

var
  regex :TXRegexp = nil;

function Match(Pattern: string; const Text: string) :boolean;
function Replace(const Pattern, Subst, Text :string; All :boolean = true) :string;

implementation

function Match(Pattern: string; const Text: string) :boolean;
begin
  if Pattern = '' then
    Pattern := '.*';
  Result := ExecRegExpr(Pattern, Text);
end;

function Replace(const Pattern, Subst, Text :string; All :boolean = true) :string;
var
  s: string;
  g: string;
begin
  // for backward compatibility
  // change $1 to \$1
  s := ReplaceRegExpr('(\$\d)', Subst, '\\$1', True);
  // change \1 to $1
  s := ReplaceRegExpr('\\\{?(\d)\}?', s, '${$1}', True);
  g := 'g';
  if not All then
    g := '-' + g;
  Result := ReplaceRegExpr('(?i' + g + ')' + Pattern, Text, s, True);
end;

{ TXRegexp }

function TXRegexp.GetSubExp(Index: Integer): string;
begin
  Result := Match[Index];
end;

function TXRegexp.ExMatch(const Pattern, Text: string): boolean;
begin
  Expression := Pattern;
  Result := Exec(Text);  
end;

initialization
  regex := TXRegexp.Create;
  //with regex do
  //  Options := Options or PCRE_EXTENDED;
finalization
  regex.Free;
end.
