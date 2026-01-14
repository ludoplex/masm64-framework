;-----------------------------------------------------------------------------
; memory64.inc - Memory Management Library Header
;-----------------------------------------------------------------------------
; Provides heap memory allocation and manipulation functions.
;-----------------------------------------------------------------------------

IFNDEF MEMORY64_INC
MEMORY64_INC EQU 1

;-----------------------------------------------------------------------------
; Heap Flags
;-----------------------------------------------------------------------------
HEAP_ZERO_MEMORY        EQU 00000008h
HEAP_NO_SERIALIZE       EQU 00000001h

;-----------------------------------------------------------------------------
; Memory Protection Constants
;-----------------------------------------------------------------------------
PAGE_NOACCESS           EQU 01h
PAGE_READONLY           EQU 02h
PAGE_READWRITE          EQU 04h
PAGE_EXECUTE            EQU 10h
PAGE_EXECUTE_READ       EQU 20h
PAGE_EXECUTE_READWRITE  EQU 40h

;-----------------------------------------------------------------------------
; Memory Allocation Types
;-----------------------------------------------------------------------------
MEM_COMMIT              EQU 1000h
MEM_RESERVE             EQU 2000h
MEM_DECOMMIT            EQU 4000h
MEM_RELEASE             EQU 8000h

;-----------------------------------------------------------------------------
; Function Prototypes
;-----------------------------------------------------------------------------

; Allocate memory from process heap
; Parameters: cbSize - Number of bytes to allocate
; Returns: Pointer to allocated memory, or NULL on failure
Mem_Alloc PROTO cbSize:QWORD

; Allocate zeroed memory from process heap
; Parameters: cbSize - Number of bytes to allocate
; Returns: Pointer to allocated memory, or NULL on failure
Mem_AllocZero PROTO cbSize:QWORD

; Reallocate memory block
; Parameters: pMem - Pointer to existing memory block
;             cbNewSize - New size in bytes
; Returns: Pointer to reallocated memory, or NULL on failure
Mem_Realloc PROTO pMem:QWORD, cbNewSize:QWORD

; Free allocated memory
; Parameters: pMem - Pointer to memory block to free
; Returns: TRUE on success, FALSE on failure
Mem_Free PROTO pMem:QWORD

; Get size of allocated block
; Parameters: pMem - Pointer to memory block
; Returns: Size in bytes, or -1 on failure
Mem_Size PROTO pMem:QWORD

; Allocate virtual memory
; Parameters: cbSize - Size in bytes
;             flProtect - Memory protection flags
; Returns: Pointer to allocated memory, or NULL
Mem_VirtualAlloc PROTO cbSize:QWORD, flProtect:DWORD

; Free virtual memory
; Parameters: pMem - Pointer to virtual memory
; Returns: TRUE on success
Mem_VirtualFree PROTO pMem:QWORD

; Change virtual memory protection
; Parameters: pMem - Pointer to memory
;             cbSize - Size of region
;             flNewProtect - New protection flags
;             pflOldProtect - Receives old protection
; Returns: TRUE on success
Mem_VirtualProtect PROTO pMem:QWORD, cbSize:QWORD, flNewProtect:DWORD, pflOldProtect:QWORD

; Copy memory
; Parameters: pDest - Destination pointer
;             pSrc - Source pointer
;             cbSize - Number of bytes to copy
; Returns: pDest
Mem_Copy PROTO pDest:QWORD, pSrc:QWORD, cbSize:QWORD

; Fill memory with value
; Parameters: pDest - Destination pointer
;             bValue - Byte value to fill
;             cbSize - Number of bytes to fill
; Returns: pDest
Mem_Set PROTO pDest:QWORD, bValue:BYTE, cbSize:QWORD

; Zero memory
; Parameters: pDest - Destination pointer
;             cbSize - Number of bytes to zero
; Returns: pDest
Mem_Zero PROTO pDest:QWORD, cbSize:QWORD

; Compare memory regions
; Parameters: pMem1 - First memory block
;             pMem2 - Second memory block
;             cbSize - Number of bytes to compare
; Returns: 0 if equal, non-zero if different
Mem_Cmp PROTO pMem1:QWORD, pMem2:QWORD, cbSize:QWORD

ENDIF ; MEMORY64_INC

