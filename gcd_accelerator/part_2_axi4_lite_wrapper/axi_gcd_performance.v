// Author: Erwin Ouyang
// Date  : 5 Feb 2019

`timescale 1ns / 1ps

module axi_gcd_performance
	(
	    // ### Clock and reset signals #########################################
		input  wire        aclk,
		input  wire        aresetn,
		// ### AXI4-lite slave signals #########################################
		// *** Write address signals ***
        output wire        s_axi_awready,
		input  wire [31:0] s_axi_awaddr,
		input  wire        s_axi_awvalid,
		// *** Write data signals ***
        output wire        s_axi_wready,
		input  wire [31:0] s_axi_wdata,
		input  wire [3:0]  s_axi_wstrb,
		input  wire        s_axi_wvalid,
		// *** Write response signals ***
        input  wire        s_axi_bready,
		output wire [1:0]  s_axi_bresp,
		output wire        s_axi_bvalid,
		// *** Read address signals ***
        output wire        s_axi_arready,
		input  wire [31:0] s_axi_araddr,
		input  wire        s_axi_arvalid,
		// *** Read data signals ***	
        input  wire        s_axi_rready,
		output wire [31:0] s_axi_rdata,
		output wire [1:0]  s_axi_rresp,
		output wire        s_axi_rvalid
		// ### User signals ####################################################
	);

    // ### Register map ########################################################
    // 0x00: start and ready
    //       bit 0 = START (R/W)
    //       bit 1 = READY (R)
    // 0x04: input a
    //       bit 31~0 = A[31:0] (R/W)
    // 0x08: input b
    //       bit 31~0 = B[31:0] (R/W)
    // 0x0c: output r
    //       bit 31~0 = R[31:0] (R)
    // 0x10: performance counter value
    //       bit 31~0 = CNT[31:0] (R)
	localparam C_ADDR_BITS = 8;
	// *** Address ***
	localparam C_ADDR_CTRL = 8'h00,
			   C_ADDR_INPA = 8'h04,
			   C_ADDR_INPB = 8'h08,
			   C_ADDR_OUTR = 8'h0c,
			   C_ADDR_CNT = 8'h10;
	// *** AXI write FSM ***
	localparam S_WRIDLE = 2'd0,
			   S_WRDATA = 2'd1,
			   S_WRRESP = 2'd2;
	// *** AXI read FSM ***
	localparam S_RDIDLE = 2'd0,
			   S_RDDATA = 2'd1;
	
	// *** AXI write ***
	reg [1:0] wstate_cs, wstate_ns;
	reg [C_ADDR_BITS-1:0] waddr;
	wire [31:0] wmask;
	wire aw_hs, w_hs;
	// *** AXI read ***
	reg [1:0] rstate_cs, rstate_ns;
	wire [C_ADDR_BITS-1:0] raddr;
	reg [31:0] rdata;
	wire ar_hs;
	// *** Control registers ***
	reg start_reg;
	wire ready_w;
	reg [31:0] a_reg;
	reg [31:0] b_reg;
	wire [31:0] r_w;
    // *** Performance counter ***
    wire done_w;
    wire clr_w, en_w;
    wire [31:0] q_w;
	
	// ### AXI write ###########################################################
	assign s_axi_awready = (wstate_cs == S_WRIDLE);
	assign s_axi_wready = (wstate_cs == S_WRDATA);
	assign s_axi_bresp = 2'b00;    // OKAY
	assign s_axi_bvalid = (wstate_cs == S_WRRESP);
	assign wmask = {{8{s_axi_wstrb[3]}}, {8{s_axi_wstrb[2]}}, {8{s_axi_wstrb[1]}}, {8{s_axi_wstrb[0]}}};
	assign aw_hs = s_axi_awvalid & s_axi_awready;
	assign w_hs = s_axi_wvalid & s_axi_wready;

	// *** Write state register ***
	always @(posedge aclk)
	begin
		if (!aresetn)
			wstate_cs <= S_WRIDLE;
		else
			wstate_cs <= wstate_ns;
	end
	
	// *** Write state next ***
	always @(*)
	begin
		case (wstate_cs)
			S_WRIDLE:
				if (s_axi_awvalid)
					wstate_ns = S_WRDATA;
				else
					wstate_ns = S_WRIDLE;
			S_WRDATA:
				if (s_axi_wvalid)
					wstate_ns = S_WRRESP;
				else
					wstate_ns = S_WRDATA;
			S_WRRESP:
				if (s_axi_bready)
					wstate_ns = S_WRIDLE;
				else
					wstate_ns = S_WRRESP;
			default:
				wstate_ns = S_WRIDLE;
		endcase
	end
	
	// *** Write address register ***
	always @(posedge aclk)
	begin
		if (aw_hs)
			waddr <= s_axi_awaddr[C_ADDR_BITS-1:0];
	end
	
	// ### AXI read ############################################################
	assign s_axi_arready = (rstate_cs == S_RDIDLE);
	assign s_axi_rdata = rdata;
	assign s_axi_rresp = 2'b00;    // OKAY
	assign s_axi_rvalid = (rstate_cs == S_RDDATA);
	assign ar_hs = s_axi_arvalid & s_axi_arready;
	assign raddr = s_axi_araddr[C_ADDR_BITS-1:0];
	
	// *** Read state register ***
	always @(posedge aclk)
	begin
		if (!aresetn)
			rstate_cs <= S_RDIDLE;
		else
			rstate_cs <= rstate_ns;
	end

	// *** Read state next ***
	always @(*) 
	begin
		case (rstate_cs)
			S_RDIDLE:
				if (s_axi_arvalid)
					rstate_ns = S_RDDATA;
				else
					rstate_ns = S_RDIDLE;
			S_RDDATA:
				if (s_axi_rready)
					rstate_ns = S_RDIDLE;
				else
					rstate_ns = S_RDDATA;
			default:
				rstate_ns = S_RDIDLE;
		endcase
	end
	
	// *** Read data register ***
	always @(posedge aclk)
	begin
	    if (!aresetn)
	        rdata <= 0;
		else if (ar_hs)
			case (raddr)
				C_ADDR_CTRL: 
					rdata <= {{30{1'b0}}, ready_w, start_reg};
				C_ADDR_INPA:
				    rdata <= a_reg[31:0];
				C_ADDR_INPB:
                    rdata <= b_reg[31:0];
                C_ADDR_OUTR:
                    rdata <= r_w[31:0];
                C_ADDR_CNT:
                    rdata <= q_w[31:0];		
			endcase
	end
	
    // ### Control registers ###################################################
    // *** GCD core *** 
	gcd_core gcd_core_0
	(
        .clk(aclk),
        .rst_n(aresetn),
        .start(start_reg),
        .a(a_reg),
        .b(b_reg),
        .done(done_w),
        .ready(ready_w),
        .r(r_w)
	);
	
	// *** Counter ***
    counter
    #(
        .CNT_WIDTH(32)
    )
    counter_0
    (
        .clk(aclk),
        .rst_n(aresetn),
        .clr(clr_w),
        .en(en_w),
        .q(q_w)
    );
	assign clr_w = start_reg;
	assign en_w = ~ready_w;
	
	// *** Start register ***
	always @(posedge aclk)
	begin
	    if (!aresetn)
	    begin
            start_reg <= 0;
        end
		else if (w_hs && waddr == C_ADDR_CTRL && s_axi_wdata[0])
		begin
			start_reg <= 1;
	    end
	    else
	    begin
	        start_reg <= 0;
	    end
	end

    // *** Register a and b ***
	always @(posedge aclk)
	begin
	    if (!aresetn)
	    begin
            a_reg[31:0] <= 0;
            b_reg[31:0] <= 0;
        end
		else if (w_hs && waddr == C_ADDR_INPA)
		begin
			a_reg[31:0] <= (s_axi_wdata[31:0] & wmask) | (a_reg[31:0] & ~wmask);
	    end
		else if (w_hs && waddr == C_ADDR_INPB)
        begin
            b_reg[31:0] <= (s_axi_wdata[31:0] & wmask) | (b_reg[31:0] & ~wmask);
        end
	end

endmodule
