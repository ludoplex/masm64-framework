;-----------------------------------------------------------------------------
; stack64.inc - Stack Frame Management Utilities
;-----------------------------------------------------------------------------
; Provides macros for proper x64 stack frame setup and teardown.
;
; Stack Layout After PROLOGUE:
;   [rbp + 28h] = 5th argument (if any)
;   [rbp + 20h] = R9 home (shadow space)
;   [rbp + 18h] = R8 home (shadow space)
;   [rbp + 10h] = RDX home (shadow space)
;   [rbp + 08h] = RCX home (shadow space)
;   [rbp + 00h] = Return address
;   [rbp - 08h] = Saved RBP
;   [rbp - xxh] = Local variables
;-----------------------------------------------------------------------------

IFNDEF STACK64_INC
STACK64_INC EQU 1

INCLUDE abi64.inc

;-----------------------------------------------------------------------------
; PROLOGUE - Set up stack frame
;-----------------------------------------------------------------------------
; Parameters:
;   num_saved_regs - Number of non-volatile registers to save (0-7)
;   local_space    - Bytes for local variables (will be aligned to 16)
;
; Automatically:
;   - Pushes RBP and sets frame pointer
;   - Allocates shadow space (32 bytes)
;   - Allocates local variable space (aligned)
;   - Generates proper .PUSHREG, .ALLOCSTACK, .SETFRAME directives
;-----------------------------------------------------------------------------
PROLOGUE MACRO num_saved_regs:=<0>, local_space:=<0>
    LOCAL total_alloc
    
    push rbp
    .pushreg rbp
    
    ;; Calculate total stack allocation
    ;; Need: shadow(32) + locals + padding for 16-byte alignment
    ;; After push rbp, RSP is 8 mod 16. We need it 0 mod 16 before calls.
    ;; push rbp used 8 bytes, so we need to allocate 8 + 32 + locals (rounded up)
    
    total_alloc = SHADOW_SPACE + local_space
    IF (total_alloc MOD 16) NE 8
        total_alloc = total_alloc + 8
    ENDIF
    
    sub rsp, total_alloc
    .allocstack total_alloc
    
    lea rbp, [rsp + SHADOW_SPACE]
    .setframe rbp, SHADOW_SPACE
    .endprolog
ENDM

;-----------------------------------------------------------------------------
; EPILOGUE - Tear down stack frame
;-----------------------------------------------------------------------------
; Restores RBP and RSP to their original values.
;-----------------------------------------------------------------------------
EPILOGUE MACRO
    lea rsp, [rbp - SHADOW_SPACE + SHADOW_SPACE]
    add rsp, 8                              ; Account for frame difference
    pop rbp
ENDM

;-----------------------------------------------------------------------------
; SAVE_NONVOL - Save non-volatile registers
;-----------------------------------------------------------------------------
; Use at start of function after PROLOGUE to save registers you'll modify.
;-----------------------------------------------------------------------------
SAVE_NONVOL MACRO regs:VARARG
    LOCAL offset
    offset = 0
    FOR reg, <regs>
        mov [rbp - SHADOW_SPACE - 8 - offset], reg
        offset = offset + 8
    ENDM
ENDM

;-----------------------------------------------------------------------------
; RESTORE_NONVOL - Restore non-volatile registers
;-----------------------------------------------------------------------------
; Use at end of function before EPILOGUE to restore saved registers.
;-----------------------------------------------------------------------------
RESTORE_NONVOL MACRO regs:VARARG
    LOCAL offset
    offset = 0
    FOR reg, <regs>
        mov reg, [rbp - SHADOW_SPACE - 8 - offset]
        offset = offset + 8
    ENDM
ENDM

;-----------------------------------------------------------------------------
; ALIGN_STACK - Ensure stack is 16-byte aligned
;-----------------------------------------------------------------------------
; Use before making calls when stack alignment is uncertain.
;-----------------------------------------------------------------------------
ALIGN_STACK MACRO
    and rsp, NOT 0Fh
ENDM

;-----------------------------------------------------------------------------
; ALLOC_SHADOW - Allocate shadow space for subcalls
;-----------------------------------------------------------------------------
; Use when you need to make calls from a leaf function.
;-----------------------------------------------------------------------------
ALLOC_SHADOW MACRO
    sub rsp, SHADOW_SPACE
ENDM

FREE_SHADOW MACRO
    add rsp, SHADOW_SPACE
ENDM

ENDIF ; STACK64_INC

