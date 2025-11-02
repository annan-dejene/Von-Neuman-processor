`include "memory.v"

module memory_tb;
    reg [15:0] address, writeData;
    reg clock = 1'b1, enable, writeEnable;

    wire [15:0] readData;

    memory myMemory(.clock(clock), .enable(enable), .writeEnable(writeEnable), .address(address), .writeData(writeData), .readData(readData));

    initial begin
    // generate files needed to plot the waveform using GTKWave
        $dumpfile("simulations/memory_wavedata.vcd");
		$dumpvars(0, memory_tb);

        // assign values with time to input signals to see output
        enable = 1'b1;
        writeEnable = 1'b0;

// ---- Reading ------
        #10
        address = 16'h0000; // memory[0]

        #10
        address = 16'h0001; // memory[1]

        #10
        address = 16'h0002; // memory[2]

        #10
        address = 16'h0003; // memory[3]
        
// ---- Writing -------
        #10
        writeEnable = 1'b1;
        
        #10
        address = 16'h0005; 
        writeData = 16'hFA2D; // memory[5] = 0xFA2D;

        #10
        writeEnable = 1'b0;

        #10
        address = 16'h0005; // read val stored in memory[5]

        #10
        $finish;
    end


    always #5 clock = ~clock;

endmodule