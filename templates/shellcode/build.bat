@echo off
setlocal

REM -----------------------------------------------------------------------------
REM Shellcode Build Script
REM -----------------------------------------------------------------------------

set PROJECT_NAME=MyShellcode

if not exist obj mkdir obj
if not exist bin mkdir bin

echo Building %PROJECT_NAME%...

echo   Assembling...
ml64 /c /nologo /Fo obj\main.obj main.asm
if errorlevel 1 goto :error

echo   Linking...
link /nologo /SUBSYSTEM:CONSOLE /ENTRY:ShellcodeEntry /NODEFAULTLIB ^
    /FIXED /BASE:0 ^
    /SECTION:.text,RWE ^
    /MERGE:.rdata=.text /MERGE:.data=.text ^
    /OUT:bin\%PROJECT_NAME%.exe ^
    obj\main.obj
if errorlevel 1 goto :error

echo.
echo Build successful: bin\%PROJECT_NAME%.exe
echo.
echo To extract raw shellcode:
echo   Use dumpbin /headers to find .text section
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
endlocal
