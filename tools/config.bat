@echo off
REM -----------------------------------------------------------------------------
REM MASM64 Framework Configuration
REM -----------------------------------------------------------------------------
REM Edit this file to match your system configuration
REM -----------------------------------------------------------------------------

REM Assembler - UASM or ML64
REM For UASM (recommended):
set ASM=uasm64.exe
set ASM_FLAGS=/c /Cp /W2 /Zp8 /win64

REM For ML64 (Microsoft MASM):
REM set ASM=ml64.exe
REM set ASM_FLAGS=/c /Cp /W2 /Zp8

REM Linker
set LINK=link.exe

REM Resource Compiler
set RC=rc.exe

REM Windows SDK paths
set WINSDK=C:\Program Files (x86)\Windows Kits\10
set WINSDK_VER=10.0.22621.0

REM WDK paths (for driver development)
set WDK=%WINSDK%
set WDK_VER=%WINSDK_VER%

REM Visual Studio paths (for vcvarsall.bat)
set VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community

REM Framework root (auto-detected from script location)
set FRAMEWORK_ROOT=%~dp0..

REM Include paths
set CORE_INC=%FRAMEWORK_ROOT%\core
set LIB_INC=%FRAMEWORK_ROOT%\lib

REM Debug settings
set DEBUG_FLAGS=/Zi /DEBUG
set RELEASE_FLAGS=/O2

REM Default debugger
set DEBUGGER=windbg

REM Output settings
set OBJ_DIR=obj
set BIN_DIR=bin

