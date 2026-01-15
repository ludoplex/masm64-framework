;-----------------------------------------------------------------------------
; DLL Template
;-----------------------------------------------------------------------------
; MASM64 Framework - Dynamic Link Library
;
; To customize: Edit config.inc and add exports to exports.def
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
; DLL Entry Reasons
;-----------------------------------------------------------------------------
DLL_PROCESS_ATTACH  EQU 1
DLL_THREAD_ATTACH   EQU 2
DLL_THREAD_DETACH   EQU 3
DLL_PROCESS_DETACH  EQU 0

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF DisableThreadLibraryCalls:PROC

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

g_hModule   QWORD 0

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; DllMain - DLL Entry Point
;-----------------------------------------------------------------------------
DllMain PROC FRAME
    push rbp
    .pushreg rbp
    push rbx
    .pushreg rbx
    sub rsp, 40
    .allocstack 40
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov rbx, rcx                        ; Save hinstDLL
    
    cmp edx, DLL_PROCESS_ATTACH
    je process_attach
    
    cmp edx, DLL_PROCESS_DETACH
    je process_detach
    
    jmp success
    
process_attach:
    mov g_hModule, rbx
    
    IF DISABLE_THREAD_CALLS
        mov rcx, rbx
        call DisableThreadLibraryCalls
    ENDIF
    
    ; Add initialization code here
    
    jmp success
    
process_detach:
    ; Add cleanup code here
    jmp success
    
success:
    mov eax, 1
    jmp done
    
fail:
    xor eax, eax
    
done:
    add rsp, 40
    pop rbx
    pop rbp
    ret
DllMain ENDP

;-----------------------------------------------------------------------------
; Exported Functions - Add your exports here
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; ExampleFunction - Example exported function
;-----------------------------------------------------------------------------
ExampleFunction PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    ; Add your code here
    mov rax, rcx
    add rax, rdx
    
    add rsp, 40
    ret
ExampleFunction ENDP

;-----------------------------------------------------------------------------
; GetVersion - Return DLL version
;-----------------------------------------------------------------------------
GetVersion PROC
    mov eax, PROJECT_VERSION
    ret
GetVersion ENDP

END
