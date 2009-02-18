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
unit dofreader;
{
Unit        : dofreader

Description : provides an abstraction to read a .DOF file

Programmer  : mike

Date        : 09-Dec-2002
}

interface

uses
  classes,
  inifiles,
  sysUtils,
  const_dofReader,
  typ_dofReader;
  

  
type
    
  TDelphiDOFReader = class(Tobject)
  protected
    dof : TIniFile;
    fsectionValues : TStringList;
    fsectionNames : TStringList;
    fdofSection : TDofSection;
    procedure setDofSection(const Value: TDofSection); virtual;    
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(nameOfDOFFile : string);
    property DofSection : TDofSection read fdofSection write setDofSection;
    property sectionValues : TStringList read fsectionValues;
  end;

implementation


  
{ TDelphiDOFReader }

constructor TDelphiDOFReader.Create;
begin
  dof := nil;
  fsectionValues := TStringList.create;
  fsectionNames  := TStringList.create;
  inherited Create;
end;

destructor TDelphiDOFReader.Destroy;
begin
  fsectionNames.free;
  fsectionValues.free;
  dof.free;
  inherited Destroy;
end;

procedure TDelphiDOFReader.LoadFromFile(nameOfDOFFile: string);
const
  NotASection = -1;
var
  dofIsBad : boolean;
  section : TdofSection; 
begin
 dofIsBad := false;
 dof.free;
 try
   dof := TInifile.create(nameOfDofFile);
   dof.UpdateFile;
   dof.ReadSections(fsectionNames);
   if fsectionNames.count < 3 then 
     dofIsBad := true
   else
     begin
       for section := low(TdoFSection) to high(TdoFSection) do
         if fsectionNames.indexOf(NamesOfSections[section]) = NotASection then
           dofIsBad := true;
     end;   
 except
   dofIsBad := true;
 end;
 if dofIsBad then
   raise EBadDofFile.create(nameOfdofFile);    
end;

procedure TDelphiDOFReader.setDofSection(const Value: TDofSection);
begin
  fdofSection := Value;
  dof.ReadSectionValues(NamesOfSections[fdofSection],fsectionValues);
end;

end.
