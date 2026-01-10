;-----------------------------------------------------------------------------
; macros64.inc - Essential General-Purpose Macros
;-----------------------------------------------------------------------------
; Commonly used macros for MASM64 development.
;-----------------------------------------------------------------------------

IFNDEF MACROS64_INC
MACROS64_INC EQU 1

INCLUDE abi64.inc

;-----------------------------------------------------------------------------
; External Win32 API Declarations
;-----------------------------------------------------------------------------
EXTERNDEF GetStdHandle:PROC
EXTERNDEF WriteConsoleA:PROC
EXTERNDEF ExitProcess:PROC

;-----------------------------------------------------------------------------
; Console Handle Constants
;-----------------------------------------------------------------------------
STD_OUTPUT_HANDLE EQU -11
STD_INPUT_HANDLE  EQU -10
STD_ERROR_HANDLE  EQU -12

;-----------------------------------------------------------------------------
; PRINT_STRING - Output string to console
;-----------------------------------------------------------------------------
; Parameters: str_label - Label of null-terminated string
; Clobbers: RAX, RCX, RDX, R8, R9
;-----------------------------------------------------------------------------
PRINT_STRING MACRO str_label
    LOCAL str_len, print_done
    
    ;; Get string length
    lea rdi, str_label
    xor ecx, ecx
@@:
    cmp BYTE PTR [rdi + rcx], 0
    je @F
    inc ecx
    jmp @B
@@:
    mov r8d, ecx                        ; Length
    
    ;; Get stdout handle
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov rcx, rax                        ; hConsole
    
    ;; WriteConsoleA(hConsole, lpBuffer, nNumberOfCharsToWrite, lpNumberWritten, lpReserved)
    lea rdx, str_label                  ; lpBuffer
    ;; R8 already has length
    lea r9, [rsp + 20h]                 ; lpNumberOfCharsWritten (use shadow space)
    mov QWORD PTR [rsp + 20h], 0        ; lpReserved
    call WriteConsoleA
ENDM

;-----------------------------------------------------------------------------
; EXIT_PROCESS - Terminate process with exit code
;-----------------------------------------------------------------------------
EXIT_PROCESS MACRO exit_code:=<0>
    mov ecx, exit_code
    call ExitProcess
ENDM

;-----------------------------------------------------------------------------
; UNICODE_STRING - Define a Unicode (wide) string
;-----------------------------------------------------------------------------
; Parameters: name - Label for the string
;             text - String content
;-----------------------------------------------------------------------------
UNICODE_STRING MACRO name, text
    name LABEL WORD
    FORC char, <text>
        DW '&char'
    ENDM
    DW 0
ENDM

;-----------------------------------------------------------------------------
; ANSI_STRING - Define an ANSI string with optional newline
;-----------------------------------------------------------------------------
ANSI_STRING MACRO name, text, newline:=<0>
    name DB text
    IF newline
        DB 13, 10
    ENDIF
    DB 0
ENDM

;-----------------------------------------------------------------------------
; ALIGN16 - Align data or code to 16 bytes
;-----------------------------------------------------------------------------
ALIGN16 MACRO
    ALIGN 16
ENDM

;-----------------------------------------------------------------------------
; ZERO_REG - Zero a register efficiently
;-----------------------------------------------------------------------------
ZERO_REG MACRO reg
    xor reg, reg
ENDM

;-----------------------------------------------------------------------------
; LOAD_ADDR - Load effective address (LEA wrapper)
;-----------------------------------------------------------------------------
LOAD_ADDR MACRO dest_reg, source
    lea dest_reg, source
ENDM

;-----------------------------------------------------------------------------
; SWAP - Exchange two registers
;-----------------------------------------------------------------------------
SWAP MACRO reg1, reg2
    xchg reg1, reg2
ENDM

;-----------------------------------------------------------------------------
; CLEAR_FLAGS - Clear CPU flags
;-----------------------------------------------------------------------------
CLEAR_FLAGS MACRO
    xor eax, eax
ENDM

;-----------------------------------------------------------------------------
; SET_CARRY - Set carry flag
;-----------------------------------------------------------------------------
SET_CARRY MACRO
    stc
ENDM

;-----------------------------------------------------------------------------
; CLEAR_CARRY - Clear carry flag
;-----------------------------------------------------------------------------
CLEAR_CARRY MACRO
    clc
ENDM

ENDIF ; MACROS64_INC

