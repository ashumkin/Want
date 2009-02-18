{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{                                              }
{   \\\                                        }
{  -(j)-                                       }
{    /juanca ®                                 }
{    ~                                         }
{  Copyright © 2003 Juancarlo Añez        }
{  http://www.suigeneris.org/juanca            }
{  All rights reserved.                        }
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

{#(@)$Id: JalLogging.pas 771 2004-05-08 16:15:25Z juanco $}

unit JalLogging;

interface
uses
  Windows,
  SysUtils,
  Classes,

  JalStrings,
  JalFiles;

type
  TLogLevel =
  (
    logNONE,
    logERROR,
    logWARNING,
    logINFO,
    logDEBUG,
    logFINE
  );

const
  logDEFAULT = logNONE;
  logALL     = logFINE;

  LOG_LEVEL_NAMES : array[TLogLevel] of string =
    (
       'NONE',
       'ERROR',
       'WARNING',
       'INFO',
       'DEBUG',
       'FINE'
    );

type
  TLogEntry = record
    Seq      :LongWord;
    When     :TDateTime;
    Who      :string;
    Level    :TLogLevel;
    Msg      :string;
  end;

  ILogHandler = interface
  ['{41D86995-FDF5-4FA2-8F2A-3FA47EEEA40A}']
    procedure Log(const Entry :TLogEntry);
  end;

  ILogger = interface
  ['{987F7D94-FA12-4B05-B767-F443977868A8}']
    procedure Log(const Entry :TLogEntry); overload;
    procedure Log(Level :TLogLevel; Msg :string); overload;
    procedure Log(Level :TLogLevel; Fmt :string; const Args :array of const); overload;

    procedure Error(Msg :string); overload;
    procedure Error(Fmt :string; const Args : array of const); overload;

    procedure Warning(Msg :string);  overload;
    procedure Warning(Fmt :string; const Args : array of const); overload;

    procedure Info(Msg :string);  overload;
    procedure Info(Fmt :string; const Args : array of const); overload;

    procedure Debug(Msg :string);  overload;
    procedure Debug(Fmt :string; const Args : array of const); overload;

    function GetName :string;

    procedure SetLevel(Value :TLogLevel);
    function  GetLevel :TLogLevel;

    procedure AddHandler(Value :ILogHandler);
    procedure RemoveHandler(Value :ILogHandler);
    function GetHandlers :IInterfaceList;

    property Name :string read GetName;
    property Level :TLogLevel read GetLevel write SetLevel;
    property Handlers :IInterfaceList read GetHandlers;
  end;

  TLogger = class(TInterfacedObject, ILogger)
  protected
    FName     :string;
    FLevel    :TLogLevel;
    FParent   :ILogger;
    FHandlers :IInterfaceList;

  public
    constructor Create(Name :string; Parent :ILogger = nil);

    procedure Log(const Entry :TLogEntry); overload;
    procedure Log(Level :TLogLevel; Msg :string); overload;
    procedure Log(Level :TLogLevel; Fmt :string; const Args :array of const); overload;

    procedure Error(Msg :string); overload;
    procedure Error(Fmt :string; const Args :array of const); overload;

    procedure Warning(Msg :string); overload;
    procedure Warning(Fmt :string; const Args :array of const); overload;

    procedure Info(Msg :string); overload;
    procedure Info(Fmt :string; const Args :array of const); overload;

    procedure Debug(Msg :string);  overload;
    procedure Debug(Fmt :string; const Args : array of const); overload;

    function GetName :string;

    procedure SetLevel(Value :TLogLevel);
    function  GetLevel :TLogLevel;

    procedure AddHandler(Value :ILogHandler);
    procedure RemoveHandler(Value :ILogHandler);
    function GetHandlers :IInterfaceList;

    property Name :string read GetName;
    property Level :TLogLevel read GetLevel write SetLevel;
    property Handlers :IInterfaceList read GetHandlers;
  end;

  TAbstractLogHandler = class(TInterfacedObject, ILogHandler)
  protected
    procedure Log(const Entry :TLogEntry); virtual; abstract;
    function FormatEntry(const Entry :TLogEntry) :string;
  end;

  TNullLogHandler = class(TAbstractLogHandler)
  protected
    procedure Log(const Entry :TLogEntry); override;
  end;

  TDebugConsoleLogHandler = class(TAbstractLogHandler)
  protected
    procedure Log(const Entry :TLogEntry); override;
  end;

  TFileLogHandler = class(TAbstractLogHandler)
  protected
    FFileName :string;
    procedure Log(const Entry :TLogEntry); override;
  public
    constructor Create(FileName :string);
  end;

var
  DefaultLogHandler :ILogHandler = nil;

function GetLogger(Name :string = '') :ILogger;   overload;
function GetLogger(Clazz :TClass) :ILogger;  overload;

procedure ResetLogSequenceNumbers;
procedure ClearLoggers;

implementation

var
  __Loggers  :TStringList = nil;
  __Sequence :LongWord = 0;

procedure ResetLogSequenceNumbers;
begin
  __Sequence := 0;
end;

function GetLogger(Name :string) :ILogger;
var
  NameParts   :TStringDynArray;
  CurrentName :string;
  i           :Integer;
  Index       :Integer;
  Logger      :TLogger;
  Prev        :TLogger;
begin
  NameParts := nil;
  if __Loggers <> nil then
  begin
    Index := __Loggers.IndexOf(Name);
    if Index >= 0 then
    begin
      Result := TLogger(__Loggers.Objects[Index]);
      exit;
    end;
    Logger := TLogger(__Loggers.Objects[__Loggers.IndexOf('')]);
  end
  else
  begin
    __Loggers := TStringList.Create;
    __Loggers.Sorted := true;
    Logger := TLogger.Create('');
    Logger._AddRef;
    __Loggers.AddObject('', Logger);
  end;

  NameParts := JalStrings.StringToArray(Name, '.');
  if Length(NameParts) > 0 then
  begin
    Prev   := Logger;
    CurrentName := '';
    for i := 0 to High(NameParts) do
    begin
      if CurrentName = '' then
        Currentname := NameParts[i]
      else
        CurrentName := CurrentName + '.' + NameParts[i];
      Logger := nil;
      Index := __Loggers.IndexOf(CurrentName);
      if Index >= 0 then
        Logger := TLogger(__Loggers.Objects[Index]);
      if Logger = nil then
      begin
        Logger := TLogger.Create(CurrentName, Prev);
        Logger._AddRef;
        __Loggers.AddObject(CurrentName, Logger);
      end;
      Prev := Logger;
    end;
  end;
  Result := Logger;
end;

function GetLogger(Clazz :TClass) :ILogger;
var
  Name :string;
begin
  Name := Clazz.ClassName;
  while Clazz.ClassParent <> nil do
  begin
    Name  := Clazz.ClassParent.ClassName + '.' + Name;
    Clazz := Clazz.ClassParent;
  end;
  Result := GetLogger(Name);
end;

procedure ClearLoggers;
var
  i :Integer;
begin
  if __Loggers <> nil then
  begin
    for i := 0 to __Loggers.Count-1 do
    begin
      TLogger(__Loggers.Objects[i])._Release;
    end;
    __Loggers.Free;
    __Loggers := nil;
  end;
  ResetLogSequenceNumbers;
end;

{ TLogger }

constructor TLogger.Create(Name :string; Parent: ILogger);
begin
  inherited Create;
  FName   := Name;
  FParent := Parent;
end;


procedure TLogger.Log(Level: TLogLevel; Fmt: string; const Args: array of const);
begin
  if GetLevel >= Level then
  begin
    Log(Level, Format(Fmt, Args));
  end;
end;

procedure TLogger.Log(Level :TLogLevel; Msg: string);
var
  Entry :TLogEntry;
begin
  if GetLevel >= Level then
  begin
    Entry.When := Now;
    Inc(__Sequence);
    Entry.Seq := __Sequence;
    Entry.Level := Level;
    Entry.Who   := self.Name;
    Entry.Msg := Msg;
    Log(Entry);
  end;
end;

procedure TLogger.Log(const Entry: TLogEntry);
var
  i :Integer;
begin
  if Handlers <> nil then
  begin
    for i := 0 to Handlers.Count-1 do
        (Handlers[i] as ILogHandler).Log(Entry);
  end;
  if FParent <> nil then
  begin
    FParent.Log(Entry);
  end;
end;

procedure TLogger.Error(Fmt: string; const Args: array of const);
begin
  Log(logERROR, Fmt, Args);
end;

procedure TLogger.Error(Msg: string);
begin
   Log(logERROR, Msg);
end;

procedure TLogger.Warning(Fmt: string; const Args: array of const);
begin
  Log(logWARNING, Fmt, Args);
end;

procedure TLogger.Warning(Msg: string);
begin
  Log(logWARNING, Msg);
end;

procedure TLogger.Info(Fmt: string; const Args: array of const);
begin
  Log(logINFO, Fmt, Args);
end;

procedure TLogger.Info(Msg: string);
begin
  Log(logINFO, Msg);
end;

procedure TLogger.Debug(Fmt: string; const Args: array of const);
begin
  Log(logDEBUG, Fmt, Args);
end;

procedure TLogger.Debug(Msg: string);
begin
  Log(logDEBUG, Msg);
end;

function TLogger.GetName: string;
begin
  Result := FName;
end;

function TLogger.GetLevel: TLogLevel;
begin
  Result := FLevel;
  if (FParent <> nil) and (FParent.GetLevel > Result) then
  begin
    Result := FParent.GetLevel;
  end;
end;

procedure TLogger.SetLevel(Value: TLogLevel);
begin
  FLevel := Value;
end;

procedure TLogger.AddHandler(Value: ILogHandler);
begin
  if Handlers = nil then
    FHandlers := TInterfaceList.Create;
  Handlers.Add(Value);
end;

procedure TLogger.RemoveHandler(Value: ILogHandler);
begin
  if Handlers <> nil then
     Handlers.Remove(Value);
end;

function TLogger.GetHandlers: IInterfaceList;
begin
  Result := FHandlers;
end;


{ TAbstractLogHandler }

function TAbstractLogHandler.FormatEntry(const Entry: TLogEntry): string;
begin
  with Entry do
  begin
    Result := Format('%8.8d %s %-8s %s %s',
                      [ Seq,
                        FormatDateTime('yyyy-mm-dd hh:mm:ss.z', When),
                        LOG_LEVEL_NAMES[Level],
                        Who,
                        Msg
                        ]);
  end;
end;

{ TNullLogHandler }

procedure TNullLogHandler.Log(const Entry: TLogEntry);
begin
  // do nothing
end;

{ TDebugConsoleLogHandler }

procedure TDebugConsoleLogHandler.Log(const Entry: TLogEntry);
begin
  OutputDebugString(PChar(FormatEntry(Entry)));
end;

{ TFileLogHandler }

constructor TFileLogHandler.Create(FileName: string);
begin
  inherited Create;
  FFileName := FileName;
end;

procedure TFileLogHandler.Log(const Entry: TLogEntry);
begin
  LogToFile(FFileName, FormatEntry(Entry));
end;

initialization
  DefaultLogHandler := TDebugConsoleLogHandler.Create;
finalization
  ClearLoggers;
end.
