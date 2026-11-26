; ============================================================================
; Super Mario Engine (16-Bit x86 Real-Mode Assembly)
; Team: Ashal Haider (25F-0543), Hamza Mansoor (25F-0579), Hassan Nadeem (25F-0577)
; ============================================================================

org 0x100

; --- HARDWARE & SCREEN CONSTANTS ---
SCREEN_W        equ 320
SCREEN_H        equ 200
MAP_W           equ 64
MAP_H           equ 12
TILE_SIZE       equ 16
MAX_CAM         equ 704             ; (64 * 16) - 320

; --- TILE IDS (1..10 = SOLID, 0 & 11+ = NON-SOLID) ---
TILE_SKY        equ 0
TILE_GROUND     equ 1
TILE_BRICK      equ 2
TILE_Q_COIN     equ 3
TILE_Q_MUSH     equ 4
TILE_EMPTY      equ 5
TILE_PIPE_TL    equ 6
TILE_PIPE_TR    equ 7
TILE_PIPE_BL    equ 8
TILE_PIPE_BR    equ 9
TILE_STAIR      equ 10
TILE_COIN       equ 11
TILE_FLAG       equ 12
TILE_CLOUD      equ 13
TILE_BUSH       equ 14

; --- VGA MODE 13H PALETTE COLORS ---
COL_BLACK       equ 0
COL_BLUE        equ 1
COL_GREEN       equ 2
COL_CYAN        equ 3
COL_RED         equ 4
COL_BROWN       equ 6
COL_LGRAY       equ 7
COL_DGRAY       equ 8
COL_LBLUE       equ 9
COL_LGREEN      equ 10
COL_YELLOW      equ 14
COL_WHITE       equ 15
COL_ORANGE      equ 42
COL_SKY         equ 54

; --- KEYBOARD SCAN CODES (SET 1) ---
KEY_ESC         equ 0x01
KEY_T           equ 0x14
KEY_P           equ 0x19
KEY_ENTER       equ 0x1C
KEY_LSHIFT      equ 0x2A
KEY_C           equ 0x2E
KEY_SPACE       equ 0x39
KEY_UP          equ 0x48
KEY_LEFT        equ 0x4B
KEY_RIGHT       equ 0x4D
KEY_DOWN        equ 0x50

; --- 8.8 FIXED-POINT PHYSICS CONSTANTS ---
WALK_ACCEL      equ 0x0030
MAX_WALK        equ 0x0180
MAX_RUN         equ 0x0280
FRICTION        equ 0x0028
GRAVITY         equ 0x0048
MAX_FALL        equ 0x0400
JUMP_START      equ 0xFB80
JUMP_CUTOFF     equ 0xFE00
STOMP_BOUNCE    equ 0xFD00

; --- ENEMY & GAME STATE CONSTANTS ---
MAX_ENEMIES     equ 16
ENEMY_SIZE      equ 8

ST_TITLE        equ 0
ST_PLAY         equ 1
ST_PAUSE        equ 2
ST_DIE          equ 3
ST_LIFELOST     equ 4
ST_WINSEQ       equ 5
ST_LVLCOMP      equ 6
ST_GAMEOVER     equ 7
ST_EXIT         equ 8

; ============================================================================
; MAIN ENTRY POINT
; ============================================================================
start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    add ax, 0x1000
    mov [buf_seg], ax

    mov ax, 0x0013
    int 0x10

    call hook_ints
    mov byte [game_state], ST_TITLE

main_loop:
    call waitframe
    inc word [frame_num]

    mov al, [game_state]
    cmp al, ST_TITLE
    je .do_title
    cmp al, ST_PLAY
    je .do_play
    cmp al, ST_PAUSE
    je .do_pause
    cmp al, ST_DIE
    je .do_die
    cmp al, ST_LIFELOST
    je .do_lifelost
    cmp al, ST_WINSEQ
    je .do_winseq
    cmp al, ST_LVLCOMP
    je .do_lvlcomp
    cmp al, ST_GAMEOVER
    je .do_gameover
    jmp exit_game

.do_title:
    call state_title
    jmp .render
.do_play:
    call state_play
    jmp .render
.do_pause:
    call state_pause
    jmp .render
.do_die:
    call state_die
    jmp .render
.do_lifelost:
    call state_lifelost
    jmp .render
.do_winseq:
    call state_winseq
    jmp .render
.do_lvlcomp:
    call state_lvlcomp
    jmp .render
.do_gameover:
    call state_gameover

.render:
    call flip
    cmp byte [game_state], ST_EXIT
    jne main_loop

exit_game:
    call unhook_ints
    mov ax, 0x0003
    int 0x10
    mov ax, 0x4C00
    int 0x21

; ============================================================================
; INCLUDE ENGINE MODULES
; ============================================================================
%include "src/gfx.asm"
%include "src/phys.asm"
%include "src/game.asm"

; ============================================================================
; GAME DATA & VARIABLES
; ============================================================================
buf_seg         dw 0
e0_flag         db 0
key_state       times 128 db 0
oldkb           dd 0
oldtimer        dd 0
tickcount       dw 0
last_tick       dw 0
frame_num       dw 0

camera_x        dw 0
mario_x         dw 32
mario_xf        db 0
mario_y         dw 144
mario_yf        db 0
mario_prev_y    dw 144
mario_vx        dw 0
mario_vy        dw 0
on_ground       db 1
mario_form      db 0
mario_hp        db 1
invuln_timer    db 0
stomp_chain     dw 0
mario_dir       db 0
mario_pose      db 0
pit_death       db 0

mush_active     db 0
mush_x          dw 0
mush_y          dw 0
mush_dir        db 1

score_lo        dw 0
score_hi        dw 0
coins           db 0
lives           db 3
game_time       dw 300
sec_ticks       db 0
game_state      db 0
state_timer     dw 0
menu_sel        db 0
time_bonus      dw 0

stomp_table     dw 100, 200, 400, 500, 800, 1000, 2000, 4000, 5000, 8000

; --- UI STRINGS ---
str_hud         db 'SCORE   COINS   WORLD  TIME  LIVES', 0
str_world       db '1-1', 0
str_title1      db 'SUPER MARIO', 0
str_title2      db 'x86 ENGINE', 0
str_start       db 'START GAME', 0
str_exit        db 'EXIT', 0
str_arrow       db '>', 0
str_group       db 'ASHAL 543|HAMZA 579|HASSAN 577', 0
str_paused      db 'PAUSED', 0
str_resume      db 'P:RESUME  ESC:TITLE', 0
str_w11         db 'WORLD 1-1', 0
str_livesleft   db 'LIVES LEFT', 0
str_lvlcomp     db 'LEVEL COMPLETE!', 0
str_lcoins      db 'COINS:', 0
str_ltleft      db 'TIME LEFT:', 0
str_ltbon       db 'TIME BONUS:', 0
str_lfinal      db 'FINAL SCORE:', 0
str_enter       db 'PRESS ENTER FOR TITLE', 0
str_gameover    db 'GAME OVER', 0

; --- INITIAL ENEMY TABLE (16 ENEMIES x 8 BYTES = 128 BYTES) ---
; Format: db type (1=goomba,2=koopa), state (1=wait), dw x, dw y, db dir, db timer
orig_enemies:
    db 1, 1
    dw 240, 144
    db 0, 0
    db 1, 1
    dw 380, 144
    db 0, 0
    db 2, 1
    dw 500, 144
    db 0, 0
    db 1, 1
    dw 620, 144
    db 0, 0
    db 1, 1
    dw 650, 144
    db 0, 0
    db 2, 1
    dw 760, 144
    db 0, 0
    db 1, 1
    dw 840, 144
    db 0, 0
    times (MAX_ENEMIES - 7) * ENEMY_SIZE db 0

enemies         times MAX_ENEMIES * ENEMY_SIZE db 0

; --- 64x12 WORLD 1-1 TILE MAP (768 BYTES) ---
orig_map:
    ; Row 0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ; Row 1 (Clouds)
    db 0,0,0,13,0,0,0,0,0,0,13,0,0,0,0,0, 0,0,13,0,0,0,0,0,0,0,13,0,0,0,0,0
    db 0,0,0,0,13,0,0,0,0,0,0,0,13,0,0,0, 0,0,0,0,13,0,0,0,0,0,0,0,0,0,0,0
    ; Row 2
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,10,0,0,0,0
    ; Row 3 (High platforms & flagpole top)
    db 0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0, 0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0
    db 0,0,0,0,0,0,11,11,11,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,10,10,0,12,0,0,0,0
    ; Row 4
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,10,10,10,0,12,0,0,0,0
    ; Row 5
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,10,10,10,10,0,12,0,0,0,0
    ; Row 6 (Question blocks, bricks & coins)
    db 0,0,0,0,0,0,0,0,3,0,2,4,2,3,2,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,11,11,0
    db 0,0,0,0,2,3,2,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,10,10,10,10,10,0,12,0,0,0,0
    ; Row 7
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,10,10,10,10,10,10,0,12,0,0,0,0
    ; Row 8 (Pipe tops)
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,6,7,0,0,0,0,0,0,0,6,7,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,6,7,0,0, 0,0,0,10,10,10,10,10,10,10,0,12,0,0,0,0
    ; Row 9 (Pipe bodies, bushes, flagpole base)
    db 0,0,0,0,0,14,0,0,0,0,0,0,0,0,0,0, 0,8,9,0,0,0,14,0,0,0,8,9,0,0,0,0
    db 0,0,0,14,0,0,0,0,0,0,0,0,8,9,0,0, 0,0,10,10,10,10,10,10,10,10,0,10,0,0,0,0
    ; Row 10 (Ground with 2 pits)
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    ; Row 11 (Sub-ground)
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0
    db 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1

level_map       times MAP_W * MAP_H db 0

; ============================================================================
; 16x16 INDEXED PIXEL BITMAPS (256 BYTES EACH, 0 = TRANSPARENT)
; ============================================================================
spr_mario_s:
    db 0,0,0,0,0,4,4,4,4,4,0,0,0,0,0,0
    db 0,0,0,0,4,4,4,4,4,4,4,4,4,0,0,0
    db 0,0,0,0,6,6,6,42,42,6,42,0,0,0,0,0
    db 0,0,0,6,42,6,42,42,42,6,42,42,42,0,0,0
    db 0,0,0,6,42,6,6,42,42,42,6,42,42,42,0,0
    db 0,0,0,6,6,42,42,42,42,6,6,6,6,0,0,0
    db 0,0,0,0,0,42,42,42,42,42,42,42,0,0,0,0
    db 0,0,0,0,4,4,1,4,4,4,0,0,0,0,0,0
    db 0,0,0,4,4,4,1,4,4,1,4,4,4,0,0,0
    db 0,0,4,4,4,4,1,1,1,1,4,4,4,4,0,0
    db 0,0,42,42,4,1,14,1,1,14,1,4,42,42,0,0
    db 0,0,42,42,42,1,1,1,1,1,1,42,42,42,0,0
    db 0,0,42,42,1,1,1,1,1,1,1,1,42,42,0,0
    db 0,0,0,0,1,1,1,0,0,1,1,1,0,0,0,0
    db 0,0,0,6,6,6,0,0,0,0,6,6,6,0,0,0
    db 0,0,6,6,6,6,0,0,0,0,6,6,6,6,0,0

spr_mario_r:
    db 0,0,0,0,0,4,4,4,4,4,0,0,0,0,0,0
    db 0,0,0,0,4,4,4,4,4,4,4,4,4,0,0,0
    db 0,0,0,0,6,6,6,42,42,6,42,0,0,0,0,0
    db 0,0,0,6,42,6,42,42,42,6,42,42,42,0,0,0
    db 0,0,0,6,42,6,6,42,42,42,6,42,42,42,0,0
    db 0,0,0,6,6,42,42,42,42,6,6,6,6,0,0,0
    db 0,0,0,0,0,42,42,42,42,42,42,42,0,0,0,0
    db 0,0,4,4,4,4,1,4,4,4,4,0,0,0,0,0
    db 0,42,42,4,4,4,1,1,4,4,1,42,42,0,0,0
    db 0,42,42,0,1,1,1,1,1,1,1,42,42,0,0,0
    db 0,0,0,0,1,1,14,1,1,14,1,0,0,0,0,0
    db 0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0
    db 0,0,1,1,1,1,0,0,0,1,1,1,1,0,0,0
    db 0,6,6,6,0,0,0,0,0,0,0,6,6,6,0,0
    db 0,6,6,0,0,0,0,0,0,0,0,0,6,6,6,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

spr_goomba:
    db 0,0,0,0,0,0,6,6,6,6,0,0,0,0,0,0
    db 0,0,0,0,0,6,6,6,6,6,6,0,0,0,0,0
    db 0,0,0,0,6,6,6,6,6,6,6,6,0,0,0,0
    db 0,0,0,6,6,6,6,6,6,6,6,6,6,0,0,0
    db 0,0,6,6,15,15,6,6,6,6,15,15,6,6,0,0
    db 0,6,6,6,15,0,6,6,6,6,0,15,6,6,6,0
    db 0,6,6,6,15,0,6,6,6,6,0,15,6,6,6,0
    db 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
    db 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
    db 0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0
    db 0,0,0,0,42,42,42,42,42,42,42,42,0,0,0,0
    db 0,0,0,42,42,42,42,42,42,42,42,42,42,0,0,0
    db 0,0,0,42,42,42,42,42,42,42,42,42,42,0,0,0
    db 0,0,6,6,6,6,0,0,0,0,6,6,6,6,0,0
    db 0,6,6,6,6,6,0,0,0,0,6,6,6,6,6,0
    db 0,6,6,6,6,6,0,0,0,0,6,6,6,6,6,0

spr_goomba_f:
    times 160 db 0
    db 0,0,6,6,6,6,6,6,6,6,6,6,6,6,0,0
    db 0,6,6,15,0,6,6,6,6,6,6,0,15,6,6,0
    db 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
    db 0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0
    db 0,0,0,42,42,42,42,42,42,42,42,42,0,0,0,0
    db 0,0,6,6,6,6,6,6,6,6,6,6,6,6,0,0

spr_koopa:
    db 0,0,0,0,0,0,0,0,0,10,10,10,0,0,0,0
    db 0,0,0,0,0,0,0,0,10,10,15,10,10,0,0,0
    db 0,0,0,0,0,0,0,0,10,10,15,0,10,0,0,0
    db 0,0,0,0,0,0,0,0,10,10,10,10,10,0,0,0
    db 0,0,0,0,2,2,2,2,0,14,14,14,0,0,0,0
    db 0,0,0,2,10,10,10,2,2,14,14,0,0,0,0,0
    db 0,0,2,10,2,10,2,10,2,14,0,0,0,0,0,0
    db 0,0,2,10,10,10,10,10,2,14,14,0,0,0,0,0
    db 0,0,2,2,10,10,10,2,2,14,14,0,0,0,0,0
    db 0,0,15,15,2,2,2,15,15,0,0,0,0,0,0,0
    db 0,0,0,14,14,14,14,14,0,0,0,0,0,0,0,0
    db 0,0,0,14,14,0,14,14,0,0,0,0,0,0,0,0
    db 0,0,0,14,14,0,14,14,0,0,0,0,0,0,0,0
    db 0,0,42,42,42,0,42,42,42,0,0,0,0,0,0,0
    db 0,42,42,42,42,0,42,42,42,42,0,0,0,0,0,0
    db 0,42,42,42,42,0,42,42,42,42,0,0,0,0,0,0

spr_shell:
    times 80 db 0
    db 0,0,0,0,2,2,2,2,2,2,2,2,0,0,0,0
    db 0,0,0,2,10,10,10,10,10,10,10,10,2,0,0,0
    db 0,0,2,10,2,10,10,10,10,2,10,10,10,2,0,0
    db 0,2,10,10,10,2,2,2,2,10,10,10,10,10,2,0
    db 0,2,10,10,10,10,10,10,10,10,10,10,10,10,2,0
    db 0,2,2,10,10,10,10,10,10,10,10,10,10,2,2,0
    db 0,0,15,15,2,2,2,2,2,2,2,2,15,15,0,0
    db 0,0,0,15,15,15,15,15,15,15,15,15,15,0,0,0
    db 0,0,0,0,14,14,14,14,14,14,14,14,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

spr_mush:
    db 0,0,0,0,0,4,4,4,4,4,4,0,0,0,0,0
    db 0,0,0,4,4,4,15,15,15,15,4,4,4,0,0,0
    db 0,0,4,4,15,15,15,15,15,15,15,15,4,4,0,0
    db 0,4,4,15,15,15,15,15,15,15,15,15,15,4,4,0
    db 0,4,15,15,4,4,15,15,15,15,4,4,15,15,4,0
    db 4,4,15,15,4,4,15,15,15,15,4,4,15,15,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 0,4,4,4,4,4,4,4,4,4,4,4,4,4,4,0
    db 0,0,0,42,42,42,42,42,42,42,42,42,42,0,0,0
    db 0,0,42,42,42,0,42,42,42,42,0,42,42,42,0,0
    db 0,0,42,42,42,0,42,42,42,42,0,42,42,42,0,0
    db 0,0,42,42,42,42,42,42,42,42,42,42,42,42,0,0
    db 0,0,0,42,42,42,42,42,42,42,42,42,42,0,0,0
    db 0,0,0,0,42,42,42,42,42,42,42,42,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

spr_heart1:
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,4,4,4,0,0,0,0,4,4,4,0,0,0,0
    db 0,4,4,15,4,4,0,0,4,4,4,4,4,0,0,0
    db 0,4,15,4,4,4,4,4,4,4,4,4,4,0,0,0
    db 0,4,4,4,4,4,4,4,4,4,4,4,4,0,0,0
    db 0,0,4,4,4,4,4,4,4,4,4,4,0,0,0,0
    db 0,0,0,4,4,4,4,4,4,4,4,0,0,0,0,0
    db 0,0,0,0,4,4,4,4,4,4,0,0,0,0,0,0
    db 0,0,0,0,0,4,4,4,4,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,4,4,0,0,0,0,0,0,0,0
    times 96 db 0

spr_heart0:
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,8,8,8,0,0,0,0,8,8,8,0,0,0,0
    db 0,8,7,7,8,8,0,0,8,8,7,7,8,0,0,0
    db 0,8,7,7,7,8,8,8,8,7,7,7,8,0,0,0
    db 0,8,7,7,7,7,7,7,7,7,7,7,8,0,0,0
    db 0,0,8,7,7,7,7,7,7,7,7,8,0,0,0,0
    db 0,0,0,8,7,7,7,7,7,7,8,0,0,0,0,0
    db 0,0,0,0,8,7,7,7,7,8,0,0,0,0,0,0
    db 0,0,0,0,0,8,7,7,8,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,8,8,0,0,0,0,0,0,0,0
    times 96 db 0
