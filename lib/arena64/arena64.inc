;-----------------------------------------------------------------------------
; arena64.inc - Arena Allocator Library
;-----------------------------------------------------------------------------
; High-performance arena (bump/linear) allocator for MASM64.
;
; Features:
;   - O(1) allocation (pointer bump)
;   - O(1) mass deallocation (reset)
;   - No per-allocation overhead
;   - Excellent cache locality
;   - Optional alignment support
;   - Nested arena scopes
;
; Use Cases:
;   - Temporary/scratch allocations
;   - Frame allocators (per-frame game data)
;   - Request-scoped allocations
;   - Parse trees and temporary data structures
;
; Allocation Strategies:
;   ARENA_GROW_NONE    - Fixed size, fail on overflow
;   ARENA_GROW_COMMIT  - Commit more from reserved space
;   ARENA_GROW_CHAIN   - Chain new arenas together
;-----------------------------------------------------------------------------

IFNDEF ARENA64_INC
ARENA64_INC EQU 1

;-----------------------------------------------------------------------------
; Arena Growth Strategies
;-----------------------------------------------------------------------------
ARENA_GROW_NONE     EQU 0               ; Fixed size, no growth
ARENA_GROW_COMMIT   EQU 1               ; Commit more pages from reserve
ARENA_GROW_CHAIN    EQU 2               ; Allocate new block and chain

;-----------------------------------------------------------------------------
; Arena Flags
;-----------------------------------------------------------------------------
ARENA_FLAG_ZERO     EQU 1               ; Zero memory on allocation

;-----------------------------------------------------------------------------
; ARENA structure
;-----------------------------------------------------------------------------
; Describes an arena allocation region.
;-----------------------------------------------------------------------------
ARENA STRUCT
    pBase           QWORD ?             ; Base address of arena memory
    pCurrent        QWORD ?             ; Current allocation pointer
    pEnd            QWORD ?             ; End of committed memory
    pReserveEnd     QWORD ?             ; End of reserved memory
    cbCommitted     QWORD ?             ; Currently committed bytes
    cbReserved      QWORD ?             ; Total reserved bytes
    dwGrowthMode    DWORD ?             ; Growth strategy
    dwFlags         DWORD ?             ; Arena flags
    pNext           QWORD ?             ; Next arena in chain (if chained)
    pParent         QWORD ?             ; Parent arena (for nested scopes)
ARENA ENDS

;-----------------------------------------------------------------------------
; ARENA_SCOPE structure
;-----------------------------------------------------------------------------
; Saved state for nested arena scopes (like stack frames).
;-----------------------------------------------------------------------------
ARENA_SCOPE STRUCT
    pSavedCurrent   QWORD ?             ; Saved allocation pointer
    pArena          QWORD ?             ; Arena this scope belongs to
ARENA_SCOPE ENDS

;-----------------------------------------------------------------------------
; Function Prototypes
;-----------------------------------------------------------------------------

; Create a new arena
; Parameters: cbReserve - Total bytes to reserve
;             cbCommit - Initial bytes to commit
;             dwGrowth - Growth strategy (ARENA_GROW_*)
; Returns: Pointer to ARENA, or NULL on failure
Arena_Create PROTO cbReserve:QWORD, cbCommit:QWORD, dwGrowth:DWORD

; Destroy an arena and free all memory
; Parameters: pArena - Arena to destroy
Arena_Destroy PROTO pArena:QWORD

; Allocate from arena
; Parameters: pArena - Arena to allocate from
;             cbSize - Size in bytes
; Returns: Pointer to allocated memory, or NULL
Arena_Alloc PROTO pArena:QWORD, cbSize:QWORD

; Allocate aligned memory from arena
; Parameters: pArena - Arena
;             cbSize - Size in bytes
;             cbAlign - Alignment (must be power of 2)
; Returns: Aligned pointer, or NULL
Arena_AllocAligned PROTO pArena:QWORD, cbSize:QWORD, cbAlign:QWORD

; Allocate and zero memory
; Parameters: pArena - Arena
;             cbSize - Size in bytes
; Returns: Pointer to zeroed memory, or NULL
Arena_AllocZero PROTO pArena:QWORD, cbSize:QWORD

; Reset arena (free all allocations, keep memory)
; Parameters: pArena - Arena to reset
Arena_Reset PROTO pArena:QWORD

; Get current usage
; Parameters: pArena - Arena
; Returns: Bytes currently allocated
Arena_GetUsed PROTO pArena:QWORD

; Get remaining space
; Parameters: pArena - Arena
; Returns: Bytes available before growth/failure
Arena_GetFree PROTO pArena:QWORD

; Push arena scope (save current state)
; Parameters: pArena - Arena
;             pScope - ARENA_SCOPE to save state into
Arena_PushScope PROTO pArena:QWORD, pScope:QWORD

; Pop arena scope (restore state, free everything allocated since push)
; Parameters: pScope - Saved scope to restore
Arena_PopScope PROTO pScope:QWORD

; Create a temporary/scratch arena with automatic cleanup
; Parameters: cbSize - Size for scratch arena
;             pParent - Parent arena (optional, for chaining)
; Returns: Pointer to new arena
Arena_CreateTemp PROTO cbSize:QWORD, pParent:QWORD

;-----------------------------------------------------------------------------
; Convenience Macros
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; ARENA_ALLOC - Inline arena allocation
;-----------------------------------------------------------------------------
; Performs allocation inline for performance-critical code.
; Faster than function call when arena is in register.
;
; Parameters:
;   arena_ptr - Register containing arena pointer
;   size_val  - Size to allocate (register or immediate)
;   result_reg - Register to receive result
;   fail_label - Label to jump to on failure
;
; Clobbers: RAX, flags
;-----------------------------------------------------------------------------
ARENA_ALLOC MACRO arena_ptr, size_val, result_reg, fail_label
    mov result_reg, [arena_ptr].ARENA.pCurrent
    lea rax, [result_reg + size_val]
    cmp rax, [arena_ptr].ARENA.pEnd
    ja fail_label
    mov [arena_ptr].ARENA.pCurrent, rax
ENDM

;-----------------------------------------------------------------------------
; ARENA_ALLOC_ALIGNED - Inline aligned allocation
;-----------------------------------------------------------------------------
ARENA_ALLOC_ALIGNED MACRO arena_ptr, size_val, align_val, result_reg, fail_label
    mov result_reg, [arena_ptr].ARENA.pCurrent
    add result_reg, align_val - 1
    and result_reg, NOT (align_val - 1)
    lea rax, [result_reg + size_val]
    cmp rax, [arena_ptr].ARENA.pEnd
    ja fail_label
    mov [arena_ptr].ARENA.pCurrent, rax
ENDM

;-----------------------------------------------------------------------------
; ARENA_SCOPE_PUSH - Save arena state
;-----------------------------------------------------------------------------
ARENA_SCOPE_PUSH MACRO arena_ptr, scope_ptr
    mov rax, [arena_ptr].ARENA.pCurrent
    mov [scope_ptr].ARENA_SCOPE.pSavedCurrent, rax
    mov [scope_ptr].ARENA_SCOPE.pArena, arena_ptr
ENDM

;-----------------------------------------------------------------------------
; ARENA_SCOPE_POP - Restore arena state
;-----------------------------------------------------------------------------
ARENA_SCOPE_POP MACRO scope_ptr
    mov rax, [scope_ptr].ARENA_SCOPE.pArena
    mov rcx, [scope_ptr].ARENA_SCOPE.pSavedCurrent
    mov [rax].ARENA.pCurrent, rcx
ENDM

ENDIF ; ARENA64_INC

