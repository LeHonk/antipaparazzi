	TITLE		"Antipaparazzi"
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

	PROCESSOR	12F683

	INCLUDE		"p12f683.inc"

TMR1_LOAD	EQU	(0xFFFF-360+1)	; Start counting on 360 less then max, 
					; ie overflow and generate timer 
					; interrupt after 360 counts

UART_DELAY	EQU	66		; Baud delay @ 8MHz ((8000000/4/9600-10)/3)

	UDATA_SHR
int_w		RES	1 		; Context save of w during interrupt
int_status	RES	1		; Context save of status during interrupt
putch_c		RES	1		; Char to transmit
putch_cnt	RES	1		; Bit loop counter
delay_cnt	RES	1		; Delay counter0

	__CONFIG _CPD_OFF & _CP_OFF & _FCMEN_ON & _IESO_ON & _BOD_ON & _MCLRE_ON & _PWRTE_ON & _INTOSCIO

reset_vec	CODE	0x00
	goto	start

int_vec		CODE	0x04
	goto	int_handler

		CODE
;===  FUNCTION  ======================================================================
; Name:  int_handler
; Description:  Handle various interrupts
;=====================================================================================
int_handler:
	BANKSEL	GPIO
	bsf	GPIO, GP4		; Erliest possible rise of puls out
	movwf	int_w			; Save context
	swapf	STATUS, w
	movwf	int_status
	bcf	PIR1, CCP1IF		; Reenable Timer1 interrupt
	swapf	int_status, w		; Restore context
	movwf	STATUS
	swapf	int_w, f
	swapf	int_w, w
	bcf	GPIO, GP4		; fall of puls out, not time critical
	retfie

;===  FUNCTION  ======================================================================
; Name:  putch
; Description:  Bitbanged uart transmit
; Note:         Destroys carry and W
;=====================================================================================
	GLOBAL	putch
putch:
	banksel	0
	movwf	putch_c
	movlw	9			; 1 start bit + 8 bit + 1 stop bit
	movwf	putch_cnt
	bsf	STATUS, C		; Stop bit high at nineth iteration
	bcf	GPIO, GP0		; Start bit
	
putch_loop:				;				Acc'd cycles
	movlw	UART_DELAY		; Uart bit delay		1
	movwf	delay_cnt		;				2
bit_delay:
	decfsz	delay_cnt, f		;				(1)
	goto	bit_delay		; loop to previous instruction	(3)

	rrf	putch_c, f		; Rotate bit into carry		3
	btfsc	STATUS, C		;				4
	bsf	GPIO, GP0		; Carry set -> output high	5
	btfss	STATUS, C		;				6
	bcf	GPIO, GP0		; Carry clear -> output low	7
	decfsz	putch_cnt, f		;				8
	goto	putch_loop		; loop over all 8 (+1) bits	10

	movlw	UART_DELAY		; Uart bit delay		1
	movwf	delay_cnt		;				2
stopbit_delay:
	decfsz	delay_cnt, f		;				(1)
	goto	stopbit_delay		; loop to previous instruction	(3)
	goto	$+1			;				4
	goto	$+1			;				6
	goto	$+1			;				8
	return				;				10

start:
	BANKSEL	OSCCON
	movlw	71h
	movwf	OSCCON			; Internal 8Mhz system clock
	BANKSEL	GPIO
	movlw	B'00000001'		; GP0 High
	movwf	GPIO			; Clear all pins,  except GP0
	movlw	B'00000111'
	movwf	CMCON0			; No comparator used
	BANKSEL	ANSEL
	clrf	ANSEL			; All pins digital IO
	movlw	B'00101110'
	movwf	TRISIO			; GP5 in, GP4 out, GP3 nc, GP2 in, GP1 nc, GP0 out
	BANKSEL	T1CON
	movlw	B'00000010'
	movwf	T1CON			; Synchronous external clock source
	clrf	TMR1H			; Preload Timer1 counter
	clrf	TMR1L
	clrf	CCP1CON			; Turn off CCP to clear prescalers
	movlw	0x0B
	movwf	CCP1CON			; Compare mode, clear timer1
	movlw	low(255)		; Set up compare to generate 360 counts per revolution
	movwf	CCPR1L
	movlw	high(255)
	movwf	CCPR1H
	clrf	PIR1			; Clear all interrupt flags
	bsf	PIE1, CCP1IE		; CCP interrupt enable
	bsf	INTCON, PEIE		; Peripheral interrupt enable
	bsf	INTCON, GIE		; Global interrupt enable
	bsf	T1CON, TMR1ON		; Start Timer1

main_loop:
;	btfss	CCP1IF
;	goto	check_detection
;	bsf	GP4
;	movlw	1
;	movwf	delay_cnt
;	decfsz	delay_cnt, f
;	goto	$-1
;	bcf	CCP1IF
;	bcf	GP4
check_detection:
	btfss	GPIO, GP2		; poll detection sensor
	goto	main_loop
detect:
	movf	TMR1L, w
	call	putch
	movf	TMR1H, w
	call	putch
wait_clear:
	btfsc	GPIO, GP2		; Wait for detection unassertion
	goto	wait_clear
	goto	main_loop		; Wait 4 next detection
	
	END
