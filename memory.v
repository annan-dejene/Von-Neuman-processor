module memory(clock, enable, writeEnable, address, writeData, readData);
    input clock, enable, writeEnable;
    input [15:0] address;
    input [15:0] writeData;
    output reg [15:0] readData;

    reg [15:0] mem[0:65535]; // 65,536 x 16-bit memory array

    // load memory content from program.hex
    integer i;
    initial begin
        for (i = 0; i < 65536; i = i + 1) // first clear all to 0
            mem[i] = 16'h0000;
      $readmemh("program.hex", mem);  // Then load 16-bit words, one per line
    end

    // read from and write to memory when enabled
    always @(posedge clock) begin
        if (enable) begin
            if (writeEnable)
                mem[address] <= writeData;
            else
                readData <= mem[address];
        end
    end
    

endmodule