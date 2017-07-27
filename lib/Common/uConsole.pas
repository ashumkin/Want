unit uConsole;

// модуль для работы с консольными приложениями

interface

uses
  Classes, Windows, SysUtils, ShellAPi, uFileVersion;

type
  // класс лога
  TLogFile = class
  private
    FFileName: string;
    FHandle: TextFile;
    FOpened: boolean;
    FUseDateTime: boolean;
  protected
    function DoModifyText(const pText: string): string; virtual;
  public
    constructor Create;//(aLogfileName: string);
    destructor Destroy; override;
    function Open(aLogFileName: string; aAppend: boolean = False): boolean;
    procedure Close;
    procedure WriteToConsole(aText: string);
    procedure Write(const aText: string); overload;
    procedure Write(E: Exception); overload;
    procedure WriteFmt(const pFmt: string; pStr: array of const);
    procedure WriteError(const aText: string); overload;
    procedure WriteError(E: Exception); overload;

    property FileName: string read FFileName;
    property Opened: boolean read FOpened;
    property UseDateTime: boolean read FUseDateTime write FUseDateTime;
  end;

// Получить строку из ресурса, ресурс должен быть типа RCDATA
function GetResourceString(const RC_Name: string): string;
// Вывод помощи из ресурса, ресурс должен быть типа RCDATA
procedure Help(const RC_HelpName: string);

{ ConvertAnsiToOem translates a string into the OEM-defined character set }
function ConvertAnsiToOem(const S : string) : string;
{ ConvertOemToAnsi translates an OEM string into the ANSI-defined character set }
function ConvertOemToAnsi(const S : string) : string;
function GetLongPathName(const PathName: string): string;
function ExpandLongPathName(const PathName: string): string;

implementation

function GetResourceString(const RC_Name: string): string;
var
  Res: TResourceStream;
  SS: TStringStream;
begin
  Res := TResourceStream.Create(HInstance, RC_Name, RT_RCDATA);
  try
    SS := TStringStream.Create('');
    try
      Res.SaveToStream(SS);
      Result := SS.DataString;
    finally
      FreeAndNil(SS);
    end;
  finally
    FreeAndNil(Res);
  end;
end;

// Вывод помощи
procedure Help(const RC_HelpName: string);
begin
  Writeln(GetResourceString(RC_HelpName));
  Writeln('Version ' + GetModuleVersion);
end;

{ ConvertAnsiToOem translates a string into the OEM-defined character set }
function ConvertAnsiToOem(const S : string) : string;
{$IFNDEF WIN32}
var
  Source, Dest : array[0..255] of Char;
{$ENDIF}
begin
{$IFDEF WIN32}
  SetLength(Result, Length(S));
  if Length(Result) > 0 then
    CharToOem(PChar(S), PChar(Result));
{$ELSE}
  if Length(Result) > 0 then
  begin
    CharToOem(StrPCopy(Source, S), Dest);
    Result := StrPas(Dest);
  end;
{$ENDIF}
end; { ConvertAnsiToOem }

{ ConvertOemToAnsi translates an OEM string into the ANSI-defined character set }
function ConvertOemToAnsi(const S : string) : string;
{$IFNDEF WIN32}
var
  Source, Dest : array[0..255] of Char;
{$ENDIF}
begin
{$IFDEF WIN32}
  SetLength(Result, Length(S));
  if Length(Result) > 0 then
    OemToChar(PChar(S), PChar(Result));
{$ELSE}
  if Length(Result) > 0 then
  begin
    OemToChar(StrPCopy(Source, S), Dest);
    Result := StrPas(Dest);
  end;
{$ENDIF}
end; { ConvertOemToAnsi }

// Разделяет путь на часть, содержащую букву диска и каталог, и
// часть, содержащую имя файла. Если путь является именем UNC, имя
// разделяемого ресурса остается в первой части.
procedure ExtractFileParts(const Path: string;
  var Directory, Name: string);
var
  I: Integer;
begin
  // Получаем букву диска или имя хоста UNC и имя
  // разделяемого ресурса. В SysUtils нет подходящей
  // для этого функции.
  I := LastDelimiter('\:', Path);
  Name := Copy(Path, I + 1, MaxInt);
  if (I > 1) and
     (Path[I] = '\') and
     (not (Path[I - 1] in ['\', ':']) or
     (ByteType(Path, I - 1) = mbTrailByte)) then
        Dec(I);
  Directory := Copy(Path, 1, I);
  // Если Directory состоит только из хоста UNC, значит, мы
  // в Name извлекли имя разделяемого ресурса.
  if (Length(Directory) > 2) and (Directory[1] = '\') and
    (LastDelimiter('\', Directory) = 2) then
  begin
    Directory := Path;
    Name := '';
  end;
end;

function GetLongPathName(const PathName: string): string;
var
  Directory, FileName, FullName: string;
  LongName: string;
  Info: TShFileInfo;
begin
  FullName := ExcludeTrailingPathDelimiter(PathName);
  repeat
    ExtractFileParts(FullName, Directory, FileName);
    if FileName = '' then
      // Если путь состоит только из буквы диска, дальнейшее
      // раскрытие не требуется.
      LongName := IncludeTrailingPathDelimiter(Directory)
    else if SHGetFileInfo(PChar(FullName), 0, Info, SizeOf(Info),
                          Shgfi_DisplayName) = 0 then
       begin
         // Невозможно развернуть имя файла.
         Result := '';
         Exit;
       end
       else
         LongName := Info.szDisplayName;
    // Убедимся, что обратные косые черты включены в результат.
    if Result = '' then
      Result := LongName
    else
      Result := IncludeTrailingPathDelimiter(LongName) + Result;
    FullName := Directory;
  until FileName = '';
end;

function ExpandLongPathName(const PathName: string): string;
begin
  Result := GetLongPathName(ExpandFileName(PathName));
end;

{ TLogFile }

procedure TLogFile.Close;
begin
  if not Opened then
    Exit;
  FOpened := False;
  CloseFile(FHandle);
end;

constructor TLogFile.Create;
begin
  inherited;
  FFileName := '';
  FOpened := False;
end;

destructor TLogFile.Destroy;
begin
  Close;
  inherited;
end;

function TLogFile.DoModifyText(const pText: string): string;
begin
  Result := '';
  if UseDateTime then
    Result := FormatDateTime('yyyy-mm-dd hh:nn:ss ', Now);
  Result := Result + pText;
end;

function TLogFile.Open(aLogFileName: string; aAppend: boolean = False): boolean;
begin
  Result := False;
  Close;
  FileMode := fmOpenReadWrite;
  FFileName := aLogFileName;
//  FFileName := ExpandLongPathName(FFileName);
  AssignFile(FHandle, FFileName);
  if Trim(FFileName) <> '' then
  begin
    {$i-}
    if aAppend and FileExists(FFileName)then
      Append(FHandle)
    else
      Rewrite(FHandle);
    Result := IOResult = 0;
    {$i+}
  end;
  FOpened := Result;
end;

procedure TLogFile.Write(const aText: string);
begin
  try
    if Opened then
    begin
      Writeln(FHandle, DoModifyText(aText));
      Flush(FHandle);
    end
    else
      WriteToConsole(aText);
  except
    WriteToConsole(aText);
  end;
end;

procedure TLogFile.Write(E: Exception);
begin
  Write(E.Message);
end;

procedure TLogFile.WriteError(const aText: string);
begin
  Write('[ Error ]');
  Write(aText);
end;

procedure TLogFile.WriteError(E: Exception);
begin
  WriteError(E.Message);
end;

procedure TLogFile.WriteFmt(const pFmt: string; pStr: array of const);
begin
  Write(Format(pFmt, pStr));
end;

procedure TLogFile.WriteToConsole(aText: string);
begin
  if IsConsole then
  try
    aText := ConvertAnsiToOem(aText);
    Writeln(aText);
  except
  end;
end;

end.