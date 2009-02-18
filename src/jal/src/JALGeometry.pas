{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{                                              }
{   \\\                                        }
{  -(j)-                                       }
{    /juanca ®                                 }
{    ~                                         }
{  Copyright © 1995-2002 Juancarlo Añez        }
{  http://www.suigeneris.org/juanca            }
{  All rights reserved.                        }
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

{#(@)$Id: JALGeometry.pas 771 2004-05-08 16:15:25Z juanco $}

unit JALGeometry;
interface
uses
    Windows,
    Classes,

    JALMath;

const
    HiMetricsPerInch = 2540;

type
  TCoordinateSystem = (
    coordWindow,
    coordUTM,
    coordLatLong
  );

  Float = Single;

  TPoint = Windows.TPoint;
  TRect  = Windows.TRect;

  TPoint3 = record
  case byte of
     0 :(X, Y, Z :Integer);
     1 :(Point :TPoint);
     2 :(V :array[1..3] of Integer);
   end;

  TVector = packed record
    case Byte of
      1 : (V :array[1..3] of Float);
      0 : (X, Y, Z :Float);
  end;

  TSegment = packed record
     case Byte of
        1  : (P1, P2 :TPoint);
        0  : (X1, Y1, X2, Y2 :Integer);
  end;

  TLineEquation = packed record
     Slope,
     YCept :Float;
  end;

  TLine = packed record
     case Byte of
        1  : (P1, P2 :TVector);
        0  : (X1, Y1, Z1, X2, Y2, Z2 :Float);
  end;

  TCube = packed record
    case Integer of
      1: (TopLeft, BottomRight: TVector);
      0: (Left, Top, Back, Right, Bottom, Front: Float);
  end;

  TBezier  = array[0..3] of TPoint;
  TVectors = array of TVector;
  TPoints  = array of TPoint;


  TMatrix  = array[1..4, 1..4] of Float;

  ITransf = interface
    ['{9EBF0160-7A28-432A-843D-94B8DACB6D67}']
    procedure compose(const T :ITransf);
    function  clone :ITransf;

    procedure scale(const sx, sy, sz :Float);
    procedure traslate(const tx, ty, tz:Float);  
    overload;
    procedure traslate(const p :TVector);
    overload;

    procedure rotateX(const ang:Float);
    procedure rotateY(const ang:Float);
    procedure rotateZ(const ang:Float);

    procedure ChangeCoords(const vx, vy, vz :TVector);

    function  apply(const p :TVector) :TVector; 
    overload;
    function  apply(const p :TPoint)  :TPoint;  
    overload;
    function  apply(const p :TVectors)  :TVectors;  
    overload;

    function  unapply(const  p :TVector) :TVector;
    overload;
    function  unapply(const  p :TPoint)  :TPoint;     
    overload;

    function mat :TMatrix;
    function inv :TMatrix;
  end;


  TTransf = class(TInterfacedObject, ITransf)
    _mat, _inv :TMatrix;

    constructor Create;

    constructor identity;
    constructor initScale(const sx, sy, sz :Float);
    constructor initTraslate(const tx, ty, tz:Float);
    constructor initRotateX(const ang:Float);
    constructor initRotateY(const ang:Float);
    constructor initRotateZ(const ang:Float);

    constructor copy(const T :ITransf);
    constructor initCoordChange(const vx, vy, vz :TVector);

    procedure compose(const T :ITransf);
    function  clone :ITransf;

    procedure scale(const sx, sy, sz :Float);

    procedure traslate(const tx, ty, tz:Float);
    overload;
    procedure traslate(const p :TVector);
    overload;

    procedure rotateX(const ang:Float);
    procedure rotateY(const ang:Float);
    procedure rotateZ(const ang:Float);

    procedure ChangeCoords(const vx, vy, vz :TVector);

    function  apply(const p :TVector) :TVector;
    overload;
    function  apply(const p :TPoint)  :TPoint;
    overload;
    function  apply(const p :TVectors)  :TVectors;
    overload;

    function  unapply(const  p :TVector) :TVector;
    overload;
    function  unapply(const  p :TPoint)  :TPoint;
    overload;

    function mat :TMatrix;
    function inv :TMatrix;
  end;

const
  OriginPoint  :TPoint  = (x:0;y:0);
  OriginVector :TVector = (x:0;y:0;z:0);

function Point(AX :Integer = 0; AY: Integer = 0): TPoint;
overload;
function Point(const P :TVector):TPoint;
overload;
function Points(const P:array of TPoint) :TPoints;
overload;
function Points(const P:TVectors) :TPoints;
overload;


function Vector(X :Float = 0; Y :Float = 0; Z :Float = 0):TVector;
overload;
function Vector(const P :TPoint):TVector;
overload;

function Rect(X1, Y1, X2, Y2 :Integer) :TRect;
overload;
function Rect(const P :array of TPoint) :TRect;
overload;
function Rect(const R:TRect)   :TRect;
overload;
function Rect(const L :TSegment) :TRect;
overload;


function Cube(const L :TLine) :TCube;
overload;
function Cube(const X1, Y1, X2, Y2 :Float) :TCube;
overload;
function Cube(const X1, Y1, Z1, X2, Y2, Z2 :Float) :TCube;
overload;
function Cube(const P :array of TVector) :TCube;
overload;
function Cube(const P :TVectors) :TCube;
overload;

function Segment(X1, Y1, X2, Y2 :Integer) :TSegment;
overload;
function Segment(X1, Y1, X2, Y2 :Float) :TLine;
overload;
function Segment(const P1, P2 :TPoint) :TSegment;
overload;
function Segment(const P1, P2 :TVector) :TLine;
overload;
function MidSegment(const L :TSegment):TPoint;
overload;
function MidSegment(const L :TLine):TVector;
overload;

function SegmentLength(const L:TSegment) :Longint;
overload;
function SegmentLength(const L:TLine) :Float;
overload;

function LineSlope(const L :TSegment) :Float;
overload;
function LineEquation(const L :TSegment) :TLineEquation;
overload;
function CalcSegmentMove(const P1, P2 :TPoint; E :Float) :TPoint;
overload;
function CalcSegmentMove(const P1, P2 :TVector; E :Float) :TVector;
overload;
function MoveSegment(const L :TSegment; const P :TPoint) :TSegment;
overload;
function MoveSegment(const L :TSegment; E :Float) :TSegment;
overload;
function MoveSegment(const L :TLine; const P :TVector) :TLine;
overload;
function MoveSegment(const L :TLine; E :Float) :TLine;
overload;
function LineSlopeVector(const L :TSegment):TPoint;
overload;
function SegmentSlopeVector(const L :TLine):TVector;
overload;
function LineIntersectionParam(const A, B :TSegment):Float;
overload;
function LineIntersection(const A, B :TSegment):TPoint;
overload;

function PointDistance(const P1, P2 :TPoint):Longint;                      
overload;
function PointDistance(const P1, P2 :TVector):Float;                    
overload;

function PointSum(const P1, P2 :TPoint) :TPoint;                           
overload;
function PointSum(const P1, P2 :TVector) :TVector;                         
overload;
function PointDiff(const P1, P2 :TPoint) :TPoint;                          
overload;
function PointDiff(const P1, P2 :TVector) :TVector;                        
overload;
function MidPoint(const P1, P2 :TPoint):TPoint;                            
overload;
function MidPoint(const P1, P2 :TVector):TVector;                          
overload;
function Equal(const P1, P2 :TPoint):Boolean;
overload;
function Equal(const P1, P2 :TVector):Boolean;
overload;
function Equal(const R1, R2 :TRect):Boolean;                          
overload;
function Equal(const R1, R2 :TCube):Boolean;
overload;
function PointLength(const P :TPoint) :Longint;
overload;
function PointLength(const P :TVector) :Float;
overload;
function Compare(const P1, P2 :TPoint):Integer;
overload;
function MovePoint(const P :TPoint; X, Y :Integer):TPoint;
overload;
procedure MovePoints(var P :array of TPoint; X, Y :Integer);
overload;
function PointAngle(const p :TPoint):Float;
overload;

function PointMin(const P1, P2 :TPoint):TPoint;
overload;
function PointMax(const P1, P2 :TPoint):TPoint;
overload;
function PointMin(const P1, P2 :TVector):TVector;
overload;
function PointMax(const P1, P2 :TVector):TVector;
overload;
function Compare(const P1, P2 :TVector):Integer;
overload;

function PointSize(const P :TVector) :Float;                            
overload;

{ LineAngle form -Pi to +Pi }
function LineAngle(const L :TSegment):Float;                            
overload;
function LineAngle(const L :TLine):Float;                           
overload;

{ AngleBetweenLines form -Pi to +Pi }
function AngleBetweenLines(const L1, L2 :TSegment):Float;               
overload;

function LineNearest(const P :TPoint; const L :TSegment) :TPoint;          
overload;
function SegmentNearest(const P :TPoint; const L :TSegment) :TPoint;       
overload;

function DistanceToLine(const p :TPoint; const L :TSegment):Longint;       
overload;
function DistanceToSegment(const p :TPoint; const L :TSegment):Longint;    
overload;
function DistanceToSegment(const p :TVector; const L :TLine):Float;
overload;

function DistanceToLine2(const p :TPoint; const L :TSegment):Longint;      
overload;
function DistanceToSegment2(const p :TPoint; const L :TSegment):Longint;   
overload;

function EmptyRect :TRect;
function EmptyCube :TCube;
function IsEmpty(const R :TRect):Boolean;
overload;
function IsEmpty(const R :TCube):Boolean;                             
overload;

function RectWidth(const R :TRect):Longint;                           
overload;
function RectWidth(const R :TCube):Float;                              
overload;

function RectHeight(const R :TRect):Longint;                          
overload;
function RectHeight(const R :TCube):Float;                             
overload;

function RectArea(const R :TRect):Longint;                                 
overload;
function RectArea(const R :TCube):Float;                               
overload;
function Intersection(const R1, R2 :TRect):TRect;
overload;
function RectsIntersect(const R1, R2 :TRect):Boolean;
overload;
function CubesIntersect(const R1, R2 :TCube):Boolean;
overload;

function Union(const R :TRect; Pt :array of TPoint):TRect;
overload;
function Union(const R1, R2 :TCube):TCube;
overload;
function Union(const R :TCube; const Pt :TVector):TCube;
overload;
function Union(const R :TCube; const Pt :array of TVector):TCube;
overload;
function Union(const R :TCube; const Pt :TVectors):TCube;
overload;

function MoveRect(const R :TRect; byX, byY :Integer) :TRect;
overload;
function ExpandRect(const  R :TRect; XExpandBy, YExpandBy :Integer):TRect;
overload;
function ExpandRect(const  R :TCube; XExpandBy, YExpandBy :Float):TCube;
overload;
function ScaleRect(const R :TRect; ScaleX, ScaleY :Float) :TRect;
overload;
function PointInRect(const P :TPoint; const R :TRect) :Boolean;
overload;
function PointInRect(const P :TVector; const R :TCube) :Boolean;
overload;
function MidRect(const R :TRect):TPoint;                                   
overload;
function MidRect(const R :TCube):TVector;                                 
overload;

{ copied from VCL Classes unit }
function Bounds(ALeft, ATop, AWidth, AHeight: Integer): TRect;             
overload;

function ScalePoint(const P :TVector; Scale:Float) :TVector;            
overload;

function Rect(R :TCube):TRect;                                            
overload;
function Cube(R :TRect) :TCube;
overload;


function BezierToRect(const B :TBezier):TRect;
function MoveBezier(const L :TBezier; F :Integer):TBezier;

function ClipToRect(const P :TPoint; const R :TRect) :TPoint;             
overload;
function ClipToRect(const P :TVector; const R :TCube) :TVector;          
overload;

function Normalize(const P:TVector) : TVector;
function CrossProduct(const p1,p2:TVector) : TVector;

function SlicePoints(const P :TPoints; i, n :Integer) :TPoints;

function Identity :ITransf;
function Scaling(const sx, sy, sz :Float) :ITransf;
function Traslation(const tx, ty, tz:Float) :ITransf;
function XRotation(const ang:Float) :ITransf;
function YRotation(const ang:Float) :ITransf;
function ZRotation(const ang:Float) :ITransf;
function CoordChange(const vx, vy, vz :TVector) :ITransf;

function Apply(const T :ITransf; const v :TVector) :TVector;            overload;
function Apply(const T :ITransf; const v :array of TVector) :TVectors;  overload;
function Apply(const T :ITransf; const v :TVectors) :TVectors;  overload;

function Compose(const T1, T2 :ITransf) :ITransf;


function Point3(x, y, z :Integer) :TPoint3; overload;
function Point3(const P :TPoint; z :Integer) :TPoint3; overload;

implementation
uses
    Math;

function Segment(X1, Y1, X2, Y2 :Integer) :TSegment;
begin
     Result.X1 := X1;
     Result.Y1 := Y1;
     Result.X2 := X2;
     Result.Y2 := Y2;
end;

function Segment(X1, Y1, X2, Y2 :Float) :TLine;
begin
     Result.X1 := X1;
     Result.Y1 := Y1;
     Result.Z1 := 0;
     Result.X2 := X2;
     Result.Y2 := Y2;
     Result.Z2 := 0;
end;

function Segment(const P1, P2 :TPoint) :TSegment;
begin
  Result := Segment(P1.X, P1.Y, P2.X, P2.Y);
end;

function Segment(const P1, P2 :TVector) :TLine;
begin
  Result := Segment(P1.X, P1.Y, P2.X, P2.Y);
end;


function MidSegment(const L :TSegment):TPoint;
begin
     Result := MidPoint(L.P1, L.P2)
end;

function MidSegment(const L :TLine):TVector;
begin
     Result := MidPoint(L.P1, L.P2)
end;



function SegmentLength(const L:TSegment) :Longint;
begin
     Result := PointDistance(L.P1, L.P2)
end;

function SegmentLength(const L:TLine) :Float;
begin
     Result := PointDistance(L.P1, L.P2)
end;


function Rect(const L :TSegment) :TRect;
begin
     with L do
        Result := JALGeometry.Rect(X1, Y1, X2, Y2);
end;

function Cube(const X1, Y1, X2, Y2 :Float) :TCube;
begin
  Result := Cube(X1, Y1, 0, X2, Y2, 0);
end;

function Cube(const X1, Y1, Z1, X2, Y2, Z2 :Float) :TCube;
begin
     if X1 <= X2 then begin
        Result.Left  := X1;
        Result.Right := X2
     end
     else begin
        Result.Left  := X2;
        Result.Right := X1
     end;
     if Y1 <= Y2 then begin
        Result.Top    := Y1;
        Result.Bottom := Y2;
     end
     else begin
        Result.Top    := Y2;
        Result.Bottom := Y1;
     end;
     if Z1 <= Z2 then begin
        Result.Back   := Z1;
        Result.Front  := Z2;
     end
     else begin
        Result.Back   := Z2;
        Result.Front  := Z1;
     end;
end;

function Cube(const L :TLine) :TCube;
begin
     with L do
        Result := Cube(X1, Y1, X2, Y2);
end;

function LineSlope(const L :TSegment) :Float;
begin
     with L do
       Result := (1.0*Y1 - Y2)/(1.0*X1 - X2)
end;

function LineEquation(const L :TSegment) :TLineEquation;
begin
     with Result do begin
          Slope := LineSlope(L);
          YCept := L.Y1 - Slope*L.X1
     end
end;

function CalcSegmentMove(const P1, P2 :TPoint; E :Float) :TPoint;
var
   A :Double;
   T :ITransf;
begin
  if E = 0 then
     Result := Point(0, 0)
  else
  begin
     A := LineAngle(Segment(P1, P2));
     T := ZRotation(A + Pi/2);
     Result := Point(Apply(T, Vector(E, 0, 0)));
  end
end;

function CalcSegmentMove(const P1, P2 :TVector; E :Float) :TVector;
var
   A :Double;
   T :ITransf;
begin
  if E = 0 then
     Result := Vector
  else
  begin
     A := LineAngle(Segment(P1, P2));
     T := ZRotation(A + Pi/2);
     Result := Apply(T, Vector(E, 0, 0));
  end
end;

function MoveSegment(const L :TSegment; const P :TPoint) :TSegment;
begin
  Result.P1 := PointSum(L.P1, P);
  Result.P2 := PointSum(L.P2, P);
end;

function MoveSegment(const L :TSegment; E :Float) :TSegment;
begin
  if E <> 0 then
     Result := MoveSegment(L, CalcSegmentMove(L.P1, L.P2, E))
  else
    Result := L;
end;

function MoveSegment(const L :TLine; const P :TVector) :TLine;
begin
  Result.P1 := PointSum(L.P1, P);
  Result.P2 := PointSum(L.P2, P);
end;

function MoveSegment(const L :TLine; E :Float) :TLine;
begin
  if E <> 0 then 
     Result := MoveSegment(L, CalcSegmentMove(L.P1, L.P2, E))
  else
    Result := L;
end;


function LineSlopeVector(const L :TSegment):TPoint;
begin
     Result.X := L.P2.X - L.P1.X;
     Result.Y := L.P2.Y - L.P1.Y;
end;

function SegmentSlopeVector(const L :TLine):TVector;
begin
     Result.X := L.P2.X - L.P1.X;
     Result.Y := L.P2.Y - L.P1.Y;
end;

function LineIntersectionParam(const A, B :TSegment):Float;
var
   da, db :TPoint;
   numer,
   denom :Float;
begin
   da := LineSlopeVector(A);
   db := LineSlopeVector(B);

   numer  := da.X * (B.P1.X - A.P1.X) - da.y * (B.P1.y - A.P1.Y);
   denom  := da.X * db.X - da.Y * db.Y;

   Result := numer/denom;
end;

function LineIntersection(const A, B :TSegment):TPoint;
var
   t :Float;
begin
   t := LineIntersectionParam(A, B);

   Result := Point( FloatToInt(t * B.P2.X + (1-t)*B.P1.X),
                    FloatToInt(t * B.P2.Y + (1-t)*B.P1.Y)
                    )
end;

function PointDistance(const P1, P2 :TPoint):Longint;
begin
     Result := FloatToInt(Sqrt(Sqr(1.0*P1.X-P2.X)+Sqr(1.0*P1.Y-P2.Y)))
end;

function PointDistance(const P1, P2 :TVector):Float;
begin
     Result := Sqrt(Sqr(P1.X-P2.X)+Sqr(P1.Y-P2.Y) +Sqr(P1.Z-P2.Z))
end;



function PointSum(const P1, P2 :TPoint) :TPoint;
begin
     Result.X := P1.X + P2.X;
     Result.Y := P1.Y + P2.Y;
end;

function PointSum(const P1, P2 :TVector) :TVector;
begin
     Result.X := P1.X + P2.X;
     Result.Y := P1.Y + P2.Y;
end;



function PointDiff(const P1, P2 :TPoint) :TPoint;
begin
     Result.X := Longint(P1.X) - P2.X;
     Result.Y := Longint(P1.Y) - P2.Y;
end;

function PointDiff(const P1, P2 :TVector) :TVector;
begin
     Result.X := P1.X - P2.X;
     Result.Y := P1.Y - P2.Y;
end;

function MovePoint(const P :TPoint; X, Y :Integer):TPoint;
begin
     Result := Point(P.X+X, P.Y+Y)
end;

procedure MovePoints(var P :array of TPoint; X, Y :Integer);
var
 i :Integer;
begin
  for i := Low(P) to High(P) do
    P[i] := MovePoint(P[i], X, Y)
end;

function MidPoint(const P1, P2 :TPoint):TPoint;
begin
     Result := Point((Longint(P1.X)+P2.X) div 2, (Longint(P1.Y)+P2.Y) div 2)
end;

function MidPoint(const P1, P2 :TVector):TVector;
begin
     Result := Vector((P1.X+P2.X)/2, (P1.Y+P2.Y)/2, (P1.Z+P2.Z)/2)
end;


function PointAngle(const p :TPoint):Float;
begin
     Result := atan2(p.X, p.Y);
end;

function Equal(const P1, P2 :TPoint):Boolean;
begin
     Result := (P1.X = P2.X) and (P1.Y = P2.Y)
end;

function Equal(const P1, P2 :TVector):Boolean;
begin
     Result := (P1.X = P2.X) and (P1.Y = P2.Y)
end;

function Equal(const R1, R2 :TRect):Boolean;
begin
   Result := Equal(R1.TopLeft, R2.TopLeft)
             and Equal(R1.BottomRight, R2.BottomRight)
end;

function Equal(const R1, R2 :TCube):Boolean;
begin
   Result := Equal(R1.TopLeft, R2.TopLeft)
             and Equal(R1.BottomRight, R2.BottomRight)
end;

function PointSize(const P :TVector) :Float;
begin
     Result := Sqrt(Sqr(P.X)+Sqr(P.Y)+Sqr(P.Z))
end;

function PointLength(const P :TPoint) :Longint;
begin
     Result := FloatToInt(PointSize(Vector(P)))
end;

function PointLength(const P :TVector) :Float;
begin
     Result := PointSize(P)
end;


function Compare(const P1, P2 :TPoint):Integer;
begin
     if Equal(P1, P2) then
        Result := 0
     else if PointLength(P1) < PointLength(P2) then
        Result := -1
     else
        Result := 1
end;

function Compare(const P1, P2 :TVector):Integer;
begin
  if Equal(P1, P2) then
    Result := 0
  else if PointLength(P1) < PointLength(P2) then
    Result := -1
  else
    Result := 1
end;

function PointMin(const P1, P2 :TPoint):TPoint;
begin
     Result := Point(Min(P1.X, P2.X), Min(P1.Y, P2.Y))
end;

function PointMax(const P1, P2 :TPoint):TPoint;
begin
     Result := Point(Max(P1.X, P2.X), Max(P1.Y, P2.Y))
end;

function PointMin(const P1, P2 :TVector):TVector;
begin
     Result := Vector(Min(P1.X, P2.X), Min(P1.Y, P2.Y))
end;

function PointMax(const P1, P2 :TVector):TVector;
begin
     Result := Vector(Max(P1.X, P2.X), Max(P1.Y, P2.Y))
end;

function LineAngle(const L :TSegment):Float;
begin
     Result := atan2(Longint(L.X2) - L.X1, Longint(L.Y2) - L.Y1)
end;

function LineAngle(const L :TLine):Float;
begin
     Result := atan2(L.X2 - L.X1, L.Y2 - L.Y1)
end;

function AngleBetweenLines(const L1, L2 :TSegment):Float;
begin
     Result := Abs(LineAngle(L1) - LineAngle(L2));
     if Result > Pi then
        Result := Result - 2*Pi
end;

function LineNearest(const P :TPoint; const L :TSegment) :TPoint;
var
   dx, dy,
   X, Y,
   slope,
   invSlope  :Float;
begin
     dx := L.X2 - L.X1;
     dy := L.Y2 - L.Y1;
     if dx = 0 then begin
        Result := Point(L.X1, P.Y);
     end
     else if dy = 0 then begin
        Result := Point(P.X, L.Y1);
     end
     else begin
          Slope     := dy/dx;
          InvSlope  := -1/Slope;
          X := ((P.Y - InvSlope*P.X) - (L.Y1 - Slope*L.X1))/(Slope-InvSlope);
          Y := Slope*(1.0*X -L.X1) + L.Y1;
          Result := Point(FloatToInt(x), FloatToInt(Y))
     end
end;

function SegmentNearest(const P :TPoint; const L :TSegment) :TPoint;
var
   Mid,
   Nearest    :TPoint;
   MidLen,
   NearDist   :Longint;
begin
     Mid      := MidSegment(L);
     MidLen   := SegmentLength(L) div 2;

     Nearest  := LineNearest(P, L);
     NearDist := PointDistance(Nearest, Mid);

     if NearDist <= MidLen then
        Result := Nearest
     else if PointDistance(L.P1, P) <= PointDistance(L.P2, P) then
        Result := L.P1
     else
        Result := L.P2
end;

function DistanceToLine2(const P :TPoint; const L :TSegment):Longint;
begin
     Result := PointDistance(P, LineNearest(P, L))
end;

function DistanceToSegment2(const P :TPoint; const L :TSegment):Longint;
begin
     Result := PointDistance(P, SegmentNearest(P, L))
end;

 function DistanceToLine(const P :TPoint; const L :TSegment):Longint;
 var
   da, db :TPoint;
   s      :Float;
 begin
   s  := SegmentLength(L);

   if (s = 0) then
     Result := PointDistance(P, L.P1)
   else begin
     da := LineSlopeVector(L);
     db := LineSlopeVector(Segment(L.P2, P));

     Result := FloatToInt(Abs(1.0*da.y*db.x - 1.0*da.x*db.y) / s);
   end
end;

function DistanceToSegment(const P :TPoint; const L :TSegment):Longint;
begin
      Result  := PointDistance(P, MidSegment(L));
      if Result < (SegmentLength(L) div 2) then
            { near enough to use distance to Segment }
            Result := DistanceToLine(P, L)
end;

function DistanceToSegment(const p :TVector; const L :TLine):Float;
 var
   da, db :TVector;
   s      :Float;
begin
   Result  := PointDistance(P, MidSegment(L));
   if Result < (SegmentLength(L) / 2) then begin
       s  := SegmentLength(L);

       if (s = 0) then
         Result := PointDistance(P, L.P1)
       else begin
         da := SegmentSlopeVector(L);
         db := SegmentSlopeVector(Segment(L.P2, P));

         Result := Abs(da.y*db.x - 1.0*da.x*db.y) / s;
       end
   end
end;

function EmptyRect :TRect;
begin
     Result.TopLeft     := Point(1,1);
     Result.BottomRight := Point(-1, -1);
end;

function EmptyCube :TCube;
begin
  Result.TopLeft     := Vector( 1, 1, 1);
  Result.BottomRight := Vector(-1,-1,-1);
end;

function IsEmpty(const R :TRect):Boolean;
begin
     Result :=  (R.Left > R.Right) or (R.Top > R.Bottom)
end;

function IsEmpty(const R :TCube):Boolean;
begin
     Result :=  (R.Left > R.Right) or (R.Top > R.Bottom) or (R.Back > R.Front);
end;

function Rect(X1, Y1, X2, Y2 :Integer) :TRect;
begin
     if X1 <= X2 then begin
        Result.Left  := X1;
        Result.Right := X2
     end
     else begin
        Result.Left  := X2;
        Result.Right := X1
     end;
     if Y1 <= Y2 then begin
        Result.Top    := Y1;
        Result.Bottom := Y2;
     end
     else begin
        Result.Top    := Y2;
        Result.Bottom := Y1;
     end;
end;

function Rect(const P :array of TPoint) :TRect;
var
  i :Integer;
begin
  Result.TopLeft     := P[0];
  Result.BottomRight := P[0];
  for i := Low(P)+1 to High(P) do
     Result := Union(Result, P[i]);
end;

function Cube(const P :array of TVector) :TCube;
var
  i :Integer;
begin
  Result.TopLeft     := P[0];
  Result.BottomRight := P[0];
  for i := Low(P)+1 to High(P) do
     Result := Union(Result, P[i]);
end;

function Cube(const P :TVectors) :TCube;
var
  i :Integer;
begin
  Result.TopLeft     := P[0];
  Result.BottomRight := P[0];
  for i := Low(P)+1 to High(P) do
     Result := Union(Result, P[i]);
end;


function Union(const R :TRect; Pt :array of TPoint):TRect;
var
  i :Integer;
begin
  for i := 0 to High(Pt) do
     with Pt[i] do
         if IsEmpty(R) then
            Result := JALGeometry.Rect(X, Y, X, Y)
         else begin
             Result := R;
             with Result do begin
                  if X < Left   then Left   := X;
                  if X > Right  then Right  := X;
                  if Y < Top    then Top    := Y;
                  if Y > Bottom then Bottom := Y;
             end
         end
end;

function Union(const R :TCube; const Pt :array of TVector):TCube;
var
  i :Integer;
begin
  Result := R;
  for i := 0 to High(Pt) do
    Result := Union(Result, Pt[i]);
end;

function Union(const R :TCube; const Pt :TVectors):TCube;
begin
  Result := Union(R, Cube(Pt));
end;

function Union(const R :TCube; const Pt :TVector):TCube;
begin

     //if (Pt.X <= 1) or (Pt.Y <= 1) then
     //  Beep(100, 1);
     with Pt do
         if IsEmpty(R) then
            Result := Cube(X, Y, X, Y)
         else begin
             Result := R;
             with Result do
             begin
                if X < Left   then
                  Left   := X
                else if X > Right then
                  Right  := X;

                if Y < Top    then
                  Top    := Y
                else if Y > Bottom then
                  Bottom := Y;

                if Z < Back   then
                  Back   := Z
                else if Z > Front then
                  Front := Z;
             end
         end
end;

function RectWidth(const R :TRect):Longint;
begin
   with R do
      Result := Abs(Longint(Right) - Left)
end;

function RectWidth(const R :TCube):Float;
begin
   with R do
      Result := Abs(Right - Left)
end;

function RectHeight(const R :TRect):Longint;
begin
   with R do
      Result := Abs(Longint(Bottom) - top)
end;

function RectHeight(const R :TCube):Float;
begin
   with R do
      Result := Abs(Bottom - top)
end;


function RectArea(const R :TRect):Longint;
begin
   Result := FloatToInt(1.0*RectWidth(R) * RectHeight(R))
end;

function RectArea(const R :TCube):Float;
begin
   Result := RectWidth(R) * RectHeight(R)
end;

function Intersection(const R1, R2 :TRect):TRect;
begin
     with Result do begin
          Left   := Max(R1.Left,   R2.Left);
          Top    := Max(R1.Top,    R2.Top);
          Right  := Min(R1.Right,  R2.Right);
          Bottom := Min(R1.Bottom, R2.Bottom)
     end
end;

function Union(const R1, R2 :TCube):TCube;
begin
 if IsEmpty(R1) then
   Result := R2
 else if IsEmpty(R2) then
   Result := R1
 else
 begin
   Result := Union(R1, R2.TopLeft);
   Result := Union(Result, R2.BottomRight);
 end;
end;


function RectsIntersect(const R1, R2 :TRect):Boolean;
begin
  if (R1.Right  < R2.Left)
  or (R1.Left   > R2.Right)
  or (R1.Bottom < R2.Top)
  or (R1.Top    > R2.Bottom) then
    Result := False
  else
    Result := True
end;


function CubesIntersect(const R1, R2 :TCube):Boolean;
begin
  if (R1.Right  < R2.Left)
  or (R1.Left   > R2.Right)
  or (R1.Bottom < R2.Top)
  or (R1.Top    > R2.Bottom) then
    Result := False
  else
    Result := True
end;

function MoveRect(const R :TRect; byX, byY :Integer) :TRect;
begin
     with Result do begin
          Left     := R.Left    + byX;
          Top      := R.Top     + byY;
          Right    := R.Right   + byX;
          Bottom   := R.Bottom  + byY;
     end
end;

function ExpandRect(const R :TRect; XExpandBy, YExpandBy :Integer):TRect;
begin
     with Result do begin
          Left     := R.Left    - XExpandBy;
          Top      := R.Top     - YExpandBy;
          Right    := R.Right   + XExpandBy;
          Bottom   := R.Bottom  + YExpandby;
     end
end;

function ExpandRect(const  R :TCube; XExpandBy, YExpandBy :Float):TCube;
begin
     with Result do begin
          Left     := R.Left    - XExpandBy;
          Top      := R.Top     - YExpandBy;
          Right    := R.Right   + XExpandBy;
          Bottom   := R.Bottom  + YExpandby;
     end
end;

function PointInRect(const P :TPoint; const R :TRect) :Boolean;
begin
     Result := (P.X >= R.Left) and (P.X <= R.Right) and
               (P.Y >= R.Top)  and (P.Y <= R.Bottom)
end;

function PointInRect(const P :TVector; const R :TCube) :Boolean;
begin
     Result := (P.X >= R.Left) and (P.X <= R.Right) and
               (P.Y >= R.Top)  and (P.Y <= R.Bottom)
end;

function ScaleRect(const R :TRect; ScaleX, ScaleY :Float) :TRect;
begin
     with Result do begin
       Left   := FloatToInt(R.Left   * ScaleX);
       Top    := FloatToInt(R.Top    * ScaleY);
       Right  := FloatToInt(R.Right  * ScaleX);
       Bottom := FloatToInt(R.Bottom * ScaleY);
     end
end;

{ Point and rectangle constructors }

function Point(AX, AY: Integer): TPoint;
begin
  with Result do begin
    X := AX;
    Y := AY;
  end;
end;

function Bounds(ALeft, ATop, AWidth, AHeight: Integer): TRect;
begin
  with Result do begin
    Left := ALeft;
    Top := ATop;
    Right := ALeft + AWidth;
    Bottom :=  ATop + AHeight;
  end;
end;

function Vector(X :Float; Y :Float; Z :Float):TVector;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

function Vector(const P :TPoint):TVector;
begin
  Result.X := P.X;
  Result.Y := P.Y;
  Result.Z := 0;
end;

function Point(const P :TVector):TPoint;
begin
  Result.X := FloatToInt(P.X);
  Result.Y := FloatToInt(P.Y);
end;

function ScalePoint(const P :TVector; Scale:Float) :TVector;
begin
   result.X := P.X * Scale;
   result.Y := P.Y * Scale;
end;

function Rect(R :TCube):TRect;
begin
  Result.TopLeft     := Point(R.TopLeft);
  Result.BottomRight := Point(R.BottomRight);
end;


function Cube(R :TRect):TCube;
begin
  Result.TopLeft     := Vector(R.TopLeft);
  Result.BottomRight := Vector(R.BottomRight);
end;


function Normalize(const P:TVector) : TVector;
var
  mag : Float;
begin
  mag := PointSize(p);
  result.x := p.x/mag;
  result.y := p.y/mag;
  result.z := p.z/mag;
end;

function CrossProduct(const p1,p2:TVector) : TVector;
begin
  result.x := p1.y*p2.z - p1.z*p2.y;
  result.y := p1.z*p2.x - p1.x*p2.z;
  result.z := p1.x*p2.y - p1.y*p2.x;
end;


function SlicePoints(const P :TPoints; i, n :Integer) :TPoints;
var
  k :Integer;
begin
  SetLength(Result, Min(n, Length(p)-i));
  for k := 0 to High(Result) do
    Result[k] := P[i+k];
end;


function BezierToRect(const B :TBezier):TRect;
begin
  Result := Rect(B);
end;

function MoveBezier(const L :TBezier; F :Integer):TBezier;
begin
   with CalcSegmentMove(L[0], L[3], F) do begin
      Result[0] := MovePoint(L[0], X, Y);
      Result[3] := MovePoint(L[3], X, Y);
   end;
   with CalcSegmentMove(L[1], L[2], F) do begin
      Result[1] := MovePoint(L[1], X, Y);
      Result[2] := MovePoint(L[2], X, Y);
   end
end;

function MidRect(const R :TRect):TPoint;
begin
   Result := MidPoint(R.TopLeft, R.BottomRight)
end;

function MidRect(const R :TCube):TVector;
begin
   Result := MidPoint(R.TopLeft, R.BottomRight)
end;

function ClipToRect(const P :TPoint; const R :TRect) :TPoint;
begin
   Result := P;
   if Result.X < R.Left then
      Result.X := R.Left
   else if Result.X > R.Right then
      Result.X := R.Right;

   if Result.Y < R.Top then
      Result.Y := R.Top
   else if Result.Y > R.Bottom then
      Result.Y := R.Bottom
end;

function ClipToRect(const P :TVector; const R :TCube) :TVector;
begin
   Result := P;
   if Result.X < R.Left then
      Result.X := R.Left
   else if Result.X > R.Right then
      Result.X := R.Right;

   if Result.Y < R.Top then
      Result.Y := R.Top
   else if Result.Y > R.Bottom then
      Result.Y := R.Bottom
end;


function Rect(const R:TRect) :TRect;
begin
  with Result do
  begin
    Left   := R.Left;
    Top    := R.Top;
    Right  := R.Right;
    Bottom := R.Bottom;
  end;
end;

function Points(const P:TVectors) :TPoints;
var
  i :Integer;
begin
  SetLength(Result, Length(P));
  for i := 0 to High(P) do
    Result[i] := Point(P[i]);
end;

function Points(const P:array of TPoint) :TPoints;
var
  i :Integer;
begin
  SetLength(Result, Length(P));
  for i := 0 to High(P) do
    Result[i] := P[i];
end;


function Identity :ITransf;
begin
  Result := TTransf.Create;
end;

function Scaling(const sx, sy, sz :Float) :ITransf;
begin
  Result := TTransf.InitScale(sx, sy, sz);
end;

function Traslation(const tx, ty, tz:Float) :ITransf;
begin
  Result := TTransf.initTraslate(tx, ty, tz);
end;

function XRotation(const ang:Float) :ITransf;
begin
  Result := TTransf.initRotateX(ang);
end;

function YRotation(const ang:Float) :ITransf;
begin
  Result := TTransf.initRotateY(ang);
end;

function ZRotation(const ang:Float) :ITransf;
begin
  Result := TTransf.initRotateZ(ang);
end;

function CoordChange(const vx, vy, vz :TVector) :ITransf;
begin
  Result := TTransf.initCoordChange(vx, vy, vz);
end;

function Apply(const T :ITransf; const v :TVector) :TVector;
begin
  if T = nil then
    Result := v
  else
    Result := T.Apply(v);
end;

function Apply(const T :ITransf; const v :array of TVector) :TVectors;
var
  i :Integer;
begin
  SetLength(Result, Length(v));
  for  i := 0 to High(v) do
    Result[i] := apply(T, v[i]);
end;

function Apply(const T :ITransf; const v :TVectors) :TVectors;
var
  i :Integer;
begin
  SetLength(Result, Length(v));
  for  i := 0 to High(v) do
    Result[i] := apply(T, v[i]);
end;

function Compose(const T1, T2 :ITransf) :ITransf;
begin
  if T1 = nil then
    Result := T2
  else if T2 = nil then
    Result := T1
  else
  begin
    Result := T1.clone;
    Result.compose(T2);
  end;
end;

procedure __init(var T:TMatrix); 
overload;
var
  i, j :Integer;
begin
  for i := 1 to 4 do
    for j := 1 to 4 do
      if i = j then
        T[i, j] := 1.0
      else
        T[i, j] := 0.0;
end;

procedure __init(var T:TMatrix; const Ax, Ay, Az :TVector); 
overload;
begin
  __init(T);

  T[1,1] :=Ax.x;  T[2,1] :=Ay.x;  T[3,1] :=Az.x;
  T[1,2] :=Ax.y;  T[2,2] :=Ay.y;  T[3,2] :=Az.y;
  T[1,3] :=Ax.z;  T[2,3] :=Ay.z;  T[3,3] :=Az.z;
end;

function __apply(const T :TMatrix; const p :TVector) :TVector; 
overload;
var
  f :Float;
begin
 with p do
 begin
    f := x*T[1,4]+y*T[2,4]+z*T[3,4]+T[4,4];
    
    Result.x := (x*T[1,1]+y*T[2,1]+z*T[3,1]+T[4,1])/f;
    Result.y := (x*T[1,2]+y*T[2,2]+z*T[3,2]+T[4,2])/f;
    Result.z := (x*T[1,3]+y*T[2,3]+z*T[3,3]+T[4,3]);
  end;
end;

function __apply(const T :TMatrix; const p :TPoint) :TPoint; 
overload;
begin
  Result := Point(__apply(T, Vector(p)));
end;

{ TTransf }

constructor TTransf.Create;
begin
  identity
end;

constructor TTransf.identity;
begin
  inherited Create;
  __init(_mat);
  _inv := _mat
end;

constructor TTransf.initScale(const sx, sy, sz :Float);
begin
  Create;
  _mat[1,1] := sx;
  _mat[2,2] := sy;
  _mat[3,3] := sz;
  if sx <> 0
  then
  _inv[1,1] := 1/sx;
  if sy <> 0
  then
  _inv[2,2] := 1/sy;
  if sz <> 0
  then
  _inv[3,3] := 1/sz;
end;

constructor TTransf.initTraslate(const tx, ty, tz:Float);
begin
  Create;
  _mat[4,1] := tx;
  _mat[4,2] := ty;
  _mat[4,3] := tz;

  _inv[4,1] := -tx;
  _inv[4,2] := -ty;
  _inv[4,3] := -tz;
end;

constructor TTransf.initRotateX(const ang:Float);
begin
  Create;
  _mat[2,2] := cos(ang);
  _mat[2,3] := sin(ang);
  _mat[3,3] := cos(ang);
  _mat[3,2] := -sin(ang);

  _inv[2,2] := cos(-ang);
  _inv[2,3] := sin(-ang);
  _inv[3,3] := cos(-ang);
  _inv[3,2] := -sin(-ang);
end;

constructor TTransf.initRotateY(const ang:Float);
begin
  Create;
  _mat[1,1] := cos(ang);
  _mat[1,3] := sin(ang);
  _mat[3,1] := -sin(ang);
  _mat[3,3] := cos(ang);

  _inv[1,1] := cos(-ang);
  _inv[1,3] := sin(-ang);
  _inv[3,1] := -sin(-ang);
  _inv[3,3] := cos(-ang);
end;

constructor TTransf.initRotateZ(const ang:Float);
begin
  Create;
  _mat[1,1] := cos(ang);
  _mat[1,2] := sin(ang);
  _mat[2,2] := cos(ang);
  _mat[2,1] := -sin(ang);

  _inv[1,1] := cos(-ang);
  _inv[1,2] := sin(-ang);
  _inv[2,2] := cos(-ang);
  _inv[2,1] := -sin(-ang);
end;

constructor TTransf.initCoordChange(const vx, vy, vz :TVector);
begin
  Create;

  __init(_mat, Normalize(vx), Normalize(vy), Normalize(vz));
  __init(_inv, Normalize(__apply(_mat, Vector(1,0,0))),
               Normalize(__apply(_mat, Vector(0,1,0))),
               Normalize(__apply(_mat, Vector(0,0,1)))
               );
end;

constructor TTransf.copy(const T : ITransf);
begin
  inherited Create;

  self._mat := T.mat;
  self._inv := T.inv;
end;


procedure TTransf.compose(const T :ITransf);
var
  i, j, k :Integer;
  sum, sum_1 :Float;
  C, C_1   :TMatrix;
  D, D_1   :TMatrix;
begin
  C   := _mat;
  C_1 := _inv;

  D   := T.mat;
  D_1 := T.inv;

  for i := 1 to 4 do
  begin
    for j := 1 to 4 do
    begin
      sum   := 0.0;
      sum_1 := 0.0;
      for k := 1 to 4 do
      begin
        sum := sum + C[i,k]*D[k,j];
        sum_1 := sum_1 + D_1[i,k]*C_1[k,j];
      end;
      _mat[i,j] := sum;
      _inv[i,j] := sum_1
    end;
  end;
end;

procedure TTransf.scale(const sx, sy, sz :Float);
begin
  Compose(Scaling(sx, sy, sz));
end;

procedure TTransf.traslate(const tx, ty, tz:Float);
begin
  compose(Traslation(tx, ty, tz));
end;

procedure TTransf.traslate(const p :TVector);
begin
  with p do
    Traslate(x, y, z);
end;

procedure TTransf.rotateX(const ang:Float);
begin
  compose(XRotation(ang));
end;

procedure TTransf.rotateY(const ang:Float);
begin
  compose(YRotation(ang));
end;

procedure TTransf.rotateZ(const ang:Float);
begin
  compose(ZRotation(ang));
end;


procedure TTransf.ChangeCoords(const vx, vy, vz :TVector);
begin
  compose(coordChange(vx, vy, vz));
end;

function TTransf.apply(const p :TVector) :TVector;
begin
  Result := __apply(_mat, p);
end;

function TTransf.unapply(const p :TVector) :TVector;
begin
  Result := __apply(_inv, p);
end;

function TTransf.apply(const p: TPoint): TPoint;
begin
  Result := __apply(_mat, p);
end;

function  TTransf.apply(const p :TVectors)  :TVectors;
var
  i :Integer;
begin
  SetLength(Result, Length(p));
  for i := 0 to High(p) do
    Result[i] := apply(p[i]);
end;

function TTransf.unapply(const p: TPoint): TPoint;
begin
  Result := __apply(_inv, p);
end;

function TTransf.clone: ITransf;
var
  T :TTransf;
begin
  T := TTransf.Create;
  T._mat := self._mat;
  T._inv := self._inv;

  Result := T;
end;

function TTransf.mat: TMatrix;
begin
  Result := _mat;
end;

function TTransf.inv: TMatrix;
begin
  Result := _inv;
end;

function Point3(x, y, z :Integer) :TPoint3;
begin
  Result.X := x;
  Result.Y := y;
  Result.Z := z;
end;

function Point3(const P :TPoint; z :Integer) :TPoint3;
begin
  Result.X := P.X;
  Result.Y := P.Y;
  Result.Z := z;
end;



end.
