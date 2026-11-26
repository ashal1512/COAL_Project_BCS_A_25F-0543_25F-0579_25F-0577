; module 11, 12, 13, 14, 15: enemies, blocks, score, hud and states

; subroutine to add points to 32-bit score using add/adc
; inputs on stack: [bp+4]=points
addscore:
    push bp
    mov bp, sp
    push ax

    mov ax, [bp+4]
    add [score_lo], ax
    adc word [score_hi], 0

    cmp word [score_hi], 0x000f
    jl .done
    jg .clamp
    cmp word [score_lo], 0x423f
    jbe .done
.clamp:
    mov word [score_hi], 0x000f
    mov word [score_lo], 0x423f
.done:
    pop ax
    pop bp
    ret 2

; subroutine to add 1 coin (+200 pts, 1-up at 100 coins)
addcoin:
    push ax
    push 200
    call addscore
    inc byte [coins]
    cmp byte [coins], 100
    jl .done
    mov byte [coins], 0
    cmp byte [lives], 99
    jge .done
    inc byte [lives]
.done:
    pop ax
    ret

; subroutine to print 16-bit number with N digits using division by 10
; inputs on stack: [bp+12]=x, [bp+10]=y, [bp+8]=num, [bp+6]=digits, [bp+4]=col
printnum:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx

    mov ax, [bp+8]
    mov cx, [bp+6]
    mov bx, 10
.nextdigit:
    xor dx, dx
    div bx
    add dl, 0x30
    push dx
    loop .nextdigit

    mov cx, [bp+6]
    mov bx, [bp+12]
.nextpos:
    pop ax
    push bx
    push word [bp+10]
    push ax
    push word [bp+4]
    call printchar
    add bx, 8
    loop .nextpos

    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 10

; subroutine to print 6-digit 32-bit score
; inputs on stack: [bp+8]=x, [bp+6]=y, [bp+4]=color
printscore:
    push bp
    mov bp, sp
    push ax
    push bx
    push dx

    mov ax, [score_lo]
    mov dx, [score_hi]
    mov bx, 1000
    div bx

    push word [bp+8]
    push word [bp+6]
    push ax
    push 3
    push word [bp+4]
    call printnum

    mov ax, [bp+8]
    add ax, 24
    push ax
    push word [bp+6]
    push dx
    push 3
    push word [bp+4]
    call printnum

    pop dx
    pop bx
    pop ax
    pop bp
    ret 6

; subroutine to draw top hud bar
drawhud:
    push ax

    push 8
    push 0
    push str_hud
    push COL_ORANGE
    call printstr

    push 8
    push 8
    push COL_WHITE
    call printscore

    push 72
    push 8
    push 'x'
    push COL_WHITE
    call printchar

    push 80
    push 8
    xor ah, ah
    mov al, [coins]
    push ax
    push 2
    push COL_WHITE
    call printnum

    push 128
    push 8
    push str_world
    push COL_WHITE
    call printstr

    push 176
    push 8
    push word [game_time]
    push 3
    push COL_WHITE
    call printnum

    push 224
    push 8
    push 'x'
    push COL_WHITE
    call printchar

    push 232
    push 8
    xor ah, ah
    mov al, [lives]
    push ax
    push 2
    push COL_WHITE
    call printnum

    push 280
    push 8
    push spr_heart1
    push 0
    call drawsprite

    push 292
    push 8
    cmp byte [mario_hp], 2
    je .hfull
    push spr_heart0
    jmp .dh2
.hfull:
    push spr_heart1
.dh2:
    push 0
    call drawsprite

    pop ax
    ret
