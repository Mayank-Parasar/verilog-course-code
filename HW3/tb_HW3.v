// Testbed for 'Serial_GPS.v'

`include "Serial_GPS.v"

module HW3_tb();

reg 		clk;
reg 		vld;
reg[7:0] 	data_in; // intilize it from the file 'GPS_Serial_data_capture.txt'
reg 		rain_in;
wire[7:0]	data_out;
wire 		out;

// reg 		rain_out; // to get the output from the rain sensor..
reg 		sprink_out;

/////// file handling descriptors... ///////////
integer in; // descriptor for reading from the file...
// integer out; // descriptor for outputting the read value on screen.. for debug pupose
integer statusI; // to hold the status of the file being opened...
integer cntr; // for debugging...

// ---------CLOCK--------------
always #1 clk = ~clk;
// --------RAIN---------------
always #10 rain_in = ~rain_in;
// ----------------------------

//-----------------------------------------------------------
//	Instantiate the Unit Under Test: 16QAM Decoder
//-----------------------------------------------------------
Serial_GPS D0(
	.CLK 						(clk), // input
	.RxD_data_in_ready			(vld), // input
	.RxD_data_in 			(data_in), // input
	.data_out 				(data_out), // don't need this really
	.data_out_valid 			(out) // output
	);

// Initial block...
initial begin
	clk <= 1'b1;
	vld <= 1'b0;
	rain_in <= 1'b0;
	/////////////
	// in <= $fopen("GPS_Serial_data_capture.txt", "r");
	in <= $fopen("gps_data.txt", "r");
	if (in == 0) begin
		$display("could not read from the specified input file");
		$finish;
	end
	data_in <= $fgetc(in);
	/////////////////

	#2 vld <= 1;

	// #100 $finish;
end

// read from the file here.. and pass it to the instantiated module..
always @(negedge clk) begin
	if (!$feof(in)) begin
		// $display("%c", data_in);
		data_in <= $fgetc(in);
		// $display("data_out_valid: %c", data_out);
		sprink_out <= out & (~rain_in); // rain logic
		// $display("data_out_valid: %b", out);
		// $display("rain_out: %b", ~rain_in);
		$display("sprink_out: %b", sprink_out);
	end else begin
	// $display("reached end of the file...");
		$fclose(in);
		// @(negedge clk);
		$finish;
		// $stop;
	end
end

endmodule