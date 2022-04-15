`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		Carrier Frequency, Inc.
// Engineer: 		Jon Carrier
// 
// Create Date:    20:03:42 05/31/2011 
// Design Name: 
// Module Name:    Serial_GPS 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Revision 0.02 - 2017.02.03 Modifed file for use at Ga Tech for
//					class example. Removed all references to the LCD and moved the 
//					UART outside the module.
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module serial_gps_mine(CLK, RxD_data_in_ready, RxD_data_in, data_out, data_out_valid);
input CLK;
input RxD_data_in_ready;
input [7:0] RxD_data_in;

output reg [7:0] data_out;
output reg data_out_valid;


//===============================================================================================
//-------------------Create the mechanism to grab the serial data and parse it-------------------
//===============================================================================================

reg [7:0] CHAR_CNT=0;
reg [2:0] STATE=0;
reg [23:0] NMEA=0;


// CREATE THE COUNTING MECHANISM FOR PARSING THE SERIAL DATA
always @(posedge CLK) begin
	if(RxD_data_in_ready) begin				
		if(RxD_data_in=="$")begin // '$': Start of frame
			CHAR_CNT<=0;
		end
		else begin
			CHAR_CNT<=CHAR_CNT+1;	
		end
	end	
end

// CREATE THE MECHNISM THAT PARSES THE SERIAL DATA
reg DONE=0;
always @(posedge CLK) begin	
	data_out <= 0;
	data_out_valid <= 1'b0;
	case(STATE)		
		//------------------------------------------------------------------------------------
		0: begin //Search for '$'		
			if(RxD_data_in_ready) begin				
				if(RxD_data_in=="$")begin// '$': Start of frame	
					STATE<=STATE+1;				
				end		
			end
		end
		//------------------------------------------------------------------------------------
		1: begin //Check Tag, if not the proper tag go back to 1, else proceed to 3	
			if(RxD_data_in_ready) begin				
				if(RxD_data_in==",")begin
					if(NMEA=="GGA")begin //GGA, this is the message that contains location and time.
						STATE<=STATE+1;
					end
					else begin	//Wrong message, go back and search for the start of the next message.
						STATE<=STATE-1;
					end
				end
				else begin //Grab the NMEA Message Type		
					NMEA[23:8]<=NMEA[15:0];
					NMEA[7:0]<=RxD_data_in; //Grab the tag info						
				end	
			end				
		end
		//------------------------------------------------------------------------------------
		2: begin //Parse the latitude and longitude		
			if(RxD_data_in_ready) begin
				if(RxD_data_in==10)begin //LF: Line Feed, end of message, go to idle state					
					STATE<=0;
				end
				else begin	//valid data on the RxD_data_in line
					if(CHAR_CNT>=6 && CHAR_CNT<=11)begin
						STATE<=STATE;
						data_out<=RxD_data_in;	//this is the time data.
						data_out_valid <= 1'b1;
					end
					//else if(CHAR_CNT>=29 && CHAR_CNT<=38 || CHAR_CNT==40)begin
					//	STATE<=STATE;
					//	data_out<=RxD_data_in;	//this is the longitude data.
					//	data_out_valid <= 1'b1;
					//end
					else begin //nothing important...just wait						
						STATE<=STATE;
					end
				end			
			end
			else begin	//Wait for the RxD_data_in_ready signal to go high.
				STATE<=STATE;
			end
		end	
		default: begin
			STATE<=0;
		end
	endcase		
end

endmodule