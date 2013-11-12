// BLAKE_CORE_FOURPIPED.v derived from http://www.rcis.aist.go.jp/files/special/SASEBO/SHA3-ja/BLAKE.zip
// Under free license for research purposes, see http://www.rcis.aist.go.jp/special/SASEBO/SHA3-en.html

module BLAKE_CORE_FOURP(
clk,
midstate,
data,
nonce,
hash_out
);

parameter C0 = 32'h243F6A88; 
parameter C1 = 32'h85A308D3;
parameter C2 = 32'h13198A2E; 
parameter C3 = 32'h03707344;
parameter C4 = 32'hA4093822; 
parameter C5 = 32'h299F31D0;
parameter C6 = 32'h082EFA98; 
parameter C7 = 32'hEC4E6C89;
parameter C8 = 32'h452821E6; 
parameter C9 = 32'h38D01377;
parameter C10 = 32'hBE5466CF;  
parameter C11 = 32'h34E90C6C; 
parameter C12 = 32'hC0AC29B7;  
parameter C13 = 32'hC97C50DD; 
parameter C14 = 32'h3F84D5B5;  
parameter C15 = 32'hB5470917; 

input clk;

input [255:0] midstate;
input [95:0] data;
input [31:0] nonce;
output[31:0] hash_out;

//reg [255:0]	data1;			// midstate
//reg [127:0]	data2;
wire [31:0] IV0, IV1, IV2, IV3, IV4, IV5, IV6, IV7;
wire [31:0] imsg0,imsg1,imsg2,imsg3;
assign IV0 = midstate[31:0];
assign IV1 = midstate[63:32];
assign IV2 = midstate[95:64];
assign IV3 = midstate[127:96];
assign IV4 = midstate[159:128];
assign IV5 = midstate[191:160];
assign IV6 = midstate[223:192];
assign IV7 = midstate[255:224];

// imsg15 .. imsg4 are constants in the midstate version, vis
// 384'h000002800000000000000001000000000000000000000000000000000000000000000000000000000000000080000000
// imsg15 = 00000280
// imsg14 = 00000000
// imsg13 = 00000001
// imsg12 = 00000000
// imsg11 = 00000000
// imsg10 = 00000000
// imsg9  = 00000000
// imsg8  = 00000000
// imsg7  = 00000000
// imsg6  = 00000000
// imsg5  = 00000000
// imsg4  = 80000000

assign imsg0 = data[31:0];
assign imsg1 = data[63:32];
assign imsg2 = data[95:64];
assign imsg3 = nonce;

// =============== UNROLLED PIPELINE ===============

// TODO g00, g02 and g03 and part of g01 can be subsumed into a more complex midstate caclulation

wire [31:0] a00, b00, c00, d00;
wire [31:0] a01, b01, c01, d01;
wire [31:0] a02, b02, c02, d02;
wire [31:0] a03, b03, c03, d03;

wire [31:0] a04, b04, c04, d04;
wire [31:0] a05, b05, c05, d05;
wire [31:0] a06, b06, c06, d06;
wire [31:0] a07, b07, c07, d07;

reg [31:0] imsg3_d1;

BLAKE_G_FOURPIPED blake_g00( .clk(clk),
   .a(IV0), .b(IV4), .c(C0), .d(C4 ^ 32'h280), .msg_i(imsg0 ^ C1), .msg_ip(imsg1 ^ C0),
   .a_out(a00), .b_out(b00), .c_out(c00), .d_out(d00));

BLAKE_G_FOURPIPED blake_g01( .clk(clk),
   .a(IV1), .b(IV5), .c(C1), .d(C5 ^ 32'h280), .msg_i(imsg2 ^ C3), .msg_ip(imsg3_d1),
   .a_out(a01), .b_out(b01), .c_out(c01), .d_out(d01));

BLAKE_G_FOURPIPED blake_g02( .clk(clk),
   .a(IV2), .b(IV6), .c(C2), .d(C6), .msg_i(32'h80000000 ^ C5), .msg_ip(C4),
   .a_out(a02), .b_out(b02), .c_out(c02), .d_out(d02));

BLAKE_G_FOURPIPED blake_g03( .clk(clk),
   .a(IV3), .b(IV7), .c(C3), .d(C7), .msg_i(C7), .msg_ip(C6),
   .a_out(a03), .b_out(b03), .c_out(c03), .d_out(d03));

// Chain imsg3 (nonce), calculating offsets and chaining xor terms
// TODO Test the alternative of broadcasting the current input nonce and calculating each
// term from scratch. This will omit one XOR operation each, but may be harder to route.
//`define ALTIMSG

// NOTE For the ztex port the nonce increments by two each clock cycle, so the offset
// calculations are different. TODO Currently NOT implemented for ALTIMSG

always @(posedge clk) begin
//imsg3_d1 <= imsg3 - 1 ^ C2;
imsg3_d1 <= imsg3 - 2 ^ C2;
end
   
BLAKE_G_FOURPIPED blake_g04( .clk(clk),
   .a(a00), .b(b01), .c(c02), .d(d03), .msg_i(C9), .msg_ip(C8),
   .a_out(a04), .b_out(b04), .c_out(c04), .d_out(d04));

BLAKE_G_FOURPIPED blake_g05( .clk(clk),
   .a(a01), .b(b02), .c(c03), .d(d00), .msg_i(C11), .msg_ip(C10),
   .a_out(a05), .b_out(b05), .c_out(c05), .d_out(d05));

BLAKE_G_FOURPIPED blake_g06( .clk(clk),
   .a(a02), .b(b03), .c(c00), .d(d01), .msg_i(C13), .msg_ip(32'h00000001 ^ C12),
   .a_out(a06), .b_out(b06), .c_out(c06), .d_out(d06));

BLAKE_G_FOURPIPED blake_g07( .clk(clk),
   .a(a03), .b(b00), .c(c01), .d(d02), .msg_i(C15), .msg_ip(32'h00000280 ^ C14),
   .a_out(a07), .b_out(b07), .c_out(c07), .d_out(d07));

wire [31:0] a10, b10, c10, d10;
wire [31:0] a11, b11, c11, d11;
wire [31:0] a12, b12, c12, d12;
wire [31:0] a13, b13, c13, d13;

wire [31:0] a14, b14, c14, d14;
wire [31:0] a15, b15, c15, d15;
wire [31:0] a16, b16, c16, d16;
wire [31:0] a17, b17, c17, d17;

reg [31:0] imsg3_d2;

BLAKE_G_FOURPIPED blake_g10( .clk(clk),
   .a(a04), .b(b07), .c(c06), .d(d05), .msg_i(C10), .msg_ip(C14),
   .a_out(a10), .b_out(b10), .c_out(c10), .d_out(d10));

BLAKE_G_FOURPIPED blake_g11( .clk(clk),
   .a(a05), .b(b04), .c(c07), .d(d06), .msg_i(32'h80000000 ^ C8), .msg_ip(C4),
   .a_out(a11), .b_out(b11), .c_out(c11), .d_out(d11));

BLAKE_G_FOURPIPED blake_g12( .clk(clk),
   .a(a06), .b(b05), .c(c04), .d(d07), .msg_i(C15), .msg_ip(32'h00000280 ^ C9),
   .a_out(a12), .b_out(b12), .c_out(c12), .d_out(d12));

BLAKE_G_FOURPIPED blake_g13( .clk(clk),
   .a(a07), .b(b06), .c(c05), .d(d04), .msg_i(32'h00000001 ^ C6), .msg_ip(C13),
   .a_out(a13), .b_out(b13), .c_out(c13), .d_out(d13));

always @(posedge clk) begin
`ifdef ALTIMSG
imsg3_d2 <= imsg3 - 13 ^ C5;
`else
//imsg3_d2 <= ((imsg3_d1 ^ C2) - 11) ^ C5;
imsg3_d2 <= ((imsg3_d1 ^ C2) - 22) ^ C5;
`endif
end
   
BLAKE_G_FOURPIPED blake_g14( .clk(clk),
   .a(a10), .b(b11), .c(c12), .d(d13), .msg_i(imsg1 ^ C12), .msg_ip(C1),
   .a_out(a14), .b_out(b14), .c_out(c14), .d_out(d14));

BLAKE_G_FOURPIPED blake_g15( .clk(clk),
   .a(a11), .b(b12), .c(c13), .d(d10), .msg_i(imsg0 ^ C2), .msg_ip(imsg2 ^ C0),
   .a_out(a15), .b_out(b15), .c_out(c15), .d_out(d15));

BLAKE_G_FOURPIPED blake_g16( .clk(clk),
   .a(a12), .b(b13), .c(c10), .d(d11), .msg_i(C7), .msg_ip(C11),
   .a_out(a16), .b_out(b16), .c_out(c16), .d_out(d16));

BLAKE_G_FOURPIPED blake_g17( .clk(clk),
   .a(a13), .b(b10), .c(c11), .d(d12), .msg_i(C3), .msg_ip(imsg3_d2),
   .a_out(a17), .b_out(b17), .c_out(c17), .d_out(d17));
   
wire [31:0] a20, b20, c20, d20;
wire [31:0] a21, b21, c21, d21;
wire [31:0] a22, b22, c22, d22;
wire [31:0] a23, b23, c23, d23;

wire [31:0] a24, b24, c24, d24;
wire [31:0] a25, b25, c25, d25;
wire [31:0] a26, b26, c26, d26;
wire [31:0] a27, b27, c27, d27;

reg [31:0] imsg3_d3;

BLAKE_G_FOURPIPED blake_g20( .clk(clk),
   .a(a14), .b(b17), .c(c16), .d(d15), .msg_i(C8), .msg_ip(C11),
   .a_out(a20), .b_out(b20), .c_out(c20), .d_out(d20));

BLAKE_G_FOURPIPED blake_g21( .clk(clk),
   .a(a15), .b(b14), .c(c17), .d(d16), .msg_i(C0), .msg_ip(imsg0 ^ C12),
   .a_out(a21), .b_out(b21), .c_out(c21), .d_out(d21));

BLAKE_G_FOURPIPED blake_g22( .clk(clk),
   .a(a16), .b(b15), .c(c14), .d(d17), .msg_i(C2), .msg_ip(imsg2 ^ C5),
   .a_out(a22), .b_out(b22), .c_out(c22), .d_out(d22));

BLAKE_G_FOURPIPED blake_g23( .clk(clk),
   .a(a17), .b(b16), .c(c15), .d(d14), .msg_i(32'h00000280 ^ C13), .msg_ip(32'h00000001 ^ C15),
   .a_out(a23), .b_out(b23), .c_out(c23), .d_out(d23));

always @(posedge clk) begin
`ifdef ALTIMSG
imsg3_d3 <= imsg3 - 19 ^ C6;
`else
//imsg3_d3 <= ((imsg3_d2 ^ C5) - 5) ^ C6;
imsg3_d3 <= ((imsg3_d2 ^ C5) - 10) ^ C6;
`endif
end
   
BLAKE_G_FOURPIPED blake_g24( .clk(clk),
   .a(a20), .b(b21), .c(c22), .d(d23), .msg_i(C14), .msg_ip(C10),
   .a_out(a24), .b_out(b24), .c_out(c24), .d_out(d24));

BLAKE_G_FOURPIPED blake_g25( .clk(clk),
   .a(a21), .b(b22), .c(c23), .d(d20), .msg_i(imsg3_d3), .msg_ip(C3),
   .a_out(a25), .b_out(b25), .c_out(c25), .d_out(d25));

BLAKE_G_FOURPIPED blake_g26( .clk(clk),
   .a(a22), .b(b23), .c(c20), .d(d21), .msg_i(C1), .msg_ip(imsg1 ^ C7),
   .a_out(a26), .b_out(b26), .c_out(c26), .d_out(d26));

BLAKE_G_FOURPIPED blake_g27( .clk(clk),
   .a(a23), .b(b20), .c(c21), .d(d22), .msg_i(C4), .msg_ip(32'h80000000 ^ C9),
   .a_out(a27), .b_out(b27), .c_out(c27), .d_out(d27));
   
wire [31:0] a30, b30, c30, d30;
wire [31:0] a31, b31, c31, d31;
wire [31:0] a32, b32, c32, d32;
wire [31:0] a33, b33, c33, d33;

wire [31:0] a34, b34, c34, d34;
wire [31:0] a35, b35, c35, d35;
wire [31:0] a36, b36, c36, d36;
wire [31:0] a37, b37, c37, d37;

reg [31:0] imsg3_d4;

BLAKE_G_FOURPIPED blake_g30( .clk(clk),
   .a(a24), .b(b27), .c(c26), .d(d25), .msg_i(C9), .msg_ip(C7),
   .a_out(a30), .b_out(b30), .c_out(c30), .d_out(d30));

BLAKE_G_FOURPIPED blake_g31( .clk(clk),
   .a(a25), .b(b24), .c(c27), .d(d26), .msg_i(imsg3_d4), .msg_ip(imsg1 ^ C3),
   .a_out(a31), .b_out(b31), .c_out(c31), .d_out(d31));

BLAKE_G_FOURPIPED blake_g32( .clk(clk),
   .a(a26), .b(b25), .c(c24), .d(d27), .msg_i(32'h00000001 ^ C12), .msg_ip(C13),
   .a_out(a32), .b_out(b32), .c_out(c32), .d_out(d32));

BLAKE_G_FOURPIPED blake_g33( .clk(clk),
   .a(a27), .b(b26), .c(c25), .d(d24), .msg_i(C14), .msg_ip(C11),
   .a_out(a33), .b_out(b33), .c_out(c33), .d_out(d33));

always @(posedge clk) begin
`ifdef ALTIMSG
imsg3_d4 <= imsg3 - 23 ^ C1;
`else
//imsg3_d4 <= ((imsg3_d3 ^ C6) - 3) ^ C1;
imsg3_d4 <= ((imsg3_d3 ^ C6) - 6) ^ C1;
`endif
end
   
BLAKE_G_FOURPIPED blake_g34( .clk(clk),
   .a(a30), .b(b31), .c(c32), .d(d33), .msg_i(imsg2 ^ C6), .msg_ip(C2),
   .a_out(a34), .b_out(b34), .c_out(c34), .d_out(d34));

BLAKE_G_FOURPIPED blake_g35( .clk(clk),
   .a(a31), .b(b32), .c(c33), .d(d30), .msg_i(C10), .msg_ip(C5),
   .a_out(a35), .b_out(b35), .c_out(c35), .d_out(d35));

BLAKE_G_FOURPIPED blake_g36( .clk(clk),
   .a(a32), .b(b33), .c(c30), .d(d31), .msg_i(32'h80000000 ^ C0), .msg_ip(imsg0 ^ C4),
   .a_out(a36), .b_out(b36), .c_out(c36), .d_out(d36));

BLAKE_G_FOURPIPED blake_g37( .clk(clk),
   .a(a33), .b(b30), .c(c31), .d(d32), .msg_i(32'h00000280 ^ C8), .msg_ip(C15),
   .a_out(a37), .b_out(b37), .c_out(c37), .d_out(d37));
   
wire [31:0] a40, b40, c40, d40;
wire [31:0] a41, b41, c41, d41;
wire [31:0] a42, b42, c42, d42;
wire [31:0] a43, b43, c43, d43;

wire [31:0] a44, b44, c44, d44;
wire [31:0] a45, b45, c45, d45;
wire [31:0] a46, b46, c46, d46;
wire [31:0] a47, b47, c47, d47;

reg [31:0] imsg3_d5;

BLAKE_G_FOURPIPED blake_g40( .clk(clk),
   .a(a34), .b(b37), .c(c36), .d(d35), .msg_i(C0), .msg_ip(imsg0 ^ C9),
   .a_out(a40), .b_out(b40), .c_out(c40), .d_out(d40));

BLAKE_G_FOURPIPED blake_g41( .clk(clk),
   .a(a35), .b(b34), .c(c37), .d(d36), .msg_i(C7), .msg_ip(C5),
   .a_out(a41), .b_out(b41), .c_out(c41), .d_out(d41));

BLAKE_G_FOURPIPED blake_g42( .clk(clk),
   .a(a36), .b(b35), .c(c34), .d(d37), .msg_i(imsg2 ^ C4), .msg_ip(32'h80000000 ^ C2),
   .a_out(a42), .b_out(b42), .c_out(c42), .d_out(d42));

BLAKE_G_FOURPIPED blake_g43( .clk(clk),
   .a(a37), .b(b36), .c(c35), .d(d34), .msg_i(C15), .msg_ip(32'h00000280 ^ C10),
   .a_out(a43), .b_out(b43), .c_out(c43), .d_out(d43));

always @(posedge clk) begin
`ifdef ALTIMSG
imsg3_d5 <= imsg3 - 35 ^ C13;
`else
//imsg3_d5 <= ((imsg3_d4 ^ C1) - 11) ^ C13;
imsg3_d5 <= ((imsg3_d4 ^ C1) - 22) ^ C13;
`endif
end
   
BLAKE_G_FOURPIPED blake_g44( .clk(clk),
   .a(a40), .b(b41), .c(c42), .d(d43), .msg_i(C1), .msg_ip(imsg1 ^ C14),
   .a_out(a44), .b_out(b44), .c_out(c44), .d_out(d44));

BLAKE_G_FOURPIPED blake_g45( .clk(clk),
   .a(a41), .b(b42), .c(c43), .d(d40), .msg_i(C12), .msg_ip(C11),
   .a_out(a45), .b_out(b45), .c_out(c45), .d_out(d45));

BLAKE_G_FOURPIPED blake_g46( .clk(clk),
   .a(a42), .b(b43), .c(c40), .d(d41), .msg_i(C8), .msg_ip(C6),
   .a_out(a46), .b_out(b46), .c_out(c46), .d_out(d46));

BLAKE_G_FOURPIPED blake_g47( .clk(clk),
   .a(a43), .b(b40), .c(c41), .d(d42), .msg_i(imsg3_d5), .msg_ip(32'h00000001 ^ C3),
   .a_out(a47), .b_out(b47), .c_out(c47), .d_out(d47));
   
wire [31:0] a50, b50, c50, d50;
wire [31:0] a51, b51, c51, d51;
wire [31:0] a52, b52, c52, d52;
wire [31:0] a53, b53, c53, d53;

wire [31:0] a54, b54, c54, d54;
wire [31:0] a55, b55, c55, d55;
wire [31:0] a56, b56, c56, d56;
wire [31:0] a57, b57, c57, d57;

reg [31:0] imsg3_d6;

BLAKE_G_FOURPIPED blake_g50( .clk(clk),
   .a(a44), .b(b47), .c(c46), .d(d45), .msg_i(imsg2 ^ C12), .msg_ip(C2),
   .a_out(a50), .b_out(b50), .c_out(c50), .d_out(d50));

BLAKE_G_FOURPIPED blake_g51( .clk(clk),
   .a(a45), .b(b44), .c(c47), .d(d46), .msg_i(C10), .msg_ip(C6),
   .a_out(a51), .b_out(b51), .c_out(c51), .d_out(d51));

BLAKE_G_FOURPIPED blake_g52( .clk(clk),
   .a(a46), .b(b45), .c(c44), .d(d47), .msg_i(imsg0 ^ C11), .msg_ip(C0),
   .a_out(a52), .b_out(b52), .c_out(c52), .d_out(d52));

BLAKE_G_FOURPIPED blake_g53( .clk(clk),
   .a(a47), .b(b46), .c(c45), .d(d44), .msg_i(C3), .msg_ip(imsg3_d6),
   .a_out(a53), .b_out(b53), .c_out(c53), .d_out(d53));

always @(posedge clk) begin
`ifdef ALTIMSG
imsg3_d6 <= imsg3 - 41 ^ C8;
`else
//imsg3_d6 <= ((imsg3_d5 ^ C13) - 5) ^ C8;
imsg3_d6 <= ((imsg3_d5 ^ C13) - 10) ^ C8;
`endif
end
   
BLAKE_G_FOURPIPED blake_g54( .clk(clk),
   .a(a50), .b(b51), .c(c52), .d(d53), .msg_i(32'h80000000 ^ C13), .msg_ip(32'h00000001 ^ C4),
   .a_out(a54), .b_out(b54), .c_out(c54), .d_out(d54));

BLAKE_G_FOURPIPED blake_g55( .clk(clk),
   .a(a51), .b(b52), .c(c53), .d(d50), .msg_i(C5), .msg_ip(C7),
   .a_out(a55), .b_out(b55), .c_out(c55), .d_out(d55));

BLAKE_G_FOURPIPED blake_g56( .clk(clk),
   .a(a52), .b(b53), .c(c50), .d(d51), .msg_i(32'h00000280 ^ C14), .msg_ip(C15),
   .a_out(a56), .b_out(b56), .c_out(c56), .d_out(d56));

BLAKE_G_FOURPIPED blake_g57( .clk(clk),
   .a(a53), .b(b50), .c(c51), .d(d52), .msg_i(imsg1 ^ C9), .msg_ip(C1),
   .a_out(a57), .b_out(b57), .c_out(c57), .d_out(d57));
   
wire [31:0] a60, b60, c60, d60;
wire [31:0] a61, b61, c61, d61;
wire [31:0] a62, b62, c62, d62;
wire [31:0] a63, b63, c63, d63;

wire [31:0] a64, b64, c64, d64;
wire [31:0] a65, b65, c65, d65;
wire [31:0] a66, b66, c66, d66;
wire [31:0] a67, b67, c67, d67;

reg [31:0] imsg3_d7;

BLAKE_G_FOURPIPED blake_g60( .clk(clk),
   .a(a54), .b(b57), .c(c56), .d(d55), .msg_i(C5), .msg_ip(C12),
   .a_out(a60), .b_out(b60), .c_out(c60), .d_out(d60));

BLAKE_G_FOURPIPED blake_g61( .clk(clk),
   .a(a55), .b(b54), .c(c57), .d(d56), .msg_i(imsg1 ^ C15), .msg_ip(32'h00000280 ^ C1),
   .a_out(a61), .b_out(b61), .c_out(c61), .d_out(d61));

BLAKE_G_FOURPIPED blake_g62( .clk(clk),
   .a(a56), .b(b55), .c(c54), .d(d57), .msg_i(C13), .msg_ip(32'h00000001 ^ C14),
   .a_out(a62), .b_out(b62), .c_out(c62), .d_out(d62));

BLAKE_G_FOURPIPED blake_g63( .clk(clk),
   .a(a57), .b(b56), .c(c55), .d(d54), .msg_i(32'h80000000 ^ C10), .msg_ip(C4),
   .a_out(a63), .b_out(b63), .c_out(c63), .d_out(d63));

always @(posedge clk) begin
`ifdef ALTIMSG
imsg3_d7 <= imsg3 - 53 ^ C6;
`else
//imsg3_d7 <= ((imsg3_d6 ^ C8) - 11) ^ C6;
imsg3_d7 <= ((imsg3_d6 ^ C8) - 22) ^ C6;
`endif
end
   
BLAKE_G_FOURPIPED blake_g64( .clk(clk),
   .a(a60), .b(b61), .c(c62), .d(d63), .msg_i(imsg0 ^ C7), .msg_ip(C0),
   .a_out(a64), .b_out(b64), .c_out(c64), .d_out(d64));

BLAKE_G_FOURPIPED blake_g65( .clk(clk),
   .a(a61), .b(b62), .c(c63), .d(d60), .msg_i(C3), .msg_ip(imsg3_d7),
   .a_out(a65), .b_out(b65), .c_out(c65), .d_out(d65));

BLAKE_G_FOURPIPED blake_g66( .clk(clk),
   .a(a62), .b(b63), .c(c60), .d(d61), .msg_i(C2), .msg_ip(imsg2 ^ C9),
   .a_out(a66), .b_out(b66), .c_out(c66), .d_out(d66));

BLAKE_G_FOURPIPED blake_g67( .clk(clk),
   .a(a63), .b(b60), .c(c61), .d(d62), .msg_i(C11), .msg_ip(C8),
   .a_out(a67), .b_out(b67), .c_out(c67), .d_out(d67));
   
wire [31:0] a70, b70, c70, d70;
wire [31:0] a71, b71, c71, d71;
wire [31:0] a72, b72, c72, d72;
wire [31:0] a73, b73, c73, d73;

wire [31:0] a74, b74, c74, d74;
wire [31:0] a75, b75, c75, d75;
wire [31:0] a76, b76, c76, d76;
wire [31:0] a77, b77, c77, d77;

reg [31:0] imsg3_d8;

BLAKE_G_FOURPIPED blake_g70( .clk(clk),
   .a(a64), .b(b67), .c(c66), .d(d65), .msg_i(32'h00000001 ^ C11), .msg_ip(C13),
   .a_out(a70), .b_out(b70), .c_out(c70), .d_out(d70));

BLAKE_G_FOURPIPED blake_g71( .clk(clk),
   .a(a65), .b(b64), .c(c67), .d(d66), .msg_i(C14), .msg_ip(C7),
   .a_out(a71), .b_out(b71), .c_out(c71), .d_out(d71));

BLAKE_G_FOURPIPED blake_g72( .clk(clk),
   .a(a66), .b(b65), .c(c64), .d(d67), .msg_i(C1), .msg_ip(imsg1 ^ C12),
   .a_out(a72), .b_out(b72), .c_out(c72), .d_out(d72));

BLAKE_G_FOURPIPED blake_g73( .clk(clk),
   .a(a67), .b(b66), .c(c65), .d(d64), .msg_i(imsg3_d8), .msg_ip(C3),
   .a_out(a73), .b_out(b73), .c_out(c73), .d_out(d73));

always @(posedge clk) begin
`ifdef ALTIMSG
imsg3_d8 <= imsg3 - 55 ^ C9;
`else
//imsg3_d8 <= ((imsg3_d7 ^ C6) - 1) ^ C9;
imsg3_d8 <= ((imsg3_d7 ^ C6) - 2) ^ C9;
`endif
end

// TODO simplify these specific G functions to omit unused outputs (all but b76, d74)

BLAKE_G_FOURPIPED blake_g74( .clk(clk),
   .a(a70), .b(b71), .c(c72), .d(d73), .msg_i(C0), .msg_ip(imsg0 ^ C5),
   .a_out(a74), .b_out(b74), .c_out(c74), .d_out(d74));

/* UNUSED
BLAKE_G_FOURPIPED blake_g75( .clk(clk),
   .a(a71), .b(b72), .c(c73), .d(d70), .msg_i(32'h00000280 ^ C4), .msg_ip(32'h80000000 ^ C15),
   .a_out(a75), .b_out(b75), .c_out(c75), .d_out(d75));
*/

BLAKE_G_FOURPIPED blake_g76( .clk(clk),
   .a(a72), .b(b73), .c(c70), .d(d71), .msg_i(C6), .msg_ip(C8),
   .a_out(a76), .b_out(b76), .c_out(c76), .d_out(d76));

/* UNUSED
BLAKE_G_FOURPIPED blake_g77( .clk(clk),
   .a(a73), .b(b70), .c(c71), .d(d72), .msg_i(imsg2 ^ C10), .msg_ip(C2),
   .a_out(a77), .b_out(b77), .c_out(c77), .d_out(d77));
*/

reg [31:0] b76_d;
reg [31:0] d74_d;

// IV7 is constant (midstate) so no need to pipeline
assign hash_out = IV7 ^ b76_d ^ d74_d;

always @(posedge clk)
begin
	b76_d <= b76;
	d74_d <= d74;
end

endmodule
