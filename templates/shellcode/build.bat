@echo off
setlocal enabledelayedexpansion

REM -----------------------------------------------------------------------------
REM Shellcode Build Script
REM -----------------------------------------------------------------------------
REM Builds position-independent shellcode and extracts raw bytes
REM -----------------------------------------------------------------------------

set PROJECT_NAME={{PROJECT_NAME}}
set ASM_FILES=main.asm

set UASM=uasm64.exe
set LINK=link.exe

if not exist obj mkdir obj
if not exist bin mkdir bin

REM Assemble
echo Assembling %PROJECT_NAME%...
%UASM% /c /Cp /W2 /Zp8 /win64 /Fo"obj\main.obj" main.asm
if errorlevel 1 goto :error

REM Link as raw binary (no imports)
echo Linking...
%LINK% /SUBSYSTEM:CONSOLE /ENTRY:ShellcodeEntry /NODEFAULTLIB ^
    /FIXED /BASE:0 /SECTION:.text,RWE /MERGE:.rdata=.text /MERGE:.data=.text ^
    /OUT:bin\%PROJECT_NAME%.exe obj\main.obj
if errorlevel 1 goto :error

REM Extract .text section as raw shellcode
echo Extracting shellcode...
REM Note: Use a tool like objcopy or custom extractor
REM For now, create a placeholder script

echo.
echo Build successful:
echo   EXE: bin\%PROJECT_NAME%.exe
echo.
echo To extract raw shellcode bytes:
echo   1. Use objdump or dumpbin to find .text section offset/size
echo   2. Extract bytes with: certutil -encodehex bin\%PROJECT_NAME%.exe bin\shellcode.hex
echo   3. Or use Python: open('bin\shellcode.bin','wb').write(pe.sections[0].get_data())
goto :end

:error
echo.
echo Build failed!
exit /b 1

:end
endlocal

