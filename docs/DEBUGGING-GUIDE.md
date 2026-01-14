# MASM64 Debugging Guide

This guide covers debugging techniques for MASM64 applications.

## Debugger Options

### WinDbg (Recommended)

The most powerful option for low-level Windows debugging.

```batch
REM Launch with application
tools\debug.bat bin\myapp.exe /windbg

REM Attach to running process
tools\debug.bat myapp.exe /windbg /attach
```

### x64dbg

User-friendly GUI debugger with good assembly support.

```batch
tools\debug.bat bin\myapp.exe /x64dbg
```

### Visual Studio

Familiar IDE-based debugging.

```batch
tools\debug.bat bin\myapp.exe /vs
```

## Common Issues and Solutions

### 1. Access Violation (0xC0000005)

**Symptoms:**
- Crash on memory access
- "Access violation reading/writing location 0x..."

**Common Causes:**
1. NULL pointer dereference
2. Stack buffer overflow
3. Uninitialized pointer
4. Use after free

**Debugging Steps:**
```
$$ In WinDbg
!analyze -v
r                           ; Check registers
dq @rsp L10                 ; Check stack
```

### 2. Stack Misalignment Crash

**Symptoms:**
- Crash in API calls (especially SSE functions)
- Works sometimes, fails randomly

**Cause:**
RSP not 16-byte aligned before CALL instruction.

**Fix:**
```asm
; WRONG
MyFunc PROC
    sub rsp, 24             ; Incorrect alignment
    call SomeAPI            ; May crash!
    add rsp, 24
    ret
MyFunc ENDP

; CORRECT
MyFunc PROC FRAME
    sub rsp, 40             ; 8 (ret) + 40 = 48, which is 0 mod 16
    .allocstack 40
    .endprolog
    call SomeAPI
    add rsp, 40
    ret
MyFunc ENDP
```

**Debug Check:**
```
$$ In WinDbg
? @rsp & 0xf               ; Should be 0
```

### 3. Corrupted Return Address

**Symptoms:**
- Random crash after RET
- RIP points to garbage

**Common Causes:**
1. Stack buffer overflow
2. Wrong stack adjustment in epilogue
3. Mismatched PUSH/POP

**Debugging:**
```
$$ Check return address
dps @rsp L1

$$ Set breakpoint on RET
bp mymodule!MyFunc+0x?? "dps @rsp L1; g"
```

### 4. Wrong Parameter Passing

**Symptoms:**
- API returns unexpected errors
- Data corruption

**Debug:**
```
$$ In WinDbg, before CALL
.printf "RCX=%p RDX=%p R8=%p R9=%p\n", @rcx, @rdx, @r8, @r9
```

## MASM64 WinDbg Scripts

Load the provided scripts:

```
$$>a< tools\windbg\masm64.wds
```

Available commands:
- `masm64_regs` - Show all registers
- `masm64_stackcheck` - Verify alignment
- `masm64_shadow` - Display shadow space
- `masm64_args` - Show function arguments

## Building with Debug Symbols

```batch
build.bat /debug
```

This adds `/Zi` for assembler and `/DEBUG` for linker.

## Crash Dump Analysis

### Creating Dumps

1. **Automatic (Windows Error Reporting)**
   - Configure in registry or via Task Manager

2. **Manual**
   ```
   .dump /ma C:\dumps\crash.dmp
   ```

### Analyzing Dumps

```batch
windbg -z C:\dumps\crash.dmp
```

Then run:
```
$$>a< tools\windbg\analyze-crash.wds
```

## Performance Profiling

### Using WPR/WPA

```batch
REM Start recording
wpr -start CPU

REM Run your application
bin\myapp.exe

REM Stop and analyze
wpr -stop trace.etl
wpa trace.etl
```

### Instruction Counting

In WinDbg:
```
wt -l 3 -oR mymodule!MyFunction
```

## Memory Analysis

### Heap Corruption

Enable page heap:
```batch
gflags /p /enable myapp.exe /full
```

### Memory Leaks

In WinDbg:
```
!heap -l
```

## Best Practices

1. **Always build debug version first**
   - Symbols make debugging much easier

2. **Use assertions liberally**
   - Catch bugs early

3. **Check return values**
   - Don't ignore error codes

4. **Validate inputs**
   - Use REQUIRE macros for function preconditions

5. **Test edge cases**
   - Empty strings, NULL pointers, max values

6. **Run under debugger during development**
   - Catches issues immediately

