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
    @brief Collections: A Delphi port of the Java Collections library.

    @author Juancarlo Añez
    @version $Revision: 706 $
}

unit JalDebug;
interface
uses
    SysUtils,
    Windows,
    JalStdIO;

const
  rcs_id :string = '@(#)$Id: JalDebug.pas 706 2003-05-14 22:13:46Z hippoman $';

var
   debugging : boolean = false;

  procedure fatalError(msg :string);   overload;
  procedure fatalError(e :Exception);  overload;

  { do nothing, like in while WaistTime do NOP; }
  {$ifdef WIN32}
  procedure NOP;
  procedure debugger;
  {$else}
  procedure NOP; inline ( $90 );
  { make the debugger step in}
  procedure debug; inline ($CC);
  {$endif}

  procedure DebugMsg(msg :string);

  function DelphiRunning :Boolean;
  
type
 {$ifdef VER70}
   Exception = Pointer;
   EAssertionFailedClass = Pointer;
 {$else}
   {$ifdef VER100}
   EFailed = class (EAssertionFailed)
   {$else}
   {$ifdef VER110}
   EFailed = class (EAssertionFailed)
   {$else}
   EFailed = class (Exception)
   {$endif}
   {$endif}
      constructor Create; virtual;
   end;

   EAssertionFailedClass = class of EFailed;
   EFreeNilObject = class(EFailed);
   EInvalidFileName = class(EFailed);
{$endif}
  TAssertProc      = procedure( fact:Boolean; ExceptClass :EAssertionFailedClass);
  {$ifdef WIN32}pascal;{$endif}

  function ReturnAddr :Pointer;
  function ConvertAddr(Address: Pointer): Pointer;

  procedure AssertX(fact:Boolean; ExceptClass :EAssertionFailedClass);
 {$ifdef WIN32}pascal;{$endif}
  procedure AssertMsg(fact:Boolean; ExceptClass :EAssertionFailedClass; const msg :String);
 {$ifdef WIN32}pascal;{$endif}

const
    require :TAssertProc = AssertX;
    ensure  :TAssertProc = AssertX;

implementation

  procedure fatalError(msg :string);
  begin
     try
       writeln(stderr, msg);
     finally
       halt(999);
     end
  end;

  procedure fatalError(e :Exception);
  begin
     fatalError(e.Message);
  end;

{$ifndef VER70}
  constructor EFailed.Create;
  begin
       inherited Create(ClassName)
  end;

{$endif}

  {$ifdef WIN32}
  procedure NOP; assembler;
  asm
    nop
  end;
  procedure debugger; assembler;
  asm
    int 3
  end;
  {$endif}

  procedure DebugMsg(msg :string);
  begin
     if debugging then begin
        if DelphiRunning then
           OutputDebugString(PChar(msg))
        else
           writeln(stderr, msg)
     end
  end;


function ReturnAddr :Pointer; assembler;
const
  {$ifndef WIN32}
  FaultIP = $02;
  FaultCS = $04;
  {$else}
  FaultIP = $04;
  {$endif}
asm
   {$ifndef WIN32}
   mov   ax, [bp].FaultIP
   mov   dx, [bp].FaultCS
   {$else}
   mov   eax, [ebp].FaultIP
   {$endif}
end;

{ from VCL }
  function ConvertAddr(Address: Pointer): Pointer; assembler;
  asm
          TEST    EAX,EAX         { Always convert nil to nil }
          JE      @@1
          SUB     EAX, $1000      { offset from code start; code start set by linker to $1000 }
  @@1:
  end;

{$ifdef Win32}
{$WRITEABLECONST ON }
{$STACKFRAMES    ON } {need stack frames to find caller's address }
{$endif}
procedure AssertX(fact :Boolean; ExceptClass :EAssertionFailedClass);
const
  { place these two in the data segment. we're gonna pot the stack }
  exc          :Exception = nil;
  FaultAddress :Pointer   = nil;
begin
  if not fact then begin
  {$ifdef VER70}
     runError(201); {generate a RangeCheck error }
  {$else}
      if Assigned(ExceptClass) then
         exc := ExceptClass.Create
      else
         exc := EFailed.Create;
      { save the caller's return-to address}
      FaultAddress := ReturnAddr;
      { pop the stack frame so we don't fool the debugger with this long jump }
      {$ifdef WIN32}
      asm
         mov esp, ebp
         pop ebp
         add esp, 8
      end;
      {$else}
      asm
         mov sp, bp { undo the stack frame (same as "leave" ) }
         pop bp
         add sp, 6  { pop parameters and return address }
      end;
      {$endif}
      raise exc at FaultAddress;
  {$endif}
  end
end;


procedure AssertMsg(fact :Boolean; ExceptClass :EAssertionFailedClass; const msg :String);
const
   exc          :Exception = nil;
   FaultAddress :Pointer = nil;
begin
  if not fact then begin
   {$ifdef VER70}
     runError(201); {generate a RangeCheck error }
   {$else}
     if assigned(ExceptClass) then
        exc := ExceptClass.Create
     else
        exc := EFailed.Create;
     if msg <> '' then
        exc.Message := exc.Message+#13+msg;
     FaultAddress := ReturnAddr;
     { pop the stack frame so we don't fool the debugger with this long jump }
     {$ifdef WIN32}
     asm
        mov esp, ebp
        pop ebp
        add esp, 12
     end;
     {$else}
     asm
        mov sp, bp { undo the stack frame (same as "leave" ) }
        pop bp
        add sp, 10  { pop parameters and return address }
     end;
     {$endif}
     raise exc at FaultAddress;
   {$endif}
  end
end;

function DelphiRunning :Boolean;
var
   hwnd    :THandle;
   {$ifndef WIN32}
   SubWnds :TDelphiSubWnds;
   {$endif}
begin
     hwnd := FindWindow('TAppBuilder', nil);
     if (hwnd = 0) or not IsWindow(hwnd) then
        Result := False
     else begin
        {$ifdef WIN32}
          Result := True
        {$else}
          SubWnds := [];
          EnumChildWindows(hwnd, @EnumDelphiChildren, Longint(@SubWnds));
          Result := SubWnds >= AllSubWnds
        {$endif}
     end
end;

end.
