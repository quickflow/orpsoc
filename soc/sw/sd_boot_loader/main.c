 /*
 * SD/MMC card bootloader for OR1k SoC
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
 *      2009-10-05 12:56:55   xzeng
 *          Init.
 *
 */


#define INCLUDED_FROM_C_FILE

#include "orsocdef.h"
#include "board.h"

#define PASS_CODE 0xc001c0de
#define FAIL_CODE 0xdeadbeef

extern void  jumpToRAM();

/******************************************************************************/
/*                           G P I O   W  R I T E                             */
/******************************************************************************/

// Write to the GPIO (32 bits)

void GPIO_Write(uint32 GPIO_data)
{   
   REG32(GPIO_BASE + RGPIO_OUT) = GPIO_data;
}

#define DEBUG 1

#define barrier() __asm__ __volatile__("": : :"memory")

#ifdef DEBUG
void or1k_putc(int c)
{
  while ( (REG32(UART_BASE_ADD+0x10) & 0x4) == 0x4 ) // wait if fifo_full
    {
      //      GPIO_Write(0x1000f111);
    }
  //  GPIO_Write(0x1000ee33);

  REG8(UART_BASE_ADD + 0x08) = c;
}

void print(unsigned char *c)
{
  uint32 i;
  
  if (c == NULL)
    return;
  
  for (i = 0; c[i] != 0; i++) {
    or1k_putc(c[i]);
  }
}

void print32bit (long unsigned int val)
{
  int i;
  unsigned long int myNibble;
  char myChar;

  for (i=0;i<8;i++) {
    myNibble =  (val >> 28) & 0xfUL;
    if (myNibble <= 0x9)
      myChar = (char) myNibble + 0x30;
    else
      myChar = (char) myNibble + 0x37;
    or1k_putc (myChar);
    val = val << 4;
  }
  or1k_putc ('\n');
  or1k_putc ('\r');
}


#else
#define or1k_putc(a)
#define print(a)
#endif


void do_sleep()
{
	uint32 i;
	for (i = 0; i < 200000; i++)
		;
}

void do_sleep2()
{
	uint32 i;
	for (i = 0; i < 1000; i++)
		;
}


/******************************************************************************/
/*                           F O R   s p i M A S T E R                        */
/******************************************************************************/

void spiRead4words(uint32 *dat0, uint32 *dat1, uint32 *dat2, uint32 *dat3)
{
  uint32 ctrl_csr_val = 
    (1 << SPI_CTRL_GO) |
    (0 << SPI_CTRL_RX_NEGEDGE) |
    (0 << SPI_CTRL_TX_NEGEDGE) |
    (0 << SPI_CTRL_LSB) |
    (0 << SPI_CTRL_IE) |
    (0 << SPI_CTRL_ASS);

  uint32 tip_count = 0;
  
  REG32(SD_BASE_ADD + (SPI_CTRL << 2)) = ctrl_csr_val | 128; /* 128 bits transfer (READ ARRAY) */

  while(REG32(SD_BASE_ADD + (SPI_CTRL << 2)) & (1 << SPI_CTRL_GO)) { // wait while SPI in progress
    //    GPIO_Write(0x9000 + tip_count);
    tip_count++;
  };
  
  // try reads
  *dat0 = REG32(SD_BASE_ADD + (SPI_RX_3 << 2));
  *dat1 = REG32(SD_BASE_ADD + (SPI_RX_2 << 2));
  *dat2 = REG32(SD_BASE_ADD + (SPI_RX_1 << 2));
  *dat3 = REG32(SD_BASE_ADD + (SPI_RX_0 << 2));

}
  
//Initialize
void spiMaster_init()
{
  uint8 data;
  int   i;
  
  REG32(SD_BASE_ADD + (SPI_DEVIDE << 2)) = 0x2;
  REG32(SD_BASE_ADD + (SPI_SS << 2)) = 0x00000000;
  REG32(SD_BASE_ADD + (SPI_SS << 2)) = 0xffffffff;

  REG32(SD_BASE_ADD + (SPI_TX_0 << 2)) = 0x03000000; /* 0x3 for Read Array; rest is address */

  uint32 ctrl_csr_val = 
    (1 << SPI_CTRL_GO) |
    (0 << SPI_CTRL_RX_NEGEDGE) |
    (0 << SPI_CTRL_TX_NEGEDGE) |
    (0 << SPI_CTRL_LSB) |
    (0 << SPI_CTRL_IE) |
    (0 << SPI_CTRL_ASS);

  REG32(SD_BASE_ADD + (SPI_CTRL << 2)) = ctrl_csr_val | 32; /* 32 bit transfer of command = 0x03 (READ ARRAY) */

  uint32 tip_count = 0;
  while(REG32(SD_BASE_ADD + (SPI_CTRL << 2)) & (1 << SPI_CTRL_GO)) { // wait while SPI in progress
    GPIO_Write(0x9000 + tip_count);
    tip_count++;
  };
}

int spiMaster_test()
{
  uint32 tip_count = 0;

  uint32 ctrl_csr_val =
    (1 << SPI_CTRL_GO) |
    (0 << SPI_CTRL_RX_NEGEDGE) |
    (0 << SPI_CTRL_TX_NEGEDGE) |
    (0 << SPI_CTRL_LSB) |
    (0 << SPI_CTRL_IE) |
    (0 << SPI_CTRL_ASS);
  
  REG32(SD_BASE_ADD + (SPI_CTRL << 2)) = ctrl_csr_val | 128; /* 128 bits transfer (READ ARRAY) */

  tip_count = 0;
  while(REG32(SD_BASE_ADD + (SPI_CTRL << 2)) & (1 << SPI_CTRL_GO)) { // wait while SPI in progress
    GPIO_Write(0x9000 + tip_count);
    tip_count++;
  };
  
  // try reads
  REG32(SRAM_BASE + 0x8000) = REG32(SD_BASE_ADD + (SPI_RX_3 << 2));
  REG32(SRAM_BASE + 0x8004) = REG32(SD_BASE_ADD + (SPI_RX_2 << 2));
  REG32(SRAM_BASE + 0x8008) = REG32(SD_BASE_ADD + (SPI_RX_1 << 2));
  REG32(SRAM_BASE + 0x800c) = REG32(SD_BASE_ADD + (SPI_RX_0 << 2));
  
  if (REG32(SRAM_BASE + 0x8000) != 0xa8600001)
    GPIO_Write(FAIL_CODE);
  if (REG32(SRAM_BASE + 0x8004) != 0xc0001811)
    GPIO_Write(FAIL_CODE);
  if (REG32(SRAM_BASE + 0x8008) != 0x0400020a)
    GPIO_Write(FAIL_CODE);
  if (REG32(SRAM_BASE + 0x800c) != 0x15000000)
    GPIO_Write(FAIL_CODE);

  GPIO_Write(0x9191);
  
  uint32 dat0, dat1, dat2, dat3;
  spiRead4words(&dat0, &dat1, &dat2, &dat3);
  GPIO_Write(dat0);
  GPIO_Write(dat1);
  GPIO_Write(dat2);
  GPIO_Write(dat3);

#if 1
  if (dat0 != 0x18000000)
    GPIO_Write(FAIL_CODE);
  if (dat1 != 0xa8000000)
    GPIO_Write(FAIL_CODE);
  if (dat2 != 0x1820e000)
    GPIO_Write(FAIL_CODE);
  if (dat3 != 0xa8213560)
    GPIO_Write(FAIL_CODE);
#endif

#if 1
  uint32 *Faddr= (uint32 *)0xf0000110;
  uint32 count;
  for(count=0; count<1500; count++) {
    GPIO_Write(count);
    if (dat0 != *Faddr)
      GPIO_Write(FAIL_CODE);
    Faddr++;
    if (dat1 != *Faddr)
      GPIO_Write(FAIL_CODE);
    Faddr++;
    if (dat2 != *Faddr)
      GPIO_Write(FAIL_CODE);
    Faddr++;
    if (dat3 != *Faddr)
      GPIO_Write(FAIL_CODE);
    Faddr++;
    spiRead4words(&dat0, &dat1, &dat2, &dat3);
  }
#endif
  return 0;
}

unsigned char data[512];

int copy_sd2ddr(void)
{

  int i, j;
  uint8 data;
  unsigned char transError;
  
  uint32 blockCnt;
  uint32 numBlocks = 2 * 1024 * 10; // How mang blocks will be copied
  
  uint32 ddr_offset = 0;
  
  print("\n\r");
  print("Copying SD image to DDR SDRAM...\n\r");
  print("Blocks:");
  print32bit((long unsigned int)numBlocks);
  
  GPIO_Write(0x77);

  uint32 dat0, dat1, dat2, dat3;
  uint32 count;

  //  for(count=0; count<1500; count++) {
  for(count=0x100; count<0x4d00; count+=16) {
    if ((count & 0xfff) == 0)
      GPIO_Write(count);

    spiRead4words(&dat0, &dat1, &dat2, &dat3);

    REG32(DRAM_BASE + count) = dat0;
    REG32(DRAM_BASE + count+4) = dat1;
    REG32(DRAM_BASE + count+8) = dat2;
    REG32(DRAM_BASE + count+12) = dat3;

#if 1
    if (count < (0x1200)) {
      if (dat0 != REG32(DRAM_BASE + count))
	GPIO_Write(FAIL_CODE);
      
      if (dat1 != REG32(DRAM_BASE + count+4))
	GPIO_Write(FAIL_CODE);
      
      if (dat2 != REG32(DRAM_BASE + count+8))
	GPIO_Write(FAIL_CODE);
      
      if (dat3 != REG32(DRAM_BASE + count+12))
	GPIO_Write(FAIL_CODE);
    }
#endif
  }
  
  GPIO_Write(0x788);

  for(count=0x35600; count<0x35700; count+=4) {
    REG32(DRAM_BASE + count) = count;
  }

  GPIO_Write(0x789);

  print("\r\nSD Copy Done!\n\r");
}


/******************************************************************************/
/*                        TEST EXTERNAL DDR SDRAM                             */
/******************************************************************************/

void ddr_sdram_init()
{
  REG32(MC_CSR_INIT) = 0x1; // mc_ reg rf0  mc_cs_0 // csr_r2[31:24], csr_r[10:1] (init)

  // delay a while
  REG32(SRAM_BASE) = 0; // zero out SRAM [0]
  while( REG32(SRAM_BASE) < 64) {
    REG32(SRAM_BASE) = REG32(SRAM_BASE) + 1; // increment it
  }

  // try lmr ?
  // load mode reg req mc_cs_0 [CAS latency=2, Sequential Burst Type, Programmed Burst Length]
  REG32(MC_CSR_BASE + 0x14) = 0x30; 
}

void ddr_sdram_sample_test()
{

  // try writes
  REG32(DRAM_BASE + 0x5000) = 0x11111111;
  REG32(DRAM_BASE + 0x5004) = 0x22222222;
  REG32(DRAM_BASE + 0x5008) = 0x33333333;
  REG32(DRAM_BASE + 0x500c) = 0x44444444;

  // try reads
  REG32(SRAM_BASE + 0x8000) = REG32(DRAM_BASE + 0x5000);
  REG32(SRAM_BASE + 0x8004) = REG32(DRAM_BASE + 0x5004);
  REG32(SRAM_BASE + 0x8008) = REG32(DRAM_BASE + 0x5008);
  REG32(SRAM_BASE + 0x800c) = REG32(DRAM_BASE + 0x500c);

  if ( REG32(SRAM_BASE + 0x8000) == 0x11111111)
    GPIO_Write(0x11);
  else
    GPIO_Write(FAIL_CODE);
  if ( REG32(SRAM_BASE + 0x8004) == 0x22222222)
    GPIO_Write(0x12);
  else
    GPIO_Write(FAIL_CODE);
  if ( REG32(SRAM_BASE + 0x8008) == 0x33333333)
    GPIO_Write(0x13);
  else
    GPIO_Write(FAIL_CODE);
  if ( REG32(SRAM_BASE + 0x800c) == 0x44444444)
    GPIO_Write(0x14);
  else
    GPIO_Write(FAIL_CODE);

  print ("DDR SDRAM sample test done.\n\r");
}

/*$$EXTERNAL EXEPTIONS*/
/******************************************************************************/
/*                  E X T E R N A L   E X E P T I O N S                       */
/******************************************************************************/

void external_exeption()
{      
  REG uint8 i;
  REG uint32 PicSr,sr;
}


/*$$MAIN*/
/******************************************************************************/
/*                                                                            */
/*                       M A I N   P R O G R A M                              */
/*                                                                            */
/******************************************************************************/

void main()
{
  uint32 i;
  uint8  str[9];

  // Configure GPIO
  REG32(GPIO_BASE + RGPIO_OE)   = 0xffffffff;  // bit0-7 = outputs, bit8-31 = inputs
  REG32(GPIO_BASE + RGPIO_INTE) = 0x0;   // Disable interrupts from GPIO

  print("\n\r\n\t");
  print("==OpenRisc 1200 SOC(");
  if (CPUID == 0)
    print("0");
  if (CPUID == 1)
    print("1");
  print(")==\n\r\n");
  print("Hi Andy\r\n");

  GPIO_Write(0x1);

  GPIO_Write(0x2);

  GPIO_Write(0x3);

  print("Init SPI:");

  spiMaster_init();
  GPIO_Write(0x51);

  GPIO_Write(0x5);

  print("Init DRAM:");
  ddr_sdram_init();
  
  GPIO_Write(0x54);

  //  ddr_sdram_sample_test();

  GPIO_Write(0x6);

  //  ddr_sdram_sample_test();

  GPIO_Write(0x61);

  print("Copy code from Flash to DRAM:");
  copy_sd2ddr();

  print("\n\r");

  print("Jump to DRAM: 0x100\n\r");
  GPIO_Write(0x8);

  jumpToRAM();

  GPIO_Write(PASS_CODE);

  print("Should not get here!!:\n\r");
  while(TRUE) {
	do_sleep();
	or1k_putc('.');
	GPIO_Write(~0x0);  // Test finished
	do_sleep();
    	GPIO_Write(~0x1);
	do_sleep();
	GPIO_Write(~0x2);
	do_sleep();
	GPIO_Write(~0x4);
	do_sleep();
	GPIO_Write(~0x8);

	if (i == 39) {
		print("\n\r");
		i = 0;
	} else 
		i++;
  }
}

