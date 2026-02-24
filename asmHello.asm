org $8000

; ROM macros 
clear_screen	equ $0d6b
open_screen  	equ $1601
print_text  	equ $203c

; the text to print
;hello_text:
;	db 'Hello world!',13

;main:;
	; call the clear the screen ROM code
;	call clear_screen
	; open screen channel
;	ld a,2
;	call open_screen
	; load the string into register de
;	ld de,hello_text
;	ld bc,13
	; call the ROM code to print on screen
;	call print_text

        ; 1. wait for a keypress
wait_key:
        ei                 ; interrupts must be enabled for the ROM to update LAST-K
        ld a, (23560)      ; read system variable LAST-K ($5c08)
        and a              ; check if it's zero
        jr z, wait_key     ; if zero, no key pressed; loop back

        ; 2. clear the key buffer
        push af            ; save the character we just read
        xor a              ; a = 0
        ld (23560), a      ; reset LAST-K so it doesn't "auto-fire"
        pop af             ; restore the character to A

		;ld a, 'k'
        ; 3. print to screen
        rst 16             ; the ROM "print a character" routine ($10)
                           ; it prints the character in register A

        ;ret                ; return to BASIC
	jp wait_key

end $8000