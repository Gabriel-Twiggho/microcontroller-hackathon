`include "config.vh"

// Word-addressed, combinational instruction memory. The testbench loads mem
// through the required hierarchical path u_cpu.u_imem.mem.
module imem (
    input  wire [`ADDR_MSB:0] address,
    output wire [`DATA_MSB:0] instruction
);
    reg [`INSTR_WIDTH-1:0] mem [0:`IMEM_DEPTH-1];

    assign instruction = mem[address];
endmodule
