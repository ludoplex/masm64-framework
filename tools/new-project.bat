@echo off
setlocal enabledelayedexpansion

REM -----------------------------------------------------------------------------
REM MASM64 Framework Project Generator
REM -----------------------------------------------------------------------------
REM Usage: new-project.bat <project_name> <template> [output_path]
REM
REM Templates: console, gui, dll, driver, shellcode
REM
REM Examples:
REM   new-project.bat MyApp console
REM   new-project.bat MyLib dll C:\Projects
REM -----------------------------------------------------------------------------

set FRAMEWORK_ROOT=%~dp0..
set TEMPLATES_DIR=%FRAMEWORK_ROOT%\templates

REM Check arguments
if "%~1"=="" (
    echo Usage: new-project.bat ^<project_name^> ^<template^> [output_path]
    echo.
    echo Templates:
    echo   console   - Console application
    echo   gui       - Win32 GUI application
    echo   dll       - Dynamic link library
    echo   driver    - Kernel mode driver
    echo   shellcode - Position-independent shellcode
    echo.
    echo Example:
    echo   new-project.bat MyApp console C:\Projects
    exit /b 1
)

set PROJECT_NAME=%~1
set TEMPLATE=%~2
set OUTPUT_PATH=%~3

REM Default output path to current directory
if "%OUTPUT_PATH%"=="" set OUTPUT_PATH=%CD%

REM Validate template
if not exist "%TEMPLATES_DIR%\%TEMPLATE%" (
    echo Error: Unknown template '%TEMPLATE%'
    echo.
    echo Available templates:
    for /d %%d in ("%TEMPLATES_DIR%\*") do echo   %%~nd
    exit /b 1
)

REM Create project directory
set PROJECT_DIR=%OUTPUT_PATH%\%PROJECT_NAME%

if exist "%PROJECT_DIR%" (
    echo Error: Directory already exists: %PROJECT_DIR%
    exit /b 1
)

echo Creating project: %PROJECT_NAME%
echo Template: %TEMPLATE%
echo Location: %PROJECT_DIR%
echo.

mkdir "%PROJECT_DIR%"
if errorlevel 1 (
    echo Error: Failed to create project directory
    exit /b 1
)

REM Copy template files
echo Copying template files...
xcopy /e /i /q "%TEMPLATES_DIR%\%TEMPLATE%\*" "%PROJECT_DIR%\"

REM Create standard directories
mkdir "%PROJECT_DIR%\obj" 2>nul
mkdir "%PROJECT_DIR%\bin" 2>nul
mkdir "%PROJECT_DIR%\res" 2>nul

REM Get current date
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set "dt=%%a"
set CURRENT_DATE=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%

REM Replace placeholders in files
echo Configuring project...

for /r "%PROJECT_DIR%" %%f in (*.asm *.inc *.bat *.json *.def) do (
    if exist "%%f" (
        REM Create temp file with replacements
        (
            for /f "usebackq delims=" %%l in ("%%f") do (
                set "line=%%l"
                set "line=!line:{{PROJECT_NAME}}=%PROJECT_NAME%!"
                set "line=!line:{{AUTHOR}}=%USERNAME%!"
                set "line=!line:{{DATE}}=%CURRENT_DATE%!"
                echo(!line!
            )
        ) > "%%f.tmp"
        move /y "%%f.tmp" "%%f" >nul
    )
)

echo.
echo ========================================
echo Project created successfully!
echo ========================================
echo.
echo Location: %PROJECT_DIR%
echo.
echo Next steps:
echo   1. cd "%PROJECT_DIR%"
echo   2. Edit main.asm to add your code
echo   3. Run build.bat to compile
echo.
if "%TEMPLATE%"=="driver" (
    echo NOTE: Driver development requires WDK and test signing.
)
if "%TEMPLATE%"=="shellcode" (
    echo NOTE: Use extract.py to get raw shellcode bytes.
)

endlocal

