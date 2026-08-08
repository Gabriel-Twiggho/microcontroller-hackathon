`ifndef MY_CONFIG_VH
`define MY_CONFIG_VH

// Stage 0 ISA and memory sizing choices from the tutorial workbook.
// These values define the width of the datapath and the depth of the
// instruction/data memories, and they are read by the RTL modules that
// implement the CPU core and its memory interfaces.

// General datapath width: register contents and ALU operands/results.
// Downstream consumers: register file, ALU, write-back muxes, and any
// condition-code / comparison logic.
`define DATA_WIDTH 32

// Number of architectural registers in the register file.
// Downstream consumers: regfile array size, decoder register-field widths,
// and any logic that addresses registers by number.
`define REG_COUNT 32

// Bits needed to address one register: log2(REG_COUNT).
// Downstream consumers: regfile ports, decoder register fields, and ALU
// operand selection widths.
`define REG_ADDR_W 5

// Width of each instruction word.
// Downstream consumers: imem data width and the decoder/CPU instruction
// bit-slicing logic.
`define INSTR_WIDTH 32

// Width of the PC and memory-address buses.
// Downstream consumers: PC register logic, branch targets, and the address
// inputs of instruction and data memory.
`define ADDR_WIDTH 16

// Instruction memory depth in words (word-addressed Harvard IMEM).
// Downstream consumers: imem.v array size.
`define IMEM_DEPTH 8192

// Data memory depth for the separate Harvard D-MEM space.
// Downstream consumers: dmem.v array size, and any Stage 1/2 load/store
// address logic.
`define DMEM_DEPTH 32768

// Derived constants used throughout the RTL.
`define DATA_MSB (`DATA_WIDTH - 1)
`define ADDR_MSB (`ADDR_WIDTH - 1)

// Reset vector / initial PC value.
// Downstream consumers: the CPU's PC register, which must begin fetching
// from a known address after reset.
`define PC_INIT {`ADDR_WIDTH{1'b0}}

// Bytes per word for memory/stack helpers added in later stages.
// Downstream consumers: stack-pointer updates and any PUSH/POP logic.
`define WORD_BYTES (`DATA_WIDTH / 8)

// Type 1 (ALU) opcode field width. Downstream consumers: decoder's
// Type 1 opcode output and the ALU's opcode input.
`define OPCODE_W 14

// Type 2 (Memory/Control) opcode field width. Downstream consumers:
// decoder's Type 2 opcode output.
`define T2_OPCODE_W 9

// Type 2 address/immediate field width. Downstream consumers: decoder's
// t2_addr output (used for LI's immediate and, in later stages, memory
// addresses/branch offsets).
`define T2_ADDR_W 16

`endif
