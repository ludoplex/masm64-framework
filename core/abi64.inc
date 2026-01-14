;-----------------------------------------------------------------------------
; abi64.inc - x64 ABI Calling Convention Enforcement
;-----------------------------------------------------------------------------
; Microsoft x64 ABI compliance macros and constants.
; Provides register preservation, shadow space, and stack alignment.
;-----------------------------------------------------------------------------

IFNDEF ABI64_INC
ABI64_INC EQU 1

;-----------------------------------------------------------------------------
; ABI Constants
;-----------------------------------------------------------------------------

; Shadow space size (home space for register parameters)
SHADOW_SPACE        EQU 32          ; 4 registers * 8 bytes = 32 bytes

; Stack alignment requirement
STACK_ALIGN         EQU 16          ; 16-byte alignment required

; Register argument positions
ARG1                EQU rcx
ARG2                EQU rdx
ARG3                EQU r8
ARG4                EQU r9

; Floating-point argument positions
FARG1               EQU xmm0
FARG2               EQU xmm1
FARG3               EQU xmm2
FARG4               EQU xmm3

; Return value registers
RETVAL              EQU rax
RETVAL_FP           EQU xmm0

;-----------------------------------------------------------------------------
; Volatile Registers (caller-saved, destroyed by calls)
;-----------------------------------------------------------------------------
; RAX, RCX, RDX, R8, R9, R10, R11
; XMM0-XMM5

;-----------------------------------------------------------------------------
; Non-volatile Registers (callee-saved, must be preserved)
;-----------------------------------------------------------------------------
; RBX, RBP, RDI, RSI, R12, R13, R14, R15
; XMM6-XMM15

;-----------------------------------------------------------------------------
; SAVE_VOLATILE - Save volatile registers before a call (optional)
;-----------------------------------------------------------------------------
; Use when you need to preserve volatile registers across a call.
; Most code doesn't need this - volatile registers are assumed destroyed.
;-----------------------------------------------------------------------------
SAVE_VOLATILE MACRO
    push rax
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11
    sub rsp, 64                     ; Space for XMM0-XMM5 (4 used) + alignment
    movdqa [rsp], xmm0
    movdqa [rsp+16], xmm1
    movdqa [rsp+32], xmm2
    movdqa [rsp+48], xmm3
ENDM

;-----------------------------------------------------------------------------
; RESTORE_VOLATILE - Restore volatile registers after a call
;-----------------------------------------------------------------------------
RESTORE_VOLATILE MACRO
    movdqa xmm3, [rsp+48]
    movdqa xmm2, [rsp+32]
    movdqa xmm1, [rsp+16]
    movdqa xmm0, [rsp]
    add rsp, 64
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rax
ENDM

;-----------------------------------------------------------------------------
; SAVE_NONVOL - Save non-volatile registers (use in prologue)
;-----------------------------------------------------------------------------
; Parameters: List of registers to save
; Example: SAVE_NONVOL rbx, rdi, rsi
;-----------------------------------------------------------------------------
SAVE_NONVOL MACRO regs:VARARG
    FOR reg, <regs>
        push reg
        .pushreg reg
    ENDM
ENDM

;-----------------------------------------------------------------------------
; RESTORE_NONVOL - Restore non-volatile registers (use in epilogue)
;-----------------------------------------------------------------------------
; Parameters: List of registers in REVERSE order from SAVE_NONVOL
; Example: RESTORE_NONVOL rsi, rdi, rbx
;-----------------------------------------------------------------------------
RESTORE_NONVOL MACRO regs:VARARG
    FOR reg, <regs>
        pop reg
    ENDM
ENDM

;-----------------------------------------------------------------------------
; SAVE_XMM - Save non-volatile XMM registers (XMM6-XMM15)
;-----------------------------------------------------------------------------
; Parameters: Starting offset from RSP, list of XMM registers
; Note: Offset must be 16-byte aligned
;-----------------------------------------------------------------------------
SAVE_XMM MACRO offset, regs:VARARG
    LOCAL off
    off = offset
    FOR reg, <regs>
        movdqa [rsp+off], reg
        .savexmm128 reg, off
        off = off + 16
    ENDM
ENDM

;-----------------------------------------------------------------------------
; RESTORE_XMM - Restore non-volatile XMM registers
;-----------------------------------------------------------------------------
RESTORE_XMM MACRO offset, regs:VARARG
    LOCAL off
    off = offset
    FOR reg, <regs>
        movdqa reg, [rsp+off]
        off = off + 16
    ENDM
ENDM

;-----------------------------------------------------------------------------
; ALIGN_STACK - Calculate aligned stack allocation size
;-----------------------------------------------------------------------------
; Parameters: locals_size - size of local variables needed
; Returns: Size that maintains 16-byte alignment after shadow space
;-----------------------------------------------------------------------------
; Formula: ((shadow + locals + 8) + 15) AND NOT 15
; The +8 accounts for the return address pushed by CALL
;-----------------------------------------------------------------------------
ALIGN_STACK MACRO locals_size
    EXITM %((SHADOW_SPACE + locals_size + 8 + 15) AND (NOT 15))
ENDM

;-----------------------------------------------------------------------------
; Shadow Space Offset Constants
;-----------------------------------------------------------------------------
; After allocating stack frame, these offsets access shadow space
; where caller's register arguments can be spilled if needed.
;-----------------------------------------------------------------------------
SHADOW_RCX          EQU 8           ; [rsp + frame_size + 8]
SHADOW_RDX          EQU 16          ; [rsp + frame_size + 16]
SHADOW_R8           EQU 24          ; [rsp + frame_size + 24]
SHADOW_R9           EQU 32          ; [rsp + frame_size + 32]

;-----------------------------------------------------------------------------
; Stack argument access (5th argument and beyond)
;-----------------------------------------------------------------------------
; After frame setup: [rsp + frame_size + 40] = 5th arg
;                    [rsp + frame_size + 48] = 6th arg
;                    etc.
;-----------------------------------------------------------------------------
STACK_ARG5          EQU 40
STACK_ARG6          EQU 48
STACK_ARG7          EQU 56
STACK_ARG8          EQU 64

;-----------------------------------------------------------------------------
; CHECK_ALIGNMENT - Debug macro to verify stack alignment
;-----------------------------------------------------------------------------
IFDEF DEBUG
CHECK_ALIGNMENT MACRO
    LOCAL aligned
    push rax
    mov rax, rsp
    add rax, 8                      ; Account for the push
    and rax, 0Fh                    ; Check low 4 bits
    jz aligned
    int 3                           ; Break if misaligned
aligned:
    pop rax
ENDM
ELSE
CHECK_ALIGNMENT MACRO
ENDM
ENDIF

ENDIF ; ABI64_INC

