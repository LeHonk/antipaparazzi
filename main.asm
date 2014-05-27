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

processor	12F683

global	start,reset_vec
fnroot	start

#include <xc.inc>

TMR1_LOAD	EQU	(0xFFFF-360+1)	; Start counting on 360 less then max, 
					; ie overflow and generate timer 
					; interrupt after 360 counts

UART_DELAY	EQU	((8000000/4/9600-10)/3)	; Baud delay @ 8MHz

psect	common, class=COMMON, space=1
int_w:
	ds	2			; Context save of w during interrupt
int_status:
	ds	2			; Context save of status during interrupt
putch_c:
	ds	1			; Char to transmit
putch_cnt:
	ds	1			; Bit loop counter
delay_cnt:
	ds	1			; Delay counter0

psect	config, class=CONFIG, delta=2
		dw	0x03F4		; config CPD=OFF, CP=OFF, FCMEN=ON, IESO=ON, 
					;	BOREN=ON, MCLRE=ON, PWRTE=ON, 
					;	FOSC=INTOSCIO
psect   idloc,class=IDLOC,delta=2
psect   code,class=CODE,delta=2
psect   powerup,class=CODE,delta=2
psect   maintext,class=CODE,delta=2
psect   eeprom_data,class=EEDATA,delta=2,space=2
psect   init,class=CODE,delta=2
psect   cinit,class=CODE,delta=2
psect   text,class=CODE,delta=2
psect   end_init,class=CODE,delta=2
psect   clrtext,class=CODE,delta=2
FSR     set     4
psect   strings,class=CODE,delta=2,reloc=256

psect   reset_vec,class=CODE,delta=2
reset_vec:
	goto	start

psect   intentry,class=CODE,delta=2
	org	0003h
intentry:
	goto	int_handler

psect   functab,class=CODE,delta=2

psect   text,class=CODE,delta=2

;===  FUNCTION  ======================================================================
; Name:  int_handler
; Description:  Handle various interrupts
;=====================================================================================
global	int_handler
int_handler:
	BANKSEL	GPIO
	bsf	GP4			; Erliest possible rise of puls out
	movwf	int_w			; Save context
	swapf	STATUS, w
	movwf	int_status
	bcf	CCP1IF			; Reenable Timer1 interrupt
	swapf	int_status, w		; Restore context
	movwf	STATUS
	swapf	int_w, f
	swapf	int_w, w
	bcf	GP4			; fall of puls out, not time critical
	retfie

;===  FUNCTION  ======================================================================
; Name:  putch
; Description:  Bitbanged uart transmit
; Note:         Destroys carry and W
;=====================================================================================
global	putch
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
	goto	$+1			;				4
	goto	$+1			;				6
	goto	$+1			;				8
	return				;				10

start:
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
	movlw	0b00000010
	movwf	T1CON			; Synchronous external clock source
	clrf	TMR1H			; Preload Timer1 counter
	clrf	TMR1L
	clrf	CCP1CON			; Turn off CCP to clear prescalers
	movlw	0x0b
	movwf	CCP1CON			; Compare mode, clear timer1
	movlw	low(255)		; Set up compare to generate 360 counts per revolution
	movwf	CCPR1L
	movlw	high(255)
	movwf	CCPR1H
	clrf	PIR1			; Clear all interrupt flags
	bsf	CCP1IE			; CCP interrupt enable
	bsf	PEIE			; Peripheral interrupt enable
	bsf	GIE			; Global interrupt enable
	bsf	TMR1ON			; Start Timer1

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
	btfss	GP2			; poll detection sensor
	goto	main_loop
detect:
	movf	TMR1L, w
	call	putch
	movf	TMR1H, w
	call	putch
wait_clear:
	btfsc	GP2			; Wait for detection unassertion
	goto	wait_clear
	goto	main_loop		; Wait 4 next detection
	
	END	start
