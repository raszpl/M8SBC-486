;
; Base 64K memory test, ran before init of the rest hardware
; Inline include
;

base_memory_test:
    ; Test first 64KB of memory with 0xA5A5 and 0x5A5A patterns. 
    ; 1st write 0xA5A5

    mov ax, 0xA5A5
    mov di, 0x0000
    mov cx, 0x8000 ; 64KB / 2 bytes
    rep stosw
    ; 1st verify 0xA5A5
    mov ax, 0xA5A5
    mov di, 0x0000
    mov cx, 0x8000
    cld
.verify_a5a5:
    lodsw
    cmp ax, 0xA5A5
    jne .mem_error
    loop .verify_a5a5

    ; 2nd write 0x5A5A
    mov ax, 0x5A5A
    mov di, 0x0000
    mov cx, 0x8000
    rep stosw
    ; 2nd verify 0x5A5A
    mov ax, 0x5A5A
    mov di, 0x0000
    mov cx, 0x8000
    cld
.verify_5a5a:
    lodsw
    cmp ax, 0x5A5A
    jne .mem_error
    loop .verify_5a5a

    jmp .done ; Pass

.mem_error: ; Fail
    mov cx, 2
    jmp pc_spk_beep_error

.done: