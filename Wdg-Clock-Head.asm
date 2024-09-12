nolist

org #1000

WRITE "e:\symbos\widgets\clock.wdg"
READ "..\..\..\SVN-Main\trunk\SymbOS-Constants.asm"

relocate_start

App_BegCode

;### APPLICATION HEADER #######################################################

;header structure
prgdatcod       equ 0           ;Length of the code area (OS will place this area everywhere)
prgdatdat       equ 2           ;Length of the data area (screen manager data; OS will place this area inside a 16k block of one 64K bank)
prgdattra       equ 4           ;Length of the transfer area (stack, message buffer, desktop manager data; placed between #c000 and #ffff of a 64K bank)
prgdatorg       equ 6           ;Original origin of the assembler code
prgdatrel       equ 8           ;Number of entries in the relocator table
prgdatstk       equ 10          ;Length of the stack in bytes
prgdatrs1       equ 12          ;*reserved* (3 bytes)
prgdatnam       equ 15          ;program name (24+1[0] chars)
prgdatflg       equ 40          ;flags (+1=16colour icon available)
prgdat16i       equ 41          ;file offset of 16colour icon
prgdatrs2       equ 43          ;*reserved* (5 bytes)
prgdatidn       equ 48          ;"SymExe10" SymbOS executable file identification
prgdatcex       equ 56          ;additional memory for code area (will be reserved directly behind the loaded code area)
prgdatdex       equ 58          ;additional memory for data area (see above)
prgdattex       equ 60          ;additional memory for transfer area (see above)
prgdatres       equ 62          ;*reserved* (26 bytes)
prgdatver       equ 88          ;required OS version (3.0)
prgdatism       equ 90          ;Application icon (small version), 8x8 pixel, SymbOS graphic format
prgdatibg       equ 109         ;Application icon (big version), 24x24 pixel, SymbOS graphic format
prgdatlen       equ 256         ;length of header

prgpstdat       equ 6           ;start address of the data area
prgpsttra       equ 8           ;start address of the transfer area
prgpstspz       equ 10          ;additional sub process or timer IDs (4*1)
prgpstbnk       equ 14          ;64K ram bank (1-15), where the application is located
prgpstmem       equ 48          ;additional memory areas; 8 memory areas can be registered here, each entry consists of 5 bytes
                                ;00  1B  Ram bank number (1-8; if 0, the entry will be ignored)
                                ;01  1W  Address
                                ;03  1W  Length
prgpstnum       equ 88          ;Application ID
prgpstprz       equ 89          ;Main process ID

            dw App_BegData-App_BegCode  ;length of code area
            dw App_BegTrns-App_BegData  ;length of data area
            dw App_EndTrns-App_BegTrns  ;length of transfer area
prgdatadr   dw #1000                ;original origin                    POST address data area
prgtrnadr   dw relocate_count       ;number of relocator table entries  POST address transfer area
prgprztab   dw prgstk-App_BegTrns   ;stack length                       POST table processes
            dw 0                    ;*reserved*
App_BnkNum  db 0                    ;*reserved*                         POST bank number
            db "Clock Widget":ds 12:db 0  ;name
            db 0                    ;flags (+1=16c icon)
            dw 0                    ;16c icon offset
            ds 5                    ;*reserved*
prgmemtab   db "SymExe10"           ;SymbOS-EXE-identifier              POST table reserved memory areas
            dw 0                    ;additional code memory
            dw 0                    ;additional data memory
            dw 0                    ;additional transfer memory
            ds 26                   ;*reserved*
            db 0,3                  ;required OS version (3.0) ##!!##
prgicnsml   db 2,8,8,#33,#CC,#47,#A6,#8F,#97,#CB,#B5,#9E,#1F,#AD,#1F,#47,#A6,#33,#CC
prgicnbig   db 6,24,24
            db #77,#FF,#DD,#FF,#FF,#80,#46,#0A,#3D,#0A,#0A,#C8,#C5,#05,#35,#05,#05,#AC,#C6,#68,#3D,#1A,#C2,#BE,#C5,#E1,#41,#B4,#E1,#BE,#C6,#E0,#78,#B0,#68,#BE,#C5,#61,#35,#05,#61,#BE,#C6,#68,#7F,#CE,#C2,#BE
            db #C5,#71,#8F,#3E,#C1,#BE,#C6,#6B,#3D,#8F,#82,#BE,#C5,#47,#C0,#67,#49,#BE,#C6,#9E,#10,#11,#2C,#BE,#C5,#AC,#00,#00,#AD,#BE,#D7,#2C,#10,#00,#9E,#BE,#D5,#48,#10,#88,#56,#BE,#F7,#58,#10,#D0,#56,#BE
            db #F3,#48,#22,#00,#56,#3E,#F3,#2C,#44,#00,#9E,#FE,#F0,#AC,#00,#00,#BC,#F0,#70,#9E,#10,#11,#3C,#E0,#00,#47,#C4,#67,#48,#00,#00,#23,#3F,#8F,#80,#00,#00,#11,#8F,#3C,#00,#00,#00,#00,#70,#C0,#00,#00

;### WIDGET HEADER ############################################################

db "SWG1"       ;identifier
db 8            ;number of sizes
db 1            ;flags (+1=property dialogue available)
dw  99,33       ;size list
dw  99,44
dw  99,44
dw  99,53
dw 151,33
dw 151,44
dw 151,44
dw 151,53


;*** SYSTEM MANAGER LIBRARY USAGE
use_SySystem_PRGRUN     equ 0   ;Starts an application or opens a document
use_SySystem_PRGEND     equ 1   ;Stops an application and frees its resources
use_SySystem_PRGSRV     equ 0   ;Manages shared services or finds applications
use_SySystem_SYSWRN     equ 0   ;Opens an info, warning or confirm box
use_SySystem_SELOPN     equ 0   ;Opens the file selection dialogue
use_SySystem_HLPOPN     equ 0   ;HLP file management

;*** DESKTOP MANAGER LIBRARY USAGE
use_SyDesktop_WINOPN    equ 1   ;Opens a new window
use_SyDesktop_WINMEN    equ 0   ;Redraws the menu bar of a window
use_SyDesktop_WININH    equ 0   ;Redraws the content of a window
use_SyDesktop_WINTOL    equ 0   ;Redraws the content of the window toolbar
use_SyDesktop_WINTIT    equ 0   ;Redraws the title bar of a window
use_SyDesktop_WINSTA    equ 0   ;Redraws the status bar of a window
use_SyDesktop_WINMVX    equ 0   ;Sets the X offset of a window content
use_SyDesktop_WINMVY    equ 0   ;Sets the Y offset of a window content
use_SyDesktop_WINTOP    equ 0   ;Takes a window to the front position
use_SyDesktop_WINMAX    equ 0   ;Maximizes a window
use_SyDesktop_WINMIN    equ 0   ;Minimizes a window
use_SyDesktop_WINMID    equ 0   ;Restores a window or the size of a window
use_SyDesktop_WINMOV    equ 0   ;Moves a window to another position
use_SyDesktop_WINSIZ    equ 0   ;Resizes a window
use_SyDesktop_WINCLS    equ 1   ;Closes a window
use_SyDesktop_WINDIN    equ 0   ;Redraws the content of a window (always)
use_SyDesktop_WINSLD    equ 0   ;Redraws the two slider of a window
use_SyDesktop_WINPIN    equ 0   ;Redraws the content of a window (clipped)
use_SyDesktop_WINSIN    equ 1   ;Redraws the content of a control collection
use_SyDesktop_MENCTX    equ 0   ;Opens a context menu
use_SyDesktop_STIADD    equ 0   ;Adds an icon to the systray
use_SyDesktop_STIREM    equ 0   ;Removes an icon from the systray
use_SyDesktop_Service   equ 0   ;[REQUIRED FOR THE FOLLOWING FUNCTIONS]
use_SyDesktop_MODGET    equ 0   ;Returns the current screen mode
use_SyDesktop_MODSET    equ 0   ;Sets the current screen 
use_SyDesktop_COLGET    equ 0   ;Returns the definition of a colours
use_SyDesktop_COLSET    equ 0   ;Defines one colours
use_SyDesktop_DSKBGR    equ 0   ;Redraws the desktop background
use_SyDesktop_DSKPLT    equ 0   ;Redraws the complete screen

READ "..\..\..\SVN-Main\trunk\Docs-Developer\symbos_lib-SystemManager.asm"
READ "..\..\..\SVN-Main\trunk\Docs-Developer\symbos_lib-DesktopManager.asm"
READ "Wdg-Clock.asm"

App_EndTrns

relocate_table
relocate_end
