// tb_d2d_dma.v
`timescale 1ns/1ps

module tb_d2d_dma;
    localparam WB_DATA_WIDTH = 32;
    localparam WB_ADDR_WIDTH = 32;
    localparam D2d_WIDTH    = 64;
    localparam DEPTH_WORDS   = 1024;

   localparam  NUM_TX_DATA_WORDS = 32;
   localparam  NUM_RX_DATA_WORDS = 64;
   
    // Clocks
    reg wb_clk, wb_rst_n;
    reg d2d_clk, d2d_rst_n;

    initial begin
        wb_clk=0; forever #5 wb_clk=~wb_clk;     // 100 MHz
    end
    initial begin
        d2d_clk=0; forever #7 d2d_clk=~d2d_clk; // ~71 MHz
    end
    initial begin
        wb_rst_n=0; d2d_rst_n=0;
        #50 wb_rst_n=1; d2d_rst_n=1;
    end

    // DUT ports
    wire [WB_ADDR_WIDTH-1:0] m_adr_o;
    wire [WB_DATA_WIDTH-1:0] m_dat_o;
    wire [WB_DATA_WIDTH-1:0] m_dat_i;
    wire                     m_we_o, m_stb_o, m_cyc_o;
    wire                     m_ack_i;

    reg  [WB_ADDR_WIDTH-1:0] s_adr_i;
    reg  [WB_DATA_WIDTH-1:0] s_dat_i;
    wire [WB_DATA_WIDTH-1:0] s_dat_o;
    reg                      s_we_i, s_stb_i, s_cyc_i;
    wire                     s_ack_o;

    wire [D2d_WIDTH-1:0]    d2d_tx_data;
    wire                     d2d_tx_valid;
    reg                      d2d_tx_ready;
    reg  [D2d_WIDTH-1:0]    d2d_rx_data;
    reg                      d2d_rx_valid;
    wire                     d2d_rx_ready;

    // DUT instantiation
   d2d_wishbone_dma_top dut (
        .wb_clk(wb_clk), .wb_rst_n(wb_rst_n),
        .m_adr_o(m_adr_o), .m_dat_o(m_dat_o), .m_dat_i(m_dat_i),
        .m_we_o(m_we_o), .m_stb_o(m_stb_o), .m_cyc_o(m_cyc_o), .m_ack_i(m_ack_i),
        .s_adr_i(s_adr_i), .s_dat_i(s_dat_i), .s_dat_o(s_dat_o),
        .s_we_i(s_we_i), .s_stb_i(s_stb_i), .s_cyc_i(s_cyc_i), .s_ack_o(s_ack_o),
        .d2d_clk(d2d_clk), .d2d_rst_n(d2d_rst_n),
        .d2d_tx_data(d2d_tx_data), .d2d_tx_valid(d2d_tx_valid), .d2d_tx_ready(d2d_tx_ready),
        .d2d_rx_data(d2d_rx_data), .d2d_rx_valid(d2d_rx_valid), .d2d_rx_ready(d2d_rx_ready)
    );

    // Memory instance
    wb_simple_ram #(.DATA_WIDTH(WB_DATA_WIDTH), .ADDR_WIDTH(WB_ADDR_WIDTH), .DEPTH_WORDS(DEPTH_WORDS)) mem (
        .wb_clk(wb_clk), .wb_rst_n(wb_rst_n),
        .wb_adr_i(m_adr_o), .wb_dat_i(m_dat_o), .wb_dat_o(m_dat_i),
        .wb_we_i(m_we_o), .wb_stb_i(m_stb_o), .wb_cyc_i(m_cyc_o), .wb_ack_o(m_ack_i)
    );

   reg [63:0]		     rx_data_val;
   
    // Random backpressure/stalls
    always @(posedge d2d_clk or negedge d2d_rst_n) begin
        if (!d2d_rst_n) begin
            d2d_tx_ready <= 1'b1;
            d2d_rx_valid <= 1'b0;
            d2d_rx_data  <= 0;
	   rx_data_val <= 64'h0102030405060708;
        end else begin
            d2d_tx_ready <= ($random % 4 != 0); // randomly deassert
            if ($random % 5 == 0) begin
                d2d_rx_valid <= 1'b1;
               d2d_rx_data  <= rx_data_val;
	       rx_data_val <= rx_data_val + 64'h0101010101010101;
            end else begin
                d2d_rx_valid <= 1'b0;
            end
        end
    end

    // Config bus helpers
    task wb_cfg_write(input [WB_ADDR_WIDTH-1:0] addr, input [WB_DATA_WIDTH-1:0] data);
    begin
        @(posedge wb_clk);
        s_adr_i <= addr; s_dat_i <= data; s_we_i <= 1; s_stb_i <= 1; s_cyc_i <= 1;
        @(posedge wb_clk);
        s_stb_i <= 0; s_cyc_i <= 0; s_we_i <= 0;
    end
    endtask

    task wb_cfg_read(input [WB_ADDR_WIDTH-1:0] addr, output [WB_DATA_WIDTH-1:0] data);
    begin
        @(posedge wb_clk);
        s_adr_i <= addr; s_we_i <= 0; s_stb_i <= 1; s_cyc_i <= 1;
        @(posedge wb_clk);
        data = s_dat_o;
        s_stb_i <= 0; s_cyc_i <= 0;
    end
    endtask

    // Testcase
    integer i;
   reg [31:0] tx_ctrl_rd, rx_ctrl_rd;
   integer    errors;
   reg [63:0] expected_rx_dat;

    initial begin
        s_adr_i=0; s_dat_i=0; s_we_i=0; s_stb_i=0; s_cyc_i=0;

        // Dumpvars
        $dumpfile("d2d_dma.vcd");
        $dumpvars(0, tb_d2d_dma);

        @(posedge wb_rst_n);
        @(posedge wb_clk);

        // Preload TX buffer at 0x0100
        for (i=0; i<NUM_TX_DATA_WORDS; i=i+1) begin
           mem.mem[(16'h0100 >> 2) + i] = 32'hA5A5_0000 | i;
        end

        // Configure TX
        wb_cfg_write(16'h0000, 16'h0100); // TX_SRC
        wb_cfg_write(16'h0004, NUM_TX_DATA_WORDS);   // TX_LEN
        wb_cfg_write(16'h0008, 32'h1);    // TX_CTRL start

        // Configure RX
        wb_cfg_write(16'h000C, 16'h0800); // RX_DST
        wb_cfg_write(16'h0010, NUM_RX_DATA_WORDS);   // RX_LEN
        wb_cfg_write(16'h0014, 32'h1);    // RX_CTRL start

        // Wait for DMA done
       errors = 0;
       
       while(errors < 2000) begin
          wb_cfg_read(16'h0008, tx_ctrl_rd);
          wb_cfg_read(16'h0014, rx_ctrl_rd);
          if (tx_ctrl_rd[2] && rx_ctrl_rd[2]) begin
             $display("DMA done at time %t", $time);
	     errors = 2000;
	  end
	  
          @(posedge wb_clk);
        end

       if (!tx_ctrl_rd[2] || !rx_ctrl_rd[2])
	 $display("*** ERROR DMA not done ***");
       
       errors=0;
        // Check RX buffer
       expected_rx_dat = 64'h0102030405060708;
       
        for (i=0; i<NUM_RX_DATA_WORDS; i=i+2) begin
            if (mem.mem[(16'h0800 >> 2) + i] !== expected_rx_dat[63:32]) begin
                $display("ERROR: RX mem[%0d] = %h", i, mem.mem[(16'h0800 >> 2) + i]);
                errors = errors + 1;
            end else begin
                $display("GOOD : RX mem[%0d] = %h", i, mem.mem[(16'h0800 >> 2) + i]);
	    end
	   
	    if (mem.mem[(16'h0800 >> 2) + i + 1] !== expected_rx_dat[31:0]) begin
                $display("ERROR: RX mem[%0d] =             %h", i + 1, mem.mem[(16'h0800 >> 2) + i + 1]);
            end else begin
                $display("GOOD : RX mem[%0d] =             %h", i + 1, mem.mem[(16'h0800 >> 2) + i + 1]);
	    end
	   
           @(posedge wb_clk);
	   expected_rx_dat <= expected_rx_dat + 64'h0101010101010101;
           @(posedge wb_clk);
        end

        if (errors==0)
            $display("PASS: RX buffer validated");
        else
            $display("FAIL: %0d mismatches", errors);

        #200;
        $finish;
    end
endmodule // tb_d2d_dma
