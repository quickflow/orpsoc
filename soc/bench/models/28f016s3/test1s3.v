/*
 INTEL DEVELOPER'S SOFTWARE LICENSE AGREEMENT

BY USING THIS SOFTWARE, YOU ARE AGREEING TO BE BOUND BY THE TERMS OF 
THIS AGREEMENT.  DO NOT USE THE SOFTWARE UNTIL YOU HAVE CAREFULLY READ 
AND AGREED TO THE FOLLOWING TERMS AND CONDITIONS.  IF YOU DO NOT AGREE 
TO THE TERMS OF THIS AGREEMENT, PROMPTLY RETURN THE SOFTWARE PACKAGE AND 
ANY ACCOMPANYING ITEMS.

IF YOU USE THIS SOFTWARE, YOU WILL BE BOUND BY THE TERMS OF THIS 
AGREEMENT

LICENSE: Intel Corporation ("Intel") grants you the non-exclusive right 
to use the enclosed software program ("Software").  You will not use, 
copy, modify, rent, sell or transfer the Software or any portion 
thereof, except as provided in this Agreement.

System OEM Developers may:
1.      Copy the Software for support, backup or archival purposes;
2.      Install, use, or distribute Intel owned Software in object code
        only;
3.      Modify and/or use Software source code that Intel directly makes
        available to you as an OEM Developer;
4.      Install, use, modify, distribute, and/or make or have made
        derivatives ("Derivatives") of Intel owned Software under the
        terms and conditions in this Agreement, ONLY if you are a System
        OEM Developer and NOT an end-user.

RESTRICTIONS:

YOU WILL NOT:
1.      Copy the Software, in whole or in part, except as provided for
        in this Agreement;
2.      Decompile or reverse engineer any Software provided in object
        code format;
3.      Distribute any Software or Derivative code to any end-users,
        unless approved by Intel in a prior writing.

TRANSFER: You may transfer the Software to another OEM Developer if the 
receiving party agrees to the terms of this Agreement at the sole risk 
of any receiving party.

OWNERSHIP AND COPYRIGHT OF SOFTWARE: Title to the Software and all 
copies thereof remain with Intel or its vendors.  The Software is 
copyrighted and is protected by United States and international 
copyright laws.  You will not remove the copyright notice from the 
Software.  You agree to prevent any unauthorized copying of the 
Software.

DERIVATIVE WORK: OEM Developers that make or have made Derivatives will 
not be required to provide Intel with a copy of the source or object 
code.  OEM Developers shall be authorized to use, market, sell, and/or 
distribute Derivatives to other OEM Developers at their own risk and 
expense. Title to Derivatives and all copies thereof shall be in the 
particular OEM Developer creating the Derivative.  Such OEMs shall 
remove the Intel copyright notice from all Derivatives if such notice is 
contained in the Software source code.

DUAL MEDIA SOFTWARE: If the Software package contains multiple media, 
you may only use the medium appropriate for your system.
 
WARRANTY: Intel warrants that it has the right to license you to use, 
modify, or distribute the Software as provided in this Agreement. The 
Software is provided "AS IS".  Intel makes no representations to 
upgrade, maintain, or support the Software at any time. Intel warrants 
that the media on which the Software is furnished will be free from 
defects in material and workmanship for a period of one (1) year from 
the date of purchase.  Upon return of such defective media, Intel's 
entire liability and your exclusive remedy shall be the replacement of 
the Software.

THE ABOVE WARRANTIES ARE THE ONLY WARRANTIES OF ANY KIND, EITHER EXPRESS 
OR IMPLIED, INCLUDING WARRANTIES OF MERCHANTABILITY OR FITNESS FOR ANY 
PARTICULAR PURPOSE.

LIMITATION OF LIABILITY: NEITHER INTEL NOR ITS VENDORS OR AGENTS SHALL 
BE LIABLE FOR ANY LOSS OF PROFITS, LOSS OF USE, LOSS OF DATA, 
INTERRUPTION OF BUSINESS, NOR FOR INDIRECT, SPECIAL, INCIDENTAL OR 
CONSEQUENTIAL DAMAGES OF ANY KIND WHETHER UNDER THIS AGREEMENT OR 
OTHERWISE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

TERMINATION OF THIS LICENSE: Intel reserves the right to conduct or have 
conducted audits to verify your compliance with this Agreement.  Intel 
may terminate this Agreement at any time if you are in breach of any of 
its terms and conditions.  Upon termination, you will immediately 
destroy, and certify in writing the destruction of, the Software or 
return all copies of the Software and documentation to Intel.

U.S. GOVERNMENT RESTRICTED RIGHTS: The Software and documentation were 
developed at private expense and are provided with "RESTRICTED RIGHTS".  
Use, duplication or disclosure by the Government is subject to 
restrictions as set forth in FAR52.227-14 and DFAR252.227-7013 et seq. 
or its successor.

EXPORT LAWS: You agree that the distribution and export/re-export of the 
Software is in compliance with the laws, regulations, orders or other 
restrictions of the U.S. Export Administration Regulations.

APPLICABLE LAW: This Agreement is governed by the laws of the State of 
California and the United States, including patent and copyright laws.  
Any claim arising out of this Agreement will be brought in Santa Clara 
County, California.

*/


`timescale   1ns/1ns


module test28F016SC();

reg [`AddrSize-1:0]  address;

reg [31:0]  vcc,
            vpp;

reg         ceb,
            oeb,
            web,
            rpb;

wire        ryby;

reg [1:0]   rpblevel;    // 00 = VIL
                         // 01 = VIH
                         // 10 = VHH

reg    [`MaxOutputs-1:0]  dq_reg;
wire   [`MaxOutputs-1:0]  dq = dq_reg;

i28f016s3 IFlash (dq, address, ceb, oeb, web, rpb, ryby, vpp, vcc, rpblevel);

initial
    begin
//        $dumpfile("f008sc.dmp");
//        $dumpoff;
//        $dumpvars(???,dq,address,ceb,oeb,web,rpb);

       dq_reg = `MaxOutputs'hz;
       rpblevel = `rpb_vil;
       powerup;
       ReadID;
       //Verify READS with loose timing (OE Toggling)
       #100
       SetReadMode;

       $display("READ DATA, Loose Timing, toggle OE");        
       #100
       ReadData(`AddrSize'h0);
       #100
       ReadData(`AddrSize'h10000);
       #100
       ReadData(`AddrSize'h1F0000);
       #100
       ReadData(`AddrSize'h1FFFFF);

       $display("READ DATA, Loose Timing, toggle Addr");
       //Verify Reads (OE LOW)
       #100
       address = `AddrSize'h3FFFF;
       #100
       address = `AddrSize'h4FFFF;
       #100
       address = `AddrSize'h5FFFF;
       #100
       oeb = `VIH;

       $display("SET BLOCK LOCK-BITS");
       #100
       SetBlockLockBit(`AddrSize'h000000);
       #100
       SetBlockLockBit(`AddrSize'h010000);
       #100
       SetBlockLockBit(`AddrSize'h1F0000);
       #100
       ReadID;
       #100
       oeb = `VIH;

       #100
       $display("PROGRAM DATA, Loose Timing, Block Locked");
       #100
       ProgramData(`AddrSize'h000000, `MaxOutputs'h00);
       #100
       ProgramData(`AddrSize'h010000, `MaxOutputs'h01);
       #100
       ProgramData(`AddrSize'h1F0000, `MaxOutputs'h0F);
       #100
       ProgramData(`AddrSize'h1FFFFF, `MaxOutputs'h10);
       #100
       SetReadMode;
       $display("READ DATA, Loose Timing, toggle OE");
       #100
       ReadData(`AddrSize'h000000);
       #100
       ReadData(`AddrSize'h010000);
       $display("READ DATA, Loose Timing, toggle Addr");
       //Verify Reads (OE LOW)
       #100
       address = `AddrSize'h1F0000;
       #100
       address = `AddrSize'h1FFFFF;
       #100
       oeb = `VIH;
       $display("BLOCK LOCK-BIT OVERRIDE");
       #100
       rpblevel = `rpb_vhh;
       #100
       ProgramData(`AddrSize'h000000, `MaxOutputs'h00);
       #100
       rpblevel = `rpb_vih;
       #100
       SetReadMode;
       #100
       ReadData(`AddrSize'h000000);
       #100
       oeb = `VIH;

       $display("CLEAR BLOCK LOCK-BITS");
       #100
       ClearBlockLockBit;
       $display("PROGRAM DATA, Boot Unlocked");
       #100
       ProgramData(`AddrSize'h015000, `MaxOutputs'h51);
       #100
       ProgramData(`AddrSize'h015FFF, `MaxOutputs'h22);
       #100
       ProgramData(`AddrSize'h020000, `MaxOutputs'h02);
       #100
       ProgramData(`AddrSize'h04FFFF, `MaxOutputs'h11);
       #100
       ProgramData(`AddrSize'h050001, `MaxOutputs'h12);
       #100
       ProgramData(`AddrSize'h060000, `MaxOutputs'h06);
       #100
       ProgramData(`AddrSize'h06FFFF, `MaxOutputs'hF6);
       #100
       ProgramData(`AddrSize'h1F0000, `MaxOutputs'hAA);
       #100
       ProgramData2(`AddrSize'h1FFFFF, `MaxOutputs'h55);

       $display("READ DATA, Loose Timing,  Toggle OE");
       #100
       SetReadMode;
       #100
       ReadData(`AddrSize'h015000);
       #100
       address = `AddrSize'h1F0000;
       #100
       address = `AddrSize'h1FFFFF;
       #100
       address = `AddrSize'h020000;
       #100
       address = `AddrSize'h0F0000;
       #100
       address = `AddrSize'h0FFFFF;
       #100
       oeb = `VIH;
       $display("ERASE BLOCK");
       #100
       EraseBlock(`AddrSize'h1F000F);
       $display("READ DATA, Loose Timing, Toggle Addr");
       #100
       SetReadMode;
       #100
       oeb = `VIL;
       #100
       address = `AddrSize'h1F0000;
       #100
       address = `AddrSize'h1FFFFF;
       #100
       address = `AddrSize'h015000;
       #100
       oeb = `VIH;
       begin:  WriteSuspend
         $display("WRITE SUSPEND TEST");
         #100
         StartProgram(`AddrSize'h050000, `MaxOutputs'h05);
         #150
         oeb = `VIH;
         #100
         oeb = `VIL;
         #100
         oeb = `VIH;
         #(((`AC_ProgramTime_Byte_50_12/2)*`TimerPeriod_)-1000)
         Suspend;
         #100
         SetReadMode;
         #100
         ReadData(`AddrSize'h04FFFF);
         #100
         ReadData(`AddrSize'h050000);
         #100
         ReadData(`AddrSize'h050001);
         #100
         oeb = `VIH;
         #100
         StartProgram(`AddrSize'h0AA000, `MaxOutputs'h66);
         #300
         Resume;
         #100
         oeb = `VIL;
         #((`AC_ProgramTime_Byte_50_12/2)*`TimerPeriod_)
         begin: Poll
           forever
             begin
               oeb = `VIH;
               #500
               oeb = `VIL;
               #500
               if (dq[7] == `VIH)
                 disable Poll;
             end
         end
         #300
         SetReadMode;
         #100
         ReadData(`AddrSize'h050001);
         #100
         ReadData(`AddrSize'h050000);
         #100
         ReadData(`AddrSize'h0AA000);
         #100
         oeb = `VIH;
       end  //WriteSuspend
       begin: BadErase
         $display("BAD ERASE TEST");
         #100
         address = `AddrSize'h060000;
         #100
         dq_reg = `EraseBlockCmd;
         #100
         web = `VIL;
         #100
         web = `VIH;
         #100
         dq_reg = `ReadArrayCmd;
         #100
         web = `VIL;
         #100
         web = `VIH;
         #100
         dq_reg = `MaxOutputs'hz;
         #100
         oeb = `VIL;
         #1000
         begin: Poll
           forever
             begin
               oeb = `VIH;
               #1000
               oeb = `VIL;
               #1000
               if (dq[7] == `VIH)
                 disable Poll;
             end
         end
       end //BadErase
       #200
       ReadCSRMode;
       #200
       ClearCSRMode;
       #200
       ReadCSRMode;
       #200
       SetReadMode;
       #100
       ReadData(`AddrSize'h060000);
       #100
       ReadData(`AddrSize'h06FFFF);
       #100
       oeb = `VIH;
       begin:  EraseSuspend
         $display("ERASE SUSPEND TEST");
         #100
         StartErase(`AddrSize'h015000);
         #1000
         oeb = `VIH;
         #100
         oeb = `VIL;
         #100
         oeb = `VIH;
         #(((`AC_EraseTime_Block_50_12/2)*`TimerPeriod_)-1000)
         Suspend;
         #100
         SetReadMode;
         #100
         ReadData(`AddrSize'h020000);
         #100
         ReadData(`AddrSize'h015FFF);
         #100
         oeb = `VIH;
         #300
         Resume;
         #100
         oeb = `VIL;
         #(((`AC_EraseTime_Block_50_12/2)*`TimerPeriod_)-1000)
         begin: Poll
           forever
             begin
               oeb = `VIH;
               #1000
               oeb = `VIL;
               #1000
               if (dq[7] == `VIH)
                 disable Poll;
             end
         end
         #300
         SetReadMode;
         #100
         ReadData(`AddrSize'h010000);
         #100
         ReadData(`AddrSize'h015FFF);
         #100
         ReadData(`AddrSize'h020000);
         #100
         oeb = `VIH;
       end  //EraseSuspend
       #300
       $display("Embedded Suspend Mode");
       begin:  EraseSuspend_
         #100
         StartErase(`AddrSize'h065000);
         #1000
         oeb = `VIH;
         #100
         oeb = `VIL;
         #100
         oeb = `VIH;
         #(((`AC_EraseTime_Block_50_12/2)*`TimerPeriod_)-1000)
         Suspend;
         #100
         SetReadMode;
         #100
         ReadData(`AddrSize'h050000);
         #100
         oeb = `VIH;
         begin:  WriteSuspend_
           $display("EMBEDDED WRITE SUSPEND TEST");
           #100
           StartProgram(`AddrSize'h0FFFFF, `MaxOutputs'h77);
           #150
           oeb = `VIH;
           #100
           oeb = `VIL;
           #100
           oeb = `VIH;
           #((`AC_ProgramTime_Byte_50_12/2)*`TimerPeriod_)
           Suspend;
           #100
           SetReadMode;
           #100
           ReadData(`AddrSize'h050001);
           #100
           ReadData(`AddrSize'h060000);
           #100
           oeb = `VIH;
           #300
           Resume;  //Write Operation
           #100
           oeb = `VIL;
           #500
//           #((`AC_ProgramTime_Byte_50_12/2)*`TimerPeriod_)
           begin: Poll
             forever
               begin
                 oeb = `VIH;
                 #500
                 oeb = `VIL;
                 #500
                 if (dq[7] == `VIH)
                   disable Poll;
               end
           end
           #300
           SetReadMode;
           #100
           ReadData(`AddrSize'h0FFFFF);
           #100
           oeb = `VIH;
         end  //WriteSuspend_
         #300
         Resume;  //Erase Operation
         #100
         oeb = `VIL;
         #(((`AC_EraseTime_Block_50_12/2)*`TimerPeriod_)-1000)
         begin: Poll
           forever
             begin
               oeb = `VIH;
               #1000
               oeb = `VIL;
               #1000
               if (dq[7] == `VIH)
                 disable Poll;
             end
         end
         #300
         SetReadMode;
         #100
         ReadData(`AddrSize'h06FFFF);
         #100
         ReadData(`AddrSize'h060000);
         #100
         ReadData(`AddrSize'h050000);
         #100
         oeb = `VIH;
       end  //EraseSuspend_
       begin: MasterLockBitTest
         $display("MASTER LOCK-BIT TEST");
         SetMasterLockBit(`AddrSize'h0);
         #100
         rpblevel = `rpb_vhh;
         #100
         SetMasterLockBit(`AddrSize'h0);
         #100
         rpblevel = `rpb_vih;
         #100
         SetBlockLockBit(`AddrSize'h090000);
         #100
         rpblevel = `rpb_vhh;
         #100
         SetBlockLockBit(`AddrSize'h080000);
         #100
         SetBlockLockBit(`AddrSize'h070000);
         #100
         rpblevel = `rpb_vih;
         #100
         ProgramData(`AddrSize'h090000, `MaxOutputs'h09);
         #100
         ProgramData(`AddrSize'h080000, `MaxOutputs'h08);
         #100
         ProgramData(`AddrSize'h070000, `MaxOutputs'h07);
         #200
         SetReadMode;
         #100
         ReadData(`AddrSize'h070000);
         #100
         ReadData(`AddrSize'h080000);
         #100
         ReadData(`AddrSize'h090000);
         #100
         oeb = `VIH;
         #100
         ClearBlockLockBit;
         #100
         rpblevel = `rpb_vhh;
         #100
         ClearBlockLockBit;
         #100
         rpblevel = `rpb_vih;
         #100
         ProgramData(`AddrSize'h080000, `MaxOutputs'h08);
         #100
         ProgramData(`AddrSize'h070000, `MaxOutputs'h07);
         #100
         SetReadMode;
         #100
         ReadData(`AddrSize'h070000);
         #100
         ReadData(`AddrSize'h080000);
         #100
         oeb = `VIH;
       end                            
       #100
       vcc = 3450;
       #100
       ReadData(`AddrSize'h000000);
       #100
       ReadData(`AddrSize'h0FFFFF);
       #1000
       powerdown;
       #1000 $finish;
    end

always @(dq or address or ceb or rpb or oeb or web or vcc or vpp or rpblevel)
  begin
    $display(
      "%d Addr = %h, Data = %h, CEb=%b, RPb=%b, OEb=%b, WEb=%d, vcc=%d, vpp = %d",
      $time, address, dq, ceb, rpb, oeb, web, vcc, vpp);
  end

task powerup;
  begin
    $display("  POWERUP TASK");
    rpb = `VIL;         //reset
    #100
    address = 0;
    #100
    web = `VIH;         //write enable high
    #100
    oeb = `VIH;         //output ts
    #100
    ceb = `VIH;         //disabled
    #100
    vcc = 5000;         //power up vcc
    #5000
    vpp = 12000;        //ramp up vpp
    #5000
    rpb = `VIH;         //out of reset
    rpblevel = `rpb_vih;
    #100
    oeb = `VIL;         //enable outputs
    #100
    ceb = `VIL;         //enable chip
  end
endtask


task powerdown;
  begin
    $display("  POWERDOWN TASK");
    address = 0;
    #100
    rpb = `VIL;     //reset
    #100
    oeb = `VIH;     //output ts
    #100
    web = `VIH;     //we high
    #100
    ceb = `VIH;     //disabled
    #100
    vpp = 0;        //power down vpp
    #5000
    vcc = 0;        //ramp down vcc
  end
endtask


task ReadData;
  input [`AddrSize-1:0] addr;

  begin
    $display("  READDATA TASK");
    oeb = `VIH;
    #100
    address = addr;
    #100
    oeb = `VIL;
  end
endtask


task SetReadMode;
  begin
    $display("  SETREADMODE TASK");
    oeb = `VIH;
    #100
    dq_reg[`Byte] = `ReadArrayCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `MaxOutputs'hz;
  end
endtask


task ReadID;
  begin
    $display("  READID TASK");
    oeb = `VIH;
    #100
    address = `AddrSize'h0;
    #100
    dq_reg[`Byte] = `ReadIDCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `MaxOutputs'hz;
    #100
    oeb = `VIL;
    #100
    address = `AddrSize'h1;
    #100
    address = `AddrSize'h3;
    #100
    address = `AddrSize'h2;
    #100
    address = `AddrSize'h10002;
  end
endtask


task ReadCSRMode;
  begin
    $display("  READCSR MODE TASK");
    oeb = `VIH;
    #100
    dq_reg[`Byte] = `ReadCSRCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `MaxOutputs'hz;
    #100
    oeb = `VIL;
  end
endtask


task ClearCSRMode;
  begin
    $display("  CLEARCSRMODE TASK");
    oeb = `VIH;
    #100
    dq_reg[`Byte] = `ClearCSRCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `MaxOutputs'hz;
  end
endtask


task StartProgram;
  input [`AddrSize-1:0] addr;
  input [`MaxOutputs-1:0] data;
  begin
    $display("  STARTPROGRAM TASK");
    #100
    address = addr;
    #100
    dq_reg[`Byte] = `Program2Cmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg[`Byte] = data;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `MaxOutputs'hz;
  end
endtask


task ProgramData;
  input [`AddrSize-1:0] addr;
  input [`MaxOutputs-1:0] data;
  begin
    $display("  PROGRAMDATA TASK");
    StartProgram(addr, data);
    #100
    oeb = `VIL;
    #((`AC_ProgramTime_Byte_50_12*`TimerPeriod_)-500)
    begin:  Poll
      forever
        begin
          oeb = `VIH;
          #100
          oeb = `VIL;
          #100
          if (dq[7] == `VIH)
            disable Poll;
        end //forever
    end //Poll
    #300
    ClearCSRMode;
  end
endtask


task StartProgram2;
  input [`AddrSize-1:0] addr;
  input [`MaxOutputs-1:0] data;
  begin
    $display("  STARTPROGRAM2 TASK");
    #100
    address = addr;
    #100
    dq_reg[`Byte] = `Program2Cmd;
    #100
    web = `VIL;
    #5
    ceb = `VIL;
    #100
    ceb = `VIH;
    #5
    web = `VIH;
    #100
    dq_reg[`Byte] = data;
    #100
    web = `VIL;
    #5
    ceb = `VIL;
    #100
    ceb = `VIH;
    #5
    web = `VIH;
    #100
    ceb = `VIL;
    dq_reg = `MaxOutputs'hz;
  end
endtask


task ProgramData2;
  input [`AddrSize-1:0] addr;
  input [`MaxOutputs-1:0] data;
  begin
    $display("  PROGRAMDATA2 TASK");
    ceb = `VIH;
    StartProgram2(addr, data);
    #100
    oeb = `VIL;
    #((`AC_ProgramTime_Byte_50_12*`TimerPeriod_)-500)
    begin:  Poll
      forever
        begin
          oeb = `VIH;
          #100
          oeb = `VIL;
          #100
          if (dq[7] == `VIH)
            disable Poll;
        end //forever
    end //Poll
    #300
    ClearCSRMode;
  end
endtask

task StartErase;
  input [`AddrSize-1:0] BlockAddr;
  begin
    $display("  STARTERASE TASK");
    #100
    address = BlockAddr;
    #100
    dq_reg = `EraseBlockCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `ConfirmCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `MaxOutputs'hz;
  end
endtask


task EraseBlock;
  input [`AddrSize-1:0] BlockAddr;
  time EraseTime;
  begin
    $display("  ERASEBLOCK TASK");
    StartErase(BlockAddr);
    #100
    oeb = `VIL;
    EraseTime = ((`AC_EraseTime_Block_50_12*`TimerPeriod_)-5000);
    #EraseTime
    begin: Poll
      forever
        begin
          oeb = `VIH;
          #1000
          oeb = `VIL;
          #1000
          if (dq[7] == `VIH)
            disable Poll;
        end
    end
    #300
    ClearCSRMode;
  end
endtask


task StartLockBit;
  input [`AddrSize-1:0] BlockAddr;
  begin
    $display("  STARTLOCKBIT TASK");
    #100
    address = BlockAddr;
    #100
    dq_reg = `LBSetupCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `SetBlockLBCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `MaxOutputs'hz;
  end
endtask


task SetBlockLockBit;
  input [`AddrSize-1:0] BlockAddr;
  time LockBitTime;
  begin
    $display("  SETBLOCKLOCKBIT TASK");
    StartLockBit(BlockAddr);
    #100
    oeb = `VIL;
    LockBitTime = ((`AC_Set_LockBit_50_12*`TimerPeriod_)-5000);
    #LockBitTime
    begin : Poll
      forever
        begin
          oeb = `VIH;
          #1000
          oeb = `VIL;
          #1000
          if (dq[7] == `VIH)
            disable Poll;
        end //forever
    end //Poll
    #300
    ClearCSRMode;
  end
endtask


task StartClearBit;
  begin
    $display("  STARTCLEARBIT TASK");
    #100
    dq_reg = `LBSetupCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `ClearLBCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `MaxOutputs'hz;
  end
endtask

    
task ClearBlockLockBit;
  time ClearBitTime;
  begin
    $display("  CLEARBLOCKLOCKBIT TASK");
    StartClearBit;
    
    #100
    oeb = `VIL;
    ClearBitTime = ((`AC_Clear_LockBit_50_12*`TimerPeriod_)-5000);
    #ClearBitTime
    begin : Poll
	 forever
	   begin
		oeb = `VIH;
		#1000
		oeb = `VIL;
		#1000
		if (dq[7] == `VIH)
		  disable Poll;
	   end //forever
    end //Poll
    #300
    ClearCSRMode;
  end
endtask


task SetMasterLockBit;
  input [`AddrSize-1:0] DeviceAddr;
  time LockBitTime;
  begin
    $display("  SETMASTERLOCKBIT TASK");
    #100
    address = DeviceAddr;
    #100
    dq_reg = `LBSetupCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `SetMasterLBCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `MaxOutputs'hz;
    #100
    oeb = `VIL;
    LockBitTime = ((`AC_Set_LockBit_50_12*`TimerPeriod_)-5000);
    #LockBitTime
    begin : Poll
      forever
        begin
          oeb = `VIH;
          #1000
          oeb = `VIL;
          #1000
          if (dq[7] == `VIH)
            disable Poll;
        end //forever
    end //Poll
    #300
    ClearCSRMode;
  end
endtask
        
task Suspend;
  begin
    $display("  SUSPEND TASK");
    #100
    dq_reg = `SuspendCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `MaxOutputs'hz;
    #100
    oeb = `VIL;
    #500
    begin: Poll
      forever
        begin
          oeb = `VIH;
          #100
          oeb = `VIL;
          #100
          if (dq[7] == `VIH)
            disable Poll;
        end
    end
  end
endtask


task Resume;
  begin
    $display("  RESUME TASK");
    #100
    dq_reg = `ResumeCmd;
    #100
    web = `VIL;
    #100
    web = `VIH;
    #100
    dq_reg = `MaxOutputs'hz;
  end
endtask

endmodule
