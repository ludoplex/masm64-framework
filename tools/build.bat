@echo off
setlocal enabledelayedexpansion

REM -----------------------------------------------------------------------------
REM MASM64 Framework Build Tool
REM -----------------------------------------------------------------------------
REM Usage: build.bat [options]
REM Options:
REM   /debug    - Build with debug symbols
REM   /release  - Build optimized (default)
REM   /clean    - Clean build artifacts
REM   /rebuild  - Clean and rebuild
REM   /verbose  - Show detailed output
REM -----------------------------------------------------------------------------

REM Load configuration
call "%~dp0config.bat"

REM Parse arguments
set BUILD_TYPE=release
set DO_CLEAN=0
set VERBOSE=0

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="/debug" set BUILD_TYPE=debug
if /i "%~1"=="/release" set BUILD_TYPE=release
if /i "%~1"=="/clean" set DO_CLEAN=1
if /i "%~1"=="/rebuild" (
    set DO_CLEAN=1
    set BUILD_TYPE=release
)
if /i "%~1"=="/verbose" set VERBOSE=1
shift
goto :parse_args
:args_done

REM Check for project.json or use defaults
set PROJECT_NAME=project
set SUBSYSTEM=CONSOLE
set ENTRY=WinMain
set ASM_FILES=*.asm
set LIBS=kernel32.lib user32.lib

if exist project.json (
    REM Parse project.json for settings
    for /f "tokens=2 delims=:," %%a in ('findstr /c:"\"name\"" project.json') do (
        set PROJECT_NAME=%%~a
        set PROJECT_NAME=!PROJECT_NAME: =!
    )
)

REM Clean if requested
if %DO_CLEAN%==1 (
    echo Cleaning...
    if exist %OBJ_DIR% rmdir /s /q %OBJ_DIR%
    if exist %BIN_DIR% rmdir /s /q %BIN_DIR%
    if %BUILD_TYPE%==clean goto :end
)

REM Create output directories
if not exist %OBJ_DIR% mkdir %OBJ_DIR%
if not exist %BIN_DIR% mkdir %BIN_DIR%

REM Set build flags
if "%BUILD_TYPE%"=="debug" (
    set EXTRA_ASM_FLAGS=/Zi /DDEBUG
    set EXTRA_LINK_FLAGS=/DEBUG
) else (
    set EXTRA_ASM_FLAGS=
    set EXTRA_LINK_FLAGS=
)

REM Assemble source files
echo.
echo Building %PROJECT_NAME% (%BUILD_TYPE%)...
echo ========================================
echo.

set ERROR_COUNT=0

for %%f in (%ASM_FILES%) do (
    echo Assembling: %%f
    if %VERBOSE%==1 (
        echo %ASM% %ASM_FLAGS% %EXTRA_ASM_FLAGS% /I"%CORE_INC%" /I"%LIB_INC%" /Fo"%OBJ_DIR%\%%~nf.obj" "%%f"
    )
    %ASM% %ASM_FLAGS% %EXTRA_ASM_FLAGS% /I"%CORE_INC%" /I"%LIB_INC%" /Fo"%OBJ_DIR%\%%~nf.obj" "%%f"
    if errorlevel 1 (
        echo   ERROR: Assembly failed for %%f
        set /a ERROR_COUNT+=1
    )
)

if %ERROR_COUNT% gtr 0 (
    echo.
    echo Build failed with %ERROR_COUNT% error(s)
    exit /b 1
)

REM Compile resources if present
set RES_FILE=
if exist res\*.rc (
    echo Compiling resources...
    for %%r in (res\*.rc) do (
        %RC% /fo"%OBJ_DIR%\%%~nr.res" "%%r"
        if errorlevel 1 goto :error
        set RES_FILE=%OBJ_DIR%\%%~nr.res
    )
)

REM Link
echo.
echo Linking...
set OBJ_LIST=
for %%o in (%OBJ_DIR%\*.obj) do set OBJ_LIST=!OBJ_LIST! "%%o"

if %VERBOSE%==1 (
    echo %LINK% /SUBSYSTEM:%SUBSYSTEM% /ENTRY:%ENTRY% %EXTRA_LINK_FLAGS% /OUT:"%BIN_DIR%\%PROJECT_NAME%.exe" %OBJ_LIST% %RES_FILE% %LIBS%
)

%LINK% /SUBSYSTEM:%SUBSYSTEM% /ENTRY:%ENTRY% %EXTRA_LINK_FLAGS% ^
    /OUT:"%BIN_DIR%\%PROJECT_NAME%.exe" ^
    %OBJ_LIST% %RES_FILE% %LIBS%

if errorlevel 1 goto :error

echo.
echo ========================================
echo Build successful: %BIN_DIR%\%PROJECT_NAME%.exe
echo ========================================
goto :end

:error
echo.
echo ========================================
echo Build FAILED
echo ========================================
exit /b 1

:end
endlocal

