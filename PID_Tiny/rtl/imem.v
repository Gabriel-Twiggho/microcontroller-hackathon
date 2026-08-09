`include "config.vh"

module imem (
    input wire [5:0] address,
    output wire [`INSTR_WIDTH-1:0] instruction
);
    reg [`INSTR_WIDTH-1:0] mem [0:`IMEM_DEPTH-1];

`ifdef ALTERA_RESERVED_QIS
`ifdef TINY_CMP
    initial $readmemh("../../../build/cmp-sim/PID_Tiny_CMP.hex", mem);
`elsif TINY_SAR
    initial $readmemh("../../../build/sar-sim/PID_Tiny_SAR.hex", mem);
`else
    initial $readmemh("../../../build/baseline-sim/PID_Tiny_Baseline.hex", mem);
`endif
`endif

    assign instruction = mem[address];
endmodule
