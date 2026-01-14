;-----------------------------------------------------------------------------
; assert64.asm - Enhanced Assertion Library Implementation
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc
INCLUDE assert64.inc

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF OutputDebugStringA:PROC
EXTERNDEF IsDebuggerPresent:PROC
EXTERNDEF DebugBreak:PROC
EXTERNDEF MessageBoxA:PROC

;-----------------------------------------------------------------------------
; Constants
;-----------------------------------------------------------------------------
MB_ICONERROR        EQU 10h
MB_ABORTRETRYIGNORE EQU 2
IDABORT             EQU 3
IDRETRY             EQU 4
IDIGNORE            EQU 5

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

g_pfnAssertHandler  QWORD 0             ; Custom handler pointer
g_dwAssertCount     DWORD 0             ; Assertion failure count

szDefaultMsg    DB "Assertion failed!", 0
szAssertTitle   DB "MASM64 Assertion", 0
szDebugPrefix   DB "[ASSERT] ", 0

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; Assert_Handler - Default assertion handler
;-----------------------------------------------------------------------------
; Parameters: RCX = Message string (or NULL for default)
; Behavior: 
;   1. Increments assertion counter
;   2. Outputs to debug console
;   3. If debugger present, breaks
;   4. Otherwise, shows message box
;-----------------------------------------------------------------------------
Assert_Handler PROC FRAME
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 56
    .allocstack 56
    .endprolog
    
    mov rdi, rcx                        ; Save message
    
    ; Increment counter
    lock inc g_dwAssertCount
    
    ; Check for custom handler
    mov rax, g_pfnAssertHandler
    test rax, rax
    jz use_default
    
    ; Call custom handler
    mov rcx, rdi
    call rax
    jmp done
    
use_default:
    ; Output to debug console
    lea rcx, szDebugPrefix
    call OutputDebugStringA
    
    test rdi, rdi
    jz use_default_msg
    mov rcx, rdi
    jmp output_msg
use_default_msg:
    lea rcx, szDefaultMsg
output_msg:
    call OutputDebugStringA
    
    ; Check if debugger present
    call IsDebuggerPresent
    test eax, eax
    jz show_msgbox
    
    ; Break into debugger
    call DebugBreak
    jmp done
    
show_msgbox:
    ; MessageBoxA(NULL, msg, title, MB_ICONERROR | MB_ABORTRETRYIGNORE)
    xor ecx, ecx
    test rdi, rdi
    jz use_default_msg2
    mov rdx, rdi
    jmp do_msgbox
use_default_msg2:
    lea rdx, szDefaultMsg
do_msgbox:
    lea r8, szAssertTitle
    mov r9d, MB_ICONERROR OR MB_ABORTRETRYIGNORE
    call MessageBoxA
    
    ; Handle response
    cmp eax, IDRETRY
    jne check_abort
    call DebugBreak                     ; Try to attach debugger
    jmp done
    
check_abort:
    cmp eax, IDABORT
    jne done
    ; Could call ExitProcess here
    
done:
    add rsp, 56
    pop rdi
    pop rbx
    ret
Assert_Handler ENDP

;-----------------------------------------------------------------------------
; Assert_SetHandler - Set custom assertion handler
;-----------------------------------------------------------------------------
Assert_SetHandler PROC
    mov g_pfnAssertHandler, rcx
    ret
Assert_SetHandler ENDP

;-----------------------------------------------------------------------------
; Assert_GetCount - Get assertion failure count
;-----------------------------------------------------------------------------
Assert_GetCount PROC
    mov eax, g_dwAssertCount
    ret
Assert_GetCount ENDP

;-----------------------------------------------------------------------------
; Assert_ResetCount - Reset assertion counter
;-----------------------------------------------------------------------------
Assert_ResetCount PROC
    xor eax, eax
    xchg g_dwAssertCount, eax
    ret
Assert_ResetCount ENDP

END

