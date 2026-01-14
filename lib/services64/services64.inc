;-----------------------------------------------------------------------------
; services64.inc - Windows Service Control Library Header
;-----------------------------------------------------------------------------
; Provides functions for managing Windows services via SCM.
;-----------------------------------------------------------------------------

IFNDEF SERVICES64_INC
SERVICES64_INC EQU 1

;-----------------------------------------------------------------------------
; Service Control Manager Access Rights
;-----------------------------------------------------------------------------
SC_MANAGER_CONNECT              EQU 0001h
SC_MANAGER_CREATE_SERVICE       EQU 0002h
SC_MANAGER_ENUMERATE_SERVICE    EQU 0004h
SC_MANAGER_ALL_ACCESS           EQU 0F003Fh

;-----------------------------------------------------------------------------
; Service Access Rights
;-----------------------------------------------------------------------------
SERVICE_QUERY_CONFIG            EQU 0001h
SERVICE_CHANGE_CONFIG           EQU 0002h
SERVICE_QUERY_STATUS            EQU 0004h
SERVICE_ENUMERATE_DEPENDENTS    EQU 0008h
SERVICE_START                   EQU 0010h
SERVICE_STOP                    EQU 0020h
SERVICE_PAUSE_CONTINUE          EQU 0040h
SERVICE_INTERROGATE             EQU 0080h
SERVICE_ALL_ACCESS              EQU 0F01FFh

;-----------------------------------------------------------------------------
; Service State
;-----------------------------------------------------------------------------
SERVICE_STOPPED                 EQU 1
SERVICE_START_PENDING           EQU 2
SERVICE_STOP_PENDING            EQU 3
SERVICE_RUNNING                 EQU 4
SERVICE_CONTINUE_PENDING        EQU 5
SERVICE_PAUSE_PENDING           EQU 6
SERVICE_PAUSED                  EQU 7

;-----------------------------------------------------------------------------
; Service Start Type
;-----------------------------------------------------------------------------
SERVICE_BOOT_START              EQU 0
SERVICE_SYSTEM_START            EQU 1
SERVICE_AUTO_START              EQU 2
SERVICE_DEMAND_START            EQU 3
SERVICE_DISABLED                EQU 4

;-----------------------------------------------------------------------------
; Service Type
;-----------------------------------------------------------------------------
SERVICE_KERNEL_DRIVER           EQU 001h
SERVICE_FILE_SYSTEM_DRIVER      EQU 002h
SERVICE_WIN32_OWN_PROCESS       EQU 010h
SERVICE_WIN32_SHARE_PROCESS     EQU 020h
SERVICE_INTERACTIVE_PROCESS     EQU 100h

;-----------------------------------------------------------------------------
; Service Control Codes
;-----------------------------------------------------------------------------
SERVICE_CONTROL_STOP            EQU 1
SERVICE_CONTROL_PAUSE           EQU 2
SERVICE_CONTROL_CONTINUE        EQU 3
SERVICE_CONTROL_INTERROGATE     EQU 4

;-----------------------------------------------------------------------------
; Function Prototypes
;-----------------------------------------------------------------------------

; Check if a service exists
; Parameters: pName - Service name
; Returns: TRUE if exists
ServiceExists PROTO pName:QWORD

; Check if a service is running
; Parameters: pName - Service name
; Returns: TRUE if running
ServiceIsRunning PROTO pName:QWORD

; Get service current state
; Parameters: pName - Service name
;             pdwState - Receives state
; Returns: TRUE on success
ServiceGetState PROTO pName:QWORD, pdwState:QWORD

; Start a service
; Parameters: pName - Service name
;             dwWaitMs - Max time to wait for start (0 = don't wait)
; Returns: TRUE on success
ServiceStart PROTO pName:QWORD, dwWaitMs:DWORD

; Stop a service
; Parameters: pName - Service name
;             dwWaitMs - Max time to wait for stop
; Returns: TRUE on success
ServiceStop PROTO pName:QWORD, dwWaitMs:DWORD

; Pause a service
; Parameters: pName - Service name
; Returns: TRUE on success
ServicePause PROTO pName:QWORD

; Continue a paused service
; Parameters: pName - Service name
; Returns: TRUE on success
ServiceContinue PROTO pName:QWORD

; Get service start type
; Parameters: pName - Service name
;             pdwType - Receives start type
; Returns: TRUE on success
ServiceGetStartType PROTO pName:QWORD, pdwType:QWORD

; Set service start type
; Parameters: pName - Service name
;             dwType - New start type
; Returns: TRUE on success
ServiceSetStartType PROTO pName:QWORD, dwType:DWORD

; Enable a service (set to auto start)
; Parameters: pName - Service name
; Returns: TRUE on success
ServiceEnable PROTO pName:QWORD

; Disable a service
; Parameters: pName - Service name
; Returns: TRUE on success
ServiceDisable PROTO pName:QWORD

ENDIF ; SERVICES64_INC

