@echo off
setlocal enabledelayedexpansion

REM -----------------------------------------------------------------------------
REM GUI Application Build Script
REM -----------------------------------------------------------------------------

set PROJECT_NAME={{PROJECT_NAME}}
set ASM_FILES=main.asm

set UASM=uasm64.exe
set LINK=link.exe
set RC=rc.exe

set INCPATH=/I"%~dp0..\..\core" /I"%~dp0..\..\lib"
set LIBS=kernel32.lib user32.lib gdi32.lib comctl32.lib

if not exist obj mkdir obj
if not exist bin mkdir bin

REM Compile resources if present
if exist res\resources.rc (
    echo Compiling resources...
    %RC% /fo"obj\resources.res" res\resources.rc
    if errorlevel 1 goto :error
    set RES=obj\resources.res
) else (
    set RES=
)

REM Assemble
echo Assembling %PROJECT_NAME%...
for %%f in (%ASM_FILES%) do (
    echo   %%f
    %UASM% /c /Cp /W2 /Zp8 /win64 %INCPATH% /Fo"obj\%%~nf.obj" "%%f"
    if errorlevel 1 goto :error
)

REM Link
echo Linking...
%LINK% /SUBSYSTEM:WINDOWS /ENTRY:WinMain /OUT:bin\%PROJECT_NAME%.exe ^
    obj\*.obj %RES% %LIBS%
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

