// ============================================================
// Testbench using configurable base addresses
// ============================================================
`timescale 1ns/1ns

module tb_conv_accel;

    // Base addresses (match top-level parameters)
    localparam [31:0] IM2_BASE = 32'h00000000;
    localparam [31:0] DNN_BASE = 32'h00010000;

    reg clk, rst;
    reg [31:0] wb_adr_i, wb_dat_i;
    wire [31:0] wb_dat_o;
    reg wb_we_i;
    reg [3:0] wb_sel_i;
    reg wb_stb_i, wb_cyc_i;
    wire wb_ack_o;
    wire irq;

    conv_accel_wb #(
        .ROWS(128), .COLS(128), .LANES(8),
        .IM2_BASE(IM2_BASE), .DNN_BASE(DNN_BASE)
    ) dut(
        .clk(clk), .rst(rst),
        .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i), .wb_dat_o(wb_dat_o),
        .wb_we_i(wb_we_i), .wb_sel_i(wb_sel_i),
        .wb_stb_i(wb_stb_i), .wb_cyc_i(wb_cyc_i), .wb_ack_o(wb_ack_o),
        .irq(irq)
    );

    localparam CLK=10;
    integer i;

    // Clock
    initial begin
`ifdef LXT2
       $dumpfile("wavedump.lxt2");
       $dumpvars(0, tb_conv_accel );
`endif
       #0 clk=0;
       forever
	 #(CLK/2) clk=~clk;
    end

    // Stimulus
    initial begin
        rst=1;
        wb_adr_i=0; wb_dat_i=0; wb_we_i=0; wb_sel_i=4'hF;
        wb_stb_i=0; wb_cyc_i=0;
        #(5*CLK) rst=0;

        // --------------------------------
        // Configure im2col (H=4,W=4,Cin=1, Kh=3,Kw=3, stride=1, pad=0)
        // --------------------------------
        wb_write(IM2_BASE + 32'h000008, {8'd1,8'd4,8'd4});         // Cin=1,H=4,W=4
        wb_write(IM2_BASE + 32'h00000C, {8'd0,8'd1,8'd3,8'd3});   // pad=0,stride=1,Kh=3,Kw=3

        // IFM: 1..16 row-major
        for(i=0;i<16;i=i+1) wb_write(IM2_BASE + 32'h00001000 + i, i+1);

        // --------------------------------
        // Kernel: 3x3 all ones into DNN B buffer
        // --------------------------------
        for(i=0;i<9;i=i+1) wb_write(DNN_BASE + 32'h00002000 + i, 8'd1);

        // --------------------------------
        // Run im2col
        // --------------------------------
        wb_write(IM2_BASE + 32'h00000000, 32'h1);
        // You can poll STATUS at 0x004; here we wait some cycles
        repeat(200) @(posedge clk);

        // --------------------------------
        // Configure DNN: Activation + Quantization
        // ReLU, quant scale 0.5 (Q8.8=128), zero-point 0, saturation ON
        // --------------------------------
        wb_write(DNN_BASE + 32'h00000000, {26'h0, 3'd1 /*ReLU*/, 1'b1 /*quant*/, 1'b1 /*sat*/, 1'b0}); // CTRL
        wb_write(DNN_BASE + 32'h0000000C, {8'd0 /*res*/, 8'd0 /*zp*/, 16'd128 /*scale*/});             // QUANT_CFG

        // --------------------------------
        // Start GEMM
        // --------------------------------
        wb_write(DNN_BASE + 32'h00000000, 32'h1); // start
        wait(irq==1);
        $display("Convolution + activation + quantization done.");

        // --------------------------------
        // Read 2x2 outputs from C buffer (row-major)
        // Expected raw sums: [54,63,90,99]; with scale 0.5 => approx [27,31,45,49]
        // --------------------------------
        for(i=0;i<4;i=i+1) begin
            wb_read(DNN_BASE + 32'h00003000 + i);
            $display("C[%0d] = %0d", i, wb_dat_o[7:0]);
        end

        // --------------------------------
        // Try Sigmoid activation (no extra quantization)
        // --------------------------------
        wb_write(DNN_BASE + 32'h00000000, {26'h0, 3'd3 /*Sigmoid*/, 1'b0 /*quant*/, 1'b1 /*sat*/, 1'b0});
        wb_write(DNN_BASE + 32'h00000000, 32'h1);
        wait(irq==1);
        $display("Convolution + Sigmoid done (LUT).");
        for(i=0;i<4;i=i+1) begin
            wb_read(DNN_BASE + 32'h00003000 + i);
            $display("Sigmoid C[%0d] = %0d", i, wb_dat_o[7:0]);
        end

        // --------------------------------
        // Try Tanh activation (no extra quantization)
        // --------------------------------
        wb_write(DNN_BASE + 32'h00000000, {26'h0, 3'd4 /*Tanh*/, 1'b0 /*quant*/, 1'b1 /*sat*/, 1'b0});
        wb_write(DNN_BASE + 32'h00000000, 32'h1);
        wait(irq==1);
        $display("Convolution + Tanh done (LUT).");
        for(i=0;i<4;i=i+1) begin
            wb_read(DNN_BASE + 32'h00003000 + i);
            $display("Tanh C[%0d] = %0d", i, wb_dat_o[7:0]);
        end

        // --------------------------------
        // Try LeakyReLU with alpha=0.25 (Q0.8 = 64)
        // --------------------------------
        wb_write(DNN_BASE + 32'h00000010, {24'h0, 8'd64}); // LEAKY_ALPHA
        wb_write(DNN_BASE + 32'h00000000, {26'h0, 3'd2 /*LeakyReLU*/, 1'b0 /*quant*/, 1'b1 /*sat*/, 1'b0});
        wb_write(DNN_BASE + 32'h00000000, 32'h1);
        wait(irq==1);
        $display("Convolution + LeakyReLU (alpha=0.25) done.");
        for(i=0;i<4;i=i+1) begin
            wb_read(DNN_BASE + 32'h00003000 + i);
            $display("LeakyReLU C[%0d] = %0d", i, wb_dat_o[7:0]);
        end

        #(50*CLK) $finish;
    end

    // Wishbone helpers
    task wb_write(input [31:0] addr, input [31:0] data);
    begin
        @(posedge clk);
        wb_adr_i <= addr;
        wb_dat_i <= data;
        wb_we_i  <= 1;
        wb_stb_i <= 1;
        wb_cyc_i <= 1;
        @(posedge clk);
        while (!wb_ack_o) @(posedge clk);
        wb_stb_i <= 0; wb_cyc_i <= 0; wb_we_i <= 0;
    end
    endtask

    task wb_read(input [31:0] addr);
    begin
        @(posedge clk);
        wb_adr_i <= addr;
        wb_we_i  <= 0;
        wb_stb_i <= 1;
        wb_cyc_i <= 1;
        @(posedge clk);
        while (!wb_ack_o) @(posedge clk);
        wb_stb_i <= 0; wb_cyc_i <= 0;
    end
    endtask

endmodule // tb_conv_accel_full
