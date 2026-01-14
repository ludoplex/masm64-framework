;-----------------------------------------------------------------------------
; services64.asm - Windows Service Control Library Implementation
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc
INCLUDE services64.inc

;-----------------------------------------------------------------------------
; SERVICE_STATUS structure
;-----------------------------------------------------------------------------
SERVICE_STATUS STRUCT
    dwServiceType               DWORD ?
    dwCurrentState              DWORD ?
    dwControlsAccepted          DWORD ?
    dwWin32ExitCode             DWORD ?
    dwServiceSpecificExitCode   DWORD ?
    dwCheckPoint                DWORD ?
    dwWaitHint                  DWORD ?
SERVICE_STATUS ENDS

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF OpenSCManagerW:PROC
EXTERNDEF OpenServiceW:PROC
EXTERNDEF CloseServiceHandle:PROC
EXTERNDEF QueryServiceStatus:PROC
EXTERNDEF StartServiceW:PROC
EXTERNDEF ControlService:PROC
EXTERNDEF QueryServiceConfigW:PROC
EXTERNDEF ChangeServiceConfigW:PROC
EXTERNDEF Sleep:PROC
EXTERNDEF GetTickCount:PROC

;-----------------------------------------------------------------------------
; Constants
;-----------------------------------------------------------------------------
SERVICE_NO_CHANGE           EQU 0FFFFFFFFh

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; Internal: OpenSCM - Open Service Control Manager
;-----------------------------------------------------------------------------
OpenSCM PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    xor ecx, ecx                        ; lpMachineName = NULL (local)
    xor edx, edx                        ; lpDatabaseName = NULL
    mov r8d, SC_MANAGER_CONNECT OR SC_MANAGER_ENUMERATE_SERVICE
    call OpenSCManagerW
    
    add rsp, SHADOW_SPACE
    ret
OpenSCM ENDP

;-----------------------------------------------------------------------------
; ServiceExists - Check if service exists
;-----------------------------------------------------------------------------
ServiceExists PROC FRAME
    LOCAL hSCM:QWORD
    LOCAL hService:QWORD
    
    push rbx
    .pushreg rbx
    sub rsp, 48
    .allocstack 48
    .endprolog
    
    mov rbx, rcx                        ; pName
    
    call OpenSCM
    test rax, rax
    jz not_exists
    mov hSCM, rax
    
    mov rcx, rax
    mov rdx, rbx
    mov r8d, SERVICE_QUERY_STATUS
    call OpenServiceW
    test rax, rax
    jz close_scm_not_exists
    mov hService, rax
    
    ; Close service handle
    mov rcx, hService
    call CloseServiceHandle
    
    mov rcx, hSCM
    call CloseServiceHandle
    
    mov eax, 1                          ; TRUE - exists
    jmp done
    
close_scm_not_exists:
    mov rcx, hSCM
    call CloseServiceHandle
    
not_exists:
    xor eax, eax
    
done:
    add rsp, 48
    pop rbx
    ret
ServiceExists ENDP

;-----------------------------------------------------------------------------
; ServiceIsRunning - Check if service is running
;-----------------------------------------------------------------------------
ServiceIsRunning PROC FRAME
    LOCAL hSCM:QWORD
    LOCAL hService:QWORD
    LOCAL status:SERVICE_STATUS
    
    push rbx
    .pushreg rbx
    sub rsp, 64
    .allocstack 64
    .endprolog
    
    mov rbx, rcx
    
    call OpenSCM
    test rax, rax
    jz not_running
    mov hSCM, rax
    
    mov rcx, rax
    mov rdx, rbx
    mov r8d, SERVICE_QUERY_STATUS
    call OpenServiceW
    test rax, rax
    jz close_scm_not_running
    mov hService, rax
    
    mov rcx, rax
    lea rdx, status
    call QueryServiceStatus
    test eax, eax
    jz close_both_not_running
    
    mov eax, status.dwCurrentState
    cmp eax, SERVICE_RUNNING
    mov ebx, 0
    jne close_both
    mov ebx, 1
    
close_both:
    mov rcx, hService
    call CloseServiceHandle
    mov rcx, hSCM
    call CloseServiceHandle
    mov eax, ebx
    jmp done
    
close_both_not_running:
    mov rcx, hService
    call CloseServiceHandle
    
close_scm_not_running:
    mov rcx, hSCM
    call CloseServiceHandle
    
not_running:
    xor eax, eax
    
done:
    add rsp, 64
    pop rbx
    ret
ServiceIsRunning ENDP

;-----------------------------------------------------------------------------
; ServiceGetState - Get service state
;-----------------------------------------------------------------------------
ServiceGetState PROC FRAME
    LOCAL hSCM:QWORD
    LOCAL hService:QWORD
    LOCAL status:SERVICE_STATUS
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 64
    .allocstack 64
    .endprolog
    
    mov rbx, rcx                        ; pName
    mov rdi, rdx                        ; pdwState
    
    call OpenSCM
    test rax, rax
    jz failed
    mov hSCM, rax
    
    mov rcx, rax
    mov rdx, rbx
    mov r8d, SERVICE_QUERY_STATUS
    call OpenServiceW
    test rax, rax
    jz close_scm_failed
    mov hService, rax
    
    mov rcx, rax
    lea rdx, status
    call QueryServiceStatus
    test eax, eax
    jz close_both_failed
    
    mov eax, status.dwCurrentState
    mov [rdi], eax
    mov ebx, 1
    jmp close_both
    
close_both_failed:
    xor ebx, ebx
    
close_both:
    mov rcx, hService
    call CloseServiceHandle
    mov rcx, hSCM
    call CloseServiceHandle
    mov eax, ebx
    jmp done
    
close_scm_failed:
    mov rcx, hSCM
    call CloseServiceHandle
    
failed:
    xor eax, eax
    
done:
    add rsp, 64
    pop rdi
    pop rbx
    ret
ServiceGetState ENDP

;-----------------------------------------------------------------------------
; ServiceStart - Start a service
;-----------------------------------------------------------------------------
ServiceStart PROC FRAME
    LOCAL hSCM:QWORD
    LOCAL hService:QWORD
    LOCAL status:SERVICE_STATUS
    LOCAL dwWait:DWORD
    LOCAL dwStart:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 80
    .allocstack 80
    .endprolog
    
    mov rbx, rcx                        ; pName
    mov dwWait, edx                     ; dwWaitMs
    
    call OpenSCM
    test rax, rax
    jz failed
    mov hSCM, rax
    
    mov rcx, rax
    mov rdx, rbx
    mov r8d, SERVICE_START OR SERVICE_QUERY_STATUS
    call OpenServiceW
    test rax, rax
    jz close_scm_failed
    mov hService, rax
    
    ; Start service
    mov rcx, rax
    xor edx, edx                        ; dwNumServiceArgs = 0
    xor r8d, r8d                        ; lpServiceArgVectors = NULL
    call StartServiceW
    test eax, eax
    jz close_both_failed
    
    ; Wait for running state if requested
    cmp dwWait, 0
    je success
    
    call GetTickCount
    mov dwStart, eax
    
wait_loop:
    mov rcx, hService
    lea rdx, status
    call QueryServiceStatus
    test eax, eax
    jz close_both_failed
    
    cmp status.dwCurrentState, SERVICE_RUNNING
    je success
    
    cmp status.dwCurrentState, SERVICE_START_PENDING
    jne close_both_failed
    
    ; Check timeout
    call GetTickCount
    sub eax, dwStart
    cmp eax, dwWait
    ja close_both_failed
    
    ; Sleep briefly
    mov ecx, 100
    call Sleep
    jmp wait_loop
    
success:
    mov ebx, 1
    jmp close_both
    
close_both_failed:
    xor ebx, ebx
    
close_both:
    mov rcx, hService
    call CloseServiceHandle
    mov rcx, hSCM
    call CloseServiceHandle
    mov eax, ebx
    jmp done
    
close_scm_failed:
    mov rcx, hSCM
    call CloseServiceHandle
    
failed:
    xor eax, eax
    
done:
    add rsp, 80
    pop rdi
    pop rbx
    ret
ServiceStart ENDP

;-----------------------------------------------------------------------------
; ServiceStop - Stop a service
;-----------------------------------------------------------------------------
ServiceStop PROC FRAME
    LOCAL hSCM:QWORD
    LOCAL hService:QWORD
    LOCAL status:SERVICE_STATUS
    LOCAL dwWait:DWORD
    LOCAL dwStart:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 80
    .allocstack 80
    .endprolog
    
    mov rbx, rcx
    mov dwWait, edx
    
    call OpenSCM
    test rax, rax
    jz failed
    mov hSCM, rax
    
    mov rcx, rax
    mov rdx, rbx
    mov r8d, SERVICE_STOP OR SERVICE_QUERY_STATUS
    call OpenServiceW
    test rax, rax
    jz close_scm_failed
    mov hService, rax
    
    ; Send stop control
    mov rcx, rax
    mov edx, SERVICE_CONTROL_STOP
    lea r8, status
    call ControlService
    test eax, eax
    jz close_both_failed
    
    ; Wait if requested
    cmp dwWait, 0
    je success
    
    call GetTickCount
    mov dwStart, eax
    
wait_loop:
    mov rcx, hService
    lea rdx, status
    call QueryServiceStatus
    test eax, eax
    jz close_both_failed
    
    cmp status.dwCurrentState, SERVICE_STOPPED
    je success
    
    call GetTickCount
    sub eax, dwStart
    cmp eax, dwWait
    ja close_both_failed
    
    mov ecx, 100
    call Sleep
    jmp wait_loop
    
success:
    mov ebx, 1
    jmp close_both
    
close_both_failed:
    xor ebx, ebx
    
close_both:
    mov rcx, hService
    call CloseServiceHandle
    mov rcx, hSCM
    call CloseServiceHandle
    mov eax, ebx
    jmp done
    
close_scm_failed:
    mov rcx, hSCM
    call CloseServiceHandle
    
failed:
    xor eax, eax
    
done:
    add rsp, 80
    pop rdi
    pop rbx
    ret
ServiceStop ENDP

;-----------------------------------------------------------------------------
; ServiceSetStartType - Set service start type
;-----------------------------------------------------------------------------
ServiceSetStartType PROC FRAME
    LOCAL hSCM:QWORD
    LOCAL hService:QWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 120
    .allocstack 120
    .endprolog
    
    mov rbx, rcx                        ; pName
    mov edi, edx                        ; dwType
    
    call OpenSCM
    test rax, rax
    jz failed
    mov hSCM, rax
    
    mov rcx, rax
    mov rdx, rbx
    mov r8d, SERVICE_CHANGE_CONFIG
    call OpenServiceW
    test rax, rax
    jz close_scm_failed
    mov hService, rax
    
    ; ChangeServiceConfigW(hService, SERVICE_NO_CHANGE, dwStartType, 
    ;   SERVICE_NO_CHANGE, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
    mov rcx, hService
    mov edx, SERVICE_NO_CHANGE          ; dwServiceType
    mov r8d, edi                        ; dwStartType
    mov r9d, SERVICE_NO_CHANGE          ; dwErrorControl
    mov QWORD PTR [rsp + 32], 0         ; lpBinaryPathName
    mov QWORD PTR [rsp + 40], 0         ; lpLoadOrderGroup
    mov QWORD PTR [rsp + 48], 0         ; lpdwTagId
    mov QWORD PTR [rsp + 56], 0         ; lpDependencies
    mov QWORD PTR [rsp + 64], 0         ; lpServiceStartName
    mov QWORD PTR [rsp + 72], 0         ; lpPassword
    mov QWORD PTR [rsp + 80], 0         ; lpDisplayName
    call ChangeServiceConfigW
    mov ebx, eax
    
    mov rcx, hService
    call CloseServiceHandle
    mov rcx, hSCM
    call CloseServiceHandle
    mov eax, ebx
    jmp done
    
close_scm_failed:
    mov rcx, hSCM
    call CloseServiceHandle
    
failed:
    xor eax, eax
    
done:
    add rsp, 120
    pop rdi
    pop rbx
    ret
ServiceSetStartType ENDP

;-----------------------------------------------------------------------------
; ServiceEnable - Enable service (auto start)
;-----------------------------------------------------------------------------
ServiceEnable PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov edx, SERVICE_AUTO_START
    call ServiceSetStartType
    
    add rsp, SHADOW_SPACE
    ret
ServiceEnable ENDP

;-----------------------------------------------------------------------------
; ServiceDisable - Disable service
;-----------------------------------------------------------------------------
ServiceDisable PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov edx, SERVICE_DISABLED
    call ServiceSetStartType
    
    add rsp, SHADOW_SPACE
    ret
ServiceDisable ENDP

END

