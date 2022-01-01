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
CurrentXPos         equ $857e
CurrentYPos         equ $857f
PreviousXPos        equ $8580
PreviousYPos        equ $8581
wasAMoveFlag        equ $8582
whoseMoveIsIt		equ $8583  ;if zero then naughts, non zero crosses
loopCounterTemp		equ $8586  
loopCounterTemp2	equ $8587 
posYTemp			equ $8588
posXTemp			equ $8589

MovesAccross		equ $858a
MovesDown			equ $858b
BoardTempIndex		equ $858c
nextPlayerTurnFlag  equ $858d

ROM_PRINT               EQU  0x203C 

call start
ret

; we store the board state in this block of memory		
; a zero inidcates no move, 1 indicates an X, 2 is an O
boardStore defb 	0
boardStore1 defb    0
boardStore2 defb	0
boardStore3 defb	0
boardStore4 defb	0
boardStore5 defb	0
boardStore6 defb	0
boardStore7 defb	0
boardStore8 defb	0
 
boardStoreXPos defb 	11,11,11,15,15,15,21,21,21
boardStoreYPos defb 	6,6,6,10,10,10,15,15,15  

;; define the "bitmap" for the naught and cross
crossBig  defb 1
crossBig1  defb 			   0
crossBig2  defb 			   0
crossBig3  defb 			   1
crossBig4  defb 0
crossBig5  defb 			   1
crossBig6  defb 1
crossBig7  defb 			   0
crossBig8  defb 			   0
crossBig9  defb 			   1
crossBig10  defb 			   1
crossBig11  defb 			   0
crossBig12  defb 			   1
crossBig13  defb 			   0
crossBig14  defb 			   0
crossBig15  defb 			   1   ; i know this is wasteful of memory!
naughtBig defb 0
naughtBig1  defb 1
naughtBig2  defb 1
naughtBig3  defb 0
naughtBig4  defb 1
naughtBig5  defb 0
naughtBig6  defb 0
naughtBig7  defb 1
naughtBig8  defb 1
naughtBig9  defb 0
naughtBig10  defb 0
naughtBig11  defb 1
naughtBig12  defb 0
naughtBig13  defb 1
naughtBig14  defb 1
naughtBig15  defb 0		

drawNaughOrCross			; draw naught or cross at position CurrentYPos CurrentXPos
	ld a,(CurrentYPos)
	ld (posYTemp),a
	ld a, (CurrentXPos)
	ld (posXTemp),a
	
	ld a,4
	ld (loopCounterTemp),a
	ld (loopCounterTemp2),a	
	
	ld a, (whoseMoveIsIt)
	ld hl,crossBig  ; ultimately will be either naught or cross big
	and 1	; compare a, if zero then draw cross, if 1 draw naught
	jp z,drawNaughOrCross_LoopCross
	ld hl,naughtBig  ; ultimately will be either naught or cross big
	
drawNaughOrCross_LoopNaught			
	ld a, (posXTemp)     ;; current y pos in e for Print_Char
	ld e,a
	ld a, (posYTemp)	 ;; current y pos in d for Print_Char
	ld d,a
	
	ld a, (hl)
	inc hl 

	cp 1
	jp z, drawNaughOrCross_SetNaught
	ld a,32					;; load space character 
	jp drawNaughOrCross_CallPrintChar
drawNaughOrCross_SetNaught			
	ld a,79					;; set register a to the O char, next condition jump skips overwriting with space 	
drawNaughOrCross_CallPrintChar
	push hl
	call Print_Char
	pop hl	
	
	
	ld a,(posYTemp)
	inc a 
	ld (posYTemp),a
	
	ld a,(loopCounterTemp)	;; this loop max set to 4 initally
	dec a		
	ld (loopCounterTemp),a	
	jp z, drawNaughOrCross_resetYIncX	
	jp drawNaughOrCross_LoopNaught
	
drawNaughOrCross_resetYIncX
	ld a,(CurrentYPos)
	ld (posYTemp),a
	ld a,(posXTemp)
	inc a
	ld (posXTemp), a
	
	ld a,4					; reset inner loop
	ld (loopCounterTemp),a	; reset inner loop
	ld a,(loopCounterTemp2)
	dec a
	ld (loopCounterTemp2),a
	jp nz, drawNaughOrCross_LoopNaught
	jp drawNaughOrCross_endFunc
	
drawNaughOrCross_LoopCross	
	ld a, (posXTemp)     ;; current y pos in e for Print_Char
	ld e,a
	ld a, (posYTemp)	 ;; current y pos in d for Print_Char
	ld d,a
	
	ld a, (hl)
	inc hl

	cp 1
	jp z, drawNaughOrCross_SetCross
	ld a,32					;; load space character 
	jp drawNaughOrCross_CallPrintCharX
drawNaughOrCross_SetCross			
	ld a,88					;; set register a to the O char, next condition jump skips overwriting with space 	
drawNaughOrCross_CallPrintCharX
	push hl
	call Print_Char
	pop hl	
	
	ld a,(posYTemp)
	inc a 
	ld (posYTemp),a
	
	ld a,(loopCounterTemp)	;; this loop max set to 4 initally
	dec a		
	ld (loopCounterTemp),a
	
	jp z, drawNaughOrCross_resetYIncX_X	
	jp drawNaughOrCross_LoopCross
	
drawNaughOrCross_resetYIncX_X
	ld a,(CurrentYPos)
	ld (posYTemp),a

	ld a,(posXTemp)
	inc a
	ld (posXTemp), a
	
	ld a,4					; reset inner loop
	ld (loopCounterTemp),a	; reset inner loop
	ld a,(loopCounterTemp2)
	dec a
	ld (loopCounterTemp2),a
	jp nz, drawNaughOrCross_LoopCross
	jp drawNaughOrCross_endFunc	
   	
drawNaughOrCross_endFunc	
	ret

start:		
	ld a, 0
	ld (MovesAccross),a		; initialise some flags and index
	ld (MovesDown),a
	ld (nextPlayerTurnFlag),a
	
	call clear_screen ; clear the screen and initialise screen stream
	call open_screen
	; print game title
	ld de,gameTitleStr
	ld bc,strLen 	
	call print_text

	ld a,1					; crosses go first
	ld (whoseMoveIsIt),a
	
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

	; initialise the current x,y and the last x,y = current at this point
	
	ld a,8
	ld (CurrentXPos),a		
	ld (PreviousXPos), a
	ld a,4
	ld (CurrentYPos),a
	ld (PreviousYPos), a
	ld a,0
	ld (wasAMoveFlag),a	
	jr readKeyboard 

gameLoop:

	; save the previous x y positions to memory so we can overwrite with blank after move
	ld a, (CurrentXPos)	
	ld (PreviousXPos), a
	ld a, (CurrentYPos)	
	ld (PreviousYPos), a
	ld a,0
	ld (wasAMoveFlag),a	
	
readKeyboard:	
	call Read_Keyboard ; register A should now contain the key pressed first nibble is row, second is column
	cp $50            ; 50 is row column on keyboard matrix for P
	call z, moveRight
	cp $4F            ; 4F is row column on keyboard matrix for O
	call z, moveLeft	
	cp $41            ; 41 is row column on keyboard matrix for A
	call z, moveUp
	cp $5A            ; 5A is row column on keyboard matrix for Z
	call z, moveDown		
	cp $4d            ; 
	call z, makeMove		
		
	call delaySome
	
	; temporarily place n X or O, depending on whos go it (whoseMoveIsIt) is at the location no at	
	call drawNaughOrCross	; if wasAMove zero then go back to game loop 	
	
	ld a, (wasAMoveFlag) ; load from memory where x position is stored
	cp 1  ; check if flag was set
	jp z, gameLoop 
	
	ld a, (nextPlayerTurnFlag)
	jp nz, gameLoop
	
	call clearPrevious; if wasAMove zero then go back to game loop 	
	jp gameLoop
	ret
	
clearPrevious:	; clear the previous location
	ld a,(PreviousYPos)
	ld (posYTemp),a
	ld a, (PreviousXPos)
	ld (posXTemp),a
	
	ld a,4
	ld (loopCounterTemp),a
	ld (loopCounterTemp2),a	
	
clearPrevious_Loop			
	ld a, (posXTemp)     ;; current y pos in e for Print_Char
	ld e,a
	ld a, (posYTemp)	 ;; current y pos in d for Print_Char
	ld d,a
	ld a,32					;; load space character
	call Print_Char
	
	
;	inc e			;; DEBUG
;	ld a,78					
;	call Print_Char
	
	ld a,(posYTemp)
	inc a 
	ld (posYTemp),a
	
	ld a,(loopCounterTemp)	;; this loop max set to 4 initally
	dec a		
	ld (loopCounterTemp),a	
	jp z, clearPrevious_resetYIncX	
	jp clearPrevious_Loop
	
clearPrevious_resetYIncX
	ld a,(PreviousYPos)
	ld (posYTemp),a

	ld a,(posXTemp)
	inc a
	ld (posXTemp), a
	
	ld a,4					; reset inner loop
	ld (loopCounterTemp),a	; reset inner loop
	ld a,(loopCounterTemp2)
	dec a
	ld (loopCounterTemp2),a
	jp nz, clearPrevious_Loop
	jp clearPrevious_endFunc
  	
clearPrevious_endFunc	
	ret


;CREDIT TO: 
; http://www.breakintoprogram.co.uk/computers/zx-spectrum/keyboard
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
						
makeMove
	ld a, (whoseMoveIsIt)
	and 1
	jr z, makeMove_printMoveO
	ld de,gameTitleStrMove_X  ; print debug to show Move and current is cross to go 
	ld bc,strLenMove_X 	
	call print_text
	
	ld a,0                    ;; save move toggle now crosses = 1
	ld (whoseMoveIsIt),a
	jr makeMove_endFunc
	
makeMove_printMoveO	
	ld de,gameTitleStrMove_O  ; print debug to show Move and current is cross to go 
	ld bc,strLenMove_O 	
	call print_text
	ld a, 1					;; save move toggle now crosses = 1
	ld (whoseMoveIsIt),a

;;;; todo: print the big version of naught or crosses

makeMove_endFunc
	;; calculate the offset
	;; offset = (accross * 3) + down
	ld hl, MovesDown
	ld a, (hl)
	add a, (hl)		; is no multiply, only add, so add 2 more times to get * 3
	add a, (hl)
	ld hl, MovesAccross
	add a, (hl)
	ld (BoardTempIndex),a

	;di
;debugXXX
	;jp  debugXXX
	;ei
	
	ld hl, boardStore   ; the board state "store"
	ld de, (BoardTempIndex) ; load the index offset we just calculated into de
	add hl,de			; the address of the de'th element of the board state array is now in hl
	ld (hl), 1			; in the board state 0=empty square, 1=naught, 2=cross, 
;	di
;debugXXX
	;jp  debugXXX
	;ei
	
	;  flag the fact the player set the move, this is used to control if current place is overritten
	ld a, 1
	ld (nextPlayerTurnFlag),a
	ret

moveRight:
	ld a,1
	ld (wasAMoveFlag),a
	ld de,gameTitleStrR
	ld bc,strLenR 	
	call print_text
	
	ld a, (CurrentXPos) ; load from memory where x position is stored
	cp 20  ; limit x pos to width of screen
	jp z,skipMR
	add a,6			  ; increment the register a (x position = x position + 1)
	ld (CurrentXPos), a ; store the x position back to memory
	
	ld a,(MovesAccross) ;; increment and store MovesAccross index
	inc a
	ld (MovesAccross),a
skipMR:	
	; do nothing, no change to CurrentXPos

	ret
moveLeft:	
	ld a,1
	ld (wasAMoveFlag),a
	ld de,gameTitleStrL
	ld bc,strLenL 	
	call print_text
		
	ld a, (CurrentXPos) ; load from memory where x position is stored
	cp 8	;limit x pos to minimum of left of screen (zero)
	jp z, skipML
	
	sub 6			  ; decrement the register a (x position = x position - 1)	
	ld (CurrentXPos), a ; store the x position back to memory
	
	ld a,(MovesAccross) ;; decrement  store MovesAccross index
	dec a
	ld (MovesAccross),a
skipML:	
	; do nothing, no change to CurrentXPos	
	ret	
	
moveUp:
	ld a,1
	ld (wasAMoveFlag),a
	ld de,gameTitleStrU
	ld bc,strLenU 	
	call print_text
	ld a, (CurrentYPos) ; load from memory where y position is stored
	cp 4
	jp z, skipMU

	sub 5			  ; decrement the register a (y position = y position - 1)
	ld (CurrentYPos), a ; store the y position back to memory
	
	ld a,(MovesDown) ;; decrement and store MovesDown index
	dec a
	ld (MovesDown),a
skipMU: 
	ret
	
moveDown:	
	ld a,1
	ld (wasAMoveFlag),a
	ld de,gameTitleStrD
	ld bc,strLenD 	
	call print_text
	ld a, (CurrentYPos) ; load from memory where y position is stored	
	cp 14
	jp z,skipMD
	add a,5		  ; increment the register a (y position = y position + 1)
	ld (CurrentYPos), a ; store the y position back to memory	
	
	ld a,(MovesDown) ;;increment and store MovesDown index
	inc a
	ld (MovesDown),a
skipMD: 
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

gameTitleStrMove	defb _at, 0, 0, _ink, 1, _paper, 6, _bright, 1, "      Noughts and Crosses, Move"
strLenMove			equ $ - gameTitleStrMove

gameTitleStrMove_X defb _at, 0, 0, _ink, 1, _paper, 6, _bright, 1, "      Noughts and Crosses,MoveX"
strLenMove_X	    equ $ - gameTitleStrMove_X

gameTitleStrMove_O defb _at, 0, 0, _ink, 1, _paper, 6, _bright, 1, "      Noughts and Crosses,MoveO"
strLenMove_O	    equ $ - gameTitleStrMove_O
;CREDIT TO: 
; http://www.breakintoprogram.co.uk/computers/zx-spectrum/keyboard
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
delaySome	;; modified from  http://www.paleotechnologist.net/?p=2589
	LD BC, 50h            ;Loads BC with hex 100
	delaySomeOuter:
	LD DE, 100h            ;Loads DE with hex 100
	delaySomeInner:
	DEC DE                  ;Decrements DE
	LD A, D                 ;Copies D into A
	OR E                    ;Bitwise OR of E with A (now, A = D | E)
	JP NZ, delaySomeInner            ;Jumps back to Inner: label if A is not zero
	DEC BC                  ;Decrements BC
	LD A, B                 ;Copies B into A
	OR C                    ;Bitwise OR of C with A (now, A = B | C)
	JP NZ, delaySomeOuter            ;Jumps back to Outer: label if A is not zero
	ret

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

hprint 	;; print 1byte hex		;;http://swensont.epizy.com/ZX81Assembly.pdf?i=1
	PUSH AF ;store the original value of A for later
	AND $F0 ; isolate the first digit
	RRA
	RRA
	RRA
	RRA
	ADD A,$41 ; add 65 to the character code
	CALL Print_Char ;
	POP AF ; retrieve original value of A
	AND $0F ; isolate the second digit
	ADD A,$41 ; add 28 to the character code
	CALL Print_Char		
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
