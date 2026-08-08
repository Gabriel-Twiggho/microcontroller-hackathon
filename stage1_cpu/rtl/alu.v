`include "config.vh"
`include "opcodes.vh"

module alu (
    input  wire [`ALU_OP_W-1:0] operation,
    input  wire [`DATA_MSB:0]   a,
    input  wire [`DATA_MSB:0]   b,
    output reg  [`DATA_MSB:0]   result
);
    always @(*) begin
        case (operation)
            `ALU_ADD: result = a + b;
            `ALU_SUB: result = a - b;
            `ALU_MOV: result = a;
            default:  result = {`DATA_WIDTH{1'b0}};
        endcase
    end
endmodule
