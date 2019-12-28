// Author: Erwin Ouyang
// Date  : 5 Feb 2019

`timescale 1ns / 1ps

module gcd_core
    (
        input wire         clk,
        input wire         rst_n,
        input wire         start,
        input wire [31:0]  a,
        input wire [31:0]  b,
        output wire        done,
        output wire        ready,
        output wire [31:0] r
    );
    
    localparam S_IDLE = 2'h0,
               S_OP = 2'h1;
    
    reg [1:0] _cs, _ns;
    reg [31:0] a_cv, a_nv;
    reg [31:0] b_cv, b_nv;
    reg [4:0] n_cv, n_nv;
    reg done_cv, done_nv;
    
    assign ready = (_cs == S_IDLE) ? 1 : 0;
    assign done = done_cv;
    assign r = a_cv;
    
    always @(posedge clk)
    begin
        if (!rst_n)
        begin
            _cs <= S_IDLE;
            a_cv <= 0;
            b_cv <= 0;
            n_cv <= 0;
            done_cv <= 0;
        end
        else
        begin
            _cs <= _ns;
            a_cv <= a_nv;
            b_cv <= b_nv;
            n_cv <= n_nv;
            done_cv <= done_nv;
        end
    end
    
    always @(*)
    begin
        _ns = _cs;
        a_nv = a_cv;
        b_nv = b_cv;
        n_nv = n_cv;
        done_nv = 0;
        case(_cs)
            S_IDLE:
            begin
                if (start)
                begin
                    a_nv = a;
                    b_nv = b;
                    n_nv = 0;
                    _ns = S_OP;
                end
            end
            S_OP:
            begin
                if (a_cv == b_cv)
                begin
                    a_nv = a_cv << n_cv;
                    done_nv = 1;
                    _ns = S_IDLE;
                end
                else
                begin
                    if (!a_cv[0])       // a even
                    begin
                        a_nv = {1'b0, a_cv[31:1]};
                        if (!b_cv[0])   // a and b even
                        begin
                            b_nv = {1'b0, b_cv[31:1]};
                            n_nv = n_cv + 1;
                        end
                    end
                    else                // a odd
                    begin
                        if (!b_cv[0])   // b even
                        begin
                            b_nv = {1'b0, b_cv[31:1]};
                        end
                        else            // a and b odd
                        begin
                            if (a_cv > b_cv)
                                a_nv = a_cv - b_cv;
                            else
                                b_nv = b_cv - a_cv;
                        end
                    end
                end
            end
        endcase
    end
    
endmodule
