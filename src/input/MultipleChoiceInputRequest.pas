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
unit MultipleChoiceInputRequest;

interface

uses
  Classes, InputRequest;

type
  TMultipleChoiceInputRequest = class(TInputRequest)
  private
    FChoices: TStrings;
    FNumberedChoices: boolean;
  protected
    function GetPrompt: string; override;
    function GetChoice: string; override;
  public
    constructor Create(const APrompt: string; AChoices: TStrings;
      bNumberedChoices: boolean); overload;
    constructor Create(const APrompt: string; AChoices: TStrings); overload;
    destructor  Destroy; override;

    function isInputValid: boolean; override;

    property Choices: TStrings read FChoices write FChoices;
  end;

implementation

uses
  SysUtils;

{ TMultipleChoiceInputRequest }

constructor TMultipleChoiceInputRequest.Create(const APrompt: string;
  AChoices: TStrings; bNumberedChoices: boolean);
begin
  if Assigned(AChoices) then
    if AChoices.Count = 0 then
      raise Exception.Create('choices must not be null');
  FPrompt  := APrompt;
  FChoices := TStringList.Create;
  TStringList(fChoices).CaseSensitive := True;
  FChoices.Assign(aChoices);
  FNumberedChoices := bNumberedChoices;
end;

constructor TMultipleChoiceInputRequest.Create(const APrompt: string;
  AChoices: TStrings);
begin
  Create(APrompt, AChoices, False);
end;

destructor TMultipleChoiceInputRequest.Destroy;
begin
  FChoices.Free;
  inherited;
end;

function TMultipleChoiceInputRequest.GetChoice: string;
begin
  Result := Choices[StrToIntDef(FInput, 1) - 1];
end;

function TMultipleChoiceInputRequest.GetPrompt: string;
var
  i: Integer;
begin
  Result := inherited GetPrompt;
  if not FNumberedChoices then
    Result := Result + '(';
  for i := 0 to Choices.Count - 1 do
  begin
    if FNumberedChoices then
      Result := Format('%s%d. %s%s', [Result, i + 1, Choices[i], #13#10])
    else
    begin
      Result := Result + Choices[i];
      if i < Choices.Count - 1 then
        Result := Result + ',';
    end;
  end;
  if not FNumberedChoices then
    Result := Result + ')';
end;

function TMultipleChoiceInputRequest.isInputValid: boolean;
var
  i: Integer;
begin
  if FNumberedChoices then
  begin
    i := StrToIntDef(FInput, -1);
    if i = 0 then
      raise Exception.Create('Choice is interrupted');
    Result := (i > 0) and (i <= FChoices.Count);
  end
  else
    Result := FChoices.IndexOf(FInput) <> -1;
end;

end.
