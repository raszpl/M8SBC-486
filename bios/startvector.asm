cpu 486
org 0xFFF0

bootentry:
	jmp (0xF000):(0x0100)
	db	"08/29/87"
	db	0x00
	db	0xFC		; Machine type (XT)
	db	0x55		; Checksum