#ifndef __BOARD_H__
#define __BOARD_H__


#ifndef REG
  #define REG register
#endif


#define IC_ENABLE       0
#define IC_SIZE         8192
#define IC_LINE         16

#define CONFIG_OR32_SYS_CLK	30
#define SYS_CLK			(CONFIG_OR32_SYS_CLK*1000000)


#define SRAM_BASE 0xE0000000
/******************************************************************************/
/*                               DDR SDRAM                                    */
/******************************************************************************/
#define DRAM_BASE 0x00000000

#define MC_CSR_BASE 0x08005000
#define MC_CSR_INIT (MC_CSR_BASE + 0x10)
#define MC_CSR_LMR  (MC_CSR_BASE + 0x14)

/******************************************************************************/
/*                               GEMM                                         */
/******************************************************************************/

#define GEMM_BASE 0x50000000

#define GEMM_CTRL_STAT 0x00
#define GEMM_MODE      0x04
#define GEMM_BASE_A    0x08
#define GEMM_BASE_B    0x0c
#define GEMM_BASE_C    0x10
#define GEMM_ALPHA     0x14
#define GEMM_QSCALE    0x18
#define GEMM_QZERO     0x1c

#define GEMM_MODE_DW16  0
#define GEMM_MODE_ACT   1
#define GEMM_MODE_QUANT 2
#define GEMM_MODE_ACT_TYPE   3
#define GEMM_MODE_SIGNED 4

/******************************************************************************/
/*                               G P I O                                      */
/******************************************************************************/

#define GPIO_BASE     0x40000000  // General purpose IO base address
#define RGPIO_IN      0x0     // GPIO input data
#define RGPIO_OUT     0x4     // GPIO output data 
#define RGPIO_OE      0x8     // GPIO output enable
#define RGPIO_INTE    0xC     // GPIO interrupt enable
#define RGPIO_PTRIG   0x10    // Type of event that triggers an IRQ
#define RGPIO_AUX     0x14    // 
#define RGPIO_CTRL    0x18    // GPIO control register
#define RGPIO_INTS    0x1C    // Interupt status
#define RGPIO_ECLK    0x20    // Enable gpio_eclk to latch RGPIO_IN
#define RGPIO_NEC     0x24    // Select active edge of gpio_eclk

/******************************************************************************/
/*                               U A R T                                      */
/******************************************************************************/
#define UART_BASE_ADD	0x30000000
#define UART_DLL        0       /* Out: Divisor Latch Low (DLAB=1) */
#define UART_DLM        1       /* Out: Divisor Latch High (DLAB=1) */

#define OR32_CONSOLE_BAUD  115200
#define UART_DEVISOR       SYS_CLK/(16*OR32_CONSOLE_BAUD)


/******************************************************************************/
/*                               s p i M A S T E R                            */
/******************************************************************************/
#define SD_BASE_ADD	0x10000000

#define SPI_RX_0                0
#define SPI_RX_1                1
#define SPI_RX_2                2
#define SPI_RX_3                3
#define SPI_TX_0                0
#define SPI_TX_1                1
#define SPI_TX_2                2
#define SPI_TX_3                3
#define SPI_CTRL                4
#define SPI_DEVIDE              5
#define SPI_SS                  6

/* Control register bit position */

#define SPI_CTRL_ASS            13    /* auto slave sel */
#define SPI_CTRL_IE             12    /* interrupt en */
#define SPI_CTRL_LSB            11    /* lab first */
#define SPI_CTRL_TX_NEGEDGE     10    /* sample tx on negedge */
#define SPI_CTRL_RX_NEGEDGE     9     /* sample rx on negedge */
#define SPI_CTRL_GO             8     /* transfer in progress */
#define SPI_CTRL_RES_1          7     /* reserved */
#define SPI_CTRL_CHAR_LEN       0     /* num bits (low 7 bits) */



#define SD_TRANS_TYPE_REG	0x2
#define SD_TRANS_CTRL_REG	0x3
#define SD_TRANS_STS_REG	0x4
#define SD_TRANS_ERROR_REG		0x5
#define SD_DIRECT_ACCESS_DATA_REG	0x6
#define SD_ADDR_7_0_REG		0x7
#define SD_ADDR_15_8_REG	0x8
#define SD_ADDR_23_16_REG	0x9
#define SD_ADDR_31_24_REG	0xa
#define SD_CLK_DEL_REG		0xb
#define SD_RX_FIFO_DATA_REG	0x10
#define SD_RX_FIFO_DATA_COUNT_MSB	0x12
#define SD_RX_FIFO_DATA_COUNT_LSB	0x13
#define SD_RX_FIFO_CONTROL_REG		0x14
#define SD_TX_FIFO_DATA_REG		0x20
#define SD_TX_FIFO_CONTROL_REG		0x24

#define SD_DIRECT_ACCESS	0
#define SD_INIT_SD		1
#define SD_RW_READ_SD_BLOCK	2
#define SD_RW_WRITE_SD_BLOCK	3

#define SD_WRITE_NO_ERROR	0
#define SD_WRITE_CMD_ERROR	1
#define SD_WRITE_DATA_ERROR	2
#define SD_WRITE_BUSY_ERROR	3

#define SD_READ_NO_ERROR	0
#define SD_READ_CMD_ERROR	1
#define SD_READ_TOKEN_ERROR	2

#define SD_INIT_NO_ERROR	0
#define SD_INIT_CMD0_ERROR	1
#define SD_INIT_CMD1_ERROR	2

#endif /*__BOARD_H__*/
