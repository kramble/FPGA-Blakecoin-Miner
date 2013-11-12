/*!
   btcminer -- BTCMiner for ZTEX USB-FPGA Modules: HDL code for ZTEX USB-FPGA Module 1.15b (one double hash pipe)
   Copyright (C) 2012 ZTEX GmbH
   http://www.ztex.de

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License version 3 as
   published by the Free Software Foundation.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, see http://www.gnu.org/licenses/.
!*/

module ztex_ufm1_15y1 (fxclk_in, reset, select, clk_reset, pll_stop,  dcm_progclk, dcm_progdata, dcm_progen,  rd_clk, wr_clk, wr_start, read, write);

	input fxclk_in, select, reset, clk_reset, pll_stop, dcm_progclk, dcm_progdata, dcm_progen, rd_clk, wr_clk, wr_start;
	input [7:0] read;
	output [7:0] write;

	reg [3:0] rd_clk_b, wr_clk_b;
	reg wr_start_b1 = 0, wr_start_b2 = 0, reset_buf = 0, reset_buf_d = 0, clk_reset_buf = 1, pll_stop_buf = 1, select_buf = 0, phase = 0;
	
	reg dcm_progclk_buf, dcm_progdata_buf, dcm_progen_buf;
	reg [4:0] wr_delay;
	reg [127:0] outbuf;
	reg [7:0] read_buf, write_buf;
	reg [31:0] golden_nonce_a = 32'd0, golden_nonce_b = 32'd0;
	
	wire fxclk, clk, dcm_clk, pll_fb, pll_clk0, dcm_locked, pll_reset;
	wire [2:1] dcm_status;
	wire [31:0] golden_nonce_1, hash_1;
	wire [31:0] golden_nonce_2, hash_2;
	wire [31:0] golden_nonce, nonce_a, hash_a;
	wire gn_match_1, gn_match_2;
	
`define NOPLL		// PLL does not route so workaround uses DCM only
`ifndef SIM
	IBUFG bufg_fxclk (
          .I(fxclk_in),
          .O(fxclk)
        );

	BUFG bufg_clk (
`ifndef NOPLL
          .I(pll_clk0),
`else
          .I(dcm_clk),
`endif
          .O(clk)
        );

		DCM_CLKGEN #(
			.CLKFX_DIVIDE(4),
			.CLKFX_MULTIPLY(16),		// Reduce from 32 to 16 since using TS_clk
			.CLKFXDV_DIVIDE(2),			// NB using CLKFXDV output
			.CLKIN_PERIOD(20.8333)		// 48MHz input
		) 
		dcm0 (
			.CLKIN(fxclk),
			.CLKFXDV(dcm_clk),			// 192MHz output vis 48 * 32 / 4 / 2
			.FREEZEDCM(1'b0),
			.PROGCLK(dcm_progclk_buf),
			.PROGDATA(dcm_progdata_buf),
			.PROGEN(dcm_progen_buf),
			.LOCKED(dcm_locked),
			.STATUS(dcm_status),
			.RST(clk_reset_buf)
		);

`ifndef NOPLL
	PLL_BASE #(
			.BANDWIDTH("LOW"),
			.CLKFBOUT_MULT(4),
			.CLKOUT0_DIVIDE(4),
			.CLKOUT0_DUTY_CYCLE(0.5),
			.CLK_FEEDBACK("CLKFBOUT"), 
			.COMPENSATION("INTERNAL"),
			.DIVCLK_DIVIDE(1),
			.REF_JITTER(0.10),
			.CLKIN_PERIOD(5.2),			// Needed since UCF now constrains clk rather than fxclk
			.RESET_ON_LOSS_OF_LOCK("FALSE")
		)
		pll0 (
			.CLKFBOUT(pll_fb),
			.CLKOUT0(pll_clk0),
			.CLKFBIN(pll_fb),
			.CLKIN(dcm_clk),
			.RST(pll_reset)
		);
`endif

`else
	assign clk = fxclk_in;
`endif

	assign write = select ? write_buf : 8'bz;		// This actually does tristate the outputs
	assign pll_reset = pll_stop_buf | ~dcm_locked | clk_reset_buf | dcm_status[2];

`ifdef SIM
		// Test hashes

		// Genesis block hashes to ba000000 so requires tweaked test in hashcore.v (odd nonce, matches core M2)
		reg [351:0] inbuf_tmp = { 256'h3171e6831d493f45254964259bc31bade1b5bb1ae3c327bc54073d19f0ea633b, 96'hffff001e11f35052d554469e };
		reg [30:0] nonce = (32'hffbd9207 - 4) >> 1;
		
		// Even nonce to test core M1
		// reg [351:0] inbuf_tmp = { 256'h553bf521cf6f816d21b2e3c660f29469f8b6ae935291176ef5dda6fe442ca6e4, 96'hd1d9011caafb56522d4278bf };
		// reg [30:0] nonce = (32'h00468bb4 - 4) >> 1;

		// Odd nonce to test core M2
		// reg [351:0] inbuf_tmp = { 256'h2e2d0db1cb61da41f552cd4737c16ec3e1a6db8d847736f5c2be55f32532edfd , 96'h14ec001c192f5752152499b9 };
		// reg [30:0] nonce = (32'h9f7210b3 - 4) >> 1;

		// Odd nonce to test core M2 ... NON-matching hash
		// reg [351:0] inbuf_tmp = { 256'h9794a4f170190ed3a319eaeb00c4f63675afd9731d552d0760c4d34325a82dd3 , 96'h8920011c3add57521d043f55 };
		// reg [30:0] nonce = (32'h18a6e42f - 4) >> 1;
`else
		reg [351:0] inbuf_tmp;
		reg [30:0] nonce = 31'd0;					// NB 31 bit nonce counter as LSB is fixed per core
`endif				

	reg [351:0] inbuf;

	// NB Multicore needs to use LSB not MSB to distinguish cores due to overflow handling in cgminer
		hashcore M1 (
			.hash_clk(clk),
			.reset(reset_buf),
			.midstate(inbuf[351:96]),
			.data(inbuf[95:0]),
			.nonce({nonce,1'b0}),
			.golden_nonce(golden_nonce_1),
			.golden_nonce_match(gn_match_1),
			.hash_out(hash_1)
			);

		hashcore M2 (
			.hash_clk(clk),
			.reset(reset_buf),
			.midstate(inbuf[351:96]),
			.data(inbuf[95:0]),
			.nonce({nonce,1'b1}),
			.golden_nonce(golden_nonce_2),
			.golden_nonce_match(gn_match_2),
			.hash_out(hash_2)
			);

	// Need to alternate between cores to ensure HW error monitoring works correctly in driver_ztex
	assign nonce_a = ( phase ? {nonce,1'b1} : {nonce,1'b0} ) - 32'd132;
	assign hash_a = phase ? hash_2 : hash_1;
	assign gn_match = gn_match_1 | gn_match_2;
	assign golden_nonce = gn_match_2 ? golden_nonce_2 : golden_nonce_1;
	
	always @ (posedge clk)
	begin
		if ( (rd_clk_b[3] == rd_clk_b[2]) && (rd_clk_b[2] == rd_clk_b[1]) && (rd_clk_b[1] != rd_clk_b[0]) && select_buf )
		begin
		    inbuf_tmp[351:344] <= read_buf;
		    inbuf_tmp[343:0] <= inbuf_tmp[351:8];
		end
		inbuf <= inbuf_tmp;  // due to TIG's
		    
		if ( wr_start_b1 && wr_start_b2 )
		begin
   		    wr_delay <= 5'd0;
		end else 
		begin
		    wr_delay[0] <= 1'b1;
		    wr_delay[4:1] <= wr_delay[3:0];
		end
		
		if ( ! wr_delay[4] ) 
		begin
   		    outbuf <= { golden_nonce_b, hash_a, nonce_a, golden_nonce_a };
   		end else
   		begin
		    if ( (wr_clk_b[3] == wr_clk_b[2]) && (wr_clk_b[2] == wr_clk_b[1]) && (wr_clk_b[1] != wr_clk_b[0]) ) 
			outbuf[119:0] <= outbuf[127:8];
   		end

   		if ( reset_buf )
			nonce <= 32'd0;
		else
			nonce <= nonce + 32'd1;
			
   		if ( reset_buf )
   		begin
   		    golden_nonce_a <= 32'd0;
   		    golden_nonce_b <= 32'd0;
   		end else if ( gn_match ) 
   		begin
   		    golden_nonce_b <= golden_nonce_a;
   		    golden_nonce_a <= golden_nonce;
   		end

		read_buf <= read;
		write_buf <= outbuf[7:0];

		rd_clk_b[0] <= rd_clk;
		rd_clk_b[3:1] <= rd_clk_b[2:0];

		wr_clk_b[0] <= wr_clk;
		wr_clk_b[3:1] <= wr_clk_b[2:0];

		wr_start_b1 <= wr_start;
		wr_start_b2 <= wr_start_b1;
		
		select_buf <= select;
		if ( select ) 
		begin
		    reset_buf <= reset;
		end

		reset_buf_d <= reset_buf;
		if (reset_buf_d & ~reset_buf)
			phase <= ~phase;
	end

	always @ (posedge fxclk)
	begin
		dcm_progclk_buf <= dcm_progclk;
		dcm_progdata_buf <= dcm_progdata;
		dcm_progen_buf <= dcm_progen & select;
		if ( select ) 
		begin
		    clk_reset_buf <= clk_reset;
		    pll_stop_buf <= pll_stop;
		end
	end


endmodule

