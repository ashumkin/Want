{$APPTYPE CONSOLE}
program URITests;

uses
  SysUtils,
  URIs in 'URIs.pas';

{$R *.RES}

procedure WriteURI(URI :string);
begin
  writeln(URI);
  with SplitURI(URI) do
    writeln(Format('[%s][%s][%s][%s][%s]', [Protocol, Server, Path, Resource, Extension]));
  writeln;
end;

begin
  WriteURI('want/src/want.dpr');
  WriteURI('/want/src/want.dpr');
  WriteURI('/c:/want/src/want.dpr');
  WriteURI('http:/c:/want/src/want.dpr');
  WriteURI('http://localhost/c:/want/src/want.dpr');
  WriteURI('http://remote.com/c:/want/src/want.dpr');
  WriteURI('http://remote.com/want.dpr');
  WriteURI('http:/want/src/want.dpr');
  WriteURI('http:want.dpr');
  WriteURI('http:.cvsignore');
  WriteURI('.cvsignore');
  WriteURI('/.cvsignore');

  WriteURI('file:/c:/.cvsignore');
  WriteURI('file:///c:/.cvsignore');
  WriteURI('file://c:/.cvsignore');

  ReadLn;
end.
