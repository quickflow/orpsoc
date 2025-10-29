module uart_wishbone (
    input         clk,
    input         rst,

    // Wishbone interface
    input         wb_cyc_i,
    input         wb_stb_i,
    input         wb_we_i,
    input  [3:0]  wb_sel_i,
    input  [31:0] wb_adr_i,
    input  [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    output reg        wb_ack_o,

    // UART signals
    input         rx,
    output reg    tx,

    // Interrupts
    output        irq_out
);

   wire		  irq_rx_done, irq_tx_done, irq_fifo_full;
   assign	  irq_out = irq_rx_done || irq_tx_done || irq_fifo_full;

    // ------------------------------------------------------------
    // Register map
    // 0x00: CTRL       [enable, reset]
    // 0x04: BAUD_DIV   [15:0]
    // 0x08: TX_DATA    [7:0]
    // 0x0C: RX_DATA    [7:0]
    // 0x10: STATUS     [fifo_full, tx_done, rx_done]
    // ------------------------------------------------------------

    reg [15:0] baud_div;
    reg [7:0]  tx_data;
    reg [7:0]  rx_data;
    reg        tx_done, rx_done, fifo_full;

    // Wishbone write
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            baud_div <= 16'd868; // default 115200 @ 100 MHz
            tx_data  <= 8'd0;
	   wb_ack_o <= 0;
	   
        end else if (wb_cyc_i && wb_stb_i && wb_we_i) begin
            case (wb_adr_i[4:2])
                3'b001: baud_div <= wb_dat_i[15:0];
                3'b010: tx_data  <= wb_dat_i[7:0]; // triggers TX
            endcase
        end
    end

    // Wishbone read
    always @(posedge clk) begin
        wb_ack_o <= wb_cyc_i & wb_stb_i && !wb_ack_o;
        if (wb_cyc_i && wb_stb_i && !wb_we_i) begin
            case (wb_adr_i[4:2])
                3'b011: wb_dat_o <= {24'd0, rx_data};
                3'b100: wb_dat_o <= {29'd0, fifo_full, tx_done, rx_done};
                default: wb_dat_o <= 32'd0;
            endcase
        end
    end

    // ------------------------------------------------------------
    // Baud rate generator
    // ------------------------------------------------------------
    reg [15:0] baud_cnt;
    wire baud_tick = (baud_cnt == 0);

    // ------------------------------------------------------------
    // TX FIFO and engine
    // ------------------------------------------------------------
    reg [7:0] tx_fifo [0:15];
    reg [3:0] tx_wr_ptr, tx_rd_ptr;
    reg [9:0] tx_shift;
    reg [3:0] tx_bit_cnt;
    reg       tx_busy;

    always @(posedge clk or posedge rst) begin
       if (rst) begin
	   baud_cnt <= 0;
	   tx_wr_ptr <= 0;
	   tx_rd_ptr <= 0;
	  tx_busy <= 0;
       end
       else begin
        baud_cnt <= baud_tick ? baud_div : baud_cnt - 1;
        if (wb_cyc_i && wb_stb_i && wb_we_i && (wb_adr_i[4:2] == 3'b010) && !fifo_full && !wb_ack_o) begin
            tx_fifo[tx_wr_ptr] <= tx_data;
            tx_wr_ptr <= tx_wr_ptr + 1;
        end

        fifo_full <= (tx_wr_ptr + 1 == tx_rd_ptr);

        if (baud_tick && !tx_busy && tx_wr_ptr != tx_rd_ptr) begin
            tx_shift <= {1'b1, tx_fifo[tx_rd_ptr], 1'b0}; // stop, data, start
            tx_bit_cnt <= 0;
            tx_busy <= 1;
            tx_rd_ptr <= tx_rd_ptr + 1;
        end else if (baud_tick && tx_busy) begin
            tx <= tx_shift[0];
           tx_shift <= tx_shift >> 1;
            tx_bit_cnt <= tx_bit_cnt + 1;
            if (tx_bit_cnt == 9) begin
                tx_busy <= 0;
                tx_done <= 1;
            end else begin
                tx_done <= 0;
            end
        end // if (baud_tick && tx_busy)
       end // else: !if(rst)
    end

    // ------------------------------------------------------------
    // RX FIFO and engine
    // ------------------------------------------------------------
    reg [7:0] rx_fifo [0:15];
    reg [3:0] rx_wr_ptr, rx_rd_ptr;
    reg [9:0] rx_shift;
    reg [3:0] rx_bit_cnt;
    reg       rx_busy;

    always @(posedge clk) begin
        if (!rx_busy && !rx) begin
            rx_busy <= 1;
            rx_bit_cnt <= 0;
	   rx_rd_ptr <= 0;
	   rx_wr_ptr <= 0;
        end else if (baud_tick && rx_busy) begin
            rx_shift <= {rx, rx_shift[9:1]};
            rx_bit_cnt <= rx_bit_cnt + 1;
            if (rx_bit_cnt == 9) begin
                rx_fifo[rx_wr_ptr] <= rx_shift[8:1];
                rx_wr_ptr <= rx_wr_ptr + 1;
                rx_busy <= 0;
                rx_done <= 1;
            end else begin
                rx_done <= 0;
            end
        end

        if (wb_cyc_i && wb_stb_i && !wb_we_i && (wb_adr_i[4:2] == 3'b011) && (rx_rd_ptr != rx_wr_ptr) && !wb_ack_o) begin
            rx_data <= rx_fifo[rx_rd_ptr];
            rx_rd_ptr <= rx_rd_ptr + 1;
        end
    end

    // ------------------------------------------------------------
    // Interrupts
    // ------------------------------------------------------------
    assign irq_rx_done   = rx_done;
    assign irq_tx_done   = tx_done;
    assign irq_fifo_full = fifo_full;

endmodule
