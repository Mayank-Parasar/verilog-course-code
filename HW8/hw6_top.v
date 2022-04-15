`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:	   Mudassar, B
// 
// Create Date:    14:46:39 02/28/2017 
// Design Name: 
// Module Name:    hw6_top 
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
module hw6_top(
						clk,
						sel_operation,
						R_in,
						G_in,
						B_in,
						HS_in,
						VS_in,
						pixel_out,
						pixel_valid_out,
						R_out,
						G_out,
						B_out,
						HS_out,
						VS_out
    );
	
//Inputs
input clk;
input sel_operation;
input [7:0] R_in, G_in, B_in;
input HS_in, VS_in;


//Outputs
output [7:0] pixel_out;
output pixel_valid_out;
output [7:0] R_out, G_out, B_out;
output VS_out, HS_out;

//Your code here


endmodule
