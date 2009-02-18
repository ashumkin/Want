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

    @author Juanco Añez
}
unit VersionInfoResources;

interface
uses
  Windows,
  SysUtils,
  Classes,
  Resources;


type

  TVersion = packed record
  case byte of
      0:  (Major, Minor, Release, Build :Byte);
      1:  (numbers : array[0..3] of Byte);
      2:  (High, Low :DWORD);
  end;

  TVS_FIXEDFILEINFO = packed record
    dwSignature: DWORD;        { e.g. $feef04bd }
    dwStrucVersion: DWORD;     { e.g. $00000042 = "0.42" }
    FileVersion    :TVersion;
    ProductVersion :TVersion;
    dwFileFlagsMask: DWORD;    { = $3F for version "0.42" }
    dwFileFlags: DWORD;        { e.g. VFF_DEBUG | VFF_PRERELEASE }
    dwFileOS: DWORD;           { e.g. VOS_DOS_WINDOWS16 }
    dwFileType: DWORD;         { e.g. VFT_DRIVER }
    dwFileSubtype: DWORD;      { e.g. VFT2_DRV_KEYBOARD }
    FileDate :TFILETIME;
    //dwFileDateMS: DWORD;       { e.g. 0 }
    //dwFileDateLS: DWORD;       { e.g. 0 }
  end;

  TVS_VERSION_INFO = packed record
    Length          :WORD;
    wValueLength    :WORD;
    wType           :WORD;
    szKey           :array[0..Length('VS_VERSION_INFO')] of WideChar;
    Padding1        :array[1..1] of Word;
    FixedInfo       : tagVS_FIXEDFILEINFO;
    // WORD  Padding2[];
    // WORD  Children[];
  end;

  TStringFileInfoHeader = packed record
      wLength        :WORD;
      wValueLength   :WORD; //o
      wType          :WORD;
      szKey          :array[1..Length('StringFileInfo')] of WideChar;
      Padding        :WORD;
      // StringTable Children[];
  end;

  TStringTableHeader = packed record
    wLength      :WORD;
    wValueLength :WORD;
    wType        :WORD; // 1 for Text
    szKey        :array[0..7] of WideChar // = 04091200 or 080904B0;
  end;

  TStringEntry = packed record
    wLength       :WORD;
    wValueLength  :WORD;
    wType         :WORD: // 1 for Text
    //szKey       :WideString;
    //Padding     :Word;
    //Value       :WideChar;
} String;


   TVersionInfoResource = class(TResource)
    _FixedInfo :TVS_FIXEDFILEINFO;
    _Infos     :array of TArrayOfByte;

    procedure FillFixedInfo;
  public
    property FileVersion    :TVersion read _FixedInfo.FileVersion    write _FixedInfo.FileVersion;
    property ProductVersion :TVersion read _FixedInfo.ProductVersion write _FixedInfo.ProductVersion;
  end;

implementation

{ TVersionInfoResource }

procedure TVersionInfoResource.FillFixedInfo;
begin
  with _FixedInfo do
  begin
    dwSignature      := $FEEF04BD;
    dwStrucVersion   := $00000042; { "0.42" }
    //FileVersion      == Self.FileVersion;
    //ProductVersion   == Self.ProductVersion;
    dwFileFlagsMask  := $3F;
    dwFileFlags      := VS_FF_DEBUG or VS_FF_PRERELEASE;
    dwFileOS         := VOS__WINDOWS32;
    dwFileType       := VFT_APP;
    dwFileSubtype    := 0;
  end;
end;

end.
