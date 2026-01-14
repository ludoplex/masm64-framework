;-----------------------------------------------------------------------------
; filesys64.asm - Filesystem Operations Library Implementation
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc
INCLUDE filesys64.inc
INCLUDE ..\memory64\memory64.inc

;-----------------------------------------------------------------------------
; Constants
;-----------------------------------------------------------------------------
INVALID_FILE_ATTRIBUTES EQU -1
INVALID_FILE_SIZE       EQU -1

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF GetFileAttributesW:PROC
EXTERNDEF SetFileAttributesW:PROC
EXTERNDEF CreateDirectoryW:PROC
EXTERNDEF RemoveDirectoryW:PROC
EXTERNDEF CopyFileW:PROC
EXTERNDEF MoveFileW:PROC
EXTERNDEF DeleteFileW:PROC
EXTERNDEF CreateFileW:PROC
EXTERNDEF ReadFile:PROC
EXTERNDEF WriteFile:PROC
EXTERNDEF CloseHandle:PROC
EXTERNDEF GetFileSize:PROC
EXTERNDEF SetFilePointer:PROC
EXTERNDEF GetTempPathW:PROC
EXTERNDEF GetTempFileNameW:PROC
EXTERNDEF GetCurrentDirectoryW:PROC
EXTERNDEF SetCurrentDirectoryW:PROC
EXTERNDEF GetModuleFileNameW:PROC

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; FileExists - Check if file exists
;-----------------------------------------------------------------------------
FileExists PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; GetFileAttributesW returns INVALID_FILE_ATTRIBUTES if not found
    call GetFileAttributesW
    cmp eax, INVALID_FILE_ATTRIBUTES
    je not_exists
    
    ; Check it's not a directory
    test eax, FILE_ATTRIBUTE_DIRECTORY
    jnz not_exists
    
    mov eax, 1                          ; TRUE
    jmp done
    
not_exists:
    xor eax, eax                        ; FALSE
    
done:
    add rsp, SHADOW_SPACE
    ret
FileExists ENDP

;-----------------------------------------------------------------------------
; DirectoryExists - Check if directory exists
;-----------------------------------------------------------------------------
DirectoryExists PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    call GetFileAttributesW
    cmp eax, INVALID_FILE_ATTRIBUTES
    je not_exists
    
    ; Check it IS a directory
    test eax, FILE_ATTRIBUTE_DIRECTORY
    jz not_exists
    
    mov eax, 1
    jmp done
    
not_exists:
    xor eax, eax
    
done:
    add rsp, SHADOW_SPACE
    ret
DirectoryExists ENDP

;-----------------------------------------------------------------------------
; CreateDirectoryTree - Create directory and parents
;-----------------------------------------------------------------------------
CreateDirectoryTree PROC FRAME
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 560                        ; Buffer for path + shadow
    .allocstack 560
    .endprolog
    
    mov rsi, rcx                        ; Save original path
    lea rdi, [rsp + 32]                 ; Buffer for working path
    
    ; Check if already exists
    mov rcx, rsi
    call GetFileAttributesW
    cmp eax, INVALID_FILE_ATTRIBUTES
    jne success                         ; Already exists
    
    ; Try to create directly first
    mov rcx, rsi
    xor edx, edx                        ; lpSecurityAttributes = NULL
    call CreateDirectoryW
    test eax, eax
    jnz success
    
    ; Need to create parent directories
    ; Copy path and iterate
    mov rcx, rdi
    mov rdx, rsi
create_loop:
    mov al, [rdx]
    mov [rcx], al
    test al, al
    jz try_create
    
    ; Check for path separator
    cmp al, '\'
    je found_sep
    cmp al, '/'
    je found_sep
    inc rcx
    inc rdx
    jmp create_loop
    
found_sep:
    mov rbx, rcx                        ; Save position
    mov BYTE PTR [rcx], 0               ; Temporarily terminate
    
    push rdx
    mov rcx, rdi
    xor edx, edx
    call CreateDirectoryW               ; May fail if exists, that's ok
    pop rdx
    
    mov BYTE PTR [rbx], '\'             ; Restore separator
    inc rcx
    inc rdx
    jmp create_loop
    
try_create:
    ; Final directory
    mov rcx, rsi
    xor edx, edx
    call CreateDirectoryW
    test eax, eax
    jnz success
    
    ; Check if it exists now
    mov rcx, rsi
    call GetFileAttributesW
    cmp eax, INVALID_FILE_ATTRIBUTES
    je failed
    
success:
    mov eax, 1
    jmp done
    
failed:
    xor eax, eax
    
done:
    add rsp, 560
    pop rsi
    pop rdi
    pop rbx
    ret
CreateDirectoryTree ENDP

;-----------------------------------------------------------------------------
; FileCopy - Copy a file
;-----------------------------------------------------------------------------
FileCopy PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; RCX = pSrc, RDX = pDst, R8D = bFailIfExists
    call CopyFileW
    
    add rsp, SHADOW_SPACE
    ret
FileCopy ENDP

;-----------------------------------------------------------------------------
; FileMove - Move/rename a file
;-----------------------------------------------------------------------------
FileMove PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    call MoveFileW
    
    add rsp, SHADOW_SPACE
    ret
FileMove ENDP

;-----------------------------------------------------------------------------
; FileDelete - Delete a file
;-----------------------------------------------------------------------------
FileDelete PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    call DeleteFileW
    
    add rsp, SHADOW_SPACE
    ret
FileDelete ENDP

;-----------------------------------------------------------------------------
; DirectoryDelete - Delete an empty directory
;-----------------------------------------------------------------------------
DirectoryDelete PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    call RemoveDirectoryW
    
    add rsp, SHADOW_SPACE
    ret
DirectoryDelete ENDP

;-----------------------------------------------------------------------------
; FileGetSize - Get file size
;-----------------------------------------------------------------------------
FileGetSize PROC FRAME
    LOCAL hFile:QWORD
    LOCAL dwSizeHigh:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 56
    .allocstack 56
    .endprolog
    
    mov rdi, rdx                        ; pSize
    
    ; Open file
    mov rdx, GENERIC_READ
    mov r8d, FILE_SHARE_READ
    xor r9d, r9d                        ; lpSecurityAttributes
    mov DWORD PTR [rsp + 32], OPEN_EXISTING
    mov DWORD PTR [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov QWORD PTR [rsp + 48], 0         ; hTemplateFile
    call CreateFileW
    cmp rax, INVALID_HANDLE_VALUE
    je failed
    mov hFile, rax
    
    ; Get size
    mov rcx, rax
    lea rdx, dwSizeHigh
    call GetFileSize
    cmp eax, INVALID_FILE_SIZE
    je close_failed
    
    ; Combine low and high parts
    mov ecx, dwSizeHigh
    shl rcx, 32
    or rax, rcx
    mov [rdi], rax
    mov ebx, 1                          ; Success
    jmp close_file
    
close_failed:
    xor ebx, ebx
    
close_file:
    mov rcx, hFile
    call CloseHandle
    mov eax, ebx
    jmp done
    
failed:
    xor eax, eax
    
done:
    add rsp, 56
    pop rdi
    pop rbx
    ret
FileGetSize ENDP

;-----------------------------------------------------------------------------
; ReadFileToBuffer - Read entire file
;-----------------------------------------------------------------------------
ReadFileToBuffer PROC FRAME
    LOCAL hFile:QWORD
    LOCAL qwSize:QWORD
    LOCAL pBuffer:QWORD
    LOCAL dwBytesRead:DWORD
    LOCAL dwSizeHigh:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 80
    .allocstack 80
    .endprolog
    
    mov rdi, rdx                        ; ppBuffer
    mov rsi, r8                         ; pSize
    
    ; Open file
    mov rdx, GENERIC_READ
    mov r8d, FILE_SHARE_READ
    xor r9d, r9d
    mov DWORD PTR [rsp + 32], OPEN_EXISTING
    mov DWORD PTR [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov QWORD PTR [rsp + 48], 0
    call CreateFileW
    cmp rax, INVALID_HANDLE_VALUE
    je failed
    mov hFile, rax
    
    ; Get size
    mov rcx, rax
    lea rdx, dwSizeHigh
    call GetFileSize
    cmp eax, INVALID_FILE_SIZE
    je close_failed
    
    mov ecx, dwSizeHigh
    shl rcx, 32
    or rax, rcx
    mov qwSize, rax
    mov [rsi], rax
    
    ; Allocate buffer
    mov rcx, rax
    inc rcx                             ; Extra byte for safety
    call Mem_Alloc
    test rax, rax
    jz close_failed
    mov pBuffer, rax
    mov [rdi], rax
    
    ; Read file
    mov rcx, hFile
    mov rdx, pBuffer
    mov r8d, DWORD PTR qwSize           ; Assuming < 4GB
    lea r9, dwBytesRead
    mov QWORD PTR [rsp + 32], 0         ; lpOverlapped
    call ReadFile
    test eax, eax
    jz free_and_fail
    
    mov ebx, 1
    jmp close_file
    
free_and_fail:
    mov rcx, pBuffer
    call Mem_Free
    mov QWORD PTR [rdi], 0
    
close_failed:
    xor ebx, ebx
    
close_file:
    mov rcx, hFile
    call CloseHandle
    mov eax, ebx
    jmp done
    
failed:
    xor eax, eax
    
done:
    add rsp, 80
    pop rsi
    pop rdi
    pop rbx
    ret
ReadFileToBuffer ENDP

;-----------------------------------------------------------------------------
; WriteBufferToFile - Write buffer to file
;-----------------------------------------------------------------------------
WriteBufferToFile PROC FRAME
    LOCAL hFile:QWORD
    LOCAL dwBytesWritten:DWORD
    
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 64
    .allocstack 64
    .endprolog
    
    mov rdi, rdx                        ; pBuffer
    mov rsi, r8                         ; cbBuffer
    
    ; Create file
    mov rdx, GENERIC_WRITE
    xor r8d, r8d                        ; No sharing
    xor r9d, r9d
    mov DWORD PTR [rsp + 32], CREATE_ALWAYS
    mov DWORD PTR [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov QWORD PTR [rsp + 48], 0
    call CreateFileW
    cmp rax, INVALID_HANDLE_VALUE
    je failed
    mov hFile, rax
    
    ; Write data
    mov rcx, rax
    mov rdx, rdi
    mov r8, rsi
    lea r9, dwBytesWritten
    mov QWORD PTR [rsp + 32], 0
    call WriteFile
    test eax, eax
    jz close_failed
    
    mov ebx, 1
    jmp close_file
    
close_failed:
    xor ebx, ebx
    
close_file:
    mov rcx, hFile
    call CloseHandle
    mov eax, ebx
    jmp done
    
failed:
    xor eax, eax
    
done:
    add rsp, 64
    pop rsi
    pop rdi
    pop rbx
    ret
WriteBufferToFile ENDP

;-----------------------------------------------------------------------------
; FileGetAttributes - Get file attributes
;-----------------------------------------------------------------------------
FileGetAttributes PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    call GetFileAttributesW
    
    add rsp, SHADOW_SPACE
    ret
FileGetAttributes ENDP

;-----------------------------------------------------------------------------
; FileSetAttributes - Set file attributes
;-----------------------------------------------------------------------------
FileSetAttributes PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    call SetFileAttributesW
    
    add rsp, SHADOW_SPACE
    ret
FileSetAttributes ENDP

;-----------------------------------------------------------------------------
; GetCurrentDir - Get current directory
;-----------------------------------------------------------------------------
GetCurrentDir PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; Swap parameters: API wants (nBufferLength, lpBuffer)
    xchg rcx, rdx
    call GetCurrentDirectoryW
    
    add rsp, SHADOW_SPACE
    ret
GetCurrentDir ENDP

;-----------------------------------------------------------------------------
; SetCurrentDir - Set current directory
;-----------------------------------------------------------------------------
SetCurrentDir PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    call SetCurrentDirectoryW
    
    add rsp, SHADOW_SPACE
    ret
SetCurrentDir ENDP

;-----------------------------------------------------------------------------
; GetModuleDir - Get directory of current module
;-----------------------------------------------------------------------------
GetModuleDir PROC FRAME
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    mov rdi, rcx                        ; pBuffer
    mov ebx, edx                        ; cchBuffer
    
    ; Get module filename
    xor ecx, ecx                        ; NULL = current module
    mov rdx, rdi
    mov r8d, ebx
    call GetModuleFileNameW
    test eax, eax
    jz failed
    
    ; Find last backslash and truncate
    mov rcx, rdi
find_slash:
    movzx eax, WORD PTR [rcx]
    test ax, ax
    jz truncate
    cmp ax, '\'
    jne next_char
    mov rbx, rcx                        ; Save last slash position
next_char:
    add rcx, 2
    jmp find_slash
    
truncate:
    test rbx, rbx
    jz failed
    mov WORD PTR [rbx], 0               ; Terminate after last slash
    
    mov eax, 1
    jmp done
    
failed:
    xor eax, eax
    
done:
    add rsp, 40
    pop rdi
    pop rbx
    ret
GetModuleDir ENDP

END

