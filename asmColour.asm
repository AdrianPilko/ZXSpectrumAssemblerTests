org $8000

; Define some ROM routines
cls     EQU $0D6B

start:
	; Clear screen
	call cls
	ld b, 31
	ld hl,$5800 ; start of attribute screen memory
	;ld a,$68    ; cyan bright = 0 + 5*8 + 1*64 + 0 = 104  
	ld a,$28    ; cyan dark = 0 + 5*8 + 0*64 + 0*128 = 104  
	; INK + PAPER*8 + BRIGHT*64 + FLASH*128           
	; 0 = black
	; 1 = blue
	; 2 = red
	; 3 = magenta
	; 4 = green
	; 5 = cyan
	; 6 = yellow
	; 7 = white
mainLoop:
	ld b, 3
outerLoop:
	push bc
		ld b, 255
innerLoop:
		ld (hl),a
		inc hl
		djnz innerLoop
		inc a
	pop bc
	djnz outerLoop
	ld hl,$5800 ; start of attribute screen memory
	jr mainLoop
	ret

end start