`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 	   Mudassar, Burhan
// 				   Parasar, Mayank
// 
// Create Date:    16:01:23 02/07/2017 
// Design Name: 
// Module Name:    hw4_tb 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created		02/07/2017 for hw3
//			0.02 - File Modified	02/15/2017 for hw4
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module hw4_tb;

	//Stimuli
	reg clk;
	reg rain_sensor_in;
	reg [7:0] gps_data_in;
	reg gps_valid_in;
	
	reg [4:0] program_zone_in;
	reg [31:0] program_time_in;
	reg program_valid_in;

	//Probe
	wire [9:0] zone_active_out;
	wire error_out;
	
	//Misc.
	integer GPS_file;
	integer program_file;
	integer result_file;
	integer r;
	
	always #5 clk <= clk+1;	
	//Initialize values and open files
	
	initial
		begin
			clk = 0;
			rain_sensor_in = 0;			
			gps_data_in = 8'd0;
			gps_valid_in = 0;
			rain_sensor_in = 0;
			program_zone_in = 5'd0;
			program_time_in = 31'd0;
			program_valid_in = 0;
			
			program_file = $fopen("zone_program-conflict.txt","rb");
			if(program_file==0)
				$display("Error! Unable to open Zone program file");
			
			GPS_file = $fopen("GPS_Serial_data_capture.txt","rb");
			if(GPS_file ==0)
				$display("Error! Could not open GPS file");

				
			//Read in the programming file			
			while(!$feof(program_file))
			begin
				@(posedge clk)		r = $fscanf(program_file, "%d, %s", program_zone_in, program_time_in); // it's blocking in nature
									program_valid_in = 1;
			end

			program_valid_in = 0;
			
			//Read in the GPS file
			while(!$feof(GPS_file))
			begin
				@(posedge clk)		gps_data_in = $fgetc(GPS_file);
									gps_valid_in = 1;
			end
			
			gps_valid_in = 0;
			$fclose(GPS_file);
			$fclose(program_file);
			
			$stop;
			
		end
		
	//--------Instantiate your module---------------//	
	hw4_sprinkler uut(
						.clk(clk),
						.rain_sensor_in(rain_sensor_in),
						.gps_data_in(gps_data_in),
						.gps_valid_in(gps_valid_in),
						.program_zone_in(program_zone_in),
						.program_time_in(program_time_in),
						.program_valid_in(program_valid_in),
						.zone_active_out(zone_active_out),
						.error_out(error_out)
	);

	/*put your logic for changing the rain_sensor_in signal*/
	always #100 rain_sensor_in = ~rain_sensor_in;

	/*Print the stats here...*/
	// always @(posedge clk) begin
	// 	$display("rain_sensor_in: %b", rain_sensor_in);
	// 	$display("zone_active_out: %b", zone_active_out);
	// 	$display("error_out: %b", error_out);
	// end

endmodule