// d2d_link_wrapper.v
// Wrapper module for D2D Link with combined Wishbone master interface

module d2d_link_wrapper #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Wishbone Clock and Reset
    input wire wb_clk,
    input wire wb_rst_n,
    
    // Combined Wishbone Master Interface
    output wire wb_cyc_o,
    output wire wb_stb_o,
    output wire wb_we_o,
    output wire [ADDR_WIDTH-1:0] wb_adr_o,
    output wire [DATA_WIDTH-1:0] wb_dat_o,
    input  wire wb_ack_i,
    input  wire [DATA_WIDTH-1:0] wb_dat_i,
    
    // CSR Wishbone Slave Interface (unchanged)
    input  wire csr_wb_cyc_i,
    input  wire csr_wb_stb_i,
    input  wire csr_wb_we_i,
    input  wire [ADDR_WIDTH-1:0] csr_wb_adr_i,
    input  wire [DATA_WIDTH-1:0] csr_wb_dat_i,
    output wire csr_wb_ack_o,
    output wire [DATA_WIDTH-1:0] csr_wb_dat_o,
    
    // D2D Clock and Reset
    input  wire d2d_clk,
    input  wire d2d_rst_n,
    
    // D2D TX Interface
    output wire [63:0] tx_data,
    output wire tx_valid,
    input  wire tx_ready,
    
    // D2D RX Interface
    input  wire [63:0] rx_data,
    input  wire rx_valid,
    output wire rx_ready,

  input wire [7:0] cpuID
);

    // Internal signals for the two DMA master interfaces
    wire tx_wb_cyc_o;
    wire tx_wb_stb_o;
    wire tx_wb_we_o;
    wire [ADDR_WIDTH-1:0] tx_wb_adr_o;
    wire [DATA_WIDTH-1:0] tx_wb_dat_o;
    wire tx_wb_ack_i;
    wire [DATA_WIDTH-1:0] tx_wb_dat_i;
    
    wire rx_wb_cyc_o;
    wire rx_wb_stb_o;
    wire rx_wb_we_o;
    wire [ADDR_WIDTH-1:0] rx_wb_adr_o;
    wire [DATA_WIDTH-1:0] rx_wb_dat_o;
    wire rx_wb_ack_i;
    wire [DATA_WIDTH-1:0] rx_wb_dat_i;
    
    // Instantiate the original D2D link module
    d2d_link_top dut (
        // Wishbone CSR Interface
        .wb_clk(wb_clk),
        .wb_rst_n(wb_rst_n),
        
        // CSR Wishbone Slave
        .csr_wb_cyc_i(csr_wb_cyc_i),
        .csr_wb_stb_i(csr_wb_stb_i),
        .csr_wb_we_i(csr_wb_we_i),
        .csr_wb_adr_i(csr_wb_adr_i),
        .csr_wb_dat_i(csr_wb_dat_i),
        .csr_wb_ack_o(csr_wb_ack_o),
        .csr_wb_dat_o(csr_wb_dat_o),
        
        // TX DMA Wishbone Master
        .tx_wb_cyc_o(tx_wb_cyc_o),
        .tx_wb_stb_o(tx_wb_stb_o),
        .tx_wb_we_o(tx_wb_we_o),
        .tx_wb_adr_o(tx_wb_adr_o),
        .tx_wb_dat_o(tx_wb_dat_o),
        .tx_wb_ack_i(tx_wb_ack_i),
        .tx_wb_dat_i(tx_wb_dat_i),
        
        // RX DMA Wishbone Master
        .rx_wb_cyc_o(rx_wb_cyc_o),
        .rx_wb_stb_o(rx_wb_stb_o),
        .rx_wb_we_o(rx_wb_we_o),
        .rx_wb_adr_o(rx_wb_adr_o),
        .rx_wb_dat_o(rx_wb_dat_o),
        .rx_wb_ack_i(rx_wb_ack_i),
        .rx_wb_dat_i(rx_wb_dat_i),
        
        // D2D Interface
        .d2d_clk(d2d_clk),
        .d2d_rst_n(d2d_rst_n),
        
        // TX D2D Interface
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        
        // RX D2D Interface
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_ready(rx_ready),

	.cpuID(cpuID)
    );
    
    // State machine for Wishbone bus arbitration
    reg [1:0] arb_state;
    reg [1:0] arb_next_state;
    
    // Arbitration states
    localparam IDLE     = 2'b00;
    localparam GRANT_TX = 2'b01;
    localparam GRANT_RX = 2'b10;
    
    // Internal registered outputs
    reg wb_cyc_o_reg;
    reg wb_stb_o_reg;
    reg wb_we_o_reg;
    reg [ADDR_WIDTH-1:0] wb_adr_o_reg;
    reg [DATA_WIDTH-1:0] wb_dat_o_reg;
    
    // Internal registered inputs
    reg tx_wb_ack_i_reg;
    reg rx_wb_ack_i_reg;
    reg [DATA_WIDTH-1:0] tx_wb_dat_i_reg;
    reg [DATA_WIDTH-1:0] rx_wb_dat_i_reg;
    
   reg			 last_was_rx, n_last_was_rx;
   
    // Priority: RX has higher priority than TX (receiving data is time-critical)
    // This can be configured differently based on system requirements
    
    // State machine for arbitration
    always @(posedge wb_clk or negedge wb_rst_n) begin
        if (!wb_rst_n) begin
            arb_state <= IDLE;
	   last_was_rx <= 0;
        end else begin
            arb_state <= arb_next_state;
	   last_was_rx <= n_last_was_rx;
        end
    end
    
    // Next state logic
    always @(*) begin
        arb_next_state = arb_state;
       n_last_was_rx = last_was_rx;
       
        case (arb_state)
            IDLE: begin
                // Priority: RX > TX
                if (rx_wb_cyc_o && !last_was_rx) begin
                    arb_next_state = GRANT_RX;
		   n_last_was_rx = 1;
                end else if (tx_wb_cyc_o) begin
                    arb_next_state = GRANT_TX;
		   n_last_was_rx = 0;
                end else if (rx_wb_cyc_o) begin
		   arb_next_state = GRANT_RX;
		   n_last_was_rx = 1;
		end
            end
            
            GRANT_TX: begin
                if (wb_ack_i) begin
                   arb_next_state = IDLE;
                end
            end
            
            GRANT_RX: begin
                if (wb_ack_i) begin
                   arb_next_state = IDLE;
                end
            end
            
            default: arb_next_state = IDLE;
        endcase
    end
    
   assign wb_cyc_o = (arb_state == GRANT_TX) ? tx_wb_cyc_o : 
		     (arb_state == GRANT_RX) ? rx_wb_cyc_o : 0;
   
   assign wb_stb_o = (arb_state == GRANT_TX) ? tx_wb_stb_o : 
		     (arb_state == GRANT_RX) ? rx_wb_stb_o : 0;
   
   assign wb_we_o =  (arb_state == GRANT_TX) ? tx_wb_we_o : 
		     (arb_state == GRANT_RX) ? rx_wb_we_o : 0;
   
   assign wb_adr_o = (arb_state == GRANT_TX) ? tx_wb_adr_o : 
		     (arb_state == GRANT_RX) ? rx_wb_adr_o : 0;
   
   assign wb_dat_o = (arb_state == GRANT_TX) ? tx_wb_dat_o : 
		     (arb_state == GRANT_RX) ? rx_wb_dat_o : 0;
   
   assign tx_wb_ack_i = (arb_state == GRANT_TX) ? wb_ack_i : 0;
   assign rx_wb_ack_i = (arb_state == GRANT_RX) ? wb_ack_i : 0;
   assign tx_wb_dat_i = wb_dat_i;
   assign rx_wb_dat_i = wb_dat_i;

endmodule // d2d_link_wrapper
