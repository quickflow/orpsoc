
  /*
   3-Jul-97 - the VCS simulator does not allow overwriting parameters. I
           changed then to integers and inited them in the initial clause.
           This should make the model better suited for all Verilog simulators.
   3-Jul-97 - Stretch size of OpBlock, CmdAdd_1 and CmdAdd_2 for 32 block parts.
  11-Jul-97 - added variable flash_cycle. Only check TAVAV timing when CEn is
           asserted. This avoids errorious ERRORS when the address toggles
           to fast when CEn is disabled.
  */

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

  // This model is representative of the flash device described in the
  // Byte-Wide Smart 3 FlashFile(tm) Memory Family datasheet (Order
  // Number 290598).

  `timescale      1ns/1ns

  //generic defines for readability (already defined!)
  `define FALSE           1'b0
  `define TRUE            1'b1

  `define Byte            7:0

  `define VIL             1'b0
  `define VIH             1'b1

  `define rpb_vil         2'b00
  `define rpb_vih         2'b01
  `define rpb_vhh         2'b10

  `define Ready           1'b1
  `define Busy            1'b0

  // These constants are the actual command codes
  `define ClearCSRCmd     8'h50
  `define ProgramCmd      8'h10
  `define Program2Cmd     8'h40
  `define EraseBlockCmd   8'h20
  `define ReadArrayCmd    8'hFF
  `define ReadCSRCmd      8'h70
  `define ReadIDCmd       8'h90
  `define SuspendCmd      8'hB0  //Valid for both erase
  `define ResumeCmd       8'hD0  //and write suspend
  `define ConfirmCmd      8'hD0
  `define LBSetupCmd      8'h60
  `define SetBlockLBCmd   8'h01
  `define SetMasterLBCmd  8'hF1
  `define ClearLBCmd      8'hD0

  `define ReadMode_T      2:0
  `define rdARRAY         3'b000
  `define rdCSR           3'b011
  `define rdID            3'b100

  `define   Program       2'b00
  `define   Erase         2'b01
  `define   Lock          2'b10

  // Cmd_T record
  `define   Cmd_T             157:0
  `define   CmdAdd_1          157:137
  `define   CmdAdd_2          136:116
  `define   Add               115:96
  `define   CmdData_1         95:88
  `define   CmdData_2         87:78
  `define   Cmd               79:72
  `define   Count             71:40
  `define   Time              39:8
  `define   Confirm           7
  `define   OpBlock           6:2
  `define   OpType            1:0

  `define WritePtr_T          1:0
  `define NewCmd              2'b01
  `define CmdField            2'b10

  `define Locked              1'b1
  `define Unlocked            1'b0

  `define Vcc2700             3'b100
  `define Vcc3300             3'b010
  `define Vcc5000             3'b001

  `include "dp016s3.v"

  // device specific

  //module definition for Intel Smartvoltage FlashFile(tm) Flash
  //
  //vpp and vcc are are 32 bit vectors which are treated as unsigned int
  //scale for vpp and vcc is millivolts.  ie. 0 = 0V, 5000 = 5V
  //

  module i28f016s3(dq, addr, ceb, oeb, web, rpb, ryby, vpp, vcc, rpblevel);

  inout [`MaxOutputs-1:0] dq;     //8 outputs

  input [`AddrSize-1:0]   addr;   //address pins.

  input          ceb,    //CE# - chip enable bar
                 oeb,    //OE# - output enable bar
                 web,    //WE# - write enable bar
                 rpb;    //RP# - reset bar, powerdown

  output         ryby;   //RY/BY# - Ready/Busy signal

  input [31:0]   vpp,    //vpp in millivolts
                 vcc;    //vcc in millivolts

  input [1:0]    rpblevel;   //rpb at vil or vih or vhh

  reg [`Byte]    MainArray[`MainArraySize];  //flash array

  //  Flag to show that a Cmd has been written
  //  and needs predecoding
  reg        CmdValid ;

  // This points to where data written to the part will
  // go. By default it is to NewCmd. CmdField means the
  // chip is waiting on more data for the cmd (ie confirm)

  reg [`WritePtr_T]   WriteToPtr ;

  // Contains the current executing command and all its
  // support information.
  reg [`Cmd_T]   Cmd ;

  reg [`Cmd_T]   Algorithm;

  reg [`Cmd_T]   SuspendedAlg;

  // Output of Data
  reg [7:0]  ArrayOut ;

  // Current output of the Compatible status register
  reg [7:0]  CSROut ;

  // Current output of the ID register
  reg [7:0]  IDOut ;

  //  Startup Flag phase
  reg        StartUpFlag ;

  //  Global Reset Flag
  reg        Reset ;

  //  Variable to see if chip can only be read -- 2.7V Vcc
  reg        ReadOnly;

  //  Vpp Monitoring
  reg        VppFlag ;
  reg        VppError ;
  reg        VppErrFlag ;
  reg        ClearVppFlag ;

  //  Internal representation of the CSR SR.1 bit
  reg        Protected;
  //  Internal representation of the CSR SR.4 bit
  reg        Program_SetLBError ;
  //  Internal representation of the CSR SR.5 bit
  reg        Erase_ClearLBError ;

  //  Internal representation of GSR bit
  reg [`ReadMode_T] ReadMode ;

  //  Current value of the CSR
  wire [`Byte] CSR ;

  //  Flag that determines if the chip is driving
  //  the outputs
  reg        DriveOutputs ;

  //  Internal value of the out data.  If DriveOutputs
  //  is active this value will be placed on the
  //  outputs.  -1 == Unknown or XXXX
  reg [`MaxOutputs-1:0]    InternalOutput ;

  //  Number of addition writes necessary to
  //  supply the current command information.
  //  When it hits zero it goes to Decode
  integer       DataPtr ;

  //  Master internal write enable
  wire       Internal_WE ;

  //  Master internal output enable
  wire       Internal_OE ;
  wire       Internal_OE2 ;
  wire       Internal_OE3 ;

  //  Master internal read enable
  wire       Internal_RE ;

  //  Internal flag to tell if an algorithm is running
  reg        ReadyBusy ;

  //  Flag to represent if the chip is write suspended
  reg        WriteSuspended ;
  //  Flag to represent if the chip is erase suspended
  reg        EraseSuspended ;
  //  Flag to represent the chip should be suspended
  reg        Suspend ;
  //  Variable to hold which algorithm (program or erase)
  //  is to be suspended
  reg [1:0]  ToBeSuspended;

  // Array to hold block lock-bit information
  reg        BlockLockBit[`NumberOfBlocks-1:0];
  // Variable for block number to be locked
  integer    WhichBlock;
  // Flag to represent state of master lock-bit
  reg        MasterLock;

  //  Algorithm Timer
  reg        TimerClk ;

  //  Flag to show the running algorithm is done.
  reg        AlgDone ;

  // Number of timer cycles remaining for the
  // current algorithm
  integer    AlgTime;

  // Number of timer cycles remaining for erase operation
  // when erase suspended and program operation in progress
  integer    TimeLeft;

  // Generic temporary varible
  integer    LoopCntr ;
  reg        Other ;

  //Block begin and end address
  reg [`AddrSize-1:0] BlocksBegin[0:`NumberOfBlocks-1];
  reg [`AddrSize-1:0] BlocksEnd[0:`NumberOfBlocks-1];
  reg [31:0]  BlocksEraseCount[0:`NumberOfBlocks-1];

  // states the flash is in a cycle
  reg     flash_cycle;


  //**********************************************************************
  //TIMING VALUES
  //**********************************************************************

  time    ToOut ;
  time    last_addr_time ,curr_addr_time;
  time    last_oe_time, curr_oe_time;
  time    last_ce_time, curr_ce_time;
  time    last_rp_time, curr_rp_time;
  time    last_ReadMode_time, curr_ReadMode_time ;
  time    last_Internal_RE_time, curr_Internal_RE_time ;
  time    last_Internal_WE_time, curr_Internal_WE_time ;
  time    last_dq_time ,curr_dq_time;
  time    last_rpb_time, curr_rpb_time ;
  time    WriteRecovery ;
  time    TempTime;

  time    Program_Time_Byte;
  time    Block_Erase_Time;
  time    Set_LockBit_Time;
  time    Clear_LockBit_Time;
  time    Program_Suspend_Time;  // latency time
  time    Erase_Suspend_Time;    // latency time

  //**********************************************************************
  //input configuration

  parameter
      LoadOnPowerup   = 1,          //load array from file
`ifdef DAMJAN
      LoadFileName    = "../src/damjan_flash.in",  //File to load array with
`else
      LoadFileName    = "flash.in",  //File to load array with
`endif
      SaveOnPowerdown = `TRUE,         //save array to file
      SaveFileName    = "flash.temp.out"; //save file name

  //TIMING PARAMETERS
  integer
      TAVAV       ,
      TPHQV       ,
      TELQV       ,
      TGLQV       ,
      TAVQV       ,
      TGLQX       ,
      TGHQZ       ,
      TEHQZ       ,
      TOH         ,
      TWPH        ,
      TWP         ,
      TPHWL       ,
      TPHHWH      ,
      TAVWH       ,
      TDVWH       ,
      TWHDX       ,
      TWHAX       ,
      TimerPeriod ;


  //**********************************************************************

  initial begin
      flash_cycle      =      0     ;
      Other               =       `FALSE  ;
      AlgDone             =       `FALSE  ;
      Reset               =        1'bx   ;
      Reset               <=      `TRUE   ;
      StartUpFlag         =       `TRUE   ;
      StartUpFlag         <=  #2  `FALSE  ;
      DriveOutputs        =       `FALSE  ;
      ToOut               =        0      ;
      VppError            =       `FALSE  ;
      VppErrFlag          =       `FALSE  ;
      ClearVppFlag        =       `FALSE  ;
      VppFlag             =       `FALSE  ;
      WriteSuspended      =       `FALSE  ;
      EraseSuspended      =       `FALSE  ;
      Suspend             =       `FALSE  ;
      ToBeSuspended       =       `Program;
      MasterLock          =       `Unlocked;
      Erase_ClearLBError  =       `FALSE  ;
      Protected           =       `FALSE  ;
      TimerClk            =        1'b0   ;
      ArrayOut            =       `MaxOutputs'hxx ;
      CSROut              =        0      ;
      IDOut               =        0      ;
      CmdValid            =       `FALSE  ;
      WriteToPtr          =       `NewCmd ;
      last_addr_time      =        0      ;
      curr_addr_time      =        0      ;
      last_ce_time        =        0      ;
      curr_ce_time        =        0      ;
      last_oe_time        =        0      ;
      curr_oe_time        =        0      ;
      last_rp_time        =        0      ;
      curr_rp_time        =        0      ;
      last_ReadMode_time  =        0      ;
      curr_ReadMode_time  =        0      ;
      last_dq_time        =        0      ;
      curr_dq_time        =        0      ;
      last_rpb_time       =        0      ;
      curr_rpb_time       =        0      ;
      WriteRecovery       =        0      ;
      last_Internal_RE_time =      0      ;
      curr_Internal_RE_time =      0      ;
      InternalOutput        =     `MaxOutputs'hxx ;
      last_Internal_WE_time =      0      ;
      curr_Internal_WE_time =      0      ;
      Program_Time_Byte    = `AC_ProgramTime_Byte_50_12 ;
      Block_Erase_Time     = `AC_EraseTime_Block_50_12;
      Set_LockBit_Time     = `AC_Set_LockBit_50_12;
      Clear_LockBit_Time   = `AC_Clear_LockBit_50_12;
      Program_Suspend_Time = `AC_Program_Suspend_50_12;
      Erase_Suspend_Time   = `AC_Erase_Suspend_50_12;

      $readmemh(`BlockFileBegin,BlocksBegin);
      $readmemh(`BlockFileEnd,BlocksEnd);

      for (LoopCntr = 0; LoopCntr <= `NumberOfBlocks; LoopCntr = LoopCntr
  + 1) begin
        BlocksEraseCount [LoopCntr] = 0 ;
      end

      for (LoopCntr = 0; LoopCntr < `NumberOfBlocks; LoopCntr = LoopCntr
  + 1) begin
        BlockLockBit[LoopCntr] = `Unlocked;
      end
  //--------------------------------------------------------------------
  // Array Init
  //--------------------------------------------------------------------

  //Constant condition expression: LoadOnPowerup == 1'b1
    if (LoadOnPowerup)
      LoadFromFile;
    else begin
      $display("%m:: Initializing Memory to 'hFF");
      for (LoopCntr = 0; LoopCntr <= `MaxAddr; LoopCntr = LoopCntr + 1) begin
        MainArray [LoopCntr] = 8'hFF ;
      end
    end
  end  //initial

  //--------------------------------------------------------------------
  // LoadFromFile
  //  This is used when the LoadOnPowerup parameter is set so that the
  //  Main array contains code at startup.  Basically it loads the array
  //  from data in a file (LoadFileName).
  //--------------------------------------------------------------------

  task LoadFromFile ;
    begin
      $display("[%m]:: Loading from file %s",LoadFileName);
      $readmemh(LoadFileName,MainArray);
    end
  endtask

  //--------------------------------------------------------------------
  // StoreToFile
  //  This is used when the SaveOnPowerDown flag is set so that the Main
  //  Array stores code at powerdown.  Basically it stores the array into
  //  a file (SaveFileName).
  //--------------------------------------------------------------------

  task  StoreToFile;
    reg [31:0]  ArrayAddr ;
    reg [31:0]  outfile ;
    begin
      outfile = $fopen(SaveFileName) ;
      if (outfile == 0)
        $display("%m:: Error, cannot open output file %s",SaveFileName) ;
      else
        $display("%m:: Saving data to file %s",SaveFileName);
      for (ArrayAddr = 0 ; ArrayAddr <= `MaxAddr; ArrayAddr = ArrayAddr
  + 1) begin
        $fdisplay(outfile,"%h",MainArray[ArrayAddr]);
      end
    end
  endtask

  //--------------------------------------------------------------------
  // Program
  //  Description: Programs new values in to the array
  //--------------------------------------------------------------------

  task  Program ;
    inout  [`Byte] TheArrayValue ;
    input  [`Byte] DataIn  ;

    reg    [`Byte] OldData;
    begin
      OldData = TheArrayValue;
      TheArrayValue = DataIn & OldData;
    end
  endtask

  assign  Internal_OE  = !(ceb | oeb | !rpb) ;
  assign  Internal_OE2 = Internal_OE ;
  assign  Internal_OE3 = Internal_OE2 ;
  assign  Internal_RE  = (((ReadyBusy == `Ready) || (ReadMode != `rdARRAY))
  && !ceb && !Reset) ;
  assign  Internal_WE  = !(ceb | web | !rpb) ;

  // register definitions //

  // Compatible Status Register
  assign  CSR [7] = ReadyBusy;
  assign  CSR [6] = EraseSuspended ;
  assign  CSR [5] = Erase_ClearLBError ;
  assign  CSR [4] = Program_SetLBError ;
  assign  CSR [3] = VppError ;
  assign  CSR [2] = WriteSuspended ;
  assign  CSR [1] = Protected ;
  assign  CSR [0] = 1'b0 ;

  // Output Drivers //
  assign dq[7:0] = (DriveOutputs == `TRUE) ? InternalOutput : 8'hz ;

  always @(Reset) begin : Reset_process
    if (Reset) begin
      ClearVppFlag    <=  #1  `TRUE   ;
      ClearVppFlag    <=  #9  `FALSE  ;
      AlgDone          =      `FALSE  ;
      VppError         =      `FALSE  ;
      ReadMode         =      `rdARRAY;
      ReadyBusy        =      `Ready  ;
      WriteSuspended   =      `FALSE  ;
      EraseSuspended   =      `FALSE  ;
      Suspend          =      `FALSE  ;
      Erase_ClearLBError  =   `FALSE  ;
      Program_SetLBError  =   `FALSE  ;
      Protected        =      `FALSE  ;
      AlgTime          =       0      ;
      CmdValid         =      `FALSE  ;
      WriteToPtr       =      `NewCmd ;
      CSROut           =       0      ;
      IDOut            =       0      ;
    end
  end


  always @(Internal_RE or ReadMode or addr) begin : array_read
    if (Internal_RE && ReadMode == `rdARRAY)
      ArrayOut  = MainArray[addr] ;      // x8 outputs
  end

  always @(Internal_RE or ReadMode or addr or Internal_OE2) begin
    // output mux
    // Determine and generate the access time .
    ToOut = 0;
    if ($time > TAVQV) begin
      last_addr_time = $time - curr_addr_time;
      if ((last_addr_time < TAVQV) && ((TAVQV - last_addr_time) > ToOut))
        ToOut = TAVQV - last_addr_time ;
      last_oe_time = $time - curr_oe_time;
      if ((last_oe_time < TGLQV) && ((TGLQV - last_oe_time) > ToOut))
        ToOut = TGLQV - last_oe_time ;
      last_ce_time = $time - curr_ce_time;
      if ((last_ce_time < TELQV) && ((TELQV - last_ce_time) > ToOut))
        ToOut = TELQV - last_ce_time ;
      last_rp_time = $time - curr_rp_time;
      if ((last_rp_time < TPHQV) && ((TPHQV - last_rp_time) > ToOut))
        ToOut = TPHQV - last_rp_time ;
      last_ReadMode_time = $time - curr_ReadMode_time;
      if ((last_ReadMode_time < TAVQV) && ((TAVQV - last_ReadMode_time) >
  ToOut))
        ToOut = TAVQV - last_ReadMode_time ;
      last_Internal_RE_time = $time - curr_Internal_RE_time ;
      if ((last_Internal_RE_time < TAVQV) && ((TAVQV - last_Internal_RE_time)
  > ToOut))
        ToOut = TAVQV - last_Internal_RE_time ;
    end  // if

    //  Output Mux with timing
    if (!StartUpFlag) begin
      case (ReadMode)
       `rdARRAY : begin
          if ( (EraseSuspended == `TRUE) && (WriteSuspended == `FALSE)
               && (addr >= BlocksBegin[Algorithm[`OpBlock]])
               && (addr <= BlocksEnd[Algorithm[`OpBlock]]) && (oeb ==
  `VIL) ) begin
            $display("%m:: Error:  Attempting to read from erase suspended block");
            InternalOutput <= `MaxOutputs'hxx;
          end
          else if ( (EraseSuspended == `TRUE) && (WriteSuspended == `TRUE)
                    && (oeb == `VIL) && (addr >=
  BlocksBegin[SuspendedAlg[`OpBlock]])
                    && (addr <= BlocksEnd[SuspendedAlg[`OpBlock]]) ) begin
            $display("%m:: Error:  Attempting to read from erase suspended block.");
            InternalOutput <= `MaxOutputs'hxx;
          end
          else if ( (WriteSuspended == `TRUE) && (addr == Algorithm[`CmdAdd_1])
                    && (oeb == `VIL) ) begin
            $display("%m:: Error:  Attempting to read from write suspended address");
            InternalOutput <= `MaxOutputs'hxx;
          end
          else
            InternalOutput <= #ToOut ArrayOut ;
        end
       `rdCSR   : begin
          InternalOutput <= #ToOut CSROut ;
        end
       `rdID    :  begin
          InternalOutput <= #ToOut IDOut ;
        end
        default  :  begin
          $display("[%t]%m:: Error: illegal readmode", $time);
        end
      endcase
    end  // if
  end  // always

  //
  // other reads
  //
  always @(Internal_OE or addr) begin : other_read
    if (!Reset) begin
      if (ReadMode != `rdARRAY) begin
        CSROut = CSR ;
        if (addr[1:0] == 2'b00)
          IDOut = `ID_ManufacturerB ;
        else if (addr[1:0] == 2'b01)
          IDOut = `ID_DeviceCodeB ;
        else if (addr[1:0] == 2'b10) begin
          for (LoopCntr = `NumberOfBlocks-1; LoopCntr >= 0; LoopCntr = LoopCntr
  -
  1)
            if (addr <= BlocksEnd[LoopCntr])
             WhichBlock = LoopCntr;
          IDOut = BlockLockBit[WhichBlock];
        end
        else
          IDOut = MasterLock;
      end
    end
  end

  // Handle Write to Part

  always @(negedge Internal_WE) begin : handle_write

    reg [`Byte]   temp ;  // temporary variable needed for double
                          // indexing CmdData.
    if (!Reset) begin
      case (WriteToPtr)             // Where are we writting to ?
       `NewCmd : begin              // This is a new command.
         Cmd[`Cmd] = dq[7:0] ;
         Cmd[`Add] = addr[`AddrSize-1:0] ;
         CmdValid <= `TRUE ; // CmdValid sends it to the Predecode section
         DataPtr <= -1 ;
       end
       `CmdField : begin   // This is data used by another command
         if (DataPtr == 1) begin
           Cmd[`CmdData_1] = dq[`Byte];
           Cmd[`CmdAdd_1] = addr [`AddrSize-1:0] ;
         end
         else if (DataPtr == 2) begin
           Cmd[`CmdData_2] = dq[`Byte];
           Cmd[`CmdAdd_2] = addr[`AddrSize-1:0] ;
         end
         else
           $display("%m:: DataPtr out of range") ;
         DataPtr <= #1 DataPtr - 1 ;  // When DataPtr hits zero the command
       end
       default    :   begin
         $display("%m:: Error: Write To ? Cmd");
       end
      endcase
    end  //if
  end  //always

  //
  // Predecode Command
  //
  always @(posedge CmdValid) begin : predecode
    reg [`Byte] temp;       // temporary variable needed for double
                            // indexing BSR.
    if (!Reset) begin
      // Set Defaults
      Cmd [`OpType] = `Program ;
      WriteToPtr = `NewCmd ;
      DataPtr <= 0 ;
      case (Cmd [`Cmd])          // Handle the basic read mode commands

       // READ ARRAY COMMAND --

       `ReadArrayCmd  : begin    // Read Flash Array
         CmdValid <= `FALSE ;
         if (ReadyBusy == `Busy) // Can not read array when running an algorithm
           ReadMode <= `rdCSR ;
         else
           ReadMode <= `rdARRAY ;
       end

       // READ INTELLIGENT IDENTIFIER COMMAND --

       `ReadIDCmd     :  begin   // Read Intelligent ID
         if ( (WriteSuspended == `TRUE) || (EraseSuspended == `TRUE) )
           $display("%m:: Invalid read ID command during suspend");
         else
           ReadMode <= `rdID ;
         CmdValid <= `FALSE ;
       end

        // READ COMPATIBLE STATUS REGISTER COMMAND --

        `ReadCSRCmd  : begin    // Read CSR
          ReadMode <= `rdCSR ;
          CmdValid <= `FALSE ;
        end
       default  : begin
          Other = `TRUE ;            // Other flag marks commands that are algorithms
          Cmd [`Confirm] = `FALSE  ; // Defaults
         case (Cmd [`Cmd])

          // PROGRAM BYTE COMMAND --

          `ProgramCmd : begin                              // Program Byte
            if (WriteSuspended == `TRUE) begin
              $display("%m:: Error:  Program Command during Write Suspend");
              CmdValid <= `FALSE;
            end
            else begin
              WriteToPtr = `CmdField  ;
              DataPtr <= 1  ;
              if (EraseSuspended == `TRUE) begin
                TimeLeft = AlgTime;
                SuspendedAlg = Algorithm;
              end
              ToBeSuspended = `Program;
            end
          end

            // PROGRAM BYTE COMMAND --

          `Program2Cmd  : begin       // Program Byte
            if (WriteSuspended == `TRUE) begin
              $display("%m:: Error:  Program Command during Write Suspend");
              CmdValid <= `FALSE;
            end
            else begin
              Cmd [`Cmd] = `ProgramCmd ;
              WriteToPtr = `CmdField ;
              DataPtr <= 1 ;
              if (EraseSuspended == `TRUE) begin
                TimeLeft = AlgTime;
                SuspendedAlg = Algorithm;
              end
              ToBeSuspended = `Program;
            end
          end

            // ERASE BLOCK COMMAND --

          `EraseBlockCmd : begin    // Single Block Erase
            if ( (WriteSuspended == `TRUE) || (EraseSuspended == `TRUE) ) begin
              $display("%m:: Attempted to erase block while suspended");
              CmdValid <= `FALSE;
            end
            else begin
              WriteToPtr = `CmdField ;
              DataPtr <= 1 ;
              Cmd [`OpType] = `Erase ;
              Cmd [`Confirm] = `TRUE ;
              ToBeSuspended = `Erase;
            end
          end

            // LOCK BIT COMMAND

          `LBSetupCmd : begin
            if ( (WriteSuspended == `TRUE) || (EraseSuspended == `TRUE) ) begin
              $display("%m:: Attempted to set lock-bit while suspended");
              CmdValid <= `FALSE;
            end
            else begin
              WriteToPtr = `CmdField ;
              DataPtr <= 1 ;
              Cmd [`OpType] = `Lock ;
            end
          end

          default : begin  // The remaining commands are complex
                           // non-algorithm commands
              Other = `FALSE ;
              CmdValid = `FALSE ;

              // CLEAR STATUS REGISTER COMMAND

              if (Cmd [`Cmd] == `ClearCSRCmd) begin
                if (EraseSuspended | WriteSuspended)
                  ReadMode <= `rdARRAY ;
                else if (ReadyBusy == `Busy)
                  ReadMode <= `rdCSR ;
                else begin
                  Erase_ClearLBError <= `FALSE ;
                  Program_SetLBError <= `FALSE ;
                  VppError <= `FALSE ;
                  Protected <= `FALSE;
                  ReadMode <= `rdCSR ;
                end
              end

              // RESUME COMMAND --

            else if (Cmd [`Cmd] == `ResumeCmd) begin
              if (WriteSuspended | EraseSuspended)
                ReadMode <= `rdCSR ;
              Suspend = `FALSE ;
              if (ToBeSuspended == `Program)
                WriteSuspended <= `FALSE ;
              else
                EraseSuspended <= `FALSE ;
              ReadyBusy = `Busy;
            end

            // SUSPEND COMMAND --

            else if (Cmd [`Cmd] == `SuspendCmd) begin
              if (ReadyBusy == `Ready) begin
                ReadMode <= `rdARRAY ;
                $display("%m:: Algorithm finished; nothing to suspend");
              end
              else begin
                ReadMode <= `rdCSR ;
                Suspend = `TRUE ;
              end
              CmdValid <= `FALSE ;
            end
            else begin
              CmdValid <= `FALSE ;
              $display("%m:: Warning:Illegal Command");
            end
          end  //default
         endcase
       end  //default
      endcase
    end  //if
  end  //always (predecode)

  //
  // Command Decode
  //

  always @(DataPtr) begin : command

    integer BlockUsed;

    if (!Reset && (DataPtr == 0) && (WriteToPtr != `NewCmd)) begin
     // When DataPtr hits zero it means that all the
     // additional data has been given to the current command
      if (CmdValid && (WriteToPtr == `CmdField)) begin
        WriteToPtr = `NewCmd;
        // Just finish a multi-cycle command.  Determine which block the command uses
        BlockUsed = -1;
        for (LoopCntr = `NumberOfBlocks-1; LoopCntr >= 0; LoopCntr =
  LoopCntr - 1) begin
          if (Cmd[`CmdAdd_1] <= BlocksEnd[LoopCntr])
            BlockUsed = LoopCntr;
        end
        if (BlockUsed == -1)
          $display("%m:: Error:  Invalid Command Address");
        else
          Cmd [`OpBlock] = BlockUsed;
        if (Cmd [`OpType] ==  `Erase )
          Cmd [`Time] = Block_Erase_Time ;
        else if (Cmd [`OpType] == `Program )
          Cmd [`Time] = Program_Time_Byte;
        else
          Cmd [`Time] = 0;

        // If this command needs a confirm
        // (flaged at predecode) then check if confirm was received
        if (Cmd [`Confirm]) begin
          if (Cmd[`CmdData_1] == `ConfirmCmd) begin
          // If the command is still valid put it in the queue and deactivate the array
            Algorithm = Cmd;
            AlgTime = Cmd [`Time] ;
            CmdValid <= `FALSE;
            if (!VppError)
              ReadyBusy <= #1 `Busy ;
            ReadMode <= `rdCSR;
          end
          else begin
            ReadMode <= `rdCSR ;
            Program_SetLBError <= `TRUE;
            Erase_ClearLBError <= `TRUE;
            CmdValid <= `FALSE;
          end
        end
        else begin
          Algorithm = Cmd;
          AlgTime = Cmd [`Time] ;
          CmdValid <= `FALSE;
          if (!VppError)
            ReadyBusy <= #1 `Busy ;
          ReadMode <= `rdCSR;
        end
      end
    end
  end  //always (command)

  ///////////////
  // Execution //
  ///////////////
  always @(posedge AlgDone)  begin : execution
    reg   [`Byte]   temp ;  // temporary variable needed for double indexing BSR.
    if (!Reset) begin
      if (AlgDone) begin  // When the algorithm finishes
                          // if chips is executing during an erase interrupt
                          // then execute out of queue slot 2
        if (Algorithm [`OpType] == `Erase) begin

         // ERASE COMMAND //
          if (VppFlag) begin
         $display("%m:: Vpp Error occured");
            VppError <= `TRUE ;
            Erase_ClearLBError <= `TRUE;
          end
          else begin
            // Do ERASE to OpBlock
            if ((BlockLockBit[Algorithm[`OpBlock]] == `Locked)
                && (rpblevel != `rpb_vhh)) begin
              $display("%m:: Error: Attempted to erase locked block");
              Erase_ClearLBError <= `TRUE;
              Protected <= `TRUE;
            end
            else begin
              for (LoopCntr = BlocksBegin[Algorithm[`OpBlock]];
                   LoopCntr <= BlocksEnd[Algorithm[`OpBlock]]; LoopCntr
  = LoopCntr + 1)
                MainArray [LoopCntr] = 'hFF ;
              BlocksEraseCount[Algorithm[`OpBlock]] =
  BlocksEraseCount[Algorithm[
  `OpBlock]] + 1;
              $display("%m:: Block %d Erase Count: %d", Algorithm[`OpBlock],
  BlocksEraseCount[Algorithm[`OpBlock]]);
            end
          end
        end  //ERASE COMMAND
        else if (Algorithm [`OpType] == `Program) begin

          // PROGRAM COMMAND //
       $display("%m:: PROGRAM COMMAND:");
       $display("%m::     VppFlag=", VppFlag);
       $display("%m::     BlockLockBit=", BlockLockBit [Algorithm[`OpBlock]]);
       $display("%m::     rpblevel=",rpblevel);

          if (VppFlag) begin
         $display("%m:: VppFlag set, do program of byte aborted!");
            Program_SetLBError <= `TRUE;
            VppError <= `TRUE ;
          end
          else begin
            if ((BlockLockBit [Algorithm[`OpBlock]] == `Locked)
                && (rpblevel != `rpb_vhh)) begin
              $display("%m:: Error: Attempted to program locked block.");
              Program_SetLBError <= `TRUE;
              Protected <= `TRUE;
            end
            else begin
           $display("%m:: calling program task");
              Program (MainArray[Algorithm [`CmdAdd_1]], Algorithm [`CmdData_1])
  ;
              if (EraseSuspended == `TRUE) begin
                AlgTime = TimeLeft;
                ToBeSuspended = `Erase;
                Algorithm = SuspendedAlg;
              end
            end
          end
        end  // PROGRAM COMMAND
        else if (Algorithm [`OpType] == `Lock) begin

          // LOCK BIT COMMANDS

          if (Algorithm [`CmdData_1] == `SetBlockLBCmd) begin
            if ( ((MasterLock == `Locked) && (rpblevel  != `rpb_vhh)) ||
                 ((rpblevel != `rpb_vih) && (rpblevel != `rpb_vhh)) ) begin
              Program_SetLBError = `TRUE;
              Protected = `TRUE;
              $display("%m:: Attempted to set locked block lock-bit");
            end
            else begin
              #Set_LockBit_Time
              BlockLockBit [Algorithm[`OpBlock]] = `Locked;
            end
          end
          else if (Algorithm [`CmdData_1] == `SetMasterLBCmd) begin
            if (rpblevel == `rpb_vhh)
              MasterLock = `Locked;
            else begin
              Program_SetLBError = `TRUE;
              Protected = `TRUE;
              $display("%m:: Attempted to set master lock-bit with invalid RP# level");
            end
          end //SetMasterLBCmd
          else if (Algorithm [`CmdData_1] == `ClearLBCmd) begin
            if ( ((MasterLock == `Locked) && (rpblevel  != `rpb_vhh)) ||
                 ((rpblevel != `rpb_vih) && (rpblevel != `rpb_vhh)) ) begin
              Erase_ClearLBError = `TRUE;
              Protected = `TRUE;
              $display("%m:: Attempted to clear lock-bits while master lock-bit set");
            end
            else begin
              #Clear_LockBit_Time
              for (LoopCntr = 0; LoopCntr < `NumberOfBlocks; LoopCntr = LoopCntr + 1) begin
                BlockLockBit[LoopCntr] = `Unlocked;
              end
            end
          end  //ClearLBCmd
          else begin
            $display("%m:: Invalid lock-bit configuration command sequence");
            Erase_ClearLBError = `TRUE;
            Program_SetLBError = `TRUE;
          end
        end  //LOCK BIT COMMANDS
        else
          $display("%m:: Invalid algorithm operation type");
      end  //if (AlgDone)
      ReadyBusy <= `Ready ;
    end  //if (!Reset)
  end  //always (execution)

  always @(ReadyBusy) begin
    if ((!Reset) && (ReadyBusy  == `Busy)) begin  // If the algorithm engine
                                                  // just started, start the clock

      ClearVppFlag <= #1 `TRUE ;
      ClearVppFlag <= #3 `FALSE ;
      TimerClk <= #1 1'b1 ;
      TimerClk <= #TimerPeriod 1'b0 ;
    end
  end

  // record the time for addr changes from ADDR change to posedge CEB.
  always @(addr or posedge ceb) begin
       if ($time != 0 & flash_cycle & ceb) begin
          if ((curr_addr_time + TAVAV) > $time)    //Read/Write Cycle Time
          $display("[",$time,"]%m:: Timing Violation: Read/Write Cycle Time (TAVAV), Last addr change: %d",curr_addr_time) ;
       end
       curr_addr_time = $time ;
       flash_cycle = ~ceb;
  end

  // start of flash cycle
  always @(negedge ceb) begin
       flash_cycle = 1;
  end

  // record the time for oe changes .
  always @(oeb) begin
    if ($time != 0) begin
      curr_oe_time = $time ;
    end
  end

  // record the time for ce changes .
  always @(ceb) begin
    if ($time != 0) begin
      curr_ce_time = $time ;
    end
  end

  // record the time for rp changes .
  always @(rpb) begin
    if ($time != 0) begin
      curr_rp_time = $time ;
    end
  end

  // record the time for ReadMode changes .
  always @(ReadMode) begin
    if ($time != 0) begin
      curr_ReadMode_time = $time ;
    end
  end

  // record the time for Internal_RE changes .
  always @(Internal_RE) begin
    if ($time != 0) begin
      curr_Internal_RE_time = $time ;
    end
  end

  //always @(InternalBoot) begin
  //  InternalBoot_WE <= #TPHHWH InternalBoot;
  //end

  always @(TimerClk) begin
    if ((!Reset) && (ReadyBusy == `Busy) && (TimerClk == 1'b0)) begin
      // Reschedule clock and decrement algorithm count
      TimerClk <= #1 1'b1 ;
      TimerClk <= #TimerPeriod 1'b0 ;
      if (Suspend) begin   // Is the chip pending suspend? If so do it
        Suspend = `FALSE;
        if (ToBeSuspended == `Program) begin
          WriteSuspended <= #Program_Suspend_Time `TRUE;
          ReadyBusy <= #Program_Suspend_Time `Ready;
        end
        else begin
          EraseSuspended <= #Erase_Suspend_Time `TRUE;
          ReadyBusy <= #Erase_Suspend_Time `Ready;
        end
      end
      if (ReadyBusy == `Busy) begin
        AlgTime = AlgTime - 1;
        if (AlgTime <= 0) begin // Check if the algorithm is done
          AlgDone <= #1 `TRUE ;
          AlgDone <= #10 `FALSE ;
        end
      end
    end
  end

  //------------------------------------------------------------------------
  //  Reset Controller
  //------------------------------------------------------------------------

  always @(rpb or vcc) begin : ResetPowerdownMonitor
    // Go into reset if reset powerdown pin is active or
    // the vcc is too low
    if ((rpb != `VIH) || (vcc < 2500)) begin // Low Vcc protection
      Reset <= `TRUE ;
      if (!((vcc >= 2500) || StartUpFlag))
        $display ("%m:: Low Vcc: Chip Resetting") ;
    end
    else
      // Coming out of reset takes time
      Reset <= #TPHWL  `FALSE ;
  end

  //------------------------------------------------------------------------
  // VccMonitor
  //------------------------------------------------------------------------

  always @(Reset or vcc) begin : VccMonitor
    // Save the array when chip is powered off
    if ($time > 0) begin
      if (vcc == 0 && SaveOnPowerdown)
        StoreToFile;
      if (vcc < 2700)
        $display("%m:: Vcc is below minimum operating specs");
      else if ((vcc >= 2700) && (vcc <= 3600)) begin
        if ((vcc >= 3000) && (vcc <= 3600) && (`VccLevels & `Vcc3300)) begin
          $display ("%m:: Vcc is in operating range for 3.3 volt mode") ;
          ReadOnly    =   `FALSE    ;
          TAVAV       =   121 ;
          TAVAV       =   `TAVAV_33 ;
          TPHQV       =   `TPHQV_33 ;
          TELQV       =   `TELQV_33 ;
          TGLQV       =   `TGLQV_33 ;
          TAVQV       =   `TAVQV_33 ;
          TGLQX       =   `TGLQX_33 ;
          TGHQZ       =   `TGHQZ_33 ;
          TEHQZ       =   `TEHQZ_33 ;
          TOH         =   `TOH_33   ;
          TWPH        =   `TWPH_33  ;
          TWP         =   `TWP_33   ;
          TPHWL       =   `TPHWL_33 ;
          TPHHWH      =   `TPHHWH_33;
          TAVWH       =   `TAVWH_33 ;
          TDVWH       =   `TDVWH_33 ;
          TWHDX       =   `TWHDX_33 ;
          TWHAX       =   `TWHAX_33 ;
       TimerPeriod =   `TimerPeriod_ ;
          if ((vpp <= 3600) && (vpp >= 3000)) begin
            $display ("%m:: Vpp is in operating range for 3.3 volt mode") ;
            Block_Erase_Time     = `AC_EraseTime_Block_33_33;
            Clear_LockBit_Time   = `AC_Clear_LockBit_33_33;
            Program_Time_Byte    = `AC_ProgramTime_Byte_33_33;
            Set_LockBit_Time     = `AC_Set_LockBit_33_33;
            Program_Suspend_Time = `AC_Program_Suspend_33_33;
            Erase_Suspend_Time   = `AC_Erase_Suspend_33_33;
          end
          else if ((vpp <= 5500) && (vpp >= 4500)) begin
            $display ("%m:: Vpp is in operating range for 5.0 volt mode") ;
            Block_Erase_Time     = `AC_EraseTime_Block_33_5;
            Program_Time_Byte    = `AC_ProgramTime_Byte_33_5;
            Set_LockBit_Time     = `AC_Set_LockBit_33_5;
            Clear_LockBit_Time   = `AC_Clear_LockBit_33_5;
            Program_Suspend_Time = `AC_Program_Suspend_33_5;
            Erase_Suspend_Time   = `AC_Erase_Suspend_33_5;
          end
          else begin
            $display ("%m:: Vpp is in operating range for 12.0 volt mode") ;
            Block_Erase_Time     = `AC_EraseTime_Block_33_12;
            Program_Time_Byte    = `AC_ProgramTime_Byte_33_12;
            Set_LockBit_Time     = `AC_Set_LockBit_33_12;
            Clear_LockBit_Time   = `AC_Clear_LockBit_33_12;
            Program_Suspend_Time = `AC_Program_Suspend_33_12;
            Erase_Suspend_Time   = `AC_Erase_Suspend_33_12;
          end
        end
        else if (`VccLevels & `Vcc2700) begin
          $display ("%m:: Vcc is in operating range for 2.7 volt mode -- read only")
  ;
          ReadOnly    =   `TRUE     ;
          TAVAV       =   `TAVAV_27 ;
          TPHQV       =   `TPHQV_27 ;
          TELQV       =   `TELQV_27 ;
          TGLQV       =   `TGLQV_27 ;
          TAVQV       =   `TAVQV_27 ;
          TGLQX       =   `TGLQX_27 ;
          TGHQZ       =   `TGHQZ_27 ;
          TEHQZ       =   `TEHQZ_27 ;
          TOH         =   `TOH_27   ;
          TWPH        =   `TWPH_27  ;
          TWP         =   `TWP_27   ;
          TPHWL       =   `TPHWL_27 ;
          TPHHWH      =   `TPHHWH_27;
          TAVWH       =   `TAVWH_27 ;
          TDVWH       =   `TDVWH_27 ;
          TWHDX       =   `TWHDX_27 ;
          TWHAX       =   `TWHAX_27 ;
       TimerPeriod =   `TimerPeriod_ ;
        end
        else
          $display("%m:: Invalid Vcc Level");
      end
      else if ((vcc >= 4500) && (vcc <= 5500) && (`VccLevels & `Vcc5000)) begin
        $display ("%m:: Vcc is in operating range for 5 volt mode") ;
        ReadOnly    =   `FALSE    ;
        TAVAV       =   `TAVAV_50 ;
        TPHQV       =   `TPHQV_50 ;
        TELQV       =   `TELQV_50 ;
        TGLQV       =   `TGLQV_50 ;
        TAVQV       =   `TAVQV_50 ;
        TGLQX       =   `TGLQX_50 ;
        TGHQZ       =   `TGHQZ_50 ;
        TEHQZ       =   `TEHQZ_50 ;
        TOH         =   `TOH_50   ;
        TWPH        =   `TWPH_50  ;
        TWP         =   `TWP_50   ;
        TPHWL       =   `TPHWL_50 ;
        TPHHWH      =   `TPHHWH_50;
        TAVWH       =   `TAVWH_50 ;
        TDVWH       =   `TDVWH_50 ;
        TWHDX       =   `TWHDX_50 ;
        TWHAX       =   `TWHAX_50 ;
        TimerPeriod =   `TimerPeriod_ ;
        if ((vpp <= 5500) && (vpp >= 4500)) begin
          Block_Erase_Time     = `AC_EraseTime_Block_50_5;
          Program_Time_Byte    = `AC_ProgramTime_Byte_50_5;
          Set_LockBit_Time     = `AC_Set_LockBit_50_5;
          Clear_LockBit_Time   = `AC_Clear_LockBit_50_5;
          Program_Suspend_Time = `AC_Program_Suspend_50_5;
          Erase_Suspend_Time   = `AC_Erase_Suspend_50_5;
        end
        else begin
          Block_Erase_Time     = `AC_EraseTime_Block_50_12;
          Program_Time_Byte    = `AC_ProgramTime_Byte_50_12;
          Set_LockBit_Time     = `AC_Set_LockBit_50_12;
          Clear_LockBit_Time   = `AC_Clear_LockBit_50_12;
          Program_Suspend_Time = `AC_Program_Suspend_50_12;
          Erase_Suspend_Time   = `AC_Erase_Suspend_50_12;
        end
      end
      else
        $display ("%m:: Vcc is out of operating range") ;
    end //$time
  end  //always (VccMonitor)

  //------------------------------------------------------------------------
  // VppMonitor
  //------------------------------------------------------------------------
  always @(VppFlag or ClearVppFlag or vpp) begin : VppMonitor
    if (ClearVppFlag) begin
      VppErrFlag = `FALSE ;
    end
    else
      if (!( ((vpp <= 12600) && (vpp >= 11400)) || ((vpp <= 5500) &&
  (vpp >= 4500))
             || ((vpp <= 3600) && (vpp >= 3000)))) begin
        VppErrFlag = `TRUE ;
      end
    if ((vpp <= 3600) && (vpp >= 3000)) begin
      if ((vcc <= 3600) && (vcc >= 3000)) begin
        Block_Erase_Time      = `AC_EraseTime_Block_33_33;
        Clear_LockBit_Time    = `AC_Clear_LockBit_33_33;
        Program_Time_Byte     = `AC_ProgramTime_Byte_33_33;
        Set_LockBit_Time      = `AC_Set_LockBit_33_33;
        Program_Suspend_Time  = `AC_Program_Suspend_33_33;
        Erase_Suspend_Time    = `AC_Erase_Suspend_33_33;
      end
      else
        VppErrFlag = `TRUE;
    end
    else if ((vpp <= 5500) && (vpp >= 4500)) begin
      if ((vcc <= 3600) && (vcc >= 3000)) begin
        Block_Erase_Time     = `AC_EraseTime_Block_33_5;
        Program_Time_Byte    = `AC_ProgramTime_Byte_33_5;
        Set_LockBit_Time     = `AC_Set_LockBit_33_5;
        Clear_LockBit_Time   = `AC_Clear_LockBit_33_5;
        Program_Suspend_Time = `AC_Program_Suspend_33_5;
        Erase_Suspend_Time   = `AC_Erase_Suspend_33_5;
      end
      else if ((vcc <= 5500) && (vcc >= 4500)) begin
        Block_Erase_Time     = `AC_EraseTime_Block_50_5;
        Program_Time_Byte    = `AC_ProgramTime_Byte_50_5;
        Set_LockBit_Time     = `AC_Set_LockBit_50_5;
        Clear_LockBit_Time   = `AC_Clear_LockBit_50_5;
        Program_Suspend_Time = `AC_Program_Suspend_50_5;
        Erase_Suspend_Time   = `AC_Erase_Suspend_50_5;
      end
      else
        VppErrFlag = `TRUE;
    end
    else begin
      if ((vcc <= 3600) && (vcc >= 3000)) begin
        Block_Erase_Time     = `AC_EraseTime_Block_33_12;
        Program_Time_Byte    = `AC_ProgramTime_Byte_33_12;
        Set_LockBit_Time     = `AC_Set_LockBit_33_12;
        Clear_LockBit_Time   = `AC_Clear_LockBit_33_12;
        Program_Suspend_Time = `AC_Program_Suspend_33_12;
        Erase_Suspend_Time   = `AC_Erase_Suspend_33_12;
      end
      else if ((vcc <= 5500) && (vcc >= 4500)) begin
        Block_Erase_Time     = `AC_EraseTime_Block_50_12;
        Program_Time_Byte    = `AC_ProgramTime_Byte_50_12;
        Set_LockBit_Time     = `AC_Set_LockBit_50_12;
        Clear_LockBit_Time   = `AC_Clear_LockBit_50_12;
        Program_Suspend_Time = `AC_Program_Suspend_50_12;
        Erase_Suspend_Time   = `AC_Erase_Suspend_50_12;
      end
      else
        VppErrFlag = `TRUE;
    end

    VppFlag <= VppErrFlag;
  end  //always (VppMonitor)


  always @(StartUpFlag or Internal_OE3) begin : OEMonitor
    // This section generated DriveOutputs which is the main signal that
    // controls the state of the output drivers

    if (!StartUpFlag)  begin
      WriteRecovery = 0 ;
      last_Internal_WE_time = $time - curr_Internal_WE_time;
      if (Internal_OE) begin
        TempTime = WriteRecovery + TGLQX ;
        DriveOutputs = `FALSE ;
        WriteRecovery = WriteRecovery + TGLQV -TempTime;
        DriveOutputs <= #WriteRecovery `TRUE ;
      end
      else begin
       InternalOutput <= #TOH `MaxOutputs'hx;
       if (oeb == `VIH)
         WriteRecovery = WriteRecovery + TGHQZ;
       else
         WriteRecovery = WriteRecovery + TEHQZ;
        DriveOutputs <= #WriteRecovery `FALSE ;
      end
    end
    else
      DriveOutputs <= `FALSE ;
  end

  /////// Timing Checks /////////////

  always @(Internal_WE) begin : Timing_chk

    if ($time > 0) begin

      // pulse chk
      if (Internal_WE) begin
        if ((($time - curr_Internal_WE_time) < TWPH) && (TWPH > 0 )) begin
          $display("[",$time,"]%m:: Timing Violation: Internal Write Enable Insufficient High Time") ;
        end
      end
      else begin
        // WEb controlled write
        if ((curr_Internal_WE_time - curr_ce_time) >= 10) begin
          if ((vcc <= 5500) && (vcc >= 4500)) begin
            if (($time - curr_Internal_WE_time) < (TWP - 10)) begin
              $display("[",$time,"]%m:: Timing Violation: Internal Write Enable Insufficient Low Time");
            end
          end
          else begin
            if (($time - curr_Internal_WE_time) < (TWP - 20))begin
              $display("[",$time,"]%m:: Timing Violation: Interanal Write Enable Insufficient Low Time");
            end
          end
        end
        // CEb controlled write
        else begin
          if ((($time - curr_Internal_WE_time) < TWP) && (TWP > 0 )) begin
            $display("[",$time,"]%m:: Timing Violation: Internal Write Enable Insufficient Low Time") ;
          end
        end
      end
      curr_Internal_WE_time = $time ;

      // timing_chk - addr
      last_dq_time = $time - curr_dq_time;
      last_rpb_time = $time - curr_rpb_time;
      last_addr_time = $time - curr_addr_time;

      if (Internal_WE == 0)  begin
        if ((last_addr_time < TAVWH) && (last_addr_time > 0))
          $display("[",$time,"]%m:: Timing Violation: Address setup time during write, Last Event %d",last_addr_time) ;
        if ((last_rpb_time < TPHWL) && (last_rpb_time > 0))
          $display("[",$time,"]%m:: Timing Violation: Writing while coming out of powerdown,  Last Event %d",last_rpb_time) ;
        if ((last_dq_time < TDVWH) && (last_dq_time > 0))
          $display("[",$time,"]%m:: Timing Violation: Data setup time during write, Last Event %d",last_dq_time) ;
      end
    end
  end

  always @(addr) begin
    last_Internal_WE_time = $time - curr_Internal_WE_time;
    if (($time > 0) && !Internal_WE) begin   //timing chk
      if ((last_Internal_WE_time < TWHAX) && (last_Internal_WE_time > 0))
        $display("[",$time,"]%m:: Timing Violation:Address hold time after write, Last Event %d",last_Internal_WE_time) ;
    end
  end

  always @(rpb) begin
    if ($time > 0) begin
      curr_rpb_time = $time ;
    end
  end

  always @(dq) begin
    curr_dq_time = $time ;
    last_Internal_WE_time = $time - curr_Internal_WE_time;
    if (($time > 0) && !Internal_WE) begin
      if ((last_Internal_WE_time < TWHDX) && (last_Internal_WE_time > 0))
        $display("[",$time,"]%m:: Timing Violation:Data hold time after write, Last Event %d",last_Internal_WE_time) ;
    end
  end

  endmodule
