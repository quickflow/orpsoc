// =============================================================================
// Module: flash_model_8bit_parallel
// Description: Behavioral Verilog model for a simple 8-bit parallel flash memory.
//              Models read access and simplified command sequence detection 
//              (e.g., for unlock and program) typical of NOR flash devices.
//
// Capacity: 16 MB (24 address bits)
// =============================================================================
`timescale 1ns / 1ps

module i28f016s3
  (
   rpb,
   ceb,
   oeb,
   web,
   ryby,
   dq,
   addr,
   vpp,
   vcc,
   rpblevel
   );
   input	     rpb;
   input	     ceb;
   input	     oeb;
   input	     web;
   output	     ryby;
   inout [7:0]	     dq;
   input [20:0]	     addr;
   input [31:0]	     vpp;
   input [31:0]	     vcc;
   input [1:0]	     rpblevel;

   wire		     RST_N = rpb;
   wire [20:0]	     A = addr;
   wire		     CE_N = ceb;
   wire		     OE_N = oeb;
   wire		     WE_N = web;

   wire		     ryby = 1;
   
    // --- Configuration and Memory Array ---
    localparam ADDR_BITS = 21;
    localparam MEM_SIZE = 1 << ADDR_BITS; // 16 MB
    
    // Internal Memory Array: 16M locations of 8-bit data
    reg [7:0] memory [0:MEM_SIZE-1];
    
    // --- Internal State and Command Registers (Simplified Flash State) ---
    
    // --- Tri-state Driver (DQ Output) ---
    // The DQ bus is driven by the internal register only during a Read operation.
    // Read Condition: Chip Enabled (CE_N=0), Output Enabled (OE_N=0), Write Disabled (WE_N=1)
    assign dq = (!CE_N && !OE_N && WE_N) ? memory[A] : 8'bz;

    // =========================================================================
    // 1. Memory Initialization
    // =========================================================================
    initial begin
        $display("%m:: Initializing 8-bit Flash Memory Model (%0d MB)", MEM_SIZE / 1024 / 1024);
        // Load contents from a file if necessary (e.g., using $readmemh)
        // For simulation, initialize to a known pattern
        $readmemh("flash.in", memory); 
    end

endmodule // flash_model_8bit_parallel
