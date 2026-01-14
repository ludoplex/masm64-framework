@echo off
setlocal

:: RawMouse Build Script
:: Builds the mouse acceleration disabler driver
::
:: REQUIREMENTS:
::   - Windows Driver Kit (WDK) installed
::   - Run from WDK build environment or set paths manually

echo Building RawMouse Driver...
echo.
echo WARNING: Kernel drivers require test signing or proper code signing!
echo          Test only in virtual machines!
echo.

:: Set paths
set FRAMEWORK=\masm64-framework
set OUT_DIR=bin
set OBJ_DIR=obj

:: Create output directories
if not exist %OUT_DIR% mkdir %OUT_DIR%
if not exist %OBJ_DIR% mkdir %OBJ_DIR%

:: Check for WDK
if not defined WDKDIR (
    echo Note: WDKDIR not set. Attempting to find WDK...
    if exist "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\km\x64" (
        set WDKDIR=C:\Program Files (x86)\Windows Kits\10
        set WDKVER=10.0.22621.0
    ) else (
        echo Error: Windows Driver Kit (WDK) not found.
        echo Please install WDK or set WDKDIR environment variable.
        exit /b 1
    )
)

:: Assemble
echo Assembling driver.asm...
ml64 /c /nologo /Zi /Fo%OBJ_DIR%\driver.obj driver.asm
if errorlevel 1 goto :error

:: Link as kernel driver
echo Linking...
link /nologo /driver /entry:DriverEntry /subsystem:native ^
    /out:%OUT_DIR%\rawmouse.sys ^
    /debug ^
    %OBJ_DIR%\driver.obj ^
    "%WDKDIR%\Lib\%WDKVER%\km\x64\ntoskrnl.lib"

if errorlevel 1 goto :error

echo.
echo Build successful: %OUT_DIR%\rawmouse.sys
echo.
echo Installation (Administrator required):
echo   1. Enable test signing: bcdedit /set testsigning on
echo   2. Reboot
echo   3. Create INF file and install via Device Manager
echo   4. Or use sc.exe to load manually (for testing)
echo.
echo For testing in VM only!
goto :end

:error
echo.
echo Build failed!
echo.
echo Common issues:
echo   - WDK not installed
echo   - Not running from WDK build environment
echo   - Missing ntoskrnl.lib
exit /b 1

:end
endlocal

