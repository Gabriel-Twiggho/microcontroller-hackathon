`ifndef PID_BASIC_OPCODES_VH
`define PID_BASIC_OPCODES_VH

// PID_Basic instruction set. See ../ISA.md for bit layouts and semantics.
// Type 1 instructions have instruction[31] = 1 and opcode [30:17].
`define T1_ADD 14'h0000
`define T1_SUB 14'h0001
`define T1_MUL 14'h000E
`define T1_SAR 14'h000C
`define T1_CMP 14'h000D

// Type 2 instructions have instruction[31] = 0 and opcode [30:22].
`define T2_LOAD  9'h000
`define T2_STORE 9'h001
`define T2_JMP   9'h004
`define T2_JZ    9'h005
`define T2_JNZ   9'h006
`define T2_JLT   9'h007
`define T2_JGT   9'h008
`define T2_LI    9'h00D


// ALU control encoding for the Stage 1 datapath.
`define ALU_ADD 2'd0
`define ALU_SUB 2'd1
`define ALU_MUL 2'd2
`define ALU_SAR 2'd3

// CMP writes -1, 0, or +1 to the dedicated condition register r5. Jcc
// instructions test that value as a signed integer.
`define COND_REG_ADDR 5'd5
`define BR_NONE       3'd0
`define BR_ALWAYS     3'd1
`define BR_ZERO       3'd2
`define BR_NOT_ZERO   3'd3
`define BR_LESS       3'd4
`define BR_GREATER    3'd5

`endif
