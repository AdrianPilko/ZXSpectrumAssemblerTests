org $8000

; ROM macros 
clear_screen	equ $0d6b
open_screen  	equ $1601
print_text  	equ $203c

; the text to print
hello_text:
	db 'Hello world!',13

main:
	; call the clear the screen ROM code
	call clear_screen
	; open screen channel
	ld hl, $4000
    ld b, $3A    
    ld a, $01
loopOuter:
    push bc
    ld b,$74
loopInner:    
    ld (hl),a
    inc hl 
    djnz loopInner
    pop bc
    djnz loopOuter
	ret
end main