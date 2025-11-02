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
   parameter MEM_SIZE = 256;
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
   reg [2:0]	   bit_cnt;
   reg [23:0]	   addr;
   reg [7:0]	   data_out;
   reg [7:0]	   data_latch;
   
   // Load memory from file
   initial begin
      $readmemh(MEMORY_FILE, memory);
   end
   
   always @(negedge clk or posedge cs_n) begin
      if (cs_n) begin
	 state <= IDLE;
	 bit_cnt <= 3'd0;
      end else begin
	 shift_reg <= {shift_reg[6:0], mosi};
	 bit_cnt <= bit_cnt + 1;
	 
	 case (state)
	   IDLE: begin
	      state <= CMD;
	      bit_cnt <= 3'd0;
	   end
	   
	   CMD: begin
	      if (bit_cnt == 3'd7) begin
		 if (shift_reg[6:0] == 7'h03) begin // Read command
		    state <= ADDR;
		 end else begin
		    state <= IDLE;
		    // Unsupported command
		 end
		 bit_cnt <= 3'd0;
	      end // if (bit_cnt == 3'd7)
	   end // case: CMD
	   
	   ADDR: begin
	      if (bit_cnt == 3'd7) begin
		 addr <= {addr[15:0], shift_reg};
		 if (&addr[23:16]) begin
		    state <= READ;
		    data_out <= memory[addr];
		    data_latch <= memory[addr];
		 end
		 bit_cnt <= 3'd0;
	      end // if (bit_cnt == 3'd7)
	   end // case: ADDR
	   
	   READ: begin
	      miso <= data_out[7];
	      data_out <= {data_out[6:0], 1'b0};
	      if (bit_cnt == 3'd7) begin
		 addr <= addr + 1;
		 data_out <= memory[addr + 1];
		 data_latch <= memory[addr + 1];
		 bit_cnt <= 3'd0;
	      end
	   end // case: READ
	 endcase // case (state)
      end // else: !if(cs_n)
   end // always @ (negedge clk or posedge cs_n)
endmodule // spi_flash_model
