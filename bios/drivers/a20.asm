; A20 line control routines
;

; a20_enable
; Enables A20..A31 access
; In:
;   none
; Out:
;   none
a20_enable:

	ret

; a20_disable
; Disables A20..A31 access
; In:
;   none
; Out:
;   none
a20_disable:

	ret

; a20_get
; Returns A20 state
; In:
;   none
; Out:
;   AL = 0 - A20 disabled, 1 - A20 enabled
a20_get:
	mov al, 1
	ret
