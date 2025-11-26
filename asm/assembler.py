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
        raise ValueError(f"Invalid register: '{token}'. Expected R0-R7.")
    return REGISTER_MAP[token]


def parse_immediate(token):
    token = token.strip().replace("#", "")
    try:
        return int(token, 0)
    except ValueError:
        raise ValueError(f"Invalid immediate value: '{token}'")


# ----- Encoding Functions -----
def encode_r_type(op, rd, rs, rt):
    opcode = OPCODES[op] << 12
    return opcode | (rd << 9) | (rs << 6) | (rt << 3)


def encode_i_type(op, rd, imm):
    # I-Type: Op(15:12) | Rd(11:9) | Imm(5:0)  <-- CHANGED to 6 bits
    opcode = OPCODES[op] << 12

    # Range Check for 6-bit signed (-32 to +31) or unsigned (0 to 63)
    # We allow 0-63 unsigned as it's common for addresses/constants
    if not (-32 <= imm <= 63):
        raise ValueError(f"Immediate {imm} out of range for 6-bit field (-32 to 63)")

    imm &= 0x3F  # Mask to 6 bits (was 0x1FF)
    return opcode | (rd << 9) | imm


def encode_mov_type(op, rd, imm):
    # SPECIALIZED for MOV: Uses 9-bit immediate
    # Range: -256 to +255 (Signed) or 0 to 511 (Unsigned)
    opcode = OPCODES[op] << 12

    # 9-bit Range Check
    if not (-256 <= imm <= 511):
        raise ValueError(f"Immediate {imm} out of range for 9-bit field (-256 to 511)")

    imm &= 0x1FF  # Mask to 9 bits
    return opcode | (rd << 9) | imm


def encode_branch_type(op, rs, imm):
    opcode = OPCODES[op] << 12

    if not (-32 <= imm <= 63):
        raise ValueError(
            f"Branch offset {imm} out of range for 6-bit field (-32 to 63)"
        )

    imm &= 0x3F  # Mask to 6 bits
    return opcode | (rs << 6) | imm


# ----- Assembler Core -----
def assemble_line(line):
    line = line.split(";")[0].strip()
    if not line:
        return None

    parts = re.split(r"[ ,]+", line)
    mnemonic = parts[0].upper()

    try:
        # --- R-Type Instructions (3 Regs) ---
        if mnemonic in ["ADD", "SUB", "AND", "OR", "XOR"]:
            if len(parts) < 4:
                raise ValueError(f"{mnemonic} requires 3 registers (Rd, Rs, Rt)")
            return encode_r_type(
                mnemonic,
                parse_register(parts[1]),
                parse_register(parts[2]),
                parse_register(parts[3]),
            )

        # --- R-Type (2 Regs) ---
        if mnemonic == "NOT":
            if len(parts) < 3:
                raise ValueError(f"{mnemonic} requires 2 registers (Rd, Rs)")
            return encode_r_type(
                mnemonic, parse_register(parts[1]), parse_register(parts[2]), 0
            )

        # --- Move Immediate ---
        if mnemonic == "MOV":
            if len(parts) < 3:
                raise ValueError(f"{mnemonic} requires Register and Immediate")
            # Uses encode_i_type which now enforces 6-bit limit
            return encode_mov_type(
                mnemonic, parse_register(parts[1]), parse_immediate(parts[2])
            )

        # --- Memory Instructions ---
        if mnemonic == "LDR":  # LDR Rd, [Rs]
            if len(parts) < 3:
                raise ValueError("LDR requires Destination and Address Register")
            return encode_r_type(
                "LD", parse_register(parts[1]), parse_register(parts[2]), 0
            )

        if mnemonic == "STR":  # STR Rs, Rt
            if len(parts) < 3:
                raise ValueError("STR requires Address Register and Data Register")
            return encode_r_type(
                "ST", 0, parse_register(parts[1]), parse_register(parts[2])
            )

        # --- Control Flow ---
        if mnemonic == "BEQZ":
            if len(parts) < 3:
                raise ValueError(
                    "BEQZ requires Register and Address (e.g., BEQZ R1, 0x07)"
                )
            rs = parse_register(parts[1])
            imm = parse_immediate(parts[2])
            return encode_branch_type(mnemonic, rs, imm)

        if mnemonic == "JMP":
            if len(parts) < 2:
                raise ValueError("JMP requires an Address")
            imm = parse_immediate(parts[1])
            # Hardware only reads bottom 6 bits for address, so we mask 0x3F
            return (OPCODES["JMP"] << 12) | (imm & 0x3F)

        if mnemonic == "HLT":
            return OPCODES["HLT"] << 12

        raise ValueError(f"Unknown instruction: {mnemonic}")

    except IndexError:
        raise ValueError("Missing arguments")


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
                    sys.exit(1)

        with open(output_file, "w") as f:
            for word in machine_code:
                f.write(word + "\n")
            f.write("\n")

        print(f"✔ Success! Assembled {len(machine_code)} instructions to {output_file}")

    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found.")
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Assemble RISC-16 assembly code.")
    parser.add_argument("input_file", help="Input assembly file (.asm)")
    parser.add_argument(
        "output_file", nargs="?", default="program.hex", help="Output hex file"
    )

    args = parser.parse_args()
    assemble_to_hex(args.input_file, args.output_file)
