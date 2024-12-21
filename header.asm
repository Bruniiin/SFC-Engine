.bank 0
.org $FFC0

.byte "SUPERFAMICOM-ASSEMBLY"
.byte $00
.byte $00
.byte $08
.byte $00
.byte $00
.byte $00
.byte $00
.word $0000
.word $0000

.word $0000
.word $0000

; Native vectors

.addr COP_int
.addr BRK_int
.addr $0000
.addr NMI_int
.addr Main
.addr IRQ_int

.word $0000
.word $0000

; Emulation vectors

.addr COP_int
.addr $0000
.addr $0000
.addr NMI_int
.addr Main
.addr IRQ_int

