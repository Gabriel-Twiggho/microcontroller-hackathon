`ifndef STAGE1_CPU_CONFIG_VH
`define STAGE1_CPU_CONFIG_VH

// Stage 1 architectural parameters.
`define DATA_WIDTH     32
`define ADDR_WIDTH     16
`define INSTR_WIDTH    32
`define REG_COUNT      32
`define REG_ADDR_W     5
`define IMEM_DEPTH     256
`define DMEM_DEPTH     256

// Derived constants used throughout the RTL.
`define DATA_MSB       (`DATA_WIDTH - 1)
`define ADDR_MSB       (`ADDR_WIDTH - 1)
`define PC_INIT        {`ADDR_WIDTH{1'b0}}

`endif
