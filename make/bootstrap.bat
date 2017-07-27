@ECHO OFF
REM Get a local want.exe built so it can then do a full build with itself
REM brcc32 and dcc32 must be in PATH already

copy ..\src\wantver.bootstrap.rc ..\src\wantver.rc
brcc32 -r ..\src\wantver.rc
if ERRORLEVEL 1 goto ERROR
brcc32 -r ..\src\license.rc
if ERRORLEVEL 1 goto ERROR
brcc32 -r ..\src\usage.rc
if ERRORLEVEL 1 goto ERROR

cd ..\src
rem jcld11.inc is for Delphi 2007
copy ..\lib\jcl\jcl\source\jcl.template.inc  ..\lib\jcl\jcl\source\jcld11.inc
dcc32 -Q -B -N%TEMP% -E%TEMP% -$O- -$J+ ..\src\want.dpr -Ulib;tasks;elements;..\lib\jcl\jcl\source\common;..\lib\jcl\jcl\source\windows;..\lib\perlre -U..\lib\dunit -U..\lib\jal\src;..\lib\jal\lib\paszlib -O..\lib\perlre -I..\lib\jcl\jcl\source
if ERRORLEVEL 1 goto ERROR
%TEMP%\want.exe %1 %2 %3 %4 %5 %6 %7 %8 %9
if ERRORLEVEL 1 goto ERROR
goto END
:ERROR
:END
cd ..\make
