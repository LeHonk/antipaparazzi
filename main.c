/*
 * =====================================================================================
 *
 *       Filename:  main.c
 *
 *    Description:  Antipaparazzi Device Main file
 *
 *        Version:  1.0
 *        Created:  14-01-02 12:57
 *       Revision:  none
 *       Compiler:  xc8
 *
 *         Author:  Tomas Holmqvist (TH), tomhol@gmail.com
 *   Organization:  
 *
 * =====================================================================================
 */
#include <xc.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#pragma config CPD=OFF, CP=OFF, FCMEN=ON, IESO=ON, BOREN=ON, MCLRE=ON, PWRTE=ON, FOSC=INTOSCIO

#define	TMR1_LOAD (UINT16_MAX-360 + 1)		/* Start counting on 360 less then max, 
						   ie overflow and generate timer 
						   interrupt after 360 counts */

#define TXpin   GP0                             /* Sowrtware UART transmit pin */
#define UART_delay()    _delay(208)             /* Baud delay @ 8MHz */
/* 
 * ===  FUNCTION  ======================================================================
 *         Name:  int_handler
 *  Description:  Hadndle various interrupts
 * =====================================================================================
 */
void interrupt int_handler( void ) {
    if (TMR1IF) {
	TMR1 = TMR1_LOAD;
	GP4 = 1;                                /* Generate a pulse on GP4 */
	GP4 = 0;
	TMR1IF = 0;                             /* Reenable Timer1 interrupt */
    }
}		/* -----  end of static function t1  ----- */


/* 
 * ===  FUNCTION  ======================================================================
 *         Name:  putch
 *  Description:  Bitbanged uart transmit
 * =====================================================================================
 */
void putch( char c ) {
    uint8_t cnt = 8;
    TXpin = 0;                                  /* Start bit */
    UART_delay();
    while (cnt--) {
	TXpin = (c & 0x01);
	UART_delay();
	c>>=1;
    }
    TXpin = 1;                                  /* Stop bit */
    UART_delay();
}		/* -----  end of function putch  ----- */

void main(void) {
    OSCCON = 0xF0;				/* Internal 8Mhz system clock */
    T1CON = 0x6;                                /* Asynchronous external clock source */
    TMR1 = TMR1_LOAD;                           /* Preload Timer1 counter */
    CCP1CON = 0x05;				/* Capture mode, every rising edge */
    GPIO = 0x00;                                /* Clear all pins */
    TRISIO = ~0x10;                             /* GP4 Output */
    ANSEL = 0x00;                               /* All pins digital IO */
    CMCON0 = 0x07;				/* All pins digital IO */
    TMR1IF = 0;                                 /* Clear Timer1 interrupt flag */
    CCP1IF = 0;                                 /* Clear CCP Interrupt flag */
    TMR1IE = 1;                                 /* Timer1 interrupt enable */
    PEIE = 1;                                   /* Peripheral interrupt enable */
    GIE = 1;                                    /* Global interrupt enable */
    TMR1ON = 1;                                 /* Start Timer1 */
    while(1) {                                  /* Loop 4-evva */
    	if (CCP1IF) {                           /* Poll CCP interrupt flag */
            printf("%d\n", CCPR1 - TMR1_LOAD);  /* Print detected angle on stdout */
	    CCP1IF = 0;                         /* Reenable CCP "Interrupt" */
	}
    }
}

