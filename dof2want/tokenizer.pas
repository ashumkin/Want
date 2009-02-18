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
unit tokenizer;
{
Unit        : tokenizer

Description : class that will take an input stream and return all the tokns
              from that input string.

Programmer  : mike

Date        : 15-May-2001
}

interface

uses
  classes;

    
type

  tTokenDelimeters = set of char;
  
  TTokenizer = class(TObject)
  protected
    fallowEmptyTokens : boolean;
    fdelimiters : tTokenDelimeters;
    tokenList : TStringList;
    function GetToken(var line, token: string; delimeters: TTokenDelimeters): boolean;    
    function GetTokenItem(index : integer) : string;
    function FindDelimeterPosition(const line: string;  delimeters: TTokenDelimeters): integer;    
  public
    constructor create;
    destructor destroy; override;
    procedure Tokenize(input : string); virtual;
    function Count : integer;    
    property Token[index : integer] : string read GetTokenItem;
    property Delimiters : tTokenDelimeters read fdelimiters write fdelimiters;
    property allowEmptyTokens : boolean read fallowEmptyTokens write fallowEmptyTokens;
  end;
  


implementation

const
  AnEmptyString = '';
  ASCII_Space = #32;
 
function TTokenizer.Count: integer;
begin
  result := tokenList.Count;
end;

constructor TTokenizer.create;
begin
  fdelimiters := [ASCII_Space];
  tokenList := TStringList.Create;
  fallowEmptyTokens := False;
end;

destructor TTokenizer.destroy;
begin
  tokenList.free;
  inherited;
end;

function TTokenizer.FindDelimeterPosition(const line : string;delimeters: TTokenDelimeters) : integer;
const
  NoDelimeter = 0;
var
  iterChar : integer;  
begin
  result := NoDelimeter;
  iterChar := 1;
  while (iterChar <= length(line)) and (result = NoDelimeter) do
    begin
      if line[iterChar] in delimeters then
        begin
          result := iterChar;
        end;
      inc(iterChar);    
    end;
end;

function TTokenizer.GetToken(var line, token: string; delimeters: TTokenDelimeters): boolean;
var
  delimpos: integer;
begin
  try
  { trim off any leading delimeter}
  
  { because I'm lazy, this loop is inefficient }
  while (length(line) > 0) and (findDelimeterPosition(line,delimeters)=1) do
    begin
      delete(line, 1, 1);
      if allowEmptyTokens then
        begin
           token := AnEmptyString;
           GetToken := True;
           exit;        
        end;
    end;  
    
  delimpos := FindDelimeterPosition(line,delimeters);
  { return an empty token if we are at the EOL and no delimeter is found }
  if (delimpos = 0) and (length(line) = 0) then
    begin
      token := AnEmptyString;
      GetToken := False;
      exit;
    end;
  { return the entire line if no delimiter is found }
  if (delimpos = 0) then
    begin
      token := line;
      line := AnEmptyString;
      GetToken := True;
      exit;
    end;

  { cut out the token (excluding the delimiter) and remove it from the line }
  token := Copy(line, 1, delimpos - 1);
  Delete(line, 1, delimpos);
  GetToken := True;
  except
   GetToken := false;
  end;
end;

function TTokenizer.GetTokenItem(index: integer): string;
begin
  try
    result := tokenList[index];
  except
    result := AnEmptyString;
  end;
end;

procedure TTokenizer.Tokenize(input: string);
var
  token : string;
begin
  tokenList.clear;
  while GetToken(input,token,fdelimiters) = true do
    begin
      tokenList.add(token);
    end;
end;

end.
