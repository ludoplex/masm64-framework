;-----------------------------------------------------------------------------
; Console Application Template
;-----------------------------------------------------------------------------
; MASM64 Framework - Console Application
;
; To customize: Edit config.inc
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

;-----------------------------------------------------------------------------
; Project Configuration
;-----------------------------------------------------------------------------
INCLUDE config.inc

;-----------------------------------------------------------------------------
; Framework Includes
;-----------------------------------------------------------------------------
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
STD_OUTPUT_HANDLE       EQU -11

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

; Invoke the string definition macro from config.inc
DEFINE_STRINGS

;-----------------------------------------------------------------------------
; BSS Section
;-----------------------------------------------------------------------------
.DATA?

hStdOut     QWORD ?
dwWritten   DWORD ?

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; WinMain - Entry Point
;-----------------------------------------------------------------------------
WinMain PROC FRAME
    push rbp
    .pushreg rbp
    sub rsp, 48
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    ; Get stdout handle
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov hStdOut, rax
    
    ; Write message
    mov rcx, rax                        ; hConsoleOutput
    lea rdx, wszAppMessage              ; lpBuffer
    mov r8d, 28                         ; nNumberOfCharsToWrite
    lea r9, dwWritten                   ; lpNumberOfCharsWritten
    mov QWORD PTR [rsp + 32], 0         ; lpReserved
    call WriteConsoleW
    
    ; Write newline
    mov rcx, hStdOut
    lea rdx, wszNewLine
    mov r8d, 2
    lea r9, dwWritten
    mov QWORD PTR [rsp + 32], 0
    call WriteConsoleW
    
    ; Exit with success
    xor ecx, ecx
    call ExitProcess
    
    ; Never reached
    add rsp, 48
    pop rbp
    ret
WinMain ENDP

END
