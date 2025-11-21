module mt48lc16m16a2_model (
    // Clock and Clock Enable
    input               CLK,
    input               CKE,
    
    // Command Inputs
    input               CS_N,
    input               RAS_N,
    input               CAS_N,
    input               WE_N,
    
    // Bank Address
    input       [1:0]   BA,
    
    // Address Bus
    input       [12:0]  A,
    
    // Data Input/Output
    inout       [15:0]  DQ,
    
    // Data Mask
    input       [1:0]   DQM
);

    // Memory organization parameters
    parameter NUM_BANKS  = 4;
    parameter NUM_ROWS   = (8*1024);
    parameter NUM_COLS   = (2*256);
//    parameter NUM_COLS   = 256;
    parameter DATA_WIDTH = 16;
    
    // Memory array
    reg [DATA_WIDTH-1:0] memory [0:NUM_BANKS-1][0:NUM_ROWS-1][0:NUM_COLS-1];
    
    // Mode Register
    reg [12:0] mode_register;
    
    // Internal state
    reg [DATA_WIDTH-1:0] data_out;
    reg output_enable;
    reg [12:0] active_row [0:NUM_BANKS-1];
    reg [3:0]  bank_active;
    
    // Read state
    reg [1:0] read_latency_counter;
    reg [1:0] read_bank;
    reg [12:0] read_row;
    reg [8:0] read_col;
    reg read_pending;
    
    // Write state - FIXED: Add pipeline registers
    reg [DATA_WIDTH-1:0] write_data_reg;
    reg write_pending_reg;
    reg [1:0] write_bank_reg;
    reg [12:0] write_row_reg;
    reg [8:0] write_col_reg;

    // Bidirectional data bus
    assign DQ = output_enable ? data_out : {DATA_WIDTH{1'bz}};
    
    // FIXED: Improved command processing with proper pipelining
    always @(posedge CLK) begin
        if (CKE) begin
            // Default outputs
            output_enable <= 0;
            data_out <= {DATA_WIDTH{1'bz}};
            
            // Handle read latency counter
            if (read_pending) begin
                if (read_latency_counter > 0) begin
                    read_latency_counter <= read_latency_counter - 1;
                    if (read_latency_counter == 1) begin
                        // Output data after CAS latency
                        output_enable <= 1;
                        data_out <= memory[read_bank][read_row][read_col];
                        $display("[SDRAM] RD: data=%h from bank=%0d, row=%h, col=%h", memory[read_bank][read_row][read_col], read_bank, read_row, read_col);
                        read_pending <= 0;
                    end
                end
            end
            
            // Process pending write from previous cycle
            if (write_pending_reg) begin
                if (bank_active[write_bank_reg]) begin
                    memory[write_bank_reg][write_row_reg][write_col_reg] <= write_data_reg;
                    $display("[SDRAM] WR: bank=%0d, row=%h, col=%h, data=%h", write_bank_reg, write_row_reg, write_col_reg, write_data_reg);
                end else begin
//                    $display("[SDRAM] ERROR: Write to inactive bank %0d", write_bank_reg);
                end
                write_pending_reg <= 0;
            end
            
            // Capture new write commands
            if (CS_N == 1'b0 && RAS_N == 1'b1 && CAS_N == 1'b0 && WE_N == 1'b0) begin
                if (bank_active[BA]) begin
                    write_data_reg <= DQ;
                    write_bank_reg <= BA;
                    write_row_reg <= active_row[BA];
                    write_col_reg <= A[8:0];
                    write_pending_reg <= 1;
//                    $display("[SDRAM] CAPTURED WRITE: bank=%0d, row=%h, col=%h, data=%h", 
//                             BA, active_row[BA], A[8:0], DQ);
                end else begin
//                    $display("[SDRAM] ERROR: Write to inactive bank %0d", BA);
                end
            end
            
            // Process other commands when CS_N is low
            if (CS_N == 1'b0) begin
                // READ command
                if (RAS_N == 1'b1 && CAS_N == 1'b0 && WE_N == 1'b1) begin
                    if (bank_active[BA]) begin
                        read_pending <= 1;
                        read_latency_counter <= 2; // CAS latency = 2
                        read_bank <= BA;
                        read_row <= active_row[BA];
                        read_col <= A[8:0];
//                        $display("[SDRAM] RD: bank=%0d, row=%h, col=%h", BA, active_row[BA], A[8:0]);
                    end else begin
//                        $display("[SDRAM] ERROR: Read to inactive bank %0d", BA);
                    end
                end
                // ACTIVATE command
                else if (RAS_N == 1'b0 && CAS_N == 1'b1 && WE_N == 1'b1) begin
                    bank_active[BA] <= 1;
                    active_row[BA] <= A;
//                    $display("[SDRAM] ACTIVATE: bank=%0d, row=%h", BA, A);
                end
                // PRECHARGE command
                else if (RAS_N == 1'b0 && CAS_N == 1'b1 && WE_N == 1'b0) begin
                    if (A[10]) begin
                        // Precharge all banks
                        bank_active <= 0;
//                        $display("[SDRAM] PRECHARGE ALL BANKS");
                    end else begin
                        // Precharge specific bank
                        bank_active[BA] <= 0;
//                        $display("[SDRAM] PRECHARGE bank=%0d", BA);
                    end
                    read_pending <= 0; // Cancel any pending read
                end
                // MODE REGISTER SET
                else if (RAS_N == 1'b0 && CAS_N == 1'b0 && WE_N == 1'b0) begin
                    mode_register <= A;
                    $display("[SDRAM] MODE REGISTER SET: %h", A);
                end
            end
        end
    end

/*
    // FIXED: Initialize all arrays properly
    integer i, j, k;
    initial begin
        for (i = 0; i < NUM_BANKS; i = i + 1) begin
            bank_active[i] = 0;
            active_row[i] = 0;
            for (j = 0; j < NUM_ROWS; j = j + 1) begin
                for (k = 0; k < NUM_COLS; k = k + 1) begin
                    memory[i][j][k] = {DATA_WIDTH{1'bx}};
                end
            end
        end
        mode_register = 0;
        output_enable = 0;
        data_out = {DATA_WIDTH{1'bz}};
        read_pending = 0;
        write_pending_reg = 0;
    end
*/
   
endmodule // mt48lc16m16a2_model
