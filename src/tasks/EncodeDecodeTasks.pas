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
    @brief EncodeTasks tasks

    @author Шумкин Алексей aka Zapped
}

unit EncodeDecodeTasks;

interface
uses
  SysUtils,
  Classes,
  Math,

  JclStrings,
  DCPbase64,

  WantUtils,
  WantClasses,
  WildPaths;

type
  EEncode = class(Exception);
  TEncodeAlgorithms = (eaBase64);

  TEncodeDecodeTask = class(TTask)
  private
    Fkey: string;
    procedure SetAlgorithm(const Value: string);
    function GetAlgorithm: string;
  protected
    FAlgorithm: TEncodeAlgorithms;
    FText    : string;
    FProcessedText: string;
    FOverwrite: boolean;
    FProperty: string;

    procedure DoEncodeDecode; virtual;
  public
    constructor Create(Owner :TScriptElement); override;
    procedure Init; override;

    procedure Execute; override;

  published
    property _text    : string    read FText    write FText;
    property _property: string    read FProperty write FProperty;
    property alg      : string read GetAlgorithm write SetAlgorithm;
    property algorithm: string read GetAlgorithm write SetAlgorithm;
    property key: string read Fkey write Fkey;
    property overwrite: boolean read FOverwrite write FOverwrite;
  end;

  TEncodeTask = class(TEncodeDecodeTask)
  protected
    procedure DoEncodeDecode; override;
  public
    class function TagName: string; override;
  end;

  TDecodeTask = class(TEncodeDecodeTask)
  protected
    procedure DoEncodeDecode; override;
  public
    class function TagName: string; override;
  end;

implementation

uses
  TypInfo;

{ TEncodeTask }

constructor TEncodeDecodeTask.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  FAlgorithm := eaBase64;
end;

procedure TEncodeDecodeTask.DoEncodeDecode;
begin
  Log(vlVerbose, 'Processing text "%s" with key "%s"', [FText, FKey]);
end;

procedure TEncodeDecodeTask.Execute;
begin
  inherited Execute;
  DoEncodeDecode;
  if _property <> '' then
    Owner.SetProperty(_property, FProcessedText, overwrite);
end;

function TEncodeDecodeTask.GetAlgorithm: string;
begin
  Result := StringReplace(
    GetEnumName(TypeInfo(TEncodeAlgorithms), ord(FAlgorithm)),
    'ea', '', [rfIgnoreCase]);
end;

procedure TEncodeDecodeTask.Init;
begin
  inherited;
  RequireAttributes(['text', 'property']);
end;

procedure TEncodeDecodeTask.SetAlgorithm(const Value: string);
var
  i: Integer;
begin
  i := GetEnumValue(TypeInfo(TEncodeAlgorithms),
    'ea' + StringReplace(Value, '-', '', [rfReplaceAll]));
  if i < 0 then
    raise EEncode.CreateFmt('Algorithm %s is not implemented', [Value])
  else
    FAlgorithm := TEncodeAlgorithms(i);
end;

{ TEncodeTask }

procedure TEncodeTask.DoEncodeDecode;
begin
  inherited;
  case FAlgorithm of
    eaBase64 : FProcessedText := Base64EncodeStr(FText);
  end;
end;

class function TEncodeTask.TagName: string;
begin
  Result := 'encode';
end;

{ TDecodeTask }

procedure TDecodeTask.DoEncodeDecode;
begin
  inherited;
  case FAlgorithm of
    eaBase64 : FProcessedText := Base64DecodeStr(FText);
  end;
end;

class function TDecodeTask.TagName: string;
begin
  Result := 'decode';
end;

initialization
  RegisterTasks([TEncodeTask, TDecodeTask]);

end.
