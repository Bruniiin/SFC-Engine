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
    rtl

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
    jsl vMultiply
    lda mpy_value
    clc
    adc v_arg003
    tay

    lda screen_width/2
    sta v_arg_multiply
    lda v_arg005
    sta v_arg_multiplier
    jsl vMultiply
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
    rtl

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
    ; j = (anim_state * object_size) + 1;
    ; for (i = 1, j; i < object_size * 2; i++, j++) {
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
    jsl v_Multiply
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
    rtl

RenderUi: ; args (object_id, anim_state, x, y, attributes)
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
    jsl vMultiply
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
    rtl

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
    rtl

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
    rtl

CheckCollisionObj: 
    php
    pha
    phx
    phy

    ; return (object_active_collision[obj_1 * 2]);

    ply
    plx
    pla 
    plp
    rtl

CheckCollisionMapToObj: ; args (obj_id, bg_layer)
    php
    pha
    phx
    phy
    ldy #0

    ; int address = current_scene + bg_layer * 2;
    ; *map_pointer = scene_map_ptr[address];
    ; int map_width = *map_pointer[];
    ; int x = obj_active_hor[obj_id*2];
    ; int y = obj_active_ver[obj_id*2];
    ; x = x / tile_size;
    ; y = y / tile_size;
    ; int pos = y * map_width + x;
    ; int col = *map_pointer[pos];
    ; return col;

    lda current_scene
    clc
    adc v_arg002
    asl
    tax 
    lda scene_map_ptr, x 
    sta $2
    inx
    lda scene_map_ptr, x
    sta $4
    lda ($0), y 
    sta local_var001 ; map_width

    lda v_arg001
    asl
    tax
    lda OBJ_ACTIVE_HOR, x
    lsr
    lsr
    lsr
    sta local_var002 ; x 
    lda OBJ_ACTIVE_VER, x
    lsr
    lsr
    lsr
    sta local_var003 ; y
    clc
    adc local_var002
    sta v_arg001
    lda local_var001
    sta v_arg002
    jsl m_Multiply
    ldy mpy_value 
    lda ($0), y
    sta ret_value

    ply
    plx
    pla 
    plp
    rtl

CheckCollisionMap: ; args (global_x, global_y, bg_layer)
    php
    pha
    phx
    phy

    ply
    plx
    pla 
    plp
    rtl

InstantiateObject: ; args (object_ptr, global_x, global_y, flags, (bool)screen_space)
    php
    pha
    phx
    phy

    ; a few implementations, not sure the best way to implement it yet

    ; *object_ptr[] = &object_ptr; 
    ; sizeof = *object_ptr[];
    ; for (int i = 0, int j = 0; j < sizeof; i++, j++) {
    ;   OBJ_DATA[i] = *object_ptr[j]; 
    ; }
    ; int i = (OBJECT_ACTIVE_SIZE << 1);
    ; OBJ_ACTIVE_POINTER[i] = object_ptr + (obj_elements << 1);
    ; OBJ_ACTIVE_FLAGS[i] = flags; 
    ; OBJ_ACTIVE_HOR[i] = (global_x / (screen_space * screen_width));
    ; OBJ_ACTIVE_VER[i] = (global_y / (screen_space * screen_height));


    ; int i, k = (object_active_sizeof << 1);
    ; OBJ_ACTIVE[i++] = (sizeof(&object_ptr) << 1);
    ; OBJ_ACTIVE[i++] = object_ptr; 
    ; OBJ_ACTIVE[i++] = (global_x / (screen_space * screen_width));
    ; OBJ_ACTIVE[i++] = (global_y / (screen_space * screen_height));
    ; OBJ_ACTIVE[i++] = flags; 
    ; *object_ptr = &object_ptr;
    ; for (i, int j = 0; j < sizeof(&object_ptr); i++, j++) {
    ;   OBJ_ACTIVE[i] = *object_ptr[j]; 
    ; } 
    ; object_active_sizeof = i;


    ; int i = (obj_active_sizeof << 1);
    ; OBJ_POINTER[i] = object_ptr; 
    ; int i = (obj_active_sizeof * 24);
    ; OBJ_DATA[i++] = (sizeof(&object_ptr) << 1);
    ; OBJ_DATA[i++] = (global_x / (screen_space * screen_width));
    ; OBJ_DATA[i++] = (global_y / (screen_space * screen_height));
    ; OBJ_DATA[i++] = flags; 
    ; *object_ptr = &object_ptr;
    ; for (i, int j = 0; j < sizeof(&object_ptr); i++, j++) {
    ;   OBJ_DATA[i] = *object_ptr[j]; 
    ; } 
    ; object_active_sizeof = i;
    ; sizeof = *object_ptr[];

    lda OBJ_ACTIVE_SIZE 
    asl
    tay
    lda v_arg001
    sta $8
    sta local_var001
    lda v_arg002
    sta OBJ_ACTIVE_HOR, y 
    lda v_arg003
    sta OBJ_ACTIVE_VER, y
    a8
    lda v_arg004
    sta OBJ_ACTIVE_FLAGS, y
    a16
    phy
    sty v_arg001
    lda #20
    sta v_arg002
    jsl m_Multiply
    ldx mpy_value
    ldy #0
    lda ($8), y
    inc a
    sta local_var002 

    .loop: 
    lda ($8), y
    sta OBJ_ELEMENTS, x
    iny
    cpy local_var002
    bne .loop

    ply
    lda #local_var001
    clc
    adc #local_var002
    sta OBJ_ACTIVE_POINTER, y 
    lda OBJ_ACTIVE_SIZE
    clc
    adc #2
    sta OBJ_ACTIVE_SIZE

    ply
    plx
    pla 
    plp
    rtl

DeallocateObject: ; args ()
    php
    pha
    phx
    phy

    ; i = (object_id * 2);
    ; OBJ_ACTIVE_POINTER[i] = 0x0000; 
    ; OBJ_ACTIVE_FLAGS[i] = 0x0000; 
    ; OBJ_ACTIVE_HOR[i] = 0x0000;
    ; OBJ_ACTIVE_VER[i] = 0x0000;
    ; sizeof = OBJ_DATA[i * struct_size];
    ; for (i; i < sizeof; i++) {
    ; OBJ_DATA[i] = 0x0000;
    ; }

    lda v_arg001
    asl
    tay
    lda #0
    sta OBJ_ACTIVE_POINTER, x
    sta OBJ_ACTIVE_HOR, x
    sta OBJ_ACTIVE_VER, x
    sta OBJ_ACTIVE_FLAGS, x
    phx
    stx v_arg001
    ldx #20
    stx v_arg002
    jsl v_Multiply
    ldx mpy_value
    stx local_var001
    plx

    .loop:
    sta OBJ_DATA, x
    inx
    cpx local_var001
    bne .loop

    ply
    plx
    pla 
    plp
    rtl

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
    rtl 

UpdateInput:

UpdateCollision: 
    php
    pha
    phx
    phy
    ldx #0
    ldy #1

    ; for (i = 0; i < obj_active_size * 4; i++) {
    ;   obj_active_collision = 0xff; 
    ; }
    ; for (i = 0; i < obj_active_size * 4; i += 4) {
    ;   for (j = 1, k = 0; j < obj_active_size, k < obj_collision_limit; j++, k++) {
    ;       hor = obj_active_hor[i] - obj_active_hor[j]; 
    ;       if (hor <= obj_active_width[j]) {
    ;           ver = obj_active_ver[i] - obj_active_ver[j];            
    ;           if (ver <= obj_active_height[j]) {
    ;               obj_active_collision[i + k] = j;
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
    tya 
    sta OBJ_ACTIVE_COL, x
    txa
    sta OBJ_ACTIVE_COL, y
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
    rtl

PushVRAMDataToScreen:
    php
    pha
    phx
    phy

    ; *bg_size = &bgsc_mirror;
    ; source = &TILE_RENDER_QUEUE;
    ; source_bank = 0x7e;
    ; dest = VMDATAL; 
    ; dest_offset = vram_tm_001;
    ; format = 0x01;
    ; for (i = 0; i < layers; i++) 
    ; { 
    ;   bg_size = *bg_size[i] ^ 0x03; 
    ;   length = ((32 * 32 * bg_size) * layers); 
    ;   DMAInit(source_bank, source, dest, dest_offset, length, format, i, 0, 1); 
    ; }

    a16
    xy8 
    ldx #$7e
    sta v_arg002 ; source_bank
    lda #TILE_RENDER_QUEUE
    sta v_arg001 ; source
    ldx #<VMDATAL
    sta v_arg003 ; dest
    lda vram_tm_001
    sta v_arg004 ; dest_offset
    lda (32 * 32 * bg_size)
    sta v_arg005 ; length
    ldx #1
    stx v_arg006 ; format 
    dex 
    stx v_arg007 ; channel 
    ldy #0
    sta v_arg008 ; direction 
    iny
    sta v_arg009 ; auto

    .loop:
    jsr DMAInit
    inx
    stx v_arg007
    cpx #4 
    bne .loop 

    ply
    plx
    pla 
    plp
    rtl

PushOAMDataToScreen: 
    php
    pha
    phx
    phy

    ; source = &OAMDATA;
    ; source_bank = 0x7e;
    ; dest = OAMDATA;
    ; dest_offset = 0x0000;
    ; length = oamdata_size; 
    ; format = 0x00;
    ; DMAInit(source_bank, source, dest, dest_offset, length, format, 8, 0, 1); 

    a16
    xy8
    ldx #$7e
    stx v_arg001 ; source_bank
    lda OAMDATA_MIRROR 
    sta v_arg002 ; source
    lda OAMDATA
    sta v_arg003 ; dest 
    lda #$0000
    sta v_arg004 ; dest_offset
    lda oam_size
    sta v_arg005 ; length
    ldx #0
    stx v_arg006 ; format
    ldx #8
    stx v_arg007 ; dma channel
    ldx #0
    stx v_arg008 ; direction
    inx
    stx v_arg009 ; auto

    jsr DMAInit

    ply
    plx
    pla 
    plp
    rtl

RenderActiveObjects: 
    php
    pha
    phx
    phy
    ldx #0
    ldy #0

    ; for (i = 0, j = 0; i < obj_active_sizeof; i++, j += 2)
    ; {
    ;   *object = OBJ_ACTIVE_POINTER[j]; 
    ;   x = OBJ_ACTIVE_HOR[j]; 
    ;   y = OBJ_ACTIVE_HOR[j];
    ;   anim = OBJ_ACTIVE_ANIM[i];
    ;   attributes = OBJ_ACTIVE_FLAGS[i];
    ;   RenderObject(*object, anim, attributes, x, y, camera_x, camera_y);
    ; }

    lda OBJ_ACTIVE_POINTER, y
    sta v_arg001 
    lda OBJ_ACTIVE_ANIM, x
    sta v_arg002 ; anim
    a8
    lda OBJ_ACTIVE_FLAGS, x
    sta v_arg003 ; attributes
    a16
    lda OBJ_ACTIVE_HOR, y 
    sta v_arg004 ; x
    lda OBJ_ACTIVE_HOR, y
    sta v_arg005 ; y
    lda global_cam_x
    sta v_arg006
    lda global_cam_y
    sta v_arg007
    
    jsr RenderObject

    ply
    plx
    pla 
    plp
    rtl

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
    rtl

UpdateAnimations:
    php
    pha
    phx
    phy

    ; for (i = 0; j = 0; i < obj_active_onscreen; i++, j += 2) {
    ;   int address = OBJ_ACTIVE_ANIM_POINTER[j];
    ;   int offset = address[];
    ;   offset = offset * 10 + sizeof(offset);
    ;   int anim_frame = address[offset];
    ;   if (!address[offset + anim_frame] <= 0x00) { 
    ;       address[offset + anim_frame]--; 
    ;   }
    ;   else {
    ;       anim_frame++;
    ;       OBJ_ACTIVE_ANIM[i] = animation_frame;
    ;       animation_frame++;
    ;       if (address[offset + anim_frame] == 0xfe) {
    ;           address[offset] = 0x00;
    ;       }
    ;       else {
    ;       address[offset] = anim_frame;
    ;       }
    ;   }
    ;

    ply
    plx
    pla
    plp
    rtl

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
    phy
    lda #1
    cpy #0
    beq +
    .loop_2: 
    ror
    dey
    cpy #0
    bne .loop_2
    ply
  + sta (HDMAEN_mirror), y

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
    phy
    lda #1
    cpy #0
    beq +
    .loop_2: 
    ror
    dey
    cpy #0
    bne .loop_2
    ply
  + sta (HDMAEN_mirror), y

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
    rtl

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
    rtl 

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
    rtl

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
    rtl

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
    rtl

m_Lerp: ; args (a, b, alpha)
    php
    pha
    phx
    phy

    ply 
    plx
    pla 
    plp
    rtl

m_Min: ; args (value, min)
    php
    pha
    phx
    phy

    ply 
    plx
    pla 
    plp
    rtl

m_Max: ; args (value, max)
    php
    pha
    phx
    phy

    ply 
    plx
    pla 
    plp
    rtl

m_Log: ; args (base, logarithm)
    php
    pha
    phx
    phy

    ply 
    plx
    pla 
    plp
    rtl

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

    ;               offset++;
    ;               if (offset >= object_collision_limit) {
    ;                   break;
    ;               }
    ; offset = 0; 
