`include "control_unit.v"
`include "datapath.v"

module cpu (
    input wire clk,
    input wire reset,
    output wire Halt   // <— expose for TB convenience
);
    // control <-> datapath wiring
    wire IRload, Aload, Bload, ALUOutLoad, MDRload, RegWrite;
    wire MemRead, MemWrite, MemToReg;
    wire [1:0] ALUSrcA, ALUSrcB, PCSel;
    wire [2:0] ALUOp;
    wire       PCWrite, AddrSel;
    wire [3:0] opcode;
    wire       zero;

    control_unit CU (
        .clk(clk), .reset(reset),
        .opcode(opcode), .zero(zero),
        .IRload(IRload), .Aload(Aload), .Bload(Bload),
        .ALUOutLoad(ALUOutLoad), .MDRload(MDRload), .RegWrite(RegWrite),
        .MemRead(MemRead), .MemWrite(MemWrite), .MemToReg(MemToReg),
        .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB), .ALUOp(ALUOp),
        .PCWrite(PCWrite), .PCSel(PCSel), .AddrSel(AddrSel),
        .Halt(Halt)
    );

    datapath DP (
        .clk(clk), .reset(reset),
        .IRload(IRload), .Aload(Aload), .Bload(Bload),
        .ALUOutLoad(ALUOutLoad), .MDRload(MDRload), .RegWrite(RegWrite),
        .MemRead(MemRead), .MemWrite(MemWrite), .MemToReg(MemToReg),
        .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB), .ALUOp(ALUOp),
        .PCWrite(PCWrite), .PCSel(PCSel), .AddrSel(AddrSel),
        .opcode(opcode), .zero(zero)
    );
endmodule