`include "config.vh"

// Stage 1 TODO: extract the selected ISA fields and generate control signals.
// Keeping the instruction input here establishes the decoder module boundary.
module decoder (
    input wire [`INSTR_WIDTH-1:0] instruction
);
endmodule
