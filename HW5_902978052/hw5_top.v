`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:	   Parasar, Mayank					
// 
// Create Date:    14:46:39 02/28/2017 
// Design Name: 
// Module Name:    hw5_top 
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
module hw5_top(
						clk,
						R,
						G,
						B,
						HS,
						VS,
						out_pixel,
						out_pixel_valid
    );
	
	//Inputs
	input clk;
	input [7:0] R, G, B;
	input HS, VS;

	//Outputs
	output [7:0] out_pixel;
	output out_pixel_valid;


	// Intermediate signals..
	reg [2:0] PS = 0; // Present state (initially at START_ST)
	reg [2:0] NS = 0; // Next state (initially at START_ST)

	// various counters..
	reg [4:0] VS_BP_CNTR = 0;
	reg [5:0] HS_FP_CNTR = 0;
	reg [6:0] HS_BP_CNTR = 0;
	reg [9:0] IM_DIM_CNTR = 0;
	reg [9:0] VGA_ROW_CNTR = 0;
	reg [8:0] FILL_IN_CNTR = 0;
	reg [9:0] GP_CNTR = 0; // this is my general purpose counter

	// various parameters
	/*back-porch phase comes after the pulse has completed*/
	parameter VS_BP_CNT = 23; // this is in-terms of HS-pulses
	parameter HS_FP_CNT = 40; // this is in-terms of cycles
	parameter HS_BP_CNT = 88; // this is in-terms of cycles
	parameter IM_DIM = 512; // this is in-terms of pixels
							// we are reading 1 pixel in a cycle..
	parameter VGA_ROW = 800; // this is the standard line-width 
							 // of vga-signal.
	parameter rows = 512;
	parameter cols = 512;
	parameter FILL_IN_CNT = 288;

	//--------------------------------------------------------
	//State Machine parameter.
	//--------------------------------------------------------
	parameter START_ST = 0; // this state wait for VS sync pulse
	parameter VS_SYNC_PULSE = 1; // detected and currently present at VS_SYNC_PULSE
	parameter VS_BP = 2; // currenlty going through VS_FP phase
	parameter HS_SYNC_PULSE = 3;  // we are in the HS sync-pulse
	parameter HS_BP = 4; // we are going through HS-back-porch
	parameter VALID_OUT = 5; // this is the state which has the valid data
	parameter FILL_IN = 6; // we are going in the state which is >512 and <800
	parameter HS_FP = 7; // we are going though HS-front-porch 


	// Misc.
	reg HS_prev;
	reg is_valid = 0;
	reg done_HS_BP = 0;
	reg img_end_flag = 0;
	reg done_fill_in = 0;
	reg done_HS_FP = 0;

/*~~~~~~~~~~~~~~~~~~~~~~~~~~*/
always @(posedge clk) begin
	HS_prev <= HS;
end
/*~~~~~~~~~~~~~~~~~~~~~~~~~~*/

// this always block maintains HS-counters as they are
// all clock driven
always @(posedge clk) begin
	if (NS == HS_BP) begin
		HS_BP_CNTR = HS_BP_CNTR + 1;
		if (HS_BP_CNTR == (HS_BP_CNT - 1)) // to avoid 1 cycle lag
			done_HS_BP = 1'b1;
		else 
			done_HS_BP = 1'b0;		
	end
	else begin
		HS_BP_CNTR = 0;
		done_HS_BP = 1'b0;
	end
	/*-----------------------------------*/
	if (NS == VALID_OUT)  begin // take care of counting till 512 clocks
		IM_DIM_CNTR = IM_DIM_CNTR + 1;
		if (IM_DIM_CNTR == IM_DIM) 
			img_end_flag = 1'b1; // image row end has reached
		else
			img_end_flag = 1'b0;
	end	
	else begin
		IM_DIM_CNTR = 0;
		img_end_flag = 1'b0;
	end
	/*-----------------------------------*/
	if (NS == FILL_IN) begin
		FILL_IN_CNTR = FILL_IN_CNTR + 1;
		if (FILL_IN_CNTR == FILL_IN_CNT)
			done_fill_in = 1'b1;
		else
			done_fill_in = 1'b0;
	end
	else begin
		FILL_IN_CNTR = 0;
		done_fill_in = 1'b0;
	end
	/*-----------------------------------*/
	if (NS == HS_FP) begin
		HS_FP_CNTR = HS_FP_CNTR + 1;
		if (HS_FP_CNTR == HS_FP_CNT)
			done_HS_FP = 1'b1;
		else
			done_HS_FP = 1'b0;
	end
	else begin
		HS_FP_CNTR = 0;
		done_HS_FP = 1'b0;
	end

end
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
assign out_pixel_valid = is_valid;
assign out_pixel = R;
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
	// create a state machine here..
	always@(posedge clk)
		PS <= NS;

	// Here's my state changing combinational logic..
	always @(*) begin
		// default assignments
		is_valid = 1'b0; // default value...
		NS = 3'b000; // default value...
		case (PS)
			START_ST: begin
				if (VS == 1'b0)
					NS = VS_SYNC_PULSE; // you have detected the falling edge of VS sync pulse
				else 
					NS = START_ST; // you keep looping at the same state.

			end
			/*---------------------------*/
			VS_SYNC_PULSE: begin
				if (VS==1'b1) 
					NS = VS_BP; // you have traversed the VS-sync pulse.. traverse the VS-FP phase next
				else 
					NS = VS_SYNC_PULSE; // still in VS_SYNC_PULSE phase keep looping
			end
			/*---------------------------*/
			VS_BP: begin
				
				if ((HS == 0) && (HS_prev == 1)) // detect the negative edge
					VS_BP_CNTR = VS_BP_CNTR + 1; // this is fine..
				else
					VS_BP_CNTR = VS_BP_CNTR; // keep the value latched

				if (VS_BP_CNTR == VS_BP_CNT + 1) begin // just to compensate the extra HS pulse in the starting of the file data
					NS = HS_SYNC_PULSE;
					VS_BP_CNTR = 0; // reset the counter to be used again if needed.
				end
				else 
					NS = VS_BP; // loop-in

			end
			/*---------------------------*/
			HS_SYNC_PULSE: begin

				if ((HS_prev == 0) && (HS == 1)) // detect the rising edge
					NS = HS_BP;
				else 
					NS = HS_SYNC_PULSE;

			end
			/*---------------------------*/
			HS_BP: begin
				
				if(done_HS_BP) begin
					NS = VALID_OUT;					
				end
				else begin
					NS = HS_BP;
				end				

			end
			/*---------------------------*/
			VALID_OUT: begin
				is_valid = 1'b1;
				if (img_end_flag) begin
					NS = FILL_IN;
				end
				else 
					NS = VALID_OUT;
			
			end
			/*---------------------------*/
			FILL_IN: begin
					if (done_fill_in) 
						NS = HS_FP;
					else
						NS = FILL_IN;
			end

			/*---------------------------*/
			HS_FP: begin
				if(done_HS_FP)
					NS = HS_SYNC_PULSE;
				else
					NS = HS_FP; 
			end
		endcase
	end

endmodule
