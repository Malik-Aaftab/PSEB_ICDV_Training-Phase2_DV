`timescale 1ns / 1ps

module axi_lite_regfile_tb #(
    parameter int ADDR_WIDTH = 7,
    parameter int DATA_WIDTH = 32
)(
    input logic ACLK,
    input logic ARESETN,

    axi_lite_if.tb axi
);

    int errors = 0;

    logic [DATA_WIDTH-1:0] rdata;


    //==================================================================
    // AXI WRITE TASK
    //==================================================================

    task automatic axi_write(
        input logic [ADDR_WIDTH-1:0] addr,
        input logic [DATA_WIDTH-1:0] data,
        input logic [(DATA_WIDTH/8)-1:0] strb = 4'hF
    );

        // Drive transaction
        @(posedge ACLK);

        axi.AWADDR  <= addr;
        axi.AWVALID <= 1'b1;

        axi.WDATA   <= data;
        axi.WSTRB   <= strb;
        axi.WVALID  <= 1'b1;

        axi.BREADY  <= 1'b1;


        // Wait for both channels to handshake
        while (!(axi.AWREADY && axi.WREADY))
            @(posedge ACLK);


        @(posedge ACLK);

        axi.AWVALID <= 1'b0;
        axi.WVALID  <= 1'b0;


        // Wait for write response
        while (!axi.BVALID)
            @(posedge ACLK);


        if (axi.BRESP !== 2'b00) begin

            $display(
                "ERROR: write addr=%0d BRESP=%b",
                addr,
                axi.BRESP
            );

            errors++;

        end


        // Response handshake
        @(posedge ACLK);

        axi.BREADY <= 1'b0;

    endtask


    //==================================================================
    // AXI READ TASK
    //==================================================================

    task automatic axi_read(
        input logic [ADDR_WIDTH-1:0] addr,
        output logic [DATA_WIDTH-1:0] data
    );

        @(posedge ACLK);

        axi.ARADDR  <= addr;
        axi.ARVALID <= 1'b1;

        axi.RREADY  <= 1'b1;


        // Wait for AR handshake
        while (!axi.ARREADY)
            @(posedge ACLK);


        @(posedge ACLK);

        axi.ARVALID <= 1'b0;


        // Wait for RVALID
        while (!axi.RVALID)
            @(posedge ACLK);


        data = axi.RDATA;


        if (axi.RRESP !== 2'b00) begin

            $display(
                "ERROR: read addr=%0d RRESP=%b",
                addr,
                axi.RRESP
            );

            errors++;

        end


        @(posedge ACLK);

        axi.RREADY <= 1'b0;

    endtask


    //==================================================================
    // INCLUDE COVERAGE TEST TASKS
    //
    // The following file contains:
    //     test_aw_first()
    //     test_w_first()
    //     test_write_backpressure()
    //     test_read_backpressure()
    //     test_read_idle()
    //     test_write_idle()
    //     test_all_wstrb()
    //     test_address_coverage()
    //     test_signal_toggles()
    //     run_coverage_tests()
    //
    // It is included here so those tasks can access:
    //     ACLK
    //     ARESETN
    //     axi
    //     rdata
    //     errors
    //     axi_write()
    //     axi_read()
    //==================================================================

    `include "axi_lite_coverage_tasks.svh"


    //==================================================================
    // TESTBENCH INITIALIZATION
    //==================================================================

    initial begin

        //==============================================================
        // Initialize interface
        //==============================================================

        axi.AWADDR  = '0;
        axi.AWVALID = 1'b0;

        axi.WDATA   = '0;
        axi.WSTRB   = '0;
        axi.WVALID  = 1'b0;

        axi.BREADY  = 1'b0;

        axi.ARADDR  = '0;
        axi.ARVALID = 1'b0;

        axi.RREADY  = 1'b0;


        //==============================================================
        // Wait for reset
        //==============================================================

        wait (ARESETN == 1'b0);

        repeat (3)
            @(posedge ACLK);

        wait (ARESETN == 1'b1);

        @(posedge ACLK);


        //==============================================================
        // RUN COVERAGE TEST SUITE
        //==============================================================

        run_coverage_tests();


        //==============================================================
        // Finish simulation
        //==============================================================

        #20;

        $finish;

    end

endmodule
