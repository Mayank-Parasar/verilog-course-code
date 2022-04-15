module v_ram_01_1 (clka, clkb, ena, enb, wea, addra, addrb, dia, doa, dob);
    input  clka, clkb;
    input  wea;
    input  ena, enb;
    input  [8:0] addra, addrb; // There are 512 pixel in each row; this is a RAM module per row
    input  [7:0] dia; // 8 bit data
    output [7:0] doa, dob; // 8 bit data
    reg    [7:0] RAM [511:0]; // 8 bits wide-512 element ram
    reg    [7:0] doa, dob;
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