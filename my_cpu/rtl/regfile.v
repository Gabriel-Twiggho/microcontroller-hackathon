`include "config.vh"

// Synchronous-write, asynchronous-read register file.
// r0 is hard-wired zero: reads always return 0, writes are discarded.
module regfile (
    input  wire                     clk,
    input  wire                     wr_en,
    input  wire [`REG_ADDR_W-1:0]   wr_addr,
    input  wire [`DATA_MSB:0]       wr_data,
    input  wire [`REG_ADDR_W-1:0]   rd_addr_a,
    input  wire [`REG_ADDR_W-1:0]   rd_addr_b,
    output wire [`DATA_MSB:0]       rd_data_a,
    output wire [`DATA_MSB:0]       rd_data_b
);

reg [`DATA_MSB:0] regs [0:`REG_COUNT-1];

assign rd_data_a = (rd_addr_a == 0) ? {`DATA_WIDTH{1'b0}} : regs[rd_addr_a];
assign rd_data_b = (rd_addr_b == 0) ? {`DATA_WIDTH{1'b0}} : regs[rd_addr_b];

always @(posedge clk) begin
    if (wr_en && wr_addr != 0)
        regs[wr_addr] <= wr_data;
end

endmodule
