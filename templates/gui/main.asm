;-----------------------------------------------------------------------------
; GUI Application Template
;-----------------------------------------------------------------------------
; MASM64 Framework - Win32 GUI Application
;
; To customize: Edit config.inc
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

;-----------------------------------------------------------------------------
; Project Configuration
;-----------------------------------------------------------------------------
INCLUDE config.inc

;-----------------------------------------------------------------------------
; Framework Includes
;-----------------------------------------------------------------------------
INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc

;-----------------------------------------------------------------------------
; External Win32 API
;-----------------------------------------------------------------------------
EXTERNDEF GetModuleHandleW:PROC
EXTERNDEF RegisterClassExW:PROC
EXTERNDEF CreateWindowExW:PROC
EXTERNDEF ShowWindow:PROC
EXTERNDEF UpdateWindow:PROC
EXTERNDEF GetMessageW:PROC
EXTERNDEF TranslateMessage:PROC
EXTERNDEF DispatchMessageW:PROC
EXTERNDEF PostQuitMessage:PROC
EXTERNDEF DefWindowProcW:PROC
EXTERNDEF LoadCursorW:PROC
EXTERNDEF ExitProcess:PROC

;-----------------------------------------------------------------------------
; Window Messages
;-----------------------------------------------------------------------------
WM_DESTROY      EQU 2
WM_CLOSE        EQU 10h
WM_PAINT        EQU 0Fh

;-----------------------------------------------------------------------------
; Window Styles
;-----------------------------------------------------------------------------
WS_OVERLAPPEDWINDOW EQU 0CF0000h
WS_VISIBLE      EQU 10000000h
SW_SHOWDEFAULT  EQU 10
IDC_ARROW       EQU 32512
CS_HREDRAW      EQU 2
CS_VREDRAW      EQU 1
CW_USEDEFAULT   EQU 80000000h

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

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

; Invoke string definitions from config.inc
DEFINE_STRINGS

hInstance   QWORD 0
hMainWnd    QWORD 0

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; WndProc - Window Procedure
;-----------------------------------------------------------------------------
WndProc PROC FRAME
    push rbp
    .pushreg rbp
    sub rsp, 32
    .allocstack 32
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    cmp edx, WM_DESTROY
    je handle_destroy
    
    cmp edx, WM_CLOSE
    je handle_close
    
    call DefWindowProcW
    jmp done
    
handle_close:
    call DefWindowProcW
    jmp done
    
handle_destroy:
    xor ecx, ecx
    call PostQuitMessage
    xor eax, eax
    
done:
    add rsp, 32
    pop rbp
    ret
WndProc ENDP

;-----------------------------------------------------------------------------
; WinMain - Entry Point
;-----------------------------------------------------------------------------
WinMain PROC FRAME
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
    
    ; Get module handle
    xor ecx, ecx
    call GetModuleHandleW
    mov hInstance, rax
    mov rsi, rax
    
    ; Load cursor
    xor ecx, ecx
    mov edx, IDC_ARROW
    call LoadCursorW
    mov rdi, rax
    
    ; Register window class - wc at [rbp+0]
    lea rbx, [rbp+0]
    mov DWORD PTR [rbx].WNDCLASSEXW.cbSize, SIZEOF WNDCLASSEXW
    mov DWORD PTR [rbx].WNDCLASSEXW.style, CS_HREDRAW OR CS_VREDRAW
    lea rax, WndProc
    mov [rbx].WNDCLASSEXW.lpfnWndProc, rax
    mov DWORD PTR [rbx].WNDCLASSEXW.cbClsExtra, 0
    mov DWORD PTR [rbx].WNDCLASSEXW.cbWndExtra, 0
    mov [rbx].WNDCLASSEXW.hInstance, rsi
    mov QWORD PTR [rbx].WNDCLASSEXW.hIcon, 0
    mov [rbx].WNDCLASSEXW.hCursor, rdi
    mov QWORD PTR [rbx].WNDCLASSEXW.hbrBackground, 6
    mov QWORD PTR [rbx].WNDCLASSEXW.lpszMenuName, 0
    lea rax, wszClassName
    mov [rbx].WNDCLASSEXW.lpszClassName, rax
    mov QWORD PTR [rbx].WNDCLASSEXW.hIconSm, 0
    
    mov rcx, rbx
    call RegisterClassExW
    test ax, ax
    jz exit_fail
    
    ; Create window
    xor ecx, ecx
    lea rdx, wszClassName
    lea r8, wszWindowTitle
    mov r9d, WS_OVERLAPPEDWINDOW OR WS_VISIBLE
    mov DWORD PTR [rsp + 32], CW_USEDEFAULT
    mov DWORD PTR [rsp + 40], CW_USEDEFAULT
    mov DWORD PTR [rsp + 48], WINDOW_WIDTH
    mov DWORD PTR [rsp + 56], WINDOW_HEIGHT
    mov QWORD PTR [rsp + 64], 0
    mov QWORD PTR [rsp + 72], 0
    mov [rsp + 80], rsi
    mov QWORD PTR [rsp + 88], 0
    call CreateWindowExW
    test rax, rax
    jz exit_fail
    mov hMainWnd, rax
    
    ; Show window
    mov rcx, rax
    mov edx, SW_SHOWDEFAULT
    call ShowWindow
    
    mov rcx, hMainWnd
    call UpdateWindow
    
    ; Message loop - msg at [rbp+96]
msg_loop:
    lea rcx, [rbp+96]
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call GetMessageW
    test eax, eax
    jz exit_ok
    cmp eax, -1
    je exit_fail
    
    lea rcx, [rbp+96]
    call TranslateMessage
    
    lea rcx, [rbp+96]
    call DispatchMessageW
    
    jmp msg_loop
    
exit_ok:
    lea rax, [rbp+96]
    mov eax, DWORD PTR [rax].MSG.wParam
    jmp exit
    
exit_fail:
    mov eax, 1
    
exit:
    add rsp, 200
    pop rsi
    pop rdi
    pop rbx
    pop rbp
    
    mov ecx, eax
    call ExitProcess
    ret
WinMain ENDP

END
