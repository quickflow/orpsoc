module AT26DFxxx
  (
   input  CSB,
   input  SCK,
   input  SI,
   input  WPB,
   output SO
   );
   
   
   wire	  sclk = SCK;
   // SPI Clock (SCK)
   wire	  cs_n = CSB;
   // Chip Select (Active Low)
   wire	  mosi = cs_n ? 1'bz : SI;
   // Master Out Slave In
   
   reg	  miso;
   
   assign      SO = cs_n ? 1'bz : miso;

    // Flash memory array
    reg [7:0] mem [0:65535];  // 64KB flash
    reg [23:0] addr;
    reg [7:0]  cmd;
    reg [31:0]  shift_in;
    reg [7:0]  shift_out;
    reg [7:0]  bit_cnt;
    reg        write_enable;
    reg        reading;
    reg        writing;
    reg [15:0] wr_ptr;

    // SPI state machine
   parameter   IDLE = 3'b000;
   parameter   CMD = 3'b001;
   parameter   ADDR = 3'b010;
   parameter   READ = 3'b011;
   parameter   WRITE = 3'b100;

   reg [2:0]   state;

   parameter   MEMORY_FILE = "memory.txt";	// Memory pre-load

   initial begin
      $readmemh (MEMORY_FILE, mem);
   end
   

    always @(negedge cs_n) begin
        state <= CMD;
        bit_cnt <= 0;
        write_enable <= 0;
        reading <= 0;
        writing <= 0;
    end

    always @(posedge sclk) begin
        if (!cs_n) begin
            shift_in <= {shift_in[6:0], mosi};
            bit_cnt <= bit_cnt + 1;

            case (state)
                CMD: if (bit_cnt == 7) begin
                    cmd <= {shift_in[6:0], mosi};
                    bit_cnt <= 0;
                    state <= ADDR;
		   $display("[%m] new CMD(%h) received", {shift_in[6:0], mosi});
                end

                ADDR: if (bit_cnt == 23) begin
                    addr <= {shift_in[22:0], mosi};
                    bit_cnt <= 0;
                    case (cmd)
                        8'h03: begin  // READ
//                            shift_out <= mem[addr];
                            shift_out <= mem[{shift_in[22:0], mosi}];
                            reading <= 1;
                            state <= READ;
			   $display("[%m] Opcode(%h) for Read Array received",cmd);
                        end
                        8'h02: begin  // WRITE
                            if (write_enable) begin
                                writing <= 1;
                                state <= WRITE;
				$display("[%m] Opcode(%h) Byte Program received",cmd);
                            end else begin
                                state <= IDLE;
                            end
                        end
                        8'h06: begin  // WREN
                            write_enable <= 1;
                            state <= IDLE;
			   $display("[%m]Opcode(%h) for Write Enable received",cmd);
                        end
                        default: state <= IDLE;
                    endcase
                end

                READ: begin
                    miso <= shift_out[7];
                    shift_out <= {shift_out[6:0], 1'b0};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 7) begin
                        addr <= addr + 1;
                        shift_out <= mem[addr + 1];
                        bit_cnt <= 0;
                    end
                end

                WRITE: begin
                    if (bit_cnt == 7) begin
                        mem[addr] <= {shift_in[6:0], mosi};
                        addr <= addr + 1;
                        bit_cnt <= 0;
                    end
                end
            endcase
        end
    end

endmodule

