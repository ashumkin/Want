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

{#(@)$Id: JalDXF.pas 771 2004-05-08 16:15:25Z juanco $}

unit JalDXF;

interface
uses
  SysUtils,
  Math,
  Graphics,

  JalMath,
  JalStrings,
  JalGeometry,
  JalGeomModels,
  JalParse;

type
  TTokenType = (tokAttribute);

  TDXFParser = class(TParser)
  protected
    tokenType  :TTokenType;
    tokenCode  :Integer;
    tokenValue :string;

    _model         :IModel;
    _entity        :IEntity;
  public
    constructor Create;

    destructor Destroy; override;

    procedure parse; override;

    property Model :IModel read _model;
  protected

    function isSpace(c :Char) : boolean;  override;

    function nextToken :TTokenType;
    function scanGroup(code :Integer; Value :string = '') :string;
    function checkGroup(code :Integer; Value :string = '') :string;
    function testGroup(code :Integer; Value :string = ''; Scan :boolean = true) :boolean;

    function IntValue   :Integer;
    function FloatValue :double;

    function  Name :string;

    function  Section :string;
    function  EndSection :boolean;
    procedure CheckEndSection;


    procedure Headers;
    procedure Variable;

    function  Attribute :boolean;
    procedure Attributes;

    function  ColorNum :boolean;

    procedure Tables;
    procedure Table;
    function  VPort :boolean;
    function  LType :boolean;
    function  Layer :boolean;
    function  Style :boolean;
    function  AppID :boolean;
    function  DimStyle: boolean;
    function  Block_Record: boolean;
    function  PolylineFlags :boolean;

    procedure Classes;
    procedure Klass;

    procedure Blocks;
    procedure Block;

    procedure Objects;
    procedure Entities;
    procedure Entity;

    procedure Line;
    procedure Polyline;

    function Vertex :boolean;
    function Point  :boolean;
    function LayerName :boolean;
  end;

implementation

const
  DXF_start            = 0;
  DXF_text_def         = 1;
  DXF_name             = 2;
  DXF_text_prompt      = 3;
  DXF_othername2       = 4;
  DXF_entity_handle    = 5;
  DXF_line_type        = 6;
  DXF_text_style       = 7;
  DXF_layer_name       = 8;
  DXF_var_name         = 9;
  DXF_primary_X        = 10;
  DXF_primary_Y        = 20;
  DXF_primary_Z        = 30;
  DXF_other_X_1        = 11;
  DXF_other_Y_1        = 21;
  DXF_other_Z_1        = 31;
  DXF_other_X_2        = 12;
  DXF_other_Y_2        = 22;
  DXF_other_Z_2        = 32;
  DXF_other_X_3        = 13;
  DXF_other_Y_3        = 23;
  DXF_other_Z_3        = 33;
  DXF_elevation        = 38;
  DXF_thickness        = 39;
  DXF_floatval         = 40;
  DXF_floatvals1       = 41;
  DXF_floatvals2       = 42;
  DXF_floatvals3       = 43;
  DXF_repeat           = 49;
  DXF_angle1           = 50;
  DXF_angle2           = 51;
  DXF_angle3           = 52;
  DXF_angle4           = 53;
  DXF_angle5           = 54;
  DXF_angle6           = 55;
  DXF_angle7           = 56;
  DXF_angle8           = 57;
  DXF_angle9           = 58;
  DXF_visible          = 60;
  DXF_colornum         = 62;
  DXF_entities_flg     = 66;
  DXF_ent_ident        = 67;
  DXF_view_state       = 69;
  DXF_70Flag           = 70;
  DXF_71Flag           = 71;
  DXF_72Flag           = 72;
  DXF_73Flag           = 73;
  DXF_74Flag           = 74;
  DXF_extrusionx       = 210;
  DXF_extrusiony       = 220;
  DXF_extrusionz       = 230;
  DXF_comment          = 999;

  DXF_PolylineFlags    = DXF_70Flag;

const
     ColorTable : array[-1..15] of TColor =
       (
       {-1} clWhite,
       { 0} clGray,
       { 1} clRed,
       { 2} clFuchsia,
       { 3} clYellow,
       { 4} clLime,
       { 5} clAqua,
       { 6} clBlue,
       { 7} clMaroon,
       { 8} clPurple,
       { 9} clOlive,
       {10} clGreen,
       {11} clTeal,
       {12} clNavy,
       {13} $00C000C0,
       {14} $0000007F,
       {15} clBlack
       );

{ TDXFParser }

constructor TDXFParser.Create;
begin
  inherited Create;
  _model := TModel.Create;
end;

destructor TDXFParser.Destroy;
begin
  inherited Destroy;
end;

function TDXFParser.isSpace(c: Char): boolean;
begin
  case c of
     #$20, #$9, #$D:
       Result := True;
  else
    Result := False;
  end;
end;


function TDXFParser.nextToken: TTokenType;
begin
  tokenCode  := StrToIntDef(toEOL, -1);
  tokenValue := toEOL;

  tokenType := tokAttribute;

  Result := tokenType;
end;

function TDXFParser.scanGroup(code: Integer; Value: string): string;
begin
  Result := checkGroup(code, Value);
  NextToken;
end;

function TDXFParser.checkGroup(code: Integer; Value: string): string;
begin
  if tokenCode <> code then
    Error('Expected code %d %s, but was %d', [ code, Value, TokenCode]);

  if (Value <> '') and (Value <> TokenValue) then
    Error('Expected code %d and value %s, but was %d %s', [ code, Value, TokenCode, TokenValue]);

  Result := TokenValue;
end;

function TDXFParser.testGroup(code: Integer; Value: string; Scan :boolean): boolean;
begin
  Result := (tokenCode = code)
            and ((Value = '') or (Value = TokenValue));
  if Result then
    NextToken;
end;

procedure TDXFParser.parse;
var
  What,
  Name  :string;
begin
  NextToken;
  while not eof do
  begin
    What := scanGroup(dxf_Start);
    if What = 'EOF' then
      break
    else if What <> 'SECTION' then
      Error('Expected "SECTION"');

    Name := Self.Name;

    if Name = 'HEADER' then
      Headers
    else if Name = 'TABLES' then
      Tables
    else if Name = 'CLASSES' then
      Classes
    else if Name = 'BLOCKS' then
      Blocks
    else if Name = 'ENTITIES' then
      Entities
    else if Name = 'OBJECTS' then
      break //Objects
    else
      Error('Unexpected section %s', [Name]);
  end;
end;

function TDXFParser.Name: string;
begin
  Result := scanGroup(dxf_Name);
end;

function TDXFParser.Section :string;
begin
  scanGroup(dxf_Start, 'SECTION');
  Result := Name;
end;

function TDXFParser.EndSection :boolean;
begin
  Result := testGroup(dxf_Start, 'ENDSEC');
end;

procedure TDXFParser.CheckEndSection;
begin
  scanGroup(dxf_Start, 'ENDSEC');
end;

procedure TDXFParser.Headers;
begin
  while not EndSection do
    Variable;
end;

procedure TDXFParser.Variable;
var
  VarName :string;
begin
  VarName := ScanGroup(dxf_var_Name);
  if (Length(VarName) = 0) or (VarName[1] <> '$') then
    Error('Expected variable name', [VarName]);
  Attributes;
end;

procedure TDXFParser.Tables;
begin
  while not EndSection do
    Table;
end;

procedure TDXFParser.Table;
begin
  ScanGroup(dxf_Start, 'TABLE');
  Name;
  while Attribute
        or VPort
        or LType
        or Layer
        or Style
        or AppID
        or DimStyle
        or Block_Record
  do
  begin
  end;
  scanGroup(dxf_Start, 'ENDTAB');
end;

function TDXFParser.VPort :boolean;
begin
  Result  := testGroup(dxf_Start, 'VPORT');
  if Result then
    Attributes;
end;

function TDXFParser.LType :boolean;
begin
  Result  := testGroup(dxf_Start, 'LTYPE');
  if Result then
    Attributes;
end;

function TDXFParser.Layer :boolean;
begin
  Result  := testGroup(dxf_Start, 'LAYER');
  if Result then
    Attributes;
end;

function TDXFParser.Style: boolean;
begin
  Result  := testGroup(dxf_Start, 'STYLE');
  if Result then
    Attributes;
end;

function TDXFParser.AppID: boolean;
begin
  Result  := testGroup(dxf_Start, 'APPID');
  if Result then
    Attributes;
end;

function TDXFParser.DimStyle : boolean;
begin
  Result  := testGroup(dxf_Start, 'DIMSTYLE');
  if Result then
    Attributes;
end;

function TDXFParser.Block_Record: boolean;
begin
  Result  := testGroup(dxf_Start, 'BLOCK_RECORD');
  if Result then
    Attributes;
end;

procedure TDXFParser.Blocks;
begin
  while not EndSection do
  begin
    Block;
    Attributes;
  end;
end;

procedure TDXFParser.Block;
begin
  ScanGroup(dxf_Start, 'BLOCK');
  while not testGroup(dxf_Start, 'ENDBLK') do
    NextToken;
  NextToken;
end;

procedure TDXFParser.Classes;
begin
  while not EndSection do
    Klass;
end;

procedure TDXFParser.Klass;
begin
  ScanGroup(dxf_Start, 'CLASS');
  Attributes;
end;

procedure TDXFParser.Objects;
begin
  while not EndSection do
    NextToken;
end;

procedure TDXFParser.Entities;
begin
  while not EndSection do
    Entity;
end;


procedure TDXFParser.Entity;
var
  Kind :string;
begin
  _entity := nil;

  Kind := scanGroup(0);
  if (Pos('POLYLINE', Kind) <> 0) then
    Polyline
  else if KIND = 'LINE' then
    Line
  else
  begin
    while Attribute do
    begin
    end;
  end;
end;

procedure TDXFParser.Line;
begin
  _entity := TPolyLine.Create;

  while LayerName
        or Point
        or ColorNum
        or Attribute do
  begin
  end;
end;

procedure TDXFParser.Polyline;
begin
  _entity := TPolyLine.Create;
  _entity.SetSize(64);

  while LayerName
        or Vertex
        or PolylineFlags
        or Attribute do
  begin
  end;
  _entity.SizeToFit;
end;

function TDXFParser.PolylineFlags: boolean;
begin
  if TokenCode <> DXF_PolylineFlags then
    Result := false
  else
  begin
    self._entity.Closed := (StrToIntDef(TokenValue,0) and $1) <> 0;
    NextToken;
    Result := true;
  end;
end;




function TDXFParser.Attribute :boolean;
begin
  Result := (TokenCode >= 1) and (TokenCode <= 8)
            or (TokenCode >= 10);
  if Result then
    NextToken;
end;

procedure TDXFParser.Attributes;
begin
  while Attribute do
  begin
  end;
end;

function TDXFParser.ColorNum: boolean;
var
  i :Integer;
begin
  Result := (TokenCode = DXF_colornum);
  if Result then
  begin
    if _entity <> nil then
    begin
      i := IntValue;
      i := Max(Low(ColorTable), Min(High(ColorTable), i));
      _entity.Color := ColorTable[i];
    end;
    NextToken;
  end;
end;

function TDXFParser.Vertex : boolean;
begin
  Result  := testGroup(dxf_Start, 'VERTEX');
  if Result then
  begin
    while Point or Attribute do
    begin
    end;
  end;
end;

function TDXFParser.Point: boolean;
var
  v :TVector;
  n :Integer;
begin
  Result := False;
  if (TokenCode >= 10) and (TokenCode < 20) then
  begin
    Result := True;

    n := TokenCode - 10;
    v.x := FloatValue;
    NextToken;

    v.y := FloatValue;

    if TokenCode = (30+n) then
    begin
      v.z := FloatValue;
      NextToken;
    end
    else
      v.z := 0;

    if _entity <> nil then
      _entity.AddPoint(v);
  end;
end;

function TDXFParser.LayerName: boolean;
var
  layer :ILayer;
begin
  Result := False;
  if TokenCode = dxf_Layer_Name then
  begin
    Result := True;

    layer := _model.NewLayer(TokenValue);
    if _entity <> nil then
      layer.AddChild(_entity);

    NextToken;
  end;
end;

function TDXFParser.FloatValue: double;
var
  num :string;
begin
  num := Trim(TokenValue);
  num := StringReplace(num, ',', '', []);
  if DecimalSeparator <> '.' then
    num := StringReplace(num, '.', DecimalSeparator, []);
  Result := StrToFloatDef(num, 0);
end;


function TDXFParser.IntValue: Integer;
begin
  Result := StrToIntDef(Trim(TokenValue), 0);
end;


end.
