@echo off
setlocal

set UASM=uasm64.exe
set LINK=link.exe
set INCPATH=/I"..\..\core" /I"..\..\lib\test64" /I"..\..\lib\branchless64"
set LIBS=kernel32.lib user32.lib

if not exist obj mkdir obj
if not exist bin mkdir bin

echo Building test framework...

REM Assemble test64 library
echo   test64.asm
%UASM% /c /Cp /W2 /Zp8 /win64 /I"..\..\core" /Fo"obj\test64.obj" "..\..\lib\test64\test64.asm"
if errorlevel 1 goto :error

REM Assemble branchless64 library
echo   branchless64.asm
%UASM% /c /Cp /W2 /Zp8 /win64 /I"..\..\core" /Fo"obj\branchless64.obj" "..\..\lib\branchless64\branchless64.asm"
if errorlevel 1 goto :error

REM Assemble tests
echo   run-tests.asm
%UASM% /c /Cp /W2 /Zp8 /win64 %INCPATH% /Fo"obj\run-tests.obj" run-tests.asm
if errorlevel 1 goto :error

REM Link
echo Linking...
%LINK% /SUBSYSTEM:CONSOLE /ENTRY:WinMain /OUT:bin\run-tests.exe ^
    obj\run-tests.obj obj\test64.obj obj\branchless64.obj %LIBS%
if errorlevel 1 goto :error

echo.
echo Build successful: bin\run-tests.exe
echo.
echo Running tests...
bin\run-tests.exe
echo.
echo Test exit code: %ERRORLEVEL%
goto :end

:error
echo Build failed!
exit /b 1

:end
endlocal

