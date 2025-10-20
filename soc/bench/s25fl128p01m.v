//////////////////////////////////////////////////////////////////////////////
//  File name : s25fl128p01m.v
//////////////////////////////////////////////////////////////////////////////
//  Copyright (C) 2006-2007 Spansion, LLC.
//
//  MODIFICATION HISTORY :
//
//  version: |   author:      |  mod date: | changes made:
//    V1.0     S.Petrovic       06 Jul 05   Initial release
//    V1.1     S.Janevski       07 Jan 23   Extended device identification
//                                          Enable WRSR,SE,BE,DP in parallel
//                                          mode
//                                          In DP mode only RES is accepted
//                                          Implemented tpd time in DP mode
//////////////////////////////////////////////////////////////////////////////
//  PART DESCRIPTION:
//
//  Library:        FLASH
//  Technology:     FLASH MEMORY
//  Part:           S25FL128P01M
//
//  Description:128 Megabit Serial Flash Memory with 104 MHz SPI Bus Interface
//  Comments :
//      For correct simulation, simulator resolution should be set to 100 ps
//
//////////////////////////////////////////////////////////////////////////////
//  Known Bugs:
//
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION                                                       //
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ns/100 ps
module s25fl128p01m
(
    SCK      ,
    SI       ,

    PO7      ,
    PO6      ,
    PO5      ,
    PO4      ,
    PO3      ,
    PO2      ,
    PO1      ,
    PO0      ,

    CSNeg    ,
    HOLDNeg  ,
    WPNeg
);

////////////////////////////////////////////////////////////////////////
// Port / Part Pin Declarations
////////////////////////////////////////////////////////////////////////
    input  SCK     ;
    input  SI      ;

    inout  PO7     ;
    inout  PO6     ;
    inout  PO5     ;
    inout  PO4     ;
    inout  PO3     ;
    inout  PO2     ;
    inout  PO1     ;
    inout  PO0     ;

    input  CSNeg   ;
    input  HOLDNeg ;
    input  WPNeg    ;

// interconnect path delay signals
    wire  SCK_ipd      ;
    wire  SI_ipd       ;

    wire  PO7_ipd      ;
    wire  PO6_ipd      ;
    wire  PO5_ipd      ;
    wire  PO4_ipd      ;
    wire  PO3_ipd      ;
    wire  PO2_ipd      ;
    wire  PO1_ipd      ;
    wire  PO0_ipd      ;

    wire [7 : 0 ] PIn;
    assign PIn = {PO7_ipd,
                  PO6_ipd,
                  PO5_ipd,
                  PO4_ipd,
                  PO3_ipd,
                  PO2_ipd,
                  PO1_ipd,
                  PO0_ipd};

    wire [7 : 0 ] POut;
    assign POut = {PO7,
                   PO6,
                   PO5,
                   PO4,
                   PO3,
                   PO2,
                   PO1,
                   PO0};

    wire  CSNeg_ipd    ;
    wire  HOLDNeg_ipd  ;
    wire  WPNeg_ipd     ;

//  internal delays
    reg PP_in       ;
    reg PP_out      ;
    reg BE_in       ;
    reg BE_out      ;
    reg SE_in       ;
    reg SE_out      ;
    reg WR_in       ;
    reg WR_out      ;
    reg DP_in       ;
    reg DP_out      ;
    reg RES_in      ;
    reg RES_out     ;

    wire  PO7_z     ;
    wire  PO6_z     ;
    wire  PO5_z     ;
    wire  PO4_z     ;
    wire  PO3_z     ;
    wire  PO2_z     ;
    wire  PO1_z     ;
    wire  PO0_z     ;

    reg [15 : 0] POut_zd = 8'bZZZZZZZZ;
    reg [15 : 0] POut_z  = 8'bZZZZZZZZ;

    assign {PO7_z,
            PO6_z,
            PO5_z,
            PO4_z,
            PO3_z,
            PO2_z,
            PO1_z,
            PO0_z} = POut_z;

    parameter UserPreload     = 1;
    parameter mem_file_name   = "none";//"s25fl128p01m.mem";

    parameter TimingModel = "DefaultTimingModel";

    parameter PartID = "s25fl128p01m";
    parameter MaxData = 255;
    parameter SecSize = 262143;
    parameter SecNum  = 63;
    parameter HiAddrBit = 23;
    parameter AddrRANGE = 24'hFFFFFF;
    parameter BYTE = 8;
    parameter Manuf_ID = 8'h01;
    parameter ES = 8'h17;
    parameter Jedec_ID =8'h20; // first byte of Device ID
    parameter DeviceID = 24'h012018;
    parameter ExtendedID    = 16'h0300;

    // If speed simulation is needed uncomment following line

    //`define SPEEDSIM;

    // powerup
    reg PoweredUp;

    reg PDONE    ; ////Prog. Done
    reg PSTART   ; ////Start Programming

    reg EDONE    ; ////Era. Done
    reg ESTART   ; ////Start Erasing

    reg WDONE    ; //// Writing Done
    reg WSTART   ; ////Start writing

    //Command Register
    reg write;
    reg read_out;

    //Status reg.
    reg[7:0] Status_reg = 8'b0;
    reg[7:0] Status_reg_in = 8'b0;

    integer SA      = 0;         // 0 TO SecNum+1
    integer Byte_number = 0;

    //Address
    integer Address = 0;         // 0 - AddrRANGE
    reg change_addr;
    reg  rd_fast;// = 1'b1;
    reg  rd_slow;
    wire fast_rd;
    wire rd;

    reg  PRL_ACT = 1'b0;
    reg  serial_mode;// = 1'b1;
    reg  prl_mode;
    wire serial;
    wire prl;

    //Sector Protection Status
    reg [SecNum:0] Sec_Prot = 64'b0; //= SecNum'b0;

    // timing check violation
    reg Viol = 1'b0;

    integer Mem[0:AddrRANGE];

    integer WByte[0:255];

    integer AddrLo;
    integer AddrHi;

    reg[7:0]  old_bit, new_bit;
    integer old_int, new_int;
    integer wr_cnt;

    integer read_cnt = 0;
    integer prl_read_cnt = 0;
    integer read_addr = 0;
    reg[7:0] data_out;
    reg[39:0] ident_out;

    reg oe = 1'b0;
    event oe_event;

///////////////////////////////////////////////////////////////////////////////
//Interconnect Path Delay Section
///////////////////////////////////////////////////////////////////////////////

 buf   (SCK_ipd, SCK);
 buf   (SI_ipd, SI);

 buf   (PO7_ipd, PO7);
 buf   (PO6_ipd, PO6);
 buf   (PO5_ipd, PO5);
 buf   (PO4_ipd, PO4);
 buf   (PO3_ipd, PO3);
 buf   (PO2_ipd, PO2);
 buf   (PO1_ipd, PO1);
 buf   (PO0_ipd, PO0);

 buf   (CSNeg_ipd, CSNeg);
 buf   (HOLDNeg_ipd, HOLDNeg);
 buf   (WPNeg_ipd, WPNeg);

///////////////////////////////////////////////////////////////////////////////
// Propagation  delay Section
///////////////////////////////////////////////////////////////////////////////
    nmos   (PO7,   PO7_z , 1);
    nmos   (PO6,   PO6_z , 1);
    nmos   (PO5,   PO5_z , 1);
    nmos   (PO4,   PO4_z , 1);
    nmos   (PO3,   PO3_z , 1);
    nmos   (PO2,   PO2_z , 1);
    nmos   (PO1,   PO1_z , 1);
    nmos   (PO0,   PO0_z , 1);

    wire deg;
    //VHDL VITAL CheckEnable equivalents
    wire prl_wr;
    assign prl_wr = prl && deg;
    wire prl_rd;
    assign prl_rd = prl && rd;
    wire serial_rd;
    assign serial_rd = serial && rd;
    wire prl_fast_rd;
    assign prl_fast_rd = prl && fast_rd;
    wire serial_fast_rd;
    assign serial_fast_rd = serial && fast_rd;
    wire power;
    assign power = PoweredUp;

 specify
        // tipd delays: interconnect path delays , mapped to input port delays.
        // In Verilog is not necessary to declare any tipd_ delay variables,
        // they can be taken from SDF file
        // With all the other delays real delays would be taken from SDF file

                        // tpd delays
     specparam           tpd_SCK_PO7              =1;
     specparam           tpd_SCK_PO0              =1;
     specparam           tpd_CSNeg_PO7            =1;
     specparam           tpd_CSNeg_PO0            =1;
     specparam           tpd_HOLDNeg_PO7          =1;
     specparam           tpd_HOLDNeg_PO0          =1;

     specparam           tsetup_SI_SCK           =1;   //tsuDAT /
     specparam           tsetup_PO0_SCK          =1;   //tsuDAT /
     specparam           tsetup_CSNeg_SCK        =1;   // tCSS /
     specparam           tsetup_HOLDNeg_SCK      =1;   //tHD /
     specparam           tsetup_SCK_HOLDNeg      =1;   //tCH \
     specparam           tsetup_WPNeg_CSNeg       =1;   //tWPS \

                          // thold values: hold times
     specparam           thold_SI_SCK            =1; //thdDAT /
     specparam           thold_PO0_SCK            =1; //thdDAT /
     specparam           thold_CSNeg_SCK         =1; //tCSH /
     specparam           thold_HOLDNeg_SCK       =1; //tCD /
     specparam           thold_SCK_HOLDNeg       =1; //tHC \
     specparam           thold_WPNeg_CSNeg        =1; //tWPH \

        // tpw values: pulse width
     specparam           tpw_SCK_serial_posedge   =1; //tWH
     specparam           tpw_SCK_prl_posedge      =1; //tWH
     specparam           tpw_SCK_serial_negedge   =1; //tWL
     specparam           tpw_SCK_prl_negedge      =1; //tWL
     specparam           tpw_CSNeg_serial_posedge =1; //tCS
     specparam           tpw_CSNeg_prl_posedge    =1; //tCS

        // tperiod min (calculated as 1/max freq)
     specparam           tperiod_SCK_serial_rd       =1; // fSCK = 40MHz
     specparam           tperiod_SCK_prl_rd          =1; // fSCK = 6MHz
     specparam           tperiod_SCK_serial_fast_rd  =1; // fSCK = 104MHz
     specparam           tperiod_SCK_prl_fast_rd     =1; // fSCK = 10MHz

        // tdevice values: values for internal delays
        `ifdef SPEEDSIM
            // Page Program Operation
            specparam   tdevice_PP                     = 30000; //30 us;
                    //Sector Erase Operation
            specparam   tdevice_SE                     = 4e6; //4 ms;
                    //Bulk Erase Operation
            specparam   tdevice_BE                     = 256e6; //256 ms;
                    //Write Status Register Operation
            specparam   tdevice_WR                     = 1000000; // 1 ms;
                    //Software Protect Mode
            specparam   tdevice_DP                     = 3000; // 3 us;
                    //Release from Software Protect Mode
            specparam   tdevice_RES                    = 30000; // 30 us;
                    //VCC (min) to CS# Low
            specparam   tdevice_PU                     = 45000000; //45 ms;
        `else
            // Page Program Operation
            specparam   tdevice_PP                     = 3000000; //3 ms;
                    //Sector Erase Operation
            specparam   tdevice_SE                     = 4e9; //4 sec;
                    //Bulk Erase Operation
            specparam   tdevice_BE                     = 256e9; //256 sec;
                    //Write Status Register Operation
            specparam   tdevice_WR                     = 100000000; // 100 ms;
                    //Software Protect Mode
            specparam   tdevice_DP                     = 3000; // 3 us;
                    //Release from Software Protect Mode
            specparam   tdevice_RES                    = 30000; // 30 us;
                    //VCC (min) to CS# Low
            specparam   tdevice_PU                     = 45000000; //45 ms;
        `endif//SPEEDSIM

///////////////////////////////////////////////////////////////////////////////
// Input Port  Delays  don't require Verilog description
///////////////////////////////////////////////////////////////////////////////
// Path delays                                                               //
///////////////////////////////////////////////////////////////////////////////
  if (serial) (SCK => PO7) = tpd_SCK_PO7;
  if (serial && CSNeg )(CSNeg => PO7) = tpd_CSNeg_PO7;
  if (serial) (HOLDNeg => PO7) = tpd_HOLDNeg_PO7;

  if (prl) (SCK *> PO0) = tpd_SCK_PO0;
  if (prl) (SCK *> PO1) = tpd_SCK_PO0;
  if (prl) (SCK *> PO2) = tpd_SCK_PO0;
  if (prl) (SCK *> PO3) = tpd_SCK_PO0;
  if (prl) (SCK *> PO4) = tpd_SCK_PO0;
  if (prl) (SCK *> PO5) = tpd_SCK_PO0;
  if (prl) (SCK *> PO6) = tpd_SCK_PO0;
  if (prl) (SCK *> PO7) = tpd_SCK_PO0;
  if (prl && CSNeg )(CSNeg => PO0) = tpd_CSNeg_PO0;
  if (prl && CSNeg )(CSNeg => PO1) = tpd_CSNeg_PO0;
  if (prl && CSNeg )(CSNeg => PO2) = tpd_CSNeg_PO0;
  if (prl && CSNeg )(CSNeg => PO3) = tpd_CSNeg_PO0;
  if (prl && CSNeg )(CSNeg => PO4) = tpd_CSNeg_PO0;
  if (prl && CSNeg )(CSNeg => PO5) = tpd_CSNeg_PO0;
  if (prl && CSNeg )(CSNeg => PO6) = tpd_CSNeg_PO0;
  if (prl && CSNeg )(CSNeg => PO7) = tpd_CSNeg_PO0;
  if (prl)(HOLDNeg => PO0) = tpd_HOLDNeg_PO0;
  if (prl)(HOLDNeg => PO1) = tpd_HOLDNeg_PO0;
  if (prl)(HOLDNeg => PO2) = tpd_HOLDNeg_PO0;
  if (prl)(HOLDNeg => PO3) = tpd_HOLDNeg_PO0;
  if (prl)(HOLDNeg => PO4) = tpd_HOLDNeg_PO0;
  if (prl)(HOLDNeg => PO5) = tpd_HOLDNeg_PO0;
  if (prl)(HOLDNeg => PO6) = tpd_HOLDNeg_PO0;
  if (prl)(HOLDNeg => PO7) = tpd_HOLDNeg_PO0;

////////////////////////////////////////////////////////////////////////////////
// Timing Violation                                                           //
////////////////////////////////////////////////////////////////////////////////
        $setup ( WPNeg , negedge CSNeg, tsetup_WPNeg_CSNeg, Viol);
        $setup ( negedge HOLDNeg, posedge SCK, tsetup_HOLDNeg_SCK, Viol);
        $setup ( posedge SCK, posedge HOLDNeg, tsetup_SCK_HOLDNeg, Viol);

        $setup ( PO0 , posedge SCK &&& prl_wr , tsetup_PO0_SCK, Viol);
        $setup ( PO1 , posedge SCK &&& prl_wr , tsetup_PO0_SCK, Viol);
        $setup ( PO2 , posedge SCK &&& prl_wr , tsetup_PO0_SCK, Viol);
        $setup ( PO3 , posedge SCK &&& prl_wr , tsetup_PO0_SCK, Viol);
        $setup ( PO4 , posedge SCK &&& prl_wr , tsetup_PO0_SCK, Viol);
        $setup ( PO5 , posedge SCK &&& prl_wr , tsetup_PO0_SCK, Viol);
        $setup ( PO6 , posedge SCK &&& prl_wr , tsetup_PO0_SCK, Viol);
        $setup ( PO7 , posedge SCK &&& prl_wr , tsetup_PO0_SCK, Viol);

        $hold ( posedge CSNeg, WPNeg,  thold_WPNeg_CSNeg, Viol);
        $hold ( posedge SCK, negedge HOLDNeg, thold_HOLDNeg_SCK, Viol);
        $hold ( posedge HOLDNeg, posedge SCK, thold_SCK_HOLDNeg, Viol);

        $hold ( posedge SCK , PO0 &&& prl_wr, thold_PO0_SCK, Viol);
        $hold ( posedge SCK , PO1 &&& prl_wr, thold_PO0_SCK, Viol);
        $hold ( posedge SCK , PO2 &&& prl_wr, thold_PO0_SCK, Viol);
        $hold ( posedge SCK , PO3 &&& prl_wr, thold_PO0_SCK, Viol);
        $hold ( posedge SCK , PO4 &&& prl_wr, thold_PO0_SCK, Viol);
        $hold ( posedge SCK , PO5 &&& prl_wr, thold_PO0_SCK, Viol);
        $hold ( posedge SCK , PO6 &&& prl_wr, thold_PO0_SCK, Viol);
        $hold ( posedge SCK , PO7 &&& prl_wr, thold_PO0_SCK, Viol);

        $setuphold ( posedge SCK, SI &&& serial, tsetup_SI_SCK,
                                                  thold_SI_SCK, Viol);
        $setuphold ( posedge SCK, CSNeg &&& power, tsetup_CSNeg_SCK,
                                                    thold_CSNeg_SCK, Viol);

        $width (posedge SCK &&& serial, tpw_SCK_serial_posedge);
        $width (posedge SCK &&& prl, tpw_SCK_prl_posedge);
        $width (negedge SCK &&& serial, tpw_SCK_serial_negedge);
        $width (negedge SCK &&& prl, tpw_SCK_prl_negedge);

        $width (posedge CSNeg &&& serial, tpw_CSNeg_serial_posedge);
        $width (posedge CSNeg &&& prl, tpw_CSNeg_prl_posedge);

        $period (posedge SCK &&& serial_rd, tperiod_SCK_serial_rd);
        $period (posedge SCK &&& prl_rd, tperiod_SCK_prl_rd);
        $period (posedge SCK &&& serial_fast_rd, tperiod_SCK_serial_fast_rd);
        $period (posedge SCK &&& prl_fast_rd, tperiod_SCK_prl_fast_rd);

    endspecify

////////////////////////////////////////////////////////////////////////////////
// Main Behavior Block                                                        //
////////////////////////////////////////////////////////////////////////////////
// FSM states
 parameter IDLE            =4'd0;
 parameter WRITE_SR        =4'd1;
 parameter DP_DOWN_WAIT    =4'd2;
 parameter DP_DOWN         =4'd3;
 parameter SECTOR_ER       =4'd4;
 parameter BULK_ER         =4'd5;
 parameter PAGE_PG         =4'd6;

 reg [3:0] current_state;
 reg [3:0] next_state;

// Instructions
 parameter NONE            =5'd0;
 parameter WREN            =5'd1;
 parameter WRDI            =5'd2;
 parameter WRSR            =5'd3;
 parameter RDSR            =5'd4;
 parameter READ            =5'd5;
 parameter FAST_READ       =5'd6;
 parameter SE              =5'd7;
 parameter BE              =5'd8;
 parameter PP              =5'd9;
 parameter DP              =5'd10;
 parameter RDID            =5'd11;
 parameter RES_READ_ES     =5'd12;
 parameter READ_ID         =5'd13;
 parameter ENTER_PRL       =5'd14;
 parameter EXIT_PRL        =5'd15;

 reg [4:0] Instruct;

//Bus cycle states
 parameter STAND_BY        =3'd0;
 parameter CODE_BYTE       =3'd1;
 parameter ADDRESS_BYTES   =3'd2;
 parameter DUMMY_BYTES     =3'd3;
 parameter DATA_BYTES      =3'd4;

 reg [2:0] bus_cycle_state;

 reg deq;
    always @(PIn, POut)
    begin
      if (PIn==POut)
        deq=1'b1;
      else
        deq=1'b0;
    end
    // chech when data is generated from model to avoid setuphold check in
    // those occasion
    assign deg=deq;

    initial
    begin : Init

        write    = 1'b0;
        read_out  = 1'b0;
        Address   = 0;
        change_addr = 1'b0;

        PDONE    = 1'b1;
        PSTART   = 1'b0;

        EDONE    = 1'b1;
        ESTART   = 1'b0;

        WDONE    = 1'b1;
        WSTART   = 1'b0;

        DP_in = 1'b0;
        DP_out = 1'b0;
        RES_in = 1'b0;
        RES_out = 1'b0;
        Instruct = NONE;
        bus_cycle_state = STAND_BY;
        current_state = IDLE;
        next_state = IDLE;
    end

    // initialize memory
    initial
    begin: InitMemory
    integer i;

        for (i=0;i<=AddrRANGE;i=i+1)
        begin
            Mem[i] = MaxData;
        end

        if ((UserPreload) && !(mem_file_name == "none"))
        begin
           // Memory Preload
           //s25fl128p01m.mem, memory preload file
           //  @aaaaaa - <aaaaaa> stands for address
           //  dd      - <dd> is byte to be written at Mem(aaaaaa++)
           // (aaaaaa is incremented at every load)
           $readmemh(mem_file_name,Mem);
        end
    end

    //Power Up time;
    initial
    begin
        PoweredUp = 1'b0;
        #tdevice_PU PoweredUp = 1'b1;
    end

   always @(posedge DP_in)
   begin:TDPr
     #tdevice_DP DP_out = DP_in;
   end
   always @(negedge DP_in)
   begin:TDPf
     #1 DP_out = DP_in;
   end

   always @(posedge RES_in)
   begin:TRESr
     #tdevice_RES RES_out = RES_in;
   end
   always @(negedge RES_in)
   begin:TRESf
     #1 RES_out = RES_in;
   end

   always @(next_state or PoweredUp)
   begin: StateTransition
       if (PoweredUp)
       begin
           current_state = next_state;
       end
   end

   always @(PoweredUp)
   begin:CheckCEOnPowerUP
       if ((~PoweredUp) && (~CSNeg_ipd))
           $display ("Device is selected during Power Up");
   end

//   ///////////////////////////////////////////////////////////////////////////
//   // Instruction cycle decode
//   ///////////////////////////////////////////////////////////////////////////
 integer data_cnt = 0;
 integer addr_cnt = 0;
 integer code_cnt = 0;
 integer dummy_cnt = 0;
 integer bit_cnt = 0;
 reg[2047:0] Data_in = 2048'b0;
 integer prl_data_in [0:255];
 reg[7:0] code = 8'b0;
 reg[7:0] code_in = 8'b0;
 reg[7:0] Byte_slv = 8'b0;
 reg[HiAddrBit:0] addr_bytes;
 reg[23:0] Address_in = 8'b0;

 reg rising_edge_CSNeg_ipd  = 1'b0;
 reg falling_edge_CSNeg_ipd = 1'b0;
 reg rising_edge_SCK_ipd    = 1'b0;
 reg falling_edge_SCK_ipd   = 1'b0;

    always @(falling_edge_CSNeg_ipd or rising_edge_CSNeg_ipd
    or rising_edge_SCK_ipd or falling_edge_SCK_ipd)
    begin: Buscycle1
        integer i;
        integer j;
        if (falling_edge_CSNeg_ipd)
        begin
            if (bus_cycle_state==STAND_BY)
            begin
                bus_cycle_state = CODE_BYTE;
                Instruct = NONE;
                write = 1'b1;
                code_cnt = 0;
                addr_cnt = 0;
                data_cnt = 0;
                dummy_cnt = 0;
            end
        end

        if (rising_edge_SCK_ipd)
        begin
            if ( HOLDNeg_ipd)
            begin
                case (bus_cycle_state)
                    CODE_BYTE :
                    begin
                        serial_mode = 1'b1;
                        prl_mode = 1'b0;
                        code_in[code_cnt] = SI_ipd;
                        code_cnt = code_cnt + 1;
                        if (code_cnt == BYTE)
                        begin
                            for (i=0;i<=7;i=i+1)
                            begin
                                code[i] = code_in[7-i];
                            end
                            case(code)
                                8'b00000110 :
                                begin
                                    Instruct = WREN;
                                    bus_cycle_state = DATA_BYTES;
                                end
                                8'b00000100 :
                                begin
                                    Instruct = WRDI;
                                    bus_cycle_state = DATA_BYTES;
                                end
                                8'b00000001 :
                                begin
                                    Instruct = WRSR;
                                    bus_cycle_state = DATA_BYTES;
                                end
                                8'b00000101 :
                                begin
                                    Instruct = RDSR;
                                    bus_cycle_state = DATA_BYTES;
                                end
                                8'b00000011 :
                                begin
                                    Instruct = READ;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end
                                8'b00001011 :
                                begin
                                    Instruct = FAST_READ;
                                    if (~PRL_ACT)
                                        bus_cycle_state = ADDRESS_BYTES;
                                end
                                8'b10101011 :
                                begin
                                    Instruct = RES_READ_ES;
                                    bus_cycle_state = DUMMY_BYTES;
                                end
                                8'b11011000 :
                                begin
                                    Instruct = SE;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end
                                8'b11000111 :
                                begin
                                    Instruct = BE;
                                    bus_cycle_state = DATA_BYTES;
                                end
                                8'b00000010 :
                                begin
                                    Instruct = PP;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end
                                8'b10111001 :
                                begin
                                    Instruct = DP;
                                    bus_cycle_state = DATA_BYTES;
                                end
                                8'b10011111 :
                                begin
                                    Instruct = RDID;
                                    bus_cycle_state = DATA_BYTES;
                                end
                                8'b10010000 :
                                begin
                                    Instruct = READ_ID;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end
                                8'b01010101 :
                                begin
                                    Instruct = ENTER_PRL;
                                    bus_cycle_state = DATA_BYTES;
                                end
                                8'b01000101 :
                                begin
                                    Instruct = EXIT_PRL;
                                    bus_cycle_state = DATA_BYTES;
                                end
                            endcase
                        end
                    end

                    ADDRESS_BYTES :
                    begin
                        Address_in[addr_cnt] = SI_ipd;
                        addr_cnt = addr_cnt + 1;
                        if (addr_cnt == 3*BYTE)
                        begin
                            for (i=23;i>=23-HiAddrBit;i=i-1)
                            begin
                                addr_bytes[23-i] = Address_in[i];
                            end
                            Address = addr_bytes;
                            change_addr = 1'b1;
                            #1 change_addr = 1'b0;
                            if (Instruct == FAST_READ)
                                bus_cycle_state = DUMMY_BYTES;
                            else
                                bus_cycle_state = DATA_BYTES;
                        end
                    end

                    DUMMY_BYTES :
                    begin
                        dummy_cnt = dummy_cnt + 1;
                        if ((dummy_cnt == BYTE && Instruct == FAST_READ) ||
                            (dummy_cnt == 3*BYTE && Instruct == RES_READ_ES))
                            bus_cycle_state = DATA_BYTES;
                    end

                    DATA_BYTES :
                    begin
                        if (PRL_ACT)
                        begin
                            serial_mode = 1'b0;
                            prl_mode = 1'b1;
                        end
                        else
                        begin
                            serial_mode = 1'b1;
                            prl_mode = 1'b0;
                        end
                        if (serial_mode)
                        begin
                            if (data_cnt > 2047)
                            //In case of serial mode and PP, if more than 256
                            //bytes are sent to the device
                            begin
                                if (bit_cnt == 0)
                                begin
                                    for (i=0;i<=(255*BYTE-1);i=i+1)
                                    begin
                                        Data_in[i] = Data_in[i+8];
                                    end
                                end
                                Data_in[2040 + bit_cnt] = SI_ipd;
                                bit_cnt = bit_cnt + 1;
                                if (bit_cnt == 8)
                                begin
                                    bit_cnt = 0;
                                end
                                data_cnt = data_cnt + 1;
                            end
                            else
                            begin
                                Data_in[data_cnt] = SI_ipd;
                                data_cnt = data_cnt + 1;
                                bit_cnt = 0;
                            end
                        end
                        else
                        begin
                            if (data_cnt > 255)
                            //In case of parallel mode and PP, if more than 256
                            //bytes are sent to the device
                            begin
                                for (i=0;i<=254;i=i+1)
                                begin
                                    prl_data_in[i] = prl_data_in[i+1];
                                end
                                prl_data_in[255] = PIn;
                                data_cnt = data_cnt + 1;
                            end
                            else
                            begin
                                prl_data_in[data_cnt] = PIn;
                                data_cnt = data_cnt + 1;
                            end
                        end
                    end
                endcase
            end
        end

        if (falling_edge_SCK_ipd)
        begin
            if (bus_cycle_state==DATA_BYTES && (~CSNeg_ipd) && (HOLDNeg_ipd))
                if (Instruct == READ || Instruct == RES_READ_ES ||
                    Instruct == FAST_READ || Instruct == RDSR ||
                    Instruct == RDID || Instruct == READ_ID)
                begin
                    if (PRL_ACT)
                    begin
                        serial_mode = 1'b0;
                        prl_mode = 1'b1;
                    end
                    else
                    begin
                        serial_mode = 1'b1;
                        prl_mode = 1'b0;
                    end
                    read_out = 1'b1;
                    #1 read_out = 1'b0;
                end
        end
        if (rising_edge_CSNeg_ipd)
        begin
            if ((bus_cycle_state != DATA_BYTES) && (bus_cycle_state !=
                                                            DUMMY_BYTES))
                bus_cycle_state = STAND_BY;
            else
            begin
            if (bus_cycle_state == DATA_BYTES)
            begin
                bus_cycle_state = STAND_BY;
                if (HOLDNeg_ipd)
                begin
                    case (Instruct)
                        WREN,
                        WRDI,
                        DP,
                        BE,
                        SE :
                        begin
                            if (data_cnt == 0)
                                write = 1'b0;
                        end

                        ENTER_PRL,
                        EXIT_PRL :
                        begin
                            if (data_cnt == 0)
                            begin
                                write = 1'b0;
                                if (Instruct == ENTER_PRL)
                                    PRL_ACT = 1'b1;
                                else if (Instruct == EXIT_PRL)
                                    PRL_ACT = 1'b0;
                            end
                        end

                        RES_READ_ES:
                        begin
                            write = 1'b0;
                        end

                        WRSR :
                        begin
                            if (data_cnt == BYTE)
                                write = 1'b0;
                                if (PRL_ACT == 1'b0)
                                    Status_reg_in = Data_in[7:0];
                                else
                                    Status_reg_in = prl_data_in[0];
                        end

                        PP :
                        begin
                            if (data_cnt > 0)
                            begin
                                if (serial_mode)
                                begin
                                    if ((data_cnt % 8) == 0)
                                    begin
                                        write = 1'b0;
                                        for (i=0;i<=255;i=i+1)
                                        begin
                                            for (j=7;j>=0;j=j-1)
                                            begin
                                                Byte_slv[j] =
                                                Data_in[(i*8) + (7-j)];
                                            end
                                            WByte[i] = Byte_slv;
                                        end
                                        if (data_cnt > 256*BYTE)
                                            Byte_number = 255;
                                        else
                                            Byte_number = ((data_cnt/8) - 1);
                                    end
                                end
                                else
                                begin
                                    write = 1'b0;
                                    for (i=0;i<=255;i=i+1)
                                    begin
                                        WByte[i] = prl_data_in[i];
                                    end
                                    if (data_cnt > 256)
                                        Byte_number = 255;
                                    else
                                        Byte_number = (data_cnt - 1);
                                end
                            end
                        end
                    endcase
                end
            end
            else
                if (bus_cycle_state == DUMMY_BYTES)
                begin
                    bus_cycle_state = STAND_BY;
                    if (HOLDNeg_ipd && (Instruct == RES_READ_ES) &&
                    (dummy_cnt == 0))
                        write = 1'b0;
                end
            end
        end
    end

    assign serial = serial_mode;
    assign prl = prl_mode;

//    /////////////////////////////////////////////////////////////////////////
//    // Timing control for the Program Operations
//    // start
//    /////////////////////////////////////////////////////////////////////////

 event pdone_event;

    always @(PSTART)
    begin
        if (PSTART && PDONE)
        begin
            PDONE = 1'b0;
            ->pdone_event;
        end
    end

    always @(pdone_event)
    begin:pdone_process
        PDONE = 1'b0;
        #tdevice_PP PDONE = 1'b1;
    end

//    /////////////////////////////////////////////////////////////////////////
//    // Timing control for the Write Status Register Operation
//    // start
//    /////////////////////////////////////////////////////////////////////////

 event wdone_event;

    always @(WSTART)
    begin
        if (WSTART && WDONE)
        begin
            WDONE = 1'b0;
            ->wdone_event;
        end
    end

    always @(wdone_event)
    begin:wdone_process
        WDONE = 1'b0;
        #tdevice_WR WDONE = 1'b1;
    end

//    /////////////////////////////////////////////////////////////////////////
//    // Timing control for the Erase Operations
//    /////////////////////////////////////////////////////////////////////////
 time duration_erase;

    event edone_event;

    always @(ESTART)
    begin: erase
        if (ESTART && EDONE)
        begin
            if (Instruct == BE)
            begin
                duration_erase = tdevice_BE;
            end
            else //if (Instruct == SE)
            begin
                duration_erase = tdevice_SE;
            end

            EDONE = 1'b0;
            ->edone_event;
        end
    end

    always @(edone_event)
    begin : edone_process
        EDONE = 1'b0;
        #duration_erase EDONE = 1'b1;
    end

//    /////////////////////////////////////////////////////////////////////////
//    // Main Behavior Process
//    // combinational process for next state generation
//    /////////////////////////////////////////////////////////////////////////

    integer sect;
    reg rising_edge_PDONE = 1'b0;
    reg rising_edge_EDONE = 1'b0;
    reg rising_edge_WDONE = 1'b0;
    reg rising_edge_DP_out = 1'b0;
    reg falling_edge_write = 1'b0;

    always @(falling_edge_write or rising_edge_PDONE or rising_edge_WDONE
    or rising_edge_EDONE or rising_edge_DP_out)
    begin: StateGen1
        if (falling_edge_write)
        begin
            case (current_state)
                IDLE :
                begin
                    if (~write)
                    begin
                        if (Instruct == WRSR && Status_reg[1])
                        begin
                            if (~(Status_reg[7] && (~WPNeg_ipd)))
                                next_state = WRITE_SR;
                        end
                        else if (Instruct == PP && Status_reg[1])
                        begin
                            sect = Address / 24'h40000;
                            if (Sec_Prot[sect] == 1'b0)
                                next_state = PAGE_PG;
                        end
                        else if (Instruct == SE && Status_reg[1])
                        begin
                            sect = Address / 24'h40000;
                            if (Sec_Prot[sect] == 1'b0)
                                next_state = SECTOR_ER;
                        end
                        else if (Instruct == BE && Status_reg[1])
                        begin
                            if (Status_reg[2]==1'b0 && Status_reg[3]==1'b0 &&
                                Status_reg[4]==1'b0 )
                                next_state = BULK_ER;
                        end
                        else if (Instruct == DP)
                            next_state = DP_DOWN_WAIT;
                        else
                            next_state = IDLE;
                    end
                end

                DP_DOWN:
                begin
                    if (~write)
                    begin
                        if (Instruct == RES_READ_ES)
                            next_state = IDLE;
                    end
                end

            endcase
        end

        if (rising_edge_PDONE)
        begin
            if (current_state==PAGE_PG)
            begin
                next_state = IDLE;
            end
        end

        if (rising_edge_WDONE)
        begin
            if (current_state==WRITE_SR)
            begin
                next_state = IDLE;
            end
        end

        if (rising_edge_EDONE)
        begin
            if (current_state==SECTOR_ER || current_state==BULK_ER)
            begin
                next_state = IDLE;
            end
        end

        if (rising_edge_DP_out)
        begin
            if (current_state==DP_DOWN_WAIT)
            begin
                next_state = DP_DOWN;
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    //FSM Output generation and general functionality
    ///////////////////////////////////////////////////////////////////////////
    reg rising_edge_read_out = 1'b0;
    reg Instruct_event       = 1'b0;
    reg change_addr_event    = 1'b0;
    reg current_state_event  = 1'b0;

    integer sector;
    integer WData [0:255];
    integer Addr;

    always @(oe_event)
    begin
        oe = 1'b1;
        #1 oe = 1'b0;
    end

    always @(rising_edge_read_out or Instruct_event or
    change_addr_event or oe or current_state_event or falling_edge_write
    or EDONE or WDONE or PDONE or CSNeg_ipd or HOLDNeg_ipd or RES_out or DP_out)
    begin: Functionality
    integer i,j;

        if (rising_edge_read_out)
        begin
            if (HOLDNeg_ipd == 1'b1 && PoweredUp == 1'b1)
                ->oe_event;
        end

        if (Instruct_event)
        begin
            read_cnt = 0;
            rd_fast = 1'b1;
            rd_slow = 1'b0;
        end

        if (Instruct_event == 1'b1 && current_state == DP_DOWN_WAIT)
        begin
             if (DP_in == 1'b1)
             begin
                  $display ("Command results can be corrupted");
             end
        end

        if (change_addr_event)
        begin
            read_addr = Address;
        end

        if (oe || current_state_event)
        begin
            case (current_state)
                IDLE :
                begin
                    if (oe && RES_in == 1'b0)
                    begin
                        if (Instruct == RDSR)
                        begin
                        //Read Status Register
                            if (serial_mode)
                            begin
                                POut_zd[7] = Status_reg[7-read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 8)
                                    read_cnt = 0;
                            end
                            else
                            begin
                                POut_zd = Status_reg;
                            end
                        end
                        else if (Instruct == READ || Instruct == FAST_READ)
                        begin
                        //Read Memory array
                            if (Instruct == READ)
                            begin
                                rd_fast = 1'b0;
                                rd_slow = 1'b1;
                            end
                            data_out[7:0] = Mem[read_addr];
                            if (serial_mode)
                            begin
                                POut_zd[7] = data_out[7-read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 8)
                                begin
                                    read_cnt = 0;
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                            end
                            else
                            begin
                                POut_zd = data_out[7:0];
                                if (read_addr == AddrRANGE)
                                    read_addr = 0;
                                else
                                    read_addr = read_addr + 1;
                            end
                        end
                        else if (Instruct == RDID)
                        begin
                        // Read ID
                            ident_out[39:0] = {DeviceID,ExtendedID};
                            if (serial_mode)
                            begin
                                POut_zd[7] = ident_out[39-read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 40)
                                    read_cnt = 0;
                            end
                            else
                            begin
                                if (prl_read_cnt == 0)
                                begin
                                    POut_zd = ident_out[39:32];
                                    prl_read_cnt = prl_read_cnt +1;
                                end
                                else if (prl_read_cnt == 1)
                                begin
                                    POut_zd = ident_out[31:24];
                                    prl_read_cnt = prl_read_cnt +1;
                                end
                                else if (prl_read_cnt == 2)
                                begin
                                    POut_zd = ident_out[23:16];
                                    prl_read_cnt = prl_read_cnt +1;
                                end
                                else if (prl_read_cnt == 3)
                                begin
                                    POut_zd = ident_out[15:8];
                                    prl_read_cnt = prl_read_cnt +1;
                                end
                                else if (prl_read_cnt == 4)
                                begin
                                    POut_zd = ident_out[7:0];
                                    prl_read_cnt = 0;
                                end
                            end
                        end
                        else if (Instruct == READ_ID)
                        begin
                        // --Read Manufacturer and Device ID
                            if (read_addr == 0)
                            begin
                                data_out[7:0] = Manuf_ID;
                                if (serial_mode)
                                begin
                                    POut_zd[7] = data_out[7-read_cnt];
                                    read_cnt = read_cnt + 1;
                                    if (read_cnt == 8)
                                    begin
                                        read_cnt = 0;
                                        read_addr = read_addr + 1;
                                    end
                                end
                                else
                                begin
                                    POut_zd = data_out[7:0];
                                    read_addr = read_addr + 1;
                                end
                            end
                            else if (read_addr == 1)
                            begin
                                data_out[7:0] = ES;
                                if (serial_mode)
                                begin
                                    POut_zd[7] = data_out[7-read_cnt];
                                    read_cnt = read_cnt + 1;
                                    if (read_cnt == 8)
                                    begin
                                        read_cnt = 0;
                                        read_addr = 0;
                                    end
                                end
                                else
                                begin
                                    POut_zd = data_out[7:0];
                                    read_addr = 0;
                                end
                            end
                        end
                    end
                    else if (oe && RES_in == 1'b1)
                    begin
                        $display ("Command results can be corrupted");
                        if (serial_mode)
                        begin
                            POut_zd[7] = 1'bX;
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                end

                WRITE_SR,
                SECTOR_ER,
                BULK_ER,
                PAGE_PG :
                begin
                    if (oe && Instruct == RDSR)
                    begin
                    //Read Status Register
                        if (serial_mode)
                        begin
                            POut_zd[7] = Status_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                        else
                        begin
                            POut_zd = Status_reg;
                        end
                    end
                end

                DP_DOWN :
                begin
                    if (oe && Instruct == RES_READ_ES)
                    begin
                    // Read ID
                        if (serial_mode)
                        begin
                            data_out[7:0] = Jedec_ID;
                            POut_zd[7] = data_out[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                        else
                        begin
                            data_out[7:0] = Jedec_ID;
                            POut_zd = data_out[7:0];
                        end
                    end
                end

            endcase
        end

        if (falling_edge_write)
        begin
            case (current_state)
                IDLE :
                begin
                    if (~write)
                    begin
                        if (RES_in == 1'b1 && Instruct != RES_READ_ES)
                        begin
                            $display ("Command results can be corrupted");
                        end
                        if (Instruct == WREN)
                            Status_reg[1] = 1'b1;
                        else if (Instruct == WRDI)
                            Status_reg[1] = 1'b0;
                        else if (Instruct == WRSR && Status_reg[1] &&
                                (~(Status_reg[7] == 1'b1 && WPNeg_ipd == 1'b0)))
                        begin
                            WSTART = 1'b1;
                            WSTART <= #1 1'b0;
                            Status_reg[0] = 1'b1;
                        end
                        else if (Instruct == PP && Status_reg[1] == 1'b1)
                        begin
                            sect = Address / 24'h40000;
                            if (Sec_Prot[sect] == 1'b0)
                            begin
                                PSTART = 1'b1;
                                PSTART <= #1 1'b0;
                                Status_reg[0] = 1'b1;
                                Addr = Address;
                                SA = sector;
                                wr_cnt = Byte_number;
                                for (i=0;i<=wr_cnt;i=i+1)
                                begin
                                    if (Viol!=1'b0)
                                        WData[i] = -1;
                                    else
                                        WData[i] = WByte[i];
                                end
                            end
                        end
                        else if (Instruct == SE && Status_reg[1] == 1'b1)
                        begin
                            sect = Address / 24'h40000;
                            if (Sec_Prot[sect] == 1'b0)
                            begin
                                ESTART = 1'b1;
                                ESTART <= #1 1'b0;
                                Status_reg[0] = 1'b1;
                                Addr = Address;
                            end
                        end
                        else if (Instruct == BE && Status_reg[1] == 1'b1 &&
                                Status_reg[2]==1'b0 && Status_reg[3]==1'b0 &&
                                Status_reg[4]==1'b0)
                        begin
                            ESTART = 1'b1;
                            ESTART <= #1 1'b0;
                            Status_reg[0] = 1'b1;
                        end
                        else if (Instruct == DP)
                        begin
                            RES_in = 1'b0;
                            DP_in = 1'b1;
                        end
                    end

                end

                DP_DOWN :
                begin
                    if (~write)
                    begin
                        if (Instruct == RES_READ_ES)
                            RES_in = 1'b1;
                    end
                end

            endcase
        end

        if(current_state_event || EDONE)
        begin
            case (current_state)

                SECTOR_ER :
                begin
                    ADDRHILO_SEC(AddrLo, AddrHi, Addr);
                    for (i=AddrLo;i<=AddrHi;i=i+1)
                    begin
                        Mem[i] = -1;
                    end

                    if (EDONE)
                    begin
                        Status_reg[0] = 1'b0;
                        Status_reg[1] = 1'b0;
                        Status_reg[6] = 1'b0;
                        for (i=AddrLo;i<=AddrHi;i=i+1)
                        begin
                            Mem[i] = MaxData;
                        end
                    end
                end

                BULK_ER :
                begin
                    for (i=0;i<=AddrRANGE;i=i+1)
                    begin
                        Mem[i] = -1;
                    end

                    if (EDONE)
                    begin
                        Status_reg[0] = 1'b0;
                        Status_reg[1] = 1'b0;
                        Status_reg[6] = 1'b0;
                        for (i=0;i<=AddrRANGE;i=i+1)
                        begin
                            Mem[i] = MaxData;
                        end
                    end
                end
            endcase
        end

        if(current_state_event || WDONE)
        begin
            if (current_state == WRITE_SR)
            begin
                if (WDONE)
                begin
                    Status_reg[0] = 1'b0;//WIP
                    Status_reg[1] = 1'b0;//WEL
                    Status_reg[6] = 1'b0;
                    Status_reg[7] = Status_reg_in[0];//MSB first, SRWD
                    Status_reg[4] = Status_reg_in[3];//MSB first, BP2
                    Status_reg[3] = Status_reg_in[4];//MSB first, BP1
                    Status_reg[2] = Status_reg_in[5];//MSB first, BP0
                    case (Status_reg[4:2])
                        3'b000 :
                        begin
                            Sec_Prot = 64'h0;
                        end

                        3'b001 :
                        begin
                            Sec_Prot[63] = 1'h1;
                            Sec_Prot[62:0] = 63'h0;
                        end

                        3'b010 :
                        begin
                            Sec_Prot[63:62] = 2'h3;
                            Sec_Prot[61:0] = 62'h0;
                        end

                        3'b011 :
                        begin
                            Sec_Prot[63:60] = 4'hF;
                            Sec_Prot[59:0] = 60'h0;
                        end

                        3'b100 :
                        begin
                            Sec_Prot[63:56] = 8'hFF;
                            Sec_Prot[55:0] = 56'h0;
                        end

                        3'b101 :
                        begin
                            Sec_Prot[63:48] = 16'hFFFF;
                            Sec_Prot[47:0] = 48'h0;
                        end

                        3'b110 :
                        begin
                            Sec_Prot[63:32] = 32'hFFFFFFFF;
                            Sec_Prot[31:0] = 32'h0;
                        end

                        3'b111 :
                        begin
                            Sec_Prot = 64'hFFFFFFFFFFFFFFFF;
                        end
                    endcase
                end
            end
        end

        if(current_state_event || PDONE)
        begin
            if (current_state == PAGE_PG)
            begin
                ADDRHILO_PG(AddrLo, AddrHi, Addr);
                if ((Addr + wr_cnt) > AddrHi)
                    wr_cnt = AddrHi - Addr;
                for (i=Addr;i<=Addr+wr_cnt;i=i+1)
                begin
                    new_int = WData[i-Addr];
                    old_int = Mem[i];
                    if (new_int > -1)
                    begin
                        new_bit = new_int;
                        if (old_int > -1)
                        begin
                            old_bit = old_int;
                            for(j=0;j<=7;j=j+1)
                                if (~old_bit[j])
                                    new_bit[j]=1'b0;
                            new_int=new_bit;
                        end

                        WData[i-Addr]= new_int;
                    end
                    else
                    begin
                        WData[i-Addr] = -1;
                    end
                end

                for (i=Addr;i<=Addr+wr_cnt;i=i+1)
                begin
                    Mem[i] = -1;
                end

                if (PDONE)
                begin
                    Status_reg[0] = 1'b0;//wip
                    Status_reg[1] = 1'b0;// wel
                    Status_reg[6] = 1'b0;
                    for (i=Addr;i<=Addr+wr_cnt;i=i+1)
                    begin
                        Mem[i] = WData[i-Addr];
                    end
                end
            end
        end

        //Output Disable Control
        if (CSNeg_ipd )
        begin
            if (serial_mode)
                POut_zd[7] = 1'bZ;
            else
                POut_zd = 8'bZZZZZZZZ;
        end

        if (RES_out)
        begin
            RES_in = 1'b0;
        end

        if (DP_out)
        begin
            DP_in = 1'b0;
        end

    end

    assign fast_rd = rd_fast;
    assign rd = rd_slow;

    always @(POut_zd or HOLDNeg_ipd)
    begin
        if (HOLDNeg_ipd == 1)
        begin
           if (serial_mode)
               POut_z[7] = POut_zd[7];
           else
               POut_z = POut_zd;
        end
        else
        begin
           if (serial_mode)
           begin
               POut_z[7] = 1'bZ;
           end
           else
           begin
               POut_z = 8'bZZZZZZZZ;
           end
        end
    end

// Procedure ADDRHILO_SEC
 task ADDRHILO_SEC;
 inout  AddrLOW;
 inout  AddrHIGH;
 input   Addr;
 integer AddrLOW;
 integer AddrHIGH;
 integer Addr;
 integer sector;
 begin
    sector = Addr / 20'h40000;
    AddrLOW = sector * 20'h40000;
    AddrHIGH = sector * 20'h40000 + 20'h3FFFF;
 end
 endtask

// Procedure ADDRHILO_PG
 task ADDRHILO_PG;
 inout  AddrLOW;
 inout  AddrHIGH;
 input   Addr;
 integer AddrLOW;
 integer AddrHIGH;
 integer Addr;
 integer page;
 begin

    page = Addr / 16'h100;
    AddrLOW = page * 16'h100;
    AddrHIGH = page * 16'h100 + 8'hFF;

 end
 endtask

    always @(negedge CSNeg_ipd)
    begin
        falling_edge_CSNeg_ipd = 1'b1;
        #1 falling_edge_CSNeg_ipd = 1'b0;
    end

    always @(posedge SCK_ipd)
    begin
        rising_edge_SCK_ipd = 1'b1;
        #1 rising_edge_SCK_ipd = 1'b0;
    end

    always @(negedge SCK_ipd)
    begin
        falling_edge_SCK_ipd = 1'b1;
        #1 falling_edge_SCK_ipd = 1'b0;
    end

    always @(posedge CSNeg_ipd)
    begin
        rising_edge_CSNeg_ipd = 1'b1;
        #1 rising_edge_CSNeg_ipd = 1'b0;
    end

    always @(negedge write)
    begin
        falling_edge_write = 1'b1;
        #1 falling_edge_write = 1'b0;
    end

    always @(posedge PDONE)
    begin
        rising_edge_PDONE = 1'b1;
        #1 rising_edge_PDONE = 1'b0;
    end

    always @(posedge WDONE)
    begin
        rising_edge_WDONE = 1'b1;
        #1 rising_edge_WDONE = 1'b0;
    end

    always @(posedge EDONE)
    begin
        rising_edge_EDONE = 1'b1;
        #1 rising_edge_EDONE = 1'b0;
    end

    always @(posedge DP_out)
    begin
        rising_edge_DP_out = 1'b1;
        #1 rising_edge_DP_out = 1'b0;
    end

    always @(read_out)
    begin
        rising_edge_read_out = 1'b1;
        #1 rising_edge_read_out = 1'b0;
    end

    always @(Instruct)
    begin
        Instruct_event = 1'b1;
        #1 Instruct_event = 1'b0;
    end

    always @(change_addr)
    begin
        change_addr_event = 1'b1;
        #1 change_addr_event = 1'b0;
    end

    always @(current_state)
    begin
        current_state_event = 1'b1;
        #1 current_state_event = 1'b0;
    end

endmodule
