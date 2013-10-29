/*
*
* Copyright (c) 2011-2012 fpgaminer@bitcoin-mining.com
*
*
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

module blakeminer_top (
	input CLK_100MHZ
);

	//// Configuration Options
	//
	// Frequency (MHz) of the incoming clock (CLK_100MHZ)
	localparam INPUT_CLOCK_FREQUENCY = 100;
	// What frequency of operation Synthesis and P&R should target. If
	// ISE can meet timing requirements, then this is the guaranteed
	// frequency of operation.
	localparam SYNTHESIS_FREQUENCY = 100;		// SHA256 version uses 200MHz but blake won't run this fast
												// 100Mhz is a compromise to allow a fast build (TODO increase this)
	// What frequency the FPGA should boot-up to.
	localparam BOOTUP_FREQUENCY = 50;
	// What is the maximum allowed overclock. User will not be able to set
	// clock frequency above this threshold.
	localparam MAXIMUM_FREQUENCY = 250;
	
	// Number of mining cores
	localparam NUM_CORES = 2;					// 1 to 4 (limited by nonce_msb width), typically 2 for sucessful PAR

	//// PLL
	wire hash_clk;
	wire clkin_100MHZ;
	wire dcm_progdata, dcm_progen, dcm_progdone;
`ifndef SIM
	//// Clock Buffer
	IBUFG clkin1_buf ( .I (CLK_100MHZ), .O (clkin_100MHZ));

	dynamic_clock # (
		.INPUT_FREQUENCY (INPUT_CLOCK_FREQUENCY),
		.SYNTHESIS_FREQUENCY (SYNTHESIS_FREQUENCY)
	) dynamic_clk_blk (
		.CLK_IN1 (clkin_100MHZ),
		.CLK_OUT1 (hash_clk),
		.PROGCLK (clkin_100MHZ),
		.PROGDATA (dcm_progdata),
		.PROGEN (dcm_progen),
		.PROGDONE (dcm_progdone)
	);
`else
	assign hash_clk = CLK_100MHZ;
	assign clkin_100MHZ = CLK_100MHZ;
	assign dcm_progdone = 1'b0;
`endif

	//// Communication Module
	wire [255:0] comm_midstate;
	wire [95:0] comm_data;
	wire comm_new_work;
	reg is_golden_ticket = 1'b0;
	reg [31:0] golden_nonce;
	wire [NUM_CORES-1:0]gn_match_i;
	wire [NUM_CORES*32-1:0] golden_nonce_i;
	
	generate
		genvar i;
		for (i = 0; i < NUM_CORES; i = i + 1)
		begin: miners
		`ifdef SIM
			wire [1:0] nonce_msb = 3 - i;		// Fudge for simulation with < 4 cores as genesis block nonce has 2'b11 prefix
			// wire [1:0] nonce_msb = (2+i)%4;	// For simulation with 2 cores, swaps result to test mux logic (modulo 4 so generic)
		`else
			wire [1:0] nonce_msb = i;
		`endif
			hashcore M (hash_clk, comm_midstate, comm_data, nonce_msb, golden_nonce_i[i*32+31:i*32], gn_match_i[i]);
		end // for
	endgenerate


`ifndef SIMNOJTAG
	jtag_comm # (
		.INPUT_FREQUENCY (INPUT_CLOCK_FREQUENCY),
		.MAXIMUM_FREQUENCY (MAXIMUM_FREQUENCY),
		.INITIAL_FREQUENCY (BOOTUP_FREQUENCY)
	) comm_blk (
		.rx_hash_clk (hash_clk),
		.rx_new_nonce (is_golden_ticket),
		.rx_golden_nonce (golden_nonce),

		.tx_new_work (comm_new_work),
		.tx_midstate (comm_midstate),
		.tx_data (comm_data),

		.rx_dcm_progclk (clkin_100MHZ),
		.tx_dcm_progdata (dcm_progdata),
		.tx_dcm_progen (dcm_progen),
		.rx_dcm_progdone (dcm_progdone)
	);
`else
	// Simple test harness for simulation (hash the genesis block)
	assign comm_midstate = 256'h3171e6831d493f45254964259bc31bade1b5bb1ae3c327bc54073d19f0ea633b;
	assign comm_data = 96'hffff001e11f35052d554469e;
`endif

	//// Control Unit
	
	always @ (posedge hash_clk)
	begin
		// Mux results (rather klunky, novice verilogger afoot)
		is_golden_ticket <= 1'b0;
		if (gn_match_i[0])
		begin
			golden_nonce <= golden_nonce_i[31:0];
			is_golden_ticket <= 1'b1;
		end
		else
		if (NUM_CORES > 1 && gn_match_i[NUM_CORES > 1 ? 1 : 0])	// Avoids bounds error
		begin
			golden_nonce <= golden_nonce_i[(NUM_CORES>1?63:31):(NUM_CORES>1?32:0)];
			is_golden_ticket <= 1'b1;
		end
		else
		if (NUM_CORES > 2 && gn_match_i[NUM_CORES > 2 ? 2 : 0])
		begin
			golden_nonce <= golden_nonce_i[(NUM_CORES>2?95:31):(NUM_CORES>2?64:0)];
			is_golden_ticket <= 1'b1;
		end
		else
		if (NUM_CORES > 3 && gn_match_i[NUM_CORES > 3 ? 3 : 0])
		begin
			golden_nonce <= golden_nonce_i[(NUM_CORES>3?127:31):(NUM_CORES>3?96:0)];
			is_golden_ticket <= 1'b1;
		end
	end

endmodule

