unit FileEditLoadTasks;

interface

uses
  SysUtils,
  
  WantClasses,

  uEncoder;

type

  TFileEditLoadTask = class(TTask)
  protected
    Fencoding: TEncoding;
    
    function Getencoding: string;
    procedure Setencoding(const Value: string);

    function ConvertFromTo(pStr: string; _from, _to: TEncoding): string; virtual;
    function Convert(pStr: string; from: boolean): string; overload; virtual;
  public
    property encoding: string read Getencoding write Setencoding;
  end;

implementation

{ TFileEditLoadTask }

function TFileEditLoadTask.ConvertFromTo(pStr: string; _from, _to: TEncoding): string;
var
  TE: TEncoder;
begin
  TE := TEncoder.Create;
  try
    TE.InputEncoding := _from;
    TE.OutputEncoding := _to;
    Result := TE.DoConvertText(pStr);
  finally
    FreeAndNil(TE);
  end;
end;

function TFileEditLoadTask.Convert(pStr: string; from: boolean): string;
var
  TE: TEncoder;
  ie, oe: TEncoding;
begin
  ie := TE.InputEncoding;
  oe := TE.OutputEncoding;
  if from then
    ie := Fencoding
  else
    oe := Fencoding;
  Result := ConvertFromTo(pStr, ie, oe);
end;

function TFileEditLoadTask.Getencoding: string;
begin
  Result := GetEncodingStr(Fencoding);
end;

procedure TFileEditLoadTask.Setencoding(const Value: string);
begin
  Fencoding := GetEncodingFromStr(Value);
  if not (Fencoding in Encodings) then
    TaskError(Format('Invalid encoding "%s"', [Value]));
end;

end.