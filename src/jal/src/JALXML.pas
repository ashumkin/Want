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
}

unit JALXML;

interface
uses
  SysUtils;


const
  rcs_id : string = '(#)$Id: JALXML.pas 706 2003-05-14 22:13:46Z hippoman $';

  XMLNameChars = ['a'..'z', 'A'..'Z', '_', ':'];
  XMLTokenChars = XMLNameChars + ['.', '0'..'9'];


function QuoteStr(s :WideString):WideString;
function XMLQuote(s :WideString; quoteWhiteSpace :Boolean) :WideString;
function XMLUnQuote(s :WideString) :WideString;

implementation

function MultiByte(c :char):WideString;
begin
    case Ord(c) and $F800 of
       0:
         Result := Chr(((Ord(c) shr 6) and $1F) or $C0) +
                   Chr((Ord(c) and $3F) or $80);
       $D800:
         assert(False)
    else
        Result :=
         Char(((Ord(c) shr 12) and $F) or $E0) +
         Chr((((Ord(c) shr 6)  and $3F) or $80)) +
         Chr(((Ord(c) and $3F) or $80));
    end
end;

function XMLQuote(s :WideString; quoteWhiteSpace :Boolean) :WideString;
var
  i      :Integer;
begin
    Result := s;
    for i := Length(Result) downto 1 do begin
       case s[i] of
           #10:
                if not quoteWhitespace then
                   Insert(#13, Result, i);
           '&': begin
                  Delete(Result, i, 1);
                  Insert('&amp;', Result, i)
                end;
           '<': begin
                  Delete(Result, i, 1);
                  Insert('&lt;', Result, i)
                end;
           '>': begin
                  Delete(Result, i, 1);
                  Insert('&gt;', Result, i)
                end;
           '"': begin
                  Delete(Result, i, 1);
                  Insert('&quot;', Result, i)
                end;
           #13: if quoteWhitespace then begin
                     Delete(Result, i, 1);
                     Insert('&#13;', Result, i)
                end;
           #9: if quoteWhitespace then begin
                   Delete(Result, i, 1);
                   Insert('&#9;', Result, i)
                end;
           #$80..#255: begin
                   Delete(Result, i, 1);
                   Insert('&#' + IntToStr(Ord(s[i])) + ';', Result, i)
                end
           else
                // do nothing
       end
    end;
end;

function QuoteStr(s :WideString):WideString;
begin
   Result := '"' + XMLQuote(s, False) + '"'
end;

function XMLUnQuote(s :WideString) :WideString;
var
  i, j, n :Integer;
  special :WideString;
  numeric :boolean;
  hex     :boolean;
begin
   i := 1;
   n := length(s);
   result := '';
   if n = 0 then
      Exit;
   if (s[1] = '''') or (s[1] = '"') then begin
      Inc(i);
      dec(n)
   end;
   while i <= n do begin
     j := i;
     while (j <= n) and (s[j] <> '&') do
        inc(j);
     result := result + copy(s, i, j-i);
     i := j+1;
     if i <= n then begin
         numeric := false;
         if s[j] = '#' then begin
           numeric := true;
           inc(j);
         end;
         while (j <= n) and (s[j] <> ';') do
               inc(j);
         if j = n then begin
            result := result + copy(s, i, 1+j-i);
            break
         end;
         hex := numeric and (j > i) and (j <= n) and (s[j-1] = 'x');
         special := copy(s, i, j-i);
         if numeric then begin
            if hex then
              result := result + Chr(StrToIntDef(special[1], 0)*16 or StrToIntDef(special[2], 0))
            else
              result := result + Chr(StrToIntDef(special, 0))
         end
         else if special = 'amp'then
            result := result + '&'
         else if special = 'lt'then
            result := result + '<'
         else if special = 'gt'then
            result := result + '>'
         else if special = 'quot'then
            result := result + '"'
         else begin
            result := result +'&';
            j := i;
         end;
         i := j+1
     end
   end
end;

(*
procedure writeSurrogatePair(c1, c2 :char);
var
  c :Integer;
begin
    assert(((c1 and $FC00) = $D800) and ((c2 and $FC00) = $DC00)));
    c := ((c1 and $3FF) << 10) or (c2 and $3FF);
    Inc(c, $10000);
    Write(Chr(Byte((((c shr 18) and $7) or $F0))));
    Write(Chr(Byte((((c shr 12) and $3F) or $80))));
    Write(Chr(Byte((((c shr 6) and $3F) or $80))));
    Write(Chr(Byte(((c and $3F) or $80))));
end;
*)

end.



