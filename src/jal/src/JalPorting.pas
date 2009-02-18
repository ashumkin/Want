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

unit JalPorting;

interface

const
   {$IFDEF WIN32}
   MaxInt2 = Longint($7FFF);
   MaxInt4 = MaxInt;
   {$ELSE}
   MaxInt2 = MaxInt;
   MaxInt4 = MaxLong;
   {$ENDIF}

   MaxSmallInt = High(SmallInt);
   SmallIntNext = Longint(MaxSmallInt)+1;

type
     TINTEGER4 = Longint;
     TINTEGER2 = SmallInt;
     TLOGICAL1 = ByteBool;
     TWORD2    = Word;
     TWORD4    = LongWord;
     TINTEGER1 = ShortInt;

     TREAL4    = Single;
     TREAL8    = DOUBLE;

     TINTEGER  = TINTEGER4;
     INTEGER2  = TINTEGER2;
     INTEGER4  = TINTEGER4;
     WORD2     = TWORD2;
     WORD4     = TWORD4;
     REAL4     = TREAL4;
     REAL8     = TREAL8;

     sInt      = INTEGER2;
     uInt      = WORD2;
     Long      = INTEGER4;
     uLong     = WORD4;
     uLongf    = uLong;
     Bytef     = Byte;
     PBytef    = ^Bytef;

{$ifndef VER120}
type
  LongWord = Longint;
{$endif}

function OverflowedSmallIntToInt(s :SmallInt):Integer;

implementation

function OverflowedSmallIntToInt(s :SmallInt):Integer;
begin
  if (s >= 0) then
     Result := s
  else
     Result := (2*SmallIntNext) + s
end;

end.

