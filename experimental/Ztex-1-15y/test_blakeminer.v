// Testbench for blakeminer_top.v

`timescale 1ns/1ps

`ifdef SIM					// Avoids wrong top selected if included in ISE/PlanAhead sources
module test_blakeminer ();

	reg clk = 1'b0;
	reg [31:0] cycle = 32'd0;

	initial begin
		clk = 0;
		
		while(1)
		begin
			#5 clk = 1; #5 clk = 0;
		end
	end

	always @ (posedge clk)
	begin
		cycle <= cycle + 32'd1;
	end

	wire [7:0] write;
	ztex_ufm1_15y1 uut (clk, 1'b0,  1'b0,  1'b0,  1'b0,  1'b0,  1'b0,  1'b0,  1'b0,  1'b0,  1'b0,  8'd0,  write);
endmodule
`endif