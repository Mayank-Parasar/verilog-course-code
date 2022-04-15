module quiz_13(
				clk,
				PB_in,
				data_in,
				ROM_RDY,
				valid_out,
				value_valid
	);

input clk;
input PB_in;
input [15:0]data_in;
input ROM_RDY;

output [15:0] valid_out;
output value_valid;



reg[1:0] PS, NS;
reg[4:0] counter_reg, counter_sig;



reg wea = 0;
reg ena = 0;
reg enb = 0;
reg [1:0] addra = 0;
reg [1:0] addrb = 0;
reg [15:0] dia = 0;

wire [15:0] doa = 0;
wire [15:0] dob = 0;

/*instantiate memory here..*/
// make connections...

v_ram ram (
			.clka(clk),
			.clkb(clk),
			.wea(wea),
			.ena(ena),
			.enb(enb),
			.addra(addra),
			.addrb(addrb),
			.dia(dia),
			.doa(doa),
			.dob(dob)
	);

parameter INIT_ST = 0;
parameter START_ST = 1;
parameter ST_1 = 2;
parameter ST_2 = 3;
parameter ST_3 = 4;


always @(posedge clk) begin
	PS <= NS;
	counter_reg <= counter_sig;
	addra <= counter_sig;
	addrb <= counter_reg;
end



always @(*) begin
	// default assignment goes here..
	counter_sig = 0;
	NS = 0;

	case (PS)

		INIT_ST: begin
			counter_sig = counter_sig + 1;
			if (counter_reg <= 4) 
				NS = INIT_ST;
			else
				NS = START_ST;
		end
		START_ST: begin
			counter_sig = 0;

			NS = START_ST;
		end
	endcase
end


/*Always block for writing to the memory*/
always @(posedge clk) begin
	if (PS == INIT_ST) begin
		ena <= 1;
		wea <= 1;
		dia <= data_in;
		addra <= addra + 1;
	end
	else begin
		ena <= 0;
		wea <= 0;
	end
end

/*Always block for reading from the memory*/




endmodule

