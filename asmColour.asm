org $8000

; Define some ROM routines
cls     EQU $0D6B

start:
	; Clear screen
	call cls

	ld a,$eb   ; blue and purple
	ld ($5800),a
	ld ($5810),a
	ld ($5812),a
	ld ($5814),a
	ld ($5814),a
	
	ret

end start