// csa.v derived from http://www.rcis.aist.go.jp/files/special/SASEBO/SHA3-ja/BLAKE.zip
// Under free license for research purposes, see http://www.rcis.aist.go.jp/special/SASEBO/SHA3-en.html

module CSA(
   input [31:0] x,
   input [31:0] y,
   input [31:0] z,
   output [31:0] vs,
   output [31:0] vc
);

assign vs = x ^ y ^ z;
assign vc = {((x[30:0] & y[30:0]) | ((x[30:0] ^ y[30:0]) & z[30:0])),1'b0};

endmodule
