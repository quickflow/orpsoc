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

//************************************************************************
// This file contains the paramenters which define the part for the
// Byte-Wide Smart 3 FlashFile(tm) memory model (bwsvff.v).  The '3.3V 
// Vcc Timing' parameters are representative of
// the 3.3V Vcc 28F016S3-120.  These parameters need to be changed if the
// 3.3V Vcc 28F016S3-150 is to be modeled.  The '2.7V Vcc Timing' parameters
// are representative of the 2.7V Vcc 28F016S3-150.  These parameters need
// to be changed if the 2.7V Vcc 28F016S3-170 is to be modeled.  The
// parameters were taken from the Byte-Wide SmartVoltage FlashFile Memory
// Family datasheet (Order Number 290598).

// This file must be loaded before the main model, as it contains
// definitions required by the model.

//28F016S3

`define BlockFileBegin  "../../bench/models/28f016s3/28f016s3.bkb"   //starting addresses of each block
`define BlockFileEnd    "../../bench/models/28f016s3/28f016s3.bke"   //ending addresses of each block

//Available Vcc supported by the device.
`define VccLevels       1       //Bit 0 - 5V, Bit 1 = 3.3V, Bit 2 = 2.7V

`define AddrSize        21          //number of address pins
`define MaxAddr         `AddrSize'h1FFFFF    // device ending address
`define MainArraySize   0:`MaxAddr  //array definition in bytes
                                    //include A-1 for 8 bit mode)
`define MaxOutputs      8           //number of output pins
`define NumberOfBlocks  32          //number of blocks in the array

`define ID_DeviceCodeB      'hAA    //016 S3
`define ID_ManufacturerB    'h89

// Timing parameters.  See the data sheet for definition
// of the parameter.

//5V Vcc Timing
`define TAVAV_50             95
`define TAVQV_50             95
`define TELQV_50             95
`define TPHQV_50            400
`define TGLQV_50             40
`define TGLQX_50              0   //TELQX also
`define TGHQZ_50             10
`define TEHQZ_50             55
`define TOH_50                0
`define TPHHWH_50           100
`define TAVWH_50             40
`define TDVWH_50             40
`define TPHWL_50              1
`define TWPH_50              25  //TWHWL, TEHEL, TWHEL, TEHWL
`define TWP_50               50  //TWLWH, TELEH, TWLEH, TELWH
`define TWHDX_50              5
`define TWHAX_50              5


//3.3V Vcc Timing
`define TAVAV_33            120
`define TAVQV_33            120
`define TELQV_33            120
`define TPHQV_33            600
`define TGLQV_33             50
`define TGLQX_33              0   //TELQX also
`define TGHQZ_33             15
`define TEHQZ_33             55
`define TOH_33                0
`define TPHHWH_33           100
`define TAVWH_33             50
`define TDVWH_33             50
`define TPHWL_33              1
`define TWPH_33              25  //TWHWL, TEHEL, TWHEL, TEHWL
`define TWP_33               70  //TWLWH, TELEH, TWLEH, TELWH
`define TWHDX_33              5
`define TWHAX_33              5

//2.7V Vcc Timing
`define TAVAV_27            150
`define TAVQV_27            150
`define TELQV_27            150
`define TPHQV_27            600
`define TGLQV_27             55
`define TGLQX_27              0   //TELQX also
`define TGHQZ_27             20
`define TEHQZ_27             55
`define TOH_27                0
`define TPHHWH_27           100
`define TAVWH_27             50
`define TDVWH_27             50
`define TPHWL_27              1
`define TWPH_27              25  //TWHWL, TEHEL, TWHEL, TEHWL
`define TWP_27               70  //TWLWH, TELEH, TWLEH, TELWH
`define TWHDX_27              5
`define TWHAX_27              5

//The following constants control how long it take an algorithm to run

// To scale all times together (for making simulation run faster)
// change the constant later listed as TimerPeriod.  The actual delays
// are TimerPeriod*xxx_Time, except for suspend latency times.

`define TimerPeriod_        1000    //1 usec = 1000ns  requires for
                                    //following times to be accurate

//reducing the following will reduce simulation time

//the times used below are the maximum (or typical if no maximum
//time is given) values from the data sheet

//5V Vcc, 12V Vpp
`define AC_ProgramTime_Byte_50_12      6       //usecs
`define AC_EraseTime_Block_50_12       1000000 //1 sec
`define AC_Set_LockBit_50_12           10      //usecs
`define AC_Clear_LockBit_50_12         1000000 //1 sec
 //Latency times are NOT multiplied by TimerPeriod_
`define AC_Program_Suspend_50_12       5000    //usecs
`define AC_Erase_Suspend_50_12         12000   //usecs

//3.3V Vcc, 12V Vpp
`define AC_ProgramTime_Byte_33_12      8       //usecs 7.6us
`define AC_EraseTime_Block_33_12       1100000 //1.1secs
`define AC_Set_LockBit_33_12           12      //usecs 11.6us
`define AC_Clear_LockBit_33_12         1100000 //1.1 sec
 //Latency times are NOT multiplied by TimerPeriod_
`define AC_Program_Suspend_33_12       6000    //usecs
`define AC_Erase_Suspend_33_12         12000   //usecs

//5V Vcc, 5V Vpp
`define AC_ProgramTime_Byte_50_5       8       //usecs
`define AC_EraseTime_Block_50_5        1100000 //1.1secs
`define AC_Set_LockBit_50_5            12      //usecs
`define AC_Clear_LockBit_50_5          1100000 //1.1 sec
 //Latency times are NOT multiplied by TimerPeriod_
`define AC_Program_Suspend_50_5        6000    //usecs
`define AC_Erase_Suspend_50_5          12000   //usecs

//3.3V Vcc, 5V Vpp
`define AC_ProgramTime_Byte_33_5       10      //usecs 9.3us
`define AC_EraseTime_Block_33_5        1200000 //1.2secs
`define AC_Set_LockBit_33_5            14      //usecs 13.3us
`define AC_Clear_LockBit_33_5          1200000 //1.2 sec
 //Latency times are NOT multiplied by TimerPeriod_
`define AC_Program_Suspend_33_5        7000    //usecs
`define AC_Erase_Suspend_33_5          12000   //usecs

//3.3V Vcc, 3.3V Vpp
`define AC_ProgramTime_Byte_33_33      17      //usecs
`define AC_EraseTime_Block_33_33       1800000 //1.8secs
`define AC_Set_LockBit_33_33           21      //usecs
`define AC_Clear_LockBit_33_33         1800000 //1.8 sec
 //Latency times are NOT multiplied by TimerPeriod_
`define AC_Program_Suspend_33_33       7000    //usecs
`define AC_Erase_Suspend_33_33         20000   //usecs
