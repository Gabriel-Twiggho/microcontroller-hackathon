`include "config.vh"

module imem #(
    parameter DEPTH = `IMEM_DEPTH
)(
    input  wire [`ADDR_MSB:0]      addr,
    output wire [`INSTR_WIDTH-1:0] data
);
    // The testbench loads this array through u_imem.mem.
    reg [`INSTR_WIDTH-1:0] mem [0:DEPTH-1];

    // Instruction fetch is an asynchronous, word-addressed read.
    assign data = (addr < DEPTH) ? mem[addr] : {`INSTR_WIDTH{1'b0}};
endmodule
