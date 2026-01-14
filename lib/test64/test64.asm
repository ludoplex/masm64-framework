;-----------------------------------------------------------------------------
; test64.asm - Unit Testing Framework Implementation
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc
INCLUDE test64.inc

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF GetStdHandle:PROC
EXTERNDEF WriteConsoleA:PROC
EXTERNDEF wsprintfA:PROC

;-----------------------------------------------------------------------------
; Constants
;-----------------------------------------------------------------------------
STD_OUTPUT_HANDLE   EQU -11

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

g_Tests         TEST_CASE TEST_MAX_TESTS DUP(<>)
g_dwTestCount   DWORD 0
g_dwCurrentTest DWORD 0
g_bTestFailed   DWORD 0
g_Results       TEST_RESULTS <>

; Output strings
szTestStart     DB "[....] ", 0
szTestPass      DB "[PASS] ", 0
szTestFail      DB "[FAIL] ", 0
szTestSkip      DB "[SKIP] ", 0
szTestError     DB "[ERR!] ", 0
szNewLine       DB 13, 10, 0
szSummary       DB 13, 10, "Results: %d passed, %d failed, %d skipped", 13, 10, 0
szFailDetail    DB "       -> %s (line %d)", 13, 10, 0

.DATA?

g_hStdOut       QWORD ?
szBuffer        BYTE 512 DUP(?)
dwWritten       DWORD ?

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; Internal: Print string to console
;-----------------------------------------------------------------------------
PrintStr PROC FRAME
    push rbx
    .pushreg rbx
    sub rsp, 48
    .allocstack 48
    .endprolog
    
    mov rbx, rcx                        ; String
    
    ; Get length
    xor eax, eax
len_loop:
    cmp BYTE PTR [rbx + rax], 0
    je got_len
    inc eax
    jmp len_loop
got_len:
    mov r8d, eax                        ; Length
    
    mov rcx, g_hStdOut
    mov rdx, rbx
    lea r9, dwWritten
    mov QWORD PTR [rsp + 32], 0
    call WriteConsoleA
    
    add rsp, 48
    pop rbx
    ret
PrintStr ENDP

;-----------------------------------------------------------------------------
; Test_Register - Register a test
;-----------------------------------------------------------------------------
Test_Register PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; RCX = pName, RDX = pfnTest
    xor r8d, r8d                        ; pfnSetup = NULL
    xor r9d, r9d                        ; pfnTeardown = NULL
    call Test_RegisterFull
    
    add rsp, SHADOW_SPACE
    ret
Test_Register ENDP

;-----------------------------------------------------------------------------
; Test_RegisterFull - Register test with setup/teardown
;-----------------------------------------------------------------------------
Test_RegisterFull PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov eax, g_dwTestCount
    cmp eax, TEST_MAX_TESTS
    jge full
    
    ; Calculate offset into array
    imul eax, SIZEOF TEST_CASE
    lea r10, g_Tests
    add r10, rax
    
    ; Store test info
    mov [r10].TEST_CASE.pName, rcx
    mov [r10].TEST_CASE.pfnTest, rdx
    mov [r10].TEST_CASE.pfnSetup, r8
    mov [r10].TEST_CASE.pfnTeardown, r9
    mov [r10].TEST_CASE.dwResult, TEST_PASS
    mov [r10].TEST_CASE.dwLine, 0
    mov QWORD PTR [r10].TEST_CASE.pFile, 0
    mov QWORD PTR [r10].TEST_CASE.pMessage, 0
    
    mov eax, g_dwTestCount
    inc g_dwTestCount
    jmp done
    
full:
    mov eax, -1
    
done:
    add rsp, SHADOW_SPACE
    ret
Test_RegisterFull ENDP

;-----------------------------------------------------------------------------
; Test_RunAll - Run all tests
;-----------------------------------------------------------------------------
Test_RunAll PROC FRAME
    LOCAL dwIndex:DWORD
    LOCAL dwFailures:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 64
    .allocstack 64
    .endprolog
    
    ; Initialize
    mov dwFailures, 0
    mov g_Results.dwTotal, 0
    mov g_Results.dwPassed, 0
    mov g_Results.dwFailed, 0
    mov g_Results.dwSkipped, 0
    mov g_Results.dwErrors, 0
    
    ; Get stdout handle
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov g_hStdOut, rax
    
    ; Run each test
    mov dwIndex, 0
run_loop:
    mov eax, dwIndex
    cmp eax, g_dwTestCount
    jge done_tests
    
    ; Run single test
    mov ecx, eax
    call Test_RunOne
    
    cmp eax, TEST_FAIL
    jne not_fail
    inc dwFailures
    
not_fail:
    inc dwIndex
    jmp run_loop
    
done_tests:
    ; Print summary
    lea rcx, szBuffer
    lea rdx, szSummary
    mov r8d, g_Results.dwPassed
    mov r9d, g_Results.dwFailed
    mov eax, g_Results.dwSkipped
    mov [rsp + 32], rax
    call wsprintfA
    
    lea rcx, szBuffer
    call PrintStr
    
    mov eax, dwFailures
    
    add rsp, 64
    pop rsi
    pop rdi
    pop rbx
    ret
Test_RunAll ENDP

;-----------------------------------------------------------------------------
; Test_RunOne - Run single test
;-----------------------------------------------------------------------------
Test_RunOne PROC FRAME
    LOCAL pTest:QWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 56
    .allocstack 56
    .endprolog
    
    mov g_dwCurrentTest, ecx
    mov g_bTestFailed, 0
    inc g_Results.dwTotal
    
    ; Get test pointer
    imul ecx, SIZEOF TEST_CASE
    lea rax, g_Tests
    add rax, rcx
    mov pTest, rax
    mov rdi, rax
    
    ; Print test start
    lea rcx, szTestStart
    call PrintStr
    
    ; Print test name
    mov rcx, [rdi].TEST_CASE.pName
    call PrintStr
    
    ; Call setup if present
    mov rax, [rdi].TEST_CASE.pfnSetup
    test rax, rax
    jz no_setup
    call rax
no_setup:
    
    ; Call test function
    mov rax, [rdi].TEST_CASE.pfnTest
    call rax
    mov ebx, eax                        ; Save result
    
    ; Call teardown if present
    mov rax, [rdi].TEST_CASE.pfnTeardown
    test rax, rax
    jz no_teardown
    call rax
no_teardown:
    
    ; Check if test failed via Test_Fail call
    cmp g_bTestFailed, 0
    jne was_failed
    
    ; Test returned, check return value
    test ebx, ebx
    jnz test_failed
    
    ; Test passed
    mov [rdi].TEST_CASE.dwResult, TEST_PASS
    inc g_Results.dwPassed
    
    ; Overwrite "[....]" with "[PASS]"
    lea rcx, szNewLine
    call PrintStr
    jmp done
    
was_failed:
test_failed:
    mov [rdi].TEST_CASE.dwResult, TEST_FAIL
    inc g_Results.dwFailed
    
    lea rcx, szNewLine
    call PrintStr
    
    ; Print failure details if available
    mov rax, [rdi].TEST_CASE.pMessage
    test rax, rax
    jz done
    
    lea rcx, szBuffer
    lea rdx, szFailDetail
    mov r8, [rdi].TEST_CASE.pMessage
    mov r9d, [rdi].TEST_CASE.dwLine
    call wsprintfA
    
    lea rcx, szBuffer
    call PrintStr
    
done:
    mov eax, [rdi].TEST_CASE.dwResult
    
    add rsp, 56
    pop rdi
    pop rbx
    ret
Test_RunOne ENDP

;-----------------------------------------------------------------------------
; Test_Fail - Mark current test as failed
;-----------------------------------------------------------------------------
Test_Fail PROC
    ; RCX = pMessage, EDX = dwLine
    mov g_bTestFailed, 1
    
    mov eax, g_dwCurrentTest
    imul eax, SIZEOF TEST_CASE
    lea r8, g_Tests
    add r8, rax
    
    mov [r8].TEST_CASE.pMessage, rcx
    mov [r8].TEST_CASE.dwLine, edx
    mov [r8].TEST_CASE.dwResult, TEST_FAIL
    
    ret
Test_Fail ENDP

;-----------------------------------------------------------------------------
; Test_Skip - Mark current test as skipped
;-----------------------------------------------------------------------------
Test_Skip PROC
    mov eax, g_dwCurrentTest
    imul eax, SIZEOF TEST_CASE
    lea rdx, g_Tests
    add rdx, rax
    
    mov [rdx].TEST_CASE.pMessage, rcx
    mov [rdx].TEST_CASE.dwResult, TEST_SKIP
    inc g_Results.dwSkipped
    
    ret
Test_Skip ENDP

;-----------------------------------------------------------------------------
; Test_GetResults - Get test results
;-----------------------------------------------------------------------------
Test_GetResults PROC
    test rcx, rcx
    jz done
    
    lea rax, g_Results
    mov rdx, [rax]
    mov [rcx], rdx
    mov rdx, [rax + 8]
    mov [rcx + 8], rdx
    mov eax, [rax + 16]
    mov [rcx + 16], eax
    
done:
    ret
Test_GetResults ENDP

;-----------------------------------------------------------------------------
; Test_Reset - Reset all tests
;-----------------------------------------------------------------------------
Test_Reset PROC
    mov g_dwTestCount, 0
    mov g_dwCurrentTest, 0
    mov g_bTestFailed, 0
    xor eax, eax
    mov g_Results.dwTotal, eax
    mov g_Results.dwPassed, eax
    mov g_Results.dwFailed, eax
    mov g_Results.dwSkipped, eax
    mov g_Results.dwErrors, eax
    ret
Test_Reset ENDP

END

