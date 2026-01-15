;-----------------------------------------------------------------------------
; Shellcode Template - Position-Independent Code
;-----------------------------------------------------------------------------
; MASM64 Framework - Position-Independent Shellcode
;
; To customize: Edit config.inc, add payload in marked section below
;
; This template resolves kernel32 APIs via PEB walking, then provides
; GetProcAddress and LoadLibraryA for loading additional functionality.
;
; WARNING: Use responsibly and only in authorized security testing.
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

;-----------------------------------------------------------------------------
; Project Configuration
;-----------------------------------------------------------------------------
INCLUDE config.inc

;-----------------------------------------------------------------------------
; Code Section - Position Independent (no .DATA section)
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; ShellcodeEntry - Entry Point (must be first)
;-----------------------------------------------------------------------------
ShellcodeEntry PROC
    push rbx
    push rdi
    push rsi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 88
    
    ; Find kernel32 base address
    call FindKernel32
    test rax, rax
    jz exit_shellcode
    mov r12, rax                        ; r12 = kernel32 base
    
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
    
    ; Find ExitProcess
    mov rcx, r12
    mov edx, HASH_EXITPROCESS
    call FindExportByHash
    test rax, rax
    jz exit_shellcode
    mov r15, rax                        ; r15 = ExitProcess
    
    ;-------------------------------------------------------------------------
    ; PAYLOAD SECTION - Add your code here
    ;-------------------------------------------------------------------------
    ; Available registers:
    ;   r12 = kernel32.dll base address
    ;   r13 = GetProcAddress function pointer
    ;   r14 = LoadLibraryA function pointer
    ;   r15 = ExitProcess function pointer
    ;
    ; Example: Exit cleanly
    xor ecx, ecx
    call r15
    ;-------------------------------------------------------------------------
    
exit_shellcode:
    add rsp, 88
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
; FindKernel32 - Locate kernel32.dll via PEB
;-----------------------------------------------------------------------------
FindKernel32 PROC
    push rbx
    push rdi
    sub rsp, 40
    
    mov rax, gs:[TEB_PEB_OFFSET]
    test rax, rax
    jz not_found
    
    mov rax, [rax + PEB_LDR_OFFSET]
    test rax, rax
    jz not_found
    
    mov rdi, [rax + LDR_INLOAD_OFFSET]
    mov rbx, rdi
    
walk_list:
    mov rax, [rdi]
    cmp rax, rbx
    je not_found
    
    mov rdi, rax
    
    mov rax, [rdi + LDR_DLLBASE_OFFSET]
    test rax, rax
    jz walk_list
    
    mov rcx, [rdi + LDR_FULLNAME_OFFSET + 8]
    test rcx, rcx
    jz walk_list
    
    xor rdx, rdx
find_name:
    movzx eax, WORD PTR [rcx + rdx*2]
    test ax, ax
    jz check_name
    cmp ax, '\'
    jne next_char
    lea r8, [rcx + rdx*2 + 2]
next_char:
    inc rdx
    jmp find_name
    
check_name:
    test r8, r8
    jz walk_list
    
    movzx eax, WORD PTR [r8]
    or al, 20h
    cmp al, 'k'
    jne walk_list
    
    movzx eax, WORD PTR [r8 + 2]
    or al, 20h
    cmp al, 'e'
    jne walk_list
    
    mov rax, [rdi + LDR_DLLBASE_OFFSET]
    jmp done
    
not_found:
    xor eax, eax
    
done:
    add rsp, 40
    pop rdi
    pop rbx
    ret
FindKernel32 ENDP

;-----------------------------------------------------------------------------
; FindExportByHash - Find export by djb2 hash
;-----------------------------------------------------------------------------
FindExportByHash PROC
    push rbx
    push rdi
    push rsi
    push r12
    push r13
    sub rsp, 56
    
    mov r12, rcx
    mov r13d, edx
    
    mov eax, [r12 + 3Ch]
    lea rdi, [r12 + rax]
    
    mov eax, [rdi + 88h]
    test eax, eax
    jz not_found
    
    lea rsi, [r12 + rax]
    
    mov eax, [rsi + 20h]
    lea rbx, [r12 + rax]
    
    mov ecx, [rsi + 18h]
    xor edi, edi
    
search_loop:
    cmp edi, ecx
    jge not_found
    
    mov eax, [rbx + rdi*4]
    lea rdx, [r12 + rax]
    
    call HashString
    cmp eax, r13d
    je found
    
    inc edi
    jmp search_loop
    
found:
    mov eax, [rsi + 24h]
    lea rax, [r12 + rax]
    movzx eax, WORD PTR [rax + rdi*2]
    
    mov ecx, [rsi + 1Ch]
    lea rcx, [r12 + rcx]
    mov eax, [rcx + rax*4]
    lea rax, [r12 + rax]
    jmp done
    
not_found:
    xor eax, eax
    
done:
    add rsp, 56
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret
FindExportByHash ENDP

;-----------------------------------------------------------------------------
; HashString - Compute djb2 hash
;-----------------------------------------------------------------------------
HashString PROC
    push rbx
    
    mov eax, 5381
    
hash_loop:
    movzx ecx, BYTE PTR [rdx]
    test cl, cl
    jz done
    
    mov ebx, eax
    shl eax, 5
    add eax, ebx
    add eax, ecx
    
    inc rdx
    jmp hash_loop
    
done:
    pop rbx
    ret
HashString ENDP

END
