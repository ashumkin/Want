@ECHO OFF
REM Get a local want.exe built so it can then do a full build with itself
REM brcc32 and dcc32 must be in PATH already

brcc32 -r ..\src\wantver.rc
if ERRORLEVEL 1 goto ERROR
brcc32 -r ..\src\license.rc
if ERRORLEVEL 1 goto ERROR

cd ..\src
dcc32 -Q -B -N%TEMP% -E%TEMP% -$O- -$J+ ..\src\want.dpr -Ulib;tasks;elements;..\lib\jcl\source;..\lib\perlre -U..\lib\dunit -U..\lib\jal\src;..\lib\jal\lib\paszlib -O..\lib\perlre
if ERRORLEVEL 1 goto ERROR
%TEMP%\want.exe %1 %2 %3 %4 %5 %6 %7 %8 %9
if ERRORLEVEL 1 goto ERROR
goto END
:ERROR
:END
cd ..\make
