org $67ce

; Some of this code is from Toni Baker's Mastering Machine code on ZXX Spectrum
; I was trying to debug using HEXLD3 but was struggling so trying a standalone 
; in assembly here


; Define some ROM routines
cls     EQU $0D6B

start:
	; Clear screen
	call cls
    ld hl, $5881
    ld a, $09
	call bricks
    ld a, $2d
	call bricks
    ld a, $1b
	call bricks
    ld a, $09
	call bricks    
	ret

;; print bricks in two colours alternating for eight * 4 coloumns
;;;; registers: a  : should contain the character to print
;;;;            hl : first location of attribute data to store a at             
;;;;            b clobbered 
org $6800
bricks:
    ld b, 8
bricks_loop:
    
    ld (hl), a   ; print block
    inc hl
    ld (hl), a   ; print block
    inc hl
    add a, $09   ; cycle colour
    ld (hl), a   ; print block
    inc hl
    ld (hl), a   ; print block
    inc hl
    sub $09    
    djnz bricks_loop
    ret
end start