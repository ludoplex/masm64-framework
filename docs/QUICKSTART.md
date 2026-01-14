# MASM64 Framework Quick Start Guide

## Prerequisites

1. **UASM Assembler** (recommended) or ML64
   - Download UASM from: http://www.terraspace.co.uk/uasm.html
   - Add to system PATH

2. **Microsoft Linker** (link.exe)
   - Included with Visual Studio Build Tools
   - Or Windows SDK

3. **Windows SDK**
   - For libraries (kernel32.lib, user32.lib, etc.)

## Creating Your First Project

### Option 1: Using the Project Generator

```batch
cd masm64-framework\tools
new-project.bat MyFirstApp console C:\Projects
cd C:\Projects\MyFirstApp
build.bat
bin\MyFirstApp.exe
```

### Option 2: Manual Setup

1. Create project directory
2. Copy template files from `templates\console`
3. Edit `main.asm` with your code
4. Run `build.bat`

## Project Structure

```
MyProject/
    main.asm          # Main source file
    build.bat         # Build script
    project.json      # Project configuration
    obj/              # Object files (generated)
    bin/              # Output binaries (generated)
    res/              # Resources (optional)
```

## Basic Code Structure

```asm
OPTION CASEMAP:NONE

; Include framework core
INCLUDE \masm64-framework\core\abi64.inc
INCLUDE \masm64-framework\core\stack64.inc
INCLUDE \masm64-framework\core\macros64.inc

; Declare external APIs
EXTERNDEF MessageBoxW:PROC
EXTERNDEF ExitProcess:PROC

.DATA
WSTR szTitle, "Hello"
WSTR szMessage, "Hello from MASM64!"

.CODE

WinMain PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    ; MessageBoxW(NULL, message, title, MB_OK)
    xor ecx, ecx
    lea rdx, szMessage
    lea r8, szTitle
    xor r9d, r9d
    call MessageBoxW
    
    xor ecx, ecx
    call ExitProcess
    
    add rsp, 40
    ret
WinMain ENDP

END
```

## Common Tasks

### Calling Windows API

```asm
; 4 or fewer arguments: use registers
; RCX = arg1, RDX = arg2, R8 = arg3, R9 = arg4

sub rsp, 32                     ; Shadow space
mov rcx, arg1
mov rdx, arg2
mov r8, arg3
mov r9, arg4
call SomeFunction
add rsp, 32
```

### Using Framework Libraries

```asm
INCLUDE \masm64-framework\lib\string64\string64.inc

.CODE
    lea rcx, szMyString
    call Str_LenW
    ; RAX = string length
```

### Proper Stack Frame

```asm
MyFunction PROC FRAME
    push rbp
    .pushreg rbp
    sub rsp, 48                 ; Shadow(32) + locals + alignment
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    ; Your code here
    
    add rsp, 48
    pop rbp
    ret
MyFunction ENDP
```

## Building

### Debug Build

```batch
build.bat /debug
```

### Release Build

```batch
build.bat /release
```

### Clean and Rebuild

```batch
build.bat /rebuild
```

## Debugging

```batch
..\masm64-framework\tools\debug.bat bin\MyApp.exe
```

## Next Steps

1. Explore `templates/` for different project types
2. Review `lib/` for reusable libraries
3. Check `examples/` for working code samples
4. Read function headers in `.inc` files for documentation

