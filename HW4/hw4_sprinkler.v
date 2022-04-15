

/*Mayank Parasar*/

module hw4_sprinkler(clk, rain_sensor_in, gps_data_in,
					gps_valid_in, program_valid_in, program_zone_in,
					program_time_in, zone_active_out, error_out);

// INPUTs
input clk;
input rain_sensor_in;
input [7:0] gps_data_in;
input gps_valid_in;
input program_valid_in; // must be held high for 1 clock-cycle to indicate data on 
						// the 'program_zone_in' and 'program_time_in' are valid
input [4:0] program_zone_in; //passed as unsigned value from 1 to 20
input [31:0] program_time_in; //is set in the format hhmm in ASCII format

// OUTPUTs
output [9:0] zone_active_out; // this will contain the zone id; which is currntly getting watered
output error_out; // if more than 1 zone are getting watered at any given time...



// The state machine must be designed with an Algorithmic State Machine (AMS)
// diagram. Please turn in your ASM diagram and your block diagram at the start
// of class. 

reg flag = 1'b0;

always @(posedge clk) begin
	if (program_valid_in) begin
		/*should set some flag here which would drive other synchronous block..*/
		flag = 1'b1;
	end else begin
		flag = 1'b0;
	end
end


always @(flag) begin
	/*code your logic here...*/
end