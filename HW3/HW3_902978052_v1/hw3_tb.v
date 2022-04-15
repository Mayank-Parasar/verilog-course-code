`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		Carrier Frequency, Inc.
// Engineer: 		Parasar, Mayank Parasar
// 					Murthy, Sahana Kishore
// 					Bush, Jack
// 					Gordon, Michael
// 
// Create Date:		20:03:42 02/08/2017 
// Design Name: 	hw3_tb.v
// Module Name:    	hw3_tb 
// Project Name: 	Sprinkler System
// Target Devices: 	Sprinkler System
//
// Revision 0.01 - File Created
// Revision 0.02 - 2017.02.03 Modifed file for use at Ga Tech for
//					class example. Removed all references to the LCD and moved the 
//					UART outside the module.
// Revision 0.03 - Modified file for testbench to verify sprinkler system
// Additional Comments: This is a testbench use for the sprinkler system designed 
// 						for hw3. The requirements of the system are that the 
// 						system should be turned on when it is dark (using GPS data)
// 						and turned off for when it is not raining. 
//////////////////////////////////////////////////////////////////////////////////

module hw3_tb();

reg 		clk;
reg 		rain_sensor_in;
reg 		gps_valid_in;
reg [7:0] 	gps_data_in;
wire 		zone_active_out;


//--------------------------FILE-I/O-------------------------------//
integer in; // descriptor for reading from the file...

//--------------------------CLOCK----------------------------------//
always #1 clk = ~clk;
//---------------------------RAIN---------------------------------//
// rain_sensor_in = 1'b0;
// always #10 rain_sensor_in = ~rain_sensor_in;
//--------------------------Instantiation--------------------------//
hw3_sprinkler dut(
.clk 				(clk),
.rain_sensor_in 	(rain_sensor_in), // being feed from TB
.gps_valid_in 		(gps_valid_in), // file I/O from tb
.gps_data_in		(gps_data_in),
.zone_active_out	(zone_active_out) // output for the sprinkler....
);
//-----------------------------------------------------------------//


// Initial block...
initial begin
	clk = 1'b1;
	gps_valid_in =1'b1;
	rain_sensor_in =1'b0; // no rain...
	// in = $fopen("gps_data.txt", "r");
	in = $fopen("GPS_Serial_data_capture.txt", "r");

	if (in == 0) begin
		$display("could not read from the specified input file");
		$finish;		
	end
	gps_data_in = $fgetc(in);

end

// read from the file here.. and pass it to the instantiated module..
always @(negedge clk) begin
	if (!$feof(in)) begin
		gps_data_in <= $fgetc(in);
		// $display("gps_data_in: %c", gps_data_in);
		// $display("zone_active_out: %b", zone_active_out);
	end else begin
		$fclose(in);
		$stop;
		// $finish;
	end
end

endmodule