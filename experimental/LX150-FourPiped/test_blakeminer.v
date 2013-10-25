// Testbench for blakeminer.v

`timescale 1ns/1ps

`ifdef SIM					// Avoids wrong top selected if included in ISE/PlanAhead sources
module test_blakeminer ();

	reg clk = 1'b0;
	reg [31:0] cycle = 32'd0;

	initial begin
		clk = 0;
		
		while(1)
		begin
			#5 clk = 1; #5 clk = 0;
		end
	end

	always @ (posedge clk)
	begin
		cycle <= cycle + 32'd1;
	end
	
	wire RxD;
	wire TxD;
	wire extminer_rxd = 0;
	wire extminer_txd;
	wire [3:0] dip = 0;
	wire [3:0] led;
	wire TMP_SCL=1, TMP_SDA=1, TMP_ALERT=1;
	
	parameter comm_clk_frequency = 1_000_000;	// Speeds up serial loading enormously
	parameter baud_rate = 115_200;
	
	blakeminer #(.comm_clk_frequency(comm_clk_frequency)) uut
		(clk, RxD, TxD, led, extminer_rxd, extminer_txd, dip, TMP_SCL, TMP_SDA, TMP_ALERT);


	// TEST DATA (diff=1) NB target, nonce, data, midstate (shifted from the msb/left end) - GENESIS BLOCK
	reg [415:0] data = 416'h000007ffffbd9207ffff001e11f35052d554469e3171e6831d493f45254964259bc31bade1b5bb1ae3c327bc54073d19f0ea633b;
	// ALSO test starting at -1 and -2 nonce to check for timing issues
	// reg [415:0] data = 416'h000007ffffbd9206ffff001e11f35052d554469e3171e6831d493f45254964259bc31bade1b5bb1ae3c327bc54073d19f0ea633b;
	// reg [415:0] data = 416'h000007ffffbd9205ffff001e11f35052d554469e3171e6831d493f45254964259bc31bade1b5bb1ae3c327bc54073d19f0ea633b;
	
	reg			serial_send = 0;
	wire		serial_busy;
	reg [31:0]	data_32 = 0;
	reg [31:0]	start_cycle = 0;

	serial_transmit #(.comm_clk_frequency(comm_clk_frequency), .baud_rate(baud_rate)) sertx (.clk(clk), .TxD(RxD), .send(serial_send), .busy(serial_busy), .word(data_32));

	// BLAKE rx_done is at 43500ns with loadnonce a few cycles later
	
	// TUNE this according to comm_clk_frequency so we send a single getwork (else it gets overwritten with 0's)
	parameter stop_cycle = 7020;		// For comm_clk_frequency=1_000_000 [TODO REDUCE FOR BLAKE, but 7020 is OK]
	// parameter stop_cycle = 0;		// Use this to DISABLE sending data
	always @ (posedge clk)
	begin
		serial_send <= 0;				// Default
		// Send data every time tx goes idle (NB the !serial_send is to prevent serial_send
		// going high for two cycles since serial_busy arrives one cycle after serial_send)
		if (cycle > 5 && cycle < stop_cycle && !serial_busy && !serial_send)
		begin
			serial_send <= 1;
			data_32 <= data[415:384];
			data <= { data[383:0], 32'd0 };
			start_cycle <= cycle;		// Remember each start cycle (makes debugging easier)
		end
	end

endmodule
`endif