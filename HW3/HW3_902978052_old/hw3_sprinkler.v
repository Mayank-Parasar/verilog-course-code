`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		Carrier Frequency, Inc.
// Engineer: 		Parasar, Mayank Parasar
// Create Date:		20:03:42 02/08/2017 
// Design Name: 	hw3_sprinkler.v
// Module Name:    	hw3_sprinkler 
// Project Name: 	Sprinkler System
// Target Devices: 	Sprinkler System
//
// Revision 0.01 - File Created
// Revision 0.02 - 2017.02.03 Modifed file for use at Ga Tech for
//					class example. Removed all references to the LCD and moved the 
//					UART outside the module.
// Revision 0.03 - Modified file for testbench to verify sprinkler system
// Additional Comments: This is a module that implements the sprinkler logic based on
// 						the appropriate conditions using state matching. 
// 						The requirements of the system are that the 
// 						system should be turned on when it is dark (using GPS data)
// 						and turned off for when it is not raining. 
//////////////////////////////////////////////////////////////////////////////////

module hw3_sprinkler(clk, rain_sensor_in, gps_data_in, gps_valid_in, zone_active_out);
// Inputs
input wire clk;
input rain_sensor_in; // handle rain logic inside the code
input [7:0] gps_data_in; // this contain the ascii char from text file
input gps_valid_in;
// Output
output reg zone_active_out;

//===============================================================================================
//-------------------Create the mechanism to grab the serial data and parse it-------------------
//===============================================================================================

reg [7:0] CHAR_CNT=0;
reg [2:0] STATE=0;
reg [23:0] NMEA=0;
reg [31:0] TIME=0;
reg flag=0;


// 'always' block for sprinkler output..
always @(*) 
	if(flag) // only get executed when flag is 1
		zone_active_out = ~rain_sensor_in; // we would set flag high apropriately in the state machine...
	else
		zone_active_out = 1'b0; // keep it 0

// CREATE THE COUNTING MECHANISM FOR PARSING THE SERIAL DATA 
always @(posedge clk) begin
	if(gps_valid_in) begin	
		
		TIME[31:8]<=TIME[23:0];
		TIME[7:0]<=gps_data_in; //Grab the tag info			

		if(gps_data_in=="$")begin // '$': Start of frame
			CHAR_CNT<=0;
		end
		else begin
			CHAR_CNT<=CHAR_CNT+1;	 // mparasar: is this valid counting mechanism?
		end
	end	
end

// CREATE THE MECHNISM THAT PARSES THE SERIAL DATA
reg DONE=0;
always @(posedge clk) begin	
	// zone_active_out <= 1'b0;
	case(STATE)		
		//------------------------------------------------------------------------------------
		0: begin //Search for '$'		
			if(gps_valid_in) begin	
				// zone_active_out <= 1'b0;
				if(gps_data_in=="$")begin// '$': Start of frame	
					STATE<=STATE+1;				
				end		
			end
		end
		//------------------------------------------------------------------------------------
		1: begin //Check Tag, if not the proper tag go back to 1, else proceed to 3	
			if(gps_valid_in) begin				
				if(gps_data_in==",")begin
					if(NMEA=="GGA")begin //GGA, this is the message that contains location and time.
						STATE<=STATE+1;
					end
					else begin	//Wrong message, go back and search for the start of the next message.
						STATE<=STATE-1;
					end
				end
				else begin //Grab the NMEA Message Type		
					NMEA[23:8]<=NMEA[15:0];
					NMEA[7:0]<=gps_data_in; //Grab the tag info						
				end	
			end				
		end
		//------------------------------------------------------------------------------------
		2: begin 		
			if(gps_valid_in) begin
				if(gps_data_in==10)begin //LF: Line Feed, end of message, go to idle state					
					STATE<=0;
				end else begin	// k//valid data on the RxD_data_in line
						if( CHAR_CNT == 10 )begin
							// $display("Inside hw3_sprinkler.v TIME: (string): %s", TIME);

							STATE<=STATE;

							if (TIME[31:16] == "00" && ((TIME[15:8] == "1") || (TIME[15:8] == "0"))) begin
								flag <= 1'b1;
							end else begin 
								flag <= 1'b0;
								end

						end else begin // to keep it latched till we encounter
								
								STATE<=STATE;
							end
					end	

				end else begin	//Wait for the RxD_data_in_ready signal to go high.
					STATE<=STATE;
					end
			end // end of the case 2

		default: begin
			STATE<=0;
		end
	endcase		
end
	
endmodule

