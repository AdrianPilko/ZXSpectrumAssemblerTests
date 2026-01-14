org $8000

Main:
    ld hl, $4050  ; load a semi random address
    ld a, $01
    ld b, $20
MainLoop1:
    push bc
        call NextScan
        ld a, $01
        ld (hl), a
    pop bc
    djnz MainLoop1

    ;if we want to draw a line horizontally its easy, just in hl
    ld b, $5
MainLoop2:
    push bc
        ld a, $ff
        ld (hl), a
        inc l
    pop bc
    djnz MainLoop2

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

end $8000