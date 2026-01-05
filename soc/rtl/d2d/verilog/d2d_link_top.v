// d2d_link_top.v
`timescale 1ns/1ps

module d2d_link_top
  (
   // Wishbone CSR Interface (shared clock domain)
   input wire	     wb_clk,
   input wire	     wb_rst_n,
   
   // CSR Wishbone Slave Interface
   input wire	     csr_wb_cyc_i,
   input wire	     csr_wb_stb_i,
   input wire	     csr_wb_we_i,
   input wire [31:0] csr_wb_adr_i,
   input wire [31:0] csr_wb_dat_i,
   output reg	     csr_wb_ack_o,
   output reg [31:0] csr_wb_dat_o,
   
   // TX DMA Wishbone Master Interface
   output reg	     tx_wb_cyc_o,
   output reg	     tx_wb_stb_o,
   output reg	     tx_wb_we_o,
   output reg [31:0] tx_wb_adr_o,
   output reg [31:0] tx_wb_dat_o,
   input wire	     tx_wb_ack_i,
   input wire [31:0] tx_wb_dat_i,
   
   // RX DMA Wishbone Master Interface
   output reg	     rx_wb_cyc_o,
   output reg	     rx_wb_stb_o,
   output reg	     rx_wb_we_o,
   output reg [31:0] rx_wb_adr_o,
   output reg [31:0] rx_wb_dat_o,
   input wire	     rx_wb_ack_i,
   input wire [31:0] rx_wb_dat_i,
   
   // D2D Interface (asynchronous clock domain)
   input wire	     d2d_clk,
   input wire	     d2d_rst_n,
   
   // TX D2D Interface
   output reg [63:0] tx_data,
   output reg	     tx_valid,
   input wire	     tx_ready,
   
   // RX D2D Interface
   input wire [63:0] rx_data,
   input wire	     rx_valid,
   output reg	     rx_ready,

   input wire [7:0]  cpuID
   );
   
   // TX FIFO status sync to wb domain
   reg [2:0] tx_fifo_full_sync;
   reg [2:0] tx_fifo_empty_sync;
   
   // RX FIFO status sync to wb domain
   reg [2:0] rx_fifo_full_sync;
   reg [2:0] rx_fifo_empty_sync;
   
   reg [63:0] tx_fifo [0:7];
   reg [3:0]  tx_fifo_wr_ptr;
   reg [3:0]  tx_fifo_rd_ptr;
   reg [3:0]  tx_fifo_count;
   wire	      tx_fifo_full;
   wire	      tx_fifo_empty;
   
   reg tx_dma_busy;
   reg tx_dma_done;
   reg [31:0] tx_dma_current_addr;
   reg [31:0] tx_dma_remaining;
   reg [2:0]  tx_dma_state;  // Changed from [1:0] to [2:0]
   reg	      tx_fifo_wr_en;
   reg [63:0] tx_fifo_wdata;
   
   reg [2:0] tx_fifo_rd_ptr_gray_d2d;
   reg [2:0] tx_fifo_rd_ptr_gray_d2d_sync1;
   reg [2:0] tx_fifo_rd_ptr_gray_d2d_sync2;
   reg [2:0] tx_fifo_rd_ptr_wb_bin;

   reg [3:0] tx_fifo_rd_ptr_d2d, n_tx_fifo_rd_ptr_d2d;
   reg [3:0] tx_fifo_count_d2d;
   reg [2:0] tx_fifo_rd_ptr_gray;
   reg [2:0] tx_fifo_rd_ptr_gray_sync;
   reg [2:0] tx_fifo_wr_ptr_gray;
   reg [2:0] tx_fifo_wr_ptr_gray_sync;
   
   reg [2:0] wr_ptr_bin;
   reg [2:0] rd_ptr_bin;

   reg [63:0] rx_fifo [0:7];
   reg [3:0]  rx_fifo_wr_ptr;
   reg [3:0]  rx_fifo_rd_ptr_wb;
   reg [3:0]  rx_fifo_count;
   wire	      rx_fifo_full;
   wire	      rx_fifo_empty;
   
   // CDC synchronization for RX FIFO write pointer from d2d_clk to wb_clk domain
   reg [2:0]  rx_fifo_wr_ptr_gray_d2d;
   reg [2:0]  rx_fifo_wr_ptr_gray_d2d_sync1;
   reg [2:0]  rx_fifo_wr_ptr_gray_d2d_sync2;
   reg [2:0]  rx_fifo_wr_ptr_wb_bin;
   
   // CDC synchronization for RX FIFO read pointer from wb_clk to d2d_clk domain
   reg [2:0]  rx_fifo_rd_ptr_wb_gray;
   reg [2:0]  rx_fifo_rd_ptr_wb_gray_sync1;
   reg [2:0]  rx_fifo_rd_ptr_wb_gray_sync2;
   reg [2:0]  rx_fifo_rd_ptr_d2d_bin;
   
   reg [1:0] rx_d2d_state;  // Changed from 1-bit to 2-bit for consistency
   reg [1:0] n_rx_d2d_state;
   
   reg	     rx_fifo_wr_en;
   reg [63:0] rx_fifo_wdata;
   
   reg rx_dma_busy;
   reg rx_dma_done;
   reg [31:0] rx_dma_current_addr;
   reg [31:0] rx_dma_remaining;
   reg [2:0]  rx_dma_state;  // Changed from [1:0] to [2:0]
   reg [63:0] rx_fifo_rdata;
   
   localparam RX_DMA_IDLE = 3'd0;
   localparam RX_DMA_WRITE = 3'd1;
   localparam RX_DMA_WAIT_FIRST = 3'd2;
   localparam RX_DMA_WAIT_SECOND = 3'd3;
   localparam RX_DMA_WAIT_SECOND2 = 3'd4;
   localparam RX_DMA_DONE = 3'd5;
   
   localparam RX_D2D_IDLE = 2'd0;
   localparam RX_D2D_RECEIVE = 2'd1;
   
   localparam TX_DMA_IDLE = 3'd0;
   localparam TX_DMA_FETCH = 3'd1;
   localparam TX_DMA_WAIT = 3'd2;
   localparam TX_DMA_WAIT2 = 3'd3;
   localparam TX_DMA_WAIT3 = 3'd4;
   localparam TX_DMA_DONE = 3'd5;
   
   localparam RX_FIFO_LAST_ENTRY=7;
   localparam TX_FIFO_LAST_ENTRY=7;

   // ============================================================================
   // CSR Register Definitions and State Machine
   // ============================================================================
   
   // CSR Address Map
   localparam	     CSR_STATUS      = 8'h00;
   localparam	     CSR_CONTROL     = 8'h04;
   localparam	     CSR_TX_SRC_ADDR = 8'h08;
   localparam	     CSR_TX_DEST_ADDR = 8'h0C;
   localparam	     CSR_TX_LENGTH   = 8'h10;
   localparam	     CSR_RX_SRC_ADDR = 8'h14;
   localparam	     CSR_RX_DEST_ADDR = 8'h18;
   localparam	     CSR_RX_LENGTH   = 8'h1C;
   
   // Status Register Bits
   localparam	     STATUS_TX_DONE = 0;
   localparam	     STATUS_RX_DONE = 1;
   localparam	     STATUS_TX_BUSY = 2;
   localparam	     STATUS_RX_BUSY = 3;
   localparam	     STATUS_TX_FIFO_FULL = 4;
   localparam	     STATUS_TX_FIFO_EMPTY = 5;
   localparam	     STATUS_RX_FIFO_FULL = 6;
   localparam	     STATUS_RX_FIFO_EMPTY = 7;
   localparam	     STATUS_TX_ERROR = 8;
   localparam	     STATUS_RX_ERROR = 9;
   
   // Control Register Bits
   localparam	     CONTROL_TX_START = 0;
   localparam	     CONTROL_RX_START = 1;
   localparam	     CONTROL_TX_RESET = 2;
   localparam	     CONTROL_RX_RESET = 3;
   localparam	     CONTROL_TX_ENABLE = 4;
   localparam	     CONTROL_RX_ENABLE = 5;
   
   // CSR Registers
   reg [31:0]	     csr_status;
   reg [31:0]	     csr_control;
   reg [31:0]	     tx_src_addr;
   reg [31:0]	     tx_dest_addr;
   reg [31:0]	     tx_length;
   reg [31:0]	     rx_src_addr;
   reg [31:0]	     rx_dest_addr;
   reg [31:0]	     rx_length;
   
   // Gray code conversion functions - MUST BE DECLARED BEFORE USE
   function [2:0] bin2gray;
      input [2:0] bin;
      begin
         bin2gray = {bin[2], bin[2] ^ bin[1], bin[1] ^ bin[0]};
      end
   endfunction
   
   function [2:0] gray2bin;
      input [2:0] gray;
      reg [2:0]	  result;
      begin
         result[2] = gray[2];
         result[1] = gray[2] ^ gray[1];
         result[0] = gray[2] ^ gray[1] ^ gray[0];
         gray2bin = result;
      end
   endfunction
   
   // CSR Wishbone Interface
   always @(posedge wb_clk or negedge wb_rst_n) begin
      if (!wb_rst_n) begin
         csr_wb_ack_o <= 1'b0;
         csr_wb_dat_o <= 32'h0;
         csr_status <= 32'h0;
         csr_control <= 32'h0;
         tx_src_addr <= 32'h0;
         tx_dest_addr <= 32'h0;
         tx_length <= 32'h0;
         rx_src_addr <= 32'h0;
         rx_dest_addr <= 32'h0;
         rx_length <= 32'h0;
      end else begin
         csr_wb_ack_o <= 1'b0;
         
         if (csr_wb_cyc_i && csr_wb_stb_i && !csr_wb_ack_o) begin
            csr_wb_ack_o <= 1'b1;
            
            if (csr_wb_we_i) begin
               // Write operation
               case (csr_wb_adr_i[7:0])
                 CSR_STATUS: begin
                    // Status is read-only, ignore writes
                 end
                 CSR_CONTROL: begin
                    csr_control <= csr_wb_dat_i;
                 end
                 CSR_TX_SRC_ADDR: begin
                    tx_src_addr <= csr_wb_dat_i;
                 end
                 CSR_TX_DEST_ADDR: begin
                    tx_dest_addr <= csr_wb_dat_i;
                 end
                 CSR_TX_LENGTH: begin
                    tx_length <= csr_wb_dat_i;
                 end
                 CSR_RX_SRC_ADDR: begin
                    rx_src_addr <= csr_wb_dat_i;
                 end
                 CSR_RX_DEST_ADDR: begin
                    rx_dest_addr <= csr_wb_dat_i;
                 end
                 CSR_RX_LENGTH: begin
                    rx_length <= csr_wb_dat_i;
                 end
                 default: begin
                    // Ignore
                 end
               endcase
            end else begin
               // Read operation
               case (csr_wb_adr_i[7:0])
                 CSR_STATUS: begin
                    csr_wb_dat_o <= csr_status;
                 end
                 CSR_CONTROL: begin
                    csr_wb_dat_o <= csr_control;
                 end
                 CSR_TX_SRC_ADDR: begin
                    csr_wb_dat_o <= tx_src_addr;
                 end
                 CSR_TX_DEST_ADDR: begin
                    csr_wb_dat_o <= tx_dest_addr;
                 end
                 CSR_TX_LENGTH: begin
                    csr_wb_dat_o <= tx_length;
                 end
                 CSR_RX_SRC_ADDR: begin
                    csr_wb_dat_o <= rx_src_addr;
                 end
                 CSR_RX_DEST_ADDR: begin
                    csr_wb_dat_o <= rx_dest_addr;
                 end
                 CSR_RX_LENGTH: begin
                    csr_wb_dat_o <= rx_length;
                 end
                 default: begin
                    csr_wb_dat_o <= 32'hDEADBEEF;
                 end
               endcase
            end
         end
      end
   end
   
   // ============================================================================
   // Clock Domain Crossing Synchronizers
   // ============================================================================
   
   // Control signals from WB to D2D clock domain
   reg [2:0] tx_start_sync;
   reg [2:0] rx_start_sync;
   reg [2:0] tx_enable_sync;
   reg [2:0] rx_enable_sync;
   reg [2:0] tx_reset_sync;
   reg [2:0] rx_reset_sync;
   
   // Status signals from D2D to WB clock domain
   reg [2:0] tx_done_sync;
   reg [2:0] rx_done_sync;
   reg [2:0] tx_busy_sync;
   reg [2:0] rx_busy_sync;
   
   // Synchronizers for WB -> D2D signals
   always @(posedge d2d_clk or negedge d2d_rst_n) begin
      if (!d2d_rst_n) begin
         tx_start_sync <= 3'b0;
         rx_start_sync <= 3'b0;
         tx_enable_sync <= 3'b0;
         rx_enable_sync <= 3'b0;
         tx_reset_sync <= 3'b0;
         rx_reset_sync <= 3'b0;
      end else begin
         tx_start_sync <= {tx_start_sync[1:0], csr_control[CONTROL_TX_START]};
         rx_start_sync <= {rx_start_sync[1:0], csr_control[CONTROL_RX_START]};
         tx_enable_sync <= {tx_enable_sync[1:0], csr_control[CONTROL_TX_ENABLE]};
         rx_enable_sync <= {rx_enable_sync[1:0], csr_control[CONTROL_RX_ENABLE]};
         tx_reset_sync <= {tx_reset_sync[1:0], csr_control[CONTROL_TX_RESET]};
         rx_reset_sync <= {rx_reset_sync[1:0], csr_control[CONTROL_RX_RESET]};
      end
   end
   
   // Synchronizers for D2D -> WB signals
   always @(posedge wb_clk or negedge wb_rst_n) begin
      if (!wb_rst_n) begin
         tx_done_sync <= 3'b0;
         rx_done_sync <= 3'b0;
         tx_busy_sync <= 3'b0;
         rx_busy_sync <= 3'b0;
      end else begin
         tx_done_sync <= {tx_done_sync[1:0], tx_dma_done};
         rx_done_sync <= {rx_done_sync[1:0], rx_dma_done};
         tx_busy_sync <= {tx_busy_sync[1:0], tx_dma_busy};
         rx_busy_sync <= {rx_busy_sync[1:0], rx_dma_busy};
      end
   end
   
   // Update status register
   always @(posedge wb_clk or negedge wb_rst_n) begin
      if (!wb_rst_n) begin
         csr_status <= 32'h0;
         tx_fifo_full_sync <= 3'b0;
         tx_fifo_empty_sync <= 3'b0;
         rx_fifo_full_sync <= 3'b0;
         rx_fifo_empty_sync <= 3'b0;
      end else begin
         tx_fifo_full_sync <= {tx_fifo_full_sync[1:0], tx_fifo_full};
         tx_fifo_empty_sync <= {tx_fifo_empty_sync[1:0], tx_fifo_empty};
         rx_fifo_full_sync <= {rx_fifo_full_sync[1:0], rx_fifo_full};
         rx_fifo_empty_sync <= {rx_fifo_empty_sync[1:0], rx_fifo_empty};
         
         csr_status[STATUS_TX_DONE] <= tx_done_sync[2];
         csr_status[STATUS_RX_DONE] <= rx_done_sync[2];
         csr_status[STATUS_TX_BUSY] <= tx_busy_sync[2];
         csr_status[STATUS_RX_BUSY] <= rx_busy_sync[2];
         csr_status[STATUS_TX_FIFO_FULL] <= tx_fifo_full_sync[2];
         csr_status[STATUS_TX_FIFO_EMPTY] <= tx_fifo_empty_sync[2];
         csr_status[STATUS_RX_FIFO_FULL] <= rx_fifo_full_sync[2];
         csr_status[STATUS_RX_FIFO_EMPTY] <= rx_fifo_empty_sync[2];

	 csr_status[31:24] <= cpuID;
	 
      end
   end
   
   // ============================================================================
   // TX FIFO (8 flits deep, 64-bit wide)
   // ============================================================================
   
   assign tx_fifo_full = (tx_fifo_count == TX_FIFO_LAST_ENTRY);
   assign tx_fifo_empty = (tx_fifo_count == 4'd0);
   
   // CDC synchronization for TX FIFO read pointer from d2d_clk to wb_clk domain
   
   // Capture read pointer in d2d_clk domain and convert to gray code
   always @(posedge d2d_clk or negedge d2d_rst_n) begin
      if (!d2d_rst_n) begin
         tx_fifo_rd_ptr_gray_d2d <= 3'b0;
      end else begin
         tx_fifo_rd_ptr_gray_d2d <= bin2gray(tx_fifo_rd_ptr_d2d[2:0]);
      end
   end
   
   // Synchronize gray-coded read pointer to wb_clk domain
   always @(posedge wb_clk or negedge wb_rst_n) begin
      if (!wb_rst_n) begin
         tx_fifo_rd_ptr_gray_d2d_sync1 <= 3'b0;
         tx_fifo_rd_ptr_gray_d2d_sync2 <= 3'b0;
         tx_fifo_rd_ptr_wb_bin <= 3'b0;
      end else begin
         tx_fifo_rd_ptr_gray_d2d_sync1 <= tx_fifo_rd_ptr_gray_d2d;
         tx_fifo_rd_ptr_gray_d2d_sync2 <= tx_fifo_rd_ptr_gray_d2d_sync1;
         
         // Convert synchronized gray code back to binary for wb_clk domain
         tx_fifo_rd_ptr_wb_bin <= gray2bin(tx_fifo_rd_ptr_gray_d2d_sync2);
      end
   end
   
   // TX FIFO write (from DMA in wb_clk domain) - UPDATED VERSION
   always @(posedge wb_clk or negedge wb_rst_n) begin
      if (!wb_rst_n) begin
         tx_fifo_wr_ptr <= 4'b0;
         tx_fifo_rd_ptr <= 4'b0;  // Initialize read pointer in wb domain
         tx_fifo_count <= 4'b0;
      end else begin
         // Update write pointer and count on write
         if (tx_fifo_wr_en && !tx_fifo_full) begin
            tx_fifo[tx_fifo_wr_ptr[2:0]] <= tx_fifo_wdata;
            tx_fifo_wr_ptr <= tx_fifo_wr_ptr + 1;
         end
         
         // Update read pointer from synchronized value
         tx_fifo_rd_ptr[2:0] <= tx_fifo_rd_ptr_wb_bin;
         tx_fifo_rd_ptr[3] <= 1'b0; // MSB is not needed for 8-entry FIFO
         
         // Calculate FIFO count based on synchronized read pointer
         if (tx_fifo_wr_ptr[2:0] >= tx_fifo_rd_ptr[2:0]) begin
            tx_fifo_count <= {1'b0, tx_fifo_wr_ptr[2:0]} - {1'b0, tx_fifo_rd_ptr[2:0]};
         end else begin
            tx_fifo_count <= 4'd8 - ({1'b0, tx_fifo_rd_ptr[2:0]} - {1'b0, tx_fifo_wr_ptr[2:0]});
         end
      end
   end
   
   // CDC for TX FIFO read side (d2d_clk domain) - UPDATED VERSION
            
   // Convert write pointer to gray code and sync to d2d domain
   always @(posedge wb_clk or negedge wb_rst_n) begin
      if (!wb_rst_n) begin
         tx_fifo_wr_ptr_gray <= 3'b0;
      end else begin
         tx_fifo_wr_ptr_gray <= bin2gray(tx_fifo_wr_ptr[2:0]);
      end
   end
   
   wire [3:0] tx_fifo_count_d2d_combo =
	      (wr_ptr_bin >= n_tx_fifo_rd_ptr_d2d[2:0]) ? {1'b0, wr_ptr_bin} - {1'b0, n_tx_fifo_rd_ptr_d2d[2:0]} :
	                                   4'd8 - ({1'b0, n_tx_fifo_rd_ptr_d2d[2:0]} - {1'b0, wr_ptr_bin});
	      

   always @(posedge d2d_clk or negedge d2d_rst_n) begin
      if (!d2d_rst_n) begin
         tx_fifo_wr_ptr_gray_sync <= 3'b0;
         tx_fifo_rd_ptr_gray_sync <= 3'b0;
         tx_fifo_count_d2d <= 4'b0;
         tx_fifo_rd_ptr_d2d <= 4'b0;
      end else begin
         tx_fifo_wr_ptr_gray_sync <= tx_fifo_wr_ptr_gray;
         tx_fifo_rd_ptr_gray_sync <= tx_fifo_rd_ptr_gray;
         
         // Calculate FIFO count in d2d domain
         begin
            // Convert gray codes back to binary
            wr_ptr_bin <= gray2bin(tx_fifo_wr_ptr_gray_sync);
            rd_ptr_bin <= n_tx_fifo_rd_ptr_d2d[2:0];
            
            // Calculate count
	    tx_fifo_count_d2d <= tx_fifo_count_d2d_combo;
         end
      end
   end
   
   // ============================================================================
   // RX FIFO (8 flits deep, 64-bit wide)
   // ============================================================================
   
   assign rx_fifo_full = (rx_fifo_count == RX_FIFO_LAST_ENTRY);
   assign rx_fifo_empty = (rx_fifo_count == 4'd0);
   
   // Capture write pointer in d2d_clk domain and convert to gray code
   always @(posedge d2d_clk or negedge d2d_rst_n) begin
      if (!d2d_rst_n) begin
	 rx_fifo_wr_ptr_gray_d2d <= 3'b0;
      end else begin
	 rx_fifo_wr_ptr_gray_d2d <= bin2gray(rx_fifo_wr_ptr[2:0]);
      end
   end
   
   // Synchronize gray-coded write pointer to wb_clk domain
   always @(posedge wb_clk or negedge wb_rst_n) begin
      if (!wb_rst_n) begin
	 rx_fifo_wr_ptr_gray_d2d_sync1 <= 3'b0;
	 rx_fifo_wr_ptr_gray_d2d_sync2 <= 3'b0;
	 rx_fifo_wr_ptr_wb_bin <= 3'b0;
      end else begin
	 rx_fifo_wr_ptr_gray_d2d_sync1 <= rx_fifo_wr_ptr_gray_d2d;
	 rx_fifo_wr_ptr_gray_d2d_sync2 <= rx_fifo_wr_ptr_gray_d2d_sync1;
	 
	 // Convert synchronized gray code back to binary for wb_clk domain
	 rx_fifo_wr_ptr_wb_bin <= gray2bin(rx_fifo_wr_ptr_gray_d2d_sync2);
      end
   end
   
   // Convert read pointer to Gray code in wb_clk domain
   always @(posedge wb_clk or negedge wb_rst_n) begin
      if (!wb_rst_n) begin
	 rx_fifo_rd_ptr_wb_gray <= 3'b0;
      end else begin
	 rx_fifo_rd_ptr_wb_gray <= bin2gray(rx_fifo_rd_ptr_wb[2:0]);
      end
   end
   
   // Synchronize Gray code to d2d_clk domain
   always @(posedge d2d_clk or negedge d2d_rst_n) begin
      if (!d2d_rst_n) begin
	 rx_fifo_rd_ptr_wb_gray_sync1 <= 3'b0;
	 rx_fifo_rd_ptr_wb_gray_sync2 <= 3'b0;
	 rx_fifo_rd_ptr_d2d_bin <= 3'b0;
      end else begin
	 rx_fifo_rd_ptr_wb_gray_sync1 <= rx_fifo_rd_ptr_wb_gray;
	 rx_fifo_rd_ptr_wb_gray_sync2 <= rx_fifo_rd_ptr_wb_gray_sync1;
	 
	 // Convert synchronized Gray code back to binary for d2d_clk domain
	 rx_fifo_rd_ptr_d2d_bin <= gray2bin(rx_fifo_rd_ptr_wb_gray_sync2);
      end
   end
   
   wire [3:0] rx_fifo_wr_ptr_inc = rx_fifo_wr_ptr + 1;

   // RX FIFO write (from D2D interface in d2d_clk domain) - FIXED VERSION
   always @(posedge d2d_clk or negedge d2d_rst_n) begin
      if (!d2d_rst_n) begin
	 rx_fifo_wr_ptr <= 4'b0;
	 rx_fifo_count <= 4'b0;
      end else begin
	 if (rx_fifo_wr_en && !rx_fifo_full) begin
            rx_fifo[rx_fifo_wr_ptr[2:0]] <= rx_fifo_wdata;
            rx_fifo_wr_ptr <= rx_fifo_wr_ptr_inc;
	 
	    // Calculate FIFO count in d2d domain using SYNCHRONIZED read pointer
	    if (rx_fifo_wr_ptr_inc[2:0] >= rx_fifo_rd_ptr_d2d_bin) begin
               rx_fifo_count <= {1'b0, rx_fifo_wr_ptr_inc[2:0]} - {1'b0, rx_fifo_rd_ptr_d2d_bin};
	    end else begin
               rx_fifo_count <= 4'd8 - ({1'b0, rx_fifo_rd_ptr_d2d_bin} - {1'b0, rx_fifo_wr_ptr_inc[2:0]});
	    end
	 end else begin // if (rx_fifo_wr_en && !rx_fifo_full)
	    // Calculate FIFO count in d2d domain using SYNCHRONIZED read pointer
	    // FIX: Use rx_fifo_rd_ptr_d2d_bin instead of rx_fifo_rd_ptr_wb
	    if (rx_fifo_wr_ptr[2:0] >= rx_fifo_rd_ptr_d2d_bin) begin
               rx_fifo_count <= {1'b0, rx_fifo_wr_ptr[2:0]} - {1'b0, rx_fifo_rd_ptr_d2d_bin};
	    end else begin
               rx_fifo_count <= 4'd8 - ({1'b0, rx_fifo_rd_ptr_d2d_bin} - {1'b0, rx_fifo_wr_ptr[2:0]});
	    end
	 end // else: !if(rx_fifo_wr_en && !rx_fifo_full)
      end // else: !if(!d2d_rst_n)
   end // always @ (posedge d2d_clk or negedge d2d_rst_n)
   
   // RX FIFO read side in wb_clk domain - FIXED VERSION
   reg [3:0] rx_fifo_count_wb;
   
   always @(posedge wb_clk or negedge wb_rst_n) begin
      if (!wb_rst_n) begin
	 rx_fifo_count_wb <= 4'b0;
	 rx_fifo_rd_ptr_wb <= 4'b0;
      end else begin
	 // Calculate FIFO count in wb domain based on synchronized write pointer
	 if (rx_fifo_wr_ptr_wb_bin >= rx_fifo_rd_ptr_wb[2:0]) begin
            rx_fifo_count_wb <= {1'b0, rx_fifo_wr_ptr_wb_bin} - {1'b0, rx_fifo_rd_ptr_wb[2:0]};
	 end else begin
            rx_fifo_count_wb <= 4'd8 - ({1'b0, rx_fifo_rd_ptr_wb[2:0]} - {1'b0, rx_fifo_wr_ptr_wb_bin});
	 end
      end
   end

   // ============================================================================
   // TX DMA Engine
   // ============================================================================
   
   // Wishbone master for TX DMA
   always @(posedge wb_clk or negedge wb_rst_n) begin
      if (!wb_rst_n) begin
         tx_wb_cyc_o <= 1'b0;
         tx_wb_stb_o <= 1'b0;
         tx_wb_we_o <= 1'b0;
         tx_wb_adr_o <= 32'h0;
         tx_wb_dat_o <= 32'h0;
         tx_dma_busy <= 1'b0;
         tx_dma_done <= 1'b0;
         tx_dma_current_addr <= 32'h0;
         tx_dma_remaining <= 32'h0;
         tx_dma_state <= TX_DMA_IDLE;
         tx_fifo_wr_en <= 1'b0;
         tx_fifo_wdata <= 64'h0;
      end else begin
         tx_fifo_wr_en <= 1'b0;
         
         case (tx_dma_state)
           TX_DMA_IDLE: begin
              if (csr_control[CONTROL_TX_START] && csr_control[CONTROL_TX_ENABLE] && 
                  !csr_control[CONTROL_TX_RESET]) begin
                 tx_dma_current_addr <= tx_src_addr;
                 tx_dma_remaining <= tx_length;
                 tx_dma_busy <= 1'b1;
                 tx_dma_done <= 1'b0;
                 tx_dma_state <= TX_DMA_FETCH;
              end
           end
           
           TX_DMA_FETCH: begin
              if (!tx_fifo_full && tx_dma_remaining > 0) begin
                 // Start read transaction for lower 32 bits
                 tx_wb_cyc_o <= 1'b1;
                 tx_wb_stb_o <= 1'b1;
                 tx_wb_we_o <= 1'b0;
                 tx_wb_adr_o <= tx_dma_current_addr;
                 tx_dma_state <= TX_DMA_WAIT;
              end else if (tx_dma_remaining == 0) begin
                 tx_dma_state <= TX_DMA_DONE;
              end
           end
           
           TX_DMA_WAIT: begin
              if (tx_wb_ack_i) begin
                 // Store lower 32 bits
                 tx_fifo_wdata[31:0] <= tx_wb_dat_i;
                 
                 // Read upper 32 bits
                 tx_wb_adr_o <= tx_dma_current_addr + 4;
                 tx_wb_stb_o <= 1'b1;
                 
                 tx_dma_state <= TX_DMA_WAIT2;
              end
           end // case: TX_DMA_WAIT
           
           
           TX_DMA_WAIT2: begin
              // Wait for second ack
              if (tx_wb_ack_i && !tx_fifo_full) begin
                 tx_fifo_wdata[63:32] <= tx_wb_dat_i;
                 tx_fifo_wr_en <= 1'b1;
                 tx_dma_current_addr <= tx_dma_current_addr + 8;
                 tx_dma_remaining <= tx_dma_remaining - 1;
                 tx_wb_stb_o <= 1'b0;
                 
                 if (tx_dma_remaining == 1) begin
                    tx_wb_cyc_o <= 1'b0;
                    tx_dma_state <= TX_DMA_DONE;
                 end else begin
                    tx_dma_state <= TX_DMA_FETCH;
                 end
              end else if (tx_wb_ack_i && tx_fifo_full) begin // if (tx_wb_ack_i && !tx_fifo_full)
                 tx_fifo_wdata[63:32] <= tx_wb_dat_i;
                 tx_wb_stb_o <= 1'b0;
		 tx_wb_cyc_o <= 1'b0;
		 tx_dma_state <= TX_DMA_WAIT3;
	      end
           end // case: TX_DMA_WAIT2

	   TX_DMA_WAIT3: begin
	      if (!tx_fifo_full) begin
                 tx_fifo_wr_en <= 1'b1;
                 tx_dma_current_addr <= tx_dma_current_addr + 8;
                 tx_dma_remaining <= tx_dma_remaining - 1;
                 if (tx_dma_remaining == 1) begin
                    tx_dma_state <= TX_DMA_DONE;
                 end else begin
                    tx_dma_state <= TX_DMA_FETCH;
                 end
	      end
	   end
                 
           TX_DMA_DONE: begin
              tx_dma_busy <= 1'b0;
              tx_dma_done <= 1'b1;
              tx_wb_cyc_o <= 1'b0;
              if (csr_control[CONTROL_TX_RESET]) begin
                 tx_dma_state <= TX_DMA_IDLE;
                 tx_dma_done <= 1'b0;
              end
           end
           
           default: begin
              tx_dma_state <= TX_DMA_IDLE;
           end
         endcase
      end
   end
   
   // ============================================================================
   // RX DMA Engine
   // ============================================================================
   
   // Wishbone master for RX DMA
   always @(posedge wb_clk or negedge wb_rst_n) begin
      if (!wb_rst_n) begin
         rx_wb_cyc_o <= 1'b0;
         rx_wb_stb_o <= 1'b0;
         rx_wb_we_o <= 1'b0;
         rx_wb_adr_o <= 32'h0;
         rx_wb_dat_o <= 32'h0;
         rx_dma_busy <= 1'b0;
         rx_dma_done <= 1'b0;
         rx_dma_current_addr <= 32'h0;
         rx_dma_remaining <= 32'h0;
         rx_dma_state <= RX_DMA_IDLE;
         rx_fifo_rdata <= 64'h0;
         rx_fifo_rd_ptr_wb <= 4'b0;
      end else begin
         case (rx_dma_state)
           RX_DMA_IDLE: begin
              if (csr_control[CONTROL_RX_START] && csr_control[CONTROL_RX_ENABLE] && 
                  !csr_control[CONTROL_RX_RESET]) begin
                 rx_dma_current_addr <= rx_dest_addr;
                 rx_dma_remaining <= rx_length;
                 rx_dma_busy <= 1'b1;
                 rx_dma_done <= 1'b0;
                 rx_dma_state <= RX_DMA_WRITE;
              end
           end
           
           RX_DMA_WRITE: begin
//              if (!rx_fifo_empty_sync[2] && rx_dma_remaining > 0) begin
              if ((rx_fifo_count_wb > 0) && rx_dma_remaining > 0) begin
                 // Read from RX FIFO
                 rx_fifo_rdata <= rx_fifo[rx_fifo_rd_ptr_wb[2:0]];
                 rx_fifo_rd_ptr_wb <= rx_fifo_rd_ptr_wb + 1;
                 rx_dma_state <= RX_DMA_WAIT_FIRST;
              end else if (rx_dma_remaining == 0) begin
                 rx_dma_state <= RX_DMA_DONE;
              end
           end
           
           RX_DMA_WAIT_FIRST: begin
              // Start writing first 32-bit word
              rx_wb_cyc_o <= 1'b1;
              rx_wb_stb_o <= 1'b1;
              rx_wb_we_o <= 1'b1;
              rx_wb_adr_o <= rx_dma_current_addr;
              rx_wb_dat_o <= rx_fifo_rdata[31:0];
              rx_dma_state <= RX_DMA_WAIT_SECOND;
           end
           
           RX_DMA_WAIT_SECOND: begin
              if (rx_wb_ack_i) begin
                 // First write completed, write second 32-bit word
                 rx_wb_adr_o <= rx_dma_current_addr + 4;
                 rx_wb_dat_o <= rx_fifo_rdata[63:32];
                 rx_wb_stb_o <= 1'b1;
		 rx_dma_state <= RX_DMA_WAIT_SECOND2;
	      end
	   end

	   RX_DMA_WAIT_SECOND2: begin
              if (rx_wb_ack_i) begin
                 rx_dma_current_addr <= rx_dma_current_addr + 8;
                 rx_dma_remaining <= rx_dma_remaining - 1;
                 rx_wb_stb_o <= 1'b0;
		 rx_wb_we_o <= 1'b0;
                 rx_wb_cyc_o <= 1'b0;
                 
                 if (rx_dma_remaining == 1) begin
                    rx_dma_state <= RX_DMA_DONE;
                 end else begin
                    rx_dma_state <= RX_DMA_WRITE;
                 end
              end
           end
           
           RX_DMA_DONE: begin
              rx_dma_busy <= 1'b0;
              rx_dma_done <= 1'b1;
              rx_wb_stb_o <= 1'b0;
	      rx_wb_we_o <= 1'b0;
              rx_wb_cyc_o <= 1'b0;
              if (csr_control[CONTROL_RX_RESET]) begin
                 rx_dma_state <= RX_DMA_IDLE;
                 rx_dma_done <= 1'b0;
              end
           end
           
           default: begin
              rx_dma_state <= RX_DMA_IDLE;
           end
         endcase
      end
   end
   
   // ============================================================================
   // TX D2D Interface (d2d_clk domain)
   // ============================================================================
   
   reg [2:0] tx_d2d_state, n_tx_d2d_state;
   
   localparam TX_D2D_IDLE = 3'd0;
   localparam TX_D2D_SEND = 3'd1;
   localparam TX_D2D_SEND2 = 3'd2;
   localparam TX_D2D_SEND3 = 3'd3;
   localparam TX_D2D_SEND4 = 3'd4;
   localparam TX_D2D_SEND5 = 3'd5;
   localparam TX_D2D_RETRY = 3'd6;
   localparam TX_D2D_RETRY_COMPLETE = 3'd7;
   
   // Convert read pointer to gray code for CDC
   always @(posedge d2d_clk or negedge d2d_rst_n) begin
      if (!d2d_rst_n) begin
	 tx_fifo_rd_ptr_gray <= 3'b0;
      end else begin
	 tx_fifo_rd_ptr_gray <= bin2gray(n_tx_fifo_rd_ptr_d2d[2:0]);
      end
   end
   
   reg n_tx_valid;
   reg [63:0] n_tx_data;
   
   always @(posedge d2d_clk or negedge d2d_rst_n) begin
      if (!d2d_rst_n) begin
	 tx_data <= 64'h0;
	 tx_valid <= 1'b0;
	 tx_fifo_rd_ptr_d2d <= 4'b0;
	 tx_d2d_state <= TX_D2D_IDLE;
      end else begin
	 tx_data <= n_tx_data;
	 tx_valid <= n_tx_valid;
	 tx_fifo_rd_ptr_d2d <= n_tx_fifo_rd_ptr_d2d;
	 tx_d2d_state <= n_tx_d2d_state;
      end
   end // always @ (posedge d2d_clk or negedge d2d_rst_n)

   always@(*) begin
      n_tx_fifo_rd_ptr_d2d = tx_fifo_rd_ptr_d2d;
      n_tx_data = tx_data;
      n_tx_valid = 0;
      
      case (tx_d2d_state)
        TX_D2D_IDLE: begin
	   if (tx_enable_sync[2] && (tx_fifo_count_d2d > 0)) begin
	      // Pre-fetch next data
	      n_tx_fifo_rd_ptr_d2d = tx_fifo_rd_ptr_d2d + 1;
	      n_tx_data = tx_fifo[tx_fifo_rd_ptr_d2d[2:0]];
	      if (tx_ready) begin
		 n_tx_d2d_state = TX_D2D_IDLE;
		 n_tx_valid = 1'b1;
	      end else begin
		 n_tx_d2d_state = TX_D2D_RETRY;
		 n_tx_valid = 0;
	      end
	   end else begin // if (tx_enable_sync[2] && (tx_fifo_count_d2d > 0))
	      n_tx_valid = 0;
	   end
	end
	
	TX_D2D_RETRY: begin
	   if (tx_ready) begin
	      n_tx_valid = 1;
	      n_tx_d2d_state = TX_D2D_RETRY_COMPLETE;
	   end
	end
	
	TX_D2D_RETRY_COMPLETE: begin
	   n_tx_valid = 0;
	   n_tx_d2d_state = TX_D2D_IDLE;
	end
	
        default: begin
	   n_tx_valid = 0;
           n_tx_d2d_state = TX_D2D_IDLE;
        end
      endcase
   end
   
   // ============================================================================
   // RX D2D Interface (d2d_clk domain)
   // ============================================================================
   
   // RX ready logic: only assert if RX side is ready to receive
   wire	      rx_side_ready;
   assign rx_side_ready = rx_enable_sync[2] && 
			  (rx_length > 0) && 
			  rx_start_sync[2] && 
			  !rx_fifo_full && 
			  !rx_done_sync[2];
   
   reg	      n_rx_ready;
   
   always @(posedge d2d_clk or negedge d2d_rst_n) begin
      if (!d2d_rst_n) begin
         rx_ready <= 1'b0;
         rx_d2d_state <= RX_D2D_IDLE;
      end else begin
	 rx_ready <= n_rx_ready;
	 rx_d2d_state <= n_rx_d2d_state;
      end // else: !if(!d2d_rst_n)
   end // always @ (posedge d2d_clk or negedge d2d_rst_n)
   
   always@(*) begin
      n_rx_ready = rx_ready;
      rx_fifo_wr_en = 0;
      n_rx_d2d_state = rx_d2d_state;

      case (rx_d2d_state)
        RX_D2D_IDLE: begin
           if (rx_valid && rx_ready) begin
              rx_fifo_wdata = rx_data;
	      rx_fifo_wr_en = 1;
	      
	      if (rx_fifo_count < RX_FIFO_LAST_ENTRY) begin
		 n_rx_ready = 0;
	      end
	   end else begin
	      n_rx_ready = rx_side_ready;
	   end
	end // case: RX_D2D_IDLE
	
	default: begin
	   n_rx_ready = rx_side_ready;
	   rx_fifo_wr_en = 0;
	   n_rx_d2d_state = RX_D2D_IDLE;
	end
      endcase
   end
   
endmodule // d2d_link_top
