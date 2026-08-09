`ifndef PID_BASIC_CONFIG_VH
`define PID_BASIC_CONFIG_VH

// Stage 0 architectural decisions. All RTL modules derive their widths here.
`define DATA_WIDTH  32
`define ADDR_WIDTH  16
`define INSTR_WIDTH 32
`define REG_COUNT   32
`define REG_ADDR_W  5
// Quartus uses a workload-sized analysis memory profile. Simulation keeps the
// original architectural capacities so existing tests remain unchanged.
`ifdef ALTERA_RESERVED_QIS
`define IMEM_DEPTH  256
`define DMEM_DEPTH  1024
`else
`define IMEM_DEPTH  8192
`define DMEM_DEPTH  32768
`endif
`define T1_OPCODE_W 14
`define T2_OPCODE_W 9

// Derived constants.
`define DATA_MSB (`DATA_WIDTH - 1)
`define ADDR_MSB (`ADDR_WIDTH - 1)
`define PC_INIT  {`ADDR_WIDTH{1'b0}}

`endif
