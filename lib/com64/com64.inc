;-----------------------------------------------------------------------------
; com64.inc - COM Interface Library Header
;-----------------------------------------------------------------------------
; Provides COM initialization and interface navigation for MASM64.
; Simplifies COM vtable access patterns.
;-----------------------------------------------------------------------------

IFNDEF COM64_INC
COM64_INC EQU 1

;-----------------------------------------------------------------------------
; COM Initialization Flags
;-----------------------------------------------------------------------------
COINIT_APARTMENTTHREADED    EQU 2
COINIT_MULTITHREADED        EQU 0
COINIT_DISABLE_OLE1DDE      EQU 4

;-----------------------------------------------------------------------------
; CLSCTX Flags
;-----------------------------------------------------------------------------
CLSCTX_INPROC_SERVER        EQU 1
CLSCTX_INPROC_HANDLER       EQU 2
CLSCTX_LOCAL_SERVER         EQU 4
CLSCTX_ALL                  EQU 23

;-----------------------------------------------------------------------------
; HRESULT Success/Failure
;-----------------------------------------------------------------------------
S_OK                        EQU 0
S_FALSE                     EQU 1
E_NOTIMPL                   EQU 80004001h
E_NOINTERFACE               EQU 80004002h
E_POINTER                   EQU 80004003h
E_ABORT                     EQU 80004004h
E_FAIL                      EQU 80004005h
E_UNEXPECTED                EQU 8000FFFFh
E_ACCESSDENIED              EQU 80070005h
E_HANDLE                    EQU 80070006h
E_OUTOFMEMORY               EQU 8007000Eh
E_INVALIDARG                EQU 80070057h

;-----------------------------------------------------------------------------
; GUID Structure
;-----------------------------------------------------------------------------
GUID STRUCT
    Data1   DWORD ?
    Data2   WORD ?
    Data3   WORD ?
    Data4   BYTE 8 DUP(?)
GUID ENDS

IID TYPEDEF GUID
CLSID TYPEDEF GUID
REFIID TYPEDEF PTR GUID
REFCLSID TYPEDEF PTR GUID

;-----------------------------------------------------------------------------
; IUnknown vtable offsets (all COM interfaces inherit from IUnknown)
;-----------------------------------------------------------------------------
IUnknown_QueryInterface     EQU 0
IUnknown_AddRef             EQU 8
IUnknown_Release            EQU 16

;-----------------------------------------------------------------------------
; Function Prototypes
;-----------------------------------------------------------------------------

; Initialize COM library
; Parameters: dwFlags - COINIT_* flags
; Returns: HRESULT
Com_Initialize PROTO dwFlags:DWORD

; Uninitialize COM library
Com_Uninitialize PROTO

; Create COM object instance
; Parameters: pClsid - Pointer to CLSID
;             pIid - Pointer to IID
;             ppInterface - Receives interface pointer
; Returns: HRESULT
Com_CreateInstance PROTO pClsid:QWORD, pIid:QWORD, ppInterface:QWORD

; Release COM interface
; Parameters: pInterface - Interface pointer to release
; Returns: Reference count
Com_Release PROTO pInterface:QWORD

; Query for interface
; Parameters: pInterface - Source interface
;             pIid - Desired interface IID
;             ppNewInterface - Receives new interface
; Returns: HRESULT
Com_QueryInterface PROTO pInterface:QWORD, pIid:QWORD, ppNewInterface:QWORD

; Add reference to interface
; Parameters: pInterface - Interface pointer
; Returns: New reference count
Com_AddRef PROTO pInterface:QWORD

; Check if HRESULT indicates success
; Parameters: hr - HRESULT value
; Returns: TRUE if succeeded
Com_Succeeded PROTO hr:DWORD

; Check if HRESULT indicates failure
; Parameters: hr - HRESULT value
; Returns: TRUE if failed
Com_Failed PROTO hr:DWORD

;-----------------------------------------------------------------------------
; COM Call Macros
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; COMCALL - Call COM interface method
;-----------------------------------------------------------------------------
; Parameters:
;   interface_ptr - Register or memory containing interface pointer
;   vtable_offset - Byte offset in vtable
;   args          - Additional arguments (interface is always first arg)
;
; Example: COMCALL rdi, 24, rdx, r8
;          Calls: pInterface->vtable[24/8](pInterface, rdx, r8)
;-----------------------------------------------------------------------------
COMCALL MACRO interface_ptr, vtable_offset, args:VARARG
    LOCAL pif
    
    ;; Get interface pointer into RCX (this pointer)
    IF (OPATTR(interface_ptr)) AND 10h
        ;; It's a register
        IFIDNI <interface_ptr>, <rcx>
            ;; Already in RCX
        ELSE
            mov rcx, interface_ptr
        ENDIF
    ELSE
        ;; Memory operand
        mov rcx, interface_ptr
    ENDIF
    
    ;; Get vtable pointer
    mov rax, [rcx]                      ; RAX = vtable pointer
    
    ;; Call method at offset
    call QWORD PTR [rax + vtable_offset]
ENDM

;-----------------------------------------------------------------------------
; COMCALL0 - COM call with no extra arguments
;-----------------------------------------------------------------------------
COMCALL0 MACRO interface_ptr, vtable_offset
    mov rcx, interface_ptr
    mov rax, [rcx]
    call QWORD PTR [rax + vtable_offset]
ENDM

;-----------------------------------------------------------------------------
; COMCALL1 - COM call with 1 extra argument
;-----------------------------------------------------------------------------
COMCALL1 MACRO interface_ptr, vtable_offset, arg1
    mov rdx, arg1
    mov rcx, interface_ptr
    mov rax, [rcx]
    call QWORD PTR [rax + vtable_offset]
ENDM

;-----------------------------------------------------------------------------
; COMCALL2 - COM call with 2 extra arguments
;-----------------------------------------------------------------------------
COMCALL2 MACRO interface_ptr, vtable_offset, arg1, arg2
    mov r8, arg2
    mov rdx, arg1
    mov rcx, interface_ptr
    mov rax, [rcx]
    call QWORD PTR [rax + vtable_offset]
ENDM

;-----------------------------------------------------------------------------
; DEFINE_GUID - Define a GUID constant
;-----------------------------------------------------------------------------
DEFINE_GUID MACRO name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8
    name GUID <l, w1, w2, <b1, b2, b3, b4, b5, b6, b7, b8>>
ENDM

ENDIF ; COM64_INC

