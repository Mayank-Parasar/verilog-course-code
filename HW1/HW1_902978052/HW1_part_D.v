//-----------------------------------------------------
// Engineer: Mayank Parasar
// Overview
//  This is a Gate Level implementation to decode IQ 
//	16QAM data into Symbols.
// Design Name:   HW1_part_D
// File Name:     HW1_part_D.v
//
// Inputs: 
//		inphase: the I input signal from the IQ demodulator
//		quad: the Q input signal from the IQ demodulator
// Outputs: 
//		symbol: The decoded output symbol
//
// History:       17 Jan. 2017, T. Brothers, File Created
//				  23 Jan. 2017, Mayank Parasar, Completed the file
//-----------------------------------------------------

module HW1_part_D(inphase, quad, symbol); // defines the module

//-----------------------------------------------------
// PARAMETERS : universal things that you cannot change during the run..
//-----------------------------------------------------

//Modules Parameters
parameter input_bitwidth = 3;
parameter symbol_bitwidth = 4;

//-----------------------------------------------------
// SIGNALS
//-----------------------------------------------------

//Module inputs and outputs
input wire [input_bitwidth-1:0] inphase;
input wire [input_bitwidth-1:0] quad;
output wire [symbol_bitwidth-1:0] symbol;

// User defined signals
//ours is complex and need more wires...
//wire example_signal;
// These wires contain the output of not gate in verilog...
wire [1:0] quad_bar;
wire [1:0] inphase_bar;
// Intermediate output from AND gates
wire [2:0] quad_and;
wire [2:0] inphase_and;

//-----------------------------------------------------
// Instantiate the Gates
//-----------------------------------------------------
// For Quadrature component
and and_1(quad_and[2],quad[0], quad[1], quad[2]);
not not_1(quad_bar[1], quad[2]);
not not_2(quad_bar[0], quad[1]);
and and_2(quad_and[1],quad[0], quad_bar[0], quad_bar[1]);
and and_3(quad_and[0],quad[0], quad[1], quad_bar[1]);
or or_1(symbol[0], quad_and[2], quad_and[1]);
or or_2(symbol[1], quad_and[1], quad_and[0]);

// For Inphase component
// and and_Q(symbol[1],inphase[0], inphase[1]);	
and and_4(inphase_and[2],inphase[0], inphase[1], inphase[2]);
not not_3(inphase_bar[1], inphase[2]);
not not_4(inphase_bar[0], inphase[1]);
and and_5(inphase_and[1],inphase[0], inphase_bar[0], inphase_bar[1]);
and and_6(inphase_and[0],inphase[0], inphase[1], inphase_bar[1]);
or or_3(symbol[2], inphase_and[2], inphase_and[1]);
or or_4(symbol[3], inphase_and[1], inphase_and[0]);

endmodule