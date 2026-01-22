org $8000

;; some helpful equ's
CLS equ $0d6b
START_OF_ATTRIBUTE_SCREEN_MEM equ $5800

Main:
    call CLS   ; clear screen rom routine using CLS equ
    call drawPlayAreaBorder

    ld hl, $4849
    ld de, GraphicTile2_8x8
    ld a, 12
    call DrawHorizontalBar


    ld a, 10
    ld (SpriteXPos), a
    ld a, 30
    ld (SpriteYPos), a

    ;ld hl, $5050  ;; start address of platform at left end
    ;xor a


    ;; read keys and make to allow what for with the sprite shall move    
ScanTheKeyBoard:
ScanKey_A:
    ld d, $00
    ld a, $fd 
    in a, ($fe)
    bit $00, a
    jp nz, ScanKey_Z
    set $00, d
ScanKey_Z:
    ld a, $fe
    in a, ($fe)
    bit $01, a
    jr nz, ScanKey_O
    set $01, d  
ScanKey_O:
    ld a, $cf
    in a, ($fe)
    bit $01, a
    jr nz, ScanKey_P
    set $02, d  
ScanKey_P:
    ld a, $df
    in a, ($fe)
    bit $00, a
    jr nz, DoneScanKeys
    set $03, d    


DoneScanKeys:       
    ; check if d bit zero set
    bit $00, d
    jr nz, MoveSpriteUp
    bit $01, d
    jr nz, MoveSpriteDown
    bit $02, d
    jr nz, MoveSpriteLeft
    bit $03, d
    jr nz, MoveSpriteRight
    jr DrawSprite


MoveSpriteUp:
    call DrawBlank24_24      
    ld a, (SpriteYPos)
    cp 8
    jp z, DrawSprite
    dec a
    ld (SpriteYPos), a
    jr DrawSprite
MoveSpriteDown:
    call DrawBlank24_24
    ld a, (SpriteYPos)
    cp 160
    jp z, DrawSprite
    inc a
    ld (SpriteYPos), a
    jp DrawSprite
MoveSpriteLeft:       
    call DrawBlank24_24
    ld a, (SpriteXPos)
    cp 1
    jp z, DrawSprite 
    dec a
    ld (SpriteXPos), a
    ld a, 1
    ld (movedLeftFlag), a
    jp DrawSprite
MoveSpriteRight:
    call DrawBlank24_24
    ld a, (SpriteXPos)
    cp 28
    jp z, DrawSprite
    inc a
    ld (SpriteXPos), a
    ld a, 1
    ld (movedRightFlag), a

DrawSprite:
    ld a, (SpriteXPos) ; for some reason, not sure why, if I do ld b, (SpritePosX) directly it just doesn't work?! same for ld c????
    ld b, a
    ld a, (SpriteYPos)
    ld c, a 
    ld de, spriteDataPerson1 

    ld a,(movedRightFlag)
    cp 1
    jp nz, checkMoveLeft
    ld a, (spaceShipFrame)
    cp 1
    jp z, skipLoadSpaceShip2
    ld de, spriteDataPerson2 
    ld a, 1
    ld (spaceShipFrame), a
    jp drawSpaceShip
skipLoadSpaceShip2:
    xor a
    ld (spaceShipFrame), a   
    ld de, spriteDataPerson1    
    jp drawSpaceShip
checkMoveLeft:
    ld a,(movedLeftFlag)
    cp 1
    jp nz, drawSpaceShip
    ld a, (spaceShipFrame)
    cp 1
    jp z, skipLoadSpaceShip1_Left
    ld de, spriteDataPerson1_Left 
    ld a, 1
    ld (spaceShipFrame), a
    jp drawSpaceShip
skipLoadSpaceShip1_Left:
    xor a
    ld (spaceShipFrame), a   
    ld de, spriteDataPerson2_Left    
    jp drawSpaceShip
drawSpaceShip:
    call DrawSprite24x24 ;; this is just a test at momemt till it's working properlDelay
    ;jp ScanTheKeyBoard
    
    ld a,(movedRightFlag)
    cp 1
    jp z, EndOfDrawLoop
checkForDelayLeft:
    ld a,(movedLeftFlag)
    cp 1
    jp z, EndOfDrawLoop
    call Delay
EndOfDrawLoop:
    xor a
    ld (movedRightFlag), a
    ld (movedLeftFlag), a
    call Delay
    jp ScanTheKeyBoard


DrawBlank24_24
    ld a, (SpriteXPos) ; for some reason, not sure why, if I do ld b, (SpritePosX) directly it just doesn't work?! same for ld c????
    ld b, a
    ld a, (SpriteYPos)
    ld c, a 
    ld de,SpriteBlank_24x24
    call DrawSprite24x24 
    ret


;; effectively commented out code to draw a moving platform
MovingPlatformLoop:
    push af
        ld a, 3
        push hl
            ld de, GraphicTile3_8x8
            call DrawHorizontalBar
            ; we need to print a blank block at each end
            pop hl
            push hl
                dec l
                ld de, GraphicTileBlank_8x8
                ld a, 1
                push hl
                    call DrawHorizontalBar
                pop hl
                ;; becasue the moving platform is length 3 inc l by 4 to get to end
                inc l
                inc l
                inc l
                inc l
                ld de, GraphicTileBlank_8x8
                ld a, 1
                call DrawHorizontalBar

            call Delay
        pop hl
    
    ;; determine direction platforms moving
    ld a, (platform_direction)
    cp 0
    jp z, platform_moves_left
platform_moves_right
    inc l
    inc l ;; this avoids a second jump platform_moves_left always decs, probably faster
platform_moves_left
    dec l
    pop af
    inc a
    cp 10
    jp z, resetPlatform
    jp EndLoopMovingPlatform    
resetPlatform:
    ;ld hl, $5050            ;; for now move it instantly back, later make it sweep back
    xor a                   ;; a storing the numbner of times moved
    push af 
    ; toggle the left right flag in  platform_direction
    ld a, (platform_direction)
    xor %00000001
    ld (platform_direction), a 
    pop af
EndLoopMovingPlatform    
    jp MovingPlatformLoop

;; might never get here
EndLoop:
    jp EndLoop

drawPlayAreaBorder
    ld b, 24
    ld hl, START_OF_ATTRIBUTE_SCREEN_MEM
    ld de, 32
SetColourLoop:
    ld a, $04
    ld (hl), a
    add hl, de 
    djnz SetColourLoop

    ld b, 24
    ld hl, START_OF_ATTRIBUTE_SCREEN_MEM+$1f
    ld de, 32
SetColourLoop2:
    ld a, $04
    ld (hl), a
    add hl, de 
    djnz SetColourLoop2

    ld b, 30 ; there's 30 columns but we only want to do the inner 30
    ld hl, $5801 ; offset to attribute memory for top row on character in from left
SetColourLoop3:
    ld a, $02
    ld (hl), a
    inc hl 
    djnz SetColourLoop3

    ld b, 30 ; there's 30 columns but we only want to do the inner 30
    ld hl, $5ae1 ; offset to attribute memory for bottom row on character in from left
SetColourLoop4:
    ld a, $02
    ld (hl), a
    inc hl 
    djnz SetColourLoop4


;; setup the screen with boarders and ledges
    ld hl, $4000  ; start of pixel memory
    ld de, GraphicTile1_8x8
    ld a, 24
    call DrawVeticalBar
    ld hl, $401f  ; pixel address of last column
    ld de, GraphicTile1_8x8
    ld a, 24
    call DrawVeticalBar
    ld hl, $4001
    ld de, GraphicTile1_8x8
    ld a, 30
    call DrawHorizontalBar
    ld hl, $50e1
    ld de, GraphicTile1_8x8
    ld a, 30
    call DrawHorizontalBar  
    ret

;;010T TSSS LLLC CCCC
DrawSprite24x24:   ; 3 by 3 character size sprite
;; top left xy is in bc
;; set de to sprite memory start is incremented throught the subroutine
push bc
    ;; the xy of first row is same as called by in bc
    call GetScreenPos
    ld a, 3
    ;ld hl, $4804   ;;;; just somewhere in centre third of screen vertically
;    ld de, Sprite1_24x24
    call DrawHorizontalSprite_3wide
pop bc
push bc
    ld a, c
    add a, 8
    ld c, a
    call GetScreenPos
    ld a, 3
    ;ld hl, $4804   ;;;; just somewhere in centre third of screen vertically
    ;ld de, Sprite1_24x24+24
    call DrawHorizontalSprite_3wide
pop bc
    ld a, c
    add a, 16
    ld c, a
    call GetScreenPos
    ld a, 3
    ;ld hl, $4804   ;;;; just somewhere in centre third of screen vertically
    ;;ld de, Sprite1_24x24+48
    call DrawHorizontalSprite_3wide

ret

DrawHorizontalSprite_3wide:    
    ld b, a    ; number of multiples of 8 blocks to display width
MainLoopH1:
    push bc
        ld b, 8
        push hl
InnerLoopH1:
            ld a, (de)
            ld (hl), a
            call NextScan
            inc de
            djnz InnerLoopH1
        pop hl
        inc l
    pop bc
    djnz MainLoopH1
ret


DrawHorizontalSprite_1x1
ld b, 8
MainLoopHS1:
    ld a, (de)
    ld (hl), a
    push af 
    push de   
    push bc
        call NextScan
    pop bc
    pop de
    pop af
    
    inc de
    djnz MainLoopHS1
ret

;; Draw a horizontal line of the value stored in 8x8 tile
;; The 8x8 tile first location should be stored in de
;;
;; Uses registers:
;;     hl - screen (pixel) memory start offset
;;     de - memory location of the start of the 8x8 tile
;;     a  - the number of horizontal 8x8 to draw
;; Changes registers:
;;     bc 
;;     af 

DrawHorizontalBar:    
    ld b, a    ; number of multiples of 8 blocks to display width
MainLoopHB1:
    push de
    push bc
        ld b, 8
        push hl
InnerLoopHB1:
            ld a, (de)
            ld (hl), a
            call NextScan
            inc de
            djnz InnerLoopHB1
        pop hl
        inc l
    pop bc
    pop de
    djnz MainLoopHB1
ret



DrawVeticalBar:    
    ld b, a    ; number of multiples of 8 blocks to display width
MainLoop2:
    push de
    push bc
        ld b, 8
InnerLoop:
        ld a, (de)
        ld (hl), a
        call NextScan
        inc de
        djnz InnerLoop
    pop bc
    pop de
    djnz MainLoop2
ret

Delay:
    push bc
    push af

    ld b, $4e
DelayLoopOuter:
    push bc
        ld b, $f0
DelayLoop:
        ld a, 4
        djnz DelayLoop 
    pop bc
    djnz DelayLoopOuter

    pop af
    pop bc
ret



GetNextLine:
	push af
		ld hl,&0000
ScreenLinePos_Plus2:
		inc h
		ld a,h
		and  %00000111;7
		jp nz,GetNextLineDone
		ld a,l
		add a,%00100000;32
		ld l,a
		jr c,GetNextLineDone
		ld a,h
		sub %00001000;8
		ld h,a
GetNextLineDone:
	ld (ScreenLinePos_Plus2-2),hl
	pop af
	ret


;;; from https://www.youtube.com/@ChibiAkumas
;;https://www.youtube.com/watch?v=hGptSfPd2uA&list=WL&index=35
GetScreenPos:	;return memory pos in HL of screen co-ord B,C (X,Y)
	
	push bc
		ld b,0			;Load B with 0 because we only want C
		ld hl,scr_addr_table
		add hl,bc	;We add twice, because each address has 2 bytes
		add hl,bc

		ld a,(hl)	
		inc l		;INC L not INC HL because we're byte aligned to 2
		ld h,(hl)
		ld l,a
	pop bc
	ld c,b		;Load the Xpos into C
	ld b,&0	;Our table is relative to 0 - so we need to add our screen base
	add hl,bc	;This is so it can be used for alt screen buffers
	ld (ScreenLinePos_Plus2-2),hl
	ret


;--------------------------------------------------
; NextScan
; https://tinyurl.com/223d4xx4
; Gets the memory location corresponding to the
; scanline.
; The next to the one indicated.
; 010T TSSS LLLC CCCC
; Input: HL -> current scanline.
; Output: HL -> scanline next.
; Alters the value of the AF and HL registers.
;--------------------------------------------------

NextScan:
; Increment H to increase the scanline
inc h
; Load the value in A
ld a, h
; Keeps the bits of the scanline
and $07
; If the value is not 0, end of routine
ret nz
; Calculate the following line
; Load the value in A
ld a, l
; Add one to the line (%0010 0000)
add a, $20
; Load the value in L
ld l, a
; If there is a carry-over, it has changed its
; position, the top is already adjusted from above.
; End of routine.
ret c

; If you get here, you haven't changed your mind
; and you have to adjust as the first INC H
; increased it.
; Load the value in A
ld a, h
; Subtract one third (%0000 1000)
sub $08
; Load the value in H
ld h, a
ret

platform_direction:

    defb 1

;; due to attribute drawing these can appear in reverse of what they look like here with 1 or zeros opposite
GraphicTile1_8x8:    ;  a diamond pattern with a dot in the middle
    defb %11100111
    defb %11011011
    defb %10111101
    defb %01100110
    defb %01100110
    defb %10111101
    defb %11011011
    defb %11100111

GraphicTile2_8x8:    ; a box filled in if using attribute colour
    defb %00000000
    defb %01111110
    defb %01111110
    defb %01111110
    defb %01111110
    defb %01111110
    defb %01111110
    defb %00000000

GraphicTile3_8x8:    ; a box empty for no attribute colour
    defb %11111111
    defb %10000001
    defb %10000001
    defb %10000001
    defb %10000001
    defb %10000001
    defb %11111111
    defb %11111111

GraphicTileBlank_8x8:    ; a box empty for no attribute colour
    defb %00000000
    defb %00000000
    defb %00000000
    defb %00000000
    defb %00000000
    defb %00000000
    defb %00000000
    defb %00000000


SpriteXPos:
    defb 10
SpriteYPos:
    defb 30
spaceShipFrame:
    defb 0
movedRightFlag:
    defb 0
movedLeftFlag:
    defb 0

scr_addr_table:
	dw &4000,&4100,&4200,&4300,&4400,&4500,&4600,&4700
	dw &4020,&4120,&4220,&4320,&4420,&4520,&4620,&4720
	dw &4040,&4140,&4240,&4340,&4440,&4540,&4640,&4740
	dw &4060,&4160,&4260,&4360,&4460,&4560,&4660,&4760
	dw &4080,&4180,&4280,&4380,&4480,&4580,&4680,&4780
	dw &40A0,&41A0,&42A0,&43A0,&44A0,&45A0,&46A0,&47A0
	dw &40C0,&41C0,&42C0,&43C0,&44C0,&45C0,&46C0,&47C0
	dw &40E0,&41E0,&42E0,&43E0,&44E0,&45E0,&46E0,&47E0
	dw &4800,&4900,&4A00,&4B00,&4C00,&4D00,&4E00,&4F00
	dw &4820,&4920,&4A20,&4B20,&4C20,&4D20,&4E20,&4F20
	dw &4840,&4940,&4A40,&4B40,&4C40,&4D40,&4E40,&4F40
	dw &4860,&4960,&4A60,&4B60,&4C60,&4D60,&4E60,&4F60
	dw &4880,&4980,&4A80,&4B80,&4C80,&4D80,&4E80,&4F80
	dw &48A0,&49A0,&4AA0,&4BA0,&4CA0,&4DA0,&4EA0,&4FA0
	dw &48C0,&49C0,&4AC0,&4BC0,&4CC0,&4DC0,&4EC0,&4FC0
	dw &48E0,&49E0,&4AE0,&4BE0,&4CE0,&4DE0,&4EE0,&4FE0
	dw &5000,&5100,&5200,&5300,&5400,&5500,&5600,&5700
	dw &5020,&5120,&5220,&5320,&5420,&5520,&5620,&5720
	dw &5040,&5140,&5240,&5340,&5440,&5540,&5640,&5740
	dw &5060,&5160,&5260,&5360,&5460,&5560,&5660,&5760
	dw &5080,&5180,&5280,&5380,&5480,&5580,&5680,&5780
	dw &50A0,&51A0,&52A0,&53A0,&54A0,&55A0,&56A0,&57A0
	dw &50C0,&51C0,&52C0,&53C0,&54C0,&55C0,&56C0,&57C0
	dw &50E0,&51E0,&52E0,&53E0,&54E0,&55E0,&56E0,&57E0

SpriteBlank_24x24:
    defs 8*9, 0

spriteDataPerson1:
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000

defb %00011111
defb %00100001
defb %01010000
defb %01010001
defb %00100001
defb %00011110
defb %00111111
defb %01100001

defb %00000000
defb %10000000
defb %11000000
defb %01100000
defb %10000000
defb %00000000
defb %00000000
defb %11000000

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000

defb %01100010
defb %01010010
defb %01010010
defb %01010100
defb %10010100
defb %10011100
defb %10011100
defb %01000001

defb %01000000
defb %00100000
defb %00100000
defb %00100000
defb %00100000
defb %01000000
defb %10000000
defb %00000000

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000

defb %00100010
defb %00010010
defb %00010001
defb %00010010
defb %00010010
defb %00010010
defb %00010111
defb %00111111

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %10000000
defb %11000000


spriteDataPerson2:
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000

defb %00011111
defb %00100001
defb %01010000
defb %01010001
defb %00100001
defb %00011110
defb %00111111
defb %01100001

defb %00000000
defb %10000000
defb %11000000
defb %01100000
defb %10000000
defb %00000000
defb %00000000
defb %11000000

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000

defb %01100010
defb %01010010
defb %01010010
defb %01010010
defb %10001001
defb %10000100
defb %10000011
defb %01000001

defb %01000000
defb %00100000
defb %00100000
defb %00100000
defb %00100000
defb %11000000
defb %10000000
defb %00000000

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000

defb %00100010
defb %00100010
defb %00100011
defb %00100110
defb %00100101
defb %00100100
defb %01111000
defb %01111111

defb %00000000
defb %00000000
defb %00000000
defb %10000000
defb %00100000
defb %10010000
defb %01011100
defb %00111111




spriteDataPerson1_Left:
defb %00000011
defb %00000001
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000

defb %11111100
defb %11101000
defb %01001000
defb %01001000
defb %01001000
defb %10001000
defb %01001000
defb %01000100

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000

defb %00000000
defb %00000001
defb %00000010
defb %00000100
defb %00000100
defb %00000100
defb %00000100
defb %00000010

defb %10000010
defb %00111001
defb %00111001
defb %00101001
defb %00101010
defb %01001010
defb %01001010
defb %01000110

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000

defb %00000011
defb %00000000
defb %00000000
defb %00000001
defb %00000110
defb %00000011
defb %00000001
defb %00000000

defb %10000110
defb %11111100
defb %01111000
defb %10000100
defb %10001010
defb %00001010
defb %10000100
defb %11111000

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000



spriteDataPerson2_Left:
defb %11111100
defb %00111010
defb %00001001
defb %00000100
defb %00000001
defb %00000000
defb %00000000
defb %00000000

defb %11111110
defb %00011110
defb %00100100
defb %10100100
defb %01100100
defb %11000100
defb %01000100
defb %01000100

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000

defb %00000000
defb %00000001
defb %00000011
defb %00000100
defb %00000100
defb %00000100
defb %00000100
defb %00000010

defb %10000010
defb %11000001
defb %00100001
defb %10010001
defb %01001010
defb %01001010
defb %01001010
defb %01000110

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000

defb %00000011
defb %00000000
defb %00000000
defb %00000001
defb %00000110
defb %00000011
defb %00000001
defb %00000000

defb %10000110
defb %11111100
defb %01111000
defb %10000100
defb %10001010
defb %00001010
defb %10000100
defb %11111000

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000000









SpaceShip1:  
 ; beacuse of the way the sprite is being drawn this has to be organised in memory the same way
 ; in other words all the first column of pixels of the first 8bytes then all the second and so on
 ; then repeated on each row of 8x8 charaters
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000001
defb %00000001
defb %00000001
defb %00000001

defb %00011000
defb %00100100
defb %01000010
defb %10011001
defb %00111100
defb %00100100
defb %00111100
defb %00100100

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %10000000
defb %10000000
defb %10000000
defb %10000000

defb %00000001
defb %00000010
defb %00000100
defb %00001000
defb %10010000
defb %10100000
defb %11000000
defb %11111111

defb %00111100
defb %00000000
defb %00000000
defb %00000000
defb %10000001
defb %10000001
defb %10000001
defb %11111111

defb %10000000
defb %01000000
defb %00100000
defb %00010000
defb %00001001
defb %00000101
defb %00000011
defb %11111111

defb %00000011
defb %00000000
defb %00000001
defb %00000010
defb %00000001
defb %00000000
defb %00000010
defb %00000000

defb %11000011
defb %00000000
defb %01000001
defb %10010010
defb %00000001
defb %10100000
defb %00000010
defb %01000000

defb %11000000
defb %00000000
defb %01000000
defb %10000000
defb %01000000
defb %00000000
defb %01000000
defb %00000000


SpaceShip2:
defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %00000001
defb %00000001
defb %00000001
defb %00000001

defb %00011000
defb %00100100
defb %01000010
defb %10011001
defb %00111100
defb %00100100
defb %00111100
defb %00100100

defb %00000000
defb %00000000
defb %00000000
defb %00000000
defb %10000000
defb %10000000
defb %10000000
defb %10000000

defb %00000001
defb %00000010
defb %00000100
defb %00001000
defb %10010000
defb %10100000
defb %11000000
defb %11111111

defb %00111100
defb %00000000
defb %00000000
defb %00000000
defb %10000001
defb %10000001
defb %10000001
defb %11111111

defb %10000000
defb %01000000
defb %00100000
defb %00010000
defb %00001001
defb %00000101
defb %00000011
defb %11111111

defb %00000011
defb %00000000
defb %00000001
defb %00000000
defb %00000001
defb %00000000
defb %00000001
defb %00000000

defb %11000011
defb %00000000
defb %01000001
defb %10100010
defb %00000100
defb %10100001
defb %01000000
defb %01010001

defb %11000000
defb %00000000
defb %00100000
defb %10000000
defb %10000000
defb %00000000
defb %01000000
defb %00100000



end $8000