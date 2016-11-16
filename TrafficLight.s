@ ********************************************************
@ Author:   John Kim <d.piot@vanderbilt.edu>
@ Class:    CS2231
@ Date:     November 13, 2016
@ File:	    TrafficLight.s
@ Version:  1.0	
@
@ This program simulates a traffic light on the embest board.s
@ ********************************************************
		@ ----------@
		@ SWI Codes @
		@ ----------@
.equ	SWI_PrChr,     	0x00		@Display Character on ConsoleS
.equ	SWI_PrStr,      0x02		@Display String on Console
.equ	SWI_Open,	0x66		@Open file
.equ	SWI_Close,     	0x68		@Close file
.equ	SWI_WrStr,     	0x69		@Write string to file.
.equ	SWI_RdStr,     	0x6a		@Read string from file.
.equ	SWI_WrInt,     	0x6b		@Write integer to file.
.equ	SWI_RdInt,     	0x6c		@Read integer from file.
.equ	SWI_GetTicks, 	0x6d		@Get current time.
.equ	SWI_Exit,       0x11		@Halt execution.

		@ --------------@
		@ EMBEST Codes  @
		@ --------------@
.equ SWI_SETSEG8,	0x200   @ display on 8 Segment
.equ SWI_SETLED,      	0x201   @ LEDs on/off
.equ SWI_CheckBlack,  	0x202   @ check Black button
.equ SWI_CheckBlue,   	0x203   @ check press Blue button
.equ SWI_DRAW_STRING, 	0x204	@ display a string on LCD
.equ SWI_DRAW_INT,    	0x205	@ display an int on LCD
.equ SWI_CLEAR_DISPLAY,	0x206	@ clear LCD
.equ SWI_DRAW_CHAR,   	0x207   @ display a char on LCD
.equ SWI_CLEAR_LINE,  	0x208   @ clear a line on LCD


@ 8 Segment data
.equ SEG_A,  		0x80	@ patterns for 8 segment display
.equ SEG_B,		0x40    @ byte values for each segment
.equ SEG_C,		0x20    @ of the 8 segment display
.equ SEG_D,		0x08
.equ SEG_E,		0x04
.equ SEG_F,		0x02
.equ SEG_G,		0x01
.equ SEG_P,		0x10

@ Leds
.equ LEFT_LED,		0x02	@ bit patterns for LED lights
.equ RIGHT_LED,		0x01
.equ BOTH_LED,		0x03
.equ NO_LED,		0x00

@ Buttons
.equ L_BlackBtn, 	0x02	@ bit patterns for black buttons
.equ R_BlackBtn,	0x01

		@ ----------------@
		@ Misc.  Codes @
		@ ----------------@


.equ 	Stdin,	0       @ 0 is the file descriptor for STDIN
.equ 	Stdout,	1       @ Set output target to be Stdout
.equ	sec_1,	1000	@ One sec
.equ	sec_10,	10000	@ Ten sec

	.DATA
Digits:
.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_G 	@Display 0 on the 8 segment
.word SEG_B|SEG_C 				@Display 1
.word SEG_A|SEG_B|SEG_F|SEG_E|SEG_D 		@Display 2
.word SEG_A|SEG_B|SEG_F|SEG_C|SEG_D 		@Display 3
.word SEG_G|SEG_F|SEG_B|SEG_C 			@Display 4
.word SEG_A|SEG_G|SEG_F|SEG_C|SEG_D 		@Display 5
.word SEG_A|SEG_G|SEG_F|SEG_E|SEG_D|SEG_C 	@Display 6
.word SEG_A|SEG_B|SEG_C 			@Display 7
.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_F|SEG_G @Display 8
.word SEG_A|SEG_B|SEG_F|SEG_G|SEG_C 		@Display 9


	.TEXT
main:
    b       init

_main:
	swi 	SWI_Exit        @all done, exit


@--------------------------------------------------------------
@ timer: wait for x milliseconds
@ Parameter : r0 = number of ms
@ Return: nothing.
@ Registers used: r0-r3
@--------------------------------------------------------------
timer:
	stmfd   sp!, {lr}

	mov     r3, r0 ;store duration in r3
	swi     SWI_GetTicks ;store start time in r0
	add     r3, r0, r3 ;store end time in r3

loop:
	swi     SWI_GetTicks ;store current time in r0
	cmp     r0, r3
	blt     loop ;if current time < end time, loop

_timer:
    ldmfd sp!, {pc} ;pc = lr


@--------------------------------------------------------------
@ timerL: wait for x milliseconds or that left button is pressed
@ Parameter : r0 = number of ms
@             r1 = button pressed flag: 1 = button pressed
@ Return: nothing
@ Registers used: r0-r2
@--------------------------------------------------------------
timerL:
    stmfd   sp!, {lr}

    mov     r2, r0 ;store duration in r2
    swi     SWI_GetTicks ;store start time in r0
    add     r2, r0, r2 ;store end time in r2
    
    mov     r0, #0 ;clear r0 for SWI calls

    timerL_loop:
        ;check if current-time >= end-time
        swi     SWI_GetTicks ;store current time in r0
        cmp     r0, r2
        bge     _timerL

        ;check if left button has been pressed
        swi     SWI_CheckBlack ;store black button status in r0
        cmp     r0, #L_BlackBtn ;check if left black button has been pressed
        beq     _timerLButton

        b       timerL_loop ;if current-time < end-time and L_BlackBtn not depressed, loop

_timerL:
    ldmfd   sp!, {pc} ;return from subroutine

_timerLButton:
    ;if left button has been pressed, raise flag and return
    mov     r1, #1
    ldmfd   sp!, {pc}


@--------------------------------------------------------------
@ timerR: wait for x milliseconds or that right button is pressed
@ Parameter : r0 = number of ms
@             r1 = button pressed flag: 1 = button pressed
@ Return: nothing
@ Registers used: r0-r2
@--------------------------------------------------------------
timerR:
    stmfd   sp!, {lr}

    mov     r2, r0 ;store duration in r2
    swi     SWI_GetTicks ;store start time in r0
    add     r2, r0, r2 ;store end time in r2
    
    mov     r0, #0 ;clear r0 for SWI calls

    timerR_loop:
        ;check if current-time >= end-time
        swi     SWI_GetTicks ;store current time in r0
        cmp     r0, r2
        bge     _timerR

        ;check if right button has been pressed
        swi     SWI_CheckBlack ;store black button status in r0
        cmp     r0, #R_BlackBtn ;check if right black button has been pressed
        beq     _timerRButton

        b       timerR_loop ;if current-time < end-time and R_BlackBtn not depressed, loop

_timerR:
    ldmfd   sp!, {pc} ;return from subroutine

_timerRButton:
    ;if right button has been pressed, raise flag and return
    mov     r1, #1
    ldmfd   sp!, {pc}


@--------------------------------------------------------------
@ timerLS: wait for x milliseconds or that left button is pressed
@          and display countdown.
@ Parameter : r0 = number of ms, 0 <= r0 <= 9999
@ Return: nothing
@ Registers used: r0-r6
@--------------------------------------------------------------
timerLS:
    stmfd   sp!, {lr, r4-r6}

    mov     r4, r0
    bl      detSeconds
                   ;r4 = duration (ms)
    mov     r5, r0 ;r5 = #seconds

    ;turn on LED
    mov     r0, #LEFT_LED
    swi     SWI_SETLED

    timerLS_loop:
        ;check if finished
        cmp     r5, #0
        beq     _timerLS

        mov     r0, r5
        bl      displaySegment
        mov     r0, #1000
        bl      timerL
        cmp     r1, #1 ;check if flag raised
        beq     _timerLS ;if so, skip to end

        sub     r5, r5, #1

        b       timerLS_loop
    
    ;display 0 for 1 second
    mov     r0, #0
    bl      displaySegment
    mov     r0, #1000
    bl      timer

_timerLS:
    ;clear display
    mov     r0, #0
    mov     r1, #0
    swi     SWI_SETSEG8

    ;turn off LED
    mov     r0, #0
    swi     SWI_SETLED

    bl      blinkL

    ldr     r0, =9000
    bl      timerRS
    ldmfd   sp!, {pc, r4-r6}


@--------------------------------------------------------------
@ timerRS: wait for x milliseconds or that right button is pressed
@              and display countdown.
@ Parameter : r0 = number of ms
@ Return: nothing
@ Registers used: r0-r6
@--------------------------------------------------------------
timerRS:
    stmfd   sp!, {lr, r4-r6}

    mov     r4, r0
    bl      detSeconds
                   ;r4 = duration (ms)
    mov     r5, r0 ;r5 = #seconds

    ;turn on LED
    mov     r0, #RIGHT_LED
    swi     SWI_SETLED

    timerRS_loop:
        ;check if finished
        cmp     r5, #0
        beq     _timerRS

        mov     r0, r5
        bl      displaySegment
        mov     r0, #1000
        bl      timerR
        cmp     r1, #1 ;check if flag raised
        beq     _timerRS ;if so, skip to end

        sub     r5, r5, #1

        b       timerRS_loop

    ;display 0 for 1 second
    mov     r0, #0
    bl      displaySegment
    mov     r0, #1000
    bl      timer
    
_timerRS:
    ;clear display
    mov     r0, #0
    mov     r1, #0
    swi     SWI_SETSEG8

    ;turn off LED
    mov     r0, #0
    swi     SWI_SETLED

    bl      blinkR
    ldmfd   sp!, {pc, r4-r6}


@--------------------------------------------------------------
@ displaySegment: display a digit on the segment
@                 verifies char is in [0..9] (does nothing
@                 if char is not in [0..9]
@ Parameter : r0 = digit to display
@ Return: nothing.
@ Registers used: r0-r1
@--------------------------------------------------------------
displaySegment:
    stmfd   sp!, {lr}

    ;check if 0 <= r0 <= 9
    cmp     r0, #0
    blt     _displaySegment
    cmp     r0, #9
    bgt     _displaySegment

    ldr     r1, =Digits
    ldr     r0, [r1, r0, lsl#2]

    swi     SWI_SETSEG8

    b       _displaySegment

_displaySegment:
    ldmfd   sp!, {pc}


@--------------------------------------------------------------
@ blinkL: blink left led for one sec
@ Parameter : none
@ Return: nothing.
@ Registers used: r0-r2
@--------------------------------------------------------------
blinkL:
    stmfd   sp!, {lr}

    ;blink 4 times per second
    mov     r2, #4 ;keep track of number of blinks
    blinkL_loop:
        mov     r0, #LEFT_LED
        swi     SWI_SETLED
        mov     r0, #125
        bl      timer

        mov     r0, #0 ;turn off LED
        swi     SWI_SETLED
        mov     r0, #125
        bl      timer

        subs    r2, r2, #1
        bne     blinkL_loop

_blinkL:
    ldmfd   sp!, {pc}


@--------------------------------------------------------------
@ blinkR: blink right led for one sec
@ Parameter : none
@ Return: nothing.
@ Registers used: r0-r2
@--------------------------------------------------------------
blinkR:
    stmfd   sp!, {lr}

        ;blink 4 times per second
        mov     r2, #4 ;keep track of number of blinks
        blinkR_loop:
            mov     r0, #RIGHT_LED
            swi     SWI_SETLED
            mov     r0, #125
            bl      timer

            mov     r0, #0 ;turn off LED
            swi     SWI_SETLED
            mov     r0, #125
            bl      timer

            subs    r2, r2, #1
            bne     blinkR_loop

    _blinkR:
        ldmfd   sp!, {pc}

@--------------------------------------------------------------
@ init: turn on left led for 2 sec
@        turn on right led for 2 sec
@        turn on both leds for 2 sec
@        turn both leds off
@        count down
@ Parameters : none
@ Return: nothing.
@ Registers used: r0, r1, r5
@--------------------------------------------------------------
init:
    stmfd   sp!, {lr, r5}

    ;turn on left LED
    mov     r0, #LEFT_LED
    swi     SWI_SETLED
    mov     r0, #2000
    bl      timer

    ;turn on right LED
    mov     r0, #RIGHT_LED
    swi     SWI_SETLED
    mov     r0, #2000
    bl      timer

    ;turn on both LEDs
    mov     r0, #(LEFT_LED|RIGHT_LED)
    swi     SWI_SETLED
    mov     r0, #2000
    bl      timer

    ;turn off both LEDs
    mov     r0, #0
    swi     SWI_SETLED

    ;display countdown
    mov     r5, #9
    init_loop:
        ;check if finished
        cmp     r5, #0
        ble     _init_loop

        mov     r0, r5
        bl      displaySegment
        mov     r0, #1000
        bl      timer

        sub     r5, r5, #1

        b       init_loop
    
    _init_loop:
        ;display 0 for 1 second
        mov     r0, #0
        bl      displaySegment
        mov     r0, #1000
        bl      timer

        ;clear display
        mov     r0, #0
        mov     r1, #0
        swi     SWI_SETSEG8
        ldr     r0, =9000
        bl      timerLS

    ldmfd   sp!, {pc, r5}

@--------------------------------------------------------------
@ detSeconds: determine number of seconds, given milliseconds
@ Parameters : r0 = number of ms
@ Return:   r0 = number of seconds
@           r1 = remainder milliseconds
@ Registers used: r0-r2
@--------------------------------------------------------------
detSeconds:
    stmfd sp!, {lr}

    mov     r2, #0 ;r2 will increment per second
    mov     r1, r0 ;store number of ms in r1

    detSeconds_loop:
        cmp     r1, #1000
        blt     _detSeconds

        sub     r1, r1, #1000 ;subtract 1 second
        add     r2, r2, #1 ;increment r2

        b       detSeconds_loop

_detSeconds:
    mov     r0, r2
    ldmfd sp!, {pc}

	.END
