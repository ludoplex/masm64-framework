;-----------------------------------------------------------------------------
; config.inc - Project Configuration
;-----------------------------------------------------------------------------
; Edit this file to customize your project.
; This is the only file you need to modify for basic customization.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Project Information
;-----------------------------------------------------------------------------
PROJECT_NAME        TEXTEQU <MyApp>
PROJECT_VERSION     EQU 00010000h           ; 1.0.0.0

;-----------------------------------------------------------------------------
; Window Configuration
;-----------------------------------------------------------------------------
WINDOW_WIDTH        EQU 800
WINDOW_HEIGHT       EQU 600

;-----------------------------------------------------------------------------
; String Resources
;-----------------------------------------------------------------------------
; MASM cannot substitute text equates into string literals, so define
; your project-specific strings here.
;-----------------------------------------------------------------------------

DEFINE_STRINGS MACRO
    wszClassName    DW "MASM64WindowClass", 0
    wszWindowTitle  DW "MyApp - MASM64 Application", 0
ENDM

