# MASM64 Framework Suite

[![Build and Test](https://github.com/ludoplex/masm64-framework/actions/workflows/build.yml/badge.svg)](https://github.com/ludoplex/masm64-framework/actions/workflows/build.yml)

A comprehensive, production-ready MASM64 development framework that eliminates the steep learning curve and common pitfalls of x64 Windows assembly development.

## Features

- **Core Layer**: ABI-compliant calling conventions, stack management, and essential macros
- **Library Layer**: Reusable Win32/NT API wrappers (registry, services, filesystem, elevation, COM)
- **Template Layer**: Ready-to-use project scaffolds for console, GUI, DLL, driver, and shellcode
- **Tooling Layer**: Batch scripts for building, testing, debugging, and project creation
- **Examples**: Practical utility applications demonstrating each template type

## Quick Start

### Automated Setup

```powershell
# Clone the repository
git clone https://github.com/ludoplex/masm64-framework.git
cd masm64-framework

# Run setup to detect/install development tools
.\tools\setup.ps1
```

The setup script will:
1. Detect Visual Studio / Build Tools and ML64 assembler
2. Check for Windows SDK
3. **Optionally** offer to install Windows Driver Kit (for driver development)
4. Save configuration to `config\environment.json`

### Manual Requirements

| Component | Required For | Download |
|-----------|-------------|----------|
| Visual Studio Build Tools | All builds | [Download](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022) |
| Windows SDK | All builds | Included with VS Build Tools |
| Windows Driver Kit | Driver builds only | [Download](https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk) |

### Build an Example

```batch
cd examples\hashcheck
build.bat
bin\hashcheck.exe somefile.zip
```

## Examples

Practical utilities demonstrating each template type:

| Example | Template | Description |
|---------|----------|-------------|
| `hashcheck` | Console | File integrity verifier (MD5/SHA1/SHA256) |
| `colorpick` | GUI | Screen color picker with Ctrl+Shift+C hotkey |
| `shellex` | DLL | "Copy Path" shell context menu extension |
| `rawmouse` | Driver | Mouse acceleration disabler (requires WDK) |
| `edrtest` | Shellcode | EDR/AV detection audit tool |

## Directory Structure

```
masm64-framework/
    core/                   # Core includes (ABI, stack, macros)
        abi64.inc
        stack64.inc
        macros64.inc
    lib/                    # Reusable libraries
        registry64/
        filesys64/
        elevation64/
        services64/
        ...
    templates/              # Project templates
        console/
        gui/
        dll/
        driver/
        shellcode/
    examples/               # Practical example applications
        hashcheck/          # Console - file hasher
        colorpick/          # GUI - color picker
        shellex/            # DLL - shell extension
        rawmouse/           # Driver - mouse filter
        edrtest/            # Shellcode - EDR testing
    tools/                  # Build tooling
        setup.ps1           # Environment setup script
        build.bat
        new-project.bat
    tests/                  # Framework tests
    docs/                   # Documentation
```

## Creating a New Project

```batch
REM Create from template
tools\new-project.bat MyApp console C:\Projects

REM Build the project
cd C:\Projects\MyApp
build.bat
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

## CI/CD

This repository includes GitHub Actions workflows that:
- Build all usermode examples (hashcheck, colorpick, shellex, edrtest)
- Build driver example with WDK (rawmouse)
- Test all templates
- Create releases on version tags

## Use as Template

Click **"Use this template"** on GitHub to create a new repository with this framework as a starting point.

## License

MIT License - See LICENSE file for details.

## Contributing

Contributions welcome! Please:
1. Follow the x64 ABI conventions documented in `docs/ABI-REFERENCE.md`
2. Test with both ML64 and UASM where possible
3. Use the provided issue/PR templates
