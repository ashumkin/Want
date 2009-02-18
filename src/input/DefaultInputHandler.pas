(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 2001-2003 Juancarlo Anez, Caracas, Venezuela.              *
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
    @author Radim Novotny
}
unit DefaultInputHandler;

interface

uses
  InputRequest, InputHandler;

type
  TDefaultInputHandler = class(TInterfacedObject, IInputHandler)
  protected
    function GetInputStream: string;
  public
    procedure handleInput(aRequest: TInputRequest; bANSI: boolean);
  end;

implementation

uses
  SysUtils,
  MultipleChoiceInputRequest,
  WantClasses;

{ TDefaultInputHandler }

function TDefaultInputHandler.GetInputStream: string;
var
  istr: string;
begin
  readln(istr);
  Result := istr;
end;

procedure TDefaultInputHandler.handleInput(aRequest: TInputRequest;
  bANSI: boolean);
var
  p, inp: string;
begin
  p := aRequest.Prompt;
  repeat
    try
      WriteToConsole(p, bANSI);
      readln(inp);
      aRequest.Input := inp;
    except
      on E: Exception do 
      begin
        raise Exception.Create('Failed to read input from Console.'#13#10 + E.Message);
      end;
    end;
  until aRequest.isInputValid;
end;

end.
