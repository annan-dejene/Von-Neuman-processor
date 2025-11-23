# 16-Bit RISC Von Neumann Processor

This repository contains the Verilog implementation of a **16-bit RISC Processor** based on the **Von Neumann architecture** (Unified Memory). It features a custom Instruction Set Architecture (ISA), a 2-cycle Finite State Machine (FSM) for instruction fetching and execution, and a complete verification suite including a custom Assembler and Visualization Dashboard.

## 🚀 Project Overview

- Architecture: Von Neumann (Shared Memory for Data & Instructions)

- Data Width: 16-bit

- Address Space: 8-bit (256 words)

- Registers: 8 General Purpose Registers (R0-R7), with R0 hardwired to 0.

- Control: 2-Cycle FSM (Fetch $\to$ Execute)

- ISA: 13 Instructions including Arithmetic, Logic, Memory Access, and Control Flow.


## 📂 Directory Structure
```
project_root/
├── src/                  # Verilog Source Modules (cpu.v, datapath.v, etc.)
├── tb/                   # Verilog Testbenches
├── asm/                  # Assembler Tools & Code
│   ├── assembler.py      # Python Assembler
│   └── program.asm       # Assembly Source Code
├── sim/                  # Simulation Artifacts
│   ├── logs/             # Execution logs (PC, Registers, Memory)
│   └── waveforms/        # .vvp and .vcd files
└── processor_viz.py      # Python Visualization Dashboard
```

## 🛠️ Prerequisites

- You need the following tools installed:

- Icarus Verilog (iverilog): For compiling and simulating the Verilog code.

- GTKWave: For viewing waveform files.

- Python 3: For running the Assembler and Visualization Dashboard.

## 💻 How to Run

Follow these steps to assemble a program, simulate the processor, and visualize the results. All commands must be run from the project root directory.

### 1. Assemble Your Program

Convert your assembly code (asm/program.asm) into machine code (program.hex).

`python asm/assembler.py asm/program.asm asm/program.hex`


### 2. Compile the Simulation

Compile the testbench along with all source modules. This resolves dependencies automatically without needing include statements in the source code.

`iverilog -o sim/waveforms/cpu_tb.vvp tb/cpu_tb.v src/*.v`


### 3. Run the Simulation

Execute the compiled simulation. This generates the log files and waveforms.

`vvp sim/waveforms/cpu_tb.vvp`


### 4. Visualize the Results

Launch the interactive dashboard to replay the execution, view register states, and inspect memory.

`python processor_viz.py`

- Memory Map: See memory updates highlighted in blue.
- Register File: See the content of the registers
- Program Counter: See the value of the program counter along with the memory address it points to highlighted in yellow

### 5. Viewing Logs (Manual Inspection)

The simulation logs are stored in the sim/logs/ directory.

- Register Dump: sim/logs/register_content.txt

- Memory Dump: sim/logs/memory_content.txt

- PC Log: sim/logs/PC_log.txt

## 🏗️ Architecture Details

### The Von Neumann Solution

To overcome the structural hazard of a single memory block, the CPU implements a 2-Cycle Finite State Machine:

- Fetch Cycle: The PC address is sent to memory. The instruction is read and latched into an internal register. The PC is frozen to prevent updates.

- Execute Cycle: The latched instruction is decoded. If it's a Load/Store instruction, the ALU result is used as the memory address. Register writes are enabled only in this cycle to prevent race conditions.

### Supported Instruction Set

| Type | Mnemonic | Description | Opcode |
| :--- | :--- | :--- | :--- |
| **R-Type** | `ADD Rd, Rs, Rt` | Add | `0001` |
| | `SUB Rd, Rs, Rt` | Subtract | `0010` |
| | `AND Rd, Rs, Rt` | Bitwise AND | `0011` |
| | `OR Rd, Rs, Rt` | Bitwise OR | `0100` |
| | `XOR Rd, Rs, Rt` | Bitwise XOR | `0101` |
| | `NOT Rd, Rs` | Bitwise NOT | `0110` |
| **I-Type** | `MOV Rd, Imm` | Move Immediate | `0111` |
| | `LDR Rd, [Rs]` | Load Register Indirect | `1000` |
| | `STR [Rs], Rt` | Store Register Indirect | `1001` |
| **Branch** | `BEQZ Rs, Imm` | Branch if Zero | `1010` |
| | `JMP Imm` | Unconditional Jump | `1011` |
| **System** | `HLT` | Halt Processor | `1110` |


## 📊 Verification

The design has been verified using:

1. Unit Tests: Individual testbenches for ALU, Register File, and Memory.

2. Integration Test (`cpu_tb.v`): A full system test running a complex assembly program that exercises all instructions, memory operations, and branching logic.

3. Visual Validation: The `processor_viz.py` tool confirms the correct state transitions cycle-by-cycle.


*Project created for CCEN-350: Computer Architecture & Organization.*