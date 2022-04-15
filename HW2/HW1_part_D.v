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

module HW1_part_D(inphase_inp, quad_inp, symbol); // defines the module

//-----------------------------------------------------
// PARAMETERS : universal things that you cannot change during the run..
//-----------------------------------------------------

//Modules Parameters
parameter input_bitwidth = 3;
parameter symbol_bitwidth = 4;

//-----------------------------------------------------
// SIGNALS
//-----------------------------------------------------

// Module inputs and outputs
input wire [input_bitwidth-1:0] inphase_inp;
input wire [input_bitwidth-1:0] quad_inp;
output wire [symbol_bitwidth-1:0] symbol;


// User defined signals
// For performing rounding/conversion logic here
// we need new set of wires of hardcoded 3-bits
wire [2:0] inphase;
wire [2:0] quad;

// wire containing mag.
wire [input_bitwidth-1:0] inphase_mag;
wire [input_bitwidth-1:0] quad_mag;

// Wire to decide the sign of inphase_inp and quad_phas_in for rounding
wire inphase_sign; // 0: positive; 1: negative
wire quad_sign; // 0: positive; 1: negative

// These wires contain the output of not gate in verilog...
wire [1:0] quad_bar;
wire [1:0] inphase_bar;
// Intermediate output from AND gates
wire [2:0] quad_and;
wire [2:0] inphase_and;


// Conversion (rounding) logic here...
				
assign inphase_mag = (inphase_inp & 16'b1000_0000_0000_0000) ?  (~inphase_inp + 16'b1) : (inphase_inp);
assign inphase_sign = (inphase_inp & 16'b1000_0000_0000_0000) ? 1 : 0;

assign inphase = (inphase_mag > 16'b0010_0000_0000_0000/*0.5*/) ? ((inphase_sign) ? -3'd3 : 3'd3 ) : /*mag<0.5*/((inphase_sign) ? -3'd1 : 3'd1 );

assign quad_mag = (quad_inp & 16'b1000_0000_0000_0000) ?  (~quad_inp + 16'b1) : (quad_inp);
assign quad_sign = (quad_inp & 16'b1000_0000_0000_0000) ? 1 : 0;

assign quad = (quad_mag > 16'b0010_0000_0000_0000/*0.5*/) ? ((quad_sign) ? -3'd3 : 3'd3 ) : /*mag<0.5*/((quad_sign) ? -3'd1 : 3'd1 );

///////////////////////////////


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