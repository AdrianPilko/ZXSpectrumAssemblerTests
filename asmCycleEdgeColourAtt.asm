org $F000

main:
    call $0D6B
    xor a
infinite:    
    ld hl, $5800    ;first half colour attribute top left
    ld b, 16
loop1:      
    ld (hl),a
    inc hl
    inc a    
    djnz loop1    	

    ld hl, $580F    ; second half of top of screen
    ld b, 16
loop2:      
    ld (hl),a
    inc hl
    inc a    
    djnz loop2   	

    ld hl, $581F   ; down top right 3rd  
    ld b, 8    
loop3:      
    ld (hl),a
    push af
    ld a, $20
    add a, l
    ld l, a  
    pop af
    inc a
    djnz loop3    
    
    ld hl, $591F   ; down right middle 2/3rds 
    ld b, 8    
loop4:      
    ld (hl),a
    push af
    ld a, $20
    add a, l
    ld l, a  
    pop af
    inc a
    djnz loop4
    
    ld hl, $5A1F    ; down bottom right 3rd
    ld b, 8    
loop5:      
    ld (hl),a
    push af
    ld a, $20
    add a, l
    ld l, a  
    pop af
    inc a
    djnz loop5 
 
    ld hl, $5AFF    ; bottom right
    ld b, 16
loop6:      
    ld (hl),a
    dec hl
    inc a    
    djnz loop6    	

    ld hl, $5AF0    ; bottom left
    ld b, 16
loop7:      
    ld (hl),a
    dec hl
    inc a    
    djnz loop7

    ld hl, $5AE0    ; up bottom left 3rd
    ld b, 8    
loop8:      
    ld (hl),a
    push af
    ld a, l
    sub $20
    ld l, a  
    pop af
    inc a
    djnz loop8 

    ld hl, $59E0    ; up left 2/3rd
    ld b, 8    
loop9:      
    ld (hl),a
    push af
    ld a, l
    sub $20
    ld l, a  
    pop af
    inc a
    djnz loop9

    ld hl, $58E0    ; up top left 1/3rd
    ld b, 8    
loop10:      
    ld (hl),a
    push af
    ld a, l
    sub $20
    ld l, a  
    pop af
    inc a
    djnz loop10

    
    jp infinite
    c9
end main