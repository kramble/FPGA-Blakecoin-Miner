/* blakeminer.v copyright kramble 2013
 * Based on https://github.com/teknohog/Open-Source-FPGA-Bitcoin-Miner/tree/master/projects/Xilinx_cluster_cgminer
 * Hub code for a cluster of miners using async links
 * by teknohog
 */

module blakeminer (osc_clk, RxD, TxD, led, extminer_rxd, extminer_txd, dip, TMP_SCL, TMP_SDA, TMP_ALERT);

	function integer clog2;		// Courtesy of razorfishsl, replaces $clog2()
		input integer value;
		begin
		value = value-1;
		for (clog2=0; value>0; clog2=clog2+1)
		value = value>>1;
		end
	endfunction

// NB SPEED_MHZ resolution is 5MHz steps to keep pll divide ratio sensible. Change the divider in xilinx_pll.v if you
// want other steps (1MHz is not sensible as it requires divide 100 which is not in the allowed range 1..32 for DCM_SP)
// New dyn_pll has 1MHz resolution and can be changed by sending a specific getwork packet (uses top bytes of target)

`define USE_DYN_PLL		// Enable new dyn_pll

`ifdef SPEED_MHZ
	parameter SPEED_MHZ = `SPEED_MHZ;
`else
	parameter SPEED_MHZ = 50;						// Default to slow, use dynamic config to ramp up in realtime
`endif

`ifdef SPEED_LIMIT
	parameter SPEED_LIMIT = `SPEED_LIMIT;			// Fastest speed accepted by dyn_pll config
`else
	parameter SPEED_LIMIT = 250;
`endif

`ifdef SPEED_MIN
	parameter SPEED_MIN = `SPEED_MIN;				// Slowest speed accepted by dyn_pll config (CARE can lock up if too low)
`else
	parameter SPEED_MIN = 10;
`endif

`ifdef SERIAL_CLK
	parameter comm_clk_frequency = `SERIAL_CLK;
`else
	parameter comm_clk_frequency = 12_500_000;		// 100MHz divide 8
`endif

`ifdef BAUD_RATE
	parameter BAUD_RATE = `BAUD_RATE;
`else
	parameter BAUD_RATE = 115_200;
`endif

// kramble - nonce distribution is crude using top 3 bits of nonce so max LOCAL_MINERS = 4
// teknohog's was more sophisticated, but requires modification of hashcore.v

// Miners on the same FPGA with this hub
`ifdef LOCAL_MINERS
	parameter LOCAL_MINERS = `LOCAL_MINERS;
`else
	parameter LOCAL_MINERS = 1;						// One to four cores
`endif

// kramble - nonce distribution only works for a single external port 
`ifdef EXT_PORTS
	parameter EXT_PORTS = `EXT_PORTS;
`else
	parameter EXT_PORTS = 1;
`endif

	localparam SLAVES = LOCAL_MINERS + EXT_PORTS;

	input osc_clk;
	wire hash_clk, uart_clk, unused_clk, shift_clk;

`ifdef USE_DYN_PLL
	wire first_dcm_locked, dcm_progclk, dcm_progdata, dcm_progen, dcm_reset, dcm_progdone, dcm_locked;
	wire [2:1] dcm_status;
`endif

`ifndef SIM
	`ifdef USE_DYN_PLL
		dyn_pll # (.SPEED_MHZ(SPEED_MHZ)) dyn_pll_blk
			(osc_clk, 
			unused_clk, 
			hash_clk, 
			uart_clk,
			first_dcm_locked,
			dcm_progclk,
			dcm_progdata,
			dcm_progen,
			dcm_reset,
			dcm_progdone,
			dcm_locked,
			dcm_status);
	`else
		main_pll # (.SPEED_MHZ(SPEED_MHZ)) pll_blk (.CLKIN_IN(osc_clk), .CLKFX_OUT(hash_clk), .CLKDV_OUT(uart_clk));
		assign unused_clk = uart_clk;
	`endif
`else
	assign hash_clk = osc_clk;
	assign uart_clk = osc_clk;
	assign unused_clk = osc_clk;
	`ifdef USE_DYN_PLL
		assign first_dcm_locked = 1'b1;
		assign dcm_progdone = 1'b1;
		assign dcm_locked = 1'b1;
		assign dcm_status = 0;
	`endif	
`endif

`ifdef USE_DYN_PLL
	reg [7:0] dyn_pll_speed = SPEED_MHZ;
	reg dyn_pll_start = 0;
	parameter OSC_MHZ = 100;		// Clock oscillator (used for divider ratio)
	dyn_pll_ctrl # (.SPEED_MHZ(SPEED_MHZ), .SPEED_LIMIT(SPEED_LIMIT), .SPEED_MIN(SPEED_MIN), .OSC_MHZ(OSC_MHZ)) dyn_pll_ctrl_blk
		(uart_clk,			// NB uses uart_clk as its just osc/8 and should always be valid
		first_dcm_locked,	// ... but we check it anyway
		dyn_pll_speed,
		dyn_pll_start,
		dcm_progclk,
		dcm_progdata,
		dcm_progen,
		dcm_reset,
		dcm_locked,
		dcm_status);
`endif
      
	input TMP_SCL, TMP_SDA, TMP_ALERT;	// Unused but set to PULLUP so as to avoid turning on the HOT LED
										// TODO implement I2C protocol to talk to temperature sensor chip (TMP101?)
										// and drive FAN speed control output.

	input [3:0]dip;
	wire reset, nonce_chip;
	assign reset = dip[0];			// Not used
	assign nonce_chip = dip[1];		// Distinguishes between the two Icarus FPGA's

	// Work distribution is simply copying to all miners, so no logic
	// needed there, simply copy the RxD.
	input	RxD;
	output	TxD;

	// Results from the input buffers (in serial_hub.v) of each slave
	wire [SLAVES*32-1:0]	slave_nonces;
	wire [SLAVES-1:0]		new_nonces;

	// Using the same transmission code as individual miners from serial.v
	wire		serial_send;
	wire		serial_busy;
	wire [31:0]	golden_nonce;
	serial_transmit #(.comm_clk_frequency(comm_clk_frequency), .baud_rate(BAUD_RATE)) sertx (.clk(uart_clk), .TxD(TxD), .send(serial_send), .busy(serial_busy), .word(golden_nonce));

	hub_core #(.SLAVES(SLAVES)) hc (.uart_clk(uart_clk), .new_nonces(new_nonces), .golden_nonce(golden_nonce), .serial_send(serial_send), .serial_busy(serial_busy), .slave_nonces(slave_nonces));

	// Common workdata input for local miners
	wire [31:0]		target;
	wire			shiftdata;
	wire			shift;			// Now used as FSM control
	reg				shift_d = 0;
	wire			shiften;		// Clock enable
	wire			rx_done;		// Signals hashcore to reset the nonce
									// NB in my implementation, it loads the nonce from data2 which should be fine as
									// this should be zero, but also supports testing using non-zero nonces.

	// Gated clock
`ifdef SIM
	assign shift_clk = shiften & uart_clk;
`else
	BUFGCE shift_clkbuf (.I(uart_clk), .CE(shiften), .O(shift_clk);
`endif

	always @ (posedge uart_clk)
		shift_d <= shift;			// Clock crossing logic (ensures data is stable before loading nonce)

`ifdef USE_DYN_PLL
	// Top byte of target is clock multiplier, 2nd byte is validation (one's complement of clock multiplier)
	// These bytes are always zero in normal getwork, so we now hard code in mod_target and use them to set clock speed.
	// NB The pll controller is in uart_clk domain so use serial_receive signals directly
	// wire [7:0]invtarg;					// Just checking the syntax in simulator, DELETE
	// assign invtarg = ~target[24:16];
	always @ (posedge uart_clk)
	begin
		dyn_pll_start <= 0;
		// A sanity check to reduce the risk of speed being set to garbage
		// Top byte of target is speed, second byte MUST be its inverse, and neither must be zero (which also rules out all ones)
		if (rx_done && target[31:24] != dyn_pll_speed && target[31:24] != 0 && target[23:16] != 0 && target[31:24] == ~target[23:16])
		// if (rx_done && target[31:24] != dyn_pll_speed && target[31:24] != 0)	// Simpler version for DEBUG, does no verification
		begin
			dyn_pll_speed <= target[31:24];
			dyn_pll_start <= 1;
		end
	end
`endif

	serial_receive #(.comm_clk_frequency(comm_clk_frequency), .baud_rate(BAUD_RATE)) serrx (.clk(uart_clk), .shift_clk(shift_clk),
			.RxD(RxD), .dout(shiftdata), .shift(shift), .shiften(shiften), .target(target), .rx_done(rx_done));

	reg [3:0] allones;				// Fudge to ensure ISE does NOT optimise the shift registers re-creating the huge global
									// buses that are unroutable. Its probably not needed, but I just want to be sure

	always @ (posedge uart_clk)		// NB uart_clk not hash_clk as shiftdata and target are uart_clk domain
		allones <= { allones[2:0], target[31] | ~target[30] | target[23] | ~target[22] };	// Fudge
	
	// Local miners now directly connected
	generate
		genvar i;
		for (i = 0; i < LOCAL_MINERS; i = i + 1)
		begin: miners
			wire [31:0] nonce_out;	// Not used
			wire [1:0] nonce_core = i;
			wire gn_match;

`ifdef SIM
			hashcore M (hash_clk, shift_clk, shiftdata & allones[i], shift_d, 3'd7, nonce_out,		// Use fixed 111 prefix in SIM
							slave_nonces[i*32+31:i*32], gn_match);								// to match genesis block
`else							
			hashcore M (hash_clk, shift_clk, shiftdata & allones[i], shift_d, {nonce_chip, nonce_core}, nonce_out,
							slave_nonces[i*32+31:i*32], gn_match);
`endif				
			// Synchronise across clock domains from hash_clk to uart_clk for: assign new_nonces[i] = gn_match;
			reg gn_match_toggle = 1'b0;		// hash_clk domain
			always @ (posedge hash_clk)
				gn_match_toggle <= gn_match_toggle ^ gn_match;

			reg gn_match_toggle_d1 = 1'b0;	// uart_clk domain
			reg gn_match_toggle_d2 = 1'b0;
			reg gn_match_toggle_d3 = 1'b0;

			assign new_nonces[i] = gn_match_toggle_d3 ^ gn_match_toggle_d2;

			always @ (posedge uart_clk)
			begin
				gn_match_toggle_d1 <= gn_match_toggle;
				gn_match_toggle_d2 <= gn_match_toggle_d1;
				gn_match_toggle_d3 <= gn_match_toggle_d2;
			end
			// End of clock domain sync
		end // for
	endgenerate

	// External miner ports, results appended to the same
	// slave_nonces/new_nonces as local ones
	output [EXT_PORTS-1:0] extminer_txd;
	input [EXT_PORTS-1:0]  extminer_rxd;
	// wire [EXT_PORTS-1:0]  extminer_rxd_debug = 1'b1;	// DISABLE INPUT
	assign extminer_txd = {EXT_PORTS{RxD}};

	generate
		genvar j;
		for (j = LOCAL_MINERS; j < SLAVES; j = j + 1)
		// begin: for_ports ... too verbose, so ...
		begin: ports
			slave_receive #(.comm_clk_frequency(comm_clk_frequency), .baud_rate(BAUD_RATE)) slrx (.clk(uart_clk), .RxD(extminer_rxd[j-LOCAL_MINERS]), .nonce(slave_nonces[j*32+31:j*32]), .new_nonce(new_nonces[j]));
		end
	endgenerate

	output [3:0] led;
	assign led[1] = ~RxD;
	// assign led[2] = ~TxD;
	// assign led[3] = ~ (TMP_SCL | TMP_SDA | TMP_ALERT);	// IDLE LED - held low (the TMP pins are PULLUP, this is a fudge to
															// avoid warning about unused inputs)
	
	assign led[3] = ~first_dcm_locked | ~dcm_locked | dcm_status[2] | ~(TMP_SCL | TMP_SDA | TMP_ALERT);	// IDLE LED now dcm status

`define FLASHCLOCK		// Gives some feedback as the the actual clock speed

`ifdef FLASHCLOCK
	reg [26:0] hash_count = 0;
	reg [3:0] sync_hash_count = 0;
	always @ (posedge uart_clk)
		if (rx_done)
			sync_hash_count[0] <= ~sync_hash_count[0];
	always @ (posedge hash_clk)
	begin
		sync_hash_count[3:1] <= sync_hash_count[2:0];
		hash_count <= hash_count + 1'b1;
		if (sync_hash_count[3] != sync_hash_count[2])
			hash_count <= 0;
	end
	assign led[2] = hash_count[26];
`else
	assign led[2] = ~TxD;
`endif

	// Light up only from locally found nonces, not ext_port results
	pwm_fade pf (.clk(uart_clk), .trigger(|new_nonces[LOCAL_MINERS-1:0]), .drive(led[0]));
   
endmodule
