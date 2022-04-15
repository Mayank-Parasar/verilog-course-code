`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Parasar, Mayank
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
module hw6_top (
						clk,
						sel_operation, // 0 indicates edge, 1 indicates transpose
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
output [7:0] R_out;
output [7:0] G_out;
output [7:0] B_out;
output HS_out;
output VS_out;


	////Instantiate read_data here////
    wire [7:0]	raw_data_out;
    wire raw_data_valid_out;
	read_file read_img	(		// THis module will write to memory as well as read it from the image
						.clk(clk),
						.R(R_in),
						.G(G_in),
						.B(B_in),
						.HS(HS_in),
						.VS(VS_in),
						.sel_operation(sel_operation),
						.out_pixel(raw_data_out),
						.out_pixel_valid(raw_data_valid_out)
					);
	////Instantiate Transpose here////
   transpose transpose_img (	//This module will output the readfile from the same memory..
	                        .clk(clk),
	                        .Data_in(raw_data_out),
	                        .Data_Valid_in(raw_data_valid_out),
	                        .pixel_out(pixel_out),
	                        .pixel_valid_out(pixel_valid_out),
	                        .R_out(R_out),
	                        .G_out(G_out),
	                        .B_out(B_out),           
	                        .HS_out(HS_out),
	                        .VS_out(VS_out)
                      );
   // Instantiate Edge Detection Unit here //
   // edge_detection edge_detection_unit (

   // 	);

endmodule