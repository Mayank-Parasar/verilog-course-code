module quiz_13_tb;

	// DUT Inputs
	reg clk = 0;
	reg PB_in = 1;
	reg ROM_RDY = 1;


	// DUT Outputs
	wire [15:0] valid_out;
	wire value_valid;




	always #5 clk <= clk+1;	//generate the clock

	// Instantiate your unit here.

	quiz_13 uut (
				.clk(clk),
				.PB_in(PB_in),
				.ROM_RDY(ROM_RDY),
				.value_valid(value_valid),
				.valid_out(valid_out)

		);





endmodule
