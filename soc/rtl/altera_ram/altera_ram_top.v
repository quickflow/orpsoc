//===============================================================================
//
//          FILE:  altera_ram_top.v
// 
//         USAGE:  ./altera_ram_top.v 
// 
//   DESCRIPTION:  Wishbone bridge for Altera RAM core
// 
//       OPTIONS:  ---
//  REQUIREMENTS:  ---
//          BUGS:  ---
//         NOTES:  ---
//        AUTHOR:  Xianfeng Zeng (ZXF), xianfeng.zeng@gmail.com
//                                      xianfeng.zeng@SierraAtlantic.com
//       COMPANY:  
//       VERSION:  1.0
//       CREATED:  10/10/2009 06:15:19 PM HKT
//      REVISION:  ---
//===============================================================================

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on


module altera_ram_top (
  wb_clk_i, wb_rst_i,

  wb_dat_i, wb_dat_o, wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i,
  wb_stb_i, wb_ack_o, wb_err_o

);

//
// Paraneters
//
parameter	Idle  = 12'b100000000000,
		Read0 = 12'b010000000000,
		Read1 = 12'b001000000000,
		Read2 = 12'b000100000000,
		Read3 = 12'b000010000000,
		Write0= 12'b000001000000,
		Write1= 12'b000000100000,
		Write2= 12'b000000010000,
		Write3= 12'b000000001000,
		Ack   = 12'b000000000100,
		Read_done  = 12'b000000000010,
		Write_done =  12'b000000000001;			

//
// I/O Ports
//
input			wb_clk_i;
input			wb_rst_i;

//
// WB slave i/f
//
input	[31:0]		wb_dat_i;
output	[31:0]		wb_dat_o;
input	[31:0]		wb_adr_i;
input	[3:0]		wb_sel_i;
input			wb_we_i;
input			wb_cyc_i;
input			wb_stb_i;
output			wb_ack_o;
output			wb_err_o;


//
// Internal regs and wires
//
reg		ack_we;
reg		wren;
reg [31:0]	adr;
reg [31:0]	cur_adr;
reg [31:0]	data_save;
reg [3:0]       sel;

wire 		wb_err;

reg		clk;
integer		i;
wire [7:0]	data_q;
reg  [7:0]	data;

reg [11:0]	State;

wire		bit_shift;

//
// Aliases and simple assignments
//
assign wb_err = wb_cyc_i & wb_stb_i & (|wb_adr_i[20:14]);	// If Access to > 16KB (4-bit leading prefix ignored)
assign wb_err_o = wb_err;

//
// Use State Machine to 32->8 or 8->32
//
always @ (negedge wb_clk_i or posedge wb_rst_i)
begin
	if (wb_rst_i) begin
		State <= Idle;
		wren <= 1'b0;
	end
	else
		case (State)
			Idle: begin
				if (wb_cyc_i & wb_stb_i) begin
					adr <= {5'b0000,wb_adr_i[26:2],2'b00};
					cur_adr <= {5'b0000,wb_adr_i[26:2],2'b00};
					sel <= wb_sel_i;
					if (wb_we_i) begin
						data_save <= wb_dat_i; 
						State <= Write0;
					    end
					else
						State <= Read0;
				end
				wren <= 1'b0;
			end
			Read0: begin
				State <= Read1;
				cur_adr <= adr + 1;
//				data_save[31:24] <= data_q;
			end
			Read1: begin
				State <= Read2;
				cur_adr <= adr + 2;
				data_save[31:24] <= data_q;
			end
			Read2: begin
				State <= Read3;
				cur_adr <= adr + 3;
				data_save[23:16] <= data_q;
			end
			Read3: begin
				State <= Read_done;
				data_save[15:8] <= data_q;
			end
			Read_done: begin
			     data_save[7:0] <= data_q;
				State <= Ack;
			end
			Ack: begin
				State <= Idle;
				wren <= 1'b0;
			end
			Write0: begin
				if (sel[3]) begin
					data <= data_save[31:24];
					wren <= 1'b1;
				end else
					wren <= 1'b0;
				cur_adr <= adr;
				State <= Write1;
			end
			Write1: begin
				if (sel[2]) begin
					data <= data_save[23:16];
					wren <= 1'b1;
				end else
					wren <= 1'b0;
				cur_adr <= adr + 1;
				State <= Write2;
			end
			Write2: begin
				if (sel[1]) begin
					data <= data_save[15:8];
					wren <= 1'b1;
				end else
					wren <= 1'b0;
				cur_adr <= adr + 2;
				State <= Write3;
			end
			Write3: begin
				if (sel[0]) begin
					data <= data_save[7:0];
					wren <= 1'b1;
				end else
					wren <= 1'b0;
				cur_adr <= adr + 3;
				State <= Ack;
			end
			default: State <= Idle;
		endcase
end

assign wb_dat_o = data_save;
assign wb_ack_o = (State == Ack) ? 1'b1 : 1'b0;

//
// Connect to altera 1-port RAM
//
altera_ram	altera_ram_inst (
	.address	( cur_adr[13:0] ),
	.clock		( wb_clk_i ),
	.data		( data ),
	.wren		( wren ),
	.q		( data_q )
	);

//
// SRAM i/f monitor
//
// synopsys translate_off
integer fsram;
initial begin
	fsram = $fopen("sram.log");
end
always @(posedge wb_clk_i)
        if (wb_cyc_i)
                if (State == Ack)
			if (wb_we_i)
                        	$fdisplay(fsram, "%t [%h] <- write %h, byte sel %b", $time, wb_adr_i, wb_dat_i, wb_sel_i);
                	else
                        	$fdisplay(fsram, "%t [%h] -> read %h, byte sel %b", $time, wb_adr_i, wb_dat_o, wb_sel_i);
// synopsys translate_on

endmodule


