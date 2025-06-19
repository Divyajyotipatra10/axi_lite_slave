`timescale 1ns / 1ps

module s_axi_lite #(
    parameter S_AXI_DATA_WIDTH  = 32,
    parameter S_AXI_ADDR_WIDTH  = 32,
    parameter S_AXI_MEM_DEPTH   = 8 
)
(
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
//local parameter declaration
localparam AW_HS = 0, AW_WT = 1; //0 - Wait until AW_HS done, 1 - Wait until B_HS  done
localparam W_WT  = 0, W_HS  = 1; //0 - Wait until AW_HS done, 1 - Wait until W_HS  done
localparam B_WT  = 0, B_HS  = 1; //0 - Wait until W_HS  done, 1 - Wait until B_HS  done
localparam AR_HS = 0, AR_WT = 1; //0 - Wait until AR_HS done, 1 - Wait until R_HS  done
localparam R_WT  = 0, R_HS  = 1; //0 - Wait until AR_HS done, 1 - Wait until R_HS  done
//Reg Declaration
reg [S_AXI_ADDR_WIDTH-1:0] awaddr  = 0; //Initial address being 0. //Word Address based. Byte address is right shifted by 2 for proper addressing
reg                        awready = 0; //Initial awready is kept 0.
reg                        awstate = 0; //State machine for write address

reg                        wready  = 0; //Initial wready is kept 0.
reg                        wstate  = 0; //State machine for write data

reg      [1:0]             bresp   = 0; //Initial bresp is kept 0 (OKAY)
reg                        bvalid  = 0; //Initial bvalid is kept 0.
reg                        bstate  = 0; //State machine for write response

reg [S_AXI_ADDR_WIDTH-1:0] araddr  = 0; //Initial address being 0.
reg                        arready = 0; //Initial arready is kept 0.
reg                        arstate = 0; //State machine for read address

reg [S_AXI_DATA_WIDTH-1:0] rdata   = 0; //Initial rready kept zero.
reg      [1:0]             rresp   = 0; //Initial rresp kept zero (OKAY)
reg                        rvalid  = 0; //Initial rvalid kept zero.
reg                        rstate  = 0; //State machine for read data

reg [S_AXI_DATA_WIDTH-1:0] slv_mem [0:S_AXI_MEM_DEPTH-1]; //Register array, 0 for GPIO 0, 1 for GPIO 0 direction and goes on
integer i = 0;
initial begin
    for(i = 0;i <S_AXI_MEM_DEPTH;i = i + 1) begin
        slv_mem[i] = 0;
    end
end
//Reg for 
//Wire Declaration
wire    aw_handshake = s_axi_awvalid & s_axi_awready; //Write address handshake
wire    w_handshake  = s_axi_wvalid  & s_axi_wready;  //Write data handshake
wire    b_handshake  = s_axi_bready  & s_axi_bvalid;  //Write response handshake

wire    ar_handshake = s_axi_arvalid & s_axi_arready; //Read address handshake
wire    r_handshake  = s_axi_rready  & s_axi_rvalid;  //Read data handshake

//FLAGS(Includes ERROR Flags for generating Write Response as well)
wire    addr_err     = (awaddr >= S_AXI_MEM_DEPTH); //ADDRESS BEYOND VALID RANGE
wire    slv_err      = addr_err;// | data_wr_err; //SLV ERROR

wire    invalid_read = (s_axi_araddr>>2)>=S_AXI_MEM_DEPTH;
//Assign Statements
assign  s_axi_awready = awready;
assign  s_axi_wready  = wready;
assign  s_axi_bvalid  = bvalid;
assign  s_axi_bresp   = bresp;

assign  s_axi_arready = arready;
assign  s_axi_rdata   = rdata;
assign  s_axi_rresp   = rresp;
assign  s_axi_rvalid  = rvalid;
//Always blocks
always @(posedge s_axi_clk) begin //Write address Process Block
    if(!s_axi_resetn) begin
        awready <= 0; awstate <= AW_HS;
    end 
    else begin
        case(awstate) 
            AW_HS: begin
                if(aw_handshake) begin
                    awready <= 0;
                    awaddr  <= s_axi_awaddr >> 2; //Latching the address just in case s_axi_awaddr is changed right after Handshake.
                    awstate <= AW_WT;
                end
                else awready <= 1;
            end
            AW_WT: begin
                if(b_handshake) begin
                    awready <= 1;
                    awstate <= AW_HS;
                end
                else awready <= 0;
            end
            default: awstate <= AW_HS;
        endcase 
    end
end

always @(posedge s_axi_clk) begin   //Write Data State Machine
    if(!s_axi_resetn) begin
        wstate <= W_WT; wready <= 0;
        /*for(i = 0; i<S_AXI_MEM_DEPTH; i = i + 1) begin
            slv_mem[i] <= 0;
        end*/
    end
    else begin
        case(wstate)
            W_WT: begin
                if(aw_handshake) begin
                    wready <= 1;
                    wstate <= W_HS;
                end
                else wready <= 0;
            end
            W_HS: begin
                if(w_handshake) begin
                    wready <= 0;
                    wstate <= W_WT;
                    if(!addr_err) begin //FOR AXI LITE TESTING
                        for(i = 0; i <S_AXI_DATA_WIDTH/8; i = i + 1) begin
                            if(s_axi_wstrb[i]) slv_mem[awaddr][8*i+:8] <= s_axi_wdata[8*i+:8];
                        end
                    end
                end
            end
            default: wstate <=W_WT;
        endcase
    end
end

always @(posedge s_axi_clk) begin   //Write Response State Machine
    if(!s_axi_resetn) begin
        bstate <= B_WT; bvalid <= 0;
    end
    else begin
        case(bstate)
            B_WT: begin
                if(w_handshake) begin
                    bresp  <= slv_err ? 2'b10:2'b00;
                    bvalid <= 1;
                    bstate <= B_HS; 
                end
                else bvalid <= 0;
            end
            B_HS: begin
                if(b_handshake) begin
                    bstate <= B_WT;
                    bvalid <= 0;
                end
                else bvalid <= 1;
            end
            default : bstate <= B_WT;
        endcase
    end
end

always @(posedge s_axi_clk) begin          //Read Address State Machine
    if(!s_axi_resetn) begin
        arstate <= AR_HS; arready <= 0;
    end
    else begin
        case (arstate)
            AR_HS: begin
                if(ar_handshake) begin
                    arready <= 0;
                    arstate <= AR_WT;
                    araddr  <= s_axi_araddr >> 2;
                end
                else arready <= 1;
            end 
            AR_WT: begin
                if(r_handshake) begin
                    arready <= 1;
                    arstate <= AR_HS;
                end
                else arready <= 0;
            end
            default: arstate <= AR_HS;
        endcase
    end
end

always @(posedge s_axi_clk) begin
    if(!s_axi_resetn) begin
        rstate <= R_WT; rvalid <= 0;
    end
    else begin
        case (rstate)
            R_WT: begin
                if(ar_handshake) begin
                    rvalid <= 1;
                    if(invalid_read) begin 
                        rresp <= 2'b10;
                        rdata <= 0;
                    end
                    else begin
                        rresp <= 2'b00;
                        rdata <= slv_mem[s_axi_araddr>>2];
                    end                                  
                    rstate <= R_HS;
                end
                else rvalid <= 0;
            end
            R_HS: begin
                if(r_handshake) begin
                    rvalid <= 0;
                    rstate <= R_WT;
                end
                else rvalid <= 1;
            end
            default: rstate <= R_WT; 
        endcase
    end
end
endmodule
