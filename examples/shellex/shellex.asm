;-----------------------------------------------------------------------------
; ShellEx - Copy Path Shell Extension
;-----------------------------------------------------------------------------
; A practical shell extension DLL that adds "Copy Path" to context menus
; Features:
;   - "Copy Path" - copies full path without quotes
;   - "Copy Unix Path" - copies with forward slashes for WSL
;   - Works without Shift+Right-click
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

;-----------------------------------------------------------------------------
; Includes
;-----------------------------------------------------------------------------
INCLUDE \masm64-framework\core\abi64.inc
INCLUDE \masm64-framework\core\stack64.inc
INCLUDE \masm64-framework\core\macros64.inc

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF DisableThreadLibraryCalls:PROC
EXTERNDEF OpenClipboard:PROC
EXTERNDEF CloseClipboard:PROC
EXTERNDEF EmptyClipboard:PROC
EXTERNDEF SetClipboardData:PROC
EXTERNDEF GlobalAlloc:PROC
EXTERNDEF GlobalLock:PROC
EXTERNDEF GlobalUnlock:PROC
EXTERNDEF GlobalFree:PROC
EXTERNDEF lstrcpyW:PROC
EXTERNDEF lstrlenW:PROC
EXTERNDEF DragQueryFileW:PROC
EXTERNDEF SHGetPathFromIDListW:PROC

;-----------------------------------------------------------------------------
; DLL Entry Reasons
;-----------------------------------------------------------------------------
DLL_PROCESS_ATTACH  EQU 1
DLL_PROCESS_DETACH  EQU 0

;-----------------------------------------------------------------------------
; COM Interface IDs (simplified - would normally use full GUID structures)
;-----------------------------------------------------------------------------
; IUnknown methods: QueryInterface, AddRef, Release
; IShellExtInit methods: Initialize
; IContextMenu methods: QueryContextMenu, InvokeCommand, GetCommandString

;-----------------------------------------------------------------------------
; Menu item IDs
;-----------------------------------------------------------------------------
IDM_COPYPATH        EQU 0
IDM_COPYUNIXPATH    EQU 1
IDM_COPYFOLDER      EQU 2

;-----------------------------------------------------------------------------
; Constants
;-----------------------------------------------------------------------------
CF_UNICODETEXT      EQU 13
GMEM_MOVEABLE       EQU 2
GMEM_ZEROINIT       EQU 40h

MAX_PATH            EQU 260

MF_STRING           EQU 0
MF_SEPARATOR        EQU 800h

S_OK                EQU 0
E_NOINTERFACE       EQU 80004002h
E_FAIL              EQU 80004005h
E_INVALIDARG        EQU 80070057h

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

g_hModule           QWORD 0
g_cRef              DWORD 0                 ; Global reference count
g_cLock             DWORD 0                 ; Server lock count

; Stored file path from Initialize
g_szFilePath        WORD MAX_PATH DUP(0)

; Menu strings (wide strings defined manually)
wszCopyPath     DW 'C','o','p','y',' ','P','a','t','h', 0
wszCopyUnixPath DW 'C','o','p','y',' ','U','n','i','x',' ','P','a','t','h', 0
wszCopyFolder   DW 'C','o','p','y',' ','F','o','l','d','e','r',' ','P','a','t','h', 0

; Help strings
szHelpCopyPath      DB "Copy full file path to clipboard", 0
szHelpUnixPath      DB "Copy path with forward slashes", 0

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; CopyPathToClipboard - Copy path string to clipboard
;-----------------------------------------------------------------------------
; RCX = wide string path, EDX = convert to unix (1) or not (0)
;-----------------------------------------------------------------------------
CopyPathToClipboard PROC FRAME
    LOCAL hMem:QWORD
    LOCAL pMem:QWORD
    LOCAL pathLen:DWORD
    LOCAL bUnix:DWORD
    LOCAL pPath:QWORD
    
    push rbp
    .pushreg rbp
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 104
    .allocstack 104
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov pPath, rcx
    mov bUnix, edx
    
    ; Get string length
    call lstrlenW
    mov pathLen, eax
    test eax, eax
    jz fail
    
    ; Allocate global memory (length + 1) * 2 for Unicode
    mov ecx, GMEM_MOVEABLE OR GMEM_ZEROINIT
    mov eax, pathLen
    inc eax
    shl eax, 1
    mov edx, eax
    call GlobalAlloc
    test rax, rax
    jz fail
    mov hMem, rax
    
    ; Lock memory
    mov rcx, rax
    call GlobalLock
    test rax, rax
    jz free_mem
    mov pMem, rax
    
    ; Copy string
    mov rcx, rax
    mov rdx, pPath
    call lstrcpyW
    
    ; Convert to Unix path if requested
    cmp bUnix, 0
    je skip_convert
    
    mov rdi, pMem
convert_loop:
    mov ax, [rdi]
    test ax, ax
    jz skip_convert
    cmp ax, '\'
    jne @F
    mov WORD PTR [rdi], '/'
@@:
    add rdi, 2
    jmp convert_loop
    
skip_convert:
    ; Unlock memory
    mov rcx, hMem
    call GlobalUnlock
    
    ; Open clipboard
    xor ecx, ecx
    call OpenClipboard
    test eax, eax
    jz free_mem
    
    ; Empty and set data
    call EmptyClipboard
    
    mov ecx, CF_UNICODETEXT
    mov rdx, hMem
    call SetClipboardData
    
    call CloseClipboard
    
    mov eax, 1
    jmp done
    
free_mem:
    mov rcx, hMem
    call GlobalFree
    
fail:
    xor eax, eax
    
done:
    add rsp, 104
    pop rsi
    pop rdi
    pop rbx
    pop rbp
    ret
CopyPathToClipboard ENDP

;-----------------------------------------------------------------------------
; GetFolderPath - Extract folder from full path
;-----------------------------------------------------------------------------
; RCX = source path, RDX = dest buffer
;-----------------------------------------------------------------------------
GetFolderPath PROC FRAME
    push rbp
    .pushreg rbp
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 48
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov rsi, rcx                        ; Source
    mov rdi, rdx                        ; Dest
    
    ; Copy entire string first
    mov rcx, rdx
    mov rdx, rsi
    call lstrcpyW
    
    ; Find last backslash
    mov rsi, rdi
    xor rax, rax                        ; Last backslash position
    
find_loop:
    mov cx, [rsi]
    test cx, cx
    jz found_end
    cmp cx, '\'
    jne @F
    mov rax, rsi
@@:
    add rsi, 2
    jmp find_loop
    
found_end:
    ; Terminate at last backslash
    test rax, rax
    jz done
    mov WORD PTR [rax], 0
    
done:
    add rsp, 48
    pop rsi
    pop rdi
    pop rbp
    ret
GetFolderPath ENDP

;-----------------------------------------------------------------------------
; DllMain - DLL Entry Point
;-----------------------------------------------------------------------------
DllMain PROC FRAME
    push rbp
    .pushreg rbp
    sub rsp, 48
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    cmp edx, DLL_PROCESS_ATTACH
    jne check_detach
    
    ; Save module handle
    mov g_hModule, rcx
    
    ; Disable thread notifications
    call DisableThreadLibraryCalls
    jmp success
    
check_detach:
    cmp edx, DLL_PROCESS_DETACH
    jne success
    ; Cleanup if needed
    
success:
    mov eax, 1
    
    add rsp, 48
    pop rbp
    ret
DllMain ENDP

;-----------------------------------------------------------------------------
; DllGetClassObject - COM class factory entry point
;-----------------------------------------------------------------------------
; This would return IClassFactory for creating shell extension instances
; Simplified implementation - full COM requires vtable setup
;-----------------------------------------------------------------------------
DllGetClassObject PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; In a full implementation, this would:
    ; 1. Check rclsid matches our CLSID
    ; 2. Check riid is IClassFactory
    ; 3. Return pointer to our IClassFactory implementation
    
    ; For this example, return E_NOINTERFACE
    mov eax, E_NOINTERFACE
    
    add rsp, SHADOW_SPACE
    ret
DllGetClassObject ENDP

;-----------------------------------------------------------------------------
; DllCanUnloadNow - Check if DLL can be unloaded
;-----------------------------------------------------------------------------
DllCanUnloadNow PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; Can unload if no references and no locks
    mov eax, g_cRef
    or eax, g_cLock
    jnz still_in_use
    
    ; S_OK = can unload
    xor eax, eax
    jmp done
    
still_in_use:
    ; S_FALSE = still in use
    mov eax, 1
    
done:
    add rsp, SHADOW_SPACE
    ret
DllCanUnloadNow ENDP

;-----------------------------------------------------------------------------
; DllRegisterServer - Register the shell extension
;-----------------------------------------------------------------------------
; Would add registry entries for the extension
;-----------------------------------------------------------------------------
DllRegisterServer PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; Registration would add entries to:
    ; HKCR\CLSID\{our-guid}
    ; HKCR\*\shellex\ContextMenuHandlers\CopyPath
    
    ; Return S_OK
    xor eax, eax
    
    add rsp, SHADOW_SPACE
    ret
DllRegisterServer ENDP

;-----------------------------------------------------------------------------
; DllUnregisterServer - Unregister the shell extension
;-----------------------------------------------------------------------------
DllUnregisterServer PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; Would remove registry entries
    xor eax, eax
    
    add rsp, SHADOW_SPACE
    ret
DllUnregisterServer ENDP

;-----------------------------------------------------------------------------
; TestCopyPath - Test function callable from command line
;-----------------------------------------------------------------------------
; Allows testing the copy functionality without full COM registration
; Usage: rundll32 shellex.dll,TestCopyPath "C:\some\path.txt"
;-----------------------------------------------------------------------------
TestCopyPath PROC FRAME
    push rbp
    .pushreg rbp
    sub rsp, 48
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    ; RCX = hwnd, RDX = hInstance, R8 = lpCmdLine, R9 = nCmdShow
    ; lpCmdLine contains the path to copy
    
    mov rcx, r8                         ; Path string
    xor edx, edx                        ; Not Unix
    call CopyPathToClipboard
    
    add rsp, 48
    pop rbp
    ret
TestCopyPath ENDP

;-----------------------------------------------------------------------------
; TestCopyUnixPath - Test function for Unix path copy
;-----------------------------------------------------------------------------
TestCopyUnixPath PROC FRAME
    push rbp
    .pushreg rbp
    sub rsp, 48
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov rcx, r8                         ; Path string
    mov edx, 1                          ; Convert to Unix
    call CopyPathToClipboard
    
    add rsp, 48
    pop rbp
    ret
TestCopyUnixPath ENDP

END

