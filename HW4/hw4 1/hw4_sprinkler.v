`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:50:19 02/15/2017 
// Design Name: 
// Module Name:    hw4_sprinkler
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
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
output reg [9:0] zone_active_out = 10'b1000000000;
output reg error_out = 0;

//---------------------------Insert your code here---------------------------------//

endmodule