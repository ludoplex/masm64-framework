@echo off
setlocal enabledelayedexpansion

REM -----------------------------------------------------------------------------
REM DLL Build Script
REM -----------------------------------------------------------------------------

set PROJECT_NAME={{PROJECT_NAME}}
set ASM_FILES=main.asm

set UASM=uasm64.exe
set LINK=link.exe

set INCPATH=/I"%~dp0..\..\core" /I"%~dp0..\..\lib"
set LIBS=kernel32.lib

if not exist obj mkdir obj
if not exist bin mkdir bin

REM Assemble
echo Assembling %PROJECT_NAME%...
for %%f in (%ASM_FILES%) do (
    echo   %%f
    %UASM% /c /Cp /W2 /Zp8 /win64 %INCPATH% /Fo"obj\%%~nf.obj" "%%f"
    if errorlevel 1 goto :error
)

REM Link as DLL
echo Linking DLL...
%LINK% /DLL /ENTRY:DllMain /DEF:exports.def /OUT:bin\%PROJECT_NAME%.dll ^
    /IMPLIB:bin\%PROJECT_NAME%.lib obj\*.obj %LIBS%
if errorlevel 1 goto :error

echo.
echo Build successful:
echo   DLL: bin\%PROJECT_NAME%.dll
echo   LIB: bin\%PROJECT_NAME%.lib
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
endlocal

