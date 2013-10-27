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
	localparam SYNTHESIS_FREQUENCY = 150;		// SHA256 version uses 200MHz but blake won't run this fast
												// 150Mhz is a compromise to allow a fast build (TODO increase this)
	// What frequency the FPGA should boot-up to.
	localparam BOOTUP_FREQUENCY = 50;
	// What is the maximum allowed overclock. User will not be able to set
	// clock frequency above this threshold.
	localparam MAXIMUM_FREQUENCY = 250;
	


	//// PLL
	wire hash_clk;
	wire dcm_progdata, dcm_progen, dcm_progdone;
`ifndef SIM
	//// Clock Buffer
	wire clkin_100MHZ;
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
`endif

	//// Communication Module
	wire [255:0] comm_midstate;
	wire [95:0] comm_data;
	wire comm_new_work;
	reg is_golden_ticket = 1'b0;
	// reg [31:0] golden_nonce;
	reg [3:0] golden_ticket_buf = 4'b0;
	reg [127:0] golden_nonce_buf;

	// NB Minimal changes from LX150-FourPiped to reduce the chance of mistakes
	// This can be optimised later once its confirmed to work, specifically use a slower shift clock,
	// integrate the shift register into jtag_comm and remove the nonce initialization field.
	
	reg [255:0]	data1sr;			// midstate
	reg [127:0]	data2sr;
	wire din = data1sr[255];
	reg shift = 0;
	reg [11:0] shift_count = 0;
	// reg [15:0] allones;				// Fudge to ensure ISE does NOT optimise the shift registers re-creating the huge global
										// buses that are unroutable. Its probably not needed, but I just want to be sure
	wire [31:0] initial_nonce;
	always @ (posedge hash_clk)
	begin
		shift <= (shift_count != 0);
		if (shift_count != 0)
			shift_count <= shift_count + 1;
		if (comm_new_work)				// NB This assumes a single clock cycle strobe (OK for x6500)
		begin
			data1sr <= comm_midstate;
			data2sr <= { initial_nonce, comm_data[95:0]};	// Initialize nonce to zero - TODO eliminate this field
			shift_count <= shift_count + 1;
		end
		else if (shift)
		begin
			data1sr <= { data1sr[254:0], data2sr[127] };
			data2sr <= { data2sr[126:0], 1'b0 };
		end
		if (shift_count == 384)
			shift_count <= 0;
		// allones <= { allones[14:0], targetreg[31] | ~targetreg[30] | targetreg[23] | ~targetreg[22] };	// Fudge
	end

	wire loadnonce = comm_new_work;
	wire gn_match;
	wire [31:0] nonce_out;			// Unused
	wire [31:0] golden_nonce;

	// Single core for now (will need allones[i] for multicore)
`ifdef SIM
			hashcore M (hash_clk, din, shift, 2'd3, nonce_out,		// Fixed 11 prefix in SIM to match genesis block
							golden_nonce, gn_match, loadnonce);
`else							
			hashcore M (hash_clk, din, shift, 2'd0, nonce_out,		// Fixed 00 prefix (variable in multicore version)
							golden_nonce, gn_match, loadnonce);
`endif				


`ifndef SIM
	jtag_comm # (
		.INPUT_FREQUENCY (INPUT_CLOCK_FREQUENCY),
		.MAXIMUM_FREQUENCY (MAXIMUM_FREQUENCY),
		.INITIAL_FREQUENCY (BOOTUP_FREQUENCY)
	) comm_blk (
		.rx_hash_clk (hash_clk),
		.rx_new_nonce (golden_ticket_buf[3]),
		.rx_golden_nonce (golden_nonce_buf[127:96]),

		.tx_new_work (comm_new_work),
		.tx_midstate (comm_midstate),
		.tx_data (comm_data),

		.rx_dcm_progclk (clkin_100MHZ),
		.tx_dcm_progdata (dcm_progdata),
		.tx_dcm_progen (dcm_progen),
		.rx_dcm_progdone (dcm_progdone)
	);
	assign initial_nonce = 32'd0;
`else
	// Simple test harness for simulation (hash the genesis block)
	reg init = 1'b0;
	always @ (posedge hash_clk)
		init <= 1'b1;
	assign comm_new_work = ~init;
	assign comm_midstate =	256'h3171e6831d493f45254964259bc31bade1b5bb1ae3c327bc54073d19f0ea633b;
	assign comm_data = 96'hffff001e11f35052d554469e;
	assign initial_nonce = 32'hffbd9207 - 0 ;		// Decrement by one or two to check timing
`endif


	//// Control Unit
	
	always @ (posedge hash_clk)
	begin
		// Check to see if the last hash generated is valid.
		is_golden_ticket <= gn_match;

		golden_ticket_buf <= {golden_ticket_buf[2:0], is_golden_ticket};
		golden_nonce_buf <= {golden_nonce_buf[95:0], golden_nonce};
	end

endmodule

