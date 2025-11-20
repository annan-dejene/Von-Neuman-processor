`include "ALU.v"
`include "regfile.v"
`include "memory.v"
`include "pc.v"
`include "control_unit.v"
`include "datapath.v"

module cpu(clock, reset);
    input clock;
    input reset;

    wire [7:0] pc_address; // Connects PC output to internal logic/memory MUX
    wire [15:0] instruction_register; // Connects Memory output to Datapath input  

    // Wires for memory control signals exported from the datapath
    wire mem_write_enable_cpu_w;         // Controls memory write enable
    wire mem_address_select_cpu_w;       // Selects between PC address (0) and ALU address (1)
    wire [15:0] mem_write_data_cpu_w;   // Data going *into* memory (from regfile)
    wire [7:0] alu_address_cpu_w;        // Address for memory data access (from ALU result)
    wire halt_cpu_w;                     // Halt signal from control unit


    // --------------------------------------------------
    // Instantiate Data Path Module
    // --------------------------------------------------
    datapath my_datapath(
        .clock(clock),
        .reset(reset),
        .instruction_address(pc_address),
        .instruction_register(instruction_register),
        
        // Connect the memory control signals from datapath outputs to local wires
        .mem_write_enable_out(mem_write_enable_cpu_w),
        .mem_address_select_out(mem_address_select_cpu_w),
        .mem_write_data_out(mem_write_data_cpu_w),
        .alu_address_out(alu_address_cpu_w),
        .halt_cpu_out(halt_cpu_w)
    );

    // --------------------------------------------------
    // Memory Address MUX (Handles the von Neumann architecture)
    // --------------------------------------------------
    // This MUX selects whether the memory sees the PC address (for fetching the next instruction)
    // or the ALU-calculated address (for LD/ST data access).
    wire [7:0] memory_access_address;
    assign memory_access_address = (mem_address_select_cpu_w == 0) ? pc_address : alu_address_cpu_w;


    // --------------------------------------------------
    // Instantiate Memory Module (The single shared memory resource)
    // --------------------------------------------------
    memory my_system_memory(
        .clock(clock),
        .enable(1'b1), // Memory is always enabled during operation
        .writeEnable(mem_write_enable_cpu_w),
        .address(memory_access_address), // Connect to the MUX output
        .writeData(mem_write_data_cpu_w),
        .readData(instruction_register)  // Memory output drives the Instruction Register input of the datapath
    );


    // --------------------------------------------------
    // Halt Logic
    // --------------------------------------------------
    // Logic to stop the simulation when HLT instruction is executed
    always @(posedge clock) begin
        if (halt_cpu_w) begin
            $display("HLT instruction executed. CPU Halted at time %0t.", $time);
            $finish; // Terminate the simulation
        end
    end
endmodule
