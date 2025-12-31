// tb_d2d_link.v
`timescale 1ns/1ps

module tb_d2d_link;

// Parameters
localparam WB_CLK_PERIOD = 10.0; // 100 MHz
localparam D2D_CLK_PERIOD = 12.658; // 79 MHz
localparam TEST_DATA_SIZE = 32; // 32 flits to transfer
localparam TX_MEM_BASE = 32'h0000_1000;
localparam RX_MEM_BASE = 32'h0000_2000;
localparam MEM_SIZE = 1024; // 1024 64-bit words

   localparam TX_DELAY = 5;
   localparam RX_DELAY = 9;

// Clocks and Resets
reg wb_clk;
reg d2d_clk;
reg wb_rst_n;
reg d2d_rst_n;

// Wishbone interfaces
reg csr_wb_cyc_i;
reg csr_wb_stb_i;
reg csr_wb_we_i;
reg [31:0] csr_wb_adr_i;
reg [31:0] csr_wb_dat_i;
wire csr_wb_ack_o;
wire [31:0] csr_wb_dat_o;

wire tx_wb_cyc_o;
wire tx_wb_stb_o;
wire tx_wb_we_o;
wire [31:0] tx_wb_adr_o;
wire [31:0] tx_wb_dat_o;
reg tx_wb_ack_i;
reg [31:0] tx_wb_dat_i;

wire rx_wb_cyc_o;
wire rx_wb_stb_o;
wire rx_wb_we_o;
wire [31:0] rx_wb_adr_o;
wire [31:0] rx_wb_dat_o;
reg rx_wb_ack_i;
reg [31:0] rx_wb_dat_i;

// D2D interfaces
wire [63:0] tx_data;
wire tx_valid;
reg tx_ready;

reg [63:0] rx_data;
reg rx_valid;
wire rx_ready;

// Memories - use associative array for flexible addressing
reg [7:0] system_memory [0:1048575]; // 1MB system memory (byte addressable)

// Testbench variables
integer i, j;
reg [31:0] expected_data;
reg test_pass;
integer errors;
reg [31:0] tx_data_offset;
reg [31:0] rx_data_offset;

// D2D Link DUT
d2d_link_top dut (
    // Wishbone CSR Interface
    .wb_clk(wb_clk),
    .wb_rst_n(wb_rst_n),
    
    // CSR Wishbone Slave
    .csr_wb_cyc_i(csr_wb_cyc_i),
    .csr_wb_stb_i(csr_wb_stb_i),
    .csr_wb_we_i(csr_wb_we_i),
    .csr_wb_adr_i(csr_wb_adr_i),
    .csr_wb_dat_i(csr_wb_dat_i),
    .csr_wb_ack_o(csr_wb_ack_o),
    .csr_wb_dat_o(csr_wb_dat_o),
    
    // TX DMA Wishbone Master
    .tx_wb_cyc_o(tx_wb_cyc_o),
    .tx_wb_stb_o(tx_wb_stb_o),
    .tx_wb_we_o(tx_wb_we_o),
    .tx_wb_adr_o(tx_wb_adr_o),
    .tx_wb_dat_o(tx_wb_dat_o),
    .tx_wb_ack_i(tx_wb_ack_i),
    .tx_wb_dat_i(tx_wb_dat_i),
    
    // RX DMA Wishbone Master
    .rx_wb_cyc_o(rx_wb_cyc_o),
    .rx_wb_stb_o(rx_wb_stb_o),
    .rx_wb_we_o(rx_wb_we_o),
    .rx_wb_adr_o(rx_wb_adr_o),
    .rx_wb_dat_o(rx_wb_dat_o),
    .rx_wb_ack_i(rx_wb_ack_i),
    .rx_wb_dat_i(rx_wb_dat_i),
    
    // D2D Interface
    .d2d_clk(d2d_clk),
    .d2d_rst_n(d2d_rst_n),
    
    // TX D2D Interface
    .tx_data(tx_data),
    .tx_valid(tx_valid),
    .tx_ready(rx_ready),
    
    // RX D2D Interface
    .rx_data(tx_data),
    .rx_valid(tx_valid),
    .rx_ready(rx_ready)
);

   integer tx_dma_delay;
   integer rx_dma_delay;
   
initial begin
   $value$plusargs("tx_dma_delay=%d", tx_dma_delay);
   $value$plusargs("rx_dma_delay=%d", rx_dma_delay);
   $display("using tx_dma_delay(%d) and rx_dma_delay(%d)", tx_dma_delay, rx_dma_delay);
end

// Clock generation
initial begin
    wb_clk = 1'b0;
    forever #(WB_CLK_PERIOD/2) wb_clk = ~wb_clk;
end

initial begin
    d2d_clk = 1'b0;
    forever #(D2D_CLK_PERIOD/2) d2d_clk = ~d2d_clk;
end

// Reset generation
initial begin
    wb_rst_n = 1'b0;
    d2d_rst_n = 1'b0;
    #100;
    wb_rst_n = 1'b1;
    d2d_rst_n = 1'b1;
end

// Function to write 64-bit data to system memory
function void write_memory64;
    input [31:0] addr;
    input [63:0] data;
    integer i;
    begin
        for (i = 0; i < 8; i = i + 1) begin
            system_memory[addr + i] = data[i*8 +: 8];
        end
    end
endfunction

// Function to read 64-bit data from system memory
function [63:0] read_memory64;
    input [31:0] addr;
    integer i;
    begin
        for (i = 0; i < 8; i = i + 1) begin
            read_memory64[i*8 +: 8] = system_memory[addr + i];
        end
    end
endfunction

// Function to read 32-bit data from system memory
function [31:0] read_memory32;
    input [31:0] addr;
    integer i;
    begin
        for (i = 0; i < 4; i = i + 1) begin
            read_memory32[i*8 +: 8] = system_memory[addr + i];
        end
    end
endfunction

// Function to write 32-bit data to system memory
function void write_memory32;
    input [31:0] addr;
    input [31:0] data;
    integer i;
    begin
        for (i = 0; i < 4; i = i + 1) begin
            system_memory[addr + i] = data[i*8 +: 8];
        end
    end
endfunction

// tb_d2d_link.v - Fix for Wishbone acknowledgment handling
// Wishbone Slave Memory Models - FIXED VERSION
always @(posedge wb_clk or negedge wb_rst_n) begin
   if (!wb_rst_n) begin
      tx_wb_ack_i <= 1'b0;
   end
   // TX DMA Memory (source memory) - Read only
   else begin
      if (tx_wb_cyc_o && tx_wb_stb_o && !tx_wb_ack_i) begin
	 // Random latency
	 if ($urandom_range(0, tx_dma_delay) > 0) begin
            repeat($urandom_range(1, tx_dma_delay)) @(posedge wb_clk);
	 end
	 
	 if (!tx_wb_we_o) begin
            // Read from system memory - FIX: send ack for each 32-bit read
            tx_wb_dat_i <= read_memory32(tx_wb_adr_o);
//            $display("[%0t] TX DMA Read: Addr=%h, Data=%h", $time, tx_wb_adr_o, read_memory32(tx_wb_adr_o));
	 end else begin
            // Write to system memory (shouldn't happen for TX DMA)
            write_memory32(tx_wb_adr_o, tx_wb_dat_o);
//            $display("[%0t] TX DMA Write (unexpected): Addr=%h, Data=%h", $time, tx_wb_adr_o, tx_wb_dat_o);
	 end
	 
	 tx_wb_ack_i <= 1'b1;
      end // if (tx_wb_cyc_o && tx_wb_stb_o && !tx_wb_ack_i)
      else begin
	 tx_wb_ack_i <= 1'b0;
      end // else: !if(tx_wb_cyc_o && tx_wb_stb_o && !tx_wb_ack_i)
   end // else: !if(!wb_rst_n)
end // always @ (posedge wb_clk or negedge wb_rst_n)
      
always @(posedge wb_clk or negedge wb_rst_n) begin
   if (!wb_rst_n) begin
      rx_wb_ack_i <= 1'b0;
   end
   // TX DMA Memory (source memory) - Read only
   else begin
      // RX DMA Memory (destination memory) - Write only
      if (rx_wb_cyc_o && rx_wb_stb_o && !rx_wb_ack_i) begin
	 // Random latency
	 if ($urandom_range(0, rx_dma_delay) > 0) begin
            repeat($urandom_range(1, rx_dma_delay)) @(posedge wb_clk);
	 end
	 
	 if (rx_wb_we_o) begin
            // Write to system memory - FIX: send ack for each 32-bit write
            write_memory32(rx_wb_adr_o, rx_wb_dat_o);
//            $display("[%0t] RX DMA Write: Addr=%h, Data=%h", $time, rx_wb_adr_o, rx_wb_dat_o);
	 end else begin
            // Read from system memory
            rx_wb_dat_i <= read_memory32(rx_wb_adr_o);
//            $display("[%0t] RX DMA Read (unexpected): Addr=%h, Data=%h", $time, rx_wb_adr_o, read_memory32(rx_wb_adr_o));
	 end
	 
	 rx_wb_ack_i <= 1'b1;
      end // if (rx_wb_cyc_o && rx_wb_stb_o && !rx_wb_ack_i)
      else begin
	 rx_wb_ack_i <= 1'b0;
      end // else: !if(rx_wb_cyc_o && rx_wb_stb_o && !rx_wb_ack_i)
   end // else: !if(!wb_rst_n)
   
end

// D2D Link Model (connects TX to RX)
reg [63:0] d2d_link_data;
reg d2d_link_valid;
integer d2d_latency_counter;

always @(posedge d2d_clk) begin
    rx_valid <= 1'b0;
    rx_data <= 64'h0;
    tx_ready <= 1'b0;
    
    // Pass through TX data to RX with random latency
    if (tx_valid && !d2d_link_valid) begin
        d2d_latency_counter = $urandom_range(1, 5);
/*
         if (d2d_latency_counter > 0) begin
            // Wait for random number of cycles
            fork
                begin
                    repeat(d2d_latency_counter) @(posedge d2d_clk);
                    d2d_link_data <= tx_data;
                    d2d_link_valid <= 1'b1;
                end
            join_none
        end else
*/
       begin
            d2d_link_data <= tx_data;
            d2d_link_valid <= 1'b1;
        end
    end
    
    // If we have data in the link and RX is ready, deliver it
    if (d2d_link_valid && rx_ready) begin
        rx_data <= d2d_link_data;
        rx_valid <= 1'b1;
        d2d_link_valid <= 1'b0;
    end
    
    // TX can send if RX is ready and no data is in flight
    tx_ready <= rx_ready && !d2d_link_valid;
end

// Wishbone CSR Write Task
task wb_csr_write;
    input [31:0] addr;
    input [31:0] data;
    begin
        @(posedge wb_clk);
        csr_wb_cyc_i = 1'b1;
        csr_wb_stb_i = 1'b1;
        csr_wb_we_i = 1'b1;
        csr_wb_adr_i = addr;
        csr_wb_dat_i = data;
        
        wait(csr_wb_ack_o);
        @(posedge wb_clk);
        csr_wb_cyc_i = 1'b0;
        csr_wb_stb_i = 1'b0;
        csr_wb_we_i = 1'b0;
    end
endtask

// Wishbone CSR Read Task
task wb_csr_read;
    input [31:0] addr;
    output [31:0] data;
    begin
        @(posedge wb_clk);
        csr_wb_cyc_i = 1'b1;
        csr_wb_stb_i = 1'b1;
        csr_wb_we_i = 1'b0;
        csr_wb_adr_i = addr;
        
        wait(csr_wb_ack_o);
        data = csr_wb_dat_o;
        @(posedge wb_clk);
        csr_wb_cyc_i = 1'b0;
        csr_wb_stb_i = 1'b0;
    end
endtask

// Initialize system memory with test data
task init_memory;
    integer i;
    reg [63:0] test_data;
    begin
        // Initialize all memory to zero
        for (i = 0; i < 1048576; i = i + 1) begin
            system_memory[i] = 8'h00;
        end
        
        // Initialize TX source memory area with incrementing pattern
        tx_data_offset = TX_MEM_BASE;
        for (i = 0; i < TEST_DATA_SIZE; i = i + 1) begin
            test_data = {32'h0000_0000 + i, 32'hDEAD_BEEF + i};
            write_memory64(tx_data_offset + (i * 8), test_data);
            $display("Initialized TX memory[%0d] at addr %h = %h", 
                     i, tx_data_offset + (i * 8), test_data);
        end
        
        // Initialize RX destination memory area with zeros
        rx_data_offset = RX_MEM_BASE;
        for (i = 0; i < TEST_DATA_SIZE; i = i + 1) begin
            write_memory64(rx_data_offset + (i * 8), 64'h0);
        end
    end
endtask

// Verify transferred data
task verify_data;
    integer i;
    reg [63:0] expected;
    reg [63:0] received;
    begin
        errors = 0;
        $display("\nVerifying transferred data...");
        
        for (i = 0; i < TEST_DATA_SIZE; i = i + 1) begin
            expected = {32'h0000_0000 + i, 32'hDEAD_BEEF + i};
            received = read_memory64(rx_data_offset + (i * 8));
            
            if (received !== expected) begin
                $display("ERROR: Memory[%0d] at addr %h = %h, Expected = %h", 
                         i, rx_data_offset + (i * 8), received, expected);
                errors = errors + 1;
            end else begin
                $display("OK: Memory[%0d] at addr %h = %h", 
                         i, rx_data_offset + (i * 8), received);
            end
        end
        
        if (errors == 0) begin
            $display("\nPASS: All %0d data flits transferred correctly", TEST_DATA_SIZE);
            test_pass = 1'b1;
        end else begin
            $display("\nFAIL: %0d errors found", errors);
            test_pass = 1'b0;
        end
    end
endtask

// Monitor D2D transactions
always @(posedge d2d_clk) begin
    if (tx_valid && tx_ready) begin
        $display("[%0t] D2D TX: Data=%h", $time, tx_data);
    end
    if (rx_valid && rx_ready) begin
        $display("[%0t] D2D RX: Data=%h", $time, rx_data);
    end
end

// Main test sequence
initial begin
    // Initialize
    csr_wb_cyc_i = 1'b0;
    csr_wb_stb_i = 1'b0;
    csr_wb_we_i = 1'b0;
    csr_wb_adr_i = 32'h0;
    csr_wb_dat_i = 32'h0;
    tx_ready = 1'b0;
    rx_valid = 1'b0;
    rx_data = 64'h0;
    d2d_link_data = 64'h0;
    d2d_link_valid = 1'b0;
    test_pass = 1'b0;
    errors = 0;
    
    // Initialize memory with test data
    init_memory();
    
    // Wait for reset
    #200;
    
    $display("\n[%0t] ===========================================", $time);
    $display("[%0t] Starting D2D Link Test", $time);
    $display("[%0t] Test Data Size: %0d flits (512 bytes)", $time, TEST_DATA_SIZE);
    $display("[%0t] TX Source: 0x%h", $time, TX_MEM_BASE);
    $display("[%0t] RX Destination: 0x%h", $time, RX_MEM_BASE);
    $display("[%0t] ===========================================\n", $time);
    
    // Enable TX and RX
    wb_csr_write(8'h04, 32'h0000_0030); // Enable TX and RX
    $display("[%0t] Enabled TX and RX", $time);
    
    // Configure TX DMA
    wb_csr_write(8'h08, TX_MEM_BASE); // TX source address
    wb_csr_write(8'h0C, 32'h0); // TX dest address (not used)
    wb_csr_write(8'h10, TEST_DATA_SIZE); // TX length
    $display("[%0t] Configured TX DMA: Src=0x%h, Len=%0d", 
             $time, TX_MEM_BASE, TEST_DATA_SIZE);
    
    // Configure RX DMA
    wb_csr_write(8'h14, 32'h0); // RX source address (not used)
    wb_csr_write(8'h18, RX_MEM_BASE); // RX dest address
    wb_csr_write(8'h1C, TEST_DATA_SIZE); // RX length
    $display("[%0t] Configured RX DMA: Dest=0x%h, Len=%0d", 
             $time, RX_MEM_BASE, TEST_DATA_SIZE);
    
    // Start RX first (wait for incoming data)
    wb_csr_write(8'h04, 32'h0000_0032); // Start RX
    $display("[%0t] Started RX DMA", $time);
    
    // Wait a bit
    #100;
    
    // Start TX
    wb_csr_write(8'h04, 32'h0000_0033); // Start TX
    $display("[%0t] Started TX DMA", $time);
    
    // Wait for completion
    $display("\n[%0t] Waiting for transfers to complete...", $time);
    
    // Poll status register
    begin
        reg [31:0] status;
        reg transfers_done;
        integer timeout;
        integer poll_count;
        
        transfers_done = 1'b0;
        timeout = 0;
        poll_count = 0;
        
        while (timeout < 10000 && !transfers_done) begin
            wb_csr_read(8'h00, status);
            poll_count = poll_count + 1;
            
            if (poll_count % 100 == 0) begin
                $display("[%0t] Polling status: TX_DONE=%b, RX_DONE=%b, TX_BUSY=%b, RX_BUSY=%b",
                         $time, status[0], status[1], status[2], status[3]);
            end
            
            if (status[0] && status[1]) begin // Both TX and RX done
                $display("\n[%0t] Transfers completed!", $time);
                $display("[%0t] Final Status: TX_DONE=%b, RX_DONE=%b, TX_BUSY=%b, RX_BUSY=%b",
                         $time, status[0], status[1], status[2], status[3]);
                transfers_done = 1'b1;
            end else begin
                #100;
                timeout = timeout + 1;
            end
        end
        
        if (timeout >= 10000) begin
            $display("\n[%0t] ERROR: Timeout waiting for transfers", $time);
            $display("[%0t] Final Status: TX_DONE=%b, RX_DONE=%b, TX_BUSY=%b, RX_BUSY=%b",
                     $time, status[0], status[1], status[2], status[3]);
            $finish;
        end
    end
    
    // Wait a bit more for any pending writes
    #1000;
    
    // Verify data
    verify_data();
    
    // Print summary
    $display("\n[%0t] ===========================================", $time);
    if (test_pass) begin
        $display("[%0t] TEST PASSED tx_delay(%d) rx_delay(%d)", $time, tx_dma_delay, rx_dma_delay);
    end else begin
        $display("[%0t] TEST FAILED tx_delay(%d) rx_delay(%d) with %0d errors", $time, tx_dma_delay, rx_dma_delay, errors);
    end
    $display("[%0t] ===========================================\n", $time);
    
    #100;
    $finish;
end

// VCD dump
initial begin
    $dumpfile("d2d_link.vcd");
    $dumpvars(0, tb_d2d_link);
    // Add specific signals to dump
    $dumpvars(1, dut);
end

// Timeout watch
initial begin
    #20000000; // 20ms timeout (more generous for simulation)
    $display("\n[%0t] ERROR: Simulation timeout", $time);
    $finish;
end

endmodule // tb_d2d_link
