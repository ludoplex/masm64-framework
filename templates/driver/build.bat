@echo off
setlocal enabledelayedexpansion

REM -----------------------------------------------------------------------------
REM Kernel Driver Build Script
REM -----------------------------------------------------------------------------
REM Requires Windows Driver Kit (WDK) to be installed
REM -----------------------------------------------------------------------------

set PROJECT_NAME={{PROJECT_NAME}}
set ASM_FILES=main.asm

REM WDK paths - adjust for your installation
set WDK=C:\Program Files (x86)\Windows Kits\10
set WDKVER=10.0.22621.0
set UASM=uasm64.exe
set LINK=link.exe

set INCPATH=/I"%WDK%\Include\%WDKVER%\km"
set LIBPATH=/LIBPATH:"%WDK%\Lib\%WDKVER%\km\x64"
set LIBS=ntoskrnl.lib hal.lib

if not exist obj mkdir obj
if not exist bin mkdir bin

REM Assemble
echo Assembling %PROJECT_NAME%...
for %%f in (%ASM_FILES%) do (
    echo   %%f
    %UASM% /c /Cp /W2 /Zp8 /win64 %INCPATH% /Fo"obj\%%~nf.obj" "%%f"
    if errorlevel 1 goto :error
)

REM Link as driver
echo Linking driver...
%LINK% /DRIVER /ENTRY:DriverEntry /SUBSYSTEM:NATIVE ^
    %LIBPATH% /OUT:bin\%PROJECT_NAME%.sys ^
    obj\*.obj %LIBS%
if errorlevel 1 goto :error

echo.
echo Build successful: bin\%PROJECT_NAME%.sys
echo.
echo WARNING: Driver must be signed before loading on production systems.
echo Use test signing for development.
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
endlocal

