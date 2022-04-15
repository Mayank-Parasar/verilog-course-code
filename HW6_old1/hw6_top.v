`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:	   Mudassar, B
// 					Parasar, Mayank
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
	input [7:0] R_in, G_in, B_in;
	input HS_in, VS_in;
	input sel_operation;

	//Outputs
	output [7:0] pixel_out;
	output pixel_valid_out;
	output [7:0] R_out, G_out, B_out;
	output HS_out, VS_out;


	// Input for RAM DUT
	// reg clka, clkb;
	reg [511:0]wea = 0;
	reg [511:0]ena = 0;
	reg [511:0]enb = 0;
	reg [8:0] addra = 0; // byte address
	reg [8:0] addrb = 0; // byte address
	reg [7:0] dia = 0; // input can fanout

	// Output for RAM DUT
	wire [(512 * 8) - 1:0] doa; // this will be present on RHS of an always block
	wire [(512 * 8) - 1:0] dob; // this will be present on RHS of an always block

	// Instantiate the RAM here to save the image first

	generate
		genvar i;
		for (i = 0; i < 512; i = i + 1)
		begin:ram_row_instance
			v_ram_01_1 ram ( 				// one ram per row!
								.clka(clk),
								.clkb(clk),
								.wea(wea[i]),
								.ena(ena[i]),
								.enb(enb[i]),
								.addra(addra),
								.addrb(addrb),
								.dia(dia),
								.doa(doa[((i+1)*8 - 1) : (i*8)]),
								.dob(dob[((i+1)*8 - 1) : (i*8)])
				);			
		end
	endgenerate


	// Intermediate signals..
	reg [3:0] PS = 0; // Present state (initially at START_ST)
	reg [3:0] NS = 0; // Next state (initially at START_ST)

	// various counters..
	reg [4:0] VS_BP_CNTR = 0;
	reg [5:0] HS_FP_CNTR = 0;
	reg [6:0] HS_BP_CNTR = 0;
	reg [9:0] IM_DIM_CNTR = 0;
	reg [9:0] VGA_ROW_CNTR = 0;
	reg [8:0] FILL_IN_CNTR = 0;
	reg [8:0] CNTR_X = 0; // to count the number of pixels sent on a row
	reg [8:0] CNTR_Y = 0;  // to count the number of rows sent

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
	parameter VS_SYNC_PULSE_ST = 1; // detected and currently present at VS_SYNC_PULSE_ST
	parameter VS_BP_ST = 2; // currenlty going through VS_FP phase
	parameter HS_SYNC_PULSE_ST = 3;  // we are in the HS sync-pulse
	parameter HS_BP_ST = 4; // we are going through HS-back-porch
	parameter VALID_OUT_ST = 5; // this is the state which has the valid data
	parameter FILL_IN_ST = 6; // we are going in the state which is >512 and <800
	parameter HS_FP_ST = 7; // we are going though HS-front-porch 
	parameter TRANSPOSE_OUT_ST = 8; // once in this state we are expected to send out transpose of the image
	parameter STOP_ST = 9; // this is the STOP_ST of the state machine

	// Misc.
	reg HS_prev;
	reg is_valid = 0;
	reg done_HS_BP = 0;
	reg img_row_end_flag = 0;
	reg done_fill_in = 0;
	reg done_HS_FP = 0;
	reg [9:0]row = 0; // to compensate for offset
	reg done_transpose = 0;
	reg [7:0]trans_pixel = 0;

/*~~~~~~~~~~~~~~~~~~~~~~~~~~*/
always @(posedge clk) begin
	HS_prev <= HS_in;
end
/*~~~~~~~~~~~~~~~~~~~~~~~~~~*/

// this always block maintains HS-counters as they are
// all clock driven
always @(posedge clk) begin
	if (NS == HS_BP_ST) begin
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
	if (NS == VALID_OUT_ST)  begin // take care of counting till 512 clocks
		IM_DIM_CNTR = IM_DIM_CNTR + 1;
		if (IM_DIM_CNTR == IM_DIM) 
			img_row_end_flag = 1'b1; // image row end has reached
		else
			img_row_end_flag = 1'b0;
	end	
	else begin
		IM_DIM_CNTR = 0;
		img_row_end_flag = 1'b0;
	end
	/*-----------------------------------*/
	if (NS == FILL_IN_ST) begin
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
	if (NS == HS_FP_ST) begin
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
	/*-----------------------------------*/
	if (NS == TRANSPOSE_OUT_ST) begin
		CNTR_X = CNTR_X + 1;
		if (CNTR_X == IM_DIM) begin
			CNTR_X = 0;
			CNTR_Y = CNTR_Y + 1;
		end
		else begin // preserve the value
			CNTR_X = CNTR_X;
			CNTR_Y = CNTR_Y;
		end

		if (CNTR_Y == IM_DIM) begin
			done_transpose = 1'b1;
			/*reset all signals*/
			CNTR_X = 0;
			CNTR_Y = 0;
		end
		else begin
			done_transpose = 1'b0;
			CNTR_X = CNTR_X;
			CNTR_Y = CNTR_Y;		
		end	
	end	
end
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
assign pixel_valid_out = is_valid;
assign pixel_out = trans_pixel;
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
	// create a state machine here..
	always@(posedge clk)
		PS <= NS;

	// Here's my state changing combinational logic..
	always @(*) begin
		// default assignments
		is_valid = 1'b0; // default value...
		NS = 4'b0000; // default value...
		case (PS)
			START_ST: begin
				if (VS_in == 1'b0)
					NS = VS_SYNC_PULSE_ST; // you have detected the falling edge of VS sync pulse
				else 
					NS = START_ST; // you keep looping at the same state.

			end
			/*---------------------------*/
			VS_SYNC_PULSE_ST: begin
				if (VS_in == 1'b1) 
					NS = VS_BP_ST; // you have traversed the VS-sync pulse.. traverse the VS-FP phase next
				else 
					NS = VS_SYNC_PULSE_ST; // still in VS_SYNC_PULSE_ST phase keep looping
			end
			/*---------------------------*/
			VS_BP_ST: begin
				
				if ((HS_in == 0) && (HS_prev == 1)) // detect the negative edge
					VS_BP_CNTR = VS_BP_CNTR + 1; // this is fine..
				else
					VS_BP_CNTR = VS_BP_CNTR; // keep the value latched

				if (VS_BP_CNTR == VS_BP_CNT + 1) begin // just to compensate the extra HS pulse in the starting of the file data
					NS = HS_SYNC_PULSE_ST;
					VS_BP_CNTR = 0; // reset the counter to be used again if needed.
				end
				else 
					NS = VS_BP_ST; // loop-in

			end
			/*---------------------------*/
			HS_SYNC_PULSE_ST: begin

				if ((HS_prev == 0) && (HS_in == 1)) // detect the rising edge
					NS = HS_BP_ST;
				else 
					NS = HS_SYNC_PULSE_ST;

			end
			/*---------------------------*/
			HS_BP_ST: begin
				
				if(done_HS_BP) begin
					NS = VALID_OUT_ST;		
					row = row + 1;	// to select the correct memeory
				end
				else begin
					NS = HS_BP_ST;
				end				

			end
			/*---------------------------*/
			VALID_OUT_ST: begin 			// this state has actual data coming in... put it inside
				// is_valid = 1'b1;
				if (img_row_end_flag) begin
					NS = FILL_IN_ST;
				end
				else 
					NS = VALID_OUT_ST;
			
			end
			/*---------------------------*/
			FILL_IN_ST: begin
				if (done_fill_in) begin
					if (row == IM_DIM) // when 'row' has rolled over
						NS = TRANSPOSE_OUT_ST;
					else
						NS = HS_FP_ST;
				end
				else
					NS = FILL_IN_ST;				
			end

			/*---------------------------*/
			HS_FP_ST: begin
				 
				if(done_HS_FP) begin
					NS = HS_SYNC_PULSE_ST;
				end
				else begin
					NS = HS_FP_ST;
				end 
			end
			/*---------------------------*/
			TRANSPOSE_OUT_ST: begin
				is_valid = 1'b1;
				row = 0;
				if(done_transpose)
					NS = STOP_ST;
				else
					NS = TRANSPOSE_OUT_ST; // keep looping here for now...
			end
			/*---------------------------*/
			STOP_ST: begin
				NS = STOP_ST; // keep looping here forever
				$display("Reached stop state");
			end
			/*Adding defaut case is good programming practice*/
		endcase
	end

	/*Always block for writing to the memory*/
	always @(posedge clk) begin
		if ((PS == VALID_OUT_ST)) begin
			/*Putting memory write logic here*/
			ena[row - 1] <= 1;
			wea[row - 1] <= 1;
			dia <= R_in;
			addra <= addra + 1;
			// $display("addra: %d; RAM[%d]: %x; dia: %x; wea: %d", ram_row_instance[0].ram.addra, ram_row_instance[0].ram.addra-1, ram_row_instance[0].ram.RAM[addra - 1], ram_row_instance[0].ram.dia, ram_row_instance[0].ram.wea);
		end	
		else begin
			ena[row - 1] <= 0;
			wea[row - 1] <= 0;			
		end
	end

	/*Send out the transpose of the image*/
	integer index =5;
	always @(posedge clk) begin
		if (PS == TRANSPOSE_OUT_ST) begin
			enb[CNTR_X - 1] <= 1;
			addrb <= CNTR_X - 1;
			trans_pixel <= dob[(CNTR_X)*8 +: 8];
			// trans_pixel <= dob[index : 0];
			/*if (index == 511)
				index = 0;
			else 
				index = index + 1;*/
		end
	end

endmodule
