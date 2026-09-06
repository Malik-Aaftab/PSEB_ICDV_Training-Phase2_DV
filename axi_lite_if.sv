`timescale 1ns / 1ps

interface axi_lite_if #(
    parameter int ADDR_WIDTH = 7,
    parameter int DATA_WIDTH = 32
);

    // ============================================================
    // AXI-Lite Write Address Channel
    // ============================================================
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic                  AWVALID;
    logic                  AWREADY;

    // ============================================================
    // AXI-Lite Write Data Channel
    // ============================================================
    logic [DATA_WIDTH-1:0]     WDATA;
    logic [(DATA_WIDTH/8)-1:0] WSTRB;
    logic                      WVALID;
    logic                      WREADY;

    // ============================================================
    // AXI-Lite Write Response Channel
    // ============================================================
    logic [1:0] BRESP;
    logic       BVALID;
    logic       BREADY;

    // ============================================================
    // AXI-Lite Read Address Channel
    // ============================================================
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic                  ARVALID;
    logic                  ARREADY;

    // ============================================================
    // AXI-Lite Read Data Channel
    // ============================================================
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;
    logic                  RVALID;
    logic                  RREADY;


    // ============================================================
    // DUT modport
    //
    // From the DUT's perspective:
    //   Inputs  = driven by TB/master
    //   Outputs = driven by DUT/slave
    // ============================================================
    modport dut (
        input  AWADDR,
        input  AWVALID,
        output AWREADY,

        input  WDATA,
        input  WSTRB,
        input  WVALID,
        output WREADY,

        output BRESP,
        output BVALID,
        input  BREADY,

        input  ARADDR,
        input  ARVALID,
        output ARREADY,

        output RDATA,
        output RRESP,
        output RVALID,
        input  RREADY
    );


    // ============================================================
    // TB modport
    //
    // From the TB/master's perspective:
    //   Outputs = driven by TB
    //   Inputs  = driven by DUT
    // ============================================================
    modport tb (
        output AWADDR,
        output AWVALID,
        input  AWREADY,

        output WDATA,
        output WSTRB,
        output WVALID,
        input  WREADY,

        input  BRESP,
        input  BVALID,
        output BREADY,

        output ARADDR,
        output ARVALID,
        input  ARREADY,

        input  RDATA,
        input  RRESP,
        input  RVALID,
        output RREADY
    );

endinterface
