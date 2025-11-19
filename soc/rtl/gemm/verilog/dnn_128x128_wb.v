// SPDX-License-Identifier: MIT
// Accelerator: im2col + GEMM + activation (ReLU/LeakyReLU/Sigmoid/Tanh) + quantization
// Clean address map:
// - im2col module has two strictly bounded windows:
//     IFM:  IFM_BASE .. IFM_BASE + IFM_SIZE - 1
//     IM2:  IM2_BASE .. IM2_BASE + IM2_SIZE - 1 (IM2_BASE aligned after IFM window)
// - DNN module has three strictly bounded windows:
//     A: A_BASE .. A_BASE + A_SIZE - 1
//     B: B_BASE .. B_BASE + B_SIZE - 1
//     C: C_BASE .. C_BASE + C_SIZE - 1
//
// Global base separation:
// - IM2 global base: 0x0000_0000 (large decode window)
// - DNN global base: 0x0200_0000 (far away; no overlap)
//
// DUT does NOT initialize data memories internally.
// Testbench clears ALL memories via Wishbone writes with parameter-correct bounds.

// ============================================================
// GEMM engine with activation and quantization
// ============================================================
module dnn_128x128_wb #(parameter ROWS=128, COLS=128, LANES=8)(
    input  wire        clk, rst,
    input  wire [31:0] wb_adr_i, wb_dat_i,
    output reg  [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire [3:0]  wb_sel_i,
    input  wire        wb_stb_i, wb_cyc_i,
    output reg         wb_ack_o,
    output reg         irq
);

    // Sizes
    localparam integer A_SIZE = ROWS*COLS;   // 16384 (0x4000)
    localparam integer B_SIZE = COLS*COLS;   // 16384 (0x4000)
    localparam integer C_SIZE = ROWS*COLS;   // 16384 (0x4000)

    // Sub-window bases (non-overlapping inside module address space)
    localparam [31:0] A_BASE = 32'h0000_1000; // 0x1000..0x4FFF
    localparam [31:0] B_BASE = 32'h0000_5000; // 0x5000..0x8FFF
    localparam [31:0] C_BASE = 32'h0000_9000; // 0x9000..0xCFFF

    // Memories (testbench initializes via Wishbone)
    reg [7:0] A_mem [0:A_SIZE-1];
    reg [7:0] B_mem [0:B_SIZE-1];
    reg [7:0] C_mem [0:C_SIZE-1];

    // CSRs
    reg        start, sat_en, quant_en;
    reg [2:0]  act_mode;
    reg [15:0] quant_scale;       // Q8.8
    reg [7:0]  quant_zero_point;  // integer offset
    reg [7:0]  leaky_alpha;       // Q0.8
    reg        busy, done;

    // LUTs (safe defaults; allow external hex load)
    reg [7:0] sigmoid_table [0:255];
    reg [7:0] tanh_table    [0:255];
    integer ii;
    initial begin
        for (ii=0; ii<256; ii=ii+1) begin
            sigmoid_table[ii]=8'h80;
            tanh_table[ii]=8'h80;
        end
        $readmemh("sigmoid.hex", sigmoid_table);
        $readmemh("tanh.hex", tanh_table);
    end

    // Wishbone access (strictly bounded sub-windows)
    always @(posedge clk) begin
        if (rst) begin
            wb_ack_o<=0; wb_dat_o<=0;
            start<=0; sat_en<=1; quant_en<=0; act_mode<=0;
            quant_scale<=16'd256; quant_zero_point<=8'd0; leaky_alpha<=8'd64;
            busy<=0; done<=0; irq<=0;
        end else begin
            wb_ack_o<=0; irq<=done;
            if (wb_stb_i && wb_cyc_i && !wb_ack_o) begin
                wb_ack_o<=1;
                if (wb_we_i) begin
                    case(wb_adr_i[11:0])
                        12'h000: begin start<=wb_dat_i[0]; sat_en<=wb_dat_i[1]; quant_en<=wb_dat_i[2]; act_mode<=wb_dat_i[5:3]; end
                        12'h00C: begin quant_scale<=wb_dat_i[15:0]; quant_zero_point<=wb_dat_i[23:16]; end
                        12'h010: leaky_alpha<=wb_dat_i[7:0];
                        default: begin
                            if (wb_adr_i>=A_BASE && wb_adr_i<A_BASE+A_SIZE) begin
			       A_mem[wb_adr_i-A_BASE]<=wb_dat_i[7:0];
//			       $display("%m:: A_mem[%h] << %h", wb_adr_i-A_BASE, wb_dat_i[7:0]);
			    end
                            else if (wb_adr_i>=B_BASE && wb_adr_i<B_BASE+B_SIZE) begin
			       B_mem[wb_adr_i-B_BASE]<=wb_dat_i[7:0];
//			       $display("%m:: B_mem[%h] << %h", wb_adr_i-B_BASE, wb_dat_i[7:0]);
			    end
                            else if (wb_adr_i>=C_BASE && wb_adr_i<C_BASE+C_SIZE) begin
			       C_mem[wb_adr_i-C_BASE]<=wb_dat_i[7:0];
//			       $display("%m:: C_mem[%h] << %h", wb_adr_i-C_BASE, wb_dat_i[7:0]);
			    end
                        end
                    endcase
                end else begin
                    case(wb_adr_i[11:0])
                        12'h000: wb_dat_o<={26'h0,act_mode,quant_en,sat_en,1'b0};
                        12'h004: wb_dat_o<={30'h0,done,busy};
                        12'h008: wb_dat_o<={COLS[15:0],ROWS[15:0]};
                        12'h00C: wb_dat_o<={8'h0,quant_zero_point,quant_scale};
                        12'h010: wb_dat_o<={24'h0,leaky_alpha};
                        default: begin
                            if (wb_adr_i>=A_BASE && wb_adr_i<A_BASE+A_SIZE)
                                wb_dat_o<={24'h0,A_mem[wb_adr_i-A_BASE]};
                            else if (wb_adr_i>=B_BASE && wb_adr_i<B_BASE+B_SIZE)
                                wb_dat_o<={24'h0,B_mem[wb_adr_i-B_BASE]};
                            else if (wb_adr_i>=C_BASE && wb_adr_i<C_BASE+C_SIZE)
                                wb_dat_o<={24'h0,C_mem[wb_adr_i-C_BASE]};
                            else wb_dat_o<=32'h0;
                        end
                    endcase
                end
            end
            if (start) start<=0;
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
            state<=ST_IDLE; busy<=0; done<=0; i_row<=0; j_col<=0; k_it<=0; acc<=0;
        end else begin
            case(state)
                ST_IDLE: begin
                    done<=0;
                    if (start) begin
                        busy<=1; i_row<=0; j_col<=0; k_it<=0; acc<=0;
                        state<=ST_COMP;
                    end
                end
                ST_COMP: begin
                    acc<=acc;
                    for (l=0; l<LANES; l=l+1) begin
                        if (k_it + l < COLS) begin
                            acc <= acc +
                                ($signed({1'b0, A_mem[i_row*COLS + (k_it+l)]}) *
                                 $signed({1'b0, B_mem[(k_it+l)*COLS + j_col]}));
                        end
                    end
                    if (k_it + LANES >= COLS) begin
                        C_mem[i_row*COLS + j_col] <= post_process(
                            acc, act_mode, leaky_alpha, sat_en, quant_en, quant_scale, quant_zero_point
                        );
                        if (j_col == COLS-1) begin
                            if (i_row == ROWS-1) state<=ST_DONE;
                            else begin i_row<=i_row+1; j_col<=0; k_it<=0; acc<=0; end
                        end else begin j_col<=j_col+1; k_it<=0; acc<=0; end
                    end else begin
                        k_it<=k_it+LANES;
                    end
                end
                ST_DONE: begin busy<=0; done<=1; state<=ST_IDLE; end
            endcase
        end
    end

    // LUT read (clamped)
    function automatic [7:0] lut_read(input signed [7:0] idx, input is_tanh);
        reg [8:0] u;
        begin
            if (^idx === 1'bx) lut_read = 8'h80;
            else begin
                u = idx + 9'd128;
                if (u > 9'd255) u = 9'd255;
                lut_read = is_tanh ? tanh_table[u[7:0]] : sigmoid_table[u[7:0]];
            end
        end
    endfunction

    // Activation + quantization + saturation
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
                qtmp = (y * $signed({1'b0, q_scale})) >>> 8;
                qtmp = qtmp + $signed({24'd0, q_zero_point});
            end else qtmp = y;

            if (sat) begin
                if (qtmp > 32'sd255)      post_process = 8'hFF;
                else if (qtmp < 32'sd0)   post_process = 8'h00;
                else                      post_process = qtmp[7:0];
            end else post_process = qtmp[7:0];
        end
    endfunction

    function automatic [31:0] activation(
        input  signed [31:0] x,
        input  [2:0]         mode,
        input  [7:0]         alpha_q08
    );
        reg signed [31:0] y;
        reg signed [7:0]  idx;
        begin
            case (mode)
                3'd0: y = x; // None
                3'd1: y = (x < 0) ? 32'sd0 : x; // ReLU
                3'd2: y = (x < 0) ? ((x * alpha_q08) >>> 8) : x; // LeakyReLU
                3'd3: begin idx = x[15:8]; y = $signed({24'd0, lut_read(idx, 1'b0)}); end // Sigmoid
                3'd4: begin idx = x[15:8]; y = $signed({24'd0, lut_read(idx, 1'b1)}); end // Tanh
                default: y = x;
            endcase
            activation = y;
        end
    endfunction

endmodule // dnn_128x128_wb
