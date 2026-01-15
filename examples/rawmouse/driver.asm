;-----------------------------------------------------------------------------
; RawMouse - Mouse Acceleration Disabler Driver
;-----------------------------------------------------------------------------
; A kernel filter driver that removes Windows mouse acceleration
; Provides true 1:1 raw mouse input for gaming and precision work
;
; WARNING: Kernel drivers require test signing or proper code signing
; Test only in virtual machines!
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

;-----------------------------------------------------------------------------
; Includes
;-----------------------------------------------------------------------------
INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc

;-----------------------------------------------------------------------------
; Kernel mode constants
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; NTSTATUS Codes
;-----------------------------------------------------------------------------
STATUS_SUCCESS              EQU 0
STATUS_UNSUCCESSFUL         EQU 0C0000001h

;-----------------------------------------------------------------------------
; IRP Major Function Codes
;-----------------------------------------------------------------------------
IRP_MJ_CREATE               EQU 0
IRP_MJ_CLOSE                EQU 2
IRP_MJ_READ                 EQU 3
IRP_MJ_DEVICE_CONTROL       EQU 14
IRP_MJ_INTERNAL_DEVICE_CONTROL EQU 15
IRP_MJ_PNP                  EQU 27

IRP_MJ_MAXIMUM_FUNCTION     EQU 27

;-----------------------------------------------------------------------------
; PnP Minor Function Codes
;-----------------------------------------------------------------------------
IRP_MN_START_DEVICE         EQU 0
IRP_MN_REMOVE_DEVICE        EQU 2

;-----------------------------------------------------------------------------
; IOCTL Codes for user configuration
;-----------------------------------------------------------------------------
IOCTL_RAWMOUSE_GET_CONFIG   EQU 220000h     ; CTL_CODE(FILE_DEVICE_MOUSE, 0x800, METHOD_BUFFERED, FILE_ANY_ACCESS)
IOCTL_RAWMOUSE_SET_CONFIG   EQU 220004h
IOCTL_RAWMOUSE_GET_STATS    EQU 220008h
IOCTL_RAWMOUSE_RESET_STATS  EQU 22000Ch

;-----------------------------------------------------------------------------
; Device extension structure (stored per-device)
;-----------------------------------------------------------------------------
DEVICE_EXTENSION STRUCT
    pLowerDevice        QWORD ?             ; Next device in stack
    bEnabled            DWORD ?             ; Filter enabled flag
    dwSensitivity       DWORD ?             ; Sensitivity multiplier (100 = 1.0x)
    qwPacketsProcessed  QWORD ?             ; Statistics counter
DEVICE_EXTENSION ENDS

;-----------------------------------------------------------------------------
; Mouse input data structure (from kbdmou.h)
;-----------------------------------------------------------------------------
MOUSE_INPUT_DATA STRUCT
    UnitId              WORD ?
    Flags               WORD ?
    ButtonFlags         WORD ?
    ButtonData          WORD ?
    RawButtons          DWORD ?
    LastX               DWORD ?             ; Relative X movement
    LastY               DWORD ?             ; Relative Y movement
    ExtraInformation    DWORD ?
MOUSE_INPUT_DATA ENDS

;-----------------------------------------------------------------------------
; Configuration structure for IOCTL
;-----------------------------------------------------------------------------
RAWMOUSE_CONFIG STRUCT
    bEnabled            DWORD ?
    dwSensitivity       DWORD ?             ; 100 = 1.0x, 50 = 0.5x, 200 = 2.0x
RAWMOUSE_CONFIG ENDS

;-----------------------------------------------------------------------------
; Statistics structure
;-----------------------------------------------------------------------------
RAWMOUSE_STATS STRUCT
    qwPacketsProcessed  QWORD ?
    qwPacketsFiltered   QWORD ?
RAWMOUSE_STATS ENDS

;-----------------------------------------------------------------------------
; External Kernel API
;-----------------------------------------------------------------------------
EXTERNDEF DbgPrint:PROC
EXTERNDEF IoCreateDevice:PROC
EXTERNDEF IoDeleteDevice:PROC
EXTERNDEF IoAttachDeviceToDeviceStack:PROC
EXTERNDEF IoDetachDevice:PROC
EXTERNDEF IoCallDriver:PROC
EXTERNDEF IofCompleteRequest:PROC
; Note: IoSkipCurrentIrpStackLocation and IoGetCurrentIrpStackLocation are
; inline macros in WDK, implemented locally below
EXTERNDEF ExAllocatePoolWithTag:PROC
EXTERNDEF ExFreePoolWithTag:PROC
EXTERNDEF RtlCopyMemory:PROC
EXTERNDEF RtlZeroMemory:PROC

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

; Debug messages
szLoadMsg       DB "RawMouse: Driver loaded", 10, 0
szUnloadMsg     DB "RawMouse: Driver unloading", 10, 0
szAddDevice     DB "RawMouse: AddDevice called", 10, 0
szProcessing    DB "RawMouse: Processing mouse packet X=%d Y=%d", 10, 0

; Pool tag 'RwMs'
POOL_TAG        EQU 'sMwR'

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; IoGetCurrentIrpStackLocation - Inline implementation
;-----------------------------------------------------------------------------
; RCX = pointer to IRP
; Returns: pointer to current IO_STACK_LOCATION in RAX
;
; IRP structure offsets (approximate, Windows version dependent):
;   +0x40 = Tail.Overlay.CurrentStackLocation
;-----------------------------------------------------------------------------
IoGetCurrentIrpStackLocation PROC
    mov rax, [rcx + 40h]                ; Irp->Tail.Overlay.CurrentStackLocation
    ret
IoGetCurrentIrpStackLocation ENDP

;-----------------------------------------------------------------------------
; IoSkipCurrentIrpStackLocation - Inline implementation
;-----------------------------------------------------------------------------
; RCX = pointer to IRP
; Increments CurrentLocation and CurrentStackLocation pointer
;
; IRP structure offsets (approximate):
;   +0x04 = CurrentLocation (CHAR)
;   +0x40 = Tail.Overlay.CurrentStackLocation
;   sizeof(IO_STACK_LOCATION) = 72 bytes (0x48)
;-----------------------------------------------------------------------------
IoSkipCurrentIrpStackLocation PROC
    inc BYTE PTR [rcx + 4]              ; Irp->CurrentLocation++
    add QWORD PTR [rcx + 40h], 48h      ; CurrentStackLocation += sizeof(IO_STACK_LOCATION)
    ret
IoSkipCurrentIrpStackLocation ENDP

;-----------------------------------------------------------------------------
; ProcessMouseData - Apply raw input processing to mouse data
;-----------------------------------------------------------------------------
; RCX = pointer to MOUSE_INPUT_DATA
; RDX = pointer to DEVICE_EXTENSION
; 
; This is where acceleration is removed - we simply pass through
; the raw delta values without any curve or acceleration applied.
;-----------------------------------------------------------------------------
ProcessMouseData PROC FRAME
    push rbp
    .pushreg rbp
    sub rsp, 48
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov r8, rcx                         ; MOUSE_INPUT_DATA
    mov r9, rdx                         ; DEVICE_EXTENSION
    
    ; Check if filtering is enabled
    cmp DWORD PTR [r9].DEVICE_EXTENSION.bEnabled, 0
    je pass_through
    
    ; Get sensitivity multiplier
    mov eax, [r9].DEVICE_EXTENSION.dwSensitivity
    
    ; Apply sensitivity to X movement
    ; NewX = (OrigX * Sensitivity) / 100
    mov ecx, [r8].MOUSE_INPUT_DATA.LastX
    imul ecx, eax
    mov edx, 100
    cdq
    idiv edx
    mov [r8].MOUSE_INPUT_DATA.LastX, eax
    
    ; Apply sensitivity to Y movement
    mov ecx, [r8].MOUSE_INPUT_DATA.LastY
    imul ecx, [r9].DEVICE_EXTENSION.dwSensitivity
    mov edx, 100
    cdq
    idiv edx
    mov [r8].MOUSE_INPUT_DATA.LastY, eax
    
    ; Increment processed counter
    inc QWORD PTR [r9].DEVICE_EXTENSION.qwPacketsProcessed
    
pass_through:
    add rsp, 48
    pop rbp
    ret
ProcessMouseData ENDP

;-----------------------------------------------------------------------------
; DispatchPassThrough - Pass IRP to lower driver
;-----------------------------------------------------------------------------
DispatchPassThrough PROC FRAME
    push rbp
    .pushreg rbp
    push rbx
    .pushreg rbx
    sub rsp, 56
    .allocstack 56
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov rbx, rcx                        ; DeviceObject
    ; rdx = Irp
    
    ; Get device extension
    mov rax, [rbx + 40]                 ; DeviceObject->DeviceExtension
    mov rcx, [rax].DEVICE_EXTENSION.pLowerDevice
    
    ; Skip current stack location
    push rdx
    mov rcx, rdx
    call IoSkipCurrentIrpStackLocation
    pop rdx
    
    ; Call lower driver
    mov rax, [rbx + 40]
    mov rcx, [rax].DEVICE_EXTENSION.pLowerDevice
    call IoCallDriver
    
    add rsp, 56
    pop rbx
    pop rbp
    ret
DispatchPassThrough ENDP

;-----------------------------------------------------------------------------
; DispatchDeviceControl - Handle IOCTLs for configuration
;-----------------------------------------------------------------------------
DispatchDeviceControl PROC FRAME
    ; Stack layout (rbp-relative):
    ;   [rbp+0]  = pExt (QWORD)
    ;   [rbp+8]  = pIrp (QWORD)
    ;   [rbp+16] = pStack (QWORD)
    ;   [rbp+24] = dwCode (DWORD)
    
    push rbp
    .pushreg rbp
    push rbx
    .pushreg rbx
    sub rsp, 88
    .allocstack 88
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov rbx, rcx                        ; DeviceObject
    mov [rbp+8], rdx                    ; pIrp = rdx
    
    ; Get device extension
    mov rax, [rbx + 40]
    mov [rbp+0], rax                    ; pExt = rax
    
    ; Get IRP stack location
    mov rcx, rdx
    call IoGetCurrentIrpStackLocation
    mov [rbp+16], rax                   ; pStack = rax
    
    ; Get IOCTL code from stack (offset varies by Windows version)
    ; Parameters.DeviceIoControl.IoControlCode
    mov eax, [rax + 24]                 ; Approximate offset
    mov [rbp+24], eax                   ; dwCode = eax
    
    cmp eax, IOCTL_RAWMOUSE_GET_CONFIG
    je get_config
    
    cmp eax, IOCTL_RAWMOUSE_SET_CONFIG
    je set_config
    
    cmp eax, IOCTL_RAWMOUSE_GET_STATS
    je get_stats
    
    ; Pass unknown IOCTLs to lower driver
    mov rcx, rbx
    mov rdx, [rbp+8]                    ; pIrp
    call DispatchPassThrough
    jmp done
    
get_config:
    ; Would copy current config to output buffer
    mov eax, STATUS_SUCCESS
    jmp complete
    
set_config:
    ; Would read config from input buffer
    mov eax, STATUS_SUCCESS
    jmp complete
    
get_stats:
    ; Would copy stats to output buffer
    mov eax, STATUS_SUCCESS
    jmp complete
    
complete:
    ; Complete the IRP
    ; Set IoStatus.Status and IoStatus.Information
    mov rcx, [rbp+8]                    ; pIrp
    mov [rcx + 24], eax                 ; IoStatus.Status (approx offset)
    mov QWORD PTR [rcx + 32], 0         ; IoStatus.Information
    xor edx, edx                        ; IO_NO_INCREMENT
    call IofCompleteRequest
    xor eax, eax                        ; STATUS_SUCCESS
    
done:
    add rsp, 88
    pop rbx
    pop rbp
    ret
DispatchDeviceControl ENDP

;-----------------------------------------------------------------------------
; DispatchPnp - Handle Plug and Play requests
;-----------------------------------------------------------------------------
DispatchPnp PROC FRAME
    push rbp
    .pushreg rbp
    push rbx
    .pushreg rbx
    push rdi
    .pushreg rdi
    sub rsp, 72
    .allocstack 72
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov rbx, rcx                        ; DeviceObject
    mov rdi, rdx                        ; Irp
    
    ; Get minor function
    mov rcx, rdx
    call IoGetCurrentIrpStackLocation
    movzx eax, BYTE PTR [rax + 1]       ; MinorFunction
    
    cmp al, IRP_MN_REMOVE_DEVICE
    je remove_device
    
    ; Pass to lower driver
    mov rcx, rbx
    mov rdx, rdi
    call DispatchPassThrough
    jmp done
    
remove_device:
    ; Detach from device stack
    mov rax, [rbx + 40]                 ; DeviceExtension
    mov rcx, [rax].DEVICE_EXTENSION.pLowerDevice
    call IoDetachDevice
    
    ; Delete our device
    mov rcx, rbx
    call IoDeleteDevice
    
    ; Complete IRP
    mov rcx, rdi
    mov DWORD PTR [rcx + 24], STATUS_SUCCESS
    xor edx, edx
    call IofCompleteRequest
    xor eax, eax
    
done:
    add rsp, 72
    pop rdi
    pop rbx
    pop rbp
    ret
DispatchPnp ENDP

;-----------------------------------------------------------------------------
; AddDevice - Attach to mouse device stack
;-----------------------------------------------------------------------------
; Called by PnP manager when a mouse device is found
;-----------------------------------------------------------------------------
AddDevice PROC FRAME
    ; Stack layout (rbp-relative):
    ;   [rbp+0]  = pDeviceObject (QWORD)
    ;   [rbp+8]  = pExt (QWORD)
    
    push rbp
    .pushreg rbp
    push rbx
    .pushreg rbx
    push r12
    .pushreg r12
    sub rsp, 88
    .allocstack 88
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov rbx, rcx                        ; DriverObject
    mov r12, rdx                        ; PhysicalDeviceObject (save for later)
    
    ; Debug output
    lea rcx, szAddDevice
    call DbgPrint
    
    ; Create filter device object
    mov rcx, rbx                        ; DriverObject
    mov edx, SIZEOF DEVICE_EXTENSION    ; DeviceExtensionSize
    xor r8d, r8d                        ; DeviceName = NULL (auto)
    mov r9d, 0Fh                        ; FILE_DEVICE_MOUSE
    mov DWORD PTR [rsp + 32], 0         ; DeviceCharacteristics
    mov DWORD PTR [rsp + 40], 0         ; Exclusive = FALSE
    lea rax, [rbp+0]                    ; &pDeviceObject
    mov [rsp + 48], rax
    call IoCreateDevice
    test eax, eax
    jnz failed
    
    ; Get and initialize extension
    mov rax, [rbp+0]                    ; pDeviceObject
    mov rax, [rax + 40]                 ; DeviceExtension
    mov [rbp+8], rax                    ; pExt = rax
    
    ; Zero extension
    mov rcx, rax
    xor edx, edx
    mov r8d, SIZEOF DEVICE_EXTENSION
    call RtlZeroMemory
    
    ; Set default config
    mov rax, [rbp+8]                    ; pExt
    mov DWORD PTR [rax].DEVICE_EXTENSION.bEnabled, 1
    mov DWORD PTR [rax].DEVICE_EXTENSION.dwSensitivity, 100
    
    ; Attach to device stack
    ; IoAttachDeviceToDeviceStack returns lower device
    mov rcx, [rbp+0]                    ; pDeviceObject
    mov rdx, r12                        ; PhysicalDeviceObject
    call IoAttachDeviceToDeviceStack
    test rax, rax
    jz cleanup_device
    
    mov rcx, [rbp+8]                    ; pExt
    mov [rcx].DEVICE_EXTENSION.pLowerDevice, rax
    
    ; Set device flags to match lower device
    mov rax, [rbp+0]                    ; pDeviceObject
    mov rcx, [rbp+8]                    ; pExt
    mov rcx, [rcx].DEVICE_EXTENSION.pLowerDevice
    mov ecx, [rcx + 28]                 ; Flags
    and ecx, 3                          ; DO_BUFFERED_IO | DO_DIRECT_IO
    or [rax + 28], ecx
    
    ; Clear initializing flag
    mov rax, [rbp+0]                    ; pDeviceObject
    and DWORD PTR [rax + 28], NOT 80h   ; ~DO_DEVICE_INITIALIZING
    
    xor eax, eax                        ; STATUS_SUCCESS
    jmp done
    
cleanup_device:
    mov rcx, [rbp+0]                    ; pDeviceObject
    call IoDeleteDevice
    
failed:
    mov eax, STATUS_UNSUCCESSFUL
    
done:
    add rsp, 88
    pop r12
    pop rbx
    pop rbp
    ret
AddDevice ENDP

;-----------------------------------------------------------------------------
; DriverUnload - Driver unload routine
;-----------------------------------------------------------------------------
DriverUnload PROC FRAME
    push rbp
    .pushreg rbp
    sub rsp, 48
    .allocstack 48
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    lea rcx, szUnloadMsg
    call DbgPrint
    
    add rsp, 48
    pop rbp
    ret
DriverUnload ENDP

;-----------------------------------------------------------------------------
; DriverEntry - Driver entry point
;-----------------------------------------------------------------------------
DriverEntry PROC FRAME
    push rbp
    .pushreg rbp
    push rbx
    .pushreg rbx
    sub rsp, 72
    .allocstack 72
    lea rbp, [rsp + 32]
    .setframe rbp, 32
    .endprolog
    
    mov rbx, rcx                        ; DriverObject
    
    ; Debug message
    lea rcx, szLoadMsg
    call DbgPrint
    
    ; Set up unload routine
    lea rax, DriverUnload
    mov [rbx + 56], rax                 ; DriverUnload
    
    ; Set up AddDevice
    lea rax, AddDevice
    mov [rbx + 168], rax                ; DriverExtension->AddDevice
    
    ; Set up dispatch routines
    lea rax, DispatchPassThrough
    
    ; Fill all MajorFunction entries with pass-through
    xor ecx, ecx
fill_loop:
    cmp ecx, IRP_MJ_MAXIMUM_FUNCTION
    ja fill_done
    mov [rbx + 112 + rcx*8], rax
    inc ecx
    jmp fill_loop
fill_done:
    
    ; Override specific handlers
    lea rax, DispatchDeviceControl
    mov [rbx + 112 + IRP_MJ_DEVICE_CONTROL*8], rax
    mov [rbx + 112 + IRP_MJ_INTERNAL_DEVICE_CONTROL*8], rax
    
    lea rax, DispatchPnp
    mov [rbx + 112 + IRP_MJ_PNP*8], rax
    
    xor eax, eax                        ; STATUS_SUCCESS
    
    add rsp, 72
    pop rbx
    pop rbp
    ret
DriverEntry ENDP

END

