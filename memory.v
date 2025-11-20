module memory(clock, enable, writeEnable, address, writeData, readData);
    input clock, enable, writeEnable;
    input [15:0] address;
    input [15:0] writeData;
    output reg [15:0] readData;

    // Initially we planned to make use of all the bits for the memory -> 65,536 x 16-bit memory array -> but this was too much to work with so we reduced it to 256 
    reg [15:0] mem[0:16];  // but we are going to make it 256 memory locations X each storing 16-bit

    // load memory content from program.hex
    integer i;
    initial begin
        for (i = 0; i < 65536; i = i + 1) // first clear all to 0
            mem[i] = 16'h0000;
      $readmemh("program.hex", mem);  // Then load 16-bit words, one per line
    end

    // variables for writing memory content to a file
    integer f;
    integer j;

    // write the content of the RAM memory to a file
    always @ (posedge clock) begin
        if (writeEnable) begin
            mem[address] <= writeData; // write to the RAM at given address
            f = $fopen("memory_content.txt", "w"); // open the file for writing
            for (i = 0; i < 256; i++) begin
                $fwrite(f, "%h \n", mem[i]); // write the data to the file
            end
            $fclose(f); // close the file
        end
    end

    // read from and write to memory when enabled -- replaced by the lines below for faster and simpler simulation but better to keep for hardware implementation as block RAMs are inherently synchronous (both read and write with the clock)
/*    always @(posedge clock) begin
        if (enable) begin
            if (writeEnable)
                mem[address] <= writeData;
            else
                readData <= mem[address];
        end
    end
*/

    // read from and write to memory when enabled
    always @(posedge clock) begin
        if (enable && writeEnable)
            mem[address] <= writeData;
    end

    // asynchronous read when enabled 
    always @* begin
        if (enable)
            readData = mem[address]; //--> read from the RAM at given address
        else
            readData = 16'h0000; // if not enabled out put 0
    end
    

endmodule