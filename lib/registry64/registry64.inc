;-----------------------------------------------------------------------------
; registry64.inc - Registry Operations Library Header
;-----------------------------------------------------------------------------
; Provides simplified registry access functions for MASM64 applications.
; All functions use Unicode (W-suffix) APIs.
;-----------------------------------------------------------------------------

IFNDEF REGISTRY64_INC
REGISTRY64_INC EQU 1

;-----------------------------------------------------------------------------
; Registry Root Keys
;-----------------------------------------------------------------------------
HKEY_CLASSES_ROOT       EQU 80000000h
HKEY_CURRENT_USER       EQU 80000001h
HKEY_LOCAL_MACHINE      EQU 80000002h
HKEY_USERS              EQU 80000003h
HKEY_CURRENT_CONFIG     EQU 80000005h

;-----------------------------------------------------------------------------
; Registry Access Rights
;-----------------------------------------------------------------------------
KEY_QUERY_VALUE         EQU 0001h
KEY_SET_VALUE           EQU 0002h
KEY_CREATE_SUB_KEY      EQU 0004h
KEY_ENUMERATE_SUB_KEYS  EQU 0008h
KEY_NOTIFY              EQU 0010h
KEY_CREATE_LINK         EQU 0020h
KEY_READ                EQU 20019h
KEY_WRITE               EQU 20006h
KEY_ALL_ACCESS          EQU 0F003Fh

;-----------------------------------------------------------------------------
; Registry Value Types
;-----------------------------------------------------------------------------
REG_NONE                EQU 0
REG_SZ                  EQU 1
REG_EXPAND_SZ           EQU 2
REG_BINARY              EQU 3
REG_DWORD               EQU 4
REG_DWORD_BIG_ENDIAN    EQU 5
REG_LINK                EQU 6
REG_MULTI_SZ            EQU 7
REG_QWORD               EQU 11

;-----------------------------------------------------------------------------
; Registry Options
;-----------------------------------------------------------------------------
REG_OPTION_NON_VOLATILE EQU 0
REG_OPTION_VOLATILE     EQU 1

;-----------------------------------------------------------------------------
; Function Prototypes
;-----------------------------------------------------------------------------

; Get DWORD value from registry
; Parameters: hRoot - Root key (HKEY_*)
;             pPath - Subkey path
;             pName - Value name
;             pdwValue - Pointer to receive DWORD value
; Returns: ERROR_SUCCESS or error code
RegGetDWORD PROTO hRoot:QWORD, pPath:QWORD, pName:QWORD, pdwValue:QWORD

; Set DWORD value in registry
; Parameters: hRoot - Root key
;             pPath - Subkey path
;             pName - Value name
;             dwValue - Value to set
; Returns: ERROR_SUCCESS or error code
RegSetDWORD PROTO hRoot:QWORD, pPath:QWORD, pName:QWORD, dwValue:DWORD

; Get QWORD value from registry
RegGetQWORD PROTO hRoot:QWORD, pPath:QWORD, pName:QWORD, pqwValue:QWORD

; Set QWORD value in registry
RegSetQWORD PROTO hRoot:QWORD, pPath:QWORD, pName:QWORD, qwValue:QWORD

; Get string value from registry
; Parameters: hRoot - Root key
;             pPath - Subkey path
;             pName - Value name
;             pBuffer - Buffer to receive string
;             cbBuffer - Buffer size in bytes
; Returns: ERROR_SUCCESS or error code
RegGetString PROTO hRoot:QWORD, pPath:QWORD, pName:QWORD, pBuffer:QWORD, cbBuffer:DWORD

; Set string value in registry
; Parameters: hRoot - Root key
;             pPath - Subkey path
;             pName - Value name
;             pValue - String value to set
; Returns: ERROR_SUCCESS or error code
RegSetString PROTO hRoot:QWORD, pPath:QWORD, pName:QWORD, pValue:QWORD

; Get binary value from registry
RegGetBinary PROTO hRoot:QWORD, pPath:QWORD, pName:QWORD, pBuffer:QWORD, pcbBuffer:QWORD

; Set binary value in registry
RegSetBinary PROTO hRoot:QWORD, pPath:QWORD, pName:QWORD, pData:QWORD, cbData:DWORD

; Delete a registry value
; Returns: ERROR_SUCCESS or error code
RegDeleteValue PROTO hRoot:QWORD, pPath:QWORD, pName:QWORD

; Delete a registry key (must have no subkeys)
; Returns: ERROR_SUCCESS or error code
RegDeleteKey PROTO hRoot:QWORD, pPath:QWORD

; Delete a registry key and all subkeys
; Returns: ERROR_SUCCESS or error code
RegDeleteTree PROTO hRoot:QWORD, pPath:QWORD

; Check if registry key exists
; Returns: TRUE if exists, FALSE otherwise
RegKeyExists PROTO hRoot:QWORD, pPath:QWORD

; Check if registry value exists
; Returns: TRUE if exists, FALSE otherwise
RegValueExists PROTO hRoot:QWORD, pPath:QWORD, pName:QWORD

; Create a registry key
; Returns: ERROR_SUCCESS or error code
RegCreateKey PROTO hRoot:QWORD, pPath:QWORD

; Enumerate subkeys
; Parameters: hRoot - Root key
;             pPath - Subkey path
;             pCallback - Callback function: BOOL Callback(pKeyName, pContext)
;             pContext - User context passed to callback
; Returns: ERROR_SUCCESS or error code
RegEnumSubKeys PROTO hRoot:QWORD, pPath:QWORD, pCallback:QWORD, pContext:QWORD

; Enumerate values
; Parameters: hRoot - Root key
;             pPath - Subkey path
;             pCallback - Callback: BOOL Callback(pValueName, dwType, pContext)
;             pContext - User context
; Returns: ERROR_SUCCESS or error code
RegEnumValues PROTO hRoot:QWORD, pPath:QWORD, pCallback:QWORD, pContext:QWORD

ENDIF ; REGISTRY64_INC

