`include "config.vh"

// Word-addressed, combinational instruction memory. The testbench loads mem
// through the required hierarchical path u_cpu.u_imem.mem.
module imem (
    input  wire [`ADDR_MSB:0] address,
    output wire [`DATA_MSB:0] instruction
);
    reg [`INSTR_WIDTH-1:0] mem [0:`IMEM_DEPTH-1];

    // Quartus-only initialization for the reproducible FPGA analysis build.
    // Simulation continues to load the selected program from the testbench.
`ifdef ALTERA_RESERVED_QIS
    initial $readmemh("../../../build/actuator-current-sim/PID_Actuator_Performance_test.hex", mem);
`endif

    assign instruction = mem[address];
endmodule
