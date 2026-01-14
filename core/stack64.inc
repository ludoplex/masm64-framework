;-----------------------------------------------------------------------------
; stack64.inc - Stack Frame Management Utilities
;-----------------------------------------------------------------------------
; Provides macros for function prologue/epilogue generation with proper
; x64 ABI compliance, unwind info, and stack alignment.
;-----------------------------------------------------------------------------

IFNDEF STACK64_INC
STACK64_INC EQU 1

INCLUDE abi64.inc

;-----------------------------------------------------------------------------
; FRAME_BEGIN - Start a stack frame with automatic alignment
;-----------------------------------------------------------------------------
; Parameters:
;   frame_size - Total size for locals (will be aligned to 16 bytes)
;   uses_rbp   - 1 to use RBP as frame pointer, 0 otherwise
;
; This macro:
;   1. Declares PROC FRAME for unwind info
;   2. Pushes RBP if requested
;   3. Allocates aligned stack space (includes shadow space)
;   4. Optionally sets up RBP as frame pointer
;-----------------------------------------------------------------------------
FRAME_BEGIN MACRO proc_name, frame_size, uses_rbp:=<1>
    LOCAL aligned_size

    proc_name PROC FRAME
    
    IF uses_rbp
        push rbp
        .pushreg rbp
    ENDIF
    
    ;; Calculate aligned size: shadow(32) + locals + padding for 16-byte alignment
    ;; After CALL, RSP is 8 mod 16. After push rbp, RSP is 0 mod 16.
    ;; We need final RSP to be 0 mod 16.
    IF uses_rbp
        aligned_size = ((SHADOW_SPACE + frame_size + 15) AND (NOT 15))
    ELSE
        ;; Without push, need extra 8 bytes for alignment
        aligned_size = ((SHADOW_SPACE + frame_size + 8 + 15) AND (NOT 15))
    ENDIF
    
    IF aligned_size GT 0
        IF aligned_size GT 4096
            ;; Large allocation requires __chkstk
            mov rax, aligned_size
            call __chkstk
            sub rsp, rax
        ELSE
            sub rsp, aligned_size
        ENDIF
        .allocstack aligned_size
    ENDIF
    
    IF uses_rbp
        lea rbp, [rsp + SHADOW_SPACE]
        .setframe rbp, SHADOW_SPACE
    ENDIF
    
    .endprolog
    
    ;; Define local label for frame size reference
    @FrameSize = aligned_size
    @UsesRbp = uses_rbp
ENDM

;-----------------------------------------------------------------------------
; FRAME_END - End a stack frame
;-----------------------------------------------------------------------------
FRAME_END MACRO proc_name
    IF @UsesRbp
        lea rsp, [rbp - SHADOW_SPACE + @FrameSize]
        pop rbp
    ELSE
        IF @FrameSize GT 0
            add rsp, @FrameSize
        ENDIF
    ENDIF
    ret
    proc_name ENDP
ENDM

;-----------------------------------------------------------------------------
; LEAF_PROC - Declare a leaf function (no stack frame needed)
;-----------------------------------------------------------------------------
; Leaf functions:
;   - Don't call other functions
;   - Don't modify non-volatile registers
;   - Don't allocate stack space
;   - Don't need unwind info
;-----------------------------------------------------------------------------
LEAF_PROC MACRO proc_name
    proc_name PROC
ENDM

LEAF_END MACRO proc_name
    ret
    proc_name ENDP
ENDM

;-----------------------------------------------------------------------------
; NESTED_PROC - Declare a nested function with saved registers
;-----------------------------------------------------------------------------
; Parameters:
;   proc_name  - Function name
;   frame_size - Local variable space
;   regs       - List of non-volatile registers to save
;
; Example: NESTED_PROC MyFunc, 64, <rbx, rdi, rsi>
;-----------------------------------------------------------------------------
NESTED_PROC MACRO proc_name, frame_size, regs
    LOCAL push_count, aligned_size, reg
    
    proc_name PROC FRAME
    
    ;; Count registers to push
    push_count = 0
    FOR reg, <regs>
        push reg
        .pushreg reg
        push_count = push_count + 1
    ENDM
    
    ;; Calculate aligned size accounting for pushes
    ;; Each push is 8 bytes. CALL pushes 8 bytes.
    ;; Total before SUB: 8 (ret) + push_count*8
    ;; Need result to be 0 mod 16
    IF ((push_count + 1) AND 1) EQ 0
        ;; Even number of 8-byte pushes (including ret), already aligned
        aligned_size = ((SHADOW_SPACE + frame_size + 15) AND (NOT 15))
    ELSE
        ;; Odd number, need 8 extra bytes
        aligned_size = ((SHADOW_SPACE + frame_size + 8 + 15) AND (NOT 15))
    ENDIF
    
    IF aligned_size GT 4096
        mov rax, aligned_size
        call __chkstk
        sub rsp, rax
    ELSE
        sub rsp, aligned_size
    ENDIF
    .allocstack aligned_size
    
    .endprolog
    
    @FrameSize = aligned_size
    @PushCount = push_count
ENDM

;-----------------------------------------------------------------------------
; NESTED_END - End a nested function
;-----------------------------------------------------------------------------
NESTED_END MACRO proc_name, regs
    LOCAL reg
    
    add rsp, @FrameSize
    
    ;; Pop registers in reverse order
    ;; Note: MASM processes VARARG in order, so we need reverse
    FOR reg, <regs>
        pop reg
    ENDM
    
    ret
    proc_name ENDP
ENDM

;-----------------------------------------------------------------------------
; LOCAL_VAR - Calculate offset for local variable from RBP
;-----------------------------------------------------------------------------
; When using RBP as frame pointer (set to RSP + SHADOW_SPACE):
;   Locals are at negative offsets from RBP
;   Shadow space is at [RBP - SHADOW_SPACE] to [RBP - 1]
;   Local at offset 0 is at [RBP]
;-----------------------------------------------------------------------------
LOCAL_VAR MACRO offset
    EXITM <[rbp + offset]>
ENDM

;-----------------------------------------------------------------------------
; SPILL_ARGS - Spill register arguments to shadow space
;-----------------------------------------------------------------------------
; Use this at function start if you need to access arguments by address
; or need to use the argument registers for other purposes.
;-----------------------------------------------------------------------------
SPILL_ARGS MACRO
    mov [rbp - SHADOW_SPACE + 0], rcx      ; 1st arg
    mov [rbp - SHADOW_SPACE + 8], rdx      ; 2nd arg
    mov [rbp - SHADOW_SPACE + 16], r8      ; 3rd arg
    mov [rbp - SHADOW_SPACE + 24], r9      ; 4th arg
ENDM

;-----------------------------------------------------------------------------
; ALLOC_DYNAMIC - Allocate dynamic stack space (like alloca)
;-----------------------------------------------------------------------------
; Parameters:
;   size_reg - Register containing size to allocate
;   result_reg - Register to receive pointer to allocated space
;
; Warning: Function must use frame pointer when using dynamic allocation
;-----------------------------------------------------------------------------
ALLOC_DYNAMIC MACRO size_reg, result_reg
    ;; Align size to 16 bytes
    add size_reg, 15
    and size_reg, NOT 15
    
    ;; Check if large allocation needs __chkstk
    cmp size_reg, 4096
    jb @F
    mov rax, size_reg
    call __chkstk
@@:
    sub rsp, size_reg
    lea result_reg, [rsp]
ENDM

;-----------------------------------------------------------------------------
; External reference for stack probing
;-----------------------------------------------------------------------------
EXTERNDEF __chkstk:PROC

ENDIF ; STACK64_INC

