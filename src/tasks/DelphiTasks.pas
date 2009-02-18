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
    @author Ignacio J. Ortega
    @author Gerrit Jan Doornink
    @author Tobias Grimm <tobias.grimm@e-tobi.net>
}
{ TODO -oGJD -cTODO :
  Add handling of:
  -J: Generate an object file
  -JP: Generate C++ object file
  -K: Set image base address
  -TX: Target file extension
  -V: Turbo Debugger debug information
  -VN: Generate namespace debugging information in Giant format (used by C++Builder) }

unit DelphiTasks;

interface
uses
  {Delphi}
  Windows,
  SysUtils,
  Classes,
  TypInfo,
  Contnrs,
  Registry,

  {Jcl}
  JclBase,
  JclSysUtils,
  JclMiscel,
  JclSysInfo,
  JclRegistry,
  JclStrings,

  {Local}
  JalStrings,

  OTRPerlRE,

  WantUtils,
  WantClasses,
  ExecTasks,
  WildPaths,
  PatternSets,
  Attributes;




const
  DelphiRegRoot   = 'SOFTWARE\Borland\Delphi';
  CBuilderRegRoot = 'SOFTWARE\Borland\C++Builder';
  BDSRegRoot      = 'SOFTWARE\Borland\BDS';
  DelphiRootKey   = 'RootDir';
  
  __RENAMED_CFG_EXT = '.want.cfg';

type
  EDelphiTaskError       = class(ETaskError);
  EDelphiNotFoundError   = class(EDelphiTaskError);
  ECompilerNotFoundError = class(EDelphiTaskError);

  TMapType = (none, segments, publics, detailed);

  TDelphiVersion = record
    Version    :string;
    Directory  :string;
    ToolPath   :string;
  end;

  TPathSet = class(TCustomDirSet)
  protected
    procedure SetPath(Value: string); virtual;
  public
    constructor Create(Owner :TScriptElement); override;
  published
    property Path: string write SetPath;
  end;

  TUnitPathElement     = class(TPathSet);
  TResourcePathElement = class(TPathSet);
  TIncludePathElement  = class(TPathSet);
  TObjectPathElement   = class(TPathSet);

  TCustomDelphiTask = class(TCustomExecTask)
  protected
    FVersions : string;

    FVersionFound :string;
    FDelphiDir    :string;
    FToolPath     :string;
    FVersionNumber:double;
    procedure HandleOutputLine(Line :string); override;

    class function RootForVersion(version: string; UseCBuilder: boolean = false): string;
    class function ReadDelphiDir(ver :string = ''; UseCBuilder: boolean = false) :string;
    class function ReadUserOption(Key, Name, Ver :string):string;
    class function ReadMachineOption(Key, Name, Ver :string):string;

    class function FindDelphi(V: string): TDelphiVersion;
    class function ToolName :string; virtual;  abstract;

    procedure FindTool;
  public
    function BuildExecutable: string; override;
    procedure Execute;  override;

    property DelphiDir :string read FDelphiDir;
    property ToolPath  :string read FToolPath;
  published
    property versions: string read FVersions  write FVersions;
    property failonerror;
  end;

type
  TWarning = (
    UNSAFE_CODE,
    UNSAFE_TYPE,
    UNSAFE_CAST,
    SYMBOL_PLATFORM,
    SYMBOL_LIBRARY,
    SYMBOL_DEPRECATED,
    UNIT_PLATFORM,
    UNIT_LIBRARY,
    UNIT_DEPRECATED
  );
  TWarnings = set of TWarning;

  TEnvironmentVar = class
  private
    FName: string;
    FPath: string;
  protected
    property Name: string read FName write FName;
    property Path: string read FPath write FPath;
  public
    constructor Create(const AName, APath: string);
  end;

  TEnvironmentVarList = class(TObjectList)
  private
    FRegistryPath: string;
    procedure ReadVars;
    function GetVars(Index: Integer): TEnvironmentVar;
    procedure MutualReplace;

    property RegistryPath: string read FRegistryPath;
  protected
    function Add(const AName, APath: string): Integer;
    function Replace(const pString: string): string;
  public
    constructor Create(const pRegistryPath: string);
    property Vars[Index: Integer]: TEnvironmentVar read GetVars;
  end;

  TDelphiEnvironmentVarList = class(TEnvironmentVarList)
  public
    constructor Create(const pRegistryPath, pDelphiPath: string);
  end;

  TDelphiCompileTask = class(TCustomDelphiTask)
  protected
    FExesPath: TPath;
    FDCUPath : TPath;
    FBPLPath : TPath;
    FDCPPath : TPath;
    FSource  : TPath;

    FQuiet          : boolean;
    FMake           : boolean;
    FBuild          : boolean;
    FOptimize       : boolean;
    FOptimization   : boolean;
    FDebug          : boolean;
    FDebugInfo      : boolean;
    FAllDebugInfo   : boolean;
    FLocalSymbols   : boolean;
    FDefinitionInfo : boolean;
    FReferenceInfo  : boolean;
    FConsole        : boolean;
    FEnableWarnings : boolean;
    FEnableHints    : boolean;
    FUseLibraryPath : boolean;
    FUseCFG         : boolean;
    FHugeStrings    : boolean;
    FOpenStrings    : boolean;
    FVarStringChecks: boolean;
    FIoChecks       : boolean;
    FOverFlowChecks : boolean;
    FRangeChecks    : boolean;
    FAssertions     : boolean;
    FAllChecks      : boolean;
    FBoolEval       : boolean;
    FTypedAddress   : boolean;
    FStackFrames    : boolean;
    FWriteableConst : boolean;
    FMap            : TMapType;
    FMinEnumSize    : integer;
    FUseDebugDCUs   : boolean;
    FSafeDivide     : boolean;
    FExtendedSyntax : boolean;
    FImportedData   : boolean;
    FTypeInfo       : boolean;
    FAlign          : boolean;
    FAlignSize      : integer;

    FUnitPaths      : TUnitPathElement;
    FResourcePaths  : TResourcePathElement;
    FIncludePaths   : TIncludePathElement;
    FObjectPaths    : TObjectPathElement;

    FDefines        : TStrings;
    FPackages       : TStrings;
    FUnitAliases    : TStrings;
    FWarnings       : TWarnings;

    FRenamedCFGs    : boolean;

    function BuildArguments: string; override;

    class function ToolName :string; override;

    function ReadLibraryPaths :string;

    function OutputPathElements(const optionDescription,
          optionFlag : string;pathsToOutput : TPaths) : string;

    function PathOpt(Opt :string; Path :TPath) :string;
  public
    constructor Create(Owner: TScriptElement); override;
    destructor  Destroy; override;

    class function TagName: string; override;

    procedure Init; override;
    procedure Execute; override;

    procedure AddUnitPath(Path: TPath);
    procedure AddResourcePath(Path: TPath);
    procedure AddIncludePath(Path: TPath);
    procedure AddObjectPath(Path: TPath);
    procedure AddDefine(Name, Value :string);
    procedure AddPackage(Name :string);
    procedure AddWarning(Name :TWarning; Value :boolean);
    procedure AddUnitAlias(OldUnit, NewUnit: string);

    procedure RestoreCFGs;

  published
    property basedir; // from TTask

    function CreateUnitPath     :TUnitPathElement;

    function CreateResourcePath :TResourcePathElement;
    function CreateIncludePath  :TIncludePathElement;
    function CreateObjectPath   :TObjectPathElement;

    // these properties are mapped to XML attributes
    property Arguments;
    property ArgumentList stored false;
    property SkipLines;

    property exeoutput :TPath read FExesPath write FExesPath;
    property dcuoutput :TPath read FDCUPath  write FDCUPath;
    property bploutput :TPath read FBPLPath  write FBPLPath;
    property dcpoutput :TPath read FDCPPath  write FDCPPath;

    property quiet :boolean read FQuiet write FQuiet default true;
    property make  :boolean read FMake  write FMake  default false;
    property build :boolean read FBuild write FBuild default true;

    property assertions     :boolean read FAssertions     write FAssertions     default true;
    property booleval       :boolean read FBoolEval       write FBoolEval       default false;
    property optimize       :boolean read FOptimize       write FOptimize       default false;
    property optimization   :boolean read FOptimization   write FOptimization   default true;
    property iochecks       :boolean read FIoChecks       write FIoChecks       default true;
    property overflowchecks :boolean read FOverFlowChecks write FOverFlowChecks default false;
    property rangechecks    :boolean read FRangeChecks    write FRangeChecks    default false;
    property allchecks      :boolean read FAllChecks      write FAllChecks      default false;
    property debug          :boolean read FDebug          write FDebug          default true;
    property debuginfo      :boolean read FDebugInfo      write FDebugInfo      default true;
    property alldebuginfo   :boolean read FAllDebugInfo   write FAllDebugInfo   default true;
    property localsymbols   :boolean read FLocalSymbols   write FLocalSymbols   default true;
    property definitioninfo :boolean read FDefinitionInfo write FDefinitionInfo default true;
    property referenceinfo  :boolean read FReferenceInfo  write FReferenceInfo  default false;
    property console        :boolean read FConsole        write FConsole        default false;
    property warnings       :boolean read FEnableWarnings write FEnableWarnings default true;
    property hints          :boolean read FEnableHints    write FEnableHints    default true;
    property usecfg         :boolean read FUseCFG         write FUseCFG         default false;
    property hugestrings    :boolean read FHugeStrings    write FHugeStrings    default true;
    property openstrings    :boolean read FOpenStrings    write FOpenStrings    default true;
    property varstringchecks:boolean read FVarStringChecks write FVarStringChecks default true;
    property typedaddress   :boolean read FTypedAddress   write FTypedAddress   default false;
    property stackframes    :boolean read FStackFrames    write FStackFrames    default false;
    property writeableconst :boolean read FWriteableConst write FWriteableConst default false;
    property usedebugdcu    :boolean read FUseDebugDCUs   write FUseDebugDCUs   default false;
    property minenumsize    :integer read FMinEnumSize    write FMinEnumSize    default 1;
    property safedivide     :boolean read FSafeDivide     write FSafeDivide     default false;
    property extendedsyntax :boolean read FExtendedSyntax write FExtendedSyntax default true;
    property importeddata   :boolean read FImportedData   write FImportedData   default true;
    property _typeinfo      :boolean read FTypeInfo       write FTypeInfo       default false;
    property align          :boolean read FAlign          write FAlign          default true;
    property alignsize      :integer read FAlignSize      write FAlignSize      default 8;

    property map            :TMapType read FMap write FMap default none;

    property uselibrarypath :boolean read FUseLibraryPath write FUseLibraryPath default false;

    property source         :TPath read FSource write FSource;
  end;

  TResourceCompileTask = class(TCustomDelphiTask)
  protected
    FFile:   string;
    FOutput: string;

    class function ToolName :string; override;

    function BuildArguments: string; override;
  public
    class function TagName: string; override;

    constructor Create(Owner: TScriptElement); override;

    procedure Init;    override;
    procedure Execute; override;
  published
    property _file:  string read FFile   write FFile;
    property output: string read FOutput write FOutput;
  end;

  TOptionElement = class(TScriptElement)
  protected
    function dcc: TDelphiCompileTask;
  end;

  TDefineElement = class(TOptionElement)
  protected
    FValue :string;
  public
    procedure Init; override;
  published
    property Name;
    property Value :string read FValue write FValue;
  end;

  TUsePackageElement = class(TOptionElement)
  protected
  public
    procedure Init; override;
  published
    property Name;
  end;

  TMapElement = class(TCustomAttributeElement)
  protected
    FValue :TMapType;
  public
  published
    property value :TMapType read FValue write FValue;
  end;

  TWarningElement = class(TOptionElement)
  protected
    FName  :TWarning;
    FValue :boolean;
  public
    procedure Init; override;
  published
    property Name  :TWarning read FName write FName;
    property Value :boolean read FValue write FValue;
  end;

  TUnitAliasElement = class(TOptionElement)
  protected
    FOldUnit :string;
    FNewUnit :string;
  public
    procedure Init; override;
  published
    property OldUnit :string read FOldUnit write FOldUnit;
    property NewUnit :string read FNewUnit write FNewUnit;
  end;


implementation
var
  WarningVersion : Array[TWarning] of double=(7.0,7.0,7.0,6.0,6.0,6.0,6.0,6.0,6.0);

{ TCustomDelphiTask }

class function TCustomDelphiTask.FindDelphi(V: string) : TDelphiVersion;
var
  vers: TStringArray;
  i     :Integer;
  Path  :string;
  Tool  :string;
  UseCBuilder : boolean;
begin
  FillChar(Result, SizeOf(Result), #0);
  vers := nil;
  if V = '' then
  begin
    WantUtils.GetEnvironmentVar('delphi_version', V, true);
  end;
  if V = '' then begin
     V := '10,9,8,7,6,5,4';
  end;
  vers := StringToArray(V);
  for i := 0 to High(vers) do
  begin
    if StrRight(vers[i], 2) <> '.0' then
    begin
      vers[i] := vers[i] + '.0';
    end;
    UseCBuilder := false;
    if ( StrLower(StrLeft(vers[i], 1)) = 'c') then
    begin
      vers[i] := StrRestOf(vers[i], 2);
      UseCBuilder := true;
    end;
    Path := ReadDelphiDir(vers[i], UseCBuilder);
    if Path <> '' then
    begin
      Tool := Path + '\' + ToolName;
      if FileExists(Tool) then // found it !
      begin
        Result.Version   := vers[i];
        Result.Directory := Path;
        Result.ToolPath  := Tool;
        Break;
      end;
    end;
  end;
end;



procedure TCustomDelphiTask.FindTool;
begin
  with FindDelphi(versions) do
  begin
    FVersionFound := Version;
    FDelphiDir    := Directory;
    FToolPath     := ToolPath;
    DecimalSeparator := '.';
    FVersionNumber := StrToFloat(Version);
    GetFormatSettings();
  end;
  if FToolPath = '' then
    TaskError('Could not find ' + ToolName);
end;


class function TCustomDelphiTask.ReadDelphiDir(ver: string; UseCBuilder: boolean): string;
begin
  assert(ver <> '');
  Result := RegReadStringDef(HKEY_LOCAL_MACHINE, RootForVersion(ver, UseCBuilder), DelphiRootKey, '');
end;

class function TCustomDelphiTask.ReadMachineOption(Key, Name, Ver: string): string;
begin
  Result := RegReadStringDef(HKEY_LOCAL_MACHINE, RootForVersion(Ver)+'\'+Key, Name, '');
end;

class function TCustomDelphiTask.ReadUserOption(Key, Name, Ver: string): string;
begin
  Result := RegReadStringDef(HKEY_CURRENT_USER, RootForVersion(Ver)+'\'+Key, Name, '');
end;

class function TCustomDelphiTask.RootForVersion(version: string; UseCBuilder: boolean): string;
var
  RegRoot : string;
begin
  if Pos('.', version) = 0 then begin
    version := version + '.0';
  end;
  if ( UseCBuilder ) then begin
    RegRoot := CBuilderRegRoot;
  end
  else begin
    if StrToIntDef(StrLeft(version, pos('.', version) -1), 0) > 8 then
    begin
      RegRoot := BDSRegRoot;
      version := '3.0'; // will this change for Delphi 10 or even before?
    end else
      RegRoot := DelphiRegRoot;
  end;
  Result := Format('%s\%s', [RegRoot, version]);
end;

procedure TCustomDelphiTask.HandleOutputLine(Line: string);
begin
 //if not OTRPerlRE.regex.Match('^(.*\([0-9]+\)) *([A-Z][a-z]+:.*$)', Msg) then
 if (Pos(':', Line) <> 0)
 and OTRPerlRE.regex.ExMatch('^(.*)(\([0-9]+\)) *([HWEF][a-z]+:.*)$', Line) then
 begin
   with regex do
     Line := ToRelativePath(ToPath(SubExp[1])) + ' ' + SubExp[2] + #10 + SubExp[3];
   if (Pos('Fatal:', Line) <> 0) or  (Pos('Error:', Line) <> 0) then
     TaskFailure(Line)
   else
     Log(vlWarnings, Line);

    (*!!!
   with regex do
   begin
     inherited Log(Level, ToRelativePath(ToPath(SubExp[1])) + ' ' + SubExp[2]);
     inherited Log(Level, regex.SubExp[3]);
   end;
   *)
 end
 else if (Pos('Fatal:', Line) <> 0) or  (Pos('Error:', Line) <> 0) then
   TaskFailure(Line)
 else if (Pos('Warning', Line) <> 0) then
     Log(vlWarnings, Line)
 else
   inherited HandleOutputLine(Line);
end;

procedure TCustomDelphiTask.Execute;
begin
  FindTool;
  Executable := ToWantPath(ToolPath);
  inherited;
end;

function TCustomDelphiTask.BuildExecutable: string;
begin
  FindTool;

  Executable := ToWantPath(ToolPath);

  Result := inherited BuildExecutable;
end;

{ TDelphiCompileTask }

constructor TDelphiCompileTask.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  SkipLines  := 2;
  inherited quiet := true;

  FUnitPaths      := TUnitPathElement.Create(Self);
  FResourcePaths  := TResourcePathElement.Create(Self);
  FIncludePaths   := TIncludePathElement.Create(Self);
  FObjectPaths    := TObjectPathElement.Create(Self);

  FDefines        := TStringList.Create;
  FPackages       := TStringList.Create;
  FUnitAliases    := TStringList.Create;

  FQuiet := true;
  FMake := false;
  FBuild := true;

  FAssertions := true;
  FBoolEval := false;
  FOptimize := false;
  FOptimization := true;
  FIoChecks := true;
  FOverFlowChecks := false;
  FRangeChecks := false;
  FDebug := true;
  FDebugInfo := true;
  FLocalSymbols := true;
  FDefinitionInfo := true;
  FReferenceInfo := false;
  FConsole := false;
  FEnableWarnings := true;
  FEnableHints := true;
  FUseCFG := false;
  FHugeStrings := true;
  FOpenStrings := true;
  FVarStringChecks := true;
  FTypedAddress := false;
  FStackFrames := false;
  FWriteableConst := false;
  FUseDebugDCUs := false;
  FMinEnumSize := 1;
  FSafeDivide := false;
  FExtendedSyntax := true;
  FImportedData := true;
  FTypeInfo := false;
  FAlign := true;
  FAlignSize := 8;
  FAllChecks := false;
  FAllDebugInfo := true;

  FMap := none;

  FUseLibraryPath := false;

  AddWarning(UNSAFE_CODE,       false);
  AddWarning(UNSAFE_TYPE,       false);
  AddWarning(UNSAFE_CAST,       false);
  AddWarning(SYMBOL_PLATFORM,   true);
  AddWarning(SYMBOL_LIBRARY,    true);
  AddWarning(SYMBOL_DEPRECATED, true);
  AddWarning(UNIT_PLATFORM,     true);
  AddWarning(UNIT_LIBRARY,      true);
  AddWarning(UNIT_DEPRECATED,   true);
end;

destructor TDelphiCompileTask.Destroy;
begin
  FreeAndNil(FDefines);
  FreeAndNil(FPackages);
  FreeAndNil(FUnitAliases);
  inherited Destroy;
end;

procedure TDelphiCompileTask.Init;
begin
  inherited Init;
  RequireAttribute('source');
end;

class function TDelphiCompileTask.ToolName: string;
begin
  Result := 'bin\dcc32.exe';
end;

procedure TDelphiCompileTask.Execute;
begin
  Log(ToRelativePath(Source));
  try
    inherited Execute;
  finally
    RestoreCFGs;
  end;
end;

class function TDelphiCompileTask.TagName: string;
begin
  Result := 'dcc';
end;

function TDelphiCompileTask.OutputPathElements(const optionDescription,
      optionFlag : string; pathsToOutput : TPaths) : string;
var
  path : integer;
begin
  result := '';
  for path := Low(pathsToOutput) to High(pathsToOutput) do
  begin
    Log(vlVerbose, '%s %s', [optionDescription, ToRelativePath(pathsToOutput[path])]);
    Result := Result + PathOpt(optionFlag, pathsToOutput[path]);
  end;
end;

function TDelphiCompileTask.PathOpt(Opt :string; Path :TPath) :string;
begin
  Result := Format(' -%s%s', [Opt, ToSystemPath(ToPath(Path))] );
end;

function TDelphiCompileTask.BuildArguments: string;
var
  Sources: TPaths;
  d      : Integer;
  a      : Integer;
  s      : Integer;
  p      : Integer;
  w      : TWarning;
  PS     : TStringArray;
  cfg    : TPath;
  wname   :string;
  libPath :string;
  path    :string;
  EnvironmentVars: TDelphiEnvironmentVarList;
begin
  Log(vlVerbose, 'sources %s', [ToRelativePath(source)]);
  Sources := WildPaths.Wild(Source, BasePath);
  if Length(Sources) = 0 then
    TaskFailure(Format('Could not find %s to compile', [ToSystemPath(PathConcat(BasePath, source))]));

  libPath := DelphiDir + '\Lib';

  for s := Low(Sources) to High(Sources) do
  begin
    Log(vlVerbose, 'source %s', [ToRelativePath(Sources[s])]);
    Result := Result + ' ' + ToSystemPath(Sources[s]);
  end;

  if not usecfg then
  begin
    try
      for s := Low(Sources) to High(Sources) do
      begin
        if (LowerCase(StrRight(Sources[s], 4)) = '.dpr') or
           (LowerCase(StrRight(Sources[s], 4)) = '.dpk') then
        begin
          cfg := Sources[s];
          cfg := StrLeft(cfg, Length(cfg) - 4);
          if PathIsFile(cfg + '.cfg') then
          begin
            Log(vlVerbose, 'Renaming configuration file for %s', [ Sources[s] ]);
            WildPaths.MoveFile(cfg + '.cfg', cfg + __RENAMED_CFG_EXT);
            if WildPaths.PathExists(cfg + '.cfg') then
            begin
              Log( vlWarnings,
                   'Should not use configuration files but could not rename "%s"',
                   [cfg + '.cfg']
                   );
            end;
          end;
        end;
      end;
    except
      Log(vlWarnings, 'Could not rename configuration file: %s', [cfg]);
    end;
  end
  else
    Log(vlVerbose, 'usecfg=true');

  if exeoutput <> '' then
  begin
    Log(vlVerbose, 'exeoutput=' + ToRelativePath(exeoutput));
    Result := Result + PathOpt('E', exeoutput);
  end;

  if dcuoutput <> '' then
  begin
    Log(vlVerbose, 'dcuoutput=' + ToRelativePath(dcuoutput));
    Result := Result + PathOpt('N', dcuoutput);
  end;

  if bploutput <> '' then
  begin
    Log(vlVerbose, 'bploutput=' + ToRelativePath(bploutput));
    Result := Result + PathOpt('LE', bploutput);
  end;

  if dcpoutput <> '' then
  begin
    Log(vlVerbose, 'dcpoutput=' + ToRelativePath(dcpoutput));
    Result := Result + PathOpt('LN', dcpoutput);
  end;

  { Meta options }

  if HasAttribute('debug') then
  begin
    if debug then
    begin
      Log(vlVerbose, 'debug=true');
      Result := Result + ' -$D+ -$L+ -$YD -$C+ -$Q+ -$R+ -$O- -GD';
    end;
  end;

  if HasAttribute('optimize') then
  begin
    if optimize then
    begin
      Log(vlVerbose, 'optimize=true');
      Result := Result + ' -$C- -$Q- -$R- -$O+';
    end
  end;

  if HasAttribute('alldebuginfo') then
  begin
    if alldebuginfo then
    begin
      Log(vlVerbose, 'alldebuginfo=true');
      Result := Result + ' -$D+ -$L+ -$YD';
    end
    else
    begin
      Log(vlVerbose, 'alldebuginfo=false');
      Result := Result + ' -$D- -$L- -$Y-';
    end;
  end;

  if HasAttribute('allchecks') then
  begin
    if allchecks then
    begin
      Log(vlVerbose, 'allchecks=true');
      Result := Result + ' -$C+ -$Q+ -$R+';
    end
    else
    begin
      Log(vlVerbose, 'allchecks=false');
      Result := Result + ' -$C- -$Q- -$R-';
    end;
  end;

  { Basic options }

  if HasAttribute('console') then
  begin
    if console then
    begin
      Log(vlVerbose, 'console=true');
      Result := Result + ' -CC';
    end
    else
      Result := Result + ' -CG';
  end;

  if HasAttribute('warnings') then
  begin
    if warnings then
      Result := Result + ' -W+'
    else
    begin
      Log(vlVerbose, 'warnings=false');
      Result := Result + ' -W-';
    end;
  end;

  if HasAttribute('hints') then
  begin
    if hints then
      Result := Result + ' -H+'
    else
    begin
      Log(vlVerbose, 'hints=false');
      Result := Result + ' -H-';
    end;
  end;

  if HasAttribute('debuginfo') then
  begin
    if debuginfo then
      Result := Result + ' -$D+'
    else
    begin
      Log(vlVerbose, 'debuginfo=false');
      Result := Result + ' -$D-';
    end;
  end;

  if HasAttribute('localsymbols') then
  begin
    if localsymbols then
      Result := Result + ' -$L+'
    else
    begin
      Log(vlVerbose, 'localsymbols=false');
      Result := Result + ' -$L-';
    end;
  end;

  if HasAttribute('referenceinfo') or HasAttribute('definitioninfo') then
  begin
    if referenceinfo then
      Result := Result + ' -$Y+'
    else if definitioninfo then
      Result := Result + ' -$YD'
    else
      Result := Result + ' -$Y-';
  end;

  if HasAttribute('optimization') then
  begin
    if optimization then
      Result := Result + ' -$O+'
    else
    begin
      Log(vlVerbose, 'optimization=false');
      Result := Result + ' -$O-';
    end;
  end;

  if HasAttribute('overflowchecks') then
  begin
    if overflowchecks then
    begin
      Log(vlVerbose, 'overflowchecks=true');
      Result := Result + ' -$Q+';
    end
    else
      Result := Result + ' -$Q-';
  end;

  if HasAttribute('rangechecks') then
  begin
    if rangechecks then
    begin
      Log(vlVerbose, 'rangechecks=true');
      Result := Result + ' -$R+';
    end
    else
      Result := Result + ' -$R-';
  end;

  if HasAttribute('assertions') then
  begin
    if assertions then
      Result := Result + ' -$C+'
    else
    begin
      Log(vlVerbose, 'assertions=false');
      Result := Result + ' -$C-';
    end;
  end;

  if HasAttribute('iochecks') then
  begin
    if iochecks then
      Result := Result + ' -$I+'
    else
    begin
      Log(vlVerbose, 'iochecks=false');
      Result := Result + ' -$I-';
    end;
  end;

  if HasAttribute('hugestrings') then
  begin
    if hugestrings then
      Result := Result + ' -$H+'
    else
    begin
      Log(vlVerbose, 'hugestrings=false');
      Result := Result + ' -$H-';
    end;
  end;

  if HasAttribute('openstrings') then
  begin
    if openstrings then
      Result := Result + ' -$P+'
    else
    begin
      Log(vlVerbose, 'openstrings=false');
      Result := Result + ' -$P-';
    end;
  end;

  if HasAttribute('varstringchecks') then
  begin
    if varstringchecks then
      Result := Result + ' -$V+'
    else
    begin
      Log(vlVerbose, 'varstringchecks=false');
      Result := Result + ' -$V-';
    end;
  end;

  if HasAttribute('booleval') then
  begin
    if booleval then
    begin
      Log(vlVerbose, 'booleval=true');
      Result := Result + ' -$B+';
    end
    else
      Result := Result + ' -$B-';
  end;

  if HasAttribute('typedaddress') then
  begin
    if typedaddress then
    begin
      Log(vlVerbose, 'typedaddress=true');
      Result := Result + ' -$T+';
    end
    else
      Result := Result + ' -$T-';
  end;

  if HasAttribute('stackframes') then
  begin
    if stackframes then
    begin
      Log(vlVerbose, 'stackframes=true');
      Result := Result + ' -$W+';
    end
    else
      Result := Result + ' -$W-';
  end;

  if HasAttribute('writeableconst') then
  begin
    if writeableconst then
    begin
      Log(vlVerbose, 'writeableconst=true');
      Result := Result + ' -$J+';
    end
    else
      Result := Result + ' -$J-';
  end;

  if HasAttribute('safedivide') then
  begin
    if safedivide then
    begin
      Log(vlVerbose, 'safedivide=true');
      Result := Result + ' -$U+';
    end
    else
      Result := Result + ' -$U-';
  end;

  if HasAttribute('extendedsyntax') then
  begin
    if extendedsyntax then
      Result := Result + ' -$X+'
    else
    begin
      Log(vlVerbose, 'extendedsyntax=false');
      Result := Result + ' -$X-';
    end;
  end;

  if HasAttribute('importeddata') then
  begin
    if importeddata then
      Result := Result + ' -$G+'
    else
    begin
      Log(vlVerbose, 'importeddata=false');
      Result := Result + ' -$G-';
    end;
  end;

  if HasAttribute('typeinfo') then
  begin
    if _typeinfo then
    begin
      Log(vlVerbose, 'typeinfo=true');
      Result := Result + ' -$M+';
    end
    else
      Result := Result + ' -$M-';
  end;

  if HasAttribute('alignsize') then
  begin
    if alignsize in [1,2,4,8] then
    begin
      if alignsize <> 8 then
        Log(vlVerbose, 'alignsize=' + IntToStr(alignsize));
      Result := Result + ' -$A' + IntToStr(alignsize);
    end
    else
      Log(vlErrors, 'Invalid align size value (not one of [1,2,4,8]): '
                    + IntToStr(alignsize));
  end
  else if HasAttribute('align') then
  begin
    if align then
      Result := Result + ' -$A+'
    else
    begin
      Log(vlVerbose, 'align=false');
      Result := Result + ' -$A-';
    end;
  end;

  if HasAttribute('minenumsize') then
  begin
    if minenumsize in [1,2,4] then
      Result := Result + ' -$Z' + IntToStr(minenumsize)
    else
      Log(vlErrors, 'Invalid enum size value (not one of [1,2,4]): '
                    + IntToStr(minenumsize));
  end;

  if (not usecfg) or HasAttribute('quiet') then
  begin
    if quiet then
      Result := Result + ' -Q'
    else
      Log(vlVerbose, 'verbose=true');
  end;

  if (not usecfg) or HasAttribute('build') or HasAttribute('make') then
  begin
    if build then
    begin
      Log(vlVerbose, 'build=true');
      Result := Result + ' -B';
    end
    else if make then
    begin
      Log(vlVerbose, 'make=true');
      Result := Result + ' -M';
    end;
  end;

  case map of
    segments : Result := Result + ' -GS';
    publics  : Result := Result + ' -GP';
    detailed : Result := Result + ' -GD';
  end;

  for d := 0 to FDefines.Count - 1 do
  begin
    Log(vlVerbose, 'define %s', [FDefines.Names[d]]);
    Result := Result + ' -D' + FDefines.Names[d];
  end;

  if FUnitAliases.Count <> 0 then
  begin
    Result := Result + ' -A';
    for a := 0 to FUnitAliases.Count - 1 do
    begin
      Log(vlVerbose, 'unit alias %s', [FUnitAliases[a]]);
      Result := Result + FUnitAliases[a] + ';';
    end;
    SetLength(Result, Length(Result) - 1);
  end;

  if HasAttribute('warnings') then
  begin
    if warnings then
    begin
      for w := Low(TWarning) to High(TWarning) do
      begin
        if  FVersionNumber >= WarningVersion[w] then
        begin
          wname := GetEnumName(TypeInfo(TWarning), Ord(w));
          if w in FWarnings then
            Result := Result + ' -W+' + wname
          else
            Result := Result + ' -W-' + wname;
        end;
      end;
    end;
  end;

  Result := Result + ' ' + inherited BuildArguments;

  for p := 0 to FPackages.Count - 1 do
  begin
    Log(vlVerbose, 'package %s', [FPackages[p]]);
    Result := Result + ' -LU' + FPackages[p];
  end;

  PS := nil;
  if (not usecfg) or HasAttribute('uselibrarypath') then
  begin
    if useLibraryPath then
    begin
      Log(vlVerbose, 'uselibrarypath=true');
      PS := StringToArray(ReadLibraryPaths, ';');
      try
        EnvironmentVars := TDelphiEnvironmentVarList.Create(
          RootForVersion(FVersionFound)
          + '\Environment Variables',
          DelphiDir);
        try
          for p := High(PS) downto Low(PS) do
          begin
            PS[p] := Trim(PS[p]);
            if PS[p] <> '' then
            begin
              PS[p] := EnvironmentVars.Replace(PS[p]);
              FUnitPaths.Includes.Insert(0, PS[p]);
              FResourcePaths.Includes.Insert(0, PS[p]);
              FIncludePaths.Includes.Insert(0, PS[p]);
            end;
          end;
        finally
          FreeAndNil(EnvironmentVars);
        end;
      finally
        PS := nil;
      end;
    end;
  end;

  if (not usecfg) or HasAttribute('usedebugdcu') then
  begin
    if usedebugdcu then
    begin
      path := libPath;
      if PathExists(path + '\Debug') then
         path := path + '\Debug';
      FUnitPaths.Includes.Insert(0, path);
      FResourcePaths.Includes.Insert(0, path);
      FResourcePaths.Includes.Insert(0, libPath);
      FIncludePaths.Includes.Insert(0, path);
    end
    else if not useLibraryPath then
    begin
      FUnitPaths.Includes.Insert(0, libPath);
      FResourcePaths.Includes.Insert(0, libPath);
      FIncludePaths.Includes.Insert(0, libPath);
    end;
  end;

  if (FUnitPaths.Includes.Count <> 0) or (Length(FUnitPaths.FPatternSets) <> 0) then
    Result := Result + OutputPathElements('unitpath', 'U', FUnitPaths.Paths);

  if (FResourcePaths.Includes.Count <> 0) or (Length(FResourcePaths.FPatternSets) <> 0) then
    Result := Result + OutputPathElements('resourcepath', 'R', FResourcePaths.Paths);

  if (FIncludePaths.Includes.Count <> 0) or (Length(FIncludePaths.FPatternSets) <> 0) then
    Result := Result + OutputPathElements('includepath', 'I', FIncludePaths.Paths);

  if (FObjectPaths.Includes.Count <> 0) or (Length(FObjectPaths.FPatternSets) <> 0) then
    Result := Result + OutputPathElements('objectpath', 'O', FObjectPaths.Paths);
end;

procedure TDelphiCompileTask.AddUnitPath(Path: TPath);
begin
  FUnitPaths.Include(Path);
end;

procedure TDelphiCompileTask.AddIncludePath(Path: TPath);
begin
  FIncludePaths.Include(Path);
end;

procedure TDelphiCompileTask.AddObjectPath(Path : TPath);
begin
  FObjectPaths.Include(Path);
end;

procedure TDelphiCompileTask.AddResourcePath(Path: TPath);
begin
  FResourcePaths.Include(Path);
end;

function TDelphiCompileTask.ReadLibraryPaths: string;
begin
  Result := ReadUserOption('Library', 'Search Path', FVersionFound) + ';' +
            ReadUserOption('Library', 'SearchPath',  FVersionFound)
end;


procedure TDelphiCompileTask.AddDefine(Name, Value: string);
begin
  if Trim(Value) <> '' then
    FDefines.Values[Name] := Value
  else
    FDefines.Add(Name + '=');
end;

procedure TDelphiCompileTask.AddPackage(Name: string);
begin
  FPackages.Add(Name);
end;

function TDelphiCompileTask.CreateUnitPath: TUnitPathElement;
begin
  Result := FUnitPaths;
end;

function TDelphiCompileTask.CreateIncludePath: TIncludePathElement;
begin
  Result := FIncludePaths;
end;

function TDelphiCompileTask.CreateObjectPath: TObjectPathElement;
begin
  Result := FObjectPaths;
end;

function TDelphiCompileTask.CreateResourcePath: TResourcePathElement;
begin
  Result := FResourcePaths;
end;

procedure TDelphiCompileTask.RestoreCFGs;
var
  cfgs :TPaths;
  cfg  :TPath;
  c    :Integer;
begin
  cfgs := nil;
  if not usecfg then
  begin
    cfgs := Wild('*' + __RENAMED_CFG_EXT);
    try
      for c := Low(cfgs) to High(cfgs) do
      begin
        cfg := cfgs[c];
        Delete(cfg, 1 + Length(cfg) - Length(__RENAMED_CFG_EXT), Length(__RENAMED_CFG_EXT));
        cfg := cfg + '.cfg';
        Log(vlDebug, 'Restoring configuration file: %s', [ cfg ]);
        WildPaths.MoveFile(cfgs[c], cfg);
      end;
    except
      Log(vlWarnings, 'Could not restore configuration file: %s', [cfg]);
    end;
  end;
end;


procedure TDelphiCompileTask.AddWarning(Name: TWarning; Value :boolean);
begin
  if Value then
    Include(FWarnings, Name)
  else
    Exclude(FWarnings, Name);
end;

procedure TDelphiCompileTask.AddUnitAlias(OldUnit, NewUnit: string);
begin
  FUnitAliases.Add(OldUnit + '=' + NewUnit);
end;

{ TResourceCompileTask }

function TResourceCompileTask.BuildArguments: string;
begin
  Result := inherited BuildArguments;

  Result := Result + ' -r ' + ToSystemPath(_file);

  if output <> '' then
    Result := Result + ' -fo' + ToSystemPath(output);
end;

constructor TResourceCompileTask.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  SkipLines := 2;
end;

procedure TResourceCompileTask.Execute;
begin
  Log(ToRelativePath(_file));
  inherited;
end;

procedure TResourceCompileTask.Init;
begin
  inherited Init;
  RequireAttribute('file');
end;

class function TResourceCompileTask.TagName: string;
begin
  Result := 'brcc';
end;

class function TResourceCompileTask.ToolName: string;
begin
  Result := 'bin\brcc32.exe';
end;

{ TDefineElement }

procedure TDefineElement.Init;
begin
  inherited Init;
  if Enabled then
  begin
    Log(vlDebug, '%s %s=%s', [TagName, Name, Value]);
    RequireAttribute('name');
    dcc.AddDefine(Name, Value);
  end;
end;


{ TPathSet }

constructor TPathSet.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  Sorted := false;
  AddDefaultPatterns;
end;

procedure TPathSet.SetPath(Value: string);
var
  Pat :TPath;
begin
  Pat := StrToken(Value, ',');
  while Pat <> '' do
  begin
    Include(Pat);
    Pat := StrToken(Value, ',');
  end;
end;

{ TOptionElement }

function TOptionElement.dcc: TDelphiCompileTask;
begin
  Result := Owner as TDelphiCompileTask;
end;

{ TUsePackageElement }

procedure TUsePackageElement.Init;
begin
  inherited Init;
  if Enabled then
  begin
    Log(vlDebug, '%s %s', [TagName, Name]);
    RequireAttribute('name');
    dcc.AddPackage(Name);
  end;
end;

{ TMapElement }

{ TWarningElement }

procedure TWarningElement.Init;
begin
  inherited Init;
  if Enabled then
  begin
    RequireAttributes(['name', 'value']);
    dcc.AddWarning(Name, Value);
  end;
end;

{ TUnitAliasElement }

procedure TUnitAliasElement.Init;
begin
  inherited Init;
  if Enabled then
  begin
    Log(vlDebug, '%s %s=%s', [TagName, OldUnit, NewUnit]);
    RequireAttributes(['oldunit', 'newunit']);
    dcc.AddUnitAlias(OldUnit, NewUnit);
  end;
end;

{ TEnvironmentVar }

constructor TEnvironmentVar.Create(const AName, APath: string);
begin
  inherited Create;
  FName := AName;
  FPath := APath;
end;

{ TEnvironmentVarList }

function TEnvironmentVarList.Add(const AName, APath: string): Integer;
begin
  Result := inherited Add(TEnvironmentVar.Create(AName, APath));
end;

constructor TEnvironmentVarList.Create(const pRegistryPath: string);
begin
  inherited Create;
  FRegistryPath := pRegistryPath;
  ReadVars;
  MutualReplace;
end;

function TEnvironmentVarList.GetVars(Index: Integer): TEnvironmentVar;
begin
  Result := TEnvironmentVar(Items[Index]);
end;

procedure TEnvironmentVarList.MutualReplace;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Vars[i].Path := Replace(Vars[i].Path);
end;

procedure TEnvironmentVarList.ReadVars;
var
  r: TRegistryIniFile;
  TSL: TStringList;
  i: Integer;
  rp, section: string;
begin
  section := ExtractFileName(RegistryPath);
  rp := ExcludeTrailingPathDelimiter(ExtractFilePath(RegistryPath));
  r := TRegistryIniFile.Create(rp, KEY_READ);
  try
    TSL := TStringList.Create;
    try
      r.ReadSection(section, TSL);
      for i := 0 to TSL.Count - 1 do
        Add(TSL.Strings[i], r.ReadString(section, TSL.Strings[i], ''));
    finally
      FreeAndNil(TSL);
    end;
  finally
    FreeAndNil(r);
  end;

end;

function TEnvironmentVarList.Replace(const pString: string): string;
var
  i: Integer;
begin
  Result := pString;
  for i := 0 to Count - 1 do
    Result := StringReplace(Result, '$(' + Vars[i].Name + ')', Vars[i].Path,
      [rfReplaceAll, rfIgnoreCase]);
end;

{ TDelphiEnvironmentVarList }

constructor TDelphiEnvironmentVarList.Create(const pRegistryPath,
  pDelphiPath: string);
begin
  inherited Create(pRegistryPath);
  Add('DELPHI', pDelphiPath);
  MutualReplace;
end;

initialization
  RegisterTasks( [TDelphiCompileTask, TResourceCompileTask]);
  RegisterElements(TDelphiCompileTask, [
                         TDefineElement ,
                         TUsePackageElement,
                         TWarningElement,
                         TUnitAliasElement
                         ]);
  with TDelphiCompileTask.FindDelphi('') do
  begin
    JclSysInfo.SetEnvironmentVar('delphi.version', Version);
    JclSysInfo.SetEnvironmentVar('delphi.dir',     Directory);
  end;
end.
