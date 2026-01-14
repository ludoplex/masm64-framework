;-----------------------------------------------------------------------------
; com64.asm - COM Interface Library Implementation
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc
INCLUDE com64.inc

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF CoInitializeEx:PROC
EXTERNDEF CoUninitialize:PROC
EXTERNDEF CoCreateInstance:PROC

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; Com_Initialize - Initialize COM library
;-----------------------------------------------------------------------------
Com_Initialize PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; CoInitializeEx(NULL, dwCoInit)
    mov edx, ecx                        ; dwCoInit
    xor ecx, ecx                        ; pvReserved = NULL
    call CoInitializeEx
    
    add rsp, SHADOW_SPACE
    ret
Com_Initialize ENDP

;-----------------------------------------------------------------------------
; Com_Uninitialize - Uninitialize COM library
;-----------------------------------------------------------------------------
Com_Uninitialize PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    call CoUninitialize
    
    add rsp, SHADOW_SPACE
    ret
Com_Uninitialize ENDP

;-----------------------------------------------------------------------------
; Com_CreateInstance - Create COM object
;-----------------------------------------------------------------------------
Com_CreateInstance PROC FRAME
    push rbx
    .pushreg rbx
    sub rsp, 48
    .allocstack 48
    .endprolog
    
    ; CoCreateInstance(rclsid, pUnkOuter, dwClsContext, riid, ppv)
    ; RCX = pClsid, RDX = pIid, R8 = ppInterface
    mov rbx, r8                         ; Save ppInterface
    
    mov r9, rdx                         ; riid
    mov QWORD PTR [rsp + 32], rbx       ; ppv
    mov r8d, CLSCTX_INPROC_SERVER       ; dwClsContext
    xor edx, edx                        ; pUnkOuter = NULL
    ; RCX = rclsid already
    call CoCreateInstance
    
    add rsp, 48
    pop rbx
    ret
Com_CreateInstance ENDP

;-----------------------------------------------------------------------------
; Com_Release - Release interface
;-----------------------------------------------------------------------------
Com_Release PROC
    ; RCX = pInterface
    test rcx, rcx
    jz null_ptr
    
    mov rax, [rcx]                      ; Get vtable
    jmp QWORD PTR [rax + IUnknown_Release]
    
null_ptr:
    xor eax, eax
    ret
Com_Release ENDP

;-----------------------------------------------------------------------------
; Com_QueryInterface - Query for interface
;-----------------------------------------------------------------------------
Com_QueryInterface PROC
    ; RCX = pInterface, RDX = pIid, R8 = ppNewInterface
    test rcx, rcx
    jz null_ptr
    
    mov rax, [rcx]                      ; Get vtable
    jmp QWORD PTR [rax + IUnknown_QueryInterface]
    
null_ptr:
    mov eax, E_POINTER
    ret
Com_QueryInterface ENDP

;-----------------------------------------------------------------------------
; Com_AddRef - Add reference
;-----------------------------------------------------------------------------
Com_AddRef PROC
    ; RCX = pInterface
    test rcx, rcx
    jz null_ptr
    
    mov rax, [rcx]
    jmp QWORD PTR [rax + IUnknown_AddRef]
    
null_ptr:
    xor eax, eax
    ret
Com_AddRef ENDP

;-----------------------------------------------------------------------------
; Com_Succeeded - Check HRESULT success
;-----------------------------------------------------------------------------
Com_Succeeded PROC
    ; ECX = hr
    ; SUCCEEDED if hr >= 0 (high bit not set)
    test ecx, ecx
    setns al
    movzx eax, al
    ret
Com_Succeeded ENDP

;-----------------------------------------------------------------------------
; Com_Failed - Check HRESULT failure
;-----------------------------------------------------------------------------
Com_Failed PROC
    ; ECX = hr
    ; FAILED if hr < 0 (high bit set)
    test ecx, ecx
    sets al
    movzx eax, al
    ret
Com_Failed ENDP

END

