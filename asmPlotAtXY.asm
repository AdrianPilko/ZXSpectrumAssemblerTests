org $8000

main:
    call $0d6b  ; clear screenm rom  
    call FillScreenAttributesRed
    ld hl, scr_addr_table
    ld b, 31
    ld a, 10
    ld (Xpos),a
    ld (Ypos),a

pixelRightLoop:
    push bc
        ld a, (Xpos)
        ld b, a
        ld a, (Ypos)
        ld c, a
        call GetScreenPos
;        ld ix, dot_table
;        ld b, 8
;dotLoop:
;        ld a, (ix+0)
        ld a, $ff
        ld (hl), a
;        inc ix
;        djnz dotLoop

        ;overwrite what is the previous with blank since we push popped
        ;ld a, 0
        ;ld (hl), a
         
    pop bc
    djnz pixelRightLoop



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
DoneScanKeys: 
    bit $00, d
    jr nz, MoveUp
    bit $01, d
    jr nz, MoveDown
    bit $02, d
    jr nz, MoveLeft
    bit $03, d
    jr nz, MoveRight
    bit $04, d
    jp nz, FireRocket
    jp pixelRightLoop
MoveDown:
    ld a, (Ypos)
    cp 191
    jp z, pixelRightLoop
    inc a
    ld (Ypos),a
    jp pixelRightLoop    
MoveUp:
    ld a, (Ypos)
    cp 0
    jp z, pixelRightLoop
    dec a
    ld (Ypos),a
    jp pixelRightLoop    

MoveLeft:
    ld a, (Xpos)
    cp 0
    jp z, pixelRightLoop
    dec a
    ld (Xpos),a
    jp pixelRightLoop    
MoveRight:
    ld a, (Xpos)
    cp 31
    jp z, pixelRightLoop
    inc a
    ld (Xpos),a
    jp pixelRightLoop
FireRocket:
    jp pixelRightLoop
    ret
; utility routines
; get the previous scan line from current hl screen position and store back in hl
PreviousScan:
    ld a, h
    dec h
    and $07
    ret nz
    ld a, l
    sub $20
    ld l, a
    ret c
    ld a, h
    add a, $08
    ld h, a
    ret

NextScan:
    ; get the next screen address of from the current pointed to by hl register
    inc h
    ld a, h
    and $07
    ret nz
    ld a, l
    add a, $20
    ld l, a
    ret c
    ld a, h
    sub $08
    ld h, a
    ret

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

FillScreenAttributesRed:
    ld a, 3           
    out ($fe), a      

    ld hl, $5800        
    ld (hl), 00100010b  
    ld de, $5801        
    ld bc, 767          
    ldir                
    ret

;; these are the adresses of the screen positions used by getScreenPos
;; to calculate the address from an xy corrdinate
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

Xpos:
    defb 0
Ypos:
    defb 0
;; this is a single pixel "sprite" so smooth left right movement possible
dot_table:
    defb %11000011
    defb %00111100
    defb %00010000
    defb %00010000
    defb %00111100
    defb %11000011
    defb %00111100
    defb %11000011
end main
