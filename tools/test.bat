@echo off
setlocal enabledelayedexpansion

REM -----------------------------------------------------------------------------
REM MASM64 Framework Test Runner
REM -----------------------------------------------------------------------------
REM Usage: test.bat [test_name] [options]
REM
REM Options:
REM   /all      - Run all tests
REM   /verbose  - Show detailed output
REM   /pause    - Pause after each test
REM -----------------------------------------------------------------------------

call "%~dp0config.bat"

set TEST_DIR=%FRAMEWORK_ROOT%\tests
set RUN_ALL=0
set VERBOSE=0
set PAUSE_AFTER=0
set SPECIFIC_TEST=

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="/all" set RUN_ALL=1& shift& goto :parse_args
if /i "%~1"=="/verbose" set VERBOSE=1& shift& goto :parse_args
if /i "%~1"=="/pause" set PAUSE_AFTER=1& shift& goto :parse_args
set SPECIFIC_TEST=%~1
shift
goto :parse_args
:args_done

REM Check if tests directory exists
if not exist "%TEST_DIR%" (
    echo No tests directory found.
    echo Create tests in: %TEST_DIR%
    exit /b 1
)

echo.
echo MASM64 Framework Test Runner
echo ============================
echo.

set PASS_COUNT=0
set FAIL_COUNT=0
set SKIP_COUNT=0

REM Run specific test or all tests
if defined SPECIFIC_TEST (
    call :run_test "%SPECIFIC_TEST%"
) else (
    for /d %%t in ("%TEST_DIR%\*") do (
        call :run_test "%%~nt"
    )
)

echo.
echo ============================
echo Results: %PASS_COUNT% passed, %FAIL_COUNT% failed, %SKIP_COUNT% skipped
echo ============================

if %FAIL_COUNT% gtr 0 exit /b 1
exit /b 0

REM -----------------------------------------------------------------------------
REM Run a single test
REM -----------------------------------------------------------------------------
:run_test
set TEST_NAME=%~1
set TEST_PATH=%TEST_DIR%\%TEST_NAME%

if not exist "%TEST_PATH%" (
    echo [SKIP] %TEST_NAME% - not found
    set /a SKIP_COUNT+=1
    exit /b 0
)

echo [....] %TEST_NAME%

REM Build test
pushd "%TEST_PATH%"

if exist build.bat (
    call build.bat >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] %TEST_NAME% - build failed
        set /a FAIL_COUNT+=1
        popd
        exit /b 1
    )
)

REM Run test executable
set TEST_EXE=
if exist bin\*.exe (
    for %%e in (bin\*.exe) do set TEST_EXE=%%e
)

if not defined TEST_EXE (
    echo [SKIP] %TEST_NAME% - no executable
    set /a SKIP_COUNT+=1
    popd
    exit /b 0
)

if %VERBOSE%==1 (
    "%TEST_EXE%"
) else (
    "%TEST_EXE%" >nul 2>&1
)

if errorlevel 1 (
    echo [FAIL] %TEST_NAME% - execution failed
    set /a FAIL_COUNT+=1
) else (
    echo [PASS] %TEST_NAME%
    set /a PASS_COUNT+=1
)

popd

if %PAUSE_AFTER%==1 pause

exit /b 0

