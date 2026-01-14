# Contributing to MASM64 Framework

Thank you for your interest in contributing to the MASM64 Framework.

## Development Workflow

### Prerequisites

1. **UASM Assembler** (preferred) or ML64
   - UASM: http://www.terraspace.co.uk/uasm.html
   - ML64: Part of Visual Studio

2. **Windows SDK**
   - For linker and libraries

3. **WinDbg** (for debugging)
   - Install from Windows SDK or Microsoft Store (WinDbg Preview)

### Setting Up

```batch
REM Clone the repository
git clone https://github.com/your-org/masm64-framework.git
cd masm64-framework

REM Build the framework tests
cd tests\framework
build.bat

REM Run tests
bin\run-tests.exe
```

### Code Style

1. **File Headers**
   - Every `.asm` and `.inc` file must have a header comment block
   - Include file name, purpose, and usage notes

2. **Naming Conventions**
   - Functions: `PascalCase` (e.g., `Arena_Alloc`)
   - Macros: `UPPER_SNAKE_CASE` (e.g., `ASSERT_NOT_NULL`)
   - Constants: `UPPER_SNAKE_CASE`
   - Local labels: Use `@@:` for simple jumps or `meaningful_name:`
   - Global data: `g_` prefix (e.g., `g_hInstance`)

3. **Stack Frames**
   - Always use `PROC FRAME` for functions that call others
   - Include proper `.pushreg`, `.allocstack`, `.setframe` directives
   - Maintain 16-byte stack alignment

4. **Comments**
   - Document function parameters and return values
   - Explain non-obvious algorithms
   - Use `;` for comments, `;;` for disabled code

### Testing

1. **Write tests for new functionality**
   - Add test cases to `tests/framework/run-tests.asm`
   - Use the `TEST_ASSERT_*` macros

2. **Run tests before submitting**
   ```batch
   cd tests\framework
   build.bat
   ```

3. **All tests must pass**
   - CI will reject PRs with failing tests

### Pull Request Process

1. **Fork the repository**

2. **Create a feature branch**
   ```batch
   git checkout -b feature/my-new-feature
   ```

3. **Make your changes**
   - Follow code style guidelines
   - Add tests for new features
   - Update documentation if needed

4. **Run tests locally**
   ```batch
   tools\test.bat /all
   ```

5. **Commit with descriptive messages**
   ```batch
   git commit -m "Add Arena_AllocAligned for cache-line alignment"
   ```

6. **Push and create PR**
   ```batch
   git push origin feature/my-new-feature
   ```

7. **Respond to review feedback**

### CI/CD Pipeline

The project uses GitHub Actions for CI:

- **Build**: Compiles all templates and tests
- **Test**: Runs unit tests
- **Package**: Creates release archives (on main branch)

PRs must pass all CI checks before merging.

### Release Process

1. Version updates are managed via tags
2. Release notes should document:
   - New features
   - Breaking changes
   - Bug fixes
   - Migration instructions (if needed)

## Areas for Contribution

### High Priority

- Additional library modules (networking, crypto, threading)
- More comprehensive test coverage
- Documentation improvements
- Bug fixes for edge cases

### Nice to Have

- Performance optimizations
- Additional templates (service, COM server)
- IDE integration (VS Code extension)
- Tutorials and examples

## Getting Help

- Open an issue for bugs or feature requests
- Use discussions for questions
- Tag maintainers for urgent issues

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

