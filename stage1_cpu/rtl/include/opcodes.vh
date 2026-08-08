`ifndef STAGE1_CPU_OPCODES_VH
`define STAGE1_CPU_OPCODES_VH

// Type 1: bit 31 is one and the opcode occupies bits [30:17].
`define T1_OPCODE_W 14
`define T1_ADD       14'h0000
`define T1_SUB       14'h0001
`define T1_CMP       14'h000d
`define T1_MOV       14'h000f

// Type 2: bit 31 is zero and the opcode occupies bits [30:22].
`define T2_OPCODE_W 9
`define T2_LOAD     9'h000
`define T2_STORE    9'h001
`define T2_JMP      9'h004
`define T2_JZ       9'h005
`define T2_JNZ      9'h006
`define T2_JLT      9'h007
`define T2_JGT      9'h008
`define T2_CALL     9'h009
`define T2_RET      9'h00a
`define T2_PUSH     9'h00b
`define T2_POP      9'h00c
`define T2_LI       9'h00d

// Small internal ALU control encoding; it is not part of an instruction.
`define ALU_OP_W 2
`define ALU_ADD  2'd0
`define ALU_SUB  2'd1
`define ALU_MOV  2'd2

`endif
