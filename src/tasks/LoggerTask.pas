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

unit LoggerTask;
interface
uses
  SysUtils,
  Classes,
  WantUtils,
  WantClasses;

type
  TLogFormat = (brief, normal, detailed);

  TInfoElement = class(TScriptElement)
  protected
    FCode :string;
    FText :string;
  published
    property code :string  read FCode write FCode;
    property text :string  read FText write FText;
  end;

  TLoggerTask = class(TTask)
  protected
    FFile   :string;
    FFormat :TLogFormat;
    FInfos  :TList;
  public
    constructor Create(Owner :TScriptElement); override;
    destructor Destroy; override;

    class function TagName :string; override;

    procedure Init; override;
    procedure Execute;  override;
  published
    function CreateInfo :TInfoElement;

    property _file  :string     read FFile   write FFile;
    property format :TLogFormat read FFormat write FFormat;
  end;

implementation

class function TLoggerTask.TagName :string;
begin
  Result := 'log';
end;

constructor TLoggerTask.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
end;

destructor TLoggerTask.Destroy;
begin
  // no need to free the TInfoElements themselves
  FreeAndNil(FInfos);
  inherited Destroy;
end;

function TLoggerTask.CreateInfo :TInfoElement;
begin
  Result := TInfoElement.Create(Self);
  if FInfos = nil then
    FInfos := TList.Create;
  FInfos.Add(Result);
end;

procedure TLoggerTask.Init;
begin
  inherited Init;
  RequireAttribute('file');
end;

procedure TLoggerTask.Execute;
var
  LogFile: System.Text;
  i:   Integer;
begin
  Log(SysUtils.Format('writing log info to "%s"', [_file]));
  AboutToScratchPath(_file);
  System.Assign(LogFile, ToSystemPath(_file));
  try
    if FileExists(ToSystemPath(_file)) then
      System.Append(LogFile)
    else
      System.Rewrite(LogFile);
  except
    TaskFailure('could not open log file');
  end;
  try
    try
      if FInfos <> nil then
      begin
        for i := 0 to FInfos.Count-1 do
        begin
          with TInfoElement(FInfos[i]) do
            Writeln( LogFile,
                     SysUtils.Format( '%-20s %12s %s',
                                       [
                                       FormatDateTime('yyyy/mm/dd hh:nn:ss', Now),
                                       '['+code+']',
                                       text
                                       ]));
        end;
      end;
    except
      TaskFailure('could not write to log file');
    end;
  finally
    System.Close(LogFile);
  end;
end;


initialization
  RegisterTask(TLoggerTask);
end.

