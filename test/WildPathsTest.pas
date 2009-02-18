unit WildPathsTest;

interface

uses
  TestFramework, WildPaths;

type
  TTestToRelativePath = class(TTestCase)
  private
  public
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure TestToRelativePath;
    procedure TestToRelativePathUNC;
    procedure TestIsMatch;
  end;

implementation

{ TTestToRelativePath }

procedure TTestToRelativePath.Setup;
begin
  inherited;

end;

procedure TTestToRelativePath.TearDown;
begin
  inherited;

end;

procedure TTestToRelativePath.TestToRelativePath;
var
  Path: string;
  Base: string;
begin
  Base := '/SomeRoot/subdir/src';
  Path := '/dev/Borland/Delphi5/bin/dcc32.exe';
  CheckEquals('../../..' + Path, WildPaths.ToRelativePath(Path, Base),
    'ToRelativePath - Path not in Base');

  Base := '/SomeRoot/subdir/src';
  Path := '/SomeRoot/subdir/src/tasks';
  CheckEquals('./tasks', WildPaths.ToRelativePath(Path, Base),
    'ToRelativePath - Path subdir');

  Base := '/SomeRoot/subdir/src';
  Path := '/SomeRoot/subdir/src';
  CheckEquals('.', WildPaths.ToRelativePath(Path, Base),
    'ToRelativePath - Path = Base');

  Base := '/subdir/src';
  Path := '/SomeRoot/subdir/src';
  CheckEquals('../..' + Path, WildPaths.ToRelativePath(Path, Base),
    'ToRelativePath - Path not in Base');

  Base := '/SomeRoot/subdir/src';
  Path := '/SomeRoot';
  CheckEquals('../..', WildPaths.ToRelativePath(Path, Base),
    'ToRelativePath - Path parent of Base');

  Path := '/d:/dev/Borland/Delphi5/bin/dcc32.exe';
  Base := '/S:/SomeRoot/subdir/src';
  CheckEquals(Path, WildPaths.ToRelativePath(Path, Base),
    'ToRelativePath with different drive absolute');

  { any case like previous where drive letter was not in same place in both
    paths? -- shouldn't be }

  Base := '../sample/test';
  Path := '../sample/test/testA/AStuff';
  CheckEquals('./testA/AStuff', WildPaths.ToRelativePath(Path, Base),
    'relative base and path, path subdir of base');

  // == Additional examples of assumptive relative behavior

  // Works
  Base := '../sample/test';
  Path := '../sample/tst/testA/AStuff';
  CheckEquals('../tst/testA/AStuff', WildPaths.ToRelativePath(Path, Base),
    'relative base and path, path on different branch of base');

  // Works
  Base := '../sample/test';
  Path := '/tst/testA/AStuff';
  CheckEquals('/tst/testA/AStuff', WildPaths.ToRelativePath(Path, Base),
    'relative base, absolute path, path not in base');

  // Works
  Base := '../sample/test';
  Path := '/tst/testA/AStuff';
  CheckEquals('/tst/testA/AStuff', WildPaths.ToRelativePath(Path, Base),
    'relative base, absolute path, path not in base');

  // Doesn't work
  Base := '/sample/test';
  Path := '../test/testA/AStuff';
  { Absolute of Path could be /sample/test/testA/AStuff OR
    /different/yuk/test/testA/AStuff OR
    anything, can't assume the two 'test' directories are on the same path }
  CheckEquals('../test/testA/AStuff', WildPaths.ToRelativePath(Path, Base),
    'absolute base, relative path, cannot determine if Path in Base or not');
end;

procedure TTestToRelativePath.TestToRelativePathUNC;
var
  B, P :TPath;
begin
  P := '//machine/c/dir/../../..';
  B := '//machine/c/dir';
  CheckEquals('../../..', ToRelativePath(P, B));
  P := '//machine';
  CheckEquals('../..', ToRelativePath(P, B));
  P := '';
  CheckEquals('.', ToRelativePath(P, B));
  P := '//';
  CheckEquals('//', ToRelativePath(P, B));
end;

procedure TTestToRelativePath.TestIsMatch;
const
  Matches : array[1..3,1..2] of string =
    ( ('**/CVS/**', 'xx/yy/CVS'),
      ('**/CVS/**', 'xx/yy/CVS/Entries'),
      ('**/CVS/**', '/c:/home/want/lib/dunit/CVS')
    );
var
  i :Integer;
begin
  for i := Low(Matches) to High(Matches) do
    Check(IsMatch(Matches[i][1], Matches[i][2]), Matches[i][1] + ' ~ '+ Matches[i][2]);
end;


initialization
  RegisterTests('Path Tests', [TTestToRelativePath.Suite]);

end.

