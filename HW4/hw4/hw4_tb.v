`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 	   Mudassar, Burhan
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
			
			program_zone_in = 5'd0;
			program_time_in = 31'd0;
			program_valid_in = 0;
			
			program_file = $fopen("zone_program.txt","rb");
			if(program_file==0)
				$display("Error! Unable to open Zone program file");
			
			GPS_file = $fopen("GPS_Serial_data_capture.txt","rb");
			if(GPS_file ==0)
				$display("Error! Could not open GPS file");
				
			result_file = $fopen("result_file.dat","w");
			if(result_file == 0)
				$display("Error! Unable to open result_file.dat");

				
			//Read in the programming file

			// @ (posedge clk) r = $fscanf(program_file, "%d, %s", program_zone_in, program_time_in);
			// 				program_valid_in = 1;
			
			while(!$feof(program_file))
			begin
				@(posedge clk)		r = $fscanf(program_file, "%d, %s", program_zone_in, program_time_in);
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
			$fclose(result_file);
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
	
	// ----------------------Useful functions for printing out result data and toggling rain sensor---------------------------------------//
	wire [7:0] gps_data_out_ascii;
	wire gps_data_out_valid;


	serial_gps_mine serial_uut (
    .CLK(clk), 
    .RxD_data_in_ready(gps_valid_in), 
    .RxD_data_in(gps_data_in), 
    .data_out(gps_data_out_ascii), 
    .data_out_valid(gps_data_out_valid)
    );
	 
	 //See whether the register values are valid or not
	 reg [3:0] data_out_valid_counter = 0;
	 always @ (posedge clk)
	 begin
			if(gps_data_out_valid && data_out_valid_counter!=4'd5)			data_out_valid_counter <= data_out_valid_counter+1;
			else if(gps_data_out_valid && data_out_valid_counter==4'd5)		data_out_valid_counter <= 4'd0;
			else															data_out_valid_counter <= data_out_valid_counter;
	 end
	 
	 wire time_reg_valid = (data_out_valid_counter == 0);
	 
	 reg [7:0] curr_time [5:0];
	 integer i;
	 always @(posedge clk)
	 begin
			if(gps_data_out_valid)
			begin
					curr_time[0] <= gps_data_out_ascii;
					for (i=1; i<6; i=i+1)
						curr_time[i] <= curr_time[i-1];
			end
	 end
	 
	 
	 //Turn on rain sensor whenever mm == 10 or 11
	 always @*
		if(time_reg_valid)
			if({curr_time[3],curr_time[2]} == "10" || {curr_time[3],curr_time[2]} == "11")
				rain_sensor_in = 1;
			else
				rain_sensor_in = 0;

	 //Print out to result file
	 always @(program_zone_in,program_time_in)
		$fwrite(result_file,"Programing Zone: %d, %s\n",program_zone_in,program_time_in);
	 
	 always @(time_reg_valid)
		if(time_reg_valid)
			$fwrite(result_file,"Time: %c%c%c%c%c%c, Rain: %d, Zone_Active: %b\n",curr_time[5],curr_time[4],curr_time[3],curr_time[2],curr_time[1],curr_time[0], rain_sensor_in, zone_active_out);


endmodule
