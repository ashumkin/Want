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

    @author Juanco Añez
}

unit TestDXFParse;

interface
uses
  TestFramework,

  JalStrings,

  JalDXF;

type
  TDXFParseTests = class(TTestCase)
  protected
    _parser :TDXFParser;
    
    procedure SetUp;    override;
    procedure TearDown; override;
  published
    procedure TestParse;
  end;

implementation

{ TDXFParseTests }

procedure TDXFParseTests.SetUp;
begin
  inherited SetUp;
  _parser := TDXFParser.Create;
end;

procedure TDXFParseTests.TearDown;
begin
  _parser.Free;
  _parser := nil;
  inherited TearDown;
end;

procedure TDXFParseTests.TestParse;
begin
  _parser.parse(FileToString('c:\home\studies\may\REDUTM.dxf'));
end;

initialization
  RegisterTest(TDXFParseTests.Suite);
end.
