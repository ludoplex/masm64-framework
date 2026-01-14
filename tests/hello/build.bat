@echo off
set UASM=uasm64.exe
set LINK=link.exe

if not exist obj mkdir obj
if not exist bin mkdir bin

%UASM% /c /Cp /W2 /Zp8 /win64 /I"..\..\core" /Fo"obj\main.obj" main.asm
if errorlevel 1 exit /b 1

%LINK% /SUBSYSTEM:CONSOLE /ENTRY:WinMain /OUT:bin\hello.exe obj\main.obj kernel32.lib
if errorlevel 1 exit /b 1

echo Build successful

