#!/usr/bin/env python3
"""Assembler for the compact 16-bit, eight-register PID_Tiny ISA."""
import argparse
import re

OPS = {
    "ADD": 0x0, "SUB": 0x1, "MUL": 0x2, "LOAD": 0x3,
    "STORE": 0x4, "LI": 0x5, "JMP": 0x6, "SAR": 0x7,
    "CMP": 0x8, "JZ": 0x9, "JNZ": 0xA, "JLT": 0xB,
    "JGT": 0xC, "HALT": 0xF,
}
BRANCHES = {"JMP", "JZ", "JNZ", "JLT", "JGT"}

def reg(token):
    match = re.fullmatch(r"r([0-7])", token.lower())
    if not match:
        raise ValueError(f"invalid tiny register {token}; expected r0-r7")
    return int(match.group(1))

def number(token):
    token = token.strip().lstrip("#")
    return int(token, 0)

def clean_lines(lines):
    labels = {}
    instructions = []
    for line_no, raw in enumerate(lines, 1):
        line = raw.split(";", 1)[0].strip()
        if not line:
            continue
        if ":" in line:
            label, line = line.split(":", 1)
            labels[label.strip()] = len(instructions)
            line = line.strip()
            if not line:
                continue
        instructions.append((line_no, line))
    return labels, instructions

def assemble(lines):
    labels, instructions = clean_lines(lines)
    words = []
    for pc, (line_no, line) in enumerate(instructions):
        tokens = [part for part in re.split(r"[,\s]+", line) if part]
        mnemonic = tokens[0].upper()
        try:
            if mnemonic not in OPS:
                raise ValueError(f"unknown instruction {mnemonic}")
            op = OPS[mnemonic] << 12
            if mnemonic in {"ADD", "SUB", "MUL"}:
                word = op | (reg(tokens[1]) << 9) | (reg(tokens[2]) << 6) | (reg(tokens[3]) << 3)
            elif mnemonic == "SAR":
                shift = number(tokens[3])
                if not 0 <= shift <= 7:
                    raise ValueError("SAR immediate must be 0-7")
                word = op | (reg(tokens[1]) << 9) | (reg(tokens[2]) << 6) | (shift << 3)
            elif mnemonic == "CMP":
                word = op | (reg(tokens[1]) << 6) | (reg(tokens[2]) << 3)
            elif mnemonic in {"LOAD", "STORE"}:
                address = number(tokens[2].strip("[]"))
                if not 0 <= address <= 0x1FF or address & 1:
                    raise ValueError("memory address must be even and within 0x000-0x1FE")
                word = op | (reg(tokens[1]) << 9) | address
            elif mnemonic == "LI":
                value = number(tokens[2])
                if not 0 <= value <= 0x1FF:
                    raise ValueError("LI immediate must be 0-511")
                word = op | (reg(tokens[1]) << 9) | value
            elif mnemonic in BRANCHES:
                target = tokens[1]
                offset = labels[target] - pc if target in labels else number(target)
                if not -2048 <= offset <= 2047:
                    raise ValueError("branch offset outside signed 12-bit range")
                word = op | (offset & 0xFFF)
            else:
                word = op
        except (IndexError, ValueError) as error:
            raise SystemExit(f"line {line_no}: {error}\n  {line}") from error
        words.append(word)
    return words

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input")
    parser.add_argument("-o", "--output", default="program.hex")
    args = parser.parse_args()
    with open(args.input, encoding="utf-8") as source:
        words = assemble(source)
    with open(args.output, "w", encoding="utf-8") as output:
        for word in words:
            output.write(f"{word:04X}\n")
    print(f"Assembled {len(words)} instructions -> {args.output}")

if __name__ == "__main__":
    main()
