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

unit JalParse;
interface
uses
  SysUtils,
  Math,
  JalMessages;

const
  eofch = #0;

type
  EParseException = class(Exception);

  TParser = class(TInterfacedObject)
  public
    constructor Create; overload;
    destructor  Destroy; override;

    procedure parse (text :string); overload;
    procedure parse; overload; virtual;

    function getColumnNumber: Integer;
    function getLineNumber: Integer;

  protected
    buffer_           :string;
    position_         :Integer;
    markIndex_        :Integer;
    marks_            :array of integer;
    line_             :Integer;
    column_           :Integer;
    currentChar       :Char;

    size_             :Integer;
    percentSize       :Integer;
    percentCounter    :Integer;

    procedure setText(text :string);

    procedure warning(msg :string);
    procedure error(const msg :string; const args :array of const); overload;
    procedure error(const msg :string); overload;
    procedure fatalError(msg :string);

    function eof : boolean;
    function eol : boolean;
    function toEOL: string;

    procedure skip;                            overload;
    procedure skip(n:Integer);                 overload;

    function  isSpace(c :Char) : boolean;  virtual;
    function  skipSpaces(skipEOL :boolean = true) :boolean;
    function  skipSpacesToEOL : boolean;
    function  space(skipEOL :boolean = true):boolean;


    function  peek(n :Integer = 1):Char;   overload;
    function  peek(s :string):boolean;     overload;

    function  scanChar :Char;
    function  scan(s :string):boolean;
    procedure check(ruleNo :Integer; s :string); overload;
    procedure check(s :string);                 overload;

    procedure mark;
    procedure unmark;
    function  markedText: string;
    function  markedTextLength :Integer;

    function  nextChar: Char;

    function  name :string;
    function  scanName :boolean;
    function  isNameChar(c: Char): boolean;          virtual;
    function  isNameStartChar(c: Char): boolean;     virtual;

    function  number :string;
    function  scanNumber :boolean;
    function  isNumberChar(c :Char):boolean;        virtual;
    function  isNumberStartChar(c :Char):boolean;    virtual;

    function  quote: Char;                         virtual;
    function  comment: boolean;                        virtual;

    function int :Integer;

    procedure SayStatus; virtual;
  end;

implementation


{ TParser }

constructor TParser.Create;
begin
   inherited Create;
   markIndex_        := -1;
end;

destructor TParser.Destroy;
begin
  inherited Destroy;
end;

procedure TParser.warning(msg: string);
begin
end;

procedure TParser.error(const msg :string);
begin
  raise EParseException.Create(Format('(%d:%d): %s', [line_, column_, msg]));
end;

procedure TParser.error(const msg :string; const args :array of const);
begin
  error(Format(msg, args));
end;

procedure TParser.fatalError(msg: string);
begin
end;

function TParser.nextChar : Char;
begin
  skip;
  result := currentChar;
end;

function TParser.peek(n: Integer): Char;
begin
  if (position_ + n) <= size_ then
     result := buffer_[position_ + n]
  else
     result := eofch
end;

function TParser.peek(s: string): boolean;
var
  i :Integer;
begin
  result := true;
  for i := 1 to length(s) do begin
      if s[i] <> peek(i-1) then begin
         result := false;
         break
      end
  end
end;

function TParser.scanChar: Char;
begin
  Result := currentChar;
  skip;
end;

function TParser.scan(s: string): boolean;
begin
   result := peek(s);
   if result then
      skip(length(s))
end;

procedure TParser.check(ruleNo :Integer; s: string);
begin
     if not scan(s) then
        error(format('[%d] Expected %s', [ruleNo, s]))
end;

procedure TParser.check(s: string);
begin
   if not scan(s) then
      error(format('Expected %s', [s]))
end;

procedure TParser.mark;
begin
  inc(markIndex_);
  if markIndex_ >= length(marks_) then
    setLength(marks_, length(marks_)+1);
  marks_[markIndex_] := position_
end;

procedure TParser.unmark;
begin
  assert(markIndex_ >= 0);
  dec(markIndex_);
end;

function TParser.markedText :string;
begin
   result := copy(buffer_, marks_[markIndex_], markedTextLength);
   unmark;
end;

function TParser.markedTextLength: Integer;
begin
   if markIndex_ < 0 then
     result := 0
   else
     result := position_ - marks_[markIndex_]
end;

procedure TParser.skip(n :Integer);
begin
  while not eof and (n > 0) do
  begin
    skip;
    Dec(n);
  end;
end;

procedure TParser.skip;
begin
  if (position_ > 0) then
  begin
    if buffer_[position_] = #$A then begin
       inc(line_);
       column_ := 1
    end
    else
       inc(column_);
  end;
  inc(position_);
  if position_ <= size_ then
    currentChar := buffer_[position_]
  else
  begin
    currentChar := eofch;
    JalMessages.clearStatus; 
  end;

  Dec(percentCounter);
  if percentCounter = 0 then
  begin
    SayStatus;
    percentCounter := percentSize;
  end;
end;

function TParser.isSpace(c: Char): boolean;
begin
  case c of
     #$20, #$9, #$D, #$A:
       Result := True;
  else
    Result := False;
  end;
end;

function TParser.space(skipEOL :boolean = true) :boolean;
begin
  Result := false;
  if isSpace(currentChar) then
    Result := skipSpaces(skipEOL)
  else
    error('Space expected');
end;

function TParser.skipSpaces(skipEOL :boolean):boolean;
begin
  while isSpace(currentChar)
  and (skipEOL or ((currentChar <> #13) and (currentChar <> #10))) do
    skip;
  Result := (currentChar = #13) or (currentChar = #10);
end;

function TParser.skipSpacesToEOL: boolean;
begin
  skipSpaces(false);
  Result := eol;
end;

function TParser.isNameChar(c :Char) :boolean;
begin
     case c of
        'a'..'z', 'A'..'Z',      // letter
        '0'..'9',                // digit
        '.', '-', '_', ':':      //
                                 // combiningChar
                                 // extender
            result := true
     else
        result := false
     end
end;


function TParser.isNameStartChar(c :Char) : boolean;
begin
     case c of
        'a'..'z', 'A'..'Z',
        '_', ':':
            result := true
     else
        result := false
     end;
end;

function TParser.name :string;
begin
     mark;
     if not scanName then
        error('expected name');
     result := markedText
end;

function TParser.scanName: boolean;
begin
   if not isNameStartChar(currentChar) then
      result := false
   else begin
       repeat
          skip
       until not isNameChar(currentChar);
       result := true
   end
end;

function TParser.quote : Char;
begin
   result := currentChar;
   case result of
      '"', '''':
          skip
   else
      error('[9] '', or " expected')
   end
end;

function TParser.comment :boolean;
begin
  result := false;
end;

function TParser.getColumnNumber: Integer;
begin
     result := self.column_
end;

function TParser.getLineNumber: Integer;
begin
     result := self.line_
end;

procedure TParser.setText(text: string);
begin
   buffer_   := text;
   position_ := 0;
   column_   := 1;
   line_     := 1;
   size_     := length(buffer_);

   percentSize := Max(1, size_ div 100);
   percentCounter := percentSize;

   nextChar;
end;

procedure TParser.parse(text :string);
begin
   setText(text);
   parse;
end;


procedure TParser.parse;
begin

end;

function TParser.int :Integer;
begin
  skipSpaces;
  Result := 0;
  while Char(currentChar) in ['0'..'9'] do
  begin
    Result := Result * 10 + Ord(currentChar) - Ord('0');
    nextChar;
  end;
end;

function TParser.eof: boolean;
begin
  Result := position_ > size_;
end;

function TParser.eol: boolean;
begin
  Result := true;
  if eof then
    // do nothing
  else if (currentChar = #10) then
    skip
  else if (currentChar = #13) then
  begin
    skip;
    if (currentChar = #10) then
      skip;
  end
  else
    Result := false;
end;

function TParser.toEOL: string;
var
  i, j :Integer;
begin
  i := position_;
  j := i;
  while not eol do
  begin
    Inc(j);
    nextChar;
  end;
  Result := Copy(buffer_, i, j-i);
end;


function TParser.isNumberStartChar(c: Char): boolean;
begin
  Result := isNumberChar(c);
end;

function TParser.isNumberChar(c: Char): boolean;
begin
  case c of
    '0'..'9':
        result := true;
  else
    result := false;
  end;
end;

function TParser.number: string;
begin
   mark;
   if not scanNumber then
      error('expected number');
   result := markedText
end;

function TParser.scanNumber: boolean;
begin
   if not isNumberStartChar(currentChar) then
      result := false
   else begin
       repeat
          skip
       until not isNumberChar(currentChar);
       result := true
   end
end;

procedure TParser.SayStatus;
begin
  JalMessages.progress(position_/size_);
end;

end.

