.MACRO a8
    sep #$10
.ENDMACRO

.MACRO a16
    rep #$10
.ENDMACRO

.MACRO xy8
    sep #$20
.ENDMACRO

.MACRO xy16
    rep #$20
.ENDMACRO

.MACRO push__arguments

.ENDMACRO

.MACRO pop__arguments

.ENDMACRO

.MACRO set__stack__frame address
    php
    xy16
    tsx
    stx stack_ptr
    dex
    dex
    txs
    plp 
.ENDMACRO

.MACRO set__up__stack__frame
    php
    xy16
    tsx
    stx stack_ptr
    txs
    plp 
.ENDMACRO

.MACRO restore__stack__frame
    php
    xy16
    ldx stack_ptr
    txs
    plp 
.ENDMACRO

.MACRO push address 
    ldx address
    phx
.ENDMACRO

.MACRO pop address
    plx
    stx address
.ENDMACRO

.MACRO DMAInit (source_bank, source_address, dest, dest_offset, length, format, channel, direction, auto)
    ldx auto 
    phx 
    ldx direction
    phx
    ldx channel
    phx
    ldx format
    phx
    ldx length
    phx
    ldx dest_offset
    phx 
    ldx dest 
    phx
    ldx source_address
    phx
    ldx source_bank
    phx 
    set__up__stack__frame
    jsl DMAInit
.ENDMACRO 

.MACRO HDMAInit (source_bank, source_address, dest, indirect_bank, indirect_address, channel, format, (bool)direction)
    ldx auto 
    phx 
    ldx direction
    phx
    ldx channel
    phx
    ldx format
    phx
    ldx indirect_address
    phx
    ldx indirect_bank
    phx 
    ldx dest 
    phx
    ldx source_address
    phx
    ldx source_bank
    phx 
    set__up__stack__frame
    jsl HDMAInit
.ENDMACRO

.MACRO InstantiateObject (address_ptr, global_x, global_y, flags, is_screen_space)
    ldx is_screen_space
    phx
    ldx flags
    phx
    ldx global_y
    phx
    ldx global_x
    phx
    ldx address_ptr
    phx
    set__up__stack__frame
    jsl InstantiateObject
.ENDMACRO

.MACRO DeallocateObject (obj_id)
    lda obj_id
    jsl DeallocateObject
.ENDMACRO

.MACRO RenderToScreen (address_ptr, x, y, obj_x, obj_y, width, height)
    ldx height 
    phx 
    ldx width 
    phx
    ldx obj_y
    phx 
    ldx obj_x
    phx
    ldx y
    phx
    ldx x
    phx
    ldx address_ptr
    phx
    set__up__stack__frame
    jsl RenderScreen
.ENDMACRO

.MACRO SetScreenMode (bg_mode, bg3_priority)
    ldx bg3_priority
    phx
    ldx bg_mode 
    phx
    set__up__stack__frame
    jsl ChangeScreenMode
.ENDMACRO

.MACRO RenderString (address_ptr, string_offset, char_offset, x, y, max_size)
    ldx max_size
    phx
    ldx y
    phx
    ldx x
    phx
    ldx char_offset
    phx
    ldx string_offset
    phx
    ldx address_ptr
    phx
    set__up__stack__frame
    jsl RenderString
.ENDMACRO

.MACRO SetCameraPos (x, y, layer)
    ldx layer
    phx
    ldx y
    phx
    ldx x
    phx
    set__up__stack__frame
    jsl SetCameraPos
.ENDMACRO

.MACRO CheckCollisionMapToObject (address_ptr, obj_id)
    ldx obj_id 
    phx
    ldx address_ptr
    phx 
    set__up__stack__frame
    jsl CheckCollisionMapToObj
.ENDMACRO

.MACRO CheckCollisionMap (global_x, global_y, bg_layer)
    ldx bg_layer
    phx
    ldx global_y
    phx
    ldx global_x
    phx 
    set__up__stack__frame
    jsl CheckCollisionMap
.ENDMACRO