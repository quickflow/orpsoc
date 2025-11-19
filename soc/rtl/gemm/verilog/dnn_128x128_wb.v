// SPDX-License-Identifier: MIT
// Full accelerator: im2col + GEMM + activation (ReLU/LeakyReLU/Sigmoid/Tanh) + quantization
// Wishbone-mapped top-level with configurable base addresses, plus a testbench.
// Place sigmoid.hex and tanh.hex in the simulation directory for LUT loading.

// ============================================================
// DNN GEMM engine with activation and quantization
// ============================================================
module dnn_128x128_wb #
(
    parameter ROWS  = 128,
    parameter COLS  = 128,
    parameter LANES = 8
)
(
    input  wire        clk,
    input  wire        rst,

    // Wishbone
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire [3:0]  wb_sel_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output reg         wb_ack_o,

    output reg         irq
);

    localparam integer NUM_ELEMS = ROWS * COLS;

    // Memories (byte-addressable)
    reg [7:0] A_mem [0:NUM_ELEMS-1]; // M x K
    reg [7:0] B_mem [0:NUM_ELEMS-1]; // K x N
    reg [7:0] C_mem [0:NUM_ELEMS-1]; // M x N

   wire [8:0] A_mem_dat_acc_op0 = {1'b0, A_mem[i_row*COLS + (k_it+l)]};
   wire [8:0] A_mem_dat_acc_op1 = {1'b0, B_mem[(k_it+l)*COLS + j_col]};

    // CSRs
    reg start;
    reg sat_en;                // saturation enable to clamp to [0,255]
    reg quant_en;              // quantization enable
    reg [2:0] act_mode;        // 0=none,1=ReLU,2=LeakyReLU,3=Sigmoid,4=Tanh

    reg [15:0] quant_scale;    // Q8.8 scale (256 == 1.0)
    reg [7:0]  quant_zero_point;

    reg [7:0]  leaky_alpha;    // Q0.8 slope for LeakyReLU (e.g., 64 == 0.25)

    reg busy, done;

    // Optional fixed DIM report
    wire [31:0] csr_dim = {COLS[15:0], ROWS[15:0]};

    // Sigmoid/Tanh tables
    reg [7:0] sigmoid_table [0:255];
    reg [7:0] tanh_table    [0:255];

    // Initialize tables from files (place sigmoid.hex/tanh.hex next to the simulator run directory)
    initial begin
        // If files are absent, these will remain X; for robust sims, provide defaults or guard loads.
        $readmemh("sigmoid.hex", sigmoid_table);
        $readmemh("tanh.hex", tanh_table);
    end

    // Wishbone register map (relative to this engine’s decode):
    // 0x000 CTRL        : [0]=start, [1]=sat_en, [2]=quant_en, [5:3]=act_mode
    // 0x004 STATUS      : [0]=busy, [1]=done
    // 0x008 DIM         : {COLS[15:0], ROWS[15:0]}
    // 0x00C QUANT_CFG   : [15:0]=quant_scale(Q8.8), [23:16]=quant_zero_point
    // 0x010 LEAKY_ALPHA : [7:0]=alpha(Q0.8)
    // 0x1000.. A buffer : ROWS*COLS bytes (row-major)
    // 0x2000.. B buffer : COLS*COLS bytes
    // 0x3000.. C buffer : ROWS*COLS bytes

    // Wishbone access
    always @(posedge clk) begin
        if (rst) begin
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'h0;

            start    <= 1'b0;
            sat_en   <= 1'b1;
            quant_en <= 1'b0;
            act_mode <= 3'd0;

            quant_scale      <= 16'd256; // 1.0
            quant_zero_point <= 8'd0;

            leaky_alpha <= 8'd51; // ~0.2 default

            busy <= 1'b0;
            done <= 1'b0;
            irq  <= 1'b0;
        end else begin
            wb_ack_o <= 1'b0;
            irq      <= done;

            if (wb_stb_i && wb_cyc_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;

                if (wb_we_i) begin
                    // Writes
                    case (wb_adr_i[11:0])
                        12'h000: begin
                            start    <= wb_dat_i[0];
                            sat_en   <= wb_dat_i[1];
                            quant_en <= wb_dat_i[2];
                            act_mode <= wb_dat_i[5:3];
                        end
                        12'h00C: begin
                            quant_scale      <= wb_dat_i[15:0];
                            quant_zero_point <= wb_dat_i[23:16];
                        end
                        12'h010: begin
                            leaky_alpha <= wb_dat_i[7:0];
                        end
                        default: begin
                            // A buffer
                            if (wb_adr_i >= 32'h00001000 && wb_adr_i < 32'h00002000) begin
                                A_mem[wb_adr_i - 32'h00001000] <= wb_dat_i[7:0];
			       $display("%m:: A_mem[%h] << %h", wb_adr_i - 32'h00001000, wb_dat_i[7:0]);
			    end
                            // B buffer
                            else if (wb_adr_i >= 32'h00002000 && wb_adr_i < 32'h00003000) begin
                                B_mem[wb_adr_i - 32'h00002000] <= wb_dat_i[7:0];
			       $display("%m:: B_mem[%h] << %h", wb_adr_i - 32'h00002000, wb_dat_i[7:0]);
			    end
                            // C buffer (rare to write, allowed for testing)
                            else if (wb_adr_i >= 32'h00003000 && wb_adr_i < 32'h00004000) begin
                                C_mem[wb_adr_i - 32'h00003000] <= wb_dat_i[7:0];
			       $display("%m:: C_mem[%h] << %h", wb_adr_i - 32'h00003000, wb_dat_i[7:0]);
			    end
                        end
                    endcase
                end else begin
                    // Reads
                    case (wb_adr_i[11:0])
                        12'h000: wb_dat_o <= {26'h0, act_mode, quant_en, sat_en, 1'b0};
                        12'h004: wb_dat_o <= {30'h0, done, busy};
                        12'h008: wb_dat_o <= csr_dim;
                        12'h00C: wb_dat_o <= {8'h0, quant_zero_point, quant_scale};
                        12'h010: wb_dat_o <= {24'h0, leaky_alpha};
                        default: begin
                            if (wb_adr_i >= 32'h00001000 && wb_adr_i < 32'h00002000)
                                wb_dat_o <= {24'h0, A_mem[wb_adr_i - 32'h00001000]};
                            else if (wb_adr_i >= 32'h00002000 && wb_adr_i < 32'h00003000)
                                wb_dat_o <= {24'h0, B_mem[wb_adr_i - 32'h00002000]};
                            else if (wb_adr_i >= 32'h00003000 && wb_adr_i < 32'h00004000)
                                wb_dat_o <= {24'h0, C_mem[wb_adr_i - 32'h00003000]};
                            else wb_dat_o <= 32'h0;
                        end
                    endcase
                end
            end

            // Auto-clear start pulse
            if (start) start <= 1'b0;
        end
    end

    // Compute FSM
   parameter ST_IDLE=0;
   parameter ST_COMP=1;
   parameter ST_DONE=2;

    reg [1:0] state;

    reg [15:0] i_row, j_col, k_it;
    reg signed [31:0] acc;

    integer l;

    always @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            busy  <= 1'b0;
            done  <= 1'b0;
            i_row <= 16'd0;
            j_col <= 16'd0;
            k_it  <= 16'd0;
            acc   <= 32'sd0;
        end else begin
            case (state)
                ST_IDLE: begin  // 0
                    done <= 1'b0;
                    if (start) begin
                        busy  <= 1'b1;
                        i_row <= 16'd0;
                        j_col <= 16'd0;
                        k_it  <= 16'd0;
                        acc   <= 32'sd0;
                        state <= ST_COMP;
                    end
                end

                ST_COMP: begin  // 1
                    acc <= acc;
                    for (l=0; l<LANES; l=l+1) begin
                        if (k_it + l < COLS) begin
                            acc <= acc + (
                                $signed({1'b0, A_mem[i_row*COLS + (k_it+l)]}) *
                                $signed({1'b0, B_mem[(k_it+l)*COLS + j_col]})
                            );
                        end
                    end

                    if (k_it + LANES >= COLS) begin
                        C_mem[i_row*COLS + j_col] <= post_process(
                            acc, act_mode, leaky_alpha, sat_en, quant_en, quant_scale, quant_zero_point
                        );

                        // Advance indices
                        if (j_col == COLS-1) begin
                            if (i_row == ROWS-1) begin
                                state <= ST_DONE;
                            end else begin
                                i_row <= i_row + 1;
                                j_col <= 16'd0;
                                k_it  <= 16'd0;
                                acc   <= 32'sd0;
                            end
                        end else begin
                            j_col <= j_col + 1;
                            k_it  <= 16'd0;
                            acc   <= 32'sd0;
                        end
                    end else begin
                        k_it <= k_it + LANES;
                    end
                end

                ST_DONE: begin  // 2
                    busy <= 1'b0;
                    done <= 1'b1;
                    state<= ST_IDLE;
                end
            endcase
        end
    end

    // Activation selection + quant + saturation
    function automatic [7:0] post_process(
        input  signed [31:0] x,
        input  [2:0]         mode,
        input  [7:0]         alpha_q08,
        input                 sat,
        input                 q_en,
        input  [15:0]        q_scale,      // Q8.8
        input  [7:0]         q_zero_point
    );
        reg signed [31:0] y;
        reg signed [31:0] qtmp;
        begin
            y = activation(x, mode, alpha_q08);

            if (q_en) begin
                // qtmp = round(y * scale) + zero_point; scale is Q8.8
                qtmp = (y * $signed({1'b0, q_scale})) >>> 8;
                qtmp = qtmp + $signed({24'd0, q_zero_point});
            end else begin
                qtmp = y;
            end

            if (sat) begin
                if (qtmp > 32'sd255)      post_process = 8'hFF;
                else if (qtmp < 32'sd0)   post_process = 8'h00;
                else                      post_process = qtmp[7:0];
            end else begin
                post_process = qtmp[7:0];
            end
	   $display("%m:: post_process(%h)", post_process);
	   
        end
    endfunction

    function automatic [31:0] activation(
        input  signed [31:0] x,
        input  [2:0]         mode,
        input  [7:0]         alpha_q08
    );
        reg signed [31:0] y;
        reg signed [7:0]  idx; // index into LUTs after coarse scaling
        begin
            case (mode)
                3'd0: y = x;                      // None
                3'd1: y = (x < 0) ? 32'sd0 : x;   // ReLU
                3'd2: y = (x < 0) ? ((x * alpha_q08) >>> 8) : x; // LeakyReLU
                3'd3: begin // Sigmoid via LUT
                    idx = x[15:8]; // coarse scale
                    y   = $signed({24'd0, sigmoid_table[idx + 8'd128]}); // 0..255
                end
                3'd4: begin // Tanh via LUT
                    idx = x[15:8];
                    y   = $signed({24'd0, tanh_table[idx + 8'd128]}); // 0..255 (128-centered)
                end
                default: y = x;
            endcase
            activation = y;
	   $display("%m:: activation(%h)", activation);
	   
        end
    endfunction

endmodule // dnn_128x128_wb
