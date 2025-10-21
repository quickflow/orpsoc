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


#define DEBUG 1

#define barrier() __asm__ __volatile__("": : :"memory")

#ifdef DEBUG
void or1k_putc(int c)
{
	while ( 0x20 != (REG8(UART_BASE_ADD+5) & 0x20) )
		;

	REG8(UART_BASE_ADD) = c;
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

	REG8(SD_BASE_ADD + SD_CLK_DEL_REG) = 0x1;

	for (i = 0; i < 5; i++) {
		REG8(SD_BASE_ADD + SD_TRANS_TYPE_REG) = SD_INIT_SD;
		REG8(SD_BASE_ADD + SD_TRANS_CTRL_REG) = 1; // TRANS_START;

		do_sleep();

		while (REG8(SD_BASE_ADD + SD_TRANS_STS_REG) & 0x1) { // exit while !TRABS_BUSY
			;
		}

		data = REG8(SD_BASE_ADD + SD_TRANS_ERROR_REG) & 0x3;

		if (data == 0) {
			return 0;
		}
	}
	return data;
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

	for (blockCnt = 0; blockCnt < numBlocks; blockCnt++) {
		REG8(SD_BASE_ADD + SD_ADDR_7_0_REG)   = 0;
		REG8(SD_BASE_ADD + SD_ADDR_15_8_REG)  = (unsigned char) ((ddr_offset >> 8) & 0xff);
		REG8(SD_BASE_ADD + SD_ADDR_23_16_REG) = (unsigned char) ((ddr_offset >> 16) & 0xff);
		REG8(SD_BASE_ADD + SD_ADDR_31_24_REG) = (unsigned char) ((ddr_offset >> 24) & 0xff);
	

		REG8(SD_BASE_ADD + SD_TRANS_TYPE_REG) = SD_RW_READ_SD_BLOCK;
		REG8(SD_BASE_ADD + SD_RX_FIFO_CONTROL_REG) = 0x1; // Clean the RX FIFO
		REG8(SD_BASE_ADD + SD_TRANS_CTRL_REG) = 0x1; //TRANS_START
		while (REG8(SD_BASE_ADD + SD_TRANS_STS_REG) & 0x1) { // exit while !TRABS_BUSY
			;
		}

		transError = REG8(SD_BASE_ADD + SD_TRANS_ERROR_REG) & 0xc;
		if ( transError == SD_READ_NO_ERROR) {
			for (i = 0; i < 512; i++) {
				data = REG8(SD_BASE_ADD + SD_RX_FIFO_DATA_REG) ;			
				REG8(DDR_SDRAM_BASE_ADDR + ddr_offset + i) = data ;
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

			ddr_offset += 512;		
		} else {
			or1k_putc('R');
			j++;
                        if (j == 20) {
                                j = 0;
                                print("\n\r");
                        }
			spiMaster_init(); // Init again and retry
			blockCnt--; // read the same block again
		}
	}

	print("\r\nSD Copy Done!\n\r");
}


/******************************************************************************/
/*                        TEST EXTERNAL DDR SDRAM                             */
/******************************************************************************/

void ddr_sdram_sample_test()
{
	uint32 int32;
	uint16 int16;
	uint8  int8;
	int    i;

	REG32(DDR_SDRAM_BASE_ADDR) = 0x12345678;
	int32 = REG32(DDR_SDRAM_BASE_ADDR);

	REG16(DDR_SDRAM_BASE_ADDR + 10) = 0x55aa;
	int16 = REG16(DDR_SDRAM_BASE_ADDR + 10);

	REG8(DDR_SDRAM_BASE_ADDR + 20) = 0x5a;
	int8 = REG8(DDR_SDRAM_BASE_ADDR + 20);

	if (REG8(DDR_SDRAM_BASE_ADDR + 20)  != 0x5a)
		print ("DDR SDRAM accesses short type Error:20!\n\r");

	REG8(DDR_SDRAM_BASE_ADDR + 100) = 0x12;
	REG8(DDR_SDRAM_BASE_ADDR + 101) = 0x34;
	REG8(DDR_SDRAM_BASE_ADDR + 102) = 0x56;
	REG8(DDR_SDRAM_BASE_ADDR + 103) = 0x78;

	int32 = REG32(DDR_SDRAM_BASE_ADDR + 100);

	if (REG8(DDR_SDRAM_BASE_ADDR + 100)  != 0x12)
		print ("DDR SDRAM accesses char type Error:100!\n\r");
	if (REG8(DDR_SDRAM_BASE_ADDR + 101)  != 0x34)
		print ("DDR SDRAM accesses char type Error:101!\n\r");
	if (REG8(DDR_SDRAM_BASE_ADDR + 102)  != 0x56)
		print ("DDR SDRAM accesses char type Error:102!\n\r");
	if (REG8(DDR_SDRAM_BASE_ADDR + 103)  != 0x78)
		print ("DDR SDRAM accesses char type Error:103!\n\r");

	for (i=0;i<64;i++) {
		REG8(DDR_SDRAM_BASE_ADDR + i) = i;	
	}

	for (i=0;i<64;i++) {
		REG8(0x3900+i) = REG8(DDR_SDRAM_BASE_ADDR + i);	
	}

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

void Start()
{
  uint32 i;
  uint8  str[9];

  // Configure GPIO
  REG32(GPIO_BASE + RGPIO_OE)   = 0xff;  // bit0-7 = outputs, bit8-31 = inputs
  REG32(GPIO_BASE + RGPIO_INTE) = 0x0;   // Disable interrupts from GPIO

  print("\n\r\n\t");
  print("==OpenRisc 1200 SOC==\n\r\n");
  GPIO_Write(~0x0);

  print("\n\r");

  print("SD Card Bootloader, v0.2\n\r");
  print("Xianfeng Zeng, 2009 SA\n\r");
  print("Xianfeng@opencores.org\n\r");
  print("http://www.opencores.org/project,or1k_soc_on_altera_embedded_dev_kit\n\r");

  print("\n\r");

  print("System Clock: 30MHz\n\r\n");

  print("DDR SDRAM Base Address: 0x00000000 - 32MB\n\r");
  print("Ethernet Base Address:  0x20000000  IRQ 4\n\r");
  print("UART Base Address:      0x30000000  IRQ 2\n\r");
  print("GPIO Base Address:      0x40000000  IRQ 3\n\r");
  print("SD Card Base Address:   0x50000000\n\r");
  print("SRAM Base Address:      0xF0000000 - 16KB\n\r");
  print("\r\n\n");


  print("Init SD Card:");
  REG8(SD_BASE_ADD + SD_TRANS_CTRL_REG) = 0x1;  /* reset spiMaster */
  do_sleep();
  REG8(SD_BASE_ADD + SD_TRANS_CTRL_REG) = 0x0;
  if (spiMaster_init() == 0) {
	print("Passed!\n\r");
  } else {
	print("Failed!\n\r");
  }

  ddr_sdram_sample_test();
  copy_sd2ddr();

  GPIO_Write(~0x1);

  print("\n\r");

  print("Jump to DDR SDRAM: 0x100\n\r");
  jumpToRAM();

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

