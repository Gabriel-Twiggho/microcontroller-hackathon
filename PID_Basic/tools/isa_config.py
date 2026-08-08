# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 Analog Devices, Inc.
"""
isa_config.py — ISA configuration for the assembler (edit this file).

This is the assembler's source of truth for the PID_Basic ISA. The matching
RTL defines are in rtl/include/opcodes.vh; ISA.md documents the format and
semantics. Keep all three files consistent when the ISA changes.
"""

# ---------------------------------------------------------------------------
# Global ISA shape
# ---------------------------------------------------------------------------
INSTR_WIDTH = 32
REG_COUNT = 32
REG_ALIASES = {
    "sp": 2,
    "lr": 3,
}

# ---------------------------------------------------------------------------
# Opcode tables
# ---------------------------------------------------------------------------

# Type 1: ALU operations, 14-bit opcode, instruction MSB is 1.
T1_OPS = {
    "ADD": 0x0000,
    "SUB": 0x0001,
    "MUL": 0x0002,
}

# No unary ALU instructions in the initial PID ISA.
T1_UNARY = set()

# Type 2: immediate, memory, and control operations, 9-bit opcode, MSB is 0.
T2_OPS = {
    "LOAD": 0x000,
    "STORE": 0x001,
    "JMP": 0x002,
    "LI": 0x003,
    "HALT": 0x004,
}

# JMP uses either a PC-relative label/offset or an absolute #address.
BRANCH_OPS = {"JMP"}

# The initial format provides 16-bit absolute word addresses only.
MEM_OPS = {"LOAD", "STORE"}


# ---------------------------------------------------------------------------
# Encoding layout
# ---------------------------------------------------------------------------

TYPE1_LAYOUT = {
    "msb": {"bit": 31, "value": 1},
    "opcode": {"lsb": 17, "width": 14},
    "arg1_imm": {"lsb": 16, "width": 1},
    "arg1_val": {"lsb": 11, "width": 5},
    "arg2_imm": {"lsb": 10, "width": 1},
    "arg2_val": {"lsb": 5, "width": 5},
    "result_reg": {"lsb": 0, "width": 5},
}

TYPE2_LAYOUT = {
    "msb": {"bit": 31, "value": 0},
    "opcode": {"lsb": 22, "width": 9},
    "ri": {"lsb": 21, "width": 1},
    "reg": {"lsb": 16, "width": 5},
    "addr": {"lsb": 0, "width": 16},
}


def _mask(width: int) -> int:
    return (1 << width) - 1


TYPE1_IMM_MAX = _mask(TYPE1_LAYOUT["arg1_val"]["width"])
TYPE2_ADDR_MASK = _mask(TYPE2_LAYOUT["addr"]["width"])


def _encode_with_layout(layout: dict, fields: dict) -> int:
    """Generic encoder from a field layout + field values."""
    instr = 0
    if "msb" in layout:
        instr |= (layout["msb"]["value"] & 1) << layout["msb"]["bit"]

    for name, spec in layout.items():
        if name == "msb":
            continue
        value = fields[name]
        instr |= (value & _mask(spec["width"])) << spec["lsb"]

    # Keep instruction width bounded for safety.
    return instr & _mask(INSTR_WIDTH)


def encode_type1(opcode, arg1_imm, arg1_val, arg2_imm, arg2_val, result_reg):
    return _encode_with_layout(
        TYPE1_LAYOUT,
        {
            "opcode": opcode,
            "arg1_imm": arg1_imm,
            "arg1_val": arg1_val,
            "arg2_imm": arg2_imm,
            "arg2_val": arg2_val,
            "result_reg": result_reg,
        },
    )


def encode_type2(opcode, ri, reg, addr):
    return _encode_with_layout(
        TYPE2_LAYOUT,
        {
            "opcode": opcode,
            "ri": ri,
            "reg": reg,
            "addr": addr,
        },
    )
