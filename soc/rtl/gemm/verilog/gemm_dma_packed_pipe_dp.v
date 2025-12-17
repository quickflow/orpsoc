// gemm_dma_packed_pipe_dp.v (rewritten loaders/writeback to avoid inner @)
`timescale 1ns/1ps

`include "header.h"

module gemm_dma_packed_pipe_dp #(parameter N = 16)
   (
    input wire	      wb_clk_i,
    input wire	      wb_rst_i,
    
    // Wishbone slave (control)
    input wire	      wbs_stb_i,
    input wire	      wbs_cyc_i,
    input wire	      wbs_we_i,
    input wire [3:0]  wbs_sel_i,
    input wire [31:0] wbs_adr_i, // word address
    input wire [31:0] wbs_dat_i,
    output reg [31:0] wbs_dat_o,
    output reg	      wbs_ack_o,
    
    // Wishbone master (DMA to external memory)
    output reg	      wbm_cyc_o,
    output reg	      wbm_stb_o,
    output reg	      wbm_we_o,
    output reg [31:0] wbm_adr_o, // word address
    output reg [31:0] wbm_dat_o,
    input wire [31:0] wbm_dat_i,
    input wire	      wbm_ack_i
    );
   // ------------------------
   // Control registers
   // ------------------------
   reg [31:0]	      reg_ctrl_stat;
   reg [31:0]	      reg_mode;
   reg [31:0]	      reg_base_a;
   reg [31:0]	      reg_base_b;
   reg [31:0]	      reg_base_c;
   reg [31:0]	      reg_leaky_alpha;   // Q1.7
   reg [31:0]	      reg_quant_scale;   // Q16.16
   reg [31:0]	      reg_quant_zero;    // integer
   
   // MODE bits
   wire		      mode_dw16     = reg_mode[`MODE_DW16]; // 1=16-bit, 0=8-bit
   wire		      mode_act_en   = reg_mode[`MODE_ACT];
   wire		      mode_quant_en = reg_mode[`MODE_QUANT];
   wire		      mode_act_type = reg_mode[`MODE_ACT_TYPE]; // 0=ReLU, 1=LeakyReLU
   wire		      mode_signed   = reg_mode[`MODE_SIGNED]; // 1=signed inputs, 0=unsigned
   
   // Sizes
   localparam	      N_SQ = N*N;
   localparam	      ADDR_WIDTH = $clog2(N_SQ);
   
   // elems per 32-bit word (combinational wire)
   wire [7:0]	      PACK = mode_dw16 ? 8'd2 : 8'd4;
   wire [15:0]	      WORDS_TOTAL = N_SQ;
   
   // ------------------------
   // Dual-port scratchpads
   // ------------------------
   // A RAM
   reg		      load_a_we;
   reg [ADDR_WIDTH-1:0]	load_a_addr;
   reg signed [15:0]	load_a_data;
   reg [ADDR_WIDTH-1:0]	comp_a_addr;
   wire signed [15:0]	comp_a_q;
   
   dp_ram #(.WIDTH(16), .DEPTH(N_SQ)) a_spad
     (
      .clk   (wb_clk_i),
      .we_a  (load_a_we),
      .addr_a(load_a_addr),
      .din_a (load_a_data),
      .dout_a(), // unused port A dout
      .we_b  (1'b0),
      .addr_b(comp_a_addr),
      .din_b (16'd0),
      .dout_b(comp_a_q)
      );
   
   // B RAM
   reg			load_b_we;
   reg [ADDR_WIDTH-1:0]	load_b_addr;
   reg signed [15:0]	load_b_data;
   reg [ADDR_WIDTH-1:0]	comp_b_addr;
   wire signed [15:0]	comp_b_q;
   
   dp_ram #(.WIDTH(16), .DEPTH(N_SQ)) b_spad
     (
      .clk   (wb_clk_i),
      .we_a  (load_b_we),
      .addr_a(load_b_addr),
      .din_a (load_b_data),
      .dout_a(),
      .we_b  (1'b0),
      .addr_b(comp_b_addr),
      .din_b (16'd0),
      .dout_b(comp_b_q)
      );
   
   // Accumulator RAM (32-bit)
   reg			acc_we_a;
   reg [ADDR_WIDTH-1:0]	acc_addr_a;
   reg signed [31:0]	acc_din_a;
   wire signed [31:0]	acc_q_a;
   reg			acc_we_b;
   reg [ADDR_WIDTH-1:0]	acc_addr_b;
   reg signed [31:0]	acc_din_b;
   wire signed [31:0]	acc_q_b;
   
   dp_ram #(.WIDTH(32), .DEPTH(N_SQ)) acc_spad
     (
      .clk   (wb_clk_i),
      .we_a  (acc_we_a),
      .addr_a(acc_addr_a),
      .din_a (acc_din_a),
      .dout_a(acc_q_a),
      .we_b  (acc_we_b),
      .addr_b(acc_addr_b),
      .din_b (acc_din_b),
      .dout_b(acc_q_b)
      );
   
   // ------------------------
   // DMA master
   // ------------------------
   reg			dma_req, dma_we;
   reg [31:0]		dma_addr;
   reg [31:0]		dma_wdata;
   wire			dma_ack = wbm_ack_i;
   reg [31:0]		dma_rdata;
   reg [15:0]		clear_idx;
   
   // ------------------------
   // FSM states
   // ------------------------
   localparam		S_IDLE   =  8'h00,
			S_CLEAR  =  8'h01,
			S_LOAD_A =  8'h02,
			S_LOAD_A0 = 8'h20,
			S_LOAD_A1 = 8'h21,
			S_LOAD_A2 = 8'h22,
			S_LOAD_A3 = 8'h23,
			S_LOAD_B =  8'h03,
			S_LOAD_B0 = 8'h30,
			S_LOAD_B1 = 8'h31,
			S_LOAD_B2 = 8'h32,
			S_LOAD_B3 = 8'h33,
			S_COMPUTE=  8'h04,
			S_COMPUTE_S2=  8'h42,
			S_COMPUTE_S3=  8'h43,
			S_COMPUTE_S4=  8'h44,
			S_W0_READ=  8'h05,
			S_W0_READ0= 8'h50,
			S_W0_READ1= 8'h51,
			S_W0_READ2= 8'h52,
			S_W0_READ3= 8'h53,
			S_W1_ACT =  8'h06,
			S_W2_QUANT= 8'h07,
			S_W3_SAT=   8'h08,
			S_W4_WRITE= 8'h09,
			S_DONE   =  8'h0A;
   
   reg [7:0]		state, next_state;
   
   // Loader counters (word and byte sub-index)
   reg [15:0]		load_idx_word;
   reg [1:0]		load_byte_idx; // 0..3 (for 8-bit mode), 0..1 (for 16-bit)
   reg			load_is_b;     // 0=A, 1=B
   
   // Compute pipeline indices
   reg [7:0]		i_sx, j_sx, k_sx;
   reg signed [15:0]	a_s2, b_s2;
   reg signed [31:0]	prod_s3;
   reg [ADDR_WIDTH-1:0]	acc_idx_s4;
   
   // Writeback pipeline
   reg [15:0]		w_idx_word;
   reg signed [31:0]	w0_x0, w0_x1, w0_x2, w0_x3;
   reg signed [31:0]	w1_y0, w1_y1, w1_y2, w1_y3;
   reg signed [31:0]	w2_z0, w2_z1, w2_z2, w2_z3;
   
   // Status bits
   wire			busy_set = (state != S_IDLE);
   wire			done_set = (state == S_DONE);
   wire			done_clr = (state == S_CLEAR);
   
   // ------------------------
   // Wishbone control slave
   // ------------------------
   always @(posedge wb_clk_i or posedge wb_rst_i ) begin
      if (wb_rst_i) begin
         wbs_ack_o <= 1'b0;
         wbs_dat_o <= 32'd0;
         reg_ctrl_stat  <= 32'd0;
         reg_mode  <= 32'd0;
         reg_base_a<= 32'd0;
         reg_base_b<= 32'd0;
         reg_base_c<= 32'd0;
         reg_leaky_alpha <= 32'd16;     // default 0.125 Q1.7
         reg_quant_scale <= 32'd65536;  // 1.0
         reg_quant_zero  <= 32'd0;
      end // if (wb_rst_i)
      else begin
         wbs_ack_o <= 1'b0;
         reg_ctrl_stat[15] <= busy_set;
         reg_ctrl_stat[16] <= !done_clr && (done_set | reg_ctrl_stat[16]);
         reg_ctrl_stat[17] <= 1'b0;
	 
         if (wbs_stb_i && wbs_cyc_i && !wbs_ack_o) begin
            wbs_ack_o <= 1'b1;
            if (wbs_we_i) begin
               case (wbs_adr_i[7:0])
                 `REG_CTRL_STAT: reg_ctrl_stat  <= wbs_dat_i;
                 `REG_MODE:      reg_mode   <= wbs_dat_i;
                 `REG_BASE_A:    reg_base_a <= wbs_dat_i;
                 `REG_BASE_B:    reg_base_b <= wbs_dat_i;
                 `REG_BASE_C:    reg_base_c <= wbs_dat_i;
                 `REG_ALPHA:     reg_leaky_alpha <= wbs_dat_i;
                 `REG_QSCALE:    reg_quant_scale <= wbs_dat_i;
                 `REG_QZERO:     reg_quant_zero  <= wbs_dat_i;
               endcase // case (wbs_adr_i[7:0])
            end // if (wbs_we_i)
	    else begin
               case (wbs_adr_i[7:0])
                 `REG_CTRL_STAT: wbs_dat_o <= reg_ctrl_stat;
                 `REG_MODE:      wbs_dat_o <= reg_mode;
                 `REG_BASE_A:    wbs_dat_o <= reg_base_a;
                 `REG_BASE_B:    wbs_dat_o <= reg_base_b;
                 `REG_BASE_C:    wbs_dat_o <= reg_base_c;
                 `REG_ALPHA:     wbs_dat_o <= reg_leaky_alpha;
                 `REG_QSCALE:    wbs_dat_o <= reg_quant_scale;
                 `REG_QZERO:     wbs_dat_o <= reg_quant_zero;
                 default: wbs_dat_o <= 32'd0;
               endcase // case (wbs_adr_i[7:0])
            end // else: !if(wbs_we_i)
         end // if (wbs_stb_i && wbs_cyc_i && !wbs_ack_o)

         // auto-clear start bit once captured
         if (reg_ctrl_stat[0] && state == S_IDLE) reg_ctrl_stat[0] <= 1'b0;
         // clear done flag request (optional)
         if (reg_ctrl_stat[1]) reg_ctrl_stat[1] <= 1'b0;
      end // else: !if(wb_rst_i)
   end // always @ (posedge wb_clk_i)

   // ------------------------
   // DMA master handshake
   // ------------------------
   always @(posedge wb_clk_i or posedge wb_rst_i) begin
      if (wb_rst_i) begin
         wbm_cyc_o <= 1'b0;
         wbm_stb_o <= 1'b0;
         wbm_we_o  <= 1'b0;
         wbm_adr_o <= 32'd0;
         wbm_dat_o <= 32'd0;
         dma_rdata <= 32'd0;
//         dma_req   <= 1'b0;
      end
      else begin
         if (dma_req && !wbm_stb_o) begin
            wbm_cyc_o <= 1'b1;
            wbm_stb_o <= 1'b1;
            wbm_we_o  <= dma_we;
            wbm_adr_o <= dma_addr;
            wbm_dat_o <= dma_wdata;
         end
	 else if (wbm_stb_o && dma_ack) begin
            wbm_stb_o <= 1'b0;
            wbm_cyc_o <= 1'b0;
            dma_rdata <= wbm_dat_i;
//            dma_req   <= 1'b0;
         end
      end // else: !if(wb_rst_i)
   end // always @ (posedge wb_clk_i)
   
   // ------------------------
   // Helpers (automatic functions to silence SV lifetime warnings)
   // ------------------------
   function automatic signed [15:0] sext8(input [7:0] x);
      sext8 = {{8{x[7]}}, x};
   endfunction
   
   function automatic signed [31:0] apply_activation(input signed [31:0] x);
      reg signed [31:0] alpha_s, leak;
      begin
         if (!mode_act_en) apply_activation = x;
         else if (!mode_act_type) apply_activation = (x < 0) ? 32'sd0 : x; // ReLU
         else begin
            if (x >= 0) apply_activation = x;
            else begin
               alpha_s = {{24{reg_leaky_alpha[7]}}, reg_leaky_alpha[7:0]}; // Q1.7
               leak    = (x * alpha_s) >>> 7;
               apply_activation = leak;
            end
         end
      end
   endfunction // apply_activation
   
   function automatic signed [31:0] apply_quant(input signed [31:0] x);
      reg signed [63:0] mult;
      reg signed [31:0]	scaled;
      begin
         if (!mode_quant_en) apply_quant = x;
         else begin
            mult   = $signed(x) * $signed({1'b0, reg_quant_scale});
            scaled = (mult + 32'sd32768) >>> 16; // round-to-nearest
            apply_quant = scaled + $signed(reg_quant_zero);
         end
      end
   endfunction // apply_quant
   
   function automatic signed [31:0] saturate_out(input signed [31:0] x);
      begin
         if (mode_dw16) begin
            if (x > 32'sd32767) saturate_out = 32'sd32767;
            else if (x < -32'sd32768) saturate_out = -32'sd32768;
            else saturate_out = x;
         end else begin
            if (x > 32'sd127) saturate_out = 32'sd127;
            else if (x < -32'sd128) saturate_out = -32'sd128;
            else saturate_out = x;
         end
      end
   endfunction // saturate_out

   // ------------------------
   // Main FSM and pipelines
   // ------------------------
   integer idx;
   always @(posedge wb_clk_i or posedge wb_rst_i) begin
      if (wb_rst_i) begin
         state <= S_IDLE;
	 
         // DMA defaults
         dma_we   <= 1'b0;
         dma_addr <= 32'd0;
         dma_wdata<= 32'd0;
	 
         // loader
         load_idx_word <= 16'd0;
         load_byte_idx <= 2'd0;
         load_is_b     <= 1'b0;
	 
         // compute
         i_sx <= 8'd0; j_sx <= 8'd0; k_sx <= 8'd0;
         a_s2 <= 16'sd0; b_s2 <= 16'sd0;
         prod_s3 <= 32'sd0;
         acc_idx_s4 <= {ADDR_WIDTH{1'b0}};
	 
         // writeback
         w_idx_word <= 16'd0;
         w0_x0 <= 0; w0_x1 <= 0; w0_x2 <= 0; w0_x3 <= 0;
         w1_y0 <= 0; w1_y1 <= 0; w1_y2 <= 0; w1_y3 <= 0;
         w2_z0 <= 0; w2_z1 <= 0; w2_z2 <= 0; w2_z3 <= 0;
	 
         // RAM write disables
         load_a_we <= 1'b0; load_b_we <= 1'b0;
         acc_we_a  <= 1'b0; acc_we_b  <= 1'b0;
         load_a_addr <= {ADDR_WIDTH{1'b0}};
         load_b_addr <= {ADDR_WIDTH{1'b0}};
         acc_addr_a  <= {ADDR_WIDTH{1'b0}};
         acc_addr_b  <= {ADDR_WIDTH{1'b0}};
         load_a_data <= 16'sd0;
         load_b_data <= 16'sd0;
         acc_din_a   <= 32'sd0;
         acc_din_b   <= 32'sd0;
	 
         dma_req   <= 1'b0;

         // clear accumulators
         for (idx=0; idx<N_SQ; idx=idx+1) begin
            acc_addr_a <= idx[ADDR_WIDTH-1:0];
            acc_din_a  <= 32'sd0;
            acc_we_a   <= 1'b1;
         end
         acc_we_a <= 1'b0;
	 clear_idx <= 0;
      end else begin
         // default write disables
         load_a_we <= 1'b0;
         load_b_we <= 1'b0;
         acc_we_a  <= 1'b0;
         acc_we_b  <= 1'b0;
	 
         // Clear DMA request when acknowledged (in DMA block)
	 
         case (state)
           // ---------------- IDLE ----------------
           S_IDLE: begin
              if (reg_ctrl_stat[0]) begin
                 // reset counters
                 load_idx_word <= 16'd0;
                 load_byte_idx <= 2'd0;
                 load_is_b     <= 1'b0;
                 w_idx_word    <= 16'd0;
                 i_sx <= 8'd0; j_sx <= 8'd0; k_sx <= 8'd0;
                 acc_we_a <= 1'b0;
		 comp_a_addr <= 0;
		 comp_b_addr <= 0;
		 state <= S_CLEAR;
              end // if (reg_ctrl[0])
           end // case: S_IDLE

	   S_CLEAR: begin
	      if (clear_idx < N_SQ) begin
		 acc_addr_a <= clear_idx[ADDR_WIDTH-1:0];
		 acc_din_a  <= 32'sd0;
		 acc_we_a   <= 1'b1;
		 clear_idx  <= clear_idx + 1;
	      end
	      else begin
		 state <= S_LOAD_A;
	      end
	   end // case: S_CLEAR
	      
           // ---------------- LOAD A ----------------
	   S_LOAD_A: begin
	      if (!dma_req && !wbm_stb_o) begin
		 dma_we   <= 1'b0;
		 dma_addr <= reg_base_a + (load_idx_word * (mode_dw16 ? 2 : 1));
		 dma_req  <= 1'b1;
	      end
	      else if (dma_req && wbm_stb_o && dma_ack) begin
		 dma_req <= 0;
		 // unpack immediately
		 if (mode_dw16) begin
		    load_a_addr <= load_idx_word;
		    load_a_data <= $signed(wbm_dat_i[15:0]);
		    load_a_we   <= 1'b1;
		    state <= S_LOAD_A0;
		 end else begin
		    load_a_addr <= load_idx_word;
		    load_a_data <= sext8(wbm_dat_i[7:0]);
		    load_a_we <= 1'b1;
		    state <= S_LOAD_A1;
		 end
		 load_idx_word <= load_idx_word + 1;
	      end // if (wbm_stb_o && dma_ack)
	   end // case: S_LOAD_A

           // ---------------- LOAD A half word 1 -----------
	   S_LOAD_A0: begin
	      load_a_addr <= load_idx_word;
	      load_a_data <= $signed(dma_rdata[31:16]);
	      load_a_we   <= 1'b1;
	      if (load_idx_word == (WORDS_TOTAL-1)) begin
		 load_idx_word <= 0;   // reset for B
		 state <= S_LOAD_B;
	      end else begin
		 load_idx_word <= load_idx_word + 1;
		 state <= S_LOAD_A;
	      end
	   end // case: S_LOAD_A0

           // ---------------- LOAD A byte 1 ----------------
	   S_LOAD_A1: begin
	      load_a_addr <= load_idx_word;
	      load_a_data <= $signed(dma_rdata[15:8]);
	      load_a_we   <= 1'b1;
	      load_idx_word <= load_idx_word + 1;
	      state <= S_LOAD_A2;
	   end

           // ---------------- LOAD A byte 2 ----------------
	   S_LOAD_A2: begin
	      load_a_addr <= load_idx_word;
	      load_a_data <= $signed(dma_rdata[23:16]);
	      load_a_we   <= 1'b1;
	      load_idx_word <= load_idx_word + 1;
	      state <= S_LOAD_A3;
	   end

           // ---------------- LOAD A byte 3 ----------------
	   S_LOAD_A3: begin
	      load_a_addr <= load_idx_word;
	      load_a_data <= $signed(dma_rdata[31:24]);
	      load_a_we   <= 1'b1;
	      if (load_idx_word == (WORDS_TOTAL-1)) begin
		 load_idx_word <= 0;   // reset for B
		 state <= S_LOAD_B;
	      end else begin
		 state <= S_LOAD_A;
		 load_idx_word <= load_idx_word + 1;
	      end
	   end // case: S_LOAD_A3

           // ---------------- LOAD B ----------------
	   S_LOAD_B: begin
	      if (!dma_req && !wbm_stb_o) begin
		 dma_we   <= 1'b0;
		 dma_addr <= reg_base_b + (load_idx_word * (mode_dw16 ? 2 : 1));
		 dma_req  <= 1'b1;
	      end
	      else if (dma_req && wbm_stb_o && dma_ack) begin
		 dma_req <= 0;
		 // unpack immediately
		 if (mode_dw16) begin
		    load_b_addr <= load_idx_word;
		    load_b_data <= $signed(wbm_dat_i[15:0]);
		    load_b_we   <= 1'b1;
		    state <= S_LOAD_B0;
		 end else begin
		    load_b_addr <= load_idx_word;
		    load_b_data <= sext8(wbm_dat_i[7:0]);
		    load_b_we <= 1'b1;
		    state <= S_LOAD_B1;
		 end
		 load_idx_word <= load_idx_word + 1;
	      end
	   end // case: S_LOAD_B

           // ---------------- LOAD B half word 1 -----------
	   S_LOAD_B0: begin
	      load_b_addr <= load_idx_word;
	      load_b_data <= $signed(dma_rdata[31:16]);
	      load_b_we   <= 1'b1;
	      if (load_idx_word == (WORDS_TOTAL-1)) begin
		 load_idx_word <= 0;   // reset for B
		 state <= S_COMPUTE;
	      end else begin
		 load_idx_word <= load_idx_word + 1;
		 state <= S_LOAD_B;
	      end
	   end // case: S_LOAD_B0

           // ---------------- LOAD B byte 1 ----------------
	   S_LOAD_B1: begin
	      load_b_addr <= load_idx_word;
	      load_b_data <= $signed(dma_rdata[15:8]);
	      load_b_we   <= 1'b1;
	      load_idx_word <= load_idx_word + 1;
	      state <= S_LOAD_B2;
	   end

           // ---------------- LOAD B byte 2 ----------------
	   S_LOAD_B2: begin
	      load_b_addr <= load_idx_word;
	      load_b_data <= $signed(dma_rdata[23:16]);
	      load_b_we   <= 1'b1;
	      load_idx_word <= load_idx_word + 1;
	      state <= S_LOAD_B3;
	   end
	   
           // ---------------- LOAD B byte 3 ----------------
	   S_LOAD_B3: begin
	      load_b_addr <= load_idx_word;
	      load_b_data <= $signed(dma_rdata[31:24]);
	      load_b_we   <= 1'b1;
	      if (load_idx_word == (WORDS_TOTAL-1)) begin
		 load_idx_word <= 0;   // reset for B
		 state <= S_COMPUTE;
	      end else begin
		 load_idx_word <= load_idx_word + 1;
		 state <= S_LOAD_B;
	      end
	   end // case: S_LOAD_B3

           // ---------------- COMPUTE (4-stage) ----------------
           S_COMPUTE: begin
              // set addresses for reads
              comp_a_addr <= (i_sx*N + k_sx);
              comp_b_addr <= (k_sx*N + j_sx);
              acc_addr_a <= (i_sx*N + j_sx);
	      acc_din_a <= 0;
              k_sx <= k_sx + 1;
	      state <= S_COMPUTE_S2;
	   end
	   
	   S_COMPUTE_S2: begin
              // S2 read,  multiply, acc, store back
//              acc_din_a <= acc_din_a + $signed(comp_a_q) * $signed(comp_b_q);
	      
              // index progression k->j->i
	      if (k_sx == 0) begin
                 k_sx <= k_sx + 1;
                 acc_we_a   <= 1'b1;
	      end else if (k_sx < N-1) begin
                 k_sx <= k_sx + 1;
              end else begin
                 k_sx <= 0;
                 if (j_sx < N-1)
		   j_sx <= j_sx + 1;
                 else begin
                    j_sx <= 0;
                    if (i_sx < N-1)
		      i_sx <= i_sx + 1;
                 end
              end // else: !if(k < N-1)

              comp_a_addr <= (i_sx*N + k_sx);
              comp_b_addr <= (k_sx*N + j_sx);

	      if (i_sx == N-1 && j_sx == N-1 && k_sx == N-1) begin
		 acc_din_a <= acc_din_a + $signed(comp_a_q) * $signed(comp_b_q);
		 state <= S_COMPUTE_S3;
	      end else begin
		 if (acc_we_a) begin
		    acc_din_a <= $signed(comp_a_q) * $signed(comp_b_q);
		    acc_addr_a <= (i_sx*N + j_sx);
		 end else begin
		    acc_din_a <= acc_din_a + $signed(comp_a_q) * $signed(comp_b_q);
		 end
	      end
	   end // case: S_COMPUTE_S2

	   S_COMPUTE_S3: begin
              // S2 read,  multiply, acc, store back

              comp_a_addr <= (i_sx*N + k_sx);
              comp_b_addr <= (k_sx*N + j_sx);

	      acc_din_a <= acc_din_a + $signed(comp_a_q) * $signed(comp_b_q);

              if (i_sx < N-1)
		i_sx <= i_sx + 1;

              acc_we_a   <= 1'b1;
	      acc_addr_b <= w_idx_word;
	      state <= S_W0_READ;
	   end // case: S_COMPUTE_S3

	   S_COMPUTE_S4: begin
              // S2 read,  multiply, acc, store back
	      
	      acc_din_a <= acc_din_a + $signed(comp_a_q) * $signed(comp_b_q);
	      acc_addr_b <= w_idx_word;
	      state <= S_W0_READ;
	      
	   end // case: S_COMPUTE_S4

           // ---------------- W0: read accumulators in packed groups (port B) ----------------
           S_W0_READ: begin
              // read four or two consecutive elements over subsequent cycles into w0_x*
              // cycle 0
              w0_x0      <= acc_q_b;
              acc_addr_b <= acc_addr_b + 1;
	      if (mode_dw16)
		state <= S_W0_READ0;
	      else
		state <= S_W0_READ1;
	   end // case: S_W0_READ
	   
           // ---------------- W0: read next half word accumulators in packed groups (port B) ----------------
	   S_W0_READ0: begin
             // cycle 1/2/3 handled via valid propagation across states; keep simple single-cycle per group
//              acc_addr_b <= w_idx_word + 1;
              w0_x1      <= acc_q_b;
	      state <= S_W1_ACT;
           end

           // ---------------- W0: read next byte accumulators in packed groups (port B) ----------------
	   S_W0_READ1:
             begin
                acc_addr_b <= acc_addr_b + 1;
                w0_x1      <= acc_q_b;
		state <= S_W0_READ2;
             end
	   
           // ---------------- W0: read next byte accumulators in packed groups (port B) ----------------
	   S_W0_READ2:
             begin
                acc_addr_b <= acc_addr_b + 1;
                w0_x2      <= acc_q_b;
		state <= S_W0_READ3;
             end
	   
           // ---------------- W0: read next byte accumulators in packed groups (port B) ----------------
	   S_W0_READ3:
             begin
                acc_addr_b <= acc_addr_b + 1;
                w0_x3      <= acc_q_b;
		state <= S_W1_ACT;
             end
	   
           // ---------------- W1: activation ----------------
           S_W1_ACT: begin
              begin
                 w1_y0 <= apply_activation(w0_x0);
                 w1_y1 <= apply_activation(w0_x1);
                 w1_y2 <= apply_activation(w0_x2);
                 w1_y3 <= apply_activation(w0_x3);
		 state <= S_W2_QUANT;
              end
           end
	   
           // ---------------- W2: quantization ----------------
           S_W2_QUANT: begin
              begin
                 w2_z0 <= apply_quant(w1_y0);
                 w2_z1 <= apply_quant(w1_y1);
                 w2_z2 <= apply_quant(w1_y2);
                 w2_z3 <= apply_quant(w1_y3);
		 state <= S_W3_SAT;
              end
           end
	   
           // ---------------- W3: saturate  ----------------
	   S_W3_SAT: begin
              // saturate
              w0_x0 <= saturate_out(w2_z0);
              w0_x1 <= saturate_out(w2_z1);
              w0_x2 <= saturate_out(w2_z2);
              w0_x3 <= saturate_out(w2_z3);
	      state <= S_W4_WRITE;
	   end
	   
           // ---------------- W3: DMA write ----------------
           S_W4_WRITE: begin
              // pack result
              // use temporary regs declared at top; no mid-block declarations
              if (!wbm_stb_o && !dma_req) begin
                 // compose word
                 dma_wdata <= (mode_dw16) ? {w0_x1[15:0], w0_x0[15:0]} :
                              {w0_x3[7:0], w0_x2[7:0], w0_x1[7:0], w0_x0[7:0]};
                 dma_we    <= 1'b1;
                 dma_addr  <= reg_base_c + w_idx_word*4;
                 dma_req   <= 1'b1;
		 
              end else if (dma_req && wbm_stb_o && dma_ack) begin
		 dma_req <= 0;
		 w_idx_word <= w_idx_word + 1;
		 acc_addr_b <= acc_addr_b + 1;
		 if (w_idx_word == WORDS_TOTAL)
		   state <= S_DONE;
		 else
		   state <= S_W0_READ;
              end
           end
	   
           S_DONE: begin
	      state <= S_IDLE;
           end
         endcase
      end
   end
   
   /*
    // ------------------------
    // Next-state logic
    // ------------------------
    always @* begin
    next_state = state;
    case (state)
    S_IDLE:     next_state = reg_ctrl[0] ? S_CLEAR : S_IDLE;
    S_CLEAR:      next_state = (clear_idx == N_SQ) ? S_LOAD_A : S_CLEAR;
    S_LOAD_A:   next_state = (load_idx_word == WORDS_TOTAL) ? S_LOAD_B : S_LOAD_A;
    S_LOAD_B:   next_state = (load_idx_word == WORDS_TOTAL) ? S_COMPUTE : S_LOAD_B;
    S_COMPUTE:  next_state = (i == N-1 && j == N-1 && k == N-1) ? S_W0_READ : S_COMPUTE;
    S_W0_READ:  next_state = S_W1_ACT;
    S_W1_ACT:   next_state = S_W2_QUANT;
    S_W2_QUANT: next_state = S_W3_WRITE;
    S_W3_WRITE: next_state = (w_idx_word == WORDS_TOTAL && !wbm_stb_o && !dma_req)
    ? S_DONE
    : ((wbm_stb_o && dma_ack) ? S_W0_READ : S_W3_WRITE);
    S_DONE:     next_state = S_IDLE;
    default:    next_state = S_IDLE;
        endcase
    end
    */
   
endmodule // gemm_dma_packed_pipe_dp
