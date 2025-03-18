a_button =      $0080
b_button =      $8000
x_button =      $0040
y_button =      $4000
l_button =      $0020
r_button =      $0010
start_button =  $2000
select_button = $1000
up_pad =        $0800
down_pad =      $0400
left_pad =      $0200
right_pad =     $0100

stack_ptr =     $1fff

w_ram_area =    $7e0000
s_ram_area =    ; unused
lo_rom_area =   $808000
hi_rom_area =   $c00000

TILE_RENDER_QUEUE =         (w_ram_area)
TILE_RENDER_QUEUE_LENGTH =  (TILE_RENDER_QUEUE+((32*32)*4))
TILE_COLLISION_WINDOW =     (TILE_RENDER_QUEUE_LENGTH+64)
OBJ_ACTIVE =                (TILE_COLLISION_WINDOW+((16*16)*4))
OBJ_ACTIVE_POINTER =        (OBJ_ACTIVE+64)
OBJ_ACTIVE_GFX =            (OBJ_ACTIVE_POINTER+128)
OBJ_ACTIVE_GFX_POINTER =    (OBJ_ACTIVE_GFX+64)
OBJ_ACTIVE_FLAGS =          (OBJ_ACTIVE_GFX_POINTER+128)
OBJ_ACTIVE_HOR =            (OBJ_ACTIVE_STATE+64)
OBJ_ACTIVE_VER =            (OBJ_ACTIVE_HOR+128)
EVENT_ACTIVE =              (OBJ_ACTIVE_VER+128)
EVENT_TIMER =               (EVENT_ACTIVE+512)
