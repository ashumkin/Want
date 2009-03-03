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

unit RegexpElements;

interface
uses
  SysUtils,
  PerlRE,
  WantClasses;

type
  TRegexpTask = class(TTask)
  protected
    FProperty :string;
    FText     :string;
    FPattern  :string;
    FSubst    :string;
    FTrim      :boolean;
    FOverwrite :boolean;
    FToUpper   :boolean;
    FToLower   :boolean;

    function Substitute(Pattern, Subst, Text :string) :string;
    procedure Perform;
  public
    procedure Init; override;
    procedure Execute; override;
  published
    property _property :string   read FProperty   write FProperty;
    property _text     :string   read FText       write FText;
    property pattern   :string   read FPattern    write FPattern;
    property subst     :string   read FSubst      write FSubst;
    property trim      :boolean  read FTrim       write FTrim;
    property overwrite :boolean  read FOverwrite  write FOverwrite;
    property toupper   :boolean  read FToUpper    write FToUpper;
    property tolower   :boolean  read FToLower    write FToLower;
  end;

implementation

{ TCustomRegexpElement }

procedure TRegexpTask.Init;
begin
  inherited Init;
  RequireAttribute('property');
  RequireAttribute('pattern');
  Perform;
end;

procedure TRegexpTask.Execute;
begin
  inherited;
  Perform;
end;

procedure TRegexpTask.Perform;
begin
  if not HasAttribute('subst') then
    Owner.SetProperty(_property, Substitute('.*('+pattern+').*', '\1', _text), overwrite)
  else
    Owner.SetProperty(_property, Substitute(pattern, subst, _text), overwrite);
end;

function TRegexpTask.Substitute(Pattern, Subst, Text : string): string;
begin
  Log(vlDebug, 'Replacing /%s/ with /%s/', [Pattern, Subst]);
  Result := PerlRE.Replace(Pattern, Subst, Text, True);
  if ToUpper then
    Result := UpperCase(Result)
  else if ToLower then
    Result := LowerCase(Result);
end;


initialization
  RegisterElement(TRegexpTask);
end.
