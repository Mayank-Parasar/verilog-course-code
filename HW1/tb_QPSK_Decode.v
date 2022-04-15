//-----------------------------------------------------
// Engineer: Mayank Parasar, Mudassar, Burhan
// Overview
//  A testbench to test 4QAM decoder
//	4QAM data into Symbols.
// Design Name:   tb_QPSK_Decode
// File Name:     tb_QPSK_Decode.v
//
// Stimuli: 
//		inphase: the I input signal from the IQ decoder
//		quad: the Q input signal from the IQ decoder
// Monitor: 
//		symbol: The decoded output symbol
//
// History:       19 Jan. 2017, B. Mudassar, File Created
//				  24 Jan. 2017, T. Brothers, Modifed the file for 
//						a class example for the QPSK or 4QAM decoder
//
//-----------------------------------------------------
// `include "HW1_part_D.v"
module tb_QPSK_Decode;

//------------------------------------------------------
// Parameters
//------------------------------------------------------
	
	parameter input_bitwidth = 3;
	parameter symbol_bitwidth = 4;

//------------------------------------------------------
// Signals
//------------------------------------------------------
	//stimuli
	reg [input_bitwidth-1:0] inphase = 0;
	reg [input_bitwidth-1:0] quad = 0;
	
	
	//probe
	wire [symbol_bitwidth-1:0] symbol;
	reg  [symbol_bitwidth-1:0] symbol_known;
	
	//testbench signals
	reg clk = 0;
	
	//Output results to file
	integer result_file = 0;

//------------------------------------------------------
// Instantiate the Unit Under Test
//------------------------------------------------------
	//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!put code here!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	// make the connections...
	HW1_part_D U0 (
		.inphase	(inphase), 
		.quad		(quad), 
		.symbol 	(symbol)
		);
//------------------------------------------------------
// Code Body
//------------------------------------------------------

	//configuration of stimuli
	always #5 clk <= ~clk;
	
	always @(posedge clk)	{inphase, quad} <= {inphase, quad} + 1;
						
	//known good behavioral model
	always @(inphase, quad)
	begin
		case({inphase[input_bitwidth-1:input_bitwidth-3],quad[input_bitwidth-1:input_bitwidth-3]}) // populate it using truth table mentioned in the assignment
			{	-3'd3,	-3'd3	}:		symbol_known = 4'b0000; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd3,	-3'd1	}:		symbol_known = 4'b0001; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd3,	3'd1	}:		symbol_known = 4'b0011; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd3,	3'd3	}:		symbol_known = 4'b0010; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd1,	-3'd3	}:		symbol_known = 4'b0100; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd1,	-3'd1	}:		symbol_known = 4'b0101; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd1,	3'd1	}:		symbol_known = 4'b0111; //enter1 the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd1,	3'd3	}:		symbol_known = 4'b0110; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd1,		-3'd3	}:	symbol_known = 4'b1100; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd1,		-3'd1	}:	symbol_known = 4'b1101; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd1,		3'd1	}:	symbol_known = 4'b1111; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd1,		3'd3	}:	symbol_known = 4'b1110; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd3,		-3'd3	}:	symbol_known = 4'b1000; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd3,		-3'd1	}:	symbol_known = 4'b1001; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd3,		3'd1	}:	symbol_known = 4'b1011; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd3,		3'd3	}:	symbol_known = 4'b1010; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			default:					symbol_known = symbol;
		endcase
	end
	
	//Simulation Stop
	always @(posedge clk) 
		if(&inphase == 1 && &quad == 1) 
			begin
				$stop;
			end
	
endmodule