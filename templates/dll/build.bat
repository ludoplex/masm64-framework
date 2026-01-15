@echo off
setlocal

REM -----------------------------------------------------------------------------
REM DLL Build Script
REM -----------------------------------------------------------------------------

set PROJECT_NAME=MyLib

if not exist obj mkdir obj
if not exist bin mkdir bin

echo Building %PROJECT_NAME%...

echo   Assembling...
ml64 /c /nologo /Zi /Fo obj\main.obj main.asm
if errorlevel 1 goto :error

echo   Linking DLL...
link /nologo /DLL /ENTRY:DllMain /DEF:exports.def /DEBUG ^
    /OUT:bin\%PROJECT_NAME%.dll ^
    /IMPLIB:bin\%PROJECT_NAME%.lib ^
    obj\main.obj ^
    kernel32.lib
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
