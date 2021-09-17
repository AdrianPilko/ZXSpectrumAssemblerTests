org $8000

; Define some ROM routines
cls     EQU $0D6B
opench  EQU $1601
print   EQU $203C

; Define our string to print
string:
db 'Hello world!',13

start:
	; Clear screen
	call cls
llll:
	; Open upper screen channel
	ld a,2
	call opench

	; Print string
	ld de,string
	ld bc,13
	call print
    jr llll
	; Return to the operating system
	ret

end start
