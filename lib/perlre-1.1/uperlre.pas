unit uperlre;

(*

  TPerlRe - Luu Tran <luutran@geocities.com>

  Version 1.1

  Last Updated: 3-Mar-99

  This is the Delphi4 wrapper for perlre.dll, the win32 port of
  Philip Hazel's PCRE (Perl Compatible Regular Expression) package.
  PCRE itself can be found at:

  ftp://ftp.cus.cam.ac.uk/pub/software/programs/pcre/

  See TPerlRe.txt for documentation.

  This is freeware.  Permission is granted to anyone to use this
  software for any purpose on any computer system,
  and to redistribute it freely, subject to the following restrictions:

1. This software is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

2. The origin of this software must not be misrepresented, either by
   explicit claim or by omission.

3. Altered versions must be plainly marked as such, and must not be
   misrepresented as being the original software.

*)

(*
  History:
    1.0: initial
    1.01: change split so split( ',', 'a') returns list with
          1 elem 'a' instead of empty list
    1.1: no longer requires external dll, thanks to CARIOTOGLOU MIXALIS <Mike@singular.gr>
*)

interface

uses
  Windows, Messages, SysUtils, Classes;

const

  // Exec-time error codes

  PCRE_ERROR_NOMATCH        = -1;
  PCRE_ERROR_NULL           = -2;
  PCRE_ERROR_BADOPTION      = -3;
  PCRE_ERROR_BADMAGIC       = -4;
  PCRE_ERROR_UNKNOWN_NODE   = -5;
  PCRE_ERROR_NOMEMORY       = -6;

  // maximum number of sub expression, not incl. the 0th part
  MAX_SUBEXP = 20;
type
  TPCREOptions = set of (
    pcre_CASELESS,
    pcre_MULTILINE,
    pcre_DOTALL,
    pcre_SINGLELINE,
    pcre_EXTENDED,
    pcre_ANCHORED,
    pcre_DOLLAR_ENDONLY,
    pcre_EXTRA,
    pcre_NOTBOL,
    pcre_NOTEOL,
    pcre_UNGREEDY
  );

const
  DefaultOpts = [pcre_CASELESS];


type

  EPerlRe = class(Exception);

  pcre = Pointer;
  pcre_xtra = Pointer;

  PPChar = ^PChar;
  PInt = ^Integer;

  // Functions

  // array of offsets from pcre_exec

  TSubExpRange = 0..MAX_SUBEXP;
  TOffsets = array[0..(MAX_SUBEXP+1)*2-1] of integer;

  TSubExp = record
    Text: string; StartP, Len: integer;
  end;

  TPerlre = class
  private
    // the "program", result from pcre_compile
    FProg: pcre;
    // result from pcre_study
    FHints: pcre_xtra;
    // the pattern
    FRegExp: string;
    // text to match
    FText: string;
    // pointer to FText's start and end search position
    FStart,FEnd: PChar;
    // offset array
    FOffsets: TOffsets;
    FErrorOffset: integer;
    // result from pcre_exec
    FMatch: integer;
    // last error msg
    FError: PChar;
    // options
    FOptions: TPCREOptions;
    FStudy: boolean;
    procedure SetOptions( opts: TPCREOptions);
    procedure SetRegExp( const s: string);
    procedure SetText( const s: string);
    function GetSubExp( index: TSubExpRange) : TSubExp;
    function GetSubExpCount: integer;
   public
    property RegExp: string read FRegExp write SetRegExp;
    property Options: TPCREOptions read FOptions write SetOptions;
    property Text: string read FText write SetText;
    property SubExp[index:TSubExpRange]: TSubExp read GetSubExp; default;
    property SubExpCount: integer read GetSubExpCount;
    constructor Create( doStudy: boolean=true; opts:TPCREOptions=DefaultOpts);
    destructor Destroy; override;
    procedure Reset;
    procedure Split( const regexp: string; str: string; elems:
                     TStrings; doTrim: boolean=true);
    procedure Compile( const regexp: string); overload;
    procedure Compile( const regexp: string; MatchCase: boolean); overload;
    procedure Compile( const regexp: string; opts: TPCREOptions); overload;
    function Match: boolean; overload;
    function Match( const str: string): boolean; overload;
    function Match( const regexp, str: string): boolean; overload;
    function Match( const regexp, str: string; opts: TPCREOptions): boolean; overload;
  end;

function EscRegex( const re: string):string;

var regex: TPerlre;

implementation

{ TPerlre }
{.$define USEDLL}
{$ifndef USEDLL}
{$L pcre.obj}
{$L study.obj}

function EscRegex( const re: string):string;
var i,n:integer;
begin
  n:=0; SetLength( Result, Length(re) shl 1); // over estimate length
  for i:=1 to Length( re) do
  begin
    inc( n);
    if (re[i] in ['!','$','^','*','(',')','+',
                  '-','=','[',']','\',',','.','{','}','|',
                  ':','?']) then
    begin
      Result[n]:='\'; inc( n);
    end;
    Result[n]:=re[i];
  end;
  SetLength( Result, n);
end;

type Tpcre_malloc=function(size:cardinal):pointer; cdecl;
     Tpcre_free  =procedure(p:pointer);cdecl;

var pcre_malloc : Tpcre_malloc;
    pcre_free   : Tpcre_free;

function malloc(size:cardinal):pointer; cdecl;
 begin
  result:=allocmem(size);
 end;

procedure free(p:pointer); cdecl;
 begin
  freeMem(p);
 end;

function memset(src:pointer; c:integer; n:cardinal):pointer; cdecl;
 begin
  fillchar(src^,n,c);
  result:=src;
 end;

function memmove(dest:pointer;src:pointer;n:cardinal):pointer; cdecl;
 begin
  move(src^,dest^,n);
  result:=dest;
 end;

function memcpy(dest:pointer;src:pointer;n:cardinal):pointer; cdecl;
 begin
  move(src^,dest^,n);
  result:=dest;
 end;

function strchr(const s:pchar; c: integer):pchar; cdecl;
 begin
  result:=StrScan(s,char(c));
 end;

{$endif}

function pcre_compile( const pattern: PChar;
                       options: integer;
                       errorptr: PPChar;
                       erroroffset: PInt;
                       const tables: PChar): pcre;
                       cdecl; external {$ifdef USEDLL} 'perlre.dll'{$endif};

function pcre_exec(    const external_re: pcre;
                       const external_xtra: pcre_xtra;
                       const subject: PChar;
                       length: integer;
                       options: integer;
                       offsets: PInt;
                       offsetcount: integer): integer;
                       cdecl; external {$ifdef USEDLL} 'perlre.dll'{$endif};

function pcre_study(   const external_re: pcre;
                       options: integer;
                       errorptr: PPChar): pcre_xtra;
                       cdecl; external {$ifdef USEDLL} 'perlre.dll'{$endif};
{$ifdef USEDLL}
procedure pcre_dispose(re: pcre; rex: pcre_xtra);
                       cdecl; external  'perlre.dll';
{$else}
procedure pcre_dispose(re: pcre; rex: pcre_xtra);
 begin
  if (re<>nil) then free(re);
  if (rex<>nil) then free(rex);
 end;
{$endif}

function pcre_info(    const external_re: pcre;
                       optptr: PInt;
                       first_char: PInt): integer;
                       cdecl; external  {$ifdef USEDLL} 'perlre.dll'{$endif};

function pcre_version: pchar;
                       cdecl; external  {$ifdef USEDLL} 'perlre.dll'{$endif};


constructor TPerlre.Create( doStudy: boolean=true; opts:TPCREOptions=DefaultOpts);
begin
  FProg:=nil; FHints:=nil;
  FStudy:=doStudy; FOptions:=opts;
  FText:=''; FError:=nil; FRegExp:='';
  Reset;
  inherited Create;
end;

destructor TPerlre.Destroy;
begin
  pcre_dispose( FProg, FHints);
  inherited Destroy;
end;


procedure TPerlre.Compile( const regexp: string);
begin
  FRegExp:=regexp;

  pcre_dispose( FProg, FHints); FProg:=nil; FHints:=nil;

  FProg:=pcre_compile( Pchar( FRegExp),  Word(FOptions), @FError, @FErrorOffset, nil);

  if FProg<>nil then
  begin
    Reset;
    if FStudy then
    begin
      FHints := pcre_study( FProg, 0, @FError);
      if FError<>nil then
        EPerlre.Create( 'Perlre: '+string( FError));
    end;
  end else
    raise EPerlre.Create( 'Perlre: '+string( FError));
end;

procedure TPerlre.Compile(const regexp: string; MatchCase: boolean);
begin
  if MatchCase then
    Exclude(FOptions, pcre_CASELESS)
  else
    Include(FOptions,PCRE_CASELESS);
  Compile( regexp);
end;

procedure TPerlre.Compile(const regexp: string; opts: TPCREOptions);
begin
  FOptions:=opts; Compile( regexp);
end;

function TPerlre.Match: boolean;
begin
  if FProg=nil then
  begin
    raise EPerlre.Create( 'Perlre: no regex defined'); exit;
  end;
  FStart:=FEnd;
  FMatch:=pcre_exec( FProg, FHints, FStart,
                     StrLen( FStart), 0, @FOffsets[0], (MAX_SUBEXP+1)*2);
  Result:=FMatch>=0;
  if Result then
    FEnd:=FStart+FOffsets[1];
end;

function TPerlre.Match(const str: string): boolean;
begin
  Text:=str; Result:=Match;
end;

function TPerlre.Match(const regexp, str: string): boolean;
begin
  Compile( regexp); Result:=Match( str);
end;

function TPerlre.Match(const regexp, str: string; opts: TPCREOptions): boolean;
begin
  FOptions:=opts; Result:=Match( regexp, str);
end;

procedure TPerlre.SetOptions(opts: TPCREOptions);
begin
  if opts<>FOptions then
  begin
    FOptions:=opts; if FProg<>nil then Compile( FRegExp);
  end;
end;

procedure TPerlre.SetRegExp(const s: string);
begin
  if s<>FRegExp then Compile( s);
end;

// split a string into a tstrings based on regexp, e.g., ' +', ','
// if dotrim=true, trim spaces
// if no match, whole string is assume as 1 element  tstrings is not cleared at start
procedure TPerlre.Split( const regexp: string; str: string;
                         elems: TStrings; doTrim: boolean=true);
var
  sub: string; P:PChar;
begin
  if Assigned(elems) then
  begin
    Compile( regexp); Text:=str; P:=FStart;
    while Match do
    begin
      sub:=copy( str, FStart-P+1, FOffsets[0]);
      if doTrim then sub:=Trim(sub);
      elems.Add(sub);
    end;
    // grab the remainder (or whole string if no match)
    sub:=String( FStart);
    if doTrim then sub:=Trim(sub);
    if sub<>'' then elems.Add(sub);
  end else
    raise EPerlre.Create('Perlre: undefined TStrings in split');
end;

function TPerlre.GetSubExp(index: TSubExpRange):  TSubExp;
var i:integer;
begin
  if (FMatch>=0) then
  begin
    i:=index;
    if (i in [0..FMatch]) then
    with result do
    begin
      i:=i shl 1;
      StartP:=(FStart-PChar(FText))+(FOffsets[i]+1);
      Len:=FOffsets[i+1]-FOffsets[i];
      Text:=copy( FText, StartP, Len);
    end else
      raise EPerlre.Create( 'Perlre: index out of range in GetSubExp')
  end else
    raise EPerlre.Create( 'Perlre: GetSubExp without match');
end;

function TPerlre.GetSubExpCount: integer;
begin
  if FMatch>=0 then
    result:=FMatch
  else
    raise EPerlre.Create( 'Perlre: GetSubExpCount without match')
end;

procedure TPerlre.Reset;
begin
  FStart:=PChar( FText); FEnd:=FStart; FMatch:=-1;
end;

procedure TPerlre.SetText(const s: string);
begin
  FText:=s; Reset;
end;

// create default regex for easy use
initialization
  pcre_malloc := malloc;
  pcre_free   := free;
  regex:=TPerlre.Create;

finalization
  regex.Free;

end.








