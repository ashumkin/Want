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

unit JalProxyStreams;

interface
uses
  Classes;

const
  rcs_id :string = '@(#)$Id: JalProxyStreams.pas 706 2003-05-14 22:13:46Z hippoman $';

type
  TStreamProxy = class(TStream)
  protected
    _strm    :TStream;
  public
     constructor Create(Strm :TStream);
     function Read(var Buffer; Count: Integer): Longint;    override;
     function Write(const Buffer; Count: Integer): Longint; override;
     function Seek(Offset: Longint; Origin: Word): Longint; override;

     property Stream :TStream
       read _strm;
  end;

implementation

{ TStreamProxy }

constructor TStreamProxy.Create(Strm: TStream);
begin
  assert(strm <> nil);
  inherited Create;
  _strm := Strm;
end;

function TStreamProxy.Read(var Buffer; Count: Integer): Longint;
begin
  result := _strm.Read(Buffer, Count)
end;

function TStreamProxy.Seek(Offset: Integer; Origin: Word): Longint;
begin
  result := _strm.Seek(Offset, Origin);
end;

function TStreamProxy.Write(const Buffer; Count: Integer): Longint;
begin
  result := _strm.Write(Buffer, Count)
end;

end.
