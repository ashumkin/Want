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
unit JalXMLGenerator;

interface
uses
  Classes,
  JALCollections,
  JALXML;

const
  rcs_id :string = '@(#)$Id: JalXMLGenerator.pas 706 2003-05-14 22:13:46Z hippoman $';

type
  TXMLGenerator = class
    constructor Create(output :TStream);             overload;
    destructor Destroy;                              override;

    procedure docType(name, systemId, publicId :string);

    procedure openElement(tag :string);
    procedure closeElement;
    procedure pi(name, value :string);
    procedure comment(value :string);

    procedure att(name :string; value :string = ''); overload;
    procedure att(name :string; value :Variant);     overload;

    procedure text(s :string);

    function entity(s :string) :Integer;
  protected
    _newElem     :boolean;
    _depth       :Integer;
    _output      :TStream;
    _elems       :TStrings;


    procedure attCheck;

    procedure write(s :string; depth :Integer = 0);
    procedure writeln;

  end;

  TXMLReader = class
    constructor Create;
    destructor  Destroy; override;
    procedure loadFrom(input :TStream);

  protected
    _strings :TStringList;
    _xml     :array of Integer;
    _pos     :Integer;

    procedure loadStringTable(reader :TReader);

    procedure loadDOCTYPE;
    procedure loadPI;
    procedure loadComment;
    procedure loadText;
    procedure loadAttributes;
    procedure loadElement;
    procedure loadEntry;
  end;

implementation
uses
  SysUtils;

const
  nullobj = 0;
  tELEM   = 1;
  tATT    = 2;
  tTEXT   = 3;
  tPI     = 4;
  tCMT    = 5;

{ TXMLGenerator }

constructor TXMLGenerator.Create(output :TStream);
begin
   inherited Create;
   _output := output;
   _elems  := TStringList.Create;
end;

destructor TXMLGenerator.Destroy;
begin
  FreeAndNil(_elems);
  inherited Destroy;
end;

function TXMLGenerator.entity(s: string): Integer;
begin
  Result := 0;
end;

procedure TXMLGenerator.docType(name, systemId, publicId: string);
begin
  write('<?xml version="1.0" encoding="ISO-8859-1" ?>');
  writeln;
end;

procedure TXMLGenerator.attCheck;
begin
  if _newElem then
  begin
    write('>');
    writeln;
  end;
  _newElem := False
end;

procedure TXMLGenerator.openElement(tag: string);
begin
  attCheck;
  write('<' + tag, _depth);
  Inc(_depth, 2);
  _elems.Add(tag);
  _newElem := true;
end;

procedure TXMLGenerator.closeElement;
var
  tag :string;
begin
  assert(_elems.Count > 0);
  tag := _elems[_elems.Count-1];
  if _newElem then
    write(' />')
  else
    write(Format('</%s>', [tag]), _depth-2);
  writeln;
  _newElem := false;
  Dec(_depth, 2);
  with _elems do
    Delete(Count-1);
end;

procedure TXMLGenerator.att(name, value: string);
begin
  assert(trim(name) <> '');
  assert((_elems.Count > 0) and _newElem);
  write(Format(' %s="%s"', [trim(name), XMLQuote(value, false)]));
end;

procedure TXMLGenerator.text(s: string);
begin
  attCheck;
  write(XMLQuote(s, false), _depth);
  writeln;
end;

procedure TXMLGenerator.pi(name, value: string);
begin
  attCheck;
  write(Format('<?%s %s ?>', [name, XMLQuote(value, false)]), _depth);
end;

procedure TXMLGenerator.comment(value: string);
begin
  attCheck;
  write(format('<!-- %s -->', [XMLQuote(value, false)]), _depth);
end;


procedure TXMLGenerator.write(s: string; depth :Integer);
begin
  s := format('%'+ IntToStr(depth) + 's%s', ['',s]);
  _output.write(s[1], length(s))
end;

const
  nl :char = #10;

procedure TXMLGenerator.writeln;
begin
  _output.write(nl, 1)
end;



procedure TXMLGenerator.att(name: string; value: Variant);
begin
  att(name, string(value));
end;

{ TXMLReader }

constructor TXMLReader.Create;
begin

end;

destructor TXMLReader.Destroy;
begin
  _strings.Free;
  inherited Destroy;
end;

procedure TXMLReader.loadFrom(input: TStream);
var
  reader :TReader;
  n      :Integer;
begin
  reader := TReader.Create(input, 1024);
  try
    loadStringTable(reader);

    n := reader.ReadInteger;
    setLength(_xml, n);
    reader.Read(_xml[0], n * sizeOf(_xml[0]));

    _pos := 0;
    loadEntry;
    _strings.Free;
    _strings := nil;
  finally
    reader.Free
  end
end;


procedure TXMLReader.loadStringTable(reader :TReader);
var
  i,
  n :Integer;
begin
   _strings.Free;
   _strings := TStringList.Create;

   n := reader.ReadInteger;
   for i := 1 to n do
   begin
       _strings.Add(reader.ReadString);
   end;
end;

procedure TXMLReader.loadDOCTYPE;
begin
end;

procedure TXMLReader.loadAttributes;
begin
  assert(_xml[_pos] = tATT);
  inc(_pos);
  while _xml[_pos] <> 0 do begin
      if _xml[_pos+1] <> 0 then begin
         // att with value
      end
      else begin
         // att without value
      end;
      inc(_pos,2)
  end;
  inc(_pos);
end;

procedure TXMLReader.loadElement;
var
  tag :string;
begin
  assert(_xml[_pos] = tELEM);
  inc(_pos);
  tag := _strings[_xml[_pos]];
  inc(_pos);
  loadAttributes;
  // startElement
  if _xml[_pos] = 0 then
     // endElement
  else begin
     while _xml[_pos] <> 0 do
        loadEntry;
     // endElement
  end;
  inc(_pos);
end;

procedure TXMLReader.loadPI;
begin
  assert(_xml[_pos] = tPI);
  inc(_pos);
  // processingInstruction _pos _pos+1
  inc(_pos, 2);
  assert(_xml[_pos] = 0);
  inc(_pos);
end;

procedure TXMLReader.loadComment;
begin
  assert(_xml[_pos] = tCMT);
  inc(_pos);
  // comment
  inc(_pos);
  assert(_xml[_pos] = 0);
  inc(_pos);
end;

procedure TXMLReader.loadText;
begin
  assert(_xml[_pos] = tTEXT);
  inc(_pos);
  // text
  inc(_pos);
end;

procedure TXMLReader.loadEntry;
begin
  case _xml[_pos] of
    tELEM :
      loadElement;
    tPI:
      loadPI;
    tCMT:
      loadComment;
    tTEXT:
      loadText;
    else
      inc(_pos);
  end;
end;

end.
