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
	ld a,2
	call open_screen
	; load the string into register de
	ld de,hello_text
	ld bc,13
	; call the ROM code to print the text on screen
	call print_text
	; return to basic "prompt"
	ret
end main