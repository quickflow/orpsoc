// tb_gemm_packed_pipe_dp.v
`timescale 1ns/1ps

`include "header.h"

module tb_gemm_packed_pipe_dp;
    localparam N = 16;

    reg clk=0, rst=1;
    always #5 clk = ~clk; // 100MHz

    // DUT control WB slave
    reg        wbs_stb_i, wbs_cyc_i, wbs_we_i;
    reg [3:0]  wbs_sel_i;
    reg [31:0] wbs_adr_i, wbs_dat_i;
    wire [31:0] wbs_dat_o;
    wire        wbs_ack_o;

   integer	passCount;
   integer	failCount;
   
    initial begin
        wbs_stb_i = 0; wbs_cyc_i = 0; wbs_we_i = 0; wbs_sel_i = 4'hF;
        wbs_adr_i = 32'd0; wbs_dat_i = 32'd0;
       passCount = 0;
       failCount = 0;
    end

    // DUT memory WB master
    wire        wbm_cyc_o, wbm_stb_o, wbm_we_o;
    wire [31:0] wbm_adr_o, wbm_dat_o;
    wire [31:0] wbm_dat_i;
    wire        wbm_ack_i;

    // DUT
    gemm_dma_packed_pipe_dp #(.N(N)) dut (
        .wb_clk_i(clk),
        .wb_rst_i(rst),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i (wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_adr_i(wbs_adr_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_dat_o(wbs_dat_o),
        .wbs_ack_o(wbs_ack_o),
        .wbm_cyc_o(wbm_cyc_o),
        .wbm_stb_o(wbm_stb_o),
        .wbm_we_o (wbm_we_o),
        .wbm_adr_o(wbm_adr_o),
        .wbm_dat_o(wbm_dat_o),
        .wbm_dat_i(wbm_dat_i),
        .wbm_ack_i(wbm_ack_i)
    );

   reg [15:0]	mmA[0:255];
   reg [15:0]	mmB[0:255];
   reg [7:0]	last_gemm_state;
   integer	mi;
   
   initial begin
      $readmemh("matrixA.txt", mmA);
      $readmemh("matrixB.txt", mmB);
      mi = 0;
   end
   
   always@(posedge clk) begin
      if (last_gemm_state != dut.state) begin
	 $display("%m:: gemm_state = %s",
		  dut.state == dut.S_DONE ? "S_DONE" :
		  dut.state == dut.S_W4_WRITE ? "S_W4_WRITE" :
		  dut.state == dut.S_W3_SAT ? "S_W3_SAT" :
		  dut.state == dut.S_W2_QUANT ? "S_W2_QUANT" :
		  dut.state == dut.S_W1_ACT ? "S_W1_ACT" :
		  dut.state == dut.S_W0_READ ? "S_W0_READ" :
		  dut.state == dut.S_W0_READ0 ? "S_W0_READ0" :
		  dut.state == dut.S_W0_READ1 ? "S_W0_READ1" :
		  dut.state == dut.S_W0_READ2 ? "S_W0_READ2" :
		  dut.state == dut.S_W0_READ3 ? "S_W0_READ3" :
		  dut.state == dut.S_COMPUTE ? "S_COMPUTE" :
		  dut.state == dut.S_COMPUTE_S2 ? "S_COMPUTE_S2" :
		  dut.state == dut.S_LOAD_B ? "S_LOAD_B" :
		  dut.state == dut.S_LOAD_A ? "S_LOAD_A" :
		  dut.state == dut.S_CLEAR ? "S_CLEAR" : "S_IDLE");
      end
      last_gemm_state = dut.state;
      if (dut.load_a_we) begin
	 if (mmA[mi] != dut.load_a_data) begin
	    $display("%m:: mmA[%d]= %h  load_a_data= %h  mismatched", mi, mmA[mi], dut.load_a_data);
	 end else begin
//	    $display("%m:: mmA[%d]= %h  load_a_data= %h  matched!", mi, mmA[mi], dut.load_a_data);
	 end
	 mi = mi+1;
	 if (mi == 256)
	   mi = 0;
      end
      if (dut.load_b_we) begin
	 if (mmB[mi] != dut.load_b_data) begin
	    $display("%m:: mmB[%d]= %h  load_b_data= %h  mismatched", mi, mmB[mi], dut.load_b_data);
	 end else begin
//	    $display("%m:: mmB[%d]= %h  load_b_data= %h  matched!", mi, mmB[mi], dut.load_b_data);
	 end
	 mi = mi+1;
	 if (mi == 256)
	   mi = 0;
      end
   end

    // Memory
    wishbone_mem #(.ADDR_WIDTH(16)) mem (
        .wb_clk_i(clk),
        .wb_rst_i(rst),
        .wbs_stb_i(wbm_stb_o),
        .wbs_cyc_i(wbm_cyc_o),
        .wbs_we_i (wbm_we_o),
        .wbs_sel_i(4'hF),
        .wbs_adr_i(wbm_adr_o),
        .wbs_dat_i(wbm_dat_o),
        .wbs_dat_o(wbm_dat_i),
        .wbs_ack_o(wbm_ack_i)
    );

    // Host WB tasks
    task wb_write(input [31:0] adr, input [31:0] data);
    begin
        @(negedge clk);
        wbs_adr_i <= adr;
        wbs_dat_i <= data;
        wbs_we_i  <= 1'b1;
        wbs_stb_i <= 1'b1;
        wbs_cyc_i <= 1'b1;
        @(posedge clk);
        while (!wbs_ack_o) @(posedge clk);
        @(negedge clk);
        wbs_stb_i <= 1'b0; wbs_cyc_i <= 1'b0; wbs_we_i <= 1'b0;
    end
    endtask

    task wb_read(input [31:0] adr, output [31:0] data);
    begin
        @(negedge clk);
        wbs_adr_i <= adr;
        wbs_we_i  <= 1'b0;
        wbs_stb_i <= 1'b1;
        wbs_cyc_i <= 1'b1;
        @(posedge clk);
        while (!wbs_ack_o) @(posedge clk);
        data = wbs_dat_o;
        @(negedge clk);
        wbs_stb_i <= 1'b0; wbs_cyc_i <= 1'b0;
    end
    endtask

   integer mem_writes;
   initial begin
      mem_writes = 0;
   end

    // Direct mem poke/read on shared memory
    task mem_write_word(input [31:0] adr, input [31:0] data);
    begin
       $display("%m:: (%d) adr[%h] data[%h]", mem_writes, adr, data);
       mem_writes = mem_writes + 1;
       
        @(negedge clk);
        force mem.wbs_adr_i = adr;
        force mem.wbs_dat_i = data;
        force mem.wbs_we_i  = 1'b1;
        force mem.wbs_stb_i = 1'b1;
        force mem.wbs_cyc_i = 1'b1;
        @(posedge clk);
        while (!mem.wbs_ack_o) @(posedge clk);
        @(negedge clk);
        force mem.wbs_stb_i = 1'b0; force mem.wbs_cyc_i = 1'b0; force mem.wbs_we_i = 1'b0;
        release mem.wbs_adr_i; release mem.wbs_dat_i; release mem.wbs_we_i; release mem.wbs_stb_i; release mem.wbs_cyc_i;
    end
    endtask

    task mem_read_word(input [31:0] adr, output [31:0] data);
    begin
        @(negedge clk);
        force mem.wbs_adr_i = adr;
        force mem.wbs_we_i  = 1'b0;
        force mem.wbs_stb_i = 1'b1;
        force mem.wbs_cyc_i = 1'b1;
        @(posedge clk);
        while (!mem.wbs_ack_o) @(posedge clk);
        data = mem.wbs_dat_o;
        @(negedge clk);
        force mem.wbs_stb_i = 1'b0; force mem.wbs_cyc_i = 1'b0;
        release mem.wbs_adr_i; release mem.wbs_we_i; release mem.wbs_stb_i; release mem.wbs_cyc_i;
    end
    endtask

    // Base addresses (words)
   localparam BASE_A = 32'h1000;
   localparam BASE_B = 32'h2000;
   localparam BASE_C = 32'h3000;

    // Pack helpers
    function [31:0] pack16(input signed [15:0] x0, input signed [15:0] x1);
        pack16 = {x1[15:0], x0[15:0]};
    endfunction
    function [31:0] pack8(input signed [7:0] x0, input signed [7:0] x1, input signed [7:0] x2, input signed [7:0] x3);
        pack8 = {x3[7:0], x2[7:0], x1[7:0], x0[7:0]};
    endfunction

    function integer val(input integer r, input integer c);
        val = r + 2*c - 3;
    endfunction

    // Load packed matrix into memory (SV keyword automatic avoided)
    task load_matrix_packed(input integer base, input integer dw16, input integer signed_in);
        integer r,c,pack;
        reg [31:0] word;
        reg signed [15:0] x0_16, x1_16;
        reg signed [7:0]  x0_8, x1_8, x2_8, x3_8;
        begin
            pack = dw16 ? 2 : 4;
            for (r=0; r<N; r=r+1) begin
                for (c=0; c<N; c=c+pack) begin
                    if (dw16) begin
                        x0_16 = val(r,c);
                        x1_16 = val(r,c+1);
                        if (!signed_in) begin
                            x0_16 = {1'b0,x0_16[14:0]};
                            x1_16 = {1'b0,x1_16[14:0]};
                        end
                        word = pack16(x0_16, x1_16);
                    end else begin
                        x0_8 = val(r,c);
                        x1_8 = val(r,c+1);
                        x2_8 = val(r,c+2);
                        x3_8 = val(r,c+3);
                        if (!signed_in) begin
                            x0_8 = {1'b0,x0_8[6:0]};
                            x1_8 = {1'b0,x1_8[6:0]};
                            x2_8 = {1'b0,x2_8[6:0]};
                            x3_8 = {1'b0,x3_8[6:0]};
                        end
                        word = pack8(x0_8,x1_8,x2_8,x3_8);
                    end
                   mem_write_word(base + (r*N + c)*4/pack, word);
                end
            end
        end
    endtask

    // Golden helpers
    function signed [31:0] relu(input signed [31:0] x);
        if (x < 0) relu = 0; else relu = x;
    endfunction
    function signed [31:0] leaky_relu_q17(input signed [31:0] x, input signed [7:0] alpha_q1_7);
        reg signed [31:0] alpha_s;
        reg signed [63:0] m;
        begin
            if (x >= 0) leaky_relu_q17 = x;
            else begin
                alpha_s = {{24{alpha_q1_7[7]}}, alpha_q1_7};
                m = $signed(x) * $signed(alpha_s);
                leaky_relu_q17 = m >>> 7;
            end
        end
    endfunction
    function signed [31:0] quantize_q1616(input signed [31:0] x, input [31:0] scale_q1616, input signed [31:0] zero);
        reg signed [63:0] m;
        reg signed [31:0] s;
        begin
            m = $signed(x) * $signed({1'b0, scale_q1616});
            s = (m + 32'sd32768) >>> 16;
            quantize_q1616 = s + zero;
        end
    endfunction

    task check_results(input [7:0] testNum,
		       input integer base_c, input integer dw16,
                       input integer act_en, input integer quant_en, input integer act_type,
                       input [31:0]  scale_q1616, input signed [31:0] zero, input signed [7:0] alpha_q1_7);
        integer r,c,t,pack,elem_in_word;
        reg [31:0] word;
        reg signed [31:0] acc, out, actv, qv;
        reg signed [15:0] out16_0, out16_1;
        reg signed [7:0]  out8_0, out8_1, out8_2, out8_3;
        integer mism;
       begin
	  $display("%m:: Test(%d)", testNum);
	  
            pack  = dw16 ? 2 : 4;
            mism  = 0;
            for (r=0; r<N; r=r+1) begin
                for (c=0; c<N; c=c+pack) begin
//                    mem_read_word(base_c + ((r*N + c) / pack), word);
//                   mem_write_word(base + (r*N + c)*4/pack, word);
                    mem_read_word(base_c + (r*N + c)*4/pack, word);
		   $display("%m:: word read[%08h]= %08h", base_c + (r*N + c)*4/pack, word);
                    if (dw16) begin
                        out16_0 = word[15:0];
                        out16_1 = word[31:16];
                    end else begin
                        out8_0 = word[7:0];
                        out8_1 = word[15:8];
                        out8_2 = word[23:16];
                        out8_3 = word[31:24];
		       $display("[CPUboard_tb]GPIO val = %08h", word);
		       $display("[CPUboard_tb]GPIO val = %08h", 32'h88000000 | out8_0);
		       $display("[CPUboard_tb]GPIO val = %08h", 32'h88000000 | out8_1);
		       $display("[CPUboard_tb]GPIO val = %08h", 32'h88000000 | out8_2);
		       $display("[CPUboard_tb]GPIO val = %08h", 32'h88000000 | out8_3);
                    end
                    for (elem_in_word=0; elem_in_word<pack; elem_in_word=elem_in_word+1) begin
                        integer col;
                        col = c + elem_in_word;
                        acc = 0;
		       $display("%m:: acc (%d)", col);
                        for (t=0; t<N; t=t+1) begin
			   acc = acc + (val(r,t) * val(t,col));
			   $display("%02h < %02h %02h", acc, val(r,t), val(t,col));
			   if (dw16) begin
//			     $display("[CPUboard_tb]GPIO val = %08h", 32'h8a000000 | val(r,t));
//			     $display("[CPUboard_tb]GPIO val = %08h", 32'h8a000000 | val(t,col));
//			     $display("[CPUboard_tb]GPIO val = %08h", 32'h8a000000 | (acc & 32'h00ffffff));
			   end
			   
			end
		       
                        actv = acc;
                        if (act_en) begin
                            if (!act_type) actv = relu(actv); else actv = leaky_relu_q17(actv, alpha_q1_7);
                        end
                        qv = actv;
                        if (quant_en) qv = quantize_q1616(qv, scale_q1616, zero);
                        if (dw16) begin
                            if (qv > 32767) out = 32767; else if (qv < -32768) out = -32768; else out = qv;
                            if (elem_in_word==0) begin
                                if (out16_0 !== out[15:0]) begin
                                    $display("Mismatch16.0 @ (%0d,%0d): got %0h exp %0h", r, col, out16_0, out);
                                    mism = mism + 1;
                                end
                            end else begin
                                if (out16_1 !== out[15:0]) begin
                                    $display("Mismatch16.1 @ (%0d,%0d): got %0h exp %0h", r, col, out16_1, out);
                                    mism = mism + 1;
                                end
                            end
                        end else begin
                            if (qv > 127) out = 127; else if (qv < -128) out = -128; else out = qv;
                            case (elem_in_word)
                                0: if ($signed({{24{out8_0[7]}}, out8_0}) !== out) begin
                                       $display("Mismatch8 @ (%0d,%0d): got %0h exp %0h", r, col, $signed({{24{out8_0[7]}}, out8_0}), out);
                                       mism = mism + 1;
                                   end
                                1: if ($signed({{24{out8_1[7]}}, out8_1}) !== out) begin
                                       $display("Mismatch8 @ (%0d,%0d): got %0h exp %0h", r, col, $signed({{24{out8_1[7]}}, out8_1}), out);
                                       mism = mism + 1;
                                   end
                                2: if ($signed({{24{out8_2[7]}}, out8_2}) !== out) begin
                                       $display("Mismatch8 @ (%0d,%0d): got %0h exp %0h", r, col, $signed({{24{out8_2[7]}}, out8_2}), out);
                                       mism = mism + 1;
                                   end
                                3: if ($signed({{24{out8_3[7]}}, out8_3}) !== out) begin
                                       $display("Mismatch8 @ (%0d,%0d): got %0h exp %0h", r, col, $signed({{24{out8_3[7]}}, out8_3}), out);
                                       mism = mism + 1;
                                   end
                            endcase
                        end
                    end
                end
            end
            if (mism==0) begin
	       $display("CHECK PASS on Test(%d) packed dw16=%0d act=%0d quant=%0d type=%0d", testNum, dw16, act_en, quant_en, act_type);
	       passCount = passCount + 1;
	    end else begin
	       $display("CHECK FAIL on Test(%d) mismatches=%0d", testNum, mism);
	       failCount = failCount + 1;
	    end
        end
    endtask

    // LXT2 dump
    initial begin
        $dumpfile("gemm_packed_pipe_dp.lxt2");
        $dumpvars(0, tb_gemm_packed_pipe_dp);
    end

   integer act_en, quant_en, mode_16, act_type, mode_signed;
   integer reg_mode_val;

    // Sequence
    initial begin
        #1 rst=1;
        #50 rst=0;

        // Program bases
        wb_write(`REG_BASE_A, BASE_A);
        wb_write(`REG_BASE_B, BASE_B);
        wb_write(`REG_BASE_C, BASE_C);

        // Test 1: 16-bit, packed, no activation/quant
       act_en = 0;
       quant_en = 0;
       mode_16 = 1;
       act_type = 0;
       mode_signed = 0;

       reg_mode_val = (mode_16 << `MODE_DW16) |
		      (act_en << `MODE_ACT) |
		      (quant_en << `MODE_QUANT) |
		      (act_type << `MODE_ACT_TYPE) |
		      (mode_signed << `MODE_SIGNED);

       $display("%m:: load_matrixA");
        load_matrix_packed(BASE_A, 1, 1);

       $display("%m:: load_matrixB");
        load_matrix_packed(BASE_B, 1, 1);
        wb_write(`REG_MODE, reg_mode_val); // dw16=1, act=0, quant=0, relu=0, signed=1
        wb_write(`REG_CTRL_STAT, 32'b1);
        wait_done();
        check_results(1, BASE_C, mode_16, act_en, quant_en, act_type, 32'd65536, 32'sd0, 8'sd0);

        // Test 2: 16-bit, ReLU activation
       act_en = 1;
       quant_en = 0;
       mode_16 = 1;
       act_type = 1;
       mode_signed = 0;

       reg_mode_val = (mode_16 << `MODE_DW16) |
		      (act_en << `MODE_ACT) |
		      (quant_en << `MODE_QUANT) |
		      (act_type << `MODE_ACT_TYPE) |
		      (mode_signed << `MODE_SIGNED);

        wb_write(`REG_MODE, reg_mode_val); // act_en=1
        wb_write(`REG_CTRL_STAT, 32'b1);
        wait_done();
        check_results(2, BASE_C, mode_16, act_en, quant_en, act_type, 32'd65536, 32'sd0, 8'sd0);

        // Test 3: 8-bit, ReLU + quant (scale 0.125)
       act_en = 0;
       quant_en = 0; //1;
       mode_16 = 0;
       act_type = 0; //1;
       mode_signed = 0;

       reg_mode_val = (mode_16 << `MODE_DW16) |
		      (act_en << `MODE_ACT) |
		      (quant_en << `MODE_QUANT) |
		      (act_type << `MODE_ACT_TYPE) |
		      (mode_signed << `MODE_SIGNED);

        load_matrix_packed(BASE_A, 0, 1);
        load_matrix_packed(BASE_B, 0, 1);
        wb_write(`REG_QZERO, 32'd8192); // 0.125
        wb_write(`REG_MODE, reg_mode_val); // dw16=0, act=1, quant=1
        wb_write(`REG_CTRL_STAT, 32'b1);
        wait_done();
        check_results(3, BASE_C, mode_16, act_en, quant_en, act_type, 32'd8192, 32'sd0, 8'sd0);

        // Test 4: 8-bit, LeakyReLU alpha=0.125 + quant 0.5
       act_en = 1;
       quant_en = 1;
       mode_16 = 0;
       act_type = 1;
       mode_signed = 0;

       reg_mode_val = (mode_16 << `MODE_DW16) |
		      (act_en << `MODE_ACT) |
		      (quant_en << `MODE_QUANT) |
		      (act_type << `MODE_ACT_TYPE) |
		      (mode_signed << `MODE_SIGNED);

        wb_write(`REG_ALPHA, 32'd16);   // alpha Q1.7
        wb_write(`REG_QSCALE, 32'd32768);// scale 0.5
        wb_write(`REG_QZERO, 32'b0000_1_1_1_1); // leaky
        wb_write(`REG_MODE, reg_mode_val); // dw16=0, act=1, quant=1
        wb_write(`REG_CTRL_STAT, 32'b1);
        wait_done();
        check_results(4, BASE_C, mode_16, act_en, quant_en, act_type, 32'd32768, 32'sd0, 8'sd16);

        $display("All tests completed.");
        #100 $finish;
    end

    task wait_done;
        reg [31:0] status;
        integer timeout;
        begin
            timeout = 0;
            wb_read(`REG_CTRL_STAT, status);
            while (!status[16] && timeout < 1000000) begin
                @(posedge clk);
                wb_read(`REG_CTRL_STAT, status);
                timeout = timeout + 1;
            end
            if (!status[1]) $display("Timeout waiting for DONE");
        end
    endtask

endmodule // tb_gemm_packed_pipe_dp
