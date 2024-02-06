; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

#include   ../macros.inc
#include   ../bios.inc
#include   ../kernel.inc

              org     2000h

              extrn   itoa32

begin:        br      start
              eever
              db      'Written by Michael H. Riley',0

start:        mov       rf,0400h       ; get Elf/OS version
              ldn       rf
              smi       5              ; must be 5+
              lbdf      start2         ; jump if valid version
              call      o_inmsg        ; display error
              db        'Requires Elf/OS 5+',10,13,0
              ldi       014h           ; set return code to invalid version
              rtn                      ; return to caller

; **********************************
; ***** Display kernel version *****
; **********************************
start2:       call      o_inmsg        ; display label
              db        'kernel      : ',0
              mov       rf,0400h       ; point to kernel version
              mov       ra,int32       ; point to integer storage
              lda       rf             ; get major version number
              str       ra
              inc       ra
              ldi       0              ; next 3 bytes of integer will be 0
              str       ra
              inc       ra
              str       ra
              inc       ra
              str       ra
              mov       rf,int32       ; point to integer
              mov       rd,buffer      ; where to put conversion
              call      itoa32         ; convert number
              mov       rf,buffer      ; display number
              call      o_msg
              ldi       '.'            ; now display a dot
              call      o_type
              mov       rf,0401h       ; point to kernel version
              mov       ra,int32       ; point to integer storage
              lda       rf             ; get major version number
              str       ra
              mov       rf,int32       ; point to integer
              mov       rd,buffer      ; where to put conversion
              call      itoa32         ; convert number
              mov       rf,buffer      ; display number
              call      o_msg
              ldi       '.'            ; now display a dot
              call      o_type
              mov       rf,0402h       ; point to kernel version
              mov       ra,int32       ; point to integer storage
              lda       rf             ; get major version number
              str       ra
              mov       rf,int32       ; point to integer
              mov       rd,buffer      ; where to put conversion
              call      itoa32         ; convert number
              mov       rf,buffer      ; display number
              call      o_msg
              call      o_inmsg        ; display 'build'
              db        ' Build ',0
              mov       rf,0404h       ; point to kernel build lsb
              mov       ra,int32       ; point to int32
              ldn       rf             ; get lsb of build
              str       ra             ; write to int32
              dec       rf             ; move to msb
              inc       ra
              ldn       rf             ; get msb
              str       ra             ; int32 now has full build
              mov       rf,int32       ; point to integer
              mov       rd,buffer      ; where to put ascii
              call      itoa32         ; convert number
              mov       rf,buffer      ; now display it
              call      o_msg
              call      o_inmsg        ; display cr/lf
              db        10,13,0

; ********************************
; ***** Display boot version *****
; ********************************
              ldi       0              ; need to read sector 0
              plo       r7
              phi       r7
              plo       r8
              ldi       0e0h
              phi       r8
              mov       rf,dta
              call      f_ideread
              ldi       (dta+087h).0
              plo       rf             ; point to build number
              ldi       (dta+087h).1
              phi       rf
              mov       ra,int32+1     ; point to msb of int32
              lda       rf             ; retrieve build number
              str       ra
              dec       ra
              ldn       rf
              str       ra
              call      o_inmsg        ; display label
              db        'Boot        : Build ',0
              mov       rf,int32       ; convert build number to ascii
              mov       rd,buffer
              call      itoa32
              mov       rf,buffer      ; then display it
              call      o_msg
              call      o_inmsg
              db        ' / ',0
              ldi       2              ; need to read sector 2
              plo       r7
              ldi       0
              phi       r7
              plo       r8
              ldi       0e0h
              phi       r8
              mov       rf,dta
              call      f_ideread
              ldi       (dta+01f7h).0
              plo       rf             ; point to build number
              ldi       (dta+01f7h).1
              phi       rf
              mov       ra,int32+1     ; point to msb of int32
              lda       rf             ; retrieve build number
              str       ra
              dec       ra
              ldn       rf
              str       ra
              mov       rf,int32       ; convert build number to ascii
              mov       rd,buffer
              call      itoa32
              mov       rf,buffer      ; then display it
              call      o_msg
              call      o_inmsg        ; display cr/lf
              db        10,13,0

; **************************
; ***** Display fstype *****
; **************************
              ldi       0              ; need to read sector 0
              plo       r7
              phi       r7
              plo       r8
              ldi       0e0h
              phi       r8
              mov       rf,dta
              call      f_ideread
              call      o_inmsg        ; display label
              db        'Filesystem  : ',0
              mov       rf,dta+104h    ; point to fstype
              mov       ra,fstype      ; will want to keep
              lda       rf             ; retrieve filesystem type
              str       ra             ; keep it
              smi       1              ; see if type I
              lbz       type_I         ; jump if so
              smi       1              ; see if type II
              lbz       type_II        ; jump if so
              call      o_inmsg        ; display unknown type
              db        'Uknown',0
              lbr       next           ; then jump to next section
type_I:       call      o_inmsg        ; display LAT-16
              db        'LAT-16',0
              lbr       next           ; then jump to next section
type_II:      call      o_inmsg        ; display LAT-32
              db        'LAT-32',0
next:         call      o_inmsg        ; display cr/lf
              db        10,13,0

; *************************************
; ***** Display number of sectors *****
; *************************************
              call      o_inmsg        ; display label
              db        'Sectors     : ',0
              mov       rf,dta+100h    ; point to sector count
              mov       ra,int32+3     ; point to int32
              lda       rf             ; transfer count to int32
              str       ra
              dec       ra
              lda       rf
              str       ra
              dec       ra
              lda       rf
              str       ra
              dec       ra
              lda       rf
              str       ra
              mov       rf,int32       ; point to int32
              mov       rd,buffer      ; where to put conversion
              call      itoa32         ; convert to ascii
              mov       rf,buffer      ; and display result
              call      o_msg
              call      o_inmsg        ; display cr/lf
              db        10,13,0

; *********************************
; ***** Display number of AUs *****
; *********************************
              call      o_inmsg        ; display label
              db        'AUs         : ',0
              mov       rf,fstype      ; retreive fstype
              ldn       rf
              smi       1              ; check for type I
              lbz       aus_I          ; jump if so
              smi       1              ; check for type II
              lbz       aus_II         ; jump if so
              call      o_inmsg        ; display unknown
              db        'Unknown',0
              lbr       next2          ; then continue
aus_I:        mov       ra,int32+3     ; point to msb of int 32
              ldi       0              ; high word is zero
              str       ra
              dec       ra
              str       ra
              dec       ra
              mov       rf,dta+10bh    ; point to AU count
              lda       rf             ; and retrieve it
              str       ra             ; into int32
              dec       ra
              ldn       rf
              str       ra
              lbr       aus_disp       ; then convert for display
aus_II:       mov       ra,int32+3     ; point to msb of int32
              mov       rf,dta+10bh    ; point to AU count
              lda       rf             ; and retrieve it
              str       ra
              dec       ra
              lda       rf
              str       ra
              dec       ra
              lda       rf
              str       ra
              dec       ra
              lda       rf
              str       ra
aus_disp:     mov       rf,int32       ; now convert to ascii
              mov       rd,buffer
              call      itoa32
              mov       rf,buffer      ; and display it
              call      o_msg
next2:        call      o_inmsg        ; display cr/lf
              db        10,13,0

; ***********************************
; ***** Dispay MD sector number *****
; ***********************************
              call      o_inmsg        ; display label
              db        'MD Sector   : ',0
              mov       rf,fstype      ; retreive fstype
              ldn       rf
              smi       1              ; check for type I
              lbz       mds_I          ; jump if so
              smi       1              ; check for type II
              lbz       mds_II         ; jump if so
              call      o_inmsg        ; display unknown
              db        'Unknown',0
              lbr       next3          ; then continue
mds_I:        mov       ra,int32+3     ; point to msb of int 32
              ldi       0              ; high word is zero
              str       ra
              dec       ra
              str       ra
              dec       ra
              mov       rf,dta+105h    ; point to MD sector
              lda       rf             ; and retrieve it
              str       ra             ; into int32
              dec       ra
              ldn       rf
              str       ra
              lbr       mds_disp       ; then convert for display
mds_II:       mov       ra,int32+3     ; point to msb of int32
              mov       rf,dta+110h    ; point to MD sector
              lda       rf             ; and retrieve it
              str       ra
              dec       ra
              lda       rf
              str       ra
              dec       ra
              lda       rf
              str       ra
              dec       ra
              lda       rf
              str       ra

mds_disp:     mov       rf,int32       ; now convert to ascii
              mov       rd,buffer
              call      itoa32
              mov       rf,buffer      ; and display it
              call      o_msg
next3:        call      o_inmsg        ; display cr/lf
              db        10,13,0

; ******************************
; ***** Display amount RAM *****
; ******************************
              call      o_inmsg        ; display label
              db        'RAM         : ',0
              mov       ra,03000h      ; where to start testing
ramlp:        ldn       ra             ; get current value in memory cell
              plo       re             ; set it aside
              ldi       0              ; clear the cell
              str       ra
              ldn       ra             ; then retrieve it
              lbnz      rambd          ; jump if not valid result
              ldi       0ffh           ; now set all bits on
              str       ra
              ldn       ra
              smi       0ffh           ; jump if not valid result
              lbnz      rambd          ; jump if not valid result
              glo       re             ; restore original value
              str       ra
              inc       ra             ; point to next address
              glo       ra             ; check for roll
              str       r2
              ghi       ra
              or
              lbnz      ramlp          ; jump if no wraparound
              call      o_inmsg        ; display result
              db        '65536',0
              lbr       next4          ; and continue
rambd:        mov       rc,65000       ; delay size
delay1:       dec       rc             ; decrement delay count
              glo       rc             ; check for zero
              str       r2
              ghi       rc
              or
              lbnz      delay1         ; loop until count complete
              glo       re             ; restore original value
              str       ra
              mov       rc,65000       ; need to delay again
delay2:       dec       rc             ; decrement delay count
              glo       rc             ; check if done
              str       r2
              ghi       rc
              or
              lbnz      delay2         ; loop until done
              mov       rf,int32       ; point to int32
              glo       ra             ; write highest address
              str       rf
              inc       rf
              ghi       ra
              str       rf
              inc       rf
              ldi       0
              str       rf
              inc       rf
              str       rf
              mov       rf,int32       ; now convert o ascii
              mov       rd,buffer
              call      itoa32
              mov       rf,buffer      ; and display it
              call      o_msg
next4:        call      o_inmsg        ; display cr/lf
              db        10,13,0

; ****************************************
; ***** Display value from f_freemem *****
; ****************************************
              call      o_inmsg        ; display label
              db        'f_freemem   : ',0
              call      f_freemem      ; get BIOS freemem
              inc       rf
              mov       ra,int32       ; point to int32
              glo       rf             ; and write freemem value
              str       ra
              inc       ra
              ghi       rf
              str       ra
              inc       ra
              ldi       0              ; high word is zero
              str       ra
              inc       ra
              str       ra
              mov       rf,int32       ; now convert o ascii
              mov       rd,buffer
              call      itoa32
              mov       rf,buffer      ; and display it
              call      o_msg
              call      o_inmsg        ; display cr/lf
              db        10,13,0

; *************************************
; ***** Display beginning of heap *****
; *************************************
              call      o_inmsg        ; display label
              db        'Heap        : $',0
              mov       rf,K_HEAP      ; pointer to heap
              lda       rf             ; retrieve it
              phi       rd             ; into RD
              lda       rf
              plo       rd
              mov       rf,buffer      ; where to put conversion
              call      f_hexout4      ; convert address to hex ascii
              ldi       0              ; terminate string
              str       rf
              mov       rf,buffer      ; point to converted address
              call      o_msg          ; and display it
              call      o_inmsg        ; display cr/lf
              db        10,13,0

; *************************
; ***** Display himem *****
; *************************
              call      o_inmsg        ; display label
              db        'High Mem    : $',0
              mov       rf,K_HIMEM     ; pointer to heap
              lda       rf             ; retrieve it
              phi       rd             ; into RD
              lda       rf
              plo       rd
              mov       rf,buffer      ; where to put conversion
              call      f_hexout4      ; convert address to hex ascii
              ldi       0              ; terminate string
              str       rf
              mov       rf,buffer      ; point to converted address
              call      o_msg          ; and display it
              call      o_inmsg        ; display cr/lf
              db        10,13,0
              

; ********************************
; ***** Display bios version *****
; ********************************
              call      o_inmsg        ; display label
              db        'bios        : ',0
              mov       rf,0fff9h      ; point to bios version
              mov       ra,int32       ; point to integer storage
              lda       rf             ; get major version number
              str       ra
              inc       ra
              ldi       0              ; next 3 bytes of integer will be 0
              str       ra
              inc       ra
              str       ra
              inc       ra
              str       ra
              mov       rf,int32       ; point to integer
              mov       rd,buffer      ; where to put conversion
              call      itoa32         ; convert number
              mov       rf,buffer      ; display number
              call      o_msg
              ldi       '.'            ; now display a dot
              call      o_type
              mov       rf,0fffah      ; point to bios version
              mov       ra,int32       ; point to integer storage
              lda       rf             ; get major version number
              str       ra
              mov       rf,int32       ; point to integer
              mov       rd,buffer      ; where to put conversion
              call      itoa32         ; convert number
              mov       rf,buffer      ; display number
              call      o_msg
              ldi       '.'            ; now display a dot
              call      o_type
              mov       rf,0fffbh      ; point to bios version
              mov       ra,int32       ; point to integer storage
              lda       rf             ; get major version number
              str       ra
              mov       rf,int32       ; point to integer
              mov       rd,buffer      ; where to put conversion
              call      itoa32         ; convert number
              mov       rf,buffer      ; display number
              call      o_msg
              call      o_inmsg        ; display cr/lf
              db        10,13,0

; *************************************
; ***** Display installed devices *****
; *************************************
              call      f_getdev       ; get devices from BIOS
              mov       r7,rf          ; keep a copy
              call      o_inmsg        ; display label
              db        '  IDE       : ',0
              glo       r7             ; check for ide
              ani       1
              lbz       ide_no         ; jump if not
              call      o_inmsg        ; display yes
              db        'Yes',0
              lbr       dev_1
ide_no:       call      o_inmsg        ; display no
              db        'No',0
dev_1:        call      o_inmsg        ; display cr/lf
              db        10,13,0
              call      o_inmsg        ; display label
              db        '  Floppy    : ',0
              glo       r7             ; check for floppy
              ani       2
              lbz       floppy_no      ; jump if not
              call      o_inmsg        ; display yes
              db        'Yes',0
              lbr       dev_2
floppy_no:    call      o_inmsg        ; display no
              db        'No',0
dev_2:        call      o_inmsg        ; display cr/lf
              db        10,13,0
              call      o_inmsg
              db        '  BB Serial : ',0
              glo       r7             ; check for bit banged serial
              ani       4
              lbz       bb_no          ; jump if not
              call      o_inmsg        ; display yes
              db        'Yes',0
              lbr       dev_3
bb_no:        call      o_inmsg        ; display no
              db        'No',0
dev_3:        call      o_inmsg        ; display cr/lf
              db        10,13,0
              call      o_inmsg
              db        '  UART      : ',0
              glo       r7             ; check for UART
              ani       8
              lbz       uart_no        ; jump if not
              call      o_inmsg        ; display yes
              db        'Yes',0
              lbr       dev_4
uart_no:      call      o_inmsg        ; display no
              db        'No',0
dev_4:        call      o_inmsg        ; display cr/lf
              db        10,13,0
              call      o_inmsg
              db        '  RTC       : ',0
              glo       r7             ; check for RTC
              ani       16
              lbz       rtc_no         ; jump if not
              call      o_inmsg        ; display yes
              db        'Yes',0
              lbr       dev_5
rtc_no:       call      o_inmsg        ; display no
              db        'No',0
dev_5:        call      o_inmsg        ; display cr/lf
              db        10,13,0
              call      o_inmsg
              db        '  NVR       : ',0
              glo       r7             ; check for NVR
              ani       32
              lbz       nvr_no         ; jump if not
              call      o_inmsg        ; display yes
              db        'Yes',0
              lbr       dev_6
nvr_no:       call      o_inmsg        ; display no
              db        'No',0
dev_6:        call      o_inmsg        ; display cr/lf
              db        10,13,0
              call      o_inmsg
              db        '  $F800     : ',0
              glo       r7             ; check for F800 vector table
              ani       64
              lbz       f800_no        ; jump if not
              call      o_inmsg        ; display yes
              db        'Yes',0
              lbr       dev_7
f800_no:      call      o_inmsg        ; display no
              db        'No',0
dev_7:        call      o_inmsg        ; display cr/lf
              db        10,13,0
              call      o_inmsg
              db        '  $F000     : ',0
              glo       r7             ; check for F000 vector table
              ani       128
              lbz       f000_no        ; jump if not
              call      o_inmsg        ; display yes
              db        'Yes',0
              lbr       dev_8
f000_no:      call      o_inmsg        ; display no
              db        'No',0
dev_8:        call      o_inmsg        ; display cr/lf
              db        10,13,0


              ldi       0              ; set return value
              rtn                      ; return to caller



dirent:    dw      0
eof:       dw      0
fstype:    db      0
int32:     dw      0,0
buffer:    ds      32
           db      0
dta:       ds      512
           db      0

           end     begin
