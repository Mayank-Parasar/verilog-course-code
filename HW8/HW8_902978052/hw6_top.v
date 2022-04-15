`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:	   Mayank Parasar, Mudassar, B
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

// Input for RAM DUT
// reg clka, clkb;
reg [511:0]wea = 0;
reg [511:0]ena = 0;
reg [511:0]enb = 0;
reg [8:0] addra = -1; // byte address
reg [8:0] addrb = 0; // byte address
reg [7:0] dia = 0; // input can fanout

// Output for RAM DUT
// NOTE: never initialize wires..
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
							.doa(doa[(i+1)*8 - 1 : i*8]),
							.dob(dob[(i+1)*8 - 1 : i*8])
			);			
	end
endgenerate
// Input for FIFO DUT
reg rd_en_in1 = 0;
reg rd_en_in2 = 0;
reg wr_en_in1 = 0;
reg wr_en_in2 = 0;
reg [7:0] data_in1 = 0;
reg [7:0] data_in2 = 0;

// Output for FIFO DUT
wire [7:0] data_out1;
wire [7:0] data_out2;

// Instantiate 2 FIFOs 512 deep each
simpleFIFO #(
		  	.DATA_WIDTH(8),
		  	.ADDR_WIDTH(9)) fifo1 (
									.clk(clk),
									.reset(),
									.data_in(data_in1),
									.rd_en_in(rd_en_in1),
									.wr_en_in(wr_en_in1),
									.data_out(data_out1),
									.empty_out(),
									.full_out(),
									.overflow_out()
			);

simpleFIFO #(
		  	.DATA_WIDTH(8),
		  	.ADDR_WIDTH(9))  fifo2 (
									.clk(clk),
									.reset(),
									.data_in(data_in2),
									.rd_en_in(rd_en_in2),
									.wr_en_in(wr_en_in2),
									.data_out(data_out2),
									.empty_out(),
									.full_out(),
									.overflow_out()
			);

// shift registers for holding numbers in 3x3 filter window
reg signed [15:0] z1 = 0, z2 = 0, z3 = 0, z4 = 0, z5 = 0, z6 = 0, z7 = 0, z8 = 0, z9 = 0;
// register to store the convolution output
reg signed [15:0] g_x = 0, g_y = 0;
reg [15:0] mag = 0, abs_g_x = 0, abs_g_y = 0;
// Threshold
parameter threshold = 75;
// Intermediate signals..
reg [3:0] PS = 0; // Present state (initially at START_ST)
reg [3:0] NS = 0; // Next state (initially at START_ST)

// through the values of these counters, we will keep track of the phase
reg [10:0] counterX = 0; 
reg [9:0] counterY = 0;
reg [7:0] trans_out = 0;

//Number of rows and cols in the input image
parameter rows = 512;
parameter cols = 512;

//--------------------------------------------------------
//VGA Details
//--------------------------------------------------------
parameter VGA_pixels = 800;
parameter VGA_lines = 600;

parameter HS_front_porch = 40;
parameter HS_sync_pulse = 128 + HS_front_porch;	//this is looking at the total count. So we are making a running sum.
parameter HS_back_porch = 88 + HS_sync_pulse;	//this is looking at the total count. So we are making a running sum.

parameter VS_front_porch = 1;
parameter VS_sync_pulse = 4 + VS_front_porch;	//this is looking at the total count. So we are making a running sum.
parameter VS_back_porch = 23 + VS_sync_pulse;	//this is looking at the total count. So we are making a running sum.

parameter HS_total_pixels = VGA_pixels+HS_back_porch;
parameter VS_total_pixels = VGA_lines+VS_back_porch;

parameter VS_BP_CNT = 23;
// ---------------------------------------------------------
reg en_vga_counters = 0; // don't need it probably
reg HS_prev = 0;
reg inc_counterY;
reg en_strt_actv_cntr = 0;
reg pixel_valid = 0;
reg pixel_valid_reg = 0;
reg pixel_valid_sig = 0;
reg HS_reg = 0; // to shift HS_out by one cycle
reg VS_reg = 0; // to shift VS_out by one cycle
// various counters
reg [4:0] VS_BP_CNTR = 0;
reg [6:0] STRT_ACTV_CNTR = 0;

//--------------------------------------------------------
//State Machine parameter.
//--------------------------------------------------------
parameter START_ST = 0; // this state wait for VS sync pulse
parameter VS_SYNC_PULSE_ST = 1; // detected and currently present at VS_SYNC_PULSE_ST
parameter VS_BP_ST = 2; // currenlty going through VS_FP phase
parameter HS_SYNC_PULSE_ST = 3;
parameter STRT_ACTV_ST = 4; // this state will take you to the start of active row-data
parameter ACTV_ST = 5;
parameter NXT_ACTV_ST = 6; 
parameter WAIT_ST = 7; // wait for 'sel_operation' to become 1 after reading the file
parameter TRANSPOSE_ST = 8;
parameter STOP_ST = 9;


always @(posedge clk) begin
	HS_prev <= HS_in;
end


// just to reach the start of the frame...
always @(posedge clk) begin
	if (en_strt_actv_cntr) 
		STRT_ACTV_CNTR <= STRT_ACTV_CNTR + 1;
	else 
		STRT_ACTV_CNTR <= 0;
end

// this always block maintains HS-counters as they are
// all clock driven
always @(posedge clk) begin
	if(en_vga_counters) begin
		if (counterX < (HS_total_pixels - 1)) begin
			counterX <= counterX + 1;
			inc_counterY <= 1'b0;
		end
		else begin
			counterX <= 0; // reset X counter which is counting rows
			if (counterY < (VS_total_pixels - 1)) begin
				counterY <= counterY + 1;
			end
			else begin
				counterY <= 0;
			end
		end		
	end
	else 
	if( PS == WAIT_ST ) begin
		if ( counterX < 514 )
			counterX <= counterX + 1;
	end
	else
	if ( PS == VS_SYNC_PULSE_ST ) begin
		counterX <= 0;
		counterY <= 0;
	end
end

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
assign pixel_valid_out = pixel_valid;
assign pixel_out = (pixel_valid)?trans_out:8'd0;
assign R_out = (pixel_valid)?trans_out:8'd0;
assign B_out = (pixel_valid)?trans_out:8'd0;
assign G_out = (pixel_valid)?trans_out:8'd0;

assign HS_out = HS_reg;						
assign VS_out = VS_reg;						
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
always @(posedge clk) begin
	PS <= NS;
end

always @(posedge clk) begin
	HS_reg <= HS_in;
	VS_reg <= VS_in;
end

// Create state machine here...
always @(*) begin
	// default assignment goes here...
	en_strt_actv_cntr = 1'b0;
	en_vga_counters = 1'b0;
	pixel_valid = 1'b0;
	enb = 0; // set its default value to 0
	ena = 0; // disable any write to ram module
	wea = 0; // disable any weite to ram
	NS = 0;
	rd_en_in1 = 0; 
	rd_en_in2 = 0; 
	wr_en_in1 = 0; 
	wr_en_in2 = 0; 

	case(PS)
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
				// this is the start of the first frame; from where we will enable 'counterX'
				NS = STRT_ACTV_ST; 
			else 
				NS = HS_SYNC_PULSE_ST;
		end
		/*---------------------------*/
		STRT_ACTV_ST: begin
			en_strt_actv_cntr = 1'b1;
			/*This is done for 1 cycle adjustment.. between trans_out and HS_out/VS_out*/
			if( STRT_ACTV_CNTR >= 85 && (sel_operation == 1'b1) )
				enb = -1;			
			// that's the backporch cycle count in a HS row
			// to compensate for cycle delay in chaging state
			if(STRT_ACTV_CNTR == 86) begin  // NOTE
				en_strt_actv_cntr = 1'b0;
				if( sel_operation == 1'b1 ) begin
					NS = TRANSPOSE_ST;
					// enb = -1;
					// en_vga_counters = 1'b1;
				end
				else begin
					NS = ACTV_ST;
					en_vga_counters = 1'b1;
					wr_en_in1 = 1'b1;
				end
			end
			else
				NS = STRT_ACTV_ST;
		end
		/*---------------------------*/
		ACTV_ST: begin // In this state you will write image data to the memory...
					   // as well perform the edge dedtection by getting data from FIFO
			en_vga_counters = 1'b1;
			
			ena = (1 << counterY); // to enable write to memory in this state
			wea = (1 << counterY);	// to enable write to memory in this state

			// enable read and write pointers of a FIFO based on the counterX and counterY value
			wr_en_in1 = 1;
			if( counterY > 0 ) begin
				rd_en_in1 = 1;
				wr_en_in2 = 1;
			end
			if( counterY > 1 )
				rd_en_in2 = 1;

			if (counterX > 1)  // because 'trans_out' is delayed by one cycle.. everytime..
				pixel_valid = 1'b1;
			else
				pixel_valid = 1'b0;

			// ----------Convolution-Start---------- //
			g_x = (z7 + 2*z8 + z9) - (z1 + 2*z2 + z3);
			g_y = (z3 + 2*z6 + z9) - (z1 + 2*z4 + z7);
			//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
			if( g_x[15] == 1'b1 )
				abs_g_x = -g_x;
			else
				abs_g_x = g_x;

			if( g_y[15] == 1'b1 )
				abs_g_y = -g_y;
			else
				abs_g_y = g_y;
			//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//

			mag = abs_g_x + abs_g_y;
			// ----------Convolution-Ends---------- //

			if ((counterY == cols - 1) && (counterX == rows-1)) begin // done reading the image
				/*Reset both counters*/
				NS = WAIT_ST;
			end
			else if ((counterY < (cols - 1)) && (counterX == rows-1)) begin
				NS = NXT_ACTV_ST;
			end
			else begin
				NS = ACTV_ST;
			end
		end
		/*---------------------------*/
		NXT_ACTV_ST: begin // this will transition to either 'ACTV_ST' or 'TRANSPOSE_ST'
			en_vga_counters = 1'b1;
			if (sel_operation == 1'b0) begin // For doing edge detection...
				if( counterX < 514 ) begin
					pixel_valid = 1'b1;
				end 
				else begin
					pixel_valid = 1'b0;
				end
			end
			else begin // FOr doing transpose
				if( counterX < 513 ) begin
					pixel_valid = 1'b1;
				end 
				else begin
					pixel_valid = 1'b0;
				end				
			end
			
			if (counterX == HS_total_pixels - 1) begin
				if( sel_operation == 1'b1 )
					NS = TRANSPOSE_ST;
				else
					NS = ACTV_ST;
			end
			else begin
				NS = NXT_ACTV_ST;
			end
		end
		/*---------------------------*/
		WAIT_ST: begin
			en_vga_counters = 1'b0;

			if( counterX < 514 ) begin
				pixel_valid = 1'b1;
			end
			else begin
				pixel_valid = 1'b0;			
			end
			// In testbed- VS goes low before 
			// sel operation get's high.. and difference
			// is just 1 cycle...
			if( VS_out == 1'b0 )
				NS = VS_SYNC_PULSE_ST;
			else
				NS = WAIT_ST;
		end
		/*---------------------------*/
		TRANSPOSE_ST: begin  // this state should be similar in spirit to 'ACTV_ST'
			en_vga_counters = 1'b1; // keep counters enabled? No.
			ena = 0; // disable any write to ram module
			wea = 0; // disable any weite to ram
			enb = -1; // enable all RAM module for reading in this state

			if (counterX > 0)  // because 'trans_out' is delayed by one cycle.. everytime..
				pixel_valid = 1'b1;
			else
				pixel_valid = 1'b0;

			if ((counterY == (cols - 1)) && (counterX == rows)) begin
				NS = STOP_ST;
				enb = 0;
			end
			else if ((counterY < (cols - 1)) && (counterX == rows-1)) begin
				NS = NXT_ACTV_ST;
			end else
				NS = TRANSPOSE_ST;

		end
		/*---------------------------*/
		STOP_ST: begin // this is dead-state

			pixel_valid = 1'b0;
			en_vga_counters = 1'b0;
			NS = STOP_ST;
			ena = 0;
			wea = 0;
			enb = 0;
			
		end 
	endcase
end

/*Always block for writing to the memory*/
always @(posedge clk) begin
	if ((PS == ACTV_ST)) begin
		/*Putting memory write logic here*/
		dia <= R_in;
		addra <= addra + 1;
	end 
	else begin
		addra <= -1;
	end
end

// Transpose-2 (expected):
always @(posedge clk) begin
	if (wr_en_in1 == 1) begin
			if( mag > threshold )
				trans_out = 8'hFF;
			else
				trans_out = 8'h00; 		
	end
	else if (NS == TRANSPOSE_ST && (sel_operation == 1'b1)) begin
		addrb <= (511 - counterY);
		trans_out <= dob[(511 - counterX)*8 +: 8];
	end
	else
		trans_out <= 8'b0000_0000;
end

// Always block for writing to the FIFO
always @(posedge clk) begin
	if (wr_en_in1 == 1) begin
		data_in1 <= R_in;
	end
	if (wr_en_in2 == 1) begin
		data_in2 <= data_out1; // because a wire can always drive a 'reg' in always block...
	end
end

// Always block for shift register logic...
always @(posedge clk) begin
	z9 <= R_in;
	z8 <= z9;
	z7 <= z8;
	if (rd_en_in1 == 1) begin
		z6 <= data_out1;
		z5 <= z6;
		z4 <= z5;
	end

	if (rd_en_in2 == 1) begin
		z3 <= data_out2;
		z2 <= z3;
		z1 <= z2;
	end
end
endmodule