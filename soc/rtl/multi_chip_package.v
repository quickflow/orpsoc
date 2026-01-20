
module multi_chip_package
   (
    input	 clk,
    input	 rstn,

    input	 d2d_clk_source,
    input	 d2d_rstn,
   
    inout [4*32-1:0] gpio_pad_io,
      
   // UART0
    input [3:0]	 uart_srx_pad_i,

    output [3:0] uart_stx_pad_o
    );

   // D2D
   wire		d2d_clk[3:0][2:0];
   wire		d2d_rst_n[3:0][2:0];
   
   wire [63:0]	d2d_tx_data[3:0][2:0];
   wire		d2d_tx_valid[3:0][2:0];
   wire		d2d_tx_ready[3:0][2:0];

   wire [63:0]	d2d_rx_data[3:0][2:0];
   wire		d2d_rx_valid[3:0][2:0];
   wire		d2d_rx_ready[3:0][2:0];
   
   //==================================================================
   // CHIP D2D interconnect
   //==================================================================

   assign d2d_rx_data[0][0]  =  d2d_tx_data[1][0];
   assign d2d_rx_valid[0][0] = d2d_tx_valid[1][0];
   assign d2d_tx_ready[0][0] = d2d_rx_ready[1][0];
   
   assign d2d_rx_data[0][1]  =  d2d_tx_data[2][0];
   assign d2d_rx_valid[0][1] = d2d_tx_valid[2][0];
   assign d2d_tx_ready[0][1] = d2d_rx_ready[2][0];
   
   assign d2d_rx_data[0][2]  =  d2d_tx_data[3][0];
   assign d2d_rx_valid[0][2] = d2d_tx_valid[3][0];
   assign d2d_tx_ready[0][2] = d2d_rx_ready[3][0];
   
   //==================================================================

   assign d2d_rx_data[1][0]  =  d2d_tx_data[0][0];
   assign d2d_rx_valid[1][0] = d2d_tx_valid[0][0];
   assign d2d_tx_ready[1][0] = d2d_rx_ready[0][0];
   
   assign d2d_rx_data[1][1]  =  d2d_tx_data[2][1];
   assign d2d_rx_valid[1][1] = d2d_tx_valid[2][1];
   assign d2d_tx_ready[1][1] = d2d_rx_ready[2][1];
   
   assign d2d_rx_data[1][2]  =  d2d_tx_data[3][2];
   assign d2d_rx_valid[1][2] = d2d_tx_valid[3][2];
   assign d2d_tx_ready[1][2] = d2d_rx_ready[3][2];
   
   //==================================================================

   assign d2d_rx_data[2][0]  =  d2d_tx_data[0][1];
   assign d2d_rx_valid[2][0] = d2d_tx_valid[0][1];
   assign d2d_tx_ready[2][0] = d2d_rx_ready[0][1];
   
   assign d2d_rx_data[2][1]  =  d2d_tx_data[1][1];
   assign d2d_rx_valid[2][1] = d2d_tx_valid[1][1];
   assign d2d_tx_ready[2][1] = d2d_rx_ready[1][1];
   
   assign d2d_rx_data[2][2]  =  d2d_tx_data[3][1];
   assign d2d_rx_valid[2][2] = d2d_tx_valid[3][1];
   assign d2d_tx_ready[2][2] = d2d_rx_ready[3][1];
   
   //==================================================================

   assign d2d_rx_data[3][0]  =  d2d_tx_data[0][2];
   assign d2d_rx_valid[3][0] = d2d_tx_valid[0][2];
   assign d2d_tx_ready[3][0] = d2d_rx_ready[0][2];
   
   assign d2d_rx_data[3][1]  =  d2d_tx_data[2][2];
   assign d2d_rx_valid[3][1] = d2d_tx_valid[2][2];
   assign d2d_tx_ready[3][1] = d2d_rx_ready[2][2];
   
   assign d2d_rx_data[3][2]  =  d2d_tx_data[1][2];
   assign d2d_rx_valid[3][2] = d2d_tx_valid[1][2];
   assign d2d_tx_ready[3][2] = d2d_rx_ready[1][2];
   
   
   //==================================================================
   // CHIP instance generate
   //==================================================================

   wire [7:0]	cpuID[3:0];
   wire		wb_clk[3:0];
   wire		wb_rst_n[3:0];

   genvar	instance_count;

   generate
      for (instance_count = 0; instance_count < 4; instance_count = instance_count + 1) begin : chiplet

	 assign wb_clk[instance_count] = clk;
	 
	 assign wb_rst_n[instance_count] = rstn;
	 
	 assign d2d_clk[instance_count][0] = d2d_clk_source;
	 assign d2d_clk[instance_count][1] = d2d_clk_source;
	 assign d2d_clk[instance_count][2] = d2d_clk_source;
	 
	 assign d2d_rst_n[instance_count][0] = d2d_rstn;
	 assign d2d_rst_n[instance_count][1] = d2d_rstn;
	 assign d2d_rst_n[instance_count][2] = d2d_rstn;
	 
	 assign cpuID[instance_count] = instance_count;
	 
	 // //   
		  defparam CPUboard_tb.pkg.chiplet[instance_count].chiplet.i_spi_flash.MEMORY_FILE="memory.txt";
   
	 chiplet chiplet
	   (
	    // Clk and reset
	    .wb_clk		(wb_clk[instance_count]),
	    .rst_n		(wb_rst_n[instance_count]),
	    
	    .gpio_pad_io          (gpio_pad_io[(instance_count+1)*32-1:(instance_count)*32]),
	    .uart_srx_pad_i		(uart_srx_pad_i[instance_count]),  
	    .uart_stx_pad_o		(uart_stx_pad_o[instance_count]),
	    
	    .d2d0_clk                (d2d_clk[instance_count][0]),
	    .d2d0_rst_n              (d2d_rst_n[instance_count][0]),
	    .d2d0_tx_data            (d2d_tx_data[instance_count][0]),
	    .d2d0_tx_valid           (d2d_tx_valid[instance_count][0]),
	    .d2d0_tx_ready           (d2d_tx_ready[instance_count][0]),
	    .d2d0_rx_data            (d2d_rx_data[instance_count][0]),
	    .d2d0_rx_valid           (d2d_rx_valid[instance_count][0]),
	    .d2d0_rx_ready           (d2d_rx_ready[instance_count][0]),
	    
	    .d2d1_clk                (d2d_clk[instance_count][1]),
	    .d2d1_rst_n              (d2d_rst_n[instance_count][1]),
	    .d2d1_tx_data            (d2d_tx_data[instance_count][1]),
	    .d2d1_tx_valid           (d2d_tx_valid[instance_count][1]),
	    .d2d1_tx_ready           (d2d_tx_ready[instance_count][1]),
	    .d2d1_rx_data            (d2d_rx_data[instance_count][1]),
	    .d2d1_rx_valid           (d2d_rx_valid[instance_count][1]),
	    .d2d1_rx_ready           (d2d_rx_ready[instance_count][1]),
	    
	    .d2d2_clk                (d2d_clk[instance_count][2]),
	    .d2d2_rst_n              (d2d_rst_n[instance_count][2]),
	    .d2d2_tx_data            (d2d_tx_data[instance_count][2]),
	    .d2d2_tx_valid           (d2d_tx_valid[instance_count][2]),
	    .d2d2_tx_ready           (d2d_tx_ready[instance_count][2]),
	    .d2d2_rx_data            (d2d_rx_data[instance_count][2]),
	    .d2d2_rx_valid           (d2d_rx_valid[instance_count][2]),
	    .d2d2_rx_ready           (d2d_rx_ready[instance_count][2]),
	    
	    .cpuID                  (cpuID[instance_count])
	    
	    );
      end // for (instance_count = 0; instance_count < 4; instance_count = instance_count + 1)
   endgenerate
   
   
endmodule // package
