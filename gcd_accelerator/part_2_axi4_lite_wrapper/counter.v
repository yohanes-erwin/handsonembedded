// Author: Erwin Ouyang
// Date  : 3 Feb 2019

`timescale 1ns / 1ps

module counter
    #(
        parameter CNT_WIDTH = 64
    )
    (
        input              clk,
        input              rst_n,
        input              clr,
        input              en,
        output [CNT_WIDTH-1:0] q
    );
    
    reg [CNT_WIDTH-1:0] q_reg;
    
    assign q = q_reg;
    
    always @(posedge clk)
    begin
        if (!rst_n || clr)
        begin
            q_reg <= 0;
        end
        else if (en)
        begin
            q_reg <= q_reg + 1;
        end
    end
    
endmodule
