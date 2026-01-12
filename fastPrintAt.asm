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
;set the screen boarder
ld a, $03
out ($fe),a

ResetAndContinue:
call CLS

ld b, 24
ld a, 24
MainLoop:
push bc
    push af
    call PrintMessage
;    call DelayLoop
    pop af 
pop bc
dec b
dec a
cp 0
jp nz, MainLoop 
jp ResetAndContinue
ret


PrintMessage:
ld c, $21-$02       ; b = X COORD
call LOCATE

ld hl, msg
Loop:
ld a, (hl)
or a
jr z, EndLoop
rst $10
inc hl
jr Loop
EndLoop:
ret

DelayLoop:
ld b, $f0
DelayLoop_1:
    push bc
    ld b, $f0
DelayLoop_2:
    djnz DelayLoop_2 
    pop bc
    djnz DelayLoop_1
ret

             
msg:    defm 'ByteForever ZX Spectrum Demo',$00
row_to_print_at: defb $00

end $8000
