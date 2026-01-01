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

#if 1
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
#endif


/******************************************************************************/
/*                  Gemm test                                                 */
/******************************************************************************/

int val(int r, int c) {
  return(r + 2*c - 3);
}

uint pack16(int x0, int x1) {
  return(((x1 & 0xffff) << 16) | (x0 & 0xffff));
}

uint pack8(int x0, int x1, int x2, int x3) {
  return(((x3 & 0xff) << 24) | ((x2 & 0xff) << 16) | ((x1 & 0xff) << 8) | (x0 & 0xff));
}

int MatA[16][8];
int MatB[16][8];
int MatC[16][8];

// Load packed matrix into memory (SV keyword automatic avoided)
void load_matrix_packed(int base, int dw16, int signed_in)
{
  int r,c;
  uint word;
  int x0_16, x1_16;
  int x0_8, x1_8, x2_8, x3_8;
  int N = 16;
  
  int pack = dw16 ? 2 : 4;
  for (r=0; r<N; r++) {
    for (c=0; c<N; c+=pack) {
      if (dw16) {
	x0_16 = val(r,c);
	x1_16 = val(r,c+1);
	if (!signed_in) {
	  x0_16 = x0_16 & 0x00007fff;
	  x1_16 = x1_16 & 0x00007fff;
	}
	word = pack16(x0_16, x1_16);
      } else {
	x0_8 = val(r,c);
	x1_8 = val(r,c+1);
	x2_8 = val(r,c+2);
	x3_8 = val(r,c+3);
	if (!signed_in) {
	  x0_8 = x0_8 & 0x7f;
	  x1_8 = x1_8 & 0x7f;
	  x2_8 = x2_8 & 0x7f;
	  x3_8 = x3_8 & 0x7f;
	}
	word = pack8(x0_8,x1_8,x2_8,x3_8);
      }
      if (dw16) {
	REG32(base + (r*N + c)*2) = word;
	//	GPIO_Write(0x99999999);
	//	GPIO_Write(word);
      }
      else {
	REG32(base + (r*N + c)*1) = word;
      }
    }
  }
}

void load_input_matrices(int dw16, int signed_in)
{
  GPIO_Write(0x5555bbb1);

  load_matrix_packed((int) &MatA[0][0], dw16, signed_in);

  int ii, jj;
  for(ii=0; ii<16; ii++) {
    for(jj=0; jj<8; jj++) {
      //      GPIO_Write(MatA[ii][jj]);
    }
  }

  GPIO_Write(0x5555bbb2);

  load_matrix_packed((int) &MatB[0][0], dw16, signed_in);

  for(ii=0; ii<16; ii++) {
    for(jj=0; jj<8; jj++) {
      //      GPIO_Write(MatB[ii][jj]);
    }
  }

  GPIO_Write(0x5555cccc);
}

int passCount;
int failCount;

int relu(int x) {
  if (x < 0)
    return 0;
  else
    return x;
}

int leaky_relu_q17(int x, int alpha_q1_7) {

  if (x >= 0)
    return x;
  else {
    int m = x * alpha_q1_7;
    return ( m >> 7);
  }
}

int quantize_q1616(int x, int scale_q1616, int zero) {

  int m = x * scale_q1616;
  int s = (m + 32768) >> 16;
  return ( s + zero );
}


void gemm_check_results (int testNum, int base_c, int dw16,
			 int act_en, int quant_en, int act_type,
			 int scale_q1616, int zero, int alpha_q1_7)
{
  int r,c,t,pack,elem_in_word;
  int word;
  int acc, out, actv, qv;
  int16 out16_0, out16_1;
  int8  out8_0, out8_1, out8_2, out8_3;
  int mism;
  int N = 16;

  print("Gemm Check\r\n");
	  
  pack  = dw16 ? 2 : 4;
  mism  = 0;

  for (r=0; r<N; r=r+1) {
    for (c=0; c<N; c=c+pack) {
//                    mem_read_word(base_c + ((r*N + c) / pack), word);
      if (dw16) {
	word = REG32(base_c + (r*N + c)*2);
	out16_0 = word & 0xffff;
	out16_1 = (word >> 16)& 0xffff;
#if 0
	GPIO_Write(word);
	GPIO_Write(0x88000000 | (out16_0 & 0xffff));
	GPIO_Write(0x88000000 | (out16_1 & 0xffff));
#endif
      } else {
	word = REG32(base_c + (r*N + c)*1);
	out8_0 = word & 0xff;
	out8_1 = (word >> 8) & 0xff;
	out8_2 = (word >> 16) & 0xff;
	out8_3 = (word >> 24) & 0xff;
#if 0
	GPIO_Write(word);
	GPIO_Write(0x88000000 | (out8_0 & 0xff));
	GPIO_Write(0x88000000 | (out8_1 & 0xff));
	GPIO_Write(0x88000000 | (out8_2 & 0xff));
	GPIO_Write(0x88000000 | (out8_3 & 0xff));
#endif
      }
      for (elem_in_word=0; elem_in_word<pack; elem_in_word=elem_in_word+1) {
	int col;
	col = c + elem_in_word;
	acc = 0;

	for (t=0; t<N; t=t+1) {
	  acc = acc + (val(r,t) * val(t,col));
#if 0
	  GPIO_Write(0x8a000000 | (val(r,t) & 0xffff));
	  GPIO_Write(0x8a000000 | (val(t,col) & 0xffff));
	  GPIO_Write(0x8a000000 | (acc & 0xffffff));
#endif
	}
		       
	actv = acc;
	if (act_en) {
	  if (!act_type)
	    actv = relu(actv);
	  else
	    actv = leaky_relu_q17(actv, alpha_q1_7);
	}
	qv = actv;
	if (quant_en)
	  qv = quantize_q1616(qv, scale_q1616, zero);
	if (dw16) {
	  if (qv > 32767)
	    out = 32767;
	  else if (qv < -32768)
	    out = -32768;
	  else
	    out = qv;
	  if (elem_in_word==0) {
	    if (out16_0 != (out & 0xffff)) {
	      mism = mism + 1;
	    }
	  } else {
	    if (out16_1 != (out & 0xffff)) {
	      mism = mism + 1;
	    }
	  }
	} else {
	  if (qv > 127)
	    out = 127;
	  else if (qv < -128)
	    out = -128;
	  else
	    out = qv;

	  switch(elem_in_word) {
	  case 0: if (out8_0 != out) {
	      mism = mism + 1;
	    }
	  case 1: if (out8_1 != out) {
	      mism = mism + 1;
	    }
	  case 2: if (out8_2 != out) {
	      mism = mism + 1;
	    }
	  case 3: if (out8_3 != out) {
	      mism = mism + 1;
	    }
	  default:
	  }
	  //	  GPIO_Write(0x8b000000 | (out & 0xffff));
	}
      }
    }
    if (mism==0) {
      passCount++;
    } else {
      failCount++;
    }
  }
}


void gemm_test()
{
  int dw16;
  int signed_in = 1;

  print("Gemm Tests\r\n");

//  int pMAT = (int) &MatA[0][0];
  GPIO_Write(0x5555aaaa);


  REG32(GEMM_BASE + GEMM_BASE_A) = (int) &MatA[0][0];
  REG32(GEMM_BASE + GEMM_BASE_B) = (int) &MatB[0][0];
  REG32(GEMM_BASE + GEMM_BASE_C) = (int) &MatC[0][0];

  int act_en, quant_en, mode_16, act_type = 0, mode_signed = 0, reg_mode_val;
  int testNum;
  
#if 0
  /******************************************************************************/
  // Test 3: 8-bit, ReLU + quant (scale 0.125)
  passCount = 0;
  failCount = 0;

  testNum = 3;

  act_en = 0;
  quant_en = 0; //1;
  mode_16 = 0;
  act_type = 0; //1;
  mode_signed = 0;

  reg_mode_val =
    (mode_16 << GEMM_MODE_DW16) |
    (act_en << GEMM_MODE_ACT) |
    (quant_en << GEMM_MODE_QUANT) |
    (act_type << GEMM_MODE_ACT_TYPE) |
    (mode_signed << GEMM_MODE_SIGNED);

  load_input_matrices(mode_16, signed_in);

  REG32(GEMM_BASE + GEMM_MODE) = reg_mode_val;
  
  REG32(GEMM_BASE + GEMM_CTRL_STAT) = 1; // start gemm

  while(REG32(GEMM_BASE + GEMM_CTRL_STAT) & 0x8000) {} // wait for done

  gemm_check_results (testNum, (int) &MatC[0][0], mode_16, act_en, quant_en, act_type, 65536, 0, 0);

  GPIO_Write(0xc0000000 | (testNum << 24) | passCount);
  GPIO_Write(0xf0000000 | (testNum << 24) | failCount);

  if (failCount == 0)
    print("\t\tTest3 PASS\r\n");
  else
    print("\t\tTest3 FAIL\r\n");
#endif
  
/******************************************************************************/
  // Test 1: 16-bit, packed, no activation/quant

  if (CPUID == 0) {
    
    passCount = 0;
    failCount = 0;
    
    testNum = 1;
    act_en = 0;
    quant_en = 0;
    mode_16 = 1;
    act_type = 0;
    mode_signed = 0;
    
    reg_mode_val =
      (mode_16 << GEMM_MODE_DW16) |
      (act_en << GEMM_MODE_ACT) |
      (quant_en << GEMM_MODE_QUANT) |
      (act_type << GEMM_MODE_ACT_TYPE) |
      (mode_signed << GEMM_MODE_SIGNED);
    
    load_input_matrices(mode_16, signed_in);
    
    REG32(GEMM_BASE + GEMM_MODE) = reg_mode_val;
    
    REG32(GEMM_BASE + GEMM_CTRL_STAT) = 1; // start gemm
    
    while(REG32(GEMM_BASE + GEMM_CTRL_STAT) & 0x8000) {} // wait for done
    
    gemm_check_results (testNum, (int) &MatC[0][0], mode_16, act_en, quant_en, act_type, 65536, 0, 0);
    
    GPIO_Write(0xc0000000 | (testNum << 24) | passCount);
    GPIO_Write(0xf0000000 | (testNum << 24) | failCount);
    
    if (failCount == 0)
      print("\t\tTest1 PASS\r\n");
    else
      print("\t\tTest1 FAIL\r\n");
  }
  
/******************************************************************************/
  // Test 2: 16-bit, ReLU activation

  if (CPUID == 1) {
    passCount = 0;
    failCount = 0;
    
    testNum = 2;
    act_en = 1;
    quant_en = 0;
    mode_16 = 1;
    act_type = 1;
    mode_signed = 0;
    
    reg_mode_val =
      (mode_16 << GEMM_MODE_DW16) |
      (act_en << GEMM_MODE_ACT) |
      (quant_en << GEMM_MODE_QUANT) |
      (act_type << GEMM_MODE_ACT_TYPE) |
      (mode_signed << GEMM_MODE_SIGNED);
    
    load_input_matrices(mode_16, signed_in);
    
    REG32(GEMM_BASE + GEMM_MODE) = reg_mode_val;
    
    REG32(GEMM_BASE + GEMM_CTRL_STAT) = 1; // start gemm
    
    while(REG32(GEMM_BASE + GEMM_CTRL_STAT) & 0x8000) {} // wait for done
    
    gemm_check_results (testNum, (int) &MatC[0][0], mode_16, act_en, quant_en, act_type, 65536, 0, 0);
    
    GPIO_Write(0xc0000000 | (testNum << 24) | passCount);
    GPIO_Write(0xf0000000 | (testNum << 24) | failCount);
    
    if (failCount == 0)
      print("\t\tTest2 PASS\r\n");
    else
      print("\t\tTest2 FAIL\r\n");
  }
  
/******************************************************************************/
  // Test 3: 8-bit, ReLU + quant (scale 0.125)

  if (CPUID == 0) {
    passCount = 0;
    failCount = 0;
    
    testNum = 3;
    act_en = 0;
    quant_en = 0; //1;
    mode_16 = 0;
    act_type = 0; //1;
    mode_signed = 0;
    
    reg_mode_val =
      (mode_16 << GEMM_MODE_DW16) |
      (act_en << GEMM_MODE_ACT) |
      (quant_en << GEMM_MODE_QUANT) |
      (act_type << GEMM_MODE_ACT_TYPE) |
      (mode_signed << GEMM_MODE_SIGNED);
    
    load_input_matrices(mode_16, signed_in);
    
    REG32(GEMM_BASE + GEMM_MODE) = reg_mode_val;
    
    REG32(GEMM_BASE + GEMM_CTRL_STAT) = 1; // start gemm
    
    while(REG32(GEMM_BASE + GEMM_CTRL_STAT) & 0x8000) {} // wait for done
    
    gemm_check_results (testNum, (int) &MatC[0][0], mode_16, act_en, quant_en, act_type, 65536, 0, 0);
    
    GPIO_Write(0xc0000000 | (testNum << 24) | passCount);
    GPIO_Write(0xf0000000 | (testNum << 24) | failCount);
    
    if (failCount == 0)
      print("\t\tTest3 PASS\r\n");
    else
      print("\t\tTest3 FAIL\r\n");
  }
  
/******************************************************************************/
  // Test 4: 8-bit, LeakyReLU alpha=0.125 + quant 0.5

  if (CPUID == 1) {
    passCount = 0;
    failCount = 0;
    
    testNum = 4;
    act_en = 1;
    quant_en = 1;
    mode_16 = 0;
    act_type = 1;
    mode_signed = 0;
    
    reg_mode_val =
      (mode_16 << GEMM_MODE_DW16) |
      (act_en << GEMM_MODE_ACT) |
      (quant_en << GEMM_MODE_QUANT) |
      (act_type << GEMM_MODE_ACT_TYPE) |
      (mode_signed << GEMM_MODE_SIGNED);
    
    load_input_matrices(mode_16, signed_in);
    
    REG32(GEMM_BASE + GEMM_MODE) = reg_mode_val;
    
    REG32(GEMM_BASE + GEMM_CTRL_STAT) = 1; // start gemm
    
    while(REG32(GEMM_BASE + GEMM_CTRL_STAT) & 0x8000) {} // wait for done
    
    gemm_check_results (testNum, (int) &MatC[0][0], mode_16, act_en, quant_en, act_type, 65536, 0, 0);
    
    GPIO_Write(0xc0000000 | (testNum << 24) | passCount);
    GPIO_Write(0xf0000000 | (testNum << 24) | failCount);
    
    if (failCount == 0)
      print("\t\tTest4 PASS\r\n");
    else
      print("\t\tTest4 FAIL\r\n");
  }
  
/******************************************************************************/
  GPIO_Write(0x5555dddd);
/******************************************************************************/
}

uint32 d2d_mat_rx[1024];
uint32 d2d_mat_tx[1024];

#if 1
void d2d_test()
{
  uint32 count;
  uint32 val;

  print("\n\rD2D Test\n\r");

  GPIO_Write((uint32) &d2d_mat_tx[0]);
  for(count=0; count<256; count++) {
    val = (CPUID << 24) + count;
    d2d_mat_tx[count] = val;
    //    GPIO_Write(val);
  }

  GPIO_Write(0xaaaa5555);
  
  //  if (CPUID == 0)
    {
      REG32(D2D_BASE + D2D_TX_SRC) = (uint32) &d2d_mat_tx[0];
      //    GPIO_Write(REG32(D2D_BASE + D2D_TX_SRC));
      REG32(D2D_BASE + D2D_TX_LEN) = 0x100;
      REG32(D2D_BASE + D2D_CTRL) = (1 << D2D_CTRL_TX_START) | (1 << D2D_CTRL_TX_ENABLE);
    }
  
    //  if (CPUID == 1)
    {
      REG32(D2D_BASE + D2D_RX_DST) = (uint32) &d2d_mat_rx[0];
      REG32(D2D_BASE + D2D_RX_LEN) = 0x100;
      REG32(D2D_BASE + D2D_CTRL) = (1 << D2D_CTRL_RX_START) | (1 << D2D_CTRL_RX_ENABLE);
    }
  
    //  if (CPUID == 0)
    {
      count = 0;
      while(count++ < 10000) {
	if ((REG32(D2D_BASE + D2D_STATUS) & (1 << D2D_STAT_TX_DONE)) == (1 << D2D_STAT_TX_DONE))
	  break;
      }
    }      

  GPIO_Write(0xbbbb4444);

  //  if (CPUID == 1)
    {
      count = 0;
      while(count++ < 10000) {
	//	GPIO_Write(0xaaa00000 + count);
	//	GPIO_Write(0x11100000 + (REG32(D2D_BASE + D2D_STATUS) && (1 << D2D_STAT_RX_DONE)));
	if ((REG32(D2D_BASE + D2D_STATUS) & (1 << D2D_STAT_RX_DONE)) == (1 << D2D_STAT_RX_DONE))
	  break;
      }
      
      GPIO_Write(0xbbbb5555);
      
      val = CPUID;
      passCount = 0;
      failCount = 0;
      
      for(count=0; count<256; count++) {
	if (val == 0) {
	  if (d2d_mat_rx[count] == (0x01000000 | count))
	    passCount++;
	  else
	    failCount++;
	}
	else if (val == 1) {
	  if (d2d_mat_rx[count] == (0x00000000 | count))
	    passCount++;
	  else
	    failCount++;
	}
      }
      
      GPIO_Write(0xdd000000 | passCount);
      GPIO_Write(0xdf000000 | failCount);
    }
}
#endif

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
    print("0)==\n\r\n");
  else
    print("1)==\n\r\n");
  GPIO_Write(0x1111);

  GPIO_Write(0x2222);
  print("Running from DRAM\n\r");

  GPIO_Write(0x3333);

  d2d_test();
  //  GPIO_Write(PASS_CODE);
  
  GPIO_Write(0x4444);

  gemm_test();

  for(i=0; i<1024; i++) {
    or1k_putc('.');
    do_sleep();
    //    GPIO_Write(i);
  }
  
  print("\n\r");
  GPIO_Write(PASS_CODE);
}

