
;; some helpful equ's
CLS equ $0d6b
START_OF_ATTRIBUTE_SCREEN_MEM equ $5800
;sounds
C_5: EQU $0326
C_5_FQ: EQU $020B / $10
C_4: EQU $066E
C_4_FQ: EQU $0105 / $10

LOCATE: equ $0dd9
NUMBER_ALIEN_IN_ROW: equ 8
NUMBER_ALIEN_ROWS: equ 8
ALIEN_MOVE_TIMER_INIT: equ 10
ALIEN_MOVE_LIMIT: equ 10
NUMBER_OF_LEFT_RIGHTS_ALIENS: equ 3

    org $8000
    defs $190

Start:
    di                  ; Disable interrupts during setup
    
    ; 1. Create the Vector Table at $8000
    ld HL, $8000        ; Table starts at $8000
    ld a, $81        ; Fill with $81
    ld de, $8001
    ld (hl), a
    ld bc, $0101-1         
    ldir                ; fill

    dec a
    ld i, a
    ; 2. Place the Interrupt Service Routine (ISR) at $8181
    ld a, $C3           ; Opcode for 'JP'
    ld ($8181), a
    ld hl, MyISR        ; Address of our counter routine
    ld ($8182), hl

    im 2                ; Enter Interrupt Mode 2
    ei                  ; re enable interrupts
    jp Main

MyISR:
    ex af, af'              ; save a and flags to alternate register set
        push bc             ; Always save registers as this can and will be asynchronous to the other code
        push de
        push hl
        push ix
        push iy
            ld hl, FrameCount
            inc (hl)
        pop iy
        pop ix
        pop hl
        pop de
        pop bc
    ex af,af'
    ei                  ; Re-enable interrupts
    reti                ; Return from Interrupt


WaitFrame:
    ld a, (FrameCount)
    inc a            ; Target frame, just 1
    ld b, a
WaitFrame_loop:
    halt                ; Wait for the next interrupt
    ;push af
    ;    ld hl, START_OF_ATTRIBUTE_SCREEN_MEM+1 ; debug
    ;    ld a,(debugColour2)
    ;    inc a
    ;    ld (debugColour2),a
    ;    ld (hl), a
    ;pop af

    ld a, (FrameCount)
    cp b                ; Compare current to target
    jr c, WaitFrame_loop
    ret


FrameCount: 
    defw 0      ; Our 1-byte counter
debugColour1:
    defb 2
debugColour2:
    defb 3

Main:

    ld a, 15
    ld (SpriteXPos), a
    ld a, 160
    ld (SpriteYPos), a
    call CLS
    call drawPlayAreaBorder
    
    ;; read keys and make to allow what for with the sprite shall move    

MainLoop:
    ; the bits comments out here are debug to give an indication
    ; of the cpu cycles being used, when the red boarder fills the
    ; whole screen means run out of time before next tv frame is being drawn
  
    call WaitFrame
    
    call z, SHOW_SCORE

;    ld  a,5             ; 2. Set color to RED (indicates processing start)
;    out ($FE), A        ; Port $FE (254) controls the border
    call ScanTheKeyBoard      ; 3. Run your main program logic here
    
;    ld a, 0             ; 4. Set color to BLACK (indicates processing end)
;    out ($FE), A
    ; Any remaining space in the border is "idle" time
    jp MainLoop

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
    jr nz, ScanKey_Space
    set $03, d    
ScanKey_Space:
    ld a, $7f
    in a, ($fe)
    bit $00, a
    jr nz, DoneScanKeys
    set $04, d   

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
    bit $04, d
    jp nz, FireRocket
    jp DrawSprite


MoveSpriteUp:
;    call DrawBlank24_24
;    ld a, (SpriteYPos)
;    dec a
;    cp 9
;    jp z, DrawSprite 
;    dec a
;    cp 9
;    jp z, DrawSprite 
;    dec a
;    cp 9
;    jp z, DrawSprite 
;    ld (SpriteYPos),a
    jp DrawSprite
MoveSpriteDown:
;    call DrawBlank24_24
;    ld a, (SpriteYPos)
;    inc a
;    cp 160
;    jp z, DrawSprite
;    ld (SpriteYPos),a
    jp DrawSprite
MoveSpriteLeft:       
    call DrawBlank24_24
    ld a, (SpriteXPos)
    dec a
    cp 1
    jp z, DrawSprite
    ld (SpriteXPos),a 
    jp DrawSprite
MoveSpriteRight:
    call DrawBlank24_24
    ld a, (SpriteXPos)
    inc a
    cp 28
    jp z, DrawSprite
    ld (SpriteXPos),a        
    jp DrawSprite

FireRocket:
    ld a, (RocketFiring)
    cp 1
    jp nz, setupRocket 
    jp DrawSprite ;  firing already
setupRocket:    
    ;; not 1  so not firing
    ld a, (SpriteXPos)
    inc a
    ld (RocketXPos),a
    
    ld a, (SpriteYPos)
    ld (RocketYPos),a    
    ld a, 1
    ld (RocketFiring),a

    ld hl, C_5
    ; DE = duration (frequency)
    ld de, C_5_FQ
    ; Jumps to beep
    call beep
    ;jp DrawSprite.  ; no need for this unless more code under here


DrawSprite:    
    ; if rocket firing then draw 
    ld a, (RocketFiring)
    cp 1
    jp nz, ActuallyDrawSprite

    ld a, (RocketXPos)
    ld b, a
    ld a, (RocketYPos)
    ld c, a
    call GetScreenPos
    
    ld a, %00000000
    ld (hl),a 
    call PreviousScan
    ld a, %00000000
    ld (hl),a 
    
    ld a, (RocketYPos)
    dec a
    ld (RocketYPos), a

    ld a, (RocketXPos)
    ld b, a
    ld a, (RocketYPos)
    ld c, a
    call GetScreenPos
    ld a, %00100000
    ld (hl),a 
    call PreviousScan
    ld a, %00100000
    ld (hl),a 
        
    ld a, (RocketYPos)
    cp 9
    jp z, resetRocket
    cp 8
    jp z, resetRocket
    cp 7
    jp z, resetRocket
    cp 6
    jp z, resetRocket
        
    jp ActuallyDrawSprite
resetRocket:
    ; play explosion sound
    ld hl, $27a0
    ; DE = frequency
    ld de, $2b/$20
    call beep
    ld a, 0 
    ld (RocketFiring), a

ActuallyDrawSprite:
    ld a, (SpriteXPos) ; have todo this ld a,(nn) then ld b, a
    ld b, a
    ld a, (SpriteYPos)
    ld c, a 

    ld de, SpaceShip_1          ; preload with space ship 1 sprite
    ld a, (SpriteFrameCounter)
    inc a
    ld (SpriteFrameCounter),a
    bit 0, a 
    jp z, ReallyDrawSprite
    ld de, SpaceShip_2          ; load alternative space ship

ReallyDrawSprite:
;    ld hl, $5aa3 ; debug
;    ld a, 16
;    ld (hl), a
   
;    ld hl, $5aa5 ; debug
;    ld a, 16
;    ld (hl), a
   
    call DrawSprite24x24   ; draw the players space ship

    call CheckAliensHit

    ld a, (moveAlienTimer)
    dec a
    ld (moveAlienTimer),a
    cp 1
    jp z, DrawAliensTimerExpired
    ret



DrawAliensTimerExpired:
    call UpdateAlienPositions
    call ChooseAliens
    call DrawAliensThisTime       
    ld a, ALIEN_MOVE_TIMER_INIT
    ld (moveAlienTimer),a
    ret

ChooseAliens:
    ld a, (AlienFrameCounter)
    inc a 
    ld (AlienFrameCounter) , a
    bit 0, a
    jp nz, Alien_1 
Alien_2:
    ld de, AlienGraphic_8x8_2
    ;ld hl, $5aa5 ; debug
    ;ld a, 2
    ;ld (hl), a
    ret

Alien_1:
    ld de, AlienGraphic_8x8_1
    ;ld hl, $5aa3 ;debug
    ;ld a, 2
    ;ld (hl), a
    ret

DrawAliensThisTime:
    ld iy,AlienLocation
    ld hl, AlienValid           ; store first alien valid address used in loop to work out where is hit
    ld (currentAlienValidAddress), hl
 
    ld b, NUMBER_ALIEN_ROWS
    
AlienDrawLoop_Rows:
    push bc
        ld b, NUMBER_ALIEN_IN_ROW
AlienDrawLoop_Cols:
        push bc
            ld l, (iy+0)
            ld h, (iy+1)
            inc iy
            inc iy
            ld a, 1
            ;; de already be loaded but save to stack 
            push de
                ; do we need to draw this one?
                push hl  
                    ld a, (currentAlienValidAddress+0)
                    ld l, a
                    ld a, (currentAlienValidAddress+1)
                    ld h, a             
                    ld a, (hl)
                    cp 1
                    jp nz, skipDrawThisAlien
                pop hl
                ;;  the alien is valid check the alien did not reach the bottom
                ld a, $50
                cp h
                jp nz, notAtBottom
                ld a, $6f
                cp l
                jp nz, notAtBottom
                pop de 
                pop bc 
                pop bc
                call GAME_OVER
notAtBottom:
                push hl
                    ld a, 1
                    call DrawHorizontalBar
                ; now draw a blank in next l position
                pop hl
                push hl ; to precompensate for if the skip did not trigger
skipDrawThisAlien:
                ld hl, (currentAlienValidAddress)  
                inc hl 
                ld (currentAlienValidAddress),hl   

                pop hl ; extra pop since we jumped past the one 3 lines above!


                inc l
                ld de, GraphicTileBlank_8x8
                ld a, 1
                call DrawHorizontalBar
            pop de
        pop bc
        djnz AlienDrawLoop_Cols   
    pop bc
    djnz AlienDrawLoop_Rows
    ret

GAME_OVER:
    LD A, 2          ; Open Channel 2 (Upper Screen)
    CALL 5633
    LD DE, MSG       ; Address of string
    LD BC, MSG_END-MSG ; Length of string
    CALL 8252        ; ROM routine to print
    call Delay
    jp GAME_OVER ; Todo -> make a proper game reset work - would need all alien start positions reseting
    ret 

MSG:    DEFB 22          ; AT control code
    DEFB 10          ; Line 10 (Vertical middle)
    DEFB 8           ; Column 8 (Horizontal start)
    DEFB "*** GAME OVER ***"
MSG_END: EQU $



UpdateAlienPositions:
    ;; determine direction aliens are currently moving
    ; 
    ld a, (AlienDirection)
    bit 0, a              ;AlienDirection inc elsewhere and this checks the resulting toggled bit zero
    jp z, AlienMoves_Left
AlienMoves_Right:

    ld iy,AlienLocation
    ld b, NUMBER_ALIEN_ROWS  
AlienPosUpLoop_Rows:
    push bc
    ld l,(iy+0)
    ld h,(iy+1)
    ld a, 2
    ld de, GraphicTileBlank_8x8
    call DrawHorizontalBar    
    ld b, NUMBER_ALIEN_IN_ROW
AlienPosUpLoop_Cols:
        ld l,(iy+0)
        ld h,(iy+1)
        inc l ;; this avoids a second jump AlienMoves_Left always decs, probably faster
        ld (iy+0),l
        inc iy
        inc iy        
        djnz AlienPosUpLoop_Cols
    pop bc
    djnz AlienPosUpLoop_Rows
    ld a,(AlienMoveCounter)
    inc a
    cp ALIEN_MOVE_LIMIT
    jp z, resetAlienRow
    ld (AlienMoveCounter), a
    ret    


AlienMoves_Left:

    ld iy,AlienLocation
    ld b, NUMBER_ALIEN_ROWS  
AlienPosUpLoop_Rows_L:
    push bc
        ld b, NUMBER_ALIEN_IN_ROW
AlienPosUpLoop_Cols_L:
        ld l,(iy+0)
        ld h,(iy+1)
        dec l ;; this avoids a second jump AlienMoves_Left always decs, probably faster
        ld (iy+0),l
        inc iy
        inc iy        
        djnz AlienPosUpLoop_Cols_L
    pop bc
    djnz AlienPosUpLoop_Rows_L
    inc l
    ld a, 2
    ld de, GraphicTileBlank_8x8
    call DrawHorizontalBar
          

    ld a,(AlienMoveCounter)
    inc a
    cp ALIEN_MOVE_LIMIT
    jp z, resetAlienRow
    ld (AlienMoveCounter), a
    ret   
resetAlienRow:
    xor a                   ;; a storing the numbner of times moved
    ld (AlienMoveCounter), a
    ; toggle the left right flag in  AlienDirection (when using bit 0, a to check)
    ld a, (AlienDirection)
    inc a 
    ld (AlienDirection), a

    ;; now move all the aliens down one
    ;; but first have to blank the top row as this will no longer have aliens
    
    ;; only moveAliens down if they've been left right 4 times
    ld a, (alienLeftRightCount)
    inc a 
    ld (alienLeftRightCount),a 
    cp NUMBER_OF_LEFT_RIGHTS_ALIENS
    ret nz

    xor a
    ld (alienLeftRightCount),a 
    ld iy, AlienLocation
    ld b, NUMBER_ALIEN_IN_ROW
AlienBlankTopRowLoop_Cols:
    push bc
        ld l, (iy+0)
        ld h, (iy+1)
        ld a, 2
        ld de, GraphicTileBlank_8x8
        call DrawHorizontalBar
        inc iy              ; Move IY to the next alien in the table
        inc iy  
    pop bc      
    djnz AlienBlankTopRowLoop_Cols

    ld iy, AlienLocation
    ld b, NUMBER_ALIEN_ROWS  
AlienPosDownLoop_Rows:
    push bc
    ld b, NUMBER_ALIEN_IN_ROW
AlienPosDownLoop_Cols:
        ld l, (iy+0)
        ld h, (iy+1)

        ld a, l
        add a, 32           ; Advance 32 bytes (one character row)
        ld l, a             ; Store new L
        jr nc, SkipCarrayAddMoveAlienDown      ; If no carry, H remains the same
        ld a, h
        add a, 8            ; Carry! Move H to the next screen third
        ld h, a
SkipCarrayAddMoveAlienDown:
        ld (iy+0), l        ; Save updated address back to table
        ld (iy+1), h
        
        inc iy              ; Move IY to the next alien in the table
        inc iy        
        djnz AlienPosDownLoop_Cols
    pop bc
    djnz AlienPosDownLoop_Rows

skipMoveAliensDown:
    ret

;; should never get here
EndLoop:
    jp EndLoop

CheckAliensHit:
    ld a, (RocketFiring)
    cp 1                    ;; only check if rocket is in flight
    jp nz, EndCheckAliensHit
    ld a, 0
    ld (ScoreChanged), a

    xor a 
    ld (alienCheckCount),a
    ld a, (RocketXPos)
    ld b, a
    ld a, (RocketYPos)
    ld c, a
    call GetScreenPos  ; takes bc, x y coord and returns hl screen address
    push hl
    pop de ;; swap hl into de to make comparison possible
    ld iy, AlienLocation
    ld hl, AlienValid           ; store first alien valid address used in loop to work out where is hit
    ld (currentAlienValidAddress), hl
    ld b, NUMBER_ALIEN_ROWS  
CheckColisAlienLoop_Rows
    push bc
        ld b, NUMBER_ALIEN_IN_ROW
CheckColisAlienLoop_Cols:

        ; first check this alien position is valid still
        ld hl, (currentAlienValidAddress)
        ld a, (hl)
        cp 1
        jp nz, skipCheckCollision
        
        ld l,(iy+0)
        ld h,(iy+1)
        ld a, d
        cp h 
        jp z, checkLCollision
        jp skipCheckCollision
checkLCollision:
        ld a, l
        cp e
        jp z, RocketHIT
        
skipCheckCollision:

        ld hl, (currentAlienValidAddress)    ; preload (even if no hit) the AlienValid address
        inc hl 
        ld (currentAlienValidAddress),hl   ; preload (even if no hit) the AlienValid address
        
        inc iy
        inc iy        
        djnz CheckColisAlienLoop_Cols
    pop bc
    djnz CheckColisAlienLoop_Rows
EndCheckAliensHit
    ret


RocketHIT:  
    pop bc ; have todo this because jumps out of loop early


    call beep
    ld a, 0 
    ld (RocketFiring), a

    ld a, 1
    ld (ScoreChanged), a

    ld a, (currentAlienValidAddress+0)
    ld l, a
    ld a, (currentAlienValidAddress+1)
    ld h, a
    xor a
    ld (hl), a
    ld (RocketFiring),a
    
    ; increase the score
    call increaseScore
    jr endCheckAliens          ; If no carry, we're finished

    dec hl                ; Carry to the hundreds/thousands byte
    ld a, (hl)
    adc a, 0              ; Add the carry
    daa
    ld (hl), a
    ; (Repeat for the third byte if needed for millions)
endCheckAliens
    ret



; --- ADDITION ROUTINE (Fixes the $10 jump) ---
increaseScore:
    ld hl, score3Bytes + 2 ; Point to the LAST byte (Units/Tens)
    ld a, (hl)
    add a, $10           ; Use $01 (hex) or 1 (decimal). DO NOT use $10.
    daa                  ; Decimal Adjust: Corrects binary to BCD
    ld (hl), a
    ret nc               ; If no carry, we are done
    
    dec hl               ; Carry to middle byte
    ld a, (hl)
    adc a, 0             ; Add carry
    daa
    ld (hl), a
    ret nc
    
    dec hl               ; Carry to first byte
    ld a, (hl)
    adc a, 0
    daa
    ld (hl), a
    ret

; --- MAIN PRINT ROUTINE ---

SHOW_SCORE
    ld hl, score3Bytes    ; Point to your score
    ld de, $4000        ; Top-left pixel address
    ld b, 3             ; Loop for 3 bytes (6 digits)

.byteLoop:
    push bc             ; Save byte counter
    ld a, (hl)          ; Get current BCD byte (e.g., $05)
    push hl             ; Save score pointer
    
    ; --- 1. Handle High Nibble (Tens) ---
    push af             ; Save byte for later
    rrca
    rrca
    rrca
    rrca ; Move high 4 bits to low 4 bits
    call .renderDigit   ; Print it
    inc e               ; Move screen pointer 1 character right
    
    ; --- 2. Handle Low Nibble (Units) ---
    pop af              ; Restore byte
    call .renderDigit   ; Print it
    inc e               ; Move screen pointer 1 character right
    
    pop hl              ; Restore score pointer
    inc hl              ; Point to next byte in ScoreData
    pop bc              ; Restore byte counter
    djnz .byteLoop      ; Repeat for all 3 bytes
    ret

; --- INTERNAL DIGIT RENDERER ---
.renderDigit:
    and $0F             ; MASK: Keep only 0-9. Prevents 'P' overflow.
    
    ; Calculate ROM Font Address
    ; '0' is at $3D00 + (48 * 8) = $3E80
    push hl             ; Save HL (the score pointer)
    ld l, a             ; Put digit in L
    ld h, 0             ; CLEAR H: If H is not 0, you get 'P'
    add hl, hl          ; * 2
    add hl, hl          ; * 4
    add hl, hl          ; * 8
    ld bc, $3D80        ; Base address of '0' in ROM
    add hl, bc          ; HL = Exact address of digit graphics
    
    ; Draw 8 scanlines to screen
    push de             ; Save screen position
    ld b, 8             ; 8 pixel rows
.line:
    ld a, (hl)          ; Get font byte
    ld (de), a          ; Write to screen
    inc hl
    inc d               ; Move down 1 scanline (adds 256 to address)
    djnz .line
    pop de              ; Restore screen position for next digit
    pop hl              ; Restore score pointer
    ret


DrawBlank24_24
    ld a, (SpriteXPos) ; for some reason, not sure why, if I do ld b, (SpritePosX) directly it just doesn't work?! same for ld c????
    ld b, a
    ld a, (SpriteYPos)
    ld c, a 
    ld de,SpriteBlank_24x24
    call DrawSprite24x24 
    ret

DrawBlank8_24
    ld a, (SpriteXPos) ; for some reason, not sure why, if I do ld b, (SpritePosX) directly it just doesn't work?! same for ld c????
    ld b, a
    ld a, (SpriteYPos)
    ld c, a 
    ld de,SpriteBlank_24x24
    call DrawSprite8x24
    ret



drawPlayAreaBorder
    ld b, 24
    ld hl, START_OF_ATTRIBUTE_SCREEN_MEM
    ld de, 32
SetColourLoop:
    ld a, $02
    ld (hl), a
    add hl, de 
    djnz SetColourLoop

    ld b, 24
    ld hl, START_OF_ATTRIBUTE_SCREEN_MEM+$1f
    ld de, 32
SetColourLoop2:
    ld a, $02
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
DrawSprite8x24:   ; 1 by 3 character size sprite
;; top left xy is in bc
;; set de to sprite memory start is incremented throught the subroutine
    ;; the xy of first row is same as called by in bc
    call GetScreenPos
    ld a, 3
    ;ld hl, $4804   ;;;; just somewhere in centre third of screen vertically
;    ld de, Sprite1_24x24
    call DrawHorizontalSprite_3wide
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

DelayNano:
    push bc
    push af
        ld b, $02
DelayLoopDN:
        djnz DelayLoopDN
    pop af
    pop bc
ret


DelayTiny:
    push bc
    push af

    ld b, $08
DelayLoopOuterDS:
    push bc
        ld b, $f2
DelayLoopDS:
        ld a, 4
        djnz DelayLoopDS 
    pop bc
    djnz DelayLoopOuterDS

    pop af
    pop bc
ret



DelaySmall:
    push bc
    push af

    ld b, $1e
DelayLoopOuterS:
    push bc
        ld b, $d0
DelayLoopS:
        ld a, 4
        djnz DelayLoopS 
    pop bc
    djnz DelayLoopOuterS

    pop af
    pop bc
ret



Delay:
    push bc
    push af

    ld b, $2e
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


; -------------------------------------------------
; PreviousScan
; https://tinyurl.com/223d4xx4
; Gets the memory location corresponding to the
; scanline.
; The following is the first time this has been
; done; prior to that indicated.
; 010T TSSS LLLC CCCC
; Input: HL -> current scanline.
; Output: HL -> previous scanline.
; Alters the value of the AF, BC and HL registers.
;--------------------------------------------------
PreviousScan:
; Load the value in A
ld a, h
; Decrements H to decrement the scanline
dec h
; Keeps the bits of the original scanline
and $07
; If not at 0, end of routine
ret nz
; Calculate the previous line
; Load the value of L into A
ld a, l
; Subtract one line
sub $20
; Load the value in L
ld l, a
; If there is carry-over, end of routine
ret c
; If you arrive here, you have moved to scanline 7
; of the previous line and subtracted a third,
; which we add up again
; Load the value of H into A
ld a, h
; Returns the third to the way it was
add a, $08
; Load the value in h
ld h, a
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

beep:
; Basic Beep Loop (No border change)
    LD A, (23624)   ; Load current border color from BORDCR ($5C48)
    AND 7           ; Keep only the border bits (0-2)
    OR 16           ; Set Bit 4 (Speaker ON)

    ld b, 10
BeepLoop:
    push bc
    OUT (254), A    ; Output to speaker + current border
    XOR 16          ; Toggle only the speaker bit (Bit 4)
    
    ; Timing delay (determines pitch)
    LD B, h 
Wait: 
    DJNZ Wait
    pop bc
    ; Add loop counters/logic here to control duration
    djnz BeepLoop

ret





AlienDirection:

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

AlienGraphic_8x8_1:    
    defb %00111100
    defb %01000010
    defb %10100101
    defb %10000001
    defb %01111110
    defb %00100100
    defb %01000010
    defb %10000001
AlienGraphic_8x8_2:    
    defb %00111100
    defb %01000010
    defb %10100101
    defb %10000001
    defb %01111110
    defb %00100100
    defb %01000010
    defb %00100100


GraphicTile3_8x8:    ; a box empty for no attribute colour
    defb %00010000
    defb %00010000
    defb %00010000
    defb %00010000
    defb %00010000
    defb %00010000
    defb %00010000
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
    defb %00000000
    defb %00000000
    defb %00000000
    defb %00000000
    defb %00000000
    defb %00000000

AlienFrameCounter:
    defb 0
moveAlienTimer:
    defb 20
RocketXPos:
    defb 0
RocketYPos:
    defb 0
RocketFiring:
    defb 0

SpriteMoveX:
    defb 0
SpriteMoveY:
    defb 0
SpriteXPos:
    defb 10
SpriteYPos:
    defb 60
SpriteFrameCounter:
    defb 0
movedRightFlag:
    defb 0
movedLeftFlag:
    defb 0
alienCheckCount
    defb 0
ScoreChanged
    defb 0
AlienLocation:  ; we use the ix register to index through the possible aliens locaitons form here 
    ; row 1
    defW $4042
    defW $4044
    defW $4046
    defW $4048
    defW $404a
    defW $404c
    defW $404e
    defW $4050
    ; row 2
    defW $4062
    defW $4064
    defW $4066
    defW $4068
    defW $406a
    defW $406c
    defW $406e
    defW $4070
    ; row 3
    defW $4082
    defW $4084
    defW $4086
    defW $4088
    defW $408a
    defW $408c
    defW $408e
    defW $4090
    ;row 4
    defW $40a2
    defW $40a4
    defW $40a6
    defW $40a8
    defW $40aa
    defW $40ac
    defW $40ae
    defW $40b0
    ; row 5 
    defW $40c2
    defW $40c4
    defW $40c6
    defW $40c8
    defW $40ca
    defW $40cc
    defW $40ce
    defW $40d0
    ;row 6
    defW $40e2
    defW $40e4
    defW $40e6
    defW $40e8
    defW $40ea
    defW $40ec
    defW $40ee
    defW $40f0

    ;row 7
    defW $4802
    defW $4804
    defW $4806
    defW $4808
    defW $480a
    defW $480c
    defW $480e
    defW $4810

    ;row 8
    defW $4822
    defW $4824
    defW $4826
    defW $4828
    defW $482a
    defW $482c
    defW $482e
    defW $4830

AlienValid: ; define 64 bytes set to 1, could save memeory with bit compression, but we have a massive 48K!!!
    defs 8*8, 1
   
AlienAttributeLocations:
    defW $5042
    defW $5044
    defW $5046
    defW $5048
    defW $504a
    defW $504c
    defW $504e
    defW $5050

AlienMoveCounter
    defb 0

alienLeftRightCount
    defb 0


currentAlienValidAddress
    defw 0

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

score3Bytes: defb 0,0,0      ; Stored as: [100k/10k], [1k/100s], [10s/1s]

SpriteBlank_24x24:
    defs 8*9, 0

SpaceShip_1:
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00100001,%00100110
defb %00110000,%01001000,%10000100,%10110100,%10110100,%10000100,%00000010,%00000001
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00010000,%10010000
defb %00101000,%00110001,%01000010,%10001000,%11110000,%00000000,%00000000,%00000000
defb %00000000,%10000110,%10000101,%01001000,%01111000,%00000000,%00101000,%01010000
defb %11010000,%00110000,%00001000,%01000100,%00111100,%00000000,%00000000,%00000000
defb %00000000,%00000000,%00000000,%00000000,%00000001,%00000000,%00000000,%00000000
defb %00100100,%01001000,%10010010,%01000100,%00001000,%00010000,%00000000,%00000000
defb %00000000,%00000000,%00000000,%00000000,%00000000,%10000000,%00000000,%00000000
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000


SpaceShip_2:
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00100001,%00100110
defb %00110000,%01001000,%10000100,%10110100,%10110100,%10000100,%00000010,%00000001
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00010000,%10010000
defb %00101000,%00110001,%01000010,%10001000,%11110000,%00000000,%00000000,%00000000
defb %00000000,%10000110,%10000101,%01001000,%01111000,%00100000,%00001000,%01010000
defb %11010000,%00110000,%00001000,%01000100,%00111100,%00000000,%00000000,%00000000
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000010,%00000000,%00000000
defb %10010000,%00101000,%10010010,%00100010,%10000100,%00010010,%00000000,%00000000
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000

end $8000