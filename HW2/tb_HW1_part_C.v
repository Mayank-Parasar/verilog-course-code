//-----------------------------------------------------
// Engineer: Mudassar, Burhan
// Overview
//  A testbench to test 16QAM demodulator
//	16QAM data into Symbols.
// Design Name:   tb_HW1_part_D
// File Name:     tb_HW1_part_D.v
//
// Stimuli: 
//		inphase: the I input signal from the IQ demodulator
//		quad: the Q input signal from the IQ demodulator
// Monitor: 
//		symbol: The decoded output symbol
//
// History:       19 Jan. 2017, B. Mudassar, File Created
//
//-----------------------------------------------------

module tb_HW1_part_C;

	//Modules Parameters
	parameter input_bitwidth = 3;
	parameter symbol_bitwidth = 4;

	//stimuli
	reg [input_bitwidth-1:0] inphase;
	reg [input_bitwidth-1:0] quad;
	
	//probe
	wire [symbol_bitwidth-1:0] symbol;
	reg  [symbol_bitwidth-1:0] symbol_known;
	
	//testbench signals
	reg clk;
	
	//Output results to file
	integer result_file;
	
	//unit under test
	HW1_part_C uut(
					.inphase(inphase), 
					.quad(quad), 
					.symbol(symbol)
					);
	
	//configuration of stimuli
	always #5 clk <= ~clk;
	
	always @(posedge clk)		inphase <= inphase + 1;
	always @(posedge clk)		if(&inphase == 1)	quad <= quad + 1;	
	
	initial
		begin
			inphase = 3'd0;
			quad = 3'd0;
			clk = 0;
			
			result_file = $fopen("result_file.dat","w");
			if(result_file == 0)
			begin
				$display("Error! Could not create result file");
				$finish;
			end
		end
					
	//known good behavioral model
	always @*
	begin
		case({inphase[2:0],quad[2:0]})
			{	-3'd3,	-3'd3	}:	symbol_known = 4'b0000;
			{	-3'd3,	-3'd1	}:	symbol_known = 4'b0001;
			{	-3'd3,	3'd1	}:	symbol_known = 4'b0011;
			{	-3'd3,	3'd3	}:	symbol_known = 4'b0010;
			{	-3'd1,	-3'd3	}:	symbol_known = 4'b0100;
			{	-3'd1,	-3'd1	}:	symbol_known = 4'b0101;
			{	-3'd1,	3'd1	}:	symbol_known = 4'b0111;
			{	-3'd1,	3'd3	}:	symbol_known = 4'b0110;
			{	3'd1,		-3'd3	}:	symbol_known = 4'b1100;
			{	3'd1,		-3'd1	}:	symbol_known = 4'b1101;
			{	3'd1,		3'd1	}:	symbol_known = 4'b1111;
			{	3'd1,		3'd3	}:	symbol_known = 4'b1110;
			{	3'd3,		-3'd3	}:	symbol_known = 4'b1000;
			{	3'd3,		-3'd1	}:	symbol_known = 4'b1001;
			{	3'd3,		3'd1	}:	symbol_known = 4'b1011;
			{	3'd3,		3'd3	}:	symbol_known = 4'b1010;
			default:					symbol_known = symbol;
		endcase
	end
	
	//Simulation Stop
	always @(posedge clk) 
		if(&inphase == 1 && &quad == 1) 
			begin
				$stop;
				$fclose(result_file);
			end

	//check loop and output results to file
	always @(negedge clk)
	begin
		if(symbol_known != symbol)
			begin
				$fwrite(result_file, "0\n");
				$display("Output does not match\n");
			end
		else
			begin
				$fwrite(result_file, "1\n");
			end
	end	
	

	
endmodule