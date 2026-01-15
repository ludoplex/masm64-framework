;-----------------------------------------------------------------------------
; config.inc - Driver Project Configuration
;-----------------------------------------------------------------------------
; Edit this file to customize your driver project.
; This is the only file you need to modify for basic customization.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Project Information
;-----------------------------------------------------------------------------
PROJECT_NAME        TEXTEQU <MyDriver>
PROJECT_VERSION     EQU 00010000h           ; 1.0.0.0

;-----------------------------------------------------------------------------
; Device Configuration
;-----------------------------------------------------------------------------
; Device type - see FILE_DEVICE_* constants in WDK
DEVICE_TYPE_CODE    EQU 22h                 ; FILE_DEVICE_UNKNOWN

;-----------------------------------------------------------------------------
; String Resources
;-----------------------------------------------------------------------------
; Device name and symbolic link for user-mode access
;-----------------------------------------------------------------------------

DEFINE_STRINGS MACRO
    szDeviceName    DB "\Device\MyDriver", 0
    szSymLink       DB "\DosDevices\MyDriver", 0
    szLoadMsg       DB "MyDriver: Driver loaded", 10, 0
    szUnloadMsg     DB "MyDriver: Driver unloaded", 10, 0
ENDM

