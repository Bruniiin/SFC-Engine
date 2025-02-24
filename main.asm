.include "header.asm"
.include "init.asm"
.include "program_engine.asm"
.include "graphics_engine.asm"
.include "nmi.asm"
.include "dma.asm"
.include "defines.asm"
.include "registers.asm"
.include "encodeddata.asm"
.include "test_program.asm"
.define using_HIROM 0 ; SNESDEV requires lorom

.ifdef using_HIROM
    .bank $C0
    .segment "MAIN_hi"
    .else
        .bank $80
        .segment "MAIN_lo"
.endif


Main:
    Main
    InitEngine
    FetchProgram
    ; phk
    ; plb
    jml ($000000)

.MACRO Main
    phk
    plb
    nop
    nop
    nop
    clc
    xce
    sei
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
    php
    lda #0
    sta v_arg001
    jsr ClearScreen
    lda INIDISP
    and #$0F
    sta INIDISP
    lda boot_start
    sta v_loop001
    sta w_var001

    ; for (i = 0; i < v_loop001; i++) {
    ;   RenderText(boot_title, i_text_index, i_text_hor, i_text_ver);
    ;   init_text_ver += 4;
    ;   init_text_index++; }
    ldy #0
    stz init_text_index
    lda boot_title+1
    sta v_arg001
    lda #0
    sta v_arg003 
    sta v_arg004
    .loop:
    lda init_text_index
    sta v_arg002
    lda init_text_hor
    sta v_arg004
    lda init_text_ver
    sta v_arg005
    jsr RenderString 
    lda init_text_ver
    adc pos_y_offset
    sta init_text_ver
    inc init_text_index
    iny
    cpy v_loop001
    bne .loop

    cli
    per $8
    pla 
    sta $09
    pla 
    sta $08
    ; if (input_hi & 0x08 | BUTTON_DOWN) {
    ; pointer_y += pointer_y_offset;
    ; pointer++; }
    ; if (input_hi & 0x04 | BUTTON_UP) {
    ; pointer_y -= pointer_y_offset;
    ; pointer--; }
    init_CheckInput:
    lda input_hi
    and #%00001000
    bne +
    lda pointer
    cmp w_var001
    beq +
    lda pointer_y
    clc
    adc pos_y_offset
    sta pointer_y
    inc pointer
  + lda input_hi
    and #%00000100
    bne +
    lda pointer
    beq +
    lda pointer_y
    sec
    sbc pos_y_offset
    sta pointer_y
    dec pointer

    ; RenderUi(pointer_obj, 0, pointer_x, pointer_y)
  + lda pointer_obj
    sta v_arg001
    lda pointer_x
    sta v_arg002
    lda pointer_y
    sta v_arg003
    jsr RenderUi

    ; if (input_hi & 0x80) {
    ; ... }
    ; else {
    ; engine_wait() }
    init_StartProgram:
    lda input_hi
    and #%10000000
    bne engine_wait
    sei
    plp
.ENDMACRO

engine_wait: 
    stz vblanking_done
engine_wait_loop:
    lda vblanking_done
    beq engine_wait_loop
    jmp ($0008)

.MACRO FetchProgram
    ; i = pointer * address_size
    ; address = boot_address[i]
    sep #$38
    lda #0
    tcd
    lda pointer
    sta WRMPYA 
    lda #3
    sta WRMPYB
    nop
    nop
    lda RDMPYL
    tay
    iny
    lda boot_address, y
    sta $00
    iny
    lda boot_address, y
    sta $01
    ; iny 
    ; lda boot_address, y
    ; sta $00+2
    lda #0
    sta v_arg001
    jsr ClearScreen
      ;   php
      ;   sep #$38
      ;   lda #0
      ;   tcd
      ;   nop
      ;   ldy #ff
      ; - iny
      ;   cpy #$ff
      ;   beq +
      ;   lda boot, y
      ;   cmp #$79
      ;   bcc -
      ;   sta $00
      ;   iny
      ;   lda boot, y
      ;   sta $00+1
      ;   bra .return
      ; + stp
      ;   .return:
      ;   plp
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

        ;   lda pos_x
        ;   sta TILE_RENDER_QUEUE, y
        ; - iny
        ;   lda pos_y
        ;  sta TILE_RENDER_QUEUE, y

        ; sta TILE_RENDER_QUEUE, y 
        ; iny
        ; lda boot, y 
        ; cmp #%
        ; bne -
        ; lda pos_y
        ; adc #pos_y_offset
        ; sta pos_y
        ; inx
        ; cpx v_loop001
        ; bne -
        ; cli