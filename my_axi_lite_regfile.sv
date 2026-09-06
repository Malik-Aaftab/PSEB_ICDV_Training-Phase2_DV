`timescale 1ns / 1ps

//======================================================================
// Register File
//======================================================================
module reg_file(
    input  logic           reg_wr,
    input  logic           clk,
    input  logic           rst,

    input  logic [4:0]     rs1_addr,
    input  logic [4:0]     rs2_addr,
    input  logic [4:0]     rd_addr,

    input  logic [31:0]    rd_data,

    output logic [31:0]    rs1_data,
    output logic [31:0]    rs2_data
);

    logic [31:0] register [0:31];

always_ff @(posedge clk)
    if (!rst) begin
        for (int i = 0; i < 32; i++)
            register[i] <= 32'd0;
    end
    else if (reg_wr) begin
        register[rd_addr] <= rd_data;
    end
    always_comb begin
        rs1_data = register[rs1_addr];
        rs2_data = register[rs2_addr];
    end

endmodule


//======================================================================
// AXI-Lite Register File
//======================================================================
module axi_lite_regfile #(
    parameter int ADDR_WIDTH = 7,
    parameter int DATA_WIDTH = 32
)(
    input logic ACLK,
    input logic ARESETN,

    axi_lite_if.dut axi
);

    localparam int REG_BITS = 5;

    //==================================================================
    // Internal register-file connections
    //==================================================================

    logic          reg_wr;

    logic [4:0]    rs1_addr;
    logic [4:0]    rs2_addr;
    logic [4:0]    rd_addr;

    logic [31:0]   rd_data;

    logic [31:0]   rs1_data;
    logic [31:0]   rs2_data;


    reg_file dut_regfile (
        .reg_wr    (reg_wr),
        .clk       (ACLK),
        .rst       (ARESETN),

        .rs1_addr  (rs1_addr),
        .rs2_addr  (rs2_addr),
        .rd_addr   (rd_addr),

        .rd_data   (rd_data),

        .rs1_data  (rs1_data),
        .rs2_data  (rs2_data)
    );


    //==================================================================
    // WRITE CHANNEL
    //==================================================================

    logic                    axi_awready;
    logic                    axi_wready;

    logic [ADDR_WIDTH-1:0]   axi_awaddr;

    always_ff @(posedge ACLK or negedge ARESETN) begin

        if (!ARESETN)
            axi_awready <= 1'b0;

        else if (~axi_awready && axi.AWVALID && axi.WVALID)
            axi_awready <= 1'b1;

        else
            axi_awready <= 1'b0;

    end


    always_ff @(posedge ACLK or negedge ARESETN) begin

        if (!ARESETN)
            axi_wready <= 1'b0;

        else if (~axi_wready && axi.WVALID && axi.AWVALID)
            axi_wready <= 1'b1;

        else
            axi_wready <= 1'b0;

    end


    always_ff @(posedge ACLK or negedge ARESETN) begin

        if (!ARESETN)
            axi_awaddr <= '0;

        else if (~axi_awready && axi.AWVALID && axi.WVALID)
            axi_awaddr <= axi.AWADDR;

    end


    //==============================================================
    // Write handshake
    //==============================================================

    logic reg_wren;

    assign reg_wren =
        axi_awready &&
        axi.AWVALID &&
        axi_wready &&
        axi.WVALID;


    //==============================================================
    // Read current register value using rs2
    //==============================================================

    assign rs2_addr = axi_awaddr[REG_BITS+1:2];


    //==============================================================
    // WSTRB merge
    //==============================================================

    logic [31:0] wdata_masked;

    always_comb begin

        wdata_masked = rs2_data;

        if (axi.WSTRB[0])
            wdata_masked[7:0] = axi.WDATA[7:0];

        if (axi.WSTRB[1])
            wdata_masked[15:8] = axi.WDATA[15:8];

        if (axi.WSTRB[2])
            wdata_masked[23:16] = axi.WDATA[23:16];

        if (axi.WSTRB[3])
            wdata_masked[31:24] = axi.WDATA[31:24];

    end


    assign rd_addr = axi_awaddr[REG_BITS+1:2];
    assign rd_data = wdata_masked;
    assign reg_wr  = reg_wren;


    assign axi.AWREADY = axi_awready;
    assign axi.WREADY  = axi_wready;


    //==================================================================
    // Write response
    //==================================================================

    logic       axi_bvalid;
    logic [1:0] axi_bresp;

    always_ff @(posedge ACLK or negedge ARESETN) begin

        if (!ARESETN) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b00;
        end

        else if (reg_wren) begin
            axi_bvalid <= 1'b1;
            axi_bresp  <= 2'b00;
        end

        else if (axi_bvalid && axi.BREADY) begin
            axi_bvalid <= 1'b0;
        end

    end


    assign axi.BVALID = axi_bvalid;
    assign axi.BRESP  = axi_bresp;


    //==================================================================
    // READ CHANNEL
    //==================================================================

    logic                  axi_arready;
    logic [ADDR_WIDTH-1:0] axi_araddr;

    logic                  axi_rvalid;
    logic [DATA_WIDTH-1:0] axi_rdata;
    logic [1:0]            axi_rresp;


    always_ff @(posedge ACLK or negedge ARESETN) begin

        if (!ARESETN)
            axi_arready <= 1'b0;

        else if (~axi_arready && axi.ARVALID)
            axi_arready <= 1'b1;

        else
            axi_arready <= 1'b0;

    end


    always_ff @(posedge ACLK or negedge ARESETN) begin

        if (!ARESETN)
            axi_araddr <= '0;

        else if (~axi_arready && axi.ARVALID)
            axi_araddr <= axi.ARADDR;

    end


    assign rs1_addr = axi_araddr[REG_BITS+1:2];


    always_ff @(posedge ACLK or negedge ARESETN) begin

        if (!ARESETN) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b00;
            axi_rdata  <= 32'd0;
        end

        else if (axi_arready &&
                 axi.ARVALID &&
                 ~axi_rvalid) begin

            axi_rvalid <= 1'b1;
            axi_rresp  <= 2'b00;
            axi_rdata  <= rs1_data;

        end

        else if (axi_rvalid && axi.RREADY) begin
            axi_rvalid <= 1'b0;
        end

    end


    assign axi.ARREADY = axi_arready;

    assign axi.RVALID  = axi_rvalid;
    assign axi.RRESP   = axi_rresp;
    assign axi.RDATA   = axi_rdata;

endmodule
