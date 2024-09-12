;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                         D e s k t o p   C l o c k                          @
;@                          (SymbOS Desktop Widget)                           @
;@             (c) 2015-2015 by Prodatron / SymbiosiS (Jörn Mika)             @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;todo


prgprz  ld ix,wdgsizt
        ld b,8
prgprz3 push bc
        ld l,(ix+0)
        ld h,(ix+1)
        inc ix:inc ix
        call wdgini
        pop bc
        djnz prgprz3

        ld b,10                 ;wait for first message (max 10 idles)
prgprz1 push bc
        rst #30
        ld a,(App_PrcID)
        db #dd:ld l,a
        db #dd:ld h,-1
        ld iy,App_MsgBuf
        rst #18
        db #dd:dec l
        pop bc
        jr z,prgprz2
        djnz prgprz1
        jr prgend

prgprz0 ld a,(App_PrcID)
        db #dd:ld l,a
        db #dd:ld h,-1
        ld iy,App_MsgBuf
        rst #18
        db #dd:dec l
        jr z,prgprz2
        rst #30
        ld hl,timcnt
        dec (hl)
        call z,timnxt
        jr prgprz0
prgprz2 ld a,(App_MsgBuf)
        or a
        jr z,prgend
        cp MSR_DSK_WCLICK
        jr z,prgprz4
        cp MSC_WDG_SIZE
        jp z,wdgsiz
        cp MSC_WDG_PROP
        jp z,wdgprp
        cp MSC_WDG_CLICK
        jp z,wdgclk
        jr prgprz0
prgprz4 ld a,(App_MsgBuf+2)
        cp DSK_ACT_CLOSE
        jp z,wdgprp0
        cp DSK_ACT_CONTENT
        jr nz,prgprz0
        ld hl,(App_MsgBuf+8)
        ld a,l
        or h
        jr z,prgprz0
        jp (hl)

;### PRGEND -> End program
prgend  ld hl,(App_BegCode+prgpstnum)
        call SySystem_PRGEND
prgend0 rst #30
        jr prgend0


;==============================================================================
;### TIME ROUTINES ############################################################
;==============================================================================

cfgdatbeg
cfgflg  db 0    ;bit0 -> 0=12hour, 1=24hour
                ;bit1 -> 0=mm/dd/yyyy, 1=dd.mm.yyyy
cfgdatend

timcnt  db 1

timsec  db 0    ;second
timhor  db 0    ;hour
timmin  db 0    ;minute
timmon  db 0    ;month
timday  db 0    ;day
timyer  dw 0    ;year

timold  db -1,-1,-1     ;sec,min,hor
        db -1,-1        ;day,mon
        dw -1           ;year
        db 0            ;weekday

timactpnt   dw 0
;hour, minute, second, am/date, weekdays
timact
db 0,5,2,0,0
db 0,7,4,2,0
db 0,5,2,0,7
db 0,7,4,2,9
db 8,5,2,0,0
db 10,7,4,2,0
db 8,5,2,0,10
db 10,7,4,2,12

;### TIMNXT -> one second or more passed
timnxt  ld (hl),50
timnxt0 rst #20:dw #810c
        ld (timsec),a
        ld (timhor),bc
        ld (timmon),de
        ld (timyer),hl

        ld iy,(timactpnt)
        ld hl,timold+0      ;show seconds
        ld ix,digfnthd4
        call timnxt1
        inc iy
        ld a,(timmin)       ;show minutes
        ld hl,timold+1
        ld ix,digfnthd2
        call timnxt8
        inc iy

        ld a,(timhor)       ;show hours and am/pm
        ld hl,timold+2
        cp (hl)
        jr z,timnxta
        ld (hl),a
        ld hl,cfgflg
        bit 0,(hl)
        ld hl,timdayz
        jr nz,timnxt6
        cp 12
        ld hl,timday0
        jr c,timnxt7
        ld hl,timday1
        jr z,timnxt6
        sub 12
        jr timnxt6
timnxt7 or a
        jr nz,timnxt6
        add 12
timnxt6 ld (timdayctl),hl
        ld ix,digfnthd0
        call timnxt9
        ld de,(wdgctrid)
        ld d,(iy+1)
        inc d:dec d
        ld a,(wdgwinid)
        push iy
        call nz,SyDesktop_WINSIN
        pop iy

timnxta ld a,(iy+1)         ;show date
        or a
        jr z,timnxtd
        ld de,(timmon)
        ld bc,(timyer)
        ld hl,(timold+3)
        or a
        sbc hl,de
        jr nz,timnxtb
        ld hl,(timold+5)
        or a
        sbc hl,bc
        jr z,timnxtd
timnxtb ld (timold+3),de
        ld (timold+5),bc
        ld hl,cfgflg
        bit 1,(hl)
        ld a,"/"
        jr z,timnxtc
        ld a,e
        ld e,d
        ld d,a
        ld a,"."
timnxtc ld (datdsptxt+2),a
        ld (datdsptxt+5),a
        ld a,e
        call clcdec
        ld (datdsptxt+0),hl
        ld a,d
        call clcdec
        ld (datdsptxt+3),hl
        ld hl,-2000
        add hl,bc
        ld a,l
        call clcdec
        ld (datdsptxt+8),hl
        ld de,(wdgctrid)
        ld d,(iy+1)
        inc d
        ld a,(wdgwinid)
        push iy
        call SyDesktop_WINSIN
        pop iy

timnxtd ld a,(iy+2)         ;show weekday
        or a
        ret z
        ld de,(timmon)
        ld hl,(timyer)
        call timgdy
        ld hl,timold+7
        cp (hl)
        ret z
        ld (hl),a
        ld hl,timwkdct0+2
        ld b,7
        ld de,4
timnxte ld (hl),16*7+1
        add hl,de
        djnz timnxte
        add a:add a
        sub 7*4
        ld c,a
        dec b
        add hl,bc
        ld (hl),16*6+1
        ld de,(wdgctrid)
        ld d,(iy+2)
        ld a,(wdgwinid)
        ld c,a
        ld b,7
timnxtf push bc
        push de
        ld a,c
        call SyDesktop_WINSIN
        pop de
        inc d
        pop bc
        djnz timnxtf
        ret

timnxt1 inc (iy+0)
        dec (iy+0)
        ret z
timnxt8 cp (hl)
        ret z
        ld (hl),a
timnxt9 ld bc,10*256
timnxt2 sub b
        jr c,timnxt3
        inc c
        jr timnxt2
timnxt3 add b           ;a=low, c=high
        push bc
        call timnxt4
        ld (ix+12+0),l
        ld (ix+12+1),h
        pop bc
        ld a,c
        call timnxt4
        ld (ix+03+0),l
        ld (ix+03+1),h
        ld de,(wdgctrid)
        ld d,(iy+0)
        ld a,(wdgwinid)
        push iy
        push af
        push de
        call SyDesktop_WINSIN
        pop de
        pop af
        inc d
        call SyDesktop_WINSIN
        pop iy
        ret
;hl=a*250+digfntbmp
timnxt4 ld h,a
        ld l,0          ;hl=a*256
        add a
        jr z,timnxt5
        ld c,a
        add a
        add c           ;a=a*6
        neg
        ld c,a
        ld b,-1         ;bc=a*-6
        add hl,bc       ;hl = a*256 - a*6 = a*250
timnxt5 ld bc,digfntbmp
        add hl,bc
        ret


;==============================================================================
;### WIDGET ROUTINES ##########################################################
;==============================================================================

wdgwinid    db 0    ;window ID
wdgctrid    db 0    ;control collection ID

;### WDGINI -> init controls
;### Input      HL=control group
wdgini  ld b,(hl)
        inc hl:inc hl
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        inc hl
        ld a,(App_PrcID)
        ld de,16
wdgini1 ld (hl),a
        add hl,de
        djnz wdgini1
        ret

;### WDGSIZ -> size event
wdgsizt dw wdggrpwin0,wdggrpwin1,wdggrpwin2,wdggrpwin3,wdggrpwin4,wdggrpwin5,wdggrpwin6,wdggrpwin7

wdgsiz  ld hl,(App_MsgBuf+1)
        ld (wdgwinid),hl
        ld a,(App_MsgBuf+3)
        ld e,a
        add a
        ld l,a
        ld h,0
        ld bc,wdgsizt
        add hl,bc
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld (wdgobjsup),bc
        add a
        add e
        ld l,a
        ld h,0
        ld bc,timact
        add hl,bc
        ld (timactpnt),hl
        ld hl,256*FNC_DXT_WDGOKY+MSR_DSK_EXTDSK
        ld (App_MsgBuf+0),hl
        ld hl,wdgobjsup
        ld (App_MsgBuf+2),hl
        ld a,(App_BnkNum)
        ld (App_MsgBuf+4),a
        ld a,(App_PrcID)
        db #dd:ld l,a
        ld iy,App_MsgBuf
        rst #10
        jp prgprz0

;### WDGPRP -> properties event
wdgprpw db 0

wdgprp  ld a,(wdgprpw)
        or a
        jp nz,prgprz0
        ld a,(cfgflg)
        srl a
        ld (cfgdat),a
        res 0,a
        rla
        ld (cfgtim),a
        ld de,configwin
        ld a,(App_BnkNum)
        call SyDesktop_WINOPN
        ld (wdgprpw),a
        jp prgprz0
wdgprp1 ld hl,(cfgtim)
        ld a,h
        add a
        add l
        ld (cfgflg),a
        call wdgclk0
wdgprp0 ld hl,wdgprpw           ;close
        ld a,(hl)
        ld (hl),0
        call SyDesktop_WINCLS
        jp prgprz0

;### WDGCLK -> click event (switch between 12/24/eu date/us date display)
wdgclk  ld a,(App_MsgBuf+3)
        cp DSK_SUB_MDCLICK
        jr z,wdgclk1
        ld hl,cfgflg                ;single click -> change time and date mode
        ld a,(hl)
        inc a
        and 3
        ld (hl),a
        call wdgclk0
        jp prgprz0
wdgclk0 ld a,-1
        ld (timold+2),a
        ld (timold+3),a
        jp timnxt0
wdgclk1 ld hl,256*2+MSC_SYS_PRGSET  ;double click -> start time/date properties (control panel)
        ld (App_MsgBuf),hl
        ld a,(App_PrcID)
        db #dd:ld l,a
        db #dd:ld h,PRC_ID_SYSTEM
        ld iy,App_MsgBuf
        rst #10
        jp prgprz0


;==============================================================================
;### SUB ROUTINES #############################################################
;==============================================================================

;### CLCDEC -> converts byte into ASCII digits
;### Input      A=value
;### Output     L=10. digit char, H=1.digit char
;### Destroyed  AF
clcdec  ld l,0
clcdec1 sub 10
        jr c,clcdec2
        inc l
        jr clcdec1
clcdec2 add "0"+10
        ld h,a
        ld a,"0"
        add l
        ld l,a
        ret

;### TIMGDY -> calculates weekday
;### Input      D=day (1-x), E=month (1-x), HL=year
;### Output     A=weekday (0-6; 0=monday)
;### Destroyed  F,BC,DE,HL
timgdyn db 0,3,3,6,1,4,6,2,5,0,3,5
timgdys db 0,3,4,0,2,5,0,3,6,1,4,6
timgdy  ld bc,1980
        or a
        sbc hl,bc
        ld b,l          ;B=Jahre seit 1980
        ld c,3          ;A=Schaltjahr-Checker
        ld a,1          ;A=Wochentag (01.01.1980 war Dienstag)
        inc b
timgdy1 dec b
        jr z,timgdy3
        inc a           ;neues Jahr -> Wochentag+1
        inc c
        bit 2,c
        jr z,timgdy2
        ld c,0          ;Schaltjahr -> Wochentag+2
        inc a
timgdy2 cp 7
        jr c,timgdy1
        sub 7
        jr timgdy1
timgdy3 ld b,a          ;B=Wochentag vom 1.1. des Jahres
        ld a,c
        cp 3
        ld hl,timgdyn
        jr nz,timgdy4
        ld hl,timgdys
timgdy4 ld a,d
        dec a
        ld d,0
        dec e
        add hl,de
        add (hl)
        add b
timgdy5 sub 7
        jr nc,timgdy5
        add 7
        ret


;==============================================================================
;### DATA AREA ################################################################
;==============================================================================

App_BegData

digfnthd0 db 10,20,25:dw 0*250+digfntbmp,digfntenc,10*250   ;hour
digfnthd1 db 10,20,25:dw 0*250+digfntbmp,digfntenc,10*250
digfnthd2 db 10,20,25:dw 0*250+digfntbmp,digfntenc,10*250   ;minute
digfnthd3 db 10,20,25:dw 0*250+digfntbmp,digfntenc,10*250
digfnthd4 db 10,20,25:dw 0*250+digfntbmp,digfntenc,10*250   ;second
digfnthd5 db 10,20,25:dw 0*250+digfntbmp,digfntenc,10*250

digfnthdt
dw 0*250+digfntbmp,1*250+digfntbmp,2*250+digfntbmp,3*250+digfntbmp,4*250+digfntbmp
dw 5*250+digfntbmp,6*250+digfntbmp,7*250+digfntbmp,8*250+digfntbmp,9*250+digfntbmp

digfntenc db 5
digfntbmp
;0
db #11,#11,#68,#88,#88,#88,#88,#88,#88,#61, #11,#18,#16,#88,#88,#88,#88,#88,#86,#61, #11,#18,#81,#88,#88,#88,#88,#88,#16,#86, #11,#18,#86,#18,#88,#88,#88,#81,#68,#81, #11,#18,#88,#61,#11,#11,#11,#16,#88,#81
db #11,#18,#88,#61,#11,#11,#11,#18,#88,#81, #11,#68,#88,#61,#11,#11,#11,#18,#88,#81, #11,#68,#88,#61,#11,#11,#11,#18,#88,#61, #11,#68,#88,#61,#11,#11,#11,#18,#88,#61, #11,#68,#88,#11,#11,#11,#11,#18,#88,#61
db #11,#18,#61,#11,#11,#11,#11,#11,#88,#11, #11,#16,#11,#11,#11,#11,#11,#11,#11,#11, #11,#11,#11,#11,#11,#11,#11,#11,#11,#11, #11,#18,#11,#11,#11,#11,#11,#11,#81,#11, #11,#88,#81,#11,#11,#11,#11,#16,#88,#11
db #11,#88,#86,#11,#11,#11,#11,#68,#88,#11, #11,#88,#86,#11,#11,#11,#11,#88,#88,#11, #16,#88,#86,#11,#11,#11,#11,#88,#88,#11, #16,#88,#86,#11,#11,#11,#11,#88,#86,#11, #16,#88,#86,#11,#11,#11,#11,#88,#86,#11
db #16,#88,#81,#11,#11,#11,#11,#88,#86,#11, #16,#88,#16,#88,#88,#88,#86,#18,#86,#11, #16,#81,#68,#88,#88,#88,#88,#61,#86,#11, #16,#16,#88,#88,#88,#88,#88,#86,#66,#11, #11,#68,#88,#88,#88,#88,#88,#88,#11,#11
;1
db #11,#11,#11,#11,#11,#11,#11,#11,#11,#11, #11,#11,#11,#11,#11,#11,#11,#18,#61,#11, #11,#11,#11,#11,#11,#11,#11,#18,#86,#11, #11,#11,#11,#11,#11,#11,#11,#18,#88,#11, #11,#11,#11,#11,#11,#11,#11,#18,#88,#81
db #11,#11,#11,#11,#11,#11,#11,#68,#88,#61, #11,#11,#11,#11,#11,#11,#11,#18,#88,#61, #11,#11,#11,#11,#11,#11,#11,#68,#88,#61, #11,#11,#11,#11,#11,#11,#11,#68,#88,#11, #11,#11,#11,#11,#11,#11,#11,#68,#88,#11
db #11,#11,#11,#11,#11,#11,#11,#18,#81,#11, #11,#11,#11,#11,#11,#11,#11,#16,#11,#11, #11,#11,#11,#11,#11,#11,#11,#11,#11,#11, #11,#11,#11,#11,#11,#11,#11,#18,#11,#11, #11,#11,#11,#11,#11,#11,#11,#88,#81,#11
db #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#11,#11,#11,#11,#16,#88,#86,#11, #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#11,#11,#11,#11,#16,#88,#86,#11, #11,#11,#11,#11,#11,#11,#16,#88,#86,#11
db #11,#11,#11,#11,#11,#11,#16,#88,#81,#11, #11,#11,#11,#11,#11,#11,#16,#88,#11,#11, #11,#11,#11,#11,#11,#11,#16,#81,#11,#11, #11,#11,#11,#11,#11,#11,#16,#11,#11,#11, #11,#11,#11,#11,#11,#11,#11,#11,#11,#11
;2
db #11,#11,#68,#88,#88,#88,#88,#88,#88,#61, #11,#11,#16,#88,#88,#88,#88,#88,#86,#61, #11,#11,#11,#88,#88,#88,#88,#88,#16,#86, #11,#11,#11,#18,#88,#88,#88,#86,#68,#81, #11,#11,#11,#11,#11,#11,#11,#16,#88,#81
db #11,#11,#11,#11,#11,#11,#11,#18,#88,#81, #11,#11,#11,#11,#11,#11,#11,#18,#88,#81, #11,#11,#11,#11,#11,#11,#11,#18,#88,#61, #11,#11,#11,#11,#11,#11,#11,#18,#88,#61, #11,#11,#11,#11,#11,#11,#11,#18,#88,#61
db #11,#11,#11,#88,#88,#88,#88,#81,#88,#11, #11,#11,#18,#88,#88,#88,#88,#88,#16,#11, #11,#11,#68,#88,#88,#88,#88,#86,#11,#11, #11,#18,#16,#88,#88,#88,#88,#61,#11,#11, #11,#88,#81,#11,#11,#11,#11,#11,#11,#11
db #11,#88,#86,#11,#11,#11,#11,#11,#11,#11, #11,#88,#86,#11,#11,#11,#11,#11,#11,#11, #16,#88,#86,#11,#11,#11,#11,#11,#11,#11, #16,#88,#86,#11,#11,#11,#11,#11,#11,#11, #16,#88,#86,#11,#11,#11,#11,#11,#11,#11
db #16,#88,#81,#11,#11,#11,#11,#11,#11,#11, #16,#88,#16,#88,#88,#88,#86,#11,#11,#11, #16,#81,#68,#88,#88,#88,#88,#61,#11,#11, #16,#16,#88,#88,#88,#88,#88,#86,#11,#11, #11,#68,#88,#88,#88,#88,#88,#88,#11,#11
;3
db #11,#11,#68,#88,#88,#88,#88,#88,#88,#61, #11,#11,#16,#88,#88,#88,#88,#88,#86,#61, #11,#11,#11,#88,#88,#88,#88,#88,#16,#86, #11,#11,#11,#18,#88,#88,#88,#81,#68,#81, #11,#11,#11,#11,#11,#11,#11,#16,#88,#81
db #11,#11,#11,#11,#11,#11,#11,#18,#88,#81, #11,#11,#11,#11,#11,#11,#11,#18,#88,#81, #11,#11,#11,#11,#11,#11,#11,#18,#88,#61, #11,#11,#11,#11,#11,#11,#11,#18,#88,#61, #11,#11,#11,#11,#11,#11,#11,#18,#88,#61
db #11,#11,#11,#88,#88,#88,#88,#81,#88,#11, #11,#11,#18,#88,#88,#88,#88,#88,#11,#11, #11,#11,#68,#88,#88,#88,#88,#86,#11,#11, #11,#11,#16,#88,#88,#88,#88,#61,#86,#11, #11,#11,#11,#11,#11,#11,#11,#18,#88,#11
db #11,#11,#11,#11,#11,#11,#11,#68,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#11,#11,#11,#11,#11,#88,#86,#11
db #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#16,#88,#88,#88,#86,#18,#86,#11, #11,#11,#68,#88,#88,#88,#88,#61,#86,#11, #11,#16,#88,#88,#88,#88,#88,#86,#66,#11, #11,#68,#88,#88,#88,#88,#88,#88,#11,#11
;4
db #11,#16,#11,#11,#11,#11,#11,#11,#11,#66, #11,#18,#61,#11,#11,#11,#11,#11,#16,#81, #11,#18,#86,#11,#11,#11,#11,#11,#18,#81, #11,#18,#88,#11,#11,#11,#11,#16,#88,#81, #11,#18,#88,#61,#11,#11,#11,#16,#88,#81
db #11,#68,#88,#61,#11,#11,#11,#18,#88,#81, #11,#18,#88,#61,#11,#11,#11,#18,#88,#81, #11,#68,#88,#61,#11,#11,#11,#18,#88,#61, #11,#68,#88,#61,#11,#11,#11,#18,#88,#61, #11,#68,#88,#11,#11,#11,#11,#18,#88,#61
db #11,#18,#81,#88,#88,#88,#88,#81,#88,#11, #11,#16,#18,#88,#88,#88,#88,#88,#11,#11, #11,#11,#68,#88,#88,#88,#88,#86,#11,#11, #11,#11,#16,#88,#88,#88,#88,#61,#86,#11, #11,#11,#11,#11,#11,#11,#11,#16,#88,#11
db #11,#11,#11,#11,#11,#11,#11,#68,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11
db #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#11,#11,#11,#11,#11,#68,#86,#11, #11,#11,#11,#11,#11,#11,#11,#16,#86,#11, #11,#11,#11,#11,#11,#11,#11,#11,#86,#11, #11,#11,#11,#11,#11,#11,#11,#11,#16,#11
;5
db #11,#11,#68,#88,#88,#88,#88,#88,#88,#61, #11,#18,#16,#88,#88,#88,#88,#88,#81,#11, #11,#18,#81,#88,#88,#88,#88,#88,#11,#11, #11,#18,#86,#18,#88,#88,#88,#81,#11,#11, #11,#18,#88,#61,#11,#11,#11,#11,#11,#11
db #11,#18,#88,#61,#11,#11,#11,#11,#11,#11, #11,#68,#88,#61,#11,#11,#11,#11,#11,#11, #11,#68,#88,#61,#11,#11,#11,#11,#11,#11, #11,#68,#88,#61,#11,#11,#11,#11,#11,#11, #11,#68,#88,#11,#11,#11,#11,#11,#11,#11
db #11,#18,#66,#88,#88,#88,#88,#81,#11,#11, #11,#16,#18,#88,#88,#88,#88,#88,#11,#11, #11,#11,#68,#88,#88,#88,#88,#86,#11,#11, #11,#11,#16,#88,#88,#88,#88,#61,#66,#11, #11,#11,#11,#11,#11,#11,#11,#18,#88,#11
db #11,#11,#11,#11,#11,#11,#11,#68,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#11,#11,#11,#11,#11,#88,#86,#11
db #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#16,#88,#88,#88,#86,#18,#86,#11, #11,#11,#68,#88,#88,#88,#88,#61,#86,#11, #11,#16,#88,#88,#88,#88,#88,#86,#66,#11, #11,#68,#88,#88,#88,#88,#88,#88,#11,#11
;6
db #11,#11,#68,#88,#88,#88,#88,#88,#88,#61, #11,#18,#16,#88,#88,#88,#88,#88,#81,#11, #11,#18,#81,#88,#88,#88,#88,#88,#11,#11, #11,#18,#86,#18,#88,#88,#88,#81,#11,#11, #11,#18,#88,#61,#11,#11,#11,#11,#11,#11
db #11,#18,#88,#61,#11,#11,#11,#11,#11,#11, #11,#68,#88,#61,#11,#11,#11,#11,#11,#11, #11,#68,#88,#61,#11,#11,#11,#11,#11,#11, #11,#68,#88,#61,#11,#11,#11,#11,#11,#11, #11,#68,#88,#11,#11,#11,#11,#11,#11,#11
db #11,#18,#66,#88,#88,#88,#88,#81,#11,#11, #11,#16,#18,#88,#88,#88,#88,#88,#11,#11, #11,#11,#68,#88,#88,#88,#88,#86,#11,#11, #11,#18,#16,#88,#88,#88,#88,#61,#66,#11, #11,#88,#81,#11,#11,#11,#11,#18,#88,#11
db #11,#88,#86,#11,#11,#11,#11,#68,#88,#11, #11,#88,#86,#11,#11,#11,#11,#88,#88,#11, #16,#88,#86,#11,#11,#11,#11,#88,#88,#11, #16,#88,#86,#11,#11,#11,#11,#88,#86,#11, #16,#88,#86,#11,#11,#11,#11,#88,#86,#11
db #16,#88,#81,#11,#11,#11,#11,#88,#86,#11, #16,#88,#16,#88,#88,#88,#86,#18,#86,#11, #16,#81,#68,#88,#88,#88,#88,#61,#86,#11, #16,#16,#88,#88,#88,#88,#88,#86,#66,#11, #11,#68,#88,#88,#88,#88,#88,#88,#11,#11
;7
db #11,#11,#68,#88,#88,#88,#88,#88,#88,#61, #11,#11,#16,#88,#88,#88,#88,#88,#86,#61, #11,#11,#11,#88,#88,#88,#88,#88,#16,#86, #11,#11,#11,#18,#88,#88,#88,#81,#68,#81, #11,#11,#11,#11,#11,#11,#11,#16,#88,#81
db #11,#11,#11,#11,#11,#11,#11,#18,#88,#81, #11,#11,#11,#11,#11,#11,#11,#18,#88,#81, #11,#11,#11,#11,#11,#11,#11,#18,#88,#61, #11,#11,#11,#11,#11,#11,#11,#18,#88,#61, #11,#11,#11,#11,#11,#11,#11,#18,#88,#61
db #11,#11,#11,#11,#11,#11,#11,#11,#88,#11, #11,#11,#11,#11,#11,#11,#11,#11,#11,#11, #11,#11,#11,#11,#11,#11,#11,#11,#11,#11, #11,#11,#11,#11,#11,#11,#11,#11,#66,#11, #11,#11,#11,#11,#11,#11,#11,#18,#88,#11
db #11,#11,#11,#11,#11,#11,#11,#68,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11
db #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#11,#11,#11,#11,#11,#68,#86,#11, #11,#11,#11,#11,#11,#11,#11,#16,#86,#11, #11,#11,#11,#11,#11,#11,#11,#11,#86,#11, #11,#11,#11,#11,#11,#11,#11,#11,#16,#11
;8
db #11,#11,#68,#88,#88,#88,#88,#88,#88,#61, #11,#18,#16,#88,#88,#88,#88,#88,#86,#61, #11,#18,#81,#88,#88,#88,#88,#88,#16,#86, #11,#18,#86,#18,#88,#88,#88,#81,#68,#81, #11,#18,#88,#61,#11,#11,#11,#16,#88,#81
db #11,#18,#88,#61,#11,#11,#11,#18,#88,#81, #11,#68,#88,#61,#11,#11,#11,#18,#88,#81, #11,#68,#88,#61,#11,#11,#11,#18,#88,#61, #11,#68,#88,#61,#11,#11,#11,#18,#88,#61, #11,#68,#88,#11,#11,#11,#11,#18,#88,#61
db #11,#18,#66,#88,#88,#88,#88,#81,#88,#11, #11,#16,#18,#88,#88,#88,#88,#88,#11,#11, #11,#11,#68,#88,#88,#88,#88,#86,#11,#11, #11,#18,#16,#88,#88,#88,#88,#61,#86,#11, #11,#88,#81,#11,#11,#11,#11,#18,#88,#11
db #11,#88,#86,#11,#11,#11,#11,#68,#88,#11, #11,#88,#86,#11,#11,#11,#11,#88,#88,#11, #16,#88,#86,#11,#11,#11,#11,#88,#88,#11, #16,#88,#86,#11,#11,#11,#11,#88,#86,#11, #16,#88,#86,#11,#11,#11,#11,#88,#86,#11
db #16,#88,#81,#11,#11,#11,#11,#88,#86,#11, #16,#88,#16,#88,#88,#88,#86,#18,#86,#11, #16,#81,#68,#88,#88,#88,#88,#61,#86,#11, #16,#16,#88,#88,#88,#88,#88,#86,#66,#11, #11,#68,#88,#88,#88,#88,#88,#88,#11,#11
;9
db #11,#11,#68,#88,#88,#88,#88,#88,#88,#61, #11,#16,#16,#88,#88,#88,#88,#88,#86,#61, #11,#18,#81,#88,#88,#88,#88,#88,#16,#86, #11,#18,#86,#18,#88,#88,#88,#81,#68,#81, #11,#18,#88,#61,#11,#11,#11,#16,#88,#81
db #11,#18,#88,#61,#11,#11,#11,#18,#88,#81, #11,#68,#88,#61,#11,#11,#11,#18,#88,#81, #11,#68,#88,#61,#11,#11,#11,#18,#88,#61, #11,#68,#88,#61,#11,#11,#11,#18,#88,#61, #11,#68,#88,#11,#11,#11,#11,#18,#88,#61
db #11,#18,#66,#88,#88,#88,#88,#81,#88,#11, #11,#16,#18,#88,#88,#88,#88,#88,#11,#11, #11,#11,#68,#88,#88,#88,#88,#86,#11,#11, #11,#11,#16,#88,#88,#88,#88,#61,#86,#11, #11,#11,#11,#11,#11,#11,#11,#18,#88,#11
db #11,#11,#11,#11,#11,#11,#11,#68,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#88,#11, #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#11,#11,#11,#11,#11,#88,#86,#11
db #11,#11,#11,#11,#11,#11,#11,#88,#86,#11, #11,#11,#16,#88,#88,#88,#86,#18,#86,#11, #11,#11,#68,#88,#88,#88,#88,#61,#86,#11, #11,#16,#88,#88,#88,#88,#88,#86,#66,#11, #11,#68,#88,#88,#88,#88,#88,#88,#11,#11

digclnbmp db 4,8,15:dw $+7:dw $+4,4*15:db 5
db #11,#11,#88,#86, #11,#16,#88,#86, #11,#16,#88,#86, #11,#16,#88,#86, #11,#11,#11,#11
db #11,#11,#11,#11, #11,#11,#11,#11, #11,#11,#11,#11, #11,#11,#11,#11, #11,#11,#11,#11
db #11,#11,#11,#11, #11,#88,#86,#11, #16,#88,#86,#11, #16,#88,#86,#11, #16,#88,#86,#11

wkdtxt0 db "MO",0
wkdtxt1 db "TU",0
wkdtxt2 db "WE",0
wkdtxt3 db "TH",0
wkdtxt4 db "FR",0
wkdtxt5 db "SA",0
wkdtxt6 db "SU",0

timdayz db 0
timday0 db "AM",0
timday1 db "PM",0

datdsptxt   db "01/01/2015",0

configtit   db "Digital Clock Setup",0
configtxt0a db "Settings",0
configtxt0b db "About",0
configtxt0c db "Digital Clock Desktop Widget for SymbOS",0
configtxt0d db "(c)2015 by Prodatron/SymbiosiS",0
configtxt1  db "Time format",0
configtxt1a db "12 hours",0
configtxt1b db "24 hours",0
configtxt2  db "Date format",0
configtxt2a db "mm/dd/yyyy",0
configtxt2b db "dd.mm.yyyy",0

prgtxtok    db "OK",0
prgtxtcnc   db "Cancel",0


;==============================================================================
;### TRANSFER AREA ############################################################
;==============================================================================

App_BegTrns
;### PRGPRZS -> stack for application process
        ds 128
prgstk  ds 6*2
        dw prgprz
App_PrcID db 0

;### App_MsgBuf -> message buffer
App_MsgBuf ds 14

;### WIDGET CONTROL COLLECTION ################################################

wdgobjsup   dw wdggrpwin0,1000,1000,0,0,0

timdayctl   dw timday0,16*6+1+32768+16384
datdspctl   dw datdsptxt,16*6+1+32768+16384+256

timwkdct0   dw wkdtxt0,16*7+1+32768
timwkdct1   dw wkdtxt1,16*7+1+32768
timwkdct2   dw wkdtxt2,16*6+1+32768
timwkdct3   dw wkdtxt3,16*7+1+32768
timwkdct4   dw wkdtxt4,16*7+1+32768
timwkdct5   dw wkdtxt5,16*7+1+32768
timwkdct6   dw wkdtxt6,16*7+1+32768

wdggrpwin0  db 7,0:dw wdgdatwin0,0,0,00*256+00,0,0,00
wdgdatwin0
dw 00,255*256+ 0, 128+1,      0, 0,1000,1000,0
dw 00,255*256+ 2,256*255+128, 1, 1,  97,  31,0      ;frame
dw 00,255*256+10,digfnthd0,  03, 4,  20,  25,0      ;hour
dw 00,255*256+10,digfnthd1,  23, 4,  20,  25,0
dw 00,255*256+10,digclnbmp,  45, 9,   8,  21,0
dw 00,255*256+10,digfnthd2,  55, 4,  20,  25,0      ;minute
dw 00,255*256+10,digfnthd3,  75, 4,  20,  25,0

wdggrpwin1  db 9,0:dw wdgdatwin1,0,0,00*256+00,0,0,00
wdgdatwin1
dw 00,255*256+ 0, 128+1,      0, 0,1000,1000,0
dw 00,255*256+ 2,256*255+128, 1, 1,  97,  42,0      ;frame
dw 00,255*256+ 1,timdayctl,  06,04,  12,   8,0      ;am/pm
dw 00,255*256+ 1,datdspctl,  43,04,  50,   8,0      ;date
dw 00,255*256+10,digfnthd0,  03,14,  20,  25,0      ;hour
dw 00,255*256+10,digfnthd1,  23,14,  20,  25,0
dw 00,255*256+10,digclnbmp,  45,19,   8,  21,0
dw 00,255*256+10,digfnthd2,  55,14,  20,  25,0      ;minute
dw 00,255*256+10,digfnthd3,  75,14,  20,  25,0

wdggrpwin2  db 14,0:dw wdgdatwin2,0,0,00*256+00,0,0,00
wdgdatwin2
dw 00,255*256+ 0, 128+1,      0, 0,1000,1000,0
dw 00,255*256+ 2,256*255+128, 1, 1,  97,  42,0      ;frame
dw 00,255*256+10,digfnthd0,  03, 5,  20,  25,0      ;hour
dw 00,255*256+10,digfnthd1,  23, 5,  20,  25,0
dw 00,255*256+10,digclnbmp,  45,10,   8,  21,0
dw 00,255*256+10,digfnthd2,  55, 5,  20,  25,0      ;minute
dw 00,255*256+10,digfnthd3,  75, 5,  20,  25,0
dw 00,255*256+ 1,timwkdct0,  06,32,  10,   8,0      ;mo
dw 00,255*256+ 1,timwkdct1,  19,32,  10,   8,0      ;tu
dw 00,255*256+ 1,timwkdct2,  32,32,  10,   8,0      ;we
dw 00,255*256+ 1,timwkdct3,  45,32,  10,   8,0      ;th
dw 00,255*256+ 1,timwkdct4,  58,32,  10,   8,0      ;fr
dw 00,255*256+ 1,timwkdct5,  71,32,  10,   8,0      ;sa
dw 00,255*256+ 1,timwkdct6,  84,32,  10,   8,0      ;su

wdggrpwin3  db 16,0:dw wdgdatwin3,0,0,00*256+00,0,0,00
wdgdatwin3
dw 00,255*256+ 0, 128+1,      0, 0,1000,1000,0
dw 00,255*256+ 2,256*255+128, 1, 1,  97,  51,0      ;frame
dw 00,255*256+ 1,timdayctl,  06,04,  12,   8,0      ;am/pm
dw 00,255*256+ 1,datdspctl,  43,04,  50,   8,0      ;date
dw 00,255*256+10,digfnthd0,  03,14,  20,  25,0      ;hour
dw 00,255*256+10,digfnthd1,  23,14,  20,  25,0
dw 00,255*256+10,digclnbmp,  45,19,   8,  21,0
dw 00,255*256+10,digfnthd2,  55,14,  20,  25,0      ;minute
dw 00,255*256+10,digfnthd3,  75,14,  20,  25,0
dw 00,255*256+ 1,timwkdct0,  06,41,  10,   8,0      ;mo
dw 00,255*256+ 1,timwkdct1,  19,41,  10,   8,0      ;tu
dw 00,255*256+ 1,timwkdct2,  32,41,  10,   8,0      ;we
dw 00,255*256+ 1,timwkdct3,  45,41,  10,   8,0      ;th
dw 00,255*256+ 1,timwkdct4,  58,41,  10,   8,0      ;fr
dw 00,255*256+ 1,timwkdct5,  71,41,  10,   8,0      ;sa
dw 00,255*256+ 1,timwkdct6,  84,41,  10,   8,0      ;su

wdggrpwin4  db 10,0:dw wdgdatwin4,0,0,00*256+00,0,0,00
wdgdatwin4
dw 00,255*256+ 0, 128+1,      0, 0,1000,1000,0
dw 00,255*256+ 2,256*255+128, 1, 1, 149,  31,0      ;frame
dw 00,255*256+10,digfnthd0,  03, 4,  20,  25,0      ;hour
dw 00,255*256+10,digfnthd1,  23, 4,  20,  25,0
dw 00,255*256+10,digclnbmp,  45, 9,   8,  21,0
dw 00,255*256+10,digfnthd2,  55, 4,  20,  25,0      ;minute
dw 00,255*256+10,digfnthd3,  75, 4,  20,  25,0
dw 00,255*256+10,digclnbmp,  97, 9,   8,  21,0
dw 00,255*256+10,digfnthd4, 107, 4,  20,  25,0      ;second
dw 00,255*256+10,digfnthd5, 127, 4,  20,  25,0

wdggrpwin5  db 12,0:dw wdgdatwin5,0,0,00*256+00,0,0,00
wdgdatwin5
dw 00,255*256+ 0, 128+1,      0, 0,1000,1000,0
dw 00,255*256+ 2,256*255+128, 1, 1, 149,  42,0      ;frame
dw 00,255*256+ 1,timdayctl,  06,04,  12,   8,0      ;am/pm
dw 00,255*256+ 1,datdspctl,  95,04,  50,   8,0      ;date
dw 00,255*256+10,digfnthd0,  03,14,  20,  25,0      ;hour
dw 00,255*256+10,digfnthd1,  23,14,  20,  25,0
dw 00,255*256+10,digclnbmp,  45,19,   8,  21,0
dw 00,255*256+10,digfnthd2,  55,14,  20,  25,0      ;minute
dw 00,255*256+10,digfnthd3,  75,14,  20,  25,0
dw 00,255*256+10,digclnbmp,  97,19,   8,  21,0
dw 00,255*256+10,digfnthd4, 107,14,  20,  25,0      ;second
dw 00,255*256+10,digfnthd5, 127,14,  20,  25,0

wdggrpwin6  db 17,0:dw wdgdatwin6,0,0,00*256+00,0,0,00
wdgdatwin6
dw 00,255*256+ 0, 128+1,      0, 0,1000,1000,0
dw 00,255*256+ 2,256*255+128, 1, 1, 149,  42,0      ;frame
dw 00,255*256+10,digfnthd0,  03, 5,  20,  25,0      ;hour
dw 00,255*256+10,digfnthd1,  23, 5,  20,  25,0
dw 00,255*256+10,digclnbmp,  45,10,   8,  21,0
dw 00,255*256+10,digfnthd2,  55, 5,  20,  25,0      ;minute
dw 00,255*256+10,digfnthd3,  75, 5,  20,  25,0
dw 00,255*256+10,digclnbmp,  97,10,   8,  21,0
dw 00,255*256+10,digfnthd4, 107, 5,  20,  25,0      ;second
dw 00,255*256+10,digfnthd5, 127, 5,  20,  25,0
dw 00,255*256+ 1,timwkdct0,  08,32,  10,   8,0      ;mo
dw 00,255*256+ 1,timwkdct1,  29,32,  10,   8,0      ;tu
dw 00,255*256+ 1,timwkdct2,  50,32,  10,   8,0      ;we
dw 00,255*256+ 1,timwkdct3,  71,32,  10,   8,0      ;th
dw 00,255*256+ 1,timwkdct4,  92,32,  10,   8,0      ;fr
dw 00,255*256+ 1,timwkdct5, 113,32,  10,   8,0      ;sa
dw 00,255*256+ 1,timwkdct6, 134,32,  10,   8,0      ;su

wdggrpwin7  db 19,0:dw wdgdatwin7,0,0,00*256+00,0,0,00
wdgdatwin7
dw 00,255*256+ 0, 128+1,      0, 0,1000,1000,0
dw 00,255*256+ 2,256*255+128, 1, 1, 149,  51,0      ;frame
dw 00,255*256+ 1,timdayctl,  06,04,  12,   8,0      ;am/pm
dw 00,255*256+ 1,datdspctl,  95,04,  50,   8,0      ;date
dw 00,255*256+10,digfnthd0,  03,14,  20,  25,0      ;hour
dw 00,255*256+10,digfnthd1,  23,14,  20,  25,0
dw 00,255*256+10,digclnbmp,  45,19,   8,  21,0
dw 00,255*256+10,digfnthd2,  55,14,  20,  25,0      ;minute
dw 00,255*256+10,digfnthd3,  75,14,  20,  25,0
dw 00,255*256+10,digclnbmp,  97,19,   8,  21,0
dw 00,255*256+10,digfnthd4, 107,14,  20,  25,0      ;second
dw 00,255*256+10,digfnthd5, 127,14,  20,  25,0
dw 00,255*256+ 1,timwkdct0,  08,41,  10,   8,0      ;mo
dw 00,255*256+ 1,timwkdct1,  29,41,  10,   8,0      ;tu
dw 00,255*256+ 1,timwkdct2,  50,41,  10,   8,0      ;we
dw 00,255*256+ 1,timwkdct3,  71,41,  10,   8,0      ;th
dw 00,255*256+ 1,timwkdct4,  92,41,  10,   8,0      ;fr
dw 00,255*256+ 1,timwkdct5, 113,41,  10,   8,0      ;sa
dw 00,255*256+ 1,timwkdct6, 134,41,  10,   8,0      ;su

;### PROPERTIES ###############################################################

configwin   dw #1501,0,059,035,192,85,0,0,192,85,192,85,192,85,prgicnsml,configtit,0,0,configgrp,0,0:ds 136+14
configgrp   db 13,0:dw configdat,0,0,256*13+12,0,0,00
configdat
dw      00,         0,2,          0,0,1000,1000,0       ;00=Hintergrund
dw      00,255*256+ 3,configdsc0a,00, 01,192,35,0       ;01=Rahmen "Settings"
dw      00,255*256+ 1,configdsc1, 08, 11, 54, 8,0       ;02=Beschreibung "Time format"
dw      00,255*256+18,configrad1a,62, 11, 20, 8,0       ;03=Radio 12h
dw      00,255*256+18,configrad1b,130,11, 20, 8,0       ;04=Radio 24h
dw      00,255*256+ 1,configdsc2, 08, 21, 54, 8,0       ;05=Beschreibung "Date format"
dw      00,255*256+18,configrad2a,62, 21, 20, 8,0       ;06=Radio mm/dd/yyyy
dw      00,255*256+18,configrad2b,130,21, 20, 8,0       ;07=Radio dd.mm.yyyy
dw      00,255*256+ 3,configdsc0b,00, 35,192,35,0       ;08=Rahmen "Misc"
dw      00,255*256+ 1,configdsc0c,08, 45,144, 8,0       ;09=Beschreibung "About 1"
dw      00,255*256+ 1,configdsc0d,08, 55,144, 8,0       ;10=Beschreibung "About 2"
dw wdgprp1,255*256+16,prgtxtok,   91, 70, 48,12,0       ;11="Ok"    -Button
dw wdgprp0,255*256+16,prgtxtcnc, 141, 70, 48,12,0       ;12="Cancel"-Button

configdsc0a dw configtxt0a,2+4
configdsc0b dw configtxt0b,2+4
configdsc0c dw configtxt0c,2+4
configdsc0d dw configtxt0d,2+4

configdsc1  dw configtxt1,2+4
configrad1k ds 4
configrad1a dw cfgtim,configtxt1a,256*0+2+4,configrad1k
configrad1b dw cfgtim,configtxt1b,256*1+2+4,configrad1k

configdsc2  dw configtxt2,2+4
configrad2k ds 4
configrad2a dw cfgdat,configtxt2a,256*0+2+4,configrad2k
configrad2b dw cfgdat,configtxt2b,256*1+2+4,configrad2k

cfgtim  db 0
cfgdat  db 0
