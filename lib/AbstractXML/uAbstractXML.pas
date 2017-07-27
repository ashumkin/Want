{-------------------------------------------------------------------------------
Сериализатор/десериализатор классов в XML
feat. Шумкин Алексей 
-------------------------------------------------------------------------------}
//{$DEFINE UPPERCASE}
unit uAbstractXML;

interface

Uses
  Windows, TypInfo, Classes, SysUtils, StrUtils,
  SimpleXML, uProps, uEncoder;

Type
  TStringMethod = function: Variant of object;

  TAXAbstractClass = class of TAXAbstract;
  TAXAbstract = class (TPersistent)
  private
    FOwner        : TAXAbstract;   // Родитель
    FAXClassName  : String;        // Имя класса (не путать с ClassName объекта)
    FFieldCount   : Integer;       // Количество полей класса AX (атрибутов в XML ноде)
    FisLocked     : Boolean;       // Признак того, что AX-объект занят кем-то (нельзя удалить)
    FisDeleted    : Boolean;
    FContextDOM   : IXMLDocument;
    FNodeValue: string;
    FPropsInChildNodes: TStringList;
    FxmlEncoding: string;
    FxmlVersion: string;
    FnodeType: Integer;
    FnodeTypes: TStrings;
    function GetChildAXCount: Integer;
    // Получить дочерний AX-объект по индексу
    function GetChildAX(Index: Integer): TAXAbstract;
    function GetChildAXByClass(Index : Integer; _Class : TClass): TAXAbstract;
    function GetChildAXCountByClass(_Class : TClass): Integer;
    function GetIsMisc: boolean;
    function ChildContextToElement(Child: TAXAbstract): IXMLElement;
    function IsPropInChildNodes(const PropName: string): boolean;
    function GetRootOwner: TAXAbstract;
    procedure AddAllPropsToChildNodes;
    function GetxmlEncoding: string;
    procedure SetxmlEncoding(const Value: string);
    function GetxmlVersion: string;
    procedure SetxmlVersion(const Value: string);
    procedure InitProcessingInstructions(pNode: IXmlNode);
    procedure SetAXClassName(const Value: string);
    function GetAXClassName: string;
    function GetAXIndex: Integer;

    // имя класса AX-объекта
    property AXClassName: string read GetAXClassName write SetAXClassName;
  protected
    FChildrenAX     : TList;   // Дочерние класcы данных
    // копирование свойств других экземпляров
    procedure AssignTo(Dest: TPersistent); override;
    // Инициализаци полей объекта и дочерних объектов
    function Init: boolean; virtual;
    // Удаление AX-объекта из родителя
    procedure DeleteFromOwner;
    function CheckAddClassInstance(_Class: TClass): TAXAbstract;
    procedure AddPropToChildNodes(const PropName: string); virtual;
    procedure DoSetPropsInChildNodes; virtual;
    procedure DoAfterCreate; virtual;
    procedure DoAfterInit; virtual;
    procedure DoAfterChildAdd(Item: TAXAbstract); virtual;
    function CreateAXClass(AXClassName: string): TObject;
    function PropertyValue(const Name: string): string; virtual;
    function Evaluate(const Value: string): string;
    function AreAllPropsChildNodes: boolean; virtual;
    function ConvertText(const pText: string; pForSave: boolean = False): string;

    class function TagName: string; virtual;
    class function doPrefix: string; virtual;
    class function GetAXClass(const _ClassName: string): TClass; virtual;
  public
    constructor Create(AOwner: TAXAbstract = nil);
    constructor CreateByContext(const AContext: string;
      AOwner: TAXAbstract = nil); overload; virtual;
    destructor Destroy; override;

    function LoadFromContext(const AContext: string): boolean;
    function LoadFromFile(const FileName: string): boolean;
    function SaveContext(ReplaceTabs: boolean = False;
      pClone: boolean = False): string; virtual;
    function SaveCloneContext(ReplaceTabs: boolean = False): string;
    function SaveToFile(const FileName: string; ReplaceTabs: boolean = False): boolean;

    // Добавление AX-объекта
    function Add(Item: TAXAbstract): Integer; virtual;
    // Вставка AX-объекта
    procedure Insert (Item : TAXAbstract; Position: Integer);
    // Удаление AX-объекта
    procedure Delete (DeletedItem : TAXAbstract); overload;
    // Удаление AX-объекта
    procedure Delete(Index : Integer) ; overload;
    // Изменение мест AX-объекта
    procedure Exchange(Index1, Index2 : Integer) ; overload;
    // Перемещение AX-объекта
    procedure Move(CurIndex, NewIndex : Integer) ; overload;
    procedure Clear; 
    function Clone: TAXAbstract;
    function FindClass(_Class : TClass; AXObject : TAXAbstract = nil): TAXAbstract;
    function GetFirstByClass(_Class : TClass) : TAXAbstract;
    function GetChildFromStr(ChildStr: string): TAXAbstract;
    function GetValueFromStr(ValueStr: string): Variant;
    function GetParentsChain(const PropName: string = ''): string; overload;
    function GetParentsChain(PropInfo: PPropInfo): string; overload;
    function ApplyTemplate(pTemplate: TAXAbstract): boolean;
    procedure Sort(Compare: TListSortCompare);

    // количество дочерних AX-объектов
    property Count : Integer read GetChildAXCount;
    property CountByClass[_Class : TClass] : Integer read GetChildAXCountByClass;
    // дочерние AX-объекты
    property ChildAX[Index : Integer]: TAXAbstract read GetChildAX; default;
    property ChildAXByClass[Index : Integer; _Class : TClass]: TAXAbstract read GetChildAXByClass;
    property isMisc : Boolean read GetisMisc;
    property AXIndex: Integer read GetAXIndex;
    property Owner : TAXAbstract read FOwner;

    property NodeValue: string read FNodeValue write FNodeValue; // значение #text узла
    property RootOwner: TAXAbstract read GetRootOwner; // самый первый родитель (верхний узел)
    property _xmlEncoding: string read GetxmlEncoding write SetxmlEncoding;
    property _xmlVersion: string read GetxmlVersion write SetxmlVersion;
    property _nodeType: Integer read FnodeType;
  published
  end;

const
  _TEXT = '#text';
  _AXT = '.';

var
  // опция преобразования логических типов данных, если true,
  // то строка "true" преобразуется в "1"
  doConvertBooleanStrToInteger: boolean = True;

function _UpperCase(const Str : String):String;

procedure RegisterAXClass(AXClass: TPersistentClass);
procedure RegisterAXClasses(AXClasses: array of TPersistentClass);
procedure RegisterAXSubClass(AXSubClassParent, AXSubClass: TAXAbstractClass);

procedure CheckPropertyOnNil(PropertyName : String);
function IsCheckProperty(PropertyName : String) : Boolean;

implementation

uses Variants;

type
  TAXSubClassesRecord = record
    _TagName: string;
    _SubClass: TAXAbstractClass;
    _SubClassParent: TAXAbstractClass;
  end;

Var
  CheckProperty: array of string;
  __RegisteredSubClasses: array of TAXSubClassesRecord;

function _UpperCase(const Str : String):String;
begin
  Result := Str;
  {$IFDEF UPPERCASE}
  Result := UpperCase(Str);
  {$ENDIF}
end;

Function ConvertSeparator(const pStr: string): String;
begin
  Result := StringReplace(pStr, _AXT, ',', [rfReplaceAll]);
end;

function IsCheckProperty(PropertyName : String) : Boolean;
Var
  I : Integer;
begin
  Result := false;
  for I := 0 to Length(CheckProperty) - 1 do
    if (PropertyName = CheckProperty[i]) then
    begin
      Result := true;
      Exit;
    end;
end;

function FindSubClass(const AXSubClassName: string; AXSubClassParent: TClass): TAXAbstractClass;
var
  i: Integer;
begin
  Result := nil;
  for i := High(__RegisteredSubClasses) downto Low(__RegisteredSubClasses) do
  begin
    with __RegisteredSubClasses[i] do
    begin
      if not AnsiSameText(_TagName, AXSubClassName) then
        Continue;
      if not Assigned(AXSubClassParent)
        or not Assigned(_SubClassParent)
        or AXSubClassParent.InheritsFrom(_SubClassParent) then
      begin
        Result := _SubClass;
        Break;
      end
    end;
  end
end;

procedure RegisterAXClass(AXClass : TPersistentClass); overload;
begin
  RegisterClass(AXClass);
end;

procedure RegisterAXClasses(AXClasses: array of TPersistentClass);
begin
  RegisterClasses(AXClasses);
end;

procedure RegisterAXSubClass(AXSubClassParent, AXSubClass: TAXAbstractClass);
var
  pos: Integer;
begin
  Assert(Assigned(AXSubClass));

  pos := Length(__RegisteredSubClasses);
  SetLength(__RegisteredSubClasses, 1 + pos);

  with __RegisteredSubClasses[pos] do
  begin
    _SubClass := AXSubClass;
    _TagName := AXSubClass.TagName;
    _SubClassParent := AXSubClassParent;
  end;
//  RegisterAXClass(TPersistentClass(AXSubClass));
end;

procedure CheckPropertyOnNil(PropertyName : String);
begin
  SetLength(CheckProperty, Length(CheckProperty) + 1);
  CheckProperty[Length(CheckProperty) - 1] := PropertyName;
end;

function GetPropValueEx(Instance: TObject; const PropName: string): Variant; overload;
begin
  if uProps.IsPublishedPropExt(Instance, PropName) then
    Result := uProps.GetPropValueExt(Instance, PropName)
  else
    Result := NULL;
end;

function GetPropValueEx(Instance: TObject; PropInfo: PPropInfo): Variant; overload;
begin
  Result := GetPropValueEx(Instance, PropInfo.Name);
end;

{ TAXAbstract }

function TAXAbstract.Add(Item : TAXAbstract): Integer;
begin
  Item.FOwner := Self;
  FChildrenAX.Capacity := Count + 1;
  Result := FChildrenAX.Add(Item);
  DoAfterChildAdd(Item);
end;

function TAXAbstract.Clone: TAXAbstract;
Var
  Context  : String;
  AXObject : TObject;
begin
  Result := nil;
  Context := SaveCloneContext;
  AXObject := CreateAXClass(AXClassName);
  if not Assigned(AXObject) then
    Exit;
  Result := TAXAbstract(AXObject).CreateByContext(Context);
end;

function TAXAbstract.ConvertText(const pText: string; pForSave: boolean = False): string;
var
  enc: TEncoder;
begin
  Result := pText;
  if GetEncodingFromStr(_xmlEncoding) <> eUTF8 then
    Exit;
  enc := TEncoder.Create;
  try
    if pForSave then
      enc.OutputEncoding := eUTF8
    else
      enc.InputEncoding := eUTF8;
    Result := enc.DoConvertText(pText);
  finally
    FreeAndNil(enc);
  end;
end;

constructor TAXAbstract.Create(AOwner: TAXAbstract = nil);
begin
  FChildrenAX := TList.Create;
  FOwner := AOwner;
  FisLocked := False;
  FisDeleted := False;
  FContextDOM := nil;
  AXClassName := ClassName;
  FPropsInChildNodes := TStringList.Create;
  FNodeValue := '';
  FnodeType := NODE_TEXT;
  FxmlVersion := '1.0';
  FxmlEncoding := 'Windows-1251';
  FnodeTypes := TStringList.Create;
  DoAfterCreate;
end;

procedure TAXAbstract.Delete(DeletedItem: TAXAbstract);
Var
  Index : Integer;
begin
  Index := FChildrenAX.IndexOf(DeletedItem);
  Delete(Index);
end;

constructor TAXAbstract.CreateByContext(const AContext: string;
  AOwner: TAXAbstract);
begin
  Create(AOwner);
  LoadFromContext(AContext);
end;

procedure TAXAbstract.Delete(Index : Integer);
begin
  if (Index > Count) or (Index < 0) then
    Exit;

  ChildAX[Index].FisLocked := false;
  ChildAX[Index].FisDeleted := True;
  ChildAX[Index].Free;
  FChildrenAX.Delete(Index);
end;

procedure TAXAbstract.DeleteFromOwner;
begin
  if Assigned(FOwner) then
    FOwner.Delete(Self);
end;

destructor TAXAbstract.Destroy;
begin
  if FisLocked
    and not FisDeleted
    and Assigned(FOwner) then
  begin
    DeleteFromOwner;
    Exit;
  end;

  Clear;
  FreeAndNil(FPropsInChildNodes);
  FreeAndNil(FChildrenAX);
  FreeAndNil(FnodeTypes);
  inherited;
end;

function TAXAbstract.FindClass(_Class: TClass;
  AXObject: TAXAbstract): TAXAbstract;
Var
  I : Integer;
  Found : Boolean;
begin
  Found := false;
  Result := Nil;
  if not Assigned(AXObject) then
  begin
    for I := 0 to Count - 1 do
      if (ChildAX[i] is _Class) then
      begin
        Result := ChildAX[i];
        Exit;
      end;

    for I := 0 to Count - 1 do
    begin
      Result := ChildAX[i].FindClass(_Class, nil);
      if Assigned(Result) then
        Exit;
    end;
  end
  else
  begin
    for I := 0 to Count - 1 do
      if (ChildAX[i] is _Class) then
      begin
        if Found then
        begin
          Result := ChildAX[i];
          Exit;
        end
        else if (ChildAX[i] <> AXObject) then
          Continue
        else
        begin
          Found := true;
          Continue;
        end
      end;
    for I := 0 to Count - 1 do
    begin
      Result := ChildAX[i].FindClass(_Class, AXObject);
      if (Result <> nil) then
        Exit;
    end;
  end;
end;

function TAXAbstract.GetFirstByClass(_Class: TClass): TAXAbstract;
begin
  Result := ChildAXByClass[0, _Class];
end;

function TAXAbstract.GetIsMisc: Boolean;
Var
  PrevClassName : String;
  I : Integer;
begin
  Result := False;
  if Count > 1 then
  begin
    PrevClassName := ChildAX[0].AXClassName;
    for I := 1 to Count - 1 do
      if PrevClassName <> ChildAX[I].AXClassName then
      begin
        Result := True;
        Exit;
      end;
  end;
end;

function TAXAbstract.GetChildAX(Index: Integer): TAXAbstract;
begin
  Result := nil;
  if (Index > Count) or (Index < 0) then
    Exit;
  Result := FChildrenAX[Index];
end;

function TAXAbstract.GetChildAXByClass(Index: Integer;
  _Class: TClass): TAXAbstract;
Var
  LIndex : Integer;
  I : Integer;

begin
  Result := nil;

  if (Index >= Count) or (Index < 0) then
    Exit;

  LIndex := 0;
  for I := 0 to Count - 1 do
    if ChildAX[I] is _Class then
      if (Index = LIndex) then
      begin
        Result := ChildAX[I];
        Exit;
      end
      else
        Inc(LIndex);
end;

function TAXAbstract.GetChildAXCountByClass(_Class: TClass): Integer;
Var
  I : Integer;
begin
  Result := 0;
  for I := 0 to Count - 1 do
    if ChildAX[I] is _Class then
      Inc(Result);
end;

function TAXAbstract.Init: boolean;
Var
  I, j      : Integer;
  FieldName : String;
  FieldValue: String;
  AXChildClassName : String;
  AXObject  : TObject;
  ChildContext : String;
  ChildAX  : TAXAbstract;
  ChildNodesCount : Integer;
  XmlElement : IXmlElement;
  ChildObjs: TStringList;
begin
  Result := False;
  if not Assigned(FContextDOM) then
    Exit;
  InitProcessingInstructions(FContextDOM);

  if FContextDOM.DocumentElement = nil then
    XmlElement := IXMLElement(FContextDOM)
  else
    XmlElement := FContextDOM.DocumentElement;

  FAXClassName := _UpperCase(XmlElement.NodeName);
  FFieldCount := XmlElement.AttrCount;
  ChildNodesCount := XmlElement.ChildNodes.Count;

  try
    ChildObjs := TStringList.Create;
    // Читаем атрибуты узла и проецируем их на поля класса
    for I := 0 to FFieldCount - 1 do
    begin
      FieldName := XmlElement.AttrNames[I];
      FieldValue := ConvertText(XmlElement.GetAttr(FieldName));
      SetPropValueExt(Self, FieldName, FieldValue);
    end;

    // Создаем дочерние объекты
    for I := 0 to ChildNodesCount - 1 do
    begin
      if (XmlElement.ChildNodes.Item[I].ChildNodes.Count > 0) then
        for j := 0 to XmlElement.ChildNodes.Item[I].ChildNodes.Count - 1 do
          if XmlElement.ChildNodes.Item[I].ChildNodes.Item[j].NodeType
            in [NODE_TEXT, NODE_CDATA_SECTION] then
          begin
            Inc(FFieldCount);
            // Читаем значения узлов дочерней ветки и проецируем на поля класса
            FieldName := XmlElement.ChildNodes.Item[I].NodeName;
            FieldValue := ConvertText(XmlElement.ChildNodes.Item[I].Text);
            if IsPublishedPropExt(Self, FieldName) then
            begin
              SetPropValueExt(Self, FieldName, FieldValue);
              FnodeTypes.AddObject(FieldName,
                TObject(XmlElement.ChildNodes.Item[I].ChildNodes
                  .Item[j].NodeType));
            end;
          end;
      if XmlElement.ChildNodes.Item[I].NodeType
        in [NODE_TEXT, NODE_CDATA_SECTION] then
      begin
        NodeValue := ConvertText(XmlElement.ChildNodes.Item[I].Text);
        FnodeType := XmlElement.ChildNodes.Item[I].NodeType;
        Continue;
      end;

      AXChildClassName := XmlElement.ChildNodes.Item[I].NodeName;
      AXObject := CreateAXClass(AXChildClassName);
      if Assigned(AXObject) then
      begin
        // запоминаем дочерние объекты
        ChildContext := XmlElement.ChildNodes.Item[I].XML;
        ChildObjs.AddObject(ChildContext, AXObject);
        ChildContext := '';
      end;
      AXChildClassName := '';
    end;
    // создаём дочерние объекты
    for i := 0 to ChildObjs.Count - 1 do
    begin
      ChildAX := TAXAbstract(ChildObjs.Objects[i])
        .CreateByContext(ChildObjs.Strings[i], Self);
      ChildAX.FisLocked := True;
      Add(ChildAX);
    end;
  finally
    FreeAndNil(ChildObjs);
  end;
  DoAfterInit;
  Result := True;
end;

procedure TAXAbstract.InitProcessingInstructions(pNode: IXmlNode);
var
  i, j: Integer;
  XmlNode: IXMLNode;
begin
  for i := 0 to pNode.ChildNodes.Count - 1 do
    if pNode.ChildNodes.Item[I].NodeType = NODE_PROCESSING_INSTRUCTION then
    begin
      XmlNode := pNode.ChildNodes.Item[I];
      for j := 0 to XmlNode.AttrCount - 1 do
        if AnsiSameText(XmlNode.AttrNames[j], 'encoding') then
          FxmlEncoding := XmlNode.GetAttr(XmlNode.AttrNames[j])
        else if AnsiSameText(XmlNode.AttrNames[j], 'version') then
          FxmlVersion := XmlNode.GetAttr(XmlNode.AttrNames[j]);
    end;
end;

procedure TAXAbstract.Insert(Item: TAXAbstract; Position: Integer);
begin
  if not Assigned(Item) then
    Exit;
  if (Position > Count)
      or (Position < 0) then
    Exit;

  Item.FOwner := Self;

  if not Assigned(FChildrenAX) then
    FChildrenAX := TList.Create;

  FChildrenAX.Capacity := Count + 1;

  if Position = Count then
    Add(Item)
  else
    FChildrenAX.Insert(Position, Item);
end;

function TAXAbstract.ChildContextToElement(Child: TAXAbstract): IXMLElement;
var
  ChildContext : String;
  ChildContexTAXM: IXmlDocument;
begin
  ChildContext := Child.SaveContext;
  try
    ChildContexTAXM := LoadXmlDocumentFromXML(ChildContext);
    Result := IXmlElement(ChildContexTAXM.DocumentElement.cloneNode(true));
  finally
    ChildContexTAXM := nil;
  end;
end;

function TAXAbstract.SaveContext(ReplaceTabs: boolean = False;
  pClone: boolean = False): string;
var
  PropList  : PPropList;
  PropCount : Integer;
  PropInfo  : PPropInfo;
  I         : Integer;
  StrTypeData  : String;

  Element   : IXMLElement;
  NodeName  : String;
  _Value    : Variant;
  _Date     : String;
  _Integer  : Integer;
  _DateTime : TDateTime;
  
  procedure SetProperty(Element: IXMLElement;
    PropInfo: PPropInfo;
    Value: string;
    SetNodeValue: boolean = False);
  var
    s: string;
  begin
    s := '';
    if Assigned(PropInfo) then
    begin
      s := _UpperCase(PropInfo.Name);
      if Copy(s, 1, 1) = UNDERLINE_CHAR then
        s := Copy(s, 2, Length(s));
    end;
    Value := ConvertText(Value, True);
    if SetNodeValue then
      if FnodeType = NODE_CDATA_SECTION then
        Element := IXmlElement(Element.AppendCDATA(Value))
      else
        Element.Text := Value
    else if not IsPropInChildNodes(s) then
      Element.SetAttr(s, Value)
    else
    begin
      Element := Element.AppendElement(s);
      if (FnodeTypes.IndexOf(s) > -1)
          and (Integer(FnodeTypes.Objects[FnodeTypes.IndexOf(s)]) = NODE_CDATA_SECTION) then
        Element := IXmlElement(Element.AppendCDATA(Value))
      else
        Element.Text := Value;
    end;
  end;
begin
  Result := '';
  PropCount := GetPropList(Self, PropList);
  try
    NodeName := _UpperCase(TagName());
    if not Assigned(Owner)
        and not pClone then
    begin
      FContextDOM := CreateXmlDocument(NodeName, _xmlVersion, _xmlEncoding);
      if Assigned(FContextDOM.DocumentElement) then
        Element := FContextDOM.DocumentElement
      else
        Abort;
    end
    else
    begin
      FContextDOM := CreateXmlDocument(NodeName, _xmlVersion, _xmlEncoding);
      Element := FContextDOM.DocumentElement;
    end;

    // сохраняем поля AX-объекта
    for I := 0 to PropCount - 1 do
    begin
      PropInfo := GetPropInfo(Self, PropList[i].Name);
      StrTypeData := PropInfo.PropType^.Name;
      _Value := GetPropValueEx(Self, PropList[i]);

      case PropInfo.PropType^.Kind of
        tkEnumeration :
          if AnsiSameText('boolean', StrTypeData) then
            SetProperty(Element, PropList[i]
              , IntToStr(Integer(Boolean(_Value))))
          else
            SetProperty(Element, PropList[i]
              , IntToStr(GetEnumValue(PropInfo.PropType^, PropList[i].Name)));
        tkFloat :
          if AnsiSameText('Domain_Date', StrTypeData)
            or AnsiSameText('TDateTime', StrTypeData) then
          begin
            _Date := _Value;
            if (_Date <> '') then
            begin
              _DateTime := Date;
              TryStrToDateTime(_Date, _DateTime);
              SetProperty(Element, PropList[i]
                , FormatDateTime('DD.MM.YYYY hh:mm', _DateTime));
            end
            else
              SetProperty(Element, PropList[i], '');
          end
          else
            SetProperty(Element, PropList[i], ConvertSeparator(_Value))
      else
        if (IsCheckProperty(PropList[i].Name)) then
        begin
          _Integer := _Value;
          if _Integer = 0 then
            SetProperty(Element, PropList[i], '')
          else
            SetProperty(Element, PropList[i], IntToStr(_Integer));
        end
        else
          SetProperty(Element, PropList[i], _Value);
      end;
    end;

    if NodeValue <> '' then
      SetProperty(Element, nil, NodeValue, True);
    // сохраняем дочерние AX-объекты
    for I := 0 to Count - 1 do
      if not IsPropInChildNodes(ChildAX[i].AXClassName) then
        Element.AppendChild(ChildContextToElement(ChildAX[i]));

    Result := FContextDOM.Xml;
    if ReplaceTabs then
      Result := StringReplace(Result, #9, '    ', [rfReplaceAll]);
  finally
    FContextDOM := nil;
  end;
end;

function TAXAbstract.SaveCloneContext(ReplaceTabs: boolean = False): string;
begin
  Result := SaveContext(ReplaceTabs, True);
end;

procedure TAXAbstract.AssignTo(Dest: TPersistent);
var
  i, c: Integer;
  PL: PPropList;
  FieldName: string;
  FieldValue: Variant;
begin
  c := GetPropList(Self, PL);
  for i := 0 to c - 1 do
  begin
    FieldName := PL^[i].Name;
    if uProps.IsPublishedPropExt(Self, FieldName) then
    begin
      FieldValue := uProps.GetPropValueExt(Self, FieldName);
      uProps.SetPropValueExt(Dest, FieldName, FieldValue);
    end;
  end;
end;

procedure TAXAbstract.Exchange(Index1, Index2: Integer);
begin
  FChildrenAX.Exchange(Index1,Index2);
end;

procedure TAXAbstract.Move(CurIndex, NewIndex: Integer);
begin
  FChildrenAX.Move(CurIndex, NewIndex);
end;

procedure TAXAbstract.Clear;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
  begin
    ChildAX[i].FisLocked := False;
    ChildAX[i].Free;
  end;
  if Assigned(FChildrenAX) then
    FChildrenAX.Clear;
end;

function TAXAbstract.GetChildAXCount: Integer;
begin
  Result := 0;
  if Assigned(FChildrenAX) then
    Result := FChildrenAX.Count;
end;

function TAXAbstract.LoadFromContext(const AContext: string): boolean;
begin
  try
    Clear;
    try
      FContextDOM := LoadXmlDocumentFromXML(AContext);
      Result := Init;
    except
      Result := False;
    end;
  finally
    FContextDOM := nil;
  end;
end;

function TAXAbstract.LoadFromFile(const FileName: string): boolean;
begin
  Clear;
  try
    FContextDOM := LoadXmlDocument(FileName);
    Result := Init;
  finally
    FContextDOM := nil;
  end;
end;

function TAXAbstract.CheckAddClassInstance(_Class: TClass): TAXAbstract;
begin
  Result := GetFirstByClass(_Class);
  if not Assigned(Result) then
    Add(TAXAbstract(_Class.NewInstance).Create);
  Result := GetFirstByClass(_Class);
end;

procedure TAXAbstract.DoAfterCreate;
begin
  DoSetPropsInChildNodes;
end;

procedure TAXAbstract.DoAfterInit;
begin
  // do nothing
end;

function TAXAbstract.SaveToFile(const FileName: string;
  ReplaceTabs: boolean = False): boolean;
var
  TSL: TStringList;
begin
  TSL := TStringList.Create;
  try
    TSL.Text := SaveContext(ReplaceTabs);
    TSL.SaveToFile(FileName);
    Result := True;
  finally
    FreeAndNil(TSL);
  end;
end;

procedure TAXAbstract.SetAXClassName(const Value: string);
begin
  FAXClassName := Value;
  System.Delete(FAXClassName, 1, Length(doPrefix()));
end;

procedure TAXAbstract.SetxmlEncoding(const Value: string);
begin
  RootOwner.FxmlEncoding := Value;
end;

procedure TAXAbstract.SetxmlVersion(const Value: string);
begin
  RootOwner.FxmlVersion := Value;
end;

function TAXAbstract.GetParentsChain(const PropName: string = ''): string;
// функция возврата строкого представления иерархии объекта (и его свойства)
// в виде .AXParentClass.AXClass1.AXClass2[.Property]
begin
  Result := AXClassName;
  if Assigned(Owner) then
    Result := Owner.GetParentsChain + _AXT + Result;
  if PropName <> '' then
    Result := Result + _AXT + PropName;
end;

function TAXAbstract.GetParentsChain(PropInfo: PPropInfo): string;
begin
  Assert(Assigned(PropInfo));
  Result := GetParentsChain(PropInfo.Name);
end;

function TAXAbstract.AreAllPropsChildNodes: boolean;
begin
  // переопределить для классов, у которых все свойства - дочерние теги
  Result := False;
end;

function TAXAbstract.IsPropInChildNodes(const PropName: string): boolean;
begin
  Result := FPropsInChildNodes.IndexOf(PropName) <> -1;
end;

procedure TAXAbstract.AddAllPropsToChildNodes;
var
  PropCount: Integer;
  PropList: PPropList;
  PropInfo: PPropInfo;
  i: Integer;
begin
  PropCount := GetPropList(Self, PropList);
  for i := 0 to PropCount - 1 do
  begin
    PropInfo := GetPropInfo(Self, PropList[i].Name);
    AddPropToChildNodes(PropInfo.Name);
  end;
end;

procedure TAXAbstract.AddPropToChildNodes(const PropName: string);
begin
  FPropsInChildNodes.Add(PropName);
end;

procedure TAXAbstract.DoSetPropsInChildNodes;
begin
 // переопределить метод для добавления свойств
 // которые хранятся в виде значений узлов, не в виде атрибутов
 // AddPropToChildNodes(<propertyname>);
 if AreAllPropsChildNodes() then
   AddAllPropsToChildNodes;
end;

class function TAXAbstract.TagName: string;
begin
  Result := Copy(ClassName, Length(doPrefix()) + 1, Length(ClassName));
end;

class function TAXAbstract.doPrefix: string;
begin
  Result := 'TAX';
end;

function TAXAbstract.CreateAXClass(AXClassName: string): TObject;
var
  AXClass: TClass;
begin
  Result := nil;
  try
   AXClass := FindSubClass(AXClassName, Self.ClassType);
   if not Assigned(AXClass) then
   begin
     AXClassName := StringReplace(AXClassName,
       '-', UNDERLINE_CHAR, [rfReplaceAll]);
     AXClass := GetAXClass(AXClassName);
   end;
   if Assigned(AXClass) then
     Result := AXClass.NewInstance;
  except
  end;
end;

class function TAXAbstract.GetAXClass(const _ClassName: string): TClass;
begin
  Result := GetClass(doPrefix() + _ClassName);
end;

function TAXAbstract.GetAXClassName: string;
begin
  Result := FAXClassName; 
end;

function TAXAbstract.GetAXIndex: Integer;
begin
  Result := FOwner.FChildrenAX.IndexOf(Self);
end;

procedure TAXAbstract.DoAfterChildAdd(Item: TAXAbstract);
begin
  // do nothing
end;

function TAXAbstract.GetChildFromStr(ChildStr: string): TAXAbstract;
// функция возврата ссылки на дочерний экземпляр класса
// по строковому представлению
// .AXParentClass.AXClass1.AXClass2
var
  TSL: TStringList;
  _ClassName: string;
  Prefix: string;
  Obj: TAXAbstract;
begin
  TSL := TStringList.Create;
  try
    Prefix := '';
    if Copy(ChildStr, 1, 1) = _AXT then
    begin
      ChildStr := UNDERLINE_CHAR + ChildStr;
      Obj := Self;
      Prefix := _AXT;
    end
    else
      Obj := RootOwner;
    ExtractStrings([_AXT], [], PAnsiChar(ChildStr), TSL);
    if TSL.Count > 1 then
    begin
      _ClassName := TSL.Strings[1];
      TSL.Strings[0] := '';
      TSL.Delete(1);
      TSL.Delimiter := _AXT;
      if _ClassName = UNDERLINE_CHAR then
        Result := Self
      else
      begin
        Result := Obj.GetFirstByClass(GetAXClass(_ClassName));
        if Assigned(Result) then
          Result := Result.GetChildFromStr({ Prefix +  }TSL.DelimitedText);
      end;
    end
    else
      Result := Self;
  finally
    FreeAndNil(TSL);
  end;
end;

function TAXAbstract.GetxmlEncoding: string;
begin
  Result := RootOwner.FxmlEncoding;
end;

function TAXAbstract.GetValueFromStr(ValueStr: string): Variant;
// функция возврата значения свойства дочернего экземпляра класса
// по строковому представлению
// .AXParentClass.AXClass1.AXClass2.Property
var
  TSL: TStringList;
  _PropName: string;
  TAX: TAXAbstract;
  Prefix: string;
  Obj: TAXAbstract;
  Method: TMethod;
begin
  Result := Unassigned;
  TSL := TStringList.Create;
  try
    Prefix := '';
    if Copy(ValueStr, 1, 1) = _AXT then
    begin
      ValueStr := UNDERLINE_CHAR + ValueStr;
      Obj := Self;
      Prefix := _AXT;
    end
    else
      Obj := RootOwner;
    ExtractStrings([_AXT], [], PAnsiChar(ValueStr), TSL);
    if TSL.Count > 0 then
    begin
      _PropName := TSL.Strings[TSL.Count - 1];
      TSL.Delete(TSL.Count - 1);
      TSL.Delimiter := _AXT;
      TAX := Obj.GetChildFromStr(Prefix + TSL.DelimitedText);
    end
    else
      TAX := Self;
    if Assigned(TAX) then
      if IsPublishedPropExt(TAX, _PropName) then
        Result := GetPropValueExt(TAX, _PropName)
      else if AnsiSameText(_PropName, _TEXT) then
        Result := NodeValue
      else
      begin
        Method.Code := TAX.MethodAddress(_PropName);
        Method.Data := TAX;
        if Assigned(Method.Code) then
          Result := TStringMethod(Method);
      end;
  finally
    FreeAndNil(TSL);
  end;
end;

function TAXAbstract.GetxmlVersion: string;
begin
  Result := RootOwner.FxmlVersion;
end;

function TAXAbstract.ApplyTemplate(pTemplate: TAXAbstract): boolean;
var
  i: Integer;
  PropList: PPropList;
  PropCount: Integer;
  Value, TemplateValue: Variant;
  Name: string;
begin
  Result := False;
  if not Assigned(pTemplate) then
    Exit;
  PropCount := GetPropList(Self, PropList);
  try
    for i := 0 to PropCount - 1 do
    begin
      Value := GetPropValueExt(Self, PropList[i]);
      Name := GetParentsChain(PropList[i]);
      TemplateValue := pTemplate.GetValueFromStr(Name);
      try
        if VarToStr(TemplateValue) <> '' then
          SetPropValueExt(Self, PropList[i],
            Evaluate(VarToStr(TemplateValue)))
      except
      end;
    end;
    Name := GetParentsChain(_TEXT);
    TemplateValue := pTemplate.GetValueFromStr(Name);
    try
      if VarToStr(TemplateValue) <> '' then
        NodeValue := Evaluate(VarToStr(TemplateValue))
    except
    end;
    for i := 0 to Count - 1 do
      ChildAX[i].ApplyTemplate(pTemplate);
  except
  end;
end;

function TAXAbstract.Evaluate(const Value: string): string;
// функция вычисления значений узлов
// честно скопирована из исходников WANT
type
  TMacroExpansion = function(const Name: string): string of object;

  function Expand(MacroStart :Integer; Val: string;
    MacroExpansion: TMacroExpansion): string;
  var
    MacroEnd   : Integer;
    Content    : string;
  begin
    Result := Val;
    Result := Copy(Result, 1, MacroStart - 1)
      + Evaluate(Copy(Result, MacroStart + 2, Length(Result)));
    MacroEnd := PosEx('}', Result, macroStart + 1);
    if MacroEnd > 0  then
    begin
      Content := Copy(Result, MacroStart, MacroEnd - MacroStart);
      System.Delete(Result, MacroStart, 1 + Length(Content));
      System.Insert(MacroExpansion(Content), Result, MacroStart);
    end;
  end;

var
  MacroStart :Integer;
begin
  Result := Value;
  MacroStart := PosEx('{', Result, 2) - 1;
  while MacroStart > 0 do
  begin
    case Result[MacroStart] of
{       '%':
          Result := Expand(MacroStart, Result, EnvironmentValue); }
      '$':
           Result := Expand(MacroStart, Result, PropertyValue);
{      '=':
          Result := Expand(MacroStart, Result, ExpressionValue);
      '?':
          Result := Expand(MacroStart, Result, INIValue);
      '@':
          Result := Expand(MacroStart, Result, FunctionValue);
}
    end;
    MacroStart := PosEx('{', Result, MacroStart + 2) - 1;
  end;
end;

function TAXAbstract.PropertyValue(const Name: string): string;
begin
  if Name = '' then
    Result := ''
  else
    Result := GetValueFromStr(Name);
end;

function TAXAbstract.GetRootOwner: TAXAbstract;
begin
  if Assigned(Owner) then
    Result := Owner.RootOwner
  else
    Result := Self;
end;

procedure TAXAbstract.Sort(Compare: TListSortCompare);
begin
  FChildrenAX.Sort(Compare);
end;

initialization
  RegisterAXClass(TAXAbstract);
  SetLength(CheckProperty, 0);
end.

