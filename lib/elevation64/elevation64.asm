;-----------------------------------------------------------------------------
; elevation64.asm - UAC and Privilege Management Implementation
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc
INCLUDE elevation64.inc

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF GetCurrentProcess:PROC
EXTERNDEF OpenProcessToken:PROC
EXTERNDEF GetTokenInformation:PROC
EXTERNDEF CloseHandle:PROC
EXTERNDEF ShellExecuteW:PROC
EXTERNDEF GetModuleFileNameW:PROC
EXTERNDEF GetCommandLineW:PROC
EXTERNDEF ExitProcess:PROC
EXTERNDEF LookupPrivilegeValueW:PROC
EXTERNDEF AdjustTokenPrivileges:PROC
EXTERNDEF PrivilegeCheck:PROC
EXTERNDEF AllocateAndInitializeSid:PROC
EXTERNDEF FreeSid:PROC
EXTERNDEF CheckTokenMembership:PROC

;-----------------------------------------------------------------------------
; Constants
;-----------------------------------------------------------------------------
SW_SHOWNORMAL           EQU 1
SECURITY_BUILTIN_DOMAIN_RID EQU 32
DOMAIN_ALIAS_RID_ADMINS EQU 544
SECURITY_NT_AUTHORITY   EQU 5

;-----------------------------------------------------------------------------
; SID_IDENTIFIER_AUTHORITY structure
;-----------------------------------------------------------------------------
SID_IDENTIFIER_AUTHORITY STRUCT
    Value   BYTE 6 DUP(?)
SID_IDENTIFIER_AUTHORITY ENDS

;-----------------------------------------------------------------------------
; LUID structure
;-----------------------------------------------------------------------------
LUID STRUCT
    LowPart     DWORD ?
    HighPart    LONG ?
LUID ENDS

;-----------------------------------------------------------------------------
; LUID_AND_ATTRIBUTES structure
;-----------------------------------------------------------------------------
LUID_AND_ATTRIBUTES STRUCT
    Luid        LUID <>
    Attributes  DWORD ?
LUID_AND_ATTRIBUTES ENDS

;-----------------------------------------------------------------------------
; TOKEN_PRIVILEGES structure
;-----------------------------------------------------------------------------
TOKEN_PRIVILEGES STRUCT
    PrivilegeCount  DWORD ?
    Privileges      LUID_AND_ATTRIBUTES <>
TOKEN_PRIVILEGES ENDS

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

WSTR wszRunAs, "runas"

g_NtAuthority   SID_IDENTIFIER_AUTHORITY <{0, 0, 0, 0, 0, 5}>

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; IsRunningAsAdmin - Check if running elevated
;-----------------------------------------------------------------------------
IsRunningAsAdmin PROC FRAME
    LOCAL hToken:QWORD
    LOCAL pAdminSid:QWORD
    LOCAL bIsAdmin:DWORD
    
    push rbx
    .pushreg rbx
    sub rsp, 80
    .allocstack 80
    .endprolog
    
    mov bIsAdmin, 0
    mov pAdminSid, 0
    
    ; Allocate admin SID
    ; AllocateAndInitializeSid(&NtAuthority, 2,
    ;   SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS,
    ;   0, 0, 0, 0, 0, 0, &pAdminSid)
    lea rcx, g_NtAuthority
    mov edx, 2                          ; nSubAuthorityCount
    mov r8d, SECURITY_BUILTIN_DOMAIN_RID
    mov r9d, DOMAIN_ALIAS_RID_ADMINS
    mov DWORD PTR [rsp + 32], 0
    mov DWORD PTR [rsp + 40], 0
    mov DWORD PTR [rsp + 48], 0
    mov DWORD PTR [rsp + 56], 0
    mov DWORD PTR [rsp + 64], 0
    mov DWORD PTR [rsp + 72], 0
    lea rax, pAdminSid
    mov [rsp + 80], rax
    call AllocateAndInitializeSid
    test eax, eax
    jz done
    
    ; Check membership
    xor ecx, ecx                        ; TokenHandle = NULL (current thread)
    mov rdx, pAdminSid
    lea r8, bIsAdmin
    call CheckTokenMembership
    test eax, eax
    jz free_sid
    
free_sid:
    mov rcx, pAdminSid
    call FreeSid
    
done:
    mov eax, bIsAdmin
    
    add rsp, 80
    pop rbx
    ret
IsRunningAsAdmin ENDP

;-----------------------------------------------------------------------------
; RelaunchAsAdmin - Relaunch with elevation
;-----------------------------------------------------------------------------
RelaunchAsAdmin PROC FRAME
    LOCAL wszPath[520]:BYTE             ; MAX_PATH * 2
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 600
    .allocstack 600
    .endprolog
    
    mov rdi, rcx                        ; pCmdLine
    
    ; Get current executable path
    xor ecx, ecx
    lea rdx, wszPath
    mov r8d, 260
    call GetModuleFileNameW
    test eax, eax
    jz failed
    
    ; If no command line provided, get current
    test rdi, rdi
    jnz have_cmdline
    call GetCommandLineW
    mov rdi, rax
    
have_cmdline:
    ; ShellExecuteW(NULL, "runas", path, cmdline, NULL, SW_SHOWNORMAL)
    xor ecx, ecx                        ; hwnd = NULL
    lea rdx, wszRunAs                   ; lpOperation
    lea r8, wszPath                     ; lpFile
    mov r9, rdi                         ; lpParameters
    mov QWORD PTR [rsp + 32], 0         ; lpDirectory = NULL
    mov DWORD PTR [rsp + 40], SW_SHOWNORMAL
    call ShellExecuteW
    
    ; ShellExecute returns > 32 on success
    cmp rax, 32
    jle failed
    
    ; Exit current process
    xor ecx, ecx
    call ExitProcess
    ; Never returns
    
failed:
    xor eax, eax
    
    add rsp, 600
    pop rdi
    pop rbx
    ret
RelaunchAsAdmin ENDP

;-----------------------------------------------------------------------------
; RequireAdminOrExit - Require admin privileges
;-----------------------------------------------------------------------------
RequireAdminOrExit PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    call IsRunningAsAdmin
    test eax, eax
    jnz is_admin
    
    ; Not admin, relaunch
    xor ecx, ecx                        ; Use current command line
    call RelaunchAsAdmin
    
    ; If relaunch failed, exit anyway
    mov ecx, 1
    call ExitProcess
    
is_admin:
    add rsp, SHADOW_SPACE
    ret
RequireAdminOrExit ENDP

;-----------------------------------------------------------------------------
; GetIntegrityLevel - Get process integrity level
;-----------------------------------------------------------------------------
GetIntegrityLevel PROC FRAME
    LOCAL hToken:QWORD
    LOCAL dwSize:DWORD
    LOCAL buffer[256]:BYTE
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 320
    .allocstack 320
    .endprolog
    
    mov rdi, rcx                        ; pLevel
    
    ; Open process token
    call GetCurrentProcess
    mov rcx, rax
    mov edx, TOKEN_QUERY
    lea r8, hToken
    call OpenProcessToken
    test eax, eax
    jz failed
    
    ; Get integrity level
    mov rcx, hToken
    mov edx, TokenIntegrityLevel
    lea r8, buffer
    mov r9d, 256
    lea rax, dwSize
    mov [rsp + 32], rax
    call GetTokenInformation
    mov ebx, eax
    
    ; Close token
    mov rcx, hToken
    call CloseHandle
    
    test ebx, ebx
    jz failed
    
    ; Extract integrity level RID from SID
    ; TOKEN_MANDATORY_LABEL.Label.Sid points to SID
    ; Last SubAuthority is the integrity level
    lea rcx, buffer
    mov rcx, [rcx]                      ; Get Sid pointer from Label
    
    ; SID structure: Revision(1) + SubAuthCount(1) + Authority(6) + SubAuth[]
    ; SubAuthCount is at offset 1
    movzx eax, BYTE PTR [rcx + 1]       ; SubAuthorityCount
    dec eax
    mov eax, [rcx + 8 + rax*4]          ; Last SubAuthority
    mov [rdi], rax
    
    mov eax, 1
    jmp done
    
failed:
    xor eax, eax
    
done:
    add rsp, 320
    pop rdi
    pop rbx
    ret
GetIntegrityLevel ENDP

;-----------------------------------------------------------------------------
; IsIntegrityAtLeast - Check minimum integrity level
;-----------------------------------------------------------------------------
IsIntegrityAtLeast PROC FRAME
    LOCAL qwLevel:QWORD
    
    push rbx
    .pushreg rbx
    sub rsp, 48
    .allocstack 48
    .endprolog
    
    mov ebx, ecx                        ; Required level
    
    lea rcx, qwLevel
    call GetIntegrityLevel
    test eax, eax
    jz failed
    
    mov eax, DWORD PTR qwLevel
    cmp eax, ebx
    jl failed
    
    mov eax, 1
    jmp done
    
failed:
    xor eax, eax
    
done:
    add rsp, 48
    pop rbx
    ret
IsIntegrityAtLeast ENDP

;-----------------------------------------------------------------------------
; EnablePrivilege - Enable a privilege
;-----------------------------------------------------------------------------
EnablePrivilege PROC FRAME
    LOCAL hToken:QWORD
    LOCAL tp:TOKEN_PRIVILEGES
    LOCAL luid:LUID
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 80
    .allocstack 80
    .endprolog
    
    mov rdi, rcx                        ; pPrivilegeName
    
    ; Open token with adjust privileges
    call GetCurrentProcess
    mov rcx, rax
    mov edx, TOKEN_ADJUST_PRIVILEGES OR TOKEN_QUERY
    lea r8, hToken
    call OpenProcessToken
    test eax, eax
    jz failed
    
    ; Look up privilege LUID
    xor ecx, ecx                        ; lpSystemName = NULL (local)
    mov rdx, rdi                        ; lpName
    lea r8, luid
    call LookupPrivilegeValueW
    test eax, eax
    jz close_failed
    
    ; Set up TOKEN_PRIVILEGES
    mov tp.PrivilegeCount, 1
    mov eax, luid.LowPart
    mov tp.Privileges.Luid.LowPart, eax
    mov eax, luid.HighPart
    mov tp.Privileges.Luid.HighPart, eax
    mov tp.Privileges.Attributes, SE_PRIVILEGE_ENABLED
    
    ; Adjust privilege
    mov rcx, hToken
    xor edx, edx                        ; DisableAllPrivileges = FALSE
    lea r8, tp
    xor r9d, r9d                        ; BufferLength = 0
    mov QWORD PTR [rsp + 32], 0         ; PreviousState = NULL
    mov QWORD PTR [rsp + 40], 0         ; ReturnLength = NULL
    call AdjustTokenPrivileges
    mov ebx, eax
    
    mov rcx, hToken
    call CloseHandle
    
    mov eax, ebx
    jmp done
    
close_failed:
    mov rcx, hToken
    call CloseHandle
    
failed:
    xor eax, eax
    
done:
    add rsp, 80
    pop rdi
    pop rbx
    ret
EnablePrivilege ENDP

;-----------------------------------------------------------------------------
; DisablePrivilege - Disable a privilege
;-----------------------------------------------------------------------------
DisablePrivilege PROC FRAME
    LOCAL hToken:QWORD
    LOCAL tp:TOKEN_PRIVILEGES
    LOCAL luid:LUID
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 80
    .allocstack 80
    .endprolog
    
    mov rdi, rcx
    
    call GetCurrentProcess
    mov rcx, rax
    mov edx, TOKEN_ADJUST_PRIVILEGES OR TOKEN_QUERY
    lea r8, hToken
    call OpenProcessToken
    test eax, eax
    jz failed
    
    xor ecx, ecx
    mov rdx, rdi
    lea r8, luid
    call LookupPrivilegeValueW
    test eax, eax
    jz close_failed
    
    mov tp.PrivilegeCount, 1
    mov eax, luid.LowPart
    mov tp.Privileges.Luid.LowPart, eax
    mov eax, luid.HighPart
    mov tp.Privileges.Luid.HighPart, eax
    mov tp.Privileges.Attributes, 0     ; Disable
    
    mov rcx, hToken
    xor edx, edx
    lea r8, tp
    xor r9d, r9d
    mov QWORD PTR [rsp + 32], 0
    mov QWORD PTR [rsp + 40], 0
    call AdjustTokenPrivileges
    mov ebx, eax
    
    mov rcx, hToken
    call CloseHandle
    
    mov eax, ebx
    jmp done
    
close_failed:
    mov rcx, hToken
    call CloseHandle
    
failed:
    xor eax, eax
    
done:
    add rsp, 80
    pop rdi
    pop rbx
    ret
DisablePrivilege ENDP

;-----------------------------------------------------------------------------
; GetProcessToken - Get process token handle
;-----------------------------------------------------------------------------
GetProcessToken PROC FRAME
    push rbx
    .pushreg rbx
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov ebx, ecx                        ; dwAccess
    mov rdi, rdx                        ; phToken
    
    call GetCurrentProcess
    mov rcx, rax
    mov edx, ebx
    mov r8, rdi
    call OpenProcessToken
    
    add rsp, SHADOW_SPACE
    pop rbx
    ret
GetProcessToken ENDP

END

