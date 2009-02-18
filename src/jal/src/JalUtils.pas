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

{
  crc32.c -- compute the CRC-32 of a data stream
  Copyright (C) 1995-1998 Mark Adler

  Pascal tranlastion
  Copyright (C) 1998 by Jacques Nomssi Nzali
Copyright (C) 1998,1999,2000 by Jacques Nomssi Nzali

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the author be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
}

unit JalUtils;
interface
uses
  SysUtils,
  Math,
	{$IFDEF VER130}
  JclMath,
	{$ENDIF VER130}

  JalPorting;




// from JclSysUtils
{$IFNDEF DELPHI5_UP}
procedure FreeAndNil(var Obj);
{$ENDIF DELPHI5_UP}

function FloatToInt(f :Double):Integer;
function FormatTime(T :TDateTime; millis :boolean = false):string;
function crc32 (crc : uLong; buf : pBytef; len : uInt): uLong;

implementation

{$IFNDEF DELPHI5_UP}

procedure FreeAndNil(var Obj);
var
  O: TObject;
begin
  O := TObject(Obj);
  Pointer(Obj) := nil;
  O.Free;
end;

{$ENDIF DELPHI5_UP}

function FloatToInt(f :Double):Integer;
begin
   asm
     FCLEX
   end;
   if f >= Maxint then
      Result := Maxint
   else if f <= -Maxint then
      Result := -Maxint
   else
      Result := Round(f)
end;

function FormatTime(T :TDateTime; millis :boolean):string;
var
  H, M, S, K :Word;
begin
   asm
     FCLEX  // Clear exceptions to cope with RTL bug in Trunc, Frac, Int, and Round
   end;
   if IsInfinite(T) then
      Result := 'FOREVER'
   else begin
      DecodeTime(Frac(T), H, M, S, K);
      if millis then
        Result := Format('%d:%2.2d:%2.2d.%3.3d', [FloatToInt(Int(T)*24)+H, M, S, K])
      else
        Result := Format('%d:%2.2d:%2.2d', [FloatToInt(Int(T)*24)+H, M, S, K])
   end
end;

{$IFDEF DYNAMIC_CRC_TABLE}

{local}
const
  crc_table_empty : boolean = TRUE;
{local}
var
  crc_table : array[0..256-1] of uLongf;

procedure make_crc_table;
var
 c    : uLong;
 n,k  : int;
 poly : uLong; { polynomial exclusive-or pattern }

const
 { terms of polynomial defining this crc (except x^32): }
 p: array [0..13] of Byte = (0,1,2,4,5,7,8,10,11,12,16,22,23,26);

begin
  { make exclusive-or pattern from polynomial ($EDB88320) }
  poly := Long(0);
  for n := 0 to (sizeof(p) div sizeof(Byte))-1 do
    poly := poly or (Long(1) shl (31 - p[n]));

  for n := 0 to 255 do
  begin
    c := uLong(n);
    for k := 0 to 7 do
    begin
      if (c and 1) <> 0 then
        c := poly xor (c shr 1)
      else
        c := (c shr 1);
    end;
    crc_table[n] := c;
  end;
  crc_table_empty := FALSE;
end;

{$ELSE}

const
  crc_table : array[0..256-1] of uLongf = (
  $00000000, $77073096, $ee0e612c, $990951ba, $076dc419,
  $706af48f, $e963a535, $9e6495a3, $0edb8832, $79dcb8a4,
  $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd, $e7b82d07,
  $90bf1d91, $1db71064, $6ab020f2, $f3b97148, $84be41de,
  $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7, $136c9856,
  $646ba8c0, $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9,
  $fa0f3d63, $8d080df5, $3b6e20c8, $4c69105e, $d56041e4,
  $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b,
  $35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940, $32d86ce3,
  $45df5c75, $dcd60dcf, $abd13d59, $26d930ac, $51de003a,
  $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599,
  $b8bda50f, $2802b89e, $5f058808, $c60cd9b2, $b10be924,
  $2f6f7c87, $58684c11, $c1611dab, $b6662d3d, $76dc4190,
  $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f,
  $9fbfe4a5, $e8b8d433, $7807c9a2, $0f00f934, $9609a88e,
  $e10e9818, $7f6a0dbb, $086d3d2d, $91646c97, $e6635c01,
  $6b6b51f4, $1c6c6162, $856530d8, $f262004e, $6c0695ed,
  $1b01a57b, $8208f4c1, $f50fc457, $65b0d9c6, $12b7e950,
  $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3,
  $fbd44c65, $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2,
  $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb, $4369e96a,
  $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5,
  $aa0a4c5f, $dd0d7cc9, $5005713c, $270241aa, $be0b1010,
  $c90c2086, $5768b525, $206f85b3, $b966d409, $ce61e49f,
  $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17,
  $2eb40d81, $b7bd5c3b, $c0ba6cad, $edb88320, $9abfb3b6,
  $03b6e20c, $74b1d29a, $ead54739, $9dd277af, $04db2615,
  $73dc1683, $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8,
  $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1, $f00f9344,
  $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb,
  $196c3671, $6e6b06e7, $fed41b76, $89d32be0, $10da7a5a,
  $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5,
  $d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1,
  $a6bc5767, $3fb506dd, $48b2364b, $d80d2bda, $af0a1b4c,
  $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef,
  $4669be79, $cb61b38c, $bc66831a, $256fd2a0, $5268e236,
  $cc0c7795, $bb0b4703, $220216b9, $5505262f, $c5ba3bbe,
  $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7, $b5d0cf31,
  $2cd99e8b, $5bdeae1d, $9b64c2b0, $ec63f226, $756aa39c,
  $026d930a, $9c0906a9, $eb0e363f, $72076785, $05005713,
  $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38, $92d28e9b,
  $e5d5be0d, $7cdcefb7, $0bdbdf21, $86d3d2d4, $f1d4e242,
  $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1,
  $18b74777, $88085ae6, $ff0f6a70, $66063bca, $11010b5c,
  $8f659eff, $f862ae69, $616bffd3, $166ccf45, $a00ae278,
  $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7,
  $4969474d, $3e6e77db, $aed16a4a, $d9d65adc, $40df0b66,
  $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9,
  $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605,
  $cdd70693, $54de5729, $23d967bf, $b3667a2e, $c4614ab8,
  $5d681b02, $2a6f2b94, $b40bbe37, $c30c8ea1, $5a05df1b,
  $2d02ef8d);

{$ENDIF}

function crc32 (crc : uLong; buf : pBytef; len : uInt): uLong;
begin
  if (buf = nil) then
    crc32 := Long(0)
  else
  begin

{$IFDEF DYNAMIC_CRC_TABLE}
    if crc_table_empty then
      make_crc_table;
{$ENDIF}

    crc := crc xor uLong($ffffffff);
    while (len >= 8) do
    begin
      {DO8(buf)}
      crc := crc_table[(crc xor buf^) and $ff] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(crc xor buf^) and $ff] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(crc xor buf^) and $ff] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(crc xor buf^) and $ff] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(crc xor buf^) and $ff] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(crc xor buf^) and $ff] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(crc xor buf^) and $ff] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(crc xor buf^) and $ff] xor (crc shr 8);
      inc(buf);

      Dec(len, 8);
    end;
    if (len <> 0) then
    repeat
      {DO1(buf)}
      crc := crc_table[(crc xor buf^) and $ff] xor (crc shr 8);
      inc(buf);

      Dec(len);
    until (len = 0);
    crc32 := crc xor uLong($ffffffff);
  end;
end;

end.