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

unit JALExpressions;

interface
uses
  SysUtils,
  Math,

  JALMath,
  JALParse;

type
  EExpressionError = class(Exception);
  ExpressionValue  = Extended;

  TExpressionParser = class(TParser)
  protected
    function expression  : ExpressionValue;
    function term        : ExpressionValue;
    function factor      : ExpressionValue;
    function signedValue : ExpressionValue;
    function value       : ExpressionValue;
    function simpleValue : ExpressionValue;
    function exponent    : ExpressionValue;
    function functionEval: ExpressionValue;
  public
    function evaluate(expre :WideString): ExpressionValue;
  end;

  function evaluate(expre :WideString): ExpressionValue;

implementation

var
  __parser :TExpressionParser = nil;

function evaluate(expre :WideString): ExpressionValue;
begin
  if __parser = nil then
    __parser := TExpressionParser.Create;
  Result := __parser.evaluate(expre);
end;


{ TExpressionParser }

function TExpressionParser.evaluate(expre: WideString): ExpressionValue;
begin
  setText(expre);
  try
    Result := expression;
  except
    on e :Exception do
      raise EExpressionError.CreateFmt('at %d %s', [getColumnNumber, e.Message]);
  end;
  if currentChar <> eofch then
    raise EExpressionError.CreateFmt('unexpected character in expression at pos %d: %s',
                                     [getColumnNumber, currentChar]
                                     );
end;

function TExpressionParser.expression: ExpressionValue;
begin
  Result := term;
  repeat
    skipSpaces;
    case currentChar of
      '+'   : begin skip; Result := Result + term; end;
      '-'   : begin skip; Result := Result - term; end;
    else
      break;
    end;
  until false;
end;

function TExpressionParser.term: ExpressionValue;
begin
  Result := factor;
  repeat
    skipSpaces;
    case currentChar of
      '*' : begin skip; Result := Result * factor; end;
      '/' : begin skip; Result := Result / factor; end;
    else
      break;
    end;
  until false;
end;

function TExpressionParser.factor: ExpressionValue;
begin
  Result := signedValue;
  repeat
    skipSpaces;
    case currentChar of
      '^' : begin skip; Result := Power(Result, signedValue); end;
    else
      break;
    end;
  until false;
end;

function TExpressionParser.signedValue: ExpressionValue;
var
  negate :boolean;
begin
  skipSpaces;
  negate := false;
  while (currentChar = '+') or (currentChar = '-') do
  begin
    if currentChar = '-' then
      negate := not negate;
    skip;
    skipSpaces;
  end;
  Result := value;
  if negate then
    Result := -Result;
end;

function TExpressionParser.value: ExpressionValue;
begin
  skipSpaces;
  if isNameStartChar(currentChar) then
    Result := functionEval
  else if currentChar = '(' then
  begin
    skip;
    Result := expression;
    skipSpaces;
    check(')');
  end
  else
  begin
    Result := simpleValue;
    if (currentChar = 'e') or (currentChar = 'E') then
    begin
      skip;
      Result := Result * power(10, exponent);
    end;
  end;
end;

function TExpressionParser.simpleValue: ExpressionValue;
var
  num :WideString;
begin
  num := number;
  if currentChar = '.' then
  begin
    skip;
    num := num + '.' + number;
  end;
  Result := StrToFloat(num);
end;

function TExpressionParser.exponent: ExpressionValue;
var
  negate : boolean;
begin
  negate := false;
  while (currentChar = '+') or (currentChar = '-') do
  begin
    if currentChar = '-' then
      negate := true;
    skip;
  end;
  Result := simpleValue;
  if negate then
    Result := -Result;
end;



function TExpressionParser.functionEval: ExpressionValue;
var
  fn    :WideString;
  arg   :ExpressionValue;
begin
  fn := name;
  arg := value;
  if fn = 'ln' then
    Result := ln(arg)
  else if fn = 'exp' then
    Result := exp(arg)
  else
    raise EExpressionError.CreateFmt('unknown function at pos %d: %s',
                                     [getColumnNumber, fn]
                                     );
end;


initialization
finalization
  __parser.Free;
end.
