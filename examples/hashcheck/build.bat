@echo off
setlocal

:: HashCheck Build Script
:: Builds the file hash verification utility

echo Building HashCheck...

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

:: Link
echo Linking...
link /nologo /subsystem:console /entry:WinMain ^
    /out:%OUT_DIR%\hashcheck.exe ^
    /debug ^
    %OBJ_DIR%\main.obj ^
    kernel32.lib advapi32.lib shell32.lib

if errorlevel 1 goto :error

echo.
echo Build successful: %OUT_DIR%\hashcheck.exe
echo.
echo Usage: hashcheck [options] filename [expected_hash]
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
endlocal

