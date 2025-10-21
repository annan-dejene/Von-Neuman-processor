`include "regfile.v"

module regfile_tb;
    reg [2:0] regSource1, regSource2, regDestination;
    reg [15:0] writeData;
    reg clock = 1'b1, reset, writeEnable;

    wire [15:0] data1, data2;

    regfile myregisters(.regSource1(regSource1), .regSource2(regSource2), .regDestination(regDestination), .writeData(writeData), .data1(data1), .data2(data2), .writeEnable(writeEnable), .clock(clock), .reset(reset));

    initial begin
    // generate files needed to plot the waveform using GTKWave
        $dumpfile("simulations/reg_file_wavedata.vcd");
		$dumpvars(0, regfile_tb);

        // assign values with time to input signals to see output
        reset = 1'b0;
        writeEnable = 1'b0;

        #4
        reset = 1'b1;
        regSource1 = 3'b000; // R0
        regSource2 = 3'b100; // R4

        #6
        reset = 1'b0;

        // Store into R2 0x23FE by selecting destination register as R2 and setting the writeData to the value and enabling the writeEnable signal

        #2
        regDestination = 3'b010; // R2
        writeData = 16'h23FE; // R2 = 0x23FE
        writeEnable = 1'b1;

        #7
        writeEnable = 1'b0;

        #1
        regSource1 = 3'b010; // R2 should have 0x23FE


        // Store into R4  0x6781
        #8
        regDestination = 3'b100; // select R4
        writeData = 16'h6781; // prepare val 0x6781
        writeEnable = 1'b1; // set write enable signal
        regSource1 = 3'b100; // check value of R4 immediately

        #8
        writeEnable = 1'b0; // clear enable signal 


        #10
        $finish;
    end


    always #4 clock = ~clock;

endmodule