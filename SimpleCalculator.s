@ ****************************************************************
@ Author:   John Kim <john.j.kim@vanderbilt.edu>
@ Class:    CS2231
@ Date:     11/29/16
@ File:	  	SimpleCalculator.s
@ Version:  1.0	
@
@ This program simulates a simple calculator on the embest board
@ ****************************************************************
		@ ----------@
		@ SWI Codes @
		@ ----------@
.equ	SWI_PrChr,     	0x00		@Display Character on Console
.equ	SWI_PrStr,		0x02		@Display String on Console
.equ	SWI_Open,     	0x66		@Open file
.equ	SWI_Close,     	0x68		@Close file
.equ	SWI_WrStr,     	0x69		@Write string to file.
.equ	SWI_RdStr,     	0x6a		@Read string from file.
.equ	SWI_WrInt,     	0x6b		@Write integer to file.
.equ	SWI_RdInt,     	0x6c		@Read integer from file.
.equ	SWI_GetTicks, 	0x6d		@Get current time.
.equ	SWI_Exit,       0x11		@Halt execution.

		@ -------------@
		@ EMBEST Codes @
		@ -------------@
.equ SWI_CHECK_BLUE_BTN,0x203   @ check press Blue button
.equ SWI_DRAW_STRING, 	0x204   @ display a string on LCD
.equ SWI_DRAW_INT,    	0x205	@ display an int on LCD
.equ SWI_CLEAR_DISPLAY,	0x206	@ clear LCD
.equ SWI_DRAW_CHAR,   	0x207   @ display a char on LCD
.equ SWI_CLEAR_LINE,  	0x208   @ clear a line on LCD


.equ KEY_00, 	0x01     	@button(0)
.equ KEY_01, 	0x02     	@button(1)
.equ KEY_02,	0x04     	@button(2)
.equ KEY_03, 	0x08     	@button(3)
.equ KEY_04, 	0x10     	@button(4)
.equ KEY_05, 	0x20     	@button(5)
.equ KEY_06, 	0x40     	@button(6)
.equ KEY_07, 	0x80     	@button(7)
.equ KEY_08, 	1<<8     	@button(8) - different way to set 0x100
.equ KEY_09,	1<<9		@button(9)
.equ KEY_10, 	1<<10    	@button(10)
.equ KEY_11,	1<<11    	@button(11)
.equ KEY_12,	1<<12    	@button(12)
.equ KEY_13,	1<<13    	@button(13)
.equ KEY_14,	1<<14    	@button(14)
.equ KEY_15,	1<<15    	@button(15) 

.equ SIZE, 0x30
.equ LAST_ROW,14
.equ LAST_COL,33
.equ MSG_ROW, 10

	.DATA
Welcome_0:	.asciz	"John Kim"
Welcome_1:	.asciz	"CS2231 Simple calculator."
Welcome_2:	.asciz	"0   1   2   3"
Welcome_3:	.asciz	"4   5   6   7"
Welcome_4:	.asciz	"8   9  <Enter>"
Welcome_5:	.asciz	"+   -   =   []"
msgBye:		.asciz	"End of program."
msgErr:		.asciz	"Error"
msgEmpty:	.asciz	"Empty"
msgBlank:	.asciz	"         "
msgEnter:	.asciz	"ENTER"
msgPlus:	.asciz	"PLUS"
msgMinus:	.asciz	"MINUS"
msgEqual:	.asciz	"EQUAL"

	.ALIGN
Stack:		.skip	SIZE
	.TEXT


@r10 will hold stack pointer
@r3 will hold accumulator (current value)
@main handles program standby until button depression, as well as 
@redirection to other subroutines in the event that other operation 
@buttons are depressed
main:
;	bl 		test 				;test subroutine
	bl 		init

	@initial variables required later
	mov 	r7, #10				;constant: multiplying factor
	ldr		r10, =Stack			;initialize stack
	add 	r10, r10, #SIZE		;set stack pointer to last word
	redirect_init:
			mov 	r3, #0				;accumulator
			mov 	r0, #16

	redirect:
			bl 		wait 		;wait for button to be depressed...

			@at this point, r0 will hold button depressed [0..15]
			@redirect to the appropriate subroutine
			cmp 	r0, #9
			ble		accumulate 	;if(r0 <= 9), jump to accumulate subroutine

			cmp 	r0, #10		;enter will occupy KEY_10 and KEY_11
			bleq 	enter
			cmp 	r0, #11
			bleq 	enter

			cmp 	r0, #12
			bleq 	plus
			
			cmp 	r0, #13
			bleq 	minus

			cmp 	r0, #14
			bleq 	equal

			cmp 	r0, #15
			bleq 	dumpStack

			@at this point, user has entered a number and returned from a subroutine
			b		redirect_init

	@if number inputted, program must begin to accumulate in the event of multiple digits
	@r4 will hold multiplying factor (10)
	accumulate:
			@handle case where first digit entered is '0'
			cmp 	r0, #0 		;true: input is 0
			cmpeq 	r3, #0		;true: input is first number
			bleq 	displayAcc	;print '0'
			beq 	redirect	;ignore leading zero and await next digit
			
			@if program reaches this point, user inputted a digit between 0..9, and 
			@the number does not include any leading zeros
			mla 	r3, r7, r3, r0	;r3 := 10*r3+r0(digit)
			bl 		displayAcc

			b 		redirect 	;wait for another input
	

_main:
	swi	SWI_CLEAR_DISPLAY
	ldr 	r2,=msgBye			;display on LCD
	mov 	r0,#1				;column number
	mov 	r1,#1				;line number
	swi 	SWI_DRAW_STRING
	swi 	SWI_Exit        	;all done, exit


@-----------------------------------------------------------------
@ dumpStack:   Dump stack on LCD starting at LAST_COL LAST_ROW
@              and then going up.
@              Display > in front of location SP points at
@	       	   Display negative numbers.
@ Parameters : none
@ Return: nothing.
@ Registers used: r0-r5
@------------------------------------------------------------------
dumpStack:
	stmfd 	sp!, {lr, r4, r5}

	@since 12 words were reserved for the stack, this subroutine
	@will only dump 12 digits
	mov 	r5, #0 				;r5: word counter

	@use r4 to keep track of stack pointer, so as to not modify r10
	ldr 	r4, =Stack
	add 	r4, r4, #SIZE
	sub 	r4, r4, #4

	mov 	r0, #33
	mov 	r1, #14

	@draw '>' to denote beginning of stack
	mov 	r2, #'>'
	swi 	SWI_DRAW_CHAR

	add 	r0, r0, #1			;move to next column over

	dumpStack_loop:
			ldr 	r2, [r4], #-4		;load number @ r4, postdecrement by 4

			cmp 	r2, #0
			movlt 	r3, r2
			bllt 	printNeg
			swige 	SWI_DRAW_INT

			add 	r5, r5, #1			;increment word counter
			sub 	r1, r1, #1			;move up a row

			cmp 	r5, #12
			blt	dumpStack_loop

_dumpStack:
	ldmfd 	sp!, {pc, r4, r5}


@--------------------------------------------------------------
@ enter: push accumulator (r3) onto the stack.
@        displays ENTER msg
@ Parameters : none
@ Return: nothing.
@ Registers used: r0
@--------------------------------------------------------------
enter:
	stmfd 	sp!, {lr}

	stmfd 	r10!, {r3}
	ldr 	r0, =msgEnter
	bl 		displayMsg

_enter:
	ldmfd 	sp!, {pc}


@--------------------------------------------------------------
@ minus: push -sign onto the stack and process the top 3 elmts
@        display MINUS msg
@ Parameters : none
@ Return: nothing.
@ Registers used: 
@--------------------------------------------------------------
minus:
	stmfd 	sp!, {lr, r4-r6}

	mov 	r3, #'-'
	stmfd 	r10!, {r3}

	@add and store top 2 elements
	ldr 	r4, [r10, #4]		;offset by 4 for each digit (using FD stack)
	ldr 	r5, [r10, #8]
	sub 	r6, r5, r4
	str 	r6, [r10, #8]		;subtract two numbers and store at top of stack

	@display PLUS msg
	ldr 	r0, =msgMinus
	bl 		displayMsg

	@reset stack pointer 
	ldr		r10, =Stack			;initialize stack
	add 	r10, r10, #SIZE		
	sub 	r10, r10, #4		;unlike initialization, must adjust by -4. during a push
								;after initialization, r10 increments then populates the
								;next byte with data. here, r10 must be adjusted to the 
								;first byte, since it is already populated
	
_minus:
	ldmfd 	sp!, {pc, r4-r6}


@--------------------------------------------------------------
@ plus: push +sign onto the stack and process the top 3 elmts
@       displays PLUS msg
@ Parameters : none
@ Return: nothing.
@ Registers used: r2,r4-r6
@--------------------------------------------------------------
plus:
	stmfd 	sp!, {lr, r4-r6}

	mov 	r3, #'+'
	stmfd 	r10!, {r3}

	@add and store top 2 elements
	ldr 	r4, [r10, #4]		;offset by 4 for each digit (using FD stack)
	ldr 	r5, [r10, #8]
	add 	r6, r4, r5
	str 	r6, [r10, #8]		;add two numbers and store at top of stack

	@display PLUS msg
	ldr 	r0, =msgPlus
	bl 		displayMsg

	@reset stack pointer 
	ldr		r10, =Stack			;initialize stack
	add 	r10, r10, #SIZE		
	sub 	r10, r10, #4		;unlike initialization, must adjust by -4. during a push
								;after initialization, r10 increments then populates the
								;next byte with data. here, r10 must be adjusted to the 
								;first byte, since it is already populated
	
_plus:
	ldmfd 	sp!, {pc, r4-r6}


@--------------------------------------------------------------
@ equal: display top of stack (but leave the value there).
@	if stack empty - does nothing.	
@	if value < 0 must display minus sign and then ABS(value).
@	displays EQUAL msg 
@ Parameters : none
@ Return: none
@ Registers used: r0-r3
@--------------------------------------------------------------
equal:
	stmfd 	sp!, {lr}

	@if stack has no added values, does nothing
	ldr 	r0, =Stack
	cmp 	r10, r0
	beq 	_equal

	mov 	r0, #0
	mov 	r1, #10
	ldr 	r2, =msgBlank
	swi 	SWI_DRAW_STRING		;clear the row

	ldr 	r2, [r10]
	cmp 	r2, #0
	movlt 	r3, r2
	bllt 	printNeg
	blt		_equal

	swi 	SWI_DRAW_INT

_equal:
	ldmfd 	sp!, {pc}


@--------------------------------------------------------------
@ printNeg:    print a negative number: -(minus)ABS(nb)
@              if number >= 0 does nothing
@ Parameters : r0 = col where to print sign
@              r1 = row where to print the number
@              r3 = number to print
@ Return: nothing.
@ Registers used: r0-r2
@--------------------------------------------------------------
printNeg:
	stmfd 	sp!, {lr}

	mov 	r2, #'-'
	swi 	SWI_DRAW_CHAR
	add 	r0, r0, #1

	mvn 	r2, r3
	add 	r2, r2, #1
	swi 	SWI_DRAW_INT

_printNeg:
	ldmfd sp!, {pc}


@---------------------------NOT USED---------------------------
@ pop:  if less than 3 elements in stack: do nothing.
@       pop the 3 elmt on top (op1 op2 operation)
@       and replace with op1 operation op2.
@		Displays error msg if stack is not as expected.
@ Parameters : none
@ Return: nothing but r10 modified
@ Registers used: 
@---------------------------NOT USED---------------------------
pop:


@--------------------------------------------------------------
@ displayAcc:   display accumulator (r3). preserves r0-r4
@ Parameters : 	none
@ Return: nothing.
@ Registers used: r0,r1
@--------------------------------------------------------------
displayAcc:
	stmfd 	sp!, {lr, r0-r4}

	mov 	r0, #0
	mov 	r1, #10
	ldr 	r2, =msgBlank
	swi 	SWI_DRAW_STRING		;clear the row

	mov 	r2, r3
	swi 	SWI_DRAW_INT

_displayAcc:
	ldmfd 	sp!, {pc, r0-r4}


@--------------------------------------------------------------
@ displayMsg:   display msg
@ Parameters : 	msg address in r0
@ Return: nothing.
@ Registers used: r0-r2, r4
@--------------------------------------------------------------
displayMsg:
	stmfd 	sp!, {lr, r4}

	mov 	r4, r0
	@clear row
	ldr 	r2, =msgBlank
	mov 	r0, #0 				;column number
	mov 	r1, #10				;row number
	swi		SWI_DRAW_STRING

	@display message
	mov 	r2, r4
	swi 	SWI_DRAW_STRING

_displayMsg:
	ldmfd	sp!, {pc, r4}


@-----------------------------------------------------------
@ Check if one blue key has been depressed - pattern in r0
@ returns value 0..15 in r0 and -1 if no pattern
@ registers used: r0,r2
@-----------------------------------------------------------
gbk:
	stmfd 	sp!, {lr}

	mov 	r2, #0				;r2 will hold return a value [0..15]
	swi 	SWI_CHECK_BLUE_BTN	;stores #KEY_XX into r0

	cmp		r0, #KEY_15
	beq     Fifteen
	cmp     r0, #KEY_14
	beq     Fourteen
	cmp     r0, #KEY_13
	beq     Thirteen
	cmp     r0, #KEY_12
	beq     Twelve
	cmp     r0, #KEY_11
	beq     Eleven
	cmp     r0, #KEY_10
	beq     Ten
	cmp     r0, #KEY_09
	beq     Nine
	cmp     r0, #KEY_08
	beq     Eight
	cmp     r0, #KEY_07
	beq     Seven
	cmp     r0, #KEY_06
	beq     Six
	cmp     r0, #KEY_05
	beq     Five
	cmp     r0, #KEY_04
	beq     Four
	cmp     r0, #KEY_03
	beq     Three
	cmp     r0, #KEY_02
	beq     Two
	cmp     r0, #KEY_01
	beq     One
	cmp     r0,#KEY_00
	beq     Zero
	
	@if program reaches this point, no button has been depressed
	sub 	r0, r2, #1
	b 		_gbk

	Fifteen:
			add r2, r2, #1
	Fourteen:
			add r2, r2, #1
	Thirteen:
			add r2, r2, #1
	Twelve:
			add r2, r2, #1
	Eleven:
			add r2, r2, #1
	Ten:
			add r2, r2, #1
	Nine:
			add r2, r2, #1
	Eight:
			add r2, r2, #1
	Seven:
			add r2, r2, #1
	Six:
			add r2, r2, #1
	Five:
			add r2, r2, #1
	Four:
			add r2, r2, #1
	Three:
			add r2, r2, #1
	Two:
			add r2, r2, #1
	One:
			add r2, r2, #1
	Zero:

	mov 	r0, r2

_gbk:
	ldmfd	sp!, {pc}


@----------------------------------
@ init: display fake board to LCD.
@ returns value: none
@ registers used: r0, r1, r2
@----------------------------------
init:
	stmfd 	sp!, {lr}

	@draw Welcome_0 to Welcome_5 on LCD

	@Welcome_0
	mov		r0, #16 ;column number
	mov 	r1, #1 ;row number
	ldr 	r2, =Welcome_0
	swi 	SWI_DRAW_STRING

	@Welcome_1
	mov 	r0, #9
	mov 	r1, #2
	ldr 	r2, =Welcome_1
	swi 	SWI_DRAW_STRING

	@Welcome_2
	mov 	r0, #1
	mov 	r1, #4
	ldr 	r2, =Welcome_2
	swi 	SWI_DRAW_STRING

	@Welcome_3
	mov 	r1, #5
	ldr 	r2, =Welcome_3
	swi 	SWI_DRAW_STRING

	@Welcome_4
	mov 	r1, #6
	ldr 	r2, =Welcome_4
	swi 	SWI_DRAW_STRING

	@Welcome_5
	mov 	r1, #7
	ldr 	r2, =Welcome_5
	swi 	SWI_DRAW_STRING

_init:
	ldmfd 	sp!, {pc}


@----------------------------------
@ wait: waits for button to be depressed
@ returns value: returns value 0..15 in r0
@ registers used: r0-r2
@----------------------------------
wait:
	stmfd 	sp!, {lr}

	mov 	r1, #-1

	loop:
			bl 	gbk
			cmp r0, r1
			beq loop
	
_wait:
	ldmfd 	sp!, {pc}


@----------------------------------
@ test: tests various subroutines
@ returns value: none
@ registers used: all
@----------------------------------
test:
	stmfd 	sp!, {lr}

	mov 	r0, #33
	mov 	r1, #12

	@draw '>' to denote beginning of stack
	mov 	r2, #'>'
	swi 	SWI_DRAW_CHAR

	add 	r0, r0, #1
	mov 	r2, #5
	swi 	SWI_DRAW_INT



	@comparing signed bytes

	mov 	r3, #1
	mov 	r4, #-1
	cmp 	r3, r4
	bgt 	isgreater
	b 		isless

	isgreater:
			mov 	r0, #1

	isless:



	bl 		init				;display initialization. WORKS
;	bl 		gbk					;button depression detection. WORKS
	bl 		wait 				;wait for depression, return number. WORKS

_test:
	ldmfd 	sp!, {pc}


.END