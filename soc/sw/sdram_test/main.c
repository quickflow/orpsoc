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

#define PASS_CODE 0xc001
#define FAIL_CODE 0xdead

#define DEBUG 1

#define barrier() __asm__ __volatile__("": : :"memory")

#ifdef DEBUG
void or1k_putc(int c)
{
  while ( REG8(UART_BASE_ADD+0x10) & 0x4 ) // wait if fifo_full
		;

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
/*                           G P I O   W  R I T E                             */
/******************************************************************************/

// Write to the GPIO (32 bits)

void GPIO_Write(uint32 GPIO_data)
{   
   REG32(GPIO_BASE + RGPIO_OUT) = GPIO_data;
}


/******************************************************************************/
/*                           F O R   s p i M A S T E R                        */
/******************************************************************************/

//Initialize
int spiMaster_init()
{
  uint8 data;
  int   i;
  
  REG32(SD_BASE_ADD + (SPI_DEVIDE << 2)) = 0x1;
  REG32(SD_BASE_ADD + (SPI_SS << 2)) = 0xffffffff;

  REG32(SD_BASE_ADD + (SPI_TX_0 << 2)) = 0x03000000; /* 0x3 for Read Array; rest is address */

  uint32 ctrl_csr_val = 
    (1 << SPI_CTRL_GO) |
    (1 << SPI_CTRL_RX_NEGEDGE) |
    (1 << SPI_CTRL_TX_NEGEDGE) |
    (0 << SPI_CTRL_LSB) |
    (0 << SPI_CTRL_IE) |
    (0 << SPI_CTRL_ASS);

  REG32(SD_BASE_ADD + (SPI_CTRL << 2)) = ctrl_csr_val | 32; /* 32 bit transfer of command = 0x03 (READ ARRAY) */

  uint32 tip_count = 0;
  while(REG32(SD_BASE_ADD + (SPI_CTRL << 2)) & (1 << SPI_CTRL_GO)) { // wait while SPI in progress
    GPIO_Write(0x9000 + tip_count);
    tip_count++;
    if (tip_count > 32)
      break;
  };
  
  REG32(SD_BASE_ADD + (SPI_CTRL << 2)) = ctrl_csr_val | 128; /* 128 bits transfer (READ ARRAY) */

  tip_count = 0;
  while(REG32(SD_BASE_ADD + (SPI_CTRL << 2)) & (1 << SPI_CTRL_GO)) { // wait while SPI in progress
    GPIO_Write(0x9000 + tip_count);
    tip_count++;
    if (tip_count > 32)
      break;
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

  return 0;
}

unsigned char data[512];

int copy_sd2ddr()
{

  int i, j;
  uint8 data;
  
  uint32 blockCnt;
  uint32 numBlocks = 12; // How mang blocks will be copied
  
  uint32 ddr_offset = 0x100;
  uint32 sd_read_addr = 0x00;
  
  print("\n\r");
  print("Copying SD image to DDR SDRAM...\n\r");
  print("Blocks:");
  print32bit((long unsigned int)numBlocks);
  
  GPIO_Write(0x77);
  
  for (blockCnt = 0; blockCnt < numBlocks; blockCnt++) {
    /* for my spimaster */
    REG32(SD_BASE_ADD + (SPI_TX_0 << 2)) = 0x03000000 | (sd_read_addr & 0x00ffffff); /* 0x3 for Read Array; rest is address */
    
    uint32 ctrl_csr_val = 
      (1 << SPI_CTRL_GO) |
      (1 << SPI_CTRL_RX_NEGEDGE) |
      (1 << SPI_CTRL_TX_NEGEDGE) |
      (0 << SPI_CTRL_LSB) |
      (0 << SPI_CTRL_IE) |
      (0 << SPI_CTRL_ASS);
    
    REG32(SD_BASE_ADD + (SPI_CTRL << 2)) = ctrl_csr_val | 32; /* 32 bit transfer of command = 0x03 (READ ARRAY) */
    
    uint32 tip_count = 0;
    while(REG32(SD_BASE_ADD + (SPI_CTRL << 2)) & (1 << SPI_CTRL_GO)) { // wait while SPI in progress
      GPIO_Write(0x9000 + tip_count);
      tip_count++;
      if (tip_count > 32)
	break;
    };
    
    GPIO_Write(0x78);
    
    for (i = 0; i < 512; i+=16) {
      REG32(SD_BASE_ADD + (SPI_CTRL << 2)) = ctrl_csr_val | 128; /* 128 bits transfer (READ ARRAY) */

      tip_count = 0;
      while(REG32(SD_BASE_ADD + (SPI_CTRL << 2)) & (1 << SPI_CTRL_GO)) { // wait while SPI in progress
	//	GPIO_Write(0x9000 + tip_count);
	tip_count++;
	if (tip_count > 32)
	  break;
      };
  
      // try reads
      REG32(DRAM_BASE + ddr_offset) = REG32(SD_BASE_ADD + (SPI_RX_3 << 2));
      REG32(DRAM_BASE + ddr_offset + 4) = REG32(SD_BASE_ADD + (SPI_RX_2 << 2));
      REG32(DRAM_BASE + ddr_offset + 8) = REG32(SD_BASE_ADD + (SPI_RX_1 << 2));
      REG32(DRAM_BASE + ddr_offset + 12) = REG32(SD_BASE_ADD + (SPI_RX_0 << 2));
      ddr_offset += 16;
      sd_read_addr += 16;
      //				print32bit((long unsigned int)data);
    }
    if ((blockCnt % 0x40) == 0) {
      or1k_putc('.');
      j++;
    }
    if (j == 20) {
      j = 0;
      print("\n\r");
    }
    
  }
  
  print("\r\nSD Copy Done!\n\r");
}


/******************************************************************************/
/*                        TEST EXTERNAL DDR SDRAM                             */
/******************************************************************************/

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

  if (REG32(SRAM_BASE + 0x8000) == 0x11111111)
    GPIO_Write(0x11);
  else
    GPIO_Write(FAIL_CODE);
  if (REG32(SRAM_BASE + 0x8004) == 0x22222222)
    GPIO_Write(0x12);
  else
    GPIO_Write(FAIL_CODE);
  if (REG32(SRAM_BASE + 0x8008) == 0x33333333)
    GPIO_Write(0x13);
  else
    GPIO_Write(FAIL_CODE);
  if (REG32(SRAM_BASE + 0x800c) == 0x44444444)
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
  REG32(GPIO_BASE + RGPIO_OE)   = 0xffff;  // bit0-7 = outputs, bit8-31 = inputs
  REG32(GPIO_BASE + RGPIO_INTE) = 0x0;   // Disable interrupts from GPIO

  print("\n\r\n\t");
  print("==OpenRisc 1200 SOC==\n\r\n");
  GPIO_Write(0x1111);

  print("\n\r");

  GPIO_Write(0x2222);
  print("SD Card Bootloader, v0.2\n\r");
  print("Xianfeng Zeng, 2009 SA\n\r");
  print("Xianfeng@opencores.org\n\r");
  print("http://www.opencores.org/project,or1k_soc_on_altera_embedded_dev_kit\n\r");

  GPIO_Write(0x3333);
  print("\n\r");

  print("System Clock: 30MHz\n\r\n");

  print("DDR SDRAM Base Address: 0x00000000 - 32MB\n\r");
  print("Ethernet Base Address:  0x20000000  IRQ 4\n\r");
  print("UART Base Address:      0x30000000  IRQ 2\n\r");
  print("GPIO Base Address:      0x40000000  IRQ 3\n\r");
  print("SD Card Base Address:   0x50000000\n\r");
  print("SRAM Base Address:      0xF0000000 - 16KB\n\r");
  print("\r\n\n");

  GPIO_Write(0x4444);

#if 0
  print("Init SD Card:");
  REG8(SD_BASE_ADD + SD_TRANS_CTRL_REG) = 0x1;  /* reset spiMaster */
  do_sleep();
  REG8(SD_BASE_ADD + SD_TRANS_CTRL_REG) = 0x0;

  if (spiMaster_init() == 0) {
	print("Passed!\n\r");
	GPIO_Write(0x51);
  } else {
	print("Failed!\n\r");
	GPIO_Write(0x55);
  }
#endif
  
  GPIO_Write(0x5);

  ddr_sdram_sample_test();

  GPIO_Write(0x6);

  ddr_sdram_sample_test();

  GPIO_Write(0x61);

  GPIO_Write(0x7);

  //  print("Jump to DDR SDRAM: 0x100\n\r");

  GPIO_Write(0x8);

  GPIO_Write(PASS_CODE);

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

