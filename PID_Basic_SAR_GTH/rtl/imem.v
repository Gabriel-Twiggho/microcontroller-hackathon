`include "config.vh"

// Word-addressed, combinational instruction memory. The testbench loads mem
// through the required hierarchical path u_cpu.u_imem.mem.
module imem (
    input  wire [`ADDR_MSB:0] address,
    output wire [`DATA_MSB:0] instruction
);
    reg [`INSTR_WIDTH-1:0] mem [0:`IMEM_DEPTH-1];

    // Program-specific ROMs make both FPGA reports reproducible. Simulation
    // continues to load the program selected by its YAML configuration.
`ifdef ALTERA_RESERVED_QIS
`ifdef GTH_FIXED_POINT_ROM
    initial $readmemh("../../../build/fixed-point-sim/PID_Fixed_Point_test.hex", mem);
`else
    initial $readmemh("../../../build/c-equivalent-sim/PID_C_Equivalent_test.hex", mem);
`endif
`endif

    assign instruction = mem[address];
endmodule
