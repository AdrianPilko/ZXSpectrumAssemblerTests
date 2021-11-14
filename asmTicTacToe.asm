org $8000

; ROM macros 
clear_screen	equ $0d6b
open_screen  	equ $1601
print_text  	equ $203c


; define the board character as blue block
boardColourAttr equ 00010101b
; define the screen memeory start, for colour attributes
cursorPos			equ $5805
screenStartHoriz_1	equ $5908
screenStartHoriz_2	equ $59a8
screenStartVert_1	equ $588d
screenStartVert_2	equ $5892
lastKey				equ $5c08
; define screen attributes for text print
_ink				equ $10
_paper				equ $11
_at					equ $16
_bright				equ $13

;current x,y position
CurrentXPos         equ $a000
CurrentYPos         equ $a001

call start
ret

start:		
	call clear_screen ; clear the screen and initialise screen stream
	call open_screen
	; print game title
	ld de,gameTitleStr
	ld bc,strLen 	
	call print_text
	ld a,boardColourAttr ; load a with board colour		

	ld hl,screenStartHoriz_1 ; draw noughts and crosses (tic tac toe) criss-cross board	
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

	; initialise the current x,y to zero
	ld a, 8
	ld (CurrentXPos),a
	ld (CurrentYPos),a
	
gameLoop:
	call Read_Keyboard ; register A should now contain the key pressed first nibble is row, second is column
	cp $50            ; 50 is row column on keyboard matrix for P
	call z, moveRight
	cp $4F            ; 4F is row column on keyboard matrix for O
	call z, moveLeft	
	cp $41            ; 41 is row column on keyboard matrix for A
	call z, moveUp
	cp $5A            ; 5A is row column on keyboard matrix for Z
	call z, moveDown		
	

	; temporarily place n X or O, depending on whos go it is at the location no at
	LD A, 88                ; Character to print
	LD D, (CurrentYPos)       ; Y position
	LD E, (CurrentXPos)       ; X position
	call Print_Char         ; Print the character

	jr gameLoop	
	
Read_Keyboard:          LD HL,Keyboard_Map      ; Point HL at the keyboard list
                        LD D,8                  ; This is the number of ports (rows) to check
                        LD C,&FE                ; C is always FEh for reading keyboard ports
Read_Keyboard_0:        LD B,(HL)               ; Get the keyboard port address from table
                        INC HL                  ; Increment to list of keys
                        IN A,(C)                ; Read the row of keys in
                        AND &1F                 ; We are only interested in the first five bits
                        LD E,5                  ; This is the number of keys in the row
Read_Keyboard_1:        SRL A                   ; Shift A right; bit 0 sets carry bit
                        JR NC,Read_Keyboard_2   ; If the bit is 0, we've found our key
                        INC HL                  ; Go to next table address
                        DEC E                   ; Decrement key loop counter
                        JR NZ,Read_Keyboard_1   ; Loop around until this row finished
                        DEC D                   ; Decrement row loop counter
                        JR NZ,Read_Keyboard_0   ; Loop around until we are done
                        AND A                   ; Clear A (no key found)
                        RET
Read_Keyboard_2:        LD A,(HL)               ; We've found a key at this point; fetch the character code!
                        RET

moveRight:
	ld de,gameTitleStrR
	ld bc,strLenR 	
	call print_text
	
	; this currently doesn't work the character doesn't move....
	ld a, CurrentXPos ; load from memory where x position is stored
	add a,1			  ; increment the register a (x position = x position + 1)
	ld (CurrentXPos), a ; store the x position back to memory
	ret
moveLeft:	
	ld de,gameTitleStrL
	ld bc,strLenL 	
	call print_text
	ld a, CurrentXPos ; load from memory where x position is stored
	ld b,1
	sbc a,b			  ; decrement the register a (x position = x position - 1)
	ld (CurrentXPos), a ; store the x position back to memory
	ret	
moveUp:
	ld de,gameTitleStrU
	ld bc,strLenU 	
	call print_text
	ld a, CurrentYPos ; load from memory where y position is stored
	ld b, 1
	sbc a,1			  ; increment the register a (y position = y position - 1)
	ld (CurrentYPos), a ; store the y position back to memory
	ret
moveDown:	
	ld de,gameTitleStrD
	ld bc,strLenD 	
	call print_text
	ld a, CurrentYPos ; load from memory where y position is stored
	ld b,1
	add a,b			  ; increment the register a (y position = y position + 1)
	ld (CurrentYPos), a ; store the y position back to memory	
	ret		
clearKey:
		
drawCross:
		ret
drawCircle:
		ret
		
gameTitleStr	defb _at, 0, 0, _ink, 1, _paper, 6, _bright, 1, "      Noughts and Crosses      "
strLen			equ $ - gameTitleStr

gameTitleStrL	defb _at, 0, 0, _ink, 1, _paper, 6, _bright, 1, "L     Noughts and Crosses      "
strLenL			equ $ - gameTitleStrL

gameTitleStrR	defb _at, 0, 0, _ink, 1, _paper, 6, _bright, 1, " R    Noughts and Crosses      "
strLenR			equ $ - gameTitleStrR

gameTitleStrU	defb _at, 0, 0, _ink, 1, _paper, 6, _bright, 1, "  U   Noughts and Crosses      "
strLenU			equ $ - gameTitleStrU

gameTitleStrD	defb _at, 0, 0, _ink, 1, _paper, 6, _bright, 1, "   D  Noughts and Crosses      "
strLenD			equ $ - gameTitleStrD

Keyboard_Map    defb &FE,"#","Z","X","C","V"	
				defb &FD,"A","S","D","F","G"
				defb &FB,"Q","W","E","R","T"
				defb &F7,"1","2","3","4","5"
				defb &EF,"0","9","8","7","6"
				defb &DF,"P","O","I","U","Y"
				defb &BF,"#","L","K","J","H"
				defb &7F," ","#","M","N","B"


; CREDIT TO: 
; http://www.breakintoprogram.co.uk/computers/zx-spectrum/assembly-language/z80-tutorials/print-in-assembly-language/2
; Print a single character out to a screen address
;  A: Character to print
;  D: Character Y position
;  E: Character X position
;
Print_Char:             LD HL, 0x3C00           ; Character set bitmap data in ROM
                        LD B,0                  ; BC = character code
                        LD C, A
                        SLA C                   ; Multiply by 8 by shifting
                        RL B
                        SLA C
                        RL B
                        SLA C
                        RL B
                        ADD HL, BC              ; And add to HL to get first byte of character
                        CALL Get_Char_Address   ; Get screen position in DE
                        LD B,8                  ; Loop counter - 8 bytes per character
Print_Char_L1:          LD A,(HL)               ; Get the byte from the ROM into A
                        LD (DE),A               ; Stick A onto the screen
                        INC HL                  ; Goto next byte of character
                        INC D                   ; Goto next line on screen
                        DJNZ Print_Char_L1      ; Loop around whilst it is Not Zero (NZ)
                        RET
 
; Get screen address from a character (X,Y) coordinate
; D = Y character position (0-23)
; E = X character position (0-31)
; Returns screen address in DE
;
Get_Char_Address:       LD A,D
                        AND %00000111
                        RRA
                        RRA
                        RRA
                        RRA
                        OR E
                        LD E,A
                        LD A,D
                        AND %00011000
                        OR %01000000
                        LD D,A
                        RET   
						
end start
