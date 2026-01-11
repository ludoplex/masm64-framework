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
; DEPRECATED: This macro has incorrect offsets due to the PROLOGUE design.
; The offsets depend on the total_alloc value which varies per function.
;
; RECOMMENDED APPROACH:
;   For register arguments (1-4): Access registers directly (RCX, RDX, R8, R9)
;   before they are clobbered, or save them explicitly if needed.
;   For stack arguments (5+): Access via [RSP + offset] before PROLOGUE,
;   or save to local variables in PROLOGUE.
;
; Note: Due to PROLOGUE setting RBP = RSP + SHADOW_SPACE, argument locations
; relative to RBP vary based on local_space allocation and cannot be
; determined by this macro alone.
;-----------------------------------------------------------------------------
ARG MACRO n
    .ERR <ARG macro is deprecated - use direct register/stack access instead>
ENDM

;-----------------------------------------------------------------------------
; LOCAL_VAR - Allocate and access local variables
;-----------------------------------------------------------------------------
; Usage: Define locals after PROLOGUE using LOCAL directive.
;        Access using standard [rbp - offset] or named locals.
;-----------------------------------------------------------------------------

ENDIF ; ABI64_INC

