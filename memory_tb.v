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
        address = 8'h00; // memory[0]

        #10
        address = 8'h01; // memory[1]

        #10
        address = 8'h02; // memory[2]

        #10
        address = 8'h03; // memory[3]
        
// ---- Writing -------
        #10
        writeEnable = 1'b1;
        enable = 1'b1;
        
        #10
        address = 8'b0000_1111;
        writeData = 16'hFA2D; // memory[15] = 0xFA2D;

        #10
        writeEnable = 1'b0;

        #10
        address = 8'b0000_1111; // read val stored in memory[5]


        // 2nd write 
        #10
        writeEnable = 1'b1;
        enable = 1'b1;
        
        #10
        address = 8'b0001_0100;
        writeData = 16'h2231; // memory[20] = 0xFA2D;

        #10
        writeEnable = 1'b0;

        #10
        address = 8'b0001_0100; // read val stored in memory[5]

        // 3rd write 
        #10
        writeEnable = 1'b1;
        enable = 1'b1;
        
        #10
        address = 8'b0001_0111;
        writeData = 16'h9999; // memory[23] = 0xFA2D;

        #10
        writeEnable = 1'b0;

        #10
        address = 8'b0001_0111; // read val stored in memory[5]

        #20
        $finish;
    end


    always #5 clock = ~clock;

endmodule