;-----------------------------------------------------------------------------
; memory64.asm - Memory Management Library Implementation
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc
INCLUDE memory64.inc

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF GetProcessHeap:PROC
EXTERNDEF HeapAlloc:PROC
EXTERNDEF HeapReAlloc:PROC
EXTERNDEF HeapFree:PROC
EXTERNDEF HeapSize:PROC
EXTERNDEF VirtualAlloc:PROC
EXTERNDEF VirtualFree:PROC
EXTERNDEF VirtualProtect:PROC
EXTERNDEF RtlMoveMemory:PROC
EXTERNDEF RtlFillMemory:PROC
EXTERNDEF RtlZeroMemory:PROC
EXTERNDEF RtlCompareMemory:PROC

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

g_hProcessHeap  QWORD 0

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; Internal: GetHeap - Get or initialize process heap handle
;-----------------------------------------------------------------------------
GetHeap PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov rax, g_hProcessHeap
    test rax, rax
    jnz have_heap
    
    call GetProcessHeap
    mov g_hProcessHeap, rax
    
have_heap:
    add rsp, SHADOW_SPACE
    ret
GetHeap ENDP

;-----------------------------------------------------------------------------
; Mem_Alloc - Allocate memory
;-----------------------------------------------------------------------------
Mem_Alloc PROC FRAME
    push rbx
    .pushreg rbx
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov rbx, rcx                        ; Save size
    
    call GetHeap
    test rax, rax
    jz alloc_failed
    
    ; HeapAlloc(hHeap, dwFlags, dwBytes)
    mov rcx, rax                        ; hHeap
    xor edx, edx                        ; dwFlags = 0
    mov r8, rbx                         ; dwBytes
    call HeapAlloc
    jmp done
    
alloc_failed:
    xor eax, eax
    
done:
    add rsp, SHADOW_SPACE
    pop rbx
    ret
Mem_Alloc ENDP

;-----------------------------------------------------------------------------
; Mem_AllocZero - Allocate zeroed memory
;-----------------------------------------------------------------------------
Mem_AllocZero PROC FRAME
    push rbx
    .pushreg rbx
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov rbx, rcx                        ; Save size
    
    call GetHeap
    test rax, rax
    jz alloc_failed
    
    mov rcx, rax                        ; hHeap
    mov edx, HEAP_ZERO_MEMORY           ; dwFlags
    mov r8, rbx                         ; dwBytes
    call HeapAlloc
    jmp done
    
alloc_failed:
    xor eax, eax
    
done:
    add rsp, SHADOW_SPACE
    pop rbx
    ret
Mem_AllocZero ENDP

;-----------------------------------------------------------------------------
; Mem_Realloc - Reallocate memory
;-----------------------------------------------------------------------------
Mem_Realloc PROC FRAME
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov rbx, rcx                        ; pMem
    mov rdi, rdx                        ; cbNewSize
    
    call GetHeap
    test rax, rax
    jz realloc_failed
    
    ; HeapReAlloc(hHeap, dwFlags, lpMem, dwBytes)
    mov rcx, rax                        ; hHeap
    xor edx, edx                        ; dwFlags = 0
    mov r8, rbx                         ; lpMem
    mov r9, rdi                         ; dwBytes
    call HeapReAlloc
    jmp done
    
realloc_failed:
    xor eax, eax
    
done:
    add rsp, SHADOW_SPACE
    pop rdi
    pop rbx
    ret
Mem_Realloc ENDP

;-----------------------------------------------------------------------------
; Mem_Free - Free allocated memory
;-----------------------------------------------------------------------------
Mem_Free PROC FRAME
    push rbx
    .pushreg rbx
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov rbx, rcx                        ; pMem
    
    call GetHeap
    test rax, rax
    jz free_failed
    
    ; HeapFree(hHeap, dwFlags, lpMem)
    mov rcx, rax                        ; hHeap
    xor edx, edx                        ; dwFlags = 0
    mov r8, rbx                         ; lpMem
    call HeapFree
    jmp done
    
free_failed:
    xor eax, eax
    
done:
    add rsp, SHADOW_SPACE
    pop rbx
    ret
Mem_Free ENDP

;-----------------------------------------------------------------------------
; Mem_Size - Get allocated block size
;-----------------------------------------------------------------------------
Mem_Size PROC FRAME
    push rbx
    .pushreg rbx
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov rbx, rcx                        ; pMem
    
    call GetHeap
    test rax, rax
    jz size_failed
    
    ; HeapSize(hHeap, dwFlags, lpMem)
    mov rcx, rax
    xor edx, edx
    mov r8, rbx
    call HeapSize
    jmp done
    
size_failed:
    mov rax, -1
    
done:
    add rsp, SHADOW_SPACE
    pop rbx
    ret
Mem_Size ENDP

;-----------------------------------------------------------------------------
; Mem_VirtualAlloc - Allocate virtual memory
;-----------------------------------------------------------------------------
Mem_VirtualAlloc PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; RCX = cbSize, EDX = flProtect
    mov r9d, edx                        ; flProtect
    mov r8d, MEM_COMMIT OR MEM_RESERVE  ; flAllocationType
    mov rdx, rcx                        ; dwSize
    xor ecx, ecx                        ; lpAddress = NULL
    call VirtualAlloc
    
    add rsp, SHADOW_SPACE
    ret
Mem_VirtualAlloc ENDP

;-----------------------------------------------------------------------------
; Mem_VirtualFree - Free virtual memory
;-----------------------------------------------------------------------------
Mem_VirtualFree PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; RCX = pMem
    xor edx, edx                        ; dwSize = 0 for MEM_RELEASE
    mov r8d, MEM_RELEASE                ; dwFreeType
    call VirtualFree
    
    add rsp, SHADOW_SPACE
    ret
Mem_VirtualFree ENDP

;-----------------------------------------------------------------------------
; Mem_VirtualProtect - Change memory protection
;-----------------------------------------------------------------------------
Mem_VirtualProtect PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    ; RCX = pMem, RDX = cbSize, R8D = flNewProtect, R9 = pflOldProtect
    mov QWORD PTR [rsp + 32], r9        ; lpflOldProtect
    mov r9d, r8d                        ; flNewProtect
    ; RDX already has dwSize
    ; RCX already has lpAddress
    call VirtualProtect
    
    add rsp, 40
    ret
Mem_VirtualProtect ENDP

;-----------------------------------------------------------------------------
; Mem_Copy - Copy memory
;-----------------------------------------------------------------------------
Mem_Copy PROC FRAME
    push rbx
    .pushreg rbx
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov rbx, rcx                        ; Save dest for return
    
    ; RtlMoveMemory(Destination, Source, Length)
    ; RCX = pDest, RDX = pSrc, R8 = cbSize
    call RtlMoveMemory
    
    mov rax, rbx
    
    add rsp, SHADOW_SPACE
    pop rbx
    ret
Mem_Copy ENDP

;-----------------------------------------------------------------------------
; Mem_Set - Fill memory
;-----------------------------------------------------------------------------
Mem_Set PROC FRAME
    push rbx
    .pushreg rbx
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov rbx, rcx                        ; Save dest
    
    ; RtlFillMemory(Destination, Length, Fill)
    ; RCX = pDest, RDX = bValue, R8 = cbSize
    mov r9d, edx                        ; Save fill value
    mov rdx, r8                         ; Length
    mov r8d, r9d                        ; Fill value
    call RtlFillMemory
    
    mov rax, rbx
    
    add rsp, SHADOW_SPACE
    pop rbx
    ret
Mem_Set ENDP

;-----------------------------------------------------------------------------
; Mem_Zero - Zero memory
;-----------------------------------------------------------------------------
Mem_Zero PROC FRAME
    push rbx
    .pushreg rbx
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    mov rbx, rcx                        ; Save dest
    
    ; RtlZeroMemory(Destination, Length)
    ; RCX = pDest, RDX = cbSize already set
    call RtlZeroMemory
    
    mov rax, rbx
    
    add rsp, SHADOW_SPACE
    pop rbx
    ret
Mem_Zero ENDP

;-----------------------------------------------------------------------------
; Mem_Cmp - Compare memory
;-----------------------------------------------------------------------------
Mem_Cmp PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; RCX = pMem1, RDX = pMem2, R8 = cbSize
    mov r9, r8                          ; Save size
    call RtlCompareMemory
    
    ; RtlCompareMemory returns number of matching bytes
    ; Return 0 if all match, non-zero otherwise
    cmp rax, r9
    mov eax, 0
    jz done
    mov eax, 1
    
done:
    add rsp, SHADOW_SPACE
    ret
Mem_Cmp ENDP

END

