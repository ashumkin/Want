(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 2001-2003 Juancarlo Anez, Caracas, Venezuela.              *
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

unit Resources;

interface
uses
  Windows,
  SysUtils,
  Classes;


type

  TResourceType = (
    RT_UNKNOWN,          // 0
    RT_CURSOR,           // 1
    RT_BITMAP,           // 2
    RT_ICON,             // 3
    RT_MENU,             // 4
    RT_DIALOG,           // 5
    RT_STRING,           // 6
    RT_FONTDIR,          // 7
    RT_FONT,             // 8
    RT_ACCELERATOR,      // 9
    RT_RCDATA,           // 10
    RT_MESSAGETABLE,     // 11
    RT_GROUP_CURSOR,     // 12
    RT_GROUP_ICON,       // 14
    RT_VERSION,          // 16
    RT_DLGINCLUDE,       // 17
    RT_PLUGPLAY,         // 19
    RT_VXD,              // 20
    RT_ANICURSOR,        // 21
    RT_ANIICON           // 22
  );

  TResourceHeaderSizes = packed record
    DataSize   :DWORD;
    HeaderSize :DWORD;
  end;

  TResourceHeaderId = packed record
    Lead        :WORD; // always $FFFF
    Id          :WORD;
  end;

  TResourceHeaderInfo = record
    DataVersion      :DWORD;
    MemoryFlags      :WORD;
    LanguageId       :WORD;
    Version          :DWORD;
    Characteristics  :DWORD;
  end;

  TResourceHeader = packed record
    Sizes            :TResourceHeaderSizes;
    _type            :TResourceHeaderId;
    Name             :TResourceHeaderId;
    Info             :TResourceHeaderInfo;
  end;

  TArrayOfByte = array of Byte;


  TResource = class
  protected
    _type   :WideString;
    _name   :WideString;
    _info   :TResourceHeaderInfo;
    _data   :TArrayOfByte;

    procedure SetId(var Id :WideString; Value :WORD);
    function  GetId(var Id :WidesTring) :WORD;

    procedure SetTypeId(Value :TResourceType);
    function  GetTypeId :TResourceType;

    procedure SetNameId(Value :WORD);
    function  GetNameId :WORD;

    procedure ParseHeader(header :array of word); virtual;
    procedure ParseData(data     :TArrayOfByte);  virtual;
  public
    constructor Create;

    procedure LoadFromStream(S :TStream);
    procedure SaveToStream(S :TStream);

    function TypeIsOrdinal :boolean;
    function NameIsOrdinal :boolean;

    property TypeId :TResourceType read GetTypeId write SetTypeId;
    property NameId :WORD read GetNameId write SetNameId;

    property ResType :WideString read _type write _type;
    property Name    :WideString read _name write _name;

    property data    :TArrayOfByte read _data write _data;
  end;

  TResourceFile = class
  protected
    _Resources : array of TResource;

    function GetResource(Index :Integer):TResource;
  public
    destructor Destroy; override;

    procedure AddResource(R :TResource);
    procedure Clear;

    procedure LoadFromFile(FileName :string);
    procedure LoadFromStream(S :TStream);

    procedure SaveToFile(FileName :string);
    procedure SaveToStream(S :TStream);

    function ResourceCount :WORD;

    property Resource[i :Integer] :TResource read GetResource;
  end;


implementation

{ TResource }

constructor TResource.Create;
begin
  inherited Create;
end;

procedure TResource.SetId(var Id: WideString; Value: WORD);
begin
  SetLength(Id, 2);
  Id[1] := WideChar($FFFF);
  Id[2] := WideChar(Value);
end;

function TResource.GetId(var Id: WidesTring): WORD;
begin
  if (Length(Id) < 2) or (WORD(Id[1]) <> $FFFF) then
    Result := 0
  else
    Result := WORD(Id[2]);
end;

procedure TResource.SetTypeId(Value: TResourceType);
begin
  SetId(_type, Ord(Value));
end;

function TResource.GetTypeId: TResourceType;
begin
  Result := TResourceType(Byte(GetId(_type)));
end;

procedure TResource.SetNameId(Value: WORD);
begin
  SetId(_name, Value);
end;

function TResource.GetNameId: WORD;
begin
  Result := GetId(_name);
end;

procedure TResource.LoadFromStream(S: TStream);
var
  Sizes   :TResourceHeaderSizes;
  header  :array of word;
  Rem     :Integer;
begin
  S.ReadBuffer(Sizes, SizeOf(Sizes));
  Assert(Sizes.HeaderSize >= SizeOf(Sizes));

  Rem := Sizes.HeaderSize - SizeOf(Sizes);
  SetLength(header, Rem div 2);
  S.ReadBuffer(header[0], Rem);

  SetLength(_data, Sizes.DataSize);
  if Sizes.DataSize > 0 then
    S.ReadBuffer(_data[0], Sizes.DataSize);

  ParseHeader(header);
  ParseData(_data);
end;


procedure TResource.ParseHeader(header: array of word);
var
  pos :Integer;
begin
  pos := 0;

  if (header[pos] = $FFFF) then
  begin
    TypeId := TResourceType(Byte(header[pos+1]));
    Inc(pos, 2);
  end
  else
  begin
    ResType := PWideChar(@header[pos]);
    Inc(pos, 1+Length(ResType))
  end;

  if (header[pos] = $FFFF) then
  begin
    NameId := header[pos+1];
    Inc(pos, 2);
  end
  else
  begin
    Name := PWideChar(@header[pos]);
    Inc(pos, 1+Length(ResType))
  end;

  Assert((2* (Length(header) - pos)) >= SizeOf(TResourceHeaderInfo));
  Move(header[pos], _info, SizeOf(_info));
end;

procedure TResource.SaveToStream(S: TStream);
var
  Sizes   :TResourceHeaderSizes;
  Id      :TResourceHeaderId;
begin
  Sizes.DataSize   := Length(data);
  Sizes.HeaderSize := SizeOf(TResourceHeader);

  if not TypeIsOrdinal then
  begin
    Dec(Sizes.HeaderSize, SizeOf(TResourceHeaderId));
    Inc(Sizes.HeaderSize, 2*(1 + Length(ResType)));
  end;

  if not NameIsOrdinal then
  begin
    Dec(Sizes.HeaderSize, SizeOf(TResourceHeaderId));
    Inc(Sizes.HeaderSize, 2*(1 + Length(Name)));
  end;

  S.WriteBuffer(Sizes, SizeOf(Sizes));

  Id.Lead := $FFFF;
  Id.Id   := 0;

  if TypeIsOrdinal then
    S.WriteBuffer(_type[1], 4)
  else if Length(_type) > 0 then
    S.WriteBuffer(_type[1], 2+Length(_type))
  else
    S.WriteBuffer(Id, SizeOf(Id));

  if NameIsOrdinal then
    S.WriteBuffer(_name[1], 4)
  else if Length(_name) > 0 then
    S.WriteBuffer(_name[1], 2+Length(_name))
  else
    S.WriteBuffer(Id, SizeOf(Id));

  S.WriteBuffer(_info, SizeOf(_info));
  if Length(_data) > 0 then
    S.WriteBuffer(_data[0], Length(_data));
end;



function TResource.NameIsOrdinal: boolean;
begin
  Result := (Length(_name) = 2) and (WORD(_name[1]) = $FFFF);
end;

function TResource.TypeIsOrdinal: boolean;
begin
  Result := (Length(_type) = 2) and (WORD(_type[1]) = $FFFF);
end;

procedure TResource.ParseData(data: TArrayOfByte);
begin

end;

{ TResourceFile }

destructor TResourceFile.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TResourceFile.Clear;
var
  i :Integer;
begin
  for i := Low(_Resources) to High(_Resources) do
    _Resources[i].Free;
  _Resources := nil;
end;

function TResourceFile.ResourceCount: WORD;
begin
  Result := Length(_Resources);
end;

procedure TResourceFile.AddResource(R: TResource);
begin
  SetLength(_Resources, 1 + Length(_Resources));
  _Resources[High(_Resources)] := R;
end;

function TResourceFile.GetResource(Index: Integer): TResource;
begin
  Assert((Index >= Low(_Resources)) and (Index <= High(_Resources)));
  Result := _Resources[Index];
end;

procedure TResourceFile.LoadFromFile(FileName: string);
var
  S :TFileStream;
begin
  S := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(S);
  finally
    S.Free;
  end;
end;

procedure TResourceFile.LoadFromStream(S: TStream);
var
  M     :TMemoryStream;
  Sizes :TResourceHeaderSizes;
  GoOn  :boolean;
  R     :TResource;
begin
  GoOn := True;
  M := TMemoryStream.Create;
  try
    while GoOn and (S.Position < S.Size) do
    begin
       M.Clear;

       M.CopyFrom(S, SizeOf(Sizes));
       M.Position := 0;
       GoOn := (M.Read(Sizes, SizeOf(Sizes)) = SizeOf(Sizes))
               and (Sizes.HeaderSize >= SizeOf(Sizes));

       if GoOn then
       begin
         M.CopyFrom(S, Sizes.DataSize + (Sizes.HeaderSize - SizeOf(Sizes)));

         R := TResource.Create;
         try
           M.Position := 0;
           R.LoadFromStream(M);
           AddResource(R);
         except
           R.Free;
           raise;
         end;
       end;
    end;
  finally
    M.Free;
  end;
end;

procedure TResourceFile.SaveToFile(FileName: string);
var
  S :TFileStream;
begin
  S := TFileStream.Create(FileName, fmCreate or fmShareDenyWrite);
  try
    SaveToStream(S);
  finally
    S.Free;
  end;
end;

procedure TResourceFile.SaveToStream(S: TStream);
var
  i :Integer;
begin
  for i := 0 to ResourceCount-1 do
  begin
    Resource[i].SaveToStream(S);
  end;
end;

end.
