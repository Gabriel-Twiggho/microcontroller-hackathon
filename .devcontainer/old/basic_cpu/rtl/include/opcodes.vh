`ifndef BASIC_CPU_OPCODES_VH
`define BASIC_CPU_OPCODES_VH

// Type 1: bit 31 is one, opcode is bits [30:17].
`define T1_ADD 14'h0000
`define T1_SUB 14'h0001
`define T1_MOV 14'h000f

// Type 2: bit 31 is zero, opcode is bits [30:22].
`define T2_JMP 9'h004
`define T2_CALL 9'h009
`define T2_RET  9'h00a
`define T2_LI  9'h00d

`define ALU_ADD 2'd0
`define ALU_SUB 2'd1
`define ALU_MOV 2'd2

`endif
