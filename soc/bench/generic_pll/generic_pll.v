//generic clock generation "PLL" -- DEFINITELY NOT SYNTHESISABLE
//All outputs are synchronous with clk_in
//Divide for clkdiv output set by divider parameter
//Locked signal goes high 8 clocks after reset
//Note the timescale ^^^^^ - cannot be changed!
//19/5/08 - Julius Baxter

`timescale  1 ps / 1 ps

module generic_pll(/*AUTOARG*/
   // Outputs
   clk1x, clk2x, clkdiv, locked,
   // Inputs
   clk_in, rst_in
   );

   input clk_in;
   input rst_in;   
   output reg clk1x;
   output reg clk2x;
   output reg clkdiv;
   output reg locked;

   parameter  DIVIDER = 8;
   
   

   // Locked shiftreg will hold locked low until 8 cycles after reset
   reg [7:0] 	  locked_shiftreg;
   always @(posedge clk_in or negedge rst_in) 
     begin
	if (rst_in) locked_shiftreg <= 8'h0;
	else locked_shiftreg <= {1'b1, locked_shiftreg[7:1]};
     end

   always @(posedge clk_in or posedge rst_in)
     begin
	if (rst_in) locked <= 1'b0;
	else
	  locked <= locked_shiftreg[0];

     end
   
   time   clk_in_edge; //variable to store the times at which we get our edges
   time   clk_in_period [3:0]; // array to store 4 calculated periods
   time   period; //period value used to generate output clocks
   
   // determine clock period
   always @(posedge clk_in or posedge rst_in)
     begin
	if (rst_in == 1) begin
	   clk_in_period[0] <= 0;
	   clk_in_period[1] <= 0;
	   clk_in_period[2] <= 0;
	   clk_in_period[3] <= 0;
	   clk_in_edge <= 0;
	end
	else begin
	   clk_in_edge <= $time;
	   clk_in_period[3] <= clk_in_period[2];
	   clk_in_period[2] <= clk_in_period[1];
	   clk_in_period[1] <= clk_in_period[0];
	   if (clk_in_edge != 0)
	     clk_in_period[0] <= $time - clk_in_edge;
	end // else: !if(rst_in == 1)
     end // always @ (posedge clk_in or posedge rst_in)

   // Calculate average of our clk_in period
   always @(clk_in_period[3] or clk_in_period[2] or 
	    clk_in_period[1] or clk_in_period[0]) begin
      period <= ((clk_in_period[3] + clk_in_period[2] +
		  clk_in_period[1] + clk_in_period[0])/4);
   end

   // generate clk1x out
   always @(posedge clk_in or posedge rst_in)
     if (rst_in)
       clk1x <= 0;
     else begin
	if (clk_in == 1 && locked_shiftreg[0]) begin
	   clk1x <= 1;
	   #(period / 2) clk1x <= 0;
	end
	else
	  clk1x <= 0;
     end
 // generate clk2x out
   always @(posedge clk_in or posedge rst_in)
     if (rst_in)
       clk2x <= 0;
     else begin
	if (clk_in == 1 && locked_shiftreg[0]) begin
	   clk2x <= 1;
	   #(period / 4) clk2x <= 0;
	   #(period / 4) clk2x <= 1;
	   #(period / 4) clk2x <= 0;	   
	end
	else
	  clk2x <= 0;
     end

   //generate clkdiv out
   always @(posedge clk_in or posedge rst_in)
     if (rst_in) 
	clkdiv <= 1'b0;
     else begin
	if (clk_in == 1 && locked_shiftreg[0]) begin
	   clkdiv <= 1'b1;
	   #(DIVIDER*period/2) clkdiv <= 1'b0;
	   #(DIVIDER*period/2);	   
	end
     end	  
   
endmodule // generic_pll


