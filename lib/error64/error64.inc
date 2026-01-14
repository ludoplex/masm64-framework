;-----------------------------------------------------------------------------
; error64.inc - Error Handling Library Header
;-----------------------------------------------------------------------------
; Provides standardized error handling patterns for MASM64 applications.
; Uses Win32 GetLastError/SetLastError pattern.
;-----------------------------------------------------------------------------

IFNDEF ERROR64_INC
ERROR64_INC EQU 1

;-----------------------------------------------------------------------------
; Error Code Constants
;-----------------------------------------------------------------------------
ERROR_SUCCESS           EQU 0
ERROR_INVALID_FUNCTION  EQU 1
ERROR_FILE_NOT_FOUND    EQU 2
ERROR_PATH_NOT_FOUND    EQU 3
ERROR_ACCESS_DENIED     EQU 5
ERROR_INVALID_HANDLE    EQU 6
ERROR_NOT_ENOUGH_MEMORY EQU 8
ERROR_INVALID_PARAMETER EQU 87
ERROR_INSUFFICIENT_BUFFER EQU 122
ERROR_MORE_DATA         EQU 234
ERROR_NO_MORE_ITEMS     EQU 259

;-----------------------------------------------------------------------------
; Framework-specific error codes (0x20000000 range)
;-----------------------------------------------------------------------------
ERR_FRAMEWORK_BASE      EQU 20000000h
ERR_NULL_POINTER        EQU (ERR_FRAMEWORK_BASE + 1)
ERR_BUFFER_TOO_SMALL    EQU (ERR_FRAMEWORK_BASE + 2)
ERR_ALLOCATION_FAILED   EQU (ERR_FRAMEWORK_BASE + 3)
ERR_INVALID_STATE       EQU (ERR_FRAMEWORK_BASE + 4)
ERR_NOT_INITIALIZED     EQU (ERR_FRAMEWORK_BASE + 5)
ERR_ALREADY_INITIALIZED EQU (ERR_FRAMEWORK_BASE + 6)

;-----------------------------------------------------------------------------
; Function Prototypes
;-----------------------------------------------------------------------------

; Get the last error code set by framework functions
; Returns: Error code in RAX
Err_GetLast PROTO

; Set the last error code
; Parameters: dwError - Error code to set
; Returns: Nothing
Err_SetLast PROTO dwError:DWORD

; Get a human-readable error message for an error code
; Parameters: dwError - Error code
;             pBuffer - Output buffer for message
;             cchBuffer - Buffer size in characters
; Returns: Number of characters written, 0 on failure
Err_GetMessage PROTO dwError:DWORD, pBuffer:QWORD, cchBuffer:DWORD

; Format a system error code to a string
; Parameters: dwError - System error code
;             pBuffer - Output buffer
;             cchBuffer - Buffer size in characters
; Returns: Number of characters written
Err_FormatSystem PROTO dwError:DWORD, pBuffer:QWORD, cchBuffer:DWORD

; Check if an operation succeeded (error code is ERROR_SUCCESS)
; Parameters: dwError - Error code to check
; Returns: TRUE (1) if success, FALSE (0) otherwise
Err_IsSuccess PROTO dwError:DWORD

; Check if operation failed
; Parameters: dwError - Error code to check
; Returns: TRUE (1) if failed, FALSE (0) if success
Err_IsFailed PROTO dwError:DWORD

;-----------------------------------------------------------------------------
; Error Handling Macros
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; CHECK_ERROR - Check return value and jump to error label if zero
;-----------------------------------------------------------------------------
CHECK_ERROR MACRO error_label
    test rax, rax
    jz error_label
ENDM

;-----------------------------------------------------------------------------
; CHECK_BOOL - Check BOOL return and jump to error label if FALSE
;-----------------------------------------------------------------------------
CHECK_BOOL MACRO error_label
    test eax, eax
    jz error_label
ENDM

;-----------------------------------------------------------------------------
; CHECK_HANDLE - Check handle and jump if INVALID_HANDLE_VALUE
;-----------------------------------------------------------------------------
CHECK_HANDLE MACRO error_label
    cmp rax, INVALID_HANDLE_VALUE
    je error_label
ENDM

;-----------------------------------------------------------------------------
; ON_ERROR - Execute code block if last error is not success
;-----------------------------------------------------------------------------
ON_ERROR MACRO action
    call Err_GetLast
    test eax, eax
    jz @F
    action
@@:
ENDM

;-----------------------------------------------------------------------------
; RETURN_ERROR - Set error and return from function
;-----------------------------------------------------------------------------
RETURN_ERROR MACRO error_code
    mov ecx, error_code
    call Err_SetLast
    xor eax, eax
ENDM

;-----------------------------------------------------------------------------
; RETURN_SUCCESS - Clear error and return success
;-----------------------------------------------------------------------------
RETURN_SUCCESS MACRO return_value
    xor ecx, ecx
    call Err_SetLast
    IFNB <return_value>
        mov rax, return_value
    ELSE
        mov eax, TRUE
    ENDIF
ENDM

ENDIF ; ERROR64_INC

