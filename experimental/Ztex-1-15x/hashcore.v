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

module hashcore (hash_clk, reset, midstate, data, nonce, golden_nonce, golden_nonce_match, hash_out);

	input hash_clk;
	input reset;
	input [255:0] midstate;
	input [95:0] data;
	input [31:0] nonce;
	output reg [31:0] golden_nonce = 32'd0;
	output reg golden_nonce_match = 1'd0;	// Strobe valid one cycle on a match (needed for serial comms)
	output reg [31:0] hash_out = 32'd0;

	wire [31:0] hash7;

	always @ (posedge hash_clk)
	begin
		golden_nonce_match <= 1'b0;
		if (reset)
		begin
			golden_nonce <= 32'd0;
			hash_out <= 32'd0;
		end
		else
		begin
`ifdef SIM			
			if (hash7[23:0] == 24'd0)	// Genesis block matches on ba000000
`else			
			if (hash7 == 32'd0)
`endif
			begin
				golden_nonce_match <= 1'b1;
				golden_nonce <= nonce - 32'd130;
			end
			hash_out <= hash7;			// Registered to keep in sync with golden_nonce
		end
	end

BLAKE_CORE_FOURP BLAKE_core(
   .clk(hash_clk),
   .midstate(midstate),
   .data(data),
   .nonce(nonce),
   .hash_out(hash7)
);

endmodule