`include "regfile.v"

module regfile_tb;
    reg [2:0] regSource1, regSource2, regDestination;
    reg [15:0] writeData;
    reg clock = 1'b1, reset, writeEnable;

    wire [15:0] data1, data2;

    regfile myregisters(.regSource1(regSource1), .regSource2(regSource2), .regDestination(regDestination), .writeData(writeData), .data1(data1), .data2(data2), .writeEnable(writeEnable), .clock(clock), .reset(reset));

    always #5 clock = ~clock;

    initial begin
    // generate files needed to plot the waveform using GTKWave
        $dumpfile("simulations/reg_file_wavedata.vcd");
		$dumpvars(0, regfile_tb);

        // Initial setup
        reset = 1'b1; // sets all registers to 0
        writeEnable = 1'b0;

        @(negedge clock); // wait until just the next pos edge (effectively #5 -> the period)
        
        // release the reset to start operation
        reset = 1'b0; 


        // --- Write 1: Store 0x23FE into R2 ---
        @(negedge clock) // prepare inputs on negative edge
        regDestination = 3'b010; // R2
        writeData = 16'h23FE; // R2 = 0x23fe
        writeEnable = 1'b1;

        // The write happens on the *next* immediate posedge clock

        @(negedge clock); // Wait for the next negedge to disable write
        writeEnable = 1'b0; // Clear write enable

        @(negedge clock); // After the write, set up read source
        regSource1 = 3'b010; // Check value of R2 (should see 0x23FE on data1 immediately)


        // --- Write 2: Store 0x6781 into R4 ---
        @(negedge clock); // Prepare inputs
        regDestination = 3'b100; // R4
        writeData = 16'h6781; 
        writeEnable = 1'b1; 

        regSource1 = 3'b100; // Check R4 value right away in data1

        @(negedge clock);
        writeEnable = 1'b0; 

        // data1 should now hold 0x6781 (read asynchronously)


         // --- Test R0: Attempt to write to R0 (should fail) ---
         @(negedge clock);
        regDestination = 3'b000; // Try to write to R0
        writeData = 16'hFFFF;    // Value we want to write
        writeEnable = 1'b1;

        @(negedge clock);
        writeEnable = 1'b0;

        @(negedge clock);
        regSource1 = 3'b000; // Read R0 (data1 should remain 0x0000, not 0xFFFF)

       @(negedge clock);

       $display("Simulation finished.");
       $finish;
       #2;
    end
endmodule