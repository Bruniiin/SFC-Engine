.bank $F0
.org $C000

NMI: ; internal to engine, not meant to be modified
    phb
    pha
    phx
    phy

    lda vblank_wait
    beq skip_frame
    stz vblank_wait
    lda INIDISP_mirror
    and #%00001111
    sta INIDISP
    lda SETINI_mirror
    sta SETINI
    lda VMAIN_mirror
    sta VMAIN
    lda TM_mirror
    ldx TS_mirror
    sta TM
    stx TS
    lda TMW_mirror  
    ldx TSW_mirror  
    sta TMW
    stx TSW
    lda WBGLOG_mirror
    ldx WOBJLOG_mirror 
    sta WBGLOG
    stx WOBJLOG
    lda BGMODE_mirror
    sta BGMODE
    and #$0F
    cmp #7
    beq m7_handler ; branches to execute Mode 7 related code
    bra +

  + jsr PushDataToVRAM
    jsr PushDataToCGRAM
    jsr PushVRAMDataToScreen
    jsr PushOAMDataToScreen 
    jsr HandleDMARequests
    jsr HandleHDMARequests
    jsr UpdateScroll
    lda INIDISP
    eor #%10000000 ; disables force-blanking as graphic updates are done
    sta INIDISP
    jsr UpdateCollisions
    jsr GetInput
    jsr UpdateInput
    jsr UpdateAudio     
    skip_frame:
    lda #1
    sta vblanking_done

    ply
    plx
    pla
    plb
    rti



IRQ: 
    phb
    pha
    phx
    phy

    per irq_done
    jml (irq_ptr)

    irq_done:
    ply
    plx
    pla
    plb
    rti

    ; lda irq_select
    ; asl
    ; tax
    ; a8
    ; lda irq_ptrs, x
    ; sta irq_ptr
    ; inx
    ; a16 
    ; lda irq_ptrs, x
    ; sta irq_ptr+2