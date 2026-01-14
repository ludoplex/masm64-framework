;-----------------------------------------------------------------------------
; string64.inc - String Manipulation Library Header
;-----------------------------------------------------------------------------
; Provides Unicode-first string operations for MASM64 applications.
; All string functions use wide characters (UTF-16LE) by default.
;-----------------------------------------------------------------------------

IFNDEF STRING64_INC
STRING64_INC EQU 1

;-----------------------------------------------------------------------------
; Function Prototypes - Wide String (Unicode)
;-----------------------------------------------------------------------------

; Get length of wide string (not including null terminator)
; Parameters: pString - Pointer to null-terminated wide string
; Returns: Length in characters (QWORD)
Str_LenW PROTO pString:QWORD

; Copy wide string
; Parameters: pDest - Destination buffer
;             pSrc - Source string
; Returns: pDest
Str_CopyW PROTO pDest:QWORD, pSrc:QWORD

; Copy wide string with length limit
; Parameters: pDest - Destination buffer
;             pSrc - Source string
;             cchMax - Maximum characters to copy (including null)
; Returns: pDest
Str_CopyNW PROTO pDest:QWORD, pSrc:QWORD, cchMax:QWORD

; Concatenate wide strings
; Parameters: pDest - Destination (must have space)
;             pSrc - String to append
; Returns: pDest
Str_CatW PROTO pDest:QWORD, pSrc:QWORD

; Compare wide strings (case-sensitive)
; Parameters: pStr1 - First string
;             pStr2 - Second string
; Returns: 0 if equal, <0 if str1<str2, >0 if str1>str2
Str_CmpW PROTO pStr1:QWORD, pStr2:QWORD

; Compare wide strings (case-insensitive)
; Parameters: pStr1 - First string
;             pStr2 - Second string
; Returns: 0 if equal, <0 if str1<str2, >0 if str1>str2
Str_CmpIW PROTO pStr1:QWORD, pStr2:QWORD

; Find character in wide string
; Parameters: pString - String to search
;             wChar - Character to find
; Returns: Pointer to character, or NULL if not found
Str_ChrW PROTO pString:QWORD, wChar:WORD

; Find last occurrence of character
; Parameters: pString - String to search
;             wChar - Character to find
; Returns: Pointer to character, or NULL if not found
Str_RChrW PROTO pString:QWORD, wChar:WORD

; Find substring in wide string
; Parameters: pString - String to search
;             pSubstr - Substring to find
; Returns: Pointer to first occurrence, or NULL
Str_StrW PROTO pString:QWORD, pSubstr:QWORD

; Convert wide string to uppercase (in-place)
; Parameters: pString - String to convert
; Returns: pString
Str_UpperW PROTO pString:QWORD

; Convert wide string to lowercase (in-place)
; Parameters: pString - String to convert
; Returns: pString
Str_LowerW PROTO pString:QWORD

; Trim whitespace from both ends (in-place)
; Parameters: pString - String to trim
; Returns: pString
Str_TrimW PROTO pString:QWORD

;-----------------------------------------------------------------------------
; Function Prototypes - ANSI String
;-----------------------------------------------------------------------------

; Get length of ANSI string
Str_LenA PROTO pString:QWORD

; Copy ANSI string
Str_CopyA PROTO pDest:QWORD, pSrc:QWORD

; Compare ANSI strings
Str_CmpA PROTO pStr1:QWORD, pStr2:QWORD

;-----------------------------------------------------------------------------
; Function Prototypes - Conversion
;-----------------------------------------------------------------------------

; Convert ANSI to Wide string
; Parameters: pDest - Destination wide string buffer
;             cchDest - Destination buffer size in characters
;             pSrc - Source ANSI string
; Returns: Number of characters written (0 on failure)
Str_AtoW PROTO pDest:QWORD, cchDest:DWORD, pSrc:QWORD

; Convert Wide to ANSI string
; Parameters: pDest - Destination ANSI buffer
;             cbDest - Destination buffer size in bytes
;             pSrc - Source wide string
; Returns: Number of bytes written (0 on failure)
Str_WtoA PROTO pDest:QWORD, cbDest:DWORD, pSrc:QWORD

; Convert integer to wide string
; Parameters: value - Integer value
;             pBuffer - Output buffer
;             radix - Base (10 for decimal, 16 for hex)
; Returns: pBuffer
Str_FromIntW PROTO value:QWORD, pBuffer:QWORD, radix:DWORD

; Convert wide string to integer
; Parameters: pString - String to convert
; Returns: Integer value
Str_ToIntW PROTO pString:QWORD

; Convert QWORD to hex string
; Parameters: value - Value to convert
;             pBuffer - Output buffer (must hold 17 chars)
; Returns: pBuffer
Str_FromHexW PROTO value:QWORD, pBuffer:QWORD

;-----------------------------------------------------------------------------
; String Constants
;-----------------------------------------------------------------------------
STR_MAX_PATH    EQU 260
STR_MAX_BUFFER  EQU 32768

ENDIF ; STRING64_INC

