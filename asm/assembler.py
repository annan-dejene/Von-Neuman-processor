import re
import argparse
import sys


# ----- ISA Definitions -----
OPCODES = {
    "NOP": 0x0,
    "ADD": 0x1,
    "SUB": 0x2,
    "AND": 0x3,
    "OR": 0x4,
    "XOR": 0x5,
    "NOT": 0x6,
    "MOV": 0x7,
    "LD": 0x8,
    "ST": 0x9,
    "BEQZ": 0xA,
    "JMP": 0xB,
    "HLT": 0xE,
}

REGISTER_MAP = {f"R{i}": i for i in range(8)}


# ----- Helper Functions -----
def parse_register(token):
    # Remove brackets [ ] if present (common in load/store syntax)
    token = token.strip().replace("[", "").replace("]", "").rstrip(",")
    if token not in REGISTER_MAP:
        raise ValueError(f"Invalid register: {token}")
    return REGISTER_MAP[token]


def parse_immediate(token):
    token = token.strip().replace("#", "")
    return int(token, 0)  # supports decimal or hex (0x..)


# ----- Encoding Functions -----
def encode_r_type(op, rd, rs, rt):
    # R-Type: Op(15:12) | Rd(11:9) | Rs(8:6) | Rt(5:3) | Unused(2:0)
    opcode = OPCODES[op] << 12
    return opcode | (rd << 9) | (rs << 6) | (rt << 3)


def encode_i_type(op, rd, imm):
    # I-Type: Op(15:12) | Rd(11:9) | Imm(8:0)
    # Used for MOV
    opcode = OPCODES[op] << 12
    imm &= 0x1FF  # Mask to 9 bits
    return opcode | (rd << 9) | imm


def encode_branch_type(op, rs, imm):
    # Branch Type: Op(15:12) | Unused(11:9) | Rs(8:6) | Imm(5:0)
    # Used for BEQZ
    opcode = OPCODES[op] << 12
    imm &= 0x3F  # Mask to 6 bits
    return opcode | (rs << 6) | imm


# ----- Assembler Core -----
def assemble_line(line):
    line = line.split(";")[0].strip()  # remove comments
    if not line:
        return None

    parts = re.split(r"[ ,]+", line)
    mnemonic = parts[0].upper()

    # --- R-Type Instructions (3 Regs) ---
    if mnemonic in ["ADD", "SUB", "AND", "OR", "XOR"]:
        rd = parse_register(parts[1])
        rs = parse_register(parts[2])
        rt = parse_register(parts[3])
        return encode_r_type(mnemonic, rd, rs, rt)

    # --- R-Type (2 Regs) ---
    if mnemonic == "NOT":
        rd = parse_register(parts[1])
        rs = parse_register(parts[2])
        return encode_r_type(mnemonic, rd, rs, 0)

    # --- Move Immediate ---
    if mnemonic == "MOV":
        rd = parse_register(parts[1])
        imm = parse_immediate(parts[2])
        return encode_i_type(mnemonic, rd, imm)

    # --- Memory Instructions (Register Addressing) ---
    # LDR Rd, [Rs]
    if mnemonic == "LDR":
        rd = parse_register(parts[1])  # Destination
        rs = parse_register(parts[2])  # Address Source
        # Map LDR -> LD opcode, Rt=0
        return encode_r_type("LD", rd, rs, 0)

    # STR Rs, Rt (Store Address, Data)
    # Based on your hardware test: STR R2, R1 (Mem[R2] = R1)
    # Syntax: STR AddrReg, DataReg
    if mnemonic == "STR":
        rs = parse_register(parts[1])  # Address Register (Rs)
        rt = parse_register(parts[2])  # Data Register (Rt)
        # Map STR -> ST opcode, Rd=0
        return encode_r_type("ST", 0, rs, rt)

    # --- Control Flow ---
    # BEQZ Rs, Imm
    if mnemonic == "BEQZ":
        rs = parse_register(parts[1])  # Condition Register (Rs)
        imm = parse_immediate(parts[2])
        # Must use Rs (bits 8:6), NOT Rd!
        return encode_branch_type(mnemonic, rs, imm)

    # JMP Imm
    if mnemonic == "JMP":
        imm = parse_immediate(parts[1])
        # JMP uses the immediate directly
        return (OPCODES["JMP"] << 12) | (
            imm & 0xFFF
        )  # Mask to 12 bits if needed, usually 6

    # Halt
    if mnemonic == "HLT":
        return OPCODES["HLT"] << 12

    raise ValueError(f"Unknown instruction: {line}")


# ----- File Handling -----
def assemble_to_hex(input_file, output_file):
    machine_code = []
    try:
        with open(input_file, "r") as f:
            for line_num, line in enumerate(f, 1):
                try:
                    encoded = assemble_line(line)
                    if encoded is not None:
                        machine_code.append(f"{encoded:04X}")
                except Exception as e:
                    print(f"Error on line {line_num}: {line.strip()} -> {e}")
                    sys.exit(1)  # Exit with error code

        with open(output_file, "w") as f:
            for word in machine_code:
                f.write(word + "\n")
            # Add a trailing newline to prevent simulator timeout/truncation
            f.write("\n")

        print(f"✔ Success! Assembled {len(machine_code)} instructions to {output_file}")

    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found.")
        sys.exit(1)  # Exit with error code


# ----- Run Assembler -----
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Assemble RISC-16 assembly code to hex machine code."
    )
    parser.add_argument("input_file", help="Path to the input assembly file (.asm)")
    parser.add_argument(
        "output_file",
        nargs="?",
        default="program.hex",
        help="Path to the output hex file (default: program.hex)",
    )

    args = parser.parse_args()

    assemble_to_hex(args.input_file, args.output_file)
