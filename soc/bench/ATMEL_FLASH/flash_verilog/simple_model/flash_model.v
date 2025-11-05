module AT26DFxxx
  (
   input  CSB,
   input  SCK,
   input  SI,
   input  WPB,
   output SO
   );
   
   
   wire	  clk = SCK;
   // SPI Clock (SCK)
   wire	  cs_n = CSB;
   // Chip Select (Active Low)
   wire	  mosi = cs_n ? 1'bz : SI;
   // Master Out Slave In
   
   reg	  miso;
   
   assign      SO = miso;
   // Master In Slave Out
   
   // Parameters
   parameter MEM_SIZE = 256*1024;
   // 256 bytes for demo
   parameter MEMORY_FILE = "memory.txt";
   // Memory pre-load
   
   // Internal memory
   reg [7:0]	   memory [0:MEM_SIZE-1];
   
   // SPI state machine
   parameter	   IDLE = 0;
   parameter	   CMD = 1;
   parameter	   ADDR = 2;
   parameter	   READ = 3;
   
   reg [1:0]	   state;
   
   // SPI shift register
   reg [7:0]	   shift_reg;
   reg [31:0]	   bit_cnt;
   reg [23:0]	   addr;
   reg [7:0]	   data_out;
   reg [7:0]	   data_latch;
   reg [7:0]	   cmd;
   
   // Load memory from file
   initial begin
      $readmemh(MEMORY_FILE, memory);
   end
   
   wire [7:0] nshift_reg = {shift_reg[6:0], mosi};

   wire [7:0] ndata_out = 
	      (state == ADDR) ? memory[{addr[15:0], nshift_reg}] :
	      ((state == READ) && (bit_cnt == 7)) ? memory[addr + 1] :
	      data_out;
   
   always @(posedge clk or posedge cs_n) begin
      if (cs_n) begin
	 state <= IDLE;
	 bit_cnt <= 0;
	 addr <= 0;
      end else begin
	 shift_reg <= nshift_reg;
	 bit_cnt <= bit_cnt + 1;
	 
	 case (state)
	   IDLE: begin
	      state <= CMD;
//	      bit_cnt <= 3'd0;
	   end
	   
	   CMD: begin
	      if (bit_cnt == 7) begin
		 cmd <= nshift_reg;
		 if (nshift_reg == 7'h03) begin // Read command
		    state <= ADDR;
		 end else begin
		    state <= IDLE;
		    // Unsupported command
		 end
		 bit_cnt <= 0;
	      end // if (bit_cnt == 3'd7)
	   end // case: CMD
	   
	   ADDR: begin
	      if (bit_cnt == 23) begin
		 addr <= {addr[15:0], nshift_reg};
		 state <= READ;
		 data_out <= ndata_out;
		 data_latch <= ndata_out;
		 miso <= ndata_out[7];
		 bit_cnt <= 0;
	      end // if (bit_cnt == 3'd7)
	   end // case: ADDR
	   
	   READ: begin
	      if (bit_cnt == 7) begin
		 addr <= addr + 1;
		 data_out <= ndata_out;
		 data_latch <= ndata_out;
		 miso <= ndata_out[7];
		 bit_cnt <= 0;
	      end
	      else begin
		 miso <= data_out[6];
		 data_out <= {data_out[6:0], 1'b0};
	      end
	      
	   end // case: READ
	 endcase // case (state)
      end // else: !if(cs_n)
   end // always @ (negedge clk or posedge cs_n)
endmodule // spi_flash_model
