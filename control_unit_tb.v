`include "control_unit.v"

module tb_control_unit;

  // Clock/reset
  reg clk   = 0;
  reg reset = 1;

  // Datapath feedback driven by TB
  reg  [3:0] opcode;
  reg        zero;

  // Control outputs under test
  wire       IRload, Aload, Bload, ALUOutLoad, MDRload, RegWrite;
  wire       MemRead, MemWrite, MemToReg;
  wire [1:0] ALUSrcA, ALUSrcB;
  wire [2:0] ALUOp;
  wire       PCWrite;
  wire [1:0] PCSel;
  wire       AddrSel;
  wire       Halt;
  
  // needed for 6) BEQZ taken - check to look for PCWrite=1, PCSel=01 a couple cycles later
  integer k;
  reg seen_branch;

  // Instantiate DUT
  control_unit dut (
    .clk(clk),
    .reset(reset),
    .opcode(opcode),
    .zero(zero),

    .IRload(IRload),
    .Aload(Aload),
    .Bload(Bload),
    .ALUOutLoad(ALUOutLoad),
    .MDRload(MDRload),
    .RegWrite(RegWrite),

    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .MemToReg(MemToReg),

    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .ALUOp(ALUOp),

    .PCWrite(PCWrite),
    .PCSel(PCSel),
    .AddrSel(AddrSel),

    .Halt(Halt)
  );

  // Clock: 10ns period
  always #5 clk = ~clk;

  // Local copies of opcode encodings (match DUT)
  localparam [3:0]
    OP_ADD  = 4'h0,
    OP_SUB  = 4'h1,
    OP_AND  = 4'h2,
    OP_OR   = 4'h3,
    OP_XOR  = 4'h4,
    OP_LDI  = 4'h5,
    OP_LD   = 4'h6,
    OP_ST   = 4'h7,
    OP_BEQZ = 4'h8,
    OP_JMP  = 4'h9,
    OP_HLT  = 4'hF;

  localparam [2:0]
    ALU_ADD   = 3'd0,
    ALU_SUB   = 3'd1,
    ALU_AND   = 3'd2,
    ALU_OR    = 3'd3,
    ALU_XOR   = 3'd4,
    ALU_PASSB = 3'd5;

  integer cyc = 0;
  always @(posedge clk) cyc <= cyc + 1;

  // Trace helper
  task trace;
    begin
      $display("T=%0t ns | cyc=%0d | op=%h z=%0b | IR=%0b A=%0b B=%0b AO=%0b MDR=%0b RW=%0b | MR=%0b MW=%0b M2R=%0b | PCW=%0b PCS=%0d AS=%0b | ASA=%0d ASB=%0d ALUOp=%0d | Halt=%0b",
        $time, cyc, opcode, zero,
        IRload, Aload, Bload, ALUOutLoad, MDRload, RegWrite,
        MemRead, MemWrite, MemToReg,
        PCWrite, PCSel, AddrSel,
        ALUSrcA, ALUSrcB, ALUOp,
        Halt);
    end
  endtask

  task step;
    begin
      @(posedge clk);
      #1 trace();
    end
  endtask

  // Issue an instruction: advance to S_IF2 and S_ID with given opcode/zero
  task issue_instruction;
    input [3:0] op;
    input       z;
    begin
      // We assume we're at S_IF1 at entry.
      step();               // S_IF2
      opcode = op;
      zero   = z;
      step();               // S_ID (opcode seen)
    end
  endtask

  // Soft checks (print warnings only)
  task expect;
    input cond;
    input [256*8-1:0] msg;
    begin
      if (!cond) $display("  [WARN] %s", msg);
    end
  endtask

  initial begin
    $dumpfile("simulations/control_unit_tb.vcd");
    $dumpvars(0, tb_control_unit);

    opcode = OP_ADD;
    zero   = 1'b0;

    // Keep reset high for 2 cycles
    repeat (2) step();
    reset = 1'b0;
    $display("== Release reset ==");

    // At this point, controller will be at S_IF1 on next step
    trace();

    // 1) ADD
    $display("\n== Test: ADD ==");
    issue_instruction(OP_ADD, 1'b0);
    step(); // S_EX_R
    expect(ALUOutLoad==1 && ALUSrcA==2'b01 && ALUSrcB==2'b00, "ADD: expected A/B to ALU and ALUOutLoad");
    step(); // S_WB_R
    expect(RegWrite==1 && MemToReg==0, "ADD: expected RegWrite from ALUOut");
    step(); // back to IF1

    // 2) LDI
    $display("\n== Test: LDI ==");
    issue_instruction(OP_LDI, 1'b0);
    step(); // S_EX_LDI
    expect(ALUOutLoad==1 && ALUOp==ALU_PASSB && ALUSrcB==2'b10, "LDI: PASSB(imm) into ALUOut");
    step(); // S_WB_LDI
    expect(RegWrite==1 && MemToReg==0, "LDI: writeback from ALUOut");
    step();

    // 3) LD
    $display("\n== Test: LD ==");
    issue_instruction(OP_LD, 1'b0);
    step(); // S_EA_LD
    expect(ALUOutLoad==1 && ALUOp==ALU_PASSB && ALUSrcB==2'b10, "LD: EA <- imm");
    step(); // S_MEM_LD
    expect(MemRead==1 && AddrSel==1 && MDRload==1, "LD: MemRead @ ALUOut, MDRload");
    step(); // S_WB_LD
    expect(RegWrite==1 && MemToReg==1, "LD: writeback from MDR");
    step();

    // 4) ST
    $display("\n== Test: ST ==");
    issue_instruction(OP_ST, 1'b0);
    step(); // S_EA_ST
    expect(ALUOutLoad==1 && ALUOp==ALU_PASSB && ALUSrcB==2'b10, "ST: EA <- imm");
    step(); // S_MEM_ST
    expect(MemWrite==1 && AddrSel==1, "ST: MemWrite @ ALUOut");
    step();

    // 5) BEQZ not taken
    $display("\n== Test: BEQZ not taken ==");
    issue_instruction(OP_BEQZ, 1'b0);
    step(); // one cycle after S_ID back to IF
    expect(PCWrite==0, "BEQZ not taken: PCWrite should be 0");
    step();

    // 6) BEQZ taken (controller applies PCWrite during the subsequent fetch window)
    $display("\n== Test: BEQZ taken ==");
    issue_instruction(OP_BEQZ, /*zero*/1'b1);

    // step once: we exit S_ID back to fetch
    step();

    // allow up to a few cycles for the controller to assert PCWrite with branch target
    seen_branch = 1'b0;
    begin: FIND_BRANCH
        for (k = 0; k < 4; k = k + 1) begin
            if (PCWrite && PCSel == 2'b01) begin
                seen_branch = 1;
                disable FIND_BRANCH; // verilog's 'break' out of this named block
        end
        step();
        end
    end
    expect(seen_branch, "BEQZ taken: expected PCWrite with branch target within next few cycles");


    // 7) JMP
    $display("\n== Test: JMP ==");
    issue_instruction(OP_JMP, 1'b0);
    step(); // cycle after S_ID
    expect(PCWrite==1 && PCSel==2'b10, "JMP: PCWrite with jump immediate");
    step();

    // 8) HLT
    $display("\n== Test: HLT ==");
    issue_instruction(OP_HLT, 1'b0);
    step(); // S_HALT
    expect(Halt==1, "HLT: Halt must be 1");
    step(); step();

    $display("\n== TB done ==");
    $finish;
  end

endmodule
