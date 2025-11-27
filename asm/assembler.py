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
    token = token.strip().replace("[", "").replace("]", "").rstrip(",")
    if token not in REGISTER_MAP:
        raise ValueError(f"Invalid register: '{token}'. Expected R0-R7.")
    return REGISTER_MAP[token]


def parse_immediate(token, current_address, symbol_table):
    """
    Parses an immediate value which can be:
    1. A number: #10, #0xFF
    2. A label: LOOP, START
    """
    token = token.strip().replace("#", "")

    # Case 1: It's a Label
    if token in symbol_table:
        return symbol_table[token]

    # Case 2: It's a Number
    try:
        return int(token, 0)
    except ValueError:
        raise ValueError(f"Invalid immediate or undefined label: '{token}'")


# ----- Encoding Functions (Updated for Labels) -----
def encode_r_type(op, rd, rs, rt):
    opcode = OPCODES[op] << 12
    return opcode | (rd << 9) | (rs << 6) | (rt << 3)


def encode_mov_type(op, rd, imm):
    opcode = OPCODES[op] << 12
    if not (-256 <= imm <= 511):
        raise ValueError(f"Immediate {imm} out of range for 9-bit field")
    imm &= 0x1FF
    return opcode | (rd << 9) | imm


def encode_i_type(op, rd, imm):
    opcode = OPCODES[op] << 12
    if not (-32 <= imm <= 63):
        raise ValueError(f"Immediate {imm} out of range for 6-bit field")
    imm &= 0x3F
    return opcode | (rd << 9) | imm


def encode_branch_type(op, rs, target_addr):
    opcode = OPCODES[op] << 12

    # Since we use Absolute Branching (PC <- Imm), target_addr is the absolute address.
    # Range Check for 6-bit address (0 to 63)
    if not (0 <= target_addr <= 63):
        raise ValueError(f"Branch target address {target_addr} out of range (0-63)")

    target_addr &= 0x3F
    return opcode | (rs << 6) | target_addr


# ----- Assembler Core (Single Line) -----
def assemble_line(line, address, symbol_table):
    # Strip comments and whitespace
    line = line.split(";")[0].strip()
    if not line:
        return None

    # Check for Label Definition (e.g., "LOOP:")
    if line.endswith(":"):
        return None  # Labels are handled in Pass 1, ignore in Pass 2

    # If line has a label prefix "LOOP: MOV...", strip it
    if ":" in line:
        line = line.split(":")[1].strip()
        if not line:
            return None

    parts = re.split(r"[ ,]+", line)
    mnemonic = parts[0].upper()

    try:
        if mnemonic in ["ADD", "SUB", "AND", "OR", "XOR"]:
            if len(parts) < 4:
                raise ValueError("Requires 3 registers")
            return encode_r_type(
                mnemonic,
                parse_register(parts[1]),
                parse_register(parts[2]),
                parse_register(parts[3]),
            )

        if mnemonic == "NOT":
            if len(parts) < 3:
                raise ValueError("Requires 2 registers")
            return encode_r_type(
                mnemonic, parse_register(parts[1]), parse_register(parts[2]), 0
            )

        if mnemonic == "MOV":
            if len(parts) < 3:
                raise ValueError("Requires Register and Immediate")
            return encode_mov_type(
                mnemonic,
                parse_register(parts[1]),
                parse_immediate(parts[2], address, symbol_table),
            )

        if mnemonic == "LDR":
            return encode_r_type(
                "LD", parse_register(parts[1]), parse_register(parts[2]), 0
            )

        if mnemonic == "STR":
            return encode_r_type(
                "ST", 0, parse_register(parts[1]), parse_register(parts[2])
            )

        if mnemonic == "BEQZ":  # BEQZ Rs, LABEL
            if len(parts) < 3:
                raise ValueError("BEQZ requires Register and Address/Label")
            rs = parse_register(parts[1])
            target = parse_immediate(parts[2], address, symbol_table)
            return encode_branch_type(mnemonic, rs, target)

        if mnemonic == "JMP":  # JMP LABEL
            target = parse_immediate(parts[1], address, symbol_table)
            if not (0 <= target <= 63):
                raise ValueError(f"Jump target {target} out of range")
            return (OPCODES["JMP"] << 12) | (target & 0x3F)

        if mnemonic == "HLT":
            return OPCODES["HLT"] << 12

        raise ValueError(f"Unknown instruction: {mnemonic}")

    except IndexError:
        raise ValueError("Missing arguments")


# ----- Two-Pass Assembler -----
def assemble_to_hex(input_file, output_file):
    machine_code = []
    symbol_table = {}

    try:
        with open(input_file, "r") as f:
            lines = f.readlines()

        # --- PASS 1: Identify Labels ---
        current_address = 0
        for line in lines:
            clean_line = line.split(";")[0].strip()
            if not clean_line:
                continue

            # Check for Label
            if ":" in clean_line:
                label_name = clean_line.split(":")[0].strip()
                # Record label address
                symbol_table[label_name] = current_address

                # If there is code on the same line (e.g. "LOOP: MOV..."), count it as an instruction
                remaining_code = clean_line.split(":")[1].strip()
                if remaining_code:
                    current_address += 1
            else:
                current_address += 1  # It's a normal instruction

        print(f"Symbols Found: {symbol_table}")

        # --- PASS 2: Generate Machine Code ---
        current_address = 0
        for line_num, line in enumerate(lines, 1):
            try:
                encoded = assemble_line(line, current_address, symbol_table)
                if encoded is not None:
                    machine_code.append(f"{encoded:04X}")
                    current_address += 1
            except Exception as e:
                print(f"Error on line {line_num}: {line.strip()} -> {e}")
                sys.exit(1)

        # Write Output
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
