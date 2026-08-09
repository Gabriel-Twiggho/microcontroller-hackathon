`include "config.vh"

// 256 x 16-bit synchronous RAM. Byte addresses must be halfword aligned.
module dmem (
    input wire clk,
    input wire write_enable,
    input wire [`ADDR_MSB:0] address,
    input wire [`DATA_MSB:0] write_data,
    output reg [`DATA_MSB:0] read_data
);
    reg [`DATA_MSB:0] mem [0:(`DMEM_DEPTH/2)-1];
    wire [7:0] word_index = address[8:1];

    always @(posedge clk) begin
        if (write_enable)
            mem[word_index] <= write_data;
        read_data <= mem[word_index];
    end
endmodule
