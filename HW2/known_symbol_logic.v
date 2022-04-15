//-----------------------------------------------------
// Engineer: Mayank Parasar
//-----------------------------------------------------
// This is the module: known_symbol_logic();
// This module takes inphase and quad as input
// and give known symbol as output.
// This is inspired from file "tb_QPSK_Decode.v"


module known_symbol_logic(inphase_inp, quad_inp, symbol_known); // defines the module

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
	input wire [input_bitwidth-1:0] inphase_inp;
	input wire [input_bitwidth-1:0] quad_inp;
	output reg [symbol_bitwidth-1:0] symbol_known;

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

// Conversion logic here...
	assign inphase_mag = (inphase_inp & 16'b1000_0000_0000_0000) ?  (~inphase_inp + 16'b1) : (inphase_inp);
	assign inphase_sign = (inphase_inp & 16'b1000_0000_0000_0000) ? 1 : 0;

	assign inphase = (inphase_mag > 16'b0010_0000_0000_0000/*0.5*/) ? ((inphase_sign) ? -3'd3 : 3'd3 ) : /*mag<0.5*/((inphase_sign) ? -3'd1 : 3'd1 );

	assign quad_mag = (quad_inp & 16'b1000_0000_0000_0000) ?  (~quad_inp + 16'b1) : (quad_inp);
	assign quad_sign = (quad_inp & 16'b1000_0000_0000_0000) ? 1 : 0;

	assign quad = (quad_mag > 16'b0010_0000_0000_0000/*0.5*/) ? ((quad_sign) ? -3'd3 : 3'd3 ) : /*mag<0.5*/((quad_sign) ? -3'd1 : 3'd1 );

///////////////////////////////



// this is kind of combinational circuit..
// so you can use the case statement and 
// no need to give clock..

	//known good behavioral model
	always @(inphase, quad)
	begin
		case({inphase,quad}) // populate it using truth table mentioned in the assignment
			{	-3'd3/*3'b101*/,	-3'd3/*3'b101*/	}:		symbol_known = 4'b0000; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd3/*3'b101*/,	-3'd1/*3'b111*/	}:		symbol_known = 4'b0001; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd3/*3'b101*/,	3'd1/*3'b001*/	}:		symbol_known = 4'b0011; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd3/*3'b101*/,	3'd3/*3'b011*/	}:		symbol_known = 4'b0010; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd1/*3'b111*/,	-3'd3/*3'b101*/	}:		symbol_known = 4'b0100; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd1/*3'b111*/,	-3'd1/*3'b111*/	}:		symbol_known = 4'b0101; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd1/*3'b111*/,	3'd1/*3'b001*/	}:		symbol_known = 4'b0111; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	-3'd1/*3'b111*/,	3'd3/*3'b011*/	}:		symbol_known = 4'b0110; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd1/*3'b001*/,		-3'd3/*3'b101*/	}:		symbol_known = 4'b1100; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd1/*3'b001*/,		-3'd1/*3'b101*/	}:		symbol_known = 4'b1101; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd1/*3'b001*/,		3'd1/*3'b001*/	}:		symbol_known = 4'b1111; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd1/*3'b001*/,		3'd3/*3'b011*/	}:		symbol_known = 4'b1110; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd3/*3'b011*/,		-3'd3/*3'b101*/	}:		symbol_known = 4'b1000; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd3/*3'b011*/,		-3'd1/*3'b111*/	}:		symbol_known = 4'b1001; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd3/*3'b011*/,		3'd1/*3'b001*/	}:		symbol_known = 4'b1011; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			{	3'd3/*3'b011*/,		3'd3/*3'b011*/	}:		symbol_known = 4'b1010; //enter the correct data here !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			default:	begin  symbol_known = 4'bXXXX; end // shouldn't reach here...
			
		endcase
	end

endmodule