module mt48lc16m16a2_tb;

    reg CLK, CKE;
    reg CS_N, RAS_N, CAS_N, WE_N;
    reg [1:0] BA;
    reg [12:0] A;
    wire [15:0] DQ;
    reg [1:0] DQM;
    reg [15:0] dq_drive;
    reg dq_enable;
    
    integer test_pass_count = 0;
    integer test_fail_count = 0;
    
    assign DQ = dq_enable ? dq_drive : 16'hzzzz;
    
    mt48lc16m16a2_model sdram (
        .CLK(CLK), .CKE(CKE),
        .CS_N(CS_N), .RAS_N(RAS_N), .CAS_N(CAS_N), .WE_N(WE_N),
        .BA(BA), .A(A), .DQ(DQ), .DQM(DQM)
    );
    
    // Clock generation
    always #3.75 CLK = ~CLK;
    
    initial begin
        `ifdef LXT2
            $dumpfile("mt48lc16m16a2_wavedump.lxt2");
            $dumpvars(0, mt48lc16m16a2_tb);
        `endif
        
        initialize();
        power_up_sequence();
        
        // Run comprehensive tests
        test_basic_functionality();
        test_multiple_banks();
        test_different_rows();
        test_consecutive_operations();
        test_bank_interleaving();
        
        $display("\n=== FINAL TEST SUMMARY ===");
        $display("Total Tests: %0d", test_pass_count + test_fail_count);
        $display("Passed: %0d, Failed: %0d", test_pass_count, test_fail_count);
        if (test_fail_count == 0) 
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");
        
        #100;
        $finish;
    end
    
    task initialize;
    begin
        CLK = 0; CKE = 0;
        CS_N = 1; RAS_N = 1; CAS_N = 1; WE_N = 1;
        BA = 0; A = 0; DQM = 0;
        dq_drive = 0; dq_enable = 0;
        #100;
    end
    endtask
    
    task power_up_sequence;
    begin
        $display("[TB] ===== POWER UP SEQUENCE =====");
        CKE = 1;
        #100;
        
        // Precharge all
        precharge_all();
        repeat(4) @(posedge CLK);
        
        // 2x Auto refresh
        refresh();
        repeat(8) @(posedge CLK);
        refresh();
        repeat(8) @(posedge CLK);
        
        // Mode register set
        mode_register_set(13'h0020); // CAS=2, BL=1
        repeat(4) @(posedge CLK);
        
        $display("[TB] Power up sequence completed\n");
    end
    endtask
    
    // Test 1: Basic functionality
    task test_basic_functionality;
    begin
        $display("[TB] ===== TEST 1: BASIC FUNCTIONALITY =====");
        
        // Test single bank operations
        activate(0, 13'h0000);
        repeat(3) @(posedge CLK);
        
        // Write and read various patterns
        write_and_check(0, 13'h0010, 16'h1234);
        write_and_check(0, 13'h0011, 16'h5678);
        write_and_check(0, 13'h00FF, 16'hABCD);
        write_and_check(0, 13'h0100, 16'hDEAD);
        write_and_check(0, 13'h0101, 16'hBEEF);
        
        // Test data patterns
        write_and_check(0, 13'h0020, 16'h0000);
        write_and_check(0, 13'h0021, 16'hFFFF);
        write_and_check(0, 13'h0022, 16'hAAAA);
        write_and_check(0, 13'h0023, 16'h5555);
        
        precharge_bank(0);
        repeat(2) @(posedge CLK);
        
        $display("[TB] Basic functionality test completed\n");
    end
    endtask
    
    // Test 2: Multiple bank operations
    task test_multiple_banks;
    begin
        $display("[TB] ===== TEST 2: MULTIPLE BANKS =====");
        
        // Activate all 4 banks with different rows (within 13-bit range)
        activate(0, 13'h1000);  // 4096
        @(posedge CLK);
        activate(1, 13'h0800);  // 2048
        @(posedge CLK);
        activate(2, 13'h0400);  // 1024
        @(posedge CLK);
        activate(3, 13'h0001);  // 1
        repeat(2) @(posedge CLK); // Wait tRCD
        
        // Write unique data to each bank at same column address
        write_data(0, 13'h0050, 16'hB0B0);
        write_data(1, 13'h0050, 16'hB1B1);
        write_data(2, 13'h0050, 16'hB2B2);
        write_data(3, 13'h0050, 16'hB3B3);
        
        // Read back and verify bank isolation
        read_and_check_name(0, 13'h0050, 16'hB0B0, "Bank 0 data");
        read_and_check_name(1, 13'h0050, 16'hB1B1, "Bank 1 data");
        read_and_check_name(2, 13'h0050, 16'hB2B2, "Bank 2 data");
        read_and_check_name(3, 13'h0050, 16'hB3B3, "Bank 3 data");
        
        // Write different data to different columns in each bank
        write_and_check(0, 13'h0060, 16'hC0C0);
        write_and_check(1, 13'h0070, 16'hC1C1);
        write_and_check(2, 13'h0080, 16'hC2C2);
        write_and_check(3, 13'h0090, 16'hC3C3);
        
        // Precharge banks individually
        precharge_bank(0);
        @(posedge CLK);
        precharge_bank(1);
        @(posedge CLK);
        precharge_bank(2);
        @(posedge CLK);
        precharge_bank(3);
        repeat(2) @(posedge CLK);
        
        $display("[TB] Multiple banks test completed\n");
    end
    endtask
    
    // Test 3: Different rows in same bank
    task test_different_rows;
    begin
        $display("[TB] ===== TEST 3: DIFFERENT ROWS =====");
        
        // Test row 0
        activate(0, 13'h0000);
        repeat(3) @(posedge CLK);
        write_and_check(0, 13'h0100, 16'h1111);
        precharge_bank(0);
        repeat(2) @(posedge CLK);
        
        // Test row 1
        activate(0, 13'h0001);
        repeat(3) @(posedge CLK);
        write_and_check(0, 13'h0100, 16'h2222);
        precharge_bank(0);
        repeat(2) @(posedge CLK);
        
        // Test row 0x7FF (middle of address space)
        activate(0, 13'h07FF);
        repeat(3) @(posedge CLK);
        write_and_check(0, 13'h0100, 16'h3333);
        precharge_bank(0);
        repeat(2) @(posedge CLK);
        
        // Test row 0xFFF (near end of address space)
        activate(0, 13'h0FFF);
        repeat(3) @(posedge CLK);
        write_and_check(0, 13'h0100, 16'h4444);
        precharge_bank(0);
        repeat(2) @(posedge CLK);
        
        // Verify data persistence across different row activations
        activate(0, 13'h0000);
        repeat(3) @(posedge CLK);
        read_and_check_name(0, 13'h0100, 16'h1111, "Verify Row 0 data persistence");
        precharge_bank(0);
        repeat(2) @(posedge CLK);
        
        activate(0, 13'h0001);
        repeat(3) @(posedge CLK);
        read_and_check_name(0, 13'h0100, 16'h2222, "Verify Row 1 data persistence");
        precharge_bank(0);
        repeat(2) @(posedge CLK);
        
        $display("[TB] Different rows test completed\n");
    end
    endtask
    
    // Test 4: Consecutive operations
    task test_consecutive_operations;
    begin
        $display("[TB] ===== TEST 4: CONSECUTIVE OPERATIONS =====");
        
        activate(0, 13'h0500);
        repeat(3) @(posedge CLK);
        
        // Consecutive writes
        write_data(0, 13'h0200, 16'h1111);
        write_data(0, 13'h0201, 16'h2222);
        write_data(0, 13'h0202, 16'h3333);
        write_data(0, 13'h0203, 16'h4444);
        write_data(0, 13'h0204, 16'h5555);
        
        // Consecutive reads
        read_and_check_name(0, 13'h0200, 16'h1111, "Consecutive read 0");
        read_and_check_name(0, 13'h0201, 16'h2222, "Consecutive read 1");
        read_and_check_name(0, 13'h0202, 16'h3333, "Consecutive read 2");
        read_and_check_name(0, 13'h0203, 16'h4444, "Consecutive read 3");
        read_and_check_name(0, 13'h0204, 16'h5555, "Consecutive read 4");
        
        // Mixed operations
        write_data(0, 13'h0300, 16'hAAAA);
        read_and_check_name(0, 13'h0300, 16'hAAAA, "Mixed write/read 1");
        write_data(0, 13'h0301, 16'hBBBB);
        read_and_check_name(0, 13'h0301, 16'hBBBB, "Mixed write/read 2");
        read_and_check_name(0, 13'h0200, 16'h1111, "Verify previous data");
        
        precharge_bank(0);
        repeat(2) @(posedge CLK);
        
        $display("[TB] Consecutive operations test completed\n");
    end
    endtask
    
    // Test 5: Bank interleaving
    task test_bank_interleaving;
    begin
        $display("[TB] ===== TEST 5: BANK INTERLEAVING =====");
        
        // Activate multiple banks (within 13-bit range)
        activate(0, 13'h1000);  // 4096
        activate(1, 13'h0800);  // 2048
        activate(2, 13'h0400);  // 1024
        repeat(3) @(posedge CLK);
        
        // Interleave operations across banks
        write_data(0, 13'h0100, 16'hD0D0);
        write_data(1, 13'h0100, 16'hD1D1);
        write_data(2, 13'h0100, 16'hD2D2);
        
        read_and_check_name(0, 13'h0100, 16'hD0D0, "Interleaved bank 0");
        read_and_check_name(1, 13'h0100, 16'hD1D1, "Interleaved bank 1");
        read_and_check_name(2, 13'h0100, 16'hD2D2, "Interleaved bank 2");
        
        // More complex interleaving
        write_data(0, 13'h0200, 16'hE0E0);
        read_and_check_name(1, 13'h0100, 16'hD1D1, "Read bank 1 during bank 0 ops");
        write_data(2, 13'h0200, 16'hE2E2);
        read_and_check_name(0, 13'h0200, 16'hE0E0, "Read bank 0 during bank 2 ops");
        write_data(1, 13'h0200, 16'hE1E1);
        read_and_check_name(2, 13'h0200, 16'hE2E2, "Read bank 2 during bank 1 ops");
        
        // Verify all data
        read_and_check_name(0, 13'h0100, 16'hD0D0, "Final verify bank 0 col 0x100");
        read_and_check_name(0, 13'h0200, 16'hE0E0, "Final verify bank 0 col 0x200");
        read_and_check_name(1, 13'h0100, 16'hD1D1, "Final verify bank 1 col 0x100");
        read_and_check_name(1, 13'h0200, 16'hE1E1, "Final verify bank 1 col 0x200");
        read_and_check_name(2, 13'h0100, 16'hD2D2, "Final verify bank 2 col 0x100");
        read_and_check_name(2, 13'h0200, 16'hE2E2, "Final verify bank 2 col 0x200");
        
        precharge_all();
        repeat(2) @(posedge CLK);
        
        $display("[TB] Bank interleaving test completed\n");
    end
    endtask
    
    // Helper tasks
    task write_and_check;
    input [1:0] bank;
    input [12:0] col;
    input [15:0] data;
    begin
        write_data(bank, col, data);
        read_and_check(bank, col, data);
    end
    endtask
    
    task write_data;
    input [1:0] bank;
    input [12:0] col;
    input [15:0] data;
    begin
        dq_enable = 1;
        dq_drive = data;
        CS_N = 0; RAS_N = 1; CAS_N = 0; WE_N = 0;
        BA = bank; A = col;
        $display("[TB] WRITE: bank=%0d, col=%h, data=%h", bank, col, data);
        @(posedge CLK);
        dq_enable = 0;
        nop();
        @(posedge CLK); // Extra cycle for write to complete
    end
    endtask
    
    task read_and_check;
    input [1:0] bank;
    input [12:0] col;
    input [15:0] expected;
    begin
        // Issue read command
        CS_N = 0; RAS_N = 1; CAS_N = 0; WE_N = 1;
        BA = bank; A = col;
        $display("[TB] READ: bank=%0d, col=%h", bank, col);
        @(posedge CLK);
        nop();
        
        // Wait for CAS latency = 2 cycles
        // Data appears 2 cycles after read command
        repeat(2) @(posedge CLK);
        
        // Check data on the bus at the right time
        @(negedge CLK); // Sample data when clock is low for stability
        
        // Check data on the bus
        if (DQ === expected) begin
            $display("[PASS] Data %h matches expected %h", DQ, expected);
            test_pass_count = test_pass_count + 1;
        end else begin
            $display("[FAIL] Got %h, expected %h", DQ, expected);
            test_fail_count = test_fail_count + 1;
        end
        
        @(posedge CLK);
    end
    endtask
    
    task read_and_check_name;
    input [1:0] bank;
    input [12:0] col;
    input [15:0] expected;
    input [80:0] test_name;
    begin
        // Issue read command
        CS_N = 0; RAS_N = 1; CAS_N = 0; WE_N = 1;
        BA = bank; A = col;
        $display("[TB] READ: bank=%0d, col=%h", bank, col);
        @(posedge CLK);
        nop();
        
        // Wait for CAS latency = 2 cycles
        // Data appears 2 cycles after read command
        repeat(2) @(posedge CLK);
        
        // Check data on the bus at the right time
        @(negedge CLK); // Sample data when clock is low for stability
        
        // Check data on the bus
        if (DQ === expected) begin
            $display("[PASS] %s: Data %h matches expected %h", test_name, DQ, expected);
            test_pass_count = test_pass_count + 1;
        end else begin
            $display("[FAIL] %s: Got %h, expected %h", test_name, DQ, expected);
            test_fail_count = test_fail_count + 1;
        end
        
        @(posedge CLK);
    end
    endtask
    
    task activate;
    input [1:0] bank;
    input [12:0] row;
    begin
        CS_N = 0; RAS_N = 0; CAS_N = 1; WE_N = 1;
        BA = bank; A = row;
        $display("[TB] ACTIVATE: bank=%0d, row=%h", bank, row);
        @(posedge CLK);
        nop();
    end
    endtask
    
    task precharge_bank;
    input [1:0] bank;
    begin
        CS_N = 0; RAS_N = 0; CAS_N = 1; WE_N = 0;
        BA = bank; A = 13'h0000;
        $display("[TB] PRECHARGE bank=%0d", bank);
        @(posedge CLK);
        nop();
    end
    endtask
    
    task precharge_all;
    begin
        CS_N = 0; RAS_N = 0; CAS_N = 1; WE_N = 0;
        BA = 0; A = 13'h0400;
        $display("[TB] PRECHARGE ALL BANKS");
        @(posedge CLK);
        nop();
    end
    endtask
    
    task refresh;
    begin
        CS_N = 0; RAS_N = 0; CAS_N = 0; WE_N = 1;
        BA = 0; A = 0;
        $display("[TB] REFRESH");
        @(posedge CLK);
        nop();
    end
    endtask
    
    task mode_register_set;
    input [12:0] value;
    begin
        CS_N = 0; RAS_N = 0; CAS_N = 0; WE_N = 0;
        BA = 0; A = value;
        $display("[TB] MODE REGISTER SET: %h", value);
        @(posedge CLK);
        nop();
    end
    endtask
    
    task nop;
    begin
        CS_N = 1; RAS_N = 1; CAS_N = 1; WE_N = 1;
        BA = 0; A = 0;
    end
    endtask

endmodule // mt48lc16m16a2_tb
