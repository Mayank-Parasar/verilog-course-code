module v_ram (clka, clkb, ena, enb, wea, addra, addrb, dia, doa, dob);
    input  clka, clkb;
    input  wea;
    input  ena, enb;
    input  [1:0] addra, addrb; 
    input  [15:0] dia; // 16 bit data
    output [15:0] doa, dob; // 16 bit data
    reg    [15:0] RAM [3:0]; // 16 bits wide-4 element ram
    reg    [15:0] doa, dob;
    always @(posedge clka)
    begin
        if (ena)
        begin
            if (wea) 
            begin

              RAM[addra]<=dia;
            end
            doa <= RAM[addra];
        end        
    end
    always @(posedge clkb)
    begin
        if (enb)
        begin
            dob <= RAM[addrb];
        end
    end
endmodule