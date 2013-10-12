// BLAKE_G_FUNCTION.v derived from http://www.rcis.aist.go.jp/files/special/SASEBO/SHA3-ja/BLAKE.zip
// Under free license for research purposes, see http://www.rcis.aist.go.jp/special/SASEBO/SHA3-en.html

module BLAKE_G_FUNCTION(a, b, c, d, msg_i, msg_ip, a_out, b_out, c_out, d_out);

input [31:0] a, b, c, d;
input [31:0] msg_i, msg_ip;
output [31:0] a_out, b_out, c_out, d_out;

wire [31:0] vs_abm, vc_abm, abm;
wire [31:0] vs_a, vc_a;
wire [31:0] rot12i, rot12;
wire [31:0] rot16i, rot16;
wire [31:0] rot8i, rot8;
wire [31:0] rot7i, rot7;
wire [31:0] c_rot;

CSA csa0(.x(a), .y(b), .z(msg_i), .vs(vs_abm), .vc(vc_abm));
CSA csa1(.x(abm), .y(rot12), .z(msg_ip), .vs(vs_a), .vc(vc_a));

assign abm = vs_abm + vc_abm;
assign c_rot = c + rot16;

assign rot12i = c_rot ^ b;
assign rot12 = {rot12i[11:0],rot12i[31:12]};

assign rot16i = abm ^ d;
assign rot16 = {rot16i[15:0],rot16i[31:16]};

assign rot8i = a_out ^ rot16;
assign rot8 = {rot8i[7:0],rot8i[31:8]};

assign rot7i = c_out ^ rot12;
assign rot7 = {rot7i[6:0],rot7i[31:7]};

assign a_out = vs_a + vc_a;
assign b_out = rot7;
assign c_out = d_out + c_rot;
assign d_out = rot8;

endmodule

