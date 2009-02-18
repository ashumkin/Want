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
unit dofDirectoriesFlags;
{
Unit        : dofDirectoriesFlags

Description : extracts directory and other items

Programmer  : mike

Date        : 11-Dec-2002
}

interface

uses
  classes,
  dofReader,
  dofFlagExtractor;
  
type

  TDirectoriesFlagExtractor = class(TDOFFlagExtractor)
  protected
    fpathElements : TSTringList;
    fconditionals : TStringList;
  public
    constructor Create(reader : TDelphiDOFReader);
    destructor Destroy; override;
    procedure ExtractValues; override;
    property pathElements : TSTringList read fpathelements;
    property conditionals : TStringList read fconditionals;
  end;
  
implementation

uses
  typ_dofReader,
  tokenizer;
  
const
  dof_MapFile = 'MapFile';
  dof_ConsoleApp = 'ConsoleApp';

type
  TElementExtractor = class(TTokenizer)
  public
    constructor create;
    destructor destroy; override;
    procedure elementsToList(list : TStringList);
  end;

{ TDirectoriesFlagExtractor }

constructor TDirectoriesFlagExtractor.Create(reader : TDelphiDOFReader);
begin
  inherited Create(reader);
  fpathElements := TSTringList.create;
  fconditionals := TStringList.create;  
end;

destructor TDirectoriesFlagExtractor.Destroy;
begin
  inherited Destroy;
end;

procedure TDirectoriesFlagExtractor.ExtractValues;
const
  BoolToStr : array[boolean] of string =
  (
   'False',
   'True'
  );
  dof_outputDir = 'OutputDir';
  want_exeoutputElement = 'exeoutput';
    
  dof_UnitOutputDir = 'UnitOutputDir';
  want_dcuoutputElement = 'dcuoutput';  
  
  dof_searchPath = 'SearchPath';
  dof_conditionals = 'Conditionals';
var
 flagValue : string;
 elementExtractor : TElementExtractor;
begin
  freader.DofSection := tsDirectories;
  try
    flagValue := freader.sectionValues.Values[dof_outputDir];       
    if flagValue <> '' then
      fvalues.values[want_exeoutputElement] := flagValue;
  except
  end;  

  try
    flagValue := freader.sectionValues.Values[dof_UnitOutputDir];       
    if flagValue <> '' then
      fvalues.values[want_dcuoutputElement] := flagValue;
  except
  end;    

  
  elementExtractor := TElementExtractor.create;
  try
    fpathElements.clear; 
    try
      flagValue := freader.sectionValues.values[dof_searchPath];
      elementExtractor.Tokenize(flagValue);
      elementExtractor.elementsToList(fpathElements);
    except
    end;
   try
      flagValue := freader.sectionValues.values[dof_conditionals];
      elementExtractor.Tokenize(flagValue);
      elementExtractor.elementsToList(fconditionals);
   except
   end; 
  finally
    elementExtractor.free;
  end;
end;

{ TElementExtractor }

constructor TElementExtractor.create;
begin
  inherited Create;
  Delimiters := [';'];
end;

destructor TElementExtractor.destroy;
begin
  inherited;
end;

procedure TElementExtractor.elementsToList(list: TStringList);
var
  iterToken : integer;
begin
  assert(list <> nil,'cannot transfer to an undefined list');
  
  list.Clear;
  
  for iterToken := 0 to count-1 do
    list.add(token[iterToken]);
end;

end.
