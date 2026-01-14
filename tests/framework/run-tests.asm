;-----------------------------------------------------------------------------
; run-tests.asm - Framework Unit Tests
;-----------------------------------------------------------------------------
; Tests for core framework functionality
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc
INCLUDE ..\..\lib\test64\test64.inc
INCLUDE ..\..\lib\branchless64\branchless64.inc

EXTERNDEF ExitProcess:PROC

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

szTestMin       DB "BL_Min64", 0
szTestMax       DB "BL_Max64", 0
szTestAbs       DB "BL_Abs64", 0
szTestClamp     DB "BL_Clamp64", 0
szTestSelect    DB "BL_Select64", 0
szTestStackAlign DB "Stack Alignment", 0

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; Test: Branchless Min
;-----------------------------------------------------------------------------
Test_BL_Min PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    ; Test min(5, 10) = 5
    mov rcx, 5
    mov rdx, 10
    call BL_Min64
    cmp rax, 5
    jne fail
    
    ; Test min(10, 5) = 5
    mov rcx, 10
    mov rdx, 5
    call BL_Min64
    cmp rax, 5
    jne fail
    
    ; Test min(-5, 5) = -5
    mov rcx, -5
    mov rdx, 5
    call BL_Min64
    cmp rax, -5
    jne fail
    
    xor eax, eax
    jmp done
    
fail:
    mov eax, 1
    
done:
    add rsp, 40
    ret
Test_BL_Min ENDP

;-----------------------------------------------------------------------------
; Test: Branchless Max
;-----------------------------------------------------------------------------
Test_BL_Max PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    ; Test max(5, 10) = 10
    mov rcx, 5
    mov rdx, 10
    call BL_Max64
    cmp rax, 10
    jne fail
    
    ; Test max(-5, -10) = -5
    mov rcx, -5
    mov rdx, -10
    call BL_Max64
    cmp rax, -5
    jne fail
    
    xor eax, eax
    jmp done
    
fail:
    mov eax, 1
    
done:
    add rsp, 40
    ret
Test_BL_Max ENDP

;-----------------------------------------------------------------------------
; Test: Branchless Abs
;-----------------------------------------------------------------------------
Test_BL_Abs PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    ; Test abs(5) = 5
    mov rcx, 5
    call BL_Abs64
    cmp rax, 5
    jne fail
    
    ; Test abs(-5) = 5
    mov rcx, -5
    call BL_Abs64
    cmp rax, 5
    jne fail
    
    ; Test abs(0) = 0
    xor ecx, ecx
    call BL_Abs64
    test rax, rax
    jnz fail
    
    xor eax, eax
    jmp done
    
fail:
    mov eax, 1
    
done:
    add rsp, 40
    ret
Test_BL_Abs ENDP

;-----------------------------------------------------------------------------
; Test: Branchless Clamp
;-----------------------------------------------------------------------------
Test_BL_Clamp PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    ; Test clamp(5, 0, 10) = 5
    mov rcx, 5
    mov rdx, 0
    mov r8, 10
    call BL_Clamp64
    cmp rax, 5
    jne fail
    
    ; Test clamp(-5, 0, 10) = 0
    mov rcx, -5
    mov rdx, 0
    mov r8, 10
    call BL_Clamp64
    test rax, rax
    jnz fail
    
    ; Test clamp(15, 0, 10) = 10
    mov rcx, 15
    mov rdx, 0
    mov r8, 10
    call BL_Clamp64
    cmp rax, 10
    jne fail
    
    xor eax, eax
    jmp done
    
fail:
    mov eax, 1
    
done:
    add rsp, 40
    ret
Test_BL_Clamp ENDP

;-----------------------------------------------------------------------------
; Test: Branchless Select
;-----------------------------------------------------------------------------
Test_BL_Select PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    ; Test select(1, 100, 200) = 100
    mov rcx, 1
    mov rdx, 100
    mov r8, 200
    call BL_Select64
    cmp rax, 100
    jne fail
    
    ; Test select(0, 100, 200) = 200
    xor ecx, ecx
    mov rdx, 100
    mov r8, 200
    call BL_Select64
    cmp rax, 200
    jne fail
    
    xor eax, eax
    jmp done
    
fail:
    mov eax, 1
    
done:
    add rsp, 40
    ret
Test_BL_Select ENDP

;-----------------------------------------------------------------------------
; Test: Stack Alignment
;-----------------------------------------------------------------------------
Test_StackAlign PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    ; Check RSP is 16-byte aligned
    mov rax, rsp
    and rax, 0Fh
    test rax, rax
    jnz fail
    
    xor eax, eax
    jmp done
    
fail:
    mov eax, 1
    
done:
    add rsp, 40
    ret
Test_StackAlign ENDP

;-----------------------------------------------------------------------------
; WinMain - Entry Point
;-----------------------------------------------------------------------------
WinMain PROC FRAME
    sub rsp, 56
    .allocstack 56
    .endprolog
    
    ; Register tests
    lea rcx, szTestMin
    lea rdx, Test_BL_Min
    call Test_Register
    
    lea rcx, szTestMax
    lea rdx, Test_BL_Max
    call Test_Register
    
    lea rcx, szTestAbs
    lea rdx, Test_BL_Abs
    call Test_Register
    
    lea rcx, szTestClamp
    lea rdx, Test_BL_Clamp
    call Test_Register
    
    lea rcx, szTestSelect
    lea rdx, Test_BL_Select
    call Test_Register
    
    lea rcx, szTestStackAlign
    lea rdx, Test_StackAlign
    call Test_Register
    
    ; Run all tests
    call Test_RunAll
    
    ; Exit with failure count
    mov ecx, eax
    call ExitProcess
    
    add rsp, 56
    ret
WinMain ENDP

END

