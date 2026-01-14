;-----------------------------------------------------------------------------
; macros64.inc - Essential MASM64 Macros
;-----------------------------------------------------------------------------
; Core macro library providing string literals, invoke wrapper,
; data alignment, conditional compilation, and utility macros.
;-----------------------------------------------------------------------------

IFNDEF MACROS64_INC
MACROS64_INC EQU 1

INCLUDE abi64.inc

;-----------------------------------------------------------------------------
; WSTR - Define a Unicode (UTF-16LE) string literal
;-----------------------------------------------------------------------------
; Parameters:
;   name - Symbol name for the string
;   text - String content (use quotes)
;
; Example: WSTR szHello, "Hello, World!"
;-----------------------------------------------------------------------------
WSTR MACRO name, text
    name DW text, 0
ENDM

;-----------------------------------------------------------------------------
; ASTR - Define an ANSI string literal
;-----------------------------------------------------------------------------
ASTR MACRO name, text
    name DB text, 0
ENDM

;-----------------------------------------------------------------------------
; WSTRN - Define a Unicode string with explicit length (no null terminator)
;-----------------------------------------------------------------------------
WSTRN MACRO name, text
    name DW text
    name&_LEN EQU ($ - name) / 2
ENDM

;-----------------------------------------------------------------------------
; ALIGN16 - Align data to 16-byte boundary
;-----------------------------------------------------------------------------
ALIGN16 MACRO
    ALIGN 16
ENDM

;-----------------------------------------------------------------------------
; ALIGNPAGE - Align data to page boundary (4KB)
;-----------------------------------------------------------------------------
ALIGNPAGE MACRO
    ALIGN 4096
ENDM

;-----------------------------------------------------------------------------
; INVOKE - Call a function with automatic parameter marshaling
;-----------------------------------------------------------------------------
; Handles up to 8 parameters, placing first 4 in registers,
; remaining on stack. Maintains proper stack alignment.
;
; Example: INVOKE MessageBoxW, NULL, ADDR szText, ADDR szCaption, MB_OK
;-----------------------------------------------------------------------------
INVOKE MACRO func:REQ, args:VARARG
    LOCAL arg_count, stack_args, i, arg, stack_size

    ;; Count arguments
    arg_count = 0
    FOR arg, <args>
        arg_count = arg_count + 1
    ENDM
    
    ;; Calculate stack arguments (5th and beyond)
    IF arg_count GT 4
        stack_args = arg_count - 4
    ELSE
        stack_args = 0
    ENDIF
    
    ;; Calculate stack space: shadow(32) + stack_args*8, aligned to 16
    IF stack_args GT 0
        stack_size = ((SHADOW_SPACE + stack_args * 8 + 15) AND (NOT 15))
    ELSE
        stack_size = SHADOW_SPACE
    ENDIF
    
    ;; Allocate stack space
    sub rsp, stack_size
    
    ;; Push stack arguments in reverse order (right to left)
    IF stack_args GT 0
        i = arg_count
        FOR arg, <args>
            IF i GT 4
                IF i EQ 5
                    IF (OPATTR(arg)) AND 10h  ;; Is it a register?
                        mov QWORD PTR [rsp + SHADOW_SPACE], arg
                    ELSEIF (OPATTR(arg)) AND 04h  ;; Is it immediate?
                        mov QWORD PTR [rsp + SHADOW_SPACE], arg
                    ELSE
                        lea rax, arg
                        mov QWORD PTR [rsp + SHADOW_SPACE], rax
                    ENDIF
                ELSEIF i EQ 6
                    IF (OPATTR(arg)) AND 10h
                        mov QWORD PTR [rsp + SHADOW_SPACE + 8], arg
                    ELSEIF (OPATTR(arg)) AND 04h
                        mov QWORD PTR [rsp + SHADOW_SPACE + 8], arg
                    ELSE
                        lea rax, arg
                        mov QWORD PTR [rsp + SHADOW_SPACE + 8], rax
                    ENDIF
                ELSEIF i EQ 7
                    IF (OPATTR(arg)) AND 10h
                        mov QWORD PTR [rsp + SHADOW_SPACE + 16], arg
                    ELSEIF (OPATTR(arg)) AND 04h
                        mov QWORD PTR [rsp + SHADOW_SPACE + 16], arg
                    ELSE
                        lea rax, arg
                        mov QWORD PTR [rsp + SHADOW_SPACE + 16], rax
                    ENDIF
                ELSEIF i EQ 8
                    IF (OPATTR(arg)) AND 10h
                        mov QWORD PTR [rsp + SHADOW_SPACE + 24], arg
                    ELSEIF (OPATTR(arg)) AND 04h
                        mov QWORD PTR [rsp + SHADOW_SPACE + 24], arg
                    ELSE
                        lea rax, arg
                        mov QWORD PTR [rsp + SHADOW_SPACE + 24], rax
                    ENDIF
                ENDIF
            ENDIF
            i = i - 1
        ENDM
    ENDIF
    
    ;; Load register arguments (process in order, load last to first)
    i = 1
    FOR arg, <args>
        IF i EQ 4
            IF (OPATTR(arg)) AND 10h
                IF @SizeStr(<arg>) GT 0
                    IFIDNI <arg>, <r9>
                        ;; Already in R9, skip
                    ELSE
                        mov r9, arg
                    ENDIF
                ENDIF
            ELSEIF (OPATTR(arg)) AND 04h
                mov r9, arg
            ELSE
                lea r9, arg
            ENDIF
        ENDIF
        i = i + 1
    ENDM
    
    i = 1
    FOR arg, <args>
        IF i EQ 3
            IF (OPATTR(arg)) AND 10h
                IFIDNI <arg>, <r8>
                ELSE
                    mov r8, arg
                ENDIF
            ELSEIF (OPATTR(arg)) AND 04h
                mov r8, arg
            ELSE
                lea r8, arg
            ENDIF
        ENDIF
        i = i + 1
    ENDM
    
    i = 1
    FOR arg, <args>
        IF i EQ 2
            IF (OPATTR(arg)) AND 10h
                IFIDNI <arg>, <rdx>
                ELSE
                    mov rdx, arg
                ENDIF
            ELSEIF (OPATTR(arg)) AND 04h
                mov rdx, arg
            ELSE
                lea rdx, arg
            ENDIF
        ENDIF
        i = i + 1
    ENDM
    
    i = 1
    FOR arg, <args>
        IF i EQ 1
            IF (OPATTR(arg)) AND 10h
                IFIDNI <arg>, <rcx>
                ELSE
                    mov rcx, arg
                ENDIF
            ELSEIF (OPATTR(arg)) AND 04h
                mov rcx, arg
            ELSE
                lea rcx, arg
            ENDIF
        ENDIF
        i = i + 1
    ENDM
    
    ;; Call the function
    call func
    
    ;; Clean up stack
    add rsp, stack_size
ENDM

;-----------------------------------------------------------------------------
; INVOKE0 - Call a function with no arguments
;-----------------------------------------------------------------------------
INVOKE0 MACRO func:REQ
    sub rsp, SHADOW_SPACE
    call func
    add rsp, SHADOW_SPACE
ENDM

;-----------------------------------------------------------------------------
; INVOKE1 - Call a function with 1 argument
;-----------------------------------------------------------------------------
INVOKE1 MACRO func:REQ, arg1:REQ
    sub rsp, SHADOW_SPACE
    IF (OPATTR(arg1)) AND 10h
        IFIDNI <arg1>, <rcx>
        ELSE
            mov rcx, arg1
        ENDIF
    ELSEIF (OPATTR(arg1)) AND 04h
        mov rcx, arg1
    ELSE
        lea rcx, arg1
    ENDIF
    call func
    add rsp, SHADOW_SPACE
ENDM

;-----------------------------------------------------------------------------
; INVOKE2 - Call a function with 2 arguments
;-----------------------------------------------------------------------------
INVOKE2 MACRO func:REQ, arg1:REQ, arg2:REQ
    sub rsp, SHADOW_SPACE
    IF (OPATTR(arg2)) AND 10h
        IFIDNI <arg2>, <rdx>
        ELSE
            mov rdx, arg2
        ENDIF
    ELSEIF (OPATTR(arg2)) AND 04h
        mov rdx, arg2
    ELSE
        lea rdx, arg2
    ENDIF
    IF (OPATTR(arg1)) AND 10h
        IFIDNI <arg1>, <rcx>
        ELSE
            mov rcx, arg1
        ENDIF
    ELSEIF (OPATTR(arg1)) AND 04h
        mov rcx, arg1
    ELSE
        lea rcx, arg1
    ENDIF
    call func
    add rsp, SHADOW_SPACE
ENDM

;-----------------------------------------------------------------------------
; INVOKE3 - Call a function with 3 arguments
;-----------------------------------------------------------------------------
INVOKE3 MACRO func:REQ, arg1:REQ, arg2:REQ, arg3:REQ
    sub rsp, SHADOW_SPACE
    IF (OPATTR(arg3)) AND 10h
        IFIDNI <arg3>, <r8>
        ELSE
            mov r8, arg3
        ENDIF
    ELSEIF (OPATTR(arg3)) AND 04h
        mov r8, arg3
    ELSE
        lea r8, arg3
    ENDIF
    IF (OPATTR(arg2)) AND 10h
        IFIDNI <arg2>, <rdx>
        ELSE
            mov rdx, arg2
        ENDIF
    ELSEIF (OPATTR(arg2)) AND 04h
        mov rdx, arg2
    ELSE
        lea rdx, arg2
    ENDIF
    IF (OPATTR(arg1)) AND 10h
        IFIDNI <arg1>, <rcx>
        ELSE
            mov rcx, arg1
        ENDIF
    ELSEIF (OPATTR(arg1)) AND 04h
        mov rcx, arg1
    ELSE
        lea rcx, arg1
    ENDIF
    call func
    add rsp, SHADOW_SPACE
ENDM

;-----------------------------------------------------------------------------
; INVOKE4 - Call a function with 4 arguments
;-----------------------------------------------------------------------------
INVOKE4 MACRO func:REQ, arg1:REQ, arg2:REQ, arg3:REQ, arg4:REQ
    sub rsp, SHADOW_SPACE
    IF (OPATTR(arg4)) AND 10h
        IFIDNI <arg4>, <r9>
        ELSE
            mov r9, arg4
        ENDIF
    ELSEIF (OPATTR(arg4)) AND 04h
        mov r9, arg4
    ELSE
        lea r9, arg4
    ENDIF
    IF (OPATTR(arg3)) AND 10h
        IFIDNI <arg3>, <r8>
        ELSE
            mov r8, arg3
        ENDIF
    ELSEIF (OPATTR(arg3)) AND 04h
        mov r8, arg3
    ELSE
        lea r8, arg3
    ENDIF
    IF (OPATTR(arg2)) AND 10h
        IFIDNI <arg2>, <rdx>
        ELSE
            mov rdx, arg2
        ENDIF
    ELSEIF (OPATTR(arg2)) AND 04h
        mov rdx, arg2
    ELSE
        lea rdx, arg2
    ENDIF
    IF (OPATTR(arg1)) AND 10h
        IFIDNI <arg1>, <rcx>
        ELSE
            mov rcx, arg1
        ENDIF
    ELSEIF (OPATTR(arg1)) AND 04h
        mov rcx, arg1
    ELSE
        lea rcx, arg1
    ENDIF
    call func
    add rsp, SHADOW_SPACE
ENDM

;-----------------------------------------------------------------------------
; RETURN - Return from function with optional value
;-----------------------------------------------------------------------------
RETURN MACRO retval
    IFNB <retval>
        IF (OPATTR(retval)) AND 10h
            IFIDNI <retval>, <rax>
            ELSE
                mov rax, retval
            ENDIF
        ELSEIF (OPATTR(retval)) AND 04h
            mov rax, retval
        ELSE
            lea rax, retval
        ENDIF
    ENDIF
ENDM

;-----------------------------------------------------------------------------
; ZERO - Zero a register efficiently
;-----------------------------------------------------------------------------
ZERO MACRO reg
    xor reg, reg
ENDM

;-----------------------------------------------------------------------------
; SETZERO - Set a memory location to zero
;-----------------------------------------------------------------------------
SETZERO MACRO mem, size
    IF size EQ 8
        mov QWORD PTR mem, 0
    ELSEIF size EQ 4
        mov DWORD PTR mem, 0
    ELSEIF size EQ 2
        mov WORD PTR mem, 0
    ELSEIF size EQ 1
        mov BYTE PTR mem, 0
    ENDIF
ENDM

;-----------------------------------------------------------------------------
; DEBUG_BREAK - Insert debugger breakpoint
;-----------------------------------------------------------------------------
IFDEF DEBUG
DEBUG_BREAK MACRO
    int 3
ENDM
ELSE
DEBUG_BREAK MACRO
ENDM
ENDIF

;-----------------------------------------------------------------------------
; ASSERT - Debug assertion
;-----------------------------------------------------------------------------
IFDEF DEBUG
ASSERT MACRO condition
    LOCAL ok
    condition
    jnz ok
    int 3
ok:
ENDM
ELSE
ASSERT MACRO condition
ENDM
ENDIF

;-----------------------------------------------------------------------------
; SIZEOF_PTR - Size of a pointer (always 8 on x64)
;-----------------------------------------------------------------------------
SIZEOF_PTR EQU 8

;-----------------------------------------------------------------------------
; NULL constant
;-----------------------------------------------------------------------------
NULL EQU 0

;-----------------------------------------------------------------------------
; TRUE/FALSE constants
;-----------------------------------------------------------------------------
TRUE EQU 1
FALSE EQU 0

;-----------------------------------------------------------------------------
; BOOL type (DWORD for Win32 compatibility)
;-----------------------------------------------------------------------------
BOOL TYPEDEF DWORD

;-----------------------------------------------------------------------------
; Common Windows constants
;-----------------------------------------------------------------------------
INVALID_HANDLE_VALUE EQU -1

ENDIF ; MACROS64_INC

