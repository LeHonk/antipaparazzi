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

//#pragma config CPD=OFF, CP=OFF, FCMEN=ON, IESO=ON, BOREN=ON, MCLRE=ON, PWRTE=ON, FOSC=INTOSCIO

TMR1_LOAD	EQU	(0xFFFF-360+1)
					; Start counting on 360 less then max, 
					; ie overflow and generate timer 
					; interrupt after 360 counts */

UART_DELAY	EQU	208		; Baud delay @ 8MHz
#define TXpin   GP0                    /* Sowrtware UART transmit pin */

psect	text, abs, ovrld, class=CODE, merge=1, delta=2, pure
org	0x005

;===  FUNCTION  ======================================================================
; Name:  int_handler
; Description:  Hadndle various interrupts
;=====================================================================================
global	int_handler
int_handler:
	BANKSEL	0
	btfss	TMR1IF
	retfie
	bsf	GP4			; Erliest possible rise of puls out
	movlw	high(TMR1_LOAD)		; Reload timer to overflow after 360 pulses
	movwf	TMR1H
	movlw	low(TMR1_LOAD)
	movwf	TMR1L
	bcf	GP4			; fall of puls out, not time critical
	bcf	TMR1IF			; Reenable Timer1 interrupt
	retfie

;===  FUNCTION  ======================================================================
; Name:  putch
; Description:  Bitbanged uart transmit
; Note:         Destroys carry and W
;=====================================================================================
putch_c		EQU	0x20		; Char to transmit
putch_cnt	EQU	0x21		; Bit loop counter
delay_cnt	EQU	0x22		; Delay counter

putch:
	banksel	0
	movwf	putch_c
	movlw	9			; 8 bit + 1 stop bit
	movwf	putch_cnt
	bsf	CARRY			; Stop bit high at nineth iteration
	bcf	TXpin			; Start bit
	
putch_loop:
	movlw	UART_DELAY		; Uart bit delay
	movwf	delay_cnt
bit_delay:
	decfsz	delay_cnt, f
	goto	bit_delay		; loop to previous instruction

	rrf	putch_c, f		; Rotate bit into carry
	btfsc	CARRY
	bsf	TXpin			; Carry set -> output high
	btfss	CARRY
	bcf	TXpin			; Carry clear -> output low
	decfsz	putch_cnt, f
	goto	putch_loop		; loop over all 8 (+1) bits

	return

global	_main
global	start_initialization
_main:
start_initialization:
	BANKSEL	1
	movlw	0xF0
    	movwf	(OSCCON&0x7F)		; Internal 8Mhz system clock
	movlw	0xEF
    	movwf	(TRISIO&0x7F)		; GP4 Output
    	clrf	(ANSEL&0x7F)		; All pins digital IO
	BANKSEL	0
	movlw	0x06
    	movwf	T1CON			; Asynchronous external clock source
	movlw	high(TMR1_LOAD)
	movwf	TMR1H			; Preload Timer1 counter
	movlw	low(TMR1_LOAD)
	movwf	TMR1L
	movlw	0x05
    	movwf	CCP1CON			; Capture mode, every rising edge
	clrf	GPIO			; Clear all pins
	movlw	0x07
	movwf	CMCON0			; All pins digital IO
	clrf	PIR1			; Clear all interrupt flags
	bsf	TMR1IE			; Timer1 interrupt enable
    	bsf	PEIE			; Peripheral interrupt enable
    	bsf	GIE			; Global interrupt enable
    	bsf	TMR1ON			; Start Timer1

main_loop:
	btfsc	CCP1IF			; poll CCP interrupt flag
	goto	main_loop		; loop 4-evva
	movf	CCPR1L, w
	sublw	low(TMR1_LOAD)
	btfsc	CARRY
	decf	CCPR1H, f
	call	putch
	movf	CCPR1H, w
	sublw	high(TMR1_LOAD)
	call	putch

	bcf	CCP1IF			; Reenable CCP "Interrupt"
	goto	main_loop		; Wait 4 next detection

END
