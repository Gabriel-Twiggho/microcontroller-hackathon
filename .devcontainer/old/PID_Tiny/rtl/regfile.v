`include "config.vh"

module regfile (
    input wire clk,
    input wire rst_n,
    input wire [`REG_ADDR_W-1:0] read_addr_a,
    input wire [`REG_ADDR_W-1:0] read_addr_b,
    output wire [`DATA_MSB:0] read_data_a,
    output wire [`DATA_MSB:0] read_data_b,
    input wire write_enable,
    input wire [`REG_ADDR_W-1:0] write_addr,
    input wire [`DATA_MSB:0] write_data
);
    reg [`DATA_MSB:0] regs [0:`REG_COUNT-1];
    integer i;

    assign read_data_a = (read_addr_a == 0) ? 16'h0000 : regs[read_addr_a];
    assign read_data_b = (read_addr_b == 0) ? 16'h0000 : regs[read_addr_b];

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < `REG_COUNT; i = i + 1)
                regs[i] <= 16'h0000;
        end else if (write_enable && write_addr != 0) begin
            regs[write_addr] <= write_data;
        end
    end
endmodule
