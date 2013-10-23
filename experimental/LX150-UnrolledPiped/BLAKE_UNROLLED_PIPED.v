// BLAKE_CORE_UNROLLED_PIPED.v derived from http://www.rcis.aist.go.jp/files/special/SASEBO/SHA3-ja/BLAKE.zip
// Under free license for research purposes, see http://www.rcis.aist.go.jp/special/SASEBO/SHA3-en.html

module BLAKE_CORE_UP(
clk,
gn_match,
din, shift,
nonce,
initnonce
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

input din, shift;
input [31:0] nonce;
output [31:0] initnonce;	// Pass out data2[127:96] for initialization

output gn_match;

reg [255:0]	data1;			// midstate
reg [127:0]	data2;
wire [31:0] IV0, IV1, IV2, IV3, IV4, IV5, IV6, IV7;
wire [31:0] imsg0,imsg1,imsg2,imsg3;
assign IV0 = data1[31:0];
assign IV1 = data1[63:32];
assign IV2 = data1[95:64];
assign IV3 = data1[127:96];
assign IV4 = data1[159:128];
assign IV5 = data1[191:160];
assign IV6 = data1[223:192];
assign IV7 = data1[255:224];

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

assign imsg0 = data2[31:0];
assign imsg1 = data2[63:32];
assign imsg2 = data2[95:64];
assign initnonce = data2[127:96];	// Output to hashcore for initialisation
assign imsg3 = nonce;

always @ (posedge clk)
begin
	if (shift)
	begin
		data1 <= { data1[254:0], data2[127] };
		data2 <= { data2[126:0], din };
	end
end

// =============== UNROLLED PIPELINE ===============

wire [31:0] a00, b00, c00, d00;
wire [31:0] a01, b01, c01, d01;
wire [31:0] a02, b02, c02, d02;
wire [31:0] a03, b03, c03, d03;

reg [31:0] sa00, sb00, sc00, sd00;
reg [31:0] sa01, sb01, sc01, sd01;
reg [31:0] sa02, sb02, sc02, sd02;
reg [31:0] sa03, sb03, sc03, sd03;

wire [31:0] a04, b04, c04, d04;
wire [31:0] a05, b05, c05, d05;
wire [31:0] a06, b06, c06, d06;
wire [31:0] a07, b07, c07, d07;

reg [31:0] sa04, sb04, sc04, sd04;
reg [31:0] sa05, sb05, sc05, sd05;
reg [31:0] sa06, sb06, sc06, sd06;
reg [31:0] sa07, sb07, sc07, sd07;

reg [31:0] imsg3_d1, imsg3_d1a, imsg3_d2, imsg3_d2a;

BLAKE_G_PIPED blake_g00( .clk(clk),
   .a(IV0), .b(IV4), .c(C0), .d(C4 ^ 32'h280), .msg_i(imsg0 ^ C1), .msg_ip(imsg1 ^ C0),
   .a_out(a00), .b_out(b00), .c_out(c00), .d_out(d00));

BLAKE_G_PIPED blake_g01( .clk(clk),
   .a(IV1), .b(IV5), .c(C1), .d(C5 ^ 32'h280), .msg_i(imsg2 ^ C3), .msg_ip(imsg3_d1 ^ C2),
   .a_out(a01), .b_out(b01), .c_out(c01), .d_out(d01));

BLAKE_G_PIPED blake_g02( .clk(clk),
   .a(IV2), .b(IV6), .c(C2), .d(C6), .msg_i(32'h80000000 ^ C5), .msg_ip(C4),
   .a_out(a02), .b_out(b02), .c_out(c02), .d_out(d02));

BLAKE_G_PIPED blake_g03( .clk(clk),
   .a(IV3), .b(IV7), .c(C3), .d(C7), .msg_i(C7), .msg_ip(C6),
   .a_out(a03), .b_out(b03), .c_out(c03), .d_out(d03));

always @(posedge clk) begin
sa00 <= a00; sb00 <= b00; sc00 <= c00; sd00 <= d00;
sa01 <= a01; sb01 <= b01; sc01 <= c01; sd01 <= d01;
sa02 <= a02; sb02 <= b02; sc02 <= c02; sd02 <= d02;
sa03 <= a03; sb03 <= b03; sc03 <= c03; sd03 <= d03;
imsg3_d1 <= imsg3;
imsg3_d1a <= imsg3_d1;
end
   
BLAKE_G_PIPED blake_g04( .clk(clk),
   .a(sa00), .b(sb01), .c(sc02), .d(sd03), .msg_i(C9), .msg_ip(C8),
   .a_out(a04), .b_out(b04), .c_out(c04), .d_out(d04));

BLAKE_G_PIPED blake_g05( .clk(clk),
   .a(sa01), .b(sb02), .c(sc03), .d(sd00), .msg_i(C11), .msg_ip(C10),
   .a_out(a05), .b_out(b05), .c_out(c05), .d_out(d05));

BLAKE_G_PIPED blake_g06( .clk(clk),
   .a(sa02), .b(sb03), .c(sc00), .d(sd01), .msg_i(C13), .msg_ip(32'h00000001 ^ C12),
   .a_out(a06), .b_out(b06), .c_out(c06), .d_out(d06));

BLAKE_G_PIPED blake_g07( .clk(clk),
   .a(sa03), .b(sb00), .c(sc01), .d(sd02), .msg_i(C15), .msg_ip(32'h00000280 ^ C14),
   .a_out(a07), .b_out(b07), .c_out(c07), .d_out(d07));

always @(posedge clk) begin
sa04 <= a04; sb04 <= b04; sc04 <= c04; sd04 <= d04;
sa05 <= a05; sb05 <= b05; sc05 <= c05; sd05 <= d05;
sa06 <= a06; sb06 <= b06; sc06 <= c06; sd06 <= d06;
sa07 <= a07; sb07 <= b07; sc07 <= c07; sd07 <= d07;
imsg3_d2 <= imsg3_d1a;
imsg3_d2a <= imsg3_d2;
end
   
wire [31:0] a10, b10, c10, d10;
wire [31:0] a11, b11, c11, d11;
wire [31:0] a12, b12, c12, d12;
wire [31:0] a13, b13, c13, d13;

reg [31:0] sa10, sb10, sc10, sd10;
reg [31:0] sa11, sb11, sc11, sd11;
reg [31:0] sa12, sb12, sc12, sd12;
reg [31:0] sa13, sb13, sc13, sd13;

wire [31:0] a14, b14, c14, d14;
wire [31:0] a15, b15, c15, d15;
wire [31:0] a16, b16, c16, d16;
wire [31:0] a17, b17, c17, d17;

reg [31:0] sa14, sb14, sc14, sd14;
reg [31:0] sa15, sb15, sc15, sd15;
reg [31:0] sa16, sb16, sc16, sd16;
reg [31:0] sa17, sb17, sc17, sd17;

reg [31:0] imsg3_d3, imsg3_d3a, imsg3_d4, imsg3_d4a;

BLAKE_G_PIPED blake_g10( .clk(clk),
   .a(sa04), .b(sb07), .c(sc06), .d(sd05), .msg_i(C10), .msg_ip(C14),
   .a_out(a10), .b_out(b10), .c_out(c10), .d_out(d10));

BLAKE_G_PIPED blake_g11( .clk(clk),
   .a(sa05), .b(sb04), .c(sc07), .d(sd06), .msg_i(32'h80000000 ^ C8), .msg_ip(C4),
   .a_out(a11), .b_out(b11), .c_out(c11), .d_out(d11));

BLAKE_G_PIPED blake_g12( .clk(clk),
   .a(sa06), .b(sb05), .c(sc04), .d(sd07), .msg_i(C15), .msg_ip(32'h00000280 ^ C9),
   .a_out(a12), .b_out(b12), .c_out(c12), .d_out(d12));

BLAKE_G_PIPED blake_g13( .clk(clk),
   .a(sa07), .b(sb06), .c(sc05), .d(sd04), .msg_i(32'h00000001 ^ C6), .msg_ip(C13),
   .a_out(a13), .b_out(b13), .c_out(c13), .d_out(d13));

always @(posedge clk) begin
sa10 <= a10; sb10 <= b10; sc10 <= c10; sd10 <= d10;
sa11 <= a11; sb11 <= b11; sc11 <= c11; sd11 <= d11;
sa12 <= a12; sb12 <= b12; sc12 <= c12; sd12 <= d12;
sa13 <= a13; sb13 <= b13; sc13 <= c13; sd13 <= d13;
imsg3_d3 <= imsg3_d2a;
imsg3_d3a <= imsg3_d3;
end
   
BLAKE_G_PIPED blake_g14( .clk(clk),
   .a(sa10), .b(sb11), .c(sc12), .d(sd13), .msg_i(imsg1 ^ C12), .msg_ip(C1),
   .a_out(a14), .b_out(b14), .c_out(c14), .d_out(d14));

BLAKE_G_PIPED blake_g15( .clk(clk),
   .a(sa11), .b(sb12), .c(sc13), .d(sd10), .msg_i(imsg0 ^ C2), .msg_ip(imsg2 ^ C0),
   .a_out(a15), .b_out(b15), .c_out(c15), .d_out(d15));

BLAKE_G_PIPED blake_g16( .clk(clk),
   .a(sa12), .b(sb13), .c(sc10), .d(sd11), .msg_i(C7), .msg_ip(C11),
   .a_out(a16), .b_out(b16), .c_out(c16), .d_out(d16));

BLAKE_G_PIPED blake_g17( .clk(clk),
   .a(sa13), .b(sb10), .c(sc11), .d(sd12), .msg_i(C3), .msg_ip(imsg3_d4 ^ C5),
   .a_out(a17), .b_out(b17), .c_out(c17), .d_out(d17));
   
always @(posedge clk) begin
sa14 <= a14; sb14 <= b14; sc14 <= c14; sd14 <= d14;
sa15 <= a15; sb15 <= b15; sc15 <= c15; sd15 <= d15;
sa16 <= a16; sb16 <= b16; sc16 <= c16; sd16 <= d16;
sa17 <= a17; sb17 <= b17; sc17 <= c17; sd17 <= d17;
imsg3_d4 <= imsg3_d3a;
imsg3_d4a <= imsg3_d4;
end

wire [31:0] a20, b20, c20, d20;
wire [31:0] a21, b21, c21, d21;
wire [31:0] a22, b22, c22, d22;
wire [31:0] a23, b23, c23, d23;

reg [31:0] sa20, sb20, sc20, sd20;
reg [31:0] sa21, sb21, sc21, sd21;
reg [31:0] sa22, sb22, sc22, sd22;
reg [31:0] sa23, sb23, sc23, sd23;

wire [31:0] a24, b24, c24, d24;
wire [31:0] a25, b25, c25, d25;
wire [31:0] a26, b26, c26, d26;
wire [31:0] a27, b27, c27, d27;

reg [31:0] sa24, sb24, sc24, sd24;
reg [31:0] sa25, sb25, sc25, sd25;
reg [31:0] sa26, sb26, sc26, sd26;
reg [31:0] sa27, sb27, sc27, sd27;

reg [31:0] imsg3_d5, imsg3_d5a, imsg3_d6, imsg3_d6a;

BLAKE_G_PIPED blake_g20( .clk(clk),
   .a(sa14), .b(sb17), .c(sc16), .d(sd15), .msg_i(C8), .msg_ip(C11),
   .a_out(a20), .b_out(b20), .c_out(c20), .d_out(d20));

BLAKE_G_PIPED blake_g21( .clk(clk),
   .a(sa15), .b(sb14), .c(sc17), .d(sd16), .msg_i(C0), .msg_ip(imsg0 ^ C12),
   .a_out(a21), .b_out(b21), .c_out(c21), .d_out(d21));

BLAKE_G_PIPED blake_g22( .clk(clk),
   .a(sa16), .b(sb15), .c(sc14), .d(sd17), .msg_i(C2), .msg_ip(imsg2 ^ C5),
   .a_out(a22), .b_out(b22), .c_out(c22), .d_out(d22));

BLAKE_G_PIPED blake_g23( .clk(clk),
   .a(sa17), .b(sb16), .c(sc15), .d(sd14), .msg_i(32'h00000280 ^ C13), .msg_ip(32'h00000001 ^ C15),
   .a_out(a23), .b_out(b23), .c_out(c23), .d_out(d23));

always @(posedge clk) begin
sa20 <= a20; sb20 <= b20; sc20 <= c20; sd20 <= d20;
sa21 <= a21; sb21 <= b21; sc21 <= c21; sd21 <= d21;
sa22 <= a22; sb22 <= b22; sc22 <= c22; sd22 <= d22;
sa23 <= a23; sb23 <= b23; sc23 <= c23; sd23 <= d23;
imsg3_d5 <= imsg3_d4a;
imsg3_d5a <= imsg3_d5;
end
   
BLAKE_G_PIPED blake_g24( .clk(clk),
   .a(sa20), .b(sb21), .c(sc22), .d(sd23), .msg_i(C14), .msg_ip(C10),
   .a_out(a24), .b_out(b24), .c_out(c24), .d_out(d24));

BLAKE_G_PIPED blake_g25( .clk(clk),
   .a(sa21), .b(sb22), .c(sc23), .d(sd20), .msg_i(imsg3_d5a ^ C6), .msg_ip(C3),
   .a_out(a25), .b_out(b25), .c_out(c25), .d_out(d25));

BLAKE_G_PIPED blake_g26( .clk(clk),
   .a(sa22), .b(sb23), .c(sc20), .d(sd21), .msg_i(C1), .msg_ip(imsg1 ^ C7),
   .a_out(a26), .b_out(b26), .c_out(c26), .d_out(d26));

BLAKE_G_PIPED blake_g27( .clk(clk),
   .a(sa23), .b(sb20), .c(sc21), .d(sd22), .msg_i(C4), .msg_ip(32'h80000000 ^ C9),
   .a_out(a27), .b_out(b27), .c_out(c27), .d_out(d27));
   
always @(posedge clk) begin
sa24 <= a24; sb24 <= b24; sc24 <= c24; sd24 <= d24;
sa25 <= a25; sb25 <= b25; sc25 <= c25; sd25 <= d25;
sa26 <= a26; sb26 <= b26; sc26 <= c26; sd26 <= d26;
sa27 <= a27; sb27 <= b27; sc27 <= c27; sd27 <= d27;
imsg3_d6 <= imsg3_d5a;
imsg3_d6a <= imsg3_d6;
end

wire [31:0] a30, b30, c30, d30;
wire [31:0] a31, b31, c31, d31;
wire [31:0] a32, b32, c32, d32;
wire [31:0] a33, b33, c33, d33;

reg [31:0] sa30, sb30, sc30, sd30;
reg [31:0] sa31, sb31, sc31, sd31;
reg [31:0] sa32, sb32, sc32, sd32;
reg [31:0] sa33, sb33, sc33, sd33;

wire [31:0] a34, b34, c34, d34;
wire [31:0] a35, b35, c35, d35;
wire [31:0] a36, b36, c36, d36;
wire [31:0] a37, b37, c37, d37;

reg [31:0] sa34, sb34, sc34, sd34;
reg [31:0] sa35, sb35, sc35, sd35;
reg [31:0] sa36, sb36, sc36, sd36;
reg [31:0] sa37, sb37, sc37, sd37;

reg [31:0] imsg3_d7, imsg3_d7a, imsg3_d8, imsg3_d8a;

BLAKE_G_PIPED blake_g30( .clk(clk),
   .a(sa24), .b(sb27), .c(sc26), .d(sd25), .msg_i(C9), .msg_ip(C7),
   .a_out(a30), .b_out(b30), .c_out(c30), .d_out(d30));

BLAKE_G_PIPED blake_g31( .clk(clk),
   .a(sa25), .b(sb24), .c(sc27), .d(sd26), .msg_i(imsg3_d6a ^ C1), .msg_ip(imsg1 ^ C3),
   .a_out(a31), .b_out(b31), .c_out(c31), .d_out(d31));

BLAKE_G_PIPED blake_g32( .clk(clk),
   .a(sa26), .b(sb25), .c(sc24), .d(sd27), .msg_i(32'h00000001 ^ C12), .msg_ip(C13),
   .a_out(a32), .b_out(b32), .c_out(c32), .d_out(d32));

BLAKE_G_PIPED blake_g33( .clk(clk),
   .a(sa27), .b(sb26), .c(sc25), .d(sd24), .msg_i(C14), .msg_ip(C11),
   .a_out(a33), .b_out(b33), .c_out(c33), .d_out(d33));

always @(posedge clk) begin
sa30 <= a30; sb30 <= b30; sc30 <= c30; sd30 <= d30;
sa31 <= a31; sb31 <= b31; sc31 <= c31; sd31 <= d31;
sa32 <= a32; sb32 <= b32; sc32 <= c32; sd32 <= d32;
sa33 <= a33; sb33 <= b33; sc33 <= c33; sd33 <= d33;
imsg3_d7 <= imsg3_d6a;
imsg3_d7a <= imsg3_d7;
end
   
BLAKE_G_PIPED blake_g34( .clk(clk),
   .a(sa30), .b(sb31), .c(sc32), .d(sd33), .msg_i(imsg2 ^ C6), .msg_ip(C2),
   .a_out(a34), .b_out(b34), .c_out(c34), .d_out(d34));

BLAKE_G_PIPED blake_g35( .clk(clk),
   .a(sa31), .b(sb32), .c(sc33), .d(sd30), .msg_i(C10), .msg_ip(C5),
   .a_out(a35), .b_out(b35), .c_out(c35), .d_out(d35));

BLAKE_G_PIPED blake_g36( .clk(clk),
   .a(sa32), .b(sb33), .c(sc30), .d(sd31), .msg_i(32'h80000000 ^ C0), .msg_ip(imsg0 ^ C4),
   .a_out(a36), .b_out(b36), .c_out(c36), .d_out(d36));

BLAKE_G_PIPED blake_g37( .clk(clk),
   .a(sa33), .b(sb30), .c(sc31), .d(sd32), .msg_i(32'h00000280 ^ C8), .msg_ip(C15),
   .a_out(a37), .b_out(b37), .c_out(c37), .d_out(d37));
   
always @(posedge clk) begin
sa34 <= a34; sb34 <= b34; sc34 <= c34; sd34 <= d34;
sa35 <= a35; sb35 <= b35; sc35 <= c35; sd35 <= d35;
sa36 <= a36; sb36 <= b36; sc36 <= c36; sd36 <= d36;
sa37 <= a37; sb37 <= b37; sc37 <= c37; sd37 <= d37;
imsg3_d8 <= imsg3_d7a;
imsg3_d8a <= imsg3_d8;
end
   
wire [31:0] a40, b40, c40, d40;
wire [31:0] a41, b41, c41, d41;
wire [31:0] a42, b42, c42, d42;
wire [31:0] a43, b43, c43, d43;

reg [31:0] sa40, sb40, sc40, sd40;
reg [31:0] sa41, sb41, sc41, sd41;
reg [31:0] sa42, sb42, sc42, sd42;
reg [31:0] sa43, sb43, sc43, sd43;

wire [31:0] a44, b44, c44, d44;
wire [31:0] a45, b45, c45, d45;
wire [31:0] a46, b46, c46, d46;
wire [31:0] a47, b47, c47, d47;

reg [31:0] sa44, sb44, sc44, sd44;
reg [31:0] sa45, sb45, sc45, sd45;
reg [31:0] sa46, sb46, sc46, sd46;
reg [31:0] sa47, sb47, sc47, sd47;

reg [31:0] imsg3_d9, imsg3_d9a, imsg3_d10, imsg3_d10a;

BLAKE_G_PIPED blake_g40( .clk(clk),
   .a(sa34), .b(sb37), .c(sc36), .d(sd35), .msg_i(C0), .msg_ip(imsg0 ^ C9),
   .a_out(a40), .b_out(b40), .c_out(c40), .d_out(d40));

BLAKE_G_PIPED blake_g41( .clk(clk),
   .a(sa35), .b(sb34), .c(sc37), .d(sd36), .msg_i(C7), .msg_ip(C5),
   .a_out(a41), .b_out(b41), .c_out(c41), .d_out(d41));

BLAKE_G_PIPED blake_g42( .clk(clk),
   .a(sa36), .b(sb35), .c(sc34), .d(sd37), .msg_i(imsg2 ^ C4), .msg_ip(32'h80000000 ^ C2),
   .a_out(a42), .b_out(b42), .c_out(c42), .d_out(d42));

BLAKE_G_PIPED blake_g43( .clk(clk),
   .a(sa37), .b(sb36), .c(sc35), .d(sd34), .msg_i(C15), .msg_ip(32'h00000280 ^ C10),
   .a_out(a43), .b_out(b43), .c_out(c43), .d_out(d43));

always @(posedge clk) begin
sa40 <= a40; sb40 <= b40; sc40 <= c40; sd40 <= d40;
sa41 <= a41; sb41 <= b41; sc41 <= c41; sd41 <= d41;
sa42 <= a42; sb42 <= b42; sc42 <= c42; sd42 <= d42;
sa43 <= a43; sb43 <= b43; sc43 <= c43; sd43 <= d43;
imsg3_d9 <= imsg3_d8a;
imsg3_d9a <= imsg3_d9;
end
   
BLAKE_G_PIPED blake_g44( .clk(clk),
   .a(sa40), .b(sb41), .c(sc42), .d(sd43), .msg_i(C1), .msg_ip(imsg1 ^ C14),
   .a_out(a44), .b_out(b44), .c_out(c44), .d_out(d44));

BLAKE_G_PIPED blake_g45( .clk(clk),
   .a(sa41), .b(sb42), .c(sc43), .d(sd40), .msg_i(C12), .msg_ip(C11),
   .a_out(a45), .b_out(b45), .c_out(c45), .d_out(d45));

BLAKE_G_PIPED blake_g46( .clk(clk),
   .a(sa42), .b(sb43), .c(sc40), .d(sd41), .msg_i(C8), .msg_ip(C6),
   .a_out(a46), .b_out(b46), .c_out(c46), .d_out(d46));

BLAKE_G_PIPED blake_g47( .clk(clk),
   .a(sa43), .b(sb40), .c(sc41), .d(sd42), .msg_i(imsg3_d9a ^ C13), .msg_ip(32'h00000001 ^ C3),
   .a_out(a47), .b_out(b47), .c_out(c47), .d_out(d47));
   
always @(posedge clk) begin
sa44 <= a44; sb44 <= b44; sc44 <= c44; sd44 <= d44;
sa45 <= a45; sb45 <= b45; sc45 <= c45; sd45 <= d45;
sa46 <= a46; sb46 <= b46; sc46 <= c46; sd46 <= d46;
sa47 <= a47; sb47 <= b47; sc47 <= c47; sd47 <= d47;
imsg3_d10 <= imsg3_d9a;
imsg3_d10a <= imsg3_d10;
end
   
wire [31:0] a50, b50, c50, d50;
wire [31:0] a51, b51, c51, d51;
wire [31:0] a52, b52, c52, d52;
wire [31:0] a53, b53, c53, d53;

reg [31:0] sa50, sb50, sc50, sd50;
reg [31:0] sa51, sb51, sc51, sd51;
reg [31:0] sa52, sb52, sc52, sd52;
reg [31:0] sa53, sb53, sc53, sd53;

wire [31:0] a54, b54, c54, d54;
wire [31:0] a55, b55, c55, d55;
wire [31:0] a56, b56, c56, d56;
wire [31:0] a57, b57, c57, d57;

reg [31:0] sa54, sb54, sc54, sd54;
reg [31:0] sa55, sb55, sc55, sd55;
reg [31:0] sa56, sb56, sc56, sd56;
reg [31:0] sa57, sb57, sc57, sd57;

reg [31:0] imsg3_d11, imsg3_d11a, imsg3_d12, imsg3_d12a;

BLAKE_G_PIPED blake_g50( .clk(clk),
   .a(sa44), .b(sb47), .c(sc46), .d(sd45), .msg_i(imsg2 ^ C12), .msg_ip(C2),
   .a_out(a50), .b_out(b50), .c_out(c50), .d_out(d50));

BLAKE_G_PIPED blake_g51( .clk(clk),
   .a(sa45), .b(sb44), .c(sc47), .d(sd46), .msg_i(C10), .msg_ip(C6),
   .a_out(a51), .b_out(b51), .c_out(c51), .d_out(d51));

BLAKE_G_PIPED blake_g52( .clk(clk),
   .a(sa46), .b(sb45), .c(sc44), .d(sd47), .msg_i(imsg0 ^ C11), .msg_ip(C0),
   .a_out(a52), .b_out(b52), .c_out(c52), .d_out(d52));

BLAKE_G_PIPED blake_g53( .clk(clk),
   .a(sa47), .b(sb46), .c(sc45), .d(sd44), .msg_i(C3), .msg_ip(imsg3_d11 ^ C8),
   .a_out(a53), .b_out(b53), .c_out(c53), .d_out(d53));

always @(posedge clk) begin
sa50 <= a50; sb50 <= b50; sc50 <= c50; sd50 <= d50;
sa51 <= a51; sb51 <= b51; sc51 <= c51; sd51 <= d51;
sa52 <= a52; sb52 <= b52; sc52 <= c52; sd52 <= d52;
sa53 <= a53; sb53 <= b53; sc53 <= c53; sd53 <= d53;
imsg3_d11 <= imsg3_d10a;
imsg3_d11a <= imsg3_d11;
end
   
BLAKE_G_PIPED blake_g54( .clk(clk),
   .a(sa50), .b(sb51), .c(sc52), .d(sd53), .msg_i(32'h80000000 ^ C13), .msg_ip(32'h00000001 ^ C4),
   .a_out(a54), .b_out(b54), .c_out(c54), .d_out(d54));

BLAKE_G_PIPED blake_g55( .clk(clk),
   .a(sa51), .b(sb52), .c(sc53), .d(sd50), .msg_i(C5), .msg_ip(C7),
   .a_out(a55), .b_out(b55), .c_out(c55), .d_out(d55));

BLAKE_G_PIPED blake_g56( .clk(clk),
   .a(sa52), .b(sb53), .c(sc50), .d(sd51), .msg_i(32'h00000280 ^ C14), .msg_ip(C15),
   .a_out(a56), .b_out(b56), .c_out(c56), .d_out(d56));

BLAKE_G_PIPED blake_g57( .clk(clk),
   .a(sa53), .b(sb50), .c(sc51), .d(sd52), .msg_i(imsg1 ^ C9), .msg_ip(C1),
   .a_out(a57), .b_out(b57), .c_out(c57), .d_out(d57));
   
always @(posedge clk) begin
sa54 <= a54; sb54 <= b54; sc54 <= c54; sd54 <= d54;
sa55 <= a55; sb55 <= b55; sc55 <= c55; sd55 <= d55;
sa56 <= a56; sb56 <= b56; sc56 <= c56; sd56 <= d56;
sa57 <= a57; sb57 <= b57; sc57 <= c57; sd57 <= d57;
imsg3_d12 <= imsg3_d11a;
imsg3_d12a <= imsg3_d12;
end
   
wire [31:0] a60, b60, c60, d60;
wire [31:0] a61, b61, c61, d61;
wire [31:0] a62, b62, c62, d62;
wire [31:0] a63, b63, c63, d63;

reg [31:0] sa60, sb60, sc60, sd60;
reg [31:0] sa61, sb61, sc61, sd61;
reg [31:0] sa62, sb62, sc62, sd62;
reg [31:0] sa63, sb63, sc63, sd63;

wire [31:0] a64, b64, c64, d64;
wire [31:0] a65, b65, c65, d65;
wire [31:0] a66, b66, c66, d66;
wire [31:0] a67, b67, c67, d67;

reg [31:0] sa64, sb64, sc64, sd64;
reg [31:0] sa65, sb65, sc65, sd65;
reg [31:0] sa66, sb66, sc66, sd66;
reg [31:0] sa67, sb67, sc67, sd67;

reg [31:0] imsg3_d13, imsg3_d13a, imsg3_d14, imsg3_d14a;

BLAKE_G_PIPED blake_g60( .clk(clk),
   .a(sa54), .b(sb57), .c(sc56), .d(sd55), .msg_i(C5), .msg_ip(C12),
   .a_out(a60), .b_out(b60), .c_out(c60), .d_out(d60));

BLAKE_G_PIPED blake_g61( .clk(clk),
   .a(sa55), .b(sb54), .c(sc57), .d(sd56), .msg_i(imsg1 ^ C15), .msg_ip(32'h00000280 ^ C1),
   .a_out(a61), .b_out(b61), .c_out(c61), .d_out(d61));

BLAKE_G_PIPED blake_g62( .clk(clk),
   .a(sa56), .b(sb55), .c(sc54), .d(sd57), .msg_i(C13), .msg_ip(32'h00000001 ^ C14),
   .a_out(a62), .b_out(b62), .c_out(c62), .d_out(d62));

BLAKE_G_PIPED blake_g63( .clk(clk),
   .a(sa57), .b(sb56), .c(sc55), .d(sd54), .msg_i(32'h80000000 ^ C10), .msg_ip(C4),
   .a_out(a63), .b_out(b63), .c_out(c63), .d_out(d63));

always @(posedge clk) begin
sa60 <= a60; sb60 <= b60; sc60 <= c60; sd60 <= d60;
sa61 <= a61; sb61 <= b61; sc61 <= c61; sd61 <= d61;
sa62 <= a62; sb62 <= b62; sc62 <= c62; sd62 <= d62;
sa63 <= a63; sb63 <= b63; sc63 <= c63; sd63 <= d63;
imsg3_d13 <= imsg3_d12a;
imsg3_d13a <= imsg3_d13;
end
   
BLAKE_G_PIPED blake_g64( .clk(clk),
   .a(sa60), .b(sb61), .c(sc62), .d(sd63), .msg_i(imsg0 ^ C7), .msg_ip(C0),
   .a_out(a64), .b_out(b64), .c_out(c64), .d_out(d64));

BLAKE_G_PIPED blake_g65( .clk(clk),
   .a(sa61), .b(sb62), .c(sc63), .d(sd60), .msg_i(C3), .msg_ip(imsg3_d14 ^ C6),
   .a_out(a65), .b_out(b65), .c_out(c65), .d_out(d65));

BLAKE_G_PIPED blake_g66( .clk(clk),
   .a(sa62), .b(sb63), .c(sc60), .d(sd61), .msg_i(C2), .msg_ip(imsg2 ^ C9),
   .a_out(a66), .b_out(b66), .c_out(c66), .d_out(d66));

BLAKE_G_PIPED blake_g67( .clk(clk),
   .a(sa63), .b(sb60), .c(sc61), .d(sd62), .msg_i(C11), .msg_ip(C8),
   .a_out(a67), .b_out(b67), .c_out(c67), .d_out(d67));
   
always @(posedge clk) begin
sa64 <= a64; sb64 <= b64; sc64 <= c64; sd64 <= d64;
sa65 <= a65; sb65 <= b65; sc65 <= c65; sd65 <= d65;
sa66 <= a66; sb66 <= b66; sc66 <= c66; sd66 <= d66;
sa67 <= a67; sb67 <= b67; sc67 <= c67; sd67 <= d67;
imsg3_d14 <= imsg3_d13a;
imsg3_d14a <= imsg3_d14;
end
   
wire [31:0] a70, b70, c70, d70;
wire [31:0] a71, b71, c71, d71;
wire [31:0] a72, b72, c72, d72;
wire [31:0] a73, b73, c73, d73;

reg [31:0] sa70, sb70, sc70, sd70;
reg [31:0] sa71, sb71, sc71, sd71;
reg [31:0] sa72, sb72, sc72, sd72;
reg [31:0] sa73, sb73, sc73, sd73;

wire [31:0] a74, b74, c74, d74;
wire [31:0] a75, b75, c75, d75;
wire [31:0] a76, b76, c76, d76;
wire [31:0] a77, b77, c77, d77;

BLAKE_G_PIPED blake_g70( .clk(clk),
   .a(sa64), .b(sb67), .c(sc66), .d(sd65), .msg_i(32'h00000001 ^ C11), .msg_ip(C13),
   .a_out(a70), .b_out(b70), .c_out(c70), .d_out(d70));

BLAKE_G_PIPED blake_g71( .clk(clk),
   .a(sa65), .b(sb64), .c(sc67), .d(sd66), .msg_i(C14), .msg_ip(C7),
   .a_out(a71), .b_out(b71), .c_out(c71), .d_out(d71));

BLAKE_G_PIPED blake_g72( .clk(clk),
   .a(sa66), .b(sb65), .c(sc64), .d(sd67), .msg_i(C1), .msg_ip(imsg1 ^ C12),
   .a_out(a72), .b_out(b72), .c_out(c72), .d_out(d72));

BLAKE_G_PIPED blake_g73( .clk(clk),
   .a(sa67), .b(sb66), .c(sc65), .d(sd64), .msg_i(imsg3_d14a ^ C9), .msg_ip(C3),
   .a_out(a73), .b_out(b73), .c_out(c73), .d_out(d73));

always @(posedge clk) begin
sa70 <= a70; sb70 <= b70; sc70 <= c70; sd70 <= d70;
sa71 <= a71; sb71 <= b71; sc71 <= c71; sd71 <= d71;
sa72 <= a72; sb72 <= b72; sc72 <= c72; sd72 <= d72;
sa73 <= a73; sb73 <= b73; sc73 <= c73; sd73 <= d73;
end
   
BLAKE_G_PIPED blake_g74( .clk(clk),
   .a(sa70), .b(sb71), .c(sc72), .d(sd73), .msg_i(C0), .msg_ip(imsg0 ^ C5),
   .a_out(a74), .b_out(b74), .c_out(c74), .d_out(d74));

BLAKE_G_PIPED blake_g75( .clk(clk),
   .a(sa71), .b(sb72), .c(sc73), .d(sd70), .msg_i(32'h00000280 ^ C4), .msg_ip(32'h80000000 ^ C15),
   .a_out(a75), .b_out(b75), .c_out(c75), .d_out(d75));

BLAKE_G_PIPED blake_g76( .clk(clk),
   .a(sa72), .b(sb73), .c(sc70), .d(sd71), .msg_i(C6), .msg_ip(C8),
   .a_out(a76), .b_out(b76), .c_out(c76), .d_out(d76));

BLAKE_G_PIPED blake_g77( .clk(clk),
   .a(sa73), .b(sb70), .c(sc71), .d(sd72), .msg_i(imsg2 ^ C10), .msg_ip(C2),
   .a_out(a77), .b_out(b77), .c_out(c77), .d_out(d77));
   
// =============== END UNROLLED ===============

reg gn_match_d = 1'b0;
always @(posedge clk)
`ifndef SIM
	gn_match_d <= (IV7 ^ b76 ^ d74) == 0;
`else
	gn_match_d <= (IV7[23:0] ^ b76[23:0] ^ d74[23:0]) == 0;
`endif

assign gn_match = gn_match_d;

`ifdef SIM	// For debugging  ...
	wire gn_hash_diff_256 = (IV7 ^ b76 ^ d74) == 0;
	wire gn_hash_diff_001 = (IV7[23:0] ^ b76[23:0] ^ d74[23:0]) == 0;

	wire[31:0] xhash0 = IV0 ^ a74 ^ c76;
	wire[31:0] xhash7 = IV7 ^ b76 ^ d74;

`endif

endmodule
