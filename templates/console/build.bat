@echo off
setlocal

REM -----------------------------------------------------------------------------
REM Console Application Build Script
REM -----------------------------------------------------------------------------

set PROJECT_NAME=MyApp

if not exist obj mkdir obj
if not exist bin mkdir bin

echo Building %PROJECT_NAME%...

echo   Assembling...
ml64 /c /nologo /Zi /Fo obj\main.obj main.asm
if errorlevel 1 goto :error

echo   Linking...
link /nologo /SUBSYSTEM:CONSOLE /ENTRY:WinMain /DEBUG ^
    /OUT:bin\%PROJECT_NAME%.exe ^
    obj\main.obj ^
    kernel32.lib user32.lib
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
