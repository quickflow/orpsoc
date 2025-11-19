// ============================================================
// Wishbone im2col: IFM[H x W x Cin] -> rows of Kh*Kw*Cin
// ============================================================
module im2col_wb #
(
    parameter MAX_H    = 128,
    parameter MAX_W    = 128,
    parameter MAX_CIN  = 32,
    parameter MAX_KH   = 7,
    parameter MAX_KW   = 7
)
(
    input  wire        clk,
    input  wire        rst,

    // Wishbone
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    input  wire        wb_we_i,
    input  wire [3:0]  wb_sel_i,
    input  wire        wb_stb_i,
    input  wire        wb_cyc_i,
    output reg         wb_ack_o,

    output reg         irq
);
    reg        start;
    reg        busy, done;

    reg [7:0]  H, W, Cin;
    reg [7:0]  Kh, Kw, stride, pad;

    // Effective dims with padding
    wire [15:0] H_eff = H + (pad<<1);
    wire [15:0] W_eff = W + (pad<<1);

    // Output dims
    wire [15:0] H_out = (H_eff >= Kh) ? ((H_eff - Kh)/stride + 1) : 0;
    wire [15:0] W_out = (W_eff >= Kw) ? ((W_eff - Kw)/stride + 1) : 0;

    // Vector length per patch row
    wire [15:0] VEC_LEN = Kh * Kw * Cin;
    wire [31:0] TOTAL_ROWS = H_out * W_out;

    localparam integer IFM_CAP = MAX_H * MAX_W * MAX_CIN;
    localparam integer IM2_CAP = MAX_H * MAX_W * MAX_KH * MAX_KW * MAX_CIN;

    reg [7:0] IFM_mem [0:IFM_CAP-1];
    reg [7:0] IM2_mem [0:IM2_CAP-1];

    // Wishbone map (for im2col):
    // 0x000 CTRL       : [0]=start
    // 0x004 STATUS     : [0]=busy, [1]=done
    // 0x008 DIMS       : {8'h00, Cin, H, W}
    // 0x00C KCFG       : {pad, stride, Kh, Kw}
    // 0x1000.. IFM     : input feature map
    // 0x2000.. IM2     : im2col output rows

    always @(posedge clk) begin
        if (rst) begin
            wb_ack_o <= 1'b0;
            wb_dat_o <= 32'h0;
            start    <= 1'b0;
            busy     <= 1'b0;
            done     <= 1'b0;
            H <= 0; W <= 0; Cin <= 0;
            Kh <= 0; Kw <= 0; stride <= 1; pad <= 0;
            irq <= 1'b0;
        end else begin
            wb_ack_o <= 1'b0;
            irq      <= done;

            if (wb_stb_i && wb_cyc_i && !wb_ack_o) begin
                wb_ack_o <= 1'b1;
                if (wb_we_i) begin
                    case (wb_adr_i[11:0])
                        12'h000: start <= wb_dat_i[0];
                        12'h008: begin W<=wb_dat_i[7:0]; H<=wb_dat_i[15:8]; Cin<=wb_dat_i[23:16]; end
                        12'h00C: begin
                            Kw     <= wb_dat_i[7:0];
                            Kh     <= wb_dat_i[15:8];
                            stride <= (wb_dat_i[23:16]==8'd0)?8'd1:wb_dat_i[23:16];
                            pad    <= wb_dat_i[31:24];
                        end
                        default: begin
                            if (wb_adr_i >= 32'h00001000 && wb_adr_i < 32'h00002000)
                                IFM_mem[wb_adr_i - 32'h00001000] <= wb_dat_i[7:0];
                            else if (wb_adr_i >= 32'h00002000)
                                IM2_mem[wb_adr_i - 32'h00002000] <= wb_dat_i[7:0];
                        end
                    endcase
                end else begin
                    case (wb_adr_i[11:0])
                        12'h004: wb_dat_o <= {30'h0, done, busy};
                        12'h008: wb_dat_o <= {8'h0, Cin, H, W};
                        12'h00C: wb_dat_o <= {pad, stride, Kh, Kw};
                        default: begin
                            if (wb_adr_i >= 32'h00001000 && wb_adr_i < 32'h00002000)
                                wb_dat_o <= {24'h0, IFM_mem[wb_adr_i - 32'h00001000]};
                            else if (wb_adr_i >= 32'h00002000)
                                wb_dat_o <= {24'h0, IM2_mem[wb_adr_i - 32'h00002000]};
                            else
                                wb_dat_o <= 32'h0;
                        end
                    endcase
                end
            end

            if (start) start <= 1'b0;
        end
    end

   parameter ST_IDLE=2'd0;
   parameter ST_GEN=2'd1;
   parameter ST_DONE=2'd2;

   reg [1:0] state;

    reg [15:0] oh, ow;
    reg [7:0]  kh_it, kw_it, c_it;
    reg [31:0] im2_ptr;
    integer h_in, w_in;

    function automatic [31:0] ifm_index(input integer h,input integer w,input integer c);
        begin ifm_index = (h * W + w) * Cin + c; end
    endfunction

    function automatic is_oob(input integer h,input integer w);
        begin is_oob = (h < 0) || (w < 0) || (h >= H) || (w >= W); end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state  <= ST_IDLE;
            busy   <= 1'b0;
            done   <= 1'b0;
            oh     <= 16'd0; ow <= 16'd0;
            kh_it  <= 8'd0;  kw_it <= 8'd0; c_it <= 8'd0;
            im2_ptr<= 32'd0;
        end else begin
            case (state)
                ST_IDLE: begin
                    done <= 1'b0;
                    if (H!=0 && W!=0 && Cin!=0 && Kh!=0 && Kw!=0 && stride!=0) begin
                        if (start) begin
                            busy    <= 1'b1;
                            oh      <= 16'd0; ow <= 16'd0;
                            kh_it   <= 8'd0;  kw_it <= 8'd0; c_it <= 8'd0;
                            im2_ptr <= 32'd0;
                            state   <= ST_GEN;
                        end
                    end
                end
                ST_GEN: begin
                    h_in = (oh * stride) + kh_it - pad;
                    w_in = (ow * stride) + kw_it - pad;

                    if (is_oob(h_in, w_in)) IM2_mem[im2_ptr] <= 8'h00;
                    else IM2_mem[im2_ptr] <= IFM_mem[ ifm_index(h_in, w_in, c_it) ];

                    // advance inner indices
                    if (c_it == Cin - 1) begin
                        c_it <= 8'd0;
                        if (kw_it == Kw - 1) begin
                            kw_it <= 8'd0;
                            if (kh_it == Kh - 1) begin
                                kh_it <= 8'd0;
                                if (ow == W_out - 1) begin
                                    ow <= 16'd0;
                                    if (oh == H_out - 1) state <= ST_DONE;
                                    else oh <= oh + 1;
                                end else ow <= ow + 1;
                            end else kh_it <= kh_it + 1;
                        end else kw_it <= kw_it + 1;
                    end else c_it <= c_it + 1;

                    im2_ptr <= im2_ptr + 1;
                end
                ST_DONE: begin
                    busy <= 1'b0; done <= 1'b1; state<= ST_IDLE;
                end
            endcase
        end
    end

endmodule // im2col_wb
