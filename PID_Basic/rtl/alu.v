`include "config.vh"

// Stage 1 TODO: choose an ALU-operation encoding and add ADD, SUB, and MOV.
module alu (
    input  wire [`DATA_MSB:0] a,
    input  wire [`DATA_MSB:0] b,
    input  wire [1:0]         operation,
    output reg  [`DATA_MSB:0] result
);
    always @* begin
        result = {`DATA_WIDTH{1'b0}};
    end
endmodule
