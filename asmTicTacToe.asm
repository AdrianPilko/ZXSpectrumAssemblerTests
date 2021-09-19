org $8000

; ROM macro
cls equ $0daf
printStr equ $203c

; define the board character as blue block
boardColourAttr equ 00001000b
; define the screen memeory start, for colour attributes
screenStartHoriz_1	equ $5908
screenStartHoriz_2	equ $59a8
screenStartVert_1	equ $588d
screenStartVert_2	equ $5892
_ink				equ $10
_paper				equ $11
_at					equ $16
_bright				equ $13

call start
ret

start:	
	call cls ; clear the screen and initialise screen stream
	; print game title
	ld de,gameTitleStr
	ld bc,strLen 	
	call printStr
	ld a,boardColourAttr ; load a with board colour		
; draw tic tac toe board	
	ld hl,screenStartHoriz_1 
	ld b,16	
loop_1: 		
	ld (hl),a
	inc hl
	djnz loop_1
	ld hl,screenStartHoriz_2 
	ld b,16
loop_2:		
	ld (hl),a
	inc hl
	djnz loop_2		
	ld hl,screenStartVert_1 
	ld b,14	
loop_3: 		
	ld (hl),a	
	ld de,32 ; can't use bc as b is the loop counter
	add hl,de
	djnz loop_3
	ld hl,screenStartVert_2
	ld b,14		
loop_4: 		
	ld (hl),a	
	ld de,32 ; can't use bc as b is the loop counter
	add hl,de
	djnz loop_4
	ret
gameTitleStr	defb _at, 0, 0, _ink, 1, _paper, 6, _bright, 1, "      Noughts and Crosses      "
strLen			equ $ - gameTitleStr
end start
