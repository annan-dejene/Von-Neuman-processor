`include "ALU.v"
`include "regfile.v"
`include "memory.v"
`include "pc.v"
`include "datapath.v"

// Control Unit for 16-bit RISC (multi-cycle, von Neumann, single-port memory)
module control_unit(opcode, alu_zero_flag_in, reg_write_enable_out, mem_write_enable_out, alu_opcode_out, alu_src_select_out, mem_to_reg_select_out, jump_enable_out, branch_enable_out, mem_address_select_out, halt_cpu_out);
    input [3:0] opcode;
    input alu_zero_flag_in; // For branching logic in Control Unit

    // These outputs will be driving the datapath control wires
    output reg reg_write_enable_out;
    output reg mem_write_enable_out;
    output reg [3:0] alu_opcode_out;
    output reg alu_src_select_out;  // 0: Use RegFile data2, 1: Use Immediate value
    output reg mem_to_reg_select_out; // 0: Write ALU result to RegFile, 1: Write Memory data to RegFile
    output reg jump_enable_out; // 1: Enable jump logic/MUX selection for PC
    output reg branch_enable_out,        // NEW: 1 to enable branch logic (used with zero flag)
    output reg mem_address_select_out,   // NEW: 0=PC address (fetch), 1=ALU address (LD/ST)
    output reg halt_cpu_out; 


    // --------------------------------------------------
    // Local Parameters for our ISA Opcodes (from documentation)
    // --------------------------------------------------
    parameter OP_NOP  = 4'b0000;
    parameter OP_ADD  = 4'b0001;
    parameter OP_SUB  = 4'b0010;
    parameter OP_AND  = 4'b0011;
    parameter OP_OR   = 4'b0100;
    parameter OP_XOR  = 4'b0101;
    parameter OP_NOT  = 4'b0110;
    parameter OP_MOV  = 4'b0111; // Formerly LDI
    parameter OP_LD   = 4'b1000;
    parameter OP_ST   = 4'b1001;
    parameter OP_BEQZ = 4'b1010;
    parameter OP_JMP  = 4'b1011;
    parameter OP_HLT  = 4'b1110;


    // --------------------------------------------------
    // Local Parameters for the ALU Opcodes (from ALU.v module)
    // --------------------------------------------------
    parameter ALU_ADD = 4'b0001;
    parameter ALU_SUB = 4'b0010;
    parameter ALU_AND = 4'b0011;
    parameter ALU_OR  = 4'b0100;
    parameter ALU_XOR = 4'b0101;
    parameter ALU_NOT = 4'b0110;
    parameter ALU_BYP = 4'b1111; // Default/Bypass num1

    // --------------------------------------------------
    // Main Control Logic (Combinational)
    // --------------------------------------------------
    always @* begin
        // Default values for all control signals (Idle state / NOP behavior)
        reg_write_enable_out = 0;
        mem_write_enable_out = 0;
        alu_opcode_out = ALU_BYP;      // Default to bypass num1
        alu_src_select_out = 0;        // Default to use RegFile data2
        mem_to_reg_select_out = 0;     // Default to write ALU result to RegFile
        jump_enable_out = 0;
        branch_enable_out = 0;        // Default to no branching
        mem_address_select_out = 0;   // Default to PC address for instruction fetch
        halt_cpu_out = 0;

        // Decode the instruction and set necessary signals
        case (opcode)
            OP_NOP: begin
                // All signals remain at default (do nothing)
            end

            // ALU Operations selected
            OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR, OP_NOT: begin
                // R-Type Instructions:
                reg_write_enable_out = 1;      // Write result back to register file
                alu_src_select_out = 0;        // Use RegFile data2 for ALU num2 input

                // Set specific ALU opcode
                if (opcode == OP_ADD) alu_opcode_out = ALU_ADD;
                else if (opcode == OP_SUB) alu_opcode_out = ALU_SUB;
                else if (opcode == OP_AND) alu_opcode_out = ALU_AND;
                else if (opcode == OP_OR) alu_opcode_out = ALU_OR;
                else if (opcode == OP_XOR) alu_opcode_out = ALU_XOR;
                else if (opcode == OP_NOT) alu_opcode_out = ALU_NOT;
                // mem_to_reg_select_out is 0 by default (write ALU result back to regfile)
            end

            OP_MOV: begin
                // I-Type Move Immediate: rd <- imm9
                reg_write_enable_out = 1;      // Write result back to register file
                alu_src_select_out = 1;        // Use Immediate value for ALU num2 input
                alu_opcode_out = ALU_ADD;      // Add imm9 to R0 (which is 0) to get imm9 as result
                // mem_to_reg_select_out is 0 by default (write ALU result back to regfile)
            end

            OP_LD: begin
                // R-Type Load: rd <- Mem[rs] (address is rs + rt, rt is 0)
                reg_write_enable_out = 1;       
                mem_to_reg_select_out = 1;      
                alu_src_select_out = 0;         // Use RegFile data2 (rt=0)
                alu_opcode_out = ALU_ADD;       // Calculate effective address
                mem_address_select_out = 1;     // **CRITICAL: Use ALU address for memory access**
            end

            OP_ST: begin
                 // R-Type Store: Mem[rs] <- data
                mem_write_enable_out = 1;       
                alu_src_select_out = 0;         // Use RegFile data2 (rt=0)
                alu_opcode_out = ALU_ADD;       // Calculate effective address
                mem_address_select_out = 1;     // **CRITICAL: Use ALU address for memory access**
            end
            
            OP_BEQZ: begin
                // I-Type Branch If Zero: if (rs == 0) PC <- PC + offset
                // This logic is complex and usually handled in the PC logic itself, but the CU needs to know if the condition is met.
                // We'll manage branching PC changes in the DataPath/Top level using alu_zero_flag_in.
                // Control signals stay default, but we'll use alu_zero_flag_in externally.
                branch_enable_out = 1;         // **CRITICAL: Enable branch logic in Datapath**
                alu_src_select_out = 1;        // Need the immediate value for branch target calculation
                alu_opcode_out = ALU_ADD;      // We don't need ALU op for condition, just PC calc
                // Data path logic handles the condition check using alu_zero_flag_in
            end

            OP_JMP: begin
                // I-Type Jump: PC <- imm9
                jump_enable_out = 1;           // Assert jump enable signal
                // All other signals remain default (NOP behavior for other components)
            end

            OP_HLT: begin
                // Halt the processor
                halt_cpu_out = 1;
            end

            default: begin
                // Handle unsupported opcodes (e.g., error in simulation)
                $display("Error: Unsupported opcode %b encountered at time %0t", opcode, $time);
            end
        endcase
    end
endmodule
