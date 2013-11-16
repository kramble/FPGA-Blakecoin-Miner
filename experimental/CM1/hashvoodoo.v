`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// HashVoodoo Top Module
// Paul Mumby 2012
//////////////////////////////////////////////////////////////////////////////////
module HASHVOODOO (
		clk_p, 
		clk_n, 
		clk_comm, 
		RxD, 
		TxD, 
		led, 
		dip, 
		reset_a, 
		reset_b, 
		reset_select
	);

	//Parameters:
	//================================================
	parameter CLOCK_RATE = 25000000;					//Input Clock Output from Controller in Hz
	parameter DCM_DIVIDER = 10;						//Starting point for DCM divider (25Mhz / 10 = 2.5Mhz increments)
	parameter DCM_MULTIPLIER_START = 40;			//Starting point for DCM multiplier (2.5Mhz x 60 = 150Mhz)
	parameter DCM_MULTIPLIER_CAP = 88;				//Max Point Allowed for DCM multiplier (Safety ceiling)
	parameter DCM_MULTIPLIER_MIN = 20;				//Minimum Allowed for DCM multiplier (If it falls below this something is seriously wrong)
	parameter UART_BAUD_RATE = 115200;				//Baud Rate to use for UART (BPS)
	parameter UART_SAMPLE_POINT = 8;					//Point in the oversampled wave to sample the bit state for the UART (6-12 should be valid)
	parameter CLOCK_FLASH_BITS = 26;					//Number of bits for divider of flasher. (28bit = approx 67M Divider)
	
	//IO Definitions:
	//================================================
   input clk_p;			//Input Clock From Controller (P signal of diff pair)
   input clk_n;			//Input Clock From Controller (N signal of diff pair)
   input clk_comm;		//Input Comm Clock From Controller (Single ended)
   input RxD;				//UART RX Pin (From Controller)
   output TxD;				//UART TX Pin  (To Controller)
   output [3:0] led;		//LED Array
	input [3:0]dip;		//DIP Switch Array
	input reset_a;			//Reset Signal A (position dependant) from Controller
	input reset_b;			//Reset Signal B (position dependant) from Controller
	input reset_select;	//Reset Selector (hard wired based on position)

	//Register/Wire Definitions:
	//================================================
	reg reset;								//Actual Reset Signal
	wire clk_buf;							//Actually Used Clock Signals
	wire clk_dcm;							//Output of hash clock DCM
	wire clk_comm_buf;
	wire clock_flash;						//Flasher output (24bit divider of clock)
	wire miner_busy;						//Miner Busy Flag
	wire miner_busy1, miner_busy2;
   wire [63:0] slave_nonces;				//Nonce found by worker
   wire serial_send;						//Serial Send flag, Triggers UART to begin sending what's in it's buffer
   wire serial_busy;						//Serial Busy flag, Indicates the UART is currently working
   wire [31:0] golden_nonce;				//Overall Found Golden Nonce
   wire [255:0] midstate, data2;			//Mistate and Data2, the main payload for a new job.
	wire start_mining;						//Start Mining flag. This flag going high will trigger the worker to begin hashing on it's buffer
	wire got_ticket1, got_ticket2;			//Got Ticket flag indicates the local worker found a new nonce.
	wire led_nonce_fade;					//This is the output from the fader, jumps to full power when nonce found and fades out
	wire led_serial_fade;					//Output from fader for serial activity.
	reg [1:0]new_nonces;					//Flag indicating new nonces found
	reg [3:0] syncticket1 = 0;				//Clock domain sync
	reg [3:0] syncticket2 = 0;
	wire dcm_prog_en;
	wire dcm_prog_data;
	wire dcm_prog_done;
	wire dcm_valid;
	wire dcm_reset = 1'b0;
	wire identify_flag;
	wire identify_flasher;
	
	//Assignments:
	//================================================
	// KRAMBLE swapped blue and geen leds as blue is far brighter and better as nonce indicator
	assign led[0] = (led_serial_fade || identify_flasher);				//LED0 (Green): UART Activity (blinks and fades on either rx or tx)
	assign led[1] = (clock_flash || ~dcm_valid || identify_flasher);	//LED1 (Red): Clock Heartbeat (blinks to indicate working input clock)
																		//		Off = no clock
																		//		On Solid = dcm invalid.
	assign led[2] = (led_nonce_fade || identify_flasher);				//LED2 (Blue): New Nonce Beacon (fader)
	assign led[3] = (~miner_busy || identify_flasher);					//LED3 (Amber): Idle Indicator. Lights when miner has nothing to do.
	assign identify_flasher = (clock_flash && identify_flag);			//Identify Mode (ALL LEDs flash with heartbeat)
	
	//Module Instantiation:
	//================================================

`ifndef SIM	
	//LVDS Clock Buffer
	IBUFGDS #(
			.DIFF_TERM("TRUE"),
			.IOSTANDARD("DEFAULT")
		) CLK_LVDS_BUF (
			.O(clk_buf),
			.I(clk_p),	//Diff_p clock input
			.IB(clk_n)	//Diff_n clock input
		);
	
	//Comm Clock Buffer
	BUFG CLK_COMM_BUF
		(
			.I   (clk_comm),
			.O   (clk_comm_buf)
		);

	//Dynamically Programmable Hash Clock DCM
	main_dcm #(
			.DCM_DIVIDER(DCM_DIVIDER),
			.DCM_MULTIPLIER(DCM_MULTIPLIER_START)
		) MAINDCM(
			.RESET(dcm_reset),
			.CLK_VALID(dcm_valid),
			.CLK_OSC(clk_buf), 
			.CLK_HASH(clk_dcm),
			.PROGCLK(clk_comm_buf),
			.PROGDATA(dcm_prog_data),
			.PROGEN(dcm_prog_en),
			.PROGDONE(dcm_prog_done)
		);
`else
	assign clk_buf = clk_p;
	assign clk_dcm = clk_buf;
	assign clk_comm_buf = clk_comm;
`endif

	//DCM Controller Core (controls dcm clock based on special (malformed) icarus work packets which act as "command" packets
	dcm_controller #(
			.MAXIMUM_MULTIPLIER(DCM_MULTIPLIER_CAP),
			.MINIMUM_MULTIPLIER(DCM_MULTIPLIER_MIN),
			.INITIAL_MULTIPLIER(DCM_MULTIPLIER_START),
			.INITIAL_DIVIDER(DCM_DIVIDER)
		) DCM_CONTROL (
			.clk(clk_comm_buf),
			.data2(data2),
			.midstate(midstate),
			.start(start_mining),
			.dcm_prog_clk(clk_comm_buf),
			.dcm_prog_en(dcm_prog_en),
			.dcm_prog_data(dcm_prog_data),
			.dcm_prog_done(dcm_prog_done),
			.identify(identify_flag)
		);
	
	//Hub core, this is a holdover from Icarus. KRAMBLE: now in use since multiple hasher cores.
   hub_core #(
			.SLAVES(2)
		) HUBCORE (
			.hash_clk(clk_comm_buf), 
			.new_nonces(new_nonces), 
			.golden_nonce(golden_nonce), 
			.serial_send(serial_send), 
			.serial_busy(serial_busy), 
			.slave_nonces(slave_nonces)
		);
	
	//New Serial Core. Handles all communications in and out to the host.
	wire unused_rx_busy;
	
	serial_core #(
			.CLOCK(CLOCK_RATE),
			.BAUD(UART_BAUD_RATE),
			.SAMPLE_POINT(UART_SAMPLE_POINT)
		) SERIAL_COMM (
			.clk(clk_comm_buf),
			.rx(RxD),
			.tx(TxD),
			.rx_ready(start_mining),
			.tx_ready(serial_send),
			.midstate(midstate),
			.data2(data2),
			.word(golden_nonce),
			.tx_busy(serial_busy),
			.rx_busy(unused_rx_busy)
		);
	
	wire [31:0] unused_nonce_out1, unused_hash_out1;
	wire [31:0] unused_nonce_out2, unused_hash_out2;

	// NB Must reset on new work for cgminer icarus detect to function
	hashcore M1 (
			.hash_clk(clk_dcm),
			.reset(start_mining),		// NB clk_comm domain, strobes each rx byte
			.midstate(midstate),
			.data(data2[95:0]),
			.nonce_msb(1'b0),
			.golden_nonce(slave_nonces[31:0]),
			.golden_nonce_match(got_ticket1),
			.miner_busy(miner_busy1),
			.nonce_out(unused_nonce_out1),
			.hash_out(unused_hash_out1)
			);

	hashcore M2 (
			.hash_clk(clk_dcm),
			.reset(start_mining),		// NB clk_comm domain, strobes each rx byte
			.midstate(midstate),
			.data(data2[95:0]),
			.nonce_msb(1'b1),
			.golden_nonce(slave_nonces[63:32]),
			.golden_nonce_match(got_ticket2),
			.miner_busy(miner_busy2),
			.nonce_out(unused_nonce_out2),
			.hash_out(unused_hash_out2)
			);

	assign miner_busy = miner_busy1 & miner_busy2;	// Both must be busy, else light IDLE led

/*	OLD bitcoin hasher ...
	sha256_top M (
			.clk(clk_dcm), 
			.rst(0), //Tied low for now, to weed out bugs.
			.midstate(midstate), 
			.data2(data2), 
			.golden_nonce(slave_nonces[31:0]), 
			.got_ticket(got_ticket), 
			.miner_busy(miner_busy),  
			.start_mining(start_mining)
		);
*/
	
	//Flasher, this handles dividing down the comm clock by 24bits to blink the clock status LED
	flasher #(
			.BITS(CLOCK_FLASH_BITS)
		) CLK_FLASH (
			.clk(clk_dcm),
			.flash(clock_flash)
		);
	
	//Nonce PWM Fader core. This triggers on a new nonce found, flashes to full brightness, then fades out for nonce found LED.
	pwm_fade PWM_FADE_NONCE (
			.clk(clk_comm_buf), 
			.trigger(|new_nonces), 
			.drive(led_nonce_fade)
		);	

	//Serial PWM Fader core. This triggers on a new nonce found, flashes to full brightness, then fades out for nonce found LED.
	pwm_fade PWM_FADE_COMM (
			.clk(clk_comm_buf), 
			.trigger(~TxD || ~RxD), 
			.drive(led_serial_fade)
		);	
	
	//Clock Domain Buffering of ticket signal

	always@ (posedge clk_dcm)
		begin
			if (got_ticket1)
				syncticket1[0] <= ~syncticket1[0];
			if (got_ticket2)
				syncticket2[0] <= ~syncticket2[0];
		end

	always@ (posedge clk_comm_buf)
		begin
			syncticket1[3:1] <= syncticket1[2:0];
			new_nonces[0] <= (syncticket1[3] != syncticket1[2]);
			syncticket2[3:1] <= syncticket2[2:0];
			new_nonces[1] <= (syncticket2[3] != syncticket2[2]);
		end

endmodule

