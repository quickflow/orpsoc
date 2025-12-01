// dp_ram.v (unchanged, Verilog-2001 compliant)
`timescale 1ns/1ps
module dp_ram #(
    parameter WIDTH = 16,
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  wire                  clk,
    // Port A
    input  wire                  we_a,
    input  wire [ADDR_WIDTH-1:0] addr_a,
    input  wire [WIDTH-1:0]      din_a,
    output wire [WIDTH-1:0]      dout_a,
    // Port B
    input  wire                  we_b,
    input  wire [ADDR_WIDTH-1:0] addr_b,
    input  wire [WIDTH-1:0]      din_b,
    output wire [WIDTH-1:0]      dout_b
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        // Port A
        if (we_a) mem[addr_a] <= din_a;
        // Port B
        if (we_b) mem[addr_b] <= din_b;
    end

   assign        dout_a = mem[addr_a];
   assign        dout_b = mem[addr_b];

endmodule // dp_ram
