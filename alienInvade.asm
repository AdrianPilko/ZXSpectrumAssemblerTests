;;;;; Adrian Pilkington 2026

;;;;; Basically a simple shoot the aliens game
;;;;; 
;;;;;
;;;;; Known Bugs and Todo list
;;      1) sometimes it's not triggering rocket hit alien (around call to RocketHIT) 
;;      2) the side boarders sometimes get trashed when the aliens move further down
;;      3) would be good to have smooth scrolling rather than character based moves
;;          (including for the flying saucer)
;; DONE 4) would be good to have better sound, and reinstate the im2 now the other iy bug fixed
;;      5) boss levels at end of say 3 main levels would be better
;;      6) flayer space ship power ups like multiple rockets or shields
;;      7) better selection of which alien fires shot and maybe more than one at once (esp in later levels)
;;      8) the shields don't do anything yet - they should protect from fire and not get erroded by any shots
;;      9) better intro screen with high score shown and keys selection
;;      10) allow player to define keys


;; some helpful equ's
CLS equ $0d6b
ROM_OPEN_CHANNEL equ $1601
ROM_PRINT_STRING equ $203c
;
; PRINT control codes - work with ROM_PRINT_STRING and RST 0x10
;
INK     equ $10
PAPER   equ $11
FLASH   equ $12
BRIGHT  equ $13
INVERSE equ $14
OVER    equ $15
AT      equ $16
TAB     equ $17
CR      equ $0c


START_OF_ATTRIBUTE_SCREEN_MEM equ $5800
;sounds
C_5: EQU $0326
C_5_FQ: EQU $020B / $10
C_4: EQU $066E
C_4_FQ: EQU $0105 / $10

LOCATE: equ $0dd9
NUMBER_ALIEN_IN_ROW: equ 8
NUMBER_ALIEN_ROWS: equ 8

ALIEN_MOVE_TIMER_INIT: equ 30
NUMBER_OF_LEFT_RIGHTS_ALIENS: equ 2
SAUCER_TIMER_INIT: equ 128
SAUCER_Y_POS: equ 8
TOTAL_NUM_ALIENS: equ 64

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
    ld hl, startOfISRSoundTable
    ld (isrSoundCount), hl
    ei                  ; re enable interrupts
    jp Main_FullReset


MyISR:
    ex af, af'              ; save a and flags to alternate register set
    exx
    push ix
    push iy

        ;ld  a,5                ; Set color (indicates processing start)
        ;out ($FE), A           ; Port $FE (254) controls the border
        ld hl, FrameCount ; this is for syncing with game loop to frame
                            ; probably only sync once to keep it speedy enough
        inc (hl)
        ; check if the player decided to stop the "music" playing
        ld a, (musicOnFlag)
        cp 0
        jp z, skipMusicInISR

        ld hl, (isrSoundCount)    ; Load current 16-bit address
        inc hl                    ; Point to next byte in table

        ; Check if we reached the end
        ld de, endOfISRSoundTable ; Load the end-marker address
        or a                     ; Clear Carry flag for SBC
        sbc hl, de                ; Subtract DE from HL
        add hl, de                ; Restore HL (SBC modified it)

        jp z, resetISRBeepTable            ; If HL == DE, jump to reset
        
        ; If not at end, save the incremented HL back to memory
        ld (isrSoundCount), hl
        
        push af
            ld a, ($5C48)   ; Load current border color from BORDCR ($5C48)
            ;and 7           ; Keep only the border bits (0-2)
            or 16           ; Set Bit 4 (Speaker ON)
            out ($fe), a    ; Output to speaker + current border
            ld a, (hl)
            ld b, a
ISRDelayLoop:   
            nop
            nop
            djnz ISRDelayLoop   
            ld a, ($5C48)   ; Load current border color from BORDCR ($5C48)
            xor 16          ; Toggle only the speaker bit (Bit 4)
            out ($fe), a    ; Output to speaker + current border
        pop af
        jr skipReset
resetISRBeepTable:
    ld hl, startOfISRSoundTable
    ld (isrSoundCount), hl
skipReset:
    ;ld  a,0                ; Set color (indicates isr end)
    ;out ($FE), a           ; Port $FE (254) controls the border

skipMusicInISR:
    pop iy
    pop ix    
    exx
    ex af,af'
    ei                  ; Re-enable interrupts
    reti                ; Return from Interrupt

isrSoundCount:
    defw startOfISRSoundTable
startOfISRSoundTable:
    defs 20, 1
    defs 10, 20
    defs 20, 1
    defs 10, 20

    defs 5, 1
    defs 5, 20
    defs 5, 1
    defs 5, 20

endOfISRSoundTable:

WaitFrame:
    ld a, (FrameCount)
    ld b, a
    inc b
    inc b
WaitFrame_loop:
    halt                ; Wait for the next interrupt
    ld a, (FrameCount)
    cp b                ; Compare current to target
    jr c, WaitFrame_loop
    ret


FrameCount: 
    defw 0      ; Our 1-byte counter


Main_FullReset:
    ld a, ALIEN_MOVE_TIMER_INIT
    ld (AlienTimerInit), a
    ld a, 1
    ld (level), a
    xor a
    ld (highScore3Bytes),a 
    ld (highScore3Bytes+1),a 
    ld (highScore3Bytes+2),a 

Main_AfterGameOver:
    ; just reset the level 
    ld a, 1
    ld (level), a
    
    xor a 
    ld (score3Bytes), a 
    ld (score3Bytes+1), a 
    ld (score3Bytes+2), a 
    call PrintFirstScreen

Main_LevelUpReset:

    ld hl, $4000
    ld (hl), 0
    ld de, $4001
    ld bc, $1800
    ldir

    ld a, (AlienTimerInit)
    dec a 
    cp 0
    jp z, noUpdateSpeed
    cp 1
    jp z, noUpdateSpeed
    cp 2
    jp z, noUpdateSpeed
    ld (AlienTimerInit), a

noUpdateSpeed:
    ; initialise all the variables apart from highScore
    call drawShields
    ld a, 1
    ld (AlienDirection),a 
    xor a
    ld (Main_LevelUpResetFLAG), a
    ld (rocketHitButNotLevelUp), a
    ld (rowEvenOddToggle),a    
    ld (alienLeftRightCount),a
    ld (saucerFrameCount), a
    ld (saucerXPos), a
    ld (saucerEnabled), a
    ld (alienShotAddress+0), a
    ld (alienShotAddress+1), a
    ld (alienFireToggle), a
    ld (alienShotInFlightFlag), a
    ld (AlienFrameCounter), a
    ld (RocketXPos), a
    ld (RocketYPos), a
    ld (RocketFiring), a
    ld (SpriteMoveX), a
    ld (SpriteMoveY), a
    ld (SpriteFrameCounter), a
    ld (movedRightFlag), a
    ld (movedLeftFlag), a
    ld (alienCheckCount), a
    ld (ScoreChanged), a
    ld a, 20
    ld (moveAlienTimer),a
    ld a, 60
    ld (saucerTimer), a

    ;; setup the aliens after a restart
    ld de, AlienLocation
    ld hl, AlienLocationInits
    ld bc, 128
    ldir 
    ld hl, AlienValid           ; use the z80 memory overlap trick to initialise all the AlienValid to 1
    ld (hl), 1
    ld de, AlienValid+1 
    ld bc, 63
    ldir 
    xor a
    ld (AlienHitCount), a

    ld a, 15
    ld (SpriteXPos), a
    ld a, 160
    ld (SpriteYPos), a

    LD HL, 22528     ; Start of Attribute Memory
    LD (HL), 6      
    LD DE, 22529     ; Point to next byte
    LD BC, 544     
    LDIR             ; Rapid block copy

    LD HL, 22528     ; Start of Attribute Memory
    LD (HL), 3      
    LD DE, 22529     ; Point to next byte
    LD BC, 64     
    LDIR             ; Rapid block copy
 
    LD HL, 22528+544     ; Start of Attribute Memory
    LD (HL), 5      
    LD DE, 22529+544     ; Point to next byte
    LD BC, 96      
    LDIR             ; Rapid block copy
    
    LD HL, 22528+640     ; Start of Attribute Memory
    LD (HL), 4     
    LD DE, 22529+640     ; Point to next byte
    LD BC, 127     
    LDIR             ; Rapid block copy


    LD HL, 23231    ; Start of Attribute Memory
    LD (HL), 2       
    LD DE, 23232     ; Point to next byte
    LD BC, 64       ; Fill the remaining 767 bytes
    LDIR             ; Rapid block copy



    call drawPlayAreaBorder
    call PrintLevel

    ld hl,highScore3Bytes
    ld de, $401a
    call SHOW_SCORE

    ld hl,score3Bytes
    ld de, $4000
    call SHOW_SCORE    


MainGAME_loop:

    ld iy, $5c00  ; backstop in case jumped back without reenabling
    ei    

    call WaitFrame

    xor a
    ld (rocketHitButNotLevelUp),a
    ld (Main_LevelUpResetFLAG),a 

;    ld hl, score3Bytes
;    ld de, $4000
;    call SHOW_SCORE
    ;ld  a,3                ; Set color (indicates processing start)
    ;out ($FE), A           ; Port $FE (254) controls the border
    
    call ScanTheKeyBoard    ; main program code
    
   ; ld a, 0                ; Set color to BLACK (indicates processing end)
   ; out ($FE), A
                            ; Any remaining space in the border is "idle" time
    ld a, (rocketHitButNotLevelUp)
    cp 1
    jp z, MainGAME_loop

    ld a, (Main_LevelUpResetFLAG)
    cp 1
    jp z, Main_LevelUpReset   

    jp MainGAME_loop

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
    jr nz, ScanKey_M
    set $04, d   
ScanKey_M:          ; to turn music on or off
    ld a, $7f
    in a, ($fe)
    bit $02, a
    jr nz, DoneScanKeys
    set $05, d  
DoneScanKeys: 
    bit $02, d
    jr nz, MoveSpriteLeft
    bit $03, d
    jr nz, MoveSpriteRight
    bit $04, d
    jp nz, FireRocket
    bit $05, d
    jp nz, turnMusicOnOff
    jp DrawSprite

turnMusicOnOff:
    ld a,(musicOnOffInc)
    inc a   ; toggle musicOnOffInc
    ld (musicOnOffInc), a
    bit 0, a
    jp z, turnMusicOn
    xor a
    ld (musicOnFlag), a
    jp DrawSprite
turnMusicOn:    
    ld a, 1
    ld (musicOnFlag), a
    jp DrawSprite

MoveSpriteLeft:       
    call DrawBlank24_24
    ld a, (SpriteXPos)
    dec a
    cp 0
    jp z, DrawSprite
    ld (SpriteXPos),a 
    jp DrawSprite
MoveSpriteRight:
    call DrawBlank24_24
    ld a, (SpriteXPos)
    inc a
    cp 29
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

    ld b, 20 ; duration (delay)
    call beep

DrawSprite:    
    call isShotInFlight  ; do alien shot if not already or continue shot
    
    ; if rocket firing then draw 
    ld a, (RocketFiring)     ;     this is the players shot
    cp 1
    jp nz, ActuallyDrawSprite

    call CheckAliensHit

    ld a, (RocketXPos)
    ld b, a
    ld a, (RocketYPos)
    ld c, a
    ;; check if hit saucer, if enabled
    ld a, (saucerEnabled)
    cp 1
    jp nz, saucerHitCheckSkip

    ld a, (saucerXPos) ;only check x position should do y as well!!
    cp b
    jp nz, saucerHitCheckSkip

  ;; got this far then reset saucer and increase score
saucerHit:
    ld a, (saucerXPos)
    dec a
    ld b, a
    ld c, SAUCER_Y_POS
    ld de, SpriteBlank_24x24
    call DrawSprite8x24

    xor a
    ld (saucerEnabled), a
    ld (saucerXPos), a
    call increaseScore
    call increaseScore
    call increaseScore
    call increaseScore

saucerHitCheckSkip:
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
    ld b, -8
    add a, b
    
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
    jp z, resetRocket
    cp 8
    jp z, resetRocket
    cp 7
    jp z, resetRocket
    cp 6
    jp z, resetRocket
    cp 5
    jp z, resetRocket
        
    jp ActuallyDrawSprite
resetRocket:
    ;ld b, 10
    ;call beep
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
    call DrawSprite24x24   ; draw the players space ship
    
    ld a, (moveAlienTimer)
    dec a
    ld (moveAlienTimer),a
    cp 1
    call z, DrawAliensTimerExpired
    ret

DrawAliensTimerExpired:
    ld hl, score3Bytes
    ld de, $4000
    call SHOW_SCORE

    call DrawAliensThisTimeBLANK
    call UpdateAlienPositions
    call ChooseAliens
    call DrawAliensThisTime
    call CheckIfAlienDirChangeLeft

    jp nz, alienDirChange
    call CheckIfAlienDirChangeRight
    jp nz, alienDirChange
    ;; otherwise just keep going
    jp noDirectionChange
alienDirChange:
    ld a, (AlienDirection)
    inc a
    and %00000001    ; this will cause a to toggle
    ld (AlienDirection),a
    ld a, (alienLeftRightCount)
    inc a 
    ld (alienLeftRightCount),a 

noDirectionChange:
    ;; reset alien move timer. -the aliens move at lower rate than the space ship
    ld a, (AlienTimerInit)
    ld (moveAlienTimer),a

    ;; other times controlling the flying saucer power up and other things
    ld a, (saucerEnabled)
    cp 1
    call z, DrawSaucerAndUpdate

    ld a, (saucerTimer)
    dec a
    ld (saucerTimer),a
    cp 1
    call z, DrawSaucerTimeExpired
    
    ret

isShotInFlight:
    ld a, (alienShotInFlightFlag)
    cp 1
    jp z, skipAlienFireAsInProgress

    ;; setup the alien shot
    ld a, 1
    ld (alienShotInFlightFlag), a 

    ld ix, AlienLocation
    ld l, (ix+0)
    ld h, (ix+1)
    ld (alienShotAddress), hl    ; HL is now the correct screen address

skipAlienFireAsInProgress:
    ld de, (alienShotAddress)  

    ; check if hit space ship
    ld a, (SpriteXPos)
    ld b, a
    ld a, (SpriteYPos)
    ld c, a
    call GetScreenPos
    ; hl now contains the address
    ld a, d
    cp h
    jp z, checkShotHitPlayerLower
    jp skipCheckAlienHitPlayer
checkShotHitPlayerLower:
    ld a, e
    cp l
    jp z, GAME_OVER
    inc l   ; check next
    cp l
    jp z, GAME_OVER
    inc l   ; check next
    cp l
    jp z, GAME_OVER
    ;;; NEVER GETS HERE
skipCheckAlienHitPlayer:
    ld hl, (alienShotAddress)  

    ; 1. Erase current position 
    ld (hl), 0                
    ; 2. Calculate next scanline
    call NextScan             ; Assuming this calculates the next pixel row
    ; 3. Check for boundary ($5800)
    ld a, h                   ; The high byte of screen memory is $40 to $57
    cp $58                    ; Have we hit the attributes?
    jr nc, shotFinished      ; If H >= $58, the shot reached the bottom
    call NextScan             ; Assuming this calculates the next pixel row
    ; 3. Check for boundary ($5800)
    ld a, h                   ; The high byte of screen memory is $40 to $57
    cp $58                    ; Have we hit the attributes?
    jr nc, shotFinished      ; If H >= $58, the shot reached the bottom

    ; 4. Otherwise, save and draw
    ld (alienShotAddress), hl
    ld a, %00011000           ; Shot graphic
    ld (hl), a
    ret

shotFinished:
    ld hl, 0
    ld (alienShotAddress), hl ; Set to 0 to indicate no active shot
    xor a 
    ld (alienShotInFlightFlag),a
    ret


findTheFirstLowestAlien:
    di 

    ld ix, AlienValid
    ld iy, AlienLocation ; HL points to the start of your 64 bytes
    ld b, NUMBER_ALIEN_IN_ROW    ; Loop counter
    ld d, 0
find_first_max:
    push bc
        ; check if the alien is valid
        ld a, (ix+0)
        inc ix 
        cp 1
        jp nz, skip
        inc d
skip:
    pop bc
    djnz find_first_max  ; Loop until B = 0
    ; Result: D = Index of the first occurrence of the highest value
    ld iy, $5c00
    ei
    ret


DrawSaucerAndUpdate    
    ld a, (saucerXPos)
    dec a
    ld b, a
    ld c, SAUCER_Y_POS
    ld de, SpriteBlank_24x24
    call DrawSprite8x24

    ld a, (saucerXPos)
    ld b, a
    inc a 
    ld (saucerXPos),a
    cp 28
    jp z, resetSaucer
    ld c, 8

    ld de, FlyingSaucer
    ld a, (saucerFrameCount)
    cp 1 
    jp z, saucer_2
    cp 2 
    jp z, saucer_3
    cp 3
    jp z, saucer_4
    jp drawSaucer ; default for zero
saucer_2:
    ld de, FlyingSaucer+24
    jp drawSaucer
saucer_3:
    ld de, FlyingSaucer+48
    jp drawSaucer 
saucer_4:
    ld de, FlyingSaucer+72
    ld a, -1        ; reset by setting to -1 then drawSaucer will inc
    ld (saucerFrameCount),a     
drawSaucer:    
    call DrawSprite8x24
    ld a, (saucerFrameCount)
    inc a
    ld (saucerFrameCount),a 
    ret
resetSaucer:
    xor a 
    ld (saucerEnabled),a
    ld a, 1
    ld (saucerXPos),a   
    ld a, SAUCER_TIMER_INIT
    ld (saucerTimer),a
    ret 


DrawSaucerTimeExpired
    ld a, SAUCER_TIMER_INIT
    ld (saucerTimer), a 
    ld a, 1
    ld (saucerXPos), a
    ld (saucerEnabled), a
    ret

ChooseAliens:
    ld a, (AlienFrameCounter)
    inc a 
    ld (AlienFrameCounter) , a
    bit 0, a
    jp nz, Alien_1 
Alien_2:
    ld de, AlienGraphic_8x8_2
    ret
Alien_1:
    ld de, AlienGraphic_8x8_1
    ret




DrawAliensThisTimeBLANK:
    di 
    ld iy, AlienLocation
    ld ix, AlienValid           ; store first alien valid address used in loop to work out where is hit
    ld b, NUMBER_ALIEN_ROWS
    
AlienDrawLoop_RowsBL:
    push bc
        ld b, NUMBER_ALIEN_IN_ROW
AlienDrawLoop_ColsBL:
        push bc
            ; do we need to draw this one? 
            ld a, (ix+0)
            inc ix
            cp 1
            jp nz, skipDrawThisAlienBLANK
            ld l, (iy+0)
            ld h, (iy+1)
            ld de, GraphicTileBlank_8x8
            ld a, 1
            call DrawHorizontalBar
skipDrawThisAlienBLANK:
            inc iy
            inc iy
        pop bc
        djnz AlienDrawLoop_ColsBL   
    pop bc
    djnz AlienDrawLoop_RowsBL
    ld iy, $5c00
    ei

    ret


DrawAliensThisTime:
    di
    ld iy, AlienLocation
    ld ix, AlienValid           ; store first alien valid address used in loop to work out where is hit
    ld b, NUMBER_ALIEN_ROWS
    
AlienDrawLoop_Rows:
    push bc
        ld b, NUMBER_ALIEN_IN_ROW
AlienDrawLoop_Cols:
        push bc
            ;; de already be loaded but save to stack 
            push de
                ; do we need to draw this one?
                ld a, (ix+0)
                inc ix
                cp 1
                jp nz, skipDrawThisAlien
                ;;  the alien is valid check the alien did not reach the bottom
                ld a, $58
                cp h
                jp nz, notAtBottom
                
                pop de 
                pop bc 
                pop bc
                jp GAME_OVER
notAtBottom:
                ld l, (iy+0)
                ld h, (iy+1)
                ld a, 1
                call DrawHorizontalBar
skipDrawThisAlien:
                inc iy
                inc iy                
            pop de
        pop bc
        djnz AlienDrawLoop_Cols   

        ; draw alternating rows with different alien sprite
        ld a, (rowEvenOddToggle)
        inc a 
        ld (rowEvenOddToggle),a
        bit 0, a 
        jp nz, subtractAlienSpriteDE 
        ld hl, -16
        add hl, de
        push hl 
        pop de
        jp nextLoopDrawAlienRow
subtractAlienSpriteDE:
        ld hl, 16
        add hl, de      
        push hl 
        pop de
nextLoopDrawAlienRow:
    pop bc
    djnz AlienDrawLoop_Rows
    ld iy, $5c00
    ei

    ret

GAME_OVER:
    pop af ;; do this because we have jp'd from a call'd routine and need to get stack consistent
    ld A, 2          ; Open Channel 2 (Upper Screen)
    call 5633
    ld DE, MSG       ; Address of string
    ld BC, MSG_END-MSG ; Length of string
    call 8252        ; ROM routine to print

    ; copy the current score into the high score (if higher)
    call CheckNewHighScore
    ; compare it with high score, if its bigger then it is a new high score
    
    call Delay
    call Delay
    call Delay
    call Delay
    call Delay
    call Delay
    jp Main_AfterGameOver ;; restart the game
    
    ret         ; never gets here (oooo could same one byte) 
MSG:    DEFB 22          ; AT control code
    DEFB 10          ; Line 10 (Vertical middle)
    DEFB 8           ; Column 8 (Horizontal start)
    DEFB "*** GAME OVER ***"
MSG_END: EQU $


CheckNewHighScore:
    ld hl, score3Bytes          ; Point to current score (High byte)
    ld de, highScore3Bytes      ; Point to high score (High byte)
    ld b, 3               ; We have 3 bytes to check

compareHSLoop:
    ld a, (de)            ; Load HighScore byte into A
    ld c, a               ; Store it in C
    ld a, (hl)            ; Load Current Score byte into A
    
    cp c                  ; Compare Score (A) with HighScore (C)
    jr nz, HSdecided       ; If not equal, we know which is higher!
    
    inc hl                ; They were equal, move to middle byte
    inc de
    djnz compareHSLoop     ; Repeat for next byte
    
    ; If we get here, the scores are exactly equal
    jr HSnotHigher

HSdecided:
    jr c, HSnotHigher      ; If Carry is set, Score < HighScore
    
    ; --- NEW HIGH SCORE FOUND ---
    ; (Score was > HighScore)
    ld hl, score3Bytes          ; Point to current score (High byte)
    ld de, highScore3Bytes      ; Point to high score (High byte)
    ld b, 3               ; We have 3 bytes to check
    ldir ; bit overkill herre only 3 in loop!!
    ret

HSnotHigher:
    ; --- NOT A HIGH SCORE ---
    ret




drawShields:
    di
    ld de, Shield_24x16
    ld b,4
    ld c,140
    call DrawSprite24x24
    ld de, Shield_24x16
    ld b,11
    ld c,140
    call DrawSprite24x24
    ld de, Shield_24x16
    ld b,18
    ld c,140
    call DrawSprite24x24
    ld de, Shield_24x16
    ld b,25
    ld c,140
    call DrawSprite24x24
    ei
    ret 

CheckIfAlienDirChangeRight
;; we check the first and last screen for any values
;; but only when that isn't the player or alien shot (which is %00011000)
    ld b, 140  ; check this many lines
    ld hl, $405d   ; start address of column rto check
checkLeftColLoop_R:
    ld a, (hl)
    cp 0
    jp z, nextLoopIfZeroOnRight
    cp %00011000  ; the shot sprite data
    jp z, nextLoopIfZeroOnRight
    cp %00100000
    jp z, nextLoopIfZeroOnRight
    ;; so now it wasn't a shot or anything else so must be an alien
    ;; we set the zero flag to tell caller we found something
    or %00000001
    ret                   ; we found an alien
nextLoopIfZeroOnRight:
    call NextScan
    djnz checkLeftColLoop_R
    xor a
    ret                    ; we didn't find anything


CheckIfAlienDirChangeLeft:
;; we check the first and last screen for any values
;; but only when that isn't the player or alien shot (which is %00011000)
    ld b, 130  ; check this many lines
    ld hl, $4041   ; start address of column rto check
checkLeftColLoop_L:
    ld a, (hl)
    ;;ld (hl), %010101010
    cp 0
    jp z, nextLoopIfZeroOnLeft
    cp %00011000  ; the shot sprite data
    jp z, nextLoopIfZeroOnLeft
    ;; so now it wasn't a shot or anything else so must be an alien
    ;; we set the zero flag to tell caller we found something
    or %00000001
    ret                   ; we found an alien
nextLoopIfZeroOnLeft:
    call NextScan
    djnz checkLeftColLoop_L
    xor a
    ret                   ; we didn't find anything

UpdateAlienPositions:
    ;; determine direction aliens are currently moving
    ; 
    ld a, (AlienDirection)
    bit 0, a              ;AlienDirection inc elsewhere and this checks the resulting toggled bit zero
    jp z, AlienMoves_Left
AlienMoves_Right:

    di

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
    call resetAlienRow
    
    ld iy, $5c00
    ei
    ret    

AlienMoves_Left:
    di

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

resetAlienRow:
    ld a, (alienLeftRightCount)
    cp NUMBER_OF_LEFT_RIGHTS_ALIENS
    ret nz
;; move them all down by one row
    xor a
    ld (alienLeftRightCount),a 

    di

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
    ld iy, $5c00
    ei
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
    ex de,hl ;; swap hl into de to make comparison possible
    di
    ld iy, AlienLocation
    ld ix, AlienValid           ; store first alien valid address used in loop to work out where is hit
    ld b, NUMBER_ALIEN_ROWS  
CheckColisAlienLoop_Rows
    push bc
        ld b, NUMBER_ALIEN_IN_ROW
CheckColisAlienLoop_Cols:
        ;first check this alien position is valid still, ix is the index into the AlienValid memory
        ld l,(ix+0)
        ld a, l
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
        call z, RocketHIT
    
        ld a, (rocketHitButNotLevelUp)
        cp 1
        pop bc
        ret z
        push bc

        ld a, (Main_LevelUpResetFLAG)
        cp 1
        pop bc
        ret z
        push bc

        inc a 
        cp e
        call z, RocketHIT

        ld a, (rocketHitButNotLevelUp)
        cp 1
        pop bc
        ret z
        push bc

        ld a, (Main_LevelUpResetFLAG)
        cp 1
        pop bc
        ret z
        push bc

skipCheckCollision:
        inc iy
        inc iy   
        inc ix     
        djnz CheckColisAlienLoop_Cols
    pop bc
    djnz CheckColisAlienLoop_Rows
EndCheckAliensHit:
    ld iy, $5c00
    ei
    ret


RocketHIT:
    ld b, 40 ; duration (delay)
    call beep  
    ld a, 0 
    ld (RocketFiring), a

    ld a, 1
    ld (ScoreChanged), a

    ;; right lets print an explosion then blank it
    push hl
        ld de, Explosion
        ld  a,1
        call DrawHorizontalBar    
        call Delay
    pop hl    
    ld de, GraphicTileBlank_8x8
    ld  a,1
    call DrawHorizontalBar
    
    xor a       
    ld (ix+0), a        ; ix still has the locaiton of the AlienValid memory so set it back to zerp
    ld (RocketFiring),a
    ld a, (AlienHitCount)
    inc a
    ld (AlienHitCount),a

    ; increase the score
    call increaseScore    

    ld a, (AlienHitCount)
    cp TOTAL_NUM_ALIENS
    jp z, AllAliensDeadLevelUp
    ld a, 1
    ld (rocketHitButNotLevelUp), a
    ret

AllAliensDeadLevelUp:  

    ld iy, $5c00  ; backstop in case jumped back without reenabling
    ei   
    call WaitFrame    
    
    ld a, 2          ; Open Channel 2 (Upper Screen)
    call ROM_OPEN_CHANNEL
    ld de, MSG_LEVEL_UP       ; Address of string
    ld bc, MSG_LEVEL_UP_END - MSG_LEVEL_UP ; Length of string    
    call ROM_PRINT_STRING        ; ROM routine to print    
    ld a, (level) 
    inc a
    ld (level), a   
    call Delay
    call Delay
    call Delay
    call Delay
    call Delay
    call Delay
    ld a, 1 
    ld (Main_LevelUpResetFLAG), a

    ret
    
    
MSG_LEVEL_UP:
   defb  AT    ; control code
   defb  10     ; Line 10 (Vertical middle)
   defb  8      ; Column 8 (Horizontal start)
   defb  "**** LEVEL UP ****"
MSG_LEVEL_UP_END: EQU $




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
    ;ld hl, score3Bytes    ; Point to your score
    ;ld de, $4000        ; Top-left pixel address
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

PrintLevel:
    LD A, 2          ; Open Channel 2 (Upper Screen)
    CALL 5633

    LD A, PAPER               ; Paper colour
    RST $10
    LD A, 2                 ; Red
    RST $10

    LD DE, MSG_LEVEL       ; Address of string
    LD BC, MSG_LEVEL_END - MSG_LEVEL ; Length of string
    CALL 8252        ; ROM routine to print
; Now print the 8-bit number (in register A)
    ld a, (level) ; Load the 8-bit number
    LD C, A      ; Move the value to be printed into C
    LD B, 0      ; Clear B so BC = A
    CALL $1A1B   ; ROM routine to print BC in decimal
    
    ret 

MSG_LEVEL:    
    defb AT          ;  control code
    DEFB 0          ; Line 0
    DEFB 9           ; Column 8
    DEFB "LEVEL "
MSG_LEVEL_END: EQU $



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

    ;; b set to the delay when on by caller
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

PrintFirstScreen
                            ;; you'll notice this before any of the bigger copies or calls to ROM
                            ;; this is due to some race conditions notices with the ISR causing
    call WaitFrame          ;; corrupted output to screens

    ld hl, $4000
    ld (hl),$0
    ld de, $4001
    ld bc, $1800
    ldir
    
    call WaitFrame

    ld hl, $5800
    ld (hl),5
    ld de, $5801
    ld bc, $300
    ldir

    call WaitFrame

    ld a, 2          ; Open Channel 2
    call 5633
    ld de, SCREEN_TEXT_1       ; Address of string
    ld bc, SCREEN_TEXT_1_END-SCREEN_TEXT_1 ; Length of string
    call 8252        ; ROM routine to print

    call WaitFrame

    ld a, 2          ; Open Channel 2
    call 5633
    ld de, SCREEN_TEXT_2       ; Address of string
    ld bc, SCREEN_TEXT_2_END-SCREEN_TEXT_2 ; Length of string
    call 8252        ; ROM routine to print

    call WaitFrame

    ld a, 2          ; Open Channel 2
    call 5633
    ld de, SCREEN_TEXT_3       ; Address of string
    ld bc, SCREEN_TEXT_3_END-SCREEN_TEXT_3 ; Length of string
    call 8252        ; ROM routine to print

    call WaitFrame

    ld a, 2          ; Open Channel 2
    call 5633
    ld de, SCREEN_TEXT_4       ; Address of string
    ld bc, SCREEN_TEXT_4_END-SCREEN_TEXT_4 ; Length of string
    call 8252        ; ROM routine to print

    call WaitFrame

    ld hl, $59a0
    ld (hl),6
    ld de, $59a1
    ld bc, 127
    ldir

ScanToStartLoop:  
    ld de, bigAlienSprite_inverse
    ld a, (FirstScreenSpriteX_pos1)
    ld b, a
    ld c, 108
    call DrawSprite24x24

    ld de, bigAlienSprite_inverse
    ld a, (FirstScreenSpriteX_pos2)
    ld b, a
    ld c, 108
    call DrawSprite24x24

    ld de, bigAlienSprite_inverse
    ld a, (FirstScreenSpriteX_pos3)
    ld b, a
    ld c, 108
    call DrawSprite24x24

    call WaitFrame

    ld de, SpriteBlank_24x24
    ld a, (FirstScreenSpriteX_pos1)
    ld b, a
    ld c, 108
    call DrawSprite24x24

    ld de, SpriteBlank_24x24
    ld a, (FirstScreenSpriteX_pos2)
    ld b, a
    ld c, 108
    call DrawSprite24x24

    ld de, SpriteBlank_24x24
    ld a, (FirstScreenSpriteX_pos3)
    ld b, a
    ld c, 108
    call DrawSprite24x24

    ld a,(directionStartScreen)
    cp 1
    jp z, incrementXPosStS
    jp decrementXPosStS
incrementXPosStS:
    ld a, (FirstScreenSpriteX_pos1)
    inc a
    ld  (FirstScreenSpriteX_pos1),a
    ld a, (FirstScreenSpriteX_pos2)
    inc a
    ld  (FirstScreenSpriteX_pos2),a
    ld a, (FirstScreenSpriteX_pos3)
    inc a
    ld  (FirstScreenSpriteX_pos3),a
    jp checkDirectionStartScreen

decrementXPosStS:
    ld a, (FirstScreenSpriteX_pos1)
    dec a
    ld  (FirstScreenSpriteX_pos1),a
    ld a, (FirstScreenSpriteX_pos2)
    dec a
    ld  (FirstScreenSpriteX_pos2),a
    ld a, (FirstScreenSpriteX_pos3)
    dec a
    ld  (FirstScreenSpriteX_pos3),a



checkDirectionStartScreen:
    ld a, (FirstScreenSpriteX_pos1)
    cp 19
    jp z, changeDirectionLeftStS
    cp 0
    jp z, changeDirectionRightStS
    jp nextCheckStartScreen
changeDirectionLeftStS:
    xor a
    ld (directionStartScreen),a
    jp nextCheckStartScreen
changeDirectionRightStS:
    ld a, 1
    ld (directionStartScreen),a
nextCheckStartScreen:
    


;;ScanKey_M:          ; to turn music on or off
    ld a, $7f
    in a, ($fe)
    bit $02, a
    jr nz, checkForGameStartKey

    ld a,(musicOnOffInc)
    inc a   ; toggle musicOnOffInc
    ld (musicOnOffInc), a
    bit 0, a
    jp z, turnMusicOnOffInStartScreen
    xor a
    ld (musicOnFlag), a
    jp checkForGameStartKey
turnMusicOnOffInStartScreen:    
    ld a, 1
    ld (musicOnFlag), a 

checkForGameStartKey
;; scan space key  
    ld a, $7f
    in a, ($fe)
    bit $00, a
    jp nz, ScanToStartLoop
    ret     

SCREEN_TEXT_1:   
    defb INK
    defb 6
    defb PAPER
    defb 0
    defb 22          ; AT control code
    defb 6           ; Line 6 (Vertical middle)
    defb 9           ; Column 2 (Horizontal start)
    DEFB "Alien Invaders"
SCREEN_TEXT_1_END: EQU $


FirstScreenSpriteX_pos1
    defb 8
FirstScreenSpriteX_pos2
    defb 13
FirstScreenSpriteX_pos3
    defb 18

SCREEN_TEXT_2:   
    defb INK
    defb 6
    defb PAPER
    defb 0
    defb 22          ; AT control code
    defb 18         ; Line 18 (Vertical middle)
    defb 2           ; Column 2 (Horizontal start)
    DEFB "*** PRESS SPACE TO START ***"
SCREEN_TEXT_2_END: EQU $

SCREEN_TEXT_3:   
    defb INK
    defb 6
    defb PAPER
    defb 0
    defb 22          ; AT control code
    defb 20           ; Line 20 (Vertical middle)
    defb 7           ; Column 8 (Horizontal start)
    DEFB "A. Pilkington 2026"
SCREEN_TEXT_3_END: EQU $


SCREEN_TEXT_4:   
    defb INK
    defb 6
    defb PAPER
    defb 0
    defb 22          ; AT control code
    defb 21           ; Line 6 (Vertical middle)
    defb 6           ; Column 2 (Horizontal start)
    DEFB "YouTube: ByteForever"
SCREEN_TEXT_4_END: EQU $




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

AlienGraphic_8x8_3:    
    defb %00000000
    defb %00000000
    defb %01000010
    defb %00100100
    defb %00011000
    defb %00100100
    defb %01000010
    defb %00000000
AlienGraphic_8x8_4:   
    defb %00000000
    defb %00000000
    defb %11000011
    defb %01111110
    defb %00111100
    defb %01111110
    defb %11000011
    defb %00000000

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

Explosion:
    defb %00100100
    defb %01000010
    defb %10100101
    defb %00000000
    defb %00000000
    defb %10100101
    defb %01000010
    defb %00100100 


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
    defb 0

AlienLocation:  ; we use the iy register to index through the possible aliens locaitons form here 
;;; these are initialised from AlienLocationInits on game restart.
;; there's 128 because 64 aliens but 2 bytes per location which is a screen memory address
    defs 256, 0

AlienValid: ; define 64 bytes set to 1, could save memeory with bit compression, but we have a massive 48K!!!
    defs 64, 1
    defb 0
    defb 0
    defb 0
    defb 0
AlienHitCount:
    defb 0
;;; we need a copy of the alien locations which is to allow for game restarts
AlienLocationInits:  ; we use the iy register to index through the possible aliens locaitons form here 
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

rowEvenOddToggle
    defb 0
alienLeftRightCount
    defb 0
saucerFrameCount:
    defb 0
saucerTimer:
    defb 60
saucerXPos:
    defb 0
saucerEnabled:
    defb 0
AlienTimerInit:
    defb 0
alienShotAddress:
    defw 0
alienFireToggle:
    defb 0
alienShotInFlightFlag:
    defb 0
Main_LevelUpResetFLAG:
    defb 0
rocketHitButNotLevelUp:
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

Shield_24x16:
defb %00001111,%00011111,%00111111,%01111111,%11111111,%11111100,%11111110,%11111110
defb %11111111,%11111111,%11111111,%11111111,%11111111,%00000000,%00000000,%00000000
defb %11110000,%11111000,%11111100,%11111110,%11111111,%00111111,%01111111,%01111111
defb %11111100,%11111111,%11111111,%11111111,%11111111,%11111111,%11111110,%11111100
defb %00000000,%11111111,%11111111,%11111111,%11111111,%11111111,%00000000,%00000000
defb %00111111,%11111111,%11111111,%11111111,%11111111,%11111111,%01111111,%00111111
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000

FlyingSaucer:

defb %00000000,%00000001,%00011111,%01111000,%01111000,%00011111,%00000001,%00000000
defb %00000000,%11111111,%11111111,%11100011,%11100011,%11111111,%11111111,%00000000
defb %00000000,%10000000,%11111000,%10001110,%10001110,%11111000,%10000000,%00000000

defb %00000000,%00000001,%00011111,%01111100,%01111100,%00011111,%00000001,%00000000
defb %00000000,%11111111,%11111111,%01110001,%01110001,%11111111,%11111111,%00000000
defb %00000000,%10000000,%11111000,%11001110,%11001110,%11111000,%10000000,%00000000

defb %00000000,%00000001,%00011111,%01111110,%01111110,%00011111,%00000001,%00000000
defb %00000000,%11111111,%11111111,%00111000,%00111000,%11111111,%11111111,%00000000
defb %00000000,%10000000,%11111000,%11101110,%11101110,%11111000,%10000000,%00000000

defb %00000000,%00000001,%00011111,%01110111,%01110111,%00011111,%00000001,%00000000
defb %00000000,%11111111,%11111111,%00011100,%00011100,%11111111,%11111111,%00000000
defb %00000000,%10000000,%11111000,%01111110,%01111110,%11111000,%10000000,%00000000

bigAlienSprite_inverse:
defb %00000011,%00000100,%00001000,%00001000,%00001000,%00001000,%00001110,%00000001
defb %11111111,%01000001,%00000000,%11100011,%10100010,%11100011,%00001000,%11111111
defb %11100000,%00010000,%00001000,%10001000,%10001000,%10001000,%01111000,%10000000
defb %00000010,%00000100,%00001010,%00010001,%00001000,%00000100,%00000000,%00000000
defb %00101010,%00101010,%00000000,%00000000,%10000001,%00000000,%00000000,%00000000
defb %01000000,%00100000,%01010000,%10001000,%00010000,%00100000,%00000000,%00000000
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
defb %00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000

bigAlienSprite:
defb %11111100,%11111011,%11110111,%11110111,%11110111,%11110111,%11110001,%11111110
defb %00000000,%10111110,%11111111,%00011100,%01011101,%00011100,%11110111,%00000000
defb %00011111,%11101111,%11110111,%01110111,%01110111,%01110111,%10000111,%01111111
defb %11111101,%11111011,%11110101,%11101110,%11110111,%11111011,%11111111,%11111110
defb %11010101,%11010101,%11111111,%11111111,%01111110,%11111111,%11111111,%11101101
defb %10111111,%11011111,%10101111,%01110111,%11101111,%11011111,%11111111,%11111111
defb %11111011,%11111111,%11101111,%11111011,%11111111,%11111111,%11111111,%11111111
defb %10111111,%11111101,%01110111,%11011111,%11111111,%11111111,%11111111,%11111111
defb %10111111,%11111111,%01111111,%11101111,%11111111,%11111111,%11111111,%11111111


level: defb 0
score3Bytes: defb 0,0,0      ; Stored as: [100k/10k], [1k/100s], [10s/1s]
highScore3Bytes: defb 0,0,0
musicOnFlag: defb 0
musicOnOffInc: defb 0
directionStartScreen: defb 1
end $8000