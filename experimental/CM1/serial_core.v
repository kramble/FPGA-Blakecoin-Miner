`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// New Serial Core
// For Enterpoint Cairnsmore1 Icarus Derived Bitstream
// By Paul Mumby
// Licensed Under GNU GPL V3
//////////////////////////////////////////////////////////////////////////////////
module serial_core #(parameter CLOCK=25000000, BAUD=57600, SAMPLE_POINT=8)(
	clk,
	rx,
	tx,
	rx_ready,
	tx_ready,
	midstate,
	data2,
	word,
	tx_busy,
	rx_busy
	);

	// IO Declaration
	//===================================================
	input clk;
	input rx;
	output tx;
	output rx_ready;
	input tx_ready;	
   output [255:0] midstate;
   output [255:0] data2;
	input [31:0] word;
	output tx_busy;
	output rx_busy;
	
	//Wire & Register Declaration
	//===================================================
	reg uart_tx_ready = 0;
	wire uart_rx_ready;
	wire uart_tx_busy;
	wire uart_rx_busy;
	wire uart_error;
	reg [7:0] uart_tx_byte;
	wire [7:0] uart_rx_byte;
   reg [3:0] tx_mux_state = 4'b0000;
	reg [31:0] tx_word_copy;
`ifdef SIM
   reg [511:0] rx_input_buffer = { 256'h3171e6831d493f45254964259bc31bade1b5bb1ae3c327bc54073d19f0ea633b, 160'd0, 96'hffff001e11f35052d554469e };
`else
   reg [511:0] rx_input_buffer;
`endif

	//Module Instantiation
	//===================================================
	wire unused_rx_error;
	
	uart #(.CLOCK(CLOCK),.BAUD(BAUD),.SAMPLE_POINT(SAMPLE_POINT)) UART_CORE (
		.clk(clk),
		.rx_pin(rx),
		.tx_pin(tx),
		.tx_start(uart_tx_ready),
		.rx_data_ready(uart_rx_ready),
		.rx_busy(uart_rx_busy),
		.tx_busy(uart_tx_busy),
		.tx_byte(uart_tx_byte),
		.rx_byte(uart_rx_byte),
		.rx_error(unused_rx_error)
		);

	//Assignments
	//===================================================
   assign tx_busy = (|tx_mux_state);
   assign midstate = rx_input_buffer[511:256];
   assign data2 = rx_input_buffer[255:0];
	assign rx_ready = uart_rx_ready;

	//Logic
	//===================================================
	
	//TX Handler
	always @(posedge clk)
	begin
		if (!tx_busy && tx_ready)
		  begin
			  tx_mux_state <= 4'b1000;
			  tx_word_copy <= word;
		  end  
		else if (tx_mux_state[3] && ~tx_mux_state[0] && !uart_tx_busy)
		  begin
			  uart_tx_ready <= 1;
			  tx_mux_state <= tx_mux_state + 1;
			  uart_tx_byte <= tx_word_copy[31:24];
			  tx_word_copy <= (tx_word_copy << 8);
		  end
		else if (tx_mux_state[3] && tx_mux_state[0])
		  begin
			  uart_tx_ready <= 0;
			  if (!uart_tx_busy) tx_mux_state <= tx_mux_state + 1;
		  end
	end
	
	//RX Handler
	always @(posedge clk)
	begin
		if(uart_rx_ready)
			begin
				rx_input_buffer <= rx_input_buffer << 8;
				rx_input_buffer[7:0] <= uart_rx_byte;
			end
		else
			rx_input_buffer <= rx_input_buffer;
	end
	

endmodule
