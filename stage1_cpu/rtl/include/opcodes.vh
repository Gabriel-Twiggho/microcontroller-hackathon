`ifndef STAGE1_CPU_OPCODES_VH
`define STAGE1_CPU_OPCODES_VH

// Type 1: bit 31 is one and the opcode occupies bits [30:17].
`define T1_OPCODE_W 14
`define T1_ADD       14'h0000
`define T1_SUB       14'h0001
`define T1_MOV       14'h000f

// Type 2: bit 31 is zero and the opcode occupies bits [30:22].
`define T2_OPCODE_W 9
`define T2_JMP      9'h004
`define T2_LI       9'h00d

// Small internal ALU control encoding; it is not part of an instruction.
`define ALU_OP_W 2
`define ALU_ADD  2'd0
`define ALU_SUB  2'd1
`define ALU_MOV  2'd2

`endif
