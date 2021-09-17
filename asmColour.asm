org $8000

; Define some ROM routines
cls     EQU $0D6B

start:
	; Clear screen
	call cls

	ld a,$d6
	ld ($5800),a
	ld ($5810),a
	ld ($5920),a
	ld ($5a00),a
	ld ($5a30),a

	ret

end start