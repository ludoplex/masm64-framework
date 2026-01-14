;-----------------------------------------------------------------------------
; error64.asm - Error Handling Library Implementation
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc
INCLUDE error64.inc

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF GetLastError:PROC
EXTERNDEF SetLastError:PROC
EXTERNDEF FormatMessageW:PROC

;-----------------------------------------------------------------------------
; FormatMessage flags
;-----------------------------------------------------------------------------
FORMAT_MESSAGE_FROM_SYSTEM      EQU 1000h
FORMAT_MESSAGE_IGNORE_INSERTS   EQU 200h

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; Err_GetLast - Get the last error code
;-----------------------------------------------------------------------------
; Returns: Error code in RAX (EAX)
;-----------------------------------------------------------------------------
Err_GetLast PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    call GetLastError
    ; Result already in EAX
    
    add rsp, SHADOW_SPACE
    ret
Err_GetLast ENDP

;-----------------------------------------------------------------------------
; Err_SetLast - Set the last error code
;-----------------------------------------------------------------------------
; Parameters: RCX = dwError
;-----------------------------------------------------------------------------
Err_SetLast PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; RCX already contains dwError
    call SetLastError
    
    add rsp, SHADOW_SPACE
    ret
Err_SetLast ENDP

;-----------------------------------------------------------------------------
; Err_FormatSystem - Format system error to string
;-----------------------------------------------------------------------------
; Parameters: ECX = dwError
;             RDX = pBuffer
;             R8D = cchBuffer
; Returns: Number of characters in RAX
;-----------------------------------------------------------------------------
Err_FormatSystem PROC FRAME
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 48                         ; Shadow + alignment
    .allocstack 48
    .endprolog
    
    ; Save parameters
    mov ebx, ecx                        ; dwError
    mov rdi, rdx                        ; pBuffer
    mov esi, r8d                        ; cchBuffer
    
    ; FormatMessageW(
    ;   dwFlags = FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
    ;   lpSource = NULL,
    ;   dwMessageId = dwError,
    ;   dwLanguageId = 0,
    ;   lpBuffer = pBuffer,
    ;   nSize = cchBuffer,
    ;   Arguments = NULL
    ; )
    mov ecx, FORMAT_MESSAGE_FROM_SYSTEM OR FORMAT_MESSAGE_IGNORE_INSERTS
    xor edx, edx                        ; lpSource = NULL
    mov r8d, ebx                        ; dwMessageId
    xor r9d, r9d                        ; dwLanguageId = 0
    mov QWORD PTR [rsp + 32], rdi       ; lpBuffer
    mov DWORD PTR [rsp + 40], esi       ; nSize
    mov QWORD PTR [rsp + 48], 0         ; Arguments = NULL
    call FormatMessageW
    
    ; RAX = number of characters (0 on failure)
    
    add rsp, 48
    pop rsi
    pop rdi
    pop rbx
    ret
Err_FormatSystem ENDP

;-----------------------------------------------------------------------------
; Err_GetMessage - Get error message (wrapper around Err_FormatSystem)
;-----------------------------------------------------------------------------
Err_GetMessage PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; Parameters already in correct registers
    call Err_FormatSystem
    
    add rsp, SHADOW_SPACE
    ret
Err_GetMessage ENDP

;-----------------------------------------------------------------------------
; Err_IsSuccess - Check if error code indicates success
;-----------------------------------------------------------------------------
; Parameters: ECX = dwError
; Returns: TRUE (1) if success, FALSE (0) otherwise
;-----------------------------------------------------------------------------
Err_IsSuccess PROC
    xor eax, eax
    test ecx, ecx
    setz al
    ret
Err_IsSuccess ENDP

;-----------------------------------------------------------------------------
; Err_IsFailed - Check if error code indicates failure
;-----------------------------------------------------------------------------
; Parameters: ECX = dwError
; Returns: TRUE (1) if failed, FALSE (0) if success
;-----------------------------------------------------------------------------
Err_IsFailed PROC
    xor eax, eax
    test ecx, ecx
    setnz al
    ret
Err_IsFailed ENDP

END

