// ============================================================
// Top-level conv accelerator: im2col + activation/quantized GEMM
// Configurable base addresses for each sub-block
// ============================================================
module conv_accel_wb #
(
    parameter ROWS  = 128,
    parameter COLS  = 128,
    parameter LANES = 8,

    // Base addresses (aligned to 64KB windows for simplicity)
    parameter IM2_BASE = 32'h00000000,
    parameter DNN_BASE = 32'h00010000
)
(
    input  wire        clk,
    input  wire        rst,

    // Wishbone
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output wire [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire [3:0]  wb_sel_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output wire        wb_ack_o,

    output wire        irq
);

    // Decode: route based on base address ranges
    wire sel_im2 = (wb_adr_i >= IM2_BASE && wb_adr_i < IM2_BASE + 32'h00010000); // 64KB window
    wire sel_dnn = (wb_adr_i >= DNN_BASE && wb_adr_i < DNN_BASE + 32'h00010000); // 64KB window

    // Adjusted addresses for submodules (subtract base)
    wire [31:0] im2_addr = wb_adr_i - IM2_BASE;
    wire [31:0] dnn_addr = wb_adr_i - DNN_BASE;

    // im2col instance
    wire [31:0] im2_wb_dat_o;
    wire        im2_wb_ack_o;
    wire        im2_irq;

    im2col_wb im2 (
        .clk(clk), .rst(rst),
        .wb_adr_i(im2_addr), .wb_dat_i(wb_dat_i), .wb_dat_o(im2_wb_dat_o),
        .wb_we_i(wb_we_i), .wb_sel_i(wb_sel_i),
        .wb_stb_i(wb_stb_i & sel_im2), .wb_cyc_i(wb_cyc_i & sel_im2), .wb_ack_o(im2_wb_ack_o),
        .irq(im2_irq)
    );

    // Quantized GEMM engine
    wire [31:0] dnn_wb_dat_o;
    wire        dnn_wb_ack_o;
    wire        dnn_irq;

    dnn_128x128_wb #(.ROWS(ROWS), .COLS(COLS), .LANES(LANES)) dnn (
        .clk(clk), .rst(rst),
        .wb_adr_i(dnn_addr), .wb_dat_i(wb_dat_i), .wb_dat_o(dnn_wb_dat_o),
        .wb_we_i(wb_we_i), .wb_sel_i(wb_sel_i),
        .wb_stb_i(wb_stb_i & sel_dnn), .wb_cyc_i(wb_cyc_i & sel_dnn), .wb_ack_o(dnn_wb_ack_o),
        .irq(dnn_irq)
    );

    // Multiplex outputs
    assign wb_dat_o = sel_im2 ? im2_wb_dat_o :
                      sel_dnn ? dnn_wb_dat_o : 32'h0;

    assign wb_ack_o = sel_im2 ? im2_wb_ack_o :
                      sel_dnn ? dnn_wb_ack_o : 1'b0;

    // IRQ: GEMM completion is the main signal (OR with im2 IRQ for observability)
    assign irq = dnn_irq | im2_irq;

endmodule // conv_accel_wb

