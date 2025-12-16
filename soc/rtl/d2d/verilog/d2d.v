// ucie_wishbone_dma_top.v
`timescale 1ns/1ps

module ucie_wishbone_dma_top #(
    parameter DATA_WIDTH = 64,           // UCIe widths are commonly 64/128/256
    parameter WB_DATA_WIDTH = 32,        // Wishbone data width
    parameter WB_ADDR_WIDTH = 16,
    parameter FIFO_DEPTH = 32
)(
    // Wishbone SoC clock/reset
    input                      wb_clk,
    input                      wb_rst_n,

    // Wishbone master (DMA -> system memory)
    output [WB_ADDR_WIDTH-1:0] m_adr_o,
    output [WB_DATA_WIDTH-1:0] m_dat_o,
    input  [WB_DATA_WIDTH-1:0] m_dat_i,
    output                     m_we_o,
    output                     m_stb_o,
    output                     m_cyc_o,
    input                      m_ack_i,

    // Wishbone slave (DMA config)
    input  [WB_ADDR_WIDTH-1:0] s_adr_i,
    input  [WB_DATA_WIDTH-1:0] s_dat_i,
    output [WB_DATA_WIDTH-1:0] s_dat_o,
    input                      s_we_i,
    input                      s_stb_i,
    input                      s_cyc_i,
    output                     s_ack_o,

    // UCIe die-to-die link clock/reset (independent domain)
    input                      ucie_clk,
    input                      ucie_rst_n,

    // UCIe streaming TX (to remote)
    output [DATA_WIDTH-1:0]    ucie_tx_data,
    output                     ucie_tx_valid,
    input                      ucie_tx_ready,

    // UCIe streaming RX (from remote)
    input  [DATA_WIDTH-1:0]    ucie_rx_data,
    input                      ucie_rx_valid,
    output                     ucie_rx_ready
);
    // Internal wires: DMA streaming ports are on wb_clk
    wire [WB_DATA_WIDTH-1:0]   dma_tx_data_wb;
    wire                       dma_tx_valid_wb;
    wire                       dma_tx_ready_wb;

    wire [WB_DATA_WIDTH-1:0]   dma_rx_data_wb;
    wire                       dma_rx_valid_wb;
    wire                       dma_rx_ready_wb;

    // Width adapter between WB (32-bit default) and UCIe (64-bit default)
    wire [DATA_WIDTH-1:0]      pack_tx_data_link;
    wire                       pack_tx_valid_link;
    wire                       pack_tx_ready_link;

    wire [DATA_WIDTH-1:0]      ucie_rx_data_link;
    wire                       ucie_rx_valid_link;
    wire                       ucie_rx_ready_link;

    // ---------------------------
    // DMA engine (Wishbone domain)
    // ---------------------------
    wb_dma_d2d #(
        .DATA_WIDTH(WB_DATA_WIDTH),
        .ADDR_WIDTH(WB_ADDR_WIDTH)
    ) dma (
        .wb_clk(wb_clk),
        .wb_rst_n(wb_rst_n),

        .m_adr_o(m_adr_o),
        .m_dat_o(m_dat_o),
        .m_dat_i(m_dat_i),
        .m_we_o(m_we_o),
        .m_stb_o(m_stb_o),
        .m_cyc_o(m_cyc_o),
        .m_ack_i(m_ack_i),

        .s_adr_i(s_adr_i),
        .s_dat_i(s_dat_i),
        .s_dat_o(s_dat_o),
        .s_we_i(s_we_i),
        .s_stb_i(s_stb_i),
        .s_cyc_i(s_cyc_i),
        .s_ack_o(s_ack_o),

        .tx_data(dma_tx_data_wb),
        .tx_valid(dma_tx_valid_wb),
        .tx_ready(dma_tx_ready_wb),

        .rx_data(dma_rx_data_wb),
        .rx_valid(dma_rx_valid_wb),
        .rx_ready(dma_rx_ready_wb)
    );

    // ----------------------------------------
    // Pack/Unpack between WB width and UCIe width
    //  - TX packs two 32-bit beats into one 64-bit word
    //  - RX unpacks one 64-bit word into two 32-bit beats
    // ----------------------------------------
    stream_width_adapter_pack #(
        .IN_WIDTH(WB_DATA_WIDTH),
        .OUT_WIDTH(DATA_WIDTH)
    ) pack_tx (
        .clk(wb_clk),
        .rst_n(wb_rst_n),
        .in_data(dma_tx_data_wb),
        .in_valid(dma_tx_valid_wb),
        .in_ready(dma_tx_ready_wb),
        .out_data(pack_tx_data_link),
        .out_valid(pack_tx_valid_link),
        .out_ready(pack_tx_ready_link)
    );

    stream_width_adapter_unpack #(
        .IN_WIDTH(DATA_WIDTH),
        .OUT_WIDTH(WB_DATA_WIDTH)
    ) unpack_rx (
        .clk(wb_clk),
        .rst_n(wb_rst_n),
        .in_data(ucie_rx_data_link),
        .in_valid(ucie_rx_valid_link),
        .in_ready(ucie_rx_ready_link),
        .out_data(dma_rx_data_wb),
        .out_valid(dma_rx_valid_wb),
        .out_ready(dma_rx_ready_wb)
    );

    // ----------------------------------------
    // Asynchronous bridge (wb_clk <-> ucie_clk)
    // ----------------------------------------
    async_stream_bridge #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) bridge (
        // TX: WB -> UCIe
        .tx_wb_clk(wb_clk),
        .tx_wb_rst_n(wb_rst_n),
        .tx_wb_data(pack_tx_data_link),
        .tx_wb_valid(pack_tx_valid_link),
        .tx_wb_ready(pack_tx_ready_link),

        .tx_link_clk(ucie_clk),
        .tx_link_rst_n(ucie_rst_n),
        .tx_link_data(ucie_tx_data),
        .tx_link_valid(ucie_tx_valid),
        .tx_link_ready(ucie_tx_ready),

        // RX: UCIe -> WB
        .rx_link_clk(ucie_clk),
        .rx_link_rst_n(ucie_rst_n),
        .rx_link_data(ucie_rx_data),
        .rx_link_valid(ucie_rx_valid),
        .rx_link_ready(ucie_rx_ready),

        .rx_wb_clk(wb_clk),
        .rx_wb_rst_n(wb_rst_n),
        .rx_wb_data(ucie_rx_data_link),
        .rx_wb_valid(ucie_rx_valid_link),
        .rx_wb_ready(ucie_rx_ready_link)
    );

endmodule // ucie_wishbone_dma_top

// wb_dma_d2d.v
`timescale 1ns/1ps

module wb_dma_d2d #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16
)(
    input                   wb_clk,
    input                   wb_rst_n,

    // Wishbone master (to memory)
    output [ADDR_WIDTH-1:0] m_adr_o,
    output [DATA_WIDTH-1:0] m_dat_o,
    input  [DATA_WIDTH-1:0] m_dat_i,
    output                  m_we_o,
    output                  m_stb_o,
    output                  m_cyc_o,
    input                   m_ack_i,

    // Wishbone slave (config)
    input  [ADDR_WIDTH-1:0] s_adr_i,
    input  [DATA_WIDTH-1:0] s_dat_i,
    output [DATA_WIDTH-1:0] s_dat_o,
    input                   s_we_i,
    input                   s_stb_i,
    input                   s_cyc_i,
    output                  s_ack_o,

    // Streaming (wb_clk domain)
    output [DATA_WIDTH-1:0] tx_data,
    output                  tx_valid,
    input                   tx_ready,

    input  [DATA_WIDTH-1:0] rx_data,
    input                   rx_valid,
    output                  rx_ready
);
    // Registers
    reg [ADDR_WIDTH-1:0] tx_src, rx_dst;
    reg [31:0]           tx_len, rx_len;
    reg [2:0]            tx_ctrl, rx_ctrl; // [0]=start, [1]=busy, [2]=done

    // WB slave: simple ack and readback
    assign s_ack_o = s_stb_i & s_cyc_i;
    assign s_dat_o =
        (s_adr_i[5:0] == 6'h00) ? {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, tx_src} :
        (s_adr_i[5:0] == 6'h04) ? tx_len :
        (s_adr_i[5:0] == 6'h08) ? {{(DATA_WIDTH-3){1'b0}}, tx_ctrl} :
        (s_adr_i[5:0] == 6'h0C) ? {{(DATA_WIDTH-ADDR_WIDTH){1'b0}}, rx_dst} :
        (s_adr_i[5:0] == 6'h10) ? rx_len :
        (s_adr_i[5:0] == 6'h14) ? {{(DATA_WIDTH-3){1'b0}}, rx_ctrl} :
        {DATA_WIDTH{1'b0}};

    always @(posedge wb_clk or negedge wb_rst_n) begin
        if (!wb_rst_n) begin
            tx_src<=0; tx_len<=0; tx_ctrl<=0;
            rx_dst<=0; rx_len<=0; rx_ctrl<=0;
        end else if (s_stb_i && s_cyc_i && s_we_i) begin
            case (s_adr_i[5:0])
                6'h00: tx_src  <= s_dat_i[ADDR_WIDTH-1:0];
                6'h04: tx_len  <= s_dat_i[31:0];
                6'h08: begin
                    if (s_dat_i[0]) tx_ctrl[0] <= 1'b1;
                    if (s_dat_i[1]) tx_ctrl[1] <= 1'b0;
                    if (s_dat_i[2]) tx_ctrl[2] <= 1'b0;
                end
                6'h0C: rx_dst  <= s_dat_i[ADDR_WIDTH-1:0];
                6'h10: rx_len  <= s_dat_i[31:0];
                6'h14: begin
                    if (s_dat_i[0]) rx_ctrl[0] <= 1'b1;
                    if (s_dat_i[1]) rx_ctrl[1] <= 1'b0;
                    if (s_dat_i[2]) rx_ctrl[2] <= 1'b0;
                end
            endcase
        end
    end

    // Wishbone master signals
    reg [ADDR_WIDTH-1:0] m_adr_r;
    reg [DATA_WIDTH-1:0] m_dat_r;
    reg m_we_r, m_stb_r, m_cyc_r;

    assign m_adr_o = m_adr_r;
    assign m_dat_o = m_dat_r;
    assign m_we_o  = m_we_r;
    assign m_stb_o = m_stb_r;
    assign m_cyc_o = m_cyc_r;

    // TX FSM
    localparam TX_IDLE=0, TX_REQ=1, TX_DATA=2, TX_DONE=3;
    reg [1:0] tx_state;
    reg [ADDR_WIDTH-1:0] tx_addr;
    reg [31:0] tx_remaining;
    reg [DATA_WIDTH-1:0] tx_data_r;
    reg tx_valid_r;

    assign tx_data  = tx_data_r;
    assign tx_valid = tx_valid_r;

    // RX FSM
    localparam RX_IDLE=0, RX_WAIT=1, RX_WRITE=2, RX_DONE=3;
    reg [1:0] rx_state;
    reg [ADDR_WIDTH-1:0] rx_addr;
    reg [31:0] rx_remaining;
    reg rx_ready_r;
    assign rx_ready = rx_ready_r;

    always @(posedge wb_clk or negedge wb_rst_n) begin
        if (!wb_rst_n) begin
            // Common reset
            m_adr_r<=0; m_dat_r<=0; m_we_r<=0; m_stb_r<=0; m_cyc_r<=0;
            // TX
            tx_state<=TX_IDLE; tx_addr<=0; tx_remaining<=0; tx_valid_r<=0;
            tx_ctrl[1]<=0; tx_ctrl[2]<=0;
            // RX
            rx_state<=RX_IDLE; rx_addr<=0; rx_remaining<=0; rx_ready_r<=0;
            rx_ctrl[1]<=0; rx_ctrl[2]<=0;
        end else begin
            // TX FSM
            case (tx_state)
                TX_IDLE: begin
                    tx_valid_r <= 1'b0;
                    if (tx_ctrl[0] && tx_len!=0) begin
                        tx_ctrl[0] <= 1'b0; tx_ctrl[1] <= 1'b1; tx_ctrl[2] <= 1'b0;
                        tx_addr <= tx_src; tx_remaining <= tx_len; tx_state <= TX_REQ;
                    end
                end
                TX_REQ: begin
                    m_adr_r <= tx_addr; m_we_r <= 1'b0; m_stb_r <= 1'b1; m_cyc_r <= 1'b1;
                    if (m_ack_i) begin
                        m_stb_r <= 1'b0; m_cyc_r <= 1'b0;
                        tx_data_r <= m_dat_i; tx_state <= TX_DATA;
                    end
                end
                TX_DATA: begin
                    tx_valid_r <= 1'b1;
                    if (tx_valid_r && tx_ready) begin
                        tx_valid_r <= 1'b0;
                        tx_addr <= tx_addr + (DATA_WIDTH/8);
                        tx_remaining <= tx_remaining - 1;
                        tx_state <= (tx_remaining==1) ? TX_DONE : TX_REQ;
                    end
                end
                TX_DONE: begin
                    tx_ctrl[1] <= 1'b0; tx_ctrl[2] <= 1'b1; tx_state <= TX_IDLE;
                end
            endcase

            // RX FSM
            case (rx_state)
                RX_IDLE: begin
                    rx_ready_r <= 1'b0;
                    if (rx_ctrl[0] && rx_len!=0) begin
                        rx_ctrl[0] <= 1'b0; rx_ctrl[1] <= 1'b1; rx_ctrl[2] <= 1'b0;
                        rx_addr <= rx_dst; rx_remaining <= rx_len; rx_state <= RX_WAIT;
                    end
                end
                RX_WAIT: begin
                    rx_ready_r <= 1'b1;
                    if (rx_valid && rx_ready_r) begin
                        m_adr_r <= rx_addr; m_dat_r <= rx_data;
                        m_we_r <= 1'b1; m_stb_r <= 1'b1; m_cyc_r <= 1'b1;
                        rx_ready_r <= 1'b0; rx_state <= RX_WRITE;
                    end
                end
                RX_WRITE: begin
                    if (m_ack_i) begin
                        m_stb_r <= 1'b0; m_cyc_r <= 1'b0; m_we_r <= 1'b0;
                        rx_addr <= rx_addr + (DATA_WIDTH/8);
                        rx_remaining <= rx_remaining - 1;
                        rx_state <= (rx_remaining==1) ? RX_DONE : RX_WAIT;
                    end
                end
                RX_DONE: begin
                    rx_ctrl[1] <= 1'b0; rx_ctrl[2] <= 1'b1; rx_state <= RX_IDLE;
                end
            endcase
        end
    end
endmodule // wb_dma_d2d

// async_stream_bridge.v
`timescale 1ns/1ps

module async_stream_bridge #(
    parameter DATA_WIDTH = 64,
    parameter FIFO_DEPTH = 32
)(
    // TX path: WB -> UCIe
    input                   tx_wb_clk,
    input                   tx_wb_rst_n,
    input  [DATA_WIDTH-1:0] tx_wb_data,
    input                   tx_wb_valid,
    output                  tx_wb_ready,

    input                   tx_link_clk,
    input                   tx_link_rst_n,
    output [DATA_WIDTH-1:0] tx_link_data,
    output                  tx_link_valid,
    input                   tx_link_ready,

    // RX path: UCIe -> WB
    input                   rx_link_clk,
    input                   rx_link_rst_n,
    input  [DATA_WIDTH-1:0] rx_link_data,
    input                   rx_link_valid,
    output                  rx_link_ready,

    input                   rx_wb_clk,
    input                   rx_wb_rst_n,
    output [DATA_WIDTH-1:0] rx_wb_data,
    output                  rx_wb_valid,
    input                   rx_wb_ready
);
    // TX dual-clock FIFO (gray pointers)
    reg [DATA_WIDTH-1:0] tx_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0] tx_wr_bin, tx_wr_gray;
    reg [$clog2(FIFO_DEPTH):0] tx_rd_bin, tx_rd_gray;
    reg [$clog2(FIFO_DEPTH):0] tx_rd_gray_sync1, tx_rd_gray_sync2;
    reg [$clog2(FIFO_DEPTH):0] tx_wr_gray_sync1, tx_wr_gray_sync2;

    wire tx_fifo_full  = (tx_wr_gray == {~tx_rd_gray_sync2[$clog2(FIFO_DEPTH):$clog2(FIFO_DEPTH)-1], tx_rd_gray_sync2[$clog2(FIFO_DEPTH)-2:0]});
    wire tx_fifo_empty = (tx_wr_gray_sync2 == tx_rd_gray);

    assign tx_wb_ready   = !tx_fifo_full;
    assign tx_link_valid = !tx_fifo_empty;
    assign tx_link_data  = tx_mem[tx_rd_bin[$clog2(FIFO_DEPTH)-1:0]];

    always @(posedge tx_wb_clk or negedge tx_wb_rst_n) begin
        if (!tx_wb_rst_n) begin
            tx_wr_bin<=0; tx_wr_gray<=0; tx_rd_gray_sync1<=0; tx_rd_gray_sync2<=0;
        end else begin
            tx_rd_gray_sync1 <= tx_rd_gray;
            tx_rd_gray_sync2 <= tx_rd_gray_sync1;
            if (tx_wb_valid && tx_wb_ready) begin
                tx_mem[tx_wr_bin[$clog2(FIFO_DEPTH)-1:0]] <= tx_wb_data;
                tx_wr_bin  <= tx_wr_bin + 1;
                tx_wr_gray <= (tx_wr_bin + 1) ^ ((tx_wr_bin + 1) >> 1);
            end
        end
    end

    always @(posedge tx_link_clk or negedge tx_link_rst_n) begin
        if (!tx_link_rst_n) begin
            tx_rd_bin<=0; tx_rd_gray<=0; tx_wr_gray_sync1<=0; tx_wr_gray_sync2<=0;
        end else begin
            tx_wr_gray_sync1 <= tx_wr_gray;
            tx_wr_gray_sync2 <= tx_wr_gray_sync1;
            if (tx_link_valid && tx_link_ready) begin
                tx_rd_bin  <= tx_rd_bin + 1;
                tx_rd_gray <= (tx_rd_bin + 1) ^ ((tx_rd_bin + 1) >> 1);
            end
        end
    end

    // RX dual-clock FIFO (gray pointers)
    reg [DATA_WIDTH-1:0] rx_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0] rx_wr_bin, rx_wr_gray;
    reg [$clog2(FIFO_DEPTH):0] rx_rd_bin, rx_rd_gray;
    reg [$clog2(FIFO_DEPTH):0] rx_rd_gray_sync1, rx_rd_gray_sync2;
    reg [$clog2(FIFO_DEPTH):0] rx_wr_gray_sync1, rx_wr_gray_sync2;

    wire rx_fifo_full  = (rx_wr_gray == {~rx_rd_gray_sync2[$clog2(FIFO_DEPTH):$clog2(FIFO_DEPTH)-1], rx_rd_gray_sync2[$clog2(FIFO_DEPTH)-2:0]});
    wire rx_fifo_empty = (rx_wr_gray_sync2 == rx_rd_gray);

    assign rx_link_ready = !rx_fifo_full;
    assign rx_wb_valid   = !rx_fifo_empty;
    assign rx_wb_data    = rx_mem[rx_rd_bin[$clog2(FIFO_DEPTH)-1:0]];

    always @(posedge rx_link_clk or negedge rx_link_rst_n) begin
        if (!rx_link_rst_n) begin
            rx_wr_bin<=0; rx_wr_gray<=0; rx_rd_gray_sync1<=0; rx_rd_gray_sync2<=0;
        end else begin
            rx_rd_gray_sync1 <= rx_rd_gray;
            rx_rd_gray_sync2 <= rx_rd_gray_sync1;
            if (rx_link_valid && rx_link_ready) begin
                rx_mem[rx_wr_bin[$clog2(FIFO_DEPTH)-1:0]] <= rx_link_data;
                rx_wr_bin  <= rx_wr_bin + 1;
                rx_wr_gray <= (rx_wr_bin + 1) ^ ((rx_wr_bin + 1) >> 1);
            end
        end
    end

    always @(posedge rx_wb_clk or negedge rx_wb_rst_n) begin
        if (!rx_wb_rst_n) begin
            rx_rd_bin<=0; rx_rd_gray<=0; rx_wr_gray_sync1<=0; rx_wr_gray_sync2<=0;
        end else begin
            rx_wr_gray_sync1 <= rx_wr_gray;
            rx_wr_gray_sync2 <= rx_wr_gray_sync1;
            if (rx_wb_valid && rx_wb_ready) begin
                rx_rd_bin  <= rx_rd_bin + 1;
                rx_rd_gray <= (rx_rd_bin + 1) ^ ((rx_rd_bin + 1) >> 1);
            end
        end
    end
endmodule // async_stream_bridge

// stream_width_adapter_pack.v
`timescale 1ns/1ps

module stream_width_adapter_pack #(
    parameter IN_WIDTH  = 32,
    parameter OUT_WIDTH = 64
)(
    input                   clk,
    input                   rst_n,
    input  [IN_WIDTH-1:0]   in_data,
    input                   in_valid,
    output                  in_ready,
    output [OUT_WIDTH-1:0]  out_data,
    output                  out_valid,
    input                   out_ready
);
    localparam RATIO = OUT_WIDTH / IN_WIDTH;
    reg [$clog2(RATIO)-1:0] cnt;
    reg [OUT_WIDTH-1:0]     shreg;
    reg                     out_v;

    assign in_ready  = (!out_v) || (out_ready && (cnt != (RATIO-1)));
    assign out_data  = shreg;
    assign out_valid = out_v;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 0; shreg <= 0; out_v <= 1'b0;
        end else begin
            // Accept input beats until we have RATIO beats
            if (in_valid && in_ready) begin
                shreg <= {shreg[OUT_WIDTH-IN_WIDTH-1:0], in_data};
                if (cnt == (RATIO-1)) begin
                    out_v <= 1'b1;
                end
                cnt <= (cnt == (RATIO-1)) ? 0 : (cnt + 1);
            end
            // Output handshake
            if (out_v && out_ready) begin
                out_v <= 1'b0;
            end
        end
    end
endmodule // stream_width_adapter_pack

// stream_width_adapter_unpack.v
`timescale 1ns/1ps

module stream_width_adapter_unpack #(
    parameter IN_WIDTH  = 64,
    parameter OUT_WIDTH = 32
)(
    input                  clk,
    input                  rst_n,
    input  [IN_WIDTH-1:0]  in_data,
    input                  in_valid,
    output                 in_ready,
    output [OUT_WIDTH-1:0] out_data,
    output                 out_valid,
    input                  out_ready
);
    localparam RATIO = IN_WIDTH / OUT_WIDTH;
    reg [$clog2(RATIO)-1:0] cnt;
    reg [IN_WIDTH-1:0]      shreg;
    reg                     have_word;
    reg                     out_v;

    assign in_ready  = !have_word; // accept new word when not busy
    assign out_data  = shreg[IN_WIDTH-1 - cnt*OUT_WIDTH -: OUT_WIDTH];
    assign out_valid = out_v;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt<=0; shreg<=0; have_word<=1'b0; out_v<=1'b0;
        end else begin
            if (in_valid && in_ready) begin
                shreg <= in_data; have_word <= 1'b1;
                cnt <= 0; out_v <= 1'b1;
            end
            if (out_v && out_ready) begin
                if (cnt == (RATIO-1)) begin
                    out_v <= 1'b0; have_word <= 1'b0; cnt <= 0;
                end else begin
                    cnt <= cnt + 1;
                end
            end
        end
    end
endmodule // stream_width_adapter_unpack

