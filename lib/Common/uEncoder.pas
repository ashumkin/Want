unit uEncoder;

interface

uses
  Classes, SysUtils, TypInfo,
  JCLUnicode
  ;

type
  TEncoding = (eOEM, eANSI, eUTF8);

  TEncoder = class(TPersistent)
  private
    FOutputFile: string;
    FInputFile: string;
    FConvert: string;
    FInputEncoding: TEncoding;
    FOutputEncoding: TEncoding;
    FText2: TWideStringList;
    FText: WideString;
    procedure SetConvert(const Value: string);
    function GetText: WideString;
    procedure SetText(const Value: WideString);
    procedure SetInputEncodingStr(const Value: string);
    procedure SetOutputEncodingStr(const Value: string);
    function GetInputEncodingStr: string;
    function GetOutputEncodingStr: string;
    procedure SetInputEncoding(const Value: TEncoding);
  protected
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function DoConvert: WideString;
    procedure Load;
    procedure LoadConvert;
    procedure LoadConvertFile(const pFileName: string);
    procedure LoadConvertSave;
    procedure Save(const OutFile: string = '');
    function DoConvertText(const pText: string): WideString;
    procedure DoConvertTextSave(const pText, OutFile: string);
    procedure DoConvertSave(const OutFile: string = '');

    property InputEncoding: TEncoding read FInputEncoding write SetInputEncoding;
    property OutputEncoding: TEncoding read FOutputEncoding write FOutputEncoding;
    property InputEncodingStr: string read GetInputEncodingStr write SetInputEncodingStr;
    property OutputEncodingStr: string read GetOutputEncodingStr write SetOutputEncodingStr;
    property Text: WideString read GetText write SetText;
  published
    property Convert: string read FConvert write SetConvert;
    property InputFile: string read FInputFile write FInputFile;
    property OutputFile: string read FOutputFile write FOutputFile;
  end;

const
  Encodings = [eANSI, eOEM, eUTF8];
  ConvertDirectionArrow = '->';

function ConvertAnsiToOem(const S: string) : string;
function ConvertOemToAnsi(const S: string) : string;
function GetEncodingStr(pEncoding: TEncoding): string;
function GetEncodingFromStr(pEncodingStr: string): TEncoding;

implementation

uses
  Windows,
{$IFDEF REGEXP}
  RegExpr,
{$ENDIF REGEXP}
  StrUtils,
  uProps;

function ConvertAnsiToOem(const S: string) : string;
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
function ConvertOemToAnsi(const S: string) : string;
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

procedure SetConversion(const aConversionParam: string;
  var aInEncoding, aOutEncoding: TEncoding);
var
{$IFDEF REGEXP}
  RE: TRegExpr;
{$ELSE REGEXP}
  p: Integer;
{$ENDIF REGEXP}
  _in, _out: string;
begin
  try
{$IFNDEF REGEXP}
    p := Pos(ConvertDirectionArrow, aConversionParam);
    if p > 1 then
    begin
      _in := LeftStr(aConversionParam, p - 1);
      _out := RightStr(aConversionParam, Length(aConversionParam) - p
        - Length(ConvertDirectionArrow));
    end
    else
{$ELSE REGEXP}
    RE.Expression := '(\w+)' + ConvertDirectionArrow + '(\w+)';
    if not RE.Exec(aConversionParam) then
{$ENDIF REGEXP}
      raise Exception.Create('Параметры преобразования кодировки заданы неверно');
{$IFDEF REGEXP}
    _in := RE.Match[1];
    _out := RE.Match[2];
{$ENDIF REGEXP}
    aInEncoding := GetEncodingFromStr(_in);
    if not (aInEncoding in Encodings) then
      raise Exception.CreateFmt('Входная кодировка %s не поддерживается', [_in]);

    aOutEncoding := GetEncodingFromStr(_out);
    if not (aOutEncoding in Encodings) then
      raise Exception.CreateFmt('Выходная кодировка %s не поддерживается', [_out]);
  finally
{$IFDEF REGEXP}
    FreeAndNil(RE);
{$ENDIF REGEXP}
  end;
end;

function GetEncodingStr(pEncoding: TEncoding): string;
begin
  Result := GetEnumName(TypeInfo(TEncoding), ord(pEncoding));
  Result := Copy(Result, 2, Length(Result));
end;

function GetEncodingFromStr(pEncodingStr: string): TEncoding;
begin
  pEncodingStr := AnsiReplaceText(pEncodingStr, '-', '');
  Result := TEncoding(GetEnumValue(TypeInfo(TEncoding), 'e' + pEncodingStr));
end;

{ TEncoder }

procedure TEncoder.Assign(Source: TPersistent);
var
  i, c: Integer;
  PL: PPropList;
  FieldName: string;
  FieldValue: Variant;
begin
  if Source is TStringList then
  begin
    FText2.Assign(Source);
    Text := FText2.Text;
  end
  else
  begin
    c := GetPropList(Source, PL);
    for i := 0 to c - 1 do
    begin
      FieldName := PL^[i].Name;
      FieldValue := GetPropValue(Source, FieldName);
      SetPropValueExt(Self, FieldName, FieldValue);
    end;
  end;
end;

constructor TEncoder.Create;
begin
  inherited;
  FInputEncoding := eANSI;
  FOutputEncoding := eANSI;
  FText2 := TWideStringList.Create;
end;

destructor TEncoder.Destroy;
begin
  FreeAndNil(FText2);
  inherited;
end;

function TEncoder.DoConvert: WideString;
begin
  if InputEncoding <> OutputEncoding then
  begin
    case InputEncoding of
       eOEM : Text := ConvertOemToAnsi(Text);
      eUTF8 :
        if FText2.SaveFormat = sfAnsi then
          Text := UTF8Decode(Text);
    end;
    case OutputEncoding of
        eOEM : Text := ConvertAnsiToOem(Text);
       eUTF8 : Text := UTF8Encode(Text);
    end;
  end;
  Result := Text;
end;

procedure TEncoder.DoConvertSave(const OutFile: string = '');
begin
  DoConvert;
  Save(OutFile);
end;

function TEncoder.DoConvertText(const pText: string): WideString;
begin
  Text := pText;
  Result := DoConvert;
end;

procedure TEncoder.DoConvertTextSave(const pText, OutFile: string);
begin
  DoConvertText(pText);
  Save(OutFile);
end;

function TEncoder.GetInputEncodingStr: string;
begin
  Result := GetEncodingStr(InputEncoding);
end;

function TEncoder.GetOutputEncodingStr: string;
begin
  Result := GetEncodingStr(OutputEncoding);
end;

function TEncoder.GetText: WideString;
begin
  Result := FText;
end;

procedure TEncoder.Load;
begin
  FText2.LoadFromFile(InputFile);
  FText := FText2.Text; 
end;

procedure TEncoder.LoadConvert;
begin
  Load;
  DoConvert;
end;

procedure TEncoder.LoadConvertFile(const pFileName: string);
begin
  InputFile := pFileName;
  LoadConvert;
end;

procedure TEncoder.LoadConvertSave;
begin
  LoadConvert;
  Save;
end;

procedure TEncoder.Save(const OutFile: string = '');
begin
  if Trim(OutFile) = '' then
    Exit;
  OutputFile := OutFile;
  FText2.SaveFormat := sfAnsi;
  FText2.SaveToFile(OutputFile);
end;

procedure TEncoder.SetConvert(const Value: string);
begin
  FConvert := Value;
  SetConversion(Convert, FInputEncoding, FOutputEncoding);
end;

procedure TEncoder.SetInputEncoding(const Value: TEncoding);
begin
  FInputEncoding := Value;
  FText2.SaveFormat := sfAnsi;
end;

procedure TEncoder.SetInputEncodingStr(const Value: string);
begin
  Convert := Value + ConvertDirectionArrow + OutputEncodingStr;
end;

procedure TEncoder.SetOutputEncodingStr(const Value: string);
begin
  Convert := InputEncodingStr + ConvertDirectionArrow + Value;
end;

procedure TEncoder.SetText(const Value: WideString);
begin
  FText2.Text := Value;
  FText := Value;
end;

end.
