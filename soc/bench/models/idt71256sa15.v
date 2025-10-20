
/*******************************************************************************
 *   Copyright 1991, 1992, 1993 Integrated Device Technology Corp.
 *   All right reserved.
 *
 *   This program is proprietary and confidential information of
 *   IDT Corp. and may be used and disclosed only as authorized 
 *   in a license agreement controlling such use and disclosure.
 *
 *   IDT reserves the right to make any changes to
 *   the product herein to improve function or design.
 *   IDT does not assume any liability arising out of
 *   the application or use of the product herein.
 *
 *   WARNING: The unlicensed shipping, mailing, or carring of this
 *   technical data outside the United States, or the unlicensed
 *   disclosure, by whatever means, through visits abroad, or the
 *   unlicensed disclosure to foreign national in the United States,
 *   may violate the United States criminal law.
 *
 *   File Name                 : idt71256sa15.v
 *   Function                  : 32Kx8-bit Asynchronous Static RAM
 *   Simulation Tool/Version   : Verilog 2.0
 *
 ******************************************************************************/

/*+ **************************** Internal Use Only *****************************
 *+   Revision History
 *+   Name              Version dd-mmm-yy   Notes
 *+   William Lam       0.1        Mar-94   Based on IDT71B256SA part
 *+   Martin Mueller    0.2      2-Sep-94   Updated to reflect IDT71256SA15 timing
 *+   Martin Mueller    0.3      6-Sep-94   Changed to 0.1nS time scale
 *+ ***************************************************************************/

/*******************************************************************************
 * Module Name: idt71256sa15
 * Description: 32Kx8 15nS Asynchronous Static RAM
 *
 *******************************************************************************/
`timescale 1ns/100ps
//`timescale 10ps/10ps

module idt71256sa15(data, addr, we_, oe_, cs_);
inout [7:0] data;
input [14:0] addr;
input we_, oe_, cs_;

//Read Cycle Parameters
parameter Taa  = 15; // address access time
parameter Tacs = 15; // cs_     access time
parameter Tclz =  4; // cs_ to output low Z time
parameter Tchz =  7; // cs_ to output high Z time
parameter Toe  =  7; // oe_ to output  time
parameter Tohz =  6; // oe_ to output Z time
parameter Toh  =  4; // data hold from adr change time

//Write Cycle Parameters
parameter Taw  = 10; // adr valid to end of write time
parameter Tcw  = 10; // cs_ to end of write time
parameter Tas  =  0; // address set up time
parameter Twp  = 10; // write pulse width min
parameter Tdw  =  7; // data valid to end of writ time
parameter Tow  =  4; // data act from end of writ time
parameter Twhz =  6; // we_ to output in high Z time

reg [7:0] mem[0:32767];

time adr_chng,da_chng,we_fall,we_rise;
time cs_fall,cs_rise,oe_fall,oe_rise;

wire [7:0] data_in;
reg  [7:0] data_out;
reg  [7:0] temp1,temp2,temp3;
reg outen, out_en, in_en;

//integer i;
//initial begin
//    for (i=0; i<32768 ; i=i+4) begin
//       mem[i]   = 8'haa;
//       mem[i+1] = 8'hbb;
//       mem[i+2] = 8'hcc;
//       mem[i+3] = 8'hdd;
//     end 
//end

initial
  begin
       in_en = 1'b1;
    if (cs_)
       out_en = 1'b0;
  end

// input/output control logic
//---------------------------
assign data   = out_en ? data_out : 'hz;
assign data_in = in_en ? data : 'hz;

// read access
//------------
always @(addr)
      if (cs_==0 & we_==1)        //read
         #Taa data_out = mem[addr];

always @(addr)
  begin
     adr_chng = $time;

              outen  = 1'b0;
         #Toh out_en = outen;

//---------------------------------------------
      if (cs_==0 & we_==1)        //read
        begin
           if (oe_==0)
             begin
              outen = 1'b1;
              out_en = 1'b1;
             end
        end
//---------------------------------------------
     if (cs_==0 & we_==0)        //write
       begin
         if (oe_==0)
           begin
                outen = 1'b0;
                out_en = 1'b0;
                     temp1 = data_in;
            #Tdw mem[addr] = temp1;
           end
         else
           begin
                 outen = 1'b0;
                 out_en = 1'b0;
                  temp1 = data_in;
            #(Tdw-Toh) mem[addr] = temp1;
           end

         data_out = mem[addr];
       end
  end

always @(negedge cs_)
  begin
     cs_fall = $time;

     if (cs_fall - adr_chng < Tas)
         $display($time, "  Adr setup time is not enough Tas");

      if (we_==1 & oe_==0)
               outen  = 1'b1;
         #Tclz out_en = outen;

      if (we_==1)
         #(Tacs-Tclz) data_out = mem[addr];

      if (we_==0)
       begin
               outen = 1'b0;
               out_en = 1'b0;
                  temp2 = data_in;
         #Tdw mem[addr] = temp2;
       end

  end

always @(posedge cs_)
  begin
     cs_rise = $time;

   if (we_==0)
    begin
     if (cs_rise - adr_chng < Taw)
       begin
         mem[addr] = 8'hxx;
         $display($time, "  Adr valid to end of write is not enough Taw");
       end

     if (cs_rise - cs_fall < Tcw)
       begin
         mem[addr] = 8'hxx;
         $display($time, "  cs_ to end of write is not enough Tcw");
       end

     if (cs_rise - da_chng < Tdw)
       begin
         mem[addr] = 8'hxx;
         $display($time, "  Data setup is not enough");
       end
    end

               outen  = 1'b0;
         #Tchz out_en = outen;
 
  end

always @(negedge oe_)
  begin
     oe_fall = $time;

         data_out = mem[addr];

      if (we_==1 & cs_==0)
              outen  = 1'b1;
         #Toe out_en = outen;
  end

always @(posedge oe_)
  begin
     oe_rise = $time;

               outen  = 1'b0;
         #Tohz out_en = outen;
  end

// write to ram
//-------------
always @(negedge we_)
  begin
     we_fall = $time;

     if (we_fall - adr_chng < Tas)
         $display($time, "  Address set-up to WE low is not enough");

     if (cs_==0 & oe_==0)
       begin
               outen  = 1'b0;
         #Twhz out_en = outen;
                  temp3 = data_in;
         #Tdw mem[addr] = temp3;

              data_out = mem[addr];
       end

     if (cs_==0 & oe_==1)
       begin
               outen = 1'b0;
               out_en = 1'b0;
                  temp3 = data_in;
         #Tdw mem[addr] = temp3;

              data_out = mem[addr];
       end
  end

always @(posedge we_)
  begin
     we_rise = $time;

   if (cs_==0)
    begin
     if (we_rise - da_chng < Tdw)
       begin
         mem[addr] = 8'hxx;
         $display($time, "  Data setup is not enough");
       end
     if (we_rise - adr_chng < Taw)
       begin
         mem[addr] = 8'hxx;
         $display($time, "  Addr setup is not enough");
       end
    end
   if (cs_==0 & oe_==0)
    begin
     if (we_rise - we_fall < (Twhz+Tdw) )
       begin
         mem[addr] = 8'hxx;
         $display($time, "  WE pulse width needs to be Twhz+Tdw");
       end

               outen  = 1'b1;
         #Tow  out_en = outen;
    end
   if (cs_==0 & oe_==1)
    begin
     if (we_rise - we_fall < Twp)
       begin
         mem[addr] = 8'hxx;
         $display($time, "  WE pulse width needs to be Twp");
       end
    end
  end

always @ (data)
  begin
     da_chng = $time;

     if (we_==0 & cs_==0)
       begin
            #Tdw mem[addr] = data_in;

                  data_out = mem[addr];
       end
  end

endmodule
