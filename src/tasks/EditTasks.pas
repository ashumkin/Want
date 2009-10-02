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
}
unit EditTasks;

interface
uses
  SysUtils,
  Classes,
  StrUtils,
  Math,

  JclSysUtils,
  JclStrings,

  PerlRE,

  WildPaths,
  WantClasses,
  FileEditLoadTasks,

  uEncoder;

type
  TEditTask = class(TFileEditLoadTask)
  protected
    FBuffer   :TStrings;
    FText     :string;
    FDot      :Integer;

    FFile     :string;
    FLastPat  :string;
    FCurrentFile :string;

    procedure SetDot(Value :Integer);

    procedure SetText(Value :string);

    property Dot    :Integer     read FDot    write SetDot;
    property Buffer :TStrings    read FBuffer write FBuffer;

    function ParseLine(Line :string) :Integer;

    procedure Perform;
    procedure ConvertBuffer;
  public
    constructor Create(Owner :TScriptElement); override;
    destructor Destroy; override;

    procedure Execute; override;
  published
    property _file :string read FFile   write FFile;
    property text  :string read FText   write FText;
    property encoding;
  end;
  
  TEditor = TEditTask;

  TCustomEditElement = class(TScriptElement)
  protected
    procedure Perform(Editor :TEditor);                                      overload; virtual;
    function  Perform(Buffer :TStrings; FromLine, ToLine :Integer) :Integer; overload; virtual;
    function  Perform(Buffer :TStrings; Line :Integer):Integer;              overload; virtual;
  end;

  TGotoElement = class(TCustomEditElement)
  protected
    FLine :string;

    procedure Perform(Editor :TEditor); override;
  public
    procedure Init; override;
  published
    property line :string read FLine write FLine;
  end;

  TRangeElement = class(TCustomEditElement)
  protected
    FFrom  :string;
    FTo    :string;

    procedure SetLine(Value :string);

    procedure Perform(Editor :TEditor); override;
    function  Perform(Buffer :TStrings; FromLine, ToLine :Integer) :Integer; override;

    procedure SetRangeToAll(Value :boolean);
  published
    property from :string  read FFrom write FFrom;
    property _to  :string  read FTo   write FTo;
    property line :string  read Ffrom write SetLine;
    property all  :boolean write SetRangeToAll;
  end;

  TEditElement = class(TRangeElement)
  protected
  end;

  TPrintElement = class(TEditElement)
  protected
    FLevel :TLogLevel;

    function Perform(Buffer :TStrings; Line :Integer) :Integer;  override;
  public
    constructor Create(Owner :TScriptElement); override;

  published
    property Level :TLogLevel read FLevel write FLevel default vlNormal;
  end;

  TPatternElement = class(TRangeElement)
  protected
    Fregexp: boolean;
    Finvert: boolean;
    FPattern :string;
    function Match(const line: string): boolean; virtual;
  published
    property pattern :string read FPattern write FPattern;
    property regexp: boolean read Fregexp write Fregexp;
    property invert: boolean read Finvert write Finvert;
  end;

  TSearchElement = class(TPatternElement)
  protected
    procedure Perform(Editor :TEditor); override;
    function  Perform(Buffer :TStrings; FromLine, ToLine :Integer):Integer; override;
  published
  end;

  TSubstElement = class(TEditElement)
  protected
    FPattern :string;
    FSubst   :string;
    FGlobal  :boolean;

    procedure Perform(Editor :TEditor); override;
    function  Perform(Buffer :TStrings; Line :Integer):Integer; override;
  public
    procedure Init; override;
  published
    property pattern :string  read FPattern write FPattern;
    property subst   :string  read FSubst   write FSubst;
    property global  :boolean read FGlobal  write FGlobal;
  end;

  TGlobalElement = class(TPatternElement)
  protected
    procedure Perform(Editor :TEditor);   override;
  end;


  TDeleteElement = class(TEditElement)
  protected
    function Perform(Buffer :TStrings; FromLine, ToLine :Integer) :Integer; override;
  public
  end;


  TEditFileElement = class(TEditElement)
  protected
    FFile :string;

    procedure Perform(Editor :TEditor);                                      override;
  published
    property _file :string read FFile write FFile;
  end;

  TReadElement = class(TEditFileElement)
  protected
    function Perform(Buffer :TStrings; FromLine, ToLine :Integer) :Integer; override;
  public
    procedure Init; override;
  end;

  TWriteElement = class(TEditFileElement)
  protected
    FAppend :boolean;

    function  Perform(Buffer :TStrings; FromLine, ToLine :Integer) :Integer; override;
  published
    constructor Create(Owner :TScriptElement); override;
    property Append :boolean read FAppend write FAppend;
  end;

  TInsertElement = class(TEditElement)
  protected
    FText :TStrings;

    function GetText :string;
    procedure SetText(Value :string);

    function TargetLine(FromLine, ToLine :Integer) :Integer; virtual;

    function Perform(Buffer :TStrings; FromLine, ToLine :Integer) :Integer; override;
  public
    constructor Create(Owner :TScriptElement); override;
    destructor Destroy; override;
  published
    property text :string read GetText write SetText;
  end;

  TAppendElement = class(TInsertElement)
  protected
    function TargetLine(FromLine, ToLine :Integer) :Integer; override;
  end;

  TEvalElement = class(TEditElement)
  protected
    function Perform(Buffer :TStrings; Line :Integer):Integer; override;
  end;

  TSetPropertyElement = class(TEditElement)
  protected
    Fname: string;
    Foverwrite: boolean;
    function Perform(Buffer :TStrings; Line :Integer) :Integer;  override;
    procedure Init; override;
  public
  published
    property name: string read Fname write Fname;
    property overwrite: boolean read Foverwrite write Foverwrite;
  end;

implementation

{ TEditTask }

procedure TEditTask.ConvertBuffer;
begin
  Buffer.Text := Convert(Buffer.Text, True);
end;

constructor TEditTask.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  FBuffer := TStringList.Create;
end;

destructor TEditTask.Destroy;
begin
  FreeAndNil(FBuffer);
  inherited Destroy;
end;

procedure TEditTask.SetText(Value: string);
var
  S :TStrings;
  i :Integer;
begin
  S := TStringList.Create;
  try
    S.Text := Trim(Value);
    i := 0;
    while (i < S.Count) and (S[i] = '') do
      Inc(i);

    while (i < S.Count) do
    begin
      if S[i] = '.' then
        Buffer.Append('')
      else
        Buffer.Append(S[i]);
      Inc(i);
    end;

    while (i < S.Count) do
    begin
      // this code is never executed after previuos loop!
      Buffer.Append(S[i]);
      Inc(i);
    end;
  finally
    FreeAndNil(S);
  end;
end;

function TEditTask.ParseLine(Line: string): Integer;
begin
  if (Line = '.') or (Line = '') then
    Result := Dot
  else if Line = '$' then
    Result := Buffer.Count-1
  else if StrLeft(Line, 1) = '+' then
    Result := Min(Buffer.Count-1, Dot + StrToInt(Copy(Line, 2, Length(Line))))
  else if StrLeft(Line, 1) = '-' then
    Result := Max(0, Dot - StrToInt(Copy(Line, 2, Length(Line))))
  else
    Result := Max(0, Min(Buffer.Count, StrToInt(Line)-1));
end;

procedure TEditTask.SetDot(Value: Integer);
begin
  if Value >= 0 then
    FDot := Min(Buffer.Count-1, Value);
end;


procedure TEditTask.Perform;
var
  i: Integer;
begin
  SetText(FText);
  for i := 0 to ChildCount-1 do
    if (Children[i] is TCustomEditElement)
        and (Children[i].Enabled) then
      TCustomEditElement(Children[i]).Perform(Self);
end;

procedure TEditTask.Execute;
var
  f     :Integer;
  Files :TPaths;
begin
  Files := nil;
  inherited Execute;
  Log;
  if _file = '' then
    Perform
  else
  begin
    Files := Wild(_file, BasePath);
    if Length(Files) = 0 then
    begin
      Log(vlVerbose, 'No files to edit');
      Perform;
    end
    else
      try
        for f := Low(Files) to High(Files) do
        begin
          FCurrentFile := Files[f];
          Log(vlVerbose, '%s', [FCurrentFile]);
          Buffer.Clear;
          Buffer.LoadFromFile(ToSystemPath(FCurrentFile));
          ConvertBuffer;
          Perform
        end;
      finally
        FCurrentFile := '';
      end;
  end;
end;

{ TCustomEditElement }

procedure TCustomEditElement.Perform(Editor: TEditor);
begin
  Editor.Dot := Perform(Editor.Buffer, Editor.Dot, Editor.Dot);
end;


function TCustomEditElement.Perform(Buffer :TStrings; FromLine, ToLine :Integer):Integer;
var
  l :Integer;
begin
  Result := FromLine;
  for l := Max(0,FromLine) to Min(Buffer.Count-1,ToLine) do
    Result := Perform(Buffer, l);
end;

function TCustomEditElement.Perform(Buffer: TStrings; Line: Integer) :Integer;
begin
  Result := Line;
end;

{ TGotoElement }

procedure TGotoElement.Init;
begin
  inherited Init;
  RequireAttribute('line');
end;

procedure TGotoElement.Perform(Editor: TEditor);
begin
  Log(vlVerbose, '%s %s', [TagName, Line]);
  Editor.Dot := Editor.ParseLine(line);
end;

{ TRangeElement }

procedure TRangeElement.Perform(Editor: TEditor);
var
  f, t :Integer;
begin
  f := Editor.ParseLine(from);
  t := Editor.ParseLine(_to);

  Editor.Dot := Perform(Editor.Buffer, f, t);
end;

function TRangeElement.Perform(Buffer: TStrings; FromLine, ToLine: Integer): Integer;
var
  i    :Integer;
begin
  Result := inherited Perform(Buffer, FromLine, ToLine);
  for i := 0 to ChildCount-1 do
  begin
    if (Children[i] is TEditElement)
        and (Children[i].Enabled) then
      Result := TEditElement(Children[i]).Perform(Buffer, FromLine, ToLine);
  end;
end;

procedure TRangeElement.SetLine(Value: string);
begin
  from := Value;
  _to  := Value;
end;

procedure TRangeElement.SetRangeToAll(Value: boolean);
begin
  if Value then
  begin
    from := '0';
    _to  := '$';
  end;
end;

{ TGlobalElement }

procedure TGlobalElement.Perform(Editor: TEditor);
var
  f, t :Integer;
  l    :Integer;
begin
  Log(vlVerbose, '%s /%s/', [TagName, pattern]);
  if from = '' then
    from := '0';
  if _to = '' then
    _to := '$';

  if pattern = '' then
    pattern := Editor.FLastPat;

  f := Editor.ParseLine(from);
  t := Editor.ParseLine(_to);

  with Editor do
  begin
    l := Max(0, f);
//    for l := Max(0, f) to Min(Buffer.Count-1, t) do
    while l <= Min(Buffer.Count-1, t) do
    begin
      Dot := l;
      if Match(Buffer[l]) then
        Dot := Self.Perform(Editor.Buffer, l, l);
      inc(l);
    end
  end;
end;

{ TSearchElement }

procedure TSearchElement.Perform(Editor: TEditor);
begin
  if pattern = '' then
    pattern := Editor.FLastPat
  else if pattern <> '' then
    Editor.FLastPat := pattern;

  Log(vlVerbose, '%s /%s/%s', [TagName, pattern, IfThen(regexp, ' regexp')]);

  if _to = '' then
    _to := '$';

  inherited Perform(Editor);
end;

function TSearchElement.Perform(Buffer :TStrings; FromLine, ToLine :Integer) :Integer;
var
  l     :Integer;
  Found :boolean;
begin
  Result := FromLine;
  Found := False;
  for l := Max(0, FromLine) to Min(Buffer.Count-1, ToLine) do
  begin
    if Match(Buffer[l]) then
    begin
      Result := inherited Perform(Buffer, l, l);
      Found := true;
      break;
    end;
  end;
  if not Found then
    Log(vlWarnings, Format('Pattern "%s" not found', [pattern]));
end;

{ TPrintElement }

constructor TPrintElement.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  Level := vlNormal;
end;

function TPrintElement.Perform(Buffer: TStrings; Line: Integer) :Integer;
begin
  Log(Buffer[Line], Level);
  Result := -1; // print doesn't alter dot
end;

{ TDeleteElement }

function TDeleteElement.Perform(Buffer: TStrings; FromLine, ToLine: Integer) :Integer;
var
  l :Integer;
begin
  Log(vlVerbose, '%s %d,%d', [TagName, 1+FromLine, 1+ToLine]);
  for l := Min(Buffer.Count-1,ToLine) downto Max(0,FromLine) do
    Buffer.Delete(l);
  Result := FromLine;
end;

{ TEditFileElement }

procedure TEditFileElement.Perform(Editor: TEditor);
begin
  if (_file = '') then
  begin
    if (Editor.FCurrentFile = '') then
      WantError('No file name')
    else
    begin
      _file := Editor.FCurrentFile;
    end;
  end;
  inherited Perform(Editor);
end;

{ TReadElement }

procedure TReadElement.Init;
begin
  inherited Init;
  RequireAttribute('file');
end;

function TReadElement.Perform(Buffer: TStrings; FromLine, ToLine: Integer): Integer;
var
  S     :TStringList;
  i     :Integer;
  f     :Integer;
  pos   :Integer;
  Files :TPaths;
begin
  Files := nil;
  Log(vlVerbose, '%s %d %s', [TagName, 1+ToLine, ToRelativePath(_file)]);
  Result := FromLIne;
  S := TStringList.Create;
  try
     pos := Max(0, 1 + Min(Buffer.Count-1, ToLine));
     Files := Wild(_file, BasePath);
     for f := High(Files) downto Low(Files) do
     begin
       Log(vlVerbose, '%s %d %s', [TagName, pos, ToRelativePath(Files[f])]);
       S.LoadFromFile(ToSystemPath(Files[f]));
       if pos >= Buffer.Count then
         Buffer.AddStrings(S)
       else
         for i := S.Count-1 downto 0 do
         begin
           Buffer.Insert(pos, S[i]);
         end;
       S.Clear;
     end;
  finally
    FreeAndNil(S);
  end;
end;

{ TWriteElement }

constructor TWriteElement.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  from  := '0';
  _to   := '$';
end;

function TWriteElement.Perform(Buffer: TStrings; FromLine, ToLine: Integer): Integer;
var
  S :TStringList;
  i :Integer;
begin
  if append then
    Log(vlVerbose, '%s %d,%d >> %s', [TagName, 1+FromLine, 1+ToLine, ToRelativePath(_file)])
  else
    Log(vlVerbose, '%s %d,%d %s', [TagName, 1+FromLine, 1+ToLine, ToRelativePath(_file)]);

  Result := -1; // don't change the line
  S := TStringList.Create;
  try
     if append and FileExists(_file) then
       S.LoadFromFile(ToSystemPath(_file));
     for i := Max(0, FromLine) to Min(Buffer.Count-1, ToLine) do
       S.Append(Buffer[i]);
     S.SaveToFile(ToSystemPath(_file));
  finally
    FreeAndNil(S);
  end;
end;


{ TInsertElement }

constructor TInsertElement.Create(Owner: TScriptElement);
begin
  inherited Create(Owner);
  FText := TStringList.Create;
end;

destructor TInsertElement.Destroy;
begin
  FreeAndNil(FText);
  inherited Destroy;
end;

function TInsertElement.GetText: string;
begin
  Result := FText.Text;
end;

function TInsertElement.Perform(Buffer: TStrings; FromLine, ToLine: Integer): Integer;
var
   i :Integer;
begin
  ToLine := Max(0, TargetLine(FromLine, ToLine));
  Log(vlVerbose, '%s %d', [TagName, 1+ToLine]);
  if ToLine > Buffer.Count then
  begin
    Buffer.AddStrings(FText);
    Result := Buffer.Count;
  end
  else
  begin
    for i := FText.Count-1 downto 0 do
      Buffer.Insert(ToLine, FText[i]);
    Result := ToLine + FText.Count;
  end;
end;

procedure TInsertElement.SetText(Value: string);
begin
  FText.Text := Value;
end;

function TInsertElement.TargetLine(FromLine, ToLine: Integer): Integer;
begin
  Result := ToLine;
end;

{ TAppendElement }

function TAppendElement.TargetLine(FromLine, ToLine: Integer): Integer;
begin
  Result := ToLine + 1;
end;


{ TSubstElement }

procedure TSubstElement.Init;
begin
  inherited Init;
  RequireAttribute('subst');
end;

function TSubstElement.Perform(Buffer: TStrings; Line: Integer): Integer;
begin
  Buffer[Line] := PerlRE.Replace(pattern, subst, Buffer[Line], global);
  Result := inherited Perform(Buffer, Line);
end;

procedure TSubstElement.Perform(Editor: TEditor);
begin
  if pattern = '' then
    pattern := Editor.FLastPat
  else if pattern <> '' then
    Editor.FLastPat := pattern;

  if global then
    Log(vlVerbose, '%s /%s/%s/g', [TagName, pattern, subst])
  else
    Log(vlVerbose, '%s /%s/%s/',  [TagName, pattern, subst]);

  inherited Perform(Editor);
end;

{ TEvalElement }

function TEvalElement.Perform(Buffer: TStrings; Line: Integer): Integer;
begin
  Buffer[Line] := Evaluate(Buffer[Line]);
  Result := inherited Perform(Buffer, Line);
end;

{ TSetPropertyElement }

procedure TSetPropertyElement.Init;
begin
  inherited;
  RequireAttribute('name');
end;

function TSetPropertyElement.Perform(Buffer: TStrings; Line: Integer): Integer;
begin
  Result := 0;
  SetProperty(name, Buffer.Text, overwrite);
end;

{ TPatternElement }

function TPatternElement.Match(const line: string): boolean;
begin
  Result := (pattern = '')
    or (invert xor (
      (not regexp and (AnsiPos(pattern, line) <> 0))
      or (regexp and PerlRE.Match(pattern, line))
    ));
end;

initialization
  RegisterTask(TEditTask);
  RegisterElements( TEditTask, [
                        TGotoElement,
                        TPrintElement,
                        TGlobalElement,
                        TSearchElement,
                        TSubstElement,
                        TEvalElement,
                        TDeleteElement,
                        TReadElement,
                        TWriteElement,
                        TInsertElement,
                        TAppendElement,
                        TSetPropertyElement
                        ]);
  RegisterElements( TGlobalElement, [
                        TGotoElement,
                        TPrintElement,
                        TDeleteElement,
                        TSubstElement,
                        TEvalElement,
                        TReadElement,
                        TWriteElement,
                        TInsertElement,
                        TAppendElement
                        ]);
  RegisterElements( TSearchElement, [
                        TPrintElement,
                        TDeleteElement,
                        TSubstElement,
                        TEvalElement,
                        TReadElement,
                        TWriteElement,
                        TInsertElement,
                        TAppendElement
                        ]);
end.
