`include "config.vh"

// Byte-addressed data memory with aligned 32-bit word accesses. LOAD is
// combinational; STORE commits on the rising edge. The low two address bits
// are ignored, so software should keep all word accesses four-byte aligned.
module dmem (
    input  wire                 clk,
    input  wire                 write_enable,
    input  wire [`ADDR_MSB:0]   address,
    input  wire [`DATA_MSB:0]   write_data,
    output wire [`DATA_MSB:0]   read_data
);
    localparam WORD_COUNT = `DMEM_DEPTH / (`DATA_WIDTH / 8);
    localparam WORD_INDEX_W = `ADDR_WIDTH - 2;

    wire [WORD_INDEX_W-1:0] word_index = address[`ADDR_MSB:2];
    wire in_range = (word_index < WORD_COUNT);
    reg [`DATA_MSB:0] mem [0:WORD_COUNT-1];

    always @(posedge clk) begin
        if (write_enable && in_range)
            mem[word_index] <= write_data;
    end

    assign read_data = in_range ? mem[word_index] : {`DATA_WIDTH{1'b0}};
endmodule
