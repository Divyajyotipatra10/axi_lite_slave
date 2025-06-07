`timescale 1ns / 1ps

module top_module#(
    parameter S_AXI_DATA_WIDTH  = 32,
    parameter S_AXI_ADDR_WIDTH  = 32,
    parameter S_AXI_MEM_DEPTH   = 8 //changes based on number of GPIO selected
)(
    //GLOBAL Signals
    input                               s_axi_clk,
    input                               s_axi_resetn,
    
    //WRITE ADDRESS Signals
    input                               s_axi_awvalid,
    input      [S_AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
    output                              s_axi_awready,

    //WRITE DATA Signals
    input                               s_axi_wvalid,
    input      [S_AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input      [S_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    output                              s_axi_wready,

    //WRITE RESPONSE Signals
    input                               s_axi_bready,
    output      [1:0]                   s_axi_bresp,
    output                              s_axi_bvalid,

    //READ ADDRESS Signals
    input                               s_axi_arvalid,
    input      [S_AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
    output                              s_axi_arready,

    //READ DATA Signals
    input                               s_axi_rready,
    output     [S_AXI_DATA_WIDTH-1:0]   s_axi_rdata,
    output      [1:0]                   s_axi_rresp,
    output                              s_axi_rvalid
    );
    
    s_axi_lite #(
    .S_AXI_ADDR_WIDTH(S_AXI_ADDR_WIDTH),
    .S_AXI_DATA_WIDTH(S_AXI_DATA_WIDTH),
    .S_AXI_MEM_DEPTH(S_AXI_MEM_DEPTH)
     )Slave(
    .s_axi_clk(s_axi_clk),
    .s_axi_resetn(s_axi_resetn),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awready(s_axi_awready),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wready(s_axi_wready),
    .s_axi_bready(s_axi_bready),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_rready(s_axi_rready),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp)
    );
endmodule
