//-----------------------------------------------------
// Engineer: Mayank Parasar
// Overview
// In this file, I want to create self checking test-bed 
//
//
// History:       27 Jan. 2017, Mayank Parasar, File Created
//				  28 Jan. 2017, Mayank Parasar, Working on the file
//-----------------------------------------------------

module HW2_tb_16QAM();

//------------------------------------------------------
// Parameters
//------------------------------------------------------
	
	parameter input_bitwidth = 16;
	parameter symbol_bitwidth = 4;


//------------------------------------------------------
// Signals
//------------------------------------------------------
	// probe
	reg [31:0] dummy;
	reg [input_bitwidth - 1:0] inphase; 
	reg [input_bitwidth - 1:0] quad;
	wire [symbol_bitwidth - 1:0] symbol;
	wire [symbol_bitwidth - 1:0] symbol_known;

	//testbench signals
	reg clk;

	// file descriptors should be declared of type integers.. 
	
	integer in; // descriptor for reading from the file..
	integer out; // for outputting on the screen, for debugging purpose.
	integer statusI; // to hold the status of the file being opened...


// ---------CLOCK--------------
always #1 clk = ~clk;
// -----------------------

//-----------------------------------------------------------
//	Instantiate the Unit Under Test: 16QAM Decoder
//-----------------------------------------------------------
	HW1_part_D #(.input_bitwidth (16)) U0 (
		.inphase_inp	(inphase), 
		.quad_inp		(quad), 
		.symbol 	(symbol)
		);
// -----------------------------------------------------------


//-----------------------------------------------------------
//	Instantiate Known Symbol logic (made the connections here...)
//-----------------------------------------------------------
	known_symbol_logic #(.input_bitwidth (16)) U1 (
		.inphase_inp		(inphase), 
		.quad_inp			(quad), 
		.symbol_known 	(symbol_known)
		);
// -----------------------------------------------------------

initial begin
	clk <= 1'b1;
	in = $fopen("VHDLVects.txt", "r"); // open file for reading..
	out <= $fopen("result_file.dat", "w"); // open file for writing..
	if ((in == 0) || (out == 0)) begin
		$display("could not create file for outpur or could not read file for data");
		$finish;
	end
	statusI <= $fscanf(in,"%b\n", dummy[31:0]); // this reads one line at a time...
	inphase <= dummy[31:16];
	quad <= dummy[15:0];

end

// read from the file here..
always @(negedge clk) begin

	if(!$feof(in)) begin

		/*write to the file here...*/
		if ((symbol == 4'bxxxx) || (symbol_known == 4'bxxxx)) 
			$display("Unknown symbol!!!");

		if (symbol_known != symbol) begin
			$fwrite(out, "0\n");
			$display("Output does not match\n");
		end else begin
			$fwrite(out, "1\n");
		end

		statusI = $fscanf(in,"%b\n", dummy[31:0]); // this reads one line at a time...
		inphase = dummy[31:16];
		quad = dummy[15:0];

	end	else begin
		@(negedge clk);
	
		/*write to the file here...*/
		if ((symbol == 4'bxxxx) || (symbol_known == 4'bxxxx)) 
			$display("Unknown symbol!!!");

		if (symbol_known != symbol) begin
			$fwrite(out, "0\n");
			$display("Output does not match\n");
		end else begin
			$fwrite(out, "1\n");
		end		
		$stop;	
		// $finish;
	end

end

endmodule
