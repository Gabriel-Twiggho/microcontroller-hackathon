`include "config.vh"
`include "opcodes.vh"

// Purely combinational. Operates on the Type 1 opcode; LI's write-back
// value bypasses the ALU entirely (handled directly in cpu.v).
module alu (
    input  wire [`DATA_MSB:0]   a,
    input  wire [`DATA_MSB:0]   b,
    input  wire [`OPCODE_W-1:0] opcode,
    output reg  [`DATA_MSB:0]   result
);

always @(*) begin
    case (opcode)
        `OP_ADD: result = a + b;
        `OP_SUB: result = a - b;
        `OP_MOV: result = a;
        default: result = {`DATA_WIDTH{1'b0}};
    endcase
end

endmodule
