/////////////////////////////////////////////////////////////////////
////                                                             ////
////  General Round Robin Arbiter                                ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/wb_conmax/ ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: wb_conmax_arb.v,v 1.2 2002-10-03 05:40:07 rudi Exp $
//
//  $Date: 2002-10-03 05:40:07 $
//  $Revision: 1.2 $
//  $Author: rudi $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.1.1.1  2001/10/19 11:01:40  rudi
//               WISHBONE CONMAX IP Core
//
//
//
//
//
//
//                        

`include "wb_conmax_defines.v"

module wb_conmax_arb(clk, rst, req, gnt, next);

   input		clk;
   input		rst;
   input [15:0]		req;		// Req input
   output [3:0]		gnt; 		// Grant output
   input		next;		// Next Target
   
   ///////////////////////////////////////////////////////////////////////
   //
   // Parameters
   //
   
   parameter [3:0]	
			grant0 = 4'd0,
			grant1 = 4'd1,
			grant2 = 4'd2,
			grant3 = 4'd3,
			grant4 = 4'd4,
			grant5 = 4'd5,
			grant6 = 4'd6,
			grant7 = 4'd7,
			grant8 = 4'd8,
			grant9 = 4'd9,
			grant10 = 4'd10,
			grant11 = 4'd11,
			grant12 = 4'd12,
			grant13 = 4'd13,
			grant14 = 4'd14,
			grant15 = 4'd15;
   
   
   ///////////////////////////////////////////////////////////////////////
   //
   // Local Registers and Wires
   //
   
   reg [3:0]		state, next_state;
   
   ///////////////////////////////////////////////////////////////////////
   //
   //  Misc Logic 
   //
   
   assign	gnt = state;
   
   always@(posedge clk or posedge rst)
     if(rst)		state <=  grant0;
     else		state <=  next_state;
   
   ///////////////////////////////////////////////////////////////////////
   //
   // Next State Logic
   //   - implements round robin arbitration algorithm
   //   - switches grant if current req is dropped or next is asserted
   //   - parks at last grant
   //
   
   always@(state or req or next)
     begin
	next_state = state;	// Default Keep State
	case(state)		// synopsys parallel_case full_case
 	  grant0:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[0] | next)
	      begin
		 if(req[1])	next_state = grant1;
		 else
		   if(req[2])	next_state = grant2;
		   else
		     if(req[3])	next_state = grant3;
		     else
		       if(req[4])	next_state = grant4;
		       else
			 if(req[5])	next_state = grant5;
			 else
			   if(req[6])	next_state = grant6;
			   else
			     if(req[7])	next_state = grant7;
			   else
			     if(req[8])	next_state = grant8;
			   else
			     if(req[9])	next_state = grant9;
			   else
			     if(req[10])	next_state = grant10;
			   else
			     if(req[11])	next_state = grant11;
			   else
			     if(req[12])	next_state = grant12;
			   else
			     if(req[13])	next_state = grant13;
			   else
			     if(req[14])	next_state = grant14;
			   else
			     if(req[15])	next_state = grant15;
	      end
 	  grant1:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[1] | next)
	      begin
		 if(req[2])	next_state = grant2;
		 else
		   if(req[3])	next_state = grant3;
		   else
		     if(req[4])	next_state = grant4;
		     else
		       if(req[5])	next_state = grant5;
		       else
			 if(req[6])	next_state = grant6;
			 else
			   if(req[7])	next_state = grant7;
			   else
			     if(req[8])	next_state = grant8;
			   else
			     if(req[9])	next_state = grant9;
			   else
			     if(req[10])	next_state = grant10;
			   else
			     if(req[11])	next_state = grant11;
			   else
			     if(req[12])	next_state = grant12;
			   else
			     if(req[13])	next_state = grant13;
			   else
			     if(req[14])	next_state = grant14;
			   else
			     if(req[15])	next_state = grant15;
			   else
			     if(req[0])	next_state = grant0;
	      end
 	  grant2:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[2] | next)
	      begin
		 if(req[3])	next_state = grant3;
		 else
		   if(req[4])	next_state = grant4;
		   else
		     if(req[5])	next_state = grant5;
			else
			  if(req[6])	next_state = grant6;
			  else
			    if(req[7])	next_state = grant7;
			   else
			     if(req[8])	next_state = grant8;
			   else
			     if(req[9])	next_state = grant9;
			   else
			     if(req[10])	next_state = grant10;
			   else
			     if(req[11])	next_state = grant11;
			   else
			     if(req[12])	next_state = grant12;
			   else
			     if(req[13])	next_state = grant13;
			   else
			     if(req[14])	next_state = grant14;
			   else
			     if(req[15])	next_state = grant15;
			    else
			      if(req[0])	next_state = grant0;
			      else
				if(req[1])	next_state = grant1;
	      end
 	  grant3:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[3] | next)
	      begin
		 if(req[4])	next_state = grant4;
		 else
		   if(req[5])	next_state = grant5;
		   else
		     if(req[6])	next_state = grant6;
		     else
		       if(req[7])	next_state = grant7;
			   else
			     if(req[8])	next_state = grant8;
			   else
			     if(req[9])	next_state = grant9;
			   else
			     if(req[10])	next_state = grant10;
			   else
			     if(req[11])	next_state = grant11;
			   else
			     if(req[12])	next_state = grant12;
			   else
			     if(req[13])	next_state = grant13;
			   else
			     if(req[14])	next_state = grant14;
			   else
			     if(req[15])	next_state = grant15;
		       else
			 if(req[0])	next_state = grant0;
			 else
			   if(req[1])	next_state = grant1;
			   else
			     if(req[2])	next_state = grant2;
	      end
 	  grant4:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[4] | next)
	      begin
		 if(req[5])	next_state = grant5;
		 else
		   if(req[6])	next_state = grant6;
		   else
		     if(req[7])	next_state = grant7;
			   else
			     if(req[8])	next_state = grant8;
			   else
			     if(req[9])	next_state = grant9;
			   else
			     if(req[10])	next_state = grant10;
			   else
			     if(req[11])	next_state = grant11;
			   else
			     if(req[12])	next_state = grant12;
			   else
			     if(req[13])	next_state = grant13;
			   else
			     if(req[14])	next_state = grant14;
			   else
			     if(req[15])	next_state = grant15;
		     else
		       if(req[0])	next_state = grant0;
		       else
			 if(req[1])	next_state = grant1;
			 else
			   if(req[2])	next_state = grant2;
			   else
			     if(req[3])	next_state = grant3;
	      end
 	  grant5:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[5] | next)
	      begin
		 if(req[6])	next_state = grant6;
		 else
		   if(req[7])	next_state = grant7;
			   else
			     if(req[8])	next_state = grant8;
			   else
			     if(req[9])	next_state = grant9;
			   else
			     if(req[10])	next_state = grant10;
			   else
			     if(req[11])	next_state = grant11;
			   else
			     if(req[12])	next_state = grant12;
			   else
			     if(req[13])	next_state = grant13;
			   else
			     if(req[14])	next_state = grant14;
			   else
			     if(req[15])	next_state = grant15;
		   else
		     if(req[0])	next_state = grant0;
		     else
		       if(req[1])	next_state = grant1;
		       else
			 if(req[2])	next_state = grant2;
			 else
			   if(req[3])	next_state = grant3;
			   else
			     if(req[4])	next_state = grant4;
	      end
 	  grant6:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[6] | next)
	      begin
		 if(req[7])	next_state = grant7;
			   else
			     if(req[8])	next_state = grant8;
			   else
			     if(req[9])	next_state = grant9;
			   else
			     if(req[10])	next_state = grant10;
			   else
			     if(req[11])	next_state = grant11;
			   else
			     if(req[12])	next_state = grant12;
			   else
			     if(req[13])	next_state = grant13;
			   else
			     if(req[14])	next_state = grant14;
			   else
			     if(req[15])	next_state = grant15;
		 else
		   if(req[0])	next_state = grant0;
		   else
		     if(req[1])	next_state = grant1;
		     else
		       if(req[2])	next_state = grant2;
		       else
			 if(req[3])	next_state = grant3;
			 else
			   if(req[4])	next_state = grant4;
			   else
			     if(req[5])	next_state = grant5;
	      end
 	  grant7:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[7] | next)
	      begin
		 if(req[8])	next_state = grant8;
		 else if(req[9])	next_state = grant9;
		 else if(req[10])	next_state = grant10;
		 else if(req[11])	next_state = grant11;
		 else if(req[12])	next_state = grant12;
		 else if(req[13])	next_state = grant13;
		 else if(req[14])	next_state = grant14;
		 else if(req[15])	next_state = grant15;
		 else if(req[0])	next_state = grant0;
		 else if(req[1])	next_state = grant1;
		 else if(req[2])	next_state = grant2;
		 else if(req[3])	next_state = grant3;
		 else if(req[4])	next_state = grant4;
		 else if(req[5])	next_state = grant5;
		 else if(req[6])	next_state = grant6;
	      end
 	  grant8:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[8] | next)
	      begin
		 if(req[9])	next_state = grant9;
		 else if(req[10])	next_state = grant10;
		 else if(req[11])	next_state = grant11;
		 else if(req[12])	next_state = grant12;
		 else if(req[13])	next_state = grant13;
		 else if(req[14])	next_state = grant14;
		 else if(req[15])	next_state = grant15;
		 else if(req[0])	next_state = grant0;
		 else if(req[1])	next_state = grant1;
		 else if(req[2])	next_state = grant2;
		 else if(req[3])	next_state = grant3;
		 else if(req[4])	next_state = grant4;
		 else if(req[5])	next_state = grant5;
		 else if(req[6])	next_state = grant6;
		 else if(req[7])	next_state = grant7;
	      end
 	  grant9:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[9] | next)
	      begin
		 if(req[10])	next_state = grant10;
		 else if(req[11])	next_state = grant11;
		 else if(req[12])	next_state = grant12;
		 else if(req[13])	next_state = grant13;
		 else if(req[14])	next_state = grant14;
		 else if(req[15])	next_state = grant15;
		 else if(req[0])	next_state = grant0;
		 else if(req[1])	next_state = grant1;
		 else if(req[2])	next_state = grant2;
		 else if(req[3])	next_state = grant3;
		 else if(req[4])	next_state = grant4;
		 else if(req[5])	next_state = grant5;
		 else if(req[6])	next_state = grant6;
		 else if(req[7])	next_state = grant7;
		 else if(req[8])	next_state = grant8;
	      end
 	  grant10:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[10] | next)
	      begin
		 if(req[11])	next_state = grant11;
		 else if(req[12])	next_state = grant12;
		 else if(req[13])	next_state = grant13;
		 else if(req[14])	next_state = grant14;
		 else if(req[15])	next_state = grant15;
		 else if(req[0])	next_state = grant0;
		 else if(req[1])	next_state = grant1;
		 else if(req[2])	next_state = grant2;
		 else if(req[3])	next_state = grant3;
		 else if(req[4])	next_state = grant4;
		 else if(req[5])	next_state = grant5;
		 else if(req[6])	next_state = grant6;
		 else if(req[7])	next_state = grant7;
		 else if(req[8])	next_state = grant8;
		 else if(req[9])	next_state = grant9;
	      end
 	  grant11:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[11] | next)
	      begin
		 if(req[12])	next_state = grant12;
		 else if(req[13])	next_state = grant13;
		 else if(req[14])	next_state = grant14;
		 else if(req[15])	next_state = grant15;
		 else if(req[0])	next_state = grant0;
		 else if(req[1])	next_state = grant1;
		 else if(req[2])	next_state = grant2;
		 else if(req[3])	next_state = grant3;
		 else if(req[4])	next_state = grant4;
		 else if(req[5])	next_state = grant5;
		 else if(req[6])	next_state = grant6;
		 else if(req[7])	next_state = grant7;
		 else if(req[8])	next_state = grant8;
		 else if(req[9])	next_state = grant9;
		 else if(req[10])	next_state = grant10;
	      end
 	  grant12:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[12] | next)
	      begin
		 if(req[13])	next_state = grant13;
		 else if(req[14])	next_state = grant14;
		 else if(req[15])	next_state = grant15;
		 else if(req[0])	next_state = grant0;
		 else if(req[1])	next_state = grant1;
		 else if(req[2])	next_state = grant2;
		 else if(req[3])	next_state = grant3;
		 else if(req[4])	next_state = grant4;
		 else if(req[5])	next_state = grant5;
		 else if(req[6])	next_state = grant6;
		 else if(req[7])	next_state = grant7;
		 else if(req[8])	next_state = grant8;
		 else if(req[9])	next_state = grant9;
		 else if(req[10])	next_state = grant10;
		 else if(req[11])	next_state = grant11;
	      end
 	  grant13:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[13] | next)
	      begin
		 if(req[14])	next_state = grant14;
		 else if(req[15])	next_state = grant15;
		 else if(req[0])	next_state = grant0;
		 else if(req[1])	next_state = grant1;
		 else if(req[2])	next_state = grant2;
		 else if(req[3])	next_state = grant3;
		 else if(req[4])	next_state = grant4;
		 else if(req[5])	next_state = grant5;
		 else if(req[6])	next_state = grant6;
		 else if(req[7])	next_state = grant7;
		 else if(req[8])	next_state = grant8;
		 else if(req[9])	next_state = grant9;
		 else if(req[10])	next_state = grant10;
		 else if(req[11])	next_state = grant11;
		 else if(req[12])	next_state = grant12;
	      end
 	  grant14:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[14] | next)
	      begin
		 if(req[15])	next_state = grant15;
		 else if(req[0])	next_state = grant0;
		 else if(req[1])	next_state = grant1;
		 else if(req[2])	next_state = grant2;
		 else if(req[3])	next_state = grant3;
		 else if(req[4])	next_state = grant4;
		 else if(req[5])	next_state = grant5;
		 else if(req[6])	next_state = grant6;
		 else if(req[7])	next_state = grant7;
		 else if(req[8])	next_state = grant8;
		 else if(req[9])	next_state = grant9;
		 else if(req[10])	next_state = grant10;
		 else if(req[11])	next_state = grant11;
		 else if(req[12])	next_state = grant12;
		 else if(req[13])	next_state = grant13;
	      end
 	  grant15:
	    // if this req is dropped or next is asserted, check for other req's
	    if(!req[15] | next)
	      begin
		 if(req[0])	next_state = grant0;
		 else if(req[1])	next_state = grant1;
		 else if(req[2])	next_state = grant2;
		 else if(req[3])	next_state = grant3;
		 else if(req[4])	next_state = grant4;
		 else if(req[5])	next_state = grant5;
		 else if(req[6])	next_state = grant6;
		 else if(req[7])	next_state = grant7;
		 else if(req[8])	next_state = grant8;
		 else if(req[9])	next_state = grant9;
		 else if(req[10])	next_state = grant10;
		 else if(req[11])	next_state = grant11;
		 else if(req[12])	next_state = grant12;
		 else if(req[13])	next_state = grant13;
		 else if(req[14])	next_state = grant14;
	      end
	endcase
     end
   
endmodule 

