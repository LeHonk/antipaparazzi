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

#pragma config CPD=OFF, CP=OFF, FCMEN=ON, IESO=ON, BOREN=ON, MCLRE=ON, PWRTE=ON, FOSC=INTOSCIO

#define	TMR1_LOAD (0xFFFF-360 + 1)			/*  */

unsigned short detection = 0xFFFF;

/* 
 * ===  FUNCTION  ======================================================================
 *         Name:  t1
 *  Description:  
 * =====================================================================================
 */
    static void interrupt
t1 ( void )
{
    if (TMR1IF) {
	TMR1IF = 0;
	TMR1 = TMR1_LOAD;
	GP4 = 1;
	NOP();
	GP4 = 0;
    }
}		/* -----  end of static function t1  ----- */

void main(void) {
    OSCCON = 0xF0;				/* Internal 8Mhz system clock */
    T1CON = 0x6;                                /* Asynchronous external clock source */
    TMR1 = TMR1_LOAD;
    GPIO = 0x00;
    TRISIO = ~0x10;                             /* GP4 Output */
    ANSEL = 0x00;
    CMCON0 = 0x07;				/* All pins digital IO */
    TMR1IF = 0;
    TMR1IE = 1;
    TMR1ON = 1;					/* Start Timer1 */
    while(1);
}
