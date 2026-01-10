# MASM64 Framework Suite

A comprehensive, production-ready MASM64 development framework that eliminates the steep learning curve and common pitfalls of x64 Windows assembly development.

## Features

- **Core Layer**: ABI-compliant calling conventions, stack management, and essential macros
- **Library Layer**: Reusable Win32/NT API wrappers (registry, services, filesystem, elevation, COM)
- **Template Layer**: Ready-to-use project scaffolds for console, GUI, DLL, driver, and shellcode
- **Tooling Layer**: Batch scripts for building, testing, debugging, and project creation

## Quick Start

```batch
REM Create a new console application
tools\new-project.bat MyApp console C:\Projects

REM Build
cd C:\Projects\MyApp
build.bat
```

## Requirements

- Windows 10/11 x64
- UASM or ML64 (MASM) assembler
- Windows SDK (for link.exe and libraries)

## Documentation

- [Quick Start Guide](docs/QUICKSTART.md)
- [ABI Reference](docs/ABI-REFERENCE.md)
- [Debugging Guide](docs/DEBUGGING-GUIDE.md)

## Project Structure

```
masm64-framework/
  core/           # Core includes (ABI, stack, macros)
  lib/            # Reusable libraries
    assert64/     # Enhanced assertions
    arena64/      # Arena allocator
    branchless64/ # Branchless operations
    error64/      # Error handling
    string64/     # String manipulation
    memory64/     # Memory management
    registry64/   # Registry operations
    filesys64/    # Filesystem operations
    elevation64/  # UAC/privilege management
    services64/   # Service control
    com64/        # COM interfaces
    test64/       # Unit testing framework
  templates/      # Project templates
    console/      # Console application
    gui/          # Win32 GUI application
    dll/          # Dynamic link library
    driver/       # Kernel driver
    shellcode/    # Position-independent code
  tools/          # Build and utility scripts
  tests/          # Framework tests
  docs/           # Documentation
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

