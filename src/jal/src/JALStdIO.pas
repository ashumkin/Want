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

unit JALStdIO;
interface
uses
   SysUtils,
   Windows;
var
   StdConsoleIn  :THandle = 0;
   StdConsoleOut :THandle = 0;
   StdConsoleErr :THandle = 0;

   STDIN  :Text absolute Input;
   STDOUT :Text absolute Output;
   STDERR :Text;

implementation

initialization
   StdConsoleIn  := GetStdHandle(STD_INPUT_HANDLE);
   StdConsoleOut := GetStdHandle(STD_OUTPUT_HANDLE);
   StdConsoleErr := GetStdHandle(STD_ERROR_HANDLE);

   if IsConsole then 
   begin
       Assign(STDERR, '');
       Rewrite(STDERR);
       TTextRec(STDERR).Handle := StdConsoleErr;

       Assign(Input,'');
       Reset(Input);
       TTextRec(Input).Handle := StdConsoleIn;

       Assign(Output, '');
       Rewrite(Output);
       TTextRec(Output).Handle := StdConsoleOut
   end;
finalization
   if IsConsole then 
   begin
     Flush(StdErr);
     Flush(Output);
     Flush(Input);
   end;
end.

