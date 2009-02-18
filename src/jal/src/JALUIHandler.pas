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
unit JALUIHandler;

interface
uses
  Windows,
  Graphics,

  JalGeometry,

  Classes,
  Controls;

const
  rcs_id : string = '(#)$Id: JALUIHandler.pas 706 2003-05-14 22:13:46Z hippoman $';

type
  TUIHandler = class(TComponent)
  public
    Selecting   :Boolean;
    AmDragging  :Boolean;
    HaveRect    :Boolean;
    Anchor      :TPoint;
    CurrentPos  :TPoint;
    DragRect    :TRect;

    procedure NewSelection(const P :TPoint);

    procedure Click(Sender: TObject);    virtual;
    procedure DblClick(Sender: TObject); virtual;
    procedure MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);  virtual;
    procedure MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);                        virtual;
    procedure MouseUp(  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);    virtual;
    procedure KeyDown(  Sender: TObject; var Key: Word; Shift: TShiftState);                          virtual;
    procedure KeyPress( Sender: TObject; var Key: Char);                                             virtual;
    procedure KeyUp(    Sender: TObject; var Key: Word; Shift: TShiftState);                            virtual;
  end;

implementation


type
  TCCCrack = class(TCustomControl);

procedure TUIHandler.NewSelection(const P: TPoint);
begin
  CurrentPos := P;
  DragRect := Rect([Anchor, P]);
  HaveRect := true;
end;

procedure TUIHandler.Click(Sender: TObject);
begin
end;

procedure TUIHandler.DblClick(Sender: TObject);
begin
end;

procedure TUIHandler.MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   if Button <> mbLeft then
      Exit;

  Self.Selecting    := True;
  Self.AmDragging   := False;

  Anchor   := Point(X, Y);
  CurrentPos := Anchor;

  if ssDouble in Shift then
    Exit; {!!!}

  DragRect := Rect([Anchor, CurrentPos]);
  HaveRect := false;
end;


procedure TUIHandler.MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if Self.Selecting and (ssLeft in Shift) then
      NewSelection(Point(X, Y))
  else
     Self.Selecting := False;
end;

procedure TUIHandler.MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  try
    if Selecting then
      NewSelection(Point(X, Y));
  finally
    Self.Selecting := False;
    Self.AmDragging  := False;
  end
end;

procedure TUIHandler.KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
end;


procedure TUIHandler.KeyPress(Sender: TObject; var Key: Char);
begin
end;

procedure TUIHandler.KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
end;

end.

