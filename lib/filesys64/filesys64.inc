;-----------------------------------------------------------------------------
; filesys64.inc - Filesystem Operations Library Header
;-----------------------------------------------------------------------------
; Provides file and directory operations for MASM64 applications.
;-----------------------------------------------------------------------------

IFNDEF FILESYS64_INC
FILESYS64_INC EQU 1

;-----------------------------------------------------------------------------
; File Access Flags
;-----------------------------------------------------------------------------
GENERIC_READ            EQU 80000000h
GENERIC_WRITE           EQU 40000000h
GENERIC_EXECUTE         EQU 20000000h
GENERIC_ALL             EQU 10000000h

;-----------------------------------------------------------------------------
; File Share Mode
;-----------------------------------------------------------------------------
FILE_SHARE_READ         EQU 1
FILE_SHARE_WRITE        EQU 2
FILE_SHARE_DELETE       EQU 4

;-----------------------------------------------------------------------------
; Creation Disposition
;-----------------------------------------------------------------------------
CREATE_NEW              EQU 1
CREATE_ALWAYS           EQU 2
OPEN_EXISTING           EQU 3
OPEN_ALWAYS             EQU 4
TRUNCATE_EXISTING       EQU 5

;-----------------------------------------------------------------------------
; File Attributes
;-----------------------------------------------------------------------------
FILE_ATTRIBUTE_READONLY     EQU 1h
FILE_ATTRIBUTE_HIDDEN       EQU 2h
FILE_ATTRIBUTE_SYSTEM       EQU 4h
FILE_ATTRIBUTE_DIRECTORY    EQU 10h
FILE_ATTRIBUTE_ARCHIVE      EQU 20h
FILE_ATTRIBUTE_NORMAL       EQU 80h
FILE_ATTRIBUTE_TEMPORARY    EQU 100h

;-----------------------------------------------------------------------------
; Seek Methods
;-----------------------------------------------------------------------------
FILE_BEGIN              EQU 0
FILE_CURRENT            EQU 1
FILE_END                EQU 2

;-----------------------------------------------------------------------------
; Function Prototypes
;-----------------------------------------------------------------------------

; Check if file exists
; Parameters: pPath - File path
; Returns: TRUE if exists, FALSE otherwise
FileExists PROTO pPath:QWORD

; Check if directory exists
; Parameters: pPath - Directory path
; Returns: TRUE if exists, FALSE otherwise
DirectoryExists PROTO pPath:QWORD

; Create directory (and parent directories if needed)
; Parameters: pPath - Directory path
; Returns: TRUE on success
CreateDirectoryTree PROTO pPath:QWORD

; Copy a file
; Parameters: pSrc - Source file path
;             pDst - Destination file path
;             bFailIfExists - Fail if destination exists
; Returns: TRUE on success
FileCopy PROTO pSrc:QWORD, pDst:QWORD, bFailIfExists:DWORD

; Move/rename a file
; Parameters: pSrc - Source path
;             pDst - Destination path
; Returns: TRUE on success
FileMove PROTO pSrc:QWORD, pDst:QWORD

; Delete a file
; Parameters: pPath - File path
; Returns: TRUE on success
FileDelete PROTO pPath:QWORD

; Delete a directory (must be empty)
; Parameters: pPath - Directory path
; Returns: TRUE on success
DirectoryDelete PROTO pPath:QWORD

; Get file size
; Parameters: pPath - File path
;             pSize - Pointer to receive size
; Returns: TRUE on success
FileGetSize PROTO pPath:QWORD, pSize:QWORD

; Read entire file into allocated buffer
; Parameters: pPath - File path
;             ppBuffer - Receives pointer to allocated buffer
;             pSize - Receives size of data
; Returns: TRUE on success (caller must free buffer)
ReadFileToBuffer PROTO pPath:QWORD, ppBuffer:QWORD, pSize:QWORD

; Write buffer to file
; Parameters: pPath - File path
;             pBuffer - Data to write
;             cbBuffer - Size of data
; Returns: TRUE on success
WriteBufferToFile PROTO pPath:QWORD, pBuffer:QWORD, cbBuffer:QWORD

; Append buffer to file
; Parameters: pPath - File path
;             pBuffer - Data to append
;             cbBuffer - Size of data
; Returns: TRUE on success
AppendBufferToFile PROTO pPath:QWORD, pBuffer:QWORD, cbBuffer:QWORD

; Get file attributes
; Parameters: pPath - File path
; Returns: Attributes or INVALID_FILE_ATTRIBUTES on failure
FileGetAttributes PROTO pPath:QWORD

; Set file attributes
; Parameters: pPath - File path
;             dwAttr - New attributes
; Returns: TRUE on success
FileSetAttributes PROTO pPath:QWORD, dwAttr:DWORD

; Get temporary file path
; Parameters: pBuffer - Buffer for path
;             cchBuffer - Buffer size
; Returns: TRUE on success
GetTempFilePath PROTO pBuffer:QWORD, cchBuffer:DWORD

; Get current directory
; Parameters: pBuffer - Buffer for path
;             cchBuffer - Buffer size
; Returns: Length of path, 0 on failure
GetCurrentDir PROTO pBuffer:QWORD, cchBuffer:DWORD

; Set current directory
; Parameters: pPath - New directory
; Returns: TRUE on success
SetCurrentDir PROTO pPath:QWORD

; Get module directory (directory of current executable)
; Parameters: pBuffer - Buffer for path
;             cchBuffer - Buffer size
; Returns: TRUE on success
GetModuleDir PROTO pBuffer:QWORD, cchBuffer:DWORD

ENDIF ; FILESYS64_INC

