// ============================================================
// Testbench using configurable base addresses
// ============================================================
`timescale 1ns/1ns

module tb_conv_accel;

    // Global bases matching top-level
    localparam [31:0] IM2_BASE = 32'h0000_0000;
    localparam [31:0] DNN_BASE = 32'h0200_0000;

    // Mirror DUT parameters
    localparam integer ROWS   = 128;
    localparam integer COLS   = 128;
    localparam integer LANES  = 8;

    localparam integer MAX_H   = 128;
    localparam integer MAX_W   = 128;
    localparam integer MAX_CIN = 32;
    localparam integer MAX_KH  = 7;
    localparam integer MAX_KW  = 7;

    // Derived sub-window bases and sizes (must mirror module constants)
    // DNN
    localparam [31:0] DNN_A_BASE = 32'h0000_1000;
    localparam [31:0] DNN_B_BASE = 32'h0000_5000;
    localparam [31:0] DNN_C_BASE = 32'h0000_9000;
    localparam integer A_SIZE = ROWS*COLS;   // 16384
    localparam integer B_SIZE = COLS*COLS;   // 16384
    localparam integer C_SIZE = ROWS*COLS;   // 16384

    // IM2
    localparam [31:0] IM2_IFM_BASE = 32'h0000_1000;
    localparam integer IFM_SIZE    = MAX_H*MAX_W*MAX_CIN; // 524288
    localparam [31:0] IM2_IM2_BASE = ((IM2_IFM_BASE + IFM_SIZE + 32'hFFF) & 32'hFFFF_F000); // 0x0008_1000
    localparam integer IM2_SIZE    = MAX_H*MAX_W*MAX_KH*MAX_KW*MAX_CIN; // 25769472

    reg clk, rst;
    reg [31:0] wb_adr_i, wb_dat_i;
    wire [31:0] wb_dat_o;
    reg wb_we_i;
    reg [3:0] wb_sel_i;
    reg wb_stb_i, wb_cyc_i;
    wire wb_ack_o;
    wire irq;

    conv_accel_wb #(
        .ROWS(ROWS), .COLS(COLS), .LANES(LANES),
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

    initial begin
`ifdef LXT2
       $dumpfile("wavedump.lxt2");
       $dumpvars(0, tb_conv_accel );
`endif
        clk = 0;
        forever #(CLK/2) clk = ~clk;
    end

    initial begin
        rst=1;
        wb_adr_i=0; wb_dat_i=0; wb_we_i=0; wb_sel_i=4'hF;
        wb_stb_i=0; wb_cyc_i=0;
        #(5*CLK) rst=0;

`ifdef INIT_ALL_MEM
        // -----------------------------
        // Initialize entire DUT memories via Wishbone writes
        // -----------------------------
        // DNN A_mem
       $display("%m:: init DNN A_mem");
        for (i=0; i<A_SIZE; i=i+1)
            wb_write(DNN_BASE + DNN_A_BASE + i, 8'h00);

        // DNN B_mem
       $display("%m:: init DNN B_mem");
        for (i=0; i<B_SIZE; i=i+1)
            wb_write(DNN_BASE + DNN_B_BASE + i, 8'h00);

        // DNN C_mem
       $display("%m:: init DNN C_mem");
        for (i=0; i<C_SIZE; i=i+1)
            wb_write(DNN_BASE + DNN_C_BASE + i, 8'h00);

        // im2 IFM
       $display("%m:: init im2 IFM");
        for (i=0; i<IFM_SIZE; i=i+1)
            wb_write(IM2_BASE + IM2_IFM_BASE + i, 8'h00);

        // im2 IM2 (WARNING: very large; slow in simulation)
       $display("%m:: init im2 IM2");
        for (i=0; i<IM2_SIZE; i=i+1)
            wb_write(IM2_BASE + IM2_IM2_BASE + i, 8'h00);

`else       
       // Initialize only occupied entries
       
       // DNN A_mem (36 entries)
       $display("%m:: init DNN A_mem");
       for (i=0; i<36; i=i+1)
	 wb_write(DNN_BASE + DNN_A_BASE + i, 8'h00);
       
       // DNN B_mem (9 entries)
       $display("%m:: init DNN B_mem");
       for (i=0; i<9; i=i+1)
	 wb_write(DNN_BASE + DNN_B_BASE + i, 8'h00);
       
       // DNN C_mem (4 entries)
       $display("%m:: init DNN C_mem");
       for (i=0; i<4; i=i+1)
	 wb_write(DNN_BASE + DNN_C_BASE + i, 8'h00);
       
       // im2 IFM (16 entries)
       $display("%m:: init im2 IFM");
       for (i=0; i<16; i=i+1)
	 wb_write(IM2_BASE + IM2_IFM_BASE + i, 8'h00);
       
       // im2 IM2 (36 entries)
       $display("%m:: init im2 IM2");
       for (i=0; i<36; i=i+1)
	 wb_write(IM2_BASE + IM2_IM2_BASE + i, 8'h00);
`endif // !`ifdef INIT_ALL_MEM
       
       $display("%m:: start here");
        // -----------------------------
        // Configure im2col: H=4, W=4, Cin=1; Kh=3, Kw=3, stride=1, pad=0
        // -----------------------------
        wb_write(IM2_BASE + 32'h0000_0008, {8'd1,8'd4,8'd4});       // Cin=1,H=4,W=4
        wb_write(IM2_BASE + 32'h0000_000C, {8'd0,8'd1,8'd3,8'd3}); // pad=0,stride=1,Kh=3,Kw=3

        // Load IFM: 1..16 row-major into IFM window
        for (i=0; i<16; i=i+1) wb_write(IM2_BASE + IM2_IFM_BASE + i, i+1);

        // Run im2col
        wb_write(IM2_BASE + 32'h0000_0000, 32'h1);

        // Poll STATUS until not busy
        wb_read(IM2_BASE + 32'h0000_0004);
        while (wb_dat_o[0] == 1'b1) begin
            @(posedge clk);
            wb_read(IM2_BASE + 32'h0000_0004);
        end

        // -----------------------------
        // Copy IM2_mem -> DNN A_mem for occupied region of this test (36 bytes)
        // -----------------------------
        for (i=0; i<36; i=i+1) begin
            wb_read(IM2_BASE + IM2_IM2_BASE + i);
            wb_write(DNN_BASE + DNN_A_BASE + i, wb_dat_o[7:0]);
        end

        // Load kernel (3x3 all ones) into DNN B buffer (first 9 entries)
        for (i=0; i<9; i=i+1) wb_write(DNN_BASE + DNN_B_BASE + i, 8'd1);

        // Configure DNN: ReLU + quant scale 0.5 (Q8.8=128), zero-point 0, saturation ON
        wb_write(DNN_BASE + 32'h0000_0000, {26'h0, 3'd1 /*ReLU*/, 1'b1 /*quant*/, 1'b1 /*sat*/, 1'b0});
        wb_write(DNN_BASE + 32'h0000_000C, {8'd0 /*res*/, 8'd0 /*zp*/, 16'd128 /*scale*/});

        // Start GEMM
        wb_write(DNN_BASE + 32'h0000_0000, 32'h1);
        wait(irq==1);
        $display("Convolution + ReLU + quantization done.");

        // Read 2x2 outputs from C buffer (row-major)
        for (i=0; i<4; i=i+1) begin
            wb_read(DNN_BASE + DNN_C_BASE + i);
            $display("ReLU+Quant C[%0d] = %0d", i, wb_dat_o[7:0]);
        end

        // Sigmoid activation
        wb_write(DNN_BASE + 32'h0000_0000, {26'h0, 3'd3 /*Sigmoid*/, 1'b0 /*quant*/, 1'b1 /*sat*/, 1'b0});
        wb_write(DNN_BASE + 32'h0000_0000, 32'h1);
        wait(irq==1);
        $display("Convolution + Sigmoid done.");
        for (i=0; i<4; i=i+1) begin
            wb_read(DNN_BASE + DNN_C_BASE + i);
            $display("Sigmoid C[%0d] = %0d", i, wb_dat_o[7:0]);
        end

        // Tanh activation
        wb_write(DNN_BASE + 32'h0000_0000, {26'h0, 3'd4 /*Tanh*/, 1'b0 /*quant*/, 1'b1 /*sat*/, 1'b0});
        wb_write(DNN_BASE + 32'h0000_0000, 32'h1);
        wait(irq==1);
        $display("Convolution + Tanh done.");
        for (i=0; i<4; i=i+1) begin
            wb_read(DNN_BASE + DNN_C_BASE + i);
            $display("Tanh C[%0d] = %0d", i, wb_dat_o[7:0]);
        end

        // LeakyReLU alpha=0.25 (Q0.8 = 64)
        wb_write(DNN_BASE + 32'h0000_0010, {24'h0, 8'd64});
        wb_write(DNN_BASE + 32'h0000_0000, {26'h0, 3'd2 /*LeakyReLU*/, 1'b0 /*quant*/, 1'b1 /*sat*/, 1'b0});
        wb_write(DNN_BASE + 32'h0000_0000, 32'h1);
        wait(irq==1);
        $display("Convolution + LeakyReLU (alpha=0.25) done.");
        for (i=0; i<4; i=i+1) begin
            wb_read(DNN_BASE + DNN_C_BASE + i);
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

endmodule // tb_conv_accel
