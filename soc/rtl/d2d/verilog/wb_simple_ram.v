// wb_simple_ram.v
`timescale 1ns/1ps

module wb_simple_ram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,
    parameter DEPTH_WORDS= 4096
)(
    input                   wb_clk,
    input                   wb_rst_n,
    input  [ADDR_WIDTH-1:0] wb_adr_i,
    input  [DATA_WIDTH-1:0] wb_dat_i,
    output [DATA_WIDTH-1:0] wb_dat_o,
    input                   wb_we_i,
    input                   wb_stb_i,
    input                   wb_cyc_i,
    output                  wb_ack_o
);
    localparam ADDR_LSB = $clog2(DATA_WIDTH/8);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH_WORDS-1];
    reg [DATA_WIDTH-1:0] dat_r;
    reg ack_r;

    assign wb_dat_o = dat_r;
    assign wb_ack_o = ack_r;

    wire [ADDR_WIDTH-1:ADDR_LSB] word_addr = wb_adr_i[ADDR_WIDTH-1:ADDR_LSB];

    always @(posedge wb_clk or negedge wb_rst_n) begin
        if (!wb_rst_n) begin
            ack_r <= 1'b0; dat_r <= {DATA_WIDTH{1'b0}};
        end else begin
            ack_r <= 1'b0;
            if (wb_stb_i && wb_cyc_i) begin
                ack_r <= 1'b1;
                if (wb_we_i) mem[word_addr] <= wb_dat_i;
                else dat_r <= mem[word_addr];
            end
        end
    end

    // Expose for testbench preload/check
    // synopsys translate_off
    // pragma translate_off
    // memory array 'mem' intentionally left accessible
    // synopsys translate_on
    // pragma translate_on
endmodule // wb_simple_ram

