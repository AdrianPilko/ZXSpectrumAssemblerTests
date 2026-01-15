org $8000

Main:
    call $0d6b   ; clear screen rom routine

    ld b, 24
    ld hl, $5800
    ld de, 32
SetColourLoop:
    ld a, $02
    ld (hl), a
    add hl, de 
    djnz SetColourLoop

    ld b, 24
    ld hl, $581f
    ld de, 32
SetColourLoop2:
    ld a, $05
    ld (hl), a
    add hl, de 
    djnz SetColourLoop2

    ld hl, $4000  ; start of pixel memory
    call DrawTheVeticalBanner
    ld hl, $401f  ; pixel address of last column
    call DrawTheVeticalBanner
    ld hl, $4001
    call DrawTheHorizontalBanner
    ;010T TSSS LLLC CCCC
    ld h, %01010000 
    ld l, %11100001
    call DrawTheHorizontalBanner
EndLoop:
    jp EndLoop



DrawTheHorizontalBanner:    
    ld b, 30    ; number of multiples of 8 blocks to display width
MainLoopHB1:
    push bc
        ld b, 8
        push hl
            ld hl, Sprite
            push hl
            pop de
        pop hl
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
    djnz MainLoopHB1
ret



DrawTheVeticalBanner:    
    ld b, 24    ; number of multiples of 8 blocks to display width
MainLoop2:
    push bc
        ld b, 8
        push hl
            ld hl, Sprite
            push hl
            pop de
        pop hl 
InnerLoop:
        ld a, (de)
        ld (hl), a
        call NextScan
        inc de
        djnz InnerLoop
    pop bc
    djnz MainLoop2
ret

Delay:
    push bc
    push af

    ld b, $f0
DelayLoopOuter:
    push bc
        ld b, $6
DelayLoop:
        ld a, 4
        djnz DelayLoop 
    pop bc
    djnz DelayLoopOuter

    pop af
    pop bc
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

Sprite:
    defb %11100111
    defb %11011011
    defb %10111101
    defb %01100110
    defb %01100110
    defb %10111101
    defb %11011011
    defb %11100111
end $8000