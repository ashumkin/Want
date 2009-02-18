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
    @author Dan Hughes <dan@multiedit.com>
}

unit Properties;

interface
uses
  { Delphi }
  Classes,
  IniFiles,

  {Local}
  WantClasses,
  WildPaths,
  JalPaths;

type
  TPropertyElement = class(TScriptElement)
  protected
    FName: string;
    FValue: string;
    FFileName: TPath;
    FSection: string;
    FOverwrite :boolean;
    procedure ProcessFile;

    function GetPath :TPath;
    procedure SetPath(Path :TPath);
  public
    procedure Init;    override;
  published
    property name: string read FName  write FName;
    property value: string read FValue write FValue;
    property path:  TPath    read GetPath write SetPath;
    property _file: TPath read FFileName  write FFileName;
    property section: string read FSection write FSection;
    property overwrite :boolean read FOverwrite write FOverwrite;
  end;

implementation

{ TPropertyElement }

function TPropertyElement.GetPath: TPath;
begin
  Result := Value;
end;

procedure TPropertyElement.SetPath(Path: TPath);
begin
  FValue := ToPath(Path);
end;

procedure TPropertyElement.Init;
begin
  inherited Init;
  if Enabled then
  begin
    RequireAttributes(['name|file', 'value|path|file']);
    Assert(Owner <> nil);
    if ( _file <> '' ) then
    begin
      ProcessFile;
    end
    else
    begin
      Owner.SetProperty(name, value, overwrite);
    end;
  end;
end;

procedure TPropertyElement.ProcessFile;
var
  I: Integer;
  IniFile : TMemIniFile;
  PropList : TStringList;

  Name : string;
  Value : string;

begin
  PropList := TStringList.Create;
  try
    if (Section <> '') then
    begin
      IniFile := TMemIniFile.Create(WildPaths.ToSystemPath(_file));
      try
        if IniFile.SectionExists(Section) then
        begin
          IniFile.ReadSectionValues(Section, PropList);
        end;
      finally
        IniFile.Free;
      end;
    end
    else begin
      PropList.LoadFromFile(WildPaths.ToSystemPath(_file));
    end;
    for I := PropList.Count - 1 downto 0 do
    begin
      Name := PropList.Names[I];
      Value := PropList.Values[Name];
      if (Name <> '') and (Name[1] <> '#') then
      begin
        Owner.SetProperty(Name, Value, overwrite);
      end;
    end;
  finally
    PropList.Free;
  end;
end;


initialization
  RegisterElement(TPropertyElement);
end.

