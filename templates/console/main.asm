;-----------------------------------------------------------------------------
; Console Application Template
;-----------------------------------------------------------------------------
; A minimal console application using the MASM64 Framework.
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc

EXTERNDEF ExitProcess:PROC

;-----------------------------------------------------------------------------
; Data Section
;-----------------------------------------------------------------------------
.DATA

szHello     DB "Hello from MASM64 Framework!", 13, 10, 0
szBanner    DB "================================", 13, 10
            DB "  MASM64 Console Application", 13, 10
            DB "================================", 13, 10, 0

;-----------------------------------------------------------------------------
; Code Section
;-----------------------------------------------------------------------------
.CODE

;-----------------------------------------------------------------------------
; main - Entry point
;-----------------------------------------------------------------------------
main PROC FRAME
    PROLOGUE 0, 32
    
    ; Print banner
    PRINT_STRING szBanner
    
    ; Print hello message
    PRINT_STRING szHello
    
    ; Exit with success
    EPILOGUE
    EXIT_PROCESS 0
main ENDP

END

