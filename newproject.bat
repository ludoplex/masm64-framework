@echo off
setlocal

REM -----------------------------------------------------------------------------
REM MASM64 Framework - New Project Scaffolding
REM -----------------------------------------------------------------------------
REM Creates a new project from a template
REM
REM Usage: newproject.bat <template> <project_name> [destination]
REM
REM Templates: console, gui, dll, driver, shellcode
REM
REM Examples:
REM   newproject.bat console MyApp
REM   newproject.bat gui MyWindow C:\Projects
REM   newproject.bat dll MyLibrary ..\libs
REM -----------------------------------------------------------------------------

if "%~1"=="" goto :usage
if "%~2"=="" goto :usage

set TEMPLATE=%~1
set PROJECT=%~2
set DEST=%~3

REM Default destination is current directory
if "%DEST%"=="" set DEST=.

REM Validate template exists
if not exist "%~dp0templates\%TEMPLATE%" (
    echo ERROR: Template '%TEMPLATE%' not found.
    echo.
    echo Available templates:
    for /d %%t in ("%~dp0templates\*") do echo   %%~nxt
    exit /b 1
)

REM Create destination directory
set TARGET=%DEST%\%PROJECT%
if exist "%TARGET%" (
    echo ERROR: Directory '%TARGET%' already exists.
    exit /b 1
)

echo Creating project '%PROJECT%' from template '%TEMPLATE%'...
echo.

REM Copy template files
xcopy /E /I /Q "%~dp0templates\%TEMPLATE%" "%TARGET%"
if errorlevel 1 (
    echo ERROR: Failed to copy template files.
    exit /b 1
)

echo.
echo Project created successfully: %TARGET%
echo.
echo Next steps:
echo   1. cd %TARGET%
echo   2. Edit config.inc to customize your project
echo   3. Run build.bat to compile
echo.
goto :end

:usage
echo MASM64 Framework - New Project
echo.
echo Usage: newproject.bat ^<template^> ^<project_name^> [destination]
echo.
echo Templates:
echo   console   - Console application
echo   gui       - Win32 GUI application
echo   dll       - Dynamic link library
echo   driver    - Kernel mode driver (requires WDK)
echo   shellcode - Position-independent shellcode
echo.
echo Examples:
echo   newproject.bat console MyApp
echo   newproject.bat gui MyWindow C:\Projects
echo.
exit /b 1

:end
endlocal

