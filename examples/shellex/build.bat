@echo off
setlocal

:: ShellEx Build Script
:: Builds the Copy Path shell extension DLL

echo Building ShellEx...

:: Set paths
set FRAMEWORK=\masm64-framework
set OUT_DIR=bin
set OBJ_DIR=obj

:: Create output directories
if not exist %OUT_DIR% mkdir %OUT_DIR%
if not exist %OBJ_DIR% mkdir %OBJ_DIR%

:: Assemble
echo Assembling shellex.asm...
ml64 /c /nologo /Zi /Fo%OBJ_DIR%\shellex.obj shellex.asm
if errorlevel 1 goto :error

:: Link as DLL
echo Linking...
link /nologo /dll /entry:DllMain ^
    /def:exports.def ^
    /out:%OUT_DIR%\shellex.dll ^
    /debug ^
    %OBJ_DIR%\shellex.obj ^
    kernel32.lib user32.lib shell32.lib ole32.lib

if errorlevel 1 goto :error

echo.
echo Build successful: %OUT_DIR%\shellex.dll
echo.
echo Testing (without registration):
echo   rundll32 %OUT_DIR%\shellex.dll,TestCopyPath "C:\path\to\file.txt"
echo   rundll32 %OUT_DIR%\shellex.dll,TestCopyUnixPath "C:\path\to\file.txt"
echo.
echo Full registration (run as admin):
echo   regsvr32 %OUT_DIR%\shellex.dll
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
endlocal

