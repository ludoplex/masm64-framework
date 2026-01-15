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
; String Resources
;-----------------------------------------------------------------------------
; MASM cannot substitute text equates into string literals, so define
; your project-specific strings here. These will be included in .DATA
;-----------------------------------------------------------------------------

; Main output message - customize as needed
DEFINE_STRINGS MACRO
    wszAppMessage   DW "Hello from MASM64 Framework!", 0
    wszNewLine      DW 13, 10, 0
ENDM

