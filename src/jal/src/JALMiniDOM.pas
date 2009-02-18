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

unit JALMiniDOM;

interface
uses
 SysUtils,
 Classes,
 JALCollections,
 JALSAX;

const
  rcs_id :string = '@(#)$Id: JALMiniDOM.pas 706 2003-05-14 22:13:46Z hippoman $';

type
  TLocation = record
    PublicId :WideString;
    SystemId :WideString;
    LineNumber :Integer;
    ColumnNumber :Integer;
  end;

  IMiniDomObject = interface(IObject)
  ['{C13B66E0-2263-11D5-8DC7-B0FF333FE70A}']
    function Location :TLocation;
  end;

  IAttribute = interface(IMiniDomObject)
  ['{CD2605D8-4108-4372-B28E-8EED1C09A42C}']
    function name  :string;
    function value :string;
  end;

  INode = interface(IMiniDomObject)
  ['{C646E358-DE27-4BB5-8897-DC8F6B3E1413}']
    function toPrefixedString(prefix :string):string;
  end;

  ITextNode = interface(INode)
   ['{ECECD7D6-5623-4749-946A-1E2BCCB881A0}']
    function text :string;
  end;

  IElement = interface(INode)
  ['{77EE9C64-31B5-4672-AFE7-3A860E7D21AA}']
    function name :string;
    function children :IList;                overload;
    function children(name :string) :IList;  overload;
    function attributes :IList;
    function attribute(name :string) :IAttribute;
    function attributeValue(name :string) :string;
    function add(n :INode):INode;
    function setAttribute(Name, Value :string): IAttribute;
    function addAttribute(att :IAttribute): IAttribute;
  end;

  IDocument = interface(INode)
  ['{1539F033-50A0-4F82-B8E9-E9D6B7A71291}']

    function newElement(name :string; const Location :TLocation; attributes :IMap = nil)  :IElement;
    function newTextNode(text :string; const Location :TLocation) :ITextNode;
    function newAttribute(name, value :string; const Location :TLocation) :IAttribute;
    function root :IElement;
    function newRoot(name :string; const Location :TLocation; attributes :IMap = nil) :IElement;
  end;

  TMiniDomObject = class(TAbstractObject, IMiniDomObject)
  protected
    _Location :TLocation;
  public
    constructor Create(const Location :TLocation);
    function Location :TLocation;
  end;

  TAttribute = class(TMiniDomObject, IAttribute)
  protected
    _name  :string;
    _value :string;
  public
    constructor create(name, value :string; const Location :TLocation);
    function name  :string;  virtual;
    function value :string;  virtual;

    function toString :string; override;
  end;

  TNode = class(TMiniDomObject, INode)
  protected
  public
    constructor Create(const Location :TLocation);
    function toPrefixedString(prefix :string):string; virtual;
  end;

  TTextNode = class(TNode, ITextNode)
  protected
    _text :string;
  public
    constructor create(value :string; const Location :TLocation);
    function text :string;

    function toString :string; override;
  end;

  TElement = class(TNode, IElement)
  protected
    _name       :string;
    _children   :IList;
    _attributes :IMap;
  public
    constructor create(name :string; const Location :TLocation; attributes :IMap = nil);
    function name :string;                   virtual;
    function children :IList;                overload; virtual;
    function children(name :string) :IList;  overload; virtual;

    function attributes :IList;                    virtual;
    function attribute(name :string) :IAttribute;  virtual;
    function attributeValue(name :string) :string; virtual;

    function add(n :INode):INode;                  virtual;
    function setAttribute(Name, Value :string): IAttribute; virtual;
    function addAttribute(att :IAttribute): IAttribute;     virtual;

    function toString :string; override;
    function toPrefixedString(prefix :string):string; override;
  end;

  TDocument = class(TNode, IDocument)
    _root :IElement;
  public
    constructor Create(const Location :TLocation);
    function newElement(name :string; const Location :TLocation; attributes :IMap)  :IElement;    virtual;
    function newTextNode(text :string; const Location :TLocation) :ITextNode;                     virtual;
    function newAttribute(name, value :string; const Location :TLocation) :IAttribute;            virtual;
    function root :IElement;                                                                      virtual;
    function newRoot(name :string; const Location :TLocation; attributes :IMap) :IElement;        virtual;

    function toString :string; override;
  end;

  ISAXToDomHandler = interface(IDocumentHandler)
  ['{5545E11B-D69A-4436-A65E-9F663F74D31B}']
    function Document :IDocument;
    function locator  :TLocator;
    function Location :TLocation;
  end;

  TSAXtoDOMHandler = class(THandlerBase, ISAXToDomHandler,  IErrorHandler)
    constructor create(IgnoreWhites :boolean = false);

    procedure startDocument; override;
    procedure endDocument;   override;

    procedure startElement (name :WideString; atts: TAttributeList);
    override;
    procedure endElement (name :WideString);
    override;
    procedure characters(ch: WideString; start, length: Integer);
    override;
    procedure ignorableWhitespace (ch :WideString; start, length :Integer);
    override;
    procedure position(pos, len: Integer);
    override;
    procedure setDocumentLocator (loc :TLocator);
    override;

    procedure warning (exception :SAXParseException);
    override;
    procedure error (exception :SAXParseException);
    override;
    procedure fatalError (exception :SAXParseException);
    override;

    function locator :TLocator;
    function Location :TLocation;
    class function MakeLocation(Locator: TLocator): TLocation;

    function Document :IDocument;
  protected
    _dom          :IDocument;
    _nodes        :IStack;
    _elements     :array[char] of IMap;
    _locator      :TLocator;
    _IgnoreWhites :boolean;
  end;

function parseToDOM(src  :IInputSource; IgnoreWhites :boolean = false) :IDocument; overload;
function parseToDOM(strm :TStream; IgnoreWhites :boolean = false)      :IDocument; overload;
function parseToDOM(fname :string; IgnoreWhites :boolean = false)      :IDocument; overload;
function parseTextToDOM(text :string; IgnoreWhites :boolean = false)   :IDocument;

implementation
uses
  JALXMLParser;

function UnknownLocation: TLocation;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

{ TMiniDomObject }

constructor TMiniDomObject.Create(const Location :TLocation);
begin
  inherited Create;
  _Location := Location;
end;

function TMiniDomObject.Location: TLocation;
begin
  Result := _Location;
end;

{ TNode }

constructor TNode.create(const Location :TLocation);
begin
  inherited create(Location);
end;

function TNode.toPrefixedString(prefix: string): string;
begin
  Result := prefix + toString;
end;

{ TTextNode }

constructor TTextNode.create(value: string; const Location :TLocation);
begin
  inherited create(Location);
  _text := value;
end;

function TTextNode.text: string;
begin
  result := _text;
end;

function TTextNode.toString: string;
begin
  Result := Text;
end;

{ TElement }

constructor TElement.create(name :string; const Location :TLocation; attributes :IMap);
begin
  inherited create(Location);
  self._name  := name;
  if attributes <> nil then
    _attributes := attributes
  else
    _attributes := TTreeMap.create;
  _children   := TLinkedList.Create;
end;

function TElement.children(name: string): IList;
var
  i :IIterator;
  n :INode;
begin
  result := TLinkedList.create;
  i := _children.iterator;
  while i.hasNext do
  begin
    n := i.next as INode;
    if n.instanceOf(IElement)
    and ((n as IElement).name = name)
    then
      result.add(n);
  end;
end;

function TElement.children: IList;
begin
  result := _children;
end;

function TElement.name: string;
begin
  result := _name;
end;


function TElement.add(n: INode): INode;
begin
  if _children.add(n) then
    result := n
  else
    result := nil;
end;

function TElement.attribute(name: string): IAttribute;
begin
  result := _attributes.get(name) as IAttribute
end;

function TElement.attributes: IList;
begin
  result := TArrayList.create(_attributes.values.size);
  result.addAll(_attributes.values);
end;

function TElement.attributeValue(name: string): string;
var
  a :IAttribute;
begin
  a := attribute(name);
  if a <> nil then
    result := a.value
  else
    result := '';
end;

function TElement.setAttribute(Name, Value: string): IAttribute;
begin
  Result := TAttribute.Create(Name, Value, UnknownLocation);
  _attributes.put(iref(Name), Result);
end;

function TElement.addAttribute(att: IAttribute): IAttribute;
begin
  _attributes.put(iref(att.Name), att);
  Result := att;
end;

function TElement.toString: string;
begin
  Result := toPrefixedString('');
end;

function TElement.toPrefixedString(prefix: string): string;
var
  i :IIterator;
begin
  Result := prefix + '<' + name;
  i := attributes.iterator;
  while i.HasNext do
    Result := Result + ' ' + (i.Next as IAttribute).toString;

  if Children.Size <= 0 then
    Result := Result + ' />'
  else
  begin
    Result := Result + '>'#13#10;
    i := Children.Iterator;
    while i.HasNext do
      Result := Result + (i.Next as INode).toPrefixedString(prefix + '  ');
    Result := Result + prefix + '</' + name + '>';
  end;
  Result := Result + #13#10;
end;


{ TDocument }

function TDocument.newElement(name: string; const Location :TLocation; attributes :IMap): IElement;
begin
  result := TElement.create(name, Location, attributes);
end;

function TDocument.newRoot(name: string; const Location :TLocation; attributes :IMap): IElement;
begin
  assert(_root = nil);
  _root := newElement(name, Location, attributes);
  result := _root;
end;

function TDocument.root: IElement;
begin
  result := _root;
end;

function TDocument.newTextNode(text: string; const Location :TLocation): ITextNode;
begin
  result := TTextNode.create(text, Location);
end;

function TDocument.newAttribute(name, value: string; const Location :TLocation): IAttribute;
begin
  result := TAttribute.create(name, value, Location);
end;

function TDocument.toString: string;
begin
  Result := Root.toString;
end;

constructor TDocument.Create(const Location :TLocation);
begin
  inherited Create(Location);
end;

{ TSAXtoDOMHandler }

constructor TSAXtoDOMHandler.create(IgnoreWhites :boolean);
begin
  inherited create;
  _nodes := TStack.create(TLinkedList.create);
  _IgnoreWhites := IgnoreWhites;
end;

procedure TSAXtoDOMHandler.startElement(name: WideString; atts: TAttributeList);
var
  n      :INode;
  amap   :IMap;
  i      :Integer;
  parent :IElement;
begin
  amap := TTreeMap.create;
  for i := 0 to atts.getLength-1 do
    amap.put( iref(atts.getName(i)),
              _dom.newAttribute( atts.getName(i),
                                 atts.getValue(i),
                                 Location
                                 )
              );
  if _nodes.isEmpty then
    n := _dom.newRoot(name, Location, amap )
  else
  begin
    parent := (_nodes.top as IElement);
    n := _dom.newElement(name, Location, amap);
    parent.add(n);
  end;
  _nodes.push(n);
end;

procedure TSAXtoDOMHandler.endElement(name: WideString);
begin
  _nodes.pop;
end;

procedure TSAXtoDOMHandler.characters(ch: WideString; start, length: Integer);
var
  s :string;
begin
  s := copy(ch, start, length);
  if s <> ''  then
    (_nodes.top as IElement).add(_dom.newTextNode(copy(ch, start, length), Location));
end;

procedure TSAXtoDOMHandler.ignorableWhitespace(ch: WideString; start, length: Integer);
begin
  if not _IgnoreWhites then
    characters(ch, start, length);
end;

procedure TSAXtoDOMHandler.error(exception: SAXParseException);
begin
  inherited error(exception)
end;

procedure TSAXtoDOMHandler.fatalError(exception: SAXParseException);
begin
  inherited fatalError(exception)
end;

procedure TSAXtoDOMHandler.warning(exception: SAXParseException);
begin
  inherited warning(exception)
end;

procedure TSAXtoDOMHandler.position(pos, len: Integer);
begin

end;

procedure TSAXtoDOMHandler.setDocumentLocator(loc: TLocator);
begin
  _locator := loc;
end;

procedure TSAXtoDOMHandler.endDocument;
begin
end;

procedure TSAXtoDOMHandler.startDocument;
begin
  _dom := TDocument.Create(Location);
end;

function TSAXtoDOMHandler.locator: TLocator;
begin
  Result := _locator;
end;


function TSAXtoDOMHandler.Location: TLocation;
begin
  Result := MakeLocation(Locator);
end;

class function TSAXtoDOMHandler.MakeLocation(Locator: TLocator): TLocation;
begin
  Result.PublicId     := Locator.getPublicId;
  Result.SystemId     := Locator.getSystemId;
  Result.LineNumber   := 1 + Locator.getLineNumber;
  Result.ColumnNumber := 1 + Locator.getColumnNumber;
end;

function TSAXtoDOMHandler.Document: IDocument;
begin
  Result := _dom;
end;

{ TAttribute }

constructor TAttribute.create(name, value: string; const Location :TLocation);
begin
  inherited create(Location);
  _name  := name;
  _value := value;
end;

function TAttribute.name: string;
begin
  result := _name;
end;

function TAttribute.toString: string;
begin
  Result := Format('%s="%s"', [Name, Value]);
end;

function TAttribute.value: string;
begin
  result := _value;
end;

function parseToDOM(src :IInputSource; IgnoreWhites :boolean) :IDocument; overload;
var
  parser  :IParser;
  handler :ISAXToDOMHandler;
begin
  Result := nil;
  try
    parser := TXMLParser.create;
    try
      handler := TSAXtoDOMHandler.create(IgnoreWhites);
      parser.setDocumentHandler(handler);
      parser.setErrorHandler(handler as IErrorHandler);
      parser.parse(src);
      Result := handler.Document;
    except
      on e :SAXParseException do
      begin
        result := nil;
        raise;
      end;
      on e :Exception do
      begin
        result := nil;
        if handler <> nil then
          raise SAXParseException.Create(e.Message, handler.locator)
        else
          raise;
      end;
    end;
  finally
    parser := nil;
  end;
end;

function parseToDOM(strm :TStream; IgnoreWhites :boolean) :IDocument;
begin
  result := parseToDOM(TInputSource.create(strm), IgnoreWhites);
end;

function parseTextToDOM(text :string; IgnoreWhites :boolean) :IDocument;
var
  s :TMemoryStream;
begin
  s := TMemoryStream.create;
  try
    s.WriteBuffer(PChar(text)^, length(text));
    s.Position := 0;
    result := parseToDOM(s, IgnoreWhites);
  finally
    s.free;
  end;
end;

function parseToDOM(fname :string; IgnoreWhites :boolean) :IDocument;
var
  s :TMemoryStream;
begin
  s := TMemoryStream.create;
  try
    s.LoadFromFile(fname);
    result := parseToDOM(s, IgnoreWhites);
  finally
    s.free;
  end;
end;



end.


