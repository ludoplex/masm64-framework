;-----------------------------------------------------------------------------
; config.inc - Shellcode Project Configuration
;-----------------------------------------------------------------------------
; Edit this file to customize your shellcode project.
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; Project Information
;-----------------------------------------------------------------------------
PROJECT_NAME        TEXTEQU <MyShellcode>

;-----------------------------------------------------------------------------
; Hash Constants for API Resolution
;-----------------------------------------------------------------------------
; Pre-computed djb2 hashes for common functions
; Use the HashString function to compute hashes for additional APIs
;-----------------------------------------------------------------------------
HASH_KERNEL32           EQU 06A4ABC5Bh
HASH_LOADLIBRARYA       EQU 0EC0E4E8Eh
HASH_GETPROCADDRESS     EQU 07C0DFCAA0h
HASH_EXITPROCESS        EQU 073E2D87Eh

;-----------------------------------------------------------------------------
; PEB/TEB Offsets (x64 Windows)
;-----------------------------------------------------------------------------
TEB_PEB_OFFSET          EQU 60h
PEB_LDR_OFFSET          EQU 18h
LDR_INLOAD_OFFSET       EQU 20h
LDR_DLLBASE_OFFSET      EQU 30h
LDR_FULLNAME_OFFSET     EQU 48h

