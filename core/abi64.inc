;-----------------------------------------------------------------------------
; abi64.inc - x64 ABI Calling Convention Enforcement
;-----------------------------------------------------------------------------
; Provides macros for correct x64 Windows calling convention compliance.
;
; Key x64 ABI Requirements:
;   - First 4 integer/pointer args: RCX, RDX, R8, R9
;   - First 4 float args: XMM0, XMM1, XMM2, XMM3
;   - Caller allocates 32 bytes shadow space
;   - Stack must be 16-byte aligned before CALL
;   - RAX returns integer/pointer results
;   - XMM0 returns float results
;   - Volatile: RAX, RCX, RDX, R8-R11, XMM0-XMM5
;   - Non-volatile: RBX, RBP, RDI, RSI, R12-R15, XMM6-XMM15
;-----------------------------------------------------------------------------

IFNDEF ABI64_INC
ABI64_INC EQU 1

;-----------------------------------------------------------------------------
; Shadow Space Constant
;-----------------------------------------------------------------------------
SHADOW_SPACE EQU 32

;-----------------------------------------------------------------------------
; INVOKE - Simplified Win64 API call
;-----------------------------------------------------------------------------
; Automatically handles register loading for up to 4 parameters.
; For more than 4 parameters, push extras to stack before INVOKE.
;
; Usage: INVOKE FunctionName, arg1, arg2, arg3, arg4
;-----------------------------------------------------------------------------
INVOKE MACRO func:REQ, a1, a2, a3, a4
    IFNB <a4>
        IF (OPATTR(a4)) AND 10h
            mov r9, a4
        ELSE
            mov r9d, a4
        ENDIF
    ENDIF
    IFNB <a3>
        IF (OPATTR(a3)) AND 10h
            mov r8, a3
        ELSE
            mov r8d, a3
        ENDIF
    ENDIF
    IFNB <a2>
        IF (OPATTR(a2)) AND 10h
            mov rdx, a2
        ELSE
            mov edx, a2
        ENDIF
    ENDIF
    IFNB <a1>
        IF (OPATTR(a1)) AND 10h
            mov rcx, a1
        ELSE
            mov ecx, a1
        ENDIF
    ENDIF
    call func
ENDM

;-----------------------------------------------------------------------------
; ARG - Access function arguments
;-----------------------------------------------------------------------------
; In x64, first 4 args are in registers but may be saved to shadow space.
; Use after PROLOGUE to access arguments by index.
;
; Note: This assumes args were saved to shadow space in prologue.
;-----------------------------------------------------------------------------
ARG MACRO n
    IF n EQ 1
        EXITM <QWORD PTR [rbp + 10h]>       ;; RCX home
    ELSEIF n EQ 2
        EXITM <QWORD PTR [rbp + 18h]>       ;; RDX home
    ELSEIF n EQ 3
        EXITM <QWORD PTR [rbp + 20h]>       ;; R8 home
    ELSEIF n EQ 4
        EXITM <QWORD PTR [rbp + 28h]>       ;; R9 home
    ELSE
        EXITM <QWORD PTR [rbp + (n * 8) + 8]>  ;; Stack args
    ENDIF
ENDM

;-----------------------------------------------------------------------------
; LOCAL_VAR - Allocate and access local variables
;-----------------------------------------------------------------------------
; Usage: Define locals after PROLOGUE using LOCAL directive.
;        Access using standard [rbp - offset] or named locals.
;-----------------------------------------------------------------------------

ENDIF ; ABI64_INC

