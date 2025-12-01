// wishbone_mem.v (unchanged)
`timescale 1ns/1ps
module wishbone_mem #(
    parameter ADDR_WIDTH = 16, // words
    parameter MEM_DEPTH  = 1 << ADDR_WIDTH
)(
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire        wbs_stb_i,
    input  wire        wbs_cyc_i,
    input  wire        wbs_we_i,
    input  wire [3:0]  wbs_sel_i,
    input  wire [31:0] wbs_adr_i,
    input  wire [31:0] wbs_dat_i,
    output reg  [31:0] wbs_dat_o,
    output reg         wbs_ack_o
);
    reg [31:0] mem [0:MEM_DEPTH-1];
    integer idx;
    initial begin
        for (idx=0; idx<MEM_DEPTH; idx=idx+1) mem[idx] = 32'd0;
    end

    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            wbs_ack_o <= 1'b0;
            wbs_dat_o <= 32'd0;
        end else begin
            wbs_ack_o <= 1'b0;
            if (wbs_stb_i && wbs_cyc_i && !wbs_ack_o) begin
                wbs_ack_o <= 1'b1;
                if (wbs_we_i) mem[wbs_adr_i] <= wbs_dat_i;
                else          wbs_dat_o      <= mem[wbs_adr_i];
            end
        end
    end
endmodule // wishbone_mem
