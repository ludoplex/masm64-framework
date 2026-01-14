;-----------------------------------------------------------------------------
; arena64.asm - Arena Allocator Implementation
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc
INCLUDE arena64.inc

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF VirtualAlloc:PROC
EXTERNDEF VirtualFree:PROC
EXTERNDEF RtlZeroMemory:PROC

;-----------------------------------------------------------------------------
; Memory Constants
;-----------------------------------------------------------------------------
MEM_RESERVE             EQU 2000h
MEM_COMMIT              EQU 1000h
MEM_RELEASE             EQU 8000h
PAGE_READWRITE          EQU 04h
PAGE_SIZE               EQU 4096

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; Arena_Create - Create a new arena
;-----------------------------------------------------------------------------
Arena_Create PROC FRAME
    LOCAL cbReserve:QWORD
    LOCAL cbCommit:QWORD
    LOCAL dwGrowth:DWORD
    LOCAL pMemory:QWORD
    LOCAL pArena:QWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 64
    .allocstack 64
    .endprolog
    
    mov cbReserve, rcx
    mov cbCommit, rdx
    mov dwGrowth, r8d
    
    ; Align reserve size to page boundary
    add rcx, PAGE_SIZE - 1
    and rcx, NOT (PAGE_SIZE - 1)
    mov cbReserve, rcx
    
    ; Align commit size to page boundary
    mov rax, rdx
    add rax, PAGE_SIZE - 1
    and rax, NOT (PAGE_SIZE - 1)
    mov cbCommit, rax
    
    ; Need space for ARENA struct + user memory
    mov rdi, rcx                        ; Total reserve size
    add rdi, SIZEOF ARENA
    add rdi, PAGE_SIZE - 1
    and rdi, NOT (PAGE_SIZE - 1)
    
    ; Initial commit includes ARENA struct
    mov rsi, rax                        ; User commit
    add rsi, SIZEOF ARENA
    add rsi, PAGE_SIZE - 1
    and rsi, NOT (PAGE_SIZE - 1)
    
    ; Reserve memory
    xor ecx, ecx                        ; lpAddress = NULL
    mov rdx, rdi                        ; dwSize = total reserve
    mov r8d, MEM_RESERVE                ; flAllocationType
    mov r9d, PAGE_READWRITE             ; flProtect
    call VirtualAlloc
    test rax, rax
    jz failed
    mov pMemory, rax
    
    ; Commit initial pages
    mov rcx, rax                        ; lpAddress
    mov rdx, rsi                        ; dwSize = initial commit
    mov r8d, MEM_COMMIT
    mov r9d, PAGE_READWRITE
    call VirtualAlloc
    test rax, rax
    jz free_and_fail
    
    ; Initialize ARENA structure at start of memory
    mov rdi, pMemory
    mov pArena, rdi
    
    ; Calculate user memory base (after ARENA struct, aligned)
    lea rax, [rdi + SIZEOF ARENA + 15]
    and rax, NOT 15                     ; 16-byte aligned
    mov [rdi].ARENA.pBase, rax
    mov [rdi].ARENA.pCurrent, rax
    
    ; Calculate end of committed memory
    mov rax, pMemory
    add rax, rsi
    mov [rdi].ARENA.pEnd, rax
    
    ; Calculate end of reserved memory
    mov rax, pMemory
    add rax, cbReserve
    add rax, SIZEOF ARENA
    mov [rdi].ARENA.pReserveEnd, rax
    
    mov rax, rsi
    mov [rdi].ARENA.cbCommitted, rax
    mov rax, cbReserve
    mov [rdi].ARENA.cbReserved, rax
    mov eax, dwGrowth
    mov [rdi].ARENA.dwGrowthMode, eax
    mov [rdi].ARENA.dwFlags, 0
    mov QWORD PTR [rdi].ARENA.pNext, 0
    mov QWORD PTR [rdi].ARENA.pParent, 0
    
    mov rax, pArena
    jmp done
    
free_and_fail:
    mov rcx, pMemory
    xor edx, edx
    mov r8d, MEM_RELEASE
    call VirtualFree
    
failed:
    xor eax, eax
    
done:
    add rsp, 64
    pop rsi
    pop rdi
    pop rbx
    ret
Arena_Create ENDP

;-----------------------------------------------------------------------------
; Arena_Destroy - Destroy arena and free all memory
;-----------------------------------------------------------------------------
Arena_Destroy PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    test rcx, rcx
    jz done
    
    ; Free the virtual memory (arena struct is at start)
    xor edx, edx                        ; dwSize = 0 for MEM_RELEASE
    mov r8d, MEM_RELEASE
    call VirtualFree
    
done:
    add rsp, SHADOW_SPACE
    ret
Arena_Destroy ENDP

;-----------------------------------------------------------------------------
; Arena_Alloc - Allocate from arena
;-----------------------------------------------------------------------------
Arena_Alloc PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    test rcx, rcx
    jz failed
    
    ; Get current pointer
    mov rax, [rcx].ARENA.pCurrent
    
    ; Calculate new position (align size to 8 bytes for safety)
    add rdx, 7
    and rdx, NOT 7
    lea r8, [rax + rdx]
    
    ; Check if we have space
    cmp r8, [rcx].ARENA.pEnd
    jbe have_space
    
    ; Need more space - check growth mode
    mov r9d, [rcx].ARENA.dwGrowthMode
    cmp r9d, ARENA_GROW_COMMIT
    jne failed                          ; Other modes not implemented inline
    
    ; Try to commit more pages
    push rcx
    push rax
    push rdx
    
    ; Calculate how much more we need
    mov rax, r8
    sub rax, [rcx].ARENA.pEnd
    add rax, PAGE_SIZE - 1
    and rax, NOT (PAGE_SIZE - 1)
    mov rdx, rax                        ; Size to commit
    
    ; Check if within reserve
    mov rax, [rcx].ARENA.pEnd
    add rax, rdx
    cmp rax, [rcx].ARENA.pReserveEnd
    ja pop_and_fail
    
    ; Commit more pages
    mov rcx, [rcx].ARENA.pEnd
    mov r8d, MEM_COMMIT
    mov r9d, PAGE_READWRITE
    call VirtualAlloc
    
    pop rdx
    pop rax
    pop rcx
    
    test rax, rax
    jz failed
    
    ; Update arena end
    mov r8, [rcx].ARENA.cbCommitted
    add r8, rdx
    mov [rcx].ARENA.cbCommitted, r8
    
    ; Recalculate end pointer
    mov r8, [rcx].ARENA.pBase
    add r8, [rcx].ARENA.cbCommitted
    mov [rcx].ARENA.pEnd, r8
    
    ; Now try again
    mov rax, [rcx].ARENA.pCurrent
    lea r8, [rax + rdx]
    
have_space:
    ; Update current pointer
    mov [rcx].ARENA.pCurrent, r8
    ; RAX already has result pointer
    jmp done
    
pop_and_fail:
    add rsp, 24
    
failed:
    xor eax, eax
    
done:
    add rsp, 40
    ret
Arena_Alloc ENDP

;-----------------------------------------------------------------------------
; Arena_AllocAligned - Allocate aligned memory
;-----------------------------------------------------------------------------
Arena_AllocAligned PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    test rcx, rcx
    jz failed
    
    ; R8 = alignment (must be power of 2)
    ; Align current pointer
    mov rax, [rcx].ARENA.pCurrent
    add rax, r8
    dec rax
    neg r8
    and rax, r8
    neg r8                              ; Restore r8
    
    ; Calculate end position
    lea r9, [rax + rdx]
    
    ; Check space
    cmp r9, [rcx].ARENA.pEnd
    ja failed                           ; Simplified - no growth for aligned
    
    ; Update and return
    mov [rcx].ARENA.pCurrent, r9
    jmp done
    
failed:
    xor eax, eax
    
done:
    add rsp, 40
    ret
Arena_AllocAligned ENDP

;-----------------------------------------------------------------------------
; Arena_AllocZero - Allocate and zero memory
;-----------------------------------------------------------------------------
Arena_AllocZero PROC FRAME
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    mov rdi, rdx                        ; Save size
    
    call Arena_Alloc
    test rax, rax
    jz done
    
    mov rbx, rax                        ; Save pointer
    
    ; Zero the memory
    mov rcx, rax
    mov rdx, rdi
    call RtlZeroMemory
    
    mov rax, rbx
    
done:
    add rsp, 40
    pop rdi
    pop rbx
    ret
Arena_AllocZero ENDP

;-----------------------------------------------------------------------------
; Arena_Reset - Reset arena (free all allocations)
;-----------------------------------------------------------------------------
Arena_Reset PROC
    test rcx, rcx
    jz done
    
    mov rax, [rcx].ARENA.pBase
    mov [rcx].ARENA.pCurrent, rax
    
done:
    ret
Arena_Reset ENDP

;-----------------------------------------------------------------------------
; Arena_GetUsed - Get current usage
;-----------------------------------------------------------------------------
Arena_GetUsed PROC
    test rcx, rcx
    jz zero_ret
    
    mov rax, [rcx].ARENA.pCurrent
    sub rax, [rcx].ARENA.pBase
    ret
    
zero_ret:
    xor eax, eax
    ret
Arena_GetUsed ENDP

;-----------------------------------------------------------------------------
; Arena_GetFree - Get remaining space
;-----------------------------------------------------------------------------
Arena_GetFree PROC
    test rcx, rcx
    jz zero_ret
    
    mov rax, [rcx].ARENA.pEnd
    sub rax, [rcx].ARENA.pCurrent
    ret
    
zero_ret:
    xor eax, eax
    ret
Arena_GetFree ENDP

;-----------------------------------------------------------------------------
; Arena_PushScope - Save arena state
;-----------------------------------------------------------------------------
Arena_PushScope PROC
    test rcx, rcx
    jz done
    test rdx, rdx
    jz done
    
    mov rax, [rcx].ARENA.pCurrent
    mov [rdx].ARENA_SCOPE.pSavedCurrent, rax
    mov [rdx].ARENA_SCOPE.pArena, rcx
    
done:
    ret
Arena_PushScope ENDP

;-----------------------------------------------------------------------------
; Arena_PopScope - Restore arena state
;-----------------------------------------------------------------------------
Arena_PopScope PROC
    test rcx, rcx
    jz done
    
    mov rax, [rcx].ARENA_SCOPE.pArena
    test rax, rax
    jz done
    
    mov rdx, [rcx].ARENA_SCOPE.pSavedCurrent
    mov [rax].ARENA.pCurrent, rdx
    
done:
    ret
Arena_PopScope ENDP

END

