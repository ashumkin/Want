unit URIs;

interface
uses
  SysUtils;

type
  TURI = record
    Protocol  :string;
    Server    :string;
    Path      :string;
    Resource  :string;
    Extension :string;
  end;

function SplitURI(URI :string) :TURI;

implementation

function SplitURIProtocol(var URI :string) :string;
var
  ColonPos,
  SlashPos :Integer;
begin
  ColonPos := Pos(':', URI);
  SlashPos := Pos('/', URI);
  if (ColonPos <= 0)        // no colon
  or (SlashPos > 0) and (SlashPos < ColonPos)  // slash before colon, like in "/c:/file"
  then
    Result := ''
  else
    Result := Copy(URI, 1, ColonPos);
  Delete(URI, 1, Length(Result));
end;

function URIProtocol(URI :string):string;
begin
   Result := SplitURIProtocol(URI);
end;

function URIWithoutProtocol(URI :string):string;
begin
   SplitURIProtocol(URI);
   Result := URI;
end;


function SplitURIServer(var URI :string) :string;
var
  SlashPos :Integer;
begin
  SplitURIProtocol(URI);
  if Pos('//', URI) <> 1 then
    Result := ''
  else
  begin
    Delete(URI, 1, 2);
    SlashPos := Pos('/', URI);
    if SlashPos = 0 then
      SlashPos := Length(URI);
    Result := Copy(URI, 1, SlashPos-1);
    Delete(URI, 1, Length(Result));
  end;
end;

function URIServer(URI :string):string;
begin
   Result := SplitURIServer(URI);
end;

function SplitURIExtension(var URI :string):string;
var
  DotPos :Integer;
begin
  DotPos := LastDelimiter('.', URI);
  if DotPos = 0 then
    Result := ''
  else
  begin
    Result := Copy(URI, DotPos, 1+Length(URI)-DotPos);
    Delete(URI, DotPos, Length(Result));
  end;
end;

function URIExtension(URI :string):string;
begin
   Result := SplitURIExtension(URI);
end;


function SplitURI(URI :string) :TURI;
var
  SlashPos :Integer;
begin
  with Result do
  begin
    Protocol  := SplitURIProtocol(URI);
    Server    := SplitURIServer(URI);

    Extension := SplitURIExtension(URI);

    SlashPos := LastDelimiter('/', URI);
    if SlashPos = 0 then
      Resource := ''
    else
    begin
      Resource := Copy(URI, SlashPos+1, Length(URI));
      Delete(URI, SlashPos, 1+Length(Resource));
    end;
    Path := URI
  end;
end;

function URIPath(URI :string) : string;
begin
   with SplitURI(URI) do
     Result := Path + Extension;
end;


end.
