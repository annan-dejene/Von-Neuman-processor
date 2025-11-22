// Control Unit for 16-bit RISC
module control_unit(opcode, alu_zero_flag_in, reg_write_enable_out, mem_write_enable_out, alu_opcode_out, alu_src_select_out, mem_to_reg_select_out, jump_enable_out, branch_enable_out, mem_address_select_out, halt_cpu_out);
    input [3:0] opcode;
    input alu_zero_flag_in; 

    output reg reg_write_enable_out;
    output reg mem_write_enable_out;
    output reg [3:0] alu_opcode_out;
    output reg alu_src_select_out;  
    output reg mem_to_reg_select_out; 
    output reg jump_enable_out; 
    output reg branch_enable_out;        
    output reg mem_address_select_out;   
    output reg halt_cpu_out; 

    // Parameters
    parameter OP_NOP  = 4'b0000;
    parameter OP_ADD  = 4'b0001;
    parameter OP_SUB  = 4'b0010;
    parameter OP_AND  = 4'b0011;
    parameter OP_OR   = 4'b0100;
    parameter OP_XOR  = 4'b0101;
    parameter OP_NOT  = 4'b0110;
    parameter OP_MOV  = 4'b0111; 
    parameter OP_LD   = 4'b1000;
    parameter OP_ST   = 4'b1001;
    parameter OP_BEQZ = 4'b1010;
    parameter OP_JMP  = 4'b1011;
    parameter OP_HLT  = 4'b1110;

    parameter ALU_ADD = 4'b0001;
    parameter ALU_SUB = 4'b0010;
    parameter ALU_AND = 4'b0011;
    parameter ALU_OR  = 4'b0100;
    parameter ALU_XOR = 4'b0101;
    parameter ALU_NOT = 4'b0110;
    parameter ALU_BYP = 4'b1111; 

    always @* begin
        // Defaults
        reg_write_enable_out = 0;
        mem_write_enable_out = 0;
        alu_opcode_out = ALU_BYP;      
        alu_src_select_out = 0;        
        mem_to_reg_select_out = 0;     
        jump_enable_out = 0;
        branch_enable_out = 0;        
        mem_address_select_out = 0;   
        halt_cpu_out = 0;

        case (opcode)
            OP_NOP: begin end

            // ALU Operations
            OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_NOT: begin
                reg_write_enable_out = 1;      
                alu_src_select_out = 0; // Select Reg source (data 2)      
                if (opcode == OP_ADD) alu_opcode_out = ALU_ADD;
                else if (opcode == OP_SUB) alu_opcode_out = ALU_SUB;
                else if (opcode == OP_AND) alu_opcode_out = ALU_AND;
                else if (opcode == OP_OR) alu_opcode_out = ALU_OR;
                else if (opcode == OP_XOR) alu_opcode_out = ALU_XOR;
                else if (opcode == OP_NOT) alu_opcode_out = ALU_NOT;
            end

            OP_MOV: begin
                reg_write_enable_out = 1;      
                alu_src_select_out = 1; // Select Immediate
                alu_opcode_out = ALU_ADD; // Add Imm to 0
            end

            // LDR: Load Register (Register Addressing)
            // Logic: Address = Rs + Rt. 
            // To do "LDR R2, [R3]", the assembler must set Rs=R3 and Rt=R0 (0).
            OP_LD: begin
                reg_write_enable_out = 1;       
                mem_to_reg_select_out = 1; // Read from Mem     
                alu_src_select_out = 0;    // Force Reg+Reg addressing (Rs + Rt)     -------------- pass the Rs as it is
                alu_opcode_out = ALU_BYP;  // Add them to get address
                mem_address_select_out = 1; // Use ALU result as address
            end

            // STR: Store Register (Register Addressing)
            // Logic: Address = Rs + Rt.
            OP_ST: begin
                mem_write_enable_out = 1;       
                alu_src_select_out = 0;    // Force Reg+Reg addressing
                alu_opcode_out = ALU_BYP;         // -------------- pass the Rs as it is
                mem_address_select_out = 1;     
            end
            
            OP_BEQZ: begin
                branch_enable_out = 1;         
                alu_src_select_out = 1; // Needed for PC offset calculation       
                alu_opcode_out = ALU_ADD;      
            end

            OP_JMP: begin
                jump_enable_out = 1;           
            end

            OP_HLT: begin
                halt_cpu_out = 1;
            end
        endcase
    end
endmodule