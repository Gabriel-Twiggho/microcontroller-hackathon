`include "config.vh"

module dmem #(
    parameter DEPTH = `DMEM_DEPTH
)(
    input  wire                 clk,
    input  wire                 wr_en,
    input  wire [`ADDR_MSB:0]   addr,
    input  wire [`DATA_MSB:0]   wr_data,
    output wire [`DATA_MSB:0]   rd_data
);
    // Addresses are byte addresses while storage entries are 32-bit words.
    // The low two address bits select a byte within a word and must be zero
    // for Stage 3 word accesses.
    localparam WORD_INDEX_W = `ADDR_WIDTH - 2;
    wire [WORD_INDEX_W-1:0] word_index = addr[`ADDR_MSB:2];
    wire                    in_range = (word_index < DEPTH);
    reg [`DATA_MSB:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (wr_en && in_range)
            mem[word_index] <= wr_data;
    end

    assign rd_data = in_range ? mem[word_index] : {`DATA_WIDTH{1'b0}};
endmodule
