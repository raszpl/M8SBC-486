;
; PC speaker driver - fatal error handling (base memory test fail)
; No mem used
;

pc_spk_beep_error:
    ; take amount of beeps in CX
    ; each beep is 880Hz with 0.5s delay
    mov al, 0x00
    out 0x61, al

    mov al, 00110000b       ; ch0 | lobyte/hibyte | mode 0 | binary
    out 0x43, al

    mov al, 10110110b       ; ch2 | lobyte/hibyte | mode 3 | binary
    out 0x43, al
    mov ax, 1355            ; 880Hz
    out 0x42, al
    mov al, ah
    out 0x42, al 

    mov bp, cx              ; Save the number of beeps to repeat the sequence

.repeat_sequence:
    mov cx, bp              ; Restore the number of beeps for this sequence

.loop_beep:
    ; --- BEEP OFF ---
    mov al, 0x00
    out 0x61, al
    
    ; --- WAIT 0.5s ---
    mov bx, 9               ; wait 9 * 1/18s = 0.5s
.wait_outer_1:
    mov ax, 0FFFFh          ; Load max count for longest delay, about 1/18s
    out 0x40, al            ; Send low byte
    mov al, ah
    out 0x40, al            ; Send high byte
.wait_for_cnt_1:
    mov al, 11000010b       ; Command: Read-Back, !COUNT, STATUS, Channel 0
    out 0x43, al
    in al, 0x40
    test al, 10000000b      ; Check if count is null (timer finished)
    jz .wait_for_cnt_1
    dec bx
    jnz .wait_outer_1

    ; --- BEEP ON ---
    mov al, 0x03
    out 0x61, al

    ; --- WAIT 0.5s ---
    mov bx, 9               ; wait 9 * 1/18s = 0.5s
.wait_outer_2:
    mov ax, 0FFFFh
    out 0x40, al
    mov al, ah
    out 0x40, al
.wait_for_cnt_2:
    mov al, 11000010b
    out 0x43, al
    in al, 0x40
    test al, 10000000b
    jz .wait_for_cnt_2
    dec bx
    jnz .wait_outer_2

    loop .loop_beep

    ; --- Turn speaker off after the beeps for the current error code are done ---
    mov al, 0x00
    out 0x61, al

    ; --- WAIT 3s ---
    mov bx, 54              ; wait 54 * 1/18s = 3s
.wait_outer_3:
    mov ax, 0FFFFh
    out 0x40, al
    mov al, ah
    out 0x40, al
.wait_for_cnt_3:
    mov al, 11000010b
    out 0x43, al
    in al, 0x40
    test al, 10000000b
    jz .wait_for_cnt_3
    dec bx
    jnz .wait_outer_3

    jmp .repeat_sequence     ; Repeat the whole beep sequence