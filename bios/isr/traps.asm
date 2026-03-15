;
; Based on work by b-dmitry1
; Copyright (c) 2025 b-dmitry1
; Licensed under the MIT License.
;

; Traps / faults
; If your system working properly this will never be executed
;
; Added with A2.01: Printing stack dump on VGA text screen
;


trap:
    ; POST EE - Real mode exception. POST code n-1 shows exception interrupt
	out 0x80, al
	mov al, 0xEE
	out 0x80, al
    
    ; Code below additionally prints expection and stack dump on the screen. Assuming video is working and current mode is text
    ; No RAM usage
    
    mov dx, 0xB800      ; VGA segment
	mov es, dx
	; xor di, di          ; Start at the top left corner (0,0)
    mov di, 3840          ; Bottom left corner (0,24)
	cld 
    
    ; Print exception letter from bl
    mov al, bl
    mov ah, 0x4F        ; White text on red background
    stosw               ; word store
	
    ; separators
    mov al, ':'
    stosw
    mov al, ' '
    stosw
    
    ; Stack dump print
    mov bp, sp
    mov cx, 8           ; Words amount, 8 words
    
.dump_word:
    mov dx, ss:[bp]     ; dx - val
    add bp, 2
    
    mov bh, 4           ; 4 nibbles in word
.print_nibble:
    rol dx, 4
    mov al, dl
    and al, 0x0F
    cmp al, 9
    jbe .is_digit
    add al, 7
.is_digit:
    add al, '0'
    mov ah, 0x4F        ; Attribute
    stosw
    dec bh
    jnz .print_nibble
    
    ; Space between words
    mov al, ' '
    mov ah, 0x4F
    stosw
    
    dec cx
    jnz .dump_word
    
    cli
.halt:
    hlt
	jmp .halt

int00:
	mov bl, '0' ; Divide by 0
    mov al, 0x00
	jmp trap

int01:
	iret
	mov bl, '1' ; Reserved
    mov al, 0x01
	jmp trap

int02:
	mov bl, '2' ; NMI Interrupt
    mov al, 0x02
	jmp trap

int03:
	mov bl, '3' ; Breakpoint
    mov al, 0x03
	jmp trap

int04:
	mov bl, '4' ; Overflow
    mov al, 0x04
	jmp trap

int05:
	mov bl, '5' ; Bounds range exceeded
    mov al, 0x05
	jmp trap

int06:
	mov bl, '6' ; Invalid opcode
    mov al, 0x06
	jmp trap

int07:
	push bp
	mov bp, sp
	add word [bp + 2], 2
	pop bp
	iret
	mov bl, '7' ; Device not available
	jmp trap
