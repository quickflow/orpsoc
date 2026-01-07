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
   
   reg		clk, rstn, rstn_dly, pll_rstn, d2d_clk, d2d_rstn;
   
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
`ifdef VCS
	   $fsdbDumpfile("wavedump.fsdb");
      $fsdbDumpvars(10, CPUboard_tb );
`else
	   $dumpfile("wavedump.lxt");
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
	#0 d2d_clk = 1'b0;
	forever
	  #23 d2d_clk = !d2d_clk;   // 25MHz
     end
   
   initial
     begin
	rstn <= 1'b1;  
	#5  rstn <= 1'b0;
	#500 rstn <= 1'b1;
     end
   
   initial
     begin
	rstn_dly <= 1'b1;  
	#75  rstn_dly <= 1'b0;
	#575 rstn_dly <= 1'b1;
     end
   
   initial
     begin
	d2d_rstn <= 1'b1;  
	#3  d2d_rstn <= 1'b0;
	#503  d2d_rstn <= 1'b1;
     end
   
   initial
     begin
	pll_rstn <= 1'b1;  
	#5  pll_rstn <= 1'b0;
	#15 pll_rstn <= 1'b1;
     end
   
   //==================================================================
   //==================================================================
   //==================================================================
   // CHIP instance 0
   //==================================================================
   //==================================================================
   //==================================================================

   integer	counter0;
   
   // Signals for generic_pll
   wire		c0_mc_clk;
   wire		c0_wb_clk;
   wire		c0_flash_clk;
   wire		c0_pll_lock;
   
   wire		c0_flash_rstn;
   wire		c0_flash_oen;
   wire		c0_flash_cen;
   wire		c0_flash_wen;
   wire		c0_flash_rdy;
   wire [7:0]	c0_flash_d;
   wire [20:0]	c0_flash_a;
   wire [31:0]	c0_flash_vpp;		// Special flash inputs
   wire [31:0]	c0_flash_vcc;		// Special flash inputs
   wire [1:0]	c0_flash_rpblevel;		// Special flash inputs
   
   
   /*
    reg [12:0]  a;
    reg [1:0]   ba;
    reg         cke, csn;
    wire        wen, rasn, casn;
    wire [15:0] dq;
    reg [1:0]   dqm;
    */
   wire [31:0]	c0_mem_dat_pad_io;
   wire [12:0]	c0_mem_adr_pad_o;
   wire [1:0]	c0_mem_ba_pad_o;
   wire [3:0]	c0_mem_dqm_pad_o;
   
   wire [31:0]	c0_gpio_pad_io;
   
   // D2D
   wire [63:0]	c01_d2d_tx_data;
   wire		c01_d2d_tx_valid;
   wire		c01_d2d_rx_ready;

   wire [63:0]	c02_d2d_tx_data;
   wire		c02_d2d_tx_valid;
   wire		c02_d2d_rx_ready;

   wire [63:0]	c03_d2d_tx_data;
   wire		c03_d2d_tx_valid;
   wire		c03_d2d_rx_ready;
   
   // D2D
   wire [63:0]	c10_d2d_tx_data;
   wire		c10_d2d_tx_valid;
   wire		c10_d2d_rx_ready;

   wire [63:0]	c12_d2d_tx_data;
   wire		c12_d2d_tx_valid;
   wire		c12_d2d_rx_ready;

   wire [63:0]	c13_d2d_tx_data;
   wire		c13_d2d_tx_valid;
   wire		c13_d2d_rx_ready;
   
   // D2D
   wire [63:0]	c20_d2d_tx_data;
   wire		c20_d2d_tx_valid;
   wire		c20_d2d_rx_ready;

   wire [63:0]	c21_d2d_tx_data;
   wire		c21_d2d_tx_valid;
   wire		c21_d2d_rx_ready;

   wire [63:0]	c23_d2d_tx_data;
   wire		c23_d2d_tx_valid;
   wire		c23_d2d_rx_ready;
   
   // D2D
   wire [63:0]	c30_d2d_tx_data;
   wire		c30_d2d_tx_valid;
   wire		c30_d2d_rx_ready;

   wire [63:0]	c32_d2d_tx_data;
   wire		c32_d2d_tx_valid;
   wire		c32_d2d_rx_ready;

   wire [63:0]	c31_d2d_tx_data;
   wire		c31_d2d_tx_valid;
   wire		c31_d2d_rx_ready;
   
   assign c0_wb_clk = clk;
   wire c01_d2d_clk = d2d_clk;
   wire	c01_d2d_rst_n = d2d_rstn;
   wire c02_d2d_clk = d2d_clk;
   wire	c02_d2d_rst_n = d2d_rstn;
   wire c03_d2d_clk = d2d_clk;
   wire	c03_d2d_rst_n = d2d_rstn;
   
   or1k_soc_top soc0
     (
      // Clk and reset
      .wb_clk_pad_i		(c0_wb_clk),
      .rst_n_pad_i		(rstn),
      
      .mc_clk_pad_o		(c0_dram_clk),
      //		.mc_clk_pad_i		(mc_clk),
      //		.flash_clk_pad_i	(flash_clk),
      
      .flash_rstn		(c0_flash_rstn),
      .flash_cen		(c0_flash_cen),
      .flash_oen		(c0_flash_oen),
      .flash_wen		(c0_flash_wen),
      .flash_rdy		(c0_flash_rdy),
      .flash_d		        (c0_flash_d),
      .flash_a		        (c0_flash_a),
      
      // Memory Controller 
      .mem_dat_pad_io         (c0_mem_dat_pad_io),
      .mem_adr_pad_o          (c0_mem_adr_pad_o[12:0]),
      .mem_dqm_pad_o          (c0_mem_dqm_pad_o[3:0]),
      .mem_ba_pad_o           (c0_mem_ba_pad_o[1:0]),
      .mem_cs_pad_o           (c0_mem_cs_pad_o),
      .mem_ras_pad_o          (c0_mem_ras_pad_o),
      .mem_cas_pad_o          (c0_mem_cas_pad_o),
      .mem_we_pad_o           (c0_mem_we_pad_o),
      .mem_cke_pad_o          (c0_mem_cke_pad_o),
      
      // SPI_FLASH
      .spi_flash_sclk_pad_o   (c0_spi_flash_sclk_pad_o),
      .spi_flash_ss_pad_o     (c0_spi_flash_ss_pad_o),
      .spi_flash_miso_pad_i   (c0_spi_flash_miso_pad_i),
      .spi_flash_mosi_pad_o   (c0_spi_flash_mosi_pad_o),  
      .spi_flash_w_n_pad_o    (c0_spi_flash_w_n_pad_o),
      .spi_flash_hold_n_pad_o (c0_spi_flash_hold_n_pad_o),
      
      /*
       // SPI1
       .spi_mmc_sclk_pad_o     (spi_mmc_sclk_pad_o),
       .spi_mmc_ss_pad_o       (spi_mmc_ss_pad_o),
       .spi_mmc_miso_pad_i     (spi_mmc_mosi_pad_o),
       .spi_mmc_mosi_pad_o     (spi_mmc_mosi_pad_o),
       */	
      // GPIO
      .gpio_a_pad_io          (c0_gpio_pad_io),
      
      // UART0
      .uart_srx_pad_i		(1'b1),  
      .uart_stx_pad_o		(c0_uart_stx_pad_o),

      .d2d0_clk                (c01_d2d_clk),
      .d2d0_rst_n              (c01_d2d_rst_n),
      .d2d0_tx_data            (c01_d2d_tx_data),
      .d2d0_tx_valid           (c01_d2d_tx_valid),
      .d2d0_tx_ready           (c10_d2d_rx_ready),
      .d2d0_rx_data            (c10_d2d_tx_data),
      .d2d0_rx_valid           (c10_d2d_tx_valid),
      .d2d0_rx_ready           (c01_d2d_rx_ready),

      .d2d1_clk                (c02_d2d_clk),
      .d2d1_rst_n              (c02_d2d_rst_n),
      .d2d1_tx_data            (c02_d2d_tx_data),
      .d2d1_tx_valid           (c02_d2d_tx_valid),
      .d2d1_tx_ready           (c20_d2d_rx_ready),
      .d2d1_rx_data            (c20_d2d_tx_data),
      .d2d1_rx_valid           (c20_d2d_tx_valid),
      .d2d1_rx_ready           (c02_d2d_rx_ready),

      .d2d2_clk                (c03_d2d_clk),
      .d2d2_rst_n              (c03_d2d_rst_n),
      .d2d2_tx_data            (c03_d2d_tx_data),
      .d2d2_tx_valid           (c03_d2d_tx_valid),
      .d2d2_tx_ready           (c30_d2d_rx_ready),
      .d2d2_rx_data            (c30_d2d_tx_data),
      .d2d2_rx_valid           (c30_d2d_tx_valid),
      .d2d2_rx_ready           (c03_d2d_rx_ready),

      .cpuID                  (8'h00)
      
      /*
       // JTAG
       .dbg_tdi_pad_i          (1'b0),
       .dbg_tck_pad_i          (1'b0),
       .dbg_tms_pad_i          (1'b0),  
       .dbg_tdo_pad_o          (dbg_tdo),
       .iob                    (iob)
       */
      );
   
   
   reg [31:0] old_c0_gpio_val;
   
   always @(posedge clk) begin
      old_c0_gpio_val <= c0_gpio_pad_io;
      if (old_c0_gpio_val != c0_gpio_pad_io)
	$display("[%m]C0 GPIO val = %h", c0_gpio_pad_io);
      
      if (c0_gpio_pad_io == 32'hc001c0de) begin
	 // 0xff has been written to GPIO, so the
	 // sofware has completed its tests
	 $display("\n\n**** PASS C0 **** indicator for Software execution complete.\n\n");
//	 $fflush(uart_mon0.fd);
	 //	       repeat(1000000) @(posedge clk);
	 $finish();
      end else if (c0_gpio_pad_io == 32'hdeadbeef) begin
	 // 0x55 has been written to GPIO, so the
	 // there was an error during the tests
	 $display("\n\n**** FAIL C0 **** indicator during Software tests. Finishing simulation.");
//	 $fflush(uart_mon0.fd);
	 repeat(1000000) @(posedge clk);
	 $finish();
      end
   end   
   
   
   always @(posedge clk or posedge rstn) begin
      if (!rstn) begin
	 counter0 = 0;
      end
      else begin
	 if (counter0 == 20000000) begin
	    $display("Completed");
	    //		 Flash.StoreToFile;
	    
//	    $fflush(uart_mon0.fd);
	    $finish();
	 end
	 counter0 = counter0 + 1;
      end
      
   end
   
   // The Flash RAM
   
   assign c0_flash_vpp = 32'h00002ee0;
   assign c0_flash_vcc = 32'h00001388;
   assign c0_flash_rpblevel = 2'b10;
   
   i28f016s3 Flash0
     (
      .rpb( c0_flash_rstn ),
      .ceb( c0_flash_cen ),
      .oeb( c0_flash_oen ),
      .web( c0_flash_wen ),
      .ryby( c0_flash_rdy ),
      .dq( c0_flash_d ),
      .addr( c0_flash_a ),
      .vpp( c0_flash_vpp ),
      .vcc( c0_flash_vcc ),
      .rpblevel( c0_flash_rpblevel )
      );
   
   
   // This model contains actual timing  MT48LC16M16B2  (4 Meg x 16 x 4 banks)
   mt48lc16m16a2_model i_sdram00
     (
      .DQ    (c0_mem_dat_pad_io[15:0]),
      .A     (c0_mem_adr_pad_o[12:0]),
      .BA    (c0_mem_ba_pad_o[1:0]),
      .CLK   (c0_dram_clk),
      .CKE   (c0_mem_cke_pad_o),
      .CS_N  (c0_mem_cs_pad_o),
      .RAS_N (c0_mem_ras_pad_o),
      .CAS_N (c0_mem_cas_pad_o),
      .WE_N  (c0_mem_we_pad_o),
      .DQM   (c0_mem_dqm_pad_o[1:0])
      );
   
   mt48lc16m16a2_model i_sdram01
     (
      .DQ    (c0_mem_dat_pad_io[31:16]),
      .A     (c0_mem_adr_pad_o[12:0]),
      .BA    (c0_mem_ba_pad_o[1:0]),
      .CLK   (c0_dram_clk),
      .CKE   (c0_mem_cke_pad_o),
      .CS_N  (c0_mem_cs_pad_o),
      .RAS_N (c0_mem_ras_pad_o),
      .CAS_N (c0_mem_cas_pad_o),
      .WE_N  (c0_mem_we_pad_o),
      .DQM   (c0_mem_dqm_pad_o[3:2])
      );
   
   
   uart_mon uart_mon0
     (
      .clk (clk), // System clock
      .reset (~rstn), // Reset signal
      .rx (c0_uart_stx_pad_o),
      .monID (8'h00)
      );
   
   // //   
       defparam CPUboard_tb.i_spi_flash0.MEMORY_FILE="memory.txt";
   
   AT26DFxxx i_spi_flash0
     (
      .CSB    (c0_spi_flash_ss_pad_o),
      .SCK    (c0_spi_flash_sclk_pad_o),
      .SI     (c0_spi_flash_mosi_pad_o),
      .WPB    (c0_spi_flash_w_n_pad_o),
      .SO     (c0_spi_flash_miso_pad_i)
      );
   
   
   
   pulldown(c0_gpio_pad_io[0]);
   pulldown(c0_gpio_pad_io[1]);
   pulldown(c0_gpio_pad_io[2]);
   pulldown(c0_gpio_pad_io[3]);
   pulldown(c0_gpio_pad_io[4]);
   pulldown(c0_gpio_pad_io[5]);
   pulldown(c0_gpio_pad_io[6]);
   pulldown(c0_gpio_pad_io[7]);
   pulldown(c0_gpio_pad_io[8]);
   pulldown(c0_gpio_pad_io[9]);
   pulldown(c0_gpio_pad_io[10]);
   pulldown(c0_gpio_pad_io[11]);
   pulldown(c0_gpio_pad_io[12]);
   pulldown(c0_gpio_pad_io[13]);
   pulldown(c0_gpio_pad_io[14]);
   pulldown(c0_gpio_pad_io[15]);
   pulldown(c0_gpio_pad_io[16]);
   pulldown(c0_gpio_pad_io[17]);
   pulldown(c0_gpio_pad_io[18]);
   pulldown(c0_gpio_pad_io[19]);
   pulldown(c0_gpio_pad_io[20]);
   pulldown(c0_gpio_pad_io[21]);
   pulldown(c0_gpio_pad_io[22]);
   pulldown(c0_gpio_pad_io[23]);
   pulldown(c0_gpio_pad_io[24]);
   pulldown(c0_gpio_pad_io[25]);
   pulldown(c0_gpio_pad_io[26]);
   pulldown(c0_gpio_pad_io[27]);
   pulldown(c0_gpio_pad_io[28]);
   pulldown(c0_gpio_pad_io[29]);
   pulldown(c0_gpio_pad_io[30]);
   pulldown(c0_gpio_pad_io[31]);

   //==================================================================
   //==================================================================
   //==================================================================
   // CHIP instance 1
   //==================================================================
   //==================================================================
   //==================================================================

   integer	counter1;
   
   // Signals for generic_pll
   wire		c1_mc_clk;
   wire		c1_wb_clk;
   wire		c1_flash_clk;
   wire		c1_pll_lock;
   
   wire		c1_flash_rstn;
   wire		c1_flash_oen;
   wire		c1_flash_cen;
   wire		c1_flash_wen;
   wire		c1_flash_rdy;
   wire [7:0]	c1_flash_d;
   wire [20:0]	c1_flash_a;
   wire [31:0]	c1_flash_vpp;		// Special flash inputs
   wire [31:0]	c1_flash_vcc;		// Special flash inputs
   wire [1:0]	c1_flash_rpblevel;		// Special flash inputs
   
   
   /*
    reg [12:0]  a;
    reg [1:0]   ba;
    reg         cke, csn;
    wire        wen, rasn, casn;
    wire [15:0] dq;
    reg [1:0]   dqm;
    */
   wire [31:0]	c1_mem_dat_pad_io;
   wire [12:0]	c1_mem_adr_pad_o;
   wire [1:0]	c1_mem_ba_pad_o;
   wire [3:0]	c1_mem_dqm_pad_o;
   
   wire [31:0]	c1_gpio_pad_io;
   
   assign c1_wb_clk = clk;
   wire c10_d2d_clk = d2d_clk;
   wire	c10_d2d_rst_n = d2d_rstn;
   wire c12_d2d_clk = d2d_clk;
   wire	c12_d2d_rst_n = d2d_rstn;
   wire c13_d2d_clk = d2d_clk;
   wire	c13_d2d_rst_n = d2d_rstn;
   
   or1k_soc_top soc1
     (
      // Clk and reset
      .wb_clk_pad_i		(c1_wb_clk),
      .rst_n_pad_i		(rstn_dly),
      
      .mc_clk_pad_o		(c1_dram_clk),
      //		.mc_clk_pad_i		(mc_clk),
      //		.flash_clk_pad_i	(flash_clk),
      
      .flash_rstn		(c1_flash_rstn),
      .flash_cen		(c1_flash_cen),
      .flash_oen		(c1_flash_oen),
      .flash_wen		(c1_flash_wen),
      .flash_rdy		(c1_flash_rdy),
      .flash_d		        (c1_flash_d),
      .flash_a		        (c1_flash_a),
      
      // Memory Controller 
      .mem_dat_pad_io         (c1_mem_dat_pad_io),
      .mem_adr_pad_o          (c1_mem_adr_pad_o[12:0]),
      .mem_dqm_pad_o          (c1_mem_dqm_pad_o[3:0]),
      .mem_ba_pad_o           (c1_mem_ba_pad_o[1:0]),
      .mem_cs_pad_o           (c1_mem_cs_pad_o),
      .mem_ras_pad_o          (c1_mem_ras_pad_o),
      .mem_cas_pad_o          (c1_mem_cas_pad_o),
      .mem_we_pad_o           (c1_mem_we_pad_o),
      .mem_cke_pad_o          (c1_mem_cke_pad_o),
      
      // SPI_FLASH
      .spi_flash_sclk_pad_o   (c1_spi_flash_sclk_pad_o),
      .spi_flash_ss_pad_o     (c1_spi_flash_ss_pad_o),
      .spi_flash_miso_pad_i   (c1_spi_flash_miso_pad_i),
      .spi_flash_mosi_pad_o   (c1_spi_flash_mosi_pad_o),  
      .spi_flash_w_n_pad_o    (c1_spi_flash_w_n_pad_o),
      .spi_flash_hold_n_pad_o (c1_spi_flash_hold_n_pad_o),
      
      /*
       // SPI1
       .spi_mmc_sclk_pad_o     (spi_mmc_sclk_pad_o),
       .spi_mmc_ss_pad_o       (spi_mmc_ss_pad_o),
       .spi_mmc_miso_pad_i     (spi_mmc_mosi_pad_o),
       .spi_mmc_mosi_pad_o     (spi_mmc_mosi_pad_o),
       */	
      // GPIO
      .gpio_a_pad_io          (c1_gpio_pad_io),
      
      // UART0
      .uart_srx_pad_i		(1'b1),  
      .uart_stx_pad_o		(c1_uart_stx_pad_o),

      .d2d0_clk                (c10_d2d_clk),
      .d2d0_rst_n              (c10_d2d_rst_n),
      .d2d0_tx_data            (c10_d2d_tx_data),
      .d2d0_tx_valid           (c10_d2d_tx_valid),
      .d2d0_tx_ready           (c01_d2d_rx_ready),
      .d2d0_rx_data            (c01_d2d_tx_data),
      .d2d0_rx_valid           (c01_d2d_tx_valid),
      .d2d0_rx_ready           (c10_d2d_rx_ready),

      .d2d1_clk                (c12_d2d_clk),
      .d2d1_rst_n              (c12_d2d_rst_n),
      .d2d1_tx_data            (c12_d2d_tx_data),
      .d2d1_tx_valid           (c12_d2d_tx_valid),
      .d2d1_tx_ready           (c21_d2d_rx_ready),
      .d2d1_rx_data            (c21_d2d_tx_data),
      .d2d1_rx_valid           (c21_d2d_tx_valid),
      .d2d1_rx_ready           (c12_d2d_rx_ready),

      .d2d2_clk                (c13_d2d_clk),
      .d2d2_rst_n              (c13_d2d_rst_n),
      .d2d2_tx_data            (c13_d2d_tx_data),
      .d2d2_tx_valid           (c13_d2d_tx_valid),
      .d2d2_tx_ready           (c31_d2d_rx_ready),
      .d2d2_rx_data            (c31_d2d_tx_data),
      .d2d2_rx_valid           (c31_d2d_tx_valid),
      .d2d2_rx_ready           (c13_d2d_rx_ready),
      
      .cpuID                  (8'h01)
      
      /*
       // JTAG
       .dbg_tdi_pad_i          (1'b0),
       .dbg_tck_pad_i          (1'b0),
       .dbg_tms_pad_i          (1'b0),  
       .dbg_tdo_pad_o          (dbg_tdo),
       .iob                    (iob)
       */
      );
   
   
   reg [31:0] old_c1_gpio_val;
   
   always @(posedge clk) begin
      old_c1_gpio_val <= c1_gpio_pad_io;
      if (old_c1_gpio_val != c1_gpio_pad_io)
	$display("[%m]C1 GPIO val = %h", c1_gpio_pad_io);
      
      if (c1_gpio_pad_io == 32'hc001c0de) begin
	 // 0xff has been written to GPIO, so the
	 // sofware has completed its tests
	 $display("\n\n**** PASS C1 **** indicator for Software execution complete.\n\n");
//	 $fflush(uart_mon1.fd);
	 //	       repeat(1000000) @(posedge clk);
	 $finish();
      end else if (c1_gpio_pad_io == 32'hdeadbeef) begin
	 // 0x55 has been written to GPIO, so the
	 // there was an error during the tests
	 $display("\n\n**** FAIL C1 **** indicator during Software tests. Finishing simulation.");
//	 $fflush(uart_mon1.fd);
	 repeat(1000000) @(posedge clk);
	 $finish();
      end
   end   
   
   
   always @(posedge clk or posedge rstn) begin
      if (!rstn) begin
	 counter1 = 0;
      end
      else begin
	 if (counter1 == 20000000) begin
	    $display("Completed");
	    //		 Flash.StoreToFile;
	    
//	    $fflush(uart_mon1.fd);
	    $finish();
	 end
	 counter1 = counter1 + 1;
      end
      
   end
   
   // The Flash RAM
   
   assign c1_flash_vpp = 32'h00002ee0;
   assign c1_flash_vcc = 32'h00001388;
   assign c1_flash_rpblevel = 2'b10;
   
   i28f016s3 Flash1
     (
      .rpb( c1_flash_rstn ),
      .ceb( c1_flash_cen ),
      .oeb( c1_flash_oen ),
      .web( c1_flash_wen ),
      .ryby( c1_flash_rdy ),
      .dq( c1_flash_d ),
      .addr( c1_flash_a ),
      .vpp( c1_flash_vpp ),
      .vcc( c1_flash_vcc ),
      .rpblevel( c1_flash_rpblevel )
      );
   
   
   // This model contains actual timing  MT48LC16M16B2  (4 Meg x 16 x 4 banks)
   mt48lc16m16a2_model i_sdram10
     (
      .DQ    (c1_mem_dat_pad_io[15:0]),
      .A     (c1_mem_adr_pad_o[12:0]),
      .BA    (c1_mem_ba_pad_o[1:0]),
      .CLK   (c1_dram_clk),
      .CKE   (c1_mem_cke_pad_o),
      .CS_N  (c1_mem_cs_pad_o),
      .RAS_N (c1_mem_ras_pad_o),
      .CAS_N (c1_mem_cas_pad_o),
      .WE_N  (c1_mem_we_pad_o),
      .DQM   (c1_mem_dqm_pad_o[1:0])
      );
   
   mt48lc16m16a2_model i_sdram11
     (
      .DQ    (c1_mem_dat_pad_io[31:16]),
      .A     (c1_mem_adr_pad_o[12:0]),
      .BA    (c1_mem_ba_pad_o[1:0]),
      .CLK   (c1_dram_clk),
      .CKE   (c1_mem_cke_pad_o),
      .CS_N  (c1_mem_cs_pad_o),
      .RAS_N (c1_mem_ras_pad_o),
      .CAS_N (c1_mem_cas_pad_o),
      .WE_N  (c1_mem_we_pad_o),
      .DQM   (c1_mem_dqm_pad_o[3:2])
      );
   
   
   uart_mon uart_mon1
     (
      .clk (clk), // System clock
      .reset (~rstn_dly),
      .rx (c1_uart_stx_pad_o),
      .monID (8'h01)
      );
   
   // //   
       defparam CPUboard_tb.i_spi_flash1.MEMORY_FILE="memory.txt";
   
   AT26DFxxx i_spi_flash1
     (
      .CSB    (c1_spi_flash_ss_pad_o),
      .SCK    (c1_spi_flash_sclk_pad_o),
      .SI     (c1_spi_flash_mosi_pad_o),
      .WPB    (c1_spi_flash_w_n_pad_o),
      .SO     (c1_spi_flash_miso_pad_i)
      );
   
   
   
   pulldown(c1_gpio_pad_io[0]);
   pulldown(c1_gpio_pad_io[1]);
   pulldown(c1_gpio_pad_io[2]);
   pulldown(c1_gpio_pad_io[3]);
   pulldown(c1_gpio_pad_io[4]);
   pulldown(c1_gpio_pad_io[5]);
   pulldown(c1_gpio_pad_io[6]);
   pulldown(c1_gpio_pad_io[7]);
   pulldown(c1_gpio_pad_io[8]);
   pulldown(c1_gpio_pad_io[9]);
   pulldown(c1_gpio_pad_io[10]);
   pulldown(c1_gpio_pad_io[11]);
   pulldown(c1_gpio_pad_io[12]);
   pulldown(c1_gpio_pad_io[13]);
   pulldown(c1_gpio_pad_io[14]);
   pulldown(c1_gpio_pad_io[15]);
   pulldown(c1_gpio_pad_io[16]);
   pulldown(c1_gpio_pad_io[17]);
   pulldown(c1_gpio_pad_io[18]);
   pulldown(c1_gpio_pad_io[19]);
   pulldown(c1_gpio_pad_io[20]);
   pulldown(c1_gpio_pad_io[21]);
   pulldown(c1_gpio_pad_io[22]);
   pulldown(c1_gpio_pad_io[23]);
   pulldown(c1_gpio_pad_io[24]);
   pulldown(c1_gpio_pad_io[25]);
   pulldown(c1_gpio_pad_io[26]);
   pulldown(c1_gpio_pad_io[27]);
   pulldown(c1_gpio_pad_io[28]);
   pulldown(c1_gpio_pad_io[29]);
   pulldown(c1_gpio_pad_io[30]);
   pulldown(c1_gpio_pad_io[31]);

   //==================================================================
   //==================================================================
   //==================================================================
   // CHIP instance 2
   //==================================================================
   //==================================================================
   //==================================================================

   integer	counter2;
   
   // Signals for generic_pll
   wire		c2_mc_clk;
   wire		c2_wb_clk;
   wire		c2_flash_clk;
   wire		c2_pll_lock;
   
   wire		c2_flash_rstn;
   wire		c2_flash_oen;
   wire		c2_flash_cen;
   wire		c2_flash_wen;
   wire		c2_flash_rdy;
   wire [7:0]	c2_flash_d;
   wire [20:0]	c2_flash_a;
   wire [31:0]	c2_flash_vpp;		// Special flash inputs
   wire [31:0]	c2_flash_vcc;		// Special flash inputs
   wire [1:0]	c2_flash_rpblevel;		// Special flash inputs
   
   
   /*
    reg [12:0]  a;
    reg [1:0]   ba;
    reg         cke, csn;
    wire        wen, rasn, casn;
    wire [15:0] dq;
    reg [1:0]   dqm;
    */
   wire [31:0]	c2_mem_dat_pad_io;
   wire [12:0]	c2_mem_adr_pad_o;
   wire [1:0]	c2_mem_ba_pad_o;
   wire [3:0]	c2_mem_dqm_pad_o;
   
   wire [31:0]	c2_gpio_pad_io;
   
   assign c2_wb_clk = clk;

   wire c20_d2d_clk = d2d_clk;
   wire	c20_d2d_rst_n = d2d_rstn;
   wire c21_d2d_clk = d2d_clk;
   wire	c21_d2d_rst_n = d2d_rstn;
   wire c23_d2d_clk = d2d_clk;
   wire	c23_d2d_rst_n = d2d_rstn;
   
   or1k_soc_top soc2
     (
      // Clk and reset
      .wb_clk_pad_i		(c2_wb_clk),
      .rst_n_pad_i		(rstn_dly),
      
      .mc_clk_pad_o		(c2_dram_clk),
      //		.mc_clk_pad_i		(mc_clk),
      //		.flash_clk_pad_i	(flash_clk),
      
      .flash_rstn		(c2_flash_rstn),
      .flash_cen		(c2_flash_cen),
      .flash_oen		(c2_flash_oen),
      .flash_wen		(c2_flash_wen),
      .flash_rdy		(c2_flash_rdy),
      .flash_d		        (c2_flash_d),
      .flash_a		        (c2_flash_a),
      
      // Memory Controller 
      .mem_dat_pad_io         (c2_mem_dat_pad_io),
      .mem_adr_pad_o          (c2_mem_adr_pad_o[12:0]),
      .mem_dqm_pad_o          (c2_mem_dqm_pad_o[3:0]),
      .mem_ba_pad_o           (c2_mem_ba_pad_o[1:0]),
      .mem_cs_pad_o           (c2_mem_cs_pad_o),
      .mem_ras_pad_o          (c2_mem_ras_pad_o),
      .mem_cas_pad_o          (c2_mem_cas_pad_o),
      .mem_we_pad_o           (c2_mem_we_pad_o),
      .mem_cke_pad_o          (c2_mem_cke_pad_o),
      
      // SPI_FLASH
      .spi_flash_sclk_pad_o   (c2_spi_flash_sclk_pad_o),
      .spi_flash_ss_pad_o     (c2_spi_flash_ss_pad_o),
      .spi_flash_miso_pad_i   (c2_spi_flash_miso_pad_i),
      .spi_flash_mosi_pad_o   (c2_spi_flash_mosi_pad_o),  
      .spi_flash_w_n_pad_o    (c2_spi_flash_w_n_pad_o),
      .spi_flash_hold_n_pad_o (c2_spi_flash_hold_n_pad_o),
      
      /*
       // SPI1
       .spi_mmc_sclk_pad_o     (spi_mmc_sclk_pad_o),
       .spi_mmc_ss_pad_o       (spi_mmc_ss_pad_o),
       .spi_mmc_miso_pad_i     (spi_mmc_mosi_pad_o),
       .spi_mmc_mosi_pad_o     (spi_mmc_mosi_pad_o),
       */	
      // GPIO
      .gpio_a_pad_io          (c2_gpio_pad_io),
      
      // UART0
      .uart_srx_pad_i		(1'b1),  
      .uart_stx_pad_o		(c2_uart_stx_pad_o),

      .d2d0_clk                (c20_d2d_clk),
      .d2d0_rst_n              (c20_d2d_rst_n),
      .d2d0_tx_data            (c20_d2d_tx_data),
      .d2d0_tx_valid           (c20_d2d_tx_valid),
      .d2d0_tx_ready           (c02_d2d_rx_ready),
      .d2d0_rx_data            (c02_d2d_tx_data),
      .d2d0_rx_valid           (c02_d2d_tx_valid),
      .d2d0_rx_ready           (c20_d2d_rx_ready),

      .d2d1_clk                (c21_d2d_clk),
      .d2d1_rst_n              (c21_d2d_rst_n),
      .d2d1_tx_data            (c21_d2d_tx_data),
      .d2d1_tx_valid           (c21_d2d_tx_valid),
      .d2d1_tx_ready           (c12_d2d_rx_ready),
      .d2d1_rx_data            (c12_d2d_tx_data),
      .d2d1_rx_valid           (c12_d2d_tx_valid),
      .d2d1_rx_ready           (c21_d2d_rx_ready),

      .d2d2_clk                (c23_d2d_clk),
      .d2d2_rst_n              (c23_d2d_rst_n),
      .d2d2_tx_data            (c23_d2d_tx_data),
      .d2d2_tx_valid           (c23_d2d_tx_valid),
      .d2d2_tx_ready           (c32_d2d_rx_ready),
      .d2d2_rx_data            (c32_d2d_tx_data),
      .d2d2_rx_valid           (c32_d2d_tx_valid),
      .d2d2_rx_ready           (c23_d2d_rx_ready),
      
      .cpuID                  (8'h02)
      
      /*
       // JTAG
       .dbg_tdi_pad_i          (1'b0),
       .dbg_tck_pad_i          (1'b0),
       .dbg_tms_pad_i          (1'b0),  
       .dbg_tdo_pad_o          (dbg_tdo),
       .iob                    (iob)
       */
      );
   
   
   reg [31:0] old_c2_gpio_val;
   
   always @(posedge clk) begin
      old_c2_gpio_val <= c2_gpio_pad_io;
      if (old_c2_gpio_val != c2_gpio_pad_io)
	$display("[%m]C2 GPIO val = %h", c2_gpio_pad_io);
      
      if (c2_gpio_pad_io == 32'hc001c0de) begin
	 // 0xff has been written to GPIO, so the
	 // sofware has completed its tests
	 $display("\n\n**** PASS C2 **** indicator for Software execution complete.\n\n");
//	 $fflush(uart_mon1.fd);
	 //	       repeat(1000000) @(posedge clk);
	 $finish();
      end else if (c2_gpio_pad_io == 32'hdeadbeef) begin
	 // 0x55 has been written to GPIO, so the
	 // there was an error during the tests
	 $display("\n\n**** FAIL C2 **** indicator during Software tests. Finishing simulation.");
//	 $fflush(uart_mon1.fd);
	 repeat(1000000) @(posedge clk);
	 $finish();
      end
   end   
   
   
   always @(posedge clk or posedge rstn) begin
      if (!rstn) begin
	 counter2 = 0;
      end
      else begin
	 if (counter2 == 20000000) begin
	    $display("Completed");
	    //		 Flash.StoreToFile;
	    
//	    $fflush(uart_mon1.fd);
	    $finish();
	 end
	 counter2 = counter2 + 1;
      end
      
   end
   
   // The Flash RAM
   
   assign c2_flash_vpp = 32'h00002ee0;
   assign c2_flash_vcc = 32'h00001388;
   assign c2_flash_rpblevel = 2'b10;
   
   i28f016s3 Flash2
     (
      .rpb( c2_flash_rstn ),
      .ceb( c2_flash_cen ),
      .oeb( c2_flash_oen ),
      .web( c2_flash_wen ),
      .ryby( c2_flash_rdy ),
      .dq( c2_flash_d ),
      .addr( c2_flash_a ),
      .vpp( c2_flash_vpp ),
      .vcc( c2_flash_vcc ),
      .rpblevel( c2_flash_rpblevel )
      );
   
   
   // This model contains actual timing  MT48LC16M16B2  (4 Meg x 16 x 4 banks)
   mt48lc16m16a2_model i_sdram20
     (
      .DQ    (c2_mem_dat_pad_io[15:0]),
      .A     (c2_mem_adr_pad_o[12:0]),
      .BA    (c2_mem_ba_pad_o[1:0]),
      .CLK   (c2_dram_clk),
      .CKE   (c2_mem_cke_pad_o),
      .CS_N  (c2_mem_cs_pad_o),
      .RAS_N (c2_mem_ras_pad_o),
      .CAS_N (c2_mem_cas_pad_o),
      .WE_N  (c2_mem_we_pad_o),
      .DQM   (c2_mem_dqm_pad_o[1:0])
      );
   
   mt48lc16m16a2_model i_sdram21
     (
      .DQ    (c2_mem_dat_pad_io[31:16]),
      .A     (c2_mem_adr_pad_o[12:0]),
      .BA    (c2_mem_ba_pad_o[1:0]),
      .CLK   (c2_dram_clk),
      .CKE   (c2_mem_cke_pad_o),
      .CS_N  (c2_mem_cs_pad_o),
      .RAS_N (c2_mem_ras_pad_o),
      .CAS_N (c2_mem_cas_pad_o),
      .WE_N  (c2_mem_we_pad_o),
      .DQM   (c2_mem_dqm_pad_o[3:2])
      );
   
   
   uart_mon uart_mon2
     (
      .clk (clk), // System clock
      .reset (~rstn_dly),
      .rx (c2_uart_stx_pad_o),
      .monID (8'h02)
      );
   
   // //   
       defparam CPUboard_tb.i_spi_flash2.MEMORY_FILE="memory.txt";
   
   AT26DFxxx i_spi_flash2
     (
      .CSB    (c2_spi_flash_ss_pad_o),
      .SCK    (c2_spi_flash_sclk_pad_o),
      .SI     (c2_spi_flash_mosi_pad_o),
      .WPB    (c2_spi_flash_w_n_pad_o),
      .SO     (c2_spi_flash_miso_pad_i)
      );
   
   
   
   pulldown(c2_gpio_pad_io[0]);
   pulldown(c2_gpio_pad_io[1]);
   pulldown(c2_gpio_pad_io[2]);
   pulldown(c2_gpio_pad_io[3]);
   pulldown(c2_gpio_pad_io[4]);
   pulldown(c2_gpio_pad_io[5]);
   pulldown(c2_gpio_pad_io[6]);
   pulldown(c2_gpio_pad_io[7]);
   pulldown(c2_gpio_pad_io[8]);
   pulldown(c2_gpio_pad_io[9]);
   pulldown(c2_gpio_pad_io[10]);
   pulldown(c2_gpio_pad_io[11]);
   pulldown(c2_gpio_pad_io[12]);
   pulldown(c2_gpio_pad_io[13]);
   pulldown(c2_gpio_pad_io[14]);
   pulldown(c2_gpio_pad_io[15]);
   pulldown(c2_gpio_pad_io[16]);
   pulldown(c2_gpio_pad_io[17]);
   pulldown(c2_gpio_pad_io[18]);
   pulldown(c2_gpio_pad_io[19]);
   pulldown(c2_gpio_pad_io[20]);
   pulldown(c2_gpio_pad_io[21]);
   pulldown(c2_gpio_pad_io[22]);
   pulldown(c2_gpio_pad_io[23]);
   pulldown(c2_gpio_pad_io[24]);
   pulldown(c2_gpio_pad_io[25]);
   pulldown(c2_gpio_pad_io[26]);
   pulldown(c2_gpio_pad_io[27]);
   pulldown(c2_gpio_pad_io[28]);
   pulldown(c2_gpio_pad_io[29]);
   pulldown(c2_gpio_pad_io[30]);
   pulldown(c2_gpio_pad_io[31]);

   //==================================================================
   //==================================================================
   //==================================================================
   // CHIP instance 3
   //==================================================================
   //==================================================================
   //==================================================================

   integer	counter3;
   
   // Signals for generic_pll
   wire		c3_mc_clk;
   wire		c3_wb_clk;
   wire		c3_flash_clk;
   wire		c3_pll_lock;
   
   wire		c3_flash_rstn;
   wire		c3_flash_oen;
   wire		c3_flash_cen;
   wire		c3_flash_wen;
   wire		c3_flash_rdy;
   wire [7:0]	c3_flash_d;
   wire [20:0]	c3_flash_a;
   wire [31:0]	c3_flash_vpp;		// Special flash inputs
   wire [31:0]	c3_flash_vcc;		// Special flash inputs
   wire [1:0]	c3_flash_rpblevel;		// Special flash inputs
   
   
   /*
    reg [12:0]  a;
    reg [1:0]   ba;
    reg         cke, csn;
    wire        wen, rasn, casn;
    wire [15:0] dq;
    reg [1:0]   dqm;
    */
   wire [31:0]	c3_mem_dat_pad_io;
   wire [12:0]	c3_mem_adr_pad_o;
   wire [1:0]	c3_mem_ba_pad_o;
   wire [3:0]	c3_mem_dqm_pad_o;
   
   wire [31:0]	c3_gpio_pad_io;
   
   assign c3_wb_clk = clk;

   wire c30_d2d_clk = d2d_clk;
   wire	c30_d2d_rst_n = d2d_rstn;
   wire c31_d2d_clk = d2d_clk;
   wire	c31_d2d_rst_n = d2d_rstn;
   wire c32_d2d_clk = d2d_clk;
   wire	c32_d2d_rst_n = d2d_rstn;
   
   or1k_soc_top soc3
     (
      // Clk and reset
      .wb_clk_pad_i		(c3_wb_clk),
      .rst_n_pad_i		(rstn_dly),
      
      .mc_clk_pad_o		(c3_dram_clk),
      //		.mc_clk_pad_i		(mc_clk),
      //		.flash_clk_pad_i	(flash_clk),
      
      .flash_rstn		(c3_flash_rstn),
      .flash_cen		(c3_flash_cen),
      .flash_oen		(c3_flash_oen),
      .flash_wen		(c3_flash_wen),
      .flash_rdy		(c3_flash_rdy),
      .flash_d		        (c3_flash_d),
      .flash_a		        (c3_flash_a),
      
      // Memory Controller 
      .mem_dat_pad_io         (c3_mem_dat_pad_io),
      .mem_adr_pad_o          (c3_mem_adr_pad_o[12:0]),
      .mem_dqm_pad_o          (c3_mem_dqm_pad_o[3:0]),
      .mem_ba_pad_o           (c3_mem_ba_pad_o[1:0]),
      .mem_cs_pad_o           (c3_mem_cs_pad_o),
      .mem_ras_pad_o          (c3_mem_ras_pad_o),
      .mem_cas_pad_o          (c3_mem_cas_pad_o),
      .mem_we_pad_o           (c3_mem_we_pad_o),
      .mem_cke_pad_o          (c3_mem_cke_pad_o),
      
      // SPI_FLASH
      .spi_flash_sclk_pad_o   (c3_spi_flash_sclk_pad_o),
      .spi_flash_ss_pad_o     (c3_spi_flash_ss_pad_o),
      .spi_flash_miso_pad_i   (c3_spi_flash_miso_pad_i),
      .spi_flash_mosi_pad_o   (c3_spi_flash_mosi_pad_o),  
      .spi_flash_w_n_pad_o    (c3_spi_flash_w_n_pad_o),
      .spi_flash_hold_n_pad_o (c3_spi_flash_hold_n_pad_o),
      
      /*
       // SPI1
       .spi_mmc_sclk_pad_o     (spi_mmc_sclk_pad_o),
       .spi_mmc_ss_pad_o       (spi_mmc_ss_pad_o),
       .spi_mmc_miso_pad_i     (spi_mmc_mosi_pad_o),
       .spi_mmc_mosi_pad_o     (spi_mmc_mosi_pad_o),
       */	
      // GPIO
      .gpio_a_pad_io          (c3_gpio_pad_io),
      
      // UART0
      .uart_srx_pad_i		(1'b1),  
      .uart_stx_pad_o		(c3_uart_stx_pad_o),

      .d2d0_clk                (c30_d2d_clk),
      .d2d0_rst_n              (c30_d2d_rst_n),
      .d2d0_tx_data            (c30_d2d_tx_data),
      .d2d0_tx_valid           (c30_d2d_tx_valid),
      .d2d0_tx_ready           (c03_d2d_rx_ready),
      .d2d0_rx_data            (c03_d2d_tx_data),
      .d2d0_rx_valid           (c03_d2d_tx_valid),
      .d2d0_rx_ready           (c30_d2d_rx_ready),

      .d2d1_clk                (c32_d2d_clk),
      .d2d1_rst_n              (c32_d2d_rst_n),
      .d2d1_tx_data            (c32_d2d_tx_data),
      .d2d1_tx_valid           (c32_d2d_tx_valid),
      .d2d1_tx_ready           (c23_d2d_rx_ready),
      .d2d1_rx_data            (c23_d2d_tx_data),
      .d2d1_rx_valid           (c23_d2d_tx_valid),
      .d2d1_rx_ready           (c32_d2d_rx_ready),

      .d2d2_clk                (c31_d2d_clk),
      .d2d2_rst_n              (c31_d2d_rst_n),
      .d2d2_tx_data            (c31_d2d_tx_data),
      .d2d2_tx_valid           (c31_d2d_tx_valid),
      .d2d2_tx_ready           (c13_d2d_rx_ready),
      .d2d2_rx_data            (c13_d2d_tx_data),
      .d2d2_rx_valid           (c13_d2d_tx_valid),
      .d2d2_rx_ready           (c31_d2d_rx_ready),
      
      .cpuID                  (8'h03)
      
      /*
       // JTAG
       .dbg_tdi_pad_i          (1'b0),
       .dbg_tck_pad_i          (1'b0),
       .dbg_tms_pad_i          (1'b0),  
       .dbg_tdo_pad_o          (dbg_tdo),
       .iob                    (iob)
       */
      );
   
   
   reg [31:0] old_c3_gpio_val;
   
   always @(posedge clk) begin
      old_c3_gpio_val <= c3_gpio_pad_io;
      if (old_c3_gpio_val != c3_gpio_pad_io)
	$display("[%m]C3 GPIO val = %h", c3_gpio_pad_io);
      
      if (c3_gpio_pad_io == 32'hc001c0de) begin
	 // 0xff has been written to GPIO, so the
	 // sofware has completed its tests
	 $display("\n\n**** PASS C3 **** indicator for Software execution complete.\n\n");
//	 $fflush(uart_mon1.fd);
	 //	       repeat(1000000) @(posedge clk);
	 $finish();
      end else if (c3_gpio_pad_io == 32'hdeadbeef) begin
	 // 0x55 has been written to GPIO, so the
	 // there was an error during the tests
	 $display("\n\n**** FAIL C3 **** indicator during Software tests. Finishing simulation.");
//	 $fflush(uart_mon1.fd);
	 repeat(1000000) @(posedge clk);
	 $finish();
      end
   end   
   
   
   always @(posedge clk or posedge rstn) begin
      if (!rstn) begin
	 counter3 = 0;
      end
      else begin
	 if (counter3 == 20000000) begin
	    $display("Completed");
	    //		 Flash.StoreToFile;
	    
//	    $fflush(uart_mon1.fd);
	    $finish();
	 end
	 counter3 = counter3 + 1;
      end
      
   end
   
   // The Flash RAM
   
   assign c3_flash_vpp = 32'h00002ee0;
   assign c3_flash_vcc = 32'h00001388;
   assign c3_flash_rpblevel = 2'b10;
   
   i28f016s3 Flash3
     (
      .rpb( c3_flash_rstn ),
      .ceb( c3_flash_cen ),
      .oeb( c3_flash_oen ),
      .web( c3_flash_wen ),
      .ryby( c3_flash_rdy ),
      .dq( c3_flash_d ),
      .addr( c3_flash_a ),
      .vpp( c3_flash_vpp ),
      .vcc( c3_flash_vcc ),
      .rpblevel( c3_flash_rpblevel )
      );
   
   
   // This model contains actual timing  MT48LC16M16B2  (4 Meg x 16 x 4 banks)
   mt48lc16m16a2_model i_sdram30
     (
      .DQ    (c3_mem_dat_pad_io[15:0]),
      .A     (c3_mem_adr_pad_o[12:0]),
      .BA    (c3_mem_ba_pad_o[1:0]),
      .CLK   (c3_dram_clk),
      .CKE   (c3_mem_cke_pad_o),
      .CS_N  (c3_mem_cs_pad_o),
      .RAS_N (c3_mem_ras_pad_o),
      .CAS_N (c3_mem_cas_pad_o),
      .WE_N  (c3_mem_we_pad_o),
      .DQM   (c3_mem_dqm_pad_o[1:0])
      );
   
   mt48lc16m16a2_model i_sdram31
     (
      .DQ    (c3_mem_dat_pad_io[31:16]),
      .A     (c3_mem_adr_pad_o[12:0]),
      .BA    (c3_mem_ba_pad_o[1:0]),
      .CLK   (c3_dram_clk),
      .CKE   (c3_mem_cke_pad_o),
      .CS_N  (c3_mem_cs_pad_o),
      .RAS_N (c3_mem_ras_pad_o),
      .CAS_N (c3_mem_cas_pad_o),
      .WE_N  (c3_mem_we_pad_o),
      .DQM   (c3_mem_dqm_pad_o[3:2])
      );
   
   
   uart_mon uart_mon3
     (
      .clk (clk), // System clock
      .reset (~rstn_dly),
      .rx (c3_uart_stx_pad_o),
      .monID (8'h03)
      );
   
   // //   
       defparam CPUboard_tb.i_spi_flash3.MEMORY_FILE="memory.txt";
   
   AT26DFxxx i_spi_flash3
     (
      .CSB    (c3_spi_flash_ss_pad_o),
      .SCK    (c3_spi_flash_sclk_pad_o),
      .SI     (c3_spi_flash_mosi_pad_o),
      .WPB    (c3_spi_flash_w_n_pad_o),
      .SO     (c3_spi_flash_miso_pad_i)
      );
   
   
   
   pulldown(c3_gpio_pad_io[0]);
   pulldown(c3_gpio_pad_io[1]);
   pulldown(c3_gpio_pad_io[2]);
   pulldown(c3_gpio_pad_io[3]);
   pulldown(c3_gpio_pad_io[4]);
   pulldown(c3_gpio_pad_io[5]);
   pulldown(c3_gpio_pad_io[6]);
   pulldown(c3_gpio_pad_io[7]);
   pulldown(c3_gpio_pad_io[8]);
   pulldown(c3_gpio_pad_io[9]);
   pulldown(c3_gpio_pad_io[10]);
   pulldown(c3_gpio_pad_io[11]);
   pulldown(c3_gpio_pad_io[12]);
   pulldown(c3_gpio_pad_io[13]);
   pulldown(c3_gpio_pad_io[14]);
   pulldown(c3_gpio_pad_io[15]);
   pulldown(c3_gpio_pad_io[16]);
   pulldown(c3_gpio_pad_io[17]);
   pulldown(c3_gpio_pad_io[18]);
   pulldown(c3_gpio_pad_io[19]);
   pulldown(c3_gpio_pad_io[20]);
   pulldown(c3_gpio_pad_io[21]);
   pulldown(c3_gpio_pad_io[22]);
   pulldown(c3_gpio_pad_io[23]);
   pulldown(c3_gpio_pad_io[24]);
   pulldown(c3_gpio_pad_io[25]);
   pulldown(c3_gpio_pad_io[26]);
   pulldown(c3_gpio_pad_io[27]);
   pulldown(c3_gpio_pad_io[28]);
   pulldown(c3_gpio_pad_io[29]);
   pulldown(c3_gpio_pad_io[30]);
   pulldown(c3_gpio_pad_io[31]);

endmodule

module dumpvars;
   initial begin:qiwc
      (*qiwc,no_opt*) $dumpvars(0,"CPUboard_tb"); 
   end
   
endmodule
