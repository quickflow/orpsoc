//===============================================================================
//
//          FILE:  rom_wb.v
// 
//         USAGE:  ./rom_wb.v 
// 
//   DESCRIPTION:  1KB ROM with Withbone interface
// 
//       OPTIONS:  ---
//  REQUIREMENTS:  ---
//          BUGS:  ---
//         NOTES:  ---
//        AUTHOR:  Xianfeng Zeng (ZXF), xianfeng.zeng@gmail.com
//       COMPANY:  
//       VERSION:  1.0
//       CREATED:  04/05/2009 11:00:16 AM HKT
//      REVISION:  ---
//===============================================================================

module flash_generic(dout, clk, addr);

   parameter 	flash_addr_width = 7;
   parameter 	flash_data_width = 8;
   parameter 	flash_data_words = 128;
   
   input	clk;
   input 	[flash_addr_width-1:0]	addr;
   output 	[flash_data_width-1:0]	dout;
   
   reg 		[flash_data_width-1:0]	memory_array [0:flash_data_words-1];
   
   parameter	MEMORYFILE = "";

   initial
     begin
	if ( MEMORYFILE != "" )
          $readmemh ( MEMORYFILE, memory_array );
	else
          begin
             $display ( "***Boot ROM image file not specified for %m - defaulting to standard OR1200 boot ROM");
	     memory_array[0] = 8'b00000000;
	     memory_array[1] = 8'b00000000;
	     memory_array[2] = 8'b00000000;
	     memory_array[3] = 8'b00011000;
	     memory_array[4] = 8'b00000000;
	     memory_array[5] = 8'b00000000;
	     memory_array[6] = 8'b00100000;
	     memory_array[7] = 8'b10101000;
	     memory_array[8] = 8'b00000000;
	     memory_array[9] = 8'b10110000;
	     memory_array[10] = 8'b10000000;
	     memory_array[11] = 8'b00011000;
	     memory_array[12] = 8'b00100000;
	     memory_array[13] = 8'b00000101;
	     memory_array[14] = 8'b10100000;
	     memory_array[15] = 8'b10101000;
	     memory_array[16] = 8'b00000001;
	     memory_array[17] = 8'b00000000;
	     memory_array[18] = 8'b01100000;
	     memory_array[19] = 8'b10101000;
	     memory_array[20] = 8'b00010100;
	     memory_array[21] = 8'b00000000;
	     memory_array[22] = 8'b00000000;
	     memory_array[23] = 8'b00000100;
	     memory_array[24] = 8'b00011000;
	     memory_array[25] = 8'b00011000;
	     memory_array[26] = 8'b00000100;
	     memory_array[27] = 8'b11010100;
	     memory_array[28] = 8'b00010010;
	     memory_array[29] = 8'b00000000;
	     memory_array[30] = 8'b00000000;
	     memory_array[31] = 8'b00000100;
	     memory_array[32] = 8'b00000000;
	     memory_array[33] = 8'b00000000;
	     memory_array[34] = 8'b00000100;
	     memory_array[35] = 8'b11010100;
	     memory_array[36] = 8'b00000100;
	     memory_array[37] = 8'b00011000;
	     memory_array[38] = 8'b01000011;
	     memory_array[39] = 8'b11100000;
	     memory_array[40] = 8'b00001111;
	     memory_array[41] = 8'b00000000;
	     memory_array[42] = 8'b00000000;
	     memory_array[43] = 8'b00000100;
	     memory_array[44] = 8'b00001000;
	     memory_array[45] = 8'b00000000;
	     memory_array[46] = 8'b00100001;
	     memory_array[47] = 8'b10011100;
	     memory_array[48] = 8'b00001101;
	     memory_array[49] = 8'b00000000;
	     memory_array[50] = 8'b00000000;
	     memory_array[51] = 8'b00000100;
	     memory_array[52] = 8'b00000100;
	     memory_array[53] = 8'b00011000;
	     memory_array[54] = 8'b00000011;
	     memory_array[55] = 8'b11100001;
	     memory_array[56] = 8'b00000000;
	     memory_array[57] = 8'b00000000;
	     memory_array[58] = 8'b00001000;
	     memory_array[59] = 8'b11100100;
	     memory_array[60] = 8'b11111011;
	     memory_array[61] = 8'b11111111;
	     memory_array[62] = 8'b11111111;
	     memory_array[63] = 8'b00001111;
	     memory_array[64] = 8'b00000000;
	     memory_array[65] = 8'b00011000;
	     memory_array[66] = 8'b00001000;
	     memory_array[67] = 8'b11010100;
	     memory_array[68] = 8'b00001000;
	     memory_array[69] = 8'b00000000;
	     memory_array[70] = 8'b00000000;
	     memory_array[71] = 8'b00000100;
	     memory_array[72] = 8'b00000100;
	     memory_array[73] = 8'b00000000;
	     memory_array[74] = 8'b00100001;
	     memory_array[75] = 8'b10011100;
	     memory_array[76] = 8'b00000000;
	     memory_array[77] = 8'b00011000;
	     memory_array[78] = 8'b00000001;
	     memory_array[79] = 8'b11010100;
	     memory_array[80] = 8'b00000000;
	     memory_array[81] = 8'b00010000;
	     memory_array[82] = 8'b00000001;
	     memory_array[83] = 8'b11100100;
	     memory_array[84] = 8'b11111100;
	     memory_array[85] = 8'b11111111;
	     memory_array[86] = 8'b11111111;
	     memory_array[87] = 8'b00001111;
	     memory_array[88] = 8'b00000000;
	     memory_array[89] = 8'b00000001;
	     memory_array[90] = 8'b11000000;
	     memory_array[91] = 8'b10101000;
	     memory_array[92] = 8'b00000000;
	     memory_array[93] = 8'b00110000;
	     memory_array[94] = 8'b00000000;
	     memory_array[95] = 8'b01000100;
	     memory_array[96] = 8'b00011000;
	     memory_array[97] = 8'b00000000;
	     memory_array[98] = 8'b00000100;
	     memory_array[99] = 8'b11010100;
	     memory_array[100] = 8'b00010000;
	     memory_array[101] = 8'b00101000;
	     memory_array[102] = 8'b00000100;
	     memory_array[103] = 8'b11010100;
	     memory_array[104] = 8'b00010000;
	     memory_array[105] = 8'b00000000;
	     memory_array[106] = 8'b01100100;
	     memory_array[107] = 8'b10000100;
	     memory_array[108] = 8'b00100000;
	     memory_array[109] = 8'b00000101;
	     memory_array[110] = 8'b00000011;
	     memory_array[111] = 8'b10111100;
	     memory_array[112] = 8'b11111110;
	     memory_array[113] = 8'b11111111;
	     memory_array[114] = 8'b11111111;
	     memory_array[115] = 8'b00010011;
	     memory_array[116] = 8'b00000000;
	     memory_array[117] = 8'b00000000;
	     memory_array[118] = 8'b00000000;
	     memory_array[119] = 8'b00010101;
	     memory_array[120] = 8'b00000000;
	     memory_array[121] = 8'b01001000;
	     memory_array[122] = 8'b00000000;
	     memory_array[123] = 8'b01000100;
	     memory_array[124] = 8'b00000000;
	     memory_array[125] = 8'b00000000;
	     memory_array[126] = 8'b01100100;
	     memory_array[127] = 8'b10000100;
          end

     end // initial begin
   

   reg [flash_addr_width-1:0] addr_int;

   always @(posedge clk)
     addr_int <= addr;

   assign 		      dout = memory_array[addr_int];
   
endmodule // flash_generic


module rom_wb (
	wb_adr_i, wb_cyc_i, wb_stb_i, wb_dat_o, wb_ack_o, flash_clk, clk, rst );

input  [4:0]  wb_adr_i;
input         wb_cyc_i;
input         wb_stb_i;
output [31:0] wb_dat_o;
reg    [31:0] wb_dat_o;
output        wb_ack_o;
reg           wb_ack_o;
input         flash_clk;
input         clk;
input         rst;

reg [3:0]     counter;
wire [7:0]    do;

parameter [31:0] NOP = 32'h15000000;

always @ (posedge rst or posedge clk)
if (rst)
	counter <= 4'd0;
else
	if (wb_cyc_i & wb_stb_i & !wb_ack_o)
		counter <= counter + 4'd1;

always @ (posedge rst or posedge clk)
if (rst)
	wb_ack_o <= 1'b0;
else
	wb_ack_o <= (counter == 4'd15);

always @ (posedge rst or posedge clk)
if (rst)
	wb_dat_o <= NOP;
else
	case (counter)	
	4'd15: wb_dat_o[31:24] <= do;
	4'd11: wb_dat_o[23:16] <= do;
	4'd7: wb_dat_o[15: 8] <= do;
	4'd3: wb_dat_o[ 7: 0] <= do;
	endcase

   // All target memory options exhausted
   // Defaulting to generic technology:
   flash_generic /* These are defaults!: #( .MEMORYFILE("flash.mem"), .flash_addr_width(7),
		    .flash_data_width(8), .flash_data_words(128))*/ 
     flash0 (
	     .clk  (counter[1] ^ counter[0]),
	     .addr ({wb_adr_i,counter[3:2]}),
	     .dout (do));
      
endmodule // rom_wb

