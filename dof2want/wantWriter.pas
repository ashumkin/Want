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
unit wantWriter;
{
Unit        : wantWriter

Description : creates a want file description from delph delphi options file
              describing the delphi project?

Programmer  : mike

Date        : 12-Dec-2002
}

interface

uses
  classes,
  dofReader;

type

  TTextfileoutput = class(Tobject)
  protected
    outputFile: textfile;
  public
    constructor Create(nameOfTextFile: string);
    destructor Destroy; override;
    procedure outputString(str: string);
  end;

  TWantCompileWriter = class(Tobject)
  private
    function outputPathElementValues(listOfElements: TStringList): string;
    function outputValueElementValues(listOfElements: TStringList): string;

  protected
    wantFile: TTextfileoutput;
    fnameOfProject : string;
    function OutputElementValues(listOfElements: TStringList;attributeName : string): string;
    function OutputTag(elementName, attributes, elementValue: string): string;
    function AttributeElement(attributeName,
      attributeValue: string): string;    
  public
    constructor Create;
    destructor Destroy; override;
    procedure WriteFile(reader: TDelphiDOFReader; outputName: string);
    property NameOfProject : string read fNameOfProject write fNameOfProject;
  end;
  
implementation

uses
  dofCompilerFlags,
  dofLinkerFlags,
  dofDirectoriesFlags,
  sysUtils;

const
  WindowsEndOfLine = #13+#10;
    
{ TWantCompileWriter }

function TWantCompileWriter.outputValueElementValues(listOfElements: TStringList): string;
const
  attributeName = 'value';
begin
  result := OutputElementValues(listOfElements,attributeName);
end;
  
function TWantCompileWriter.outputPathElementValues(listOfElements: TStringList): string;
const
  attributeName = 'path';
begin
  result := OutputElementValues(listOfElements,attributeName);
end;

function TWantCompileWriter.OutputElementValues(listOfElements: TStringList;attributeName : string): string;
var
  iterElement: integer;
  elementName,
    elementValue: string;
begin
  result := '';
  try
    for iterElement := 0 to listOfElements.Count - 1 do
      begin
        elementName := ListOfelements.names[iterElement];
        elementValue := ListOfelements.values[elementName];
        result := result + outputTag(elementName, AttributeElement(attributeName, elementValue),'');
      end;
  except
    on e: exception do
      raise exception.create(e.Message + #13 + 'outputElementValues');
  end;
end;

function TWantCompileWriter.AttributeElement(attributeName, attributeValue: string): string;
begin
  result := format('%s = "%s" ', [attributeName, attributeValue]);
end;

function TWantCompileWriter.OutputTag(elementName, attributes, elementValue: string): string;
begin
  if elementValue <> '' then
    begin
      result := format('<%s %s>%s%s%s</%s>', [elementName, attributes, WindowsEndOfLine,ElementValue, WindowsEndOfLine,elementName])
    end
  else
    result := format('<%s %s />', [elementName, attributes]);
  result := WindowsEndOfLine + result + WindowsEndOfLine;
end;

procedure TWantCompileWriter.WriteFile(reader: TDelphiDOFReader;
  outputName: string);
const
  attributeName = 'name';
  elementInclude = 'include';

var
  DirectoryInfo: TDirectoriesFlagExtractor;
  compilerFlags: TCompilerFlagExtractor;
  linkerFlags: TLinkerFlagExtractor;
  iterPathElement: integer;
  hasPathElements: boolean;


  iterDefine: integer;
  elements: string;
  conditionals: string;
  pathElementsRef: string;

  wantDef : string;
begin
  assert(fnameOfProject <> '','Must define the project name to write a want_compile file');
  wantFile := TTextfileoutput.Create(outputName);
  try

    DirectoryInfo := TDirectoriesFlagExtractor.Create(reader);
    try
      DirectoryInfo.ExtractValues;
      hasPathElements := directoryInfo.pathElements.count > 0;

      compilerFlags := TCompilerFlagExtractor.Create(reader);
      try
        compilerFlags.ExtractValues;
        linkerFlags := TLinkerFlagExtractor.create(reader);
        try
          linkerFlags.extractValues;

          if hasPathElements then
            begin
              elements := '';
              for iterPathElement := 0 to directoryInfo.pathElements.count - 1 do
                elements := elements + outputTag(elementInclude, AttributeElement(attributeName, directoryInfo.pathElements[iterPathElement]), '');
              elements := outputTag('patternset',AttributeElement('id','sources'),elements);
            end
          else
            elements := '';

          conditionals := '';
          for iterDefine := 0 to directoryInfo.conditionals.Count - 1 do
            begin
              conditionals := conditionals +
                outputTag('define', AttributeElement('name', directoryInfo.conditionals[iterDefine]), '');
            end;

          if hasPathElements then
            begin
              pathElementsRef :=
                outputTag('unitPath', AttributeElement('refid', 'sources'), '') +
                outputTag('includePath', AttributeElement('refid', 'sources'), '') +
                outputTag('resourcePath', AttributeElement('refid', 'sources'), '');
            end
          else
            pathElementsRef := '';

          wantDef :=   
          OutputTag('project', 
                    AttributeElement('name', 'compilecode') +
                    AttributeElement('basedir', '.') +
                    Attributeelement('default', 'compile'),
                    
                    elements +
        
                    outputTag('target', 
                              AttributeElement('name', 'compile'),
                              outputTag('dcc', 
                                        AttributeElement('basedir', '.') +
                                        AttributeElement('source', fNameOfProject),
                                        OutputTag('build',attributeElement('value','True'),'')+
                                        OutputPathElementValues(directoryInfo.values)+
                                        OutputValueElementValues(compilerFlags.values) +
                                        OutputValueElementValues(linkerFlags.values) +
                                        conditionals +
                                        pathElementsRef
                                       )
                             )
                   );

            wantFile.outputString(wantDef);       
        finally
          linkerFlags.free;
        end;
      finally
        compilerFlags.free;
      end;
    finally
      directoryInfo.free;
    end;
  finally
    wantFile.free;
  end;
end;

constructor TWantCompileWriter.Create;
begin
  inherited Create;
  fnameOfProject := '';
end;

destructor TWantCompileWriter.Destroy;
begin
  inherited;
end;

{ TTextfileoutput }

constructor TTextfileoutput.Create(nameOfTextFile: string);
begin
  assign(outputFile, NameOfTextfile);
  rewrite(outputFile);
end;

destructor TTextfileoutput.Destroy;
begin
  closefile(outputFile);
  inherited;
end;

procedure TTextfileoutput.outputString(str: string);
begin
  writeln(outputFile, str);
end;

end.

