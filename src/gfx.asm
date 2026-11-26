; module 3, 4, 5: mode 13h double buffer, tile renderer, sprites and bios font

; clear off-screen buffer with sky blue
clrscr:
    push es
    push ax
    push cx
    push di

    mov es, [buf_seg]
    xor di, di
    mov al, COL_SKY
    mov ah, COL_SKY
    mov cx, 32000
    cld
    rep stosw

    pop di
    pop cx
    pop ax
    pop es
    ret

; copy off-screen buffer to VGA memory (0xA000:0000)
flip:
    push ds
    push es
    push cx
    push si
    push di

    mov ax, 0xA000
    mov es, ax
    mov ds, [cs:buf_seg]
    xor si, si
    xor di, di
    mov cx, 32000
    cld
    rep movsw

    pop di
    pop si
    pop cx
    pop es
    pop ds
    ret

; draw filled rectangle on off-screen buffer
; inputs: [bp+12]=x, [bp+10]=y, [bp+8]=w, [bp+6]=h, [bp+4]=col
fillrect:
    push bp
    mov bp, sp
    push es
    push ax
    push bx
    push cx
    push dx
    push di

    mov es, [buf_seg]
    mov dx, [bp+10]         ; y
    mov bx, [bp+6]          ; h
.row:
    cmp bx, 0
    jle .done
    cmp dx, 0
    jl .next_row
    cmp dx, 200
    jge .done

    mov ax, dx
    shl ax, 6
    mov di, dx
    shl di, 8
    add di, ax
    add di, [bp+12]

    mov cx, [bp+8]          ; w
    mov al, [bp+4]          ; col
.col:
    cmp cx, 0
    jle .next_row
    mov [es:di], al
    inc di
    dec cx
    jmp .col

.next_row:
    inc dx
    dec bx
    jmp .row

.done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop es
    pop bp
    ret 10

; draw 16x16 sprite with horizontal flip (bit 0) and 2x height (bit 1)
; inputs: [bp+10]=x, [bp+8]=y, [bp+6]=spr_ptr, [bp+4]=flags
drawsprite:
    push bp
    mov bp, sp
    push es
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov es, [buf_seg]
    mov si, [bp+6]
    mov dx, [bp+8]          ; screen y
    mov cx, 16              ; 16 sprite rows

.srow:
    push cx
    mov bx, 1               ; repeat count (1 for small, 2 for super)
    test word [bp+4], 2
    jz .rep_row
    mov bx, 2

.rep_row:
    cmp dx, 0
    jl .skip_line
    cmp dx, 200
    jge .skip_line

    mov ax, dx
    shl ax, 6
    mov di, dx
    shl di, 8
    add di, ax
    add di, [bp+10]

    push bx
    mov cx, 0               ; column 0..15
.scol:
    cmp cx, 16
    jge .col_done

    mov ax, [bp+10]
    add ax, cx
    cmp ax, 0
    jl .next_px
    cmp ax, 320
    jge .next_px

    mov bx, cx
    test word [bp+4], 1
    jz .no_flip
    mov bx, 15
    sub bx, cx
.no_flip:
    mov al, [si + bx]
    cmp al, 0
    je .next_px
    mov [es:di], al

.next_px:
    inc di
    inc cx
    jmp .scol

.col_done:
    pop bx

.skip_line:
    inc dx
    dec bx
    jnz .rep_row

    add si, 16
    pop cx
    loop .srow

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop es
    pop bp
    ret 8

; print 8x8 character using BIOS ROM font at 0xF000:0xFA6E
; inputs: [bp+10]=x, [bp+8]=y, [bp+6]=char, [bp+4]=col
printchar:
    push bp
    mov bp, sp
    push ds
    push es
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov es, [cs:buf_seg]
    mov ax, 0xF000
    mov ds, ax

    mov si, [bp+6]
    and si, 0x00FF
    shl si, 3
    add si, 0xFA6E

    mov dx, [bp+8]
    mov cx, 8
.crow:
    cmp dx, 0
    jl .cnext
    cmp dx, 200
    jge .cdone

    mov ax, dx
    shl ax, 6
    mov di, dx
    shl di, 8
    add di, ax
    add di, [bp+10]

    mov bl, [ds:si]
    mov bh, 0x80
.cbit:
    test bl, bh
    jz .cskip
    mov al, [bp+4]
    mov [es:di], al
.cskip:
    inc di
    shr bh, 1
    jnz .cbit

.cnext:
    inc si
    inc dx
    loop .crow

.cdone:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop es
    pop ds
    ret 8

; print null-terminated string
; inputs: [bp+10]=x, [bp+8]=y, [bp+6]=str_ptr, [bp+4]=col
printstr:
    push bp
    mov bp, sp
    push ax
    push bx
    push si

    mov bx, [bp+10]
    mov si, [bp+6]
.sloop:
    mov al, [si]
    cmp al, 0
    je .sdone
    xor ah, ah
    push bx
    push word [bp+8]
    push ax
    push word [bp+4]
    call printchar
    add bx, 8
    inc si
    jmp .sloop

.sdone:
    pop si
    pop bx
    pop ax
    pop bp
    ret 8

; reset level_map from orig_map
resetmap:
    push es
    push cx
    push si
    push di

    cld
    push ds
    pop es
    mov si, orig_map
    mov di, level_map
    mov cx, MAP_W * MAP_H
    rep movsb

    pop di
    pop si
    pop cx
    pop es
    ret

; get tile ID at pixel (px, py) -> returns in AL
; inputs: [bp+6]=px, [bp+4]=py
gettile:
    push bp
    mov bp, sp
    push bx

    mov bx, [bp+6]
    shr bx, 4
    cmp bx, 0
    jl .oob
    cmp bx, MAP_W
    jge .oob

    mov ax, [bp+4]
    shr ax, 4
    cmp ax, 0
    jl .oob
    cmp ax, MAP_H
    jge .oob

    shl ax, 6
    add bx, ax
    mov al, [level_map + bx]
    jmp .done

.oob:
    xor al, al
.done:
    pop bx
    pop bp
    ret 4

; set tile ID at pixel (px, py)
; inputs: [bp+8]=px, [bp+6]=py, [bp+4]=tile_id
settile:
    push bp
    mov bp, sp
    push ax
    push bx

    mov bx, [bp+8]
    shr bx, 4
    cmp bx, 0
    jl .done
    cmp bx, MAP_W
    jge .done

    mov ax, [bp+6]
    shr ax, 4
    cmp ax, 0
    jl .done
    cmp ax, MAP_H
    jge .done

    shl ax, 6
    add bx, ax
    mov al, [bp+4]
    mov [level_map + bx], al

.done:
    pop bx
    pop ax
    pop bp
    ret 6

; render visible 16x16 tiles of level_map
drawmap:
    push ax
    push bx
    push cx
    push dx
    push si

    mov cx, 0               ; row 0..11
.mrow:
    cmp cx, MAP_H
    jge .mdone

    mov ax, [camera_x]
    shr ax, 4
    mov dx, ax              ; start col
    mov bx, ax
    add bx, 21              ; end col
    cmp bx, MAP_W
    jle .mcol
    mov bx, MAP_W

.mcol:
    cmp dx, bx
    jge .next_mrow

    mov si, cx
    shl si, 6
    add si, dx
    mov al, [level_map + si]
    cmp al, TILE_SKY
    je .next_mcol

    push bx
    push cx
    push dx

    ; compute screen x, y
    mov ax, dx
    shl ax, 4
    sub ax, [camera_x]      ; sx
    mov bx, cx
    shl bx, 4               ; sy

    ; pick tile color
    mov cl, COL_BROWN
    cmp al, -320            ; dummy
    mov dl, [level_map + si]
    cmp dl, TILE_GROUND
    je .t_ground
    cmp dl, TILE_BRICK
    je .t_brick
    cmp dl, TILE_Q_COIN
    je .t_q
    cmp dl, TILE_Q_MUSH
    je .t_q
    cmp dl, TILE_EMPTY
    je .t_empty
    cmp dl, TILE_STAIR
    je .t_stair
    cmp dl, TILE_COIN
    je .t_coin
    cmp dl, TILE_FLAG
    je .t_flag
    cmp dl, TILE_CLOUD
    je .t_cloud
    cmp dl, TILE_BUSH
    je .t_bush
    mov cl, COL_LGREEN      ; pipes (6..9)
    jmp .draw_t

.t_ground:
    mov cl, COL_BROWN
    jmp .draw_t
.t_brick:
    mov cl, COL_RED
    jmp .draw_t
.t_q:
    mov cl, COL_YELLOW
    jmp .draw_t
.t_empty:
    mov cl, COL_DGRAY
    jmp .draw_t
.t_stair:
    mov cl, COL_ORANGE
    jmp .draw_t
.t_coin:
    mov cl, COL_YELLOW
    push ax
    add ax, 4
    push ax
    add bx, 3
    push bx
    push 8
    push 10
    push cx
    call fillrect
    pop ax
    jmp .t_done
.t_flag:
    push ax
    add ax, 7
    push ax
    push bx
    push 2
    push 16
    push COL_WHITE
    call fillrect
    pop ax
    jmp .t_done
.t_cloud:
    mov cl, COL_WHITE
    jmp .draw_t
.t_bush:
    mov cl, COL_GREEN

.draw_t:
    push ax
    push bx
    push 16
    push 16
    push cx
    call fillrect

.t_done:
    pop dx
    pop cx
    pop bx

.next_mcol:
    inc dx
    jmp .mcol

.next_mrow:
    inc cx
    jmp .mrow

.mdone:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
