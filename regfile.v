// 8 registers R0-R7, 16 bits each so 8x16 register file
// read from the regiser so for reading we output the data to be read for the specified register (to be input to ALU for eg)
// write to the registers so for writing we accept as an input the data to write (writeData) as a result of ALU computation for eg
// if write enable == 1 then we are trying to write something into a particular register so we accept that value and put it into the specified register
module regfile(regSource1, regSource2, regDestination, writeData, data1, data2, writeEnable, clock, reset);
    input clock, reset, writeEnable;
    input [2:0] regSource1;
    input [2:0] regSource2;
    input [2:0] regDestination;

    input [15:0] writeData;

    output [15:0] data1;
    output [15:0] data2;

    reg [15:0] registers [0:7]; // R0-R7 each of size 16 bits (registers)

    integer i;

    always @(posedge clock) begin
        if (reset)
            begin
                // initialize registers to 0 initially
                for (i=0; i<8; i=i+1)
                    registers[i] <= 16'b0000_0000_0000_0000;    
            end
        
        else if (writeEnable && regDestination != 3'b000) // if writing enabled then write the data from 'writeData' to the specified destination register like MOV
            registers[regDestination] <= writeData;
    end


    /* Using the same register as the destination and source
        ADD R1, R1, R2;  -> R1 = R1 + R2 
        
        If that is the instruction we have for example, the control unit will be requesting to get/read the values of registers R1 and R2 to
        be provided as inputs to the ALU first. (regSource1=3'b001 and regSource2=3'b010 and writeEnable=0)
        This will mean data1 will have value of R1 (old val before addition operation) and data2=R2
        the operation will be carried out by the ALU and the result written(writeData=R1+R2 and writeEnable=1) back to R1. 
    */


    // To read the register values and provide them as an output for a different module to work with
    // Read means the callee expects to get the value stored in the register specified by the argument to the module 
    assign data1 = (regSource1==3'b000) ? 16'b0000_0000_0000_0000: registers[regSource1]; // Hardwiring R0 to 0
    assign data2 = (regSource2==3'b000) ? 16'b0000_0000_0000_0000: registers[regSource2];

endmodule