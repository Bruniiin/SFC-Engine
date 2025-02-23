.bank $F0
.org $8000

RenderScreen: ; args (tile_id, x, y, obj_x, obj_y, width, height)
    php
    pha
    phx
    phy
    ldx #0
    ldy #0
    stz local_width
    stz local_height
    lda v_arg001
    asl
    tax
    lda tile_list, x
    sta $4
    lda ($4), y
    sta local_obj_width
    iny
    lda ($4), y
    sta local_obj_height

    ; j = local_obj_width * obj_y + obj_x
    ; k = screen_width / 2 * y + x
    ; for (i = 0; i < width*height; i++) {
        ; TILE_RENDER_QUEUE[k] = *tilemap[j]
        ; local_width++;
        ; if (l_width == width) {
            ; local_height++; 
                ; if (local_height == height) {
                ;       break;
                ; }
            ; local_width = 0;
            ; j += local_obj_width - width;
            ; k += screen_width / 2 - width;
            ; }
    ; }
    lda local_obj_width
    sta WRMPYA
    lda v_arg005
    sta WRMPYB
    nop
    lda MPYL
    clc
    adc v_arg004
    tay

    lda screen_width/2
    sta WRMPYA
    lda v_arg003
    sta WRMPYB
    nop 
    lda MPYL
    clc
    adc v_arg002
    tax

    .loop:
    lda ($4), y
    sta TILE_RENDER_QUEUE, x
    iny
    inx
    inc local_width
    cmp v_arg006
    bne .loop

    stz local_width
    
    txa
    sec 
    adc #screen_width/2
    clc 
    sbc v_arg006
    tax

    tya
    sec
    adc local_obj_width
    clc
    sbc v_arg006
    tay 

    inc local_height
    cmp v_arg007
    bne .loop
    
    ply
    plx
    pla
    plp
    rts

RenderString: ; args (list_id, string_offset, char_offset, x, y, max_size)
    php
    pha
    phx
    phy
    ldx #0
    ldy #0
    lda v_arg001 
    sta $4
    lda #0
    sta local_var001 ; size iterator

    ; j = list_id + string_offset * 20;
    ; k = screen_width/2 * y + x; 
    ; for (i = 0; i < max_size; i++)
    ; {  
    ;   TILE_RENDER_QUEUE[k] = string_offset[j + char_offset];
    ;   char_offset++;
    ;   if (listoffset[j + char_offset] == %) {
    ;       break;
    ;       }
    ; }
    lda v_arg002
    sta v_arg_multiply
    lda char_size
    sta v_arg_multiplier
    jsr vMultiply
    lda mpy_value
    clc
    adc v_arg003
    tay

    lda screen_width/2
    sta v_arg_multiply
    lda v_arg005
    sta v_arg_multiplier
    jsr vMultiply
    lda mpy_value
    clc
    adc v_arg004
    tax

    .loop:
    lda ($4), y
    cmp #%
    beq .break
    sta TILE_RENDER_QUEUE, x
    iny
    inx
    inc local_var001
    cmp v_arg006
    bne .loop
    .break:
    ply
    plx
    pla
    plp
    rts

RenderObject: ; args (object_id, anim_state, obj_attributes, global_x, global_y, camera_x, camera_y, (bool)is_visible)
    php
    pha
    phx
    phy
    ldx #0
    ldy #0

    ; object_id_offset = object_id * obj_header_size;
    ; *object = object_list[object_id * obj_header_size];
    ; object_size = object_list[(object_id * obj_header_size)+1];
    ; object_frames = object_list[(object_id * obj_header_size)+2];
    ; for (i = 0; i < object_size * 2; i++) {
        ; object_offset = *object[i + (anim_state * object_size)];
            ; i++;
        ; obj_id = *object[i + (anim_state * object_size)];
        ; screen_x = global_x (ex.250) - camera_x (ex.200) + ((object_offset & 0x0F) * 8);
        ; screen_y = global_y - camera_y + ((object_offset & 0xF0 >> 4) * 8);
        ; if (screen_x < screen_width && screen_y < screen_height) 
        ; {
            ;   OAMDATA(screen_x, screen_y, obj_id, obj_attributes);
        ; }
    ; }

    ldx v_arg001
    lda object_id, x
    sta $0
    inx
    txa

    lda object_id, x
    asl
    sta object_size
    inx
    lda object_id, x
    sta object_frames

    ldx oam_buffer_offset
    lda v_arg002
    beq +
    sta v_arg_multiplicand
    lda object_size
    sta v_arg_multiplier
    jsr v_Multiply
    lda mpy_value
  + tay

    .loop:
    lda ($0), y
    pha
    and #%00001111
    asl 
    asl
    asl
    asl
    adc v_arg004
    sec
    sbc v_arg006
    bmi +
    sta local_screen_x
    cmp screen_width
    bcs + 

    pla
    and #%11110000
    adc v_arg005
    sec
    sbc v_arg007
    bmi +
    sta local_screen_y
    cmp screen_height
    bcs + 
    iny

    lda local_screen_x
    sta OAM_BUFFER, x
    inx
    lda local_screen_y
    sta OAM_BUFFER, x
    inx
    lda ($0), y
    sta OAM_BUFFER, x
    inx
    lda v_arg003
    sta OAM_BUFFER, x
    inx
    stx oam_buffer_offset
  + iny
    cpy object_size
    bne .loop

    ply
    plx
    pla
    plp
    rts

RenderUi: ; args (object_id, anim_state, x, y, obj_attributes)
    php
    pha
    phx
    phy
    ldy #0

    ldx v_arg001
    lda object_list, x
    sta $0
    lda v_arg002
    sta v_arg_multiplicand
    lda ($0), y
    sta object_size
    sta v_arg_multiplier
    jsr vMultiply
    lda mpy_value
    ; asl
    tay
    ldx oam_buffer_offset

    .loop:
    lda ($0), y
    sta local_object_offset_x
    iny
    lda ($0), y
    sta local_object_offset_y 
    iny
    lda v_arg003
    clc
    adc local_object_offset_x
    sta OAM_BUFFER, x
    inx
    lda v_arg004
    clc
    adc local_object_offset_y
    sta OAM_BUFFER, x
    inx
    lda ($0), y
    sta OAM_BUFFER, x
    inx
    lda v_arg005
    sta OAM_BUFFER, x
    inx
    stx oam_buffer_offset
    iny
    cpy object_size
    bne .loop

    ply
    plx
    pla
    plp
    rts

PlayObjAnim:

ChangeScreenMode: ; args (bg_mode, bg3_priority, (bool)bg1_sprite_size, (bool)bg2_sprite_size, (bool)bg3_sprite_size, (bool), bg4_sprite_size)
    php
    pha
    phx
    phy

    lda BGMODE
    and #%11110000
    ora v_arg001
    sta BGMODE_mirror
    lda v_arg002
    rol
    rol 
    rol
    ora BGMODE_mirror
    sta BGMODE_mirror

    ply
    plx
    pla
    plp
    rts


FadeIn: 

FadeOut:

SetCameraPos: ; args (x, y, bg_layer)
    php
    pha
    phx
    phy
    ldx #0

    lda v_arg001
    pha
    ldx v_arg003
    sec
    sbc global_cam_x
    bmi +
    ; eor #255
    ; clc 
    ; adc #1
    adc scroll_reg_mirror_x, x
    sta scroll_reg_mirror_x, x
    bra ++
  + eor #255
    clc 
    adc #1
    sta local_var001
    lda scroll_reg_mirror_x, x
    sec
    sbc local_var001
    sta scroll_reg_mirror_x, x 
 ++ pla
    sta global_cam_x
    ldx #0

    lda v_arg002
    pha
    sec
    sbc global_cam_y
    bmi +
    adc scroll_reg_mirror_y, x
    sta scroll_reg_mirror_y, x
    bra ++
  + eor #255
    clc 
    adc #1
    sec
    sbc scroll_reg_mirror_y, x
    sta scroll_reg_mirror_y, x 
 ++ pla
    sta global_cam_y
    
    ply
    plx
    pla 
    plp
    rts

UpdateScroll: 

CheckCollisionW:

CheckCollisionObj:

CheckCollisionWtoObj:

InitializeObject:

GetInput:

UpdateInput:

DMAInit:

HDMAInit:

ConvertBinDec:

v_Multiply:
    php
    lda v_arg_multiplicand
    sta WRMPYA
    lda v_arg_multiplier
    sta WRMPYB
    nop
    lda MPYL
    sta mpy_value
    lda MPYH
    sta mpy_value_h
    plp
    rts

v_Divide:
    php
    lda v_arg_dividendl
    sta WRDIVL
    lda v_arg_dividendh
    sta WRDIVH
    lda v_arg_div_divisor
    sta WRDIVB
    nop
    nop 
    nop
    lda RDDIVL
    sta div_value 
    lda RDVILH
    sta div_value_h
    lda RDMPYL
    sta div_rem
    lda RDMPYH
    sta div_rem_h
    plp
    rts 

vMath:

    ; lda v_arg002
    ; sta TILE_RENDER_QUEUE_POS
    ; lda v_arg003 
    ; sta TILE_RENDER_QUEUE_POS

    ; object_offset = object_offset << 3;
    ; object_offset_x = *object[j];
    ; j++;
    ; object_offset_y = *object[j];
    ; j++;

    ; ldx v_arg003
    ; lda BACKGROUND_SCROLL_LAYERS, x
    ; sta $4

    ; **object = &object;
    ; object_size = *object[];
    ; object_frames = *object[1];
    ; **object += obj_header_size;

    ; ldy ($0), y
    ; sta object_size
    ; iny
    ; ldy ($0), y
    ; sta object_frames
    ; lda $0
    ; clc
    ; adc obj_header_size
    ; sta $0+1
    ; ror
    ; ror
    ; ror 
    ; ror
