//===============================================================================
//
//          FILE:  CPUboard_tb.v
// 
//         USAGE:  ./CPUboard_tb.v 
// 
//   DESCRIPTION:  Top of test branch
// 
//       OPTIONS:  ---
//  REQUIREMENTS:  ---
//          BUGS:  ---
//         NOTES:  ---
//        AUTHOR:  Xianfeng Zeng (ZXF), xianfeng.zeng@gmail.com
//                                      xianfeng.zeng@gmail.com
//       COMPANY:  
//       VERSION:  1.0
//       CREATED:  04/05/2009 07:54:54 PM HKT
//      REVISION:  ---
//===============================================================================

`timescale 1ns/10ps
`include "bench_defines.v"
`include "or1200_defines.v"

module CPUboard_tb ();

integer	counter;

reg	clk, rstn, pll_rstn;

// Signals for generic_pll
wire	mc_clk;
wire	wb_clk;
wire	flash_clk;
wire	pll_lock;

wire		flash_rstn;
wire		flash_oen;
wire		flash_cen;
wire		flash_wen;
wire		flash_rdy;
wire [7:0]	flash_d;
wire [20:0]	flash_a;
wire [31:0]	flash_vpp;		// Special flash inputs
wire [31:0]	flash_vcc;		// Special flash inputs
wire [1:0]	flash_rpblevel;		// Special flash inputs


/*
	reg [12:0]  a;
	reg [1:0]   ba;
	reg         cke, csn;
	wire        wen, rasn, casn;
	wire [15:0] dq;
	reg [1:0]   dqm;
*/
	wire [31:0] mem_dat_pad_io;
	wire [12:0] mem_adr_pad_o;
	wire [1:0]  mem_ba_pad_o;
	wire [3:0]  mem_dqm_pad_o;

	wire [31:0] gpio_pad_io;

//	wire [8:0]  iob;

//	wire        spi2_mosi, spi2_miso, spi2_ss, spi2_sclk;


	//
	// Put the informat here to make someboday know what happen
	//
	initial begin

`ifdef CONFIG_USE_SRAM
		$display("\n\nCurrently, Slave0 is connecting to SRAM, not Memory Controller!!");
		$display("If you want to use MC to drive the SDRAM, comment macro CONFIG_USE_SRAM in bench_defines.v");
`endif

		if (`OR1200_SR_EPH_DEF == 1'b0) begin
			$display("\n\nOR1k reset ventor = 0x100");
		end else begin
			$display("\n\nOR1k reset ventor = 0xf00000100");
		end
		$display("To change the reset ventor, mondify OR1200_SR_EPH_DEF in rtl/or1200/rtl/verilog/or1200_defines.v");
		$display("\n\n");

	end


	initial begin
`ifdef LXT
		$dumpfile("wavedump.lxt");
		$dumpvars(10, CPUboard_tb );
`endif
`ifdef VCD
		$dumpfile("wavedump.vcd");
		$dumpvars(10, CPUboard_tb );
`endif

	end

	initial
	begin
		#0 clk = 1'b0;
		forever
		#20 clk = !clk;   // 25MHz
	end

	initial
	begin
		rstn <= 1'b1;  
		#5  rstn <= 1'b0;
		#500 rstn <= 1'b1;
	end

	initial
	begin
		pll_rstn <= 1'b1;  
		#5  pll_rstn <= 1'b0;
		#15 pll_rstn <= 1'b1;
	end


	//    
	// CLKs Genericed
	// clk2x goes to wishbone clock (wb_clk), clk1x to memory contr.
	// Unsure if flash_clk used
	//
	defparam	iclk_gen.DIVIDER=2.4;
	generic_pll iclk_gen (   
		// If we're using the new SDRAM controller we 
		// want wb_clk to be 2xmc_clk, and if using the
		// old one we want everything to be on same freq
		.clk1x		(mc_clk),
		.clk2x		(wb_clk),
		.clkdiv		(flash_clk),
		.locked		(pll_lock),

		//Input
		.clk_in		(clk),
		.rst_in		(~pll_rstn)
	); 
//
//==================================================================
//
	or1k_soc_top soc0 (
         	// Clk and reset
		.wb_clk_pad_i		(wb_clk),
		.rst_n_pad_i		(rstn),

		.mc_clk_pad_i		(mc_clk),
		.flash_clk_pad_i	(flash_clk),

		.flash_rstn		(flash_rstn),
		.flash_cen		(flash_cen),
		.flash_oen		(flash_oen),
		.flash_wen		(flash_wen),
		.flash_rdy		(flash_rdy),
		.flash_d		(flash_d),
		.flash_a		(flash_a),

		// Memory Controller 
		.mem_dat_pad_io         (mem_dat_pad_io),
		.mem_adr_pad_o          (mem_adr_pad_o[12:0]),
		.mem_dqm_pad_o          (mem_dqm_pad_o[3:0]),
		.mem_ba_pad_o           (mem_ba_pad_o[1:0]),
		.mem_cs_pad_o           (mem_cs_pad_o),
		.mem_ras_pad_o          (mem_ras_pad_o),
		.mem_cas_pad_o          (mem_cas_pad_o),
		.mem_we_pad_o           (mem_we_pad_o),
		.mem_cke_pad_o          (mem_cke_pad_o),

		// SPI_FLASH
		.spi_flash_sclk_pad_o   (spi_flash_sclk_pad_o),
		.spi_flash_ss_pad_o     (spi_flash_ss_pad_o),
		.spi_flash_miso_pad_i   (spi_flash_miso_pad_i),
		.spi_flash_mosi_pad_o   (spi_flash_mosi_pad_o),  
		.spi_flash_w_n_pad_o    (spi_flash_w_n_pad_o),
		.spi_flash_hold_n_pad_o (spi_flash_hold_n_pad_o),
		
/*
		// SPI1
		.spi_mmc_sclk_pad_o     (spi_mmc_sclk_pad_o),
		.spi_mmc_ss_pad_o       (spi_mmc_ss_pad_o),
		.spi_mmc_miso_pad_i     (spi_mmc_mosi_pad_o),
		.spi_mmc_mosi_pad_o     (spi_mmc_mosi_pad_o),
*/	
		// GPIO
		.gpio_a_pad_io          (gpio_pad_io),

		// UART0
		.uart_srx_pad_i		(1'b1),  
		.uart_stx_pad_o		(uart_stx_pad_o)
/*
		// JTAG
		.dbg_tdi_pad_i          (1'b0),
		.dbg_tck_pad_i          (1'b0),
		.dbg_tms_pad_i          (1'b0),  
		.dbg_tdo_pad_o          (dbg_tdo),
		.iob                    (iob)
*/
         );


 	 always @(posedge clk) begin
		if (gpio_pad_io[7:0] == 8'hff) begin
			// 0xff has been written to GPIO, so the
			// sofware has completed its tests
			$display("Software execution complete.");
			$finish();
		end else if (gpio_pad_io[7:0] == 8'h55) begin
			// 0x55 has been written to GPIO, so the
			// there was an error during the tests
			$display("***Error during software tests. Finishing simulation.");
			$finish();
		end
	end   


	always @(posedge clk or rstn) begin
		if (!rstn) begin
			counter = 0;
		end
	   else begin
	      if (counter == 5000) begin
		 $display("Completed");
//		 Flash.StoreToFile;
		 
		 $finish();
	      end
	      counter = counter + 1;
	   end
	   
	end

// The Flash RAM

assign flash_vpp = 32'h00002ee0;
assign flash_vcc = 32'h00001388;
assign flash_rpblevel = 2'b10;

i28f016s3 Flash (
        .rpb( flash_rstn ),
        .ceb( flash_cen ),
        .oeb( flash_oen ),
        .web( flash_wen ),
        .ryby( flash_rdy ),
        .dq( flash_d ),
        .addr( flash_a ),
	.vpp( flash_vpp ),
	.vcc( flash_vcc ),
	.rpblevel( flash_rpblevel )
);


// This model contains actual timing  MT48LC16M16B2  (4 Meg x 16 x 4 banks)
mt48lc16m16a2 i_sdram0(
	.Dq    (mem_dat_pad_io[15:0]),
	.Addr  (mem_adr_pad_o[12:0]),
	.Ba    (mem_ba_pad_o[1:0]),
	.Clk   (clk),
	.Cke   (mem_cke_pad_o),
	.Cs_n  (mem_cs_pad_o),
	.Ras_n (mem_ras_pad_o),
	.Cas_n (mem_cas_pad_o),
	.We_n  (mem_we_pad_o),
	.Dqm   (mem_dqm_pad_o[1:0])
);

mt48lc16m16a2 i_sdram1(
	.Dq    (mem_dat_pad_io[31:16]),
	.Addr  (mem_adr_pad_o[12:0]),
	.Ba    (mem_ba_pad_o[1:0]),
	.Clk   (clk),
	.Cke   (mem_cke_pad_o),
	.Cs_n  (mem_cs_pad_o),
	.Ras_n (mem_ras_pad_o),
	.Cas_n (mem_cas_pad_o),
	.We_n  (mem_we_pad_o),
	.Dqm   (mem_dqm_pad_o[3:2])
);


  
   defparam CPUboard_tb.i_spi_flash.MEMORY_FILE="memory.txt";
     
   AT26DFxxx i_spi_flash(
       .CSB    (spi_flash_ss_pad_o),
       .SCK    (spi_flash_sclk_pad_o),
       .SI     (spi_flash_mosi_pad_o),
       .WPB    (spi_flash_w_n_pad_o),
       .SO     (spi_flash_miso_pad_i)
       );



   pulldown(gpio_pad_io[0]);
   pulldown(gpio_pad_io[1]);
   pulldown(gpio_pad_io[2]);
   pulldown(gpio_pad_io[3]);
   pulldown(gpio_pad_io[4]);
   pulldown(gpio_pad_io[5]);
   pulldown(gpio_pad_io[6]);
   pulldown(gpio_pad_io[7]);
   pulldown(gpio_pad_io[8]);
   pulldown(gpio_pad_io[9]);
   pulldown(gpio_pad_io[10]);
   pulldown(gpio_pad_io[11]);
   pulldown(gpio_pad_io[12]);
   pulldown(gpio_pad_io[13]);
   pulldown(gpio_pad_io[14]);
   pulldown(gpio_pad_io[15]);
   pulldown(gpio_pad_io[16]);
   pulldown(gpio_pad_io[17]);
   pulldown(gpio_pad_io[18]);
   pulldown(gpio_pad_io[19]);
   pulldown(gpio_pad_io[20]);
   pulldown(gpio_pad_io[21]);
   pulldown(gpio_pad_io[22]);
   pulldown(gpio_pad_io[23]);
   pulldown(gpio_pad_io[24]);
   pulldown(gpio_pad_io[25]);
   pulldown(gpio_pad_io[26]);
   pulldown(gpio_pad_io[27]);
   pulldown(gpio_pad_io[28]);
   pulldown(gpio_pad_io[29]);
   pulldown(gpio_pad_io[30]);
   pulldown(gpio_pad_io[31]);

endmodule
