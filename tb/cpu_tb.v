// `include "../src/cpu.v"

module cpu_tb;
    reg clock, reset;

    integer f;

    // Instantiate the top-level CPU module
    cpu my_cpu(.clock(clock), .reset(reset));

    // Clock generator (10ns period)
    always #5 clock = ~clock;

    initial begin
        // Generate waveform dump file
        $dumpfile("sim/waveforms/cpu_wavedata.vcd");
		    $dumpvars(0, cpu_tb);
        
        // Clear PC log file
        begin 
            f = $fopen("sim/logs/PC_log.txt", "w");
            $fclose(f); 
        end 

        // --- Start of Simulation ---
        clock = 1'b0;
        reset = 1'b1; // Hold CPU in reset

        #20;          // Wait for a bit in reset
        @(negedge clock);
        reset = 1'b0; // Release reset, CPU starts execution on next posedge clock

        // The simulation will now run autonomously until the HLT instruction 
        // is executed (handled by the logic inside cpu.v)
        
        // Add a safety timeout just in case HLT is never reached
        #10000; 
        $display("Simulation timed out, HLT not reached.");
        my_cpu.my_datapath.my_regfile.display_memory_content();
        $finish;
    end

    // Monitor key signals (optional, but useful for quick terminal checks)
    initial begin
        $monitor("Time: %0t | PC Addr: %h | Instruction: %h | Reg R3: %h | Reg R5: %h | ALU Zero: %b", 
                 $time, 
                 my_cpu.my_datapath.instruction_address, 
                 my_cpu.instruction_register_store, 
                 my_cpu.my_datapath.my_regfile.registers[3], // Accessing internal register 3 value
                 my_cpu.my_datapath.my_regfile.registers[5], // Accessing internal register 5 value
                 my_cpu.my_datapath.alu_zero_flag);
    end

endmodule
