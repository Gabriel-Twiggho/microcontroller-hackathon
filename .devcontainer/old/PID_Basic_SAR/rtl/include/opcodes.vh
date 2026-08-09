`ifndef PID_BASIC_OPCODES_VH
`define PID_BASIC_OPCODES_VH

// PID_Basic instruction set. See ../ISA.md for bit layouts and semantics.
// Type 1 instructions have instruction[31] = 1 and opcode [30:17].
`define T1_ADD 14'h0000
`define T1_SUB 14'h0001
`define T1_MUL 14'h000E
`define T1_SAR 14'h000C

// Type 2 instructions have instruction[31] = 0 and opcode [30:22].
`define T2_LOAD  9'h000
`define T2_STORE 9'h001
`define T2_JMP   9'h004
`define T2_LI    9'h00D


// ALU control encoding for the Stage 1 datapath.
`define ALU_ADD 2'd0
`define ALU_SUB 2'd1
`define ALU_MUL 2'd2
`define ALU_SAR 2'd3

`endif
