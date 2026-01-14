# MASM64 Framework Suite

A comprehensive, production-ready MASM64 development framework that eliminates the steep learning curve and common pitfalls of x64 Windows assembly development.

## Features

- **Core Layer**: ABI-compliant calling conventions, stack management, and essential macros
- **Library Layer**: Reusable Win32/NT API wrappers (registry, services, filesystem, elevation, COM)
- **Template Layer**: Ready-to-use project scaffolds for console, GUI, DLL, driver, and shellcode
- **Tooling Layer**: Batch scripts for building, testing, debugging, and project creation

## Requirements

- Windows 10/11 x64
- UASM or ML64 (MASM) assembler
- Windows SDK (for link.exe, rc.exe, and libraries)
- Visual Studio Build Tools (optional, for vcvarsall.bat)

## Quick Start

```batch
REM Create a new console application
tools\new-project.bat MyApp console C:\Projects

REM Build the project
cd C:\Projects\MyApp
build.bat

REM Run with debugging
..\masm64-framework\tools\debug.bat bin\MyApp.exe
```

## Directory Structure

```
masm64-framework/
    core/                   # Core includes (ABI, stack, macros)
        abi64.inc
        stack64.inc
        macros64.inc
    lib/                    # Reusable libraries
        error64/
        string64/
        memory64/
        registry64/
        filesys64/
        elevation64/
        services64/
        com64/
    templates/              # Project templates
        console/
        gui/
        dll/
        driver/
        shellcode/
    tools/                  # Batch build tooling
        build.bat
        new-project.bat
        test.bat
        debug.bat
        config.bat
    examples/               # Example projects
    tests/                  # Framework tests
```

## x64 Calling Convention Reference

The framework enforces Microsoft x64 ABI compliance:

| Register | Status | Purpose |
|----------|--------|---------|
| RAX | Volatile | Return value |
| RCX | Volatile | 1st integer argument |
| RDX | Volatile | 2nd integer argument |
| R8 | Volatile | 3rd integer argument |
| R9 | Volatile | 4th integer argument |
| R10-R11 | Volatile | Caller-saved scratch |
| RBX, RBP, RDI, RSI | Non-volatile | Callee-saved |
| R12-R15 | Non-volatile | Callee-saved |
| XMM0-XMM5 | Volatile | FP args and scratch |
| XMM6-XMM15 | Non-volatile | Callee-saved |

### Stack Requirements

- 16-byte alignment before CALL instruction
- 32-byte shadow space (home space) for register parameters
- RSP must be 16-byte aligned in function body (after prologue)

## License

MIT License - See LICENSE file for details.

## Contributing

Contributions welcome. Please follow the coding conventions established in the codebase.
