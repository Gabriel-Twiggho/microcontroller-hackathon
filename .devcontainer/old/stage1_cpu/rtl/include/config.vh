`ifndef STAGE1_CPU_CONFIG_VH
`define STAGE1_CPU_CONFIG_VH

// Stage 1 architectural parameters.
`define DATA_WIDTH     32
`define ADDR_WIDTH     16
`define INSTR_WIDTH    32
`define REG_COUNT      32
`define REG_ADDR_W     5
`define IMEM_DEPTH     256
// 8192 32-bit words provide 32 KiB of byte-addressed data memory. This covers
// the startup stack address at 0x7c00.
`define DMEM_DEPTH     8192
`define WORD_BYTES     (`DATA_WIDTH / 8)

// Derived constants used throughout the RTL.
`define DATA_MSB       (`DATA_WIDTH - 1)
`define ADDR_MSB       (`ADDR_WIDTH - 1)
`define PC_INIT        {`ADDR_WIDTH{1'b0}}

`endif
