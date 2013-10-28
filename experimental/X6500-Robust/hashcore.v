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

`timescale 1ns/1ps

module hashcore (hash_clk, midstate, data, nonce_msb, golden_nonce, golden_nonce_match);

	input hash_clk;
	input [255:0] midstate;
	input [95:0] data;
	input [1:0] nonce_msb;			// Supports multicore
	output reg [31:0] golden_nonce = 32'd0;
	output reg golden_nonce_match = 1'd0;	// Strobe valid one cycle on a match (needed for serial comms)
	
	`ifdef SIM
		reg [29:0] nonce_cnt = 30'h3fbd9207 - 2;	// Simulation test (genesis block). NB 2 cycle latency on midstate,data
	`else
		reg [29:0] nonce_cnt = 30'd0;				// Multiple cores use different prefix
	`endif

	wire [31:0] nonce;
	assign nonce = { nonce_msb, nonce_cnt };
	
	wire gn_match;

	`ifdef SIM
		reg [31:0] golden_nonce_adj = 32'd65;
	`endif
	
	always @ (posedge hash_clk)
	begin
		golden_nonce_match <= 1'b0;
		nonce_cnt <= nonce_cnt + 30'd1;
		if (gn_match)
		begin
			golden_nonce_match <= 1'b1;
			`ifdef SIM
				golden_nonce <= nonce - golden_nonce_adj;
			`else
				golden_nonce <= nonce - 32'd65;
			`endif
		end
		`ifdef SIM
			if (nonce_cnt == 30'h3fbd9207 + 200)
			begin
				// Reset to generate another match, adjust timings to test before/during/after the capture window in jtag_comm.v
				// nonce_cnt <= nonce_cnt - 200;			// reg_golden_nonce overwritten at 2780 BEFORE capture window (and several
															// more times before the subsequent capture)
				nonce_cnt <= nonce_cnt - 400;				// fifo_empty cleared at 5000nS DURING capture window (NORMAL case)
				// nonce_cnt <= nonce_cnt - 800;			// fifo_empty cleared at 9000nS AFTER capture window
				golden_nonce_adj <= golden_nonce_adj - 4;	// Tweak the gn so we can see the new value loaded
			end
		`endif
	end

BLAKE_CORE_FOURP BLAKE_core(
   .clk(hash_clk),
   .midstate(midstate),
   .data(data),
   .nonce(nonce),
   .gn_match(gn_match)
);

endmodule