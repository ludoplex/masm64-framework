@echo off
setlocal

set UASM=uasm64.exe
set LINK=link.exe
set INCPATH=/I"..\..\core" /I"..\..\lib"
set LIBS=kernel32.lib

if not exist obj mkdir obj
if not exist bin mkdir bin

echo Assembling...
%UASM% /c /Cp /W2 /Zp8 /win64 %INCPATH% /Fo"obj\main.obj" main.asm
if errorlevel 1 goto :error

echo Linking...
%LINK% /SUBSYSTEM:CONSOLE /ENTRY:WinMain /OUT:bin\simple-console.exe obj\main.obj %LIBS%
if errorlevel 1 goto :error

echo.
echo Build successful: bin\simple-console.exe
goto :end

:error
echo Build failed!
exit /b 1

:end
endlocal

