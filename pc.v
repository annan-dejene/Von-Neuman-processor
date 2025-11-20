module pc(clock, reset, next_address, current_address);
    input clock;
    input reset;
    input [7:0] next_address; // 8 bits because the memory is 8-bit addressed (256 locations)
    output reg [7:0] current_address;

    // The core logic behind our PC is a synchronous register with asynchronous reset
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            current_address <= 8'h00; // Reset PC to the start of memory (address 0)
        end 
        else begin
            // Update the PC with the address provided by the control path
            current_address <= next_address;
        end
    end

endmodule
