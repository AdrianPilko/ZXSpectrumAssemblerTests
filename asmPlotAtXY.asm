org $F000

;  d = y pixel position
;  c = x pixel position
;  hl stores the address
;  from:
;  http://www.breakintoprogram.co.uk/hardware/computers/zx-spectrum/screen-memory-layout 
pixelAddress:      
    ld a,d          ; calculate y2,y1,y0
    and %00000111   ; mask out unwanted bits
    or %01000000    ; set base address of screen
    ld h,a          ; store in h
    ld a,d          ; calculate y7,y6
    rra             ; shift to position
    rra
    rra
    and %00011000   ; mask out unwanted bits
    or h            ; or with y2,y1,y0
    ld h,a          ; store in h
    ld a,d          ; calculate y5,y4,y3
    rla             ; shift to position
    rla
    and %11100000   ; mask out unwanted bits
    ld l,a          ; store in l
    ld a,c          ; calculate x4,x3,x2,x1,x0
    rra             ; shift into position
    rra
    rra
    and %00011111   ; mask out unwanted bits
    or l            ; or with y5,y4,y3
    ld l,a          ; store in l
    ret
    
main:
	call $0d6b ; rom routine to clear screen
    ld b, 100
    ld d, 20
    ld c, 30    
loop1:          ; loop1 draw vertical line
    call pixelAddress
    ld (hl), 1        
    inc d  
    djnz loop1
    
    ld b, 100
    ld d, 120
    ld c, 32   
loop2:          ; loop2 draw horizontal line
    call pixelAddress
    ld (hl), $ff        
    inc c
    djnz loop2   
	ret
end main
