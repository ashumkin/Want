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
    @brief Hash tasks

    @author Шумкин Алексей aka Zapped
}

unit HashTasks;

interface
uses
  SysUtils,
  Classes,
  Math,

  JclStrings,
  uCRC32, DCPcrypt2, DCPmd4, DCPmd5, DCPsha1, DCPsha256, DCPsha512, DCPtiger,

  WantUtils,
  WantClasses,
  WildPaths;

type
  ECRCException = class(Exception);
  THashAlgorithms = (atCRC32, atMD4, atMD5, atSHA1, atSHA256, atSHA512, atTiger);

  THashTask = class(TTask)
  private
    procedure SetAlgorithm(const Value: string);
    function GetAlgorithm: string;
  protected
    FAlgorithm: THashAlgorithms;
    FHashStr  : string;
    FHash     : Cardinal;
    FText    : string;
    FFile    : TPath;
    FLevel   : TLogLevel;
    FOverwrite: boolean;
    FProperty: string;
    FUpperCase: boolean;

  public
    constructor Create(Owner :TScriptElement); override;
    procedure Init; override;

    procedure Execute; override;

  published
    property _text    : string    read FText    write FText;
    property _file    : TPath     read FFile    write FFile;
    property _property: string    read FProperty write FProperty;
    property alg      : string read GetAlgorithm write SetAlgorithm;
    property algorithm: string read GetAlgorithm write SetAlgorithm;
    property overwrite: boolean read FOverwrite write FOverwrite;
    property uppercase: boolean read FUpperCase write FUpperCase;
  end;

implementation

uses TypInfo;

{ THashTask }

constructor THashTask.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  FAlgorithm := atCRC32;
end;

procedure THashTask.Execute;
var
  sysfile:  string;
  CRCBuffer: array[1..4096] of byte;
  i: Integer;
  DCP_CRC: TDCP_hash;
  FileStream: TFileStream;
begin
  FHash := 0;
  FHashStr := '';
  inherited Execute;
  if Trim(_file) = '' then
    TaskFailure('Filename is not set');
  Log(vlVerbose, '%s', [ToRelativePath(_file)]);
  AboutToScratchPath(_file);
  sysfile := ToSystemPath(_file);
  if not PathIsFile(sysfile) then
    TaskFailureFmt('file "%s" not found', [sysfile]);
  case FAlgorithm of
    atCRC32 :
      try
        FHash := FileCRC32(sysfile);
        FHashStr := IntToHex(FHash, 8);
      except
        on E: Exception do
          TaskFailureFmt('Error while calculating CRC. %s', [E.Message]);
      end;
  else
    try
      FileStream := TFileStream.Create(sysfile, fmOpenRead);
      try
        DCP_CRC := TDCP_hash(GetClass('TDCP_' + Alg).NewInstance);
        try
         DCP_CRC.Init;
         DCP_CRC.UpdateStream(FileStream, FileStream.Size);
         DCP_CRC.Final(CRCBuffer);
         for i := 1 to DCP_CRC.HashSize div 8 do
           FHashStr := FHashStr + IntToHex(CRCBuffer[i], 2);
       finally
         FreeAndNil(DCP_CRC);
       end;
      finally
        FreeAndNil(FileStream);
      end;
    except
      on E: EFOpenError do
        TaskFailureFmt('File "%s" can not be opened for reading. Exclusively locked?', [sysfile]);
      on E: Exception do
        raise; 
    end;
  end;
  if uppercase then
    FHashStr := AnsiUpperCase(FHashStr)
  else
    FHashStr := AnsiLowerCase(FHashStr);

  if _property <> '' then
    Owner.SetProperty(_property, FHashStr, overwrite);
end;

function THashTask.GetAlgorithm: string;
begin
  Result := StringReplace(GetEnumName(TypeInfo(THashAlgorithms), ord(FAlgorithm)),
    'at', '', [rfIgnoreCase]);
end;

procedure THashTask.Init;
begin
  inherited;
  RequireAttributes(['file', 'property']);
end;

procedure THashTask.SetAlgorithm(const Value: string);
var
  i: Integer;
begin
  i := GetEnumValue(TypeInfo(THashAlgorithms),
    'at' + StringReplace(Value, '-', '', [rfReplaceAll]));
  if i < 0 then
    raise ECRCException.CreateFmt('Algorithm %s is not implemented', [Value])
  else
    FAlgorithm := THashAlgorithms(i);
end;

initialization
  RegisterTask(THashTask);
  RegisterClasses([TDCP_md4, TDCP_md5, TDCP_sha1, TDCP_sha256, TDCP_sha512,
    TDCP_tiger]);

end.
