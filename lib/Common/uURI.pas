{************************************************************}
{                                                            }
{                 Модуль uURI                                }
{                                                            }
{  Содержит функции для работы с URI и URL                   }
{  Разработчик: Шумкин А. К.                                 }
{                                                            }
{************************************************************}

unit uURI;

interface

uses
  WinInet;

type
  TURI = record
    Schema,
    Host,
    Port,
    Path,
    Query,
    UserName,
    Password: string;
  end;

// получает имя файла из ссылки URI
// в том числе убирает параметры (?param...)
function ExtractURIFileName(const AUrl: string): string;

// проверяет существование URL - смотрит на ответ сервера - 200 или 302
function CheckUrlExists(url: string): boolean;

// получает URL из основного и относительного
// поведение такое же, как у браузера с атрибутом href тега <a>:
// 1. если RelURL абсолютный, то берётся он
// 2. если начинается с "/", то URL получается относительно корня сервера
//    иначе - относительно текущей папки
function CombineURLs(const BaseURL, RelURL: string): string;
// то же, но с каноническим URL на выходе
function CombineURLs2(const BaseURL, RelURL: string): string;

implementation

uses
  SysUtils, StrUtils, Windows;

function ExtractURIFileName(const AUrl: string): string;
var
  i: Integer;
begin
  i := LastDelimiter('/', AUrl);
  Result := RightStr(AUrl, Length(AUrl) - i);
  i := Pos('?', Result);
  if i > 0 then
    Result := LeftStr(Result, i - 1);
end;

function CheckUrlExists(url: string): boolean;
var
  hSession, hFile: hInternet;
  dwIndex, dwCodeLen: dword;
  dwCode: array [1..20] of char;
  res: Integer;
begin
  if not AnsiStartsText('http://', url) then
    url := 'http://' + url;
  Result := false;
  hSession := InternetOpen('InetURL:/1.0', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then
  begin
    hFile := InternetOpenUrl(hSession, pchar(url), nil, 0, INTERNET_FLAG_RELOAD, 0);
    dwIndex := 0;
    dwCodeLen := 10;
    HttpQueryInfo(hFile, HTTP_QUERY_STATUS_CODE, @dwCode, dwCodeLen, dwIndex);
    res := StrToIntDef(PChar(@dwCode), -1);
    result := (res = 200) or (res = 302);
    if Assigned(hFile) then
      InternetCloseHandle(hFile);
    InternetCloseHandle(hSession);
  end;
end;

function CombineURLs(const BaseURL, RelURL: string): string;
var
  Res: PAnsiChar;
  i: Cardinal;
begin
  GetMem(Res, MAX_PATH + 1);
  try
    ZeroMemory(Res, MAX_PATH + 1);
    i := MAX_PATH + 1;
    InternetCombineUrl(PAnsiChar(BaseURL), PAnsiChar(RelURL), Res, i, ICU_BROWSER_MODE);
    Result := Res;
  finally
    FreeMem(Res);
  end;
end;

function CombineURLs2(const BaseURL, RelURL: string): string;
var
  Res, cRes: PAnsiChar;
  i: Cardinal;
begin
  i := INTERNET_MAX_URL_LENGTH;
  GetMem(Res, i + 1);
  try
    GetMem(cRes, i + 1);
    try
      ZeroMemory(Res, i + 1);
      ZeroMemory(cRes, i + 1);
      if not InternetCombineUrl(PAnsiChar(BaseURL), PAnsiChar(RelURL), Res, i,
          ICU_BROWSER_MODE) then
        RaiseLastOSError;
      i := INTERNET_MAX_URL_LENGTH;
      if not InternetCanonicalizeUrl(Res, cRes, i, ICU_ESCAPE) then
        RaiseLastOSError;
      Result := cRes;
    finally
      FreeMem(cRes);
    end;
  finally
    FreeMem(Res);
  end;
end;

end.
