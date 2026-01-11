org $8000

ATTR_S: equ $5c8d
ATTR_T: equ $5c8f
LOCATE: equ $0dd9
CLS: equ $0daf

Main:
ld a, $0e
ld hl, ATTR_T
ld (hl),a
ld hl, ATTR_S
ld (hl), a

call CLS

;set the screen boarder
ld a, $03
out ($fe),a

ld b, $18-$0e       ; b = Y COORD
ld c, $21-$03       ; b = X COORD
call LOCATE

ld hl, msg

Loop:
ld a, (hl)
or a
jr z, Exit
rst $10
inc hl
jr Loop


Exit:
jr Exit

msg:    defm 'Hello ZX Spectrum Assembly',$00

end $8000
