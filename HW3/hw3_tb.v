`timescale 1ns / 1ps
// `include "hw3_sprinkler.v"
/**************************Contributers****************************
Name: Mayank Parasar
Name: Sahana Murthy
Name: Michael Gordon
Name: Jack Bush
*******************************************************************/

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
