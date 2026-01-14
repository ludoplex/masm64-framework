;-----------------------------------------------------------------------------
; registry64.asm - Registry Operations Library Implementation
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc
INCLUDE registry64.inc

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF RegOpenKeyExW:PROC
EXTERNDEF RegCreateKeyExW:PROC
EXTERNDEF RegCloseKey:PROC
EXTERNDEF RegQueryValueExW:PROC
EXTERNDEF RegSetValueExW:PROC
EXTERNDEF RegDeleteValueW:PROC
EXTERNDEF RegDeleteKeyW:PROC
EXTERNDEF RegDeleteTreeW:PROC
EXTERNDEF RegEnumKeyExW:PROC
EXTERNDEF RegEnumValueW:PROC
EXTERNDEF lstrlenW:PROC

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; RegGetDWORD - Get DWORD value from registry
;-----------------------------------------------------------------------------
RegGetDWORD PROC FRAME
    LOCAL hKey:QWORD
    LOCAL cbData:DWORD
    LOCAL dwType:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    push r12
    .pushreg r12
    sub rsp, 64
    .allocstack 64
    .endprolog
    
    ; Save parameters
    mov rbx, rcx                        ; hRoot
    mov rdi, rdx                        ; pPath
    mov rsi, r8                         ; pName
    mov r12, r9                         ; pdwValue
    
    ; Open key
    mov rcx, rbx                        ; hKey
    mov rdx, rdi                        ; lpSubKey
    xor r8d, r8d                        ; ulOptions = 0
    mov r9d, KEY_READ                   ; samDesired
    lea rax, hKey
    mov [rsp + 32], rax                 ; phkResult
    call RegOpenKeyExW
    test eax, eax
    jnz done
    
    ; Query value
    mov cbData, 4
    mov rcx, hKey                       ; hKey
    mov rdx, rsi                        ; lpValueName
    xor r8d, r8d                        ; lpReserved = NULL
    lea r9, dwType                      ; lpType
    mov QWORD PTR [rsp + 32], r12       ; lpData
    lea rax, cbData
    mov [rsp + 40], rax                 ; lpcbData
    call RegQueryValueExW
    mov ebx, eax                        ; Save result
    
    ; Close key
    mov rcx, hKey
    call RegCloseKey
    
    mov eax, ebx
    
done:
    add rsp, 64
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret
RegGetDWORD ENDP

;-----------------------------------------------------------------------------
; RegSetDWORD - Set DWORD value in registry
;-----------------------------------------------------------------------------
RegSetDWORD PROC FRAME
    LOCAL hKey:QWORD
    LOCAL dwValue:DWORD
    LOCAL dwDisposition:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 80
    .allocstack 80
    .endprolog
    
    mov rbx, rcx                        ; hRoot
    mov rdi, rdx                        ; pPath
    mov rsi, r8                         ; pName
    mov dwValue, r9d                    ; dwValue
    
    ; Create/Open key
    mov rcx, rbx
    mov rdx, rdi
    xor r8d, r8d                        ; Reserved
    xor r9d, r9d                        ; lpClass = NULL
    mov DWORD PTR [rsp + 32], REG_OPTION_NON_VOLATILE
    mov DWORD PTR [rsp + 40], KEY_WRITE
    mov QWORD PTR [rsp + 48], 0         ; lpSecurityAttributes
    lea rax, hKey
    mov [rsp + 56], rax
    lea rax, dwDisposition
    mov [rsp + 64], rax
    call RegCreateKeyExW
    test eax, eax
    jnz done
    
    ; Set value
    mov rcx, hKey
    mov rdx, rsi
    xor r8d, r8d                        ; Reserved
    mov r9d, REG_DWORD
    lea rax, dwValue
    mov [rsp + 32], rax                 ; lpData
    mov DWORD PTR [rsp + 40], 4         ; cbData
    call RegSetValueExW
    mov ebx, eax
    
    ; Close key
    mov rcx, hKey
    call RegCloseKey
    
    mov eax, ebx
    
done:
    add rsp, 80
    pop rsi
    pop rdi
    pop rbx
    ret
RegSetDWORD ENDP

;-----------------------------------------------------------------------------
; RegGetQWORD - Get QWORD value from registry
;-----------------------------------------------------------------------------
RegGetQWORD PROC FRAME
    LOCAL hKey:QWORD
    LOCAL cbData:DWORD
    LOCAL dwType:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    push r12
    .pushreg r12
    sub rsp, 64
    .allocstack 64
    .endprolog
    
    mov rbx, rcx
    mov rdi, rdx
    mov rsi, r8
    mov r12, r9
    
    mov rcx, rbx
    mov rdx, rdi
    xor r8d, r8d
    mov r9d, KEY_READ
    lea rax, hKey
    mov [rsp + 32], rax
    call RegOpenKeyExW
    test eax, eax
    jnz done
    
    mov cbData, 8
    mov rcx, hKey
    mov rdx, rsi
    xor r8d, r8d
    lea r9, dwType
    mov QWORD PTR [rsp + 32], r12
    lea rax, cbData
    mov [rsp + 40], rax
    call RegQueryValueExW
    mov ebx, eax
    
    mov rcx, hKey
    call RegCloseKey
    
    mov eax, ebx
    
done:
    add rsp, 64
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret
RegGetQWORD ENDP

;-----------------------------------------------------------------------------
; RegSetQWORD - Set QWORD value in registry
;-----------------------------------------------------------------------------
RegSetQWORD PROC FRAME
    LOCAL hKey:QWORD
    LOCAL qwValue:QWORD
    LOCAL dwDisposition:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 80
    .allocstack 80
    .endprolog
    
    mov rbx, rcx
    mov rdi, rdx
    mov rsi, r8
    mov qwValue, r9
    
    mov rcx, rbx
    mov rdx, rdi
    xor r8d, r8d
    xor r9d, r9d
    mov DWORD PTR [rsp + 32], REG_OPTION_NON_VOLATILE
    mov DWORD PTR [rsp + 40], KEY_WRITE
    mov QWORD PTR [rsp + 48], 0
    lea rax, hKey
    mov [rsp + 56], rax
    lea rax, dwDisposition
    mov [rsp + 64], rax
    call RegCreateKeyExW
    test eax, eax
    jnz done
    
    mov rcx, hKey
    mov rdx, rsi
    xor r8d, r8d
    mov r9d, REG_QWORD
    lea rax, qwValue
    mov [rsp + 32], rax
    mov DWORD PTR [rsp + 40], 8
    call RegSetValueExW
    mov ebx, eax
    
    mov rcx, hKey
    call RegCloseKey
    
    mov eax, ebx
    
done:
    add rsp, 80
    pop rsi
    pop rdi
    pop rbx
    ret
RegSetQWORD ENDP

;-----------------------------------------------------------------------------
; RegGetString - Get string value from registry
;-----------------------------------------------------------------------------
RegGetString PROC FRAME
    LOCAL hKey:QWORD
    LOCAL dwType:DWORD
    LOCAL cbData:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    push r12
    .pushreg r12
    push r13
    .pushreg r13
    sub rsp, 72
    .allocstack 72
    .endprolog
    
    mov rbx, rcx                        ; hRoot
    mov rdi, rdx                        ; pPath
    mov rsi, r8                         ; pName
    mov r12, r9                         ; pBuffer
    mov r13d, DWORD PTR [rsp + 72 + 40 + 8] ; cbBuffer (5th param)
    
    mov rcx, rbx
    mov rdx, rdi
    xor r8d, r8d
    mov r9d, KEY_READ
    lea rax, hKey
    mov [rsp + 32], rax
    call RegOpenKeyExW
    test eax, eax
    jnz done
    
    mov cbData, r13d
    mov rcx, hKey
    mov rdx, rsi
    xor r8d, r8d
    lea r9, dwType
    mov QWORD PTR [rsp + 32], r12
    lea rax, cbData
    mov [rsp + 40], rax
    call RegQueryValueExW
    mov ebx, eax
    
    mov rcx, hKey
    call RegCloseKey
    
    mov eax, ebx
    
done:
    add rsp, 72
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret
RegGetString ENDP

;-----------------------------------------------------------------------------
; RegSetString - Set string value in registry
;-----------------------------------------------------------------------------
RegSetString PROC FRAME
    LOCAL hKey:QWORD
    LOCAL dwDisposition:DWORD
    LOCAL cbData:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    push r12
    .pushreg r12
    sub rsp, 80
    .allocstack 80
    .endprolog
    
    mov rbx, rcx
    mov rdi, rdx
    mov rsi, r8
    mov r12, r9
    
    ; Get string length
    mov rcx, r12
    call lstrlenW
    inc eax                             ; Include null
    shl eax, 1                          ; Convert to bytes
    mov cbData, eax
    
    mov rcx, rbx
    mov rdx, rdi
    xor r8d, r8d
    xor r9d, r9d
    mov DWORD PTR [rsp + 32], REG_OPTION_NON_VOLATILE
    mov DWORD PTR [rsp + 40], KEY_WRITE
    mov QWORD PTR [rsp + 48], 0
    lea rax, hKey
    mov [rsp + 56], rax
    lea rax, dwDisposition
    mov [rsp + 64], rax
    call RegCreateKeyExW
    test eax, eax
    jnz done
    
    mov rcx, hKey
    mov rdx, rsi
    xor r8d, r8d
    mov r9d, REG_SZ
    mov QWORD PTR [rsp + 32], r12
    mov eax, cbData
    mov DWORD PTR [rsp + 40], eax
    call RegSetValueExW
    mov ebx, eax
    
    mov rcx, hKey
    call RegCloseKey
    
    mov eax, ebx
    
done:
    add rsp, 80
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret
RegSetString ENDP

;-----------------------------------------------------------------------------
; RegDeleteValue - Delete a registry value
;-----------------------------------------------------------------------------
RegDeleteValue PROC FRAME
    LOCAL hKey:QWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 48
    .allocstack 48
    .endprolog
    
    mov rbx, rcx
    mov rdi, rdx
    mov rsi, r8
    
    mov rcx, rbx
    mov rdx, rdi
    xor r8d, r8d
    mov r9d, KEY_WRITE
    lea rax, hKey
    mov [rsp + 32], rax
    call RegOpenKeyExW
    test eax, eax
    jnz done
    
    mov rcx, hKey
    mov rdx, rsi
    call RegDeleteValueW
    mov ebx, eax
    
    mov rcx, hKey
    call RegCloseKey
    
    mov eax, ebx
    
done:
    add rsp, 48
    pop rsi
    pop rdi
    pop rbx
    ret
RegDeleteValue ENDP

;-----------------------------------------------------------------------------
; RegDeleteKey - Delete a registry key
;-----------------------------------------------------------------------------
RegDeleteKey PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; RCX = hRoot, RDX = pPath
    call RegDeleteKeyW
    
    add rsp, SHADOW_SPACE
    ret
RegDeleteKey ENDP

;-----------------------------------------------------------------------------
; RegDeleteTree - Delete registry key tree
;-----------------------------------------------------------------------------
RegDeleteTree PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    call RegDeleteTreeW
    
    add rsp, SHADOW_SPACE
    ret
RegDeleteTree ENDP

;-----------------------------------------------------------------------------
; RegKeyExists - Check if registry key exists
;-----------------------------------------------------------------------------
RegKeyExists PROC FRAME
    LOCAL hKey:QWORD
    
    push rbx
    .pushreg rbx
    sub rsp, 48
    .allocstack 48
    .endprolog
    
    mov rcx, rcx                        ; hRoot
    mov rdx, rdx                        ; pPath
    xor r8d, r8d
    mov r9d, KEY_READ
    lea rax, hKey
    mov [rsp + 32], rax
    call RegOpenKeyExW
    
    test eax, eax
    jnz not_exists
    
    mov rcx, hKey
    call RegCloseKey
    mov eax, 1                          ; TRUE
    jmp done
    
not_exists:
    xor eax, eax                        ; FALSE
    
done:
    add rsp, 48
    pop rbx
    ret
RegKeyExists ENDP

;-----------------------------------------------------------------------------
; RegValueExists - Check if registry value exists
;-----------------------------------------------------------------------------
RegValueExists PROC FRAME
    LOCAL hKey:QWORD
    LOCAL dwType:DWORD
    
    push rbx
    .pushreg rbx
    push rsi
    .pushreg rsi
    sub rsp, 56
    .allocstack 56
    .endprolog
    
    mov rbx, rcx
    mov rsi, r8                         ; pName
    
    mov rcx, rbx
    ; RDX = pPath already
    xor r8d, r8d
    mov r9d, KEY_READ
    lea rax, hKey
    mov [rsp + 32], rax
    call RegOpenKeyExW
    test eax, eax
    jnz not_exists
    
    mov rcx, hKey
    mov rdx, rsi
    xor r8d, r8d
    lea r9, dwType
    mov QWORD PTR [rsp + 32], 0         ; lpData = NULL
    mov QWORD PTR [rsp + 40], 0         ; lpcbData = NULL
    call RegQueryValueExW
    mov ebx, eax
    
    mov rcx, hKey
    call RegCloseKey
    
    test ebx, ebx
    jnz not_exists
    mov eax, 1
    jmp done
    
not_exists:
    xor eax, eax
    
done:
    add rsp, 56
    pop rsi
    pop rbx
    ret
RegValueExists ENDP

;-----------------------------------------------------------------------------
; RegCreateKey - Create a registry key
;-----------------------------------------------------------------------------
RegCreateKey PROC FRAME
    LOCAL hKey:QWORD
    LOCAL dwDisposition:DWORD
    
    push rbx
    .pushreg rbx
    sub rsp, 80
    .allocstack 80
    .endprolog
    
    mov rbx, rcx
    
    mov rcx, rbx
    ; RDX = pPath
    xor r8d, r8d
    xor r9d, r9d
    mov DWORD PTR [rsp + 32], REG_OPTION_NON_VOLATILE
    mov DWORD PTR [rsp + 40], KEY_WRITE
    mov QWORD PTR [rsp + 48], 0
    lea rax, hKey
    mov [rsp + 56], rax
    lea rax, dwDisposition
    mov [rsp + 64], rax
    call RegCreateKeyExW
    test eax, eax
    jnz done
    
    mov rcx, hKey
    call RegCloseKey
    xor eax, eax
    
done:
    add rsp, 80
    pop rbx
    ret
RegCreateKey ENDP

END

