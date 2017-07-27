unit uProps;

{$WRITEABLECONST ON}

interface

uses
  SysUtils, TypInfo, StrUtils, Variants, RTLConsts;

const
  // флаг преобразования булевых типов данных
  // т.е. "true" -> "1"
  PropsConvertBooleanStrToInteger: boolean = False;
  UNDERLINE_CHAR = '_';

function GetPublishedPropRealName(Instance: TObject; var PropName: string): boolean; 

function IsPublishedPropExt(Instance: TObject; const PropName: string): boolean; overload;
function IsPublishedPropExt(Instance: TObject; PropInfo: PPropInfo): boolean; overload;

function GetPropValueExt(Instance: TObject; const PropName: string;
  PreferStrings: Boolean = True): Variant; overload;
function GetPropValueExt(Instance: TObject; PropInfo: PPropInfo;
  PreferStrings: Boolean = True): Variant; overload;
function SetPropValueExt(Instance: TObject; const PropName: string;
  const Value: Variant): boolean; overload;
function SetPropValueExt(Instance: TObject; PropInfo: PPropInfo;
  const Value: Variant): boolean; overload;

function PropIsTypeExt(Instance: TObject; const PropName: string;
  TypeKind: TTypeKind): Boolean;

implementation

function ConvertSeparator(Str: string): string;
begin
  Result := StringReplace(Str, '.', DecimalSeparator, [rfReplaceAll]);
end;

function GetPublishedPropRealName(Instance: TObject; var PropName: string): boolean;
var
  s: string;
begin
  Result := IsPublishedProp(Instance, PropName);
  if Result then
    Exit;
  s := '_' + PropName;
  Result := IsPublishedProp(Instance, s);
  // если нет такого свойства
  if not Result
    // и в имени есть "-" (точнее, это не рекурсивный вызов)
    and (PropName <> StringReplace(PropName, '-', UNDERLINE_CHAR,
      [rfReplaceAll])) then
  begin
    s := StringReplace(PropName, '-', UNDERLINE_CHAR, [rfReplaceAll]);
    Result := GetPublishedPropRealName(Instance, s);
  end;
  if Result then
    PropName := s;
end;

function IsPublishedPropExt(Instance: TObject; const PropName: string): Boolean;
begin
  Result := IsPublishedProp(Instance, PropName);
  if not Result then
    Result := IsPublishedProp(Instance, '_' + PropName);
end;

function IsPublishedPropExt(Instance: TObject; PropInfo: PPropInfo): boolean; overload;
begin
  Result := IsPublishedPropExt(Instance, PropInfo.Name);
end;

function GetPropValueExt(Instance: TObject; const PropName: string;
  PreferStrings: Boolean = True): Variant;
var
  PropInfo: PPropInfo;
  s: string;
begin
  s := PropName;
  if not GetPublishedPropRealName(Instance, s) then
    raise EPropertyError.CreateResFmt(@SUnknownProperty, [PropName]);
  PropInfo := GetPropInfo(Instance, s);
  if Assigned(PropInfo^.GetProc) then
    Result := GetPropValue(Instance, s)
  else
    Abort;
end;

function GetPropValueExt(Instance: TObject; PropInfo: PPropInfo;
  PreferStrings: Boolean = True): Variant;
begin
  Result := GetPropValueExt(Instance, PropInfo.Name, PreferStrings);
end;

function SetPropValueExt(Instance: TObject; const PropName: string;
  const Value: Variant): boolean;
var
  PropInfo     : PPropInfo;
  StrTypeData  : string;

  IntValue     : Integer;
  RealValue    : Extended;
  s: string;
  bool: boolean;
  PName: string;
begin
  Result := False;
  PName := PropName;
  if not GetPublishedPropRealName(Instance, PName) then
    Exit;
  try
    IntValue := 0;
    PropInfo := GetPropInfo(Instance, PName);
    // если свойство readonly
    if PropInfo^.SetProc = nil then
      Exit;
    StrTypeData := PropInfo.PropType^.Name;
    if AnsiContainsText(StrTypeData, 'boolean') then
    begin
      s := VarToStr(Value);
      if PropsConvertBooleanStrToInteger then
      begin
        TryStrToInt(s, IntValue);
        SetPropValue(Instance, PName, boolean(IntValue));
      end
      else
      begin
        if s = '' then
          bool := True
        else
          bool := StrToBoolDef(s, True);
//          bool := boolean(GetEnumValue(TypeInfo(boolean), StrToBoolDef(s, True)));
        SetPropValue(Instance, PName, bool);
      end;
    end
    else if AnsiContainsText(StrTypeData, 'real')
      or AnsiContainsText(StrTypeData, 'extended')
      or AnsiContainsText(StrTypeData, 'currency') then
    begin
      RealValue := StrToFloatDef(ConvertSeparator(VarToStr(Value)), 0);
      SetPropValue(Instance, PName, RealValue);
    end
    else if AnsiContainsText(StrTypeData, 'Integer') then
      SetPropValue(Instance, PName, StrToIntDef(VarToStr(Value), 0))
    else
      SetPropValue(Instance, PName, VarToStr(Value));
    Result := True;
  except
    on E: EPropertyError do ;
    on E: EPropertyConvertError do ;
    on E: ERangeError do ;
    on E: EVariantTypeCastError do
      raise EVariantTypeCastError.CreateFmt('Invalid value "%s" for property "%s"',
        [Value, PropName]);
    on E: Exception do
      raise;
  end;
end;

function SetPropValueExt(Instance: TObject; PropInfo: PPropInfo;
  const Value: Variant): boolean;
begin
  Result := SetPropValueExt(Instance, PropInfo.Name, Value);
end;

function PropIsTypeExt(Instance: TObject; const PropName: string;
  TypeKind: TTypeKind): Boolean;
var
  s: string;
  {$IFOPT D+}
  tk: TTypeKind;
  {$ENDIF}
begin
  Result := False;
  s := PropName;
  if GetPublishedPropRealName(Instance, s) then
  begin
    {$IFOPT D+}
    tk := PropType(Instance, s);
    {$ENDIF}
    Result := PropIsType(Instance, s, TypeKind);
  end;
end;
  
end.