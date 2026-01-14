;-----------------------------------------------------------------------------
; ColorPick - Screen Color Picker Utility
;-----------------------------------------------------------------------------
; A practical GUI utility to pick colors from anywhere on screen
; Features:
;   - System tray icon
;   - Global hotkey (Ctrl+Shift+C) to activate picker
;   - Click anywhere to capture color
;   - Copies hex color to clipboard
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
EXTERNDEF GetModuleHandleW:PROC
EXTERNDEF RegisterClassExW:PROC
EXTERNDEF CreateWindowExW:PROC
EXTERNDEF ShowWindow:PROC
EXTERNDEF GetMessageW:PROC
EXTERNDEF TranslateMessage:PROC
EXTERNDEF DispatchMessageW:PROC
EXTERNDEF PostQuitMessage:PROC
EXTERNDEF DefWindowProcW:PROC
EXTERNDEF LoadCursorW:PROC
EXTERNDEF LoadIconW:PROC
EXTERNDEF ExitProcess:PROC
EXTERNDEF RegisterHotKey:PROC
EXTERNDEF UnregisterHotKey:PROC
EXTERNDEF SetCapture:PROC
EXTERNDEF ReleaseCapture:PROC
EXTERNDEF GetCursorPos:PROC
EXTERNDEF GetDC:PROC
EXTERNDEF ReleaseDC:PROC
EXTERNDEF GetPixel:PROC
EXTERNDEF OpenClipboard:PROC
EXTERNDEF CloseClipboard:PROC
EXTERNDEF EmptyClipboard:PROC
EXTERNDEF SetClipboardData:PROC
EXTERNDEF GlobalAlloc:PROC
EXTERNDEF GlobalLock:PROC
EXTERNDEF GlobalUnlock:PROC
EXTERNDEF Shell_NotifyIconW:PROC
EXTERNDEF CreatePopupMenu:PROC
EXTERNDEF AppendMenuW:PROC
EXTERNDEF TrackPopupMenu:PROC
EXTERNDEF DestroyMenu:PROC
EXTERNDEF SetForegroundWindow:PROC
EXTERNDEF PostMessageW:PROC
EXTERNDEF GetWindowRect:PROC
EXTERNDEF SetWindowPos:PROC
EXTERNDEF SetTimer:PROC
EXTERNDEF KillTimer:PROC
EXTERNDEF InvalidateRect:PROC
EXTERNDEF BeginPaint:PROC
EXTERNDEF EndPaint:PROC
EXTERNDEF CreateSolidBrush:PROC
EXTERNDEF FillRect:PROC
EXTERNDEF DeleteObject:PROC
EXTERNDEF SetBkMode:PROC
EXTERNDEF SetTextColor:PROC
EXTERNDEF TextOutA:PROC
EXTERNDEF wsprintfA:PROC

;-----------------------------------------------------------------------------
; Window Messages
;-----------------------------------------------------------------------------
WM_CREATE           EQU 1
WM_DESTROY          EQU 2
WM_PAINT            EQU 0Fh
WM_CLOSE            EQU 10h
WM_HOTKEY           EQU 312h
WM_LBUTTONDOWN      EQU 201h
WM_RBUTTONDOWN      EQU 204h
WM_MOUSEMOVE        EQU 200h
WM_TIMER            EQU 113h
WM_USER             EQU 400h
WM_TRAYICON         EQU WM_USER + 1
WM_COMMAND          EQU 111h

;-----------------------------------------------------------------------------
; Window Styles
;-----------------------------------------------------------------------------
WS_POPUP            EQU 80000000h
WS_VISIBLE          EQU 10000000h
WS_EX_TOPMOST       EQU 8
WS_EX_TOOLWINDOW    EQU 80h

;-----------------------------------------------------------------------------
; Hotkey modifiers
;-----------------------------------------------------------------------------
MOD_CONTROL         EQU 2
MOD_SHIFT           EQU 4
MOD_NOREPEAT        EQU 4000h

;-----------------------------------------------------------------------------
; Other constants
;-----------------------------------------------------------------------------
HOTKEY_ID           EQU 1
TIMER_ID            EQU 1
TIMER_INTERVAL      EQU 50

CF_TEXT             EQU 1
GMEM_MOVEABLE       EQU 2
GMEM_ZEROINIT       EQU 40h

NIM_ADD             EQU 0
NIM_DELETE          EQU 2
NIF_ICON            EQU 2
NIF_MESSAGE         EQU 1
NIF_TIP             EQU 4

IDI_APPLICATION     EQU 32512
IDC_CROSS           EQU 32515

TPM_RIGHTALIGN      EQU 8
TPM_BOTTOMALIGN     EQU 20h

HWND_TOPMOST        EQU -1
SWP_NOMOVE          EQU 2
SWP_NOSIZE          EQU 1

SW_HIDE             EQU 0
SW_SHOW             EQU 5

TRANSPARENT         EQU 1

ID_EXIT             EQU 1001
ID_ABOUT            EQU 1002

;-----------------------------------------------------------------------------
; Structures
;-----------------------------------------------------------------------------
WNDCLASSEXW STRUCT
    cbSize          DWORD ?
    style           DWORD ?
    lpfnWndProc     QWORD ?
    cbClsExtra      DWORD ?
    cbWndExtra      DWORD ?
    hInstance       QWORD ?
    hIcon           QWORD ?
    hCursor         QWORD ?
    hbrBackground   QWORD ?
    lpszMenuName    QWORD ?
    lpszClassName   QWORD ?
    hIconSm         QWORD ?
WNDCLASSEXW ENDS

POINT STRUCT
    x   DWORD ?
    y   DWORD ?
POINT ENDS

MSG STRUCT
    hwnd        QWORD ?
    message     DWORD ?
    padding1    DWORD ?
    wParam      QWORD ?
    lParam      QWORD ?
    time        DWORD ?
    pt          POINT <>
    padding2    DWORD ?
MSG ENDS

RECT STRUCT
    left    DWORD ?
    top     DWORD ?
    right   DWORD ?
    bottom  DWORD ?
RECT ENDS

NOTIFYICONDATAW STRUCT
    cbSize          DWORD ?
    padding1        DWORD ?
    hWnd            QWORD ?
    uID             DWORD ?
    uFlags          DWORD ?
    uCallbackMessage DWORD ?
    padding2        DWORD ?
    hIcon           QWORD ?
    szTip           WORD 128 DUP(?)
NOTIFYICONDATAW ENDS

PAINTSTRUCT STRUCT
    hdc         QWORD ?
    fErase      DWORD ?
    rcPaint     RECT <>
    fRestore    DWORD ?
    fIncUpdate  DWORD ?
    rgbReserved DB 32 DUP(?)
    padding     DWORD ?
PAINTSTRUCT ENDS

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

WSTR wszClassName, "ColorPickClass"
WSTR wszWindowTitle, "ColorPick"
WSTR wszTip, "ColorPick - Ctrl+Shift+C to pick"
WSTR wszExit, "Exit"
WSTR wszAbout, "About"

szHexFormat     DB "#%02X%02X%02X", 0
szClipFormat    DB "#000000", 0, 0

hInstance       QWORD 0
hMainWnd        QWORD 0
hIcon           QWORD 0
bPicking        DWORD 0
dwCurrentColor  DWORD 0

nid             NOTIFYICONDATAW <>

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; CopyColorToClipboard - Copy hex color string to clipboard
;-----------------------------------------------------------------------------
CopyColorToClipboard PROC FRAME
    LOCAL hMem:QWORD
    LOCAL pMem:QWORD
    LOCAL r:DWORD
    LOCAL g:DWORD
    LOCAL b:DWORD
    
    push rbp
    .pushreg rbp
    sub rsp, 96
    .allocstack 96
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    ; Extract RGB from COLORREF (0x00BBGGRR)
    mov eax, dwCurrentColor
    movzx ecx, al                       ; R
    mov r, ecx
    shr eax, 8
    movzx ecx, al                       ; G
    mov g, ecx
    shr eax, 8
    movzx ecx, al                       ; B
    mov b, ecx
    
    ; Format string
    lea rcx, szClipFormat
    lea rdx, szHexFormat
    mov r8d, r
    mov r9d, g
    mov eax, b
    mov [rsp + 32], rax
    call wsprintfA
    
    ; Allocate global memory
    mov ecx, GMEM_MOVEABLE OR GMEM_ZEROINIT
    mov edx, 16
    call GlobalAlloc
    test rax, rax
    jz done
    mov hMem, rax
    
    ; Lock and copy
    mov rcx, rax
    call GlobalLock
    test rax, rax
    jz done
    mov pMem, rax
    
    ; Copy string
    lea rsi, szClipFormat
    mov rdi, rax
    mov ecx, 8
    rep movsb
    
    ; Unlock
    mov rcx, hMem
    call GlobalUnlock
    
    ; Open clipboard
    mov rcx, hMainWnd
    call OpenClipboard
    test eax, eax
    jz done
    
    ; Empty and set
    call EmptyClipboard
    
    mov ecx, CF_TEXT
    mov rdx, hMem
    call SetClipboardData
    
    call CloseClipboard
    
done:
    add rsp, 96
    pop rbp
    ret
CopyColorToClipboard ENDP

;-----------------------------------------------------------------------------
; ShowTrayMenu - Show context menu for tray icon
;-----------------------------------------------------------------------------
ShowTrayMenu PROC FRAME
    LOCAL hMenu:QWORD
    LOCAL pt:POINT
    
    push rbp
    .pushreg rbp
    sub rsp, 80
    .allocstack 80
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    ; Create popup menu
    call CreatePopupMenu
    test rax, rax
    jz done
    mov hMenu, rax
    
    ; Add items
    mov rcx, rax
    xor edx, edx                        ; MF_STRING = 0
    mov r8d, ID_ABOUT
    lea r9, wszAbout
    call AppendMenuW
    
    mov rcx, hMenu
    xor edx, edx
    mov r8d, ID_EXIT
    lea r9, wszExit
    call AppendMenuW
    
    ; Get cursor position
    lea rcx, pt
    call GetCursorPos
    
    ; Bring window to foreground (required for menu to work properly)
    mov rcx, hMainWnd
    call SetForegroundWindow
    
    ; Show menu
    mov rcx, hMenu
    mov edx, TPM_RIGHTALIGN OR TPM_BOTTOMALIGN
    mov r8d, pt.x
    mov r9d, pt.y
    mov QWORD PTR [rsp + 32], 0         ; nReserved
    mov rax, hMainWnd
    mov [rsp + 40], rax                 ; hWnd
    mov QWORD PTR [rsp + 48], 0         ; lpRect
    call TrackPopupMenu
    
    ; Destroy menu
    mov rcx, hMenu
    call DestroyMenu
    
done:
    add rsp, 80
    pop rbp
    ret
ShowTrayMenu ENDP

;-----------------------------------------------------------------------------
; StartColorPick - Enter color picking mode
;-----------------------------------------------------------------------------
StartColorPick PROC FRAME
    push rbp
    .pushreg rbp
    sub rsp, 48
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov bPicking, 1
    
    ; Show preview window
    mov rcx, hMainWnd
    mov edx, SW_SHOW
    call ShowWindow
    
    ; Capture mouse
    mov rcx, hMainWnd
    call SetCapture
    
    ; Start timer for color preview updates
    mov rcx, hMainWnd
    mov edx, TIMER_ID
    mov r8d, TIMER_INTERVAL
    xor r9d, r9d
    call SetTimer
    
    add rsp, 48
    pop rbp
    ret
StartColorPick ENDP

;-----------------------------------------------------------------------------
; StopColorPick - Exit color picking mode
;-----------------------------------------------------------------------------
StopColorPick PROC FRAME
    push rbp
    .pushreg rbp
    sub rsp, 48
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov bPicking, 0
    
    ; Release capture
    call ReleaseCapture
    
    ; Kill timer
    mov rcx, hMainWnd
    mov edx, TIMER_ID
    call KillTimer
    
    ; Hide window
    mov rcx, hMainWnd
    mov edx, SW_HIDE
    call ShowWindow
    
    add rsp, 48
    pop rbp
    ret
StopColorPick ENDP

;-----------------------------------------------------------------------------
; UpdateColorPreview - Get color under cursor and update preview
;-----------------------------------------------------------------------------
UpdateColorPreview PROC FRAME
    LOCAL pt:POINT
    LOCAL hDC:QWORD
    
    push rbp
    .pushreg rbp
    sub rsp, 80
    .allocstack 80
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    ; Get cursor position
    lea rcx, pt
    call GetCursorPos
    
    ; Get DC for entire screen
    xor ecx, ecx
    call GetDC
    test rax, rax
    jz done
    mov hDC, rax
    
    ; Get pixel color
    mov rcx, rax
    mov edx, pt.x
    mov r8d, pt.y
    call GetPixel
    mov dwCurrentColor, eax
    
    ; Release DC
    xor ecx, ecx
    mov rdx, hDC
    call ReleaseDC
    
    ; Move preview window near cursor
    mov rcx, hMainWnd
    mov rdx, HWND_TOPMOST
    mov r8d, pt.x
    add r8d, 20
    mov r9d, pt.y
    add r9d, 20
    mov DWORD PTR [rsp + 32], 100       ; Width
    mov DWORD PTR [rsp + 40], 60        ; Height
    mov DWORD PTR [rsp + 48], 0         ; Flags
    call SetWindowPos
    
    ; Invalidate to trigger repaint
    mov rcx, hMainWnd
    xor edx, edx
    xor r8d, r8d
    call InvalidateRect
    
done:
    add rsp, 80
    pop rbp
    ret
UpdateColorPreview ENDP

;-----------------------------------------------------------------------------
; WndProc - Window Procedure
;-----------------------------------------------------------------------------
WndProc PROC FRAME
    LOCAL ps:PAINTSTRUCT
    LOCAL rc:RECT
    LOCAL hBrush:QWORD
    LOCAL szColor[16]:BYTE
    
    push rbp
    .pushreg rbp
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 200
    .allocstack 200
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov rbx, rcx                        ; hWnd
    mov esi, edx                        ; uMsg
    mov rdi, r8                         ; wParam
    ; r9 = lParam
    
    cmp esi, WM_DESTROY
    je handle_destroy
    
    cmp esi, WM_HOTKEY
    je handle_hotkey
    
    cmp esi, WM_LBUTTONDOWN
    je handle_lbutton
    
    cmp esi, WM_RBUTTONDOWN
    je handle_rbutton
    
    cmp esi, WM_TIMER
    je handle_timer
    
    cmp esi, WM_PAINT
    je handle_paint
    
    cmp esi, WM_TRAYICON
    je handle_tray
    
    cmp esi, WM_COMMAND
    je handle_command
    
    ; Default processing
    mov rcx, rbx
    mov edx, esi
    mov r8, rdi
    ; r9 already set
    call DefWindowProcW
    jmp done
    
handle_destroy:
    ; Remove tray icon
    lea rcx, nid
    mov DWORD PTR [rcx].NOTIFYICONDATAW.cbSize, SIZEOF NOTIFYICONDATAW
    mov rax, hMainWnd
    mov [rcx].NOTIFYICONDATAW.hWnd, rax
    mov DWORD PTR [rcx].NOTIFYICONDATAW.uID, 1
    mov edx, NIM_DELETE
    call Shell_NotifyIconW
    
    ; Unregister hotkey
    mov rcx, hMainWnd
    mov edx, HOTKEY_ID
    call UnregisterHotKey
    
    xor ecx, ecx
    call PostQuitMessage
    xor eax, eax
    jmp done
    
handle_hotkey:
    cmp edi, HOTKEY_ID
    jne default_proc
    call StartColorPick
    xor eax, eax
    jmp done
    
handle_lbutton:
    cmp bPicking, 0
    je default_proc
    
    ; Copy color to clipboard
    call CopyColorToClipboard
    
    ; Stop picking
    call StopColorPick
    xor eax, eax
    jmp done
    
handle_rbutton:
    cmp bPicking, 0
    je default_proc
    
    ; Cancel picking
    call StopColorPick
    xor eax, eax
    jmp done
    
handle_timer:
    cmp bPicking, 0
    je default_proc
    call UpdateColorPreview
    xor eax, eax
    jmp done
    
handle_paint:
    mov rcx, rbx
    lea rdx, ps
    call BeginPaint
    test rax, rax
    jz paint_done
    
    push rax                            ; Save hDC
    
    ; Create brush with current color
    mov ecx, dwCurrentColor
    call CreateSolidBrush
    mov hBrush, rax
    
    ; Fill color preview area
    mov rc.left, 5
    mov rc.top, 5
    mov rc.right, 95
    mov rc.bottom, 35
    
    pop rcx                             ; hDC
    push rcx
    lea rdx, rc
    mov r8, hBrush
    call FillRect
    
    ; Delete brush
    mov rcx, hBrush
    call DeleteObject
    
    ; Draw hex string
    pop rcx                             ; hDC
    push rcx
    
    mov edx, TRANSPARENT
    call SetBkMode
    
    pop rcx
    push rcx
    mov edx, 0                          ; Black text
    call SetTextColor
    
    ; Format color string
    mov eax, dwCurrentColor
    movzx ecx, al
    push rcx                            ; R
    shr eax, 8
    movzx ecx, al
    push rcx                            ; G
    shr eax, 8
    movzx ecx, al
    push rcx                            ; B
    
    lea rcx, szColor
    lea rdx, szHexFormat
    pop r8                              ; Actually need to reorganize
    pop r9
    pop rax
    
    ; Simpler approach - just use wsprintfA
    lea rcx, szColor
    lea rdx, szHexFormat
    mov eax, dwCurrentColor
    movzx r8d, al                       ; R
    shr eax, 8
    movzx r9d, al                       ; G
    shr eax, 8
    movzx eax, al                       ; B
    mov [rsp + 32], rax
    call wsprintfA
    
    pop rcx                             ; hDC
    mov edx, 10                         ; x
    mov r8d, 40                         ; y
    lea r9, szColor
    mov DWORD PTR [rsp + 32], 7         ; String length
    call TextOutA
    
    mov rcx, rbx
    lea rdx, ps
    call EndPaint
    
paint_done:
    xor eax, eax
    jmp done
    
handle_tray:
    ; r9 = lParam contains mouse message
    mov eax, r9d
    cmp eax, WM_RBUTTONDOWN
    jne @F
    call ShowTrayMenu
@@:
    cmp eax, WM_LBUTTONDOWN
    jne @F
    call StartColorPick
@@:
    xor eax, eax
    jmp done
    
handle_command:
    mov eax, edi                        ; wParam
    and eax, 0FFFFh                     ; LOWORD = menu item ID
    
    cmp eax, ID_EXIT
    jne @F
    mov rcx, rbx
    xor edx, edx
    mov r8d, WM_DESTROY
    xor r9d, r9d
    call PostMessageW
    jmp @command_done
@@:
    ; ID_ABOUT - could show about dialog
    
@command_done:
    xor eax, eax
    jmp done
    
default_proc:
    mov rcx, rbx
    mov edx, esi
    mov r8, rdi
    call DefWindowProcW
    
done:
    add rsp, 200
    pop rsi
    pop rdi
    pop rbx
    pop rbp
    ret
WndProc ENDP

;-----------------------------------------------------------------------------
; WinMain - Entry Point
;-----------------------------------------------------------------------------
WinMain PROC FRAME
    LOCAL wc:WNDCLASSEXW
    LOCAL msg:MSG
    
    push rbp
    .pushreg rbp
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 280
    .allocstack 280
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    ; Get module handle
    xor ecx, ecx
    call GetModuleHandleW
    mov hInstance, rax
    mov rsi, rax
    
    ; Load icon
    xor ecx, ecx
    mov edx, IDI_APPLICATION
    call LoadIconW
    mov hIcon, rax
    mov rdi, rax
    
    ; Load crosshair cursor
    xor ecx, ecx
    mov edx, IDC_CROSS
    call LoadCursorW
    mov rbx, rax
    
    ; Register window class
    lea rax, wc
    mov DWORD PTR [rax].WNDCLASSEXW.cbSize, SIZEOF WNDCLASSEXW
    mov DWORD PTR [rax].WNDCLASSEXW.style, 0
    lea rcx, WndProc
    mov [rax].WNDCLASSEXW.lpfnWndProc, rcx
    mov DWORD PTR [rax].WNDCLASSEXW.cbClsExtra, 0
    mov DWORD PTR [rax].WNDCLASSEXW.cbWndExtra, 0
    mov [rax].WNDCLASSEXW.hInstance, rsi
    mov [rax].WNDCLASSEXW.hIcon, rdi
    mov [rax].WNDCLASSEXW.hCursor, rbx
    mov QWORD PTR [rax].WNDCLASSEXW.hbrBackground, 16    ; COLOR_BTNFACE + 1
    mov QWORD PTR [rax].WNDCLASSEXW.lpszMenuName, 0
    lea rcx, wszClassName
    mov [rax].WNDCLASSEXW.lpszClassName, rcx
    mov [rax].WNDCLASSEXW.hIconSm, rdi
    
    lea rcx, wc
    call RegisterClassExW
    test ax, ax
    jz exit_fail
    
    ; Create hidden popup window for preview
    mov ecx, WS_EX_TOPMOST OR WS_EX_TOOLWINDOW
    lea rdx, wszClassName
    lea r8, wszWindowTitle
    mov r9d, WS_POPUP
    mov DWORD PTR [rsp + 32], 0         ; x
    mov DWORD PTR [rsp + 40], 0         ; y
    mov DWORD PTR [rsp + 48], 100       ; width
    mov DWORD PTR [rsp + 56], 60        ; height
    mov QWORD PTR [rsp + 64], 0         ; parent
    mov QWORD PTR [rsp + 72], 0         ; menu
    mov [rsp + 80], rsi                 ; hInstance
    mov QWORD PTR [rsp + 88], 0         ; lpParam
    call CreateWindowExW
    test rax, rax
    jz exit_fail
    mov hMainWnd, rax
    
    ; Register global hotkey (Ctrl+Shift+C)
    mov rcx, rax
    mov edx, HOTKEY_ID
    mov r8d, MOD_CONTROL OR MOD_SHIFT OR MOD_NOREPEAT
    mov r9d, 43h                        ; 'C' key
    call RegisterHotKey
    
    ; Create system tray icon
    lea rcx, nid
    mov DWORD PTR [rcx].NOTIFYICONDATAW.cbSize, SIZEOF NOTIFYICONDATAW
    mov rax, hMainWnd
    mov [rcx].NOTIFYICONDATAW.hWnd, rax
    mov DWORD PTR [rcx].NOTIFYICONDATAW.uID, 1
    mov DWORD PTR [rcx].NOTIFYICONDATAW.uFlags, NIF_ICON OR NIF_MESSAGE OR NIF_TIP
    mov DWORD PTR [rcx].NOTIFYICONDATAW.uCallbackMessage, WM_TRAYICON
    mov rax, hIcon
    mov [rcx].NOTIFYICONDATAW.hIcon, rax
    
    ; Copy tooltip
    push rcx
    lea rdi, [rcx].NOTIFYICONDATAW.szTip
    lea rsi, wszTip
    mov ecx, 64
    rep movsw
    pop rcx
    
    mov edx, NIM_ADD
    call Shell_NotifyIconW
    
    ; Message loop
msg_loop:
    lea rcx, msg
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call GetMessageW
    test eax, eax
    jz exit_ok
    cmp eax, -1
    je exit_fail
    
    lea rcx, msg
    call TranslateMessage
    
    lea rcx, msg
    call DispatchMessageW
    
    jmp msg_loop
    
exit_ok:
    xor eax, eax
    jmp exit
    
exit_fail:
    mov eax, 1
    
exit:
    mov ecx, eax
    call ExitProcess
    
    add rsp, 280
    pop rsi
    pop rdi
    pop rbx
    pop rbp
    ret
WinMain ENDP

END

