# Contributing to MASM64 Framework

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Ways to Contribute

- **Report bugs** - Open an issue describing the problem
- **Request features** - Open an issue with the enhancement label
- **Submit fixes** - Fork, fix, and submit a pull request
- **Improve documentation** - Help make the docs clearer
- **Write tests** - Expand test coverage

## Development Setup

1. **Fork and clone the repository**
   ```batch
   git clone https://github.com/YOUR_USERNAME/masm64-framework.git
   cd masm64-framework
   ```

2. **Install requirements**
   - UASM or ML64 assembler
   - Windows SDK
   - (Optional) WinDbg for debugging

3. **Build and test**
   ```batch
   cd tests\framework
   build.bat
   ```

## Code Style

- Use descriptive labels and comments
- Follow x64 ABI conventions
- Include header comments in all files
- Use PROC FRAME for functions that make calls
- Maintain 16-byte stack alignment

## Pull Request Process

1. Create a feature branch from `master`
2. Make your changes with clear commit messages
3. Add or update tests as needed
4. Update documentation if applicable
5. Submit a pull request

## Questions?

Open a discussion on GitHub if you have questions about contributing.

