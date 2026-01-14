@echo off
setlocal

:: EDRTest Build Script
:: Builds the EDR/AV security testing shellcode

echo Building EDRTest...
echo.
echo This tool tests EDR/AV detection capabilities using benign shellcode.
echo The payload only displays a MessageBox - completely safe to run.
echo.

:: Set paths
set FRAMEWORK=\masm64-framework
set OUT_DIR=bin
set OBJ_DIR=obj

:: Create output directories
if not exist %OUT_DIR% mkdir %OUT_DIR%
if not exist %OBJ_DIR% mkdir %OBJ_DIR%

:: Assemble with minimal sections
echo Assembling main.asm...
ml64 /c /nologo /Fo%OBJ_DIR%\main.obj main.asm
if errorlevel 1 goto :error

:: Link as executable (for easy testing)
echo Linking as executable...
link /nologo /subsystem:console /entry:ShellcodeEntry ^
    /out:%OUT_DIR%\edrtest.exe ^
    %OBJ_DIR%\main.obj ^
    kernel32.lib user32.lib

if errorlevel 1 goto :error

:: Also create raw .bin if Python is available
echo.
echo Extracting shellcode bytes...
where python >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    python extract.py %OUT_DIR%\edrtest.exe %OUT_DIR%\edrtest.bin
    if %ERRORLEVEL% EQU 0 (
        echo Created: %OUT_DIR%\edrtest.bin
    ) else (
        echo Note: Could not extract raw shellcode. Run extract.py manually.
    )
) else (
    echo Note: Python not found. Run extract.py manually to get raw bytes.
)

echo.
echo Build successful!
echo.
echo Files created:
echo   %OUT_DIR%\edrtest.exe - Standalone test executable
echo   %OUT_DIR%\edrtest.bin - Raw shellcode bytes (if Python available)
echo.
echo Usage:
echo   1. Run edrtest.exe directly to test
echo   2. If EDR blocks it, the techniques triggered detection
echo   3. If MessageBox appears, techniques evaded detection
echo.
echo For security research only!
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
endlocal

