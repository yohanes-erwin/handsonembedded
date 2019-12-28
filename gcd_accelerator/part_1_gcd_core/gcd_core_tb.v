`timescale 1ns / 1ps

module gcd_core_tb();
    localparam T = 10;
    
    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] a;
    reg [31:0] b;
    wire done;
    wire ready;
    wire [31:0] r;
    
    gcd_core dut
    (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .a(a),
        .b(b),
        .done(done),
        .ready(ready),
        .r(r)
    );
    
    always
    begin
        clk = 0;
        #(T/2);
        clk = 1;
        #(T/2);
    end
    
    initial
    begin
        // Initial value
        a = 0;
        b = 0;
        start = 0;
        
        // Reset
        rst_n = 0;
        #T;
        rst_n = 1;
        #T;
        
        // gcd(35, 25)
        a = 35;
        b = 25;
        start = 1;
        #T;
        start = 0;
        #(T*10);

        // gcd(128, 72)
        a = 128;
        b = 72;
        start = 1;
        #T;
        start = 0;
        #(T*15);

        // gcd(24, 15)
        a = 24;
        b = 15;
        start = 1;
        #T;
        start = 0;
        #(T*10);  
    end
     
endmodule
