//===============================================================================
//
//          FILE:  altera_ddr_top.v
// 
//         USAGE:  
// 
//   DESCRIPTION:  WishBone interface for Altera DDR SDRAM Controller
//   		   This verion is just for 32MB SDRAM
//   		   wb_err_o will be asserted while wb_add_i > 32MB
//
//   		   Read proformance is very low because we have to
//   		   wait for the local_rdata_vaild available, and then
//   		   generate the wb_ack_o. In fact, we have not use the
//   		   buast read, I don't know how to implement it currently.
// 
//       OPTIONS:  ---
//  REQUIREMENTS:  ---
//          BUGS:  ---
//         NOTES:  ---
//        AUTHOR:  Xianfeng Zeng (ZXF), xianfeng.zeng@gmail.com
//                                      xianfeng.zeng@SierraAtlantic.com
//       COMPANY:  
//       VERSION:  1.0
//       CREATED:  10/09/2009 12:58:10 PM HKT
//      REVISION:  ---
//===============================================================================

module altera_ddr_top (
  // Wishbine interface
  wb_clk_i, wb_rst_i,

  wb_dat_i, wb_dat_o, wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i,
  wb_stb_i, wb_ack_o, wb_err_o,


  // reset to ddr core
  global_reset_n_i,

  // global output
  reset_request_n_o,

  // to DDR SDRAM

  ddr_pll_clk_i,

  mem_cs_n_o,
  mem_cke_o,
  mem_addr_o,
  mem_ba_o,
  mem_ras_n_o,
  mem_cas_n_o,
  mem_we_n_o,
  mem_dm_o,
  mem_clk_io,
  mem_clk_n_io,
  mem_dq_io,
  mem_dqs_io
);

//
// Paraneters
//
parameter	wb_Idle  = 4'b1000,
		wb_Read  = 4'b0100,
		wb_Write = 4'b0010,
		wb_Ack   = 4'b0001;

parameter	ddr_Idle  		= 6'b100000,
		ddr_Read		= 6'b010000,
		ddr_Wait_data_vaild	= 6'b001000,
		ddr_Wait_wb_Ack		= 6'b000100,
		ddr_Write		= 6'b000010,	
		ddr_Set_locale_ready_reg= 6'b000001;

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
// DDR I/O Ports
//

input		ddr_pll_clk_i;
input 		global_reset_n_i;

output	[0:0]	mem_cs_n_o;
output	[0:0]	mem_cke_o;
output	[12:0]	mem_addr_o;
output	[1:0]	mem_ba_o;
output		mem_ras_n_o;
output		mem_cas_n_o;
output		mem_we_n_o;
output	[1:0]	mem_dm_o;

output		reset_request_n_o;

inout	[0:0]	mem_clk_io;
inout	[0:0]	mem_clk_n_io;
inout	[15:0]	mem_dq_io;
inout	[1:0]	mem_dqs_io;


//
// Internal singal for DDR core
//
wire	[22:0]	local_address;
wire		local_write_req;
wire		local_read_req;
wire		local_burstbegin;
wire	[31:0]	local_wdata;
wire		local_ready;
wire	[31:0]	local_rdata;
wire		local_rdata_valid;

wire		local_refresh_ack;
wire		local_wdata_req;
wire		local_init_done;
wire		reset_phy_clk_n;

wire		phy_clk;
wire		aux_full_rate_clk;
wire		aux_half_rate_clk;

reg 		local_ready_reg;
reg		local_rdata_valid_reg;

//
// Internal regs and wires
//

reg [31:0]	data_save;
wire 		wb_err;

reg [3:0]	wb_State;
reg [5:0]	ddr_State;


//
// Altera DDR SDRAM Controller
// with
// 	1. Alvon interface
// 	2. Full speed
//
altera_ddr ddr(
	// input
	.local_address		(local_address),
	.local_write_req	(local_write_req),
	.local_read_req		(local_read_req),
	.local_burstbegin	(local_burstbegin),
	.local_wdata		(local_wdata),

	.local_be		(wb_sel_i),
	.local_size		(2'b01),
	.global_reset_n		(global_reset_n_i),
	.pll_ref_clk		(ddr_pll_clk_i),
	.soft_reset_n		(1'b1),

	//output
	.local_ready		(local_ready),
	.local_rdata		(local_rdata),
	.local_rdata_valid	(local_rdata_valid),
	.reset_request_n	(reset_request_n_o),
	.mem_cs_n		(mem_cs_n_o),
	.mem_cke		(mem_cke_o),
	.mem_addr		(mem_addr_o),
	.mem_ba			(mem_ba_o),
	.mem_ras_n		(mem_ras_n_o),
	.mem_cas_n		(mem_cas_n_o),
	.mem_we_n		(mem_we_n_o),
	.mem_dm			(mem_dm_o),
	.local_refresh_ack	(local_refresh_ack),
	.local_wdata_req	(local_wdata_req),
	.local_init_done	(local_init_done),
	.reset_phy_clk_n	(reset_phy_clk_n),
	.phy_clk		(phy_clk),
	.aux_full_rate_clk	(aux_full_rate_clk),
	.aux_half_rate_clk	(aux_half_rate_clk),

	//inout
	.mem_clk		(mem_clk_io),
	.mem_clk_n		(mem_clk_n_io),
	.mem_dq			(mem_dq_io),
	.mem_dqs		(mem_dqs_io)
);

//
// Aliases and simple assignments
//
assign wb_err = wb_cyc_i & wb_stb_i & (|wb_adr_i[26:25]);	// If Access to > 32MB (4-bit leading prefix ignored)
assign wb_err_o = wb_err;

//
// State Machine for Wishbone side
//
always @ (negedge wb_clk_i or posedge wb_rst_i)
begin
	if (wb_rst_i) begin
		wb_State <= wb_Idle;
	end
	else
		case (wb_State)
			wb_Idle: begin
				if (!local_init_done)
					wb_State <= wb_Idle;
				else if (wb_cyc_i & wb_stb_i) begin
					if (wb_we_i)
						wb_State <= wb_Write;
					else
						wb_State <= wb_Read;
				end
			end

			wb_Read: begin
				if (local_rdata_valid_reg)
					wb_State <= wb_Ack;
			end

			wb_Ack: begin
				wb_State <= wb_Idle;
			end

			wb_Write: begin
				if (local_ready_reg)
					wb_State <= wb_Ack;
			end

			default: wb_State <= wb_Idle;
		endcase
end

//
// State Machine for DDR SDRAM Core side
//

always @ (posedge phy_clk or posedge wb_rst_i)
begin
	if (wb_rst_i) begin
		ddr_State <= ddr_Idle;
		local_ready_reg <= 1'b0;
		local_rdata_valid_reg <= 1'b0;
	end
	else
		case (ddr_State)
			ddr_Idle: begin

//				local_address <= {23{1'b0}};

				if (!local_init_done)
					ddr_State <= ddr_Idle;
				else if (wb_State == wb_Write)
					ddr_State <= ddr_Write;
				else if (wb_State == wb_Read)
					ddr_State <= ddr_Read;

				// These signals are used to triger wb enter
				// ACK state, so they need to be reset when in
				// wb_Ack state 
				if (wb_State == wb_Ack) begin
					local_ready_reg <= 1'b0;
					local_rdata_valid_reg <= 1'b0;
				end

			end

			ddr_Read: begin
//				local_address <= wb_adr_i[24:2];
				
				if (local_ready)
					ddr_State <= ddr_Wait_data_vaild;

			end
			ddr_Wait_data_vaild: begin
				if (local_rdata_valid) begin
					data_save <= local_rdata;

					local_rdata_valid_reg <= 1'b1; // Triger wb_ack to happen
					ddr_State <= ddr_Wait_wb_Ack;
				end
			end

			ddr_Wait_wb_Ack: begin
				if (wb_State == wb_Ack)
					ddr_State <= ddr_Idle;
			end

			ddr_Write: begin

				if (local_ready)
					ddr_State <= ddr_Set_locale_ready_reg;
			end

			ddr_Set_locale_ready_reg: begin

				local_ready_reg <= 1'b1; // let wb State Machine enter wb_Ack state

				if (wb_State == wb_Ack)
					ddr_State <= ddr_Idle;
			end

			default: ddr_State <= ddr_Idle;
		endcase
end


assign wb_dat_o = data_save;
assign wb_ack_o = (wb_State == wb_Ack) ? 1'b1 : 1'b0;

assign local_burstbegin = (ddr_State == ddr_Write) ? 1'b1 : 
			  (ddr_State == ddr_Read)  ? 1'b1 : 1'b0;
assign local_write_req  = (ddr_State == ddr_Write) ? 1'b1 : 1'b0;
assign local_read_req   = (ddr_State == ddr_Read)  ? 1'b1 : 1'b0;
assign local_wdata      = (ddr_State == ddr_Write) ? wb_dat_i       : {32{1'b0}};
assign local_address    = (ddr_State == ddr_Write) ? wb_adr_i[24:2] : 
			  (ddr_State == ddr_Read)  ? wb_adr_i[24:2] : {32{1'b0}};


//
// SDRAM i/f monitor
//
// synopsys translate_off
integer fsdram;
initial begin
	fsdram = $fopen("sdram.log");
end
always @(posedge wb_clk_i)
        if (wb_cyc_i)
                if (wb_State == wb_Ack)
			if (wb_we_i)
                        	$fdisplay(fsdram, "%t [%h] <- write %h, byte sel %b", $time, wb_adr_i, wb_dat_i, wb_sel_i);
                	else
                        	$fdisplay(fsdram, "%t [%h] -> read %h byte sel %b", $time, wb_adr_i, wb_dat_o, wb_sel_i);
// synopsys translate_on

endmodule


