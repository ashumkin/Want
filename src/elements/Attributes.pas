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
    @brief Attribute types

    @author Juancarlo Añez
}

unit Attributes;

interface
uses
  SysUtils,
  WildPaths,
  WantClasses;

type
  TBooleanAttributeElement = class(TCustomAttributeElement)
  protected
    FVAlue :boolean;
  published
    property value :boolean read FValue write FValue;
  end;

  TPathAttributeElement = class(TCustomAttributeElement)
  protected
    FPath :TPath;
    function  ValueName :string; override;
  published
    property path :TPath read FPath write FPath;
  end;



implementation

function TPathAttributeElement.ValueName: string;
begin
  Result := 'path';
end;

initialization
  RegisterElements([ TAttributeElement,
                     TPathAttributeElement,
                     TBooleanAttributeElement
                     ]);
end.
