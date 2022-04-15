`timescale 1ns/1ns

/*
************************************************************
*	Engineer: 	Mudassar, B
*	Module:		hw6 testbench
*	Functionality:
*					Reads a bitmap file using fgetc
*					Copies the headers and writes them to a new file
*					Generates VGA signals and pushes pixels from bitmap file to the dut
*	Version History:
*		0.1		File Created		02/28/2017
*		0.2		2017.03.03 T. Brothers
*					Added a state machine to the design for the file read/write.
*		0.3		2017.03.06	T. Brothers
*					Modifed some signal names to make the signals more clear.
*		0.4		2017.03.06	T. Brothers
*					Modifed to read the input file two times.
************************************************************
*/

module hw6_tb;

//===========================================================
// PARAMETERS
//===========================================================
	parameter counter_wid = 32;
	
	//--------------------------------------------------------
	//Image Details
	//--------------------------------------------------------
	parameter bit_depth = 8;
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
	parameter VS_back_porch = 23 + VS_sync_pulse;		//this is looking at the total count. So we are making a running sum.
	
	parameter HS_total_pixels = VGA_pixels+HS_back_porch;
	parameter VS_total_pixels = VGA_lines+VS_back_porch;
	
//===========================================================
// SIGNALS
//===========================================================	
	//DUT Inputs
	reg clk = 0;
	reg [counter_wid-1:0]	rd_counter = 0;	//read counter
	reg clr_rd_counter;
	reg inc_rd_counter;
	reg [bit_depth-1:0]		in_byte;		//read byte
	reg sel_opertion;	//0 indicates edge, 1 indicates transpose
	
	//DUT Outputs
	wire [bit_depth-1:0]		out_pixel;				//pixel generated from your code
	wire						out_pixel_valid;		//pixel valid generated from your code
	wire [7:0] R_out;
	wire [7:0] G_out;
	wire [7:0] B_out;
	wire HS_out;
	wire VS_out;
	
	//Misc.
	//Variables for reading and writing
	integer 	im_file_read_sig;
	integer 	im_file_read_reg;
	reg			im_file_read_valid;
	integer 	im_file_write1_sig;
	integer 	im_file_write1_reg;
	integer 	im_file_write2_sig;
	integer 	im_file_write2_reg;
	integer 	status;
	reg [counter_wid-1:0]	out_pixel_counter = 0;	
	reg 		file_read_done;
	
	reg [counter_wid-1:0] pixel_data_offset_reg = 0;				//variable for storing offset of pixel array
	reg [counter_wid-1:0] pixel_data_offset_sig;					//variable for storing offset of pixel array
	reg header_valid_sig;											//1 when input bytes belong to the header
	
//===========================================================
// Code Body
//===========================================================
	//--------------------------------------------------------
	//Pixel to VGA Signal Conversion
	//http://martin.hinner.info/vga/vga.html
	//https://en.wikipedia.org/wiki/Video_Graphics_Array
	//--------------------------------------------------------
	
	//VGA Signals
	wire VS;					//Vertical Sync
	wire HS;					//Horizontal Sync
	wire [7:0] R, G, B;		//8 bit RGB channels, normally it is an analog output but for the sake of this testbed it is a 8-bit digital signal
	
		
	//Horizontal Sync (HS) and Vertical Sync (VS) timing is managed by the code below
	//Values for each phase of HS and VS are specified in terms of clock cycles. 
	//http://tinyvga.com/vga-timing/800x600@60Hz
	
	reg [10:0] counterX = 0;
	reg [9:0] counterY = 0;
	reg en_vga_counters;

	//--------------------------------------------------------
	//Counters to keep track of screen location
	//--------------------------------------------------------
	//Timings for 800*600 VGA resolution (W*H)
	always @(posedge clk)
		if(en_vga_counters)
			if(counterX < (HS_total_pixels-1))
				counterX <= counterX + 1;			//Whole row is 1056 pixels wide
			else begin					
				counterX <= 0;
				if(counterY < (VS_total_pixels-1))
					counterY <= counterY + 1;		//Whole column is 628 pixels high
				else
					counterY <= 0;
				end
		
			
				
	//--------------------------------------------------------
	//Horizontal and Vertical Sync Signals
	//--------------------------------------------------------
	wire HS_FP = (counterX < HS_front_porch);		//Front Porch
	wire HS_SY = (counterX >= HS_front_porch) && (counterX < HS_sync_pulse);	//Sync Pulse (128)
	wire HS_BP = (counterX >= HS_sync_pulse) && (counterX < HS_back_porch);	//Back Porch (88)
	wire HS_DI = (counterX >= HS_back_porch);		//Display Region
	wire pixel_valid = HS_DI && (counterX < HS_back_porch + cols);	//Image is only 512 columns wide
	
	wire VS_FP = (counterY < VS_front_porch);		//Front Porch
	wire VS_SY = (counterY >= VS_front_porch) && (counterY < VS_sync_pulse);	//Sync Pulse (4)
	wire VS_BP = (counterY >= VS_sync_pulse) && (counterY < VS_back_porch);	//Back Porch (23)
	wire VS_DI = (counterY >= VS_back_porch);		//Display Region
	wire line_valid = VS_DI && (counterY < VS_back_porch + rows);							//Image is only 512 rows wide
	
	wire image_pixel_valid = line_valid && pixel_valid;									
	
	assign HS = ~HS_SY;				//active low
	assign VS = ~VS_SY;				//active low
	
	assign R = (image_pixel_valid)?in_byte:8'd0;		//We are working with grayscale images so assigning the same value to all channels
	assign G = (image_pixel_valid)?in_byte:8'd0;
	assign B = (image_pixel_valid)?in_byte:8'd0;
	
	//--------------------------------------------------------
	//Unit Under Test
	//--------------------------------------------------------
	
	////Instantiate your unit here////
	
	hw6_top uut 	(
						.clk(clk),
						.sel_operation(sel_opertion),	//0 indicates edge, 1 indicates transpose
						.R_in(R),
						.G_in(G),
						.B_in(B),
						.HS_in(HS),
						.VS_in(VS),
						.pixel_out(out_pixel),
						.pixel_valid_out(out_pixel_valid),
						.R_out(R_out),
						.G_out(G_out),
						.B_out(B_out),
						.HS_out(HS_out),
						.VS_out(VS_out)
					);

	
	//////////////////////////////////
	
	//--------------------------------------------------------
	//Testbed Signals
	//--------------------------------------------------------
	always #1 clk <= clk+1;	//generate the clock
	
	//--------------------------------------------------------
	//Counter for the state machine
	//--------------------------------------------------------
		//Counters to keep track of bytes read
		always @(posedge clk)
			if(clr_rd_counter) 		rd_counter <= 0;
			else if(inc_rd_counter) rd_counter <= rd_counter + 1;
			else 					rd_counter <= rd_counter;
			
	//--------------------------------------------------------
	//State Machine for the controller.
	//--------------------------------------------------------
	parameter IDLE_ST 			= 0;
	parameter OPEN_FILE_ST 		= 1;
	parameter READ_HEADER_ST 	= 2;
	parameter SEND_DATA_EDGE_ST = 3;
	parameter WAIT_ST 			= 4;
	parameter SEND_DATA_TRANSPOSE_ST = 5;
	parameter STOP_ST 			= 6;
	
	
	reg [2:0] PS=0, NS;
	
	always @ (posedge clk)
		PS <= NS;
		
	always @ (*) begin
		//default assignments
		sel_opertion = 0;	//0 indicates edge, 1 indicates transpose
		header_valid_sig = 0;
		en_vga_counters = 1'b0;
		clr_rd_counter = 1'b0;
		inc_rd_counter = 1'b0;
		pixel_data_offset_sig = pixel_data_offset_reg;
		im_file_read_sig = im_file_read_reg;
		im_file_write1_sig = im_file_write1_reg;
		im_file_write2_sig = im_file_write2_reg;
		
		//state machine case statement
		case (PS)
			IDLE_ST: begin
				clr_rd_counter = 1'b1;
				NS = OPEN_FILE_ST;
				end
			OPEN_FILE_ST: begin
				//open the read file
				im_file_read_sig = $fopen("lena512.bmp","rb");

				//open the write file
				im_file_write1_sig = $fopen("lena512_out_edge.bmp","wb");
				im_file_write2_sig = $fopen("lena512_out_trans.bmp","wb");
				
				//check to see if they were opened
				if((im_file_read_sig==0) || (im_file_write1_sig==0) || (im_file_write2_sig==0)) begin
					$display("Error! Unable to open the read and/or write file.");
					NS = STOP_ST;
					end
				else
					NS = READ_HEADER_ST;
				
				end
			READ_HEADER_ST: begin
				header_valid_sig = 1'b1;
				/* Header Counter and offset calculator */
				// Reads offset of pixel array in bitmap by reading locations 10 through 13
				// Stores that value and asserts a signal header_valid until pixel array data is reached
				if(im_file_read_valid) begin
					inc_rd_counter = 1'b1;
					case(rd_counter)
						8'hA:		pixel_data_offset_sig[7:0] 		= in_byte;
						8'hB:		pixel_data_offset_sig[15:8] 	= in_byte;
						8'hC:		pixel_data_offset_sig[23:16] 	= in_byte;
						8'hD:		pixel_data_offset_sig[31:24] 	= in_byte;
					endcase		
					
					//write the data to file
					$fwrite(im_file_write1_reg,"%c",in_byte);
					$fwrite(im_file_write2_reg,"%c",in_byte);
					end
				//next state logic.
				if ((rd_counter < pixel_data_offset_reg-1) || (rd_counter < 8'hE))	//check if we are at the start of the data and that the counter is greater than the header location that stores the data location.
					NS = READ_HEADER_ST;
				else
					NS = SEND_DATA_EDGE_ST;
				
				end
			SEND_DATA_EDGE_ST: begin
				en_vga_counters = 1'b1;
				if (file_read_done)
					NS = WAIT_ST;
				else
					NS = SEND_DATA_EDGE_ST;
					
				end
			WAIT_ST: begin
				en_vga_counters = 1'b1;
				clr_rd_counter = 1'b1;
				if (VS == 0)	//at the end of the frame, switch operaitons.
					NS = SEND_DATA_TRANSPOSE_ST;
				else
					NS = WAIT_ST;
					
				end
			SEND_DATA_TRANSPOSE_ST: begin
				en_vga_counters = 1'b1;
				sel_opertion = 1'b1;	//0 indicates edge, 1 indicates transpose
				if (file_read_done)
					NS = STOP_ST;
				else
					NS = SEND_DATA_TRANSPOSE_ST;
					
				end
			STOP_ST: begin
				NS = STOP_ST;
				sel_opertion = 1'b1;	//0 indicates edge, 1 indicates transpose
				en_vga_counters = 1'b1;	//keep the counters running to clear out the pipelines of data.
				$display("End of state machine");
				end
			endcase
		end
		
	//register block for state machine variables
	always @ (posedge clk) begin
		pixel_data_offset_reg <= pixel_data_offset_sig;
		im_file_read_reg <= im_file_read_sig;
		im_file_write1_reg <= im_file_write1_sig;
		im_file_write2_reg <= im_file_write2_sig;
		end
		
		
	//--------------------------------------------------------
	//Read from the input file
	//--------------------------------------------------------
	initial	begin
		//a flag to indiate the file read is complete
		file_read_done = 1'b0;
		
		//default conditions
		in_byte <= 0;
		im_file_read_valid <= 0;
		
		#30 //wait for the file to be opened
		
		//Read in the image file one byte at a time		
		while(!$feof(im_file_read_reg))	//NOTE: This is not synthesizable. This can only be done in a testbed!
		begin
			@(posedge clk)		
			if(header_valid_sig || image_pixel_valid) begin	//read file
				in_byte <= $fgetc(im_file_read_reg);
				im_file_read_valid <= 1;
				end
			else begin
				//in_byte <= 0;
				im_file_read_valid <= 0;
				end
		end
		
		//set the output to zero while we go back to the start of the image file
		im_file_read_valid <= 0;
		in_byte <= 0;
		
		@(posedge clk) begin
			//status = $rewind(im_file_read_reg); // Move to the start of the file
			status = $fseek(im_file_read_reg,pixel_data_offset_reg, 0); // Move to the start of the data in the file
			file_read_done = 1'b1;	//set file read done high for one clock.
			end
		@(posedge clk) begin
			file_read_done = 1'b0;
			end
		
		//Read in the image file one byte at a time...again
		while(!$feof(im_file_read_reg))	//NOTE: This is not synthesizable. This can only be done in a testbed!
		begin
			@(posedge clk)		
			if(header_valid_sig || image_pixel_valid) begin	//read file
				in_byte <= $fgetc(im_file_read_reg);
				im_file_read_valid <= 1;
				end
			else begin
				//in_byte <= 0;
				im_file_read_valid <= 0;
				end
		end
		
		//for the rest of time just output 0 for data and valid.
		im_file_read_valid <= 0;
		in_byte <= 0;
		file_read_done = 1'b1;
		
		//close the file.
		$fclose(im_file_read_reg);
		
		//wait for the end of the test.
		while(out_pixel_counter != rows*cols)				//Stop the testbench once number of pixels has been output from the dut
			@(posedge clk);
		//we are done so we close the files.
		$display("Done writing file. Stopping Test.");
		$fclose(im_file_write1_reg);
		$fclose(im_file_write2_reg);
		$stop;
		
	end
	
	//--------------------------------------------------------
	//Write to the output file
	//--------------------------------------------------------
	//Counter to count pixels coming out of your module
	always @(posedge clk)
		if(!VS_out) out_pixel_counter <= 0;	//VS is active low.
		else if(out_pixel_valid)	out_pixel_counter <= out_pixel_counter + 1;
		else out_pixel_counter <= out_pixel_counter;
	
	//write the pixels to file
	always @(posedge clk)
		if(out_pixel_valid && sel_opertion ==1'b0)								//Write the pixel data from your module
			$fwrite(im_file_write1_reg,"%c",out_pixel);
		else if(out_pixel_valid && sel_opertion ==1'b1)							//Write the pixel data from your module
			$fwrite(im_file_write2_reg,"%c",out_pixel);
		
endmodule
