//===============================================================================
//
//          FILE:  or1k_sco_top.v
// 
//         USAGE:  ./or1k_sco_top.v 
// 
//   DESCRIPTION:  Top of the soc
// 
//       OPTIONS:  ---
//  REQUIREMENTS:  ---
//          BUGS:  ---
//         NOTES:  ---
//        AUTHOR:  Xianfeng Zeng (ZXF), xianfeng.zeng@gmail.com
//                                      Xianfeng.zeng@SierraAtlantic.com
//       COMPANY:  
//       VERSION:  1.0
//       CREATED:  04/05/2009 12:59:12 PM HKT
//      REVISION:  ---
//===============================================================================



// synopsys translate_off
// `include "timescale.v"
// synopsys translate_on
`include "or1200/rtl/verilog/or1200_defines.v"
`include "or1k_soc_defines.v"

module or1k_soc_top(
	// CLK and RESET
	wb_clk_pad_i, 		// 50 MHz to pll for cpu and other logic
	ddr_pll_clk_pad_i,	// 50 Mhz to ddr core

	rst_n_pad_i,		// to ddr core that will generate out globle reset

	// Flash chip
	flash_rstn, flash_cen, flash_oen, flash_wen,
	flash_rdy, flash_d, flash_a, flash_clk_pad_i,

	// SDRAM
	mc_clk_pad_i,
	mem_dat_pad_io,
	mem_adr_pad_o,
	mem_dqm_pad_o,
	mem_ba_pad_o,
	mem_cs_pad_o,
	mem_ras_pad_o,
	mem_cas_pad_o,
	mem_we_pad_o,
	mem_cke_pad_o,	

/*
 	//DDR SDRAM
	ddr_mem_cs_n_o,
	ddr_mem_cke_o,
	ddr_mem_addr_o,
	ddr_mem_ba_o,
	ddr_mem_ras_n_o,
	ddr_mem_cas_n_o,
	ddr_mem_we_n_o,
	ddr_mem_dm_o,
	ddr_mem_clk_io,
	ddr_mem_clk_n_io,
	ddr_mem_dq_io,
	ddr_mem_dqs_io,
*/
		    
	// Ethernet
	eth_reset_n_pad_o,
	eth_tx_er_pad_o,
	eth_tx_clk_pad_i,
	eth_tx_en_pad_o,
	eth_txd_pad_o,
	eth_rx_er_pad_i,
	eth_rx_clk_pad_i,
	eth_rx_dv_pad_i,
	eth_rxd_pad_i,
	eth_col_pad_i,
	eth_crs_pad_i,
	eth_mdio_pad_io,
	eth_mdc_pad_o,

	// UART
	uart_stx_pad_o,
	uart_srx_pad_i,

	// GPIO
	gpio_a_pad_io,

	// SPI_FLASH
	spi_flash_sclk_pad_o,
	spi_flash_ss_pad_o,
	spi_flash_miso_pad_i,
	spi_flash_mosi_pad_o,  
	spi_flash_w_n_pad_o,
	spi_flash_hold_n_pad_o,

	// MMC/SD Card 
	sd_card_clk_pad_o,
	sd_card_data_pad_i,
	sd_card_data_pad_o,
	sd_card_cs_n_pad_o,

	// LEDs
	led3_pad_o
);

// System pads
input	wb_clk_pad_i;
input	ddr_pll_clk_pad_i;
input	rst_n_pad_i;

//
// Flash
//
input	flash_clk_pad_i;
output 		flash_rstn;
output 		flash_cen;
output 		flash_oen;
output 		flash_wen;
input 		flash_rdy;
inout	[7:0]	flash_d;
inout	[20:0]	flash_a;

// Memory controller pads
input		mc_clk_pad_i;

//
// SDR SDRAM
//
inout 	[31:0]	mem_dat_pad_io;
output	[12:0]	mem_adr_pad_o;
output 	[3:0] 	mem_dqm_pad_o;
output 	[1:0]  	mem_ba_pad_o;
output        	mem_cs_pad_o;
output        	mem_ras_pad_o;
output        	mem_cas_pad_o;
output        	mem_we_pad_o;
output        	mem_cke_pad_o;

/*
//DDR SDRAM
output	[0:0]	ddr_mem_cs_n_o;
output	[0:0]	ddr_mem_cke_o;
output	[12:0]	ddr_mem_addr_o;
output	[1:0]	ddr_mem_ba_o;
output		ddr_mem_ras_n_o;
output		ddr_mem_cas_n_o;
output		ddr_mem_we_n_o;
output	[1:0]	ddr_mem_dm_o;
inout	[0:0]	ddr_mem_clk_io;
inout	[0:0]	ddr_mem_clk_n_io;
inout	[15:0]	ddr_mem_dq_io;
inout	[1:0]	ddr_mem_dqs_io;
*/
   
//
// Ethernet
//
output		eth_reset_n_pad_o;
output		eth_tx_er_pad_o;
input		eth_tx_clk_pad_i;
output		eth_tx_en_pad_o;
output	[3:0]	eth_txd_pad_o;
input		eth_rx_er_pad_i;
input		eth_rx_clk_pad_i;
input		eth_rx_dv_pad_i;
input	[3:0]	eth_rxd_pad_i;
input		eth_col_pad_i;
input		eth_crs_pad_i;
inout		eth_mdio_pad_io;
output		eth_mdc_pad_o;

//
// UART external i/f wires
//
output		uart_stx_pad_o;
input		uart_srx_pad_i;

// GPIO
inout [31:0]	gpio_a_pad_io;

// SPI_FLASH
output        	spi_flash_sclk_pad_o;
output        	spi_flash_ss_pad_o;
input         	spi_flash_miso_pad_i;
output        	spi_flash_mosi_pad_o;
output        	spi_flash_w_n_pad_o;
output        	spi_flash_hold_n_pad_o;


//
// spiMaster for MMC/SD Card
output sd_card_clk_pad_o;
input  sd_card_data_pad_i;
output sd_card_data_pad_o;
output sd_card_cs_n_pad_o;

//
// LEDs output
//
output led3_pad_o;


//
//---------------------------------------
// Internal Signals
//---------------------------------------
//

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_OPERAND_WIDTH;
parameter ppic_ints = `OR1200_PIC_INTS;

//
// Signals for OR1200
//
wire	[1:0]		or1k_clmode_i = 2'd0;	// 00 WB=RISC, 01 WB=RISC/2, 10 N/A, 11 WB=RISC/4

//
// RISC misc
//
wire	[ppic_ints-1:0]	pic_ints;

//
// Instruction WISHBONE interface for OR1200
//
wire			or1k_iwb_clk_i;	// clock input
wire			or1k_iwb_rst_i;	// reset input
wire			or1k_iwb_ack_i;	// normal termination
wire			or1k_iwb_err_i;	// termination w/ error
wire			or1k_iwb_rty_i;	// termination w/ retry
wire	[dw-1:0]	or1k_iwb_dat_i;	// input data bus
wire			or1k_iwb_cyc_o;	// cycle valid output
wire	[aw-1:0]	or1k_iwb_adr_o;	// address bus outputs
wire			or1k_iwb_stb_o;	// strobe output
wire			or1k_iwb_we_o;	// indicates write transfer
wire	[3:0]		or1k_iwb_sel_o;	// byte select outputs
wire	[dw-1:0]	or1k_iwb_dat_o;	// output data bus
`ifdef OR1200_WB_CAB
wire			or1k_iwb_cab_o;	// indicates consecutive address burst
`endif
`ifdef OR1200_WB_B3
wire	[2:0]		or1k_iwb_cti_o;	// cycle type identifier
wire	[1:0]		or1k_iwb_bte_o;	// burst type extension
`endif

//
// Data WISHBONE interface for OR1200
//
wire			or1k_dwb_clk_i;	// clock input
wire			or1k_dwb_rst_i;	// reset input
wire			or1k_dwb_ack_i;	// normal termination
wire			or1k_dwb_err_i;	// termination w/ error
wire			or1k_dwb_rty_i;	// termination w/ retry
wire	[dw-1:0]	or1k_dwb_dat_i;	// input data bus
wire			or1k_dwb_cyc_o;	// cycle valid output
wire	[aw-1:0]	or1k_dwb_adr_o;	// address bus outputs
wire			or1k_dwb_stb_o;	// strobe output
wire			or1k_dwb_we_o;	// indicates write transfer
wire	[3:0]		or1k_dwb_sel_o;	// byte select outputs
wire	[dw-1:0]	or1k_dwb_dat_o;	// output data bus
`ifdef OR1200_WB_CAB
wire			or1k_dwb_cab_o;	// indicates consecutive address burst
`endif
`ifdef OR1200_WB_B3
wire	[2:0]		or1k_dwb_cti_o;	// cycle type identifier
wire	[1:0]		or1k_dwb_bte_o;	// burst type extension
`endif

// MEM_IF_WB_SLAVE
wire	[31:0]	mem_if_wb_data_i;
wire	[31:0]	mem_if_wb_data_o;
wire	[31:0]	mem_if_wb_addr_i;
wire	[3:0]	mem_if_wb_sel_i;
wire		mem_if_wb_we_i;
wire		mem_if_wb_cyc_i;
wire		mem_if_wb_stb_i;
wire		mem_if_wb_ack_o;
wire		mem_if_wb_err_o;	

//
// Flash controller slave i/f wires
//
wire 	[31:0]		wb_fs_dat_i;
wire 	[31:0]		wb_fs_dat_o;
wire 	[31:0]		wb_fs_adr_i;
wire 	[3:0]		wb_fs_sel_i;
wire			wb_fs_we_i;
wire			wb_fs_cyc_i;
wire			wb_fs_stb_i;
wire			wb_fs_ack_o;
wire			wb_fs_err_o;

//
// UART16550 core slave i/f wires
//
wire	[31:0]		wb_us_dat_i;
wire	[31:0]		wb_us_dat_o;
wire	[31:0]		wb_us_adr_i;
wire	[3:0]		wb_us_sel_i;
wire			wb_us_we_i;
wire			wb_us_cyc_i;
wire			wb_us_stb_i;
wire			wb_us_ack_o;
//wire			wb_us_err_o;

// CPU signals for advanced debug interface
wire	[31:0]	dbg_cpu0_addr_o; 
wire	[31:0]	dbg_cpu0_data_i; 
wire	[31:0]	dbg_cpu0_data_o;
wire		dbg_cpu0_bp_i;
wire		dbg_cpu0_stall_o;
wire		dbg_cpu0_stb_o;
wire		dbg_cpu0_we_o;
wire		dbg_cpu0_ack_i;

wire		dbg_cpu0_rst_o;


//
// reset_request output from DDR core
//
wire	reset_request_n;

//
// for internal clk
//
wire	clk_cpu_25;	// cpu clk
wire	spiSysClk;	// spiMaster logic clock

//
// SD Loader
//
//wire        sd_loader_rst_o;
//wire        sd_loader_done_o;

//---------------------------------------
//
// Assign wires to pads
//
wire wb_rst_pad_i;
reg [1:0] count;

//
// generate wb_rst_pad_i by sd_loader_rst_o that is 
// from SD Loader 
//
/*
always @(posedge clk_cpu_25 or negedge reset_request_n)
begin
	if (~reset_request_n) begin
		wb_rst_pad_i <= 1'b1;
		count <= 2'b00;
	end
	else if (count != 2'b11) begin
		count <= count + 1;
	end
	else
		wb_rst_pad_i <= 1'b0;
end
*/
assign wb_rst_pad_i = ~rst_n_pad_i;
assign eth_reset_n_pad_o = ~wb_rst_pad_i;

//
// Unused interrupts
//
assign pic_ints[`APP_INT_RES1] = 'b0;
assign pic_ints[`APP_INT_RES3] = 'b0;

//
//---------------------------------------
// Compoments
//---------------------------------------
//

//
// Altera PLL
//
//altera_pll pll (
//	.inclk0	(wb_clk_pad_i),
//	.c0	(),		// 25MHz for wb
//	.c1	(clk_cpu_25),	// 30MHz 
//	.c2	(),		// 35Mhz
//	.c3	(spiSysClk),	// 50Mhz
//	.locked ()
//);

   assign clk_cpu_25 = wb_clk_pad_i;
   
//
// OR1K CPU
//

or1200_top cpu(
	// System
	.clk_i		(clk_cpu_25),
	.rst_i		(wb_rst_pad_i | dbg_cpu0_rst_o),

	.clmode_i	(or1k_clmode_i),

	// Interrupts
	.pic_ints_i	(pic_ints),

	// Instruction WISHBONE INTERFACE
	.iwb_clk_i	(clk_cpu_25),
	.iwb_rst_i	(wb_rst_pad_i),
	.iwb_ack_i	(or1k_iwb_ack_i),
	.iwb_err_i	(or1k_iwb_err_i),
	.iwb_rty_i	(or1k_iwb_rty_i),
	.iwb_dat_i	(or1k_iwb_dat_i),
	.iwb_cyc_o	(or1k_iwb_cyc_o),
	.iwb_adr_o	(or1k_iwb_adr_o),
	.iwb_stb_o	(or1k_iwb_stb_o),
	.iwb_we_o	(or1k_iwb_we_o),
	.iwb_sel_o	(or1k_iwb_sel_o),
	.iwb_dat_o	(or1k_iwb_dat_o),

`ifdef NO_USED_CURRENTLY

`ifdef OR1200_WB_CAB
	iwb_cab_o,
`endif
`ifdef OR1200_WB_B3
	iwb_cti_o, iwb_bte_o,
`endif
`endif // NO_USED_CURRENTLY

	// Data WISHBONE INTERFACE
	.dwb_clk_i	(clk_cpu_25),
	.dwb_rst_i	(wb_rst_pad_i),
	.dwb_ack_i	(or1k_dwb_ack_i),
	.dwb_err_i	(or1k_dwb_err_i),
	.dwb_rty_i	(or1k_dwb_rty_i),
	.dwb_dat_i	(or1k_dwb_dat_i),
	.dwb_cyc_o	(or1k_dwb_cyc_o),
	.dwb_adr_o	(or1k_dwb_adr_o),
	.dwb_stb_o	(or1k_dwb_stb_o),
	.dwb_we_o	(or1k_dwb_we_o),
	.dwb_sel_o	(or1k_dwb_sel_o),
	.dwb_dat_o	(or1k_dwb_dat_o),

`ifdef OR1200_WB_CAB
	.dwb_cab_o	(),
`endif

`ifdef OR1200_WB_B3
	.dwb_cti_o	(),
	.dwb_bte_o	(),
`endif

	// External Debug Interface
	.dbg_stall_i	(dbg_cpu0_stall_o),
	.dbg_ewt_i	(1'b0),
	.dbg_lss_o	(),
	.dbg_is_o	(),
	.dbg_wp_o	(),
	.dbg_bp_o	(dbg_cpu0_bp_i),
	.dbg_stb_i	(dbg_cpu0_stb_o),
	.dbg_we_i	(dbg_cpu0_we_o),
	.dbg_adr_i	(dbg_cpu0_addr_o),
	.dbg_dat_i	(dbg_cpu0_data_o),
	.dbg_dat_o	(dbg_cpu0_data_i),
	.dbg_ack_o	(dbg_cpu0_ack_i),

	// Power Management
	.pm_cpustall_i	(1'b0),
	.pm_clksd_o	(),
	.pm_dc_gate_o	(),
	.pm_ic_gate_o	(),
	.pm_dmmu_gate_o	(), 
	.pm_immu_gate_o	(),
	.pm_tt_gate_o	(),
	.pm_cpu_gate_o	(),
	.pm_wakeup_o	(),
	.pm_lvolt_o	()
);

flash_top flash_top (

	// WISHBONE common
	.wb_clk_i	( wb_clk_pad_i ),
	.wb_rst_i	( wb_rst_pad_i ),

	// WISHBONE slave
	.wb_dat_i	( wb_fs_dat_i ),
	.wb_dat_o	( wb_fs_dat_o ),
	.wb_adr_i	( wb_fs_adr_i ),
	.wb_sel_i	( wb_fs_sel_i ),
	.wb_we_i	( wb_fs_we_i  ),
	.wb_cyc_i	( wb_fs_cyc_i ),
	.wb_stb_i	( wb_fs_stb_i ),
	.wb_ack_o	( wb_fs_ack_o ),
	.wb_err_o	( wb_fs_err_o ),

	// Flash external
	.flash_rstn	( flash_rstn ),
	.cen		( flash_cen ),
	.oen		( flash_oen ),
	.wen		( flash_wen ),
	.rdy		( flash_rdy ),
	.d		( flash_d ),
	.a		( flash_a ),
	.a_oe		( )
);

//
// memory controller
//
wire 	 	mem_dat_pad_oe,mem_con_pad_oe;
wire [23:0] 	mc_addr_wire_o;
wire [31:0]	mem_dat_pad_i, mem_dat_pad_o;// mem_dat_pad_oe is now declared lower! - Julius
//wire [1:0]	mem_dqm_pad_oe;
wire [12:0] 	mem_adr_pad_oe;
//wire [1:0] 	mem_ba_pad_oe;
wire [7:0] 	mem_csi_pad_o;
wire [7:0] 	mem_csi_pad_oe;
wire 		mem_ras_pad_oe, mem_cas_pad_oe, mem_we_pad_oe, mem_cke_pad_oe;

mc_top mem_if(
	.clk_i		(clk_cpu_25),
	.rst_i		(wb_rst_pad_i),	// The reset is asynchronous and an active low signal

	.wb_data_i	(mem_if_wb_data_i),
	.wb_data_o	(mem_if_wb_data_o),
	.wb_addr_i	(mem_if_wb_addr_i),
	.wb_sel_i	(mem_if_wb_sel_i),
	.wb_we_i	(mem_if_wb_we_i),
	.wb_cyc_i	(mem_if_wb_cyc_i),
	.wb_stb_i	(mem_if_wb_stb_i),
	.wb_ack_o	(mem_if_wb_ack_o),
	.wb_err_o	(mem_if_wb_err_o), 

	.suspended_o		(),
	.poc_o			(),
	.mc_bg_pad_o		(),
	.mc_addr_pad_o		(mc_addr_wire_o),
	.mc_data_pad_o		(mem_dat_pad_o),
	.mc_dp_pad_o		(),
	.mc_doe_pad_doe_o	(mem_dat_pad_oe),
	.mc_dqm_pad_o		(mem_dqm_pad_o),
	.mc_oe_pad_o_		(mem_oe_pad_o_),
	.mc_we_pad_o_		(mem_we_pad_o),
	.mc_cas_pad_o_		(mem_cas_pad_o),
	.mc_ras_pad_o_		(mem_ras_pad_o),
	.mc_cke_pad_o_		(mem_cke_pad_o),
	.mc_cs_pad_o_		(mem_csi_pad_o),
	.mc_rp_pad_o_		(),
	.mc_vpen_pad_o		(),
	.mc_adsc_pad_o_		(),
	.mc_adv_pad_o_		(),
	.mc_zz_pad_o		(),
	.mc_coe_pad_coe_o	(mem_con_pad_oe),
	.susp_req_i		(1'b0),
	.resume_req_i		(1'b0),
	.mc_clk_i		(mc_clk_pad_i),
	.mc_br_pad_i		(1'b0),
	.mc_ack_pad_i		(1'b0),
	.mc_data_pad_i		(mem_dat_pad_i),
	.mc_dp_pad_i		(4'h0),
	.mc_sts_pad_i		(1'b0)	   
);

   assign 	 mem_dat_pad_io = (wb_rst_pad_i) ? 32'h0000_0000 :  (mem_dat_pad_oe) ? mem_dat_pad_o : {32{1'bz}};
   assign 	 mem_dat_pad_i = mem_dat_pad_io;
   assign 	 mem_cs_pad_o = mem_csi_pad_o[0];

   assign 	 mem_adr_pad_o = (mem_con_pad_oe) ? mc_addr_wire_o[12:0] : {13{1'bz}};
   assign 	 mem_ba_pad_o = (mem_con_pad_oe) ? mc_addr_wire_o[14:13] : {2{1'bz}};

//
// Instantiation of the UART16550
//
uart_top uart_top (

	// WISHBONE common
	.wb_clk_i	( clk_cpu_25 ), 
	.wb_rst_i	( wb_rst_pad_i ),

	// WISHBONE slave
	.wb_adr_i	( wb_us_adr_i[4:0] ),
	.wb_dat_i	( wb_us_dat_i ),
	.wb_dat_o	( wb_us_dat_o ),
	.wb_we_i	( wb_us_we_i  ),
	.wb_stb_i	( wb_us_stb_i ),
	.wb_cyc_i	( wb_us_cyc_i ),
	.wb_ack_o	( wb_us_ack_o ),
	.wb_sel_i	( wb_us_sel_i ),

	// Interrupt request
	.int_o		( pic_ints[`APP_INT_UART] ),

	// UART signals
	// serial input/output
	.stx_pad_o	( uart_stx_pad_o ),
	.srx_pad_i	( uart_srx_pad_i ),

	// modem signals
	.rts_pad_o	( ),
	.cts_pad_i	( 1'b0 ),
	.dtr_pad_o	( ),
	.dsr_pad_i	( 1'b0 ),
	.ri_pad_i	( 1'b0 ),
	.dcd_pad_i	( 1'b0 )
);


   // GPIO
// wbs_gpio_led
wire [31:0] wbs_gpio_dat_o;
wire [31:0] wbs_gpio_dat_i;
wire [31:0] wbs_gpio_adr_i;
wire [3:0] wbs_gpio_sel_i;
wire wbs_gpio_stb_i;
wire wbs_gpio_cyc_i;
wire wbs_gpio_ack_o;
wire wbs_gpio_err_o;


   // GPIO_0
   wire [31:0] 	 gpio_a_o, gpio_a_oe, gpio_a_i;

   gpio_top i_gpio_a_top (
			  .wb_dat_o     (wbs_gpio_dat_o),
			  .wb_dat_i     (wbs_gpio_dat_i),
			  .wb_sel_i     (wbs_gpio_sel_i),
			  .wb_adr_i     (wbs_gpio_adr_i[7:0]),
			  .wb_we_i      (wbs_gpio_we_i),
			  .wb_stb_i     (wbs_gpio_stb_i),
			  .wb_cyc_i     (wbs_gpio_cyc_i),
			  .wb_ack_o     (wbs_gpio_ack_o),
			  .wb_err_o     (wbs_gpio_err_o),
			  .wb_clk_i     (clk_cpu_25),
			  .wb_rst_i     (wb_rst_pad_i),
			  .wb_inta_o    (pic_ints[`APP_INT_GPIO]),

			  .ext_pad_i    (gpio_a_i),
			  .ext_pad_o    (gpio_a_o),
			  .ext_padoe_o  (gpio_a_oe)
			  );
   
   assign 	 gpio_a_pad_io[ 0] = (gpio_a_oe[ 0]) ? gpio_a_o[ 0] : 1'bz;
   assign 	 gpio_a_pad_io[ 1] = (gpio_a_oe[ 1]) ? gpio_a_o[ 1] : 1'bz;
   assign 	 gpio_a_pad_io[ 2] = (gpio_a_oe[ 2]) ? gpio_a_o[ 2] : 1'bz;
   assign 	 gpio_a_pad_io[ 3] = (gpio_a_oe[ 3]) ? gpio_a_o[ 3] : 1'bz;
   assign 	 gpio_a_pad_io[ 4] = (gpio_a_oe[ 4]) ? gpio_a_o[ 4] : 1'bz;
   assign 	 gpio_a_pad_io[ 5] = (gpio_a_oe[ 5]) ? gpio_a_o[ 5] : 1'bz;
   assign 	 gpio_a_pad_io[ 6] = (gpio_a_oe[ 6]) ? gpio_a_o[ 6] : 1'bz;
   assign 	 gpio_a_pad_io[ 7] = (gpio_a_oe[ 7]) ? gpio_a_o[ 7] : 1'bz;
   assign 	 gpio_a_pad_io[ 8] = (gpio_a_oe[ 8]) ? gpio_a_o[ 8] : 1'bz;
   assign 	 gpio_a_pad_io[ 9] = (gpio_a_oe[ 9]) ? gpio_a_o[ 9] : 1'bz;
   assign 	 gpio_a_pad_io[10] = (gpio_a_oe[10]) ? gpio_a_o[10] : 1'bz;
   assign 	 gpio_a_pad_io[11] = (gpio_a_oe[11]) ? gpio_a_o[11] : 1'bz;
   assign 	 gpio_a_pad_io[12] = (gpio_a_oe[12]) ? gpio_a_o[12] : 1'bz;
   assign 	 gpio_a_pad_io[13] = (gpio_a_oe[13]) ? gpio_a_o[13] : 1'bz;
   assign 	 gpio_a_pad_io[14] = (gpio_a_oe[14]) ? gpio_a_o[14] : 1'bz;
   assign 	 gpio_a_pad_io[15] = (gpio_a_oe[15]) ? gpio_a_o[15] : 1'bz;
   assign 	 gpio_a_pad_io[16] = (gpio_a_oe[16]) ? gpio_a_o[16] : 1'bz;
   assign 	 gpio_a_pad_io[17] = (gpio_a_oe[17]) ? gpio_a_o[17] : 1'bz;
   assign 	 gpio_a_pad_io[18] = (gpio_a_oe[18]) ? gpio_a_o[18] : 1'bz;
   assign 	 gpio_a_pad_io[19] = (gpio_a_oe[19]) ? gpio_a_o[19] : 1'bz;
   assign 	 gpio_a_pad_io[20] = (gpio_a_oe[20]) ? gpio_a_o[20] : 1'bz;
   assign 	 gpio_a_pad_io[21] = (gpio_a_oe[21]) ? gpio_a_o[21] : 1'bz;
   assign 	 gpio_a_pad_io[22] = (gpio_a_oe[22]) ? gpio_a_o[22] : 1'bz;
   assign 	 gpio_a_pad_io[23] = (gpio_a_oe[23]) ? gpio_a_o[23] : 1'bz;
   assign 	 gpio_a_pad_io[24] = (gpio_a_oe[24]) ? gpio_a_o[24] : 1'bz;
   assign 	 gpio_a_pad_io[25] = (gpio_a_oe[25]) ? gpio_a_o[25] : 1'bz;
   assign 	 gpio_a_pad_io[26] = (gpio_a_oe[26]) ? gpio_a_o[26] : 1'bz;
   assign 	 gpio_a_pad_io[27] = (gpio_a_oe[27]) ? gpio_a_o[27] : 1'bz;
   assign 	 gpio_a_pad_io[28] = (gpio_a_oe[28]) ? gpio_a_o[28] : 1'bz;
   assign 	 gpio_a_pad_io[29] = (gpio_a_oe[29]) ? gpio_a_o[29] : 1'bz;
   assign 	 gpio_a_pad_io[30] = (gpio_a_oe[30]) ? gpio_a_o[30] : 1'bz;
   assign 	 gpio_a_pad_io[31] = (gpio_a_oe[31]) ? gpio_a_o[31] : 1'bz;
   assign 	 gpio_a_i = gpio_a_pad_io;

   // SPI_Flash
wire [31:0] wbs_spi_0_dat_o;
wire [31:0] wbs_spi_0_dat_i;
wire [31:0] wbs_spi_0_adr_i;
wire [3:0] wbs_spi_0_sel_i;
wire [1:0] wbs_spi_0_bte_i;
wire [2:0] wbs_spi_0_cti_i;
wire [7:0] spi_flash_ss_o;
wire wbs_spi_0_we_i;
wire wbs_spi_0_stb_i;
wire wbs_spi_0_cyc_i;
wire wbs_spi_0_ack_o;
wire wbs_spi_0_err_o;
   spi_top #(1) i_spi_0_top
     (
      .wb_dat_o   (wbs_spi_0_dat_o),
      .wb_dat_i   (wbs_spi_0_dat_i),
      .wb_sel_i   (wbs_spi_0_sel_i),
      .wb_adr_i   (wbs_spi_0_adr_i[4:0]),
      .wb_we_i    (wbs_spi_0_we_i),
      .wb_stb_i   (wbs_spi_0_stb_i),
      .wb_cyc_i   (wbs_spi_0_cyc_i),
      .wb_ack_o   (wbs_spi_0_ack_o),
      .wb_err_o   (wbs_spi_0_err_o),
      .wb_clk_i   (wb_clk_pad_i),
      .wb_rst_i   (wb_rst_pad_i),
      .wb_int_o   (pic_ints[`APP_INT_SPI0]),
      
      .miso_pad_i (spi_flash_miso_pad_i),
      .mosi_pad_o (spi_flash_mosi_pad_o),
      .ss_pad_o   (spi_flash_ss_o),
      .sclk_pad_o (spi_flash_sclk_pad_o)
      );

   assign	spi_flash_w_n_pad_o    = 1'b1;
   assign	spi_flash_hold_n_pad_o = 1'b1;
   assign	spi_flash_ss_o = spi_flash_ss_o[0];
   
//
// Instantiation of the Ethernet 10/100 MAC
//

// Ethernet core master i/f wires
wire 	[31:0]		wb_em_adr_o;
wire 	[31:0] 		wb_em_dat_i;
wire 	[31:0] 		wb_em_dat_o;
wire 	[3:0]		wb_em_sel_o;
wire			wb_em_we_o;
wire 			wb_em_stb_o;
wire			wb_em_cyc_o;
wire			wb_em_cab_o;
wire			wb_em_ack_i;
wire			wb_em_err_i;

// Ethernet core slave i/f wires
wire	[31:0]		wb_es_dat_i;
wire	[31:0]		wb_es_dat_o;
wire	[31:0]		wb_es_adr_i;
wire	[3:0]		wb_es_sel_i;
wire			wb_es_we_i;
wire			wb_es_cyc_i;
wire			wb_es_stb_i;
wire			wb_es_ack_o;
wire			wb_es_err_o;

wire	eth_mdo;
wire	eth_mdoe;

eth_top eth_top (

	// WISHBONE common
	.wb_clk_i	( clk_cpu_25 ),
	.wb_rst_i	( wb_rst_pad_i ),

	// WISHBONE slave
	.wb_dat_i	( wb_es_dat_i ),
	.wb_dat_o	( wb_es_dat_o ),
	.wb_adr_i	( wb_es_adr_i[11:2] ),
	.wb_sel_i	( wb_es_sel_i ),
	.wb_we_i	( wb_es_we_i  ),
	.wb_cyc_i	( wb_es_cyc_i ),
	.wb_stb_i	( wb_es_stb_i ),
	.wb_ack_o	( wb_es_ack_o ),
	.wb_err_o	( wb_es_err_o ), 

	// WISHBONE master
	.m_wb_adr_o	( wb_em_adr_o ),
	.m_wb_sel_o	( wb_em_sel_o ),
	.m_wb_we_o	( wb_em_we_o  ), 
	.m_wb_dat_o	( wb_em_dat_o ),
	.m_wb_dat_i	( wb_em_dat_i ),
	.m_wb_cyc_o	( wb_em_cyc_o ), 
	.m_wb_stb_o	( wb_em_stb_o ),
	.m_wb_ack_i	( wb_em_ack_i ),
	.m_wb_err_i	( wb_em_err_i ), 

	// TX
	.mtx_clk_pad_i	( eth_tx_clk_pad_i ),
	.mtxd_pad_o	( eth_txd_pad_o ),
	.mtxen_pad_o	( eth_tx_en_pad_o ),
	.mtxerr_pad_o	( eth_tx_er_pad_o ),

	// RX
	.mrx_clk_pad_i	( eth_rx_clk_pad_i ),
	.mrxd_pad_i	( eth_rxd_pad_i ),
	.mrxdv_pad_i	( eth_rx_dv_pad_i ),
	.mrxerr_pad_i	( eth_rx_er_pad_i ),
	.mcoll_pad_i	( eth_col_pad_i ),
	.mcrs_pad_i	( eth_crs_pad_i ),
  
	// MIIM
	.mdc_pad_o	( eth_mdc_pad_o ),
	.md_pad_i	( eth_mdio_pad_i ),
	.md_pad_o	( eth_mdo ),
	.md_padoe_o	( eth_mdoe ),

	// Interrupt
	.int_o		( pic_ints[`APP_INT_ETH] )
);

//
// Ethernet tri-state
//
assign eth_mdio_pad_io = eth_mdoe ? eth_mdo : 1'bz;

//
// Advanced Debug Interface
//
// JTAG signals
wire		dbg_tck_i;
wire		dbg_tdi_i;
wire		dbg_tdo_o;
wire		dbg_rst_i;
// TAP states
wire		dbg_shift_dr_i;
wire		dbg_pause_dr_i;
wire		dbg_update_dr_i;
wire		dbg_capture_dr_i;
// Module select from TAP
wire		dbg_debug_select_i;

wire	[31:0]	dbg_wb_adr_o;
wire	[31:0]	dbg_wb_dat_o;
wire	[31:0]	dbg_wb_dat_i;
wire		dbg_wb_cyc_o;
wire		dbg_wb_stb_o;
wire	[3:0]	dbg_wb_sel_o;
wire		dbg_wb_we_o;
wire		dbg_wb_ack_i;
//wire		dbg_wb_cab_o;
wire		dbg_wb_err_i;
//wire	[2:0]	dbg_wb_cti_o;
//wire	[1:0]	dbg_wb_bte_o;

   assign dbg_rst_i = wb_rst_pad_i;

adbg_top adbg_if(
	// JTAG signals
	.tck_i		(dbg_tck_i),
	.tdi_i		(dbg_tdi_i),
	.tdo_o		(dbg_tdo_o),
	.rst_i		(dbg_rst_i),

	// TAP states
	.shift_dr_i	(dbg_shift_dr_i),
	.pause_dr_i	(dbg_pause_dr_i),
	.update_dr_i	(dbg_update_dr_i),
	.capture_dr_i	(dbg_capture_dr_i),

	// Instructions
	.debug_select_i	(dbg_debug_select_i),

	// WISHBONE common signals
	.wb_clk_i	(clk_cpu_25),

	// WISHBONE master interface
	.wb_adr_o	(dbg_wb_adr_o),
	.wb_dat_o	(dbg_wb_dat_o),
	.wb_dat_i	(dbg_wb_dat_i),
	.wb_cyc_o	(dbg_wb_cyc_o),
	.wb_stb_o	(dbg_wb_stb_o),
	.wb_sel_o	(dbg_wb_sel_o),
	.wb_we_o	(dbg_wb_we_o),
	.wb_ack_i	(dbg_wb_ack_i),
	.wb_cab_o	(),
	.wb_err_i	(dbg_wb_err_i),
	.wb_cti_o	(),
	.wb_bte_o	(),

	// CPU signals
	.cpu0_clk_i	(clk_cpu_25), 
	.cpu0_addr_o	(dbg_cpu0_addr_o), 
	.cpu0_data_i	(dbg_cpu0_data_i), 
	.cpu0_data_o	(dbg_cpu0_data_o),
	.cpu0_bp_i	(dbg_cpu0_bp_i),
	.cpu0_stall_o	(dbg_cpu0_stall_o),
	.cpu0_stb_o	(dbg_cpu0_stb_o),
	.cpu0_we_o	(dbg_cpu0_we_o),
	.cpu0_ack_i	(dbg_cpu0_ack_i),
	.cpu0_rst_o	(dbg_cpu0_rst_o)
);

/*
altera_virtual_jtag altera_vjtag(
	.tck_o			(dbg_tck_i),
	.debug_tdo_o		(dbg_tdo_o),
	.tdi_o			(dbg_tdi_i),
	.test_logic_reset_o	(dbg_rst_i),
	.run_test_idle_o	(),
	.shift_dr_o		(dbg_shift_dr_i),
	.capture_dr_o		(dbg_capture_dr_i),
	.pause_dr_o		(dbg_pause_dr_i),
	.update_dr_o		(dbg_update_dr_i),
	.debug_select_o		(dbg_debug_select_i)
);
*/
   
assign led3_pad_o = ~dbg_cpu0_stall_o;

//
// Work around for GDB access 0xc0000000 after MMU enabled
//
wire [31:0] s0_data_i;	
wire [31:0] s0_data_o;	
wire [31:0] s0_addr_o;	
wire [3:0]  s0_sel_o;	
wire        s0_we_o;	
wire        s0_cyc_o;	
wire        s0_stb_o;	
wire        s0_ack_i;	
wire        s0_err_i;	


wire [31:0] s12_data_i;	
wire [31:0] s12_data_o;	
wire [31:0] s12_addr_o;	
wire [3:0]  s12_sel_o;	
wire        s12_we_o;	
wire        s12_cyc_o;	
wire        s12_stb_o;	
wire        s12_ack_i;	
wire        s12_err_i;	


/*
//
// SD Loader
//
wire [31:0] sd_loader_adr_o;
wire [31:0] sd_loader_dat_o;
wire [31:0] sd_loader_dat_i;
wire        sd_loader_cyc_o;
wire        sd_loader_stb_o;
wire [3:0]  sd_loader_sel_o;
wire        sd_loader_we_o;
wire        sd_loader_ack_i;

sd_loader_top sd_loasder(
                .wb_clk_i	(clk_cpu_25),
		.wb_rst_i	(wb_rst_pad_i),

		.done_o		(sd_loader_done_o),

		.wb_rst_o	(sd_loader_rst_o), // Control CPU reset pin
                                                                                
                // WISHBONE master interface
                .wb_adr_o	(sd_loader_adr_o),
                .wb_dat_o	(sd_loader_dat_o),
                .wb_dat_i	(sd_loader_dat_i),
                .wb_cyc_o	(sd_loader_cyc_o),
                .wb_stb_o	(sd_loader_stb_o),
                .wb_sel_o	(sd_loader_sel_o),
                .wb_we_o	(sd_loader_we_o),
                .wb_ack_i	(sd_loader_ack_i),
                .wb_err_i	(1'b0)
);
*/

//
// Internal SRAM
//

wire [31:0] wb_sram_dat_i;	
wire [31:0] wb_sram_dat_o;	
wire [31:0] wb_sram_addr_i;	
wire [3:0]  wb_sram_sel_i;	
wire        wb_sram_we_i;	
wire        wb_sram_cyc_i;	
wire        wb_sram_stb_i;	
wire        wb_sram_ack_o;	
wire        wb_sram_err_o;	

sram_top sram_top
  (
   .wb_clk_i ( clk_cpu_25 ),
   .wb_rst_i ( wb_rst_pad_i ),
   .wb_dat_i ( wb_sram_dat_i ),
   .wb_dat_o ( wb_sram_dat_o ),
   .wb_adr_i ( wb_sram_addr_i ),
   .wb_sel_i ( wb_sram_sel_i ),
   .wb_we_i  ( wb_sram_we_i ),
   .wb_cyc_i ( wb_sram_cyc_i ),
   .wb_stb_i ( wb_sram_stb_i ),
   .wb_ack_o ( wb_sram_ack_o ),
   .wb_err_o ( wb_sram_err_o )
   );
   
//
// OrSoC GFX
//

wire [31:0] wbm_gfx_w_dat_o;	
wire [31:0] wbm_gfx_w_addr_o;	
wire [3:0]  wbm_gfx_w_sel_o;	
wire        wbm_gfx_w_we_o;	
wire        wbm_gfx_w_cyc_o;	
wire        wbm_gfx_w_stb_o;	
wire        wbm_gfx_w_ack_i;	
wire        wbm_gfx_w_err_i;	

wire [31:0] wbm_gfx_r_dat_i;	
wire [31:0] wbm_gfx_r_addr_o;	
wire [3:0]  wbm_gfx_r_sel_o;	
wire        wbm_gfx_r_we_o;	
wire        wbm_gfx_r_cyc_o;	
wire        wbm_gfx_r_stb_o;	
wire        wbm_gfx_r_ack_i;	
wire        wbm_gfx_r_err_i;	

wire [31:0] wbs_gfx_dat_i;	
wire [31:0] wbs_gfx_dat_o;	
wire [31:0] wbs_gfx_addr_i;	
wire [3:0]  wbs_gfx_sel_i;	
wire        wbs_gfx_we_i;	
wire        wbs_gfx_cyc_i;	
wire        wbs_gfx_stb_i;	
wire        wbs_gfx_ack_o;	
wire        wbs_gfx_err_o;	

gfx_top gfx_top
  (
   .wb_clk_i ( clk_cpu_25 ),
   .wb_rst_i ( wb_rst_pad_i ),
   .wb_inta_o ( pic_ints[`APP_INT_UART] ),
   // Wishbone master signals (interfaces with video memory, write)
   .wbm_write_cyc_o ( wbm_gfx_w_cyc_o ), 
   .wbm_write_stb_o ( wbm_gfx_w_stb_o ),
   .wbm_write_cti_o ( ),
   .wbm_write_bte_o ( ),
   .wbm_write_we_o ( wbm_gfx_w_we_o ),
   .wbm_write_adr_o ( wbm_gfx_w_addr_o ),
   .wbm_write_sel_o ( wbm_gfx_w_sel_o ),
   .wbm_write_ack_i ( wbm_gfx_w_ack_i ),
   .wbm_write_err_i ( wbm_gfx_w_err_i ),
   .wbm_write_dat_o ( wbm_gfx_w_dat_o ),
   // Wishbone master signals (interfaces with video memory, read)
   .wbm_read_cyc_o ( wbm_gfx_r_cyc_o ),
   .wbm_read_stb_o ( wbm_gfx_r_stb_o ),
   .wbm_read_cti_o ( ),
   .wbm_read_bte_o ( ),
   .wbm_read_we_o ( wbm_gfx_r_we_o ),
   .wbm_read_adr_o ( wbm_gfx_r_addr_o ),
   .wbm_read_sel_o ( wbm_gfx_r_sel_o ),
   .wbm_read_ack_i ( wbm_gfx_r_ack_i ),
   .wbm_read_err_i ( wbm_gfx_r_err_i ),
   .wbm_read_dat_i ( wbm_gfx_r_dat_i ),
   // Wishbone slave signals (interfaces with main bus/CPU)
   .wbs_cyc_i ( wbs_gfx_cyc_i ),
   .wbs_stb_i ( wbs_gfx_stb_i ),
   .wbs_cti_i ( ),
   .wbs_bte_i ( ),
   .wbs_we_i ( wbs_gfx_we_i ),
   .wbs_adr_i ( wbs_gfx_addr_i ),
   .wbs_sel_i ( wbs_gfx_sel_i ),
   .wbs_ack_o ( wbs_gfx_ack_o ),
   .wbs_err_o ( wbs_gfx_err_o ),
   .wbs_dat_i ( wbs_gfx_dat_i ),
   .wbs_dat_o ( wbs_gfx_dat_o )
);

//
// inter connect
//
wb_conmax_top #(
	32,	// Dada Bus width
	32,	// Address Bus width
	4'hf,	// Registerr File Address
	2'h1,	// Number of priorities for Slave 0
	2'h1	// Number of priorities for Slave 1
	//Priorities for Slave 2 through 15 will default to 2’h2
	) intcon0
  (
   
   .clk_i		(clk_cpu_25),
   .rst_i		(wb_rst_pad_i),
   
   // Master 0 Interface.  Connect to or32 IWB   OR1K
   .m0_data_i	(or1k_iwb_dat_o),
   .m0_data_o	(or1k_iwb_dat_i),
   .m0_addr_i	(or1k_iwb_adr_o),
   .m0_sel_i	(or1k_iwb_sel_o),
   .m0_we_i	(or1k_iwb_we_o),
   .m0_cyc_i	(or1k_iwb_cyc_o),
   .m0_stb_i	(or1k_iwb_stb_o),
   .m0_ack_o	(or1k_iwb_ack_i),
   .m0_err_o	(or1k_iwb_err_i),
   .m0_rty_o	(or1k_iwb_rty_i),
   
   // Master 1 Interface. Connect to or32 DWB
   .m1_data_i	(or1k_dwb_dat_o),
   .m1_data_o	(or1k_dwb_dat_i),
   .m1_addr_i	(or1k_dwb_adr_o),
   .m1_sel_i	(or1k_dwb_sel_o),
   .m1_we_i	(or1k_dwb_we_o),
   .m1_cyc_i	(or1k_dwb_cyc_o),
   .m1_stb_i	(or1k_dwb_stb_o),
   .m1_ack_o	(or1k_dwb_ack_i),
   .m1_err_o	(or1k_dwb_err_i),
   .m1_rty_o	(or1k_dwb_rty_i),
   
   // Master 2 Interface. For Ethernet Master Port
   .m2_data_i	(wb_em_dat_o),
   .m2_data_o	(wb_em_dat_i),
   .m2_addr_i	(wb_em_adr_o),
   .m2_sel_i	(wb_em_sel_o),
   .m2_we_i	(wb_em_we_o),
   .m2_cyc_i	(wb_em_cyc_o),
   .m2_stb_i	(wb_em_stb_o),
   .m2_ack_o	(wb_em_ack_i),
   .m2_err_o	(wb_em_err_i),
   .m2_rty_o	(),
   
   // Master 3 Interface. for Advanced Debug Interface
   .m3_data_i	(dbg_wb_dat_o),
   .m3_data_o	(dbg_wb_dat_i),
   .m3_addr_i	(dbg_wb_adr_o),
   .m3_sel_i	(dbg_wb_sel_o),
   .m3_we_i	(dbg_wb_we_o),
   .m3_cyc_i	(dbg_wb_cyc_o),
   .m3_stb_i	(dbg_wb_stb_o),
   .m3_ack_o	(dbg_wb_ack_i),
   .m3_err_o	(dbg_wb_err_i),
   .m3_rty_o	(),
   
   // Master 4 Interface (GFX Write master)
   .m4_data_i ( wbm_gfx_w_dat_o ),
   .m4_data_o ( ),
   .m4_addr_i ( wbm_gfx_w_addr_o ),
   .m4_sel_i ( wbm_gfx_w_sel_o ),
   .m4_we_i ( wbm_gfx_w_we_o ),
   .m4_cyc_i ( wbm_gfx_w_cyc_o ),
   .m4_stb_i ( wbm_gfx_w_stb_o ),
   .m4_ack_o ( wbm_gfx_w_ack_i ),
   .m4_err_o ( wbm_gfx_w_err_i ),
   .m4_rty_o ( ),
   
   // Master 5 Interface (GFX read master)
   .m5_data_i ( ),
   .m5_data_o ( wbm_gfx_r_dat_i ),
   .m5_addr_i ( wbm_gfx_r_addr_o ),
   .m5_sel_i ( wbm_gfx_r_sel_o ),
   .m5_we_i ( wbm_gfx_r_we_o ),
   .m5_cyc_i ( wbm_gfx_r_cyc_o ),
   .m5_stb_i ( wbm_gfx_r_stb_o ),
   .m5_ack_o ( wbm_gfx_r_ack_i ),
   .m5_err_o ( wbm_gfx_r_err_i ),
   .m5_rty_o (),
   
/*
   // Master 6 Interface
   m6_data_i, m6_data_o, m6_addr_i, m6_sel_i, m6_we_i, m6_cyc_i,
   m6_stb_i, m6_ack_o, m6_err_o, m6_rty_o,
   
   // Master 7 Interface. For SD Loader
   .m7_data_i	(sd_loader_dat_o),
   .m7_data_o	(sd_loader_dat_i),
   .m7_addr_i	(sd_loader_adr_o),
   .m7_sel_i	(sd_loader_sel_o),
   .m7_we_i	(sd_loader_we_o),
   .m7_cyc_i	(sd_loader_cyc_o),
   .m7_stb_i	(sd_loader_stb_o),
   .m7_ack_o	(sd_loader_ack_i),
   .m7_err_o	(),
   .m7_rty_o	(),
*/

   // Slave 0 Interface. connect to memory controller
   .s0_data_i	(mem_if_wb_data_o),
   .s0_data_o	(mem_if_wb_data_i),
   .s0_addr_o	(mem_if_wb_addr_i),
   .s0_sel_o	(mem_if_wb_sel_i),
   .s0_we_o	(mem_if_wb_we_i),
   .s0_cyc_o	(mem_if_wb_cyc_i),
   .s0_stb_o	(mem_if_wb_stb_i),
   .s0_ack_i	(mem_if_wb_ack_o),
   .s0_err_i	(mem_if_wb_err_o),
   .s0_rty_i	(1'b0),
   
   
   // Slave 1 Interface. SPI0 for flash
   .s1_data_i      (wbs_spi_0_dat_o),
   .s1_data_o	(wbs_spi_0_dat_i),
   .s1_addr_o	(wbs_spi_0_adr_i),
   .s1_sel_o	(wbs_spi_0_sel_i),
   .s1_we_o	(wbs_spi_0_we_i),
   .s1_cyc_o	(wbs_spi_0_cyc_i),
   .s1_stb_o	(wbs_spi_0_stb_i),
   .s1_ack_i	(wbs_spi_0_ack_o),
   .s1_err_i	(wbs_spi_0_err_o),
   .s1_rty_i	(1'b0),
   
   // Slave 2 Interface. connect to ethernet
   .s2_data_i	(wb_es_dat_o),
   .s2_data_o	(wb_es_dat_i),
   .s2_addr_o	(wb_es_adr_i),
   .s2_sel_o	(wb_es_sel_i),
   .s2_we_o	(wb_es_we_i),
   .s2_cyc_o	(wb_es_cyc_i),
   .s2_stb_o	(wb_es_stb_i),
   .s2_ack_i	(wb_es_ack_o),
   .s2_err_i	(wb_es_err_o),
   .s2_rty_i	(1'b0),
   
   // Slave 3 Interface. connect to uart
   .s3_data_i	(wb_us_dat_o),
   .s3_data_o	(wb_us_dat_i),
   .s3_addr_o	(wb_us_adr_i),
   .s3_sel_o	(wb_us_sel_i),
   .s3_we_o	(wb_us_we_i),
   .s3_cyc_o	(wb_us_cyc_i),
   .s3_stb_o	(wb_us_stb_i),
   .s3_ack_i	(wb_us_ack_o),
   .s3_err_i	(1'b0),
   .s3_rty_i	(1'b0),
   
   // Slave 4 Interface. connect to GPIO
   .s4_data_i	(wbs_gpio_dat_o),
   .s4_data_o	(wbs_gpio_dat_i),
   .s4_addr_o	(wbs_gpio_adr_i),
   .s4_sel_o	(wbs_gpio_sel_i),
   .s4_we_o	(wbs_gpio_we_i),
   .s4_cyc_o	(wbs_gpio_cyc_i),
   .s4_stb_o	(wbs_gpio_stb_i),
   .s4_ack_i	(wbs_gpio_ack_o),
   .s4_err_i	(wbs_gpio_err_o),
   .s4_rty_i	(1'b0),
   
   // Slave 5 Interface. spiMaster for SD Card
   .s5_data_i	(32'h0000_0000),
   .s5_data_o	(),
   .s5_addr_o	(),
   .s5_sel_o	(),
   .s5_we_o	(),
   .s5_cyc_o	(),
   .s5_stb_o	(),
   .s5_ack_i	(1'b0),
   .s5_err_i	(1'b1),
   .s5_rty_i	(1'b0),
   
   // Slave 6 Interface (GFX Slave)
   .s6_data_i	( wbs_gfx_dat_o ),
   .s6_data_o	( wbs_gfx_dat_i ),
   .s6_addr_o	( wbs_gfx_addr_i ),
   .s6_sel_o	( wbs_gfx_sel_i ),
   .s6_we_o	( wbs_gfx_we_i ),
   .s6_cyc_o	( wbs_gfx_cyc_i ),
   .s6_stb_o	( wbs_gfx_stb_i ),
   .s6_ack_i	( wbs_gfx_ack_o ),
   .s6_err_i	( wbs_gfx_err_o ),
   .s6_rty_i	(1'b0),
   
   // Slave 7 Interface
   .s7_data_i	(32'h0000_0000),
   .s7_data_o	(),
   .s7_addr_o	(),
   .s7_sel_o	(),
   .s7_we_o	(),
   .s7_cyc_o	(),
   .s7_stb_o	(),
   .s7_ack_i	(1'b0),
   .s7_err_i	(1'b1),
   .s7_rty_i	(1'b0),
   
   // Slave 8 Interface
   .s8_data_i	(32'h0000_0000),
   .s8_data_o	(),
   .s8_addr_o	(),
   .s8_sel_o	(),
   .s8_we_o	(),
   .s8_cyc_o	(),
   .s8_stb_o	(),
   .s8_ack_i	(1'b0),
   .s8_err_i	(1'b1),
   .s8_rty_i	(1'b0),
   
   // Slave 9 Interface
   .s9_data_i	(32'h0000_0000),
   .s9_data_o	(),
   .s9_addr_o	(),
   .s9_sel_o	(),
   .s9_we_o	(),
   .s9_cyc_o	(),
   .s9_stb_o	(),
   .s9_ack_i	(1'b0),
   .s9_err_i	(1'b1),
   .s9_rty_i	(1'b0),
   
   // Slave 10 Interface
   .s10_data_i	(32'h0000_0000),
   .s10_data_o	(),
   .s10_addr_o	(),
   .s10_sel_o	(),
   .s10_we_o	(),
   .s10_cyc_o	(),
   .s10_stb_o	(),
   .s10_ack_i	(1'b0),
   .s10_err_i	(1'b1),
   .s10_rty_i	(1'b0),
   
   // Slave 11 Interface
   .s11_data_i	(32'h0000_0000),
   .s11_data_o	(),
   .s11_addr_o	(),
   .s11_sel_o	(),
   .s11_we_o	(),
   .s11_cyc_o	(),
   .s11_stb_o	(),
   .s11_ack_i	(1'b0),
   .s11_err_i	(1'b1),
   .s11_rty_i	(1'b0),
   
   .s12_data_i	(32'h0000_0000),
   .s12_data_o	(),
   .s12_addr_o	(),
   .s12_sel_o	(),
   .s12_we_o	(),
   .s12_cyc_o	(),
   .s12_stb_o	(),
   .s12_ack_i	(1'b0),
   .s12_err_i	(1'b1),
   .s12_rty_i	(1'b0),
   
   // Slave 13 Interface
   .s13_data_i	(32'h0000_0000),
   .s13_data_o	(),
   .s13_addr_o	(),
   .s13_sel_o	(),
   .s13_we_o	(),
   .s13_cyc_o	(),
   .s13_stb_o	(),
   .s13_ack_i	(1'b0),
   .s13_err_i	(1'b1),
   .s13_rty_i	(1'b0),
   
   // Slave 14 Interface
   .s14_data_i	( wb_sram_dat_o ),
   .s14_data_o	( wb_sram_dat_i ),
   .s14_addr_o	( wb_sram_addr_i),
   .s14_sel_o	( wb_sram_sel_i ),
   .s14_we_o	( wb_sram_we_i ),
   .s14_cyc_o	( wb_sram_cyc_i ),
   .s14_stb_o	( wb_sram_stb_i ),
   .s14_ack_i	( wb_sram_ack_o ),
   .s14_err_i	( wb_sram_err_o ),
   .s14_rty_i	(1'b0),
   
   // Slave 15 Interface  - Flash
   .s15_data_i	( wb_fs_dat_o ),
   .s15_data_o	( wb_fs_dat_i ),
   .s15_addr_o	( wb_fs_adr_i ),
   .s15_sel_o	( wb_fs_sel_i ),
   .s15_we_o	( wb_fs_we_i ),
   .s15_cyc_o	( wb_fs_cyc_i ),
   .s15_stb_o	( wb_fs_stb_i ),
   .s15_ack_i	( wb_fs_ack_o ),
   .s15_err_i	( wb_fs_err_o ),
   .s15_rty_i	(1'b0)
   
   );

endmodule

