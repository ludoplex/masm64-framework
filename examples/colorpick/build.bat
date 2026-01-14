@echo off
setlocal

:: ColorPick Build Script
:: Builds the screen color picker utility

echo Building ColorPick...

:: Set paths
set FRAMEWORK=\masm64-framework
set OUT_DIR=bin
set OBJ_DIR=obj

:: Create output directories
if not exist %OUT_DIR% mkdir %OUT_DIR%
if not exist %OBJ_DIR% mkdir %OBJ_DIR%

:: Assemble
echo Assembling main.asm...
ml64 /c /nologo /Zi /Fo%OBJ_DIR%\main.obj main.asm
if errorlevel 1 goto :error

:: Link as Windows GUI application
echo Linking...
link /nologo /subsystem:windows /entry:WinMain ^
    /out:%OUT_DIR%\colorpick.exe ^
    /debug ^
    %OBJ_DIR%\main.obj ^
    kernel32.lib user32.lib gdi32.lib shell32.lib

if errorlevel 1 goto :error

echo.
echo Build successful: %OUT_DIR%\colorpick.exe
echo.
echo Usage:
echo   - Run colorpick.exe (sits in system tray)
echo   - Press Ctrl+Shift+C to activate color picker
echo   - Click anywhere to copy hex color to clipboard
echo   - Right-click tray icon to exit
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
endlocal

