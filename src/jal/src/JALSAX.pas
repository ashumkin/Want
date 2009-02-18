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

unit JALSAX;
interface
uses
  SysUtils,
  JALCollections,
  Classes;

type
  SAXParseException = class;
  TLocator          = class;
  TAttributeList    = class;
  IInputSource      = interface;


  IDocumentHandler = interface
  ['{01A64BFE-5C0C-43BE-9F02-D21D46AC489C}']
    procedure setDocumentLocator (locator :TLocator);
    procedure startDocument;
    procedure endDocument;
    procedure startElement (name :WideString; atts: TAttributeList);
    procedure endElement (name :WideString);
    procedure characters (ch :WideString; start, length :Integer);
    procedure ignorableWhitespace (ch :WideString; start, length :Integer);
    procedure processingInstruction (target, data :WideString);
    procedure position(pos, len :Longint);
  end;

  IDTDHandler = interface
  ['{CC7055A0-9F96-4631-B9E9-4BA0C6A25BBA}']
      procedure notationDecl (name, publicId, systemId :WideString);
      procedure unparsedEntityDecl (name, publicId, systemId, notationName :WideString);
  end;

  IEntityResolver = interface
  ['{71A26825-8AA6-4D28-94D1-08EE52F05CF3}']
     function resolveEntity (publicId, systemId :WideString) :IInputSource;
  end;

  IErrorHandler = interface
  ['{1D62B415-7C67-46AE-AFD2-24162831A2DF}']
    procedure warning (exception :SAXParseException);
    procedure error (exception :SAXParseException);
    procedure fatalError (exception :SAXParseException);
  end;

  THandlerBase = class( TInterfacedObject,
                        IEntityResolver,
                        IDTDHandler,
	                      IDocumentHandler,
                        IErrorHandler)
  public
    function resolveEntity (publicId, systemId :WideString) :IInputSource;       virtual;
    procedure notationDecl (name, publicId, systemId :WideString);               virtual;
    procedure unparsedEntityDecl (name, publicId, systemId, notationName :WideString);   virtual;
    procedure setDocumentLocator (locator :TLocator);                                    virtual;
    procedure startDocument;                                                             virtual;
    procedure endDocument;                                                               virtual;
    procedure startElement (name :WideString; atts :TAttributeList);                     virtual;
    procedure endElement (name :WideString);                                             virtual;
    procedure characters (ch :WideString; start, length :Integer);                       virtual;
    procedure ignorableWhitespace (ch :WideString; start, length :Integer);              virtual;
    procedure processingInstruction (target, data :WideString);                          virtual;
    procedure warning (e : SAXParseException);                                           virtual;
    procedure error (e :SAXParseException);                                              virtual;
    procedure fatalError (e :SAXParseException);                                         virtual;
    procedure position(pos, len :Longint);                                               virtual;
  end;

  IInputSource = interface
    procedure setPublicId (publicId :WideString);
    function getPublicId :WideString;
    procedure setSystemId (systemId :WideString);
    function getSystemId :WideString;
    procedure setByteStream (byteStream :TStream);
    function getByteStream :TStream;
    procedure setEncoding (encoding :WideString);
    function getEncoding :WideString;
    procedure setCharacterStream (characterStream :TStream);
    function getCharacterStream :TStream;
  end;


  TInputSource = class(TInterfacedObject, IInputSource)
    constructor Create; overload;
    constructor Create(systemId :WideString); overload;
    constructor Create( byteStream :TStream); overload;
    //constructor Create(characterStream :TStream); overload;
    (*
      setCharacterStream(characterStream);
    *)
    procedure setPublicId (publicId :WideString);
    function getPublicId :WideString;
    procedure setSystemId (systemId :WideString);
    function getSystemId :WideString;
    procedure setByteStream (byteStream :TStream);
    function getByteStream :TStream;
    procedure setEncoding (encoding :WideString);
    function getEncoding :WideString;
    procedure setCharacterStream (characterStream :TStream);
    function getCharacterStream :TStream;

  private
         publicId         :WideString;
         systemId         :WideString;
         encoding         :WideString;
         byteStream       :TStream;
         characterStream  :TStream;
  end;

  TLocator = class
    function getPublicId :WideString; virtual; abstract;
    function getSystemId :WideString; virtual; abstract;
    function getLineNumber :Integer; virtual; abstract;
    function getColumnNumber :Integer; virtual; abstract;
  end;

  IParser = interface
    procedure setLocale (locale :WideString);
    procedure setEntityResolver (resolver :IEntityResolver);
    procedure setDTDHandler (handler :IDTDHandler);
    procedure setDocumentHandler (handler :IDocumentHandler);
    procedure setErrorHandler (handler :IErrorHandler);
    procedure parse (source :IInputSource); overload;
    procedure parse (systemId :string); overload;
  end;

  SAXException = class (Exception)
    constructor Create(message :WideString); overload;
    constructor CreateW(message :WideString);
    constructor Create(message :string); overload;
    constructor Create(e: Exception); overload;
    constructor Create(message :WideString; e :Exception); overload;
    function getMessage :WideString;
    function getException :Exception;
    function toString :WideString;
  private
     message   :WideString;
     exception :Exception ;
  end;

  SAXParseException = class (SAXException)
    constructor Create(message :WideString; locator :TLocator); overload;
    constructor Create(message :WideString; locator :TLocator; e :Exception); overload;
    constructor Create(message, publicId, systemId :WideString;
            lineNumber, columnNumber :Integer); overload;
    constructor Create( message, publicId, systemId :WideString;
                        lineNumber, columnNumber: Integer; e :Exception); overload;
    function getPublicId :WideString;
    function getSystemId :WideString;
    function getLineNumber :Integer;
    function getColumnNumber :Integer;

  private
     publicId_       :WideString;
     systemId_       :WideString;
     lineNumber_     :Integer;
     columnNumber_   :Integer;
  end;

  TBasicLocator = class(TLocator)
  public
    constructor Create;                    overload;
    constructor Create(locator: TLocator); overload;
    function    getColumnNumber: Integer;                 override;
    function    getLineNumber: Integer;                   override;
    function    getPublicId: WideString;                  override;
    function    getSystemId: WideString;                  override;
    procedure   setLineNumber(lineNumber: Integer);       virtual;
    procedure   setPublicId(publicId: WideString);        virtual;
    procedure   setSystemId(systemId: WideString);        virtual;
    procedure   setColumnNumber(columnNumber: Integer);   virtual;
  private
     publicId_       :WideString;
     systemId_       :WideString;
     lineNumber_     :Integer;
     columnNumber_   :Integer;
  end;

  TAttributeList = class
      constructor Create;

      procedure add(name, value, typ :WideString);

      function getLength:Integer;
      function getName(i :Integer): string;
      function getType (i :Integer) :WideString;       overload;
      function getValue (i :Integer):WideString;       overload;
      function getType (name :WideString) :WideString; overload;
      function getValue(name :WideString) :WideString; overload;
  protected
      list_  :IList;
      map_   :IMap;
      types_ :IMap;
  end;

implementation
{ THandlerBase }


procedure THandlerBase.characters(ch: WideString; start, length: Integer);
begin

end;

procedure THandlerBase.endDocument;
begin

end;

procedure THandlerBase.endElement(name: WideString);
begin

end;

procedure THandlerBase.error(e: SAXParseException);
begin
   raise e;
end;

procedure THandlerBase.fatalError(e: SAXParseException);
begin
   raise e;
end;

procedure THandlerBase.ignorableWhitespace(ch: WideString; start, length: Integer);
begin

end;

procedure THandlerBase.notationDecl(name, publicId, systemId: WideString);
begin

end;

procedure THandlerBase.position(pos, len: Integer);
begin

end;

procedure THandlerBase.processingInstruction(target, data: WideString);
begin

end;

function THandlerBase.resolveEntity(publicId, systemId: WideString): IInputSource;
begin
   result := TInputSource.Create;
   result.setPublicId(publicId);
   result.setSystemId(systemId);
   result.setByteStream(TFileStream.Create(systemId, fmOpenRead or fmShareDenyWrite));
   result.setCharacterStream(result.getByteStream)
end;

procedure THandlerBase.setDocumentLocator(locator: TLocator);
begin

end;

procedure THandlerBase.startDocument;
begin

end;

procedure THandlerBase.startElement(name: WideString; atts: TAttributeList);
begin

end;

procedure THandlerBase.unparsedEntityDecl(name, publicId, systemId,
  notationName: WideString);
begin

end;

procedure THandlerBase.warning(e: SAXParseException);
begin
  raise e;
end;

{ IInputSource }

constructor TInputSource.Create(byteStream: TStream);
begin
  inherited Create;
  self.byteStream      := byteStream;
  self.characterStream := byteStream
end;

constructor TInputSource.Create(systemId: WideString);
begin
  inherited Create;
  self.systemId := systemId
end;

(*constructor TInputSource.Create(characterStream: TStream);
begin
  inherited Create;
  self.characterStream := characterStream
end;
*)
function TInputSource.getByteStream: TStream;
begin
    result := self.byteStream
end;

function TInputSource.getCharacterStream: TStream;
begin
   result := self.characterStream
end;

function TInputSource.getEncoding: WideString;
begin
     result := self.encoding
end;

function TInputSource.getPublicId: WideString;
begin
   result := self.publicId
end;

function TInputSource.getSystemId: WideString;
begin
  result := self.systemId
end;

constructor TInputSource.Create;
begin
  inherited Create;

end;

procedure TInputSource.setByteStream(byteStream: TStream);
begin
     self.byteStream := byteStream
end;

procedure TInputSource.setCharacterStream(characterStream: TStream);
begin
     self.characterStream := characterStream
end;

procedure TInputSource.setEncoding(encoding: WideString);
begin
     self.encoding := encoding
end;

procedure TInputSource.setPublicId(publicId: WideString);
begin
     self.publicId := publicId
end;

procedure TInputSource.setSystemId(systemId: WideString);
begin
     self.systemId := systemId
end;

{ SAXException }

constructor SAXException.Create(message: WideString);
begin
     inherited Create(message);
     self.message := message
end;

constructor SAXException.Create(e: Exception);
begin
     inherited Create(e.Message);
     self.exception := e
end;

constructor SAXException.Create(message: WideString; e: Exception);
begin
     inherited Create(e.Message);
     self.message := message;
     self.exception := e
end;

constructor SAXException.Create(message: string);
begin
     inherited Create(message);
     self.message := message
end;

constructor SAXException.CreateW(message: WideString);
begin
  inherited Create(message);
   self.message := message
end;

function SAXException.getException: Exception;
begin
   result := self.exception
end;

function SAXException.getMessage: WideString;
begin
     result := self.message
end;

function SAXException.toString: WideString;
begin
     result := self.message
end;

{ SAXParseException }

constructor SAXParseException.Create(message, publicId,
  systemId: WideString; lineNumber, columnNumber: Integer);
begin
  inherited CreateW(message);
  self.publicId_     := publicId;
  self.systemId_     := systemId;
  self.lineNumber_   := lineNumber;
  self.columnNumber_ := columnNumber
end;

constructor SAXParseException.Create(message: WideString; locator: TLocator; e: Exception);
begin
    inherited Create(message, e);
    self.lineNumber_   := locator.getLineNumber;
    self.columnNumber_ := locator.getColumnNumber;
end;

constructor SAXParseException.Create(message: WideString; locator: TLocator);
begin
    self.lineNumber_   := locator.getLineNumber;
    self.columnNumber_ := locator.getColumnNumber;
    inherited CreateW(format('%s(%d:%d): %s', [locator.getSystemId,
                                              1+locator.getLineNumber,
                                              locator.getColumnNumber,
                                              message
                                              ]));
end;

constructor SAXParseException.Create(message, publicId,
  systemId: WideString; lineNumber, columnNumber: Integer; e: Exception);
begin

end;

function SAXParseException.getColumnNumber: Integer;
begin
     result := self.columnNumber_
end;

function SAXParseException.getLineNumber: Integer;
begin
     result := self.lineNumber_
end;

function SAXParseException.getPublicId: WideString;
begin
     result := self.publicId_
end;

function SAXParseException.getSystemId: WideString;
begin
     result := self.systemId_
end;

// SAX default implementation for Locator.
// No warranty; no copyright -- use this as you will.

(**
  * Provide an optional convenience implementation of Locator.
  *
  * <p>This class is available mainly for application writers, who
  * can use it to make a persistent snapshot of a locator at any
  * point during a document parse:</p>
  *
  * <pre>
  * Locator locator;
  * Locator startloc;
  *
  * public void setLocator (Locator locator)
  * {
  *         // note the locator
  *   this.locator = locator;
  * }
  *
  * public void startDocument ()
  * {
  *         // save the location of the start of the document
  *         // for future use.
  *   Locator startloc = new LocatorImpl(locator);
  * }
  *</pre>
  *
  * <p>Normally, parser writers will not use this class, since it
  * is more efficient to provide location information only when
  * requested, rather than constantly updating a Locator object.</p>
  *
  * @see org.xml.sax.Locator
  *)

  (**
    * Zero-argument constructor.
    *
    * <p>This will not normally be useful, since the main purpose
    * of this class is to make a snapshot of an existing Locator.</p>
    *)
  constructor TBasicLocator.Create;
  begin
     inherited Create;
  end;


  (**
    * Copy constructor.
    *
    * <p>Create a persistent copy of the current state of a locator.
    * When the original locator changes, this copy will still keep
    * the original values (and it can be used outside the scope of
    * DocumentHandler methods).</p>
    *
    * @param locator The locator to copy.
    *)
  constructor TBasicLocator.Create(locator :TLocator);
  begin
    setPublicId(locator.getPublicId);
    setSystemId(locator.getSystemId);
    setLineNumber(locator.getLineNumber);
    setColumnNumber(locator.getColumnNumber);
  end;


  //////////////////////////////////////////////////////////////////////
  // Implementation of org.xml.sax.Locator
  //////////////////////////////////////////////////////////////////////


  (**
    * Return the saved public identifier.
    *
    * @return The public identifier as a string, or null if none
    *         is available.
    * @see org.xml.sax.Locator#getPublicId
    * @see #setPublicId
    *)
  function TBasicLocator.getPublicId :WideString;
  begin
    result := publicId_;
  end;


  (**
    * Return the saved system identifier.
    *
    * @return The system identifier as a string, or null if none
    *         is available.
    * @see org.xml.sax.Locator#getSystemId
    * @see #setSystemId
    *)
  function TBasicLocator.getSystemId :WideString;
  begin
    result := systemId_;
  end;


  (**
    * Return the saved line number (1-based).
    *
    * @return The line number as an integer, or -1 if none is available.
    * @see org.xml.sax.Locator#getLineNumber
    * @see #setLineNumber
    *)
  function TBasicLocator.getLineNumber :Integer;
  begin
    result := lineNumber_;
  end;


  (**
    * Return the saved column number (1-based).
    *
    * @return The column number as an integer, or -1 if none is available.
    * @see org.xml.sax.Locator#getColumnNumber
    * @see #setColumnNumber
    *)
  function TBasicLocator.getColumnNumber :Integer;
  begin
    result := columnNumber_
  end;


  //////////////////////////////////////////////////////////////////////
  // Setters for the properties (not in org.xml.sax.Locator)
  //////////////////////////////////////////////////////////////////////


  (**
    * Set the public identifier for this locator.
    *
    * @param publicId The new public identifier, or null
    *        if none is available.
    * @see #getPublicId
    *)
  procedure TBasicLocator.setPublicId (publicId :WideString);
  begin
    self.publicId_ := publicId;
  end;


  (**
    * Set the system identifier for this locator.
    *
    * @param systemId The new system identifier, or null
    *        if none is available.
    * @see #getSystemId
    *)
  procedure TBasicLocator.setSystemId (systemId :WideString);
  begin
    self.systemId_ := systemId;
  end;


  (**
    * Set the line number for this locator (1-based).
    *
    * @param lineNumber The line number, or -1 if none is available.
    * @see #getLineNumber
    *)
  procedure TBasicLocator.setLineNumber (lineNumber :Integer);
  begin
    self.lineNumber_ := lineNumber;
  end;


  (*
    * Set the column number for this locator (1-based).
    *
    * @param columnNumber The column number, or -1 if none is available.
    * @see #getColumnNumber
    *)
  procedure TBasicLocator.setColumnNumber (columnNumber :Integer);
  begin
    self.columnNumber_ := columnNumber;
  end;

{ TAttributeList }

procedure TAttributeList.add(name, value, typ: WideString);
var
  iname,
  ivalue :IString;
begin
   iname  := iref(name);
   ivalue := iref(value);
   list_.add(iname);
   if value <> '' then
     map_.put(iname, ivalue);
   if typ <> '' then begin
     if types_ = nil then
        types_ := TTreeMap.create;
     types_.put(iname, iref(UpperCase(typ)));
   end
end;

constructor TAttributeList.Create;
begin
   inherited Create;
   list_  := TArrayList.create;
   map_   := TTreeMap.create;
end;

function TAttributeList.getLength: Integer;
begin
   result := list_.size
end;

function TAttributeList.getType(i: Integer): WideString;
begin
  if types_ = nil then
    result := ''
  else
    result := (types_.get(list_.at(i)) as IString).toString;
end;

function TAttributeList.getName(i: Integer): string;
begin
     result := (list_.at(i) as IString).toString;
end;

function TAttributeList.getType(name: WideString): WideString;
var
  r :IString;
begin
  if types_ = nil then
     result := ''
  else begin
    r := types_.get(iref(name)) as IString;
    if r = nil then
       result := ''
    else
       result := r.toString;
  end
end;

function TAttributeList.getValue(name: WideString): WideString;
var
  r :IString;
begin
  r := map_.get(iref(name)) as IString;
  if r = nil then
    result := ''
  else
    result := r.toString;
end;

function TAttributeList.getValue(i: Integer): WideString;
var
  value :IString;
begin
  value := (map_.get(list_.at(i)) as IString);
  if value = nil then
    Result := ''
  else
    Result := Value.toString;
end;

end.
