
module chiplet
  (
   input	 wb_clk,
   input	 rst_n,
   
   inout [31:0]	 gpio_pad_io,
      
   // UART0
   input	 uart_srx_pad_i,
   output	 uart_stx_pad_o,
		
   input	 d2d0_clk,
   input	 d2d0_rst_n,
   output [63:0] d2d0_tx_data,
   output	 d2d0_tx_valid,
   input	 d2d0_tx_ready,
   input [63:0]	 d2d0_rx_data,
   input	 d2d0_rx_valid,
   output	 d2d0_rx_ready,
		 
   input	 d2d1_clk,
   input	 d2d1_rst_n,
   output [63:0] d2d1_tx_data,
   output	 d2d1_tx_valid,
   input	 d2d1_tx_ready,
   input [63:0]	 d2d1_rx_data,
   input	 d2d1_rx_valid,
   output	 d2d1_rx_ready,
		 
   input	 d2d2_clk,
   input	 d2d2_rst_n,
   output [63:0] d2d2_tx_data,
   output	 d2d2_tx_valid,
   input	 d2d2_tx_ready,
   input [63:0]	 d2d2_rx_data,
   input	 d2d2_rx_valid,
   output	 d2d2_rx_ready,
		 
   input [7:0]	 cpuID
   );
   
   wire		mc_clk;
   wire		flash_clk;
   wire		pll_lock;
   
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

   wire [31:0]	mem_dat_pad_io;
   wire [12:0]	mem_adr_pad_o;
   wire [1:0]	mem_ba_pad_o;
   wire [3:0]	mem_dqm_pad_o;

   or1k_soc_top soc
     (
      // Clk and reset
      .wb_clk_pad_i		(wb_clk),
      .rst_n_pad_i		(rst_n),
      
      .mc_clk_pad_o		(dram_clk),
      //		.mc_clk_pad_i		(mc_clk),
      //		.flash_clk_pad_i	(flash_clk),
      
      .flash_rstn		(flash_rstn),
      .flash_cen		(flash_cen),
      .flash_oen		(flash_oen),
      .flash_wen		(flash_wen),
      .flash_rdy		(flash_rdy),
      .flash_d		        (flash_d),
      .flash_a		        (flash_a),
      
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
      .uart_srx_pad_i		(uart_srx_pad_i),  
      .uart_stx_pad_o		(uart_stx_pad_o),

      .d2d0_clk                (d2d0_clk),
      .d2d0_rst_n              (d2d0_rst_n),
      .d2d0_tx_data            (d2d0_tx_data),
      .d2d0_tx_valid           (d2d0_tx_valid),
      .d2d0_tx_ready           (d2d0_tx_ready),
      .d2d0_rx_data            (d2d0_rx_data),
      .d2d0_rx_valid           (d2d0_rx_valid),
      .d2d0_rx_ready           (d2d0_rx_ready),

      .d2d1_clk                (d2d1_clk),
      .d2d1_rst_n              (d2d1_rst_n),
      .d2d1_tx_data            (d2d1_tx_data),
      .d2d1_tx_valid           (d2d1_tx_valid),
      .d2d1_tx_ready           (d2d1_tx_ready),
      .d2d1_rx_data            (d2d1_rx_data),
      .d2d1_rx_valid           (d2d1_rx_valid),
      .d2d1_rx_ready           (d2d1_rx_ready),

      .d2d2_clk                (d2d2_clk),
      .d2d2_rst_n              (d2d2_rst_n),
      .d2d2_tx_data            (d2d2_tx_data),
      .d2d2_tx_valid           (d2d2_tx_valid),
      .d2d2_tx_ready           (d2d2_tx_ready),
      .d2d2_rx_data            (d2d2_rx_data),
      .d2d2_rx_valid           (d2d2_rx_valid),
      .d2d2_rx_ready           (d2d2_rx_ready),

      .cpuID                  (cpuID)
      
      /*
       // JTAG
       .dbg_tdi_pad_i          (1'b0),
       .dbg_tck_pad_i          (1'b0),
       .dbg_tms_pad_i          (1'b0),  
       .dbg_tdo_pad_o          (dbg_tdo),
       .iob                    (iob)
       */
      );
   
   // The Flash RAM
   
   assign flash_vpp = 32'h00002ee0;
   assign flash_vcc = 32'h00001388;
   assign flash_rpblevel = 2'b10;
   
   i28f016s3 Flash
     (
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
   mt48lc16m16a2_model i_sdram0
     (
      .DQ    (mem_dat_pad_io[15:0]),
      .A     (mem_adr_pad_o[12:0]),
      .BA    (mem_ba_pad_o[1:0]),
      .CLK   (dram_clk),
      .CKE   (mem_cke_pad_o),
      .CS_N  (mem_cs_pad_o),
      .RAS_N (mem_ras_pad_o),
      .CAS_N (mem_cas_pad_o),
      .WE_N  (mem_we_pad_o),
      .DQM   (mem_dqm_pad_o[1:0])
      );
   
   mt48lc16m16a2_model i_sdram1
     (
      .DQ    (mem_dat_pad_io[31:16]),
      .A     (mem_adr_pad_o[12:0]),
      .BA    (mem_ba_pad_o[1:0]),
      .CLK   (dram_clk),
      .CKE   (mem_cke_pad_o),
      .CS_N  (mem_cs_pad_o),
      .RAS_N (mem_ras_pad_o),
      .CAS_N (mem_cas_pad_o),
      .WE_N  (mem_we_pad_o),
      .DQM   (mem_dqm_pad_o[3:2])
      );
   
   AT26DFxxx i_spi_flash
     (
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

endmodule // chiplet
