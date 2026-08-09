`include "config.vh"
`include "opcodes.vh"

// Combinational arithmetic unit. Multiplication keeps the low DATA_WIDTH bits,
// giving the ISA's defined modular two's-complement result.
module alu (
    input  wire [`DATA_MSB:0] a,
    input  wire [`DATA_MSB:0] b,
    input  wire [1:0]         operation,
    output reg  [`DATA_MSB:0] result
);
    always @* begin
        case (operation)
            `ALU_ADD: result = a + b;
            `ALU_SUB: result = a - b;
            `ALU_MUL: result = a * b;
            `ALU_SAR: result = $signed(a) >>> b[4:0];
            default:  result = {`DATA_WIDTH{1'b0}};
        endcase
    end
endmodule
