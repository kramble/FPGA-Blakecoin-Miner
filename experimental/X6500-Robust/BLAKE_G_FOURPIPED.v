// BLAKE_G_MAXPIPED.v derived from http://www.rcis.aist.go.jp/files/special/SASEBO/SHA3-ja/BLAKE.zip
// Under free license for research purposes, see http://www.rcis.aist.go.jp/special/SASEBO/SHA3-en.html

module BLAKE_G_FOURPIPED(clk, a, b, c, d, msg_i, msg_ip, a_out, b_out, c_out, d_out);

input clk;
input [31:0] a, b, c, d;
input [31:0] msg_i, msg_ip;
output [31:0] a_out, b_out, c_out, d_out;

wire [31:0] rot12i, rot12;
wire [31:0] rot16i, rot16;
wire [31:0] rot8i, rot8;
wire [31:0] rot7i, rot7;

reg  [31:0] abm, abm1, abm3, abm4;
reg  [31:0] b2, b3, c2, d2, cd, cd2, cd3;
reg  [31:0] rot8d, rot12d, rot12d2, rot16d, rot16d2;

assign rot7i = cd3 ^ rot12d2;
assign rot7 = {rot7i[6:0],rot7i[31:7]};
assign rot8i = abm3 ^ rot16d2;
assign rot8 = {rot8i[7:0],rot8i[31:8]};
assign rot12i = cd ^ b3;
assign rot12 = {rot12i[11:0],rot12i[31:12]};
assign rot16i = abm ^ d2;
assign rot16 = {rot16i[15:0],rot16i[31:16]};

assign a_out = abm4;
assign b_out = rot7;
assign c_out = cd3;
assign d_out = rot8d;

always @(posedge clk) begin
	b2 <= b;
	b3 <= b2;
	c2 <= c;
	d2 <= d;

	// Spartan 6 supports ternary adders natively via 6-input LUT
	// so replace the carry-save adders with this ...
	abm <= a + b + msg_i;
	abm1 <= abm;
	abm3 <= abm1 + rot12 + msg_ip;
	abm4 <= abm3;

	cd <= c2 + rot16;
	cd2 <= cd;
	cd3 <= cd2 + rot8;
	
	rot8d <= rot8;
	rot12d <= rot12;
	rot12d2 <= rot12d;
	rot16d <= rot16;
	rot16d2 <= rot16d;
end

endmodule

