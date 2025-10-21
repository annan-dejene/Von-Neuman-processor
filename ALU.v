module ALU(num1, num2, opcode, result);
    input [15:0] num1; // 16 bit register inputs to ALU
    input [15:0] num2;
    input [3:0] opcode; // 4 bit operation code
    output reg [15:0] result;

    always @(num1 or num2 or opcode)
        case (opcode)
            4'b0001: result = num1 + num2; // ADD
            4'b0010: result = num1 - num2; // SUB
            4'b0011: result = num1 & num2; // AND
            4'b0100: result = num1 | num2;  // OR
            4'b0101: result = num1 ^ num2;  // XOR
            default: result = 0;            // default case incase opcode is not any of the above
        endcase 

endmodule