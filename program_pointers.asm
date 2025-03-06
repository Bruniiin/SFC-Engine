.bank 0
.org $FF00

boot_title:
.byte $03
.byte "Main Game Test%     "
.byte "Engine Test%        "
.byte "Mode 0-7 Test%      "

boot_address:
.byte $90
.word $8000
.byte $80
.word $8000
.byte $81
.word $8000