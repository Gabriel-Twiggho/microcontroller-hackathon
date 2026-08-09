`ifndef PID_BASIC_CONFIG_VH
`define PID_BASIC_CONFIG_VH

// Stage 0 architectural decisions. All RTL modules derive their widths here.
`ifndef DATA_WIDTH
`define DATA_WIDTH  32
`endif
`ifndef ADDR_WIDTH
`define ADDR_WIDTH  16
`endif
`ifndef INSTR_WIDTH
`define INSTR_WIDTH 32
`endif
`ifndef REG_COUNT
`define REG_COUNT   32
`endif
`ifndef REG_ADDR_W
`define REG_ADDR_W  5
`endif
// Quartus analysis uses memories sized for the PID workload. The architectural
// simulation profile retains the larger memories below.
`ifdef ALTERA_RESERVED_QIS
`ifndef IMEM_DEPTH
`define IMEM_DEPTH  256
`endif
`ifndef DMEM_DEPTH
`define DMEM_DEPTH  1024
`endif
`else
`ifndef IMEM_DEPTH
`define IMEM_DEPTH  8192
`endif
`ifndef DMEM_DEPTH
`define DMEM_DEPTH  32768
`endif
`endif
`define T1_OPCODE_W 14
`define T2_OPCODE_W 9

// Derived constants.
`define DATA_MSB (`DATA_WIDTH - 1)
`define ADDR_MSB (`ADDR_WIDTH - 1)
`define PC_INIT  {`ADDR_WIDTH{1'b0}}

`endif
