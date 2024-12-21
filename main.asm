.include "header.asm"
.include "init.asm"
.include "program_engine.asm"
.include "graphics_engine.asm"
.include "nmi.asm"
.include "dma.asm"
.include "defines.asm"
.include "registers.asm"
.include "encodeddata.asm"
.define using_HIROM 0 ; SNESDEV requires lorom

.ifdef using_HIROM
    .segment "MAIN_hi"
.endif
    .else
        .segment "MAIN_lo"

Main:
    Main
    InitEngine
    FetchProgram
    ; phk
    ; plb
    cli
    jml ($0000)

.MACRO Main
    phk
    plb
    nop
    nop
    nop
    sei
    clc
    xce
    cld
    rep #$38
    ldx #$1fff
    txs
    init5a22 ; Main Processor
    init5c77 ; Graphics Processor
    ClrMem 0 0 1    ; WRAM 
    ClrMem 80 0 1   ; VRAM
    ClrMem 0 0 1    ; OAM RAM
    ClrMem 20 200 1 ; CG RAM
.ENDMACRO

.MACRO init5c77
    lda #%10001111
    sta INIDISP
    stz OBSEL
    stz OAMADDL
    stz OAMADDH
    stz OAMDATA
    stz BGMODE
    stz MOSAIC
    stz BG1SC
    stz BG2SC
    stz BG3SC
    stz BG4SC
    stz BG12NBA 
    stz BG34NBA
    stz BG1HOFS
    stz M7HOFS
    stz BG1VOFS
    lda #$ff
    sta M7VOFS
    stz BG2HOFS
    stz BG2VOFS
    stz BG3HOFS
    stz BG3VOFS
    stz BG4HOFS
    stz BG4VOFS
    lda #$80
    sta VMAIN
    stz VMADDL
    stz VMADDH
    stz VMDATAL
    stz VMDATAH
    stz M7SEL
    lda #$01
    sta M7A
    stz M7B
    stz M7C
    stz M7D
    stz M7X
    stz M7Y
    stz CGADD
    stz CGDATA
    stz W12SEL
    stz W34SEL
    stz WOBJSEL
    stz WH0
    stz WH1
    stz WH2
    stz WH3 
    stz WBGLOG
    stz WOBJLOG
    stz TM
    stz TS
    stz TMW
    stz TSW
    stz CGWSEL
    stz CGADSUB
    stz COLDATA
    stz SETINI  
.ENDMACRO

.MACRO init5a22
    stz NMITIMEN
    lda #$ff
    sta WRIO
    stz WRMPYA
    stz WRMPYB
    stz WRDIVL
    stz WRDIVH
    stz WRDIVB
    stz HTIMEL
    stz HTIMEH 
    stz VTIMEL
    stz VTIMEH
    stz MDMAEN
    stz HDMAEN
    stz MEMSEL
.ENDMACRO

.MACRO InitEngine
.ENDMACRO

.MACRO FetchProgram
    php
    sep #$38
    lda #0
    tcd
    nop
    ldy #ff
  - iny
    cpy #$ff
    beq +
    lda boot, y
    cmp #$80
    bcc -
    sta $00
    iny
    lda boot, y
    sta $00+1
    bra .return
  + stp
    .return
    plp
.ENDMACRO

.MACRO ClrMem start_8, size_16, bus
    php
    lda #$80
    sta VMAIN
    stz VMADDL
    stz WMADDL
    stz WMADDM
    lda start_8
    sta BBADx 
    lda size_16
    sta DASxL
    stz DMAPx 
    stz A1TxL
    stz A1TxH
    stz A1Bx
    lda #1
    sta MDMAEN
    plp
.ENDMACRO

setRegisterSize:
    cmp #16
    beq +
    sep #$20
    bra ++
  + rep #$20
 ++ cpy #16
    beq +++
    sep #$18
    bra .return
+++ rep #$18
    .return:
    rts

