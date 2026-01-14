@echo off
setlocal enabledelayedexpansion

REM -----------------------------------------------------------------------------
REM Console Application Build Script
REM -----------------------------------------------------------------------------

REM Configuration
set PROJECT_NAME={{PROJECT_NAME}}
set ASM_FILES=main.asm

REM Paths (adjust as needed)
set UASM=uasm64.exe
set LINK=link.exe

REM Include paths
set INCPATH=/I"%~dp0..\..\core" /I"%~dp0..\..\lib"

REM Libraries
set LIBS=kernel32.lib user32.lib

REM Output directories
if not exist obj mkdir obj
if not exist bin mkdir bin

REM Assemble
echo Assembling %PROJECT_NAME%...
for %%f in (%ASM_FILES%) do (
    echo   %%f
    %UASM% /c /Cp /W2 /Zp8 /win64 %INCPATH% /Fo"obj\%%~nf.obj" "%%f"
    if errorlevel 1 goto :error
)

REM Link
echo Linking...
%LINK% /SUBSYSTEM:CONSOLE /ENTRY:WinMain /OUT:bin\%PROJECT_NAME%.exe ^
    obj\*.obj %LIBS%
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

