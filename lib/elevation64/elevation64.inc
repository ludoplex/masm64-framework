;-----------------------------------------------------------------------------
; elevation64.inc - UAC and Privilege Management Library Header
;-----------------------------------------------------------------------------
; Provides functions for checking and elevating process privileges.
;-----------------------------------------------------------------------------

IFNDEF ELEVATION64_INC
ELEVATION64_INC EQU 1

;-----------------------------------------------------------------------------
; Token Information Classes
;-----------------------------------------------------------------------------
TokenElevation          EQU 20
TokenIntegrityLevel     EQU 25
TokenElevationType      EQU 18

;-----------------------------------------------------------------------------
; Token Access Rights
;-----------------------------------------------------------------------------
TOKEN_QUERY             EQU 0008h
TOKEN_ADJUST_PRIVILEGES EQU 0020h

;-----------------------------------------------------------------------------
; Privilege Constants
;-----------------------------------------------------------------------------
SE_PRIVILEGE_ENABLED    EQU 2

;-----------------------------------------------------------------------------
; Integrity Levels
;-----------------------------------------------------------------------------
SECURITY_MANDATORY_UNTRUSTED_RID        EQU 0
SECURITY_MANDATORY_LOW_RID              EQU 1000h
SECURITY_MANDATORY_MEDIUM_RID           EQU 2000h
SECURITY_MANDATORY_HIGH_RID             EQU 3000h
SECURITY_MANDATORY_SYSTEM_RID           EQU 4000h

;-----------------------------------------------------------------------------
; Common Privilege Names (Unicode)
;-----------------------------------------------------------------------------
; SE_DEBUG_NAME, SE_BACKUP_NAME, etc. - defined in data section

;-----------------------------------------------------------------------------
; Function Prototypes
;-----------------------------------------------------------------------------

; Check if current process is running as administrator
; Returns: TRUE if elevated, FALSE otherwise
IsRunningAsAdmin PROTO

; Relaunch current process with elevation (UAC prompt)
; Parameters: pCmdLine - Command line for new process (or NULL)
; Returns: Does not return on success, FALSE on failure
RelaunchAsAdmin PROTO pCmdLine:QWORD

; Require admin or exit - combines check and relaunch
; If not admin, relaunches elevated and exits current process
; If admin, returns normally
RequireAdminOrExit PROTO

; Get current process integrity level
; Parameters: pLevel - Pointer to receive integrity level RID
; Returns: TRUE on success
GetIntegrityLevel PROTO pLevel:QWORD

; Check if integrity level is at least specified level
; Parameters: dwRequiredLevel - Required level (use RID constants)
; Returns: TRUE if current level >= required
IsIntegrityAtLeast PROTO dwRequiredLevel:DWORD

; Enable a privilege in current process token
; Parameters: pPrivilegeName - Name of privilege (e.g., SE_DEBUG_NAME)
; Returns: TRUE on success
EnablePrivilege PROTO pPrivilegeName:QWORD

; Disable a privilege in current process token
; Parameters: pPrivilegeName - Name of privilege
; Returns: TRUE on success
DisablePrivilege PROTO pPrivilegeName:QWORD

; Check if a privilege is enabled
; Parameters: pPrivilegeName - Name of privilege
; Returns: TRUE if enabled
IsPrivilegeEnabled PROTO pPrivilegeName:QWORD

; Get process token
; Parameters: dwAccess - Desired access rights
;             phToken - Receives token handle
; Returns: TRUE on success
GetProcessToken PROTO dwAccess:DWORD, phToken:QWORD

ENDIF ; ELEVATION64_INC

