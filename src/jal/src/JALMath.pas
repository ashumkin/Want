{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{                                              }
{   \\\                                        }
{  -(j)-                                       }
{    /juanca ®                                 }
{    ~                                         }
{  Copyright © 1995-2002 Juancarlo Añez        }
{  http://www.suigeneris.org/juanca            }
{  All rights reserved.                        }
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

{#(@)$Id: JALMath.pas 771 2004-05-08 16:15:25Z juanco $}

unit JALMath;
interface
uses
  Math,
  SysUtils;

{ Coprocessor control word bits }
type
  TEM87ControlWordBits = (
     f87InvalidOperand,       { $0001 }
     f87DenormalOperand,      { $0002 }
     f87DivideByZero,         { $0004 }
     f87Overflow,             { $0008 }
     f87Underflow,            { $0010 }
     f87Inexact,              { $0020 }
     f87NotEmulated1,         { $0040 }
     f87NotEmulated2,         { $0080 }
     f87PrecisionLo,          { $0100 }
     f87PrecisionHi,          { $0200 }
     f87RoundDown,            { $0400 }
     f87RoundUp,              { $0800 }
     f87AffineInfinity        { $1000 }
  );
  TEM87ControlWord = set of TEM87ControlWordBits;

  const
  f87Chop        :TEM87ControlWord = [f87RoundDown,f87RoundUp];
  f87Precision64 = [f87PrecisionLo, f87PrecisionHi];
  f87Precision53 = [f87PrecisionHi];
  f87Precision24 = [f87PrecisionLo];

type
  TEM87Exception = (
     e87OK,                   { $0000 }
     e87InvalidOperand,       { $0001 }
     e87DenormalOperand,      { $0002 }
     e87DivideByZero,         { $0004 }
     e87Overflow,             { $0008 }
     e87Underflow,            { $0010 }
     e87Inexact,              { $0020 }
     e87NotEmulated,          { $0040 }
     e87SqrtNegative,         { $0080 }
     e87StackOverFlow,        { $0100 }
     e87StackUnderflow,       { $0200 }
     e87ExplicitRaise         { $0400 }
  );

EFloatingPointException            = EMathError;
TFloatingPointExceptionClass       = class of EFloatingPointException;

EFloatingPointInvalidOperand       = EInvalidOp;
EFloatingPointDenormalOperand      = class(EFloatingPointException);
EFloatingPointDivideByZero         = EZeroDivide;
EFloatingPointOverflow             = EOverflow;
EFloatingPointUnderflow            = EUnderflow;
EFloatingPointPrecision            = class(EFloatingPointException);
EFloatingPointNotEmulated          = class(EFloatingPointException);
EFloatingPointSqrtNegative         = class(EFloatingPointException);
EFloatingPointStackOverFlow        = class(EFloatingPointException);
EFloatingPointStackUnderflow       = class(EFloatingPointException);
EFloatingPointExplicitRaise        = class(EFloatingPointException);


const
   EM87ExceptionClasses : array[TEM87Exception] of TFloatingPointExceptionClass =
   ( nil,
     EFloatingPointInvalidOperand,
     EFloatingPointDenormalOperand,
     EFloatingPointDivideByZero,
     EFloatingPointOverflow,
     EFloatingPointUnderflow,
     EFloatingPointPrecision,
     EFloatingPointNotEmulated,
     EFloatingPointSqrtNegative,
     EFloatingPointStackOverFlow,
     EFloatingPointStackUnderflow,
     EFloatingPointExplicitRaise
   );



CONST
 iee_BitsInSingle   = 8*sizeOf(Single);
 iee_BitsInDouble   = 8*sizeOf(Double);
 iee_BitsInExtended = 8*sizeOf(Extended);

 iee_BitsInSExp     =  8;
 iee_BitsInDExp     = 11;
 iee_BitsInEExp     = 15;

TYPE
 TBitSetForSingle   = set of 0..iee_BitsInSingle-1;
 tBitSetForDouble   = set of 0..iee_BitsInDouble-1;
 tBitSetForExtended = set of 0..iee_BitsInExtended-1;

CONST
 IEE_SINGLE_INF_BITS   :  TBitSetForSingle   = [23..iee_BitsInSingle-2];
 IEE_DOUBLE_INF_BITS   :  TBitSetForDouble   = [53..iee_BitsInDouble-2];
 IEE_EXTENDED_INF_BITS :  TBitSetForExtended = [64..iee_BitsInExtended-2];

 IEE_SINGLE_NAN_BITS   :  TBitSetForSingle   = [0..iee_BitsInSingle-2];
 IEE_DOUBLE_NAN_BITS   :  TBitSetForDouble   = [0..iee_BitsInDouble-2];
 IEE_EXTENDED_NAN_BITS :  TBitSetForExtended = [0..iee_BitsInExtended-2];

function INF :Single;
function NAN :Single;

function IsNAN(f :Extended):Boolean;

function EM87GetControlWord:TEM87ControlWord;
function EM87SetControlWord(newCW :TEM87ControlWord):TEM87ControlWord;


function atan2(x, y :Extended):Extended;

function FloatToInt(f :Double):Integer;
function StrIsNumber(s :string; ExpAllowed :Boolean):Boolean;
function StrToFloatDef(const s :string; Default :Extended) :Extended;
function StrToFloatStd(const s:string):double;
{function EM87Frac(x :Extended)  :Extended;}
{function Trunc(x :Extended) :Integer; pascal;}

implementation
var
  { representations of special numbers }
  _INF :Single absolute IEE_SINGLE_INF_BITS;
  _NAN :Single absolute IEE_SINGLE_NAN_BITS;


function INF :Single;
begin
     Result := _INF
end;

function NAN :Single;
begin
     Result := _NAN
end;

{ I'm not too sure about this routine.  How do you check for a NAN? }
function IsNAN(f :Extended):Boolean;
 var
   b :tBitSetForExtended absolute f;
 begin
   isNAN := (IEE_EXTENDED_INF_BITS <= b) and not (b <= IEE_EXTENDED_NAN_BITS);
 end;

function EM87GetControlWord:TEM87ControlWord;
begin
  Result := TEM87ControlWord(Default8087CW)
end;

function EM87SetControlWord(newCW :TEM87ControlWord):TEM87ControlWord;
begin
   Result    := EM87GetControlWord;
   System.Set8087CW(Word(NewCW))
end;


function atan2(x, y :Extended):Extended;
begin
  if x = 0.0 then
  begin
    if y >= 0.0 then
      Result := pi/2
    else
      Result := -pi/2;
  end
  else if x > 0.0 then
    Result := arctan(y/x)
  else if y >= 0.0 then
    Result := arctan(y/x)+pi
  else
    Result := arctan(y/x)-pi;
end;

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

function StrToFloatDef(const s :string; Default :Extended) :Extended;
begin
   if not StrIsNumber(s, True) then
      Result := Default
   else
      Result := StrToFloatStd(s)
end;

function StrToFloatStd(const s:string):double;
var
  ts  :string;
  pct :boolean;
begin
  asm
    FCLEX  //!!! Clear exceptions to cope with RTL bug in Trunc, Frac, Int, and Round
    FWAIT
  end;
  ts := UpperCase(Trim(s));
  if Length(ts) = 0 then begin
     Result := 0;
     EXIT
  end;
  pct := False;
  if ts[Length(ts)] = '%' then begin
     pct := true;
     Delete(ts, Length(ts), 1);
  end;
  if ts = 'INF' then
    Result := INF
  else if ts = '-INF' then
    Result := -INF
  else if StrIsNumber(ts, True) then
    try
       Result := SysUtils.StrToFloat(ts)
    except
       Result := NAN
    end
  else
    Result := NAN;
  if pct then
     Result := Result / 100
end;

function StrIsNumber(s :string; ExpAllowed :Boolean):Boolean;
var
 i           :Integer;
 DecimalSeen :Boolean;
 ThousandPos :Integer;
begin
  Result       := False;
  DecimalSeen  := False;
  ThousandPos  := 0;
  i            :=  1;
  if S <> '' then begin
     if s[Length(s)] = '%' then begin
        s := copy(s, 1, Length(s)-1);
        if Length(s) = 0 then
           EXIT;
     end;
     if not (S[i] in ['-','+','0'..'9']) then begin
       if S[i] = DecimalSeparator then begin
         DecimalSeen := True;
         Inc(i)
       end
       else
         Exit
     end
     else
       Inc(i);

     { initial set of numbers }
     while (i <= Length(s)) and (s[i] in ['0'..'9', ThousandSeparator]) do begin
         if (S[i] = ThousandSeparator) then begin
            if DecimalSeen then
               Exit;
            ThousandPos := i
         end;
        Inc(i)
     end;

     if (i <= Length(S)) and (S[i] = DecimalSeparator) then begin
         Inc(i);
         if DecimalSeen then
           Exit {FALSE - Only one decimal separator allowed }
         else begin
            { no thousands separator here }
            while (i <= Length(s)) and (s[i] in ['0'..'9']) do
              Inc(i)
         end;
     end;
     if (ThousandPos = 0) or ((i-ThousandPos) >= 3) then begin
        if (i > Length(S)) then
            Result := True
        else if (S[i] in ['e','E']) then
           if ExpAllowed then
              Result := StrIsNumber(Copy(s,i+1, Length(s)), False)
           else
              Result := False
        else
            Result := False
     end
  end
end;


end.






