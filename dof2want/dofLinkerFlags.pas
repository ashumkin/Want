(****************************************************************************
 * dof2want - A convert utility for Want                                    *
 * Copyright (c) 2003 Mike Johnson.                                         *
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

    @author Mike Johnson
}
unit dofLinkerFlags;
{
Unit        : dofLinkerFlags

Description : gets the linker flags from the dof reader

Programmer  : mike

Date        : 11-Dec-2002
}

interface

uses
  dofFlagExtractor;
type

  TLinkerFlagExtractor = class(TDOFFlagExtractor)
  public
    procedure ExtractValues; override;
  end;

implementation

uses
  typ_dofReader,
  sysUtils;
  
procedure TLinkerFlagExtractor.ExtractValues;

const
  BoolToStr : array[boolean] of string =
  (
   'False',
   'True'
  );
  dof_MapFile = 'MapFile';
  dof_ConsoleApp = 'ConsoleApp';
  want_mapElement = 'map';
  want_consoleAppElement = 'console';
var
 flagValue : string;
 flagState : boolean;
 flagInt : integer;
begin
  freader.DofSection := tsLinker;
  try
    flagValue := freader.sectionValues.Values[dof_MapFile];       
    flagInt := StrToInt(flagValue);
    case flagInt of
      0 : fvalues.Values[want_mapElement] := 'none';
      1 : fvalues.Values[want_mapElement] := 'segments';
      2 : fvalues.Values[want_mapElement] := 'publics';
      3 : fvalues.Values[want_mapElement] := 'detailed';
    end;    
  except
  end;  
  try
   flagValue := freader.sectionValues.values[dof_ConsoleApp];
   flagState := Boolean(StrToInt(flagValue));
   fvalues.Values[want_consoleAppElement] := BoolToStr[flagState];
  except
  end;
end;

end.






