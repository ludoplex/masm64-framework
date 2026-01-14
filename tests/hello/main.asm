;-----------------------------------------------------------------------------
; Hello World Test
;-----------------------------------------------------------------------------
; Basic sanity test for MASM64 Framework
;-----------------------------------------------------------------------------

OPTION CASEMAP:NONE

INCLUDE ..\..\core\abi64.inc
INCLUDE ..\..\core\stack64.inc
INCLUDE ..\..\core\macros64.inc

EXTERNDEF ExitProcess:PROC

.CODE

WinMain PROC FRAME
    sub rsp, SHADOW_SPACE
    .allocstack SHADOW_SPACE
    .endprolog
    
    ; Test passes - return 0
    xor ecx, ecx
    call ExitProcess
    
    add rsp, SHADOW_SPACE
    ret
WinMain ENDP

END

