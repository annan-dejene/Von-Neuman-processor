`include "memory.v"

module memory_tb;
    reg [7:0] address;
    reg [15:0] writeData;
    reg clock = 1'b1, enable, writeEnable;

    wire [15:0] readData;

    memory myMemory(.clock(clock), .enable(enable), .writeEnable(writeEnable), .address(address), .writeData(writeData), .readData(readData));

    always #5 clock = ~clock;

    initial begin
    // generate files needed to plot the waveform using GTKWave
        $dumpfile("sim/waveforms/memory_wavedata.vcd");
		$dumpvars(0, memory_tb);

        // assign values with time to input signals to see output
        enable = 1'b1;
        writeEnable = 1'b0;
        address = 8'h00;

        // Wait for the first negative edge to start operations -- basically #5 but synchronizes it well
        @(negedge clock); 


        // ---- Reading - read the first 5 elements from the memory ------
        // We set up the address on the negative edge, 
        // the module reads the data on the *next* positive edge.
        repeat (4) begin 
            @(negedge clock); address = address + 1'b1;
        end
        // At this point, several clock cycles have passed and memory_content.txt has been initialized once.


// ---- Writing 1 -------
        @(negedge clock); 
        writeEnable = 1'b1; // Turn on write mode
        address = 8'h0F;    // Address 15
        writeData = 16'hFA2D; 

        @(negedge clock);   // Wait for one more negative edge (the write happens on the posedge in between)
        writeEnable = 1'b0; // Turn off write mode

        @(negedge clock);
        address = 8'h0F;    // Read back address 15 (check readData wire after posedge clock)

        // 2nd write 
        @(negedge clock); 
        writeEnable = 1'b1;
        address = 8'h0C;    // Address 12
        writeData = 16'h2231; 

        @(negedge clock); 
        writeEnable = 1'b0;

        @(negedge clock);
        address = 8'h0C;    // Read back address 12

        // 3rd write 
        @(negedge clock); 
        writeEnable = 1'b1;
        address = 8'h14;    // Address 20
        writeData = 16'h9999; 

        @(negedge clock); 
        writeEnable = 1'b0;

        @(negedge clock);
        address = 8'h14;    // Read back address 20

        @(negedge clock);
        #1;
        $display("Simulation finished.");
        $finish;
    end
endmodule