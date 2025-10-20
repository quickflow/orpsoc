//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Model of AK4520A Codec chip                                 ////
////                                                              ////
////  This file is part of the OR1K test application              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  The model simulated only mode that is found on Xess XSV     ////
////  boards which is defined by:                                 ////
////  CMODE = 0                                                   ////
////  DIF0  = 0                                                   ////
////  DIF1  = 1                                                   ////
////  This mode represent MCLK = 256fs                            ////
////       20 bit in/out MSB justified, SCLK = 64fs               ////
////                                                              ////
////  Functionality:                                              ////
////  -    The model takes the input channel and dumps the        ////
////       samples to an output file.                             ////
////  -    The model creates activity on the input channel        ////
////       according to an input file. (not yet implemented)      ////
////                                                              ////
////  To Do:                                                      ////
////   - input activity                                           ////
////                                                              ////
////  Author(s):                                                  ////
////      - Lior Shtram, lior.shtram@flextronicssemi.com          ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2002 Author                                    ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//
// CVS Revision History
//
// $Log: codec_model.v,v $
// Revision 1.1  2002/03/28 19:59:53  lampret
// Added bench directory
//
// Revision 1.1.1.1  2002/03/21 16:55:44  lampret
// First import of the "new" XESS XSV environment.
//

`include "timescale.v"

module codec_model (
	mclk, lrclk, sclk, sdin, sdout
);

input 	mclk;
input 	lrclk;
input 	sclk;
input 	sdin;
output 	sdout;

reg [19:0]	left_data;
reg [19:0]	right_data;
integer		left_count, right_count;

// The file descriptors
integer		left_file, right_file;

	assign sdout = 1'b0;

// Opening the files for output data
initial 
   begin
	left_file = $fopen("../out/left.dat");
	right_file = $fopen("../out/right.dat");
   end // of opening files

always @(negedge lrclk)
   begin
	left_count = 19;
	right_count = 19;
	$fdisplay(left_file, left_data);
	$fdisplay(right_file, right_data);
   end

always @(negedge sclk)
   begin
      if ((left_count > 0) &  (lrclk == 1'b0)) begin
	left_data[left_count] <= sdin;
	left_count <= left_count - 1;
      end
      if ((right_count > 0) & (lrclk == 1'b1)) begin
	right_data[right_count] <= sdin;
	right_count <= right_count - 1;
      end
   end

endmodule
