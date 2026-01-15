;-----------------------------------------------------------------------------
; Kernel Driver Template
;-----------------------------------------------------------------------------
; MASM64 Framework - Windows Kernel Mode Driver
;
; To customize: Edit config.inc
;
; WARNING: Kernel drivers require special signing and testing.
;          Test only in virtual machines with kernel debugging enabled.
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

;-----------------------------------------------------------------------------
; Project Configuration
;-----------------------------------------------------------------------------
INCLUDE config.inc

;-----------------------------------------------------------------------------
; NTSTATUS Codes
;-----------------------------------------------------------------------------
STATUS_SUCCESS              EQU 0
STATUS_UNSUCCESSFUL         EQU 0C0000001h
STATUS_NOT_IMPLEMENTED      EQU 0C0000002h

;-----------------------------------------------------------------------------
; IRP Major Function Codes
;-----------------------------------------------------------------------------
IRP_MJ_CREATE               EQU 0
IRP_MJ_CLOSE                EQU 2
IRP_MJ_DEVICE_CONTROL       EQU 14

;-----------------------------------------------------------------------------
; UNICODE_STRING structure
;-----------------------------------------------------------------------------
UNICODE_STRING STRUCT
    wLength         WORD ?
    MaximumLength   WORD ?
    padding         DWORD ?
    Buffer          QWORD ?
UNICODE_STRING ENDS

;-----------------------------------------------------------------------------
; External Kernel API
;-----------------------------------------------------------------------------
EXTERNDEF DbgPrint:PROC
EXTERNDEF IoCreateDevice:PROC
EXTERNDEF IoDeleteDevice:PROC
EXTERNDEF IoCreateSymbolicLink:PROC
EXTERNDEF IoDeleteSymbolicLink:PROC
EXTERNDEF RtlInitUnicodeString:PROC

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

; Invoke string definitions from config.inc
DEFINE_STRINGS

g_pDeviceObject QWORD 0

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; DriverUnload - Driver unload routine
;-----------------------------------------------------------------------------
DriverUnload PROC FRAME
    push rbp
    .pushreg rbp
    push rbx
    .pushreg rbx
    sub rsp, 56
    .allocstack 56
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov rbx, rcx
    
    ; Delete symbolic link
    lea rcx, [rbp + 0]
    lea rdx, szSymLink
    call RtlInitUnicodeString
    
    lea rcx, [rbp + 0]
    call IoDeleteSymbolicLink
    
    ; Delete device object
    mov rcx, g_pDeviceObject
    test rcx, rcx
    jz no_device
    call IoDeleteDevice
    
no_device:
    lea rcx, szUnloadMsg
    call DbgPrint
    
    add rsp, 56
    pop rbx
    pop rbp
    ret
DriverUnload ENDP

;-----------------------------------------------------------------------------
; DispatchCreate - Handle IRP_MJ_CREATE
;-----------------------------------------------------------------------------
DispatchCreate PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    mov eax, STATUS_SUCCESS
    
    add rsp, 40
    ret
DispatchCreate ENDP

;-----------------------------------------------------------------------------
; DispatchClose - Handle IRP_MJ_CLOSE
;-----------------------------------------------------------------------------
DispatchClose PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    mov eax, STATUS_SUCCESS
    
    add rsp, 40
    ret
DispatchClose ENDP

;-----------------------------------------------------------------------------
; DispatchDeviceControl - Handle IRP_MJ_DEVICE_CONTROL
;-----------------------------------------------------------------------------
DispatchDeviceControl PROC FRAME
    sub rsp, 40
    .allocstack 40
    .endprolog
    
    ; Add IOCTL handling here
    mov eax, STATUS_NOT_IMPLEMENTED
    
    add rsp, 40
    ret
DispatchDeviceControl ENDP

;-----------------------------------------------------------------------------
; DriverEntry - Driver entry point
;-----------------------------------------------------------------------------
DriverEntry PROC FRAME
    push rbp
    .pushreg rbp
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    push rsi
    .pushreg rsi
    sub rsp, 120
    .allocstack 120
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov rbx, rcx                        ; Save driver object
    
    lea rcx, szLoadMsg
    call DbgPrint
    
    ; Set up unload routine
    lea rax, DriverUnload
    mov [rbx + 56], rax
    
    ; Set up dispatch routines
    lea rax, DispatchCreate
    mov [rbx + 112 + IRP_MJ_CREATE*8], rax
    
    lea rax, DispatchClose
    mov [rbx + 112 + IRP_MJ_CLOSE*8], rax
    
    lea rax, DispatchDeviceControl
    mov [rbx + 112 + IRP_MJ_DEVICE_CONTROL*8], rax
    
    ; Initialize device name - usDeviceName at [rbp+0]
    lea rcx, [rbp+0]
    lea rdx, szDeviceName
    call RtlInitUnicodeString
    
    ; Create device object
    mov rcx, rbx
    xor edx, edx
    lea r8, [rbp+0]
    mov r9d, DEVICE_TYPE_CODE
    mov DWORD PTR [rsp + 32], 0
    mov DWORD PTR [rsp + 40], 0
    lea rax, g_pDeviceObject
    mov [rsp + 48], rax
    call IoCreateDevice
    test eax, eax
    jnz exit_fail
    
    ; Create symbolic link - usSymLink at [rbp+16]
    lea rcx, [rbp+16]
    lea rdx, szSymLink
    call RtlInitUnicodeString
    
    lea rcx, [rbp+16]
    lea rdx, [rbp+0]
    call IoCreateSymbolicLink
    test eax, eax
    jnz cleanup_device
    
    mov eax, STATUS_SUCCESS
    jmp done
    
cleanup_device:
    mov rcx, g_pDeviceObject
    call IoDeleteDevice
    
exit_fail:
    mov eax, STATUS_UNSUCCESSFUL
    
done:
    add rsp, 120
    pop rsi
    pop rdi
    pop rbx
    pop rbp
    ret
DriverEntry ENDP

END
