@ **************************************************
@ Author:   John Kim <john.j.kim@vanderbilt.edu>   *
@ Class:    CS2231                                 *
@ Date:     November 6, 2016                       *
@ File:	    validNum.s                             *
@ Version:  1.0	                                   *
@ **************************************************


@ This program reads a string of characters from the ARMSim console
@ and determines if this is a valid number or not.


		@ ----------@
		@ SWI Codes @
		@ ----------@

.equ	SWI_PrChr,0x00	@Display Character on Console
.equ	SWI_PrStr,0x02	@Display String on Console
.equ	SWI_Open, 0x66	@Open file
.equ	SWI_Close,0x68	@Close file
.equ	SWI_WrStr,0x69	@Write string to file.
.equ	SWI_RdStr,0x6a	@Read string from file.
.equ	SWI_WrInt,0x6b	@Write integer to file.
.equ	SWI_RdInt,0x6c	@Read integer from file.
.equ	SWI_Timer,0x6d	@Get current time.
.equ	SWI_Exit,0x11	@Halt execution.

.equ 	Stdin,0	        @ 0 is the file descriptor for STDIN
.equ 	Stdout,1       	@ Set output target to be Stdout
.equ	BytesCnt,6	@ Bytes to read (last one will be null)
			@ so will only store 5 bytes max.

	.DATA
buffer:
	.word	9,8,7,6,5,4,3,2,1,-1	@ buffer to store input
msgerr:
	.asciz	"Read/Write error."
msginvalid:
	.asciz	"This is not a valid number."
msgvalid:
	.asciz	"This is a valid number. "
msgoutlimit:
	.asciz	"Outside of limits."
msgenter:
	.asciz	"\nType a number between [-9999..9999] then Enter: "
	.TEXT

@ validate should be the first subroutine called
; TO DO - CHECK IF NUMBER WITHIN LIMITS [-9999, 9999]
main:
	; begin program
	bl    validate ; after validate, r0 holds number of characters not including
								 ; null chracter
	bl    calculate ; after calculate, r0 will hold number
	mov   r1, r0
	mov   r0, #Stdout
	swi   SWI_WrInt

_main:
	swi	SWI_Exit	@ Exit gracefully.

@--------------------------------------------------------------
@ display: Display message to user.
@ Note: swi sets the carry bit in case of error.
@ Parameters : r1 = address message
@ Return: nothing
@ Registers used: r0
@--------------------------------------------------------------
display:
	stmfd sp!, {lr}

	; print initial message on screen
	mov   r0, #Stdout
	swi   SWI_WrStr

	ldmfd sp!, {pc}


@--------------------------------------------------------------
@ readString: Display msg to user, read a string from console.
@             and store it at address buffer.
@ Note: swi sets the carry bit in case of error.
@ Parameters : none
@ Return: byte count in r0 due to  SWI_RdStr
@ Registers used: r0 - r2
@--------------------------------------------------------------
readStr:
	stmfd sp!, {lr}
	; display message
	ldr   r1, =msgenter
	bl    display

	input:
	; read user input
	mov   r0, #Stdin
	ldr   r1, =buffer
	mov   r2, #BytesCnt
	swi   SWI_RdStr

	; check if more than 5 characters. if so, display read/write error
	; and run function again
	cmp   r0, #BytesCnt
	ldrgt r1, =msgerr
	blgt  display
	bgt   readStr

	ldmfd sp!, {pc}

@--------------------------------------------------------------
@ validate: Checks that string at address buffer is a valid number.
@           Assume strings ends with null char.
@	    			Display if number is valid or not.
@     			If number is not valid, query user for another number
@ Parameters : none
@ Returns r0, number of characters
@ Registers used: r0-r3
@--------------------------------------------------------------
validate:
	stmfd sp!, {lr}
	; prompt user to enter number and store number of characters in r2
	bl    readStr
	sub   r2, r0, #1 ; store number of characters in r2
	mov   r3, r2 ; r3 will be unchanged, while r2 will be modified

	ldr   r0, =buffer ; load address of buffer
	ldrb  r1, [r0], #1 ; load first character, move r0 to point to next character

	; remove leading spaces from input
	v_removeSpaces:
		cmp   r1, #' ' ; check if there are any leading spaces
		ldreqb r1, [r0], #1 ; load next character and adjust r0
		subeq r2, r2, #1 ; update number of digits
		beq   v_removeSpaces

	; process sign of input
	v_checkSign:
		cmp   r1, #'+'
		ldreqb r1, [r0], #1 ; load next character and adjust r0
		subeq r2, r2, #1 ; update number of digits
		beq   isNumber

		cmp   r1, #'-'
		ldreqb r1, [r0], #1 ; load next character and adjust r0
		subeq r2, r2, #1 ; update number of digits

	; after checkSign and removeSpaces, the next character must
	; be a number
	isNumber:
		; number must have <= 4 digits
		cmp   r2, #4
		blgt  dispInvalid
		bgt   validate

		isNumberLoop:
			; number must be between 0 and 9 and within limits, else invalid
			cmp   r1, #'0'
			bllt  dispInvalid
			blt   validate ; query user for another number

			cmp   r1, #'9'
			blgt  dispInvalid
			bgt   validate ; query user for another number

			subs  r2, r2, #1 ; 1 digit less left to process...

			ldrneb r1, [r0], #1
			bne   isNumberLoop

	mov   r0, r3 ; store number of characters

	ldmfd sp!, {pc}

@--------------------------------------------------------------
@ calculate: Calculate the value of an ASCII string containing
@            a number. Assume strings ends with null char.
@ Note: very similar to validate but simpler since we know
@       the number is correct.
@ Parameters : r0, number of characters
@ Returns r0 value of number.
@ Registers used: r0-r6
@--------------------------------------------------------------
calculate:
	stmfd sp!, {lr, r4, r5, r6}

	mov   r2, r0 ; use r2 to hold number of characters
	mov   r4, #1 ; set multiplying factor to 1
	mov   r3, #0 ; set sum to 0
	mov   r6, #10 ; to use in mul operation

	ldr   r0, =buffer ; load address of buffer
	ldrb  r1, [r0], #1 ; load first character and adjust

	; remove leading spaces from input
	removeSpaces:
		cmp   r1, #' ' ; check if there are any leading spaces
		ldreqb r1, [r0], #1 ; load next character and adjust r0
		subeq r2, r2, #1 ; update number of characters
		beq   removeSpaces

	; process sign of input
	checkSign:
		cmp   r1, #'+'
		subeq r2, r2, #1 ; update number of digits
		; *digits are not updated since the next subroutine will handle digits
		;  backwards, since the digits are stored as such
		beq   isPos

		cmp   r1, #'-'
		subeq r2, r2, #1 ; update number of digits
		; again, digits are not updated
		beq   isNeg

		sub   r0, r0, #1 ; if no sign, address to buffer must be readjusted to
										 ; position of first digit
		b     isPos ; if no sign, integer is positive

	; determine value
	; r0 should now point at a digit
	isPos:
		sub   r2, r2, #1 ; adjust offset for next command (e.g. 3 digits =
										 ; 2 index offset)
		add   r0, r0, r2 ; store address of end of buffer in r0
		ldrb  r1, [r0], #-1 ; load first character and adjust r0
		add   r2, r2, #1 ; restore number of digits

		isPosLoop:
			sub   r1, r1, #'0' ; adjust for ASCII offset
			mul   r5, r1, r4 ; r5 = r1(digit)*r4(multiplying factor)
			add   r3, r3, r5 ; sum = sum + r5

			subs  r2, r2, #1 ; 1 digit less left to process...
			ldrneb r1, [r0], #-1 ; load next character and adjust r0
			mulne r4, r6, r4 ; adjust multiplying factor
			bne   isPosLoop
			b     _calculate

	isNeg:
		sub   r2, r2, #1 ; adjust offset for next command (e.g. 3 digits =
																											; 2 index offset)
		add   r0, r0, r2 ; store address of end of buffer in r0
		ldrb  r1, [r0], #-1 ; load first character and adjust r0
		add   r2, r2, #1 ; restore number of digits

		isNegLoop:
			sub   r1, r1, #'0' ; adjust for ASCII offset
			mul   r5, r4, r1 ; multiply digit by factor and store in r5
			sub   r3, r3, r5 ; add to sum

			subs  r2, r2, #1 ; 1 digit less left to process...
			mulne r4, r6, r4 ; adjust multiplying factor
			ldrneb r1, [r0], #-1 ; load next character and adjust r0
			bne   isNegLoop

_calculate:
	mov   r0, r3
	ldmfd sp!, {pc, r4, r5, r6}

@--------------------------------------------------------------
@ dispInvalid: display invalid message
@ Parameters : none
@ Return: none
@ Registers used: r0-r1
@--------------------------------------------------------------
dispInvalid:
	stmfd sp!, {lr}

	ldr   r1, =msginvalid
	bl    display

	ldmfd sp!, {pc}

	.END
