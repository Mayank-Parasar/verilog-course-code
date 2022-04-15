//-----------------------------------------------------
// Engineer: Mayank Parasar
// Overview
// In this file, I want to create self checking test-bed 
//
//
// History:       27 Jan. 2017, Mayank Parasar, File Created
//				  28 Jan. 2017, Mayank Parasar, Working on the file
//-----------------------------------------------------


`include "HW1_part_D.v"

module self_checking_testbed();

//------------------------------------------------------
// Parameters
//------------------------------------------------------
	
	parameter input_bitwidth = 3;
	parameter symbol_bitwidth = 4;


// create some obvious symbols/parameters here...
reg clk;
reg [15:0] din_inphase; // this will be helpful in reading the inphase part from VHDLVects.txt
reg [15:0] din_quad; // this will be helpful in reading the inphase part from VHDLVects.txt
reg [31:0] dummy;
reg [input_bitwidth - 1:0] inphase; 
reg [input_bitwidth - 1:0] quad;
wire [symbol_bitwidth - 1:0] symbol;

// file descriptors should be declared of type integers.. 
// taken from asic world example...
integer in; // descriptor for reading from the file..
integer out; // for outputting on the screen, for debugging purpose.
integer statusI; // to hold the status of the file being opened...
integer cntr;  // for debugging

initial begin
	in = $fopen("VHDLVects.txt", "r"); // open file for reading..
end

// ---------CLOCK--------------
always #1 clk = ~clk;
// -----------------------

//-----------------------------------------------------------
//	Instantiate the Unit Under Test
//-----------------------------------------------------------
	HW1_part_D U0 (
		.inphase	(inphase), 
		.quad		(quad), 
		.symbol 	(symbol)
		);
// -----------------------------------------------------------

initial begin
	clk <= 1'b1;
	// cntr <= 1'b0;
	#40000 $finish(); 
end

// read from the file here..

// always @(posedge clk) begin
initial begin
	while(!$feof(in)) begin
	@(posedge clk);
	// cntr = cntr + 1;
	statusI = $fscanf(in,"%b\n", dummy[31:0]); // this reads one line at a time...
	$display("%b",dummy);
	din_inphase[15:0] = dummy[31:16];
	din_quad[15:0] = dummy[15:0];
	
	inphase = din_inphase[15:13];
	quad = din_quad[15:13];
	// @(negedge clk);
	// why symbol is not getting initialized..?
	$display("self_checking_testbed.U0.inphase = %b \t self_checking_testbed.U0.quad = %b", self_checking_testbed.U0.inphase, self_checking_testbed.U0.quad);
	$display("din_phase = %b \t din_quad = %b \t inphase = %b \t quad = %b \t symbol = %b", din_inphase, din_quad, inphase, quad, symbol);
	// $display("\tcntr = %d", cntr);
	end	
end

endmodule
