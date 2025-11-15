`include "ALU.v"
`include "regfile.v"
`include "memory.v"

module datapath (
    input  wire        clk,
    input  wire        reset,

    // ---- control signals from control_unit ----
    input  wire        IRload,
    input  wire        Aload,
    input  wire        Bload,
    input  wire        ALUOutLoad,
    input  wire        MDRload,
    input  wire        RegWrite,

    input  wire        MemRead,
    input  wire        MemWrite,
    input  wire        MemToReg,     // 0: ALUOut -> RF, 1: MDR -> RF

    input  wire [1:0]  ALUSrcA,      // 00: PC, 01: A, 10: 0, 11: reserved
    input  wire [1:0]  ALUSrcB,      // 00: B, 01: +1, 10: imm, 11: reserved
    input  wire [2:0]  ALUOp,        // 0=ADD,1=SUB,2=AND,3=OR,4=XOR,5=PASSB

    input  wire        PCWrite,
    input  wire [1:0]  PCSel,        // 00/01: ALUOut, 10: jump immediate
    input  wire        AddrSel,      // 0: PC -> mem.addr, 1: ALUOut -> mem.addr

    // ---- feedback to control_unit ----
    output wire [3:0]  opcode,       // IR[15:12]
    output wire        zero          // BEQZ condition (rs==0)
);

    // ------------------------------------------------------------
    // Internal registers
    // ------------------------------------------------------------
    reg  [15:0] PC_q, PC_d;
    reg  [15:0] IR_q;                // instruction register
    reg  [15:0] A_q,  B_q;           // operand latches from regfile
    reg  [15:0] ALUOut_q;            // holds ALU result between cycles
    reg  [15:0] MDR_q;               // holds memory read data

    // ------------------------------------------------------------
    // IR fields / immediates
    // ------------------------------------------------------------
    assign opcode = IR_q[15:12];

    wire [2:0] rd = IR_q[11:9];
    wire [2:0] rs = IR_q[8:6];
    wire [2:0] rt = IR_q[5:3];

    // Sign-extended 8-bit immediate (you can change width to taste)
    wire [15:0] imm16 = {{8{IR_q[7]}}, IR_q[7:0]};

    // Absolute 12-bit jump target (zero-extended for now)
    wire [15:0] jmp_addr = {4'b0000, IR_q[11:0]};

    // ------------------------------------------------------------
    // Register file (8 x 16) — assumes your regfile interface
    // module regfile(regSource1, regSource2, regDestination, writeData, data1, data2, writeEnable, clock, reset);
    // ------------------------------------------------------------
    wire [15:0] rf_data1, rf_data2;
    wire [15:0] rf_wdata = (MemToReg) ? MDR_q : ALUOut_q;

    regfile RF (
        .regSource1     (rs),
        .regSource2     (rt),
        .regDestination (rd),
        .writeData      (rf_wdata),
        .data1          (rf_data1),
        .data2          (rf_data2),
        .writeEnable    (RegWrite),
        .clock          (clk),
        .reset          (reset)
    );

    // BEQZ condition: rs == 0 (use regfile output directly so it's available in ID)
    assign zero = (rf_data1 == 16'h0000);

    // ------------------------------------------------------------
    // A/B operand latches (loaded in ID)
    // ------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            A_q <= 16'h0000;
            B_q <= 16'h0000;
        end else begin
            if (Aload) A_q <= rf_data1;
            if (Bload) B_q <= rf_data2;
        end
    end

    // ------------------------------------------------------------
    // ALU input muxes
    // ------------------------------------------------------------
    reg [15:0] alu_a;
    reg [15:0] alu_b;

    always @* begin
        // ALUSrcA: 00=PC, 01=A, 10=0, 11=reserved
        case (ALUSrcA)
            2'b00: alu_a = PC_q;
            2'b01: alu_a = A_q;
            2'b10: alu_a = 16'h0000;
            default: alu_a = 16'h0000;
        endcase

        // ALUSrcB: 00=B, 01=+1, 10=imm, 11=reserved
        case (ALUSrcB)
            2'b00: alu_b = B_q;
            2'b01: alu_b = 16'h0001;
            2'b10: alu_b = imm16;
            default: alu_b = 16'h0000;
        endcase
    end

    // ------------------------------------------------------------
    // ALU
    // ------------------------------------------------------------
    wire [15:0] alu_y;

    alu16 ALU (
        .a  (alu_a),
        .b  (alu_b),
        .op (ALUOp),
        .y  (alu_y)
    );

    // ALUOut register
    always @(posedge clk or posedge reset) begin
        if (reset)
            ALUOut_q <= 16'h0000;
        else if (ALUOutLoad)
            ALUOut_q <= alu_y;
    end

        // ------------------------------------------------------------
    // Unified memory (single-port) – new interface:
    // memory(clock, enable, writeEnable, address, writeData, readData)
    // ------------------------------------------------------------

    // Address mux: 0 -> PC, 1 -> ALUOut
    wire [15:0] mem_addr  = (AddrSel == 1'b0) ? PC_q : ALUOut_q;

    // Translate control-unit signals to memory interface
    wire        mem_enable      = MemRead | MemWrite;
    wire        mem_writeEnable = MemWrite;

    wire [15:0] mem_rdata;

    // Instance name kept as MEM so your TB paths still work (dut.DP.MEM.regs)
    memory MEM (
        .clock       (clk),
        .enable      (mem_enable),
        .writeEnable (mem_writeEnable),
        .address     (mem_addr),
        .writeData   (B_q),
        .readData    (mem_rdata)
    );

    // MDR register (capture memory read data)
    always @(posedge clk or posedge reset) begin
        if (reset)
            MDR_q <= 16'h0000;
        else if (MDRload)
            MDR_q <= mem_rdata;
    end

    // Instruction Register (IR) captures from the same readData
    always @(posedge clk or posedge reset) begin
        if (reset)
            IR_q <= 16'h0000;
        else if (IRload)
            IR_q <= mem_rdata;
    end


    // ------------------------------------------------------------
    // Instruction Register (IR)
    // ------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset)
            IR_q <= 16'h0000;
        else if (IRload)
            IR_q <= ram_out;      // instruction fetch path
    end

    // ------------------------------------------------------------
    // Program Counter (PC)
    // PCWrite is asserted in IF2 (for PC+1) and also for branches/jumps
    // PCSel: 00/01 = ALUOut (PC+1 or branch target), 10 = jump immediate
    // ------------------------------------------------------------
    always @* begin
        PC_d = PC_q; // default hold
        if (PCWrite) begin
            case (PCSel)
                2'b00: PC_d = ALUOut_q;     // PC+1 in IF2
                2'b01: PC_d = ALUOut_q;     // branch target (already in ALUOut)
                2'b10: PC_d = jmp_addr;     // absolute jump target (12-bit zero-extended)
                default: PC_d = ALUOut_q;
            endcase
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            PC_q <= 16'h0000;
        else
            PC_q <= PC_d;
    end

endmodule

// ------------------------------------------------------------
// Simple 16-bit combinational ALU (Verilog-2001)
// op: 0=ADD, 1=SUB, 2=AND, 3=OR, 4=XOR, 5=PASSB
// ------------------------------------------------------------
module alu16 (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [2:0]  op,
    output reg  [15:0] y
);
    always @* begin
        case (op)
            3'd0: y = a + b;       // ADD
            3'd1: y = a - b;       // SUB
            3'd2: y = a & b;       // AND
            3'd3: y = a | b;       // OR
            3'd4: y = a ^ b;       // XOR
            3'd5: y = b;           // PASSB
            default: y = 16'h0000;
        endcase
    end
endmodule
