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


/******************************************************************************/
/*                               DDR SDRAM                                    */
/******************************************************************************/
#define DDR_SDRAM_BASE_ADDR 0x00000000


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
#define SD_BASE_ADD	0x50000000

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
