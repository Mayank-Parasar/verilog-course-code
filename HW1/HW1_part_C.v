//-----------------------------------------------------
// Engineer: Mayank Parasar
//-----------------------------------------------------
// Copyright (C) 2016  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel MegaCore Function License Agreement, or other 
// applicable license agreement, including, without limitation, 
// that your use is for the sole purpose of programming logic 
// devices manufactured by Intel and sold by Intel or its 
// authorized distributors.  Please refer to the applicable 
// agreement for further details.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 16.1.1 Build 200 11/30/2016 SJ Lite Edition"
// CREATED		"Tue Jan 24 15:50:18 2017"

module HW1_part_C(
	Inphase,
	Quad,
	symbol
);


input wire	[2:0] Inphase;
input wire	[2:0] Quad;
output wire	[3:0] symbol;

wire	[2:0] Inphase_and;
wire	[2:1] Inphase_bar;
wire	[2:0] Quad_and;
wire	[2:1] Quad_bar;
wire	[3:0] Symbol_ALTERA_SYNTHESIZED;




assign	Inphase_and[2] = Inphase[2] & Inphase[1] & Inphase[0];

assign	Quad_and[1] = Quad[0] & Quad_bar[2] & Quad_bar[1];

assign	Quad_and[0] = Quad_bar[2] & Quad[1] & Quad[0];

assign	Symbol_ALTERA_SYNTHESIZED[0] = Quad_and[1] | Quad_and[2];

assign	Symbol_ALTERA_SYNTHESIZED[1] = Quad_and[0] | Quad_and[1];

assign	Quad_bar[2] =  ~Quad[2];

assign	Quad_bar[1] =  ~Quad[1];

assign	Inphase_and[1] = Inphase[0] & Inphase_bar[2] & Inphase_bar[1];

assign	Inphase_and[0] = Inphase_bar[2] & Inphase[1] & Inphase[0];

assign	Inphase_bar[2] =  ~Inphase[2];

assign	Inphase_bar[1] =  ~Inphase[1];

assign	Symbol_ALTERA_SYNTHESIZED[2] = Inphase_and[1] | Inphase_and[2];

assign	Symbol_ALTERA_SYNTHESIZED[3] = Inphase_and[0] | Inphase_and[1];

assign	Quad_and[2] = Quad[2] & Quad[1] & Quad[0];

assign	symbol = Symbol_ALTERA_SYNTHESIZED;

endmodule
