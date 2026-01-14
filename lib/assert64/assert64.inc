;-----------------------------------------------------------------------------
; assert64.inc - Enhanced Assertion and Validation Library
;-----------------------------------------------------------------------------
; Provides compile-time and runtime assertions, parameter validation,
; and contract programming (preconditions/postconditions).
;
; Assertion Types:
;   ASSERT      - Debug-only runtime assertion
;   REQUIRE     - Always-active precondition check
;   ENSURE      - Always-active postcondition check
;   STATIC_ASSERT - Compile-time assertion
;   ASSUME      - Optimizer hint (no code generated)
;
; Validation Macros:
;   VALIDATE_PTR     - Check pointer is non-NULL
;   VALIDATE_HANDLE  - Check handle is valid
;   VALIDATE_RANGE   - Check value is in range
;   VALIDATE_ALIGNED - Check pointer alignment
;-----------------------------------------------------------------------------

IFNDEF ASSERT64_INC
ASSERT64_INC EQU 1

;-----------------------------------------------------------------------------
; Configuration
;-----------------------------------------------------------------------------
; Define NDEBUG to disable debug assertions
; Define ASSERT_HANDLER to use custom assertion handler
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; STATIC_ASSERT - Compile-time assertion
;-----------------------------------------------------------------------------
; Usage: STATIC_ASSERT <condition>, <message>
; Example: STATIC_ASSERT (SIZEOF MYSTRUCT EQ 64), "MYSTRUCT size mismatch"
;
; Generates compile error if condition is false.
;-----------------------------------------------------------------------------
STATIC_ASSERT MACRO condition, message
    IF NOT (condition)
        .ERR <STATIC_ASSERT failed: message>
    ENDIF
ENDM

;-----------------------------------------------------------------------------
; ASSERT - Debug-only runtime assertion
;-----------------------------------------------------------------------------
; Disabled when NDEBUG is defined. Use for invariant checks.
; Parameters: 
;   condition - Comparison that sets flags (e.g., test rax, rax)
;   jmp_type  - Jump if FALSE (e.g., jz, je, jl)
;
; Example:
;   test rax, rax
;   ASSERT jnz                    ; Assert RAX != 0
;-----------------------------------------------------------------------------
IFNDEF NDEBUG

ASSERT MACRO jmp_condition
    LOCAL assert_ok
    jmp_condition assert_ok
    int 3                               ; Debug break
assert_ok:
ENDM

ASSERT_MSG MACRO jmp_condition, msg_addr
    LOCAL assert_ok
    jmp_condition assert_ok
    lea rcx, msg_addr
    call Assert_Handler
assert_ok:
ENDM

;; Assert with expression evaluation
ASSERT_EXPR MACRO expr, jmp_condition
    LOCAL assert_ok
    expr
    jmp_condition assert_ok
    int 3
assert_ok:
ENDM

;; Assert RAX is non-zero
ASSERT_RAX MACRO
    LOCAL assert_ok
    test rax, rax
    jnz assert_ok
    int 3
assert_ok:
ENDM

;; Assert RCX is non-zero (common for this pointer/first arg)
ASSERT_RCX MACRO
    LOCAL assert_ok
    test rcx, rcx
    jnz assert_ok
    int 3
assert_ok:
ENDM

;; Assert stack is 16-byte aligned
ASSERT_STACK_ALIGNED MACRO
    LOCAL assert_ok
    push rax
    mov rax, rsp
    add rax, 8                          ; Account for the push
    test al, 0Fh
    pop rax
    jz assert_ok
    int 3
assert_ok:
ENDM

ELSE ; NDEBUG defined - assertions become no-ops

ASSERT MACRO jmp_condition
ENDM

ASSERT_MSG MACRO jmp_condition, msg_addr
ENDM

ASSERT_EXPR MACRO expr, jmp_condition
ENDM

ASSERT_RAX MACRO
ENDM

ASSERT_RCX MACRO
ENDM

ASSERT_STACK_ALIGNED MACRO
ENDM

ENDIF ; NDEBUG

;-----------------------------------------------------------------------------
; REQUIRE - Always-active precondition check
;-----------------------------------------------------------------------------
; Never disabled. Use for validating function inputs.
; On failure, calls error handler or returns error code.
;-----------------------------------------------------------------------------
REQUIRE MACRO condition_reg, jmp_if_valid, error_label
    test condition_reg, condition_reg
    jmp_if_valid @F
    jmp error_label
@@:
ENDM

REQUIRE_NONNULL MACRO ptr_reg, error_label
    test ptr_reg, ptr_reg
    jnz @F
    jmp error_label
@@:
ENDM

REQUIRE_VALID_HANDLE MACRO handle_reg, error_label
    cmp handle_reg, -1                  ; INVALID_HANDLE_VALUE
    jne @F
    jmp error_label
@@:
ENDM

;-----------------------------------------------------------------------------
; ENSURE - Always-active postcondition check
;-----------------------------------------------------------------------------
; Use to validate function outputs before returning.
;-----------------------------------------------------------------------------
ENSURE MACRO condition_reg, jmp_if_valid
    LOCAL ensure_ok
    test condition_reg, condition_reg
    jmp_if_valid ensure_ok
    int 3                               ; Should not happen
ensure_ok:
ENDM

;-----------------------------------------------------------------------------
; ASSUME - Optimizer hint
;-----------------------------------------------------------------------------
; Tells the assembler/optimizer to assume a condition is true.
; No code is generated; purely for documentation and future optimizers.
;-----------------------------------------------------------------------------
ASSUME_ALIGNED MACRO reg, alignment
    ;; Documentation only - no code generated
    ;; Future: could integrate with UASM optimization hints
ENDM

ASSUME_NONNULL MACRO reg
    ;; Documentation only
ENDM

;-----------------------------------------------------------------------------
; VALIDATE_PTR - Validate pointer is non-NULL
;-----------------------------------------------------------------------------
; Parameters: ptr_reg - Register containing pointer
;             fail_action - Code to execute on failure (optional)
;-----------------------------------------------------------------------------
VALIDATE_PTR MACRO ptr_reg, fail_action
    LOCAL valid
    test ptr_reg, ptr_reg
    jnz valid
    IFNB <fail_action>
        fail_action
    ELSE
        xor eax, eax
        ret
    ENDIF
valid:
ENDM

;-----------------------------------------------------------------------------
; VALIDATE_HANDLE - Validate handle is not INVALID_HANDLE_VALUE
;-----------------------------------------------------------------------------
VALIDATE_HANDLE MACRO handle_reg, fail_action
    LOCAL valid
    cmp handle_reg, -1
    jne valid
    IFNB <fail_action>
        fail_action
    ELSE
        xor eax, eax
        ret
    ENDIF
valid:
ENDM

;-----------------------------------------------------------------------------
; VALIDATE_RANGE - Validate value is within range [min, max]
;-----------------------------------------------------------------------------
; Parameters: val_reg - Register with value
;             min_val - Minimum (inclusive)
;             max_val - Maximum (inclusive)
;-----------------------------------------------------------------------------
VALIDATE_RANGE MACRO val_reg, min_val, max_val, fail_action
    LOCAL valid
    cmp val_reg, min_val
    jl @F
    cmp val_reg, max_val
    jle valid
@@:
    IFNB <fail_action>
        fail_action
    ELSE
        xor eax, eax
        ret
    ENDIF
valid:
ENDM

;-----------------------------------------------------------------------------
; VALIDATE_ALIGNED - Validate pointer alignment
;-----------------------------------------------------------------------------
; Parameters: ptr_reg - Register containing pointer
;             alignment - Required alignment (power of 2)
;-----------------------------------------------------------------------------
VALIDATE_ALIGNED MACRO ptr_reg, alignment, fail_action
    LOCAL valid
    test ptr_reg, alignment - 1
    jz valid
    IFNB <fail_action>
        fail_action
    ELSE
        xor eax, eax
        ret
    ENDIF
valid:
ENDM

;-----------------------------------------------------------------------------
; CONTRACT_BEGIN / CONTRACT_END - Design by Contract pattern
;-----------------------------------------------------------------------------
; Use to document and enforce function contracts.
;
; Example:
;   MyFunc PROC FRAME
;       CONTRACT_BEGIN
;           REQUIRE_NONNULL rcx, contract_fail
;           REQUIRE_NONNULL rdx, contract_fail
;       CONTRACT_END
;       ; ... function body ...
;       jmp done
;   contract_fail:
;       xor eax, eax
;       ret
;   done:
;       ; ...
;   MyFunc ENDP
;-----------------------------------------------------------------------------
CONTRACT_BEGIN MACRO
ENDM

CONTRACT_END MACRO
ENDM

;-----------------------------------------------------------------------------
; Function Prototypes
;-----------------------------------------------------------------------------

; Default assertion handler (can be replaced)
; Parameters: RCX = Message string (optional)
Assert_Handler PROTO pMessage:QWORD

; Set custom assertion handler
; Parameters: RCX = Function pointer for new handler
Assert_SetHandler PROTO pfnHandler:QWORD

; Get current assertion count (for testing)
Assert_GetCount PROTO

; Reset assertion count
Assert_ResetCount PROTO

ENDIF ; ASSERT64_INC

