
	; Set interrupt controller (PICs 8259) registers
	mov al, 0x11	; ICW1: Edge triggered mode, cascade, ICW4 needed
	out 0x20, al
	mov al, 0x08	; ICW2: Table start at 8
	out 0x21, al
	mov al, 0x00	; ICW3: No slave
	out 0x21, al
	mov al, 0x01	; ICW4: 8086 mode, normal EOI
	out 0x21, al
	mov al, 0x00	; OCW1: enable IRQs 0-7
	out 0x21, al
	mov al, 0x20	; OCW2: end of interrupt just in case
	out 0x20, al
	mov al, 0x08	; OCW3: reset OCW3
	out 0x20, al


; No return from here (inline code!)
