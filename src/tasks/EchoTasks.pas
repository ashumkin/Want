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

unit EchoTasks;

interface
uses
  SysUtils,
  Classes,
  Math,

  JclStrings,

  WantUtils,
  WantClasses,
  WildPaths;

type
  TEchoTask = class(TTask)
  protected
    FMessage :string;
    FText    :string;
    FFile    :TPath;
    FAppend  :boolean;
    FLevel   :TLogLevel;
    FInput   :TPath;

  public
    constructor Create(Owner :TScriptElement); override;

    procedure Execute; override;

    function FormatText :string;
  published
    property _message :string    read FMessage write FMessage;
    property _text    :string    read FText    write FText;
    property _file    :TPath     read FFile    write FFile;
    property append   :boolean   read FAppend  write FAppend;
    property level    :TLogLevel read FLevel   write FLevel default vlNormal;
    property input    :TPath     read FInput   write FInput;
  end;

implementation

{ TEchoTask }

constructor TEchoTask.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  Level := vlNormal;
end;

procedure TEchoTask.Execute;
var
  msg:      string;
  sysfile:  string;
begin
  inherited Execute;
  msg := Evaluate( _message + FormatText );
  if _file = '' then
    Log(msg, Level)
  else
  begin
    if input = '' then
      Log(vlVerbose, '%s', [ToRelativePath(_file)])
    else
      Log(vlVerbose, '%s -> %s', [ToRelativePath(input), ToRelativePath(_file)]);
    AboutToScratchPath(_file);

    if StrRight(msg, 1) <> #10 then
      msg := AdjustLineBreaks(msg + #10);

    sysfile := ToSystemPath(_file);
    if append and PathIsFile(_file) then
      msg := FileToString(sysfile) + msg;
    StringToFile(sysfile, msg);
  end;
end;


function TEchoTask.FormatText: string;
var
  S     :TStrings;
  Lead  :Integer;
  i     :Integer;
  p     :Integer;
begin
  S := TStringList.Create;
  try
    S.Text := _text;
    Lead := MaxInt;

    while (S.Count > 0) and (S[0] = '') do
      S.Delete(0);

    // find first non blank column
    for i := 0 to S.Count-1 do
    begin
      if Length(Trim(S[i])) = 0 then
        continue;
      Lead := Min(Lead, Length(S[i]));
      for p := 1 to Lead do
      begin
        if not (S[i][p] in [' ',#9]) then
        begin
          Lead := p;
          break;
        end;
      end;
      if Lead <= 0 then
        break;
    end;

    if Lead > 0 then
    begin
      // remove leading spaces
      for i := 0 to S.Count-1 do
        S[i] := Copy(S[i], Lead, Length(S[i]));
    end;

    Result := S.Text;

    if input <> '' then
    begin
      if not FileExists(ToSystemPath(input)) then
        TaskFailure(Format('file "%s" not found', [ToSystemPath(input)]));
      try
        Result := Result + FileToString( ToSystemPath(input) );
      except
        on e :Exception do
          TaskFailure(Format('%s: %s', [input, e.Message]));
      end;
    end;
  finally
    FreeAndNil(S);
  end;
end;

initialization
 RegisterTask(TEchoTask);
end.
