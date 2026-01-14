@echo off
setlocal enabledelayedexpansion

REM -----------------------------------------------------------------------------
REM MASM64 Disassembly Helper
REM -----------------------------------------------------------------------------
REM Usage: disasm.bat <executable> [options]
REM
REM Options:
REM   /all      - Disassemble all sections
REM   /headers  - Show PE headers
REM   /imports  - Show import table
REM   /exports  - Show export table
REM   /out file - Output to file
REM -----------------------------------------------------------------------------

call "%~dp0config.bat"

set EXECUTABLE=%~1
set SHOW_ALL=0
set SHOW_HEADERS=0
set SHOW_IMPORTS=0
set SHOW_EXPORTS=0
set OUTPUT_FILE=

if "%EXECUTABLE%"=="" (
    echo Usage: disasm.bat ^<executable^> [options]
    exit /b 1
)

shift

:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="/all" set SHOW_ALL=1
if /i "%~1"=="/headers" set SHOW_HEADERS=1
if /i "%~1"=="/imports" set SHOW_IMPORTS=1
if /i "%~1"=="/exports" set SHOW_EXPORTS=1
if /i "%~1"=="/out" set OUTPUT_FILE=%~2& shift
shift
goto :parse_args
:args_done

REM Find dumpbin
set DUMPBIN=dumpbin.exe

REM Try to find in Windows SDK
if exist "%WINSDK%\bin\%WINSDK_VER%\x64\dumpbin.exe" (
    set DUMPBIN=%WINSDK%\bin\%WINSDK_VER%\x64\dumpbin.exe
)

REM Build command
set DUMPBIN_FLAGS=

if %SHOW_ALL%==1 (
    set DUMPBIN_FLAGS=/DISASM /ALL
) else (
    set DUMPBIN_FLAGS=/DISASM
)

if %SHOW_HEADERS%==1 set DUMPBIN_FLAGS=%DUMPBIN_FLAGS% /HEADERS
if %SHOW_IMPORTS%==1 set DUMPBIN_FLAGS=%DUMPBIN_FLAGS% /IMPORTS
if %SHOW_EXPORTS%==1 set DUMPBIN_FLAGS=%DUMPBIN_FLAGS% /EXPORTS

echo Disassembling %EXECUTABLE%...

if defined OUTPUT_FILE (
    "%DUMPBIN%" %DUMPBIN_FLAGS% "%EXECUTABLE%" > "%OUTPUT_FILE%"
    echo Output written to: %OUTPUT_FILE%
) else (
    "%DUMPBIN%" %DUMPBIN_FLAGS% "%EXECUTABLE%"
)

endlocal

