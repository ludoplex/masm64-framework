@echo off
setlocal

REM -----------------------------------------------------------------------------
REM GUI Application Build Script
REM -----------------------------------------------------------------------------

set PROJECT_NAME=MyApp
set ASM=ml64.exe
set LINK=link.exe
set RC=rc.exe
set LIBS=kernel32.lib user32.lib gdi32.lib comctl32.lib

if not exist obj mkdir obj
if not exist bin mkdir bin

echo Building %PROJECT_NAME%...

REM Compile resources if present
if exist res\resources.rc (
    echo   Compiling resources...
    %RC% /nologo /fo obj\resources.res res\resources.rc
    if errorlevel 1 goto :error
    set RES=obj\resources.res
) else (
    set RES=
)

echo   Assembling...
%ASM% /c /nologo /Zi /Fo obj\main.obj main.asm
if errorlevel 1 goto :error

echo   Linking...
%LINK% /nologo /SUBSYSTEM:WINDOWS /ENTRY:WinMain /DEBUG ^
    /OUT:bin\%PROJECT_NAME%.exe obj\main.obj %RES% %LIBS%
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
