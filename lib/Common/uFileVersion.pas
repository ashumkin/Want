unit uFileVersion;

interface

uses
  ShellApi, Windows, SysUtils, Math
  {$IFDEF VER_REGEXP}
  , RegExpr
  {$ENDIF}
  {$IFDEF VER_NATCMP}
  , StrNatCmp
  {$ENDIF};

type
  TFileVersionInfo = record
    FileType,
    CompanyName,
    FileDescription,
    FileVersion,
    InternalName,
    LegalCopyRight,
    LegalTradeMarks,
    OriginalFileName,
    ProductName,
    ProductVersion,
    Comments,
    SpecialBuildStr,
    PrivateBuildStr,
    FileFunction : string;
    DebugBuild,
    PreRelease,
    SpecialBuild,
    PrivateBuild,
    Patched,
    InfoInferred : Boolean;
    FileVersionFixed: string;
  end;

  TVersionRec = record
    case Integer of
      0: (Build, Release, Minor, Major: Word);
      1: (HiD, LoD: LongWord);
      2: (Ver: Int64);
  end;

  // класс версии (файла)
  TCustomVersion = class
  private
    FVersionMajor: string;
    FVersionMinor: string;
    FVersionRelease: string;
    FVersionBuild: string;
    FVersion: string;
    FisBuildMandatory: boolean;
    procedure SetVersion(const Value: string);
    function GetVersionStr: string;
  public
    constructor Create(AVersion: string; isBuildMandatory: boolean = True); overload;
    constructor Create(AVersion: Int64); overload;
    class function RecToString(AVersion: TVersionRec): string;
    class function Int64ToString(AVersion: Int64): string;
    class function StringToInt64(const AVersion: string): Int64;

    property Version: string read FVersion write SetVersion;
    property VersionStr: string read GetVersionStr;
    property VersionMajor: string read FVersionMajor;
    property VersionMinor: string read FVersionMinor;
    property VersionRelease: string read FVersionRelease;
    property VersionBuild: string read FVersionBuild;
  end;

  TVersion = class(TCustomVersion);

// функци€ возвращает полный путь исполн€емого модул€
function AppFileName: string;

function ParseVersionRec(const AVersion: string): TVersionRec;
// процедура разбивает версию вида N.N.aaN(p|.)N на составл€ющие
procedure ParseVersion(const AVersion: string;
                       out AVersionMajor, AVersionMinor, AVersionRelease, AVersionBuild: string;
                       pBuildIsMandatory: boolean = False); overload;
function ParseVersion(const AVersion: string): Int64; overload;

//функци€ возвращает информацию о файле по его имени
function FileVersionInfo(const sAppNamePath: String): TFileVersionInfo;
function GetFileVersion(const sAppNamePath: String): string;
function GetModuleVersion: string;

procedure NormalizeVersion(var pVersion: string);

// сравнение двух версий
// возвращает:
// < 0 - если Version1 > Version2
// 0 - если Version1 = Version2
// > 0 - если Version1 < Version2
function CompareVersions(Version1, Version2: string; IgnoreBuild : Boolean = False): Integer; overload;
function CompareVersions(Version1, Version2: TCustomVersion; IgnoreBuild : Boolean = False): Integer; overload;
function DiffVersions(Version1, Version2: TCustomVersion): TCustomVersion; overload;
function DiffVersions(Version1, Version2: string): string; overload;

implementation

function AppFileName: string;
begin
  Result := GetModuleName(HInstance);
end;

{$IFDEF VER_REGEXP}
procedure ParseVersion(const AVersion: string;
  var AVersionMajor, AVersionMinor, AVersionRelease, AVersionBuild: string;
  pBuildIsMandatory: boolean = False);
var
  RE: TRegExpr;
  BIM: string;
begin
  RE := TRegExpr.Create;
  AVersionMajor := '';
  AVersionMinor := '';
  AVersionRelease := '';
  AVersionBuild := '';
  try
    if pBuildIsMandatory then
      BIM := ''
    else
      BIM := '?';
    RE.Expression := '^(\d+)\.(\d+)(\.([^.]+?)([\.p](\d+))' + BIM + ')?$';
    if RE.Exec(AVersion) then
    begin
      AVersionMajor := RE.Match[1];
      AVersionMinor := RE.Match[2];
      AVersionRelease := RE.Match[4];
      AVersionBuild := RE.Match[6];
      NormalizeVersion(AVersionMajor);
      NormalizeVersion(AVersionMinor);
      NormalizeVersion(AVersionRelease);
      NormalizeVersion(AVersionBuild);
    end;
  finally
    FreeAndNil(RE);
  end;
end;
{$ELSE}
procedure ParseVersion(const AVersion: string;
  out AVersionMajor, AVersionMinor, AVersionRelease, AVersionBuild: string;
  pBuildIsMandatory: boolean = False);
var
  s: string;
  function GetDigit: string;
  var
    p: Integer;
  begin
    p := Pos('.', s);
    if p = 0 then
      p := Length(s) + 1;
    Result := Copy(s, 1, p - 1);
    s := Copy(s, p + 1, Length(s));
  end;
begin
  s := AVersion;
  AVersionMajor := GetDigit;
  AVersionMinor := GetDigit;
  AVersionRelease := GetDigit;
  AVersionBuild := GetDigit;
  NormalizeVersion(AVersionMajor);
  NormalizeVersion(AVersionMinor);
  NormalizeVersion(AVersionRelease);
  NormalizeVersion(AVersionBuild);
end;
{$ENDIF}

function ParseVersionRec(const AVersion: string): TVersionRec;
var
  ma, mi, r, b: string;
begin
  ParseVersion(AVersion, ma, mi, r, b);
  with Result do
  begin
    Major := StrToIntDef(ma, 0);
    Minor := StrToIntDef(mi, 0);
    Release := StrToIntDef(r, 0);
    Build := StrToIntDef(b, 0);
  end;
end;

function ParseVersion(const AVersion: string): Int64;
begin
  Result := ParseVersionRec(AVersion).Ver;
end;

function FileVersionInfo(const sAppNamePath: String): TFileVersionInfo;
var 
  rSHFI: TSHFileInfo; 
  iRet: Integer; 
  VerSize: Integer; 
  VerBuf: PChar; 
  VerBufValue: Pointer; 
  VerHandle: Cardinal; 
  VerBufLen: Cardinal;
  VerKey: string;
  FixedFileInfo: PVSFixedFileInfo;

  // dwFileType, dwFileSubtype
  function GetFileSubType(FixedFileInfo: PVSFixedFileInfo) : string;
  begin
    case FixedFileInfo.dwFileType of

      VFT_UNKNOWN: Result := 'Unknown';
      VFT_APP: Result := 'Application'; 
      VFT_DLL: Result := 'DLL'; 
      VFT_STATIC_LIB: Result := 'Static-link Library'; 

      VFT_DRV: 
        case 
          FixedFileInfo.dwFileSubtype of 
          VFT2_UNKNOWN: Result := 'Unknown Driver'; 
          VFT2_DRV_COMM: Result := 'Communications Driver'; 
          VFT2_DRV_PRINTER: Result := 'Printer Driver'; 
          VFT2_DRV_KEYBOARD: Result := 'Keyboard Driver'; 
          VFT2_DRV_LANGUAGE: Result := 'Language Driver'; 
          VFT2_DRV_DISPLAY: Result := 'Display Driver'; 
          VFT2_DRV_MOUSE: Result := 'Mouse Driver';
          VFT2_DRV_NETWORK: Result := 'Network Driver'; 
          VFT2_DRV_SYSTEM: Result := 'System Driver'; 
          VFT2_DRV_INSTALLABLE: Result := 'InstallableDriver'; 
          VFT2_DRV_SOUND: Result := 'Sound Driver'; 
        end; 
      VFT_FONT: 
         case FixedFileInfo.dwFileSubtype of 
          VFT2_UNKNOWN: Result := 'Unknown Font'; 
          VFT2_FONT_RASTER: Result := 'Raster Font'; 
          VFT2_FONT_VECTOR: Result := 'Vector Font'; 
          VFT2_FONT_TRUETYPE: Result :='Truetype Font'; 
          else; 
        end; 
      VFT_VXD: Result :='Virtual Defice Identifier = ' +
          IntToHex(FixedFileInfo.dwFileSubtype, 8); 
    end; 
  end;


  function HasdwFileFlags(FixedFileInfo: PVSFixedFileInfo;
  Flag : Word) : Boolean;
  begin 
    Result := (FixedFileInfo.dwFileFlagsMask and 
              FixedFileInfo.dwFileFlags and 
              Flag) = Flag; 
  end; 

  function GetFixedFileInfo: PVSFixedFileInfo;
  begin 
    if not VerQueryValue(VerBuf, '', Pointer(Result), VerBufLen) then 
      Result := nil 
  end; 

  function GetFileVersionFixed(FixedFileInfo: PVSFixedFileInfo): string;
  begin
    with FixedFileInfo^ do
      Result := Format('%d.%d.%d.%d',
        [
        dwFileVersionMS shr 16,
        dwFileVersionMS and $FFFF,
        dwFileVersionLS shr 16,
        dwFileVersionLS and $FFFF
        ]);
  end;

  function GetInfo(const aKey: string): string;
  begin 
    Result := ''; 
    VerKey := Format('\StringFileInfo\%.4x%.4x\%s',
              [LoWord(Integer(VerBufValue^)), 
               HiWord(Integer(VerBufValue^)), aKey]); 
    if VerQueryValue(VerBuf, PChar(VerKey),VerBufValue,VerBufLen) then 
      Result := StrPas(VerBufValue); 
  end; 

  function QueryValue(const aValue: string): string; 
  begin 
    Result := ''; 
    // obtain version information about the specified file 
    if GetFileVersionInfo(PChar(sAppNamePath), VerHandle, VerSize, VerBuf)
      and
       // return selected version information
         VerQueryValue(VerBuf, '\VarFileInfo\Translation',
           VerBufValue, VerBufLen) then
       Result := GetInfo(aValue);
  end; 


begin 
  // Initialize the Result
  with Result do
  begin
    FileType := '';
    CompanyName := '';
    FileDescription := '';
    FileVersion := '';
    InternalName := '';
    LegalCopyRight := '';
    LegalTradeMarks := '';
    OriginalFileName := '';
    ProductName := '';
    ProductVersion := '';
    Comments := '';
    SpecialBuildStr:= '';
    PrivateBuildStr := '';
    FileFunction := '';
    DebugBuild := False;
    Patched := False;
    PreRelease:= False;
    SpecialBuild:= False;
    PrivateBuild:= False;
    InfoInferred := False;
  end;

  // Get the file type
  if SHGetFileInfo(PChar(sAppNamePath), 0, rSHFI, SizeOf(rSHFI),
    SHGFI_TYPENAME) <> 0 then
  begin
    Result.FileType := rSHFI.szTypeName;
  end;

  iRet := SHGetFileInfo(PChar(sAppNamePath), 0, rSHFI,
  SizeOf(rSHFI), SHGFI_EXETYPE);
  if iRet <> 0 then
  begin
    // determine whether the OS can obtain version information
    VerSize := GetFileVersionInfoSize(PChar(sAppNamePath), VerHandle);
    if VerSize > 0 then
    begin
      VerBuf := AllocMem(VerSize);
      try
        with Result do
        begin
          CompanyName      := QueryValue('CompanyName');
          FileDescription  := QueryValue('FileDescription');
          FileVersion      := QueryValue('FileVersion');
          InternalName     := QueryValue('InternalName');
          LegalCopyRight   := QueryValue('LegalCopyRight');
          LegalTradeMarks  := QueryValue('LegalTradeMarks');
          OriginalFileName := QueryValue('OriginalFileName');
          ProductName      := QueryValue('ProductName');
          ProductVersion   := QueryValue('ProductVersion');
          Comments         := QueryValue('Comments');
          SpecialBuildStr  := QueryValue('SpecialBuild');
          PrivateBuildStr  := QueryValue('PrivateBuild');
          // Fill the  VS_FIXEDFILEINFO structure
          FixedFileInfo    := GetFixedFileInfo;
          FileVersionFixed := GetFileVersionFixed(FixedFileInfo);
          DebugBuild       := HasdwFileFlags(FixedFileInfo,VS_FF_DEBUG);
          PreRelease       := HasdwFileFlags(FixedFileInfo,VS_FF_PRERELEASE);
          PrivateBuild     := HasdwFileFlags(FixedFileInfo,VS_FF_PRIVATEBUILD);
          SpecialBuild     := HasdwFileFlags(FixedFileInfo,VS_FF_SPECIALBUILD);
          Patched          := HasdwFileFlags(FixedFileInfo,VS_FF_PATCHED);
          InfoInferred     := HasdwFileFlags(FixedFileInfo,VS_FF_INFOINFERRED);
          FileFunction     := GetFileSubType(FixedFileInfo);
        end;
      finally
        FreeMem(VerBuf, VerSize);
      end
    end;
  end
end;

function GetFileVersion(const sAppNamePath: String): string;
begin
  Result := FileVersionInfo(sAppNamePath).FileVersionFixed;
end;

function GetModuleVersion: string;
begin
  Result := GetFileVersion(GetModuleName(HInstance));
end;

procedure NormalizeVersion(var pVersion: string);
begin
  if pVersion = '' then
    pVersion := '0';
end;

{ TCustomVersion }

constructor TCustomVersion.Create(AVersion: string; isBuildMandatory: boolean = True);
begin
  inherited Create;
  FisBuildMandatory := isBuildMandatory;
  Version := AVersion;
end;

constructor TCustomVersion.Create(AVersion: Int64);
begin
  Create(TCustomVersion.Int64ToString(AVersion));
end;

function TCustomVersion.GetVersionStr: string;
begin
  FVersion := Format('%s.%s.%s.%s', [FVersionMajor, FVersionMinor, FVersionRelease, FVersionBuild]);
  // удал€ем сдвоенные точки
  FVersion := StringReplace(FVersion, '..', '.', [rfReplaceAll]);
  // удал€ем точки в начале и конце
  {$IFDEF VER_REGEXP}
  Result := ReplaceRegExpr('^\.+|\.+$', FVersion, '');
  {$ELSE}
  while Pos('.', FVersion) = 1 do
    FVersion := Copy(FVersion, 2, Length(FVersion));
  while (LastDelimiter('.', FVersion) = Length(FVersion)) do
    FVersion := Copy(FVersion, 1, Length(FVersion) - 1);
  Result := FVersion;
  {$ENDIF}
end;

class function TCustomVersion.Int64ToString(AVersion: Int64): string;
begin
  Result := TCustomVersion.RecToString(TVersionRec(AVersion));
end;

class function TCustomVersion.RecToString(AVersion: TVersionRec): string;
begin
  with AVersion do
    Result := Format('%d.%d.%d.%d', [Major, Minor, Release, Build]);
end;

procedure TCustomVersion.SetVersion(const Value: string);
begin
  FVersion := Value;
  ParseVersion(FVersion, FVersionMajor, FVersionMinor, FVersionRelease,
    FVersionBuild, FisBuildMandatory);
end;

class function TCustomVersion.StringToInt64(const AVersion: string): Int64;
begin
  Result := ParseVersion(AVersion);
end;

{
  сравнение двух версий
  возвращает:
    < 0 - если Version1 < Version2
    0 - если Version1 = Version2
    > 0 - если Version1 > Version2
}
function CompareVersions(Version1, Version2: TCustomVersion; IgnoreBuild : Boolean = False): Integer;
begin
  Result := CompareValue(StrToIntDef(Version1.VersionMajor, -1), StrToIntDef(Version2.VersionMajor, -1));
  if Result = 0 then
  begin
    Result := CompareValue(StrToIntDef(Version1.VersionMinor, -1), StrToIntDef(Version2.VersionMinor, -1));
    if Result = 0 then
    begin
      {$IFDEF VER_NATCMP}
      Result := NatCompareText(Version1.VersionRelease, Version2.VersionRelease);
      {$ELSE}
      Result := AnsiCompareText(Version1.VersionRelease, Version2.VersionRelease);
      {$ENDIF}
      if (Result = 0) and (not IgnoreBuild) then
        Result := CompareValue(StrToIntDef(Version1.VersionBuild, -1), StrToIntDef(Version2.VersionBuild, -1));
    end;
  end;
//  Result := -Result;
end;

function CompareVersions(Version1, Version2: string; IgnoreBuild : Boolean = False): Integer;
var
  V1, V2: TCustomVersion;
begin
  V1 := TCustomVersion.Create(Version1, not IgnoreBuild);
  try
    V2 := TCustomVersion.Create(Version2, not IgnoreBuild);
    try
       Result := CompareVersions(V1, V2, IgnoreBuild);
    finally
      FreeAndNil(V2);
    end;
  finally
    FreeAndNil(V1);
  end;
end;

{
  вычисление разницы двух версий
  возвращает Version1 - Version2
}
function DiffVersions(Version1, Version2: TCustomVersion) : TCustomVersion;
begin
  Result := TCustomVersion.Create('');
  Result.FVersionMajor := IntToStr(StrToIntDef(Version1.VersionMajor, 0) - StrToIntDef(Version2.VersionMajor, 0));
  Result.FVersionMinor := IntToStr(StrToIntDef(Version1.VersionMinor, 0) - StrToIntDef(Version2.VersionMinor, 0));
  Result.FVersionRelease := IntToStr(StrToIntDef(Version1.VersionRelease, 0) - StrToIntDef(Version2.VersionRelease, 0));
  Result.FVersionBuild := IntToStr(StrToIntDef(Version1.VersionBuild, 0) - StrToIntDef(Version2.VersionBuild, 0));
end;

function DiffVersions(Version1, Version2: string): string;
var
  V1, V2, VDiff: TCustomVersion;
begin
  V1 := TCustomVersion.Create(Version1);
  try
    V2 := TCustomVersion.Create(Version2);
    try
      VDiff := DiffVersions(V1, V2);
      Result := VDiff.VersionStr;
    finally
      FreeAndNil(VDiff);
      FreeAndNil(V2);
    end;
  finally
    FreeAndNil(V1);
  end;
end;

end.
