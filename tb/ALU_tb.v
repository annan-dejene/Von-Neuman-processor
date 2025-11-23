`include "ALU.v"
module ALU_tb;
    reg [15:0] num1, num2;
    reg [3:0] opcode;
    wire [15:0] result;
    wire zero;

    ALU myALU(.num1(num1), .num2(num2), .opcode(opcode), .result(result), .zero(zero));

    initial begin
        $dumpfile("sim/waveforms/alu_wavedata.vcd");
		$dumpvars(0, ALU_tb);


        // ------- ADD TEST ---------
        #10 // 9 + 3
        $display("Test Case: ADD 9 + 3");
        num1 = 16'd9; // 1001
        num2 = 16'd3; // 0011
        opcode = 4'b0001; // add

        // test zero flag -> 5 + (-5)
        $display("Test Case: ADD 5 + -5");
        #10
        num1 = 16'd5;
        num2 = 16'hFFFB; // -5 in 2's complement
        opcode = 4'b0001;


        // ------- SUB TEST ---------
        #10 // 11 - 3
        $display("Test Case: SUB 11 - 3");
        num1 = 16'd11;
        num2 = 16'd3;
        opcode = 4'b0010; // sub

        // test zero flag -> 5 - 5
        #10
        $display("Test Case: SUB Zero flag 5 - 5");
        num1 = 16'd5;
        num2 = 16'd5;
        opcode = 4'b0010;


        // ------- AND TEST ---------
        #10
        $display("Test Case: AND 15 & 7"); // 15 (0...1111), 7 (0...0111) -> 7 (0...0111)
        num1 = 16'hF;
        num2 = 16'h7;
        opcode = 4'b0011; // AND

        // ------- OR TEST ---------
        #10
        $display("Test Case: OR 15 | 7"); // 15 (0...1111), 7 (0...0111) -> 15 (0...1111)
        num1 = 16'hF;
        num2 = 16'h7;
        opcode = 4'b0100; // OR

        // ------- XOR TEST ---------
        #10
        $display("Test Case: XOR 15 ^ 7"); // 15 (0...1111), 7 (0...0111) -> 8 (0...1000)
        num1 = 16'hF;
        num2 = 16'h7;
        opcode = 4'b0101; // xor

        // ------- NOT TEST ---------
        #10
        $display("Test Case: NOT 0xF000"); // 0xF000 (1111...) -> 0x0FFF (0000...)
        num1 = 16'hF;
        opcode = 4'b0110; // not

        // ------- Default Case Unused Operator TEST ---------
        $display("Test Case: Default Opcode");
        num1 = 16'hABCD;
        num2 = 16'h1234;
        opcode = 4'b1111; // Unused opcode

        // Finished sim
        #10;
        $finish;
    
    end


endmodule