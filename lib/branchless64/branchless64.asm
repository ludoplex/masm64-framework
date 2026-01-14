;-----------------------------------------------------------------------------
; branchless64.asm - Branchless Operation Utilities Implementation
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE branchless64.inc

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; BL_Min64 - Branchless minimum
;-----------------------------------------------------------------------------
; Parameters: RCX = a, RDX = b
; Returns: min(a, b) in RAX
;-----------------------------------------------------------------------------
BL_Min64 PROC
    mov rax, rcx
    cmp rax, rdx
    cmovg rax, rdx
    ret
BL_Min64 ENDP

;-----------------------------------------------------------------------------
; BL_Max64 - Branchless maximum
;-----------------------------------------------------------------------------
BL_Max64 PROC
    mov rax, rcx
    cmp rax, rdx
    cmovl rax, rdx
    ret
BL_Max64 ENDP

;-----------------------------------------------------------------------------
; BL_Clamp64 - Branchless clamp
;-----------------------------------------------------------------------------
; Parameters: RCX = value, RDX = min, R8 = max
; Returns: clamped value in RAX
;-----------------------------------------------------------------------------
BL_Clamp64 PROC
    mov rax, rcx
    cmp rax, rdx
    cmovl rax, rdx                      ; Clamp to min
    cmp rax, r8
    cmovg rax, r8                       ; Clamp to max
    ret
BL_Clamp64 ENDP

;-----------------------------------------------------------------------------
; BL_Abs64 - Branchless absolute value
;-----------------------------------------------------------------------------
; Parameters: RCX = value
; Returns: |value| in RAX
;-----------------------------------------------------------------------------
BL_Abs64 PROC
    mov rax, rcx
    mov rdx, rcx
    sar rdx, 63                         ; -1 if negative, 0 if positive
    xor rax, rdx                        ; Flip bits if negative
    sub rax, rdx                        ; Add 1 if was negative
    ret
BL_Abs64 ENDP

;-----------------------------------------------------------------------------
; BL_Sign64 - Extract sign
;-----------------------------------------------------------------------------
; Parameters: RCX = value
; Returns: -1, 0, or 1 in RAX
;-----------------------------------------------------------------------------
BL_Sign64 PROC
    mov rax, rcx
    mov rdx, rcx
    sar rax, 63                         ; -1 if negative, 0 otherwise
    shr rdx, 63                         ; 1 if negative, 0 otherwise
    or rax, rdx                         ; Combine: gives -1, 0, or 1
    ret
BL_Sign64 ENDP

;-----------------------------------------------------------------------------
; BL_Select64 - Conditional select
;-----------------------------------------------------------------------------
; Parameters: RCX = condition, RDX = a, R8 = b
; Returns: a if condition != 0, else b
;-----------------------------------------------------------------------------
BL_Select64 PROC
    mov rax, r8                         ; Default to b
    test rcx, rcx
    cmovnz rax, rdx                     ; Select a if condition true
    ret
BL_Select64 ENDP

END

