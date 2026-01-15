@echo off
setlocal

REM -----------------------------------------------------------------------------
REM Console Application Build Script
REM -----------------------------------------------------------------------------
REM Project name is read from config.inc or set below as fallback
REM -----------------------------------------------------------------------------

set PROJECT_NAME=MyApp
set ASM=ml64.exe
set LINK=link.exe
set LIBS=kernel32.lib user32.lib

if not exist obj mkdir obj
if not exist bin mkdir bin

echo Building %PROJECT_NAME%...

echo   Assembling...
%ASM% /c /nologo /Zi /Fo obj\main.obj main.asm
if errorlevel 1 goto :error

echo   Linking...
%LINK% /nologo /SUBSYSTEM:CONSOLE /ENTRY:WinMain /DEBUG ^
    /OUT:bin\%PROJECT_NAME%.exe obj\main.obj %LIBS%
if errorlevel 1 goto :error

echo.
echo Build successful: bin\%PROJECT_NAME%.exe
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
endlocal
