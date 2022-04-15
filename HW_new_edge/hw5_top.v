/*
Condition for stopping the simulation is
when 'out_pixel_counter == rows*cols'
Therefore, set 'out_pixel_valid' only when
you are sending the transpose image pixel for 
writing it into the file.
*/

module hw5_top (
	clk,
	R,
	G,
	B,
	HS,
	VS,
	out_pixel, // this is what will get written...
	out_pixel_valid
	);

// Inputs
input clk;
input [7:0] R, G, B;
input HS, VS;

// Outputs
output [7:0] out_pixel;
output out_pixel_valid;

// Intermediate signals..
reg [3:0] PS = 0; // Present state (initially at START_ST)
reg [3:0] NS = 0; // Next state (initially at START_ST)

// through the values of these counters, we will keep track of the phase
reg [10:0] counterX = 0; 
reg [9:0] counterY = 0;
reg [7:0] edge_pixel = 0;

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
reg edge_pixel_vld = 0;

// various counters
reg [4:0] VS_BP_CNTR = 0;
reg [6:0] STRT_ACTV_CNTR = 0;
reg [7:0] D0 = 0;
reg [7:0] D1 = 0;
reg [7:0] D2 = 0;
reg [9:0] SUM = 0;
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
parameter STOP_ST = 7;

parameter MAX = 8'b1111_1111;


always @(posedge clk) begin
	HS_prev <= HS;
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
		if (counterX < HS_total_pixels) begin
			counterX <= counterX + 1;
			inc_counterY <= 1'b0;
		end
		else begin
			counterX <= 0; // reset X counter which is counting rows
			if (counterY < VS_total_pixels) begin
				counterY <= counterY + 1;
			end
			else begin
				counterY <= 0;
			end
		end		
	end

end


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
assign out_pixel_valid = edge_pixel_vld;
assign out_pixel = (edge_pixel_vld)?edge_pixel:8'd0;
// assign out_pixel = (pixel_valid)?trans_out:8'd0;
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


always @(posedge clk) begin
	PS <= NS;
end

// Create state machine here...
always @(*) begin
	// default assignment goes here...
	en_strt_actv_cntr = 1'b0;
	en_vga_counters = 1'b0;
	pixel_valid = 1'b0;
	case(PS)
		START_ST: begin
			if (VS == 1'b0)
				NS = VS_SYNC_PULSE_ST; // you have detected the falling edge of VS sync pulse
			else 
				NS = START_ST; // you keep looping at the same state.

		end
		/*---------------------------*/	
		VS_SYNC_PULSE_ST: begin
			if (VS == 1'b1) 
				NS = VS_BP_ST; // you have traversed the VS-sync pulse.. traverse the VS-FP phase next
			else 
				NS = VS_SYNC_PULSE_ST; // still in VS_SYNC_PULSE_ST phase keep looping
		end
		/*---------------------------*/
		VS_BP_ST: begin
			
			if ((HS == 0) && (HS_prev == 1)) // detect the negative edge
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
			// en_vga_counters = 1'b1;
			if ((HS_prev == 0) && (HS == 1)) // detect the rising edge
				// this is the start of the first frame; from where we will enable 'counterX'
				NS = STRT_ACTV_ST; 
			else 
				NS = HS_SYNC_PULSE_ST;
		end
		/*---------------------------*/
		STRT_ACTV_ST: begin
			en_strt_actv_cntr = 1'b1;
			// that's the backporch cycle count in a HS row
			// to compensate for cycle delay in chaging state
			if(STRT_ACTV_CNTR == 86) begin  // NOTE : this just to offset the extra-2 cycles
				en_strt_actv_cntr = 1'b0;
				NS = ACTV_ST;
			end
			else
				NS = STRT_ACTV_ST;
		end
		/*---------------------------*/
		ACTV_ST: begin // In this state you will write image data to the memory...
			en_vga_counters = 1'b1;
			pixel_valid = 1'b1;

			if ((counterY == cols - 1) && (counterX == 514)) begin // done reading the image
				NS = STOP_ST;
			end
			else if ((counterY < (cols - 1)) && (counterX == rows-1)) begin
				NS = NXT_ACTV_ST;
			end
			else begin
				NS = ACTV_ST;
			end
		end
		/*---------------------------*/
		NXT_ACTV_ST: begin
			en_vga_counters = 1'b1;

			if (counterX < 512) 
				pixel_valid = 1'b1;
			else
				pixel_valid = 1'b0;

			if (counterX == HS_total_pixels) begin
				NS = ACTV_ST;
			end
			else begin
				NS = NXT_ACTV_ST;
			end
		end

		/*---------------------------*/
		STOP_ST: begin // this is dead-state
			pixel_valid = 1'b0;
			en_vga_counters = 1'b0;
			NS = STOP_ST;
		end 
	endcase
end

/*this will send out the edge detected pixel*/
always @(posedge clk) begin
	if ((PS == ACTV_ST) || ((counterX > 0) && (counterX < 514))) begin // delayed by 3 clock cycle
		D2 <= R;
		D1 <= D2;
		D0 <= D1; 
		if (counterX > 1) begin
			if(SUM > MAX)
				edge_pixel <= MAX;
			else
				edge_pixel <= D0 + D1 + D2; // NOTE: should be clipped by 8 bits	
		end

	end
	else
		edge_pixel <= 0;
end

always @* begin
	SUM <= D0 + D1 + D2;
	if (((counterX > 2) && (counterX < 515)))	
		edge_pixel_vld = 1'b1;
	else
		edge_pixel_vld = 1'b0;
end

endmodule

