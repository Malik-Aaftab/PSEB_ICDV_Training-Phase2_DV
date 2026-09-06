//======================================================================
// AXI-Lite Coverage Tests
//
// Include this file INSIDE the axi_lite_regfile_tb module:
//
//     `include "axi_lite_coverage_tasks.svh"
//
// These tasks assume the TB contains:
//     ACLK
//     ARESETN
//     axi
//     errors
//     axi_write()
//     axi_read()
//======================================================================


//======================================================================
// TEST 5
// AWVALID asserted before WVALID
//
// Purpose:
// Exercise:
//     AWVALID = 1
//     WVALID  = 0
//
// before the write data channel becomes valid.
//======================================================================

task automatic test_aw_first;

    $display("\n============================================================");
    $display("TEST 5: AWVALID before WVALID");
    $display("============================================================");

    @(posedge ACLK);

    axi.AWADDR  <= 7'd3 << 2;
    axi.AWVALID <= 1'b1;

    axi.WDATA   <= 32'hAAAA_BBBB;
    axi.WSTRB   <= 4'hF;
    axi.WVALID  <= 1'b0;

    axi.BREADY  <= 1'b1;


    // Keep AWVALID asserted while WVALID is low
    repeat (2)
        @(posedge ACLK);


    // Now assert WVALID
    axi.WVALID <= 1'b1;


    // Wait for write handshake
    while (!(axi.AWREADY && axi.WREADY))
        @(posedge ACLK);


    @(posedge ACLK);

    axi.AWVALID <= 1'b0;
    axi.WVALID  <= 1'b0;


    // Wait for response
    while (!axi.BVALID)
        @(posedge ACLK);


    if (axi.BRESP !== 2'b00) begin

        $display(
            "ERROR: AW-first write BRESP = %b",
            axi.BRESP
        );

        errors++;

    end
    else begin

        $display("PASS: AW-first write");

    end


    @(posedge ACLK);

    axi.BREADY <= 1'b0;

endtask



//======================================================================
// TEST 6
// WVALID asserted before AWVALID
//
// Purpose:
// Exercise:
//     WVALID  = 1
//     AWVALID = 0
//
// before the address channel becomes valid.
//======================================================================

task automatic test_w_first;

    $display("\n============================================================");
    $display("TEST 6: WVALID before AWVALID");
    $display("============================================================");

    @(posedge ACLK);

    axi.AWADDR  <= 7'd4 << 2;
    axi.AWVALID <= 1'b0;

    axi.WDATA   <= 32'hCCCC_DDDD;
    axi.WSTRB   <= 4'hF;
    axi.WVALID  <= 1'b1;

    axi.BREADY  <= 1'b1;


    // Keep WVALID asserted while AWVALID is low
    repeat (2)
        @(posedge ACLK);


    // Now assert AWVALID
    axi.AWVALID <= 1'b1;


    // Wait for write handshake
    while (!(axi.AWREADY && axi.WREADY))
        @(posedge ACLK);


    @(posedge ACLK);

    axi.AWVALID <= 1'b0;
    axi.WVALID  <= 1'b0;


    // Wait for response
    while (!axi.BVALID)
        @(posedge ACLK);


    if (axi.BRESP !== 2'b00) begin

        $display(
            "ERROR: W-first write BRESP = %b",
            axi.BRESP
        );

        errors++;

    end
    else begin

        $display("PASS: W-first write");

    end


    @(posedge ACLK);

    axi.BREADY <= 1'b0;

endtask



//======================================================================
// TEST 7
// Write response backpressure
//
// Purpose:
// Exercise:
//
//     BVALID = 1
//     BREADY = 0
//
// followed by:
//
//     BVALID = 1
//     BREADY = 1
//
// This specifically targets the BREADY side of the response
// handshake.
//======================================================================

task automatic test_write_backpressure;

    $display("\n============================================================");
    $display("TEST 7: Write response backpressure");
    $display("============================================================");


    @(posedge ACLK);

    axi.AWADDR  <= 7'd6 << 2;
    axi.AWVALID <= 1'b1;

    axi.WDATA   <= 32'h1111_2222;
    axi.WSTRB   <= 4'hF;
    axi.WVALID  <= 1'b1;


    // IMPORTANT:
    // Do NOT accept BVALID immediately.
    axi.BREADY <= 1'b0;


    // Wait for write handshake
    while (!(axi.AWREADY && axi.WREADY))
        @(posedge ACLK);


    @(posedge ACLK);

    axi.AWVALID <= 1'b0;
    axi.WVALID  <= 1'b0;


    // Wait until DUT produces BVALID
    while (!axi.BVALID)
        @(posedge ACLK);


    $display("BVALID asserted while BREADY = 0");


    // Hold response for several cycles
    repeat (3)
        @(posedge ACLK);


    // Now accept response
    axi.BREADY <= 1'b1;


    @(posedge ACLK);


    if (axi.BVALID !== 1'b0) begin

        // Give DUT another clock to complete response
        @(posedge ACLK);

    end


    axi.BREADY <= 1'b0;

    $display("PASS: Write response backpressure");

endtask



//======================================================================
// TEST 8
// Read response backpressure
//
// Purpose:
// Exercise:
//
//     RVALID = 1
//     RREADY = 0
//
// followed by:
//
//     RREADY = 1
//
//======================================================================

task automatic test_read_backpressure;

    logic [DATA_WIDTH-1:0] temp_data;

    $display("\n============================================================");
    $display("TEST 8: Read response backpressure");
    $display("============================================================");


    @(posedge ACLK);

    axi.ARADDR  <= 7'd6 << 2;
    axi.ARVALID <= 1'b1;

    // Do not accept read data immediately
    axi.RREADY <= 1'b0;


    // Wait for address handshake
    while (!axi.ARREADY)
        @(posedge ACLK);


    @(posedge ACLK);

    axi.ARVALID <= 1'b0;


    // Wait for RVALID
    while (!axi.RVALID)
        @(posedge ACLK);


    $display("RVALID asserted while RREADY = 0");


    // Hold RREADY low
    repeat (3)
        @(posedge ACLK);


    // Now accept the read response
    axi.RREADY <= 1'b1;


    @(posedge ACLK);

    temp_data = axi.RDATA;


    if (axi.RRESP !== 2'b00) begin

        $display(
            "ERROR: Read backpressure RRESP = %b",
            axi.RRESP
        );

        errors++;

    end
    else begin

        $display(
            "PASS: Read response backpressure, RDATA = %h",
            temp_data
        );

    end


    @(posedge ACLK);

    axi.RREADY <= 1'b0;

endtask



//======================================================================
// TEST 9
// Read channel idle
//
// Purpose:
// Exercise ARVALID = 0 for several cycles.
//======================================================================

task automatic test_read_idle;

    $display("\n============================================================");
    $display("TEST 9: Read channel idle");
    $display("============================================================");


    axi.ARVALID = 1'b0;
    axi.RREADY  = 1'b0;

    repeat (5)
        @(posedge ACLK);


    $display("PASS: Read channel remained idle");

endtask



//======================================================================
// TEST 10
// Write channel idle
//
// Purpose:
// Exercise:
//     AWVALID = 0
//     WVALID  = 0
//     BREADY  = 0
//
// for several cycles.
//======================================================================

task automatic test_write_idle;

    $display("\n============================================================");
    $display("TEST 10: Write channel idle");
    $display("============================================================");


    axi.AWVALID = 1'b0;
    axi.WVALID  = 1'b0;
    axi.BREADY  = 1'b0;

    repeat (5)
        @(posedge ACLK);


    $display("PASS: Write channel remained idle");

endtask



//======================================================================
// TEST 11
// All WSTRB combinations
//
// Purpose:
// Exercise every possible combination of:
//
//     WSTRB[3:0]
//
// This ensures each individual WSTRB condition experiences both:
//
//     0
//     1
//
//======================================================================

task automatic test_all_wstrb;

    logic [DATA_WIDTH-1:0] original;
    logic [DATA_WIDTH-1:0] new_data;
    logic [DATA_WIDTH-1:0] expected;

    logic [3:0] strb;


    $display("\n============================================================");
    $display("TEST 11: All WSTRB combinations");
    $display("============================================================");


    // Initial value
    original = 32'h1122_3344;


    // Write initial value
    axi_write(
        7'd10 << 2,
        original
    );


    // Try all 16 WSTRB combinations
    for (int i = 0; i < 16; i++) begin

        strb     = i[3:0];
        new_data = 32'hA5A5_5A5A;


        //----------------------------------------------------------
        // Write using current WSTRB
        //----------------------------------------------------------

        axi_write(
            7'd10 << 2,
            new_data,
            strb
        );


        //----------------------------------------------------------
        // Read result
        //----------------------------------------------------------

        axi_read(
            7'd10 << 2,
            rdata
        );


        //----------------------------------------------------------
        // Calculate expected result
        //----------------------------------------------------------

        expected = original;


        if (strb[0])
            expected[7:0] = new_data[7:0];

        if (strb[1])
            expected[15:8] = new_data[15:8];

        if (strb[2])
            expected[23:16] = new_data[23:16];

        if (strb[3])
            expected[31:24] = new_data[31:24];


        //----------------------------------------------------------
        // Check
        //----------------------------------------------------------

        if (rdata !== expected) begin

            $display(
                "ERROR: WSTRB=%b expected=%h got=%h",
                strb,
                expected,
                rdata
            );

            errors++;

        end
        else begin

            $display(
                "PASS: WSTRB=%b result=%h",
                strb,
                rdata
            );

        end


        original = expected;

    end

endtask



//==================================================================
// DATA PATTERN VARIETY
// Drive all registers with FFFF_FFFF -> 0000_0000
// Ensures all register/data bits, including bit 22, toggle
// 0 -> 1 -> 0.
//==================================================================

task automatic test_data_pattern_variety;

    logic [DATA_WIDTH-1:0] temp_data;

    $display("\n============================================================");
    $display("TEST: Alternating data patterns");
    $display("============================================================");


    //--------------------------------------------------------------
    // ALL ZEROS
    //--------------------------------------------------------------

    for (int i = 0; i < 32; i++) begin

        axi_write(
            i << 2,
            32'h0000_0000
        );

        axi_read(
            i << 2,
            temp_data
        );

        if (temp_data !== 32'h0000_0000) begin

            $display(
                "ERROR: reg[%0d] expected 00000000, got %h",
                i,
                temp_data
            );

            errors++;

        end

    end


    //--------------------------------------------------------------
    // ALL ONES
    //--------------------------------------------------------------

    for (int i = 0; i < 32; i++) begin

        axi_write(
            i << 2,
            32'hFFFF_FFFF
        );

        axi_read(
            i << 2,
            temp_data
        );

        if (temp_data !== 32'hFFFF_FFFF) begin

            $display(
                "ERROR: reg[%0d] expected FFFFFFFF, got %h",
                i,
                temp_data
            );

            errors++;

        end

    end


    //--------------------------------------------------------------
    // ALL ZEROS AGAIN
    //
    // Explicitly creates:
    //
    //     0 -> 1 -> 0
    //--------------------------------------------------------------

    for (int i = 0; i < 32; i++) begin

        axi_write(
            i << 2,
            32'h0000_0000
        );

        axi_read(
            i << 2,
            temp_data
        );

        if (temp_data !== 32'h0000_0000) begin

            $display(
                "ERROR: reg[%0d] expected 00000000, got %h",
                i,
                temp_data
            );

            errors++;

        end

    end


    $display("PASS: Alternating data pattern coverage completed");

endtask



//======================================================================
// TEST 12
// Address coverage
//
// Purpose:
// Exercise different register addresses so that address bits toggle
// extensively.
//
//======================================================================

//==================================================================
// TEST: Expanded register address coverage
//
// Purpose:
// Exercise register indices >= 16 so address bit 4 becomes 1.
//
// This targets:
//     rs1_addr[4]
//     rs2_addr[4]
//     rd_addr[4]
//
// Also exercises rs1_addr[1] using multiple register indices.
//==================================================================

task automatic test_address_coverage;

    logic [DATA_WIDTH-1:0] temp_data;

    $display("\n============================================================");
    $display("TEST: Expanded register address coverage");
    $display("============================================================");


    //--------------------------------------------------------------
    // Lower register indices
    // Address bit 4 = 0
    //--------------------------------------------------------------

    axi_write(
        7'd0 << 2,
        32'h0000_0000
    );

    axi_read(
        7'd0 << 2,
        temp_data
    );


    axi_write(
        7'd1 << 2,
        32'h1111_1111
    );

    axi_read(
        7'd1 << 2,
        temp_data
    );


    axi_write(
        7'd3 << 2,
        32'h3333_3333
    );

    axi_read(
        7'd3 << 2,
        temp_data
    );


    //--------------------------------------------------------------
    // Higher register indices
    // Address bit 4 = 1
    //--------------------------------------------------------------

    axi_write(
        7'd16 << 2,
        32'hAAAA_AAAA
    );

    axi_read(
        7'd16 << 2,
        temp_data
    );


    axi_write(
        7'd17 << 2,
        32'hBBBB_BBBB
    );

    axi_read(
        7'd17 << 2,
        temp_data
    );


    axi_write(
        7'd18 << 2,
        32'hCCCC_CCCC
    );

    axi_read(
        7'd18 << 2,
        temp_data
    );


    axi_write(
        7'd19 << 2,
        32'hDDDD_DDDD
    );

    axi_read(
        7'd19 << 2,
        temp_data
    );


    axi_write(
        7'd23 << 2,
        32'hEEEE_EEEE
    );

    axi_read(
        7'd23 << 2,
        temp_data
    );


    axi_write(
        7'd24 << 2,
        32'h1234_5678
    );

    axi_read(
        7'd24 << 2,
        temp_data
    );


    axi_write(
        7'd31 << 2,
        32'hFFFF_FFFF
    );

    axi_read(
        7'd31 << 2,
        temp_data
    );


    $display("PASS: Expanded register address coverage completed");

endtask



//======================================================================
// TEST 13
// AXI signal toggling
//
// Purpose:
// Explicitly drive the master-side signals through 0 -> 1 -> 0.
// Useful for toggle coverage.
//======================================================================

task automatic test_signal_toggles;

    $display("\n============================================================");
    $display("TEST 13: AXI signal toggle stimulus");
    $display("============================================================");


    //--------------------------------------------------------------
    // AW channel
    //--------------------------------------------------------------

    axi.AWADDR  = '0;
    axi.AWVALID = 1'b0;

    @(posedge ACLK);

    axi.AWADDR  = '1;
    axi.AWVALID = 1'b1;

    @(posedge ACLK);

    axi.AWADDR  = '0;
    axi.AWVALID = 1'b0;


    //--------------------------------------------------------------
    // W channel
    //--------------------------------------------------------------

    axi.WDATA   = '0;
    axi.WSTRB   = '0;
    axi.WVALID  = 1'b0;

    @(posedge ACLK);

    axi.WDATA   = '1;
    axi.WSTRB   = '1;
    axi.WVALID  = 1'b1;

    @(posedge ACLK);

    axi.WDATA   = '0;
    axi.WSTRB   = '0;
    axi.WVALID  = 1'b0;


    //--------------------------------------------------------------
    // BREADY
    //--------------------------------------------------------------

    axi.BREADY = 1'b0;

    @(posedge ACLK);

    axi.BREADY = 1'b1;

    @(posedge ACLK);

    axi.BREADY = 1'b0;


    //--------------------------------------------------------------
    // AR channel
    //--------------------------------------------------------------

    axi.ARADDR  = '0;
    axi.ARVALID = 1'b0;

    @(posedge ACLK);

    axi.ARADDR  = '1;
    axi.ARVALID = 1'b1;

    @(posedge ACLK);

    axi.ARADDR  = '0;
    axi.ARVALID = 1'b0;


    //--------------------------------------------------------------
    // RREADY
    //--------------------------------------------------------------

    axi.RREADY = 1'b0;

    @(posedge ACLK);

    axi.RREADY = 1'b1;

    @(posedge ACLK);

    axi.RREADY = 1'b0;


    $display("PASS: AXI signal toggle stimulus completed");

endtask

//==================================================================
// TEST: Additional reset pulse
//
// Purpose:
// Exercise reset transition:
//     ARESETN: 1 -> 0 -> 1
//
// This provides additional reset coverage at the end of simulation.
//==================================================================

task automatic test_reset_pulse;

    $display("\n============================================================");
    $display("TEST: Additional reset pulse");
    $display("============================================================");

    // Ensure we are currently out of reset
    wait (ARESETN == 1'b1);

    repeat (2)
        @(posedge ACLK);

    // Assert reset
    $display("Asserting additional reset pulse");

    force ARESETN = 1'b0;

    repeat (3)
        @(posedge ACLK);

    // Release reset
    $display("Releasing additional reset pulse");

    force ARESETN = 1'b1;

    repeat (3)
        @(posedge ACLK);

    release ARESETN;

    $display("PASS: Additional reset pulse completed");

endtask


//======================================================================
// MASTER TASK
//
// Call ONLY this task from your TB initial block:
//
//     run_coverage_tests();
//
//======================================================================

task automatic run_coverage_tests;

    $display("\n");
    $display("############################################################");
    $display("#                                                          #");
    $display("#              AXI-LITE COVERAGE TESTS                    #");
    $display("#                                                          #");
    $display("############################################################");


    //--------------------------------------------------------------
    // Wait until reset is released
    //--------------------------------------------------------------

    wait (ARESETN == 1'b1);

    @(posedge ACLK);


    //--------------------------------------------------------------
    // Basic write/read
    //--------------------------------------------------------------

    $display("\nTEST 1: Basic write/read");

    axi_write(
        7'd5 << 2,
        32'hDEAD_BEEF
    );

    axi_read(
        7'd5 << 2,
        rdata
    );


    //--------------------------------------------------------------
    // Basic second register
    //--------------------------------------------------------------

    $display("\nTEST 2: Second register");

    axi_write(
        7'd10 << 2,
        32'h1234_5678
    );

    axi_read(
        7'd10 << 2,
        rdata
    );


    //--------------------------------------------------------------
    // Basic WSTRB
    //--------------------------------------------------------------

    $display("\nTEST 3: Basic WSTRB");

    axi_write(
        7'd10 << 2,
        32'h0000_00AA,
        4'b0001
    );

    axi_read(
        7'd10 << 2,
        rdata
    );


    //--------------------------------------------------------------
    // AWVALID before WVALID
    //--------------------------------------------------------------

    test_aw_first();


    //--------------------------------------------------------------
    // WVALID before AWVALID
    //--------------------------------------------------------------

    test_w_first();


    //--------------------------------------------------------------
    // BVALID/BREADY backpressure
    //--------------------------------------------------------------

    test_write_backpressure();


    //--------------------------------------------------------------
    // RVALID/RREADY backpressure
    //--------------------------------------------------------------

    test_read_backpressure();


    //--------------------------------------------------------------
    // Read channel idle
    //--------------------------------------------------------------

    test_read_idle();


    //--------------------------------------------------------------
    // Write channel idle
    //--------------------------------------------------------------

    test_write_idle();


    //--------------------------------------------------------------
    // All WSTRB combinations
    //--------------------------------------------------------------

    test_all_wstrb();


    //--------------------------------------------------------------
    // Address coverage
    //--------------------------------------------------------------

    test_address_coverage();


    //--------------------------------------------------------------
    // Toggle stimulus
    //--------------------------------------------------------------

    test_signal_toggles();
    test_reset_pulse();

    
    //--------------------------------------------------------------
    // Final result
    //--------------------------------------------------------------

    $display("\n");
    $display("############################################################");

    if (errors == 0) begin

        $display("#              ALL TESTS PASSED                         #");

    end
    else begin

        $display(
            "#              %0d TEST(S) FAILED                       #",
            errors
        );

    end

    $display("############################################################");
    $display("\n");

endtask
