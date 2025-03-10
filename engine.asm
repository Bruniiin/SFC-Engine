.bank $F0
.org $8000

RenderScreen: ; args (address, x, y, obj_x, obj_y, width, height)
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

    ; *tilemap = &address;
    ; obj_width = *tilemap[0];
    ; obj_height = *tilemap[1];
    ; j = local_obj_width * obj_y + obj_x + header;
    ; k = (screen_width / 2 * y) + x;
    ; for (i = 0; i < width*height; i++) {
        ; TILE_RENDER_QUEUE[k] = *tilemap[j];
        ; local_width++;
        ; if (local_width == width) {
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

RenderString: ; args (address, string_offset, char_offset, x, y, max_size)
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

    ; *address = &address;
    ; j = address + (string_offset * 20);
    ; k = (screen_width/2 * y) + x; 
    ; for (i = 0; i < max_size; i++)
    ; {  
    ;   TILE_RENDER_QUEUE[k] = *address[j + char_offset];
    ;   char_offset++;
    ;   if (*address[j + char_offset] == %) {
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
    ; *object = object_list[object_id_offset];
    ; object_size = object_list[(object_id_offset)+1];
    ; object_frames = object_list[(object_id_offset)+2];
    ; for (i = 0; i < object_size * 2; i++) {
        ; object_offset = *object[i + (object_size * anim_state)];
            ; i++;
        ; obj_graph = *object[i + (object_size * anim_state)];
        ; screen_x = global_x (ex.250) - camera_x (ex.200) + ((object_offset & 0x0F) * 8);
        ; screen_y = global_y - camera_y + ((object_offset & 0xF0 >> 4) * 8);
        ; if (screen_x < screen_width && screen_y < screen_height) 
        ; {
            ;   OAMDATA(screen_x, screen_y, obj_graph, obj_attributes);
        ; }
    ; }

    ; simplified code

    ; *object[] = object_ptr; 
    ; object_size = *object[];
    ; j = (object_size * anim_state);
    ; ++j;
    ; for (i = j; i < object_size * 2; i++) {
          ; ++j;
          ; object_offset = *object[i];
          ; obj_graph = *object[j];
          ; screen_x = global_x (ex.250) - camera_x (ex.200) + ((object_offset & 0x0F << 4) * 8);
          ; screen_y = global_y - camera_y + ((object_offset & 0xF0) * 8);
          ; if (screen_x < screen_width && screen_y < screen_height) 
          ; {
              ;   OAMDATA(screen_x, screen_y, obj_graph, obj_attributes);
          ; }
    ; }

    a8
    ldx v_arg001
    lda object_id, x
    sta $0
    inx
    txa

    lda ($0), y
    asl
    sta object_size
    iny
    lda ($0), y
    sta object_frames

    lda object_size
    sta v_arg_multiplicand
    lda v_arg002
    beq +
    sta v_arg_multiplier
    jsr v_Multiply
    lda mpy_value
  + tay
    iny
    iny
    ldx oam_buffer_offset

    .loop:
    a16
    lda ($0), y
    ; xba
    ; pha
    ; xba
    pha
    and #%00001111
    beq +
    asl 
    asl
    asl
    asl
  + adc v_arg004
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
    a8

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

RunAnim:

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

CheckCollisionObj: ; args (obj_1, obj_2, (bool)auto)
    php
    pha
    phx
    phy

    ply
    plx
    pla 
    plp
    rts

CheckCollisionMapToObj: ; args (obj, bg_layer)
    php
    pha
    phx
    phy

    ply
    plx
    pla 
    plp
    rts

CheckCollisionMap:
    php
    pha
    phx
    phy

    ply
    plx
    pla 
    plp
    rts

InstantiateObject: ; args (object_ptr, global_x, global_y, flags, (bool)world_space)
    php
    pha
    phx
    phy

    ply
    plx
    pla 
    plp
    rts

; Low-level internal functions

GetInput:
    php
    pha

    a8
    lda NMITIMEN
    ora #$81
    sta NMITIMEN
  - lda HVBJOY
    and #$01
    beq - 
    a16
    lda JOY1L
    sta input_lo

    pla
    plp
    rts 

UpdateInput:

UpdateCollision: ; code is a bit unpolished, had a massive brain fog while writing this
    php
    pha
    phx
    phy
    ldx #0
    ldy #1

    ; for (i = 0; i < obj_size; i++) {
    ;   object_active_col[i] = false; 
    ; }
    ; for (i = 0; i < obj_size; i++) {
    ;   for (j = 1; j < obj_size; j++) {
    ;       hor = object_active_hor[i] - object_active_hor[j]; 
    ;       if (hor <= object_active_width[j]) {
    ;           ver = object_active_ver[i] - object_active_ver[j];            
    ;           if (ver <= object_active_height[j]) {
    ;               object_active_col[i] = j;
    ;          }
    ;       }
    ;    }
    ; } 

    .loop_1:
    lda #0 
    sta OBJ_ACTIVE_COL, x
    inx
    cmp Obj_Size
    bne .loop_1

    lda Obj_Size
    asl
    sta local_var001
    a16
    .loop_2:
    lda OBJ_ACTIVE_STATE, x
    and #$01
    cmp Collision_Enable_Flag
    bne +
    lda OBJ_ACTIVE_HOR, x
    sec 
    sbc OBJ_ACTIVE_HOR, y 
    cmp OBJ_ACTIVE_WIDTH, y 
    bne +
    lda OBJ_ACTIVE_VER, x
    sec
    sbc OBJ_ACTIVE_HOR, y
    cmp OBJ_ACTIVE_HEIGHT, y
    bne +
    a8
    lda OBJ_ACTIVE, y 
    sta OBJ_ACTIVE_COL, x
    a16
  + inx
    inx 
    iny
    iny
    cpx local_var001
    bne .loop_2

    ply
    plx
    pla 
    plp
    rts

PushDataToScreen:
    php
    pha
    phx
    phy

    ply
    plx
    pla 
    plp
    rts

UpdateScroll: 
    php
    pha
    phx
    phy
    ldx #0

    a16
    lda scroll_reg_mirror_x, x 
    sta BG1HOFS
    lda scroll_reg_mirror_y, x
    sta BG1VOFS
    inx
    lda scroll_reg_mirror_x, x 
    sta BG2HOFS
    lda scroll_reg_mirror_y, x
    sta BG2VOFS
    inx 
    lda scroll_reg_mirror_x, x 
    sta BG3HOFS
    lda scroll_reg_mirror_y, x
    sta BG3VOFS
    inx 
    lda scroll_reg_mirror_x, x 
    sta BG4HOFS
    lda scroll_reg_mirror_y, x
    sta BG4VOFS
    inx 
    lda scroll_reg_mirror_x, x
    sta M7HOFS
    lda scroll_reg_mirror_y, x
    sta M7VOFS
    
    pla
    plx 
    ply
    plp
    rts

DMAInit: ; args (source_bank, source_address, dest, dest_offset, length, format, channel, (bool)direction, (bool)auto)
    php
    pha
    phx
    phy
    ldx #0
    ldy #0

    a8
    stz DMAPx
    lda #DMAPx
    tcd 
    lda v_arg007
    pha
    ror
    ror
    ror
    ror
    cmp DMAx_mirror
    beq +
    sta local_var001
    a16    

    .loop_1: 
    lda #DMAPx, x
    ora local_var001
    sta DMAx_mirror, x
    inx
    inx
    cpx #14
    bne .loop_1

    ; alternative implementation without looping
    ; ora w_var001
    ; sta DMAPx_mirror 
    ; ora w_var001
    ; sta BBADx_mirror
    ; ora w_var001 
    ; sta A1TxL_mirror
    ; ora w_var001
    ; sta A1TxH_mirror
    ; ora w_var001
    ; sta A1Bx_mirror
    ; ora w_var001
    ; sta DASxL_mirror
    ; ora w_var001
    ; sta DASxH_mirror

  + ldx v_arg003
    lda v_arg004
    sta registers, x
    lda v_arg003
    sta (BBADx_mirror), y
    lda v_arg002
    sta (A1TxL_mirror), y 
    a8
    lda v_arg001
    sta (A1Bx_mirror),  y
    a16
    lda v_arg005
    sta (DASxL_mirror), y 

    lda v_arg008
    ror
    ror
    sta (DMAPx_mirror), y
    lda v_arg009
    rol
    rol
    rol
    ora (DMAPx_mirror), y
    ora v_arg006
    sta (DMAPx_mirror), y
    pla
    tay
    lda #1
    cpy #0
    beq +
    .loop_2: 
    ror
    dey
    cpy #0
    bne .loop_2
  + sta MDMAEN 

    pla 
    ply
    plx
    plp
    rts

HDMAInit: ; args (source_bank, source_address, dest, indirect_bank, indirect_address, channel, format, (bool)direction)
    php
    pha
    phx
    phy

    a8
    stz DMAPx
    lda #DMAPx
    tcd 
    lda v_arg007
    ror
    ror
    ror
    ror
    cmp HDMAx_mirror
    beq +
    sta local_var001
    a16

    .loop_1:
    lda #DMAPx, x
    ora local_var001
    sta HDMAx_mirror, x
    inx
    inx
    cpx #22
    bne .loop_1

  + lda v_arg003
    sta (hBBADx_mirror), y
    lda v_arg002
    sta (hA1TxL_mirror), y
    a8
    lda v_arg001
    sta (hA1Bx_mirror),  y 
    a16
    lda v_arg005
    cmp #0
    beq +

  + lda v_arg008
    ror
    ror
    ora (hDMAPx_mirror), y
    ora v_arg007
    sta (hDMAPx_mirror), y

    ldy v_arg006
    lda #1
    cpy #0
    beq +
    .loop_2: 
    ror
    dey
    cpy #0
    bne .loop_2
  + sta HDMAEN

    ply
    plx
    pla 
    plp
    rts

ConvertToDecimal:

; Math (A few math functions. I like writing math functions so i'll add many more of them.)

m_Multiply: ; args (multiplicand, multiplier, (bool)m7_matrix)
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

m_Divide: ; args (dividend, divisor)
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

m_GetDirection: ; args (x1, y1, x2, y2)
    php
    pha
    phx
    phy

    lda v_arg001
    ldx v_arg002
    sec
    sbc v_arg003
    pha
    txa
    sec 
    sbc v_arg004
    sta ret_value+1
    pla
    sta ret_value    

    ply
    plx
    pla 
    plp 
    rts

m_Clamp: ; args (value, clamp_min, clamp_max)
    php
    pha
    phx
    phy

    ; if (value < clamp_min) 
    ;   value = clamp_min; 
    ; else if (value > clamp_max)
    ;   value = clamp_max;

    lda v_arg002
    cmp v_arg001
    bcc +
    sta v_arg001
  + lda v_arg003
    cmp v_arg001
    bcs +
    sta v_arg001

  + ply 
    plx
    pla 
    plp

m_PowerOf: ; args (base, exponent)
    php
    pha
    phx
    phy
    ldx #0
    lda v_arg001
    ldx v_arg002
    sta w_var001
    stx v_loop001

    ; ex. 2^16 = 65536; 
    ; a = base;
    ; for (i = 0; i < exponent; i++) {
    ;   a = a * base; 
    ; }
    ; return a;

    .loop:
    lda v_arg001
    sta M7A
    lda w_var001
    sta M7B
    lda MPYL
    sta v_arg001
    inx
    cpx v_loop001
    bne .loop
    sta ret_value

    ply 
    plx
    pla 
    plp
    rts

m_Min: ; args (value, min)
    php
    pha
    phx
    phy

    ply 
    plx
    pla 
    plp
    rts

m_Max: ; args (value, max)
    php
    pha
    phx
    phy

    ply 
    plx
    pla 
    plp
    rts

m_Log: ; args (base, logarithm)
    php
    pha
    phx
    phy

    ply 
    plx
    pla 
    plp
    rts

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
    ; iny
    ; phy
    ; iny
    
    ; lda #DMAPx, x
    ; ora w_var001
    ; sta DMAPx_mirror, y
    ; iny
    ; iny

    ; lda object_id, x
    ; asl
    ; sta object_size
    ; inx
    ; lda object_id, x
    ; sta object_frames
