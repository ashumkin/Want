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

unit JALGeomModels;

interface
uses
  Windows,
  SysUtils,
  Math,
  Graphics,

  JALGeometry,
  JALCollections;

type
  TToPoint = function(const P:TVector) : TPoint of object;

  TDrawOption = (
      drwNoSetcolor
  );
  TDrawOptions = set of TDrawOption;

  IVector = interface(IComparable)
    ['{FA5752CB-E02E-4007-97F6-D783C7F1A73B}']
    function  GetVector :TVector;
    procedure SetVector(Value :TVector);

    function GetX : JalGeometry.Float;
    function GetY : JalGeometry.Float;
    function GetZ : JalGeometry.Float;

    procedure SetX(Value :JalGeometry.Float);
    procedure SetY(Value :JalGeometry.Float);
    procedure SetZ(Value :JalGeometry.Float);

    property vector :TVector read GetVector write SetVector;

    property X :JalGeometry.Float read GetX write SetX;
    property Y :JalGeometry.Float read GetY write SetY;
    property Z :JalGeometry.Float read GetZ write SetZ;
  end;

  IEntity = interface(IComparable)
    ['{70794A65-BEE7-4FE7-A392-41C247B6F405}']

    procedure GetBounds(var bounds :TCube);
    function  Bounds :TCube;
    function  Draw(Canvas :TCanvas; const ToPoint :TToPoint; const options :TDrawOptions = []) :boolean;

    procedure SetSize(S :Integer);
    procedure SizeToFit;

    procedure SetPoint( No :Word; const P :TVector);       overload;
    procedure SetPoint( No :Word; const X, Y, Z  :Double); overload;
    procedure SetPointX(No :Word; const Value :Double);
    procedure SetPointY(No :Word; const Value :Double);

    procedure AddPoint(const X, Y, Z :Double);  overload;
    procedure AddPoint(const p :TVector);       overload;

    procedure AddChild(child :IEntity);
    procedure InsertChild(pos :Integer; child :IEntity);
    function  ChildPos(child :IEntity):Integer;

    function  HasChildren :boolean;
    procedure ClearChildren;

    function GetColor :TColor;
    procedure SetColor(const Value :TColor);
    property Color :TColor read GetColor write SetColor;

    function GetName :string;
    procedure SetName(const Name :string);
    property Name :string read GetName write SetName;

    function  GetVisible :boolean;
    procedure SetVisible(Value :boolean);
    property Visible :boolean read GetVisible write SetVisible;

    function  GetUseColor :boolean;
    procedure SetUseColor(Value :boolean);
    property  UseColor :boolean read GetUseColor write SetUseColor;

    function  GetClosed :boolean;
    procedure SetClosed(Value :boolean);
    property  Closed :boolean read GetClosed write SetClosed;

    function children :IList;
  end;

  IPolyline = interface(IEntity)
  ['{43C67219-CD07-46E0-AA23-407BF3913088}']
  end;

  ILayer = interface(IEntity)
  ['{FFA34383-2CD6-4015-ACF8-023B7F6961D2}']
  end;

  IModel = interface(IEntity)
    ['{FE758F38-D42D-4C7A-965C-FF57CD9DBA08}']

    function NewLayer(const Name :string) :ILayer;
  end;

  TVectorC = class(TAbstractObject, IVector)
  protected
    _vector :TVector;
  public
    constructor Create(V :TVector);

    function compareTo(other :IUnknown) :Integer; virtual;

    function  GetVector :TVector;
    procedure SetVector(Value :TVector);

    function GetX : JalGeometry.Float;
    function GetY : JalGeometry.Float;
    function GetZ : JalGeometry.Float;

    procedure SetX(Value :JalGeometry.Float);
    procedure SetY(Value :JalGeometry.Float);
    procedure SetZ(Value :JalGeometry.Float);

    property vector :TVector read GetVector write SetVector;
  end;

  TAbstractEntity = class(TAbstractObject, IEntity, IComparable, IDelphiObject)
  protected
    _Name     :string;
    _points   :TVectors;
    _children :IList;
    _Color    :TColor;
    _UseColor :ByteBool;
    _Hidden   :ByteBool;
    _count    :Integer;
    _Closed :ByteBool;

    procedure MakeChildren;
  public
    constructor Create(const Name :string = '');

    function compareTo(other :IUnknown) :Integer; virtual;

    procedure GetBounds(var bounds :TCube); virtual;
    function  Bounds :TCube;                virtual;

    function Draw(Canvas :TCanvas; const ToPoint :TToPoint; const options :TDrawOptions = []) :boolean; virtual;

    procedure SetSize(S :Integer);
    procedure SizeToFit;

    procedure SetPoint( No :Word;  const P :TVector);      overload; virtual;
    procedure SetPoint( No :Word;  const X, Y, Z :Double); overload; virtual;

    procedure SetPointX(No :Word; const Value :Double); virtual;
    procedure SetPointY(No :Word; const Value :Double); virtual;
    procedure SetPointZ(No :Word; const Value :Double); virtual;

    procedure AddPoint(const X, Y, Z :Double); overload; virtual;
    procedure AddPoint(const p :TVector);      overload; virtual;

    procedure AddChild(child :IEntity);
    procedure InsertChild(pos :Integer; child :IEntity);
    function  ChildPos(child :IEntity):Integer;

    function  HasChildren :boolean;
    procedure ClearChildren;

    function  GetName :string;
    procedure SetName(const Name :string);

    function  GetColor :TColor;
    procedure SetColor(const Value :TColor);

    function  GetVisible :boolean;
    procedure SetVisible(Value :boolean);

    function  GetUseColor :boolean;
    procedure SetUseColor(Value :boolean);

    function  GetClosed :boolean;
    procedure SetClosed(Value :boolean);
    property  Closed :boolean read GetClosed write SetClosed;

    function children :IList;
  end;

  TPolyLine = class(TAbstractEntity)
  public
    function Draw(Canvas :TCanvas; const ToPoint :TToPoint; const options :TDrawOptions = []) :boolean; override;
  end;

  TLayer = class(TAbstractEntity, ILayer)
  end;

  TAbstractModel = class(TAbstractEntity, IModel)
    function NewLayer(const Name :string) :ILayer; virtual; abstract;
  end;

  TModel = class(TAbstractModel)
  protected
    _layers :IMap;
  public
    constructor Create;
    procedure GetBounds(var bounds: TCube);  override;
    function  Draw(Canvas :TCanvas; const ToPoint :TToPoint; const options :TDrawOptions = []):boolean; override;

    function NewLayer(const Name :string) :ILayer; override;
  end;

function newIVector(V :TVector):IVector;

implementation

{ TVectorC }

function newIVector(V :TVector):IVector;
begin
  Result := TVectorC.Create(V);
end;

function  TVectorC.GetVector :TVector;
begin
  Result := _vector;
end;

procedure TVectorC.SetVector(Value :TVector);
begin
  _vector := Value;
end;

function TVectorC.compareTo(other :IUnknown) :Integer;
begin
  Result := Compare(_vector, (other as IVector).vector);
end;

constructor TVectorC.Create(V: TVector);
begin
  inherited Create;
  _vector := V;
end;

function TVectorC.GetX: JalGeometry.Float;
begin
  Result := _vector.X;
end;

function TVectorC.GetY: JalGeometry.Float;
begin
  Result := _vector.Y;
end;

function TVectorC.GetZ: JalGeometry.Float;
begin
  Result := _vector.Z;
end;

procedure TVectorC.SetX(Value: Float);
begin
  _vector.X := Value;
end;

procedure TVectorC.SetY(Value: Float);
begin
end;

procedure TVectorC.SetZ(Value: Float);
begin
  _vector.Z := Value;
end;

{ TAbstractEntity }

constructor TAbstractEntity.Create(const Name :string);
begin
  inherited Create;
  _Name     := Name;
end;

procedure TAbstractEntity.MakeChildren;
begin
  if _children = nil then
    _children := TLinkedList.Create;
end;

function TAbstractEntity.Bounds: TCube;
begin
  Result := EmptyCube;
  GetBounds(Result);
end;

function TAbstractEntity.Draw(Canvas: TCanvas; const ToPoint: TToPoint; const options :TDrawOptions):boolean;
var
  i :IIterator;
begin
  if not GetVisible then
    Result := false
  else
  begin
    if GetUseColor and not (drwNoSetcolor in options) then
    begin
      with Canvas do
        if Pen.Color <> _Color then
           Pen.Color:= _Color;
    end;

    if _children <> nil then
    begin
      i := _children.iterator;
      while i.hasNext do
        (i.next as IEntity).Draw(Canvas, ToPoint, options);
    end;
    Result := true;
  end;
end;

procedure TAbstractEntity.GetBounds(var bounds: TCube);
var
  n :Integer;
  i :IIterator;
begin
  for n := 0 to _count-1 do
      bounds := Union(Bounds, _points[n]);

  if _children <> nil then
  begin
    i := _children.iterator;
    while i.hasNext do
      (i.next as IEntity).GetBounds(bounds);
  end;
end;

procedure TAbstractEntity.SetSize(S: Integer);
begin
  SetLength(_points, Max(Length(_points), S));
end;

procedure TAbstractEntity.SizeToFit;
begin
  SetLength(_points, _count);
end;

procedure TAbstractEntity.SetPoint(No: Word; const P: TVector);
begin
  setSize(No+1);
  _points[No] := P;
  _count := Max(_count, No+1);
end;

procedure TAbstractEntity.SetPoint(No: Word; const X, Y, Z: Double);
begin
  SetPoint(No, Vector(X, Y, Z));
end;

procedure TAbstractEntity.SetPointX(No: Word; const Value: Double);
begin
  setSize(No+1);
  _points[No].X := Value;
  _count := Max(_count, No+1);
end;

procedure TAbstractEntity.SetPointY(No: Word; const Value: Double);
begin
  setSize(No+1);
  _points[No].Y := Value;
  _count := Max(_count, No+1);
end;

procedure TAbstractEntity.SetPointZ(No: Word; const Value: Double);
begin
  setSize(No+1);
  _points[No].Z := Value;
  _count := Max(_count, No+1);
end;

procedure TAbstractEntity.AddPoint(const X, Y, Z: Double);
begin
  SetPoint(_count, X, Y, Z);
end;

procedure TAbstractEntity.AddPoint(const p: TVector);
begin
  SetPoint(_count, p);
end;

procedure TAbstractEntity.AddChild(child: IEntity);
begin
  MakeChildren;
  _children.add(child);
end;

function TAbstractEntity.GetColor: TColor;
begin
  Result := _color;
end;

procedure TAbstractEntity.SetColor(const Value: TColor);
begin
  _color := Value;
end;


function TAbstractEntity.children: IList;
begin
  Result := _children;
end;

function TAbstractEntity.compareTo(other: IUnknown): Integer;
begin
  Result := compare(Longint(self.obj), Longint((other as IDelphiObject).obj) );
end;

function TAbstractEntity.GetVisible: boolean;
begin
  Result := not _Hidden;
end;

procedure TAbstractEntity.SetVisible(Value: boolean);
begin
  _Hidden := not Value;
end;

function TAbstractEntity.GetUseColor: boolean;
begin
  Result := _UseColor;
end;

procedure TAbstractEntity.SetUseColor(Value: boolean);
var
  i :IIterator;
begin
  _UseColor := Value;
  if _children <> nil then
  begin
    i := _children.iterator;
    while i.hasNext do
      (i.next as IEntity).SetUseColor(Value);
  end;
end;

function TAbstractEntity.ChildPos(child: IEntity): Integer;
begin
  if _children <> nil then
    Result := _children.indexOf(child)
  else
    Result := -1;
end;

procedure TAbstractEntity.InsertChild(pos :Integer; child: IEntity);
begin
  if (_children <> nil) and _children.has(child) then
     _children.remove(child);
  MakeChildren;
  _children.insert(pos, child);
end;

procedure TAbstractEntity.ClearChildren;
begin
  _children := nil;
end;


function TAbstractEntity.HasChildren: boolean;
begin
  Result := _children <> nil;
end;

function TAbstractEntity.GetClosed: boolean;
begin
  Result := _Closed;
end;

procedure TAbstractEntity.SetClosed(Value: boolean);
begin
  _Closed := Value;
end;

{ TLayer }


function TAbstractEntity.GetName: string;
begin
  Result := _Name;
end;

procedure TAbstractEntity.SetName(const Name: string);
begin
  _Name := Name;
end;

{ TModel }

constructor TModel.Create;
begin
  inherited Create;

  _layers := TTreeMap.Create;
end;

function TModel.Draw(Canvas: TCanvas; const ToPoint: TToPoint; const options :TDrawOptions):boolean;
var
  i :IIterator;
begin
  Result := inherited Draw(Canvas, ToPoint, options);
  if Result then
  begin
    i := _layers.values.iterator;
    while i.hasNext do
      (i.next as IEntity).Draw(Canvas, ToPoint, options);
  end;
end;

function TModel.NewLayer(const Name: string): ILayer;
begin
  Result := _layers.get(Name) as ILayer;
  if Result = nil then
  begin
    Result := TLayer.Create(Name);
    _layers.put(iref(Name), Result);
  end;
end;

procedure TModel.GetBounds(var bounds: TCube);
var
  i :IIterator;
begin
  inherited GetBounds(bounds);

  i := _layers.values.iterator;
  while i.hasNext do
    (i.next as IEntity).GetBounds(bounds);
end;

{ TPolyLine }

function TPolyLine.Draw(Canvas: TCanvas; const ToPoint: TToPoint; const options :TDrawOptions):boolean;
var
  pts :TPoints;
  n   :Integer;
begin
  Result := inherited Draw(Canvas, ToPoint, options);

  if Result then
  begin
    SetLength(pts, _count);
    for n := 0 to _count-1 do
      pts[n] := ToPoint(_points[n]);
    if not Closed then
      Canvas.Polyline(pts)
    else
      Canvas.Polygon(pts);
  end;

  end;

end.
