`include "cpu.v"

module cpu_top_tb;

  // Clock & reset
  reg clk   = 0;
  reg reset = 1;

  // Halt from DUT (if cpu_top exposes it). Otherwise, use hierarchical: wire Halt = dut.CU.Halt;
  wire Halt;

  // counter to run until halt or timeout
  integer max_cycles;

  // Instantiate DUT
  cpu dut (
    .clk  (clk),
    .reset(reset),
    .Halt (Halt)
  );

  // If cpu_top doesn't have .Halt, uncomment the next line:
  // wire Halt = dut.CU.Halt;

  // Clock: 10 ns period
  always #5 clk = ~clk;

  // Convenience aliases into datapath/ram for checks
  // Adjust names if you changed instance names in datapath.v
  // Memory is dut.DP.MEM, register file is dut.DP.RF
  // Internal RAM array is "regs" in your ram.v
  integer i;

  // Simple helper: step one cycle and print a short trace
  integer cyc = 0;
  task step;
    begin
      @(posedge clk);
      cyc = cyc + 1;
      // Peek a few useful signals (hierarchical)
      $display("T=%0t ns | cyc=%0d | PC=%h IR=%h | Halt=%0b | mem[20]=%h | R1=%h R2=%h R3=%h R4=%h R5=%h",
        $time, cyc,
        dut.DP.PC_q,
        dut.DP.IR_q,
        Halt,
        dut.DP.MEM.regs[8'h20],
        dut.DP.RF.registers[1],
        dut.DP.RF.registers[2],
        dut.DP.RF.registers[3],
        dut.DP.RF.registers[4],
        dut.DP.RF.registers[5]
      );
    end
  endtask

  initial begin
    $dumpfile("simulations/cpu_top_tb.vcd");
    $dumpvars(0, cpu_top_tb);

    // -------- Reset --------
    repeat (2) step();   // let clocks tick while reset=1
    reset = 0;
    $display("== Release reset ==");

    // -------- Load program into unified RAM --------
    // First clear a reasonable range (optional, but avoids stale init from ram.v)
    for (i = 0; i < 256; i = i + 1)
      dut.DP.MEM.regs[i] = 16'h0000;

    // Load program at address 0
    $readmemh("prog.hex", dut.DP.MEM.regs);

    // -------- Run until Halt or timeout --------
    max_cycles = 500;

    while (!Halt && max_cycles > 0) begin
      step();
      max_cycles = max_cycles - 1;
    end

    if (Halt)
      $display("== Program halted at PC=%h after %0d cycles ==", dut.DP.PC_q, cyc);
    else
      $display("** TIMEOUT: no HLT observed by %0d cycles **", cyc);

    // -------- Post-run checks --------
    // Expect: mem[0x20] == 8 (stored R3)
    if (dut.DP.MEM.regs[8'h20] !== 16'h0008)
      $display("  [WARN] mem[0x20]=%h, expected 0008", dut.DP.MEM.regs[8'h20]);
    else
      $display("  [OK] mem[0x20]=0008");

    // Expect: R5 == 0x000D (13) from ADD R5,R4,R1 after branch skip
    if (dut.DP.RF.registers[5] !== 16'h000D)
      $display("  [WARN] R5=%h, expected 000D", dut.DP.RF.registers[5]);
    else
      $display("  [OK] R5=000D");

    $finish;
  end

endmodule
