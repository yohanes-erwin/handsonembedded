`timescale 1ns / 1ps

module axi_gcd_performance_tb();
    localparam T = 10;
    
    reg aclk;
    reg aresetn;
    wire s_axi_arready;
    reg [31:0] s_axi_araddr;
    reg s_axi_arvalid; 
    wire s_axi_awready;
    reg [31:0] s_axi_awaddr;
    reg s_axi_awvalid;  
    reg s_axi_bready;
    wire [1:0] s_axi_bresp;
    wire s_axi_bvalid;
    reg s_axi_rready;
    wire [31:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    wire s_axi_rvalid;
    wire s_axi_wready;
    reg [31:0] s_axi_wdata;
    reg [3:0] s_axi_wstrb;
    reg s_axi_wvalid;
    
    axi_gcd_performance dut
    (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arready(s_axi_arready),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awready(s_axi_awready),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rready(s_axi_rready),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wready(s_axi_wready),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid)
    );

    always
    begin
        aclk = 0;
        #(T/2);
        aclk = 1;
        #(T/2);
    end

    initial
    begin
        // *** Initial value ***
        s_axi_awaddr = 0;
        s_axi_awvalid = 0;
        s_axi_wstrb = 0;
        s_axi_wdata = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 1;
        s_axi_araddr = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 1;
        
        // *** Reset ***
        aresetn = 0;
        #(T*5);
        aresetn = 1;
        #(T*5);
    
        // *** Calculate gcd(35,25) ***
        axi_write(8'h04, 35);   // A = 35
        axi_write(8'h08, 25);   // B = 25
        axi_write(8'h00, 1);    // START = 1
        #(T*10);
        axi_read(8'hc);         // Read R
        
        // *** Calculate gcd(128,72) ***
        axi_write(8'h04, 128);  // A = 128
        axi_write(8'h08, 72);   // B = 72
        axi_write(8'h00, 1);    // START = 1
        #(T*20);
        axi_read(8'hc);         // Read R     
    end

    task axi_write;
        input [31:0] awaddr;
        input [31:0] wdata; 
        begin
            // *** Write address ***
            s_axi_awaddr = awaddr;
            s_axi_awvalid = 1;
            #T;
            s_axi_awvalid = 0;
            // *** Write data ***
            s_axi_wdata = wdata;
            s_axi_wstrb = 4'hf;
            s_axi_wvalid = 1; 
            #T;
            s_axi_wvalid = 0;
            #T;
        end
    endtask
    
    task axi_read;
        input [31:0] araddr;
        begin
            // *** Read address ***
            s_axi_araddr = araddr;
            s_axi_arvalid = 1;
            #T;
            s_axi_arvalid = 0;
            #T;
        end
    endtask
    
endmodule
