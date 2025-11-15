// Control Unit for 16-bit RISC (multi-cycle, von Neumann, single-port memory)
module control_unit (
    input  wire        clk,
    input  wire        reset,

    // Datapath feedback
    input  wire [3:0]  opcode,    // IR[15:12]
    input  wire        zero,      // ALU zero flag (for BEQZ)

    // Control outputs to datapath
    output reg         IRload,
    output reg         Aload,
    output reg         Bload,
    output reg         ALUOutLoad,
    output reg         MDRload,
    output reg         RegWrite,

    output reg         MemRead,
    output reg         MemWrite,
    output reg         MemToReg,  // 0: ALUOut -> RF ; 1: MDR -> RF

    output reg  [1:0]  ALUSrcA,   // 00: PC, 01: A, 10: 0, 11: reserved
    output reg  [1:0]  ALUSrcB,   // 00: B, 01: +1, 10: imm, 11: reserved
    output reg  [2:0]  ALUOp,     // 0=ADD,1=SUB,2=AND,3=OR,4=XOR,5=PASSB

    output reg         PCWrite,
    output reg  [1:0]  PCSel,     // 00: ALUOut (PC+1), 01: ALUOut (branch target), 10: jump immediate
    output reg         AddrSel,   // 0: PC -> mem.addr, 1: ALUOut -> mem.addr

    output reg         Halt       // stop execution
);

    // ------------ Opcode map ------------
    localparam [3:0] OP_ADD  = 4'h0;
    localparam [3:0] OP_SUB  = 4'h1;
    localparam [3:0] OP_AND  = 4'h2;
    localparam [3:0] OP_OR   = 4'h3;
    localparam [3:0] OP_XOR  = 4'h4;
    localparam [3:0] OP_LDI  = 4'h5;
    localparam [3:0] OP_LD   = 4'h6;
    localparam [3:0] OP_ST   = 4'h7;
    localparam [3:0] OP_BEQZ = 4'h8;
    localparam [3:0] OP_JMP  = 4'h9;
    localparam [3:0] OP_HLT  = 4'hF;

    // ------------ ALU operations ------------
    localparam [2:0] ALU_ADD   = 3'd0;
    localparam [2:0] ALU_SUB   = 3'd1;
    localparam [2:0] ALU_AND   = 3'd2;
    localparam [2:0] ALU_OR    = 3'd3;
    localparam [2:0] ALU_XOR   = 3'd4;
    localparam [2:0] ALU_PASSB = 3'd5;

    // ------------ FSM states (Verilog-2001) ------------
    localparam [3:0]
        S_IF1    = 4'd0,   // start fetch
        S_IF2    = 4'd1,   // latch IR, PC <- PC+1
        S_ID     = 4'd2,   // decode, reg fetch, resolve beqz/jmp
        S_EX_R   = 4'd3,   // ALU A op B -> ALUOut
        S_WB_R   = 4'd4,   // RegWrite from ALUOut
        S_EX_LDI = 4'd5,   // ALU PASSB(imm) -> ALUOut
        S_WB_LDI = 4'd6,   // RegWrite from ALUOut
        S_EA_LD  = 4'd7,   // effective address for LD
        S_MEM_LD = 4'd8,   // MemRead -> MDR
        S_WB_LD  = 4'd9,   // RegWrite from MDR
        S_EA_ST  = 4'd10,  // effective address for ST
        S_MEM_ST = 4'd11,  // MemWrite
        S_HALT   = 4'd15;

    reg [3:0] state;
    reg [3:0] next;

    // ------------ Sequential: state register ------------
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= S_IF1;
        else
            state <= next;
    end

    // ------------ Combinational: defaults + outputs + next-state ------------
    always @* begin
        // defaults (deassert everything unless stated otherwise)
        IRload     = 1'b0;
        Aload      = 1'b0;
        Bload      = 1'b0;
        ALUOutLoad = 1'b0;
        MDRload    = 1'b0;
        RegWrite   = 1'b0;

        MemRead    = 1'b0;
        MemWrite   = 1'b0;
        MemToReg   = 1'b0;

        ALUSrcA    = 2'b00;  // default A = PC
        ALUSrcB    = 2'b00;  // default B = reg B
        ALUOp      = ALU_ADD;

        PCWrite    = 1'b0;
        PCSel      = 2'b00;  // from ALUOut
        AddrSel    = 1'b0;   // PC -> mem.addr
        Halt       = 1'b0;

        next       = state;

        case (state)
            // ------- IF1: start instruction fetch -------
            S_IF1: begin
                AddrSel    = 1'b0;      // mem.addr <= PC
                MemRead    = 1'b1;      // begin read
                // Prepare PC+1 in ALUOut
                ALUSrcA    = 2'b00;     // A=PC
                ALUSrcB    = 2'b01;     // +1
                ALUOp      = ALU_ADD;
                ALUOutLoad = 1'b1;      // ALUOut <- PC+1
                next       = S_IF2;
            end

            // ------- IF2: latch IR, commit PC <- PC+1 -------
            S_IF2: begin
                IRload   = 1'b1;        // IR <- mem.out
                PCWrite  = 1'b1;        // PC <- ALUOut (PC+1)
                PCSel    = 2'b00;
                next     = S_ID;
            end

            // ------- ID: decode, read regfile, resolve BEQZ/JMP -------
            S_ID: begin
                Aload = 1'b1;           // A <- Reg[rs]
                Bload = 1'b1;           // B <- Reg[rt]

                // Precompute branch target for BEQZ: PC + imm
                if (opcode == OP_BEQZ) begin
                    ALUSrcA    = 2'b00; // PC
                    ALUSrcB    = 2'b10; // imm
                    ALUOp      = ALU_ADD;
                    ALUOutLoad = 1'b1;  // ALUOut <- PC+imm
                end

                // Route by opcode (resolve JMP/BEQZ here)
                if (opcode == OP_ADD || opcode == OP_SUB ||
                    opcode == OP_AND || opcode == OP_OR  ||
                    opcode == OP_XOR) begin
                    next = S_EX_R;
                end
                else if (opcode == OP_LDI) begin
                    next = S_EX_LDI;
                end
                else if (opcode == OP_LD) begin
                    next = S_EA_LD;
                end
                else if (opcode == OP_ST) begin
                    next = S_EA_ST;
                end
                else if (opcode == OP_BEQZ) begin
                    if (zero) begin
                        PCWrite = 1'b1; PCSel = 2'b01; // PC <- ALUOut (branch target)
                    end
                    next = S_IF1;
                end
                else if (opcode == OP_JMP) begin
                    PCWrite = 1'b1; PCSel = 2'b10;     // PC <- jump immediate (from datapath)
                    next    = S_IF1;
                end
                else if (opcode == OP_HLT) begin
                    Halt = 1'b1;
                    next = S_HALT;
                end
                else begin
                    next = S_IF1; // default NOP
                end
            end

            // ------- R-type execute -------
            S_EX_R: begin
                ALUSrcA    = 2'b01;                 // A
                ALUSrcB    = 2'b00;                 // B
                case (opcode)
                    OP_ADD: ALUOp = ALU_ADD;
                    OP_SUB: ALUOp = ALU_SUB;
                    OP_AND: ALUOp = ALU_AND;
                    OP_OR : ALUOp = ALU_OR;
                    OP_XOR: ALUOp = ALU_XOR;
                    default: ALUOp = ALU_ADD;
                endcase
                ALUOutLoad = 1'b1;                  // latch result
                next       = S_WB_R;
            end

            // ------- R-type write-back -------
            S_WB_R: begin
                RegWrite = 1'b1;                    // write regfile from ALUOut
                MemToReg = 1'b0;
                next     = S_IF1;
            end

            // ------- LDI execute -------
            S_EX_LDI: begin
                ALUSrcA    = 2'b10;                 // 0 (don't care)
                ALUSrcB    = 2'b10;                 // imm
                ALUOp      = ALU_PASSB;
                ALUOutLoad = 1'b1;
                next       = S_WB_LDI;
            end

            // ------- LDI write-back -------
            S_WB_LDI: begin
                RegWrite = 1'b1;
                MemToReg = 1'b0;                    // ALUOut
                next     = S_IF1;
            end

            // ------- LD effective address (absolute for now) -------
            S_EA_LD: begin
                // ALUOut <- imm
                ALUSrcA    = 2'b10;                 // 0
                ALUSrcB    = 2'b10;                 // imm
                ALUOp      = ALU_PASSB;
                ALUOutLoad = 1'b1;
                next       = S_MEM_LD;
            end

            // ------- LD memory read -------
            S_MEM_LD: begin
                AddrSel = 1'b1;                     // mem.addr <= ALUOut
                MemRead = 1'b1;
                MDRload = 1'b1;                     // capture mem data
                next    = S_WB_LD;
            end

            // ------- LD write-back -------
            S_WB_LD: begin
                RegWrite = 1'b1;
                MemToReg = 1'b1;                    // from MDR
                next     = S_IF1;
            end

            // ------- ST effective address -------
            S_EA_ST: begin
                // ALUOut <- imm
                ALUSrcA    = 2'b10;                 // 0
                ALUSrcB    = 2'b10;                 // imm
                ALUOp      = ALU_PASSB;
                ALUOutLoad = 1'b1;
                next       = S_MEM_ST;
            end

            // ------- ST memory write -------
            S_MEM_ST: begin
                AddrSel  = 1'b1;                    // mem.addr <= ALUOut
                MemWrite = 1'b1;                    // mem.wdata driven by datapath (B)
                next     = S_IF1;
            end

            // ------- Halt -------
            S_HALT: begin
                Halt = 1'b1;
                next = S_HALT;                      // stay until reset
            end

            default: begin
                next = S_IF1;
            end
        endcase
    end

endmodule
