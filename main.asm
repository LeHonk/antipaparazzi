OPT	TITLE		"Antipaparazzi"
;=====================================================================================
;
;      Filename:  main.asm
;
;   Description:  Antipaparazzi Device Main file
;
;       Version:  1.0
;       Created:  14-01-19 12:57
;      Revision:  none
;      Compiler:  xc8
;
;        Author:  Tomas Holmqvist (TH), tomhol@gmail.com
;  Organization:  
;
;=====================================================================================

#include <xc.inc>

psect	conf, class=CONFIG, merge=1, pure
org	0
	dw	0x03F4			;config CPD=OFF, CP=OFF, FCMEN=ON, IESO=ON, 
					;	BOREN=ON, MCLRE=ON, PWRTE=ON, 
					;	FOSC=INTOSCIO

TMR1_LOAD	EQU	(0xFFFF-360+1)	; Start counting on 360 less then max, 
					; ie overflow and generate timer 
					; interrupt after 360 counts

UART_DELAY	EQU	((8000000/4/9600-10)/3)	; Baud delay @ 8MHz

psect	ram, class=RAM, space=1
int_w:		ds	2		; Context save of w during interrupt
int_status:	ds	2		; Context save of status during interrupt
putch_c:	ds	1		; Char to transmit
putch_cnt:	ds	1		; Bit loop counter
delay_cnt:	ds	1		; Delay counter0

psect	intentry, class=CODE, delta=2

	goto	int_handler

psect	text, class=CODE, merge=1, delta=2, pure

;===  FUNCTION  ======================================================================
; Name:  int_handler
; Description:  Handle various interrupts
;=====================================================================================
global	int_handler
int_handler:
;	BANKSEL	TMR1IF
;	btfss	TMR1IF
;	retfie
	movwf	int_w			; Save context
	swapf	STATUS, w
	movwf	int_status
	movlw	GPIO_GP4_MASK
	xorwf	GPIO			; Toggle GP4
;	bsf	GP4			; Erliest possible rise of puls out

	movlw	high(TMR1_LOAD)		; Reload timer to overflow after 360 pulses
	movwf	TMR1H
	movlw	low(TMR1_LOAD)
	movwf	TMR1L
;	bcf	GP4			; fall of puls out, not time critical
	bcf	TMR1IF			; Reenable Timer1 interrupt
	swapf	int_status, w		; Restore context
	movwf	STATUS
	swapf	int_w, f
	swapf	int_w, w
	retfie

;===  FUNCTION  ======================================================================
; Name:  putch
; Description:  Bitbanged uart transmit
; Note:         Destroys carry and W
;=====================================================================================

putch:
	banksel	0
	movwf	putch_c
	movlw	9			; 1 start bit + 8 bit + 1 stop bit
	movwf	putch_cnt
	bsf	CARRY			; Stop bit high at nineth iteration
	bcf	GP0			; Start bit
	
putch_loop:				;				Acc'd cycles
	movlw	UART_DELAY		; Uart bit delay		1
	movwf	delay_cnt		;				2
bit_delay:
	decfsz	delay_cnt, f		;				(1)
	goto	bit_delay		; loop to previous instruction	(3)

	rrf	putch_c, f		; Rotate bit into carry		3
	btfsc	CARRY			;				4
	bsf	GP0			; Carry set -> output high	5
	btfss	CARRY			;				6
	bcf	GP0			; Carry clear -> output low	7
	decfsz	putch_cnt, f		;				8
	goto	putch_loop		; loop over all 8 (+1) bits	10

	movlw	UART_DELAY		; Uart bit delay		1
	movwf	delay_cnt		;				2
stopbit_delay:
	decfsz	delay_cnt, f		;				(1)
	goto	stopbit_delay		; loop to previous instruction	(3)
	nop				;				3
	nop				;				4
	nop				;				5
	nop				;				6
	nop				;				7
	nop				;				8
	return				;				10

global	_main
global	start_initialization
_main:
start_initialization:
	BANKSEL	OSCCON
	movlw	0x71
	movwf	BANKMASK(OSCCON)	; Internal 8Mhz system clock
	BANKSEL	GPIO
	movlw	0b00000001		; GP0 High
	movwf	GPIO			; Clear all pins,  except GP0
	movlw	0x07
	movwf	CMCON0			; No comparator used
	BANKSEL	ANSEL
	clrf	BANKMASK(ANSEL)		; All pins digital IO
	movlw	0b00101110
	movwf	BANKMASK(TRISIO)	; GP5 in, GP4 out, GP3 nc, GP2 in, GP1 nc, GP0 out
	BANKSEL	T1CON
	movlw	0b00000110
	movwf	T1CON			; Asynchronous external clock source
	movlw	high(TMR1_LOAD)
	movwf	TMR1H			; Preload Timer1 counter
	movlw	low(TMR1_LOAD)
	movwf	TMR1L
	clrf	CCP1CON			; Turn off CCP to clear prescalers
	movlw	0x05
	movwf	CCP1CON			; Capture mode, every rising edge
	clrf	PIR1			; Clear all interrupt flags
	bsf	TMR1IE			; Timer1 interrupt enable
	bsf	PEIE			; Peripheral interrupt enable
	bsf	GIE			; Global interrupt enable
	bsf	TMR1ON			; Start Timer1

main_loop:
	btfss	CCP1IF			; poll CCP interrupt flag
	goto	main_loop		; loop 4-evva
	movf	CCPR1L, w
;	sublw	low(TMR1_LOAD)
;	btfsc	CARRY
;	decf	CCPR1H, f
	call	putch
	movf	CCPR1H, w
;	sublw	high(TMR1_LOAD)
	call	putch

	bcf	CCP1IF			; Reenable CCP "Interrupt"
	goto	main_loop		; Wait 4 next detection

END
