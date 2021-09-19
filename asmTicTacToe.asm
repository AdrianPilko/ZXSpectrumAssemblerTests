org $8000

; ROM macro
cls equ $0d6b

; define the board character as blue block
boardColourAttr equ 00001000b
; define the screen memeory start, for colour attributes
screenStartHoriz_1 equ $58e8
screenStartHoriz_2 equ $5988
screenStartVert_1 equ $584c
screenStartVert_2 equ $5849

call start
ret

start:	
	call cls ; clear the screen using the ROM macro
	ld a,boardColourAttr ; load a with board colour		
; draw tic tac toe board	
	ld hl,screenStartHoriz_1 
	ld b,13	
loop_1: 		
	ld (hl),a
	inc hl
	djnz loop_1
	ld hl,screenStartHoriz_2 
	ld b,13	
loop_2:		
	ld (hl),a
	inc hl
	djnz loop_2	
	
	ld hl,screenStartVert_1 
	ld b,13	
loop_3: 		
	ld (hl),a	
	ld de,32 ; can't use bc as b is the loop counter
	add hl,de
	djnz loop_3

	ret
end start
