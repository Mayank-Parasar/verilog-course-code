`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 		Parasar, Mayank
// 
// Create Date:    11:50:19 02/15/2017 
// Design Name: 
// Module Name:    hw4_sprinkler
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 		This is the file that implements the sprinkler
//						logic, for 10-zones.
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module hw4_sprinkler(clk, rain_sensor_in, gps_data_in, gps_valid_in, program_zone_in, program_time_in, program_valid_in, zone_active_out, error_out);

//Inputs
input clk;
input rain_sensor_in;
input [7:0] gps_data_in;
input gps_valid_in;
	
input [4:0] program_zone_in;
input [31:0] program_time_in;
input program_valid_in;

//Outputs
// let the default zone be 0; we will set the correct output
// later in the state machine...
output reg [9:0] zone_active_out = 10'b0000000000; 
output reg error_out = 0;


//---------------------------Insert your code here---------------------------------//

//===============================================================================================
//-------------------Create the mechanism to grab the serial data and parse it-------------------
//===============================================================================================

reg [9:0] cnt = 0;
reg [31:0] zone_time[0:19]; // start-end time for 10 zones

reg [7:0] CHAR_CNT=0;
reg [3:0] STATE=0;
reg [31:0] TIME=0;
reg [23:0] NMEA=0;
reg [9:0] in_zone=0;
reg [3:0] ones = 0; // this will count the number of ones in the bit-vector
reg [9:0] tmp_zone_active_out = 10'b0000000000;  // output from rain-sensor would be the right output


// CREATE THE COUNTING MECHANISM FOR PARSING THE SERIAL DATA
always @(negedge clk) begin
	if(gps_valid_in) begin				
		TIME[31:8]<=TIME[23:0];
		TIME[7:0]<=gps_data_in;
		if(gps_data_in=="$")begin // '$': Start of frame
			CHAR_CNT<=0;
		end
		else begin
			CHAR_CNT<=CHAR_CNT+1;	
		end
	end	
end

// CREATE THE MECHNISM THAT PARSES THE SERIAL DATA

/*Reading from the file.. works...*/
always@(negedge clk) 
begin
	case(STATE)
		//---------------------Reading from the zone-program file-------------------------------
		0: 
		begin
			if((program_valid_in==0) && (cnt==0)) // initial condition at the very begining..
				STATE<=STATE;
			else if (program_valid_in) 
					begin
						zone_time[cnt] <= program_time_in;
						cnt <= cnt + 1;
					end 
				else 
					begin
						STATE <= STATE + 1;
					end
		end
		//---------------------Now read from the GPS data file-------------------------------
		1:
		begin // search for '$'
			if (gps_valid_in) 
				begin
					if (gps_data_in == "$")  // '$': Start of frame
						begin
							STATE<=STATE+1;	
						end	
				end
			else  // shouldn't be the case..
				begin
					STATE<=STATE;
				end
		end
		//------Check Tag, if not the proper tag go back to 1, else proceed to 3------------
		2:
		begin
			if (gps_valid_in) 
				begin
					if (gps_data_in==",") 
						begin
							if (NMEA=="GGA")  // GGA, this is the message containing the time..
								begin
									STATE<=STATE+1;
								end		
							else  // Wrong message, go back and search for the start of next message.
								begin
									STATE<=STATE-1;
								end
						end	
					else  // Grab the NMEA Message Type...
						begin
							NMEA[23:8]<=NMEA[15:0];
							NMEA[7:0]<=gps_data_in; // Grab the tag info
						end	
				end
		end
		//-------------------------Parse the time information---------------------------
		3:
		begin
			if (gps_valid_in) 
				begin
					if (gps_data_in==10) 
						begin
							STATE<=1;	
						end	
					else 
						begin
							if (CHAR_CNT==10)  // 'TIME' reg contains the time in hhmm format at this point
								begin /*decision making state...*/
									// in_zone = 0; // so that is contain the most updated information...
									/*is time in zone 1: if it is the starting time of z1, then set flag to 'yes'*/
									if (TIME==zone_time[0]) // you want to have bit-wise OR so that it retain the older in-range values
										in_zone = in_zone | 10'b0000000001;  // you would like it to be blocking..
									if (TIME==zone_time[1]) 
										in_zone = in_zone & 10'b1111111110; /*if it is ending time of z1 then set flag to 'no'*/
									/*is time in zone 2*/
									if (TIME==zone_time[2])
										in_zone = in_zone | 10'b0000000010;  
									if (TIME==zone_time[3]) 
										in_zone = in_zone & 10'b1111111101; 
									/*is time in zone 3*/
									if (TIME==zone_time[4])
										in_zone = in_zone | 10'b0000000100;  
									if (TIME==zone_time[5]) 
										in_zone = in_zone & 10'b1111111011; 									
									/*is time in zone 4*/
									if (TIME==zone_time[6])
										in_zone = in_zone | 10'b0000001000;  
									if (TIME==zone_time[7]) 
										in_zone = in_zone & 10'b1111110111; 									
									/*is time in zone 5*/
									if (TIME==zone_time[8])
										in_zone = in_zone | 10'b0000010000;  
									if (TIME==zone_time[9]) 
										in_zone = in_zone & 10'b1111101111; 
									/*is time in zone 6*/
									if (TIME==zone_time[10])
										in_zone = in_zone | 10'b0000100000;  
									if (TIME==zone_time[11]) 
										in_zone = in_zone & 10'b1111011111; 
									/*is time in zone 7*/
									if (TIME==zone_time[12])
										in_zone = in_zone | 10'b0001000000;  
									if (TIME==zone_time[13]) 
										in_zone = in_zone & 10'b1110111111; 
									/*is time in zone 8*/
									if (TIME==zone_time[14])
										in_zone = in_zone | 10'b0010000000;  
									if (TIME==zone_time[15]) 
										in_zone = in_zone & 10'b1101111111; 									
									/*is time in zone 9*/
									if (TIME==zone_time[16])
										in_zone = in_zone | 10'b0100000000;  
									if (TIME==zone_time[17]) 
										in_zone = in_zone & 10'b1011111111; 									
									/*is time in zone 10*/
									if (TIME==zone_time[18])
										in_zone = in_zone | 10'b1000000000;  
									if (TIME==zone_time[19]) 
										in_zone = in_zone & 10'b0111111111; 									

									STATE=STATE+1;
									/*if program_valid_in signal becomes high... go to the start of the program*/
									if(program_valid_in)
										STATE=0;									
								end
							else 
								begin
									STATE<=STATE; // keep looping on this state until we reach the end of the line...
								end
						end
				end
		end
		//-------------------------Conflict detection state---------------------------
		4:
		begin
			ones =	((in_zone[0] + in_zone[1] + in_zone[2] + in_zone[3]) +
						(in_zone[4] + in_zone[5] + in_zone[6] + in_zone[7]) +
						(in_zone[8] + in_zone[9]));

			/*water the zone anyways...*/
			if(in_zone[0])
				tmp_zone_active_out = 10'b0000000001;
			else if (in_zone[1])
				tmp_zone_active_out = 10'b0000000010;
			else if (in_zone[2])
				tmp_zone_active_out = 10'b0000000100;
			else if (in_zone[3])
				tmp_zone_active_out = 10'b0000001000;
			else if (in_zone[4])
				tmp_zone_active_out = 10'b0000010000;
			else if (in_zone[5])
				tmp_zone_active_out = 10'b0000100000;
			else if (in_zone[6])
				tmp_zone_active_out = 10'b0001000000;
			else if (in_zone[7])
				tmp_zone_active_out = 10'b0010000000;
			else if (in_zone[8])
				tmp_zone_active_out = 10'b0100000000;
			else if (in_zone[9])
				tmp_zone_active_out = 10'b1000000000;	
			else // for the case, when there is no zone time...
				tmp_zone_active_out = 10'b0000000000; // default value
			/*move back to the starting state..*/
			STATE=1;
		end

		default: begin
			STATE<=1; // go read the gps file...
		end
	endcase
end

/*Rain Module: defined it here...*/
/*Combinational logic, which drives the final output*/
always@(*) begin
	if (rain_sensor_in) 
		zone_active_out <= 10'b0000000000;
	else 
		zone_active_out <= tmp_zone_active_out;

	if (ones > 1) 
		error_out <= 1;
	else
		error_out <= 0;
end

endmodule