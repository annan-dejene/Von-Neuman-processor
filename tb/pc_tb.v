`include "pc.v"

module pc_tb;
    reg clock, reset;
    reg [7:0] next_address;
    wire [7:0] current_address;

    pc my_pc(.clock(clock), .reset(reset), .next_address(next_address), .current_address(current_address));

    // Clock generator
    always #5 clock = ~clock;

    initial begin
        $dumpfile("simulations/pc_wavedata.vcd");
		$dumpvars(0, pc_tb);

        // Initial setup
        clock = 1'b0;
        reset = 1'b1; // Hold in reset
        next_address = 8'hFF; // Put some random value on input while in reset

        // --- Test 1: Reset Behavior ---
        // PC should go to 0x00 on the first positive clock edge
        #10; // Wait a little time to stabilize inputs
        reset = 1'b0; // Release reset

        // --- Test 2: Sequential Counting ---
        // The PC should now load whatever is on next_address on each posedge
        
        @(negedge clock); // Sync up to the negedge to change inputs safely
        next_address = 8'h01; 

        @(negedge clock);
        next_address = 8'h02;

        @(negedge clock);
        next_address = 8'h03;

        // --- Test 3: Jump to a New Address ---
        @(negedge clock);
        $display("Testing Jump/Branch functionality");
        next_address = 8'h20; // Simulate a jump instruction result

        @(negedge clock);
        next_address = 8'h21; // Check increment after jump

        @(negedge clock);
        next_address = 8'h22;

        #20;
        $display("Simulation finished.");
        $finish;
    end
endmodule
