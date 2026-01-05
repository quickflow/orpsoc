
module uart_mon
  (
   input wire	    clk, // System clock
   input wire	    reset, // Reset signal
   input wire	    rx, // UART receive line
   input [7:0]      monID
   );
   
   reg [7:0]	    data;   // Received ASCII data
   reg		    data_ready;    // Data ready flag
   
   parameter	    BAUD_TICKS = 868;
   // Adjust for your clock frequency and baud rate
   parameter	    IDLE = 0, START = 1, DATA = 2, STOP = 3;
   
   
   reg [3:0]	    bit_count;
   // Bit counter
   reg [13:0]	    baud_counter;
   // Baud rate counter
   reg [7:0]	    shift_reg;
   // Shift register for received data
   reg [1:0]	    state;
   // State machine
   
   integer 	    fd;
   integer	    fcount;
   
   reg 		    file_opened;
 	    
   initial begin
      fcount = 0;
   end

   always @(posedge clk or posedge reset) begin
      if (reset) begin
	 state <= IDLE;
	 baud_counter <= 0;
	 bit_count <= 0;
	 shift_reg <= 0;
	 data_ready <= 0;
	 file_opened <= 0;
      end else begin // if (reset)
	 if (!file_opened) begin
	    if (monID == 0) begin
	       fd = $fopen("uart0.txt", "w");
	       $display("%m:: executed uart0.txt fopen");
	    end
	    else if (monID == 1) begin
	       fd = $fopen("uart1.txt", "w");
	       $display("%m:: executed uart1.txt fopen");
	    end
	    else if (monID == 2) begin
	       fd = $fopen("uart2.txt", "w");
	       $display("%m:: executed uart2.txt fopen");
	    end
	    else if (monID == 3) begin
	       fd = $fopen("uart3.txt", "w");
	       $display("%m:: executed uart3.txt fopen");
	    end
	    file_opened <= 1;
	 end
	 
	 case (state)
	   IDLE: begin
	      data_ready <= 0;
	      if (rx == 0) begin // Start bit detected
		 state <= START;
		 baud_counter <= 0;
	      end
	   end
	   START: begin
	      if (baud_counter == (BAUD_TICKS / 2)) begin
		 state <= DATA;
		 baud_counter <= 0;
		 bit_count <= 0;
	      end else begin
		 baud_counter <= baud_counter + 1;
	      end // else: !if(baud_counter == (BAUD_TICKS / 2))
	   end // case: START
	   DATA: begin
	      if (baud_counter == BAUD_TICKS) begin
		 baud_counter <= 0;
		 shift_reg <= {rx, shift_reg[7:1] };
		 // Shift in received bit
		 bit_count <= bit_count + 1;
		 if (bit_count == 7) begin
		    state <= STOP;
		 end
	      end else begin // if (baud_counter == BAUD_TICKS)
		 baud_counter <= baud_counter + 1;
	      end // else: !if(baud_counter == BAUD_TICKS)
	   end // case: DATA
	   STOP: begin
	      if (baud_counter == BAUD_TICKS) begin
		 state <= IDLE;
		 data <= shift_reg;
		 // Store received data
		 data_ready <= 1;
		 $fwrite(fd, "%s", shift_reg);
		 fcount = fcount + 1;
		 if ((fcount & 32'hf) == 32'hf)
		   $fflush(fd);
		 
		 // Indicate data is ready
	      end else begin
		 baud_counter <= baud_counter + 1;
	      end // else: !if(baud_counter == BAUD_TICKS)
	   end // case: STOP
	 endcase // case (state)
      end // else: !if(reset)
   end // always @ (posedge clk or posedge reset)
endmodule // uart_receiver
