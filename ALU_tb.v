`include "ALU.v"
module ALU_tb;
    reg [15:0] num1, num2;
    reg [3:0] opcode;
    wire [15:0] result;

    ALU myALU(.num1(num1), .num2(num2), .opcode(opcode), .result(result));

    initial begin
        $dumpfile("simulations/alu_wavedata.vcd");
		$dumpvars(0, ALU_tb);

        #10
        num1 = 16'h9; // 1001
        num2 = 16'h3; // 0011
        opcode = 4'b0001; // add

        #20
        opcode = 4'b0010; // sub

        #10
        opcode = 4'b0011; // AND

        #10
        opcode = 4'b0100; // OR

        #10
        opcode = 4'b0101; // xor

        #10
        $finish;
    
    end


endmodule