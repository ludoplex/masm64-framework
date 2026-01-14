;-----------------------------------------------------------------------------
; test64.inc - Unit Testing Framework for MASM64
;-----------------------------------------------------------------------------
; Provides test case definition, assertions, and result reporting.
;
; Features:
;   - Test case registration
;   - Rich assertion macros
;   - Pass/fail tracking
;   - Failure details (file/line)
;   - Setup/teardown support
;   - Test suites
;
; Usage:
;   1. Include test64.inc
;   2. Define test functions
;   3. Register tests with TEST_REGISTER
;   4. Call Test_RunAll from main
;-----------------------------------------------------------------------------

IFNDEF TEST64_INC
TEST64_INC EQU 1

;-----------------------------------------------------------------------------
; Test Result Codes
;-----------------------------------------------------------------------------
TEST_PASS       EQU 0
TEST_FAIL       EQU 1
TEST_SKIP       EQU 2
TEST_ERROR      EQU 3

;-----------------------------------------------------------------------------
; Maximum values
;-----------------------------------------------------------------------------
TEST_MAX_TESTS      EQU 256
TEST_MAX_NAME_LEN   EQU 64

;-----------------------------------------------------------------------------
; TEST_CASE structure
;-----------------------------------------------------------------------------
TEST_CASE STRUCT
    pName       QWORD ?                 ; Test name (ANSI string)
    pfnTest     QWORD ?                 ; Test function pointer
    pfnSetup    QWORD ?                 ; Setup function (optional)
    pfnTeardown QWORD ?                 ; Teardown function (optional)
    dwResult    DWORD ?                 ; Test result
    dwLine      DWORD ?                 ; Line of failure (if failed)
    pFile       QWORD ?                 ; File of failure
    pMessage    QWORD ?                 ; Failure message
TEST_CASE ENDS

;-----------------------------------------------------------------------------
; TEST_RESULTS structure
;-----------------------------------------------------------------------------
TEST_RESULTS STRUCT
    dwTotal     DWORD ?
    dwPassed    DWORD ?
    dwFailed    DWORD ?
    dwSkipped   DWORD ?
    dwErrors    DWORD ?
TEST_RESULTS ENDS

;-----------------------------------------------------------------------------
; Function Prototypes
;-----------------------------------------------------------------------------

; Register a test case
; Parameters: pName - Test name
;             pfnTest - Test function (returns 0 for pass)
; Returns: Test index, or -1 on failure
Test_Register PROTO pName:QWORD, pfnTest:QWORD

; Register test with setup/teardown
Test_RegisterFull PROTO pName:QWORD, pfnTest:QWORD, pfnSetup:QWORD, pfnTeardown:QWORD

; Run all registered tests
; Returns: Number of failures
Test_RunAll PROTO

; Run a single test by index
; Returns: TEST_* result code
Test_RunOne PROTO dwIndex:DWORD

; Get test results
; Parameters: pResults - Pointer to TEST_RESULTS structure
Test_GetResults PROTO pResults:QWORD

; Reset all tests
Test_Reset PROTO

; Set current test as failed
; Parameters: pMessage - Failure message
;             dwLine - Line number
Test_Fail PROTO pMessage:QWORD, dwLine:DWORD

; Mark current test as skipped
Test_Skip PROTO pReason:QWORD

;-----------------------------------------------------------------------------
; Assertion Macros
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; TEST_ASSERT - Basic assertion
;-----------------------------------------------------------------------------
TEST_ASSERT MACRO condition_jmp
    LOCAL pass
    condition_jmp pass
    lea rcx, @CatStr(<"Assertion failed at line ">, %@Line, <" in ">, @FileCur)
    mov edx, @Line
    call Test_Fail
pass:
ENDM

;-----------------------------------------------------------------------------
; TEST_ASSERT_EQ - Assert equality
;-----------------------------------------------------------------------------
TEST_ASSERT_EQ MACRO expected, actual
    LOCAL pass
    cmp expected, actual
    je pass
    lea rcx, @CatStr(<"Expected ">, <expected>, <" == ">, <actual>)
    mov edx, @Line
    call Test_Fail
pass:
ENDM

;-----------------------------------------------------------------------------
; TEST_ASSERT_NE - Assert not equal
;-----------------------------------------------------------------------------
TEST_ASSERT_NE MACRO val1, val2
    LOCAL pass
    cmp val1, val2
    jne pass
    lea rcx, @CatStr(<"Expected ">, <val1>, <" != ">, <val2>)
    mov edx, @Line
    call Test_Fail
pass:
ENDM

;-----------------------------------------------------------------------------
; TEST_ASSERT_TRUE - Assert non-zero
;-----------------------------------------------------------------------------
TEST_ASSERT_TRUE MACRO value_reg
    LOCAL pass
    test value_reg, value_reg
    jnz pass
    lea rcx, @CatStr(<"Expected TRUE, got FALSE at line ">, %@Line)
    mov edx, @Line
    call Test_Fail
pass:
ENDM

;-----------------------------------------------------------------------------
; TEST_ASSERT_FALSE - Assert zero
;-----------------------------------------------------------------------------
TEST_ASSERT_FALSE MACRO value_reg
    LOCAL pass
    test value_reg, value_reg
    jz pass
    lea rcx, @CatStr(<"Expected FALSE, got TRUE at line ">, %@Line)
    mov edx, @Line
    call Test_Fail
pass:
ENDM

;-----------------------------------------------------------------------------
; TEST_ASSERT_NULL - Assert NULL pointer
;-----------------------------------------------------------------------------
TEST_ASSERT_NULL MACRO ptr_reg
    LOCAL pass
    test ptr_reg, ptr_reg
    jz pass
    lea rcx, @CatStr(<"Expected NULL at line ">, %@Line)
    mov edx, @Line
    call Test_Fail
pass:
ENDM

;-----------------------------------------------------------------------------
; TEST_ASSERT_NOT_NULL - Assert non-NULL pointer
;-----------------------------------------------------------------------------
TEST_ASSERT_NOT_NULL MACRO ptr_reg
    LOCAL pass
    test ptr_reg, ptr_reg
    jnz pass
    lea rcx, @CatStr(<"Expected non-NULL at line ">, %@Line)
    mov edx, @Line
    call Test_Fail
pass:
ENDM

;-----------------------------------------------------------------------------
; TEST_ASSERT_LT - Assert less than
;-----------------------------------------------------------------------------
TEST_ASSERT_LT MACRO a_reg, b_reg
    LOCAL pass
    cmp a_reg, b_reg
    jl pass
    lea rcx, @CatStr(<"Expected less than at line ">, %@Line)
    mov edx, @Line
    call Test_Fail
pass:
ENDM

;-----------------------------------------------------------------------------
; TEST_ASSERT_LE - Assert less than or equal
;-----------------------------------------------------------------------------
TEST_ASSERT_LE MACRO a_reg, b_reg
    LOCAL pass
    cmp a_reg, b_reg
    jle pass
    lea rcx, @CatStr(<"Expected <= at line ">, %@Line)
    mov edx, @Line
    call Test_Fail
pass:
ENDM

;-----------------------------------------------------------------------------
; TEST_ASSERT_GT - Assert greater than
;-----------------------------------------------------------------------------
TEST_ASSERT_GT MACRO a_reg, b_reg
    LOCAL pass
    cmp a_reg, b_reg
    jg pass
    lea rcx, @CatStr(<"Expected > at line ">, %@Line)
    mov edx, @Line
    call Test_Fail
pass:
ENDM

;-----------------------------------------------------------------------------
; TEST_ASSERT_GE - Assert greater than or equal
;-----------------------------------------------------------------------------
TEST_ASSERT_GE MACRO a_reg, b_reg
    LOCAL pass
    cmp a_reg, b_reg
    jge pass
    lea rcx, @CatStr(<"Expected >= at line ">, %@Line)
    mov edx, @Line
    call Test_Fail
pass:
ENDM

;-----------------------------------------------------------------------------
; TEST_ASSERT_MEM_EQ - Assert memory regions are equal
;-----------------------------------------------------------------------------
; Compares cbSize bytes starting at pMem1 and pMem2
;-----------------------------------------------------------------------------
TEST_ASSERT_MEM_EQ MACRO pMem1, pMem2, cbSize
    LOCAL pass, compare_loop
    push rsi
    push rdi
    push rcx
    
    mov rsi, pMem1
    mov rdi, pMem2
    mov rcx, cbSize
    
compare_loop:
    test rcx, rcx
    jz pass
    mov al, [rsi]
    cmp al, [rdi]
    jne mem_fail
    inc rsi
    inc rdi
    dec rcx
    jmp compare_loop
    
mem_fail:
    pop rcx
    pop rdi
    pop rsi
    lea rcx, @CatStr(<"Memory comparison failed at line ">, %@Line)
    mov edx, @Line
    call Test_Fail
    jmp @F
    
pass:
    pop rcx
    pop rdi
    pop rsi
@@:
ENDM

;-----------------------------------------------------------------------------
; TEST_BEGIN / TEST_END - Test function wrapper
;-----------------------------------------------------------------------------
TEST_BEGIN MACRO test_name
    test_name PROC FRAME
    push rbp
    .pushreg rbp
    sub rsp, 48
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
ENDM

TEST_END MACRO test_name
    ; Return success if we got here
    xor eax, eax
    add rsp, 48
    pop rbp
    ret
    test_name ENDP
ENDM

ENDIF ; TEST64_INC

