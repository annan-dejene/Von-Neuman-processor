module pc(clock, reset, next_address, current_address);
    input clock;
    input reset;
    input [7:0] next_address; // 8 bits because the memory is 8-bit addressed (256 locations)
    output reg [7:0] current_address;

    // Task to log PC changes to a file
    task log_pc_change();
        integer f_pc_log;
        // Use $fopen with "a" mode to APPEND to the file (prevents overwriting every time)
        begin
            f_pc_log = $fopen("PC_log.txt", "a"); 
            if (f_pc_log) begin
                $fwrite(f_pc_log, "Time: %0t ns | Next Addr: %h | Current Addr: %h\n", $time, next_address, current_address);
                $fclose(f_pc_log);
            end
        end
    endtask

    // The core logic behind our PC is a synchronous register with asynchronous reset
    always @(posedge clock) begin
        if (reset) begin
            current_address <= 8'h00; // Reset PC to the start of memory (address 0)
        end 
        else begin
            // Update the PC with the address provided by the control path
            current_address <= next_address;
        end
    end

    always @(negedge clock)
        log_pc_change();

endmodule
