/*
 *
 * Create by Linux Device Driver VIM Plugin 
 *
 * Copyright (c) 2008 by:
 *      Xianfeng Zeng <xianfeng.zeng@gmail.com, Xianfeng.zeng@SierraAtlantic.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the BSD Licence, GNU General Public License
 * as published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version
 *
 * ChangeLog:
 *      2009-10-02 09:35:09   xzeng
 *          Init.
 *
 */

#include "board.h"
#include "spr_defs.h"

#define KALLE 0x12345678

.macro  load32i reg const
        l.movhi \reg,hi(\const)
        l.ori   \reg,\reg,lo(\const)
.endm

.macro  exception_vector name org
        .org \org
        .p2align 8
        .global  __exception_\name
__exception_\name:
        
        l.j __exception_\name
        l.nop
.endm

.macro  BSR name
        l.j    \name
        l.nop
ret_\name:  
.endm


/** Other MACROS **/

#define LOAD_SYMBOL_2_GPR(gpr,symbol)	\
    l.movhi gpr,hi(symbol)		;\
    l.ori   gpr,gpr,lo(symbol)

/*$$RESET START*/

#ifndef ENTRY
#  define ENTRY(symbol)			\
	  .global symbol		;\
   symbol:	
#endif

/* 
 * emergency_print temporary stores 
 */
#define EMERGENCY_PRINT_STORE_GPR4	l.sw    0x20(r0),r4
#define EMERGENCY_PRINT_LOAD_GPR4	l.lwz   r4,0x20(r0)

#define EMERGENCY_PRINT_STORE_GPR5	l.sw    0x24(r0),r5
#define EMERGENCY_PRINT_LOAD_GPR5	l.lwz   r5,0x24(r0)
	
#define EMERGENCY_PRINT_STORE_GPR6	l.sw    0x28(r0),r6
#define EMERGENCY_PRINT_LOAD_GPR6	l.lwz   r6,0x28(r0)
	
#define EMERGENCY_PRINT_STORE_GPR7	l.sw    0x2c(r0),r7
#define EMERGENCY_PRINT_LOAD_GPR7	l.lwz   r7,0x2c(r0)

#define EMERGENCY_PRINT_STORE_GPR8	l.sw    0x30(r0),r8
#define EMERGENCY_PRINT_LOAD_GPR8	l.lwz   r8,0x30(r0)

#define EMERGENCY_PRINT_STORE_GPR9	l.sw    0x34(r0),r9
#define EMERGENCY_PRINT_LOAD_GPR9	l.lwz   r9,0x34(r0)

/******************************************************************************/
/*                                                                            */
/*                          R E S E T   S T A R T                             */
/*                                                                            */
/******************************************************************************/

.section .vectors, "ax"

.org 0x100 - 0x100 		// Sector .vectors start at 0x100

	l.ori	r3,r0,0x1
	l.mtspr	r0,r3,SPR_SR

_reset:

	l.jal	_early_uart_init
	l.nop

	/*
	 * Set stack pointer (r1) to 0xf0003560
	 * Clear all other registers
	 */
	.equ sp,0xf0003560	;
	l.movhi r0,0x0000	; #r0 = 0
	l.ori r0,r0,0x0000	; 
	l.movhi r1,hi(sp)	; #r1 = sp
	l.ori r1,r1,lo(sp)	;
	l.or r2,r0,r0		; #clear r2
	l.or r3,r0,r0		; #clear r3
	l.or r4,r0,r0		; #clear r4
	l.or r5,r0,r0		; #clear r5
	l.or r6,r0,r0		; #clear r6
	l.or r7,r0,r0		; #clear r7
	l.or r8,r0,r0		; #clear r8
	l.or r9,r0,r0		; #clear r9
	l.or r10,r0,r0		; #clear r10
	l.or r11,r0,r0		; #clear r11
	l.or r12,r0,r0		; #clear r12
	l.or r13,r0,r0		; #clear r13
	l.or r14,r0,r0		; #clear r14
	l.or r15,r0,r0		; #clear r15
	l.or r16,r0,r0		; #clear r16
	l.or r17,r0,r0		; #clear r17
	l.or r18,r0,r0		; #clear r18
	l.or r19,r0,r0		; #clear r19
	l.or r20,r0,r0		; #clear r20
	l.or r21,r0,r0		; #clear r21
	l.or r22,r0,r0		; #clear r22
	l.or r23,r0,r0		; #clear r23
	l.or r24,r0,r0		; #clear r24
	l.or r25,r0,r0		; #clear r25
	l.or r26,r0,r0		; #clear r26
	l.or r27,r0,r0		; #clear r27
	l.or r28,r0,r0		; #clear r28
	l.or r29,r0,r0		; #clear r29
	l.or r30,r0,r0		; #clear r30
	l.or r31,r0,r0		; #clear r31		


#if IC_ENABLE == 1      /* INSTRUCTION CACHE */
        BSR ic_enable
#endif

	
// Jump to start of program

        load32i r2, (_Start)
        l.jr    r2
        l.nop

        exception_vector        bus_error               0x200 - 0x100 // Sector .vectors start at 0x100 
        exception_vector        data_page_fault         0x300 - 0x100 // Sector .vectors start at 0x100
        exception_vector        instruction_page_fault  0x400 - 0x100 // Sector .vectors start at 0x100
        exception_vector        tick_timer              0x500 - 0x100 // Sector .vectors start at 0x100
        exception_vector        unaligned_access        0x600 - 0x100 // Sector .vectors start at 0x100
        exception_vector        illegal_instruction     0x700 - 0x100 // Sector .vectors start at 0x100


// Defines what will happen when an external interrupt occurs

.org 0x800 - 0x100

        .global  __external_IRQ

__external_IRQ:        
        l.addi r1,r1,-30*4			//move SP 30*4 adresses lower

        l.sw 0x1c(r1),r9
        
        l.jal (save_state)
        l.nop
		                
        // we mess with r3, r4 and r9
        //
        l.mfspr r3,r0,SPR_ESR_BASE      // get SR before interrupt
        l.andi  r4,r3,SPR_SR_IEE        // check if it had SPR_SR_IEE bit enabled
        l.sfeqi r4,0
        l.bnf   JUMP                      // external irq enabled, all ok.
        l.nop

JUMP:	  l.jal (_external_exeption)
        l.nop

        l.jal (restore_state)
        l.nop

        l.lwz r9 ,0x1c(r1)
        l.addi r1,r1,30*4			//move SP 30*4 adresses lower
                
        //Return from exception
        l.rfe


// Save current state (all general purpose registers)

save_state:
    l.sw 0x0(r1),r2
    l.sw 0x4(r1),r3
    l.sw 0x8(r1),r4
    l.sw 0xc(r1),r5
    l.sw 0x10(r1),r6
    l.sw 0x14(r1),r7
    l.sw 0x18(r1),r8
    l.sw 0x20(r1),r10
    l.sw 0x24(r1),r11
    l.sw 0x28(r1),r12
    l.sw 0x2c(r1),r13
    l.sw 0x30(r1),r14
    l.sw 0x34(r1),r15
    l.sw 0x38(r1),r16
    l.sw 0x3c(r1),r17
    l.sw 0x40(r1),r18
    l.sw 0x44(r1),r19
    l.sw 0x48(r1),r20
    l.sw 0x4c(r1),r21
    l.sw 0x50(r1),r22
    l.sw 0x54(r1),r23
    l.sw 0x58(r1),r24
    l.sw 0x5c(r1),r25
    l.sw 0x60(r1),r26
    l.sw 0x64(r1),r27
    l.sw 0x68(r1),r28
    l.sw 0x6c(r1),r29
    l.sw 0x70(r1),r30
    l.jr r9
    l.nop

// Restore current state

restore_state:
    // disable interrupts (if needed)
    l.lwz r2,0x0(r1)
    l.lwz r3  ,0x4(r1)
    l.lwz r4  ,0x8(r1)
    l.lwz r5  ,0xc(r1)
    l.lwz r6 ,0x10(r1)
    l.lwz r7 ,0x14(r1)
    l.lwz r8 ,0x18(r1)
    l.lwz r10,0x20(r1)
    l.lwz r11,0x24(r1)
    l.lwz r12,0x28(r1)
    l.lwz r13,0x2c(r1)
    l.lwz r14,0x30(r1)
    l.lwz r15,0x34(r1)
    l.lwz r16,0x38(r1)
    l.lwz r17,0x3c(r1)
    l.lwz r18,0x40(r1)
    l.lwz r19,0x44(r1)
    l.lwz r20,0x48(r1)
    l.lwz r21,0x4c(r1)
    l.lwz r22,0x50(r1)
    l.lwz r23,0x54(r1)
    l.lwz r24,0x58(r1)
    l.lwz r25,0x5c(r1)
    l.lwz r26,0x60(r1)
    l.lwz r27,0x64(r1)
    l.lwz r28,0x68(r1)
    l.lwz r29,0x6c(r1)
    l.lwz r30,0x70(r1)
    l.jr r9
    l.nop



/***************************
 * Instruction cache enable 
 */
#if IC_ENABLE == 1      
ic_enable:

        /* Disable IC */
        l.mfspr r6,r0,SPR_SR
        l.addi  r5,r0,-1
        l.xori  r5,r5,SPR_SR_ICE
        l.and   r5,r6,r5
        l.mtspr r0,r5,SPR_SR

        /* Invalidate IC */
        l.addi  r6,r0,0
        l.addi  r5,r0,IC_SIZE
1:
        l.mtspr r0,r6,SPR_ICBIR
        l.sfne  r6,r5
        l.bf    1b
        l.addi  r6,r6,IC_LINE

        /* Enable IC */
        l.mfspr r6,r0,SPR_SR
        l.ori   r6,r6,SPR_SR_ICE
        l.mtspr r0,r6,SPR_SR
        l.nop
        l.nop
        l.nop
        l.nop
        l.nop
        l.nop
        l.nop
        l.nop
        l.nop
        l.nop
        l.j  ret_ic_enable
        l.nop
#endif


ENTRY(_early_uart_init)
        l.movhi	r3,hi(UART_BASE_ADD)

        l.addi	r4,r0,0x00c0	//0x2 FIFO Control
        l.sb	0x2(r3),r4        

        l.addi	r4,r0,0x0
        l.sb	0x1(r3),r4	//0x1 Interrupt Enable

        l.addi	r4,r0,0x0003
        l.sb	0x3(r3),r4	//0x3 Line Control Register

        l.lbz	r5,3(r3)	//Line Control Register
        l.ori	r4,r5,0x0080
        l.sb	0x3(r3),r4
	l.addi	r4,r0,((UART_DEVISOR>>8) & 0x000000ff)
        l.sb	UART_DLM(r3),r4
        l.addi  r4,r0,((UART_DEVISOR) & 0x000000ff)
        l.sb	UART_DLL(r3),r4
        l.sb	0x3(r3),r5
  
        l.jr	r9
        l.nop

ENTRY(_emergency_print)
	EMERGENCY_PRINT_STORE_GPR4
	EMERGENCY_PRINT_STORE_GPR5
	EMERGENCY_PRINT_STORE_GPR6
	EMERGENCY_PRINT_STORE_GPR7
2:	
	l.lbz	r7,0(r3)
	l.sfeq	r7,r0
	l.bf	9f
	l.nop

// putc:
        l.movhi r4,hi(UART_BASE_ADD)

        l.addi  r6,r0,0x20
1:      l.lbz   r5,5(r4)
        l.andi  r5,r5,0x20
        l.sfeq  r5,r6
        l.bnf   1b
        l.nop
      
        l.sb    0(r4),r7

        l.addi  r6,r0,0x60
1:      l.lbz   r5,5(r4)
        l.andi  r5,r5,0x60
        l.sfeq  r5,r6
        l.bnf   1b
        l.nop

	/* next character */
	l.j	2b
	l.addi	r3,r3,0x1

9:
	EMERGENCY_PRINT_LOAD_GPR7
	EMERGENCY_PRINT_LOAD_GPR6
	EMERGENCY_PRINT_LOAD_GPR5
	EMERGENCY_PRINT_LOAD_GPR4	
	l.jr	r9
	l.nop


/* Jump to 0x0000100 after the Image was copied to this section */

.global _jumpToRAM

        .section .text, "ax"
_jumpToRAM:
        l.movhi r2,hi(0x00000100)
        l.ori   r2,r2,lo(0x00000100)
        l.jr    r2
        l.addi  r2,r0,0

