// `include "memory.v"
// `include "datapath.v"

module cpu(clock, reset);
    input clock;
    input reset;

    wire [7:0] pc_address; 
    wire [15:0] memory_out_wire; 

    // Datapath wires
    wire mem_write_enable_cpu_w;         
    wire mem_address_select_cpu_w;       
    wire [15:0] mem_write_data_cpu_w;   
    wire [7:0] alu_address_cpu_w;        
    wire halt_cpu_w;                     

    // --------------------------------------------------
    // Von Neumann Control Logic (2-Cycle FSM)
    // --------------------------------------------------
    reg state; // 0 = FETCH, 1 = EXECUTE
    reg [15:0] instruction_register_store; // Holds the instruction during execution

    // State Machine
    always @(posedge clock) begin
        if (reset) begin
            state <= 0;
            instruction_register_store <= 16'h0000;
        end else begin
            if (state == 0) begin
                // FETCH STATE:
                // Latch the instruction coming from memory
                instruction_register_store <= memory_out_wire;
                // Move to Execute state
                state <= 1;
            end else begin
                // EXECUTE STATE:
                // Instruction is executed by datapath. Move back to Fetch.
                state <= 0;
            end
        end
    end

    // --------------------------------------------------
    // MUX Logic driven by State
    // --------------------------------------------------
    
    // 1. Memory Address MUX
    // In Fetch (0): Always use PC.
    // In Execute (1): Use ALU address if requested (LD/ST), otherwise PC.
    wire [7:0] final_mem_address;
    assign final_mem_address = (state == 0) ? pc_address : 
                               (mem_address_select_cpu_w ? alu_address_cpu_w : pc_address);

    // 2. PC Write Enable
    // Only allow PC to update (increment/jump) during the Execute state.
    // In Fetch state, we must hold the PC stable.
    wire pc_enable;
    assign pc_enable = (state == 1);

    // 3. Memory Write Enable Safety
    // Only allow writing to memory during Execute. 
    // (Prevents accidental writes during Fetch phase)
    wire effective_mem_write;
    assign effective_mem_write = (state == 1) && mem_write_enable_cpu_w;

    // --------------------------------------------------
    // Instantiate Data Path
    // --------------------------------------------------
    datapath my_datapath(
        .clock(clock),
        .reset(reset),
        .instruction_address(pc_address),
        
        // FEED THE LATCHED INSTRUCTION, NOT THE RAW MEMORY WIRE
        .instruction_register(instruction_register_store), 
        
        .mem_read_data_in(memory_out_wire),     
        .pc_write_enable(pc_enable), // Connect our new stall signal
        
        .mem_write_enable_out(mem_write_enable_cpu_w),
        .mem_address_select_out(mem_address_select_cpu_w),
        .mem_write_data_out(mem_write_data_cpu_w),
        .alu_address_out(alu_address_cpu_w),
        .halt_cpu_out(halt_cpu_w)
    );

    // --------------------------------------------------
    // Single Shared Memory (Von Neumann)
    // --------------------------------------------------
    memory my_system_memory(
        .clock(clock),
        .enable(1'b1), 
        .writeEnable(effective_mem_write), // Use the safe write signal
        .address(final_mem_address), 
        .writeData(mem_write_data_cpu_w),
        .readData(memory_out_wire) 
    );

    // --------------------------------------------------
    // Halt Logic
    // --------------------------------------------------
    always @(posedge clock) begin
        if (halt_cpu_w && state == 1) begin // Only halt in Execute phase
            $display("HLT instruction executed. CPU Halted at time %0t.", $time);
            my_datapath.my_regfile.display_memory_content();
            my_system_memory.display_memory_content();
            $finish; 
        end
    end
endmodule