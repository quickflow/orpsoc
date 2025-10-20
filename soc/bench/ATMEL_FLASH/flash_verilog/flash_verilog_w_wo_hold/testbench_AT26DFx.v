//--------------------------------------------------------------------------
// This is the property of PERFTRENDS TECHNOLOGIES PRIVATE LIMITED and
// possession or use of file has to be with the written LICENCE AGGREMENT
// from PERFTRENDS TECHNOLOGIES PRIVATE LIMITED.
//
//--------------------------------------------------------------------------
//
// Project : ATMEL Data Flash Device
//--------------------------------------------------------------------------
// File 	: $RCSfile: testbench_AT26DFx.v,v $
// Path 	: $Source: /home/cvs/atmel_flash_dev/design_26x/testbench_AT26DFx.v,v $
// Author 	: $ Devi Vasumathy N $
// Created on 	: $ 26-03-07 $
// Revision 	: $Revision: 1.5 $
// Last modified by : $Author: devivasumathy $
// Last modified on : $Date: 2007/04/16 06:24:44 $
//--------------------------------------------------------------------------
// Module 		: AT26DFxxx.v
// Description 		: testbench for devices AT26F004, AT26DF081A, 
//			  AT26DF161A, AT26DF321
//
//--------------------------------------------------------------------------
//
// Design hierarchy : _top.v/top_1.v/top_2.v/...
// Instantiated Modules : top_1.v, top_2.v
//--------------------------------------------------------------------------
// Revision history :
// $Log: testbench_AT26DFx.v,v $
// Revision 1.5  2007/04/16 06:24:44  devivasumathy
// *** empty log message ***
//
// Revision 1.4  2007/04/10 09:37:36  devivasumathy
// *** empty log message ***
//
// Revision 1.3  2007/04/09 12:06:09  devivasumathy
// *** empty log message ***
//
// Revision 1.2  2007/04/05 14:45:12  devivasumathy
// *** empty log message ***
//
// Revision 1.1  2007/04/05 11:32:55  devivasumathy
// AT26DFx data flash model testbench
//
//--------------------------------------------------------------------------

// module declarations
module AT26DFx_testbench(
			clk,
			HOLDB,
			SO_data,
			tr_read_stat,
			tr_write_stat,
			tr_wr_en,
			tr_wr_dis,
			tr_man,
			tr_pwr_dwn,
			tr_res_pwr_dwn,
			tr_byt_prog,
			tr_rd_array,
			tr_rd_array_l,
			tr_seq_byt,
			tr_protect,
			tr_unprotect,
			tr_rd_protect,
			tr_be4,
			tr_be32,
			tr_be64,
			tr_ce,
			data_num,
			no_addr,
			m_address,
			w_data,
			serial_in,
			out_data);

// input declarations
input clk;		// Clock input
input HOLDB;		// Hold
input SO_data;		// SO from BFM
input tr_read_stat;	// trigger for read status reg
input tr_write_stat;	// trigger for write status reg
input tr_wr_en;		// trigger for Write Enable
input tr_wr_dis;	// trigger for Write Disable
input tr_man;		// trigger for read Manufacturer ID
input tr_pwr_dwn;	// trigger for Deep Power-Down
input tr_res_pwr_dwn;	// trigger for resume from Deep Power-Down
input tr_byt_prog;	// trigger for Byte programming
input tr_rd_array;	// trigger for Read array
input tr_rd_array_l;	// trigger for Read array in low frequeny
input tr_seq_byt;	// trigger for Sequential programming
input tr_protect;	// trigger for Protect sector
input tr_unprotect;	// trigger for Unprotect sector
input tr_rd_protect;	// trigger for read protection register
input tr_be4;		// trigger for 4KB Block erase
input tr_be32;		// trigger for 32KB Block erase
input tr_be64;		// trigger for 64KB Block erase
input tr_ce;		// trigger for Chip erase
input [8:0] data_num;	// no. of data to be transmitted/read
input no_addr;		// No address for consecutive sequential programming
input [23:0] m_address; // address for protect/unprotect/read arrays/programming/erase
input [7:0] w_data;	// write data for Byte programming / Sequential programming

// output declarations
output serial_in;	// SI for BFM
output [7:0] out_data;	// data from read array to top

// Output-reg declarations
reg [7:0] out_data;
reg serial_in;

// parameters for SI related delay
parameter tDS     = 2 ;		// Data in Setup time
parameter tDH     = 3 ;		// Data in Hold time

// opcode registers
reg [7:0] read_status;		// opcode for read status reg
reg [7:0] wite_status;		// opcode for write status reg
reg [7:0] write_enable;		// opcode for Write Enable
reg [7:0] write_disable;	// opcode for Write Disable
reg [7:0] manufacturer;		// opcode for Manufacturer ID
reg [7:0] deep_power_down;	// opcode for Deep Power-Down
reg [7:0] res_deep_power;	// opcode for resume from Deep Power-Down
reg [7:0] byte_program;		// opcode for Byte programming
reg [7:0] read_array;		// opcode for Read array
reg [7:0] read_array_l;		// opcode for Read array in low frequeny
reg [7:0] seq_program;		// opcode for Sequential programming
reg [7:0] protect;		// opcode for Protect sector
reg [7:0] unprotect;		// opcode for Unprotect sector
reg [7:0] read_protect;		// opcode for read protection register
reg [7:0] erase_4;		// opcode for 4KB Block erase
reg [7:0] erase_32;		// opcode for 32KB Block erase
reg [7:0] erase_64;		// opcode for 64KB Block erase
reg [7:0] chip_erase;		// opcode for Chip erase
integer i,j;
reg [7:0] x_val;		// dont care values for Read array in low frequeny

// events for all the opcodes
event read_stat;
event wr_en;
event wr_dis;
event manufact;
event pwr_dwn;
event res_pwr_dwn;
event byt_prog;
event rd_array;
event rd_array_l;
event seq_byte;
event protect_sector;
event unprotect_sector;
event read_sector;
event write_stat;
event erase4;
event erase32;
event erase64;
event erase_chip;

initial
begin
	serial_in	= 1'b1;
	x_val		= 8'bx;
	read_status	= 8'h05;
	write_enable	= 8'h06;
	write_disable	= 8'h04;
	manufacturer	= 8'h9F;
	deep_power_down = 8'hB9;
	res_deep_power	= 8'hAB;
	byte_program	= 8'h02;
	read_array	= 8'h0B;
	read_array_l	= 8'h03;
	seq_program	= 8'hAF;
	protect		= 8'h36;
	unprotect	= 8'h39;
	read_protect	= 8'h3C;
	wite_status	= 8'h01;
	erase_4		= 8'h20;
	erase_32	= 8'h52;
	erase_64	= 8'hD8;
	chip_erase	= 8'hC7;

	out_data	= 8'b0;

end

// trigger particular opcode,address and data sending event
always @(tr_read_stat or tr_write_stat or tr_wr_en or tr_wr_dis or 
	tr_man or tr_pwr_dwn or tr_res_pwr_dwn or 
	tr_byt_prog or tr_seq_byt or 
	tr_rd_array or tr_rd_array_l or 
	tr_protect or tr_unprotect or tr_rd_protect or 
	tr_be4 or tr_be32 or tr_be64 or tr_ce)
begin
	if(tr_byt_prog==1'b1)
		-> byt_prog;
	else if(tr_seq_byt==1'b1)
		-> seq_byte;
	else if(tr_protect==1'b1)
		-> protect_sector;
	else if(tr_unprotect==1'b1)
		-> unprotect_sector;
	else if(tr_rd_protect==1'b1)
		-> read_sector;
	else if(tr_rd_array==1'b1)
		-> rd_array;
	else if(tr_rd_array_l==1'b1)
		-> rd_array_l;
	else if(tr_read_stat==1'b1)
		-> read_stat;
	else if(tr_write_stat==1'b1)
		-> write_stat;
	else if(tr_wr_en==1'b1)
		-> wr_en;
	else if(tr_wr_dis==1'b1)
		-> wr_dis;
	else if(tr_man==1'b1)
		-> manufact;
	else if(tr_pwr_dwn==1'b1)
		-> pwr_dwn;
	else if(tr_res_pwr_dwn==1'b1)
		-> res_pwr_dwn;
	else if(tr_be4==1'b1)
		-> erase4;
	else if(tr_be32==1'b1)
		-> erase32;
	else if(tr_be64==1'b1)
		-> erase64;
	else if(tr_ce==1'b1)
		-> erase_chip;
end

always @(read_stat)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = read_status[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(wr_en)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = write_enable[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(wr_dis)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = write_disable[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(manufact)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = manufacturer[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(pwr_dwn)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = deep_power_down[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(res_pwr_dwn)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = res_deep_power[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(byt_prog)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = byte_program[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	for (i=23; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = m_address[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	for(j=0; j<data_num; j=j+1)
	begin
		for (i=7; i >= 0; i=i-1)
		begin
			@ (negedge clk);
			#tDS;
			serial_in = w_data[i];
			@ (posedge clk);
			#tDH;
			serial_in = 1'bx;
			if(HOLDB==1'b0)
				wait (HOLDB);
		end
	end
	j=0;
	serial_in = 1'bz;
end

always @(rd_array)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = read_array[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	for (i=23; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = m_address[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait(HOLDB);
	end
	for (i=7; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = x_val[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
	for(j=0; j<data_num; j=j+1)// to receive data from model
	begin
		for (i=8; i > 0; i=i-1)
		begin
			@ (posedge clk);
			out_data[i-1] = SO_data;
		end
	end
	j=0;
end

always @(rd_array_l)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = read_array_l[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	for (i=23; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = m_address[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
	for(j=0; j<data_num; j=j+1)// to receive data from model
	begin
		for (i=8; i > 0; i=i-1)
		begin
			@ (posedge clk);
			out_data[i-1] = SO_data;
		end
	end
	j=0;
end

always @(seq_byte)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = seq_program[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	if(no_addr==1'b0)
	    for (i=23; i >= 0; i=i-1)
	    begin
		@ (negedge clk);
		#tDS;
		serial_in = m_address[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	    end
	for (i=7; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = w_data[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(protect_sector)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = protect[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	for (i=23; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = m_address[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(unprotect_sector)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = unprotect[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	for (i=23; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = m_address[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(read_sector)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = read_protect[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	for (i=23; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = m_address[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(write_stat)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = wite_status[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	for (i=7; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = w_data[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(erase4)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = erase_4[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	for (i=23; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = m_address[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(erase32)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = erase_32[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	for (i=23; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = m_address[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(erase64)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = erase_64[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	for (i=23; i >= 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = m_address[i];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

always @(erase_chip)
begin
	for (i=8; i > 0; i=i-1)
	begin
		@ (negedge clk);
		#tDS;
		serial_in = chip_erase[i-1];
		@ (posedge clk);
		#tDH;
		serial_in = 1'bx;
		if(HOLDB==1'b0)
			wait (HOLDB);
	end
	serial_in = 1'bz;
end

endmodule
