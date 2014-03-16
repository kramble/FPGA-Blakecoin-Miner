/* blakeminer.v
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

`ifdef NOLEDS
	module blakeminer (osc_clk);		// Version without LEDs for DE2-115
`else
	module blakeminer (osc_clk, LEDS_out);
`endif
	
`ifdef SPEED_MHZ
	parameter SPEED_MHZ = `SPEED_MHZ;
`else
	parameter SPEED_MHZ = 50;
`endif

// LOCAL_MINERS determinse the number of cores (the terminology is consistent with the LX150 port)
`ifdef LOCAL_MINERS
	parameter LOCAL_MINERS = `LOCAL_MINERS;
`else
	parameter LOCAL_MINERS = 2;
`endif

	input osc_clk;
`ifndef NOLEDS
	output reg [7:0]LEDS_out;			// Optional progress indicator
`endif

	wire hash_clk;
	`ifndef SIM
		main_pll #(.SPEED_MHZ(SPEED_MHZ)) pll_blk (osc_clk, hash_clk);
	`else
	 	assign hash_clk = osc_clk;
	`endif

// Virtual wire is now done here rather than in hashcore so as to support MULTICORE	

`ifndef SIM
	// 80 byte block header (NB this implimetation does not use midstate)
	reg [255:0] data1 = 256'd0;	// midstate
	reg [127:0] data2 = 128'd0;
`else
	// Test data (genesis block)
	reg [255:0] data1 = 256'h3171e6831d493f45254964259bc31bade1b5bb1ae3c327bc54073d19f0ea633b; // midstate
	// reg [127:0] data2 = 128'hffbd9207ffff001e11f35052d554469e;  // NB ffbd9207 is loaded into nonce
	reg [127:0] data2 = 128'hffbd9206ffff001e11f35052d554469e;  // Test using prior nonce ffbd9206
	// final_hash=be39762c0b8042bbc6394b23d7965d4e42c34cf823b8a2b14846ae5cba000000 (or backwards)
`endif
	
	wire [31:0]golden_nonce_out;
	wire [31:0] nonce_out;
	wire loadnonce = 1'b0;				// Only used in serial comms interface
	wire [LOCAL_MINERS*32-1:0] golden_nonce_i;
	wire [LOCAL_MINERS-1:0] golden_nonce_match;

	generate
		genvar i;
		for (i = 0; i < LOCAL_MINERS; i = i + 1)
		begin: miners
			wire [31:0] nonce_out_i;
			wire [3:0] nonce_core = i;
		
			hashcore M (hash_clk, data1, data2, nonce_core, nonce_out_i, golden_nonce_i[(i+1)*32-1:i*32], golden_nonce_match[i], loadnonce);
			
			if (i==0)
				assign nonce_out = nonce_out_i;	// NB mining script will under-report hash rate by factor of LOCAL_MINERS
												// TODO correctabe by a simple shift here of log2(LOCAL-MINERS)
		end
	endgenerate
	
	// Simple queue as virtual_wire just reports current value of golden_nonce
	
	// What I want here is a parameterised, one-hot (priority) selected multiplexor, but since
	// my verilog is not very good, I'll just reuse the hub_core code instead
	
	reg [LOCAL_MINERS-1:0]new_nonces_flag = 0;
   
	function integer clog2;		// Courtesy of razorfishsl, replaces $clog2() - needed for ISE < 14.1
	input integer value;
	begin
		value = value-1;
		for (clog2=0; value>0; clog2=clog2+1)
		value = value>>1;
	end
	endfunction

	reg [clog2(LOCAL_MINERS)+1:0] port_counter = 0;
	reg [LOCAL_MINERS*32-1:0] nonces_shifted = 0;
	assign golden_nonce_out = nonces_shifted[31:0];

	// Mark nonces to be cleared during next clock cycle
	reg [LOCAL_MINERS-1:0] clear_nonces = 0;

	always @(posedge hash_clk)
	begin
		// Raise flags when new nonces appear; lower those that have been sent
		new_nonces_flag <= (new_nonces_flag & ~clear_nonces) | golden_nonce_match;

		if (port_counter == LOCAL_MINERS-1)
			port_counter <= 0;
		else
			port_counter <= port_counter + 1'd1;
		
		// kramble - the optimiser removes all but the low 32 bits of nonces_shifted since
		// the following code implements a multiplexor on nonces input, NOT an actual shifter.
		if (new_nonces_flag[port_counter])
		begin
			nonces_shifted <= golden_nonce_i >> port_counter*32;
			clear_nonces[port_counter] <= 1;
		end
		else 
		begin
			clear_nonces <= 0;
		end
	end
	
	`ifndef SIM

	//// Virtual Wire Control
	wire [255:0] data1_vw;
	wire [127:0] data2_vw;		// 96 bits actually used, the extra 32 are the nonce, normally all zeros but for
								// testing we can supply a nonce which will be loaded. Some pools set a non-zero nonce
								// in getwork (which we will load), but this is of no consequence to live mining.

	virtual_wire # (.PROBE_WIDTH(0), .WIDTH(256), .INSTANCE_ID("DAT1")) data1_vw_blk(.probe(), .source(data1_vw));
	virtual_wire # (.PROBE_WIDTH(0), .WIDTH(128), .INSTANCE_ID("DAT2")) data2_vw_blk(.probe(), .source(data2_vw));

	always @ (posedge hash_clk)
	begin
		data1 <= data1_vw;
		data2 <= data2_vw;
	end

	//// Virtual Wire Output
	
	virtual_wire # (.PROBE_WIDTH(32), .WIDTH(0), .INSTANCE_ID("GNON")) golden_nonce_vw_blk (.probe(golden_nonce_out), .source());
	virtual_wire # (.PROBE_WIDTH(32), .WIDTH(0), .INSTANCE_ID("NONC")) nonce_vw_blk (.probe(nonce_out), .source());

	`endif
	

`ifndef NOLEDS
	// Optional LED progress indicator
	always @(posedge hash_clk) begin
	`ifdef INVERTLEDS
		LEDS_out <= ~nonce_out[23:16];		// Inverted for BeMicro
	`else
		LEDS_out <= nonce_out[23:16];
	`endif
	end
`endif

endmodule
