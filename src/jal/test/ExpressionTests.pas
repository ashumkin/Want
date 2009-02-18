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

unit ExpressionTests;

interface
uses
  TestFramework,

  JalMath,
  JALExpressions;

type
  TExpressionTests = class(TTestCase)
  protected
    FExpreParser :TExpressionParser;

    function eval(expre :string) :Extended;
  published
    procedure SimpleExpressions;
    procedure Terms;
    procedure Factors;
    procedure Associativity;
    procedure Functions;
    procedure ComplexExpressions;
    procedure Errors;
  end;

implementation

{ TExpressionTests }

function TExpressionTests.eval(expre: string): Extended;
begin
  Result := JALExpressions.evaluate(expre);
end;

procedure TExpressionTests.SimpleExpressions;
begin
  checkEquals(    1,  eval(' 1'),    0);
  checkEquals(   -1,  eval('-1'),    0);

  checkEquals(    1,  eval(' 1.0'),  0);
  checkEquals(   -1,  eval('-1.0'),  0);

  checkEquals(    1,  eval(' 1.0e0'),  0);
  checkEquals(   -1,  eval('-1.0e0'),  0);

  checkEquals(   10,  eval(' 1.0e+1'),  0);
  checkEquals( -0.1,  eval('-1.0e-1'),  0);

  checkEquals(    1,  eval('- - 1'),    0);
  checkEquals(    1,  eval('(1)'),    0);
  checkEquals(   -1,  eval('( - 1)'),    0);
  checkEquals(    1,  eval('( - - 1)'),    0);
  checkEquals(   -1,  eval('-(1)'),    0);

  checkEquals(   1,  eval('2^0'),  0);
  checkEquals(   2,  eval('2^1'),  0);
  checkEquals(   4,  eval('2^2'),  0);
  checkEquals( 0.5,  eval('2^-1'),  0);
  checkEquals(   2,  eval('4^0.5'),  0);
  checkEquals( 0.5,  eval('4^-0.5'),  0);
end;

procedure TExpressionTests.Terms;
begin
  checkEquals(  0,    eval('0 + 0'),    0);
  checkEquals(  1,    eval('0 + 1'),    0);
  checkEquals(  1,    eval('1 + 0'),    0);
  checkEquals(  2,    eval('1+1'),      0);
  checkEquals(  2,    eval(' 3 - 1'),    0);
  checkEquals(  0.2,  eval(' 0.1 + 0.1'),    0.01);
  checkEquals(  0.2,  eval(' 0.3 - 0.1'),    0.01);
end;

procedure TExpressionTests.Factors;
begin
  checkEquals(  0,    eval('0 * 0'),    0);
  checkEquals(  0,    eval('1 * 0'),    0);
  checkEquals(  0,    eval('0 * 1'),    0);
  checkEquals(  1,    eval('1 * 1'),    0);
  checkEquals(  3,    eval('1 * 3'),    0);
  checkEquals(  0.333,  eval('1 / 3'),    0.0005);
end;

procedure TExpressionTests.Associativity;
begin
  checkEquals(  0,    eval(' 3 - 1 - 1 - 1'),    0);
  checkEquals(  0,    eval(' 2 + 1 - 1 - 1 - 1'),    0);
  checkEquals(  3.5,  eval(' 1.5 +  1.5 +  0.5'),    0);

  checkEquals(  21,  eval(' 2*3 + 3*5'),    0);

  checkEquals(  3,  eval(' 2 * 3 / 2'),    0);

  checkEquals(  9,  eval(' 9 / 3 * 3'),    0);
  checkEquals(  1,  eval(' 9 / (3 * 3)'),    0);
end;

procedure TExpressionTests.Functions;
begin
  checkEquals(  1,  eval('exp 0'),    0);
  checkEquals(  1,  eval('exp (0)'),    0);
  checkEquals(  1,  eval('exp(0)'),    0);

  checkEquals(  0,  eval('ln  1'),    0);
  checkEquals(  0,  eval('ln (1)'),    0);
  checkEquals(  0,  eval('ln (1)'),    0);

  checkEquals( -1,  eval('- ln  exp 1'),    0);
  checkEquals( -1,  eval('- ln (exp 1)'),    0);
end;

procedure TExpressionTests.ComplexExpressions;
begin
  checkEquals( $F,  eval('2^3 + 2^2 + 2^1 + 1'),    0);
  checkEquals(  1,  eval('123.456e-1^4.8^(1/4.8)/123.456e-1'),    0);
end;

procedure TExpressionTests.Errors;
begin
  ExpectedException := EExpressionError;
  checkEquals(0, eval('###'), 0);

  ExpectedException := EExpressionError;
  checkEquals(0, eval('e1'), 0);

  ExpectedException := EExpressionError;
  checkEquals(0, eval('1e--1'), 0);

  ExpectedException := EExpressionError;
  checkEquals(0, eval('1)'), 0);
end;

initialization
  RegisterTests('', [TExpressionTests.Suite]);
end.
