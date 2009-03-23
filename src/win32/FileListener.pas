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
    @brief File listener implementation

    @author Zapped
}
unit FileListener;

interface

uses
  Windows,
  SysUtils,
  Classes,

  WildPaths,

  WantClasses,
  ConsoleListener;

const
  rcs_id :string = '#(@)$Id: FileListener.pas 1 2009-03-20 12:37:46Z zapped $';

type
  TFileListener = class(TConsoleListener)
  private
  protected
    FFileName: string;
    FFileHandle: text;
    FOwner: TConsoleListener;
    FIsFileOpened: boolean;
    procedure LogPrefix(const Prefix: string; Level: TLogLevel); override;
    procedure LogMessage(const Prefix, Msg :string; Level :TLogLevel);  override;
    procedure OpenFile;
  public
    constructor Create(AOwner: TConsoleListener; const pFileName: string;
      pLevel: TLogLevel = vlDebug);
    destructor Destroy; override;

    property FileName: string read FFileName write FFileName;
    property IsFileOpened: boolean read FIsFileOpened;
  end;

implementation

{ TFileListener }

constructor TFileListener.Create(AOwner: TConsoleListener; const pFileName: string;
  pLevel: TLogLevel = vlDebug);
begin
  inherited Create;
  FOwner := AOwner;
  FFileName := pFileName;
  Level := pLevel;
  OpenFile;
end;

destructor TFileListener.Destroy;
begin
  if FIsFileOpened then
    CloseFile(FFileHandle);
  inherited;
end;

procedure TFileListener.LogMessage(const Prefix, Msg :string; Level: TLogLevel);
begin
  if not IsFileOpened then
    Exit;
  LogPrefix(Prefix, Level);
  WriteLn(FFileHandle, Msg);
  Flush(FFileHandle);
end;

procedure TFileListener.LogPrefix(const Prefix: string; Level: TLogLevel);
begin
  if not IsFileOpened then
    Exit;
  Write(FFileHandle, Prefix);
end;

procedure TFileListener.OpenFile;
begin
  FIsFileOpened := False;
  if FileName = '' then
  begin
    FileName := 'want.debug.log';
    if Assigned(FOwner) then
      FOwner.Log(vlDebug,
        Format('Log file name not defined, using default name "%s"',
          [FileName]));
  end;
  Assign(FFileHandle, FFileName);
  {$I-}
  Rewrite(FFileHandle);
  {$I+}
  FIsFileOpened := IOResult = 0;
  if not FIsFileOpened then
    if Assigned(FOwner) then
      FOwner.Log(vlWarnings,
        Format('Log file "%s" cannot be opened for writing.', [FileName]));
end;

end.
