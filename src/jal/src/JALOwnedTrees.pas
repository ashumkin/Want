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

unit JALOwnedTrees;

interface
uses
  SysUtils,
  Classes;

type
  TTree = class
  protected
    FParent   :TTree;
    FChildren :TList;

    function GetChild(i :Integer):TTree;

    procedure SetParent(NewParent :TTree); virtual;

    procedure InsertNotification(Child : TTree); virtual;
    procedure RemoveNotification(Child : TTree); virtual;
  public
    constructor Create(Parent :TTree = nil);
    destructor  Destroy; override;

    function ChildCount :Integer;

    function Add(Child :TTree) :TTree;    virtual;
    function Remove(Child :TTree) :TTree; virtual;

    procedure Clear;

    property Parent :TTree read FParent write Setparent;

    property Children[i :Integer] :TTree read GetChild;
  end;


implementation

{ TTree }

constructor TTree.Create(Parent: TTree);
begin
  inherited Create;
  FChildren := TList.Create;

  SetParent(Parent);
end;

destructor TTree.Destroy;
begin
  SetParent(nil);
  Clear;
  FChildren.Free;
  FChildren := nil;
  inherited Destroy;
end;

function TTree.ChildCount: Integer;
begin
  Result := FChildren.Count;
end;

function TTree.GetChild(i: Integer): TTree;
begin
  if (i < 0) or (i >= FChildren.Count) then
    raise Exception.Create('Invalid position' + IntToStr(i));

  Result := FChildren[i];
end;

function TTree.Add(Child: TTree) :TTree;
begin
  Assert(Child <> nil);
  Child.SetParent(Self);
  Result := Child;
end;

function TTree.Remove(Child: TTree) :TTree;
var
  Index :Integer;
begin
  Index := FChildren.IndexOf(Child);
  if Index < 0 then
    raise Exception.Create('Child not found');

  Child.SetParent(nil);

  Result := Child;
end;

procedure TTree.SetParent(NewParent: TTree);
begin
  if NewParent = Self.Parent then
    EXIT;

  if Parent <> nil then
  begin
    Parent.RemoveNotification(Self);
    Parent.FChildren.Remove(Self);
  end;

  if NewParent <> nil then
  begin
    NewParent.FChildren.Add(Self);
    NewParent.InsertNotification(Self);
  end;

  Self.FParent := NewParent;
end;


procedure TTree.InsertNotification(Child: TTree);
begin

end;

procedure TTree.RemoveNotification(Child: TTree);
begin

end;

procedure TTree.Clear;
var
  i :Integer;
begin
  for i := ChildCount-1 downto 0 do
    Children[i].Free;
end;

end.
