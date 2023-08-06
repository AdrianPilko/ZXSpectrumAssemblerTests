org $F000

main:
    ld hl, $4000
    ld b, 192
loop1:
    push bc        
    ld b, 32
loop2:
    ld (hl),$ff
    inc hl
    djnz loop2
    pop bc
    djnz loop1    
	ret
end main