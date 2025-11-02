module ALU(num1, num2, opcode, result);
    input [15:0] num1; // 16 bit register inputs to ALU
    input [15:0] num2;
    input [3:0] opcode; // 4 bit operation code
    output reg [15:0] result;

    // wire zero, carry, overflow, negative;

    always @(num1 or num2 or opcode)
        case (opcode)
            4'b0001: result = num1 + num2; // ADD
            4'b0010: result = num1 - num2; // SUB
            4'b0011: result = num1 & num2; // AND
            4'b0100: result = num1 | num2;  // OR
            4'b0101: result = num1 ^ num2;  // XOR
            4'b0110: result = ~num1; // NOT first register
            4'b0111: result = 0;            // Clear

            default: result = num1;         // default case incase opcode is not any of the above -- bypass simply give num1
        endcase 

    // assign negative = result[15];
    // assign zero = (result == 0);
    // assign carry = (num1[15] & num2[15])


endmodule