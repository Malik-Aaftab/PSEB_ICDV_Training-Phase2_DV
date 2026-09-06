`timescale 1ns / 1ps

module top;

    localparam int ADDR_WIDTH = 7;
    localparam int DATA_WIDTH = 32;


    //==============================================================
    // Clock / Reset
    //==============================================================

    logic ACLK;
    logic ARESETN;

    initial ACLK = 1'b0;

    always #5 ACLK = ~ACLK;


    initial begin

        ARESETN = 1'b0;

        repeat (3) @(posedge ACLK);

        ARESETN = 1'b1;

    end


    //==============================================================
    // AXI-Lite Interface
    //==============================================================

    axi_lite_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) axi();


    //==============================================================
    // DUT
    //==============================================================

    axi_lite_regfile #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .ACLK    (ACLK),
        .ARESETN (ARESETN),
        .axi     (axi)
    );


    //==============================================================
    // TESTBENCH
    //==============================================================

    axi_lite_regfile_tb #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) tb (
        .ACLK    (ACLK),
        .ARESETN (ARESETN),
        .axi     (axi)
    );

endmodule
