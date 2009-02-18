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
unit InputTasks;

interface

uses
  WantClasses,
  Classes;

type
  TInputTask = class(TTask)
  private
    FValidArgs:   string;
    FMessage:     string;
    FAddProperty: string;
    Fnumbered: boolean;
  public
    procedure Execute; override;
  published
    property _message:    string read FMessage     write FMessage;
    property validargs:   string read FValidArgs   write FValidArgs;
    property addproperty: string read FAddProperty write FAddProperty;
    property numbered: boolean read Fnumbered write Fnumbered;
  end;

implementation

uses
  InputRequest, MultipleChoiceInputRequest;

{ TInputTask }

procedure TInputTask.Execute;
var
  bInputRequest: TInputRequest;
  bArgs:         TStringList;
  bValue:        string;
begin
  inherited;
  if GetAttribute('validargs') <> '' then
  begin
    bArgs := TStringList.Create;
    try
      bArgs.Delimiter := ',';
      bArgs.DelimitedText := FValidArgs;
      bInputRequest := TMultipleChoiceInputRequest.Create(FMessage, bArgs,
        numbered);
    finally
      bArgs.Free;
    end;
  end
  else
  begin
    bInputRequest := TInputRequest.Create(FMessage);
  end;

  Project.InputHandler.handleInput(bInputRequest, Project.Listener.ANSI);

  bValue := bInputRequest.Choice;
  if (FAddProperty <> '') and (bValue <> '') then
    Project.SetProperty(FAddProperty, bValue);
end;

initialization
  RegisterTask(TInputTask);
end.
