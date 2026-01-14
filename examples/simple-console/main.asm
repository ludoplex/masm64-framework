;-----------------------------------------------------------------------------
; Simple Console Example
;-----------------------------------------------------------------------------
; Demonstrates basic console output using framework macros
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF GetStdHandle:PROC
EXTERNDEF WriteConsoleW:PROC
EXTERNDEF ExitProcess:PROC

;-----------------------------------------------------------------------------
; Constants
;-----------------------------------------------------------------------------
STD_OUTPUT_HANDLE   EQU -11

;-----------------------------------------------------------------------------
; Data
;-----------------------------------------------------------------------------
.DATA

WSTR szMessage, "Simple Console Example"
WSTR szNewLine, 13, 10

;-----------------------------------------------------------------------------
; Code
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; PrintLine - Print a line to console
;-----------------------------------------------------------------------------
; Parameters: RCX = String pointer, RDX = Length
;-----------------------------------------------------------------------------
PrintLine PROC FRAME
    LOCAL hStdOut:QWORD
    LOCAL dwWritten:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 48
    .allocstack 48
    .endprolog
    
    mov rdi, rcx                        ; String
    mov esi, edx                        ; Length
    
    ; Get stdout
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov hStdOut, rax
    
    ; Write string
    mov rcx, rax
    mov rdx, rdi
    mov r8d, esi
    lea r9, dwWritten
    mov QWORD PTR [rsp + 32], 0
    call WriteConsoleW
    
    ; Write newline
    mov rcx, hStdOut
    lea rdx, szNewLine
    mov r8d, 2
    lea r9, dwWritten
    mov QWORD PTR [rsp + 32], 0
    call WriteConsoleW
    
    add rsp, 48
    pop rsi
    pop rdi
    pop rbx
    ret
PrintLine ENDP

;-----------------------------------------------------------------------------
; WinMain - Entry Point
;-----------------------------------------------------------------------------
WinMain PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    ; Print message
    lea rcx, szMessage
    mov edx, 22                         ; Length of "Simple Console Example"
    call PrintLine
    
    ; Exit
    xor ecx, ecx
    call ExitProcess
    
    add rsp, 40
    ret
WinMain ENDP

END

