org $F000

;  d = y pixel position
;  c = x pixel position
;  hl stores the address
;  from:
;  https://www.overtakenbyevents.com/lets-talk-about-the-zx-specrum-screen-layout-part-three/
pixelAddress:      
    ld a,d	; Work on the upper byte of the address
    and %00000111		; a = Y2 Y1 y0
    or %01000000		; first three bits are always 010
    ld h,a		; store in h
    ld a,d		; get bits Y7, Y6
    rra		; move them into place
    rra		;
    rra		;
    and %00011000		; mask off
    or h		; a = 0 1 0 Y7 Y6 Y2 Y1 Y0
    ld h,a		; calculation of h is now complete
    ld a,d		; get y
    rla		;
    rla		;
    and %11100000		; a = y5 y4 y3 0 0 0 0 0
    ld l,a		; store in l
    ld a,c		;
    and %00011111		; a = X4 X3 X2 X1
    or l		; a = Y5 Y4 Y3 X4 X3 X2 X1
    ld l,a		; calculation of l is complete
    ret
    
main:
	call $0d6b ; rom routine to clear screen
    ld b, 150
    ld d, 5
    ld c, 5    
loop1:          ; loop1 draw vertical line
    call pixelAddress
    ld (hl), 1
    inc d  
    ;inc c
    djnz loop1
	ret
end main
