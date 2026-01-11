;-----------------------------------------------------------------------------
; stack64.inc - Stack Frame Management Utilities
;-----------------------------------------------------------------------------
; Provides macros for proper x64 stack frame setup and teardown.
;
; Stack Layout After PROLOGUE (with PROLOGUE 0, local_space):
;   After 'push rbp', 'sub rsp, total_alloc', 'lea rbp, [rsp + SHADOW_SPACE]':
;
;   Higher addresses (arguments from caller)
;   [rbp + total_alloc + 16] = 5th argument (if any)
;   [rbp + total_alloc + 8]  = R9 home (shadow space from caller)
;   [rbp + total_alloc]      = R8 home (shadow space from caller)
;   [rbp + total_alloc - 8]  = RDX home (shadow space from caller)
;   [rbp + total_alloc - 16] = RCX home (shadow space from caller)
;   [rbp + total_alloc - 24] = Return address
;   [rbp + total_alloc - 32] = Saved RBP
;   [rbp]                    = Start of our shadow space for calls we make
;   [rbp - SHADOW_SPACE]     = RSP (points to local variable space)
;   Lower addresses (local variables)
;
;   Note: total_alloc = SHADOW_SPACE + local_space, aligned to maintain
;         16-byte alignment before calls. Access to arguments requires
;         knowing total_alloc, so direct register access is recommended.
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
    lea rsp, [rbp - SHADOW_SPACE]           ; Point RSP to saved RBP
    pop rbp                                  ; Restore RBP and adjust RSP
ENDM

;-----------------------------------------------------------------------------
; SAVE_NONVOL - Save non-volatile registers
;-----------------------------------------------------------------------------
; Use at start of function after PROLOGUE to save registers you'll modify.
;
; IMPORTANT: This macro saves registers to stack locations below shadow space.
; You MUST ensure sufficient local_space is allocated in PROLOGUE to accommodate
; all saved registers. Each register requires 8 bytes.
;
; Example: If saving 3 registers (RBX, RDI, RSI), allocate at least 24 bytes
; in PROLOGUE's local_space parameter: PROLOGUE 0, 24
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
; Must specify registers in the SAME ORDER as SAVE_NONVOL.
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

