`include "cpu.v"

module cpu_top_tb;

  // Clock & reset
  reg clk   = 0;
  reg reset = 1;

  // Halt from DUT
  wire Halt;

  // counter to run until halt or timeout
  integer max_cycles;

  // Instantiate DUT (module name 'cpu' from cpu.v)
  cpu dut (
    .clk  (clk),
    .reset(reset),
    .Halt (Halt)
  );

  // Clock: 10 ns period
  always #5 clk = ~clk;

  // Convenience aliases into datapath/memory for checks
  // Memory instance is dut.DP.MEM, internal RAM array is 'mem'
  // Register file instance is dut.DP.RF with 'registers' array
  integer cyc = 0;

  // Step one cycle and print a short trace
  task step;
    begin
      @(posedge clk);
      cyc = cyc + 1;
      $display("T=%0t ns | cyc=%0d | PC=%h IR=%h | Halt=%0b | mem[0x20]=%h | R1=%h R2=%h R3=%h R4=%h R5=%h",
        $time, cyc,
        dut.DP.PC_q,
        dut.DP.IR_q,
        Halt,
        dut.DP.MEM.mem[16'h0020],
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

    // -------- Load program into unified memory BEFORE releasing reset --------
    // (This overwrites any contents set by memory.v's initial block.)
    $readmemh("program.hex", dut.DP.MEM.mem);
    // DEBUGGING -- check the contents to ensure it was loaded properly
    $display("mem[0]=%h mem[1]=%h mem[2]=%h mem[3]=%h",
         dut.DP.MEM.mem[16'h0000],
         dut.DP.MEM.mem[16'h0001],
         dut.DP.MEM.mem[16'h0002],
         dut.DP.MEM.mem[16'h0003]);

    // -------- Reset --------
    repeat (2) step();   // clocks while reset=1
    reset = 0;
    $display("== Release reset ==");

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
    // Expect: mem[0x20] == 0x0008
    if (dut.DP.MEM.mem[16'h0020] !== 16'h0008)
      $display("  [WARN] mem[0x20]=%h, expected 0008", dut.DP.MEM.mem[16'h0020]);
    else
      $display("  [OK] mem[0x20]=0008");

    // Expect: R5 == 0x000D
    if (dut.DP.RF.registers[5] !== 16'h000D)
      $display("  [WARN] R5=%h, expected 000D", dut.DP.RF.registers[5]);
    else
      $display("  [OK] R5=000D");

    $finish;
  end

endmodule
