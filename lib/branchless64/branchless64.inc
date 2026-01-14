;-----------------------------------------------------------------------------
; branchless64.inc - Branchless Operation Utilities
;-----------------------------------------------------------------------------
; Provides branchless implementations of common operations.
;
; Benefits of branchless code:
;   - No branch misprediction penalties
;   - Consistent execution time (security/timing)
;   - Better instruction-level parallelism
;   - Simpler control flow for CPU
;
; Use Cases:
;   - Performance-critical inner loops
;   - Cryptographic code (constant-time)
;   - SIMD-friendly patterns
;   - Avoiding branch misprediction
;
; Categories:
;   - Conditional selection (min, max, clamp, abs)
;   - Bit manipulation (sign, msb, lsb)
;   - Arithmetic (saturating add/sub)
;   - Comparison (equality, ordering)
;-----------------------------------------------------------------------------

IFNDEF BRANCHLESS64_INC
BRANCHLESS64_INC EQU 1

;-----------------------------------------------------------------------------
; BL_MIN - Branchless minimum of two values
;-----------------------------------------------------------------------------
; Uses: CMOV instruction
; Parameters: a_reg - First value (modified)
;             b_reg - Second value
; Result in a_reg
;-----------------------------------------------------------------------------
BL_MIN MACRO a_reg, b_reg
    cmp a_reg, b_reg
    cmovg a_reg, b_reg
ENDM

;; Signed version
BL_SMIN MACRO a_reg, b_reg
    cmp a_reg, b_reg
    cmovg a_reg, b_reg
ENDM

;; Unsigned version
BL_UMIN MACRO a_reg, b_reg
    cmp a_reg, b_reg
    cmova a_reg, b_reg
ENDM

;-----------------------------------------------------------------------------
; BL_MAX - Branchless maximum of two values
;-----------------------------------------------------------------------------
BL_MAX MACRO a_reg, b_reg
    cmp a_reg, b_reg
    cmovl a_reg, b_reg
ENDM

BL_SMAX MACRO a_reg, b_reg
    cmp a_reg, b_reg
    cmovl a_reg, b_reg
ENDM

BL_UMAX MACRO a_reg, b_reg
    cmp a_reg, b_reg
    cmovb a_reg, b_reg
ENDM

;-----------------------------------------------------------------------------
; BL_ABS - Branchless absolute value
;-----------------------------------------------------------------------------
; Uses arithmetic right shift to create mask
; Parameters: val_reg - Value (modified to absolute)
;             scratch_reg - Scratch register
;-----------------------------------------------------------------------------
BL_ABS MACRO val_reg, scratch_reg
    mov scratch_reg, val_reg
    sar scratch_reg, 63                 ; -1 if negative, 0 if positive
    xor val_reg, scratch_reg            ; Invert bits if negative
    sub val_reg, scratch_reg            ; Add 1 if was negative
ENDM

;; Alternative using NEG/CMOV
BL_ABS2 MACRO val_reg, scratch_reg
    mov scratch_reg, val_reg
    neg scratch_reg
    cmovs scratch_reg, val_reg          ; Use original if NEG caused sign
    mov val_reg, scratch_reg
ENDM

;-----------------------------------------------------------------------------
; BL_NABS - Branchless negative absolute value
;-----------------------------------------------------------------------------
; Always returns -|x|, useful for avoiding overflow with MIN_INT
;-----------------------------------------------------------------------------
BL_NABS MACRO val_reg, scratch_reg
    mov scratch_reg, val_reg
    neg scratch_reg
    cmovl scratch_reg, val_reg
    neg scratch_reg
ENDM

;-----------------------------------------------------------------------------
; BL_CLAMP - Branchless clamp to range [min, max]
;-----------------------------------------------------------------------------
; Parameters: val_reg - Value (modified)
;             min_reg - Minimum value
;             max_reg - Maximum value
;-----------------------------------------------------------------------------
BL_CLAMP MACRO val_reg, min_reg, max_reg
    cmp val_reg, min_reg
    cmovl val_reg, min_reg
    cmp val_reg, max_reg
    cmovg val_reg, max_reg
ENDM

BL_UCLAMP MACRO val_reg, min_reg, max_reg
    cmp val_reg, min_reg
    cmovb val_reg, min_reg
    cmp val_reg, max_reg
    cmova val_reg, max_reg
ENDM

;-----------------------------------------------------------------------------
; BL_SIGN - Extract sign (-1, 0, or 1)
;-----------------------------------------------------------------------------
; Parameters: val_reg - Input value
;             result_reg - Output (-1, 0, or 1)
;-----------------------------------------------------------------------------
BL_SIGN MACRO val_reg, result_reg
    mov result_reg, val_reg
    sar result_reg, 63                  ; -1 or 0
    shr val_reg, 63
    or result_reg, val_reg
ENDM

;-----------------------------------------------------------------------------
; BL_BOOL - Convert to boolean (0 or 1)
;-----------------------------------------------------------------------------
; Any non-zero becomes 1
;-----------------------------------------------------------------------------
BL_BOOL MACRO val_reg
    neg val_reg
    sbb val_reg, val_reg
    neg val_reg
ENDM

;; Alternative using comparison
BL_BOOL2 MACRO val_reg
    test val_reg, val_reg
    setne al
    movzx val_reg, al
ENDM

;-----------------------------------------------------------------------------
; BL_SELECT - Conditional select (like ternary operator)
;-----------------------------------------------------------------------------
; result = condition ? a : b
; Parameters: cond_reg - Condition (0 or non-zero)
;             a_reg - Value if true
;             b_reg - Value if false (receives result)
;-----------------------------------------------------------------------------
BL_SELECT MACRO cond_reg, a_reg, b_reg
    test cond_reg, cond_reg
    cmovnz b_reg, a_reg
ENDM

;; Select using mask generation
BL_SELECT_MASK MACRO cond_reg, a_reg, b_reg, scratch_reg
    neg cond_reg
    sbb scratch_reg, scratch_reg        ; -1 if cond, 0 otherwise
    and a_reg, scratch_reg
    not scratch_reg
    and b_reg, scratch_reg
    or b_reg, a_reg
ENDM

;-----------------------------------------------------------------------------
; BL_EQUAL - Branchless equality test
;-----------------------------------------------------------------------------
; Returns 0 if equal, non-zero if different
;-----------------------------------------------------------------------------
BL_EQUAL MACRO a_reg, b_reg, result_reg
    xor result_reg, result_reg
    cmp a_reg, b_reg
    sete result_reg
ENDM

;-----------------------------------------------------------------------------
; BL_SATURATE_ADD - Saturating unsigned add
;-----------------------------------------------------------------------------
; Adds without overflow - clamps to MAX value
;-----------------------------------------------------------------------------
BL_SATURATE_ADD MACRO a_reg, b_reg
    add a_reg, b_reg
    sbb b_reg, b_reg                    ; -1 if overflow, 0 otherwise
    or a_reg, b_reg                     ; Set all bits if overflow
ENDM

;-----------------------------------------------------------------------------
; BL_SATURATE_SUB - Saturating unsigned subtract
;-----------------------------------------------------------------------------
; Subtracts without underflow - clamps to 0
;-----------------------------------------------------------------------------
BL_SATURATE_SUB MACRO a_reg, b_reg
    sub a_reg, b_reg
    sbb b_reg, b_reg                    ; -1 if underflow
    and a_reg, b_reg
    not a_reg
ENDM

;-----------------------------------------------------------------------------
; BL_ROUNDUP_POW2 - Round up to next power of 2
;-----------------------------------------------------------------------------
; Parameters: val_reg - Value (modified)
;             scratch_reg - Scratch register
;-----------------------------------------------------------------------------
BL_ROUNDUP_POW2 MACRO val_reg, scratch_reg
    dec val_reg
    mov scratch_reg, val_reg
    shr scratch_reg, 1
    or val_reg, scratch_reg
    mov scratch_reg, val_reg
    shr scratch_reg, 2
    or val_reg, scratch_reg
    mov scratch_reg, val_reg
    shr scratch_reg, 4
    or val_reg, scratch_reg
    mov scratch_reg, val_reg
    shr scratch_reg, 8
    or val_reg, scratch_reg
    mov scratch_reg, val_reg
    shr scratch_reg, 16
    or val_reg, scratch_reg
    mov scratch_reg, val_reg
    shr scratch_reg, 32
    or val_reg, scratch_reg
    inc val_reg
ENDM

;-----------------------------------------------------------------------------
; BL_IS_POW2 - Check if value is power of 2
;-----------------------------------------------------------------------------
; Result: 1 if power of 2, 0 otherwise
;-----------------------------------------------------------------------------
BL_IS_POW2 MACRO val_reg, result_reg
    lea result_reg, [val_reg - 1]
    test val_reg, result_reg
    setz result_reg
    movzx result_reg, result_reg
ENDM

;-----------------------------------------------------------------------------
; BL_CTZ - Count trailing zeros (position of lowest set bit)
;-----------------------------------------------------------------------------
; Uses BSF instruction. Result undefined if input is 0.
;-----------------------------------------------------------------------------
BL_CTZ MACRO val_reg, result_reg
    bsf result_reg, val_reg
ENDM

;-----------------------------------------------------------------------------
; BL_CLZ - Count leading zeros
;-----------------------------------------------------------------------------
; Uses BSR instruction and subtraction.
;-----------------------------------------------------------------------------
BL_CLZ MACRO val_reg, result_reg
    bsr result_reg, val_reg
    xor result_reg, 63                  ; 63 - position = leading zeros
ENDM

;; Alternative using LZCNT if available (AMD and Intel Haswell+)
BL_LZCNT MACRO val_reg, result_reg
    lzcnt result_reg, val_reg
ENDM

;-----------------------------------------------------------------------------
; BL_POPCOUNT - Count set bits
;-----------------------------------------------------------------------------
; Uses POPCNT instruction (SSE4.2 required)
;-----------------------------------------------------------------------------
BL_POPCOUNT MACRO val_reg, result_reg
    popcnt result_reg, val_reg
ENDM

;; Software fallback for systems without POPCNT
BL_POPCOUNT_SW MACRO val_reg, scratch_reg
    ;; Sideways addition (SWAR technique)
    mov scratch_reg, val_reg
    shr scratch_reg, 1
    mov rax, 5555555555555555h
    and scratch_reg, rax
    sub val_reg, scratch_reg
    
    mov scratch_reg, val_reg
    shr scratch_reg, 2
    mov rax, 3333333333333333h
    and val_reg, rax
    and scratch_reg, rax
    add val_reg, scratch_reg
    
    mov scratch_reg, val_reg
    shr scratch_reg, 4
    add val_reg, scratch_reg
    mov rax, 0F0F0F0F0F0F0F0Fh
    and val_reg, rax
    
    mov rax, 0101010101010101h
    imul val_reg, rax
    shr val_reg, 56
ENDM

;-----------------------------------------------------------------------------
; BL_BLEND - Blend two values based on mask
;-----------------------------------------------------------------------------
; result = (a & mask) | (b & ~mask)
;-----------------------------------------------------------------------------
BL_BLEND MACRO a_reg, b_reg, mask_reg, result_reg
    mov result_reg, a_reg
    and result_reg, mask_reg
    not mask_reg
    and b_reg, mask_reg
    or result_reg, b_reg
    not mask_reg                        ; Restore mask
ENDM

;-----------------------------------------------------------------------------
; Function Prototypes for Complex Operations
;-----------------------------------------------------------------------------

; Branchless min of two signed 64-bit values
BL_Min64 PROTO a:QWORD, b:QWORD

; Branchless max of two signed 64-bit values
BL_Max64 PROTO a:QWORD, b:QWORD

; Branchless clamp
BL_Clamp64 PROTO value:QWORD, min_val:QWORD, max_val:QWORD

; Branchless absolute value
BL_Abs64 PROTO value:QWORD

; Branchless sign extraction
BL_Sign64 PROTO value:QWORD

; Branchless conditional select
BL_Select64 PROTO condition:QWORD, a:QWORD, b:QWORD

ENDIF ; BRANCHLESS64_INC

