# x64 ABI Reference for MASM64

## Calling Convention (Microsoft x64)

### Register Usage

| Register | Status | Purpose |
|----------|--------|---------|
| RAX | Volatile | Return value, scratch |
| RCX | Volatile | 1st integer argument |
| RDX | Volatile | 2nd integer argument |
| R8 | Volatile | 3rd integer argument |
| R9 | Volatile | 4th integer argument |
| R10-R11 | Volatile | Scratch registers |
| RBX | Non-volatile | Must be preserved |
| RBP | Non-volatile | Frame pointer (optional) |
| RDI | Non-volatile | Must be preserved |
| RSI | Non-volatile | Must be preserved |
| R12-R15 | Non-volatile | Must be preserved |
| XMM0-XMM3 | Volatile | FP arguments 1-4 |
| XMM4-XMM5 | Volatile | Scratch |
| XMM6-XMM15 | Non-volatile | Must be preserved |

### Shadow Space (Home Space)

**Always allocate 32 bytes (4 * 8) of shadow space before any CALL instruction.**

This space is for the callee to spill register arguments if needed.

```asm
sub rsp, 32                     ; Allocate shadow space
call SomeFunction
add rsp, 32                     ; Clean up
```

### Stack Alignment

**Stack must be 16-byte aligned at the point of CALL instruction.**

After CALL pushes the return address, RSP is 8 mod 16.
Your prologue must account for this.

### Prologue Pattern

```asm
MyFunction PROC FRAME
    push rbp                    ; 8 bytes - now RSP is 0 mod 16
    .pushreg rbp
    sub rsp, 48                 ; Shadow(32) + locals(16)
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    ; RSP is now 0 mod 16
    ; RBP points past shadow space to locals
    
    ; ... function body ...
    
    add rsp, 48
    pop rbp
    ret
MyFunction ENDP
```

### Argument Passing

**Integer/Pointer Arguments:**
- Arg 1: RCX
- Arg 2: RDX
- Arg 3: R8
- Arg 4: R9
- Arg 5+: Stack (at [RSP+32] after shadow space)

**Floating-Point Arguments:**
- Arg 1: XMM0
- Arg 2: XMM1
- Arg 3: XMM2
- Arg 4: XMM3
- Arg 5+: Stack

**Mixed Arguments:**
If argument 1 is integer and argument 2 is float:
- Arg 1: RCX (not XMM0)
- Arg 2: XMM1 (not XMM0 or RDX)

The position determines the register, not the type.

### Return Values

- Integer/pointer: RAX
- Floating-point: XMM0
- Structures <= 8 bytes: RAX
- Structures > 8 bytes: Caller passes hidden first argument

### Stack Frame Layout

```
High addresses
+------------------+
| Arg N (if > 4)   |  [RSP + 32 + (N-5)*8] after prologue
+------------------+
| ...              |
+------------------+
| Arg 5            |  [RSP + 32 + 0]
+------------------+
| Shadow R9        |  [RSP + 24] (for callee's use)
+------------------+
| Shadow R8        |  [RSP + 16]
+------------------+
| Shadow RDX       |  [RSP + 8]
+------------------+
| Shadow RCX       |  [RSP + 0]
+------------------+
| Return Address   |  <- RSP at function entry
+------------------+
| Saved RBP        |  <- After push rbp
+------------------+
| Local Variables  |  <- After sub rsp, N
+------------------+
Low addresses
```

### Common Pitfalls

1. **Forgetting Shadow Space**
   ```asm
   ; WRONG
   call MessageBoxW
   
   ; CORRECT
   sub rsp, 32
   call MessageBoxW
   add rsp, 32
   ```

2. **Misaligned Stack**
   ```asm
   ; WRONG - RSP is 8 mod 16 after entry
   sub rsp, 40          ; Now 8+40=48, which is 0 mod 16
   call Foo
   
   ; CORRECT
   sub rsp, 40          ; 8 (ret) + 40 = 48 = 0 mod 16
   call Foo
   ```

3. **Not Preserving Non-volatile Registers**
   ```asm
   ; WRONG
   mov rbx, rax         ; Using RBX without saving
   
   ; CORRECT
   push rbx
   mov rbx, rax
   ; ... use rbx ...
   pop rbx
   ```

4. **Wrong Argument Register Order**
   ```asm
   ; WRONG - Loading RCX last clobbers it for address calculation
   lea rcx, [rdx + rsi]
   mov rdx, rdi
   
   ; CORRECT - Load in reverse order
   mov rdx, rdi
   lea rcx, [rdx + rsi]  ; RDX already set, use original value
   ```

### Leaf Functions

Functions that:
- Don't call other functions
- Don't modify non-volatile registers
- Don't allocate stack space

Can skip the FRAME directive:

```asm
LeafAdd PROC
    mov rax, rcx
    add rax, rdx
    ret
LeafAdd ENDP
```

### Exception Handling (.xdata/.pdata)

The `.pushreg`, `.allocstack`, `.setframe`, and `.endprolog` directives generate unwind information for proper exception handling and stack walking.

Always use PROC FRAME for functions that:
- Call other functions
- Modify the stack pointer
- Use non-volatile registers

