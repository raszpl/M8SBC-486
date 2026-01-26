; Cache memory routines
;

cache_enable:
	
	; cache enable
    mov eax, cr0
    and eax , 0x9FFFFFFF ; enable cache, 9 = 1001 
    mov cr0, eax
    wbinvd

	ret
