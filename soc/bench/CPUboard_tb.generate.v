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
   
   reg		clk, rstn, rstn_dly, pll_rstn, d2d_clk_source, d2d_rstn;
   
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
`ifdef ZEBU
      $dumpfile("wavedump.lxt");
      $dumpvars(10, CPUboard_tb );
`elsif VCS
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
	#0 d2d_clk_source = 1'b0;
	forever
	  #23 d2d_clk_source = !d2d_clk_source;   // 25MHz
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
   
   // Signals for generic_pll
   
   wire [4*32-1:0]	gpio_pad_io;
   wire [31:0]		curr_gpio_pad_io[3:0];
   
   wire	[3:0]		uart_stx_pad_o;
   
   integer		counter[3:0];

   reg [31:0]		old_gpio_val[3:0];
	 
   multi_chip_package pkg
     (
      // Clk and reset
      .clk		(clk),
      .rstn		(rstn),
      
      .d2d_clk_source   (d2d_clk_source),
      .d2d_rstn         (d2d_rstn),

      .gpio_pad_io      (gpio_pad_io),
      
      // UART0
      .uart_srx_pad_i	({1'b1, 1'b1, 1'b1, 1'b1}),  
      .uart_stx_pad_o	(uart_stx_pad_o)
      );
   
   genvar	instance_count;
   
   wire [7:0]	cpuID[3:0];

   generate
      for (instance_count = 0; instance_count < 4; instance_count = instance_count + 1) begin : monitors
	 
	 assign cpuID[instance_count] = instance_count;
	 
	 assign curr_gpio_pad_io[instance_count] = gpio_pad_io[(instance_count+1)*32-1:(instance_count)*32];
	 
	 //==================================================================
	 
	 always @(posedge clk) begin
	    old_gpio_val[instance_count] <= curr_gpio_pad_io[instance_count];
	    if (old_gpio_val[instance_count] != curr_gpio_pad_io[instance_count])
	      $display("[%m]C%d GPIO val = %h", instance_count, curr_gpio_pad_io[instance_count]);
	    
	    if (curr_gpio_pad_io[instance_count] == 32'hc001c0de) begin
	       // 0xff has been written to GPIO, so the
	       // sofware has completed its tests
	       $display("\n\n**** PASS C%d **** indicator for Software execution complete.\n\n", instance_count);
	       $finish();
	    end else if (curr_gpio_pad_io[instance_count] == 32'hdeadbeef) begin
	       // 0x55 has been written to GPIO, so the
	       // there was an error during the tests
	       $display("\n\n**** FAIL C%d **** indicator during Software tests. Finishing simulation.", instance_count);
	       repeat(1000000) @(posedge clk);
	       $finish();
	    end
	 end   
	 
	 
	 always @(posedge clk or posedge rstn) begin
	    if (!rstn) begin
	       counter[instance_count] = 0;
	    end
	    else begin
	       if (counter[instance_count] == 20000000) begin
		  $display("Completed");
		  $finish();
	       end
	       counter[instance_count] = counter[instance_count] + 1;
	    end
	    
	 end
	 
	 uart_mon uart_mon
	   (
	    .clk (clk), // System clock
	    .reset (~rstn), // Reset signal
	    .rx (uart_stx_pad_o[instance_count]),
	    .monID (cpuID[instance_count])
	    );
	 
      end // for (instance_count = 0; instance_count < 4; instance_count = instance_count + 1)
   endgenerate
   
endmodule

module dumpvars;
   initial begin:qiwc
      (*qiwc,no_opt*) $dumpvars(0,"CPUboard_tb"); 
   end
   
endmodule
