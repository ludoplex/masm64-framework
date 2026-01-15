@echo off
setlocal

REM -----------------------------------------------------------------------------
REM Kernel Driver Build Script
REM -----------------------------------------------------------------------------
REM Requires Windows Driver Kit (WDK)
REM Run tools\setup.ps1 from repository root to install WDK
REM -----------------------------------------------------------------------------

set PROJECT_NAME=MyDriver
set ASM=ml64.exe
set LINK=link.exe

REM WDK paths
set WDK=%ProgramFiles(x86)%\Windows Kits\10
set WDKVER=10.0.22621.0
set LIBPATH=/LIBPATH:"%WDK%\Lib\%WDKVER%\km\x64"
set LIBS=ntoskrnl.lib hal.lib

if not exist obj mkdir obj
if not exist bin mkdir bin

REM Check for WDK
if not exist "%WDK%\Lib\%WDKVER%\km\x64\ntoskrnl.lib" (
    echo ERROR: Windows Driver Kit not found.
    echo Please install WDK or adjust WDKVER in this script.
    echo Expected: %WDK%\Lib\%WDKVER%\km\x64\ntoskrnl.lib
    exit /b 1
)

echo Building %PROJECT_NAME%...

echo   Assembling...
%ASM% /c /nologo /Zi /Fo obj\main.obj main.asm
if errorlevel 1 goto :error

echo   Linking driver...
%LINK% /nologo /DRIVER /ENTRY:DriverEntry /SUBSYSTEM:NATIVE /DEBUG ^
    %LIBPATH% /OUT:bin\%PROJECT_NAME%.sys obj\main.obj %LIBS%
if errorlevel 1 goto :error

echo.
echo Build successful: bin\%PROJECT_NAME%.sys
echo.
echo NOTE: Driver must be signed before loading on production systems.
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
endlocal
