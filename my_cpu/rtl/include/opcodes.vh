`ifndef OPCODES_VH
`define OPCODES_VH

// Stage 1 instruction opcodes. Values match tools/isa_config.py's T1_OPS /
// T2_OPS exactly, since the RTL decoder and the Python assembler must agree
// bit-for-bit on every encoding.

// Type 1 (ALU) opcodes — 14-bit field at instr[30:17].
`define OP_ADD 14'h0000
`define OP_SUB 14'h0001
`define OP_MOV 14'h000F

// Type 2 (Memory/Control) opcodes — 9-bit field at instr[30:22].
`define OP_LI  9'h00D

// OP_JMP is only needed to recognise asm.py's HALT pseudo-instruction,
// which it encodes as "JMP to self" with every field zero
// (encode_type2(T2_OPS['JMP'], 0, 0, 0)). No hardware JMP exists until
// Stage 2 — this define exists solely for HALT detection.
`define OP_JMP 9'h004

// CALL/RET — required ahead of Stage 2/3 because compile.py's generated
// startup stub always invokes the entry function via CALL, and every
// compiled function returns via RET (MYISAISelLowering.cpp's LowerReturn
// unconditionally emits it). Only unconditional PC redirect + the link
// register (r3) are implemented here — no CMP, conditional branches, or
// stack/PUSH/POP, which remain genuine Stage 2/3 work.
`define OP_CALL 9'h009
`define OP_RET  9'h00A

// Link register number (architecturally fixed, not decoded from the
// instruction — CALL/RET always target r3).
`define LR_REG 5'd3

`endif
