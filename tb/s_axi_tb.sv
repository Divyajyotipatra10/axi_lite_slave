`timescale 1ns / 1ps

module s_axi_tb;
parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 32;
parameter MEM_DEPTH  = 8;

//TB variables
reg clk = 0;
reg resetn = 1; //Initially High(No reset)

reg awvalid = 0;
wire awready;
reg [ADDR_WIDTH-1:0]awaddr = 0;

reg wvalid = 0;
wire wready;
reg [DATA_WIDTH-1:0]wdata = 0;
reg [DATA_WIDTH/8-1:0]wstrb = 0;

wire bvalid;
reg bready = 0;
wire [1:0]bresp;

reg arvalid = 0;
wire arready;
reg [ADDR_WIDTH-1:0]araddr = 0;

wire rvalid;
reg  rready = 0;
wire [DATA_WIDTH-1:0] rdata;
wire [1:0] rresp;

//TB manager Variables
reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1]; //Memory for testing
reg [DATA_WIDTH-1:0] slv_mem [0:MEM_DEPTH-1]; //Slave memory for DUT
reg [DATA_WIDTH-1:0] expected_data; //Expected data for read operations
reg [1:0] tb_bresp, tb_rresp; //TB response variables for write and read
reg tb_awready, tb_wready, tb_bvalid ,tb_arready, tb_rvalid; //TB ready and valid signals
reg [1:0] wr_status, rd_status; //Write and Read status for TB
reg [31:0] err_count = 0; //Error count for TB
reg done = 0; //Done signal for TB
//TB Variables END

initial begin //TB variables initialization
    for(int i = 0; i < MEM_DEPTH; i++) begin
        mem[i] = 0; //Initialize memory to zero
        slv_mem[i] = 0; //Initialize slave memory to zero
    end
    tb_awready = 0;
    tb_wready = 0;
    tb_bvalid = 0;
    tb_arready = 0;
    tb_rvalid = 0;
    wr_status = 0; //Initial status for write
    rd_status = 0; //Initial status for read
    expected_data = 0; //Initialize expected data to zero
    tb_bresp = 2'b00; //OKAY response for write
    tb_rresp = 2'b00; //OKAY response for read
end

top_module #(
    .S_AXI_ADDR_WIDTH(ADDR_WIDTH),
    .S_AXI_DATA_WIDTH(DATA_WIDTH),
    .S_AXI_MEM_DEPTH(MEM_DEPTH)
)UUT(
    .s_axi_clk(clk),
    .s_axi_resetn(resetn),
    .s_axi_awvalid(awvalid),
    .s_axi_awaddr(awaddr),
    .s_axi_awready(awready),
    .s_axi_wvalid(wvalid),
    .s_axi_wdata(wdata),
    .s_axi_wstrb(wstrb),
    .s_axi_wready(wready),
    .s_axi_bready(bready),
    .s_axi_bvalid(bvalid),
    .s_axi_bresp(bresp),
    .s_axi_arvalid(arvalid),
    .s_axi_arready(arready),
    .s_axi_araddr(araddr),
    .s_axi_rready(rready),
    .s_axi_rvalid(rvalid),
    .s_axi_rdata(rdata),
    .s_axi_rresp(rresp)
);

always #5 clk = ~clk; //100 MHz Clock

always @(*) begin //To save the content from DUT
    for(int i = 0; i < MEM_DEPTH; i++) begin
        slv_mem[i] = UUT.Slave.slv_mem[i]; //Copy DUT memory to TB memory
    end
end
//Task for read and write
wire tb_awhs = (awvalid && tb_awready);
wire tb_whs = (wvalid && tb_wready);
wire tb_bhs = (tb_bvalid && bready);
wire tb_arhs = (arvalid && tb_arready);
wire tb_rhs = (tb_rvalid && rready);
//Task for read and write END
always @(posedge clk) begin  //MANAGING Write txn
    if(!resetn) begin
        tb_awready <= 0;
        tb_wready <= 0;
        tb_bvalid <= 0;
        wr_status <= 0; //Reset write status
    end
    else begin
        case(wr_status)
            0: begin //Idle State
                if(tb_awhs) begin
                    tb_awready <= 0;    
                    tb_wready <= 1;
                    wr_status <= 1; //Move to next state
                end
                else tb_awready <= 1;
            end
            1: begin //Write Address Handshake
                if(tb_whs) begin
                    tb_wready <= 0;
                    tb_bvalid <= 1; //Assert bvalid
                    wr_status <= 2; //Move to next state
                    if(!((awaddr>>2) >= MEM_DEPTH)) begin
                        for(int i=0; i<DATA_WIDTH/8; i++) begin
                            if(wstrb[i]) begin
                                mem[awaddr >> 2][i*8 +: 8] <= wdata[i*8 +: 8]; //Write data to memory
                            end
                        end
                        tb_bresp <= 2'b00; //OKAY response
                    end
                    else begin
                        tb_bresp <= 2'b10; //SLVERR response for invalid address
                    end
                end
                else tb_wready <= 1;
            end
            2: begin
                if(tb_bhs) begin
                    tb_bvalid <= 0; //Deassert bvalid
                    wr_status <= 0; //Move back to idle state
                    tb_awready <= 1; //assert awready 
                end
                else tb_bvalid <= 1;
            end
            default: begin
                tb_awready <= 0;
                tb_wready <= 0;
                tb_bvalid <= 0;
                wr_status <= 0;
            end
        endcase
    end
end

always @(posedge clk) begin
    if(!resetn) begin
        tb_arready <= 0;
        tb_rvalid <= 0;
        rd_status <= 0;
    end
    else begin
        case (rd_status)
            0: begin //Idle State
                if(tb_arhs) begin
                    tb_rvalid <= 1; //Assert rvalid
                    tb_arready <= 0;    
                    rd_status <= 1; //Move to next state
                    if((araddr>>2) < MEM_DEPTH) begin
                        expected_data <= mem[araddr >> 2]; //Read data from memory
                        tb_rresp <= 2'b00; //OKAY response
                    end
                    else begin
                        expected_data <= 0; //Invalid address, return zero
                        tb_rresp <= 2'b10; //SLVERR response for invalid address
                    end
                end
                else tb_arready <= 1;
            end
            1: begin //Read Address Handshake
                if(tb_rhs) begin
                    tb_rvalid <= 0; //Deassert rvalid
                    rd_status <= 2; //Move to next state
                    tb_arready <= 1; //Assert arready
                end
                else tb_rvalid <= 1;
            end 
            default: rd_status <= 0; //Reset read status
        endcase
    end
end

always @(posedge clk) begin
    $write("\n");
    if(arready != tb_arready) begin
        $display("ARREADY MISMATCH: Expected %b, Got %b", tb_arready, arready);
        err_count <= err_count + 1;
    end
    else begin
        $display("ARREADY MATCH: Expected %b, Got %b", tb_arready, arready);
    end
    
    if(rvalid != tb_rvalid) begin
        $display("RVALID MISMATCH: Expected %b, Got %b", tb_rvalid, rvalid);
        err_count <= err_count + 1;
    end
    else begin
        $display("RVALID MATCH: Expected %b, Got %b", tb_rvalid, rvalid);
    end

    if(rdata != expected_data) begin
        $display("RDATA MISMATCH: Expected %h, Got %h", expected_data, rdata);
        err_count <= err_count + 1;
    end
    else begin
        $display("RDATA MATCH: Expected %h, Got %h", expected_data, rdata);
    end

    if(rresp != tb_rresp) begin
        $display("RRESP MISMATCH: Expected %b, Got %b", tb_rresp, rresp);
        err_count <= err_count + 1;
    end
    else begin
        $display("RRESP MATCH: Expected %b, Got %b", tb_rresp, rresp);
    end

    if(awready != tb_awready) begin
        $display("AWREADY MISMATCH: Expected %b, Got %b", tb_awready, awready);
        err_count <= err_count + 1;
    end
    else begin
        $display("AWREADY MATCH: Expected %b, Got %b", tb_awready, awready);
    end
    
    if(wready != tb_wready) begin
        $display("WREADY MISMATCH: Expected %b, Got %b", tb_wready, wready);
        err_count <= err_count + 1;
    end
    else begin
        $display("WREADY MATCH: Expected %b, Got %b", tb_wready, wready);
    end
    
    if(bvalid != tb_bvalid) begin
        $display("BVALID MISMATCH: Expected %b, Got %b", tb_bvalid, bvalid);
        err_count <= err_count + 1;
    end
    else begin
        $display("BVALID MATCH: Expected %b, Got %b", tb_bvalid, bvalid);
    end

    if(bresp != tb_bresp) begin
        $display("BRESP MISMATCH: Expected %b, Got %b", tb_bresp, bresp);
        err_count <= err_count + 1;
    end
    else begin
        $display("BRESP MATCH: Expected %b, Got %b", tb_bresp, bresp);
    end
    // Check memory content against DUT memory    
    for(int i = 0; i < MEM_DEPTH; i++) begin
        if(mem[i] !== slv_mem[i]) begin
            $display("MEMORY MISMATCH at index %0d: Expected %h, Got %h", i, mem[i], slv_mem[i]);
            err_count <= err_count + 1;
        end
        else begin
            $display("MEMORY MATCH at index %0d: Expected %h, Got %h", i, mem[i], slv_mem[i]);
        end
    end

end


task reset_sys();
begin
    @(posedge clk);
    @(posedge clk); #0.001 resetn = 0; // Active Low Reset
    #20;
    @(posedge clk); #0.001 resetn = 1; // Deassert Reset
end
endtask


task write_txn(       //TASK to WRITE INTO SLV, Handles Single Write(No Consecutive Writes)
    input [ADDR_WIDTH-1:0] ADDR,
    input [DATA_WIDTH-1:0] DATA,
    input [DATA_WIDTH/8-1:0]STRB
);
begin
    @(posedge clk);
    awaddr = ADDR;
    wdata  = DATA;
    wstrb  = STRB;
    bready = 1'b1;
    @(posedge clk) #0.001 awvalid = 1;
    wait(awready);
    @(posedge clk) #0.001 awvalid = 0; wvalid = 1;
    wait(wready);
    @(posedge clk) #0.001 wvalid  = 0;
    wait(bvalid);
    @(posedge clk) #0.001 bready  = 0;
end
endtask

task wr_addr_err(); //RANDOM DATA GENERATED
begin
    @(posedge clk);
    awaddr = 32'h00000100;   //Change this but keep 
    wdata  = $random;
    wstrb  = $random;
    bready = 1'b1;
    @(posedge clk) #0.001 awvalid = 1;
    wait(awready);
    @(posedge clk) #0.001 awvalid = 0; wvalid = 1;
    wait(wready);
    @(posedge clk) #0.001 wvalid  = 0;
    wait(bvalid);
    @(posedge clk) #0.001 bready  = 0;
end
endtask

task read_txn(
    input [ADDR_WIDTH-1:0] ADDR
);
begin
    @(posedge clk);
    araddr = ADDR;
    @(posedge clk) #0.001 arvalid = 1; rready = 1;
    wait(arready);
    @(posedge clk) #0.001 arvalid = 0; 
    wait(rvalid);
    @(posedge clk) #0.001 rready = 0;
end
endtask

task rd_addr_err();
begin
    @(posedge clk);
    araddr = 32'h00000020; //Invalid address to be put here
    @(posedge clk) #0.001 arvalid = 1; rready = 1;
    wait(arready);
    @(posedge clk) #0.001 arvalid = 0; 
    wait(rvalid);
    @(posedge clk) #0.001 rready = 0;
end
endtask

task sim_rd_wr(
    input [ADDR_WIDTH-1:0] WADDR,
    input [DATA_WIDTH-1:0] DATA,
    input [DATA_WIDTH/8-1:0]STRB,
    input [ADDR_WIDTH-1:0] RADDR    
);
begin
    @(posedge clk);
    awaddr = WADDR;
    wdata  = DATA;
    wstrb  = STRB;
    araddr = RADDR; 
    bready = 1'b1;
    rready = 1'b1;
    
    @(posedge clk) #0.001 arvalid = 1; awvalid = 1; wvalid = 1;
    wait(arready & arvalid);
    @(posedge clk) #0.001 arvalid = 0; awvalid = 0;
    wait(rvalid & wready);
    @(posedge clk) #0.001 rready = 0; wvalid = 0;
    wait(bvalid);
    @(posedge clk) #0.001 bready = 0;
end
endtask

task back_to_back_wr( //for testing 
    input [ADDR_WIDTH-1:0] WADDR,  //Base address for write  
    input [DATA_WIDTH-1:0] DATA,   //Base data for write
    input integer NUM_WRITES       //Number of writes to perform
);
begin
    @(posedge clk);
    for(int i = 0; i < NUM_WRITES; i++) begin
        awaddr = WADDR + i*4; //Increment address for each write
        wdata  = DATA + i; //Increment data for each write
        wstrb  = $urandom; //Random strb for each write
        bready = 1'b1;
        @(posedge clk) #0.001 awvalid = 1;
        wait(awready);
        @(posedge clk) #0.001 awvalid = 0; wvalid = 1;
        wait(wready);
        @(posedge clk) #0.001 wvalid  = 0;
        wait(bvalid);
        @(posedge clk) #0.001;    
    end
    bready  = 0;  //Deassert bready after all writes
    @(posedge clk);
end
endtask

task back_to_back_rd( //for testing
    input [ADDR_WIDTH-1:0] RADDR,  //Base address for read
    input integer NUM_READS        //Number of reads to perform
);
begin
    @(posedge clk);
    for(int i = 0; i < NUM_READS; i++) begin
        araddr = RADDR + i*4; //Increment address for each read
        rready = 1'b1;
        @(posedge clk) #0.001 arvalid = 1;
        wait(arready);
        @(posedge clk) #0.001 arvalid = 0; 
        wait(rvalid);
        @(posedge clk) #0.001 rready = 0;
    end
    @(posedge clk);
end
endtask

task back_to_back_wr_rd( //for testing
    input [ADDR_WIDTH-1:0] WADDR,  //Base address for write
    input [DATA_WIDTH-1:0] DATA,   //Base data for write
    input integer NUM_TXNS         //Number of transactions to perform
    );
begin
    @(posedge clk);
    for(int i = 0; i < NUM_TXNS; i++) begin
        awaddr = WADDR + i*4; //Increment address for each write
        wdata  = DATA + i; //Increment data for each write
        wstrb  = 1 << i;
        araddr = WADDR + i*4; //Increment address for each read
        bready = 1'b1;
        rready = 1'b1; 
        @(posedge clk) #0.001 arvalid = 1; awvalid = 1; wvalid = 1;
        wait(arready & arvalid); 
        @(posedge clk) #0.001 ;arvalid = 0; awvalid = 0;
        wait(rvalid & wready);
        @(posedge clk) #0.001;  //wvalid = 0;
        wait(bvalid);
        @(posedge clk) #0.001; 
    end
    @(posedge clk) #0.001 rready = 0; bready = 0; wvalid = 0;
     //Deassert all valid signals
end
endtask

task w_valid_backpressure(
    input [ADDR_WIDTH-1:0] ADDR,
    input [DATA_WIDTH-1:0] DATA,
    input [DATA_WIDTH/8-1:0]STRB
); //For testing backpressure on write valid
begin
    @(posedge clk);
    awaddr = ADDR;
    wdata  = DATA;
    wstrb  = STRB;
    bready = 1'b1;
    @(posedge clk) #0.001 awvalid = 1;  //Hold awvalid and wvalid high
    wait(awready);
    @(posedge clk) #0.001 awvalid = 0; //Do not deassert awvalid
    #60; //Wait for some time to simulate backpressure
    wvalid = 1;
    wait(wready); //Wait for write ready
    @(posedge clk) #0.001 wvalid = 0; //Do not deassert wvalid
    wait(bvalid); //Wait for write response
    @(posedge clk) #0.001 bready = 0; //Deassert bready after write response
end
endtask

task b_ready_backpressure(
    input [ADDR_WIDTH-1:0] ADDR,
    input [DATA_WIDTH-1:0] DATA,
    input [DATA_WIDTH/8-1:0]STRB
); //For testing backpressure on bready
begin
    @(posedge clk);
    awaddr = ADDR;
    wdata  = DATA;
    wstrb  = STRB;
    bready = 1'b0;  
    @(posedge clk) #0.001 awvalid = 1; wvalid = 1; //Hold awvalid and wvalid high
    wait(awready);
    @(posedge clk) #0.001 awvalid = 0; //Deassert awvalid
    wait(wready); //Wait for write ready
    @(posedge clk) #0.001 wvalid = 0; //Deassert wvalid
    #40; //Wait for some time to simulate backpressure
    bready = 1; //Hold bready high
    wait(bvalid); //Wait for write response
    @(posedge clk) #0.001 bready = 0; //Hold bready high
end
endtask

task r_ready_backpressure(
    input [ADDR_WIDTH-1:0] ADDR
); //For testing backpressure on rready
begin
    @(posedge clk);
    araddr = ADDR;
    rready = 1'b0; //Hold rready low
    @(posedge clk) #0.001 arvalid = 1; //Hold arvalid high
    wait(arready);
    @(posedge clk) #0.001 arvalid = 0; //Deassert arvalid
    #50; //Wait for some time to simulate backpressure
    rready = 1; //Hold rready high
    wait(rvalid); //Wait for read data
    @(posedge clk) #0.001 rready = 0; //Deassert rready after read data
end
endtask

initial begin
    reset_sys();
    write_txn(32'h00000000,32'hff120a2c,4'hf);
    sim_rd_wr(32'h00000004,32'habcdef01,4'hc,32'h00000000);
    read_txn(32'h00000004);
    wr_addr_err();
    rd_addr_err();
    back_to_back_wr(32'h00000008,32'h12345678,6); //Write 5 consecutive addresses
    back_to_back_rd(32'h00000008,6); //Read 5 consecutive addresses
    back_to_back_wr_rd(32'h0000000c,32'hdeadefef,4); //Write and Read 4 addresses
    w_valid_backpressure(32'h00000010,32'hdeadbeef,4'hf); //Test backpressure on write valid
    b_ready_backpressure(32'h00000014,32'hcafebabe,4'hf); //Test backpressure on bready
    r_ready_backpressure(32'h00000018); //Test backpressure on rready
    //reset_sys();
    done = 1; //Set done signal to indicate end of simulation
    #100;
    if(err_count == 0) begin
        $display("Simulation completed successfully with no errors.");
    end else begin
        $display("Simulation completed with %0d errors.", err_count);
    end
    $finish; //End simulation
end
endmodule
