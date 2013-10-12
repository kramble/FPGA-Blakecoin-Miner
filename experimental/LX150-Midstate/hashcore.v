/* hashcore.v
*
* Copyright (c) 2013 kramble
* Parts copyright (c) 2011 fpgaminer@bitcoin-mining.com
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* 
*/

//`define NOMULTICORE 1	// Use for testing in simulation (set it in compile properties)

`timescale 1ns/1ps

module hashcore (hash_clk, din, shift, /*data1, data2, */ nonce_msb, nonce_out, golden_nonce_out, golden_nonce_match, loadnonce);

	input hash_clk;
	input din, shift;
	//input [255:0] data1;
	//input [127:0] data2;
	input [4:0] nonce_msb;		// Supports multicore (set MULTICORE below)
	output [31:0] nonce_out;
	output [31:0] golden_nonce_out;
	output golden_nonce_match;	// Strobe valid one cycle on a match (needed for serial comms)
	input loadnonce;			// Strobe loads nonce (used for serial interface)
	
	wire [31:0] initnonce;		// data2[127:96] passed out of BLAKE_CORE_MS for initialization

	reg poweron_reset = 1'b1;
	reg reset = 1'b1;
	reg shift_d = 1'b0;
	
	`ifndef NOMULTICORE
		reg [26:0] nonce_cnt = 27'd0;		// Multiple cores use different prefix
		wire [31:0] nonce;
		assign nonce = { nonce_msb, nonce_cnt };
	`else
		`ifdef SIM
			//reg [31:0] nonce = 32'hffbd9207;	// Simulation test (genesis block) - NOMULTICORE
			// reg [31:0] nonce = 32'hffbd9206;	// One earlier
			// reg [31:0] nonce = 32'hffbd910c;	// F8 ish earlier for serial shift - works OK
			reg [31:0] nonce = 32'hffbd910b;	// F8 ish earlier for serial shift
		`else
			reg [31:0] nonce = 32'd0;			// NB Initially loaded from data2[127:96]
		`endif
	`endif

	assign nonce_out = nonce;

	reg [31:0] golden_nonce = 32'd0;
	assign golden_nonce_out = golden_nonce;
	reg golden_nonce_match = 1'b0;
	
	reg start = 0;

	// wire [31:0] hash7;	// Don't need both
	wire gn_match;
	
	// wire [511:0] data;
	// NB the extra '1' in this const for blakecoin cf scrypt
	// assign data = { 384'h000002800000000000000001000000000000000000000000000000000000000000000000000000000000000080000000,
	//							nonce, data2[95:0] };

	reg [7:0] cycle = 0;
	always @ (posedge hash_clk)
	begin
		poweron_reset <= 1'b0;
		reset <= poweron_reset;			// Ensures a full clock cycle for reset
		
		cycle <= cycle + 1;
		golden_nonce_match <= 0;
		
		if (reset | shift_d)			// NB shift_d so we don't start until data is valid
			cycle <= 0;
		
		shift_d <= shift;
		
		if (shift_d & ~shift)			// Load nonce once shift completes
		begin
			`ifdef NOMULTICORE
				nonce <= initnonce[31:0];	// Supports loading of initial nonce for test purposes (potentially
											// overriden by the increment below, but this occurs very rarely)
											// This also gives a consistent start point when we send the first work
											// packet (but ONLY the first one since its always zero) when using live data
											// as we initialise nonce_prevous_load to ffffffff
			`else
				nonce_cnt <= initnonce[26:0];	// The 5 msb of nonce are hardwired in MULTICORE mode, so test nonce
												// needs to be <= 0fffffff and will only match in the 0 core
			`endif
		end

		if (cycle == 1)			// NOT cycle==0 as timing of EN is incorrect after shift
		begin
			start <= 1;
		end

		if (cycle == 2)
			start <= 0;

		if (cycle == 19)
		begin
			`ifndef NOMULTICORE
				nonce_cnt <= nonce_cnt + 27'd1;
			`else
				nonce <= nonce + 32'd1;
			`endif
			if (gn_match)
			begin
				golden_nonce <= nonce;
				golden_nonce_match <= 1;
			end
			cycle <= 1;
		end
	end
	
BLAKE_CORE_MS BLAKE_core(
   .clk(hash_clk), .rst_n(~reset),
   // .hash7(hash7),
   .gn_match(gn_match),
   .start(start),
   .nonce(nonce),
   .din(din),
   .shift(shift),
   .initnonce(initnonce)
   /*
   .IV0(data1[31:0]),
   .IV1(data1[63:32]),
   .IV2(data1[95:64]),
   .IV3(data1[127:96]),
   .IV4(data1[159:128]),
   .IV5(data1[191:160]),
   .IV6(data1[223:192]),
   .IV7(data1[255:224]),
   .imsg0(data2[31:0]),
   .imsg1(data2[63:32]),
   .imsg2(data2[95:64]),
   .imsg3(nonce)//,
   .imsg3(data[127:96]),
   .imsg4(data[159:128]),
   .imsg5(data[191:160]),
   .imsg6(data[223:192]),
   .imsg7(data[255:224]),
   .imsg8(data[287:256]),
   .imsg9(data[319:288]),
   .imsg10(data[351:320]),
   .imsg11(data[383:352]),
   .imsg12(data[415:384]),
   .imsg13(data[447:416]),
   .imsg14(data[479:448]),
   .imsg15(data[511:480])
   */
);

endmodule