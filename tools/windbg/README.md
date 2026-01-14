# MASM64 WinDbg Extensions

This directory contains WinDbg scripts for debugging MASM64 applications.

## Loading Scripts

In WinDbg, load a script using:

```
$$>a< C:\path\to\masm64-framework\tools\windbg\masm64.wds
```

Or add to your WinDbg startup script.

## Available Scripts

### masm64.wds

General-purpose debugging commands for MASM64 code.

**Commands:**
- `masm64_regs` - Display all general-purpose registers
- `masm64_stackcheck` - Check 16-byte stack alignment
- `masm64_shadow` - Display shadow space contents
- `masm64_args` - Display function arguments (RCX, RDX, R8, R9)
- `masm64_nonvol` - Display non-volatile registers
- `masm64_trace` - Trace function calls
- `masm64_bpapi` - Set breakpoints on common Win32 APIs
- `masm64_help` - Show command help

### analyze-crash.wds

Crash dump analysis with MASM64-specific insights.

**Usage:**
```
$$>a< analyze-crash.wds
```

**Provides:**
- Standard crash analysis (`!analyze -v`)
- Stack alignment check
- Shadow space contents
- Access violation analysis
- Return address validation
- Disassembly around crash point
- Common issues checklist

## Common MASM64 Bugs Detected

1. **Stack Misalignment**
   - RSP must be 16-byte aligned before CALL instructions
   - The scripts check `RSP mod 16`

2. **Missing Shadow Space**
   - Every CALL requires 32 bytes of shadow space
   - Scripts display shadow space for inspection

3. **Clobbered Non-volatile Registers**
   - RBX, RBP, RDI, RSI, R12-R15 must be preserved
   - Compare values before/after function calls

4. **Invalid Pointers**
   - NULL pointer dereferences
   - Stack buffer overflows
   - Use-after-free

## Quick Debugging Tips

```
$$ Set breakpoint on function
bp MyModule!MyFunction

$$ Display arguments when breakpoint hits
bp MyModule!MyFunction "masm64_args; g"

$$ Check alignment before every call
bp MyModule!* "masm64_stackcheck; g"

$$ Trace with call logging
wt -l 3 -oR MyModule!MyFunction
```

