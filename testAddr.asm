org $8000

;current x,y position
CurrentXPos         equ $857e
CurrentYPos         equ $857f


main:
	ld a,2
	ld (CurrentXPos),a		
	ld (CurrentYPos),a
	
	ld hl, CurrentYPos
	ld d, (hl)
	ld hl, CurrentYPos
	ld e, (hl)
debug2:			; infinite loop for debug
	jr debug2	
	ret
end main