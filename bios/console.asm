	; Display 1 char (TTY)
	; AL = char
putchv:
	push ax
	mov ah, 0xE
	int 0x10
	pop ax
	ret

	; Display string (TTY)
	; CS:SI = string
putsv:
	push ax
putsv_loop:
	mov al, [cs:si]
	inc si
	cmp al, 0
	jz putsv_done
	call putchv
	jmp putsv_loop
putsv_done:
	pop ax
	ret

	; Display hex byte
	; AL = value
print_hexv:
	push ax
	push bx
	mov bl, al
	shr al, 1
	shr al, 1
	shr al, 1
	shr al, 1
	and al, 0x0F
	cmp al, 10
	jge print_hexv_1
	add al, '0'
	call putchv
	jmp print_hexv_2
print_hexv_1:
	add al, 'A' - 10
	call putchv
print_hexv_2:
	mov al, bl
	and al, 0x0F
	cmp al, 10
	jge print_hexv_3
	add al, '0'
	call putchv
	jmp print_hexv_4
print_hexv_3:
	add al, 'A' - 10
	call putchv
print_hexv_4:
	pop bx
	pop ax
	ret

	; Display signed 16-bit value
	; AX = value
print_i16v:
	test ax, 0x8000
	jz print_u16v
	push ax
	mov al, '-'
	call putchv
	pop ax
	neg ax
	; Display unsigned 16-bit value
	; AX = value
print_u16v:
	push ax
	push bx
	push cx
	push dx
	or ax, ax
	jnz print_u16v_nz
	mov al, '0'
	call putchv
	pop dx
	pop cx
	pop bx
	pop ax
	ret
print_u16v_nz:
	mov bx, 10
	mov cx, 5
print_u16v_loop1:
	xor dx, dx
	div bx
	and dl, 0x0F
	push dx
	loop print_u16v_loop1

	mov cx, 5
print_u16v_loop2:
	pop ax
	or al, al
	jnz print_u16v_nz1
	loop print_u16v_loop2

print_u16v_nz1:
	push ax

print_u16v_loop3:
	pop ax
	add al, 0x30
	call putchv
	loop print_u16v_loop3

	pop dx
	pop cx
	pop bx
	pop ax

	ret

