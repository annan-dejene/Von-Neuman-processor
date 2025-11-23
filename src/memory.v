module memory(clock, enable, writeEnable, address, writeData, readData);
    input clock, enable, writeEnable;
    input [7:0] address;
    input [15:0] writeData;
    output wire [15:0] readData;

    // Initially we planned to make use of all the bits for the memory -> 65,536 x 16-bit memory array -> but this was too much to work with so we reduced it to 256 
    reg [15:0] mem[0:255];  // but we are going to make it 256 memory locations X each storing 16-bit

    // load memory content from program.hex
    initial begin
        $readmemh("asm/program.hex", mem);  // Then load 16-bit words, one per line
        display_memory_content(); // begin by displaying the memory content in the file
        // $writememh("memory_content.txt", mem); // alternative

    end

    task display_memory_content(); 
        // variables for writing memory content to a file
        integer f; // file handler
        integer j; // memory location counter

        begin
            f = $fopen("sim/logs/memory_content.txt", "w"); // open the file for writing
            for (j = 0; j < 256; j++) begin
                $fwrite(f, "%02d: %04h\n", j[7:0], mem[j]);  // addr: data
            end
            $fclose(f); // close the file        
        end
    endtask


    // write the content of the RAM memory to a file
    always @ (posedge clock) begin
        if (enable && writeEnable) begin
            mem[address] <= writeData; // write to the RAM at given address
            // #1 $writememh("memory_content.txt", mem); // alternative

            // #1 display_memory_content(); // update the memory content file accordingly
        end
    end

    // taken out of the above always block to avoid a race condition between the displaying and writing to the RAM which would be scheduled for the same time (posedge of the clock) so we write to the RAM on the posedge of the clock and display the updates on the following negedge
    always @(negedge clock) begin
        if (enable && writeEnable) begin
            display_memory_content();
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

    // asynchronous read when enabled 
    assign readData = enable ? mem[address] : 16'h0000;

endmodule