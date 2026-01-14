@echo off
setlocal enabledelayedexpansion

REM -----------------------------------------------------------------------------
REM MASM64 Framework Debug Helper
REM -----------------------------------------------------------------------------
REM Usage: debug.bat <executable> [options]
REM
REM Options:
REM   /windbg   - Use WinDbg (default)
REM   /x64dbg   - Use x64dbg
REM   /vs       - Use Visual Studio debugger
REM   /attach   - Attach to running process
REM   /cmd      - Execute debugger commands from file
REM -----------------------------------------------------------------------------

call "%~dp0config.bat"

set EXECUTABLE=
set DEBUGGER_TYPE=windbg
set ATTACH_MODE=0
set CMD_FILE=

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="/windbg" set DEBUGGER_TYPE=windbg& shift& goto :parse_args
if /i "%~1"=="/x64dbg" set DEBUGGER_TYPE=x64dbg& shift& goto :parse_args
if /i "%~1"=="/vs" set DEBUGGER_TYPE=vs& shift& goto :parse_args
if /i "%~1"=="/attach" set ATTACH_MODE=1& shift& goto :parse_args
if /i "%~1"=="/cmd" set CMD_FILE=%~2& shift& shift& goto :parse_args
if not defined EXECUTABLE set EXECUTABLE=%~1
shift
goto :parse_args
:args_done

if not defined EXECUTABLE (
    echo Usage: debug.bat ^<executable^> [options]
    echo.
    echo Options:
    echo   /windbg   - Use WinDbg (default)
    echo   /x64dbg   - Use x64dbg
    echo   /vs       - Use Visual Studio debugger
    echo   /attach   - Attach to running process by name
    echo   /cmd file - Execute debugger commands from file
    echo.
    echo Examples:
    echo   debug.bat bin\myapp.exe
    echo   debug.bat myapp.exe /x64dbg
    echo   debug.bat myapp /attach
    exit /b 1
)

REM Check if file exists (unless attach mode)
if %ATTACH_MODE%==0 (
    if not exist "%EXECUTABLE%" (
        REM Try adding .exe
        if exist "%EXECUTABLE%.exe" (
            set EXECUTABLE=%EXECUTABLE%.exe
        ) else (
            REM Try in bin directory
            if exist "bin\%EXECUTABLE%" (
                set EXECUTABLE=bin\%EXECUTABLE%
            ) else if exist "bin\%EXECUTABLE%.exe" (
                set EXECUTABLE=bin\%EXECUTABLE%.exe
            ) else (
                echo Error: Executable not found: %EXECUTABLE%
                exit /b 1
            )
        )
    )
)

echo.
echo MASM64 Debug Helper
echo ===================
echo Executable: %EXECUTABLE%
echo Debugger: %DEBUGGER_TYPE%
if %ATTACH_MODE%==1 echo Mode: Attach to process
echo.

REM Launch debugger
if "%DEBUGGER_TYPE%"=="windbg" (
    call :launch_windbg
) else if "%DEBUGGER_TYPE%"=="x64dbg" (
    call :launch_x64dbg
) else if "%DEBUGGER_TYPE%"=="vs" (
    call :launch_vs
) else (
    echo Error: Unknown debugger type: %DEBUGGER_TYPE%
    exit /b 1
)

exit /b 0

REM -----------------------------------------------------------------------------
REM Launch WinDbg
REM -----------------------------------------------------------------------------
:launch_windbg
set WINDBG_PATH=

REM Try to find WinDbg
if exist "C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\windbg.exe" (
    set WINDBG_PATH=C:\Program Files (x86)\Windows Kits\10\Debuggers\x64\windbg.exe
) else if exist "%WINSDK%\Debuggers\x64\windbg.exe" (
    set WINDBG_PATH=%WINSDK%\Debuggers\x64\windbg.exe
) else (
    REM Try WinDbg Preview from Store
    for /d %%d in ("%LOCALAPPDATA%\Microsoft\WindowsApps\Microsoft.WinDbg*") do (
        if exist "%%d\WinDbgX.exe" set WINDBG_PATH=%%d\WinDbgX.exe
    )
)

if not defined WINDBG_PATH (
    echo Error: WinDbg not found
    echo Install Windows SDK or WinDbg Preview from Microsoft Store
    exit /b 1
)

echo Launching WinDbg...

set WINDBG_CMD="%WINDBG_PATH%"

if %ATTACH_MODE%==1 (
    set WINDBG_CMD=%WINDBG_CMD% -pn "%EXECUTABLE%"
) else (
    set WINDBG_CMD=%WINDBG_CMD% "%EXECUTABLE%"
)

if defined CMD_FILE (
    set WINDBG_CMD=%WINDBG_CMD% -cf "%CMD_FILE%"
)

start "" %WINDBG_CMD%
exit /b 0

REM -----------------------------------------------------------------------------
REM Launch x64dbg
REM -----------------------------------------------------------------------------
:launch_x64dbg
set X64DBG_PATH=

REM Try to find x64dbg
if exist "C:\x64dbg\release\x64\x64dbg.exe" (
    set X64DBG_PATH=C:\x64dbg\release\x64\x64dbg.exe
) else if exist "%ProgramFiles%\x64dbg\release\x64\x64dbg.exe" (
    set X64DBG_PATH=%ProgramFiles%\x64dbg\release\x64\x64dbg.exe
)

if not defined X64DBG_PATH (
    echo Error: x64dbg not found
    echo Download from: https://x64dbg.com
    exit /b 1
)

echo Launching x64dbg...

if %ATTACH_MODE%==1 (
    echo Note: Use File menu to attach to process
    start "" "%X64DBG_PATH%"
) else (
    start "" "%X64DBG_PATH%" "%EXECUTABLE%"
)
exit /b 0

REM -----------------------------------------------------------------------------
REM Launch Visual Studio debugger
REM -----------------------------------------------------------------------------
:launch_vs
if not defined VS_PATH (
    echo Error: Visual Studio path not configured
    echo Edit tools\config.bat to set VS_PATH
    exit /b 1
)

set DEVENV_PATH=%VS_PATH%\Common7\IDE\devenv.exe

if not exist "%DEVENV_PATH%" (
    echo Error: Visual Studio not found at configured path
    exit /b 1
)

echo Launching Visual Studio debugger...

if %ATTACH_MODE%==1 (
    echo Note: Use Debug menu to attach to process
    start "" "%DEVENV_PATH%"
) else (
    start "" "%DEVENV_PATH%" /debugexe "%EXECUTABLE%"
)
exit /b 0

