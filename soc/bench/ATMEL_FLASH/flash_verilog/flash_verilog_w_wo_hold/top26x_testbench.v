//--------------------------------------------------------------------------
// This is the property of PERFTRENDS TECHNOLOGIES PRIVATE LIMITED and
// possession or use of file has to be with the written LICENCE AGGREMENT
// from PERFTRENDS TECHNOLOGIES PRIVATE LIMITED.
//
//--------------------------------------------------------------------------
//
// Project : ATMEL Data Flash Device
//--------------------------------------------------------------------------
// File 	: $RCSfile: top26x_testbench.v,v $
// Path 	: $Source: /home/cvs/atmel_flash_dev/design_26x/top26x_testbench.v,v $
// Author 	: $ Devi Vasumathy N $
// Created on 	: $ 27-03-07 $
// Revision 	: $Revision: 1.11 $
// Last modified by : $Author: devivasumathy $
// Last modified on : $Date: 2007/05/10 05:15:51 $
//--------------------------------------------------------------------------
// Module 		: AT26DFxxx.v
// Description 		: testbench top for devices AT26F004, AT26DF081A, 
//			  AT26DF161A, AT26DF321
//
//--------------------------------------------------------------------------
//
// Design hierarchy : _top.v/top_1.v/top_2.v/...
// Instantiated Modules : top_1.v, top_2.v
//--------------------------------------------------------------------------
// Revision history :
// $Log: top26x_testbench.v,v $
// Revision 1.11  2007/05/10 05:15:51  devivasumathy
// Card Memory preload
//
// Revision 1.10  2007/04/27 09:09:40  devivasumathy
// *** empty log message ***
//
// Revision 1.9  2007/04/17 10:50:59  devivasumathy
// Timing verified
//
// Revision 1.8  2007/04/16 06:28:55  devivasumathy
// *** empty log message ***
//
// Revision 1.7  2007/04/16 06:24:44  devivasumathy
// *** empty log message ***
//
// Revision 1.6  2007/04/12 09:43:55  magesh
// *** empty log message ***
//
// Revision 1.5  2007/04/12 05:02:10  devivasumathy
// AT26x
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
`timescale 1 ns / 1 ps

module top26x_testbench();

reg SCK_gen;		// local clock

reg CSB_out;		// CSB signal for BFM
reg WPB_out;		// WPB signal for BFM
reg HOLDB_out;		// HOLDB signal for BFM
wire SCK_out;		// SCK for BFM
wire SO_in;		// SO from BFM
wire SI_out;		// SI for BFM
wire [7:0] out_data;

reg trg_read_stat;	// trigger for read status reg
reg trg_write_stat;	// trigger for write status reg;
reg trg_wr_en;          // trigger for Write Enable
reg trg_wr_dis;         // trigger for Write Disable
reg trg_man;            // trigger for read Manufacturer ID
reg trg_pwr_dwn;        // trigger for Deep Power-Down
reg trg_res_pwr_dwn;	// trigger for resume from Deep Power-Down
reg trg_byt_prog;	// trigger for Byte programming
reg trg_rd_array;	// trigger for Read array
reg trg_rd_array_l;	// trigger for Read array in low frequency
reg trg_seq_byt;        // trigger for Sequential programming
reg trg_protect;	// trigger for Protect sector
reg trg_unprotect;	// trigger for Unprotect sector;
reg trg_rd_protect;	// trigger for read protection register
reg trg_be4;		// trigger for 4KB Block erase
reg trg_be32;		// trigger for 32KB Block erase
reg trg_be64;		// trigger for 64KB Block erase
reg trg_ce;		// trigger for Chip erase
reg [8:0] t_data_num;	// no. of data to be transmitted/read
reg t_no_addr;		// No address for consecutive sequential programming
reg [23:0] address;	// address for protect/unprotect/read arrays/programming/erase
reg [7:0] data;		// write data for Byte programming / Sequential programming

integer i;
integer j;
integer k;
integer delay;			// delay for chip erase
reg [7:0] store_data [63:0];	// write data stored here for data validation check
reg [7:0] read_data [63:0];	// read data stored here for data validation check
reg CSB_start;			// for SPI mode 0; to avoid glitch in SCK
reg CSB_stop;			// for SPI mode 3; to avoid glitch in SCK

`ifdef 041
parameter DEVICE = "AT25DF041A";	// Device selected
`endif
`ifdef 081
parameter DEVICE = "AT26DF081A";
`endif
`ifdef 161
parameter DEVICE = "AT26DF161A";
`endif
`ifdef 321
parameter DEVICE = "AT26DF321";
`endif

`ifdef LOAD
	parameter PRELOAD = 1;			// preload memory with content in MEMORY_FILE
`else
	parameter PRELOAD = 0;			// preload memory with content in MEMORY_FILE
`endif

`ifdef LOAD
	parameter MEMORY_FILE = "memory.txt";	// Memory pre-load
`else
	parameter MEMORY_FILE = 0;		// Memory pre-load
`endif

// ********************************************************************* //
//Timing Parameters :
// ******************************************************************** //
parameter fRDLF   = 33;		// SCK Frequency for read Array (Low freq - 03h opcode)
//representation in ns

parameter tCSH    = 50;		// Chip Select high time
parameter tCSLS   = 5 ;		// Chip Select Low Setup time
parameter tCSLH   = 5 ;		// Chip Select Low hold time
//parameter tCSLH   = 12;	// (for SPI3)		// Chip Select Low hold time
parameter tCSHS   = 5 ;		// Chip Select high Setup time
parameter tCSHH   = 5 ;		// Chip Select high hold time

parameter tDS     = 2 ;		// Data in Setup time
parameter tDH     = 3 ;		// Data in Hold time

parameter tHLS    = 5 ;		// HOLD! Low Setup Time
parameter tHHS    = 5 ;		// HOLD! High Setup Time
parameter tHLH    = 5 ;		// HOLD! Low Hold Time
parameter tHHH    = 5 ;		// HOLD! High Hold Time

parameter tWPS    = 20;		// Write Protect Setup Time (only when SPRL=1)
parameter tWPH    = 100;	// Write Protect Hold Time (only when SPRL=1)

parameter tWRSR   = 200;	// Write Status Register Time

parameter tSECP   = 20;		// Sector Protect Time
parameter tSECUP  = 20;		// Sector Unprotect Time

parameter tEDPD   = 3000;	// Chip Select high to Deep Power-down (3 us)
parameter tRDPD   = 3000;	// Chip Select high to Stand-by Mode
parameter tPP     = 5000000;	// Page Program Time
parameter tBLKE4  = 200000000;	// Block Erase Time 4-kB (0.350 sec)
parameter tBLKE32 = 600000000;	// Block Erase Time 32-kB
parameter tCHPEn = 1000000000;  // local chip erase time

// variable parameters
// ******************************************************************** //
//parameter tBLKE64 = 950000000;	// Block Erase Time 64-kB
//parameter tCHPE   = 3000000000;	// Chip Erase Time. this is actual;
					// due to simulation warning splitted into 2 parameters as tCHPE = tmult * tCHPEn
//parameter tmult   = 3;		// Multiplication factor for chip erase timing

parameter tBP = 	(DEVICE == "AT25DF041A") ? 7000 :
			(DEVICE == "AT26DF081A") ? 7000 :
			(DEVICE == "AT26DF161A") ? 7000 :
			(DEVICE == "AT26DF321")  ? 6000 : 7000;

parameter tBLKE64 = 	(DEVICE == "AT25DF041A") ? 950000000 :
			(DEVICE == "AT26DF081A") ? 950000000 :
			(DEVICE == "AT26DF161A") ? 950000000 :
			(DEVICE == "AT26DF321")  ? 1000000000 :950000000 ;

parameter tmult = 	(DEVICE == "AT25DF041A") ? 3 :
			(DEVICE == "AT26DF081A") ? 6 :
			(DEVICE == "AT26DF161A") ? 12 :
			(DEVICE == "AT26DF321")  ? 36 : 3;

//parameter fSCK    = 70;		// Serial clock (SCK) Frequency in MHz
//parameter tSCKH   = 6.4;		// SCK High time
//parameter tSCKL   = 6.4;		// SCK Low time
parameter tSCKH   = 8.4;		// SCK High time
parameter tSCKL   = 8.4;		// SCK Low time

parameter fSCK = 	(DEVICE == "AT25DF041A") ? 70 :
			(DEVICE == "AT26DF081A") ? 70 :
			(DEVICE == "AT26DF161A") ? 70 :
			(DEVICE == "AT26DF321")  ? 66 : 70;
/*
parameter tSCKH = 	(DEVICE == "AT25DF041A") ? 6.4 :
			(DEVICE == "AT26DF081A") ? 6.4 :
			(DEVICE == "AT26DF161A") ? 6.4 :
			(DEVICE == "AT26DF321")  ? 6.8 : 6.4;

parameter tSCKL = 	(DEVICE == "AT25DF041A") ? 6.4 :
			(DEVICE == "AT26DF081A") ? 6.4 :
			(DEVICE == "AT26DF161A") ? 6.4 :
			(DEVICE == "AT26DF321")  ? 6.8 : 6.4;*/
// ******************************************************************** //


// ******************************************************************** //
// used in Model
//parameter tDIS    = 6;		// Output Disable time
//parameter tV      = 6;		// Output Valid time
//parameter tOH     = 0 ;		// Output Hold time

//parameter tHLQZ   = 6 ;		// HOLD! Low to Output High-z
//parameter tHHQX   = 6 ;		// HOLD! High to Output Low-z
// ******************************************************************** //

// local clock generation
always
	#(tSCKH) SCK_gen = !SCK_gen;

// for SCK
`ifdef MODE3
assign SCK_out = (CSB_out==1'b0) ? SCK_gen : (CSB_stop==1'b1) ? SCK_gen : 1'b1; // SPI mode 3
`else
assign SCK_out = (CSB_out==1'b0) ? SCK_gen : (CSB_start==1'b1) ? SCK_gen : 1'b0; // SPI mode 0
`endif

initial
begin
	$dumpvars;
end

initial
begin
i = 0;
CSB_start	 = 1'b0;
CSB_stop	 = 1'b0;
SCK_gen		 = 1'b1;
WPB_out		 = 1'b1;
HOLDB_out	 = 1'b1;
trg_read_stat	 = 1'b0;
trg_write_stat	 = 1'b0;
trg_wr_en	 = 1'b0;
trg_wr_dis	 = 1'b0;
trg_man		 = 1'b0;
trg_pwr_dwn	 = 1'b0;
trg_res_pwr_dwn  = 1'b0;
trg_byt_prog	 = 1'b0;
trg_rd_array	 = 1'b0;
trg_rd_array_l	 = 1'b0;
trg_seq_byt	 = 1'b0;
t_no_addr	 = 1'b0;
trg_protect	 = 1'b0;
trg_unprotect	 = 1'b0;
trg_rd_protect	 = 1'b0;
trg_be4		 = 1'b0;
trg_be32	 = 1'b0;
trg_be64	 = 1'b0;
trg_ce		 = 1'b0;
t_data_num	 = 9'b0;

CSB_out = 1'b1;
#(11*tSCKH)

@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_read_stat=1'b1;	// read status register
#(16*tSCKH)
#(38*tSCKH) 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1; trg_read_stat=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH)
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(16*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH) 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_dis = 1'b1;		// write disable
#(2*tSCKH);
#(16*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_dis = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH) 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_man = 1'b1;		// Manufacturer
#(84*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_man = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_pwr_dwn = 1'b1;		// deep power down
#(2*tSCKH);
#(16*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_pwr_dwn = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tEDPD;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable - this will not be executed
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h000101; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_res_pwr_dwn = 1'b1;	// resume deep power down
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_res_pwr_dwn = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tRDPD;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_read_stat=1'b1;		// read status register
#(54*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_read_stat=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_protect = 1'b1; address = 24'h00010A; // read sector protection
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(20*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECP;
///*
$display("****** ****** Byte/Page programming Start ****** ******");
#(4*tSCKH); 

@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_byt_prog = 1'b1;address = 24'h00010A;data = 8'h05;t_data_num = 9'b0_0000_0001; //byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH);  // for data txn
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_byt_prog = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tPP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h000101; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_byt_prog = 1'b1;address = 24'h00010B;data = 8'h06;t_data_num = 9'b0_0000_0001; //byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH);  // for data txn
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_byt_prog = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tPP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_byt_prog = 1'b1;address = 24'h000100;data = 8'h04;t_data_num = 9'b0_0000_0010;//byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH); data = 8'h05;  // for data txn
#(16*tSCKH);  // for data txn
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_byt_prog = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tPP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_byt_prog = 1'b1;address = 24'h000102;data = 8'h2F;t_data_num = 9'b0_0000_1001;//byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH); data = 8'h2E; // for data txn
#(16*tSCKH); data = 8'h2A; // for data txn
#(16*tSCKH); data = 8'h21; // for data txn
#(16*tSCKH); data = 8'h3F; // for data txn
#(16*tSCKH); data = 8'h4F; // for data txn
#(16*tSCKH); data = 8'h5F; // for data txn
#(16*tSCKH); data = 8'h6F; // for data txn
#(16*tSCKH); data = 8'h7F; // for data txn
#(16*tSCKH); // for data txn
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_byt_prog = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tPP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_array_l = 1'b1;address = 24'h000100;t_data_num = 9'b0_0000_0001; // read array (low freq)
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(20*tSCKH);  // for data txn
#(20*tSCKH);  // for data txn
#(20*tSCKH);  // for data txn
#(20*tSCKH);  // for data txn
#(20*tSCKH);  // for data txn
#(20*tSCKH);  // for data txn
#(20*tSCKH);  // for data txn
#(20*tSCKH);  // for data txn
#(20*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_array_l = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_protect = 1'b1; address = 24'h000101; // read sector protection
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(20*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h000101; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_protect = 1'b1; address = 24'h000108; // read sector protection
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(20*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_byt_prog = 1'b1;address = 24'h00010B;data = 8'hCA;t_data_num = 9'b0_0000_0001;//byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH);  // for data txn
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_byt_prog = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tPP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h000A01; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_byt_prog = 1'b1;address = 24'h000A04;data = 8'h2F;t_data_num = 9'b1_0000_0000;//byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
for(i=0; i < 256; i=i+1) // for one page programming
begin
	#(16*tSCKH); data = 8'h10 + (3 * i);
end
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_byt_prog = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tPP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h000A00; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#(2*tSCKH);
$display("****** ****** Byte/Page programming End ****** ******");
//*/
///*
$display("****** ****** Sequential programming Start ****** ******");
#(4*tSCKH); 

@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;address = 24'h07A000;data = 8'h1F;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

`ifdef 321
`else
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h07A000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;address = 24'h07A000;data = 8'h1F;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;address = 24'h07A000;data = 8'h1F;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;data = 8'h6E;t_no_addr=1'b1;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;t_no_addr=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;data = 8'h6B;t_no_addr=1'b1;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;t_no_addr=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;data = 8'h81;t_no_addr=1'b1;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;t_no_addr=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;data = 8'h14;t_no_addr=1'b1;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;t_no_addr=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_dis = 1'b1;		// write disable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_dis = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h07A000; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_array = 1'b1;address = 24'h07A000;t_data_num = 9'b0_0000_0101; // read array
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH);  // for x val
#(16*tSCKH);  // for data txn
#(16*tSCKH);  // for data txn
#(16*tSCKH);  // for data txn
#(16*tSCKH);  // for data txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_array = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h060000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;address = 24'h060000;data = 8'h1F;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

for(i=1; i < 51; i=i+1)
begin
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;t_no_addr=1'b1;// sequential byte program
data = (8'hAE + i + (i*4));
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;t_no_addr=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;
end

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_dis = 1'b1;		// write disable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_dis = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h060000; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_array = 1'b1;address = 24'h060000;t_data_num = 9'b0_0011_0011; // read array
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH);  // for x val
#(16*tSCKH);  // for data txn
for(i=1; i < 51; i=i+1)
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_array = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h07C000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;address = 24'h07FFFD;data = 8'h1F;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;data = 8'h6B;t_no_addr=1'b1;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;t_no_addr=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;data = 8'h6B;t_no_addr=1'b1;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;t_no_addr=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_seq_byt = 1'b1;data = 8'h6B;t_no_addr=1'b1;// sequential byte program
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_seq_byt = 1'b0;t_no_addr=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h07C000; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#(2*tSCKH);

`endif
$display("****** ****** Sequential programming end ****** ******");
//*/
///*
// ----- check SPRL and WP -----
$display("****** ****** Global protect, unprotect, SPRL and WPB start ****** ******");
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hF0; //Write Status reg - set SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h011101; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h0F; //Write Status reg - reset SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h011101; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH);
#tWPH;
WPB_out = 1'b0;
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_read_stat=1'b1;		// read status register
#(54*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_read_stat=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hF0; //Write Status reg - set SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_read_stat=1'b1;		// read status register
#(54*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_read_stat=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h011101; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hF0; //Write Status reg - set SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h0F; //Write Status reg - reset SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

WPB_out = 1'b1;
#tWPS;
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hF0; //Write Status reg - set SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h00; //Write Status reg - reset SPRL; global unprotect
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;
// since SPRL is locked, global unprotect will not be executed

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h011101; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#(2*tSCKH);

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h00; //Write Status reg - global unprotect
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(4*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_protect = 1'b1; address = 24'h00010A; // read sector protection
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(20*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h000000; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h010000; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h020000; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h7F; //Write Status reg - global protect; reset SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h00; //Write Status reg - global unprotect
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h000101; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#(10*tSCKH);

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hF0; //Write Status reg - set SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(4*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h00; //Write Status reg - global unprotect
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;
// above global unprotect resets SPRL only. since SPRL is set, global unprotect cannot be done

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hFF; //Write Status reg - global protect; SPRL set
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h0F; //Write Status reg - reset SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(4*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(2*tSCKH);
$display("****** ****** Global protect, unprotect, SPRL and WPB end ****** ******");
//*/
// this part will take huge amount of time to simulate. Hence commented. can be run after uncommenting.
/*
$display("****** ****** Block Erase Start ****** ******");

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h060000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be4 = 1'b1;address = 24'h060032; // 4K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be4 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE4;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be32 = 1'b1;address = 24'h065032; // 32K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be32 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE32;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be64 = 1'b1;address = 24'h06A032; // 64K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be64 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE64;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h000000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h010000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h020000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h030000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); CSB_out = 1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h040000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h050000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h060000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h070000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h078000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h07A000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h07C000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

// for slot 7-10
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be64 = 1'b1;address = 24'h070000; // 64K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be64 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE64;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be32 = 1'b1;address = 24'h07A000; // 32K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be32 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE32;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h00; //Write Status reg - global unprotect
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_ce = 1'b1;address = 24'h060032; // Chip erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_ce = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
		for(delay =0; delay < tmult; delay = delay+1)
			#tCHPEn;
#(15*tSCKH);

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hFF; //Write Status reg - global protect; SPRL set
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_array = 1'b1;address = 24'h060000;t_data_num = 9'b0_0011_0011; // read array
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH);  // for x val
#(20*tSCKH);  // for data txn
for(i=1; i < 51; i=i+1)
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_array = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#(2*tSCKH);

`ifdef 041
// Erase operation in uneven sectors for device AT25DF041A
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h0F; //Write Status reg - reset SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h070000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be64 = 1'b1;address = 24'h070000; // 64K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be64 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE64;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h07A000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be32 = 1'b1;address = 24'h07A000; // 32K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be32 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE32;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hFF; //Write Status reg - global protect; SPRL set
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;
`endif

`ifdef 081
// Erase operation in uneven sectors for device AT26DF081A
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h0F; //Write Status reg - reset SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h088000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be64 = 1'b1;address = 24'h080000; // 64K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be64 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE64;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h086000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be32 = 1'b1;address = 24'h080000; // 32K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be32 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE32;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be4 = 1'b1;address = 24'h088000; // 4K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be4 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE32;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hFF; //Write Status reg - global protect; SPRL set
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;
`endif

`ifdef 161
// Erase operation in uneven sectors for device AT26DF161A
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h0F; //Write Status reg - reset SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h1F8000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be64 = 1'b1;address = 24'h1F8000; // 64K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be64 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE64;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h1E8600; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be32 = 1'b1;address = 24'h1E8600; // 32K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be32 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE32;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be4 = 1'b1;address = 24'h1E0010; // 4K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be4 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE32;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hFF; //Write Status reg - global protect; SPRL set
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;
`endif

`ifdef 321
// Erase operation in uneven sectors for device AT26DF321
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h0F; //Write Status reg - reset SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h3F8000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be64 = 1'b1;address = 24'h3F8000; // 64K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be64 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE64;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h3E8600; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be32 = 1'b1;address = 24'h3E8600; // 32K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be32 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE32;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_be4 = 1'b1;address = 24'h3E0010; // 4K block erase
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_be4 = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tBLKE32;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hFF; //Write Status reg - global protect; SPRL set
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;
`endif

#(2*tSCKH);
$display("****** ****** Block Erase end ****** ******");
*/
// this part can be uncommented. but will take huge amount of time to finish
///*
`ifdef 321
`else
$display("****** ****** Hold ****** ******");
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(16*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h07A000; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;
trg_wr_en = 1'b1;		// write enable
#(4*tSCKH);
@(posedge SCK_gen);
#tHHH HOLDB_out = 1'b0;
#(6*tSCKH);
@(posedge SCK_gen);
#tHLH HOLDB_out = 1'b1;
#(14*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_byt_prog = 1'b1;address = 24'h07A000;data = 8'h2F;t_data_num = 9'b0_0000_1001;//byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH); data = 8'h2E; // for data txn
#(16*tSCKH); data = 8'h2A; // for data txn
#(16*tSCKH); data = 8'h21; // for data txn
#(16*tSCKH); data = 8'h3F; // for data txn
#(16*tSCKH); data = 8'h4F; // for data txn
#(16*tSCKH); data = 8'h5F; // for data txn
#(16*tSCKH); data = 8'h6F; // for data txn
#(16*tSCKH); data = 8'h7F; // for data txn
#(16*tSCKH); // for data txn
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_byt_prog = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tPP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_array = 1'b1;address = 24'h07A000;t_data_num = 9'b0_0011_0011; // read array
#(4*tSCKH);
@(posedge SCK_gen); 
#tHHH HOLDB_out = 1'b0;
#(8*tSCKH);
@(posedge SCK_gen);
#tHLH HOLDB_out = 1'b1;
#(14*tSCKH);  // for opcode txn
#(8*tSCKH);
@(posedge SCK_gen);
#tHHH HOLDB_out = 1'b0;
#(8*tSCKH);
@(posedge SCK_gen);
#tHLH HOLDB_out = 1'b1;
#(40*tSCKH);  // for address txn
#(16*tSCKH);  // for x val
#(20*tSCKH);  // for data txn
#(20*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_array = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_array_l = 1'b1;address = 24'h07A003;t_data_num = 9'b0_0000_0001; // read array
#(4*tSCKH);
@(posedge SCK_gen);
#tHHH HOLDB_out = 1'b0;
#(8*tSCKH);
@(posedge SCK_gen);
#tHLH HOLDB_out = 1'b1;
#(14*tSCKH);  // for opcode txn
#(8*tSCKH);
#tHHH HOLDB_out = 1'b0;
#(8*tSCKH);
@(posedge SCK_gen);
#tHLH HOLDB_out = 1'b1;
#(40*tSCKH);  // for address txn
#(20*tSCKH);  // for data txn
#(4*tSCKH);
@(posedge SCK_gen);
#tHHH HOLDB_out = 1'b0;
#(8*tSCKH);
@(posedge SCK_gen);
#tHLH HOLDB_out = 1'b1;
#(20*tSCKH);  // for data txn
#(4*tSCKH);
@(posedge SCK_gen);
#tHHH HOLDB_out = 1'b0;
#(8*tSCKH);
@(posedge SCK_gen);
#tHLH HOLDB_out = 1'b1;
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_array_l = 1'b0;t_data_num = 9'b0_0000_0000;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_protect = 1'b1; address = 24'h07A000; // read sector protection
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(20*tSCKH);  // for data txn
#(4*tSCKH);
@(posedge SCK_gen);
#tHHH HOLDB_out = 1'b0;
#(8*tSCKH);
@(posedge SCK_gen);
#tHLH HOLDB_out = 1'b1;
#(20*tSCKH);  // for data txn
#(2*tSCKH);
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_man = 1'b1;		// Manufacturer
#(16*tSCKH); // for opcode txn
#(4*tSCKH);
@(posedge SCK_gen);
#tHHH HOLDB_out = 1'b0;
#(8*tSCKH);
@(posedge SCK_gen);
#tHLH HOLDB_out = 1'b1;
#(84*tSCKH);
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_man = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_read_stat=1'b1;		// read status register
#(16*tSCKH); // for opcode txn
#(8*tSCKH);
@(posedge SCK_gen);
#tHHH HOLDB_out = 1'b0;
#(8*tSCKH);
@(posedge SCK_gen);
#tHLH HOLDB_out = 1'b1;
#(54*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_read_stat=1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

$display("****** ****** Hold End ****** ******");
`endif
//*/
///*
$display("****** ****** Data validation Start****** ******");
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'h0F; //Write Status reg - set SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(16*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h000101; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

j=0;
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_byt_prog = 1'b1;address = 24'h000101;data = 8'h2F;t_data_num = 9'b0_0000_1001;//byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
store_data [j] = data; j=j+1;
#(16*tSCKH); data = 8'h2E; store_data [j] = data; j=j+1; // for data txn
#(16*tSCKH); data = 8'h2A; store_data [j] = data; j=j+1; // for data txn
#(16*tSCKH); data = 8'h21; store_data [j] = data; j=j+1; // for data txn
#(16*tSCKH); data = 8'h3F; store_data [j] = data; j=j+1; // for data txn
#(16*tSCKH); data = 8'h4F; store_data [j] = data; j=j+1; // for data txn
#(16*tSCKH); data = 8'h5F; store_data [j] = data; j=j+1; // for data txn
#(16*tSCKH); data = 8'h6F; store_data [j] = data; j=j+1; // for data txn
#(16*tSCKH); data = 8'h7F; store_data [j] = data; j=j+1; // for data txn
#(16*tSCKH); store_data [j] = data; j=j+1; // for data txn
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_byt_prog = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tPP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h000A01; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_byt_prog = 1'b1;address = 24'h000A04;data = 8'h2F;t_data_num = 9'b0_0001_1001;//byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
for(i=0; i < 25; i=i+1) // for one page programming
begin
	#(16*tSCKH); store_data [j] = data; j=j+1; data = 8'h10 + (3 * i);
end
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_byt_prog = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tPP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(16*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h000101; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_protect = 1'b1; address = 24'h000A01; // protect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_protect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECP

k=0;
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_array_l = 1'b1;address = 24'h000101;t_data_num = 9'b0_0000_1001;// read array (low freq)
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
for(i=0; i < 9; i=i+1)
begin
	#(16*tSCKH); // for data txn
	read_data[k] = out_data;k=k+1;
end
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_array_l = 1'b0;t_data_num = 9'b0_0000_0000;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_array_l = 1'b1;address = 24'h000A04;t_data_num = 9'b0_0001_1001;// read array (low freq)
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
for(i=0; i <= 25; i=i+1)
begin
	read_data[k] = out_data;k=k+1;
	#(16*tSCKH); // for data txn
end
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_array_l = 1'b0;t_data_num = 9'b0_0000_0000;
@(posedge SCK_gen);CSB_stop=1'b0;

for (i=0; i < k; i=i+1)
begin
	if(store_data[i] == read_data[i])
		$display("Write Data: %h, Read Data: %h Valid Data received",store_data[i],read_data[i]);
	else
		$display("Write Data: %h, Read Data: %h Invalid Data received",store_data[i],read_data[i]);
end
i=0;
j=0;
k=0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_write_stat = 1'b1;data = 8'hF0; //Write Status reg - set SPRL
#(16*tSCKH);  // for opcode txn
#(16*tSCKH);  // for data txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_write_stat = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tWRSR;
// this will create data mismatch since byte program will not be done  -- intentionally done

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(16*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_unprotect = 1'b1; address = 24'h000101; // unprotect sector
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_unprotect = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tSECUP;

#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_wr_en = 1'b1;		// write enable
#(18*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_wr_en = 1'b0;
@(posedge SCK_gen);CSB_stop=1'b0;

j=0;
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_byt_prog = 1'b1;address = 24'h000301;data = 8'h2F;t_data_num = 9'b0_0000_0100;//byte program
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
store_data [j] = data; j=j+1;
#(16*tSCKH); data = 8'h2E; store_data [j] = data; j=j+1; // for data txn
#(16*tSCKH); data = 8'h2A; store_data [j] = data; j=j+1; // for data txn
#(16*tSCKH); data = 8'h21; store_data [j] = data; j=j+1; // for data txn
#(16*tSCKH); store_data [j] = data; j=j+1; // for data txn
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_byt_prog = 1'b0;t_data_num = 9'b0;
@(posedge SCK_gen);CSB_stop=1'b0;
#tPP;

k=0;
#(4*tSCKH); 
@(posedge SCK_gen); CSB_start = 1'b1;
#tCSHH
CSB_out = 1'b0;CSB_start = 1'b0;trg_rd_array_l = 1'b1;address = 24'h000301;t_data_num = 9'b0_0000_0100;// read array (low freq)
#(16*tSCKH);  // for opcode txn
#(48*tSCKH);  // for address txn
#(16*tSCKH); // for data txn
for(i=0; i <= 4; i=i+1)
begin
	read_data[k] = out_data;k=k+1;
	#(16*tSCKH); // for data txn
end
#(2*tSCKH); 
#tCSLH CSB_out = 1'b1;CSB_stop=1'b1;trg_rd_array_l = 1'b0;t_data_num = 9'b0_0000_0000;
@(posedge SCK_gen);CSB_stop=1'b0;

for (i=0; i < k; i=i+1)
begin
	if(store_data[i] == read_data[i])
		$display("Write Data: %h, Read Data: %h Valid Data received",store_data[i],read_data[i]);
	else
		$display("Write Data: %h, Read Data: %h Invalid Data received",store_data[i],read_data[i]);
end

i=0;
k=0;
j=0;
$display("****** ****** Data validation End ****** ******");
//*/

#(38*tSCKH);
$finish;

end

`ifdef 041
AT26DFxxx #("AT25DF041A",PRELOAD,MEMORY_FILE) AT26DFxxx_dev1 (
`endif
`ifdef 081
AT26DFxxx #("AT26DF081A",PRELOAD,MEMORY_FILE) AT26DFxxx_dev1 (
`endif
`ifdef 161
AT26DFxxx #("AT26DF161A",PRELOAD,MEMORY_FILE) AT26DFxxx_dev1 (
`endif
`ifdef 321
AT26DFxxx #("AT26DF321",PRELOAD,MEMORY_FILE) AT26DFxxx_dev1 (
`endif
		.CSB	(CSB_out),
		.SCK	(SCK_out),
		.SI	(SI_out),
		.WPB	(WPB_out),
	`ifdef 321
	`else
		.HOLDB	(HOLDB_out),
	`endif
		.SO	(SO_in)
		);

AT26DFx_testbench tb1 (
		.clk		(SCK_gen),
		.HOLDB		(HOLDB_out),
		.SO_data	(SO_in),
		.tr_read_stat	(trg_read_stat),
		.tr_write_stat	(trg_write_stat),
		.tr_wr_en	(trg_wr_en),
		.tr_wr_dis	(trg_wr_dis),
		.tr_man		(trg_man),
		.tr_pwr_dwn	(trg_pwr_dwn),
		.tr_res_pwr_dwn	(trg_res_pwr_dwn),
		.tr_byt_prog	(trg_byt_prog),
		.tr_rd_array	(trg_rd_array),
		.tr_rd_array_l	(trg_rd_array_l),
		.tr_seq_byt	(trg_seq_byt),
		.tr_protect	(trg_protect),
		.tr_unprotect	(trg_unprotect),
		.tr_rd_protect	(trg_rd_protect),
		.tr_be4		(trg_be4),
		.tr_be32	(trg_be32),
		.tr_be64	(trg_be64),
		.tr_ce		(trg_ce),
		.data_num	(t_data_num),
		.no_addr	(t_no_addr),
		.m_address	(address),
		.w_data		(data),
		.serial_in 	(SI_out),
		.out_data	(out_data)
		);

endmodule
