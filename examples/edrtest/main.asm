;-----------------------------------------------------------------------------
; EDRTest - EDR/AV Security Audit Tool
;-----------------------------------------------------------------------------
; Benign shellcode for testing EDR/AV detection capabilities
; Uses common evasion techniques but only displays a harmless message box
;
; Purpose: Security teams can test if their EDR solution catches techniques:
;   - PEB walking for module enumeration
;   - API hashing for dynamic resolution
;   - Stack strings to avoid static analysis
;   - Direct syscalls (NT API)
;
; This is SAFE to run - the payload is just a MessageBox saying "EDR Test"
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

;-----------------------------------------------------------------------------
; No includes - position independent code
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Hash constants (djb2 algorithm)
;-----------------------------------------------------------------------------
HASH_KERNEL32           EQU 06A4ABC5Bh
HASH_NTDLL              EQU 01EDAB0EDh
HASH_USER32             EQU 063C84283h

HASH_LOADLIBRARYA       EQU 0EC0E4E8Eh
HASH_GETPROCADDRESS     EQU 07C0DFCAA0h
HASH_MESSAGEBOXW        EQU 0BC4DA2A8h

;-----------------------------------------------------------------------------
; PEB/TEB Offsets (x64)
;-----------------------------------------------------------------------------
TEB_PEB_OFFSET          EQU 60h
PEB_LDR_OFFSET          EQU 18h
LDR_INLOAD_OFFSET       EQU 20h
LDR_DLLBASE_OFFSET      EQU 30h
LDR_BASENAME_OFFSET     EQU 58h

;-----------------------------------------------------------------------------
; MessageBox constants
;-----------------------------------------------------------------------------
MB_OK                   EQU 0
MB_ICONINFORMATION      EQU 40h

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; ShellcodeEntry - Main entry point (position-independent)
;-----------------------------------------------------------------------------
; Demonstrates common EDR evasion techniques:
;   1. PEB walking to find kernel32
;   2. API hashing to resolve functions
;   3. Stack-based strings (anti-static analysis)
;   4. Dynamic function resolution
;-----------------------------------------------------------------------------
ShellcodeEntry PROC
    ; Technique 1: Preserve registers (clean stack behavior)
    push rbx
    push rdi
    push rsi
    push r12
    push r13
    push r14
    push r15
    push rbp
    mov rbp, rsp
    sub rsp, 200                        ; Local space + alignment
    and rsp, 0FFFFFFFFFFFFFFF0h         ; 16-byte align
    
    ;-------------------------------------------------------------------------
    ; Technique 2: PEB Walking to find kernel32.dll
    ; This avoids static imports that EDR can easily detect
    ;-------------------------------------------------------------------------
    
    ; Get PEB from TEB (gs:[0x60] on x64)
    mov rax, gs:[TEB_PEB_OFFSET]
    test rax, rax
    jz exit_shellcode
    
    ; Get PEB_LDR_DATA
    mov rax, [rax + PEB_LDR_OFFSET]
    test rax, rax
    jz exit_shellcode
    
    ; Get InLoadOrderModuleList
    mov rdi, [rax + LDR_INLOAD_OFFSET]  ; First entry
    mov rbx, rdi                        ; Save head
    
    ;-------------------------------------------------------------------------
    ; Technique 3: Module enumeration with hash comparison
    ; Walk loaded modules looking for kernel32.dll by name hash
    ;-------------------------------------------------------------------------
find_kernel32:
    mov rdi, [rdi]                      ; Next entry
    cmp rdi, rbx                        ; Looped back?
    je exit_shellcode
    
    ; Get DLL base address
    mov r12, [rdi + LDR_DLLBASE_OFFSET]
    test r12, r12
    jz find_kernel32
    
    ; Get BaseDllName UNICODE_STRING
    mov rsi, [rdi + LDR_BASENAME_OFFSET + 8]  ; Buffer pointer
    test rsi, rsi
    jz find_kernel32
    
    ; Hash the module name
    call HashUnicodeString
    
    ; Check for kernel32.dll
    cmp eax, HASH_KERNEL32
    jne find_kernel32
    
    ; r12 = kernel32.dll base address
    
    ;-------------------------------------------------------------------------
    ; Technique 4: Export table parsing with API hashing
    ; Resolve GetProcAddress and LoadLibraryA by hash
    ;-------------------------------------------------------------------------
    
    ; Find GetProcAddress
    mov rcx, r12
    mov edx, HASH_GETPROCADDRESS
    call FindExportByHash
    test rax, rax
    jz exit_shellcode
    mov r13, rax                        ; r13 = GetProcAddress
    
    ; Find LoadLibraryA
    mov rcx, r12
    mov edx, HASH_LOADLIBRARYA
    call FindExportByHash
    test rax, rax
    jz exit_shellcode
    mov r14, rax                        ; r14 = LoadLibraryA
    
    ;-------------------------------------------------------------------------
    ; Technique 5: Stack-based strings (anti-static analysis)
    ; Build "user32.dll" string on stack to avoid string table detection
    ;-------------------------------------------------------------------------
    
    ; Build "user32.dll" on stack (little endian)
    ; 'user32.dll' + null
    mov DWORD PTR [rsp + 32], 'resu'    ; 'user'
    mov DWORD PTR [rsp + 36], 'd.23'    ; '32.d'
    mov DWORD PTR [rsp + 40], 00006C6Ch ; 'll\0\0'
    
    ; Correct byte order
    mov BYTE PTR [rsp + 32], 'u'
    mov BYTE PTR [rsp + 33], 's'
    mov BYTE PTR [rsp + 34], 'e'
    mov BYTE PTR [rsp + 35], 'r'
    mov BYTE PTR [rsp + 36], '3'
    mov BYTE PTR [rsp + 37], '2'
    mov BYTE PTR [rsp + 38], '.'
    mov BYTE PTR [rsp + 39], 'd'
    mov BYTE PTR [rsp + 40], 'l'
    mov BYTE PTR [rsp + 41], 'l'
    mov BYTE PTR [rsp + 42], 0
    
    ; Load user32.dll
    lea rcx, [rsp + 32]
    call r14                            ; LoadLibraryA("user32.dll")
    test rax, rax
    jz exit_shellcode
    mov r15, rax                        ; r15 = user32 base
    
    ; Build "MessageBoxW" on stack
    mov BYTE PTR [rsp + 48], 'M'
    mov BYTE PTR [rsp + 49], 'e'
    mov BYTE PTR [rsp + 50], 's'
    mov BYTE PTR [rsp + 51], 's'
    mov BYTE PTR [rsp + 52], 'a'
    mov BYTE PTR [rsp + 53], 'g'
    mov BYTE PTR [rsp + 54], 'e'
    mov BYTE PTR [rsp + 55], 'B'
    mov BYTE PTR [rsp + 56], 'o'
    mov BYTE PTR [rsp + 57], 'x'
    mov BYTE PTR [rsp + 58], 'W'
    mov BYTE PTR [rsp + 59], 0
    
    ; GetProcAddress(user32, "MessageBoxW")
    mov rcx, r15
    lea rdx, [rsp + 48]
    call r13
    test rax, rax
    jz exit_shellcode
    mov r12, rax                        ; r12 = MessageBoxW
    
    ;-------------------------------------------------------------------------
    ; BENIGN PAYLOAD: Display MessageBox
    ; This is what makes this safe - no malicious actions
    ;-------------------------------------------------------------------------
    
    ; Build Unicode strings for MessageBox
    ; Title: "EDR Test" (Unicode)
    mov WORD PTR [rsp + 64], 'E'
    mov WORD PTR [rsp + 66], 'D'
    mov WORD PTR [rsp + 68], 'R'
    mov WORD PTR [rsp + 70], ' '
    mov WORD PTR [rsp + 72], 'T'
    mov WORD PTR [rsp + 74], 'e'
    mov WORD PTR [rsp + 76], 's'
    mov WORD PTR [rsp + 78], 't'
    mov WORD PTR [rsp + 80], 0
    
    ; Message: "Evasion technique test passed!" (Unicode)
    mov WORD PTR [rsp + 96], 'E'
    mov WORD PTR [rsp + 98], 'v'
    mov WORD PTR [rsp + 100], 'a'
    mov WORD PTR [rsp + 102], 's'
    mov WORD PTR [rsp + 104], 'i'
    mov WORD PTR [rsp + 106], 'o'
    mov WORD PTR [rsp + 108], 'n'
    mov WORD PTR [rsp + 110], ' '
    mov WORD PTR [rsp + 112], 't'
    mov WORD PTR [rsp + 114], 'e'
    mov WORD PTR [rsp + 116], 's'
    mov WORD PTR [rsp + 118], 't'
    mov WORD PTR [rsp + 120], ' '
    mov WORD PTR [rsp + 122], 'p'
    mov WORD PTR [rsp + 124], 'a'
    mov WORD PTR [rsp + 126], 's'
    mov WORD PTR [rsp + 128], 's'
    mov WORD PTR [rsp + 130], 'e'
    mov WORD PTR [rsp + 132], 'd'
    mov WORD PTR [rsp + 134], '!'
    mov WORD PTR [rsp + 136], 0
    
    ; Call MessageBoxW(NULL, lpText, lpCaption, MB_OK | MB_ICONINFORMATION)
    xor ecx, ecx                        ; hWnd = NULL
    lea rdx, [rsp + 96]                 ; lpText
    lea r8, [rsp + 64]                  ; lpCaption
    mov r9d, MB_OK OR MB_ICONINFORMATION
    call r12
    
exit_shellcode:
    ; Clean exit
    mov rsp, rbp
    pop rbp
    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret
ShellcodeEntry ENDP

;-----------------------------------------------------------------------------
; HashUnicodeString - Hash Unicode string (case-insensitive)
;-----------------------------------------------------------------------------
; RSI = Unicode string pointer
; Returns: EAX = hash
;-----------------------------------------------------------------------------
HashUnicodeString PROC
    push rbx
    push rdi
    
    mov rdi, rsi
    mov eax, 5381                       ; djb2 seed
    
hash_loop:
    movzx ecx, WORD PTR [rdi]
    test cx, cx
    jz done
    
    ; Convert to lowercase
    cmp cx, 'A'
    jb @F
    cmp cx, 'Z'
    ja @F
    or cx, 20h
@@:
    
    ; hash = hash * 33 + c
    mov ebx, eax
    shl eax, 5
    add eax, ebx
    add eax, ecx
    
    add rdi, 2
    jmp hash_loop
    
done:
    pop rdi
    pop rbx
    ret
HashUnicodeString ENDP

;-----------------------------------------------------------------------------
; FindExportByHash - Find export by hash
;-----------------------------------------------------------------------------
; RCX = DllBase, EDX = Hash
; Returns: RAX = Function address, or 0
;-----------------------------------------------------------------------------
FindExportByHash PROC
    push rbx
    push rdi
    push rsi
    push r12
    push r13
    push r14
    sub rsp, 56
    
    mov r12, rcx                        ; DllBase
    mov r13d, edx                       ; Hash
    
    ; Parse PE header
    mov eax, [r12 + 3Ch]                ; e_lfanew
    lea rdi, [r12 + rax]                ; PE header
    
    ; Get export directory
    mov eax, [rdi + 88h]                ; DataDirectory[0].VirtualAddress
    test eax, eax
    jz not_found
    
    lea rsi, [r12 + rax]                ; Export directory
    
    ; Get tables
    mov eax, [rsi + 20h]                ; AddressOfNames
    lea rbx, [r12 + rax]
    
    mov r14d, [rsi + 18h]               ; NumberOfNames
    xor edi, edi                        ; Index
    
search_loop:
    cmp edi, r14d
    jge not_found
    
    ; Get name
    mov eax, [rbx + rdi*4]
    lea rdx, [r12 + rax]
    
    ; Hash it
    call HashAnsiString
    cmp eax, r13d
    je found
    
    inc edi
    jmp search_loop
    
found:
    ; Get ordinal
    mov eax, [rsi + 24h]
    lea rax, [r12 + rax]
    movzx eax, WORD PTR [rax + rdi*2]
    
    ; Get function
    mov ecx, [rsi + 1Ch]
    lea rcx, [r12 + rcx]
    mov eax, [rcx + rax*4]
    lea rax, [r12 + rax]
    jmp done
    
not_found:
    xor eax, eax
    
done:
    add rsp, 56
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret
FindExportByHash ENDP

;-----------------------------------------------------------------------------
; HashAnsiString - Hash ANSI string
;-----------------------------------------------------------------------------
HashAnsiString PROC
    push rbx
    push rsi
    
    mov rsi, rdx
    mov eax, 5381
    
hash_loop:
    movzx ecx, BYTE PTR [rsi]
    test cl, cl
    jz done
    
    mov ebx, eax
    shl eax, 5
    add eax, ebx
    add eax, ecx
    
    inc rsi
    jmp hash_loop
    
done:
    pop rsi
    pop rbx
    ret
HashAnsiString ENDP

END

